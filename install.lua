-- filepath: d:\luaasm\install.lua
-- LuaASM Installer for ComputerCraft
-- Downloads files from a Forgejo Git server and sets up the LuaASM environment.


-- Configuration
local GIT_SERVER = "https://git.carsoncoder.com"
local REPO = "charlie-san/LuaASM"
local BRANCH = "main"
local FILES = {
    "interp.lua",
    "debugger.lua",
    "tui.lua",
    "main.masm",
    "root/stdio/print.masm",
    "README.md",
    "mni-instructions.md",
    "v2instructions.md"
}

-- Helper function to download a file
local function downloadFile(url, path)
    local response, err = http.get(url)
    if not response then
        error("Failed to download " .. url .. ": " .. err)
    end

    local content = response.readAll()
    response.close()

    -- Ensure the directory exists
    local dir = path:match("^(.*)/")
    if dir and not fs.exists(dir) then
        fs.makeDir(dir)
    end

    -- Write the file
    local file = fs.open(path, "w")
    file.write(content)
    file.close()

    print("Downloaded: " .. path)
end

-- Main installation function
local function install()
    print("Starting LuaASM installation...")

    for _, file in ipairs(FILES) do
        local url = string.format("%s/%s/raw/branch/%s/%s", GIT_SERVER, REPO, BRANCH, file)
        downloadFile(url, file)
    end

    print("LuaASM installation complete!")
end

-- Run the installer
local ok, err = pcall(install)
if not ok then
    printError("Installation failed: " .. err)
end