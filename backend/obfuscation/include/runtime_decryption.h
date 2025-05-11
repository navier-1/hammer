#pragma once

#ifdef __cplusplus
	#define EXTERN_C extern "C"
#else
	#define EXTERN_C
#endif

#if defined(_WIN32) || defined(_WIN64)
	#define EXPORT_SYMBOL __declspec(dllexport) EXTERN_C
	#define NO_OPTIMIZE __pragma(optimize("", off))
	#define END_NO_OPTIMIZE __pragma(optimize("", on))
#else
	#define EXPORT_SYMBOL  __attribute__((visibility("default"))) EXTERN_C
	#define NO_OPTIMIZE __attribute__((optnone))
	#define END_NO_OPTIMIZE
#endif

unsigned int mock_get_key(unsigned int max_len, char* out_key);

#if defined(_WIN32) || defined(_WIN64)
void encrypt_code(char* key, unsigned int key_len, char* code, unsigned int code_len);
#else
void encrypt_code(char* key, unsigned int key_len, char* code_in, unsigned int code_len, char* code_out);
#endif

#if defined(_WIN32) || defined(_WIN64)
void decrypt_code(char* key, unsigned int key_len, char* code, unsigned int code_len);
#else
void decrypt_code(char* key, unsigned int key_len, char* code_in, unsigned int code_len, char* code_out);
#endif

// Prototypes of decryption stubs must match prototypes of functions being decrypted, that are junkle functions, i.e., the original functions being protected.

EXPORT_SYMBOL void s_encrypt(char* plain, unsigned int plain_length, char* key, unsigned int key_length, char* out, char* license);

EXPORT_SYMBOL void s_decrypt(char* enc, unsigned int enc_length, char* key, unsigned int key_length, char* out, char* license);
