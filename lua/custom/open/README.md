# custom.open

Unified `:Open <target>` command for Neovim — dispatches the text under the cursor
(or a visual selection) to a browser, file manager, text editor, or a Neovim split/tab.

Follows the same architecture as `:Insert` and `:Format`.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Available Targets](#available-targets)
- [Usage](#usage)
  - [Normal Mode](#normal-mode)
  - [Visual Mode](#visual-mode)
  - [Tab Completion](#tab-completion)
- [Target Reference](#target-reference)
  - [Browser Targets](#browser-targets)
  - [:Open filemanager](#open-filemanager)
  - [:Open notepad / editor](#open-notepad--editor)
  - [:Open split / vsplit / tab](#open-split--vsplit--tab)
- [Configuration](#configuration)
- [Extending with Custom Handlers](#extending-with-custom-handlers)
- [Suggested Keymaps](#suggested-keymaps)
- [Architecture](#architecture)
- [Platform Notes](#platform-notes)
- [See Also](#see-also)

---

## Quick Start

```lua
-- custom/init.lua (or wherever you load your custom modules)
require("custom.open").setup()
```

```vim
" Open URL under cursor in the system browser
:Open browser

" Open path in the file manager
:Open filemanager

" Open text in Notepad / TextEdit / gedit
:Open notepad

" Open file path in a Neovim split
:Open split
```

---

## Features

- **Browser dispatch** — default, Chrome, Chromium, Firefox, Edge, Safari
- **File manager** — Explorer, Finder, Nautilus, Thunar, … (auto-detected)
- **Text editor** — Notepad.exe, TextEdit, xdg-open, gedit, kate, …
- **Neovim splits/tabs** — open local file paths inside the session
- **Smart context** — visual selection preferred; falls back to `<cWORD>`
- **URL heuristics** — non-URL text sent to browsers becomes a Google search
- **Tab completion** — all registered targets are completable
- **Cross-platform** — Windows, macOS, Linux, WSL
- **Extensible** — register custom handlers with a three-field table

---

## Available Targets

| Target        | Description                                        |
|---------------|----------------------------------------------------|
| `browser`     | System default browser                             |
| `chrome`      | Google Chrome (Chromium on Linux if absent)        |
| `chromium`    | Chromium                                           |
| `firefox`     | Mozilla Firefox                                    |
| `edge`        | Microsoft Edge                                     |
| `safari`      | Safari (macOS only)                                |
| `filemanager` | System file manager                                |
| `notepad`     | System default text editor (via temp file)         |
| `editor`      | Alias for `notepad`                                |
| `split`       | Open file in Neovim horizontal split               |
| `vsplit`      | Open file in Neovim vertical split                 |
| `tab`         | Open file in new Neovim tab                        |

---

## Usage

### Normal Mode

Place the cursor on any word, URL, or path:

```vim
" Cursor on: https://neovim.io
:Open browser        " → opens https://neovim.io

" Cursor on: /home/alice/docs
:Open filemanager    " → opens Nautilus / Explorer at /home/alice/docs

" Cursor on: lua/custom/insert/init.lua
:Open split          " → :split lua/custom/insert/init.lua
```

### Visual Mode

Select text in visual or visual-line mode, then run `:Open`:

```
" Visual: select 'my search query'
:Open browser        " → opens Google search for 'my search query'

" Visual: select multi-line log snippet
:Open notepad        " → writes to temp file, opens in text editor
```

The `'<` and `'>` marks are read after exiting visual mode, so the selection
is available even when the command line has focus.

### Tab Completion

```vim
:Open <Tab>
" → browser, chrome, chromium, edge, editor, filemanager,
"   firefox, notepad, safari, split, tab, vsplit
```

---

## Target Reference

### Browser Targets

All browser targets handle text as follows:

| Input text         | Behaviour                              |
|--------------------|----------------------------------------|
| `https://…`        | Passed through unchanged               |
| `www.example.com`  | Prefixed with `https://`               |
| `/home/alice/file` | Opened as `file:///home/alice/file`    |
| `pcall`            | Google search for `pcall`              |

```vim
:Open browser    " system default
:Open chrome
:Open chromium
:Open firefox
:Open edge
:Open safari     " macOS only; warns on other platforms
```

### :Open filemanager

Resolves `~` and relative paths, then opens the result in the native GUI
file manager.  URL text is rejected.

```vim
" Cursor on: ~/projects/reposcope
:Open filemanager
" → Nautilus / Finder / Explorer at ~/projects/reposcope
```

**macOS note:** directories use `open <dir>`; files use `open -R <file>`
(Reveal in Finder).

**WSL note:** `wslpath -w` is used to convert the Unix path before calling
`explorer.exe`.

### :Open notepad / editor

Writes context text to a temporary `.txt` file and opens it in the platform
GUI text editor.

```vim
" Visual: select any block of text
:Open notepad    " → writes to /tmp/nvimXXXX.txt, opens in editor
:Open editor     " alias — same behaviour
```

The temporary file is **not** deleted automatically; you can review or save it.

### :Open split / vsplit / tab

Opens a local file path inside the current Neovim session.  The path must
exist on disk; URLs are rejected.

```vim
" Cursor on: lua/custom/format/init.lua
:Open split      " horizontal split
:Open vsplit     " vertical split
:Open tab        " new tab
```

---

## Configuration

```lua
require("custom.open").setup({
  -- Handler to use when :Open is called with no arguments.
  -- nil (default) prints the usage / available-targets message.
  default_handler = nil,
})
```

---

## Extending with Custom Handlers

Register a handler before or after `setup()`:

```lua
local registry = require("custom.open.registry")

registry.register({
  key  = "vscode",
  desc = "Open file or folder in Visual Studio Code",
  run  = function(ctx)
    if ctx.is_url then return false end
    local path = vim.fn.expand(ctx.text)
    vim.system({ "code", path }, { detach = true }, nil)
    vim.notify("[open] VS Code: " .. path)
    return true
  end,
})
```

Handler contract:

| Field  | Type                               | Description                  |
|--------|------------------------------------|------------------------------|
| `key`  | `string`                           | Unique target name (no spaces)|
| `desc` | `string`                           | One-line description          |
| `run`  | `fun(ctx: Custom.Open.Context): boolean` | Returns `true` on success |

---

## Suggested Keymaps

```lua
local map = vim.keymap.set

map("n", "<leader>ob", "<Cmd>Open browser<CR>",     { desc = "Open: browser" })
map("n", "<leader>of", "<Cmd>Open filemanager<CR>", { desc = "Open: filemanager" })
map("n", "<leader>on", "<Cmd>Open notepad<CR>",     { desc = "Open: notepad" })
map("n", "<leader>os", "<Cmd>Open split<CR>",       { desc = "Open: split" })
map("n", "<leader>ov", "<Cmd>Open vsplit<CR>",      { desc = "Open: vsplit" })
map("n", "<leader>ot", "<Cmd>Open tab<CR>",         { desc = "Open: tab" })

-- Visual mode: browser and editor
map("x", "<leader>ob", "<Cmd>Open browser<CR>",     { desc = "Open selection: browser" })
map("x", "<leader>on", "<Cmd>Open notepad<CR>",     { desc = "Open selection: notepad" })
```

---

## Architecture

```
lua/custom/open/
├── @types/
│   └── init.lua            Pure type annotations (Custom.Open.*)
├── handlers/
│   ├── browser.lua         browser, chrome, chromium, firefox, edge, safari
│   ├── filemanager.lua     filemanager
│   ├── notepad.lua         notepad, editor
│   └── nvim_internal.lua   split, vsplit, tab
├── context.lua             Text extraction from cursor / visual selection
├── platform.lua            Cached platform detection
├── registry.lua            Handler register / get / list
├── util.lua                run_detached, url_encode, find_exec
├── init.lua                :Open command, setup, completion
└── doc/
    └── open_custom_usrcmd.txt  Vim :h documentation
```

### Data flow

```
:Open chrome
    ↓
open_handler(opts)          init.lua
    ↓
context.build()             → Custom.Open.Context { text, is_url, is_path }
    ↓
registry.get("chrome")      → Custom.Open.Handler
    ↓
handler.run(ctx)            handlers/browser.lua
    ↓
util.run_detached(cmd, …)   util.lua
```

---

## Platform Notes

| Platform | Browser        | File manager   | Editor         |
|----------|----------------|----------------|----------------|
| Windows  | `start`        | `explorer.exe` | `notepad.exe`  |
| WSL      | `wslview` / `start` | `explorer.exe` (via wslpath) | `notepad.exe` |
| macOS    | `open` / `open -a` | `open` / `open -R` | `open -e` (TextEdit) |
| Linux    | `xdg-open` / binary name | `xdg-open` / first found manager | `xdg-open` / first found editor |

---

## See Also

- `:h open_custom_usrcmd` — in-editor documentation
- `custom/insert/` — `:Insert` command (same pattern)
- `custom/format/` — `:Format` command (same pattern)

---

## Literature and References

- Neovim `vim.system` API: <https://neovim.io/doc/user/lua.html#vim.system()>
- `xdg-open` (Linux): <https://portland.freedesktop.org/doc/xdg-open.html>
- `wslview` (WSL): <https://github.com/wslutilities/wslu>
- EmmyLua annotation spec: <https://luals.github.io/wiki/annotations/>
