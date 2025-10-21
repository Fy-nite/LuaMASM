-- Simple LuaASM test runner (no lfs required)
local interp = 'lua interp.lua'
local test_dir = 'tests'

local function parse_expectations(lines)
    local expects = {}
    for _, line in ipairs(lines) do
        local reg, val = line:match('; EXPECT ([%w_]+) ([%d%-]+)')
        if reg and val then
            expects[reg] = tonumber(val)
        end
    end
    return expects
end

local function run_test(file)
    local f = io.open(file, 'r')
    local lines = {}
    for line in f:lines() do table.insert(lines, line) end
    f:close()
    local expects = parse_expectations(lines)
    local output = {}
    local handle = io.popen(interp .. ' ' .. file .. ' 2>&1')
    for line in handle:lines() do table.insert(output, line) end
    handle:close()
    local passed = true
    for reg, val in pairs(expects) do
        local found = false
        for _, out in ipairs(output) do
            if out:match(reg .. ':?%s*' .. val) then found = true break end
        end
        if not found then
            print(file .. ': FAIL (' .. reg .. ' ~= ' .. val .. ')')
            passed = false
        end
    end
    if passed then print(file .. ': PASS') end
    return passed
end

local total, passed = 0, 0
local p = io.popen('ls "'..test_dir..'"')
for file in p:lines() do
    if file:match('%.masm$') then
        total = total + 1
        if run_test(test_dir .. '/' .. file) then passed = passed + 1 end
    end
end
p:close()
print(('Summary: %d/%d tests passed'):format(passed, total))
