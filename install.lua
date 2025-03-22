-- filepath: d:\luaasm\install.lua
-- LuaASM Installer for ComputerCraft
-- Downloads files from a Git server and sets up the LuaASM environment.
-- Uses config.lua for configuration settings

-- Load configuration
local function loadConfig()
    -- Default configuration
    local config = {
        GIT_SERVER = "https://git.carsoncoder.com",
        REPO = "charlie-san/LuaASM",
        BRANCH = "main",
        FILES = {
            "interp.lua",
            "debugger.lua",
            "tui.lua",
            "main.masm",
            "root/stdio/print.masm",
            "README.md",
            "mni-instructions.md",
            "v2instructions.md"
        }
    }
    
    -- Try to load from config file if it exists
    if fs.exists("config.lua") then
        local ok, userConfig = pcall(dofile, "config.lua")
        if ok and type(userConfig) == "table" then
            -- Merge configs, with user config taking precedence
            for k, v in pairs(userConfig) do
                config[k] = v
            end
        end
    end
    
    return config
end

-- Helper function to download a file
local function downloadFile(url, path)
    print("Downloading: " .. url)
    
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
    local config = loadConfig()
    print("Starting LuaASM installation...")
    print("Using Git server: " .. config.GIT_SERVER)
    print("Repository: " .. config.REPO)
    print("Branch: " .. config.BRANCH)
    print("Files to download: " .. #config.FILES)
    
    for _, file in ipairs(config.FILES) do
        local url = string.format("%s/%s/raw/branch/%s/%s", 
            config.GIT_SERVER, config.REPO, config.BRANCH, file)
        downloadFile(url, file)
    end

    print("LuaASM installation complete!")
end

-- Run the installer
local ok, err = pcall(install)
if not ok then
    printError("Installation failed: " .. err)
end