--[[
Reads the listing file produced by the Pasmo assembler and returns a table with
all the symbols in the listing with their values.
]]

return function(path)
    if not path or #path == 0 then
        return nil, 'invalid file path'
    end

    local file, err = io.open(path, 'r')

    if not file then
        return nil, err
    end

    local symbols = {}

    for line in file:lines() do
        local symbol, value = line:match('([^%s]+)%s+EQU%s+(%x+)H')

        if symbol then
            symbols[symbol] = tonumber(value, 16)
        end
    end

    file:close()
    return symbols
end
