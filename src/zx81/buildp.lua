local pasmo = arg[1] or '../../../pasmo-0.5.3/pasmo'
local zxtext2p = arg[2] or '../../etc/zxtext2p'

-- Assemble
assert(os.execute(string.format('%s --bin zx81.asm zx81asm.bin zx81.lst', pasmo)))

-- Get information from the assembled file
local f = assert(io.open('zx81.lst', 'rb'))
local main, message

for line in f:lines() do
    local symbol, value = line:match('([^%s]+)%s+EQU%s+([%x]+)H')
    print(symbol, value, line)

    if symbol == 'main' then
        main = tonumber(value, 16)
    elseif symbol == 'qrc1_message' then
        message = tonumber(value, 16)
    end
end

f:close()

-- Get the size of the assembled file
local f = assert(io.open('zx81asm.bin', 'rb'))
local size = #f:read('*a')
f:close()

-- Create the BASIC list
local f = assert(io.open('zx81.bas', 'r'))
local bas = f:read('*a')
f:close()

bas = bas:gsub('%${(.-)}', {
    ASM = string.rep('.', size),
    MESSAGE = message,
    MAIN = main
})

-- Generate the P file from the BASIC list
local f = assert(io.open('temp.bas', 'w'))
f:write(bas)
f:close()

assert(os.execute(string.format('%s -o zx81bas.bin temp.bas', zxtext2p)))

-- Read and combine the generated files
local f = assert(io.open('zx81asm.bin', 'rb'))
local asm = f:read('*a')
f:close()

local f = assert(io.open('zx81bas.bin', 'rb'))
local bas = f:read('*a')
f:close()

local pfile = bas:sub(1, 0x79) .. asm .. bas:sub(0x79 + size + 1, -1)
local f = assert(io.open('zx81.p', 'wb'))
f:write(pfile)
f:close()

-- Clean up
os.remove('zx81asm.bin')
os.remove('zx81bas.bin')
os.remove('zx81.lst')
os.remove('temp.bas')
