# LuaMASM Runtime

LuaMASM Runtime is a lightweight interpreter for the MicroASM assembly-like language, written in Lua. It enables execution of MicroASM programs on any Lua 5.4+ compatible platform, including Minecraft mods such as OpenComputers and ComputerCraft/CCTweaked, as well as standard PC environments (Windows, Mac, Linux). The runtime supports a wide range of instructions for arithmetic, flow control, stack operations, I/O, and more, with extensible features like debugging, TUI (Text User Interface), and MNI (Micro Native Interface) for advanced functionality.

## Features

- **Assembly-like Language**: Supports basic instructions like `MOV`, `ADD`, `SUB`, and more.
- **Flow Control**: Includes `JMP`, `CALL`, `RET`, and conditional jumps like `JE`, `JL`, etc.
- **Stack Operations**: Push and pop values to/from the stack.
- **I/O Operations**: Output strings or values to stdout or stderr using `OUT`.
- **Data Definition**: Define strings in memory using `DB`.
- **Debugger**: Step through code, inspect registers, memory, and stack.
- **TUI Mode**: Visualize code execution, registers, and stack in a terminal-based UI.
- **MNI Support**: Extend functionality with native system calls or external libraries.
- **Cross-Platform**: Runs on Lua-based machines in Minecraft (OpenComputers, ComputerCraft/CCTweaked) and standard PCs.

## Supported Platforms

- **Minecraft Mods**:
  - OpenComputers mod
  - ComputerCraft/CCTweaked mod
- **PC Platforms**:
  - Windows
  - macOS
  - Linux

Requires Lua 5.4 or later on the target platform.

## Getting Started

### Prerequisites

- Lua 5.4 or later installed on your system or mod environment.
- A terminal or command prompt to run the interpreter (for PC platforms).

### Installation

1. Clone the repository or copy the files into a directory.
2. Ensure the following directory structure:

```text
MicroASM\
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

To execute a MicroASM program, run the following command:

```bash
lua interp.lua main.masm
```

For Minecraft mods, load the Lua files into your in-game computer and execute similarly, adapting to the mod's Lua environment.

### Example Program

Here's an example program (`main.masm`) that outputs "hello world":

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

For a complete list of supported instructions, see [Instruction Set Documentation](docs/MicroV2.md).

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
