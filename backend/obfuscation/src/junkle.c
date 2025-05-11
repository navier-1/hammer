#include "junkle.h"
#include "sensible_code.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpointer-to-int-cast"

uint32_t fnv1a_32(const char* str) {
    uint32_t hash = FNV_OFFSET;
    for (size_t i = 0; i < strlen(str); i++) {
        hash ^= (uint8_t)str[i];
        hash *= FNV_PRIME;
    }
    return hash;
}

forceinline void generic_junk(int seed) {
    volatile int junk = seed; // Using `volatile` to prevent compiler optimization
    for (int i = 0; i < (seed % 4) + 2; i++) {
        junk += i;
        if (junk & 0x1) {
            for (int j = 0; j < (junk % 3) + 1; j++) {
                junk ^= (j * seed);
                switch (j % 3) {
                case 0:
                    junk += (j + i) * 3;
                    break;
                case 1:
                    junk -= (i * seed) / (j + 1);
                    break;
                case 2:
                    junk ^= (junk << (j % 2));
                    break;
                }
            }
        }
        else {
            junk ^= seed;
            switch (junk & 0x3) {
            case 0:
                for (int k = 0; k < 2; k++) {
                    junk += k * seed;
                }
                break;
            case 1:
                for (int k = 0; k < 3; k++) {
                    junk -= k * seed;
                }
                break;
            case 2:
                junk ^= (seed << i);
                break;
            case 3:
                junk += (seed * (i + 1));
                break;
            }
        }
        // Additional nested loop and switch to add more junk code
        for (int m = 0; m < 2; m++) {
            switch ((seed + m) % 4) {
            case 0:
                junk += m * i;
                break;
            case 1:
                junk ^= i * 3;
                break;
            case 2:
                junk -= m * seed;
                break;
            case 3:
                junk += seed ^ m;
                break;
            }
        }
    }
    // Prevent junk variable from being optimized out entirely
    (void)junk;
}

void junkle_encrypt(char* plain, unsigned int plain_length, char* key, unsigned int key_length, char* out, char* license) {
    if (is_debugged()) {
        return;
    }
    uint32_t hash = fnv1a_32(license); 
    uint32_t val = 0xdeadbeef;
    hash ^= val;  // Result must be: 0xf5345f58
    unsigned int tmp_i = 0;
    char tmp_c = 0;
    if (((hash >> 24) + 10) == 0xfd) {
        // See, for example here is junk code, but the junk code uses function parameters so it's confusing for the reverse engineer
        tmp_i = plain_length;
        tmp_i += key_length;
        if ((((hash >> 16) & 255) + 1) == 0x35) {
            tmp_c = plain[0] ^ key[0];
        }
        else {
            tmp_c = plain[0];
        }
        tmp_i += (unsigned int)tmp_c;
        goto label_0;
    }
    else {
        switch ((hash >> 24) + 10) {
        case 0xff:
            tmp_c = 'A';
            break;
        case 0xf5:
            generic_junk((int)plain);
            tmp_c = 'B';
            break;
        default:
            generic_junk((int)key);
            break;
        }
    label_0:
        if ((tmp_c + (hash & 255) == 153)) {
            if ((tmp_i & ((hash >> 16) & 255)) == 0) {
                if (((hash >> 16) & 255) == 0x34) {
                    if (((hash >> 8) & 255) * 2 == 0xbe) {
                        if ((hash & 255) >= 0x58) {
                            // Actual function to be called
                            return encrypt(plain, plain_length, key, key_length, out, license);
                        }
                        else {
                            return generic_junk(key_length);
                        }
                    }
                    else {
                        return generic_junk(plain_length);
                    }
                }
                else {
                    unsigned int i = 0;
                    while (i < ((hash >> 8) & 255)) {
                        tmp_i += key_length;
                        i++;
                    }
                    return generic_junk(tmp_i);
                }
            }
            else {
                generic_junk(val);  // This is needed to ensure "val" is not optimized away, since it needs to be patched
                return generic_junk((int)out);
            }
        }
    }
}

void junkle_decrypt(char* enc, unsigned int enc_length, char* key, unsigned int key_length, char* out, char* license) {
    if (is_debugged()) {
        return;
    }
    uint32_t hash = fnv1a_32(license);
    uint32_t val = 0xdeadbeef;
    hash ^= val;  // Result must be: 0xf5345f58
    unsigned int tmp_i = 0;
    char tmp_c = 0;
    if (((hash >> 24) + 10) == 0xfd) {
        // See, for example here is junk code, but the junk code uses function parameters so it's confusing for the reverse engineer
        tmp_i = enc_length;
        tmp_i += key_length;
        if ((((hash >> 16) & 255) + 1) == 0x35) {
            tmp_c = enc[0] ^ key[0];
        }
        else {
            tmp_c = enc[0];
        }
        tmp_i += (unsigned int)tmp_c;
        goto label_0;
    }
    else {
        switch ((hash >> 24) + 10) {
        case 0xff:
            tmp_c = 'A';
            break;
        case 0xf5:
            generic_junk((int)enc);
            tmp_c = 'B';
            break;
        default:
            generic_junk((int)key);
            break;
        }
    label_0:
        if ((tmp_c + (hash & 255) == 153)) {
            if ((tmp_i & ((hash >> 16) & 255)) == 0) {
                if (((hash >> 16) & 255) == 0x34) {
                    if (((hash >> 8) & 255) * 2 == 0xbe) {
                        if ((hash & 255) >= 0x58) {
                            // Actual function to be called
                            return decrypt(enc, enc_length, key, key_length, out, license);
                        }
                        else {
                            return generic_junk(key_length);
                        }
                    }
                    else {
                        return generic_junk(enc_length);
                    }
                }
                else {
                    unsigned int i = 0;
                    while (i < ((hash >> 8) & 255)) {
                        tmp_i += key_length;
                        i++;
                    }
                    return generic_junk(tmp_i);
                }
            }
            else {
                generic_junk(val * 2 + 1);  // This is needed to ensure "val" is not optimized away, since it needs to be patched. I also make it a little bit different from the other function
                return generic_junk((int)out);
            }
        }
    }
}
#pragma GCC diagnostic pop