Warning: Could not open src/custom-mni.lua
Warning: Could not open src/debugger.lua
Warning: Could not open src/interp.lua
Warning: Could not open src/tui.lua
local fileArray = {
["root/MNI/stringoperations.lua"] = [====[-- Advanced String Operations MNI Module (Stub)

return function(machine)
    -- Example: toUpper (already in string.lua)
    -- Example: toLower (already in string.lua)
    -- Example: trim (stub)
    machine:registerMNI("StringOperations", "trim", function(machine, src, dest)
        -- Not implemented
        machine.RFLAGS = 1 -- Error
    end)
    -- Add more advanced string operations as needed
end
]====],
["root/MNI/file.lua"] = [====[-- File Operations MNI Module (Stub)

return function(machine)
    -- Example: Open file (stub)
    machine:registerMNI("File", "open", function(machine, pathReg, modeReg, handleReg)
        -- Not implemented
        machine[handleReg] = 0
        machine.RFLAGS = 1 -- Error
    end)
    -- Add more file operations as needed
end
]====],
["root/MNI/util.lua"] = [====[-- Utility Functions MNI Module

return function(machine)
    -- Get current timestamp
    machine:registerMNI("Util", "time", function(machine, dest)
        machine[dest] = os.time()
    end)
    
    -- Sleep for milliseconds
    machine:registerMNI("Util", "sleep", function(machine, ms)
        local duration = machine[ms] / 1000  -- Convert to seconds
        local start = os.clock()
        while os.clock() - start < duration do
            -- Busy wait
        end
    end)
    
    -- Format date/time
    machine:registerMNI("Util", "formatDate", function(machine, timestampReg, formatAddrReg, destAddrReg)
        local timestamp = machine[timestampReg]
        local formatAddr = machine[formatAddrReg]
        local destAddr = machine[destAddrReg]
        
        -- Extract format string
        local formatStr = ""
        while machine.memory[formatAddr] and machine.memory[formatAddr] ~= 0 do
            formatStr = formatStr .. string.char(machine.memory[formatAddr])
            formatAddr = formatAddr + 1
        end
        
        -- Format date
        local dateStr = os.date(formatStr, timestamp)
        
        -- Store result
        for i = 1, #dateStr do
            machine.memory[destAddr + i - 1] = string.byte(dateStr, i)
        end
        machine.memory[destAddr + #dateStr] = 0 -- Null-terminate
    end)
    
    -- Convert hex string to integer
    machine:registerMNI("Util", "hexToInt", function(machine, srcReg, destReg)
        local srcAddr = machine[srcReg]
        
        -- Extract hex string
        local hexStr = ""
        while machine.memory[srcAddr] and machine.memory[srcAddr] ~= 0 do
            hexStr = hexStr .. string.char(machine.memory[srcAddr])
            srcAddr = srcAddr + 1
        end
        
        -- Convert to number
        local value = tonumber(hexStr, 16) or 0
        machine[destReg] = value
    end)
end
]====],
["tests/test_macro.masm"] = [====[; Test macro expansion and unique labels
MACRO inc_twice reg
    INC reg
    INC reg
ENDMACRO

STATE result <QWORD> 0

LBL main
    MOV R1 10
    inc_twice R1
    MOV result R1
    HLT
; EXPECT result 12
]====],
["root/MNI/macro.lua"] = [====[-- MicroASM Macro management module
-- Handles macro definition, expansion, and unique local labels

local Macro = {}
Macro.__index = Macro

function Macro.new()
    local self = setmetatable({}, Macro)
    self.macros = {} -- name -> {params, body}
    self.expansionCount = {} -- name -> count
    return self
end

function Macro:define(name, params, body)
    if self.macros[name] then error("Duplicate macro: "..name) end
    self.macros[name] = {params = params, body = body}
    self.expansionCount[name] = 0
end

function Macro:expand(name, args)
    local macro = self.macros[name]
    if not macro then error("Macro not found: "..name) end
    if #args ~= #macro.params then error("Macro argument count mismatch for "..name) end
    self.expansionCount[name] = self.expansionCount[name] + 1
    local uniq = self.expansionCount[name]
    local expanded = {}
    for _, line in ipairs(macro.body) do
        local l = line
        -- Parameter substitution
        for i, param in ipairs(macro.params) do
            l = l:gsub(param, args[i])
        end
        -- Unique local label substitution (@@label)
        l = l:gsub("@@(%w+)", function(lbl)
            return string.format("..@%s@%d@%s", name, uniq, lbl)
        end)
        table.insert(expanded, l)
    end
    return expanded
end

return Macro
]====],
["root/MNI/io.lua"] = [====[-- IO Operations MNI Module (Stub)

return function(machine)
    -- Example: Write (stub)
    machine:registerMNI("IO", "write", function(machine, portReg, addrReg)
        -- Not implemented
        machine.RFLAGS = 0
    end)
    -- Add more IO operations as needed
end
]====],
["root/MNI/debug.lua"] = [====[-- Debugging Operations MNI Module (Stub)

return function(machine)
    -- Example: Breakpoint (stub)
    machine:registerMNI("Debug", "breakpoint", function(machine)
        -- Not implemented
        machine.RFLAGS = 0
    end)
    -- Add more debugging operations as needed
end
]====],
["root/MNI/memory.lua"] = [====[-- Memory Management MNI Module (Stub)

return function(machine)
    -- Example: Allocate (stub)
    machine:registerMNI("Memory", "allocate", function(machine, sizeReg, addrReg)
        -- Not implemented
        machine[addrReg] = 0
        machine.RFLAGS = 1 -- Error
    end)
    
end
]====],
["root/MNI/system.lua"] = [====[-- System Operations MNI Module (Stub)

return function(machine)
    -- Example: Sleep (stub)
    machine:registerMNI("System", "sleep", function(machine, msReg)
        -- Not implemented
        machine.RFLAGS = 0
    end)
    -- Add more system operations as needed
end
]====],
["tests/test_state.masm"] = [====[; Test STATE variable usage
STATE counter <QWORD> 42
STATE flag <BYTE> 1

LBL main
    MOV R1 counter
    MOV R2 flag
    HLT
; EXPECT R1 42
; EXPECT R2 1
]====],
["root/MNI/filesystem.lua"] = [====[-- File System Operations MNI Module (Stub)

return function(machine)
    -- Example: Open file (stub)
    machine:registerMNI("FileSystem", "open", function(machine, pathReg, modeReg, handleReg)
        -- Not implemented
        machine[handleReg] = 0
        machine.RFLAGS = 1 -- Error
    end)
    -- Add more file system operations as needed
end
]====],
["root/MNI/string.lua"] = [====[-- String Manipulation MNI Module

return function(machine)
    -- Convert string to uppercase
    machine:registerMNI("String", "toUpper", function(machine, src, dest)
        local address = machine[src]
        local result = ""
        
        -- Read the source string
        while machine.memory[address] and machine.memory[address] ~= 0 do
            local char = string.char(machine.memory[address])
            result = result .. string.upper(char)
            address = address + 1
        end

        -- Write the result to the destination address
        local destAddress = machine[dest]
        for i = 1, #result do
            machine.memory[destAddress + i - 1] = string.byte(result, i)
        end
        machine.memory[destAddress + #result] = 0 -- Null-terminate
    end)
    machine:registerMNI("String", "equals", function(machine, str1AddrReg, str2AddrReg, resultReg)
        local addr1 = machine[str1AddrReg]
        local addr2 = machine[str2AddrReg]
        
        -- loop through both strings, build a string for each in lua and compare
        local str1 = ""
        while machine.memory[addr1] and machine.memory[addr1] ~= 0 do
            str1 = str1 .. string.char(machine.memory[addr1])
            addr1 = addr1 + 1
        end 
        local str2 = ""
        while machine.memory[addr2] and machine.memory[addr2] ~= 0 do
            str2 = str2 .. string.char(machine.memory[addr2])
            addr2 = addr2 + 1
        end
        if str1 == str2 then
            machine[resultReg] = 1
        else
            machine[resultReg] = 0
        end
    end)
    -- Convert string to lowercase
    machine:registerMNI("String", "toLower", function(machine, src, dest)
        local address = machine[src]
        local result = ""
        
        -- Read the source string
        while machine.memory[address] and machine.memory[address] ~= 0 do
            local char = string.char(machine.memory[address])
            result = result .. string.lower(char)
            address = address + 1
        end

        -- Write the result to the destination address
        local destAddress = machine[dest]
        for i = 1, #result do
            machine.memory[destAddress + i - 1] = string.byte(result, i)
        end
        machine.memory[destAddress + #result] = 0 -- Null-terminate
    end)

    -- Get string length
    machine:registerMNI("String", "length", function(machine, src, dest)
        local address = machine[src]
        local length = 0
        
        -- Count characters until null terminator
        while machine.memory[address] and machine.memory[address] ~= 0 do
            length = length + 1
            address = address + 1
        end
        
        machine[dest] = length
    end)
end
]====],
["root/MNI/datastructures.lua"] = [====[-- Data Structures MNI Module (Stub)

return function(machine)
    -- Example: Create List (stub)
    machine:registerMNI("DataStructures", "createList", function(machine, handleReg)
        -- Not implemented
        machine[handleReg] = 0
        machine.RFLAGS = 1 -- Error
    end)
    -- Add more data structure operations as needed
end
]====],
["root/MNI/state.lua"] = [====[-- MicroASM STATE variable management module
-- Handles parsing, storage, and scoping of STATE variables

local State = {}
State.__index = State

function State.new()
    local self = setmetatable({}, State)
    self.global = {}      -- Global state variables
    self.scopes = {}      -- Stack of local scopes
    return self
end

function State:enterScope(scopeName)
    table.insert(self.scopes, {name = scopeName, vars = {}})
end

function State:leaveScope()
    table.remove(self.scopes)
end

function State:declare(name, typeStr, initial)
    local var = {type = typeStr, value = initial or 0}
    if #self.scopes > 0 then
        local scope = self.scopes[#self.scopes]
        if scope.vars[name] then error("Duplicate STATE variable in scope: "..name) end
        scope.vars[name] = var
    else
        if self.global[name] then error("Duplicate global STATE variable: "..name) end
        self.global[name] = var
    end
end

function State:get(name, scopeChain)
    -- scopeChain: array of scope names from innermost to outermost
    for i = #self.scopes, 1, -1 do
        local scope = self.scopes[i]
        if scope.vars[name] then return scope.vars[name] end
    end
    return self.global[name]
end

function State:set(name, value)
    for i = #self.scopes, 1, -1 do
        local scope = self.scopes[i]
        if scope.vars[name] then scope.vars[name].value = value; return end
    end
    if self.global[name] then self.global[name].value = value; return end
    error("STATE variable not found: "..name)
end

return State
]====],
["root/MNI/network.lua"] = [====[-- Network Operations MNI Module (Stub)

return function(machine)
    -- Example: HTTP GET (stub)
    machine:registerMNI("Net", "httpGet", function(machine, urlReg, destReg)
        -- Not implemented
        machine.RFLAGS = 1 -- Error
    end)
    -- Add more network operations as needed
end
]====],
["root/stdio/print.masm"] = [====[lbl printf
    out RAX $RBX
    ret]====],
["root/MNI/math.lua"] = [====[-- Extended Math Functions MNI Module

return function(machine)
    -- Calculate square root
    machine:registerMNI("MathExt", "sqrt", function(machine, src, dest)
        local value = machine[src]
        if value >= 0 then
            machine[dest] = math.sqrt(value)
        else
            machine[dest] = 0
            machine.RFLAGS = 1  -- Error flag
        end
    end)
    
    -- Random number generator with range
    machine:registerMNI("MathExt", "random", function(machine, min, max, dest)
        local minVal = machine[min]
        local maxVal = machine[max]
        machine[dest] = math.random(minVal, maxVal)
    end)
    
    -- Round to nearest integer
    machine:registerMNI("MathExt", "round", function(machine, src, dest)
        machine[dest] = math.floor(machine[src] + 0.5)
    end)
    
    -- Calculate absolute value
    machine:registerMNI("MathExt", "abs", function(machine, src, dest)
        machine[dest] = math.abs(machine[src])
    end)
end
]====],
}
return fileArray
