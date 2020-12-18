#include <lua.h>
#include <lauxlib.h>

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

/*---------------------------------------------------------------------------*/
/* z80.h and z80dasm.h config and inclusion */
#define CHIPS_IMPL
#define CHIPS_ASSERT(c)
#include "z80.h"
#include "z80dasm.h"
/*---------------------------------------------------------------------------*/

static bool l_checkboolean(lua_State* const L, int const index) {
    luaL_checktype(L, index, LUA_TBOOLEAN);
    return lua_toboolean(L, index) == 0 ? false : true;
}

#define Z80_STATE_MT "Z80State"

typedef struct {
    z80_t z80;
    lua_State* L;
    int tick_ref;
    int trap_cb_ref;
}
Z80State;

static Z80State* z80_check(lua_State* const L, int const index) {
    return (Z80State*)luaL_checkudata(L, index, Z80_STATE_MT);
}

static uint64_t tick(int const num_ticks, uint64_t const pins, void* const user_data) {
    Z80State* const self = (Z80State*)user_data;
    lua_State* const L = self->L;

    lua_rawgeti(L, LUA_REGISTRYINDEX, self->tick_ref);
    lua_pushvalue(L, 1);
    lua_pushinteger(L, num_ticks);
    lua_pushinteger(L, pins);

    lua_call(L, 3, 1);

    if (!lua_isinteger(L, -1)) {
        return luaL_error(L, "'tick' must return an integer");
    }

    lua_Integer const new_pins = lua_tointeger(L, -1);
    lua_pop(L, 1);
    return new_pins;
}

static int trap_cb(uint16_t const pc, uint32_t const ticks, uint64_t const pins, void* const trap_user_data) {
    Z80State* const self = (Z80State*)trap_user_data;
    lua_State* const L = self->L;

    lua_rawgeti(L, LUA_REGISTRYINDEX, self->trap_cb_ref);
    lua_pushvalue(L, 1);
    lua_pushinteger(L, pc);
    lua_pushinteger(L, ticks);
    lua_pushinteger(L, pins);

    lua_call(L, 4, 1);

    if (!lua_isinteger(L, -1)) {
        return luaL_error(L, "'trap_cb' must return an integer");
    }

    lua_Integer const trap_id = lua_tointeger(L, -1);
    lua_pop(L, 1);
    return trap_id;
}

static int l_a(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_a(&self->z80));
    return 1;
}

static int l_af(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_af(&self->z80));
    return 1;
}

static int l_af_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_af_(&self->z80));
    return 1;
}

static int l_b(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_b(&self->z80));
    return 1;
}

static int l_bc(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_bc(&self->z80));
    return 1;
}

static int l_bc_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_bc_(&self->z80));
    return 1;
}

static int l_c(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_c(&self->z80));
    return 1;
}

static int l_d(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_d(&self->z80));
    return 1;
}

static int l_de(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_de(&self->z80));
    return 1;
}

static int l_de_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_de_(&self->z80));
    return 1;
}

static int l_e(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_e(&self->z80));
    return 1;
}

static int l_ei_pending(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushboolean(L, z80_ei_pending(&self->z80));
    return 1;
}

static int l_exec(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const ticks = luaL_checkinteger(L, 2);

    self->L = L;
    uint32_t const executed_ticks = z80_exec(&self->z80, ticks);
    self->L = NULL;

    lua_pushinteger(L, executed_ticks);
    return 1;
}

static int l_f(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_f(&self->z80));
    return 1;
}

static int l_fa(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_fa(&self->z80));
    return 1;
}

static int l_fa_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_fa_(&self->z80));
    return 1;
}

static int l_h(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_h(&self->z80));
    return 1;
}

static int l_hl(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_hl(&self->z80));
    return 1;
}

static int l_hl_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_hl_(&self->z80));
    return 1;
}

static int l_i(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_i(&self->z80));
    return 1;
}

static int l_iff1(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushboolean(L, z80_iff1(&self->z80));
    return 1;
}

static int l_iff2(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushboolean(L, z80_iff2(&self->z80));
    return 1;
}

static int l_im(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_im(&self->z80));
    return 1;
}

static int l_ix(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_ix(&self->z80));
    return 1;
}

static int l_iy(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_iy(&self->z80));
    return 1;
}

static int l_l(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_l(&self->z80));
    return 1;
}

