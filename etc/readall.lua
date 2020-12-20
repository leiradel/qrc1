return function(path)
    if not path or #path == 0 then
        return nil, 'invalid file path'
    end

    local file, err = io.open(path, 'rb')

    if not file then
        return nil, err
    end

    local contents = file:read('*a')
    file:close()
    return contents
end
