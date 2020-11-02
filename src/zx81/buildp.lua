local zasm = arg[1] or '../../../zasm/Linux/zasm'
local zxtext2p = arg[2] or '../../etc/zxtext2p'

-- Assemble
assert(os.execute(string.format('%s -uwy zx81.asm zx81asm.bin', zasm)))

-- Get information from the assembled file
local f = assert(io.open('zx81.lst', 'rb'))
local main, message, size

for line in f:lines() do
    local symbol, value = line:match('([^%s]-)%s+=%s+%$....%s+=%s+(%d+).*')

    if symbol == 'main' then
        main = tonumber(value)
    elseif symbol == 'qrc1_message' then
        message = tonumber(value)
    elseif symbol == '_size' then
        size = tonumber(value)
    end
end

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