static int l_opdone(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushboolean(L, z80_opdone(&self->z80));
    return 1;
}

static int l_pc(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_pc(&self->z80));
    return 1;
}

static int l_r(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_r(&self->z80));
    return 1;
}

static int l_reset(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    z80_reset(&self->z80);
    return 0;
}

static int l_set_a(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_a(&self->z80, value);
    return 1;
}

static int l_set_af(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_af(&self->z80, value);
    return 1;
}

static int l_set_af_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_af_(&self->z80, value);
    return 1;
}

static int l_set_b(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_b(&self->z80, value);
    return 1;
}

static int l_set_bc(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_bc(&self->z80, value);
    return 1;
}

static int l_set_bc_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_bc_(&self->z80, value);
    return 1;
}

static int l_set_c(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_c(&self->z80, value);
    return 1;
}

static int l_set_d(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_d(&self->z80, value);
    return 1;
}

static int l_set_de(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_de(&self->z80, value);
    return 1;
}

static int l_set_de_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_de_(&self->z80, value);
    return 1;
}

static int l_set_e(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_e(&self->z80, value);
    return 1;
}

static int l_set_ei_pending(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    bool const value = l_checkboolean(L, 2);
    z80_set_ei_pending(&self->z80, value);
    return 1;
}

static int l_set_f(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_f(&self->z80, value);
    return 1;
}

static int l_set_fa(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_fa(&self->z80, value);
    return 1;
}

static int l_set_fa_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_fa_(&self->z80, value);
    return 1;
}

static int l_set_h(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_h(&self->z80, value);
    return 1;
}

static int l_set_hl(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_hl(&self->z80, value);
    return 1;
}

static int l_set_hl_(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_hl_(&self->z80, value);
    return 1;
}

static int l_set_i(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_i(&self->z80, value);
    return 1;
}

static int l_set_iff1(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    bool const value = l_checkboolean(L, 2);
    z80_set_iff1(&self->z80, value);
    return 1;
}

static int l_set_iff2(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = l_checkboolean(L, 2);
    z80_set_iff2(&self->z80, value);
    return 1;
}

static int l_set_im(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_im(&self->z80, value);
    return 1;
}

static int l_set_ix(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_ix(&self->z80, value);
    return 1;
}

static int l_set_iy(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_iy(&self->z80, value);
    return 1;
}

static int l_set_l(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_l(&self->z80, value);
    return 1;
}

static int l_set_pc(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_pc(&self->z80, value);
    return 1;
}

static int l_set_r(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_r(&self->z80, value);
    return 1;
}

static int l_set_sp(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_sp(&self->z80, value);
    return 1;
}

static int l_set_wz(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_Integer const value = luaL_checkinteger(L, 2);
    z80_set_wz(&self->z80, value);
    return 1;
}

static int l_sp(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_sp(&self->z80));
    return 1;
}

static int l_trap_cb(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);

    if (self->trap_cb_ref != LUA_NOREF) {
        luaL_unref(L, LUA_REGISTRYINDEX, self->trap_cb_ref);
        self->trap_cb_ref = LUA_NOREF;

        z80_trap_cb(&self->z80, NULL, NULL);
    }

    if (lua_type(L, 2) != LUA_TNIL) {
        luaL_checktype(L, 2, LUA_TFUNCTION);
        lua_pushvalue(L, 2);
        self->trap_cb_ref = luaL_ref(L, LUA_REGISTRYINDEX);

        z80_trap_cb(&self->z80, trap_cb, (void*)self);
    }

    return 1;
}

static int l_trap_id(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, self->z80.trap_id);
    return 1;
}

static int l_wz(lua_State* const L) {
    Z80State* const self = z80_check(L, 1);
    lua_pushinteger(L, z80_wz(&self->z80));
    return 1;
}

static int l_gc(lua_State* const L) {
    Z80State* const self = (Z80State*)lua_touserdata(L, 1);
    luaL_unref(L, LUA_REGISTRYINDEX, self->tick_ref);

    if (self->trap_cb_ref != LUA_NOREF) {
        luaL_unref(L, LUA_REGISTRYINDEX, self->trap_cb_ref);
    }

    return 0;
}

