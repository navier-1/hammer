import subprocess
import sys
import os
from Crypto.Cipher import AES
import re


FNV_OFFSET = 0x811C9DC5
FNV_PRIME = 0x01000193

def fnv1a_32(string):
    hash_value = FNV_OFFSET
    for char in string:
        hash_value ^= ord(char)
        hash_value = (hash_value * FNV_PRIME) & 0xFFFFFFFF  # Ensure 32-bit overflow
    return hash_value

# Get symbol info for a specific symbol from parsed data
def get_symbol_info(symbol_info, symbol_name):
    if symbol_name not in symbol_info:
        raise ValueError(f"Symbol '{symbol_name}' not found in map data.")
    info = symbol_info[symbol_name]
    return info['archive_offset'], info['size'], info['rva'], info['encryptable_size']

# AES-256 encryption, skipping the last partial block
def encrypt_function(data: bytes, key: bytes):
    # Key size is 32 bytes, block size is 16 bytes
    assert(len(key) == 32)
    data = bytes(data)
    aes_ctx = AES.new(key, AES.MODE_ECB)
    payload_size = (len(data) // 16) * 16
    ciphertext = aes_ctx.encrypt(data[:payload_size])
    return bytes(ciphertext + data[payload_size:])  

def mock_get_key():
    # This must be replaced with a proper way to obtain the key, such to do not hardcode the key in the code
    return bytes.fromhex("40588dce461363b0ec7381c9df736c6831cbf4f7306586bda45a9609241d38b5")

# Encrypt the function in place in the .text section
def encrypt_in_place(binary, function_address, function_size, key):
    text_section = binary
    function_offset = function_address
    function_code = text_section[function_offset:function_offset + function_size]

    # Encrypt the function code
    encrypted_code = encrypt_function(function_code, key)

    # Replace the original function bytes with encrypted bytes
    text_section = bytes(text_section[:function_offset]) + encrypted_code + bytes(text_section[function_offset + function_size:])
    return text_section

# Patch the size placeholder pattern in stub functions
def patch_placeholder_with_size(binary, stub_address, function_size, stub_size):
    # Convert 0xdeadbeef to little-endian format
    placeholder = (0xdeadbeef).to_bytes(4, byteorder='little')
    new_value = function_size.to_bytes(4, byteorder='little')
    text_section = binary
    stub_offset = stub_address
    content = text_section
    patched = False

    # Search and replace placeholder in the function
    for i in range(stub_offset, stub_offset + stub_size - 3):
        if content[i:i+4] == placeholder:
            text_section = text_section[:i] + new_value + text_section[i+4:]
            print(f"Patched 0xdeadbeef at offset {i} with function size.")
            patched = True
    else:
        if not patched:
            raise ValueError("Placeholder 0xdeadbeef not found in stub function.")
    return text_section

# Patch the XOR value placeholder pattern in junkle functions to implement License sealing
def patch_placeholder_with_license_xor_value(binary, function_address, function_size, license_hash):
    target_hash = 0xf5345f58
    xor_hash = target_hash ^ license_hash
    # Convert 0xdeadbeef to little-endian format
    placeholder = (0xdeadbeef).to_bytes(4, byteorder='little')
    new_value = xor_hash.to_bytes(4, byteorder='little')
    text_section = binary
    function_offset = function_address
    content = text_section
    patched = False

    # Search and replace placeholder in the function
    for i in range(function_offset, function_offset + function_size - 3):
        if content[i:i+4] == placeholder:
            text_section = text_section[:i] + new_value + text_section[i+4:]
            print(f"Patched 0xdeadbeef at offset {i} with XOR value for license sealing.")
            patched = True
    else:
        if not patched:
            raise ValueError("Placeholder 0xdeadbeef not found in junkle function.")
    return text_section

def run_command(command):
    """Run a shell command and return its output as a string."""
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, text=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {' '.join(command)}\n{e.stderr}")
        sys.exit(1)

def parse_llvm_nm_output(llvm_nm_output, target_symbols):
    """Parse the output of llvm-nm and return a dictionary of symbol info including object file."""
    symbols = {}
    for line in llvm_nm_output.splitlines():
        parts = line.strip().split()
        if len(parts) < 3:
            if len(parts) == 1 and parts[0][-1] == ':':
                object_file = parts[0][:-1]
            continue
        address, symbol_type, symbol_name = parts[0], parts[1], parts[2]

        # Only keep symbols of type "T" and match them with the target symbols list
        if symbol_type == "T" and symbol_name in target_symbols:
            symbols[symbol_name] = {
                "address": int(address, 16),
                "type": symbol_type,
                "object_file": object_file
            }
    return symbols

def parse_ar_output(ar_output):
    """Parse the output of 'ar tOv' and return a list of object files with offsets."""
    object_files = []
    for line in ar_output.splitlines():
        parts = line.split()
        if len(parts) < 2:
            continue
        offset = int(parts[-1], 16)
        filename = parts[-2]
        object_files.append({"filename": filename, "offset": offset})
    return object_files

def get_disassembly_and_file_offsets(archive_file, symbol_list, llvm_symbols):
    output = run_command(["objdump", "-dF", archive_file])
    object_file = "unknown"
    symbol_name = "unknown"
    symbol_offset = 0
    symbol_rva = 0
    symbols = {}
    for line in output.splitlines():
        parts = line.split()
        if len(parts) < 2:
            continue
        if parts[0].endswith('.obj:') or parts[0].endswith('.o:'):
            object_file = parts[0][:-1]
            continue
        if 'File Offset' in line and line.startswith('00'):
            symbol_name = parts[1][1:-1]
            symbol_offset = int(parts[-1][:-2], 16)
            symbol_rva = int(parts[0], 16)
            continue
        if len(parts) >= 3 and parts[2] == 'ret':
            symbol_size = int(parts[0][:-1], 16) + 1 - symbol_rva
            if symbol_name in symbol_list and llvm_symbols[symbol_name]['object_file'] == object_file:
                if symbol_name not in symbols:
                    symbols[symbol_name] = {
                        "offset": symbol_offset,
                        "size": symbol_size,
                        "object_file": object_file
                    }
                else:
                    prev_size = symbols[symbol_name]['size']
                    if symbol_size > prev_size:
                        symbols[symbol_name] = {
                            "offset": symbol_offset,
                            "size": symbol_size,
                            "object_file": object_file
                        }
    return symbols

def parse_objdump_relocations(archive_file):
    # Get objdump reloc output as a string
    objdump_output = run_command(["objdump", "-r", archive_file])

    # Dictionary to store offsets for each object file
    relocations = {}
    
    # Regular expression patterns to match the object file and relocation entries
    object_pattern = re.compile(r"^(\S+\.o|\S+\.obj):\s+file format.*$")
    section_pattern = re.compile(r"^\s*RELOCATION RECORDS FOR \[(\.[a-zA-Z0-9_.]+)\]:")
    relocation_pattern = re.compile(r"^\s*(0x{0,1}[0-9a-fA-F]+)\s+(R_[A-Z0-9_]+|IMAGE_[A-Z0-9_]+)\s+(\S+)")

    current_object = None
    current_section = None

    # Process the objdump output line by line
    for line in objdump_output.splitlines():
        # Check if the line matches an object file header
        object_match = object_pattern.match(line)
        if object_match:
            current_object = object_match.group(1)
            relocations[current_object] = []

        section_match = section_pattern.match(line)
        if section_match:
            current_section = section_match.group(1)
        
        # Check if the line matches a relocation entry
        relocation_match = relocation_pattern.match(line)
        if relocation_match and current_object and current_section == '.text':
            offset = relocation_match.group(1)  # Relocation offset
            relocations[current_object].append(int(offset, 16))
    return relocations

def get_symbols_from_file(archive_file, symbol_list):
    # Run llvm-nm on the archive to find symbols
    llvm_nm_output = run_command(["llvm-nm", archive_file])
    symbols = parse_llvm_nm_output(llvm_nm_output, symbol_list)

    if not symbols:
        raise Exception("No matching symbols found.")

    # Run ar to list object files with offsets
    ar_output = run_command(["ar", "tOv", archive_file])
    object_files = parse_ar_output(ar_output)

    symbol_details = get_disassembly_and_file_offsets(archive_file, symbol_list, symbols)

    relocations = parse_objdump_relocations(archive_file)

    # Process each symbol
    results = {}
    for symbol_name, symbol_info in symbols.items():
        for obj in object_files:
            if obj['filename'] == symbol_info["object_file"]:
                obj_offset = obj['offset']
                break
        else:
            raise Exception("No matching object file for symbol")  
        detail = symbol_details[symbol_name]
        # Calculate final offset
        archive_offset = detail["offset"] + obj_offset
        # For static library, encryptable size is limited by first relocation; the relocation address is expressed as RVA
        symbol_relocs = relocations[symbol_info["object_file"]]
        greater_relocs = [reloc for reloc in symbol_relocs if reloc > symbol_info["address"]]
        if len(greater_relocs) >= 1:
            encryptable_size = greater_relocs[0] - symbol_info["address"]
            encryptable_size = (encryptable_size // 16) * 16
        else:
            encryptable_size = detail["size"]
        results[symbol_name] = {
            "object_file": symbol_info["object_file"],
            "rva": symbol_info["address"],
            "size": detail["size"],
            "archive_offset": archive_offset,
            "encryptable_size": encryptable_size
        }
    return results

if __name__ == "__main__":
    if len(sys.argv) < 6:
        print(f"Usage: {sys.argv[0]} input_binary_path ignored_argument out_binary_path target_pairs_path target_license_path")
        sys.exit(1)
    binary_path = sys.argv[1]
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

    # Use third-party utilities to parse the static library with debug info to get symbol information
    symbol_data = get_symbols_from_file(binary_path, target_symbols)
    print(symbol_data)

    # Load the binary
    with open(binary_path, 'rb') as f:
        binary = f.read()
    
    for pair in target_pairs:
        encrypt_address, encrypt_size, _, actual_encryptable_size = get_symbol_info(symbol_data, pair[0])
        stub_address, stub_size, _, _ = get_symbol_info(symbol_data, pair[1])
        # Patch placeholder in junkle function for license sealing
        binary = patch_placeholder_with_license_xor_value(binary, encrypt_address, encrypt_size, license_hash)
        # Encrypt the function in place
        binary = encrypt_in_place(binary, encrypt_address, actual_encryptable_size, key=code_encryption_key)
        # Patch 0xdeadbeef in the stub with the size of the function that the stub decrypts
        binary = patch_placeholder_with_size(binary, stub_address, actual_encryptable_size, stub_size)
    
    # Save the modified binary
    with open(out_path, 'wb') as f:
        f.write(binary)

    print(f"Binary modified and saved as {out_path}")