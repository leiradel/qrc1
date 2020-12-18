local z80 = require 'z80'
local imgcreate = require 'imgcreate'

local CMD_PORT =         0xde
local CMD_PIXEL_LEFT =   0
local CMD_PIXEL_RIGHT =  1
local CMD_PIXEL_UP =     2
local CMD_PIXEL_DOWN =   3
local CMD_SET_PIXEL =    4
local CMD_MESSAGE =      5
local CMD_PRINT_WORD =   6
local CMD_INVERT_PIXEL = 7
local CMD_SET_XY =       8

local memory = {}
local done = false

local width, height = 0,0 
local x, y = 0, 0
local pixels = {}

local command; command = function(data)
    if data == CMD_PIXEL_LEFT then
        x = x - 1
    elseif data == CMD_PIXEL_RIGHT then
        x = x + 1
    elseif data == CMD_PIXEL_UP then
        y = y - 1
    elseif data == CMD_PIXEL_DOWN then
        y = y + 1
    elseif data == CMD_SET_PIXEL then
        if x >= width then
            width = x + 1
        end

        if y >= height then
            for i = height, y do
                pixels[i] = {}
            end

            height = y + 1
        end

        pixels[y][x] = true
    elseif data == CMD_MESSAGE then
        local old = command
        local message = ''

        command = function(data)
            if data ~= 0 then
                message = message .. string.char(data)
            else
                print(message)
                command = old
            end
        end
    elseif data == CMD_PRINT_WORD then
        local old = command
        local word, step = 0, 1

        command = function(data)
            if step == 1 then
                word = data
            elseif step == 2 then
                word = word | data << 8
                print(string.format('%04x (%u)', word, word))
                command = old
            end

            step = step + 1
        end
    elseif data == CMD_INVERT_PIXEL then
        if x >= width then
            width = x + 1
        end

        if y >= height then
            for i = height, y do
                pixels[i] = {}
            end

            height = y + 1
        end

        pixels[y][x] = not pixels[y][x]
    elseif data == CMD_SET_XY then
        local old = command
        local step = 1

        command = function(data)
            if step == 1 then
                x = data
            elseif step == 2 then
                y = data
                command = old
            end

            step = step + 1
        end
    end
end

do
    local file = assert(io.open('qrc11.bin', 'rb'))
    local bin = file:read('*a')
    file:close()

    for i = 1, #bin do
        memory[i - 1] = bin:byte(i)
    end
end

local cpu = z80.init(function(cpu, num_ticks, pins)
    done = (pins & z80.HALT) ~= 0

    if (pins & z80.M1) ~= 0 then
        local insn = z80.dasm(cpu:pc(), memory, cpu:pc())
        insn = insn:gsub('(%x%x%x%x)h', function(value) return '0000h' end)
        insn = insn:gsub('IY', 'IX')
        --print(string.format('%s ; A=%02x DE=%04x', insn, cpu:a(), cpu:de()))
    end

    if (pins & z80.MREQ) ~= 0 then
        local address = z80.GET_ADDR(pins)

        if (pins & z80.RD) ~= 0 then
            pins = z80.SET_DATA(pins, memory[address])
        elseif (pins & z80.WR) ~= 0 then
            memory[address] = z80.GET_DATA(pins)

            if address < 0xf000 and cpu:pc() ~= 0x002a then
                --print(string.format('memory[0x%04x] = {data = 0x%02x, pc = 0x%04x} -- %d', address, z80.GET_DATA(pins), cpu:pc(), address - 0x0318))
            end
        end
    elseif (pins & z80.IORQ) ~= 0 then
        local address = z80.GET_ADDR(pins)

        if (address & 0xff) == CMD_PORT and (pins & z80.WR) ~= 0 then
            local data = z80.GET_DATA(pins)
            command(data)
        end
    end

    return pins
end)

while not done do
    cpu:exec(1)
end

--[[for i = 0x0317, 0x0317 + 4095, 16 do
    io.write(string.format('%04x ', i))

    for j = i, i + 15 do
        if j <= 0x0317 + 4095 then
            io.write(string.format(' %02x', memory[j]))
        end
    end

    io.write('   ')

    for j = i, i + 15 do
        if j <= 0x0317 + 4095 then
            io.write(string.format('%c', (memory[j] >= 32 and memory[j] < 127) and memory[j] or string.byte('.')))
        end
    end

    io.write('\n')
end]]

do
    local png = imgcreate.png(width, height, 1, function(x, y)
        return pixels[y][x] and 0x00 or 0xff
    end)

    local file = assert(io.open('qrc11.png', 'wb'))
    file:write(png)
    file:close()
end
