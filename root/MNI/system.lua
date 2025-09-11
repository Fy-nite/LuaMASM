-- System Operations MNI Module (Stub)

return function(machine)
    -- Example: Sleep (stub)
    machine:registerMNI("System", "sleep", function(machine, msReg)
        -- Not implemented
        machine.RFLAGS = 0
    end)
    -- Add more system operations as needed
end