static int l_init(lua_State* const L) {
    luaL_checktype(L, 1, LUA_TFUNCTION);

    Z80State* const self = (Z80State*)lua_newuserdata(L, sizeof(Z80State));

    z80_init(&self->z80, &(z80_desc_t){
        .tick_cb = tick,
        .user_data = (void*)self
    });

    lua_pushvalue(L, 1);
    self->tick_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    self->trap_cb_ref = LUA_NOREF;
    self->L = NULL;

    if (luaL_newmetatable(L, Z80_STATE_MT) != 0) {
        static luaL_Reg const methods[] = {
            {"a", l_a},
            {"af", l_af},
            {"af_", l_af_},
            {"b", l_b},
            {"bc", l_bc},
            {"bc_", l_bc_},
            {"c", l_c},
            {"d", l_d},
            {"de", l_de},
            {"de_", l_de_},
            {"e", l_e},
            {"ei_pending", l_ei_pending},
            {"exec", l_exec},
            {"f", l_f},
            {"fa", l_fa},
            {"fa_", l_fa_},
            {"h", l_h},
            {"hl", l_hl},
            {"hl_", l_hl_},
            {"i", l_i},
            {"iff1", l_iff1},
            {"iff2", l_iff2},
            {"im", l_im},
            {"ix", l_ix},
            {"iy", l_iy},
            {"l", l_l},
            {"opdone", l_opdone},
            {"pc", l_pc},
            {"r", l_r},
            {"reset", l_reset},
            {"set_a", l_set_a},
            {"set_af", l_set_af},
            {"set_af_", l_set_af_},
            {"set_b", l_set_b},
            {"set_bc", l_set_bc},
            {"set_bc_", l_set_bc_},
            {"set_c", l_set_c},
            {"set_d", l_set_d},
            {"set_de", l_set_de},
            {"set_de_", l_set_de_},
            {"set_e", l_set_e},
            {"set_ei_pending", l_set_ei_pending},
            {"set_f", l_set_f},
            {"set_fa", l_set_fa},
            {"set_fa_", l_set_fa_},
            {"set_h", l_set_h},
            {"set_hl", l_set_hl},
            {"set_hl_", l_set_hl_},
            {"set_i", l_set_i},
            {"set_iff1", l_set_iff1},
            {"set_iff2", l_set_iff2},
            {"set_im", l_set_im},
            {"set_ix", l_set_ix},
            {"set_iy", l_set_iy},
            {"set_l", l_set_l},
            {"set_pc", l_set_pc},
            {"set_r", l_set_r},
            {"set_sp", l_set_sp},
            {"set_wz", l_set_wz},
            {"sp", l_sp},
            {"trap_cb", l_trap_cb},
            {"trap_id", l_trap_id},
            {"wz", l_wz}
        };

        luaL_newlib(L, methods);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, l_gc);
        lua_setfield(L, -2, "__gc");
    }

    lua_setmetatable(L, -2);
    return 1;
}

static int l_make_pins(lua_State* const L) {
    lua_Integer const ctrl = luaL_checkinteger(L, 1);
    lua_Integer const addr = luaL_checkinteger(L, 2);
    lua_Integer const data = luaL_checkinteger(L, 3);

    lua_Integer const pins = Z80_MAKE_PINS(ctrl, addr, data);
    lua_pushinteger(L, pins);
    return 1;
}

static int l_get_addr(lua_State* const L) {
    lua_Integer const pins = luaL_checkinteger(L, 1);
    lua_Integer const addr = Z80_GET_ADDR(pins);
    lua_pushinteger(L, addr);
    return 1;
}

static int l_set_addr(lua_State* const L) {
    lua_Integer const pins = luaL_checkinteger(L, 1);
    lua_Integer const addr = luaL_checkinteger(L, 2);

    lua_Integer new_pins = pins;
    Z80_SET_ADDR(new_pins, addr);
    lua_pushinteger(L, new_pins);
    return 1;
}

static int l_get_data(lua_State* const L) {
    lua_Integer const pins = luaL_checkinteger(L, 1);
    lua_Integer const data = Z80_GET_DATA(pins);
    lua_pushinteger(L, data);
    return 1;
}

static int l_set_data(lua_State* const L) {
    lua_Integer const pins = luaL_checkinteger(L, 1);
    lua_Integer const data = luaL_checkinteger(L, 2);

    lua_Integer new_pins = pins;
    Z80_SET_DATA(new_pins, data);
    lua_pushinteger(L, new_pins);
    return 1;
}

