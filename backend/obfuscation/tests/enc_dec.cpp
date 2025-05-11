// Gtest inclusion must be on top of the module
#include "gtest/gtest.h"
#include <stdio.h>
#include <assert.h>
#include "junkle.h"
#include "runtime_decryption.h"


void to_hex(char* buf, unsigned int buf_len, char* out) {
	char* map = "0123456789ABCDEF";
	for (unsigned int i = 0; i < buf_len; i++) {
		out[2 * i] = map[buf[i] >> 4];
		out[2 * i + 1] = map[buf[i] & 15];
	}
}

int test_enc_dec(char* license) {
	char plain[16] = "attack at dawn";
	unsigned int plain_length = 15;
	char key[7] = "Hello, world!";
	unsigned int key_length = 6;
	char plain_hex[100] = { 0 };
	char enc[50] = { 0 };
	char enc_hex[100] = { 0 };
	char dec[50] = { 0 };
	char dec_hex[100] = { 0 };

	s_encrypt(plain, plain_length, key, key_length, enc, license);
	s_decrypt(enc, plain_length, key, key_length, dec, license);
	to_hex(plain, plain_length, plain_hex);
	to_hex(enc, plain_length, enc_hex);
	to_hex(dec, plain_length, dec_hex);
	printf("Plaintext hex: %s\nCiphertext hex: %s\nDecrypted hex: %s\n", plain_hex, enc_hex, dec_hex);
	int check = 0;
	for (unsigned int i = 0; i < plain_length; i++) {
		check = plain[i] - dec[i];
		if (check != 0) {
			break;
		}
	}
	assert(check == 0);
	return 0;
}

TEST(encryption_decryption, BasicTest) {
	char* license = "Hello, world!";
	int res = test_enc_dec(license);
	assert(res == 0);
}

int main(int argc, char** argv)
{
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
