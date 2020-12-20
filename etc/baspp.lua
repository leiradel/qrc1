--[[

Preprocess a BASIC source file. Changes:

* `${symbol}` for the corresponding value in the provided symbols file
* `${#symbol}` for the length of the corresponding value in the provided symbols file
* `${#@path}` for the size of the file

]]

local readall = require 'readall'

return function(basic, symbols)
    local errors = {}

    -- Substitute ${#@path} by the size of the file.
    basic = basic:gsub('%${#@(.-)}', function(path)
        local contents, err = readall(path)

        if contents then
            return string.rep('.', #contents)
        else
            errors[#errors + 1] = string.format('error reading from "%s": %s', path, err)
            return ''
        end
    end)

    -- Substitute ${#symbol} by the length of the symbol.
    basic = basic:gsub('%${#(.-)}', function(symbol)
        if symbols[symbol] then
            return string.rep('.', #symbols[symbol])
        else
            errors[#errors + 1] = string.format('symbol not found: %s', symbol)
            return ''
        end
    end)

    -- Substitute ${symbol} by the symbol itself.
    basic = basic:gsub('%${(.-)}', symbols)

    -- Return the result.
    return (#errors == 0 and basic or nil), errors
end