static int l_get_wait(lua_State* const L) {
    lua_Integer const pins = luaL_checkinteger(L, 1);
    lua_Integer const wait = Z80_GET_WAIT(pins);
    lua_pushinteger(L, wait);
    return 1;
}

static int l_set_wait(lua_State* const L) {
    lua_Integer const pins = luaL_checkinteger(L, 1);
    lua_Integer const wait = luaL_checkinteger(L, 2);

    lua_Integer new_pins = pins;
    Z80_SET_WAIT(new_pins, wait);
    lua_pushinteger(L, new_pins);
    return 1;
}

typedef struct {
    int input_cb_index;
    lua_State* L;
    luaL_Buffer B;
    int count;
    uint8_t bytes[5];
}
Z80DasmState;

static void info(uint8_t const* const opcode, uint8_t* const cycles, uint16_t* const flags) {
    // 64 is for DJNZ: 13 when it jumps, 8 when it doesn't.
    // 65 is for JR cc: 12 when it jumps, 7 when it doesn't.
    // 66 is for RET cc: 11 when it returns, 5 when it doesn't.
    // 67 is for CALL cc: 17 when it jumps, 10 when it doesn't.
    // 68 is for block transfers: 21 when it repeats, 16 when it doesn't.
    static uint8_t const cycles_main[256] = {
         4, 10,  7,  6,  4,  4,  7,  4,  4, 11,  7,  6,  4,  4,  7,  4,
        64, 10,  7,  6,  4,  4,  7,  4, 12, 11,  7,  6,  4,  4,  7,  4,
        65, 10, 16,  6,  4,  4,  7,  4, 65, 11, 16,  6,  4,  4,  7,  4,
        65, 10, 13,  6, 11, 11, 10,  4, 65, 11, 13,  6,  4,  4,  7,  4,
         4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
         4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
         4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
         7,  7,  7,  7,  7,  7,  4,  7,  4,  4,  4,  4,  4,  4,  7,  4,
         4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
         4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
         4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
         4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
        66, 10, 10, 10, 67, 11,  7, 11, 66, 10, 10,  0, 67, 17,  7, 11,
        66, 10, 10, 11, 67, 11,  7, 11, 66,  4, 10, 11, 67,  0,  7, 11,
        66, 10, 10, 19, 67, 11,  7, 11, 66,  4, 10,  4, 67,  0,  7, 11,
        66, 10, 10,  4, 67, 11,  7, 11, 66,  6, 10,  4, 67,  0,  7, 11,
    };

    static uint8_t const cycles_ed[128] = {
        12, 12, 15, 20,  8, 14,  8,  9, 12,  8, 15,  8,  8, 14,  8,  9,
        12,  8, 15,  8,  8, 14,  8,  9, 12,  8, 15,  8,  8, 14,  8,  9,
        12,  8, 15,  8,  8, 14,  8, 18, 12,  8, 15,  8,  8, 14,  8, 18,
        12,  8, 15,  8,  8, 14,  8,  8, 12,  8, 15,  8,  8, 14,  8,  8,
         8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
         8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
        16, 16, 16, 16,  8,  8,  8,  8, 16, 16, 16, 16,  8,  8,  8,  8,
        68, 68, 68, 68,  8,  8,  8,  8, 68, 68, 68, 68,  8,  8,  8,  8,
    };

    static uint8_t const cycles_ddfd[256] = {
         0,  0,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,
         0,  0,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,
         0, 14, 20, 10,  8,  8, 11,  0,  0, 15, 20, 10,  8,  8, 11,  0,
         0,  0,  0,  0, 23, 23, 19,  0,  0, 15,  0,  0,  0,  0,  0,  0,
         0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
         0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
         0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
        19, 19, 19, 19, 19, 19,  0, 19,  0,  0,  0,  0,  8,  8, 19,  0,
         0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
         0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
         0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
         0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
         0, 14,  0, 23,  0, 15,  0,  0,  0,  8,  0,  0,  0,  0,  0,  0,
         0,  0,  0,  0,  0,  0,  0,  0,  0, 10,  0,  0,  0,  0,  0,  0,
    };

    // Two bits per flag, in the following order (MSB to LSB): SZ5H3PNV
    // 0b00: flag is unchanged
    // 0b01: flag is set
    // 0b10: flag is reset
    // 0b11: flag is changed depending on the CPU state
    static uint16_t const flags_main[256] = {
        0x0000, 0x0000, 0x0000, 0x0000, 0xfffc, 0xfffc, 0x0000, 0x0ecb, 
        0xffff, 0x0fcb, 0x0000, 0x0000, 0xfffc, 0xfffc, 0x0000, 0x0ecb, 
        0x0000, 0x0000, 0x0000, 0x0000, 0xfffc, 0xfffc, 0x0000, 0x0ecb, 
        0x0000, 0x0fcb, 0x0000, 0x0000, 0xfffc, 0xfffc, 0x0000, 0x0ecb, 
        0x0000, 0x0000, 0x0000, 0x0000, 0xfffc, 0xfffc, 0x0000, 0xfff3, 
        0x0000, 0x0fcb, 0x0000, 0x0000, 0xfffc, 0xfffc, 0x0000, 0x0dc4, 
        0x0000, 0x0000, 0x0000, 0x0000, 0xfffc, 0xfffc, 0x0000, 0x0ec9, 
        0x0000, 0x0fcb, 0x0000, 0x0000, 0xfffc, 0xfffc, 0x0000, 0x0fcb, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 
        0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 
        0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 
        0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 
        0xfdfa, 0xfdfa, 0xfdfa, 0xfdfa, 0xfdfa, 0xfdfa, 0xfdfa, 0xfdfa, 
        0xfefa, 0xfefa, 0xfefa, 0xfefa, 0xfefa, 0xfefa, 0xfefa, 0xfefa, 
        0xfefa, 0xfefa, 0xfefa, 0xfefa, 0xfefa, 0xfefa, 0xfefa, 0xfefa, 
        0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xffff, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xffff, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xffff, 0x0000, 
        0x0000, 0x0000, 0x0000, 0xfef8, 0x0000, 0x0000, 0xffff, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xfdfa, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xfefa, 0x0000, 
        0x0000, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0xfefa, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xffff, 0x0000, 
    };

    static uint16_t const flags_ed[128] = {
        0xfef8, 0x0000, 0xffff, 0x0000, 0xfff7, 0x0000, 0x0000, 0x0000, 
        0xfef8, 0x0000, 0xffff, 0x0000, 0xfff7, 0x0000, 0x0000, 0x0000, 
        0xfef8, 0x0000, 0xffff, 0x0000, 0xfff7, 0x0000, 0x0000, 0xfef8, 
        0xfef8, 0x0000, 0xffff, 0x0000, 0xfff7, 0x0000, 0x0000, 0xfef8, 
        0xfef8, 0x0000, 0xffff, 0x0000, 0xfff7, 0x0000, 0x0000, 0xfef8, 
        0xfef8, 0x0000, 0xffff, 0x0000, 0xfff7, 0x0000, 0x0000, 0xfef8, 
        0xfef8, 0x0000, 0xffff, 0x0000, 0xfff7, 0x0000, 0x0000, 0x0000, 
        0xfef8, 0x0000, 0xffff, 0x0000, 0xfff7, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0ef8, 0xfff4, 0xffff, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0ef8, 0xfff4, 0xffff, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0ef8, 0xfff4, 0xffff, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 
        0x0ef8, 0xfff4, 0xffff, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 
    };

    if (opcode[0] == 0xcb) {
        // Bit instructions, all shift and rotate instructions affect the flags
        // in the same way. Same thing for all bit test instructions. Set and
        // reset instructions don't affect the flags.
        uint8_t const op = opcode[1];
        *flags = op < 0x40 ? 0xfefb : op < 0x80 ? 0xfdf8 : 0x0000;
    }
    else if (opcode[0] == 0xed) {
        // Valid extended instructions change the flags according to the
        // flags_ed table. Invalid ones are NOPs and don't change the flags.
        uint8_t const op = opcode[1] - 0x40;
        *flags = (op < 0x80) ? flags_ed[op] : 0x0000;
    }
    else if (opcode[0] == 0xdd || opcode[0] == 0xfd) {
        // IX or IY.
        if (opcode[1] == 0xcb) {
            // The index prefix don't change how flags are affected by the bit
            // instructions.
            uint8_t const op = opcode[3];
            *flags = op < 0x40 ? 0xfefb : op < 0x80 ? 0xfdf8 : 0x0000;
        }
        else if (opcode[1] == 0xed || opcode[1] == 0xdd || opcode[1] == 0xfd) {
            // A prefix followed by ED or by another prefix executes as a NOP,
            // which doesn't affect the flags.
            *flags = 0x0000;
        }
        else if (cycles_ddfd[opcode[1]] == 0) {
            // A prefix followed by an instruction that doesn't use IX or IY
            // is also executed as a NOP.
            *flags = 0x0000;
        }
        else {
            // Use the flags_main table since the prefix will affect the flags
            // in the same way as the unprefixed instructions.
            *flags = flags_main[opcode[1]];
        }
    }
    else {
        // Use the flags_main table directly.
        *flags = flags_main[opcode[0]];
    }

    if (opcode[0] == 0xcb) {
        // Bit instructions.
        uint8_t const op = opcode[1] & 0xc7;

        if (op == 0x06 || op == 0x86 || op == 0xc6) {
            // Shift, rotate, set, and reset instructions that use (HL) take
            // 15 cycles.
            *cycles = 15;
        } else if (op == 0x46) {
            // Bit test instructions that use (HL) take 12 cycles.
            *cycles = 12;
        } else {
            // All other bit instructions take 8 cycles.
            *cycles = 8;
        }
    }
    else if (opcode[0] == 0xed) {
        // Valid extended instructions consume cycles according to the
        // cycles_ed table. Invalid ones are NOPs that take 8 cycles.
        uint8_t const op = opcode[1] - 0x40;
        *cycles = (op < 0x80) ? cycles_ed[op] : 8;
    }
    else if (opcode[0] == 0xdd || opcode[0] == 0xfd) {
        // IX or IY.
        if (opcode[1] == 0xcb) {
            // Bit instructions.
            uint8_t const op = opcode[3] & 0xc0;

            if (op == 0x40) {
                // Bit test instructions take 20 cycles.
                *cycles = 20;
            } else {
                // All other bit instructions take 23 cycles.
                *cycles = 23;
            }
        }
        else if (opcode[1] == 0xed || opcode[1] == 0xdd || opcode[1] == 0xfd) {
            // A prefix followed by ED or by another prefix executes as a NOP,
            // which takes 4 cycles.
            *cycles = 4;
        }
        else if (cycles_ddfd[opcode[1]] == 0) {
            // A prefix followed by an instruction that doesn't use IX or IY
            // is also executed as a NOP.
            *cycles = 4;
        }
        else {
            // Use the cycles_ddfd table for valid uses of the prefix.
            *cycles = cycles_ddfd[opcode[1]];
        }
    }
    else {
        // Use the cycles_main table directly.
        *cycles = cycles_main[opcode[0]];
    }
}

