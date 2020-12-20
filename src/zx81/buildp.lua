local basic_path = arg[1]
local assembly_path = arg[2]
local p_path = arg[3]
local pasmo = arg[4]
local zxtext2p = arg[5]

-- Set up temporary paths.
local tmp_bin_path = 'temp.bin'
local tmp_lst_path = 'temp.lst'
local tmp_bas_path = 'temp.bas'
local tmp_p_path = 'temp.p'

local function build()
    local lstsym = require 'lstsym'
    local readall = require 'readall'
    local baspp = require 'baspp'
    local writeall = require 'writeall'

    local function execute(format, ...)
        local cmd = string.format(format, ...)
        assert(os.execute(cmd))
    end

    -- Assemble.
    execute('%s --bin %s %s %s', pasmo, assembly_path, tmp_bin_path, tmp_lst_path)

    -- Get symbols from the assembled file.
    local symbols = assert(lstsym(tmp_lst_path))

    -- Create the BASIC list.
    local basic = assert(readall(basic_path))
    basic = assert(baspp(basic, symbols))

    -- Generate the P file from the BASIC list.
    assert(writeall(tmp_bas_path, basic))
    execute('%s -o %s %s', zxtext2p, tmp_p_path, tmp_bas_path)

    -- Read and combine the generated files.
    local bin = assert(readall(tmp_bin_path))
    local p = assert(readall(tmp_p_path))

    p = p:sub(1, 0x79) .. bin .. p:sub(0x79 + #bin + 1, -1)
    assert(writeall(p_path, p))

    return true
end

local ok, err = pcall(build)

-- Clean up.
os.remove(tmp_bin_path)
os.remove(tmp_lst_path)
os.remove(tmp_bas_path)
os.remove(tmp_p_path)

if not ok then
    io.stderr:write(string.format('%s\n', err))
    os.exit(1)
end
