#include <stdint.h>
#include <stdlib.h>

#define SHA_DIGEST_LENGTH 20
#define SHA256_DIGEST_LENGTH 32
#define SHA384_DIGEST_LENGTH 48
#define SHA512_DIGEST_LENGTH 64

#define DECLARE_SHA(name) uint8_t *name(const uint8_t *d, size_t n, uint8_t *md)

DECLARE_SHA(SHA1);
DECLARE_SHA(SHA256);
DECLARE_SHA(SHA384);
DECLARE_SHA(SHA512);