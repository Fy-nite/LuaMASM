local term = {}
function term.write(text)
    io.write(text)
end
function term.read()
    return io.read()
end
function term.setCursor(x, y)
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
    return 50, 16
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


local TUI = {}
TUI.__index = TUI

-- Box drawing characters for OpenComputers
local BOX = {
    TL = "┌", TR = "┐", BL = "└", BR = "┘",
    H = "─", V = "│"
}

function TUI.new(machine, debugger)
    local self = setmetatable({}, TUI)
    self.machine = machine
    self.debugger = debugger
    self.w, self.h = gpu.getResolution()
    self.codeHeight = math.floor(self.h * 0.7)
    self.registerHeight = 6
    return self
end

function TUI:clear()
    gpu.fill(1, 1, self.w, self.h, " ")
end

function TUI:drawBorder(x, y, width, height)
    -- Draw top and bottom
    gpu.set(x, y, BOX.TL .. string.rep(BOX.H, width-2) .. BOX.TR)
    gpu.set(x, y+height-1, BOX.BL .. string.rep(BOX.H, width-2) .. BOX.BR)
    
    -- Draw sides
    for i = 1, height-2 do
        gpu.set(x, y+i, BOX.V)
        gpu.set(x+width-1, y+i, BOX.V)
    end
end

function TUI:drawCodeWindow()
    self:drawBorder(1, 1, self.w, self.codeHeight)
    gpu.set(3, 1, " Source Code ")
    
    -- Display code around current instruction
    local start = math.max(1, self.machine.RIP - 7)
    for i = 0, self.codeHeight-4 do
        local lineNum = start + i
        local line = self.machine.currentCode[lineNum] or ""
        local prefix = lineNum == self.machine.RIP + 1 and ">" or " "
        gpu.set(2, i+2, string.format("%s %3d: %s", 
            prefix, lineNum, line:sub(1, self.w-8)))
    end
end

function TUI:drawRegisterWindow()
    local y = self.codeHeight + 1
    self:drawBorder(1, y, self.w, self.registerHeight)
    gpu.set(3, y, " Registers ")
    
    -- Display registers in a more compact format for OpenComputers
    local fmt = "%-12s"
    local regs = {
        string.format(fmt, "RAX: " .. self.machine.RAX),
        string.format(fmt, "RBX: " .. self.machine.RBX),
        string.format(fmt, "RCX: " .. self.machine.RCX),
        string.format(fmt, "RDX: " .. self.machine.RDX)
    }
    gpu.set(2, y+1, table.concat(regs))
    
    regs = {
        string.format(fmt, "RSI: " .. self.machine.RSI),
        string.format(fmt, "RDI: " .. self.machine.RDI),
        string.format(fmt, "RBP: " .. self.machine.RBP),
        string.format(fmt, "RSP: " .. self.machine.RSP)
    }
    gpu.set(2, y+2, table.concat(regs))
    
    gpu.set(2, y+3, string.format("RIP: %-8d  FLAGS: %d", 
        self.machine.RIP, self.machine.RFLAGS))
end

function TUI:drawStackWindow()
    local y = self.codeHeight + self.registerHeight + 1
    self:drawBorder(1, y, self.w, self.h - y)
    gpu.set(3, y, " Stack ")
    
    local stackStart = self.machine.RSP
    for i = 0, self.h - y - 3 do
        local addr = stackStart + i
        gpu.set(2, y + i + 1, string.format("%04d: %-6d", addr, self.machine.memory[addr] or 0))
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
