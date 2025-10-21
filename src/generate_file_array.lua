local files = {
    "src/custom-mni.lua",
    "src/debugger.lua",
    "src/interp.lua",
    "src/tui.lua",
    "root/MNI/datastructures.lua",
    "root/MNI/debug.lua",
    "root/MNI/file.lua",
    "root/MNI/filesystem.lua",
    "root/MNI/io.lua",
    "root/MNI/macro.lua",
    "root/MNI/math.lua",
    "root/MNI/memory.lua",
    "root/MNI/network.lua",
    "root/MNI/state.lua",
    "root/MNI/string.lua",
    "root/MNI/stringoperations.lua",
    "root/MNI/system.lua",
    "root/MNI/util.lua",
    "root/stdio/print.masm",
    "tests/test_macro.masm",
    "tests/test_state.masm"
}

local fileContents = {}

for _, file in ipairs(files) do
    local f = io.open(file, "r")
    if f then
        fileContents[file] = f:read("*all")
        f:close()
    else
        print("Warning: Could not open " .. file)
    end
end

print("local fileArray = {")
for path, content in pairs(fileContents) do
    print('["' .. path .. '"] = [====[' .. content .. ']====],')
end
print("}")
print("return fileArray")