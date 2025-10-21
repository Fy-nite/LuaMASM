-- filepath: d:\luaasm\install.lua
-- LuaASM Installer for ComputerCraft
-- Uses file_array.lua to set up the LuaASM environment locally.

-- Load the file array
local fileArray = require("file_array")

-- Helper function to write a file
local function writeFile(path, content)
    -- Ensure the directory exists
    local dir = path:match("^(.*)/")
    if dir and not fs.exists(dir) then
        fs.makeDir(dir)
    end

    -- Write the file
    local file = fs.open(path, "w")
    file.write(content)
    file.close()

    print("Created: " .. path)
end

-- Main installation function
local function install()
    print("Starting LuaASM installation...")

    for path, content in pairs(fileArray) do
        writeFile(path, content)
    end

    print("LuaASM installation complete!")
end

-- Run the installer
local ok, err = pcall(install)
if not ok then
    printError("Installation failed: " .. err)
end
