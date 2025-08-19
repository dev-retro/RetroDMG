#pragma once
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Memory helpers
void retrodmg_string_free(char* ptr);
void retrodmg_buffer_free(void* ptr);

// Lifecycle
uint64_t retrodmg_create(void);
void     retrodmg_destroy(uint64_t handle);

// Metadata
char*  retrodmg_name(uint64_t handle);
char*  retrodmg_description(uint64_t handle);
int32_t retrodmg_release_year(uint64_t handle);

// Control
int32_t retrodmg_start(uint64_t handle);
int32_t retrodmg_pause(uint64_t handle);
int32_t retrodmg_stop(uint64_t handle);

// ROM / Settings
void retrodmg_load_rom(uint64_t handle, const uint8_t* data, int length);
void retrodmg_set_bios(uint64_t handle, const uint8_t* data, int length);

// Save Data
void   retrodmg_load_save_data(uint64_t handle, const uint8_t* data, int length);
int32_t retrodmg_get_save_data(uint64_t handle, uint8_t** outData, int* outLength);

// Inputs
int32_t retrodmg_input_count(uint64_t handle);
char*   retrodmg_input_name(uint64_t handle, int32_t index);
void    retrodmg_set_input(uint64_t handle, const char* name, int32_t active, int32_t playerNo);
// Batch inputs: names is array of C strings, actives is array of int8_t (0/1), playerNos is array of int32_t, count is length
void    retrodmg_set_inputs(uint64_t handle, const char** names, const int8_t* actives, const int32_t* playerNos, int32_t count);

// Video
// Copy current 160x144 viewport pixels into outPixels buffer (int32_t ARGB/whatever format provided by core)
// Returns number of pixels written or 0 on failure.
int32_t retrodmg_viewport_copy(uint64_t handle, int32_t* outPixels, int32_t outPixelCount);

#ifdef __cplusplus
}
#endif
