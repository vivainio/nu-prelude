# nu-prelude

A collection of useful Nushell modules including set operations, git helpers, JWT utilities, an Obsidian vault manager, and a native prompt.

## Modules

### nuship.nu - Native Nushell Prompt

A lightweight, native Nushell prompt replacement for Starship. Displays:
- Penguin icon (on WSL)
- Current directory (with `~` for home)
- Git branch in the right prompt (purple)

### git-helpers.nu - Fast Git Helpers

Fast git branch detection by reading `.git/HEAD` directly instead of spawning `git` processes. Supports regular repos and worktrees.

- `find-in-parents` - Find a file/directory by searching up from current directory
- `fast-get-git-branch` - Get current branch name (or short commit hash if detached)

### sets.nu - Mathematical Set Operations

Comprehensive set theory functions using Nushell lists. See [SETS.md](SETS.md) for full documentation.

### jwt.nu - JWT Utilities

Decode and inspect JSON Web Tokens:
- `decode jwt` - Parse a JWT and return header, payload, signature, and decoded timestamps

### nun.nu - Obsidian Vault Manager

Tools for interacting with Obsidian vaults from the command line:
- `nun set-vault` - Set vault path (with `--journal` for journal vault)
- `nun list` - List all notes
- `nun new` - Create a new note
- `nun read` - Read a note's content
- `nun search` - Search for notes containing text
- `nun append` - Append text to a note
- `nun open` - Open a note or vault
- `nun journal` - Show recent journal entries
- `nunn` - Quick access to today's journal

## Installation

### nuship (Prompt)

Add to your config file (`config nu`):

```nushell
source ~/nu-prelude/nuship.nu
```

### All Modules

To use all modules (sets, jwt, nun, git-helpers), add to your config:

```nushell
use ~/nu-prelude/mod.nu *
```

### Individual Modules

```nushell
use ~/nu-prelude/sets.nu *
use ~/nu-prelude/jwt.nu *
use ~/nu-prelude/nun.nu *
use ~/nu-prelude/git-helpers.nu *
```

## License

MIT License

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 