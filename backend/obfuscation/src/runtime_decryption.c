#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

#define OPENSSL_API_COMPAT 0x10100000L  // For OpenSSL 1.1.0 compatibility
#define OPENSSL_NO_DEPRECATED
#include <openssl/aes.h>

#if defined(_WIN32) || defined(_WIN64)
    #include <windows.h>
#else
    #include <sys/mman.h>
    #include <unistd.h>
    #include <errno.h>
    #include <string.h>
    #include <fcntl.h>
#endif

#include "runtime_decryption.h"
#include "junkle.h"

/*
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wattributes"
*/

#define BLOCK_SIZE 16

/*
uintptr_t base_address = 0;  // Global variable to store the base address

uintptr_t get_base_address() {
    if (base_address != NULL) {
        return base_address;  // Return cached base address if already initialized
    }

#if defined(_WIN32) || defined(_WIN64)
    base_address = (uintptr_t)GetModuleHandle(NULL);
#else
    FILE* maps = fopen("/proc/self/maps", "r");
    if (!maps) {
        // perror("fopen /proc/self/maps failed");
        return NULL;
    }

    char line[256];
    uintptr_t start_addr = 0;

    while (fgets(line, sizeof(line), maps)) {
        if (strstr(line, " r--p ") && strstr(line, "/")) {  // Look for executable segments with a file path
            sscanf(line, "%lx-", &start_addr);
            base_address = start_addr;
            break;
        }
    }
    fclose(maps);
#endif

    return base_address;
}
*/

unsigned int mock_get_key(unsigned int max_len, char* out_key) {
    unsigned int key_len = 32;
    if (max_len < key_len) {
        return 0;
    }
    char mock_key[32] = "\x40\x58\x8d\xce\x46\x13\x63\xb0\xec\x73\x81\xc9\xdf\x73\x6c\x68\x31\xcb\xf4\xf7\x30\x65\x86\xbd\xa4\x5a\x96\x09\x24\x1d\x38\xb5";
    memcpy(out_key, mock_key, 32);
    return key_len;
}

// Encryption/Decryption are such to keep code size unchanged, as such if the plaintext length is not multiple of the block size, the last partial block is skipped.

#if defined(_WIN32) || defined(_WIN64)
#ifdef _MSC_VER
#pragma warning(disable : 4996)  // Disable MSVC-specific warning C4996
#endif
void encrypt_code(char* key, unsigned int key_len, char* code, unsigned int code_len) {
    if (key_len < 32) {
        // Silently skip encryption
        return;
    }
    AES_KEY enc_key;
    AES_set_encrypt_key(key, 256, &enc_key);
    unsigned int number_of_full_blocks = code_len / BLOCK_SIZE;
    for (unsigned int i = 0; i < number_of_full_blocks * BLOCK_SIZE; i += BLOCK_SIZE) {
        AES_encrypt(code + i, code + i, &enc_key);
    }
}
#else
void encrypt_code(char* key, unsigned int key_len, char* code_in, unsigned int code_len, char* code_out) {
    if (key_len < 32) {
        // Silently skip encryption
        return;
    }
    AES_KEY enc_key;
    AES_set_encrypt_key(key, 256, &enc_key);
    unsigned int number_of_full_blocks = code_len / BLOCK_SIZE;
    for (unsigned int i = 0; i < number_of_full_blocks * BLOCK_SIZE; i += BLOCK_SIZE) {
        AES_encrypt(code_in + i, code_out + i, &enc_key);
    }
}
#endif

#if defined(_WIN32) || defined(_WIN64)
#ifdef _MSC_VER
#pragma warning(disable : 4996)  // Disable MSVC-specific warning C4996
#endif
void decrypt_code(char* key, unsigned int key_len, char* code, unsigned int code_len) {
    if (key_len < 32) {
        // Silently skip decryption
        return;
    }
    AES_KEY dec_key;
    AES_set_decrypt_key(key, 256, &dec_key);
    unsigned int number_of_full_blocks = code_len / BLOCK_SIZE;
    for (unsigned int i = 0; i < number_of_full_blocks * BLOCK_SIZE; i += BLOCK_SIZE) {
        AES_decrypt(code + i, code + i, &dec_key);
    }
}
#else
void decrypt_code(char* key, unsigned int key_len, char* code_in, unsigned int code_len, char* code_out) {
    if (key_len < 32) {
        // Silently skip decryption
        return;
    }
    AES_KEY dec_key;
    AES_set_decrypt_key(key, 256, &dec_key);
    unsigned int number_of_full_blocks = code_len / BLOCK_SIZE;
    for (unsigned int i = 0; i < number_of_full_blocks * BLOCK_SIZE; i += BLOCK_SIZE) {
        AES_decrypt(code_in + i, code_out + i, &dec_key);
    }
}
#endif

