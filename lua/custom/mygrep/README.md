# live_grep_memory.nvim

> Extendable memory-enhanced search layer for Telescope-powered grep tools in Neovim.

**live_grep_memory** adds a persistent, session-aware memory system to any Telescope-based grep tool.
It remembers your search history, lets you mark favorites, supports undo for accidental deletions, and provides interactive, tool-specific pickers with consistent UX.

## Features

- 🧠 **Session memory** for all registered grep tools (`live_grep`, `multigrep`, ...)
- 📌 **Favorites** with toggle support (`<Tab>`) and dedicated view
- 🗑️ **Entry deletion** (`<C-d>`) and **undo** (`<C-z>`) stack
- 🔍 **Result preview** of potential matches (`<C-h>`) via `rg --count`
- 🔁 Modular architecture — register new tools with a single Lua file
- 💾 Persistent storage in `stdpath("cache")/live_grep_memory/`
- ✅ Safe, testable, documented & LSP-ready codebase

---

## Quick Start

```lua
-- init.lua
require("custom.live_grep_memory.keymaps").setup()
````

Default keybindings:

| Mode | Mapping      | Description                      |
| ---- | ------------ | -------------------------------- |
| `n`  | `<leader>lg` | Launch `live_grep` memory picker |
| `n`  | `<leader>mg` | Launch `multigrep` memory picker |

---

## Tool Examples

### Register your own grep tool:

```lua
-- tools/mygrep.lua
return function(opts)
  local state = require("...history").load("mygrep")
  require("...picker").open("mygrep", "My Grep", function(input)
    -- your custom search implementation
  end, state)
end
```

### Add to registry:

```lua
-- in init.lua or plugin setup
local registry = require("custom.live_grep_memory.core.registry")
registry.register("mygrep", require("custom.live_grep_memory.tools.mygrep"))
```

---

## Architecture

### Layered modules:

```
live_grep_memory/
├── init.lua              ← Entry point + tool registration
├── core/
│   ├── picker.lua        ← Generic UI + keymaps
│   ├── history.lua       ← Tool-specific history/favorites
│   ├── undo.lua          ← Session undo stack
│   ├── registry.lua      ← Tool registration & lookup
│   └── preview.lua       ← Live result count preview
└── tools/
    ├── live_grep.lua     ← Uses `builtin.live_grep`
    ├── multigrep.lua     ← Pattern + glob matching (via `rg`)
```

---

## Requirements

* [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
* [ripgrep](https://github.com/BurntSushi/ripgrep)
* Neovim 0.9+

---

## License

MIT — see `LICENSE`

---