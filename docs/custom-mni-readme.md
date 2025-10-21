# Custom MNI Functions for LuaASM

This document explains how to use the custom MNI (Micro Native Interface) functions provided in `custom-mni.lua`.

## Getting Started

To use these custom MNI functions in your LuaASM interpreter, you need to:

1. Include the `custom-mni.lua` file with your LuaASM installation
2. Modify your `interp.lua` to require and register these functions

## Integration with Interpreter

Add the following code to your `interp.lua` file:

```lua
-- Near the end of your interp.lua file, before the main() function
local function loadCustomMNI(machine)
    local ok, customMNI = pcall(require, "custom-mni")
    if ok then
        customMNI(machine)
    else
        print("Warning: Could not load custom MNI functions: " .. tostring(customMNI))
    end
end

-- Find the initialization code in your interp.lua and add this line:
-- (typically right after creating the machine instance)
local machine = RegisterMachine.new(16)
loadCustomMNI(machine) -- Add this line
```

## Available Functions

### String Manipulation

#### String.toUpper
Converts a null-terminated string to uppercase.
- **Input**: Source address register, Destination address register
- **Output**: Uppercase string written to destination address

#### String.toLower
Converts a null-terminated string to lowercase.
- **Input**: Source address register, Destination address register
- **Output**: Lowercase string written to destination address

#### String.length
Calculates the length of a null-terminated string.
- **Input**: Source address register, Destination register for result
- **Output**: Length stored in destination register

#### String.concat
Concatenates two null-terminated strings.
- **Input**: First string address register, Second string address register, Destination address register
- **Output**: Combined string written to destination address

### Math Extensions

#### MathExt.sqrt
Calculates the square root of a number.
- **Input**: Source register containing number, Destination register for result
- **Output**: Square root stored in destination register

#### MathExt.random
Generates a random number between min and max values.
- **Input**: Min value register, Max value register, Destination register
- **Output**: Random number stored in destination register

#### MathExt.round
Rounds a floating-point number to the nearest integer.
- **Input**: Source register containing number, Destination register for result
- **Output**: Rounded number stored in destination register

#### MathExt.abs
Calculates the absolute value of a number.
- **Input**: Source register containing number, Destination register for result
- **Output**: Absolute value stored in destination register

### File Operations

#### File.open
Opens a file.
- **Input**: Path string address register, Mode register (1=read, 2=write, 3=append), Handle register
- **Output**: File handle stored in handle register, RFLAGS set to 0 on success, 1 on failure

#### File.readLine
Reads a line from an open file.
- **Input**: File handle register, Buffer address register
- **Output**: Line written to buffer address, RFLAGS set to 0 on success, 1 on EOF/error, 2 on invalid handle

#### File.writeString
Writes a string to an open file.
- **Input**: File handle register, String address register
- **Output**: RFLAGS set to 0 on success, 1 on error, 2 on invalid handle

#### File.close
Closes an open file.
- **Input**: File handle register
- **Output**: RFLAGS set to 0 on success, 1 on invalid handle

### Utility Functions

#### Util.time
Gets the current timestamp in seconds since epoch.
- **Input**: Destination register
- **Output**: Timestamp stored in destination register

#### Util.sleep
Pauses execution for the specified number of milliseconds.
- **Input**: Milliseconds register
- **Output**: None

#### Util.formatDate
Formats a timestamp according to the specified format string.
- **Input**: Timestamp register, Format string address register, Destination address register
- **Output**: Formatted date string written to destination address

#### Util.hexToInt
Converts a hex string to an integer.
- **Input**: Hex string address register, Destination register
- **Output**: Integer value stored in destination register

#### Util.intToHex
Converts an integer to a hex string.
- **Input**: Value register, Destination address register
- **Output**: Hex string written to destination address

## Example Program

See `example-mni.masm` for examples of how to use these functions.

## Creating Your Own MNI Functions

You can use the `custom-mni.lua` file as a template to create your own MNI functions. Follow these guidelines:

1. Group related functions into a namespace
2. Validate all inputs
3. Handle error cases
4. Use RFLAGS to indicate success/failure where appropriate

```lua
-- Example of creating a custom MNI function
machine:registerMNI("MyNamespace", "myFunction", function(machine, inputReg, outputReg)
    -- Get input value from register
    local input = machine[inputReg]
    
    -- Process the value
    local result = input * 2
    
    -- Store result
    machine[outputReg] = result
end)
```
