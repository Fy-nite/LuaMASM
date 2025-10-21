-- String Manipulation MNI Module

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
