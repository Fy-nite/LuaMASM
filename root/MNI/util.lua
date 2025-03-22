-- Utility Functions MNI Module

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
