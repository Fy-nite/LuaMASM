-- Configuration Manager for LuaASM Installer
-- This script provides a UI for updating the config.lua file

-- Helper functions for file operations using standard Lua IO
local function fileExists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function readFile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

local function writeFile(path, content)
    -- Ensure directory exists
    local dir = path:match("^(.-)[/\\][^/\\]+$")
    if dir and dir ~= "" then
        os.execute("mkdir -p \"" .. dir .. "\"")
    end
    
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

-- Simulate terminal functions with standard IO
local function clearScreen()
    -- In some terminals, we can clear with escape sequences
    -- But for compatibility, we'll print newlines
    io.write("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
end

local function setCursorPos(x, y)
    -- Not really possible in standard IO without terminal control
    -- But we can use newlines to approximate positioning
    -- This is a simplified version
    io.write("\n")
end

-- Save configuration to file
local function saveConfig(config)
    -- Convert config to Lua code
    local lines = {"-- Configuration for LuaASM Installer", "-- Edit this file to customize your installation", "", "return {"}
    
    -- Add Git server
    table.insert(lines, string.format("    -- Git server URL (no trailing slash)"))
    table.insert(lines, string.format("    GIT_SERVER = \"%s\",", config.GIT_SERVER))
    table.insert(lines, "")
    
    -- Add repo
    table.insert(lines, string.format("    -- Repository path (username/repo)"))
    table.insert(lines, string.format("    REPO = \"%s\",", config.REPO))
    table.insert(lines, "")
    
    -- Add branch
    table.insert(lines, string.format("    -- Branch name"))
    table.insert(lines, string.format("    BRANCH = \"%s\",", config.BRANCH))
    table.insert(lines, "")
    
    -- Add files
    table.insert(lines, "    -- Files to download")
    table.insert(lines, "    FILES = {")
    
    -- Group files by directory for better organization
    local groups = {}
    local dirs = {
        ["."] = "Core files",
        ["root/stdio"] = "Standard library",
        ["root/MNI"] = "MNI modules"
    }
    
    for _, file in ipairs(config.FILES) do
        local dir = file:match("^(.-)/") or "."
        if not groups[dir] then
            groups[dir] = {}
        end
        table.insert(groups[dir], file)
    end
    
    -- Add files from each group
    for dir, files in pairs(groups) do
        local comment = dirs[dir] or (dir .. " files")
        table.insert(lines, string.format("        -- %s", comment))
        for _, file in ipairs(files) do
            table.insert(lines, string.format("        \"%s\",", file))
        end
        table.insert(lines, "")
    end
    
    -- Close the FILES table and the main table
    table.insert(lines, "    }")
    table.insert(lines, "}")
    
    -- Write to file
    writeFile("config.lua", table.concat(lines, "\n"))
    
    print("Configuration saved to config.lua")
end

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
    if fileExists("config.lua") then
        local ok, userConfig = pcall(dofile, "config.lua")
        if ok and type(userConfig) == "table" then
            -- Merge configs, with user config taking precedence
            for k, v in pairs(userConfig) do
                config[k] = v
            end
        else
            print("Warning: Could not load config.lua, using defaults")
        end
    else
        print("No config.lua found, using default settings")
    end
    
    return config
end

-- File management menu
local function manageFiles(config)
    while true do
        clearScreen()
        setCursorPos(1, 1)
        
        print("File Management")
        print("==============")
        print("")
        print("Current files:")
        
        for i, file in ipairs(config.FILES) do
            print(i .. ". " .. file)
        end
        
        print("")
        print("A. Add file")
        print("R. Remove file")
        print("B. Back to main menu")
        
        io.write("\nEnter choice: ")
        local choice = io.read()
        
        if choice:upper() == "A" then
            io.write("Enter file path to add: ")
            local newFile = io.read()
            if newFile and newFile ~= "" then
                table.insert(config.FILES, newFile)
                print("Added " .. newFile)
            end
        elseif choice:upper() == "R" then
            io.write("Enter number of file to remove: ")
            local fileNum = tonumber(io.read())
            if fileNum and fileNum >= 1 and fileNum <= #config.FILES then
                local removed = table.remove(config.FILES, fileNum)
                print("Removed " .. removed)
            else
                print("Invalid file number")
            end
        elseif choice:upper() == "B" then
            return
        else
            local num = tonumber(choice)
            if num and num >= 1 and num <= #config.FILES then
                io.write("Edit file path [" .. config.FILES[num] .. "]: ")
                local newPath = io.read()
                if newPath and newPath ~= "" then
                    config.FILES[num] = newPath
                end
            else
                print("Invalid choice. Press Enter to continue...")
                io.read()
            end
        end
        
        -- Add a small pause to see messages
        print("\nPress Enter to continue...")
        io.read()
    end
end

-- Show main menu
local function showMainMenu()
    local config = loadConfig()
    
    while true do
        clearScreen()
        setCursorPos(1, 1)
        
        print("LuaASM Configuration Manager")
        print("===========================")
        print("")
        print("1. Edit Git Server: " .. config.GIT_SERVER)
        print("2. Edit Repository: " .. config.REPO)
        print("3. Edit Branch: " .. config.BRANCH)
        print("4. Manage Files (" .. #config.FILES .. " files)")
        print("5. Save Configuration")
        print("6. Exit")
        
        io.write("\nEnter choice (1-6): ")
        local choice = tonumber(io.read())
        
        if choice == 1 then
            io.write("Enter Git server URL: ")
            config.GIT_SERVER = io.read()
        elseif choice == 2 then
            io.write("Enter repository path (username/repo): ")
            config.REPO = io.read()
        elseif choice == 3 then
            io.write("Enter branch name: ")
            config.BRANCH = io.read()
        elseif choice == 4 then
            manageFiles(config)
        elseif choice == 5 then
            saveConfig(config)
        elseif choice == 6 then
            return
        else
            print("Invalid choice. Press Enter to continue...")
            io.read()
        end
    end
end

-- Quick setup function
local function quickSetup()
    local config = loadConfig()
    
    print("Quick Setup")
    print("==========")
    print("")
    
    io.write("Git server URL [" .. config.GIT_SERVER .. "]: ")
    local server = io.read()
    if server and server ~= "" then
        config.GIT_SERVER = server
    end
    
    io.write("Repository path [" .. config.REPO .. "]: ")
    local repo = io.read()
    if repo and repo ~= "" then
        config.REPO = repo
    end
    
    io.write("Branch name [" .. config.BRANCH .. "]: ")
    local branch = io.read()
    if branch and branch ~= "" then
        config.BRANCH = branch
    end
    
    print("Configuration updated. Saving...")
    saveConfig(config)
    
    print("Press Enter to continue...")
    io.read()
end

-- Main function
local function main(args)
    args = args or {}
    if #args > 0 and args[1] == "quick" then
        quickSetup()
    else
        showMainMenu()
    end
end

-- Run the script
main({...})
