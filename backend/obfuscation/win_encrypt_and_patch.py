import sys
import lief
from Crypto.Cipher import AES


FNV_OFFSET = 0x811C9DC5
FNV_PRIME = 0x01000193

def fnv1a_32(string):
    hash_value = FNV_OFFSET
    for char in string:
        hash_value ^= ord(char)
        hash_value = (hash_value * FNV_PRIME) & 0xFFFFFFFF  # Ensure 32-bit overflow
    return hash_value


# Load and parse map file for specific symbols
def parse_map_file(map_file_path, symbols):
    symbol_info = {}
    last_address = None
    last_symbol = None

    with open(map_file_path, 'r') as f:
        for line in f:
            parts = line.split()
            if "Preferred load address" in line:
                base_load_address = int(parts[4], 16)
                continue
            try:
                if len(parts) >= 2:
                    symbol_name = parts[1]
                    address_str = parts[0].split(':')[1]
                    address = int(address_str, 16)
                    load_address_str = parts[2]
                    load_address = int(load_address_str, 16)

                    # Calculate size based on previous symbol
                    if last_symbol in symbols:
                        symbol_info[last_symbol] = (last_address, address - last_address, last_load_offset)

                    last_address = address
                    last_symbol = symbol_name
                    last_load_offset = load_address - base_load_address
            except:
                pass

    return symbol_info


# Get symbol info for a specific symbol from parsed data
def get_symbol_info(symbol_info, symbol_name):
    if symbol_name not in symbol_info:
        raise ValueError(f"Symbol '{symbol_name}' not found in map data.")
    return symbol_info[symbol_name]


