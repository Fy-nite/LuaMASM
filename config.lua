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
        "main.masm",
        "README.md",
        "mni-instructions.md",
        "v2instructions.md",

        -- root files
        "root/stdio/print.masm",

    }
}