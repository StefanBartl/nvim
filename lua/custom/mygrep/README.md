lua/custom/live_grep_memory/
├── init.lua               -- Einstiegspunkt
├── core/
│   ├── registry.lua       -- Registriert alle Tools (live_grep, multigrep, ...)
│   ├── history.lua        -- Persistent + Session History per Tool
│   ├── picker.lua         -- Generischer Picker mit Attach-Mappings
│   ├── undo.lua           -- Undo-Stack pro Tool
│   └── preview.lua        -- Treffer-Vorschau (count)
├── tools/
│   ├── live_grep.lua      -- Wrapper für builtin.live_grep
│   └── multigrep.lua      -- Eigenes async_job-basiertes Tool



Hier ist eine **README.md** für dein Projekt `live_grep_memory`, professionell formuliert, klar strukturiert und mit starkem Fokus auf Entwicklerfreundlichkeit, Erweiterbarkeit und Best Practices.

---

````markdown
# 🔍 live_grep_memory.nvim

> Extendable memory-enhanced search layer for Telescope-powered grep tools in Neovim.

**live_grep_memory** adds a persistent, session-aware memory system to any Telescope-based grep tool.
It remembers your search history, lets you mark favorites, supports undo for accidental deletions, and provides interactive, tool-specific pickers with consistent UX.

## ✨ Features

- 🧠 **Session memory** for all registered grep tools (`live_grep`, `multigrep`, ...)
- 📌 **Favorites** with toggle support (`<Tab>`) and dedicated view
- 🗑️ **Entry deletion** (`<C-d>`) and **undo** (`<C-z>`) stack
- 🔍 **Result preview** of potential matches (`<C-h>`) via `rg --count`
- 🔁 Modular architecture — register new tools with a single Lua file
- 💾 Persistent storage in `stdpath("cache")/live_grep_memory/`
- ✅ Safe, testable, documented & LSP-ready codebase

---

## 🚀 Quick Start

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

## 🧩 Tool Examples

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

## 🧠 Architecture

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

## 🔐 Code Quality Principles

* 💡 **Pure functions** where possible, no side effects
* ✅ `pcall()` and assert guards used throughout
* 🔬 Testable in isolation, each module has a single responsibility
* 📦 Tool state (history/favs/undo) passed explicitly
* 📚 EmmyLua annotations for full LSP + autocomplete support

---

## 🛠 Requirements

* [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
* [ripgrep](https://github.com/BurntSushi/ripgrep)
* Neovim 0.9+

---

## 📄 License

MIT — see `LICENSE`

---

## 🙌 Credits

Inspired by [tjdevries/advent-of-nvim](https://github.com/tjdevries/advent-of-nvim)
Built with ❤️ for developers who live in their search buffer.

```

---

Wenn du möchtest, passe ich dir den Pfadstil (z. B. `custom.live_grep_memory` vs. `plugins/...`) oder Featurestruktur (Screenshots, GIFs) an.
Willst du z. B. auch ein Abschnitt für:

- Plugin-Manager-Installation (`lazy.nvim`, `packer`)?
- Developer Guide zum Erstellen neuer Tools?
- GIFs/Vorschau-Animationen?