# AES-256 encryption, skipping the last partial block
def encrypt_function(data: bytes, key: bytes):
    # Key size is 32 bytes, block size is 16 bytes
    assert(len(key) == 32)
    aes_ctx = AES.new(key, AES.MODE_ECB)
    payload_size = (len(data) // 16) * 16
    ciphertext = aes_ctx.encrypt(data[:payload_size])
    return ciphertext + data[payload_size:]


def mock_get_key():
    # This must be replaced with a proper way to obtain the key, such to do not hardcode the key in the code
    return bytes.fromhex("40588dce461363b0ec7381c9df736c6831cbf4f7306586bda45a9609241d38b5")


# Encrypt the function in place in the .text section
def encrypt_in_place(binary, function_address, function_size, key):
    text_section = binary.get_section(".text")
    function_offset = function_address
    function_code = text_section.content[function_offset:function_offset + function_size].tobytes()

    # Encrypt the function code
    encrypted_code = encrypt_function(function_code, key)

    # Replace the original function bytes with encrypted bytes
    text_section.content = [b for b in text_section.content[:function_offset].tobytes() + encrypted_code + text_section.content[function_offset + function_size:].tobytes()]


# Patch the size placeholder pattern in stub functions
def patch_placeholder_with_size(binary, stub_address, function_size, stub_size):
    # Convert 0xdeadbeef to little-endian format
    placeholder = (0xdeadbeef).to_bytes(4, byteorder='little')
    new_value = function_size.to_bytes(4, byteorder='little')
    text_section = binary.get_section(".text")
    stub_offset = stub_address
    content = text_section.content
    patched = False

    # Search and replace placeholder in the function
    for i in range(stub_offset, stub_offset + stub_size - 3):
        if content[i:i+4] == placeholder:
            text_section.content = [b for b in text_section.content[:i].tobytes() + new_value + text_section.content[i+4:].tobytes()]
            print(f"Patched 0xdeadbeef at offset {i} with function size.")
            patched = True
    else:
        if not patched:
            raise ValueError("Placeholder 0xdeadbeef not found in stub function.")


# Patch the offset placeholder pattern in stub functions
def patch_placeholder_with_offset(binary, stub_address, function_load_offset, stub_size):
    # Convert 0xcafebabecafebabe to little-endian format
    placeholder = (0xcafebabecafebabe).to_bytes(8, byteorder='little')
    new_value = function_load_offset.to_bytes(8, byteorder='little')
    text_section = binary.get_section(".text")
    stub_offset = stub_address
    content = text_section.content

    # Search and replace placeholder in the function
    for i in range(stub_offset, stub_offset + stub_size - 7):
        if content[i:i+8] == placeholder:
            text_section.content = [b for b in text_section.content[:i].tobytes() + new_value + text_section.content[i+8:].tobytes()]
            print(f"Patched 0xcafebabecafebabe at offset {i} with function offset.")
            break
    else:
        raise ValueError("Placeholder 0xcafebabecafebabe not found in stub function.")


# Patch the XOR value placeholder pattern in junkle functions to implement License sealing
def patch_placeholder_with_license_xor_value(binary, function_address, function_size, license_hash):
    target_hash = 0xf5345f58
    xor_hash = target_hash ^ license_hash
    # Convert 0xdeadbeef to little-endian format
    placeholder = (0xdeadbeef).to_bytes(4, byteorder='little')
    new_value = xor_hash.to_bytes(4, byteorder='little')
    text_section = binary.get_section(".text")
    function_offset = function_address
    content = text_section.content
    patched = False

    # Search and replace placeholder in the function
    for i in range(function_offset, function_offset + function_size - 3):
        if content[i:i+4] == placeholder:
            text_section.content = [b for b in text_section.content[:i].tobytes() + new_value + text_section.content[i+4:].tobytes()]
            print(f"Patched 0xdeadbeef at offset {i} with XOR value for license sealing.")
            patched = True
    else:
        if not patched:
            raise ValueError("Placeholder 0xdeadbeef not found in junkle function.")


if __name__ == "__main__":
    if len(sys.argv) < 6:
        print(f"Usage: {sys.argv[0]} input_binary_path map_file_path out_binary_path target_pairs_path target_license_path")
        sys.exit(1)
    binary_path = sys.argv[1]
    map_file_path = sys.argv[2]
    out_path = sys.argv[3]
    target_pairs_path = sys.argv[4]
    license_path = sys.argv[5]
    code_encryption_key = mock_get_key()

    # Read symbols to locate
    target_pairs = []
    with open(target_pairs_path, 'r') as f:
        pair = f.readline()
        while pair:
            pair = pair.split()
            target_pairs.append((pair[0], pair[1]))
            pair = f.readline()

    target_symbols = [pair[i] for pair in target_pairs for i in range(2)]

    # Read target license to seal in the binary
    with open(license_path, 'r') as f:
        line = f.readline()
        __license = line.strip()
    license_hash = fnv1a_32(__license)

    # Load the binary
    binary = lief.parse(binary_path)

    # Parse map file and get symbol information
    symbol_data = parse_map_file(map_file_path, target_symbols)
    print(symbol_data)
    for pair in target_pairs:
        encrypt_address, encrypt_size, encrypt_load_offset = get_symbol_info(symbol_data, pair[0])
        stub_address, stub_size, _ = get_symbol_info(symbol_data, pair[1])
        # Patch placeholder in junkle function for license sealing
        patch_placeholder_with_license_xor_value(binary, encrypt_address, encrypt_size, license_hash)
        # Encrypt the function in place
        encrypt_in_place(binary, encrypt_address, encrypt_size, key=code_encryption_key)
        # Patch 0xdeadbeef in the stub with the size of the function that the stub decrypts
        patch_placeholder_with_size(binary, stub_address, encrypt_size, stub_size)
        # Patch 0xcafebabecafebabe in the stub with the offset of the function that the stub decrypts
        # Commented out because it works just with function address in Release mode
        # patch_placeholder_with_offset(binary, stub_address, encrypt_load_offset, stub_size)

    # Save the modified binary
    binary.write(out_path)
    print(f"Binary modified and saved as {out_path}")
