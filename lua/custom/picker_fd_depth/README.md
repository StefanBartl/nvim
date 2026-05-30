# picker_fd_depth.nvim

## Table of content

- [picker_fd_depth.nvim](#picker_fd_depthnvim)
  - [Intro](#intro)
  - [Features](#features)
  - [Directory Structure](#directory-structure)
  - [Setup](#setup)
  - [Usage](#usage)
    - [1. Ex-Commands (Command Line)](#1-ex-commands-command-line)
    - [2. Interactive Keymap (Sequential UI)](#2-interactive-keymap-sequential-ui)
  - [Programmatic API](#programmatic-api)
  - [Architecture Compliance Notes](#architecture-compliance-notes)

---

## Intro

A lightweight, high-performance, and cross-platform Neovim module designed to execute file searches (`fd`) targeting a dynamic directory depth above the current Working Directory (`CWD`). It supports pluggable picker engines (**Telescope** and **fzf-lua**).

Built with strict compliance to team architecture principles: **zero startup footprint (100% lazy-loaded)**, robust input guarding, cross-platform safety, and integration with project-specific framework libraries.

## Features

- **Dynamic Depth Slicing:** Search files seamlessly up $N$ levels from your current working directory (e.g., `:FindFiles 2`).
- **Dual-Engine Architecture:** Toggle between `Telescope` and `fzf-lua` on the fly.
- **Strict Performance Guards:** Low-level core modules are completely lazy-loaded; requiring the entry point adds absolutely zero milliseconds to your Neovim startup time.
- **Robust Usability Guards:** Interrupted inputs via `<Esc>` abort instantly and silently instead of falling back to unsafe operations.
- **Cross-Platform Path Engine:** Utilizes isolated string manipulations and `vim.fs.normalize` to execute natively on Linux, macOS, Windows (PowerShell), and WSL without costly shell-spawning system calls.

## Directory Structure

```
nvim/lua/custom/picker_fd_depth/
  ├── README.md       # Module documentation
  ├── init.lua        # Orchestrator and entry point
  ├── core.lua        # Low-level business logic & engine routers (Lazy)
  ├── usercmds.lua    # Command registration wrapper
  └── keymaps.lua     # Interactive sequential UI wrapper

```

## Setup

Initialize the module inside your central mapping configuration or main `init.lua`:

```lua
require("custom.picker_fd_depth").setup()

```

This will automatically configure the `:FindFiles` UserCommand and bind the `<leader>fdd` key mapping using your configured framework handlers (`lib.usercmd` and `lib.map`).

## Usage

### 1. Ex-Commands (Command Line)

The system registers a smart command with argument autocompletion for picker engines:

```vim
:FindFiles [depth] [engine]

```

* `:FindFiles` — Searches current CWD using **Telescope** (Defaults).
* `:FindFiles 2` — Traverses **2 levels above** your CWD using Telescope.
* `:FindFiles 1 fzf` — Traverses **1 level above** your CWD using **fzf-lua**.

### 2. Interactive Keymap (Sequential UI)

Pressing **`<leader>fdd`** initiates a fail-safe interactive cascade using `vim.ui.input` and `lib.hover_select`:

1. **Prompt 1:** Asks for the depth level upwards. Type an integer or press `Enter` to default to `0` (current directory).
* *UX Guard:* Hitting `<Esc>` here cancels execution instantly and silently.


2. **Prompt 2:** Displays a structured dropdown list to select your active picker engine. Choose `telescope` or `fzf` (Defaults to `telescope` upon pressing `Enter`).

---

## Programmatic API

You can call the core logic directly inside your custom Lua automation workflows:

```lua
local core = require("custom.picker_fd_depth.core")

-- Search 3 directory levels above using fzf-lua
core.find_files(3, "fzf")

-- Fall back to default directory and Telescope safely on mixed or invalid values
core.find_files(-1, "unknown_engine")

```

---

## Architecture Compliance Notes

* **Zero Global Pollution:** All functions are encapsulated within localized modules.
* **No Side-Effects on Failure:** Directory status is verified with `vim.fn.isdirectory` before triggering any external picker UI to avoid hanging processes.
* **Framework Native:** Respects and prioritizes custom framework abstractions (`lib.usercmd`, `lib.map`, `lib.hover_select`, `lib.notify`) with clean standard fallback overrides.

---

