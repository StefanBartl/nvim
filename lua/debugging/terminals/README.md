# debugging.terminals

Terminal debugging tools including keylogger for inspecting terminal input.

## Table of content

  - [Features](#features)
  - [Quick Start](#quick-start)
  - [Commands](#commands)
    - [`:TerminalKeyLoggerStart`](#terminalkeyloggerstart)
    - [`:TerminalKeyLoggerStop`](#terminalkeyloggerstop)
  - [Use Cases](#use-cases)
    - [1. Debug Terminal Keymaps](#1-debug-terminal-keymaps)
    - [2. Inspect Special Characters](#2-inspect-special-characters)
    - [3. Debug Key Sequences](#3-debug-key-sequences)
  - [API](#api)
    - [Module State](#module-state)
    - [`M.start()`](#mstart)
    - [`M.stop()`](#mstop)
  - [Architecture](#architecture)
    - [How It Works](#how-it-works)
    - [Code Flow](#code-flow)
  - [Limitations](#limitations)
    - [1. Terminal buffers only](#1-terminal-buffers-only)
    - [2. Blocking behavior](#2-blocking-behavior)
    - [3. No replay functionality](#3-no-replay-functionality)
  - [Troubleshooting](#troubleshooting)
    - [Keylogger not starting](#keylogger-not-starting)
    - [Not a terminal buffer](#not-a-terminal-buffer)
    - [Keys not showing](#keys-not-showing)
  - [Safety](#safety)
    - [No Password Capture](#no-password-capture)
    - [Buffer Scope](#buffer-scope)
    - [Performance](#performance)
  - [See Also](#see-also)

---

## Features

- ✅ **Key logging** - Captures all keypresses in terminal buffers
- ✅ **Real-time notifications** - Immediate feedback via vim.notify
- ✅ **Safe activation** - Only works in terminal buffers
- ✅ **Toggle control** - Start/stop logging on demand

---

## Quick Start

```lua
require("debugging.terminals").attach({ keylogger = true })
```

```vim
" In a terminal buffer
:TerminalKeyLoggerStart

" Press keys - they'll be logged
" i, j, k, <C-c>, etc.

:TerminalKeyLoggerStop
```

---

## Commands

### `:TerminalKeyLoggerStart`

Starts logging all keypresses in the current terminal buffer.

**Requirements:**
- Current buffer must be a terminal (`buftype == "terminal"`)

**Behavior:**
- Uses `vim.fn.getcharstr()` to capture keys
- Displays each key via `vim.notify()`
- Runs in background via `vim.schedule()`

**Example:**
```vim
" Open terminal
:terminal

" Start logging
:TerminalKeyLoggerStart

" Press keys
i
j
k
<C-c>

" Output in :messages:
[terminal_keylogger] Key pressed: "i"
[terminal_keylogger] Key pressed: "j"
[terminal_keylogger] Key pressed: "k"
[terminal_keylogger] Key pressed: "\3"  " <C-c>
```

---

### `:TerminalKeyLoggerStop`

Stops terminal keylogging.

**Example:**
```vim
:TerminalKeyLoggerStop
" [terminal_keylogger] Stopped logging keys.
```

---

## Use Cases

### 1. Debug Terminal Keymaps

Find out which keys are actually sent to the terminal:

```vim
:terminal
:TerminalKeyLoggerStart

" Press your keymap
<C-h>

" Check :messages
[terminal_keylogger] Key pressed: "\8"  " ASCII backspace
```

### 2. Inspect Special Characters

See how special keys are represented:

```vim
:TerminalKeyLoggerStart

<C-c>    → "\3"
<C-d>    → "\4"
<Esc>    → "\27"
<Tab>    → "\t"
<Enter>  → "\r" or "\n"
```

### 3. Debug Key Sequences

Capture multi-key sequences:

```vim
:TerminalKeyLoggerStart

" Type: jj
[terminal_keylogger] Key pressed: "j"
[terminal_keylogger] Key pressed: "j"
```

---

## API

### Module State

```lua
local M = require("debugging.terminals.keylogger")

-- Check if logging active
print(M.logging)  -- boolean

-- Get current buffer
print(M.bufnr)    -- integer|nil
```

### `M.start()`

Starts keylogging in current terminal buffer.

**Example:**
```lua
local keylogger = require("debugging.terminals.keylogger")
keylogger.start()
```

### `M.stop()`

Stops keylogging.

**Example:**
```lua
local keylogger = require("debugging.terminals.keylogger")
keylogger.stop()
```

---

## Architecture

### How It Works

1. **Activation**: `:TerminalKeyLoggerStart` sets `M.logging = true`
2. **Capture Loop**: `log_key()` function runs recursively via `vim.schedule()`
3. **Key Reading**: `vim.fn.getcharstr()` blocks until next keypress
4. **Notification**: Each key logged via `vim.notify()`
5. **Termination**: `:TerminalKeyLoggerStop` sets `M.logging = false`

### Code Flow

```lua
function log_key()
  if not M.logging then return end

  vim.schedule(function()
    if not M.logging then return end

    local ok, key = pcall(vim.fn.getcharstr)
    if ok and key then
      vim.notify(string.format("[terminal_keylogger] Key pressed: %q", key))
    end

    if M.logging then
      log_key()  -- Recursive call
    end
  end)
end
```

---

## Limitations

### 1. Terminal buffers only

Keylogger only works in terminal buffers (`buftype == "terminal"`).

**Workaround:** None - this is by design for safety.

### 2. Blocking behavior

`vim.fn.getcharstr()` blocks the event loop.

**Impact:** Neovim may appear frozen while waiting for input.

**Mitigation:** Use `vim.schedule()` to yield between captures.

### 3. No replay functionality

Logged keys are display-only, not recorded to file.

**Future Enhancement:** Add optional file output.

---

## Troubleshooting

### Keylogger not starting

**Symptom:** "Already logging!" or "Not currently logging!" warnings

**Solution:**
```vim
" Check state
:lua print(require("debugging.terminals.keylogger").logging)

" Force stop if stuck
:lua require("debugging.terminals.keylogger").logging = false
```

### Not a terminal buffer

**Symptom:** No keys logged

**Cause:** Current buffer is not a terminal

**Solution:**
```vim
" Check buffer type
:lua print(vim.bo.buftype)  " Should be "terminal"

" Open terminal first
:terminal
:TerminalKeyLoggerStart
```

### Keys not showing

**Symptom:** Keylogger started but no output

**Cause:** Keys might be consumed by terminal before logger sees them

**Solution:** This is expected for some terminal-specific keys.

---

## Safety

### No Password Capture

**Warning:** Keylogger captures ALL input including passwords.

**Best Practice:**
- Stop logging before entering sensitive data
- Clear `:messages` after debugging: `:messages clear`

### Buffer Scope

Keylogger only affects the buffer where it was started.

### Performance

Minimal impact - uses async scheduling.

---

## See Also

- [Main README](../..README.md)
- `:h debugging-terminals`
- [Neovim Terminal Mode](https://neovim.io/doc/user/nvim_terminal_emulator.html)

---