EXPORT_SYMBOL NO_OPTIMIZE void s_encrypt(char* plain, unsigned int plain_length, char* key, unsigned int key_length, char* out, char* license) {
    // In general, you need to adjust the "return" statements to match function prototype
    size_t func_size = 0xdeadbeef;  // Placeholder to be replaced by actual size

    /*
    void* func_offset = (void*)0xcafebabecafebabe;    // Placeholder to be replaced by actual function offset
    uintptr_t process_base = get_base_address();
    void* func_addr = process_base + (uintptr_t)func_offset;
    */
    void* func_addr = (void*)&junkle_encrypt;

    char code_key[32] = { 0 };
    unsigned int code_key_len = mock_get_key(32, code_key);
#if defined(_WIN32) || defined(_WIN64)
    DWORD oldProtect;
    if (!VirtualProtect((void*)func_addr, func_size, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        // fprintf(stderr, "VirtualProtect RWX failed\n");
        return;
    }
    char* func_data = (char*)func_addr;
    decrypt_code(code_key, code_key_len, func_data, func_size);
    // No need to use function pointers, it's possible to directly call junkle_encrypt since at this point it will have been decrypted
    junkle_encrypt(plain, plain_length, key, key_length, out, license);
    encrypt_code(code_key, code_key_len, func_data, func_size);
    if (!VirtualProtect((void*)func_addr, func_size, oldProtect, &oldProtect)) {
        // fprintf(stderr, "VirtualProtect restore failed\n");
        return;
    }
#else
    size_t page_size = sysconf(_SC_PAGESIZE);
    size_t mprotect_size = ((func_size / page_size) + 2) * page_size;
    uintptr_t page_start = (uintptr_t)func_addr & ~((uintptr_t)page_size - 1);
    if (mprotect((void*)page_start, mprotect_size, PROT_READ | PROT_WRITE | PROT_EXEC) == -1) {
        // perror("mprotect RWX failed");
        return;
    }
    char* func_data = (char*)func_addr;
    decrypt_code(code_key, code_key_len, func_data, func_size, func_data);
    junkle_encrypt(plain, plain_length, key, key_length, out, license);
    encrypt_code(code_key, code_key_len, func_data, func_size, func_data);
    if (mprotect((void*)page_start, mprotect_size, PROT_READ | PROT_EXEC) == -1) {
        // perror("mprotect X-only failed");
        return;
    }
#endif
}
END_NO_OPTIMIZE

EXPORT_SYMBOL NO_OPTIMIZE void s_decrypt(char* enc, unsigned int enc_length, char* key, unsigned int key_length, char* out, char* license) {
    // In general, you need to adjust the "return" statements to match function prototype
    size_t func_size = 0xdeadbeef;  // Placeholder to be replaced by actual size

    /*
    void* func_offset = (void*)0xcafebabecafebabe;    // Placeholder to be replaced by actual function offset
    uintptr_t process_base = get_base_address();
    void* func_addr = process_base + (uintptr_t)func_offset;
    */
    void* func_addr = (void*)&junkle_decrypt;

    char code_key[32] = { 0 };
    unsigned int code_key_len = mock_get_key(32, code_key);

#if defined(_WIN32) || defined(_WIN64)
    DWORD oldProtect;
    if (!VirtualProtect((void*)func_addr, func_size, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        // fprintf(stderr, "VirtualProtect RWX failed\n");
        return;
    }
    char* func_data = (char*)func_addr;
    decrypt_code(code_key, code_key_len, func_data, func_size);
    // No need to use function pointers, it's possible to directly call junkle_decrypt since at this point it will have been decrypted
    junkle_decrypt(enc, enc_length, key, key_length, out, license);
    encrypt_code(code_key, code_key_len, func_data, func_size);
    if (!VirtualProtect((void*)func_addr, func_size, oldProtect, &oldProtect)) {
        // fprintf(stderr, "VirtualProtect restore failed\n");
        return;
    }
#else
    size_t page_size = sysconf(_SC_PAGESIZE);
    size_t mprotect_size = ((func_size / page_size) + 2) * page_size;
    uintptr_t page_start = (uintptr_t)func_addr & ~((uintptr_t)page_size - 1);
    if (mprotect((void*)page_start, mprotect_size, PROT_READ | PROT_WRITE | PROT_EXEC) == -1) {
        // perror("mprotect RWX failed");
        return;
    }
    char* func_data = (char*)func_addr;
    decrypt_code(code_key, code_key_len, func_data, func_size, func_data);
    junkle_decrypt(enc, enc_length, key, key_length, out, license);
    encrypt_code(code_key, code_key_len, func_data, func_size, func_data);
    if (mprotect((void*)page_start, mprotect_size, PROT_READ | PROT_EXEC) == -1) {
        // perror("mprotect X-only failed");
        return;
    }
#endif
/*
#pragma GCC diagnostic pop
#pragma GCC diagnostic pop
*/
}
END_NO_OPTIMIZE
