# DAP - Vereinfachtes Setup

## Table of content

- [DAP - Vereinfachtes Setup](#dap-vereinfachtes-setup)
  - [🎯 Was ist anders?](#was-ist-anders)
    - [Vorteile:](#vorteile)
  - [📦 Installation](#installation)
    - [1. Ersetze `lua/plugins/dap.lua`](#1-ersetze-luapluginsdaplua)
    - [2. Installiere Adapter](#2-installiere-adapter)
    - [3. Neustart](#3-neustart)
    - [4. Teste](#4-teste)
  - [🚀 Verwendung](#verwendung)
    - [Breakpoints setzen](#breakpoints-setzen)
    - [Debugging starten](#debugging-starten)
    - [Stepping](#stepping)
    - [UI](#ui)
    - [Session Control](#session-control)
  - [🔧 Unterstützte Sprachen](#untersttzte-sprachen)
  - [➕ Weitere Sprachen hinzufügen](#weitere-sprachen-hinzufgen)
    - [Beispiel: Rust](#beispiel-rust)
  - [🐛 Troubleshooting](#troubleshooting)
    - [Problem: "Adapter not found"](#problem-adapter-not-found)
- [Suche nach dem Adapter und installiere ihn](#suche-nach-dem-adapter-und-installiere-ihn)
    - [Problem: "No configuration found"](#problem-no-configuration-found)
    - [Problem: UI öffnet nicht automatisch](#problem-ui-ffnet-nicht-automatisch)
  - [📊 Debug-Kommandos](#debug-kommandos)
  - [🎨 Anpassungen](#anpassungen)
    - [Keymaps ändern](#keymaps-ndern)
    - [Signs ändern](#signs-ndern)
    - [Highlights ändern](#highlights-ndern)
  - [✅ Das war's!](#das-wars)
  - [🔄 Migration zum Full Framework](#migration-zum-full-framework)

---

## 🎯 Was ist anders?

Dieses Setup funktioniert **OHNE** das komplexe `lua/dap/` Framework. Alles ist direkt in `lua/plugins/dap.lua` definiert.

### Vorteile:
- ✅ Keine Initialisierungsprobleme
- ✅ Keine zirkulären Abhängigkeiten
- ✅ Alles an einem Ort
- ✅ Einfach zu debuggen
- ✅ Funktioniert sofort

---

## 📦 Installation

### 1. Ersetze `lua/plugins/dap.lua`

Kopiere die neue Datei aus dem Artifact.

### 2. Installiere Adapter

```vim
:MasonInstall js-debug-adapter codelldb delve debugpy
```

### 3. Neustart

```vim
:qa
nvim
```

### 4. Teste

```vim
:checkhealth dap
```

---

## 🚀 Verwendung

### Breakpoints setzen

```vim
<leader>db    " Toggle Breakpoint
<leader>dB    " Conditional Breakpoint
```

### Debugging starten

```vim
<leader>dc    " Continue / Start
```

### Stepping

```vim
<leader>ds    " Step Over
<leader>di    " Step Into
<leader>do    " Step Out
```

### UI

```vim
<leader>du    " Toggle DAP UI
<leader>de    " Evaluate Expression
```

### Session Control

```vim
<leader>dt    " Terminate
<leader>dr    " Restart
<leader>dR    " Open REPL
```

---

## 🔧 Unterstützte Sprachen

| Sprache        | Adapter    | Command               |
|----------------|------------|-----------------------|
| Lua            | OSV        | (Built-in)            |
| JavaScript/TS  | pwa-node   | `:MasonInstall js-debug-adapter` |
| Go             | Delve      | `:MasonInstall delve` |
| Python         | debugpy    | `:MasonInstall debugpy` |

---

## ➕ Weitere Sprachen hinzufügen

### Beispiel: Rust

```lua
-- In lua/plugins/dap.lua, nach setup_python_adapter():

local function setup_rust_adapter()
  local lldb = vim.fn.exepath("lldb-vscode")
  if lldb ~= "" then
    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = {
        command = lldb,
        args = { "--port", "${port}" },
      },
    }

    dap.configurations.rust = {
      {
        name = "Launch",
        type = "codelldb",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
      },
    }
  end
end

-- Dann registrieren:
pcall(setup_rust_adapter)
```

---

## 🐛 Troubleshooting

### Problem: "Adapter not found"

**Lösung:** Installiere den Adapter:
```vim
:Mason
# Suche nach dem Adapter und installiere ihn
```

### Problem: "No configuration found"

**Lösung:** Prüfe ob der Adapter für deine Sprache definiert ist:
```vim
:lua print(vim.inspect(require("dap").configurations))
```

### Problem: UI öffnet nicht automatisch

**Lösung:** Öffne manuell:
```vim
<leader>du
```

---

## 📊 Debug-Kommandos

```vim
" Zeige alle Adapter
:lua print(vim.inspect(require("dap").adapters))

" Zeige alle Konfigurationen
:lua print(vim.inspect(require("dap").configurations))

" Zeige Breakpoints
:lua require("dap").list_breakpoints()

" Health Check
:checkhealth dap
```

---

## 🎨 Anpassungen

### Keymaps ändern

In `lua/plugins/dap.lua`, ändere die Keymap-Definitionen:

```lua
map("n", "<F5>", dap.continue, { desc = "[DAP] Continue" })
map("n", "<F10>", dap.step_over, { desc = "[DAP] Step Over" })
-- etc.
```

### Signs ändern

```lua
vim.fn.sign_define("DapBreakpoint", {
  text = "🔴",  -- Dein Icon
  texthl = "DapBreakpoint"
})
```

### Highlights ändern

```lua
vim.api.nvim_set_hl(0, "DapBreakpoint", {
  fg = "#FF0000"  -- Deine Farbe
})
```

---

## ✅ Das war's!

Dieses Setup ist:
- ✅ Einfach
- ✅ Wartbar
- ✅ Erweiterbar
- ✅ Funktioniert garantiert

Keine komplizierten Module, keine versteckten Abhängigkeiten.

---

## 🔄 Migration zum Full Framework

Wenn du später das vollständige `lua/dap/` Framework nutzen möchtest:

1. Behalte diese Datei als Backup
2. Implementiere das Framework schrittweise
3. Teste jede Komponente einzeln
