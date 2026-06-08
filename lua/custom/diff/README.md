# custom/diff

A self-contained Neovim diff subsystem with three opt-in components.

---

## Table of Contents

- [Overview](#overview)
- [File Structure](#file-structure)
- [Setup](#setup)
- [Components](#components)
  - [diff_exit](#diff_exit)
  - [diff_origin](#diff_origin)
  - [diff — the :Diff command](#diff--the-diff-command)
- [:Diff Command Reference](#diff-command-reference)
  - [Parameters](#parameters)
  - [Examples](#examples)
- [Design Notes](#design-notes)

---

## Overview

```
custom/diff/
├── init.lua            ← entry point; call .enable(opts) here
├── diff_exit.lua       ← safe :q / :DiffExit for diffmode
├── diff_origin.lua     ← :DiffOrigin — buffer vs. last-saved version
├── @types/
│   └── init.lua        ← all LuaLS type annotations
└── README.md           ← you are here
```

---

## Setup

Call `enable` once — typically inside your plugin loader or `init.lua`.

```lua
require("custom.diff").enable({
  diff_exit   = true,
  diff_origin = true,
  diff        = true,
})
```

All flags are opt-in. To enable everything at once:

```lua
require("custom.diff").enable({ enable_all = true })
```

`enable` is **idempotent** — repeated calls after the first are silent no-ops.

---

## Components

### diff_exit

Provides a safe way to quit diffmode without leaving orphaned windows or
lingering `diff` option state.

| Command / map | Action |
|---|---|
| `:DiffExit` | Disables diffmode and closes all associated windows cleanly |
| `q` (in diffmode) | Mapped to `:DiffExit` automatically |

Enable:
```lua
require("custom.diff").enable({ diff_exit = true })
```

---

### diff_origin

Compares the current buffer against its last-saved version (disk or git HEAD).

| Command | Action |
|---|---|
| `:DiffOrigin` | Opens a vsplit showing the saved version with diffmode active |

Enable:
```lua
require("custom.diff").enable({ diff_origin = true })
```

---

### diff — the :Diff command

A flexible diff command that bridges the current editor state with any external
content source.

Enable:
```lua
require("custom.diff").enable({ diff = true })
```

---

## :Diff Command Reference

```
:Diff [target=…] [source=…] [view=…] [output=…]
```

All parameters are **optional and named** (`key=value` syntax).
Omitting a parameter falls back to its documented default.

### Parameters

#### `target=` — what to compare against *(required, but interactive when omitted)*

| Value | Description |
|---|---|
| `clipboard` | Content of the system clipboard (`+` register) |
| `<path>` | A file path — relative or absolute; tab-completion works |
| `<bufnr>` | The number of an already-open Neovim buffer |

When `target` is **not supplied**, a small selection popup appears with the
three choices above. Pick one and the diff proceeds automatically.

---

#### `source=` — the baseline to compare from *(default: `current`)*

| Value | Description |
|---|---|
| `current` | The buffer active at the moment `:Diff` was typed *(default)* |
| `<path>` | A file path |
| `<bufnr>` | A buffer number |

---

#### `view=` — how the comparison is rendered *(default: `vsplit`)*

| Value | Description |
|---|---|
| `vsplit` | Side-by-side vertical split with native diffmode *(default)* |
| `split` | Horizontal split with native diffmode |
| `inline` | Reserved for a future in-place rendering mode |

---

#### `output=` — where the result goes *(default: `buffer`)*

| Value | Description |
|---|---|
| `buffer` | Interactive scratch buffer inside the split *(default)* |
| `prompt` | Unified-diff text shown in the more-prompt (`:h more-prompt`) |
| `file` | Unified diff written to a temporary `.diff` file on disk |

---

### Examples

```vim
" No arguments — pick target interactively
:Diff

" Compare current buffer against the clipboard
:Diff target=clipboard

" Compare current buffer against an older file
:Diff target=../archive/main.lua

" Compare current buffer against another open buffer, horizontal split
:Diff target=3 view=split

" Compare two arbitrary files without being in either
:Diff target=a.lua source=b.lua

" Get a quick unified diff in the command area instead of opening a window
:Diff target=clipboard output=prompt

" Write the diff to a file for later review
:Diff target=../old.lua output=file

" Close all :Diff windows and clear diffmode everywhere
:DiffClear
```

---

## Design Notes

**No external processes.**
All diff computation uses `vim.diff()`, Neovim's built-in C implementation.
No shell commands, no `git diff`, no spawned processes.

**Context snapshot.**
`source_bufnr` and `origin_win` are captured *immediately* on `:Diff` invocation,
before any asynchronous step (the interactive picker). This prevents race
conditions when the user switches buffers during the popup.

**Scratch buffer lifecycle.**
Every scratch buffer opened by `:Diff` is registered in an internal list.
`:DiffClear` and a `VimLeavePre` autocmd guarantee they are wiped on exit.
Buffer handles are validated with `nvim_buf_is_valid()` before every API call.

**Idempotent setup.**
`enable()` uses a `_setup_done` guard. Sourcing your config multiple times or
calling `enable` from several places is safe.

**lib integration.**
Where available, `lib.notify`, `lib.usercmd`, and `lib.hover_select` are used
in preference to their Neovim built-in equivalents. Each falls back gracefully
when the library is not present.
