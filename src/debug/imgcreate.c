#include <lua.h>
#include <lauxlib.h>

#include <stdint.h>
#include <stdlib.h>

/*---------------------------------------------------------------------------*/
/* stb_image_write config and inclusion */
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBIW_ASSERT(x)
#define STBI_WRITE_NO_STDIO
#define STB_IMAGE_WRITE_STATIC
#include "stb_image_write.h"
/*---------------------------------------------------------------------------*/

typedef enum {
    PNG,
    BMP,
    TGA,
    JPEG
}
Format;

static void const* get_pixels(
    lua_State* const L,
    int const width,
    int const height,
    int const components,
    int const get_pixel_index) {

    uint8_t* const pixels = (uint8_t*)malloc(width * height * components);

    if (pixels == NULL) {
        luaL_error(L, "could not allocate the pixel buffer");

        // Let the compiler know luaL_error doesn't return.
        return NULL;
    }

    uint8_t* aux = pixels;

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            lua_pushvalue(L, get_pixel_index);
            lua_pushinteger(L, x);
            lua_pushinteger(L, y);

            lua_call(L, 2, components);

            for (int i = -components; i <= -1; i++) {
                if (!lua_isinteger(L, i)) {
                    luaL_error(L, "'get_pixel' must return integer components");
                    return NULL;
                }

                *aux++ = lua_tointeger(L, i);
            }

            lua_pop(L, components);
        }
    }

    return (void*)pixels;
}

static void write_to_buffer(void* const context, void* const data, int const size) {
    luaL_Buffer* const buffer = (luaL_Buffer*)context;
    luaL_addlstring(buffer, (char const*)data, (size_t)size);
}

static int l_create(lua_State* const L, Format const format) {
    lua_Integer const width = luaL_checkinteger(L, 1);
    lua_Integer const height = luaL_checkinteger(L, 2);
    lua_Integer const components = luaL_checkinteger(L, 3);

    int const get_pixel_index = format == JPEG ? 5 : 4;

    luaL_checktype(L, get_pixel_index, LUA_TFUNCTION);

    // Validate common arguments.
    if (width <= 0) {
        return luaL_error(L, "invalid width, must be greater than zero");
    }

    if (height <= 0) {
        return luaL_error(L, "invalid height, must be greater than zero");
    }

    if (components < 1 || components > 4) {
        return luaL_error(L, "invalid number of components, must be between 1 and 4 for Y, YA, RGB, or RGBA");
    }

    // Generate the pixels buffer.
    void const* const pixels = get_pixels(L, width, height, components, get_pixel_index);

    // The image will be written to a Lua buffer.
    luaL_Buffer buffer;
    luaL_buffinit(L, &buffer);

    // Create the image.
    int result = 0;

    switch (format) {
        case PNG: {
            int const stride_in_bytes = width * components;
            result = stbi_write_png_to_func(write_to_buffer, (void*)&buffer, width, height, components, pixels, stride_in_bytes);
            break;
        }

        case BMP:
            result = stbi_write_bmp_to_func(write_to_buffer, (void*)&buffer, width, height, components, pixels);
            break;

        case TGA:
            result = stbi_write_tga_to_func(write_to_buffer, (void*)&buffer, width, height, components, pixels);
            break;

        case JPEG: {
            lua_Integer const quality = luaL_checkinteger(L, 4);

            // Validate the quality.
            if (quality < 1 || quality > 100) {
                return luaL_error(L, "invalid quality, must be between 1 and 100");
            }

            result = stbi_write_jpg_to_func(write_to_buffer, (void*)&buffer, width, height, components, pixels, quality);
            break;
        }
    }

    // Free the pixels.
    free((void*)pixels);

    // Error creating image.
    if (result == 0) {
        return luaL_error(L, "error creating image");
    }

    // Success, return a string with the created image.
    luaL_pushresult(&buffer);
    return 1;
}

static int l_png(lua_State* const L) {
    return l_create(L, PNG);
}

static int l_bmp(lua_State* const L) {
    return l_create(L, BMP);
}

static int l_tga(lua_State* const L) {
    return l_create(L, TGA);
}

static int l_jpeg(lua_State* const L) {
    return l_create(L, JPEG);
}

LUAMOD_API int luaopen_imgcreate(lua_State* const L) {
    static const luaL_Reg functions[] = {
        {"png", l_png},
        {"bmp", l_bmp},
        {"tga", l_tga},
        {"jpeg",l_jpeg},
        {NULL, NULL}
    };

    static struct {char const* const name; char const* const value;} const info[] = {
        {"_COPYRIGHT", "Copyright (c) 2020 Andre Leiradella"},
        {"_LICENSE", "MIT"},
        {"_VERSION", "1.0.0"},
        {"_NAME", "imgcreate"},
        {"_URL", "https://github.com/leiradel/luamods/imgcreate"},
        {"_DESCRIPTION", "Writes images to the file system"}
    };

    size_t const functions_count = sizeof(functions) / sizeof(functions[0]) - 1;
    size_t const info_count = sizeof(info) / sizeof(info[0]);

    lua_createtable(L, 0, functions_count + info_count);
    luaL_setfuncs(L, functions, 0);

    for (size_t i = 0; i < info_count; i++) {
        lua_pushstring(L, info[i].value);
        lua_setfield(L, -2, info[i].name);
    }

    return 1;
}
