local proxyud = require 'proxyud'
local proxyud_new = proxyud.new
local proxyud_get = proxyud.get

-- The metatable for readonly tables.
local constmt = {
    __index = function(ud, key)
        -- Get the table for the userdata.
        local table = proxyud_get(ud)
        -- Get the value in the table.
        local value = table[key]

        -- Return the value if there's one.
        if value ~= nil then
            return value
        end

        -- Unknown key.
        error(string.format('cannot access unknown field \'%s\' in table', key))
    end,

    __newindex = function(ud, key, value)
        -- Const tables don't support assignments.
        error(string.format('cannot assign to field \'%s\' in constant table', key))
    end,

    __add = function(ud, other)    return proxyud_get(ud) + other end,
    __sub = function(ud, other)    return proxyud_get(ud) - other end,
    __mul = function(ud, other)    return proxyud_get(ud) * other end,
    __div = function(ud, other)    return proxyud_get(ud) / other end,
    __mod = function(ud, other)    return proxyud_get(ud) % other end,
    __pow = function(ud, other)    return proxyud_get(ud) ^ other end,
    __unm = function(ud)           return -proxyud_get(ud) end,
    __idiv = function(ud, other)   return proxyud_get(ud) // other end,
    __band = function(ud, other)   return proxyud_get(ud) & other end,
    __bor = function(ud, other)    return proxyud_get(ud) | other end,
    __bxor = function(ud, other)   return proxyud_get(ud) ~ other end,
    __bnot = function(ud)          return ~proxyud_get(ud) end,
    __shl = function(ud, other)    return proxyud_get(ud) << other end,
    __shr = function(ud, other)    return proxyud_get(ud) >> other end,
    __concat = function(ud, other) return proxyud_get(ud) .. other end,
    __len = function(ud)           return #proxyud_get(ud) end,
    __eq = function(ud, other)     return proxyud_get(ud) == other end,
    __lt = function(ud, other)     return proxyud_get(ud) < other end,
    __le = function(ud, other)     return proxyud_get(ud) <= other end,
    __call = function(ud, ...)     return proxyud_get(ud)(...) end
}

-- The metatable for sealed tables.
local sealmt = {
    __index = constmt.__index,

    __newindex = function(ud, key, value)
        -- Get the table for the userdata.
        local table = proxyud_get(ud)

        -- Only assign if the field exists.
        if table[key] ~= nil then
            table[key] = value
            return
        end

        -- Unknown key.
        error(string.format('cannot assign to unknown field \'%s\' in sealed table', key))
    end,

    __add = constmt.__add,
    __sub = constmt.__sub,
    __mul = constmt.__mul,
    __div = constmt.__div,
    __mod = constmt.__mod,
    __pow = constmt.__pow,
    __unm = constmt.__unm,
    __idiv = constmt.__idiv,
    __band = constmt.__band,
    __bor = constmt.__bor,
    __bxor = constmt.__bxor,
    __bnot = constmt.__bnot,
    __shl = constmt.__shl,
    __shr = constmt.__shr,
    __concat = constmt.__concat,
    __len = constmt.__len,
    __eq = constmt.__eq,
    __lt = constmt.__lt,
    __le = constmt.__le,
    __call = constmt.__call
}

local function const(table)
    -- Create an userdata with the table and the constmt metatable.
    local ud = proxyud_new(table, constmt)
    -- Return the userdata proxy.
    return ud
end

local function seal(table)
    local ud = proxyud_new(table, sealmt)
    return ud
end

-- The module.
return const {
    _COPYRIGHT = 'Copyright (c) 2020 Andre Leiradella',
    _LICENSE = 'MIT',
    _VERSION = '1.0.0',
    _NAME = 'proxyud',
    _URL = 'https://github.com/leiradel/luamods/access',
    _DESCRIPTION = 'Creates constant and sealed objects',

    const = const,
    seal = seal
}
