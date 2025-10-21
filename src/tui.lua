local term = {}
function term.write(text)
    io.write(text)
end
function term.read()
    return io.read()
end
function term.setCursor(x, y)
    -- Only use ANSI escape sequences when in ANSI mode
    if _G.ANSI_MODE then
        io.write(string.format("\27[%d;%dH", y, x))
    end
end
local fs = {}
function fs.exists(path)
    return io.open(path, "r") ~= nil
end
local bit32 = {}


local gpu = {}
function gpu.getResolution()
    return _G.ANSI_MODE and 80 or 50, _G.ANSI_MODE and 24 or 16
end
function gpu.fill(x, y, w, h, char)
    if _G.ANSI_MODE then
        -- ANSI mode fill
        for i = 0, h-1 do
            term.setCursor(x, y+i)
            term.write(string.rep(char, w))
        end
    else
        -- Text mode just outputs the characters
        term.write(string.rep(char, w) .. "\n")
    end
end
function gpu.set(x, y, text)
    if _G.ANSI_MODE then
        -- ANSI mode positioning
        term.setCursor(x, y)
        term.write(text)
    else
        -- Text mode just outputs the text
        term.write(text .. "\n")
    end
end

-- Terminal capability detection
local function detectTerminalCapabilities()
    local capabilities = {
        ansiSupport = _G.ANSI_MODE, -- Based on global flag
        unicodeSupport = false,
        colorSupport = false
    }
    
    return capabilities
end

local TUI = {}
TUI.__index = TUI

-- Define box drawing characters with fallbacks
local function getBoxChars(unicodeSupport)
    -- Always use ASCII characters for compatibility
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
    self.codeHeight = _G.ANSI_MODE and math.floor(self.h * 0.6) or 8
    self.registerHeight = _G.ANSI_MODE and 6 or 4
    
    -- Detect terminal capabilities
    self.capabilities = detectTerminalCapabilities()
    self.BOX = getBoxChars(false)
    
    return self
end

function TUI:clear()
    if self.capabilities.ansiSupport then
        io.write("\27[2J\27[H")  -- ANSI clear screen and home cursor
    else
        -- Text mode just outputs multiple newlines
        term.write("\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
    end
end

function TUI:drawBorder(x, y, width, height, title)
    if self.capabilities.ansiSupport then
        -- ANSI mode borders
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
    else
        -- Text mode simple borders
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
    end
end

function TUI:drawCodeWindow()
    if self.capabilities.ansiSupport then
        self:drawBorder(1, 1, self.w, self.codeHeight, "Source Code")
    else
        term.write("=== SOURCE CODE ===\n")
    end
    
    -- Display code around current instruction
    local currentLine = self.machine.RIP + 1
    local visibleLines = self.capabilities.ansiSupport and self.codeHeight - 3 or 6
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
            local maxLineWidth = self.capabilities.ansiSupport and self.w - 8 or 45
            local displayLine = line
            if #displayLine > maxLineWidth then
                displayLine = displayLine:sub(1, maxLineWidth-3) .. "..."
            end
            
            if self.capabilities.ansiSupport then
                gpu.set(2, i+2, string.format("%s %3d: %s", prefix, lineNum, displayLine))
            else
                term.write(string.format("%s %3d: %s\n", prefix, lineNum, displayLine))
            end
        end
    end
end

function TUI:drawRegisterWindow()
    if self.capabilities.ansiSupport then
        local y = self.codeHeight + 1
        self:drawBorder(1, y, self.w, self.registerHeight, "Registers")
    else
        term.write("\n=== REGISTERS ===\n")
    end
    
    -- Display registers in columns for better readability
    local registers = {
        {"RAX", self.machine.RAX}, {"RBX", self.machine.RBX}, 
        {"RCX", self.machine.RCX}, {"RDX", self.machine.RDX},
        {"RSI", self.machine.RSI}, {"RDI", self.machine.RDI}, 
        {"RBP", self.machine.RBP}, {"RSP", self.machine.RSP},
        {"RIP", self.machine.RIP}, {"RFLAGS", self.machine.RFLAGS}
    }
    
    if self.capabilities.ansiSupport then
        -- ANSI mode with proper positioning
        local colWidth = 15
        local cols = math.floor((self.w - 4) / colWidth)
        
        -- Draw registers in columns
        for i, reg in ipairs(registers) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local x = 3 + col * colWidth
            local y = self.codeHeight + 2 + row
            gpu.set(x, y, string.format("%-4s: %-8d", reg[1], reg[2]))
        end
        
        -- Display R0-R7 on another row
        local rRow = math.ceil(#registers / cols) + 1
        for i = 0, 7 do
            local x = 3 + i * 9
            if x + 9 <= self.w - 2 then
                gpu.set(x, self.codeHeight + 2 + rRow, string.format("R%-1d: %-4d", i, self.machine["R"..i]))
            end
        end
    else
        -- Text mode with simple output
        -- Output in pairs to save space
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
    end
end

function TUI:drawStackWindow()
    if self.capabilities.ansiSupport then
        local y = self.codeHeight + self.registerHeight + 1
        self:drawBorder(1, y, self.w, self.h - y, "Stack")
        
        -- Display multiple stack entries per row
        local stackStart = math.max(0, self.machine.RSP - 32)
        local cols = 4
        local itemWidth = math.floor((self.w - 4) / cols)
        
        for i = 0, 15 do
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
    else
        -- Text mode
        term.write("\n=== STACK ===\n")
        
        -- Show just a few stack entries in text mode
        local stackStart = math.max(0, self.machine.RSP - 8)
        local stackEnd = stackStart + 7
        
        for addr = stackStart, stackEnd do
            if addr >= 0 then
                local value = self.machine.memory[addr] or 0
                local highlight = addr == self.machine.RSP - 1 and "*" or " "
                term.write(string.format("%s%04d: %-6d\n", highlight, addr, value))
            end
        end
    end
end

function TUI:refresh()
    self:clear()
    self:drawCodeWindow()
    self:drawRegisterWindow()
    self:drawStackWindow()
    
    if self.capabilities.ansiSupport then
        gpu.set(1, self.h, "debug> ")
    else
        term.write("\ndebug> ")
    end
end

function TUI:handleInput()
    self:refresh()
    while true do
        if self.capabilities.ansiSupport then
            term.setCursor(8, self.h)
        end
        
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