static uint8_t in_cb(void* const user_data) {
    Z80DasmState* const ud = (Z80DasmState*)user_data;

    // Push and call the input callback.
    lua_pushvalue(ud->L, ud->input_cb_index);
    lua_call(ud->L, 0, 1);

    // Oops.
    if (!lua_isinteger(ud->L, -1)) {
        return luaL_error(ud->  L, "'dasm' input callback must return an integer");
    }

    // Get the returned byte, save it, remove it from the stack, and return.
    uint8_t const byte = (uint8_t)lua_tointeger(ud->L, -1);
    ud->bytes[ud->count++] = byte;
    lua_pop(ud->L, 1);
    return byte;
}

static void out_cb(char const c, void* const user_data) {
    // Just add the character to the buffer.
    Z80DasmState* const ud = (Z80DasmState*)user_data;
    luaL_addchar(&ud->B, c);
}

static int flag_is(lua_State* const L, uint8_t const condition) {
    uint16_t const flags = *(uint16_t*)luaL_checkudata(L, 1, "z80flags");

    size_t length = 0;
    char const* const flag = luaL_checklstring(L, 2, &length);

    if (length != 1) {
unknown:
        return luaL_error(L, "unknown Z80 flag %s", flag);
    }

    int result = 0;

    switch (*flag) {
        case 'S': case 's': result = ((flags >> 14) & 3) == condition; break;
        case 'Z': case 'z': result = ((flags >> 12) & 3) == condition; break;
        case 'Y': case 'y': case '5': result = ((flags >> 10) & 3) == condition; break;
        case 'H': case 'h': result = ((flags >>  8) & 3) == condition; break;
        case 'X': case 'x': case '3': result = ((flags >>  6) & 3) == condition; break;
        case 'P': case 'p': result = ((flags >>  4) & 3) == condition; break;
        case 'N': case 'n': result = ((flags >>  2) & 3) == condition; break;
        case 'C': case 'c': result = ((flags >>  0) & 3) == condition; break;
        default: goto unknown;
    }

    lua_pushboolean(L, result);
    return 1;
}

