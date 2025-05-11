#pragma once

#ifdef _MSC_VER
#define forceinline __forceinline
#elif defined(__GNUC__)
#define forceinline inline __attribute__((__always_inline__))
#elif defined(__CLANG__)
#if __has_attribute(__always_inline__)
#define forceinline inline __attribute__((__always_inline__))
#else
#define forceinline inline
#endif
#else
#define forceinline inline
#endif

// First step, define the sensible functions as inline to be included in the "junkler" code. The inline behaviour must be forced, and the function definition must be in the header file. If the compiler, despite all, does not want to put stuff inline, copy-paste the code in the "junkler" function (ugly but effective).

forceinline void encrypt(char* plain, unsigned int plain_length, char* key, unsigned int key_length, char* out, char* license) {
	for (unsigned int i = 0; i < plain_length; i++) {
		out[i] = plain[i] ^ key[i % key_length];
	}
}

forceinline void decrypt(char* enc, unsigned int enc_length, char* key, unsigned int key_length, char* out, char* license) {
	for (unsigned int i = 0; i < enc_length; i++) {
		out[i] = enc[i] ^ key[i % key_length];
	}
}
