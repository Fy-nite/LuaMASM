local term = {}
function term.write(text)
    io.write(text)
end
function term.read()
    return io.read()
end
function term.setCursor(x, y)
    -- ComputerCraft doesn't support ANSI escape sequences
    -- Instead of using ANSI positioning, we'll output newlines and spaces
    -- This is a simplified approach for terminals without cursor control
    io.write("\n")
end
local fs = {}
function fs.exists(path)
    return io.open(path, "r") ~= nil
end
local bit32 = {}


local gpu = {}
function gpu.getResolution()
    return 50, 16  -- Smaller size for ComputerCraft compatibility
end
function gpu.fill(x, y, w, h, char)
    -- Simple fill without cursor positioning
    for i = 0, h-1 do
        term.write(string.rep(char, w) .. "\n")
    end
end
function gpu.set(x, y, text)
    -- Simple text output without cursor positioning
    term.write(text .. "\n")
end

-- Terminal capability detection - always assume minimal capabilities
local function detectTerminalCapabilities()
    return {
        ansiSupport = false,  -- No ANSI support for ComputerCraft
        unicodeSupport = false, -- No Unicode for ComputerCraft
        colorSupport = false   -- No color handling in this simplified version
    }
end

local TUI = {}
TUI.__index = TUI

-- Define box drawing characters with ASCII only
local function getBoxChars()
    return {
        TL = "+", TR = "+", BL = "+", BR = "+",
        H = "-", V = "|"
    }
end

function TUI.new(machine, debugger)
    local self = setmetatable({}, TUI)
    self.machine = machine
    self.debugger = debugger
    self.w, self.h = gpu.getResolution()
    self.codeHeight = 8  -- Fixed height for code section
    self.registerHeight = 4  -- Fixed height for register section
    
    -- Always use minimal capabilities for ComputerCraft
    self.capabilities = {
        ansiSupport = false,
        unicodeSupport = false,
        colorSupport = false
    }
    self.BOX = getBoxChars()
    
    return self
end

function TUI:clear()
    -- Simple clear with newlines
    term.write("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
end

function TUI:drawBorder(x, y, width, height, title)
    -- Top border with title
    local topBorder = self.BOX.TL .. string.rep(self.BOX.H, width-2) .. self.BOX.TR
    if title then
        local titlePos = math.floor((width - #title - 2) / 2)
        if titlePos > 0 then
            topBorder = self.BOX.TL .. 
                       string.rep(self.BOX.H, titlePos) .. 
                       " " .. title .. " " ..
                       string.rep(self.BOX.H, width - titlePos - #title - 4) .. 
                       self.BOX.TR
        end
    end
    term.write(topBorder .. "\n")
    
    -- Middle content area with side borders
    local middleLine = self.BOX.V .. string.rep(" ", width-2) .. self.BOX.V
    for i = 1, height-2 do
        term.write(middleLine .. "\n")
    end
    
    -- Bottom border
    term.write(self.BOX.BL .. string.rep(self.BOX.H, width-2) .. self.BOX.BR .. "\n")
end

function TUI:drawCodeWindow()
    term.write("=== SOURCE CODE ===\n")
    
    -- Display code around current instruction
    local currentLine = self.machine.RIP + 1
    local visibleLines = 6  -- Show fewer lines for limited screen space
    local halfVisible = math.floor(visibleLines / 2)
    
    -- Calculate the range of lines to display
    local start = math.max(1, currentLine - halfVisible)
    local endLine = math.min(#self.machine.currentCode, start + visibleLines - 1)
    
    for i = start, endLine do
        local line = self.machine.currentCode[i] or ""
        local prefix = i == currentLine and ">" or " "
        
        -- Truncate line if too long
        local maxLineWidth = 45  -- Smaller width for ComputerCraft
        local displayLine = line
        if #displayLine > maxLineWidth then
            displayLine = displayLine:sub(1, maxLineWidth-3) .. "..."
        end
        
        term.write(string.format("%s %3d: %s\n", prefix, i, displayLine))
    end
    term.write("\n")
end

function TUI:drawRegisterWindow()
    term.write("=== REGISTERS ===\n")
    
    -- Display registers in two columns for space efficiency
    local registers = {
        {"RAX", self.machine.RAX}, {"RBX", self.machine.RBX}, 
        {"RCX", self.machine.RCX}, {"RDX", self.machine.RDX},
        {"RSI", self.machine.RSI}, {"RDI", self.machine.RDI}, 
        {"RBP", self.machine.RBP}, {"RSP", self.machine.RSP},
        {"RIP", self.machine.RIP}, {"RFLAGS", self.machine.RFLAGS}
    }
    
    -- Display registers in two columns
    for i = 1, 5 do
        term.write(string.format("%-4s: %-8d    %-4s: %-8d\n", 
            registers[i][1], registers[i][2],
            registers[i+5][1], registers[i+5][2]))
    end
    
    -- Display R0-R3 on one line, R4-R7 on another
    term.write(string.format("R0: %-4d  R1: %-4d  R2: %-4d  R3: %-4d\n", 
        self.machine.R0, self.machine.R1, self.machine.R2, self.machine.R3))
    term.write(string.format("R4: %-4d  R5: %-4d  R6: %-4d  R7: %-4d\n", 
        self.machine.R4, self.machine.R5, self.machine.R6, self.machine.R7))
    term.write("\n")
end

function TUI:drawStackWindow()
    term.write("=== STACK ===\n")
    
    -- Display stack items
    local stackStart = math.max(0, self.machine.RSP - 8)
    local stackEnd = stackStart + 7
    
    for addr = stackStart, stackEnd do
        if addr >= 0 then
            local value = self.machine.memory[addr] or 0
            local highlight = addr == self.machine.RSP - 1 and "*" or " "
            term.write(string.format("%s%04d: %-6d\n", highlight, addr, value))
        end
    end
    term.write("\n")
end

function TUI:refresh()
    self:clear()
    self:drawCodeWindow()
    self:drawRegisterWindow()
    self:drawStackWindow()
    term.write("debug> ")
end

function TUI:handleInput()
    self:refresh()
    while true do
        local input = term.read()
        if not input then break end
        
        local cmd, arg = input:match("^(%S+)%s*(.*)$")
        if not cmd then 
            self:refresh()
            goto continue 
        end
        
        if cmd == "tui" and arg == "stop" then
            self:clear()
            return false
        end
        
        if cmd == "q" or cmd == "quit" then
            self:clear()
            return false
        end
        
        -- Process regular debugger commands
        self.debugger:processCommand(cmd, arg)
        self:refresh()
        
        ::continue::
    end
end

return TUI
