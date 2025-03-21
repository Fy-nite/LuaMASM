# LuaASM Interpreter

LuaASM is a lightweight assembly-like language interpreter written in Lua. It supports a variety of instructions for arithmetic, flow control, stack operations, I/O, and more. LuaASM is designed to be extensible and includes features like debugging, TUI (Text User Interface), and MNI (Micro Native Interface) for advanced functionality.

## Features

- **Assembly-like Language**: Supports basic instructions like `MOV`, `ADD`, `SUB`, and more.
- **Flow Control**: Includes `JMP`, `CALL`, `RET`, and conditional jumps like `JE`, `JL`, etc.
- **Stack Operations**: Push and pop values to/from the stack.
- **I/O Operations**: Output strings or values to stdout or stderr using `OUT`.
- **Data Definition**: Define strings in memory using `DB`.
- **Debugger**: Step through code, inspect registers, memory, and stack.
- **TUI Mode**: Visualize code execution, registers, and stack in a terminal-based UI.
- **MNI Support**: Extend functionality with native system calls or external libraries.

## Getting Started

### Prerequisites

- Lua 5.4 or later installed on your system.
- A terminal or command prompt to run the interpreter.

### Installation

1. Clone the repository or copy the files into a directory.
2. Ensure the following directory structure:
   ```
   LuaASM\
   ├── interp.lua
   ├── debug.lua
   ├── tui.lua
   ├── root\
   │   └── stdio\
   │       └── print.masm
  
   ├── main.masm
   └── README.md
   ```

### Running the Interpreter

To execute a LuaASM program, run the following command:

```bash
lua interp.lua main.masm
```

### Example Program

Here’s an example program (`main.masm`) that outputs "hello world":

```asm
#include "stdio.print"
lbl main
    mov RAX 1
    mov RBX 100
    db $100 "hello world"
    call #printf
    hlt
```

### Debugging

Start the interpreter in debug mode:

```bash
lua interp.lua main.masm --debug-cli
```

In debug mode, you can step through instructions, inspect registers, and more. Type `h` in the debugger for a list of commands.

### TUI Mode

To enable the Text User Interface (TUI) for debugging:

```bash
lua interp.lua main.masm --debug
```

Then, in the debugger, type:

```bash
tui start
```

## Instruction Set

For a complete list of supported instructions, see [Instruction Set Documentation](v2instructions.md).

## Directory Structure

- `interp.lua`: The main interpreter.
- `debug.lua`: Debugger for stepping through code and inspecting state.
- `tui.lua`: Text User Interface for debugging.
- `root/`: Contains standard library files (e.g., `stdio.print`).
- `includes/`: Placeholder for Lua-based extensions.
- `main.masm`: Example program.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
