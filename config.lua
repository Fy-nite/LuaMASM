-- Configuration for LuaASM Installer
-- Edit this file to customize your installation

return {
    -- Git server URL (no trailing slash)
    GIT_SERVER = "https://git.carsoncoder.com",
    
    -- Repository path (username/repo)
    REPO = "charlie-san/LuaASM",
    
    -- Branch name
    BRANCH = "main",
    
    -- Files to download
    FILES = {
        -- Core files
        "interp.lua",
        "debugger.lua",
        "tui.lua",
        
        -- Documentation
        "README.md",
        "mni-instructions.md",
        "v2instructions.md",
        "mni-modules.md",
        
        -- Example files
        "main.masm",
        "example-mni.masm",
        "example-mni-module.masm",
        
        -- Standard library
        "root/stdio/print.masm",
        
        -- MNI modules
        "root/MNI/string.lua",
        "root/MNI/math.lua",
        "root/MNI/util.lua",
        
        -- Custom modules
        "custom-mni.lua",
        "custom-mni-readme.md"
    }
}
