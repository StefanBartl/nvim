# pdfport – Usage Guide

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Setup](#setup)
- [Configuration Reference](#configuration-reference)
- [User Commands](#user-commands)
- [Lua API](#lua-api)
  - [open()](#open)
  - [extract()](#extract)
  - [register_backend()](#register_backend)
  - [config()](#config)
- [Backends](#backends)
  - [pdftotext](#pdftotext)
  - [pdfplumber](#pdfplumber)
  - [marker](#marker)
  - [docling](#docling)
  - [ollama](#ollama)
  - [claude](#claude)
- [Renderer Modes](#renderer-modes)
  - [buffer](#buffer)
  - [float](#float)
  - [terminal](#terminal)
  - [system](#system)
- [Integrations](#integrations)
  - [Neo-tree](#neo-tree)
  - [Telescope](#telescope)
  - [fzf-lua](#fzf-lua)
- [Custom Backends](#custom-backends)
- [Health Check](#health-check)
- [Troubleshooting](#troubleshooting)

---

## Overview

pdfport is a Neovim module for opening and extracting PDF content. It provides
a pluggable backend/renderer architecture that separates extraction (how text is
obtained from a PDF) from rendering (how that text is displayed in Neovim).

The same API works regardless of whether the call originates from a keymap,
a Neo-tree command, a Telescope previewer, or a plain Lua script.

---

## Installation

Add pdfport to your Neovim config by placing the module under:

```
lua/custom/pdfport/
```

pdfport has no mandatory Neovim plugin dependencies. External tool dependencies
depend on which backends are used. See [Backends](#backends) for details.

For lazy.nvim, no plugin spec entry is needed since pdfport lives in your own
config tree and is loaded via `require`.

---

## Setup

Call `setup()` once during Neovim startup, for example in `lua/plugins/pdfport.lua`
or directly in your init:

```lua
require("custom.pdfport").setup({
  default_backend = "auto",
  fallback_chain  = { "pdftotext", "marker", "claude" },
  extract_opts = {
    max_pages  = 20,
    timeout_ms = 30000,
  },
  render_opts = {
    mode  = "buffer",
    split = "vsplit",
    focus = true,
  },
  claude_api_key = nil,   -- falls back to $ANTHROPIC_API_KEY
  ollama_host    = "http://localhost:11434",
  ollama_model   = "llava",
  debug          = false,
})
```

If `setup()` is never called explicitly, it is called automatically with
default values on the first call to `open()` or `extract()`.

---

## Configuration Reference

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `default_backend` | `string\|"auto"` | `"auto"` | Backend to use when none is specified. `"auto"` picks the first available backend from `fallback_chain`. |
| `fallback_chain` | `string[]` | see below | Ordered list of backends to try when the preferred one is unavailable. |
| `extract_opts.max_pages` | `integer\|nil` | `nil` | Global page limit for all extractions. `nil` means no limit. |
| `extract_opts.timeout_ms` | `integer` | `30000` | Extraction timeout in milliseconds. |
| `render_opts.mode` | `string` | `"buffer"` | Default render mode: `"buffer"`, `"float"`, `"terminal"`, `"system"`. |
| `render_opts.split` | `string` | `"vsplit"` | Split direction for buffer mode: `"vsplit"`, `"split"`, `"tab"`. |
| `render_opts.focus` | `boolean` | `true` | Whether to focus the window after opening. |
| `claude_api_key` | `string\|nil` | `nil` | Anthropic API key. Overrides `$ANTHROPIC_API_KEY`. |
| `ollama_host` | `string` | `"http://localhost:11434"` | Ollama API host. |
| `ollama_model` | `string` | `"llava"` | Ollama model name. |
| `debug` | `boolean` | `false` | Enable debug notifications. |

Default fallback chain:

```lua
{ "pdftotext", "pdfplumber", "marker", "docling", "ollama", "claude" }
```

---

## User Commands

All commands accept an optional file path argument. When omitted, the path of
the current buffer is used.

| Command | Description |
|---------|-------------|
| `:PdfPort [path]` | Open an interactive mode picker, then extract and render. |
| `:PdfPortText [path]` | Extract text and open in a vertical split buffer. |
| `:PdfPortFloat [path]` | Extract text and open in a centered floating window. |
| `:PdfPortSystem [path]` | Open the PDF in the operating system's default application. |
| `:PdfPortTerminal [path]` | Render the first page as an image in the terminal. |
| `:PdfPortHealth` | Run `:checkhealth pdfport`. |

Examples:

```vim
" Open the current buffer PDF with the mode picker
:PdfPort

" Open a specific file as plain text
:PdfPortText /home/user/documents/report.pdf

" Open a specific file in the system viewer
:PdfPortSystem ~/Downloads/invoice.pdf
```

---

## Lua API

### open()

Extracts and renders a PDF in one call.

```lua
require("custom.pdfport").open({
  path       = "/absolute/path/to/file.pdf",  -- required
  mode       = "buffer",    -- "buffer"|"float"|"terminal"|"system"
  backend_id = "marker",    -- optional; nil = auto-resolve
  split      = "vsplit",    -- "vsplit"|"split"|"tab"  (buffer mode)
  focus      = true,        -- focus the new window
  max_pages  = 10,          -- override global page limit
  timeout_ms = 60000,       -- override global timeout
  pages      = { 1, 2, 3 }, -- specific pages (terminal mode)
  prompt     = "Extract all text as Markdown.", -- AI backends only
  model      = "claude-opus-4-5",               -- AI backends only
})
```

### extract()

Extracts text without rendering. The result is delivered asynchronously via
the required `__callback` function.

```lua
require("custom.pdfport").extract({
  path       = "/absolute/path/to/file.pdf",
  backend_id = "pdftotext",  -- optional
  max_pages  = 5,
  __callback = function(result)
    if result.status == "ok" then
      print(result.text)
      print("backend used: " .. result.backend)
      print("format: " .. result.format)  -- "plain" or "markdown"
    else
      print("error: " .. (result.error or "unknown"))
    end
  end,
})
```

The `result` table always contains:

| Field | Type | Description |
|-------|------|-------------|
| `status` | `"ok"\|"error"\|"partial"` | Extraction outcome. |
| `text` | `string\|nil` | Extracted text. `nil` on error. |
| `format` | `"plain"\|"markdown"` | Output format. |
| `backend` | `string` | ID of the backend that produced the result. |
| `pages_processed` | `integer\|nil` | Number of pages processed, if known. |
| `error` | `string\|nil` | Error message. `nil` on success. |

### register_backend()

Registers a custom extraction backend at runtime.

```lua
require("custom.pdfport").register_backend({
  id   = "my_backend",
  name = "My Custom Backend",
  capabilities = {
    markdown    = true,
    tables      = false,
    ocr         = false,
    remote      = false,
    gpu_optional = false,
  },
  available = function()
    return vim.fn.executable("my_tool") == 1
  end,
  extract = function(path, opts)
    -- Run extraction; deliver result via opts.__callback
    -- Return nil for async, or a PdfPort.Result for sync
  end,
})
```

### config()

Returns a copy of the active configuration.

```lua
local cfg = require("custom.pdfport").config()
print(cfg.default_backend)
print(cfg.ollama_model)
```

---

## Backends

Backends are tried in the order of `fallback_chain`. The first one that
reports itself as available is used.

### pdftotext

Uses the `pdftotext` binary from poppler-utils.

- Output format: plain text
- Table support: weak
- OCR support: no
- Install: `apt install poppler-utils` / `brew install poppler`

```lua
require("custom.pdfport").open({
  path       = "/path/to/file.pdf",
  backend_id = "pdftotext",
})
```

### pdfplumber

Uses the Python `pdfplumber` library via `python3`.

- Output format: plain text
- Table support: good
- OCR support: no
- Install: `pip install pdfplumber`

```lua
require("custom.pdfport").open({
  path       = "/path/to/file.pdf",
  backend_id = "pdfplumber",
})
```

### marker

Uses the `marker_single` CLI tool from the `marker-pdf` Python package.
Produces high-quality Markdown with preserved headings, lists, tables and
code blocks. Runs locally; GPU is optional.

- Output format: Markdown
- Table support: excellent
- OCR support: yes
- Install: `pip install marker-pdf`

```lua
require("custom.pdfport").open({
  path       = "/path/to/file.pdf",
  backend_id = "marker",
  max_pages  = 10,
})
```

### docling

Uses IBM's `docling` Python library. Optimized for structured documents such
as research papers and financial reports.

- Output format: Markdown
- Table support: excellent
- OCR support: yes
- Install: `pip install docling`

```lua
require("custom.pdfport").open({
  path       = "/path/to/file.pdf",
  backend_id = "docling",
})
```

### ollama

Uses a locally running ollama daemon with a multimodal model (e.g. `llava`).
Pages are rasterized to PNG first via `pdftoppm`, then sent to the model.
Useful for scanned PDFs without selectable text.

- Output format: Markdown (model-dependent)
- Table support: model-dependent
- OCR support: yes (via vision model)
- Requires: `ollama` daemon running, `pdftoppm` on PATH

```lua
-- Configure model globally
require("custom.pdfport").setup({
  ollama_host  = "http://localhost:11434",
  ollama_model = "llava",
})

-- Override per call
require("custom.pdfport").open({
  path       = "/path/to/scanned.pdf",
  backend_id = "ollama",
  model      = "llava:13b",
  prompt     = "Extract all visible text. Format as Markdown.",
  pages      = { 1, 2 },
})
```

### claude

Sends the PDF to the Anthropic Claude API as a native document block.
Claude reads the PDF directly and returns a Markdown extraction.

- Output format: Markdown
- Table support: excellent
- OCR support: yes
- Requires: `curl` on PATH, `ANTHROPIC_API_KEY` set

```lua
-- API key via environment variable (recommended)
-- export ANTHROPIC_API_KEY=sk-ant-...

-- Or pass it directly in setup()
require("custom.pdfport").setup({
  claude_api_key = "sk-ant-...",
})

require("custom.pdfport").open({
  path       = "/path/to/file.pdf",
  backend_id = "claude",
  model      = "claude-opus-4-5",
  max_pages  = 5,
  prompt     = "Extract all text. Preserve tables as Markdown.",
  timeout_ms = 60000,
})
```

---

## Renderer Modes

### buffer

Opens extracted text in a Neovim scratch buffer. The buffer is not written
to disk and is wiped when closed. Filetype is set to `markdown` or `text`
depending on the backend's output format.

```lua
require("custom.pdfport").open({
  path  = "/path/to/file.pdf",
  mode  = "buffer",
  split = "vsplit",  -- "vsplit" | "split" | "tab" | nil (current window)
  focus = true,
})
```

### float

Opens extracted text in a centered floating window. Close with `q` or `<Esc>`.

```lua
require("custom.pdfport").open({
  path       = "/path/to/file.pdf",
  mode       = "float",
  float_opts = {
    border = "rounded",
    width  = 100,
    height = 40,
  },
})
```

### terminal

Rasterizes PDF pages via `pdftoppm` and displays them using the best
available terminal image tool. Rendering tool priority:

1. ueberzug++ (`ueberzugpp`)
2. kitty icat (`kitten icat`)
3. imgcat (iTerm2)
4. chafa (universal ASCII-art fallback)

```lua
require("custom.pdfport").open({
  path          = "/path/to/file.pdf",
  mode          = "terminal",
  pages         = { 1, 2, 3 },       -- pages to render; default: { 1 }
  terminal_tool = "chafa",            -- force a specific tool
})
```

Required: `pdftoppm` from poppler-utils plus at least one rendering tool.

### system

Opens the PDF with the operating system default application. No text
extraction is performed.

| OS | Command used |
|----|-------------|
| Linux | `xdg-open` |
| macOS | `open` |
| Windows / WSL | `start` / `wsl-open` |

```lua
require("custom.pdfport").open({
  path = "/path/to/file.pdf",
  mode = "system",
})
```

---

## Integrations

### Neo-tree

Add pdfport commands and keymaps to Neo-tree's filesystem window:

```lua
-- In your neo-tree opts function:
local pdfport_neo = require("custom.pdfport.integrations.neotree")

opts.commands = vim.tbl_extend("force", opts.commands or {}, pdfport_neo.commands())

opts.filesystem = opts.filesystem or {}
opts.filesystem.window = opts.filesystem.window or {}
opts.filesystem.window.mappings = vim.tbl_extend(
  "force",
  opts.filesystem.window.mappings or {},
  pdfport_neo.keymaps()
)
```

Default keymaps (all only active on `.pdf` nodes):

| Key | Action |
|-----|--------|
| `<leader>po` | Interactive mode picker |
| `<leader>pt` | Quick plain text extraction |
| `<leader>ps` | Open in system application |
| `<leader>pi` | Terminal image preview |

Custom keymaps:

```lua
opts.filesystem.window.mappings = vim.tbl_extend("force", mappings, {
  ["gp"] = "pdfport_open",     -- reassign to gp
  ["gt"] = "pdfport_text",
  ["gi"] = "pdfport_terminal",
})
```

Available Neo-tree command names:

- `pdfport_open` — interactive picker
- `pdfport_text` — plain text in vsplit
- `pdfport_system` — system application
- `pdfport_terminal` — terminal image preview

### Telescope

Option A: per-picker previewer

```lua
local pdfport_tel = require("custom.pdfport.integrations.telescope")

require("telescope.builtin").find_files({
  previewer = pdfport_tel.previewer({
    backend_id = "pdftotext",
    max_pages  = 3,
  }),
})
```

Option B: global filetype hook (automatic for all pickers)

```lua
require("telescope").setup({
  defaults = {
    preview = {
      filetype_hook = require("custom.pdfport.integrations.telescope").filetype_hook,
    },
  },
})
```

With the filetype hook active, any `.pdf` file focused in any Telescope picker
will automatically show the extracted text in the preview pane. The first 5
pages are extracted by default.

### fzf-lua

```lua
local pdfport_fzf = require("custom.pdfport.integrations.fzf")

require("fzf-lua").files({
  previewer = false,  -- disable default previewer
  preview   = pdfport_fzf.preview_fn({
    backend_id = "pdftotext",
    max_pages  = 3,
  }),
})
```

The preview function can also be used with `fzf-lua`'s `winopts.preview`
configuration for permanent attachment to a picker.

---

## Custom Backends

A backend is a plain Lua table that satisfies the `PdfPort.Backend` interface.

Minimum required fields:

```lua
---@type PdfPort.Backend
local my_backend = {
  id   = "my_tool",
  name = "My PDF Tool",

  capabilities = {
    markdown    = true,
    tables      = false,
    ocr         = false,
    remote      = false,
    gpu_optional = false,
  },

  available = function()
    return vim.fn.executable("my_tool") == 1
  end,

  ---@param path string
  ---@param opts PdfPort.InternalExtractOpts
  ---@return PdfPort.Result|nil
  extract = function(path, opts)
    local output = vim.fn.system({ "my_tool", path })

    local result = {
      status          = vim.v.shell_error == 0 and "ok" or "error",
      text            = vim.v.shell_error == 0 and output or nil,
      format          = "plain",
      backend         = "my_tool",
      pages_processed = nil,
      error           = vim.v.shell_error ~= 0 and output or nil,
    }

    -- For sync backends: return the result directly
    return result

    -- For async backends: call opts.__callback and return nil
    -- opts.__callback(result)
    -- return nil
  end,
}

require("custom.pdfport").register_backend(my_backend)
```

The backend is then available by its `id` in all open/extract calls:

```lua
require("custom.pdfport").open({
  path       = "/path/to/file.pdf",
  backend_id = "my_tool",
})
```

To make a custom backend load automatically on startup, place its module under
`lua/custom/pdfport/backends/my_tool.lua` and add it to the loader list in
`lua/custom/pdfport/backends/init.lua`.

---

## Health Check

Run the built-in health check to verify that all backends and renderers are
correctly configured:

```vim
:checkhealth pdfport
```

Or via the user command:

```vim
:PdfPortHealth
```

The health check reports:

- Whether the core modules load without error
- Availability of each extraction backend and its system dependencies
- Availability of each renderer and its tools
- Whether Neo-tree, Telescope and fzf-lua integrations are active
- The current state of the backend registry

---

## Troubleshooting

**No backend available**

Run `:checkhealth pdfport` to see which backends are installed. Install at
least `poppler-utils` for the `pdftotext` baseline:

```sh
# Debian / Ubuntu
sudo apt install poppler-utils

# macOS
brew install poppler

# Arch
sudo pacman -S poppler
```

**Terminal preview shows nothing**

Install at least one image rendering tool. `chafa` is the most universally
compatible option:

```sh
sudo apt install chafa        # Debian / Ubuntu
brew install chafa            # macOS
sudo pacman -S chafa          # Arch
```

Also ensure `pdftoppm` is available (part of `poppler-utils`).

**Claude backend returns an auth error**

Verify the API key is set:

```sh
echo $ANTHROPIC_API_KEY
```

Or pass it explicitly in `setup()`. Confirm that `curl` is on PATH.

**marker backend is slow**

marker uses neural models and is CPU-bound without a GPU. Set `max_pages` to
limit the number of pages processed per extraction:

```lua
require("custom.pdfport").setup({
  extract_opts = { max_pages = 5 },
})
```

**Telescope preview does not update**

The filetype hook approach relies on Telescope's preview hook mechanism. If
it does not trigger, use the explicit `previewer` option instead:

```lua
require("telescope.builtin").find_files({
  previewer = require("custom.pdfport.integrations.telescope").previewer(),
})
```

**LSP warnings about undefined fields**

Ensure `lua/custom/pdfport/@types/init.lua` is loaded by the Lua language
server. Add the types path to `workspace.library` in the lua-ls settings if
needed.
