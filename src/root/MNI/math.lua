-- Extended Math Functions MNI Module

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
