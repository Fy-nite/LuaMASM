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
