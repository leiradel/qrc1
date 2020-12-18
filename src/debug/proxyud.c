#include <lua.h>
#include <lauxlib.h>

static int l_new(lua_State* const L) {
    int const top = lua_gettop(L);

    // Create an empty full userdata object.
    lua_newuserdata(L, 0);

    // The first parameter to new is the value that will be associated to the
    // userdata.
    if (top >= 1) {
        lua_pushvalue(L, 1);
        lua_setuservalue(L, -2);
    }

    // The second parameter to new, if present, is the metatable for the
    // userdata.
    if (top >= 2 && lua_type(L, 2) == LUA_TTABLE) {
        lua_pushvalue(L, 2);
        lua_setmetatable(L, -2);
    }

    // Return the userdata object.
    return 1;
}

static int l_get(lua_State* const L) {
    // Check that the first argument is a full userdata.
    luaL_checktype(L, 1, LUA_TUSERDATA);

    // Return the value associated with it.
    lua_getuservalue(L, 1);
    return 1;
}

LUAMOD_API int luaopen_proxyud(lua_State* L) {
    static luaL_Reg const functions[] = {
        {"new", l_new},
        {"get", l_get},
        {NULL,  NULL}
    };

    static struct {char const* const name; char const* const value;} const info[] = {
        {"_COPYRIGHT", "Copyright (c) 2020 Andre Leiradella"},
        {"_LICENSE", "MIT"},
        {"_VERSION", "1.0.0"},
        {"_NAME", "proxyud"},
        {"_URL", "https://github.com/leiradel/luamods/proxyud"},
        {"_DESCRIPTION", "Creates proxy userdata objects"}
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
