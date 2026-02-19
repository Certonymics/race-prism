#include "sha_wasm.h"

#include <emscripten.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

EM_ASYNC_JS(bool, js_digest, (const char *algo, const uint8_t *input, size_t input_len, uint8_t *out), {
// clang-format off
    try {
        const algoStr = UTF8ToString(algo);
        const hashBuffer = await crypto.subtle.digest(
            algoStr, HEAPU8.subarray(input, input + input_len));
        HEAPU8.set(new Uint8Array(hashBuffer), out);
        return true;
    }
    catch(_) {
        return false;
    }
// clang-format on
});

uint8_t *SHA1(const uint8_t *d, size_t n, uint8_t *md) {
  static uint8_t m[SHA_DIGEST_LENGTH];

  if (md == NULL) {
    md = m;
  }
  return js_digest("SHA-1", d, n, md) ? md : NULL;
}

uint8_t *SHA256(const uint8_t *d, size_t n, uint8_t *md) {
  static uint8_t m[SHA256_DIGEST_LENGTH];

  if (md == NULL) {
    md = m;
  }
  return js_digest("SHA-256", d, n, md) ? md : NULL;
}

uint8_t *SHA384(const uint8_t *d, size_t n, uint8_t *md) {
  static uint8_t m[SHA384_DIGEST_LENGTH];

  if (md == NULL) {
    md = m;
  }
  return js_digest("SHA-384", d, n, md) ? md : NULL;
}

uint8_t *SHA512(const uint8_t *d, size_t n, uint8_t *md) {
  static uint8_t m[SHA512_DIGEST_LENGTH];

  if (md == NULL) {
    md = m;
  }
  return js_digest("SHA-512", d, n, md) ? md : NULL;
}