-- Custom MNI Functions for LuaASM
-- This file demonstrates how to create MNI functions outside the main interpreter

-- The main function that registers all custom MNI functions with the interpreter
local function registerCustomMNI(machine)
    -- String manipulation functions
    registerStringFunctions(machine)
    
    -- Math extended functions
    registerMathFunctions(machine)
    
    -- File operations
    registerFileOperations(machine)
    
    -- Utility functions
    registerUtilityFunctions(machine)
end

-- String manipulation functions
function registerStringFunctions(machine)
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

    -- Concatenate two strings
    machine:registerMNI("String", "concat", function(machine, src1, src2, dest)
        local addr1 = machine[src1]
        local addr2 = machine[src2]
        local destAddr = machine[dest]
        local pos = 0
        
        -- Copy first string
        while machine.memory[addr1] and machine.memory[addr1] ~= 0 do
            machine.memory[destAddr + pos] = machine.memory[addr1]
            pos = pos + 1
            addr1 = addr1 + 1
        end
        
        -- Copy second string
        while machine.memory[addr2] and machine.memory[addr2] ~= 0 do
            machine.memory[destAddr + pos] = machine.memory[addr2]
            pos = pos + 1
            addr2 = addr2 + 1
        end
        
        -- Null terminate
        machine.memory[destAddr + pos] = 0
    end)
end

-- Extended math functions
function registerMathFunctions(machine)
    -- Calculate square root
    machine:registerMNI("MathExt", "sqrt", function(machine, src, dest)
        local value = machine[src]
        if value >= 0 then
            machine[dest] = math.sqrt(value)
        else
            -- Handle negative input
            machine[dest] = 0
            -- Set error flag (could use a designated error register)
            machine.RFLAGS = 1
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

-- File operations
function registerFileOperations(machine)
    -- Open file (mode: 1=read, 2=write, 3=append)
    machine:registerMNI("File", "open", function(machine, pathReg, modeReg, handleReg)
        local pathAddr = machine[pathReg]
        local mode = machine[modeReg]
        
        -- Extract path string
        local path = ""
        while machine.memory[pathAddr] and machine.memory[pathAddr] ~= 0 do
            path = path .. string.char(machine.memory[pathAddr])
            pathAddr = pathAddr + 1
        end
        
        -- Convert mode number to string
        local modeStr = "r"
        if mode == 2 then modeStr = "w"
        elseif mode == 3 then modeStr = "a" end
        
        -- Try to open the file
        local file, err = io.open(path, modeStr)
        if file then
            -- Store file handle in an internal table if not already present
            if not machine.fileHandles then
                machine.fileHandles = {}
            end
            
            -- Find a free handle ID
            local handleId = 1
            while machine.fileHandles[handleId] do
                handleId = handleId + 1
            end
            
            -- Store the file object
            machine.fileHandles[handleId] = file
            machine[handleReg] = handleId
            machine.RFLAGS = 0 -- Success
        else
            machine[handleReg] = 0
            machine.RFLAGS = 1 -- Error
        end
    end)
    
    -- Read line from file
    machine:registerMNI("File", "readLine", function(machine, handleReg, bufferReg)
        local handleId = machine[handleReg]
        local bufferAddr = machine[bufferReg]
        
        if machine.fileHandles and machine.fileHandles[handleId] then
            local line = machine.fileHandles[handleId]:read("*l")
            if line then
                -- Write the line to memory
                for i = 1, #line do
                    machine.memory[bufferAddr + i - 1] = string.byte(line, i)
                end
                machine.memory[bufferAddr + #line] = 0 -- Null-terminate
                machine.RFLAGS = 0 -- Success
            else
                -- End of file or error
                machine.memory[bufferAddr] = 0 -- Empty string
                machine.RFLAGS = 1 -- EOF or error
            end
        else
            -- Invalid handle
            machine.memory[bufferAddr] = 0 -- Empty string
            machine.RFLAGS = 2 -- Invalid handle
        end
    end)
    
    -- Write string to file
    machine:registerMNI("File", "writeString", function(machine, handleReg, bufferReg)
        local handleId = machine[handleReg]
        local bufferAddr = machine[bufferReg]
        
        if machine.fileHandles and machine.fileHandles[handleId] then
            -- Extract string from memory
            local str = ""
            while machine.memory[bufferAddr] and machine.memory[bufferAddr] ~= 0 do
                str = str .. string.char(machine.memory[bufferAddr])
                bufferAddr = bufferAddr + 1
            end
            
            -- Write to file
            local success = machine.fileHandles[handleId]:write(str)
            machine.RFLAGS = success and 0 or 1
        else
            -- Invalid handle
            machine.RFLAGS = 2 -- Invalid handle
        end
    end)
    
    -- Close file
    machine:registerMNI("File", "close", function(machine, handleReg)
        local handleId = machine[handleReg]
        
        if machine.fileHandles and machine.fileHandles[handleId] then
            machine.fileHandles[handleId]:close()
            machine.fileHandles[handleId] = nil
            machine.RFLAGS = 0 -- Success
        else
            machine.RFLAGS = 1 -- Invalid handle
        end
    end)
end

-- Utility functions
function registerUtilityFunctions(machine)
    -- Get current timestamp (in seconds since epoch)
    machine:registerMNI("Util", "time", function(machine, dest)
        machine[dest] = os.time()
    end)
    
    -- Sleep for milliseconds
    machine:registerMNI("Util", "sleep", function(machine, ms)
        local duration = machine[ms] / 1000  -- Convert to seconds
        local start = os.clock()
        while os.clock() - start < duration do
            -- Busy wait (not ideal but works in pure Lua)
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
    
    -- Parse hex string to number
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
    
    -- Convert number to hex string
    machine:registerMNI("Util", "intToHex", function(machine, valueReg, destReg)
        local value = machine[valueReg]
        local destAddr = machine[destReg]
        
        -- Convert to hex
        local hexStr = string.format("%X", value)
        
        -- Store result
        for i = 1, #hexStr do
            machine.memory[destAddr + i - 1] = string.byte(hexStr, i)
        end
        machine.memory[destAddr + #hexStr] = 0 -- Null-terminate
    end)
end

-- Return the registration function so it can be used by the interpreter
return registerCustomMNI
