local term = {}
function term.write(text)
    io.write(text)
end
function term.read()
    return io.read()
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

local Debugger = {}
Debugger.__index = Debugger

function Debugger.new(machine)
    local self = setmetatable({}, Debugger)
    self.machine = machine
    self.breakpoints = {}
    self.history = {}
    self.historySize = 100
    self.tuiMode = false
    self.tui = nil
    return self
end

function Debugger:help()
    term.write([[
Debugger commands:
    h, help      - Show this help
    s, step      - Execute next instruction
    c, continue  - Continue execution until next breakpoint
    b <line>     - Set breakpoint at line number
    rb <line>    - Remove breakpoint at line number
    lb           - List all breakpoints
    p <reg>      - Print register value
    pm <addr>    - Print memory at address
    r            - Print all registers
    m            - Print memory dump
    stack        - Print stack dump
    fill <addr> <value> <count> - Fill memory with value
    copy <src> <dest> <count> - Copy memory from src to dest
    q, quit      - Quit debugger
    tui start    - Start TUI mode
    tui stop     - Stop TUI mode
    ]])
end

function Debugger:printRegisters()
    term.write("\nRegister values:\n")
    term.write(string.format("RAX: %-8d RBX: %-8d RCX: %-8d RDX: %-8d\n", 
        self.machine.RAX, self.machine.RBX, self.machine.RCX, self.machine.RDX))
    term.write(string.format("RSI: %-8d RDI: %-8d RBP: %-8d RSP: %-8d\n", 
        self.machine.RSI, self.machine.RDI, self.machine.RBP, self.machine.RSP))
    term.write(string.format("RIP: %-8d FLAGS: %d\n", 
        self.machine.RIP, self.machine.RFLAGS))
end

function Debugger:printMemory(start, count)
    start = tonumber(start) or 0
    count = tonumber(count) or 16
    term.write("\nMemory dump:\n")
    for i = start, start + count - 1 do
        if i % 4 == 0 then term.write("\n") end
        term.write(string.format("%04d: %-6d ", i, self.machine.memory[i] or 0))
    end
    term.write("\n")
end

function Debugger:printStack()
    term.write("\nStack dump:\n")
    local stackBase = self.machine.RSP
    local count = 16  -- Show 16 stack items
    
    for i = 0, count-1 do
        local addr = stackBase - i - 1
        if addr >= 0 then
            term.write(string.format("%04d: %-6d\n", addr, self.machine.memory[addr] or 0))
        end
    end
end

function Debugger:setBreakpoint(line)
    local lineNum = tonumber(line)
    if lineNum and lineNum > 0 and lineNum <= #self.machine.currentCode then
        self.breakpoints[lineNum] = true
        term.write("Breakpoint set at line " .. lineNum .. "\n")
    else
        term.write("Invalid line number\n")
    end
end

function Debugger:removeBreakpoint(line)
    local lineNum = tonumber(line)
    if lineNum and self.breakpoints[lineNum] then
        self.breakpoints[lineNum] = nil
        term.write("Breakpoint removed from line " .. lineNum .. "\n")
    else
        term.write("No breakpoint at line " .. (lineNum or "nil") .. "\n")
    end
end

function Debugger:listBreakpoints()
    term.write("\nBreakpoints:\n")
    local found = false
    for line, _ in pairs(self.breakpoints) do
        term.write("Line " .. line .. "\n")
        found = true
    end
    if not found then
        term.write("No breakpoints set\n")
    end
end

function Debugger:shouldBreak()
    return self.breakpoints[self.machine.RIP + 1]
end

