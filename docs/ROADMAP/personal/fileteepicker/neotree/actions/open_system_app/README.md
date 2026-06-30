# `config.neotree.actions.open_system_app`

Opens files in neo-tree with the OS-default application instead of a Neovim
buffer — triggered by `<Tab>` or `<CR>` on any node whose extension matches
the configured set.

---

## Table of content

- [`config.neotree.actions.open_system_app`](#configneotreeactionsopen_system_app)
  - [Structure](#structure)
  - [How it works](#how-it-works)
    - [OS openers](#os-openers)
  - [Default filetypes](#default-filetypes)
  - [Usage](#usage)
    - [Minimal (keep all defaults)](#minimal-keep-all-defaults)
    - [Extend defaults with extra types](#extend-defaults-with-extra-types)
    - [Replace defaults entirely](#replace-defaults-entirely)
    - [All options](#all-options)
    - [Full example (plugins/neotree.lua)](#full-example-pluginsneotreelua)
  - [Public API](#public-api)
  - [Notes](#notes)

---

## Structure

```
config/neotree/actions/open_system_app/
├── init.lua          Core module (setup / attach / open / is_handled)
└── @types/init.lua   LuaLS type definitions
```

---

## How it works

1. `setup(opts?)` — configure filetypes and notification behaviour (idempotent).
2. `attach(opts)` — called **before** `require("neo-tree").setup(opts)`.
   Mutates the opts table in-place:
   - Registers the neo-tree command `"open_system_app"`.
   - Wires `<Tab>` and `<CR>` to that command in `opts.window.mappings`
     **and** in every per-source `window.mappings`
     (`filesystem`, `buffers`, `git_status`, `document_symbols`,
     `diagnostics`, `tests`).
3. When the command fires on a node:
   - **Handled extension** → `uv.spawn` hands the file to the OS opener
     (detached, async — Neovim never blocks).
   - **Any other node** → falls through to neo-tree's built-in `open`.

### OS openers

| Platform | Command        |
|----------|----------------|
| Linux    | `xdg-open`     |
| macOS    | `open`         |
| Windows  | `cmd /c start` |

Platform detection uses `lib.cross` when available, falling back to
`vim.uv.os_uname()`.

---

## Default filetypes

| Category      | Extensions                                              |
|---------------|---------------------------------------------------------|
| Documents     | `pdf`                                                   |
| Raster images | `png jpg jpeg gif bmp webp tiff tif ico heic heif`      |
| Vector/Design | `svg ai psd xcf sketch fig`                             |
| Video         | `mp4 mkv avi mov wmv flv webm m4v`                      |
| Audio         | `mp3 wav flac ogg aac m4a opus`                         |
| Office        | `docx doc odt xlsx xls ods pptx ppt odp`                |
| Archives      | `zip tar gz bz2 xz 7z rar`                              |

All comparisons are case-insensitive; leading dots are stripped automatically.

---

## Usage

### Minimal (keep all defaults)

```lua
-- plugins/neotree.lua  →  config = function(_, opts)
local OPEN_SYSTEM_APP = require("config.neotree.actions.open_system_app")

OPEN_SYSTEM_APP.attach(opts)          -- setup() with defaults is called implicitly
```

### Extend defaults with extra types

```lua
OPEN_SYSTEM_APP.setup({
  extra_filetypes = { "epub", "blend", "fcstd" },
})
OPEN_SYSTEM_APP.attach(opts)
```

### Replace defaults entirely

```lua
OPEN_SYSTEM_APP.setup({
  filetypes = { "pdf", "png", "jpg" },
})
OPEN_SYSTEM_APP.attach(opts)
```

### All options

```lua
OPEN_SYSTEM_APP.setup({
  -- Replaces the default list when provided and non-empty.
  filetypes        = { ... },

  -- Merged on top of the default list (or on top of `filetypes` if given).
  extra_filetypes  = { ... },

  -- Show a notification when a file is handed off.  Default: true
  notify_on_open   = true,

  -- Show a notification when the OS opener exits non-zero.  Default: true
  notify_on_error  = true,
})
```

### Full example (plugins/neotree.lua)

```lua
local OPEN_SYSTEM_APP = require("config.neotree.actions.open_system_app")

-- ...

config = function(_, opts)
  OPEN_SYSTEM_APP.setup({ extra_filetypes = { "epub" } })
  OPEN_SYSTEM_APP.attach(opts)                          -- before neo-tree.setup!

  require("config.neotree.actions.find_or_grep_menu").attach(opts)
  require("config.neotree.current_hl").attach(opts)
  require("neo-tree").setup(opts)
  require("config.neotree.components.marks").attach(opts)
  -- ...
end,
```

---

## Public API

| Symbol | Signature | Description |
|---|---|---|
| `DEFAULT_FILETYPES` | `string[]` | The built-in extension list. |
| `setup` | `(opts?: OpenSysApp.Opts) → nil` | Configure the module (idempotent). |
| `attach` | `(opts: table) → nil` | Inject command + mappings into neo-tree opts. |
| `open` | `(path: string) → nil` | Hand a path to the OS opener directly. |
| `is_handled` | `(path: string) → boolean` | Check whether a path's extension is in the set. |
| `get_config` | `() → OpenSysApp.Config` | Return a copy of the active config. |

---

## Notes

- `attach` must be called **before** `require("neo-tree").setup(opts)`.
- `setup` is idempotent — calling it multiple times has no effect after
  the first successful call.
- The OS process is spawned **detached**; Neovim does not wait for it and
  will not be affected if the viewer is slow to start.
- Extensions that are not in the configured set continue to behave exactly
  as before — no neo-tree behaviour is changed for them.

---
