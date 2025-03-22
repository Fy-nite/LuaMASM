# MNI Modules Documentation

This document explains how to create, organize, and use MNI modules in LuaASM.

## What are MNI Modules?

MNI (Micro Native Interface) modules are Lua scripts that define custom functions that can be called from LuaASM programs. These modules are loaded dynamically when the interpreter starts up, allowing for a modular and extensible system.

## Module Location

MNI modules are stored in the `root/MNI` directory by default. You can change this location using the `--mni=<folder>` command-line option when running the interpreter.

## Module Structure

Each module is a Lua script that returns a function. This function takes a `machine` parameter and registers MNI functions using the `registerMNI` method.

### Basic Module Template

```lua
-- MyModule.lua
return function(machine)
    -- Register MNI functions
    machine:registerMNI("Namespace", "functionName", function(machine, arg1, arg2)
        -- Implementation
    end)
    
    machine:registerMNI("Namespace", "anotherFunction", function(machine, arg1, arg2, arg3)
        -- Implementation
    end)
end
```

## Organizing Modules

It's recommended to group related functions into a single module with a common namespace. For example:

- `string.lua` - String manipulation functions (namespace: `String`)
- `math.lua` - Mathematical functions (namespace: `MathExt`)
- `file.lua` - File operations (namespace: `File`)
- `network.lua` - Networking functions (namespace: `Net`)

## Using MNI Functions in LuaASM

Once registered, MNI functions can be called from LuaASM code using the `MNI` instruction:

```asm
MNI Namespace.functionName R1 R2
```

Where:
- `Namespace.functionName` is the full function name
- `R1`, `R2` are registers passed as arguments

## Example Module: String Operations

Here's an example of a module that provides string manipulation functions:

```lua
-- string.lua
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
end
```

## Example Usage in LuaASM

```asm
; String manipulation example
DB $100 "hello world!"               ; Define source string
MOV R1 100                           ; Source address
MOV R2 200                           ; Destination address
MNI String.toUpper R1 R2             ; Convert to uppercase
OUT 1 $200                           ; Print result (HELLO WORLD!)
```

## Creating Your Own Modules

To create a new module:

1. Create a `.lua` file in the `root/MNI` directory
2. Define your module with a return function that takes a machine parameter
3. Register your MNI functions using `machine:registerMNI`
4. Test your module with a simple LuaASM program

The interpreter will automatically load your module at startup.