function Debugger:processCommand(cmd, arg)
    if not cmd then return true end
    
    -- Trim whitespace and convert to lowercase
    cmd = cmd:match("^%s*(.-)%s*$"):lower()
    arg = arg and arg:match("^%s*(.-)%s*$")
    
    -- Handle TUI commands first
    if cmd == "tui" then
        if arg == "start" and not self.tuiMode then
            local ok, TUI = pcall(require, "tui")
            if not ok then
                term.write("Error loading TUI module: " .. tostring(TUI) .. "\n")
                term.write("Current package.path: " .. package.path .. "\n")
                return true
            end
            self.tui = TUI.new(self.machine, self)
            self.tuiMode = true
            self.tui:handleInput()
            return true
        elseif arg == "stop" and self.tuiMode then
            if self.tui then
                self.tui:clear()
            end
            self.tuiMode = false
            return true
        end
    end
    
    if cmd == "h" or cmd == "help" then
        self:help()
        
    elseif cmd == "s" or cmd == "step" then
        local line = self.machine.currentCode[self.machine.RIP + 1]
        term.write("Executing: " .. (line or "end of program") .. "\n")
        if not self.machine:executeInstruction(line) then
            term.write("Program finished\n")
            return false
        end
        if not self.tuiMode then
            self:printRegisters()
        end
        
    elseif cmd == "c" or cmd == "continue" then
        while self.machine.RIP < #self.machine.currentCode do
            if self:shouldBreak() then
                term.write("Breakpoint hit at line " .. (self.machine.RIP+1) .. "\n")
                break
            end
            local line = self.machine.currentCode[self.machine.RIP + 1]
            if not self.machine:executeInstruction(line) then 
                term.write("Program finished\n")
                break 
            end
        end
        if not self.tuiMode then
            self:printRegisters()
        end
        
    elseif cmd == "b" then
        self:setBreakpoint(arg)
        
    elseif cmd == "rb" then
        self:removeBreakpoint(arg)
        
    elseif cmd == "lb" then
        self:listBreakpoints()
        
    elseif cmd == "p" then
        local value = self.machine[arg]
        term.write(string.format("%s = %s\n", arg, value or "nil"))
        
    elseif cmd == "pm" then
        local addr = tonumber(arg) or 0
        self:printMemory(addr, 16)
        
    elseif cmd == "r" then
        self:printRegisters()
        
    elseif cmd == "m" then
        self:printMemory()
        
    elseif cmd == "stack" then
        self:printStack()
        
    elseif cmd == "fill" then
        local args = {}
        for word in string.gmatch(arg, "%S+") do
            table.insert(args, word)
        end
        if #args >= 3 then
            self.machine:fill(args[1], args[2], args[3])
            term.write("Memory filled\n")
        else
            term.write("Usage: fill <addr> <value> <count>\n")
        end
        
    elseif cmd == "copy" then
        local args = {}
        for word in string.gmatch(arg, "%S+") do
            table.insert(args, word)
        end
        if #args >= 3 then
            self.machine:copy(args[2], args[1], args[3])
            term.write("Memory copied\n")
        else
            term.write("Usage: copy <src> <dest> <count>\n")
        end
        
    elseif cmd == "q" or cmd == "quit" then
        term.write("Debugger terminated\n")
        return false
        
    else
        term.write("Unknown command '" .. cmd .. "'. Type 'h' for help\n")
    end
    return true
end

function Debugger:start()
    -- Auto-start TUI if machine is in debug mode and autoTUI is enabled
    if self.machine.debugMode and self.machine.autoTUI then
        local ok, TUI = pcall(require, "tui")
        if ok then
            self.tui = TUI.new(self.machine, self)
            self.tuiMode = true
            self.tui:handleInput()
            return
        else
            term.write("Warning: Could not load TUI module, falling back to CLI mode\n")
            term.write("Error: " .. tostring(TUI) .. "\n")
        end
    end

    term.write("Debugger started. Type 'h' for help.\n")
    
    while true do
        term.write("debug> ")
        local input = term.read()
        if not input then break end
        
        local cmd, arg = input:match("^(%S+)%s*(.*)$")
        if cmd then
            if self:processCommand(cmd, arg) == false then
                break
            end
            
            if self.tuiMode and self.tui then
                self.tui:handleInput()
            end
        end
    end
end

return Debugger
