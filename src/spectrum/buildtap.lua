local basic_path = arg[1]
local assembly_path = arg[2]
local tap_path = arg[3]
local pasmo = arg[4]
local zmakebas = arg[5]

-- Set up temporary paths.
local tmp_bin_path = 'temp.bin'
local tmp_lst_path = 'temp.lst'
local tmp_bas_path = 'temp.bas'
local tmp_tap1_path = 'temp1.tap'
local tmp_tap2_path = 'temp2.tap'


local function build()
    local lstsym = require 'lstsym'
    local readall = require 'readall'
    local baspp = require 'baspp'
    local writeall = require 'writeall'

    local function execute(format, ...)
        local cmd = string.format(format, ...)
        assert(os.execute(cmd))
    end

    -- Assemble
    execute('%s --tap %s %s %s', pasmo, assembly_path, tmp_tap2_path, tmp_lst_path)

    -- Get symbols from the assembled file.
    local symbols = assert(lstsym(tmp_lst_path))

    -- Create the BASIC list
    local basic = assert(readall(basic_path))
    basic = assert(baspp(basic, symbols))

    -- Generate the TAP file from the BASIC list.
    assert(writeall(tmp_bas_path, basic))
    execute('%s -a 10 -n barcode -o %s %s', zmakebas, tmp_tap1_path, tmp_bas_path)

    -- Read and combine the generated files
    local tap1 = assert(readall(tmp_tap1_path))
    local tap2 = assert(readall(tmp_tap2_path))
    assert(writeall(tap_path, tap1 .. tap2))
end

local ok, err = pcall(build)

-- Clean up
os.remove(tmp_bin_path)
os.remove(tmp_lst_path)
os.remove(tmp_bas_path)
os.remove(tmp_tap1_path)
os.remove(tmp_tap2_path)

if not ok then
    io.stderr:write(string.format('%s\n', err))
    os.exit(1)
end
