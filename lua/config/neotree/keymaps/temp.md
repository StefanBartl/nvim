Ich analysiere die Mappings und erstelle eine strukturierte Zuordnung:

## 📋 Mapping-Aufteilung nach Sources

### 🌐 GLOBAL (keymaps/init.lua - für ALLE Sources)

**Nur diese sollten in init.lua bleiben:**

```lua
-- Window Control
["q"] = "close_window"
["?"] = "show_help"
["g?"] = "noop"
["<Esc>"] = function(state) ... end  -- close + clear search

-- Source Switching
["\""] = "next_source"
["!"] = "prev_source"
["<"] = "noop"

-- Window Management
["w"] = function(state) ... end  -- resize helper
["R"] = "refresh"
["C"] = "close_node"
["z"] = "close_all_nodes"

-- Splits/Tabs (bedingt - filesystem verwendet sie anders)
["s"] = "noop"
["t"] = "noop"
```

---

### 📁 FILESYSTEM (keymaps/filesystem.lua)

**Diese gehören NUR in filesystem.lua:**

```lua
-- File Operations
["<CR>"] = function(state) ... end  -- custom expand/collapse/open
["<2-LeftMouse>"] = "open"
["<Tab>"] = function(state) ... end  -- preview
["<S-CR>"] = "open_badd"
["gb"] = "open_badd"
["<S-o>"] = function(state) ... end  -- open_replace

-- Splits/Tabs
["sv"] = "open_split"
["sg"] = "open_vsplit"
["st"] = "open_tabnew"

-- File Clipboard Operations
["c"] = "copy_to_clipboard"
["x"] = "cut_to_clipboard"
["p"] = "paste_from_clipboard"

-- File Creation/Modification
["a"] = { "add", ... }
["A"] = { "add_directory", ... }
["r"] = "rename"
["D"] = "diff_files"

-- Trash Operations
["dd"] = function(state) ... end  -- trash
["U"] = function(state) ... end  -- undo trash
["<leader>th"] = function() ... end  -- trash history

-- Mark Operations
["m"] = function(state) ... end  -- toggle mark
["<S-m>"] = function(state) ... end  -- mark all in dir
["<leader>mc"] = function(state) ... end  -- clear marks

-- Navigation
["+"] = function(state) ... end  -- cd to node
["-"] = function(state) ... end  -- updir

-- Path Copying
["[p"] = function(state) ... end  -- copy absolute path
["]p"] = function(state) ... end  -- copy base dir
["]r"] = function(state) ... end  -- copy relative path
["[r"] = function(state) ... end  -- copy relative base dir
["[f"] = function(state) ... end  -- copy folder list (abs)
["[F"] = function(state) ... end  -- copy folder list (rel)
["[t"] = function(state) ... end  -- copy file list (abs)
["[T"] = function(state) ... end  -- copy file list (rel)
["Y"] = function(state) ... end  -- copy path to clipboard

-- Special Operations
["I"] = function(state) ... end  -- node info
["O"] = function(state) ... end  -- open with system app
["L"] = function(state) ... end  -- open in file manager
["[l"] = function(state) ... end  -- copy require() string
["grep"] = function(state) ... end  -- fzf grep

-- Save Operations
["<C-s>"] = function() ... end  -- save adjacent buffer
["<M-s>"] = function() ... end  -- save node buffer

-- Preview Scrolling
["<PageDown>"] = { "scroll_preview", ... }
["<PageUp>"] = { "scroll_preview", ... }
["<C-f>"] = { "scroll_preview", ... }
["<C-b>"] = { "scroll_preview", ... }

-- Filter (bereits vorhanden)
["/"] = "noop"
["f"] = "filter_on_submit"
["F"] = "fuzzy_finder"
["<C-c>"] = "clear_filter"

-- Commands (bereits vorhanden)
["i"] = "run_command"
["tf"] = "telescope_find"
["tg"] = "telescope_grep"
```

---

### 📦 BUFFERS (keymaps/buffers.lua)

**Aktuelle Mappings sind OK, aber füge noop hinzu:**

```lua
-- Valid
["dd"] = "buffer_delete"

-- Add noop für filesystem-specific:
["a"] = "noop"
["A"] = "noop"
["r"] = "noop"
["c"] = "noop"
["x"] = "noop"
["p"] = "noop"
["m"] = "noop"
["<S-m>"] = "noop"
["U"] = "noop"
["+"] = "noop"
["-"] = "noop"
["I"] = "noop"
["O"] = "noop"
["L"] = "noop"
["[l"] = "noop"
["grep"] = "noop"
["D"] = "noop"
["[p"] = "noop"
["]p"] = "noop"
["]r"] = "noop"
["[r"] = "noop"
["[f"] = "noop"
["[F"] = "noop"
["[t"] = "noop"
["[T"] = "noop"
["Y"] = "noop"
["<S-o>"] = "noop"
["<S-CR>"] = "noop"
["gb"] = "noop"
["<C-s>"] = "noop"
["<M-s>"] = "noop"
```

---

### 🔀 GIT_STATUS (keymaps/git_status.lua)

**Aktuelle Mappings sind OK, aber füge noop hinzu:**

```lua
-- Valid
["d"] = "noop"
["dd"] = "delete"

-- Add noop für filesystem-specific (gleich wie buffers):
["a"] = "noop"
["A"] = "noop"
["r"] = "noop"
["c"] = "noop"
["x"] = "noop"
["p"] = "noop"
["m"] = "noop"
["<S-m>"] = "noop"
["U"] = "noop"
["+"] = "noop"
["-"] = "noop"
["I"] = "noop"
["O"] = "noop"
["L"] = "noop"
["[l"] = "noop"
["grep"] = "noop"
["D"] = "noop"
["[p"] = "noop"
["]p"] = "noop"
["]r"] = "noop"
["[r"] = "noop"
["[f"] = "noop"
["[F"] = "noop"
["[t"] = "noop"
["[T"] = "noop"
["Y"] = "noop"
["<S-o>"] = "noop"
["<S-CR>"] = "noop"
["gb"] = "noop"
["<C-s>"] = "noop"
["<M-s>"] = "noop"
```

---

### 📄 DOCUMENT_SYMBOLS (keymaps/document_symbols.lua)

**Komplett neu strukturieren:**

```lua
-- Navigation (document_symbols specific)
["<CR>"] = "jump_to_symbol"
["<2-LeftMouse>"] = "jump_to_symbol"
["l"] = "jump_to_symbol"
["o"] = "jump_to_symbol"

-- Filter
["F"] = "filter"
["f"] = "filter_on_submit"

-- Disable ALL filesystem operations:
["/"] = "noop"
["<C-c>"] = "noop"
["a"] = "noop"
["A"] = "noop"
["d"] = "noop"
["dd"] = "noop"
["r"] = "noop"
["c"] = "noop"
["x"] = "noop"
["p"] = "noop"
["m"] = "noop"
["<S-m>"] = "noop"
["<leader>mc"] = "noop"
["U"] = "noop"
["<leader>th"] = "noop"
["+"] = "noop"
["-"] = "noop"
["I"] = "noop"
["O"] = "noop"
["L"] = "noop"
["[l"] = "noop"
["grep"] = "noop"
["D"] = "noop"
["[p"] = "noop"
["]p"] = "noop"
["]r"] = "noop"
["[r"] = "noop"
["[f"] = "noop"
["[F"] = "noop"
["[t"] = "noop"
["[T"] = "noop"
["Y"] = "noop"
["<S-o>"] = "noop"
["<S-CR>"] = "noop"
["gb"] = "noop"
["<C-s>"] = "noop"
["<M-s>"] = "noop"
["<Tab>"] = "noop"  -- No preview
["<PageDown>"] = "noop"
["<PageUp>"] = "noop"
["<C-f>"] = "noop"
["<C-b>"] = "noop"
["sv"] = "noop"
["sg"] = "noop"
["st"] = "noop"
```

---

### 🧪 TESTS (keymaps/tests.lua)

**Komplett neu strukturieren:**

```lua
-- Test Execution
["<CR>"] = "run_test"
["<S-CR>"] = "debug_test"

-- Output
["o"] = "output"
["O"] = "short_output"

-- Control
["s"] = "stop_test"
["w"] = "watch_test"

-- Disable ALL filesystem operations (gleiche Liste wie document_symbols):
["/"] = "noop"
["<C-c>"] = "noop"
["a"] = "noop"
["A"] = "noop"
["d"] = "noop"
["dd"] = "noop"
["r"] = "noop"
["c"] = "noop"
["x"] = "noop"
["p"] = "noop"
["m"] = "noop"
["<S-m>"] = "noop"
["<leader>mc"] = "noop"
["U"] = "noop"
["<leader>th"] = "noop"
["+"] = "noop"
["-"] = "noop"
["I"] = "noop"
["L"] = "noop"
["[l"] = "noop"
["grep"] = "noop"
["D"] = "noop"
["[p"] = "noop"
["]p"] = "noop"
["]r"] = "noop"
["[r"] = "noop"
["[f"] = "noop"
["[F"] = "noop"
["[t"] = "noop"
["[T"] = "noop"
["Y"] = "noop"
["<S-o>"] = "noop"
["gb"] = "noop"
["<C-s>"] = "noop"
["<M-s>"] = "noop"
["<Tab>"] = "noop"
["<PageDown>"] = "noop"
["<PageUp>"] = "noop"
["<C-f>"] = "noop"
["<C-b>"] = "noop"
["sv"] = "noop"
["sg"] = "noop"
["st"] = "noop"
```

---

## 🔄 Migration-Strategie

### Schritt 1: init.lua minimalisieren

**Behalte nur:**
- Window control (`q`, `?`, `<Esc>`, `w`, `R`, `C`, `z`)
- Source switching (`"`, `!`, `<`)
- Grundlegende noops (`s`, `t`, `g?`, `<leader>`)

**Alle anderen Imports entfernen!**

### Schritt 2: filesystem.lua maximieren

Verschiebe ALLE filesystem-spezifischen Funktionen von init.lua nach filesystem.lua

### Schritt 3: Andere Sources absichern

Füge explizite `noop` Mappings für alle filesystem-Commands hinzu

---

## 📊 Zusammenfassung

| Mapping-Typ | init.lua (global) | filesystem | buffers | git_status | document_symbols | tests |
|-------------|-------------------|------------|---------|------------|------------------|-------|
| Window control | ✅ | - | - | - | - | - |
| Source switch | ✅ | - | - | - | - | - |
| File operations | ❌ | ✅ | noop | noop | noop | noop |
| Path operations | ❌ | ✅ | noop | noop | noop | noop |
| Trash | ❌ | ✅ | noop | noop | noop | noop |
| Navigation | ❌ | ✅ | noop | noop | noop | noop |
| Buffer delete | - | - | ✅ | - | noop | noop |
| Git delete | - | - | - | ✅ | noop | noop |
| Jump to symbol | - | - | - | - | ✅ | - |
| Test operations | - | - | - | - | noop | ✅ |

Das sollte eine klare Trennung schaffen und Errors in anderen Sources vermeiden! 🎯

