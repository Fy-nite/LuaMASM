local term = {}
function term.write(text)
    io.write(text)
end
function term.read()
    return io.read()
end
function term.setCursor(x, y)
    -- Use ANSI escape sequence for cursor positioning if terminal supports it
    io.write(string.format("\27[%d;%dH", y, x))
end
local fs = {}
function fs.exists(path)
    return io.open(path, "r") ~= nil
end
local bit32 = {}
function bit32.band(a, b)
    return a & b
end
function bit32.bor(a, b)
    return a | b
end
function bit32.bxor(a, b)
    return a ~ b
end
function bit32.bnot(a)
    return ~a
end

local gpu = {}
function gpu.getResolution()
    return 80, 24  -- More standard terminal size
end
function gpu.fill(x, y, w, h, char)
    for i = 0, h-1 do
        term.setCursor(x, y+i)
        term.write(string.rep(char, w))
    end
end
function gpu.set(x, y, text)
    term.setCursor(x, y)
    term.write(text)
end

-- Terminal capability detection
local function detectTerminalCapabilities()
    local capabilities = {
        ansiSupport = true,  -- Assume ANSI support by default
        unicodeSupport = false, -- Assume no Unicode by default
        colorSupport = false   -- Assume no color support by default
    }
    
    -- Try to detect terminal type from environment
    local term_env = os.getenv("TERM")
    if term_env then
        if term_env:match("xterm") or term_env:match("linux") or term_env:match("vt100") then
            capabilities.ansiSupport = true
            capabilities.colorSupport = true
        end
        
        if term_env:match("utf") or term_env:match("UTF") then
            capabilities.unicodeSupport = true
        end
    end
    
    return capabilities
end

local TUI = {}
TUI.__index = TUI

-- Define box drawing characters with fallbacks
local function getBoxChars(unicodeSupport)
    if unicodeSupport then
        return {
            TL = "┌", TR = "┐", BL = "└", BR = "┘",
            H = "─", V = "│"
        }
    else
        -- ASCII fallbacks
        return {
            TL = "+", TR = "+", BL = "+", BR = "+",
            H = "-", V = "|"
        }
    end
end

function TUI.new(machine, debugger)
    local self = setmetatable({}, TUI)
    self.machine = machine
    self.debugger = debugger
    self.w, self.h = gpu.getResolution()
    self.codeHeight = math.floor(self.h * 0.6)  -- Slightly smaller code window
    self.registerHeight = 6
    
    -- Detect terminal capabilities
    self.capabilities = detectTerminalCapabilities()
    self.BOX = getBoxChars(self.capabilities.unicodeSupport)
    
    return self
end

function TUI:clear()
    if self.capabilities.ansiSupport then
        io.write("\27[2J\27[H")  -- ANSI clear screen and home cursor
    else
        -- Fallback for terminals without ANSI support
        for i = 1, self.h do
            io.write("\n")
        end
    end
end

function TUI:drawBorder(x, y, width, height, title)
    -- Draw top and bottom
    gpu.set(x, y, self.BOX.TL .. string.rep(self.BOX.H, width-2) .. self.BOX.TR)
    gpu.set(x, y+height-1, self.BOX.BL .. string.rep(self.BOX.H, width-2) .. self.BOX.BR)
    
    -- Draw sides
    for i = 1, height-2 do
        gpu.set(x, y+i, self.BOX.V)
        gpu.set(x+width-1, y+i, self.BOX.V)
    end
    
    -- Draw title if provided
    if title then
        local titleX = x + 3
        gpu.set(titleX, y, " " .. title .. " ")
    end
end

function TUI:drawCodeWindow()
    self:drawBorder(1, 1, self.w, self.codeHeight, "Source Code")
    
    -- Display code around current instruction
    local currentLine = self.machine.RIP + 1
    local visibleLines = self.codeHeight - 3
    local halfVisible = math.floor(visibleLines / 2)
    
    -- Calculate the range of lines to display
    local start = math.max(1, currentLine - halfVisible)
    local endLine = math.min(#self.machine.currentCode, start + visibleLines - 1)
    
    -- Adjust start if we're near the end
    if #self.machine.currentCode > visibleLines and endLine < #self.machine.currentCode then
        start = math.max(1, endLine - visibleLines + 1)
    end
    
    for i = 0, visibleLines - 1 do
        local lineNum = start + i
        if lineNum <= #self.machine.currentCode then
            local line = self.machine.currentCode[lineNum] or ""
            local prefix = lineNum == currentLine and ">" or " "
            
            -- Truncate line if too long
            local maxLineWidth = self.w - 8
            local displayLine = line
            if #displayLine > maxLineWidth then
                displayLine = displayLine:sub(1, maxLineWidth-3) .. "..."
            end
            
            gpu.set(2, i+2, string.format("%s %3d: %s", 
                prefix, lineNum, displayLine))
        end
    end
end

function TUI:drawRegisterWindow()
    local y = self.codeHeight + 1
    self:drawBorder(1, y, self.w, self.registerHeight, "Registers")
    
    -- Display registers in columns for better readability
    local registers = {
        {"RAX", self.machine.RAX}, {"RBX", self.machine.RBX}, 
        {"RCX", self.machine.RCX}, {"RDX", self.machine.RDX},
        {"RSI", self.machine.RSI}, {"RDI", self.machine.RDI}, 
        {"RBP", self.machine.RBP}, {"RSP", self.machine.RSP},
        {"RIP", self.machine.RIP}, {"RFLAGS", self.machine.RFLAGS}
    }
    
    -- Calculate columns
    local colWidth = 15
    local cols = math.floor((self.w - 4) / colWidth)
    
    -- Draw registers in columns
    for i, reg in ipairs(registers) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = 3 + col * colWidth
        gpu.set(x, y + row + 1, string.format("%-4s: %-8d", reg[1], reg[2]))
    end
    
    -- Display R0-R7 on another row
    local rRow = math.ceil(#registers / cols) + 1
    for i = 0, 7 do
        local x = 3 + i * 9
        if x + 9 <= self.w - 2 then
            gpu.set(x, y + rRow, string.format("R%-1d: %-4d", i, self.machine["R"..i]))
        end
    end
end

function TUI:drawStackWindow()
    local y = self.codeHeight + self.registerHeight + 1
    self:drawBorder(1, y, self.w, self.h - y, "Stack")
    
    -- Display multiple stack entries per row
    local stackStart = math.max(0, self.machine.RSP - 32)  -- Show some items before current RSP
    local cols = 4
    local itemWidth = math.floor((self.w - 4) / cols)
    
    for i = 0, 15 do  -- Show 16 stack items, 4 per row
        local row = math.floor(i / cols)
        local col = i % cols
        local addr = stackStart + i
        local x = 3 + col * itemWidth
        
        if addr >= 0 and row < self.h - y - 1 then
            local value = self.machine.memory[addr] or 0
            local highlight = addr == self.machine.RSP - 1 and "*" or " "
            gpu.set(x, y + row + 1, string.format("%s%04d: %-6d", highlight, addr, value))
        end
    end
end

function TUI:refresh()
    self:clear()
    self:drawCodeWindow()
    self:drawRegisterWindow()
    self:drawStackWindow()
    gpu.set(1, self.h, "debug> ")
end

function TUI:handleInput()
    self:refresh()
    while true do
        term.setCursor(8, self.h)
        local input = term.read()
        if not input then break end
        
        local cmd, arg = input:match("^(%S+)%s*(.*)$")
        if not cmd then goto continue end
        
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
