local term = {}
function term.write(text)
    io.write(text)
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
    print([[
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
    start = start or 0
    count = count or 16
    term.write("\nMemory dump:\n")
    for i = start, start + count - 1 do
        if i % 4 == 0 then term.write("\n") end
        term.write(string.format("%04d: %-6d", i, self.machine.memory[i] or 0))
    end
    term.write("\n")
end

function Debugger:printStack()
    term.write("\nStack dump:\n")
    for i = self.machine.RSP, 1024 do
        term.write(string.format("%04d: %-6d\n", i, self.machine.memory[i] or 0))
    end
end

function Debugger:setBreakpoint(line)
    self.breakpoints[tonumber(line)] = true
    print("Breakpoint set at line " .. line)
end

function Debugger:removeBreakpoint(line)
    self.breakpoints[tonumber(line)] = nil
    print("Breakpoint removed from line " .. line)
end

function Debugger:listBreakpoints()
    print("\nBreakpoints:")
    for line, _ in pairs(self.breakpoints) do
        print("Line " .. line)
    end
end

function Debugger:shouldBreak()
    return self.breakpoints[self.machine.RIP]
end

function Debugger:processCommand(cmd, arg)
    if not cmd then return end
    
    -- Trim whitespace and convert to lowercase
    cmd = cmd:match("^%s*(.-)%s*$"):lower()
    arg = arg and arg:match("^%s*(.-)%s*$")
    
    -- Handle TUI commands first
    if cmd == "tui" then
        if arg == "start" and not self.tuiMode then
            local ok, TUI = pcall(require, "./lua/tui")
            if not ok then
                -- Try alternate path
                ok, TUI = pcall(require, "tui")
                if not ok then
                    print("Error loading TUI module: " .. tostring(TUI))
                    print("Current package.path: " .. package.path)
                    return true
                end
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
        print("Executing: " .. (line or "end of program"))
        if not self.machine:executeInstruction(line) then
            print("Program finished")
            return
        end
        self:printRegisters()
        
    elseif cmd == "c" or cmd == "continue" then
        while self.machine.RIP < #self.machine.currentCode do
            if self:shouldBreak() then
                print("Breakpoint hit at line " .. self.machine.RIP)
                break
            end
            local line = self.machine.currentCode[self.machine.RIP + 1]
            if not self.machine:executeInstruction(line) then break end
        end
        self:printRegisters()
        
    elseif cmd == "b" then
        self:setBreakpoint(arg)
        
    elseif cmd == "rb" then
        self:removeBreakpoint(arg)
        
    elseif cmd == "lb" then
        self:listBreakpoints()
        
    elseif cmd == "p" then
        local value = self.machine[arg]
        print(string.format("%s = %s", arg, value or "nil"))
        
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
        self.machine:fill(args[1], args[2], args[3])
        
    elseif cmd == "copy" then
        local args = {}
        for word in string.gmatch(arg, "%S+") do
            table.insert(args, word)
        end
        self.machine:copy(args[1], args[2], args[3])
        
    elseif cmd == "q" or cmd == "quit" then
        print("Debugger terminated")
        return
        
    else
        print("Unknown command '" .. cmd .. "'. Type 'h' for help")
    end
    return true
end

function Debugger:start()
    -- Auto-start TUI if machine is in debug mode and autoTUI is enabled
    if self.machine.debugMode and self.machine.autoTUI then
        local ok, TUI = pcall(require, "./lua/tui")
        if not ok then
            -- Try alternate path
            ok, TUI = pcall(require, "tui")
        end
        
        if ok then
            self.tui = TUI.new(self.machine, self)
            self.tuiMode = true
            self.tui:handleInput()
            return
        else
            print("Warning: Could not load TUI module, falling back to CLI mode")
            print("Error: " .. tostring(TUI))
            print("Current package.path: " .. package.path)
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
