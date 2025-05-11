#pragma once
#include <stdint.h>
#include <string.h>

#include "anti_debug.h"

// There is a "junkler" function for each function to be obfuscated. The junkler has the same prototype of the target function, computes the FNV1a-32 hash of the input license and performs dummy branches with junk code based on the hash result (which is XORed with a patched placeholder such to know the final result), then calls the target function, that is supposed to be defined as inline in order to be included inline. It is designed to be efficient, also it can be tailored on the parameters of the function to be obfuscated, such that the junk code uses the parameters (better for confusing the reverse engineer). There is also the usage of a "generic_junk" inline function that is never actually called and has the purpose of balancing the volumes of dummy branches and of the real branch.
// NOTE: the junkler function is intended to be encrypted at post-compile time, and then decrypted at runtime to be executed. It's not intended as a single anti-RE solution.


#define FNV_OFFSET 0x811C9DC5
#define FNV_PRIME  0x01000193

// FNV-1a 32-bit hash calculation
uint32_t fnv1a_32(const char* str);

// Thanks to the seed, this junk function will be different for different parameters. It's particularly effective when using function parameters as seed, in order to make it look like an useful function which process function parameters.
extern void generic_junk(int seed);

void junkle_encrypt(char* plain, unsigned int plain_length, char* key, unsigned int key_length, char* out, char* license);

void junkle_decrypt(char* enc, unsigned int enc_length, char* key, unsigned int key_length, char* out, char* license);
