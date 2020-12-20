return function(path, contents)
    if not path or #path == 0 then
        return nil, 'invalid file path'
    end

    local file, err = io.open(path, 'wb')

    if not file then
        return nil, err
    end

    file:write(contents)
    file:close()
    return true
end