static int l_flag_unchanged(lua_State* const L) {
    return flag_is(L, 0);
}

static int l_flag_set(lua_State* const L) {
    return flag_is(L, 1);
}

static int l_flag_reset(lua_State* const L) {
    return flag_is(L, 2);
}

static int l_flag_changed(lua_State* const L) {
    return flag_is(L, 3);
}

static int l_flag_tostring(lua_State* const L) {
    static char const statuses[] = "-10*";

    uint16_t const flags = *(uint16_t*)luaL_checkudata(L, 1, "z80flags");
    char result[8];

    for (int i = 0; i < 8; i++) {
        int const shift_amount = 14 - i * 2;
        uint8_t const flag_status = (flags >> shift_amount) & 3;
        result[i] = statuses[flag_status];
    }

    lua_pushlstring(L, result, 8);
    return 1;
}

static int l_dasm(lua_State* L) {
    Z80DasmState ud;
    ud.input_cb_index = 1;

    // Get an optional address in the first argument.
    uint16_t address = 0;

    if (lua_isinteger(L, 1)) {
        address = (uint16_t)lua_tointeger(L, 1);
        ud.input_cb_index = 2;
    }

    // Make sure we have an input callback.
    luaL_checktype(L, ud.input_cb_index, LUA_TFUNCTION);

    // Prepare the userdata.
    ud.L = L;
    luaL_buffinitsize(L, &ud.B, 32);
    ud.count = 0;

    // Disassemble the instruction.
    uint16_t const next_address = z80dasm_op(address, in_cb, out_cb, (void*)&ud);

    // Get cycle and flags information.
    uint8_t cycles = 0;
    uint16_t flags = 0;
    info(ud.bytes, &cycles, &flags);

    // Push the results: disassembled instruction, next address.
    luaL_pushresult(&ud.B);
    lua_pushinteger(L, next_address);

    // Push affected flags.
    uint16_t* const flags_ud = (uint16_t*)lua_newuserdata(L, sizeof(uint16_t));
    *flags_ud = flags;

    // Set the flags userdata's metatable.
    if (luaL_newmetatable(L, "z80flags")) {
        static const luaL_Reg methods[] = {
            {"unchanged", l_flag_unchanged},
            {"set", l_flag_set},
            {"reset", l_flag_reset},
            {"changed", l_flag_changed},
            {NULL, NULL}
        };

        luaL_newlib(L, methods);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, l_flag_tostring);
        lua_setfield(L, -2, "__tostring");
    }

    lua_setmetatable(L, -2);

    // Push cycles.
    switch (cycles) {
        case 64: lua_pushinteger(L, 13); lua_pushinteger(L, 8); break;
        case 65: lua_pushinteger(L, 12); lua_pushinteger(L, 7); break;
        case 66: lua_pushinteger(L, 11); lua_pushinteger(L, 5); break;
        case 67: lua_pushinteger(L, 17); lua_pushinteger(L, 10); break;
        case 68: lua_pushinteger(L, 21); lua_pushinteger(L, 16); break;

        default: lua_pushinteger(L, cycles); lua_pushnil(L); break;
    }

    return 5;
}

