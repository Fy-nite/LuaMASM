# Micro Native Interface (MNI) Documentation

The Micro Native Interface (MNI) allows LuaASM programs to interact with native Lua functions or external libraries. This feature enables advanced functionality such as mathematical operations, memory management, string manipulation, and system calls.

## How MNI Works

MNI functions are registered in the interpreter and can be directly called from LuaASM programs using the `MNI` instruction. MNI functions are identified by their namespace and name, separated by a dot (`.`). For example:

```asm
MNI Math.sin R1 R2
```

In this example:
- `Math` is the namespace.
- `sin` is the function name.
- `R1` and `R2` are the arguments (input and output registers).

### Key Features

- **Namespaces**: Organize related functions into groups (e.g., `Math`, `Memory`, `Debug`).
- **Arguments**: Pass arguments to MNI functions using registers.
- **Return Values**: Store results in registers or memory.

## Built-in MNI Functions

The interpreter includes several built-in MNI functions. For a complete list, see the [Instruction Set Documentation](v2instructions.md).

### Example: Math Functions

```asm
MOV R1 90          ; Angle in degrees
MNI Math.sin R1 R2 ; Calculate sine of R1, store result in R2
```

### Example: Memory Allocation

```asm
MOV R1 64          ; Allocate 64 bytes
MNI Memory.allocate R1 R2 ; Store the address in R2
```

## Creating Custom MNI Functions

You can extend the interpreter by creating your own MNI functions. Follow these steps:

### 1. Define the Function in Lua

Add your function to the `RegisterMachine`'s `functionTable`. For example, to create a custom `Math.square` function:

````lua
-- filepath: d:\luaasm\interp.lua
-- ...existing code...

function RegisterMachine:square(src, dest)
    self[dest] = self[src] * self[src]
end

-- Register the function
function RegisterMachine:registerMNIExamples()
    self:registerMNI("Math", "square", function(machine, src, dest)
        machine:square(src, dest)
    end)
end

-- Call this during initialization
registerMNIExamples(RegisterMachine.new(16))
-- ...existing code...
````

### 2. Register the Function

Use the `registerMNI` method to add your function to the `functionTable`. The `registerMNI` method takes three arguments:
- **Namespace**: The group name (e.g., `Math`).
- **Function Name**: The name of the function (e.g., `square`).
- **Function Implementation**: A Lua function that implements the behavior.

Example:

````lua
self:registerMNI("Math", "square", function(machine, src, dest)
    machine[dest] = machine[src] * machine[src]
end)
````

### 3. Call the Function in LuaASM

Once registered, you can call the function in your LuaASM program:

```asm
MOV R1 5           ; Set R1 to 5
MNI Math.square R1 R2 ; Calculate square of R1, store result in R2
```

### 4. Debugging Custom Functions

Use the debugger to inspect registers and memory while testing your custom MNI functions. For example:

```bash
lua interp.lua main.masm --debug
```

## Guidelines for Creating MNI Functions

1. **Use Namespaces**: Group related functions into namespaces to avoid naming conflicts.
2. **Validate Arguments**: Ensure that registers or memory addresses passed to your function are valid.
3. **Document Behavior**: Clearly document the purpose, arguments, and return values of your function.
4. **Test Thoroughly**: Use the debugger to verify that your function works as expected.

## Example: Advanced String Manipulation

Here’s an example of creating a custom MNI function to convert a string to uppercase:

````lua
-- filepath: d:\luaasm\interp.lua
-- ...existing code...

function RegisterMachine:toUpper(src, dest)
    local address = self[src]
    local result = ""
    while self.memory[address] and self.memory[address] ~= 0 do
        local char = string.char(self.memory[address])
        result = result .. string.upper(char)
        address = address + 1
    end

    -- Write the result to the destination address
    local destAddress = self[dest]
    for i = 1, #result do
        self.memory[destAddress + i - 1] = string.byte(result, i)
    end
    self.memory[destAddress + #result] = 0 -- Null-terminate
end

-- Register the function
self:registerMNI("String", "toUpper", function(machine, src, dest)
    machine:toUpper(src, dest)
end)
-- ...existing code...
````

### Usage in LuaASM

```asm
DB $100 "hello world" ; Define a string at memory address 100
MOV R1 100            ; Source address
MOV R2 200            ; Destination address
MNI String.toUpper R1 R2 ; Convert string to uppercase
OUT 1 $200            ; Output the result
```

## Notes

- MNI functions can interact with memory, registers, and external libraries.
- Use the `debug.lua` module to step through your code and verify behavior.
- Always clean up allocated memory to avoid leaks.

## Contributing MNI Functions

If you create useful MNI functions, consider contributing them to the project! Submit a pull request or share your code with the community.

## License

This documentation is part of the LuaASM project and is licensed under the MIT License.