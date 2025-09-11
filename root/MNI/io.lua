-- IO Operations MNI Module (Stub)

return function(machine)
    -- Example: Write (stub)
    machine:registerMNI("IO", "write", function(machine, portReg, addrReg)
        -- Not implemented
        machine.RFLAGS = 0
    end)
    -- Add more IO operations as needed
end
