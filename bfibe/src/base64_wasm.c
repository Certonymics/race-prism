#include <emscripten.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

EM_JS(size_t, js_base64_decode, (const char *input, uint8_t *output), {
// clang-format off
  try {
    const decoded = atob(UTF8ToString(input));
    const len = decoded.length;
    for (let i = 0; i < len; i++) {
      HEAPU8[output + i] = decoded.charCodeAt(i);
    }
    return len;
  } catch(_) {
    return 0;
  }
// clang-format on
});

uint8_t *base64_decode(uint8_t *b64message, size_t *decode_len) {
  if (NULL == b64message || NULL == decode_len) {
    return NULL;
  }

  size_t input_len = strlen((char *)b64message);
  size_t max_len = (input_len * 3) / 4 + 1;
  uint8_t *decoded = (uint8_t *)malloc(max_len + 1);
  if (NULL == decoded) {
    *decode_len = 0;
    return NULL;
  }

  *decode_len = js_base64_decode((const char *)b64message, decoded);

  if (*decode_len == 0 && input_len > 0) {
    free(decoded);
    return NULL;
  }

  return decoded;
}

EM_JS(char *, js_base64_encode, (uint8_t *input, size_t input_len), {
// clang-format off
  try {
    var charCodes = '';
    for (let i = 0; i < input_len; i++) {
      charCodes += String.fromCharCode(HEAPU8[input + i]);
    }
    return stringToNewUTF8(btoa(charCodes));
  } catch (_) {
    return 0;
  }
// clang-format on
});

uint8_t *base64_encode(uint8_t *buffer, size_t length) {
  if (NULL == buffer) {
    return NULL;
  }

  return (uint8_t *)js_base64_encode(buffer, length);
}
