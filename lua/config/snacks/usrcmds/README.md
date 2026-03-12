# Snacks UserCommands Module

Umfassendes UserCommand-System für [snacks.nvim](https://github.com/folke/snacks.nvim) mit Autocompletion und modularer Konfiguration.

## Table of content

- [Snacks UserCommands Module](#snacks-usercommands-module)
  - [🎯 Features](#features)
  - [📦 Installation](#installation)
    - [Mit Lazy.nvim](#mit-lazynvim)
    - [Manuelle Installation](#manuelle-installation)
  - [🚀 Quick Start](#quick-start)
    - [Basis-Setup](#basis-setup)
    - [Custom Setup](#custom-setup)
    - [Granulare Kontrolle](#granulare-kontrolle)
  - [📝 Verwendung](#verwendung)
    - [Hauptcommand mit Autocompletion](#hauptcommand-mit-autocompletion)
    - [Direkte Commands](#direkte-commands)
  - [📚 Command-Kategorien](#command-kategorien)
    - [Misc (3 Commands)](#misc-3-commands)
    - [Find (6 Commands)](#find-6-commands)
    - [Git (7 Commands)](#git-7-commands)
    - [GitHub (4 Commands)](#github-4-commands)
    - [Grep (4 Commands)](#grep-4-commands)
    - [Search (21 Commands)](#search-21-commands)
    - [LSP (9 Commands)](#lsp-9-commands)
  - [📖 Dokumentation](#dokumentation)
  - [🏗️ Struktur](#struktur)
  - [🔧 Erweiterte Konfiguration](#erweiterte-konfiguration)
    - [Beispiel: Nur oft genutzte Commands](#beispiel-nur-oft-genutzte-commands)
    - [Integration mit which-key](#integration-mit-which-key)
    - [Custom Keybindings](#custom-keybindings)
  - [🔍 Troubleshooting](#troubleshooting)
    - [Commands nicht verfügbar](#commands-nicht-verfgbar)
    - [snacks.nvim nicht gefunden](#snacksnvim-nicht-gefunden)
    - [Picker öffnet nicht](#picker-ffnet-nicht)
  - [📝 Anforderungen](#anforderungen)
  - [🤝 Beiträge](#beitrge)
  - [📜 Lizenz](#lizenz)
  - [🔗 Links](#links)

---

## 🎯 Features

- ✅ **70+ UserCommands** für alle snacks.nvim Features
- ✅ **Autocompletion** mit Tab-Unterstützung
- ✅ **Modulare Struktur** - Kategorien einzeln aktivierbar
- ✅ **Granulare Kontrolle** - Commands einzeln togglebar
- ✅ **Sichere Fehlerbehandlung** mit pcall
- ✅ **LuaLS Typisierung** für IDE-Support
- ✅ **Hauptcommand** `:Snacks` mit intuitiver Syntax

## 📦 Installation

### Mit Lazy.nvim

```lua
{
  dir = "~/.config/nvim/lua/usrcmds/snacks",
  name = "usrcmds-snacks",
  lazy = false,
  dependencies = {
    "folke/snacks.nvim",
  },
  config = function()
    require("config.snacks.usrcmds").setup()
  end,
}
```

### Manuelle Installation

1. Kopiere den `usrcmds/snacks/` Ordner nach `~/.config/nvim/lua/usrcmds/snacks/`
2. Füge zu deiner `init.lua` hinzu:

```lua
require("config.snacks.usrcmds").setup()
```

## 🚀 Quick Start

### Basis-Setup

```lua
-- Minimale Konfiguration (alle Commands aktiviert)
require("config.snacks.usrcmds").setup()
```

### Custom Setup

```lua
-- Selektive Aktivierung
require("config.snacks.usrcmds").setup({
  find = { enabled = true },
  git = { enabled = true },
  github = { enabled = false }, -- GitHub deaktiviert
  grep = { enabled = true },
  search = { enabled = true },
  lsp = { enabled = true },
  misc = { enabled = true },
})
```

### Granulare Kontrolle

```lua
-- Einzelne Commands innerhalb Kategorien togglen
require("config.snacks.usrcmds").setup({
  find = {
    enabled = true,
    files = true,
    buffers = true,
    projects = false, -- SnacksFindProjects deaktiviert
  },

  search = {
    enabled = true,
    help = true,
    keymaps = true,
    colorschemes = false, -- SnacksSearchColorschemes deaktiviert
  },
})
```

## 📝 Verwendung

### Hauptcommand mit Autocompletion

```vim
:Snacks <Tab>              " Zeigt alle Kategorien
:Snacks find <Tab>         " Zeigt find-Subcategories
:Snacks find files         " Führt SnacksFindFiles aus
:Snacks git branches       " Führt SnacksGitBranches aus
```

### Direkte Commands

```vim
:SnacksFindFiles           " File Picker
:SnacksFindBuffers         " Buffer Picker
:SnacksGitStatus           " Git Status Picker
:SnacksGitBranches         " Git Branches Picker
:SnacksGrep                " Grep Picker
:SnacksSearchHelp          " Help Pages Picker
:SnacksLspDefinitions      " LSP Definitions Picker
:SnacksExplorer            " File Explorer
```

## 📚 Command-Kategorien

### Misc (3 Commands)
- Explorer, Notifications, Command History

### Find (6 Commands)
- Buffers, Files, Git Files, Config, Recent, Projects

### Git (7 Commands)
- Branches, Log, Log Line, Status, Stash, Diff, Log File

### GitHub (4 Commands)
- Issues (open/all), Pull Requests (open/all)

### Grep (4 Commands)
- Grep, Lines, Buffers, Word

### Search (21 Commands)
- Registers, History, Autocmds, Commands, Diagnostics, Help, Highlights, Icons, Jumps, Keymaps, Marks, Man, und mehr

### LSP (9 Commands)
- Definitions, Declarations, References, Implementations, Type Definitions, Incoming/Outgoing Calls, Symbols

**Gesamt: 54 dedizierte Commands + Hauptcommand**

## 📖 Dokumentation

Siehe [COMMANDS.md](./COMMANDS.md) für:
- Vollständige Command-Referenz-Tabelle
- Detaillierte Beschreibung jedes Commands
- Syntax und Verwendungsbeispiele
- Konfigurationsoptionen
- Troubleshooting-Guide

## 🏗️ Struktur

```
usrcmds/snacks/
├── init.lua          # Hauptmodul mit setup() und :Snacks command
├── types.lua         # LuaLS Type-Definitionen
├── find.lua          # Find-Commands
├── git.lua           # Git-Commands
├── github.lua        # GitHub-Commands
├── grep.lua          # Grep-Commands
├── search.lua        # Search-Commands
├── lsp.lua           # LSP-Commands
├── misc.lua          # Miscellaneous Commands
├── COMMANDS.md       # Detaillierte Dokumentation
└── README.md         # Dieser File
```

## 🔧 Erweiterte Konfiguration

### Beispiel: Nur oft genutzte Commands

```lua
require("config.snacks.usrcmds").setup({
  find = {
    enabled = true,
    buffers = true,
    files = true,
    git_files = false,
    config = false,
    recent = false,
    projects = false,
  },

  git = {
    enabled = true,
    branches = true,
    status = true,
    log = false,
    log_line = false,
    stash = false,
    diff = false,
    log_file = false,
  },

  github = { enabled = false },

  grep = {
    enabled = true,
    grep = true,
    lines = false,
    buffers = false,
    word = true,
  },

  search = {
    enabled = true,
    help = true,
    keymaps = true,
    command_history = true,
    diagnostics = true,
    -- Rest deaktiviert
  },

  lsp = {
    enabled = true,
    definitions = true,
    references = true,
    implementations = false,
    -- Rest deaktiviert
  },

  misc = {
    enabled = true,
    explorer = true,
    notifications = false,
    command_history = false,
  },
})
```

### Integration mit which-key

```lua
require("which-key").register({
  ["<leader>s"] = {
    name = "+snacks",
    f = {
      name = "+find",
      f = { ":SnacksFindFiles<CR>", "Files" },
      b = { ":SnacksFindBuffers<CR>", "Buffers" },
      g = { ":SnacksFindGitFiles<CR>", "Git Files" },
    },
    g = {
      name = "+git",
      b = { ":SnacksGitBranches<CR>", "Branches" },
      s = { ":SnacksGitStatus<CR>", "Status" },
      l = { ":SnacksGitLog<CR>", "Log" },
    },
  },
})
```

### Custom Keybindings

```lua
local map = vim.keymap.set

-- Find
map("n", "<leader>ff", ":SnacksFindFiles<CR>", { desc = "Find Files" })
map("n", "<leader>fb", ":SnacksFindBuffers<CR>", { desc = "Find Buffers" })
map("n", "<leader>fr", ":SnacksFindRecent<CR>", { desc = "Recent Files" })

-- Git
map("n", "<leader>gs", ":SnacksGitStatus<CR>", { desc = "Git Status" })
map("n", "<leader>gb", ":SnacksGitBranches<CR>", { desc = "Git Branches" })
map("n", "<leader>gl", ":SnacksGitLog<CR>", { desc = "Git Log" })

-- Grep
map("n", "<leader>sg", ":SnacksGrep<CR>", { desc = "Grep" })
map("n", "<leader>sw", ":SnacksGrepWord<CR>", { desc = "Grep Word" })

-- LSP
map("n", "gd", ":SnacksLspDefinitions<CR>", { desc = "Goto Definition" })
map("n", "gr", ":SnacksLspReferences<CR>", { desc = "References" })
map("n", "gi", ":SnacksLspImplementations<CR>", { desc = "Implementations" })

-- Misc
map("n", "<leader>e", ":SnacksExplorer<CR>", { desc = "Explorer" })
map("n", "<leader>n", ":SnacksNotifications<CR>", { desc = "Notifications" })
```

## 🔍 Troubleshooting

### Commands nicht verfügbar

```lua
-- Prüfe ob setup() aufgerufen wurde
:lua print(vim.inspect(require("config.snacks.usrcmds")))

-- Prüfe ob Kategorie aktiviert ist
:lua print(vim.inspect(require("config.snacks.usrcmds").default_opts))
```

### snacks.nvim nicht gefunden

```lua
-- Prüfe Installation
:Lazy

-- Prüfe ob snacks.nvim geladen ist
:lua print(require("snacks"))
```

### Picker öffnet nicht

```lua
-- Prüfe snacks.picker Config
:lua print(require("snacks").picker)

-- Check Logs
:messages
```

## 📝 Anforderungen

- Neovim >= 0.9.4
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- Custom `lib.usercmd` Bibliothek (im Projekt enthalten)
- Custom `lib.notify` Bibliothek (im Projekt enthalten)

## 🤝 Beiträge

Dieses Modul ist Teil einer privaten Neovim-Konfiguration. Bei Fragen oder Vorschlägen öffne ein Issue oder Pull Request.

## 📜 Lizenz

Dieses Modul ist Teil deiner Neovim-Konfiguration und unterliegt deren Lizenz.

## 🔗 Links

- [snacks.nvim GitHub](https://github.com/folke/snacks.nvim)
- [snacks.nvim Dokumentation](https://github.com/folke/snacks.nvim/tree/main/docs)
- [Neovim UserCommand API](https://neovim.io/doc/user/api.html#nvim_create_user_command())

---

**Version:** 1.0.0
**Erstellt:** 2025-02-11
