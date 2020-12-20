local pasmo = arg[1] or '../../../pasmo-0.5.3/pasmo'
local zmakebas = arg[2] or '../../../zmakebas/zmakebas'

local function execute(format, ...)
    local cmd = string.format(format, ...)
    print(cmd)
    assert(os.execute(cmd))
end

-- Assemble
execute(string.format('%s --tap qrc11.asm zxsasm.tap zxs11.lst', pasmo))

-- Get information from the assembled file
local f = assert(io.open('zxs11.lst', 'rb'))
local main, message

for line in f:lines() do
    local symbol, value = line:match('([^%s]+)%s+EQU%s+([%x]+)H')

    if symbol == 'main' then
        main = tonumber(value, 16)
    elseif symbol == 'qrc11_message' then
        message = tonumber(value, 16)
    end
end

f:close()

-- Create the BASIC list
local f = assert(io.open('qrc11.bas', 'r'))
local bas = f:read('*a')
f:close()

bas = bas:gsub('%${(.-)}', {
    MESSAGE = message,
    MAIN = main,
    RAMTOP = main - 1
})

-- Generate the P file from the BASIC list
local f = assert(io.open('temp.bas', 'w'))
f:write(bas)
f:close()

execute(string.format('%s -a 10 -n qrc11 -o zxsbas.tap temp.bas', zmakebas))

-- Read and combine the generated files
local f = assert(io.open('zxsbas.tap', 'rb'))
local bas = f:read('*a')
f:close()

local f = assert(io.open('zxsasm.tap', 'rb'))
local asm = f:read('*a')
f:close()

local tap = bas .. asm
local f = assert(io.open('qrc11.tap', 'wb'))
f:write(tap)
f:close()

-- Clean up
os.remove('zxsasm.tap')
os.remove('zxsbas.tap')
os.remove('zxs11.lst')
os.remove('temp.bas')
