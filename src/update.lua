-- LuaASM Updater Script
-- Automates the process of updating files and testing

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

local function downloadFile(url, path)
    local success, response
    
    -- Try different HTTP libraries based on what's available
    if package.loaded.http then
        -- ComputerCraft style
        success, response = pcall(function() 
            return package.loaded.http.get(url) 
        end)
    elseif package.loaded.socket and package.loaded.socket.http then
        -- LuaSocket style
        success, response = pcall(function() 
            return package.loaded.socket.http.request(url) 
        end)
    elseif io.popen then
        -- Use curl if available
        success = true
        local command = "curl -s \"" .. url .. "\""
        local handle = io.popen(command)
        response = handle:read("*all")
        handle:close()
    else
        print("No HTTP library found. Please install LuaSocket or use an environment with HTTP capabilities")
        return false
    end
    
    if not success or not response then
        print("ERROR: Could not download " .. url)
        return false
    end
    
    -- Extract content from response
    local content
    if type(response) == "table" and response.readAll then
        -- ComputerCraft style response
        content = response.readAll()
        response.close()
    else
        -- String response
        content = response
    end
    
    -- Write content to file
    return writeFile(path, content)
end

local function executeCommand(command)
    local handle = io.popen(command)
    if handle then
        local result = handle:read("*all")
        handle:close()
        return result
    end
    return nil
end

-- Check if required files exist
if not fileExists("config.lua") then
    error("Configuration file 'config.lua' not found. Please run config-manager.lua first.")
end

-- Load configuration
local config = dofile("config.lua")

-- Ask for update type
print("LuaASM Update Helper")
print("==================")
print("")
print("1. Update all files from repository")
print("2. Update specific files")
print("3. Test LuaASM with a sample program")
print("4. Push local changes to repository (requires git)")
print("5. Exit")

io.write("\nEnter choice (1-5): ")
local choice = tonumber(io.read())

-- Function to download files from repository
local function downloadFiles(fileList)
    for _, file in ipairs(fileList) do
        print("Downloading " .. file)
        local url = string.format("%s/%s/raw/branch/%s/%s", 
            config.GIT_SERVER, config.REPO, config.BRANCH, file)
        
        if downloadFile(url, file) then
            print("Successfully downloaded " .. file)
        else
            print("ERROR: Failed to download " .. file)
        end
    end
end

-- Function to run a test program
local function runTest()
    print("\nSelect a test program to run:")
    print("1. main.masm (Hello World)")
    print("2. example-mni.masm (MNI Example)")
    print("3. example-mni-module.masm (Module Example)")
    print("4. Custom file")
    
    io.write("\nEnter choice (1-4): ")
    local testChoice = tonumber(io.read())
    
    local testFile
    if testChoice == 1 then
        testFile = "main.masm"
    elseif testChoice == 2 then
        testFile = "example-mni.masm"
    elseif testChoice == 3 then
        testFile = "example-mni-module.masm"
    elseif testChoice == 4 then
        io.write("Enter filename: ")
        testFile = io.read()
    else
        print("Invalid choice")
        return
    end
    
    if not fileExists(testFile) then
        print("Error: Test file not found: " .. testFile)
        return
    end
    
    print("\nRunning test with " .. testFile)
    print("Debug options:")
    print("1. Normal execution")
    print("2. Debug mode with TUI")
    print("3. Debug CLI mode")
    io.write("Enter choice (1-3): ")
    local debugChoice = tonumber(io.read())
    
    local debugFlag = ""
    if debugChoice == 2 then
        debugFlag = "--debug"
    elseif debugChoice == 3 then
        debugFlag = "--debug-cli"
    end
    
    -- Execute the test
    print("\n--- Test Output ---")
    local command = "lua interp.lua " .. testFile .. " " .. debugFlag
    executeCommand(command)
    print("--- End Output ---\n")
    
    print("Press Enter to continue...")
    io.read()
end

-- Handle the choice
if choice == 1 then
    -- Update all files
    print("\nUpdating all files...")
    downloadFiles(config.FILES)
    
    print("\nUpdate complete. Press Enter to continue...")
    io.read()
    
elseif choice == 2 then
    -- Update specific files
    print("\nSelect files to update (comma-separated numbers, e.g. 1,3,5):")
    for i, file in ipairs(config.FILES) do
        print(i .. ". " .. file)
    end
    
    io.write("\nEnter numbers: ")
    local input = io.read()
    local filesToUpdate = {}
    
    for num in input:gmatch("(%d+)") do
        local index = tonumber(num)
        if index and index >= 1 and index <= #config.FILES then
            table.insert(filesToUpdate, config.FILES[index])
        end
    end
    
    print("\nUpdating " .. #filesToUpdate .. " files...")
    downloadFiles(filesToUpdate)
    
    print("\nUpdate complete. Press Enter to continue...")
    io.read()
    
elseif choice == 3 then
    -- Test LuaASM
    runTest()
    
elseif choice == 4 then
    -- Push changes (this requires git to be installed and configured)
    print("\nThis option requires git to be configured on your system.")
    print("Make sure your changes are committed locally first.")
    
    io.write("Enter commit message: ")
    local commitMsg = io.read()
    
    print("\nRunning git commands...")
    executeCommand("git add .")
    executeCommand("git commit -m \"" .. commitMsg .. "\"")
    executeCommand("git push origin " .. config.BRANCH)
    
    print("\nPush complete. Press Enter to continue...")
    io.read()
    
elseif choice == 5 then
    -- Exit
    print("Exiting...")
end