LUAMOD_API int luaopen_z80(lua_State* const L) {
    static const luaL_Reg functions[] = {
        {"init", l_init},
        {"MAKE_PINS", l_make_pins},
        {"GET_ADDR", l_get_addr},
        {"SET_ADDR", l_set_addr},
        {"GET_DATA", l_get_data},
        {"SET_DATA", l_set_data},
        {"GET_WAIT", l_get_wait},
        {"SET_WAIT", l_set_wait},
        {"dasm", l_dasm},
        {NULL, NULL}
    };

    static struct {char const* const name; uint64_t const value;} const constants[] = {
        {"A0", Z80_A0},
        {"A1", Z80_A1},
        {"A2", Z80_A2},
        {"A3", Z80_A3},
        {"A4", Z80_A4},
        {"A5", Z80_A5},
        {"A6", Z80_A6},
        {"A7", Z80_A7},
        {"A8", Z80_A8},
        {"A9", Z80_A9},
        {"A10", Z80_A10},
        {"A11", Z80_A11},
        {"A12", Z80_A12},
        {"A13", Z80_A13},
        {"A14", Z80_A14},
        {"A15", Z80_A15},
        {"D0", Z80_D0},
        {"D1", Z80_D1},
        {"D2", Z80_D2},
        {"D3", Z80_D3},
        {"D4", Z80_D4},
        {"D5", Z80_D5},
        {"D6", Z80_D6},
        {"D7", Z80_D7},
        {"M1", Z80_M1},
        {"MREQ", Z80_MREQ},
        {"IORQ", Z80_IORQ},
        {"RD", Z80_RD},
        {"WR", Z80_WR},
        {"RFSH", Z80_RFSH},
        {"CTRL_MASK", Z80_CTRL_MASK},
        {"HALT", Z80_HALT},
        {"INT", Z80_INT},
        {"NMI", Z80_NMI},
        {"WAIT0", Z80_WAIT0},
        {"WAIT1", Z80_WAIT1},
        {"WAIT2", Z80_WAIT2},
        {"WAIT_SHIFT", Z80_WAIT_SHIFT},
        {"WAIT_MASK", Z80_WAIT_MASK},
        {"IEIO", Z80_IEIO},
        {"RETI", Z80_RETI},
        {"PIN_MASK", Z80_PIN_MASK}
    };

    static struct {char const* const name; char const* const value;} const info[] = {
        {"_COPYRIGHT", "Copyright (c) 2020 Andre Leiradella"},
        {"_LICENSE", "MIT"},
        {"_VERSION", "1.0.0"},
        {"_NAME", "z80"},
        {"_URL", "https://github.com/leiradel/luamods/z80"},
        {"_DESCRIPTION", "Bindings for Andre Weissflog's Z80 emulator"}
    };

    size_t const functions_count = sizeof(functions) / sizeof(functions[0]) - 1;
    size_t const constants_count = sizeof(constants) / sizeof(constants[0]);
    size_t const info_count = sizeof(info) / sizeof(info[0]);

    lua_createtable(L, 0, functions_count + constants_count + info_count);
    luaL_setfuncs(L, functions, 0);

    for (size_t i = 0; i < constants_count; i++) {
        lua_pushinteger(L, constants[i].value);
        lua_setfield(L, -2, constants[i].name);
    }

    for (size_t i = 0; i < info_count; i++) {
        lua_pushstring(L, info[i].value);
        lua_setfield(L, -2, info[i].name);
    }

    // Enrich z80.dasm.
    int const load_res = luaL_loadstring(L,
        "return function(z80)\n"
        "    local dasm0 = z80.dasm\n"
        "\n"
        "    z80.dasm = function(pc, input_cb, start_index)\n"
        "        local dasm\n"
        "\n"
        "        if type(pc) == 'number' then\n"
        "            dasm = function(input_cb) return dasm0(pc, input_cb) end\n"
        "        else\n"
        "            dasm = function(input_cb) return dasm0(input_cb) end\n"
        "            start_index = input_cb\n"
        "            input_cb = pc\n"
        "        end\n"
        "\n"
        "        if type(input_cb) == 'string' then\n"
        "            local index = start_index or 1\n"
        "\n"
        "            return dasm(function()\n"
        "                local byte = input_cb:byte(index)\n"
        "                index = index + 1\n"
        "                return byte\n"
        "            end)\n"
        "        elseif type(input_cb) == 'table' then\n"
        "            local index = start_index or 1\n"
        "\n"
        "            return dasm(function()\n"
        "                local byte = input_cb[index]\n"
        "                index = index + 1\n"
        "                return byte\n"
        "            end)\n"
        "        else\n"
        "            return dasm(input_cb)\n"
        "        end\n"
        "    end\n"
        "end\n"
    );

    if (load_res != LUA_OK) {
        return lua_error(L);
    }

    // Call the chunk to get the function, and then call it with the module.
    lua_call(L, 0, 1);
    lua_pushvalue(L, -2);
    lua_call(L, 1, 0);

    return 1;
}
