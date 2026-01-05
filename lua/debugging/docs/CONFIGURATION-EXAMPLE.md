# Debugging.nvim – Modulkonfiguration

Diese Datei dokumentiert alle verfügbaren Module, Optionen und Default-Werte für `require("debugging").setup()`.

---

## Table of content

  - [Notes](#notes)
  - [1. Hauptsetup](#1-hauptsetup)
  - [2. Module](#2-module)
    - [2.1 Autocmds](#21-autocmds)
    - [2.2 Markdown](#22-markdown)
    - [2.3 Terminals](#23-terminals)
    - [2.4 Views](#24-views)
    - [2.5 Tools](#25-tools)
    - [2.6 Nvim Options](#26-nvim-options)
    - [2.7 User Commands](#27-user-commands)
  - [3. Beispiele für Setup](#3-beispiele-fr-setup)
  - [4. Keymaps (Standard `<leader>d`)](#4-keymaps-standard-leaderd)
  - [5. User Commands](#5-user-commands)

---

## Notes

* Module werden nur aktiviert, wenn das jeweilige Flag auf `true` oder `all = true` gesetzt ist.
* `all = true` überschreibt selektive Optionen innerhalb des Moduls.
* Default-Prefix für Views-Keymaps ist `<lt>`.
* Vardump nimmt Variable unter Cursor, wenn kein Argument angegeben wird.


## 1. Hauptsetup

```lua
require("debugging").setup({
  all = false,        -- optional: aktiviert alle Module
  autocmds = nil,     -- Dbg.Autocmds.Modules|nil
  markdown = nil,     -- Dbg.Markdown.Modules|nil
  terminals = nil,    -- Dbg.Terminals.Modules|nil
  views = nil,        -- Dbg.Views.Setup|nil
  usercmds = true,    -- boolean|nil
  tools = nil,        -- Dbg.Tools.Modules|nil
})
````

---

## 2. Module

### 2.1 Autocmds

| Option          | Typ      | Default | Beschreibung                             |
| --------------- | -------- | ------- | ---------------------------------------- |
| `all`           | boolean? | `false` | Aktiviert alle Autocmd-bezogenen Module  |
| `list_autocmds` | boolean? | `false` | Listet alle Autocmds über `:autocmd` auf |

Beispiel:

```lua
require("debugging").setup({
  autocmds = { list_autocmds = true }
})
```

---

### 2.2 Markdown

| Option               | Typ      | Default | Beschreibung                            |
| -------------------- | -------- | ------- | --------------------------------------- |
| `all`                | boolean? | `false` | Aktiviert alle Markdown-Module          |
| `inline_debug_fixed` | boolean? | `false` | Aktiviert Inline-Debugging für Markdown |

Beispiel:

```lua
require("debugging").setup({
  markdown = { inline_debug_fixed = true }
})
```

---

### 2.3 Terminals

| Option      | Typ      | Default | Beschreibung                          |
| ----------- | -------- | ------- | ------------------------------------- |
| `all`       | boolean? | `false` | Aktiviert alle Terminal-Tools         |
| `keylogger` | boolean? | `false` | Aktiviert Keylogger-Terminal-Funktion |

Beispiel:

```lua
require("debugging").setup({
  terminals = { keylogger = true }
})
```

---

### 2.4 Views

| Option     | Typ                   | Default     | Beschreibung                      |
| ---------- | --------------------- | ----------- | --------------------------------- |
| `keymaps`  | Dbg.Views.Keymaps     | siehe unten | Keymap-Konfiguration für Views    |
| `autocmds` | Dbg.Views.Autocmds    | siehe unten | Autocmd-Konfiguration für Views   |
| `timings`  | Dbg.Views.Timings     | siehe unten | Timing-Optionen für Refresh/Retry |
| `capture`  | Dbg.Views.CaptureOpts | siehe unten | Optionen für Capture-Commands     |

**Keymaps Defaults:**

```lua
{
  enable = true,
  map = vim.keymap.set,
  prefix = "<lt>",
}
```

**Autocmds Defaults:**

```lua
{
  enable = true,
  group_name = "DebugViewsAuto",
  auto_refresh = true,
}
```

**Timings Defaults:**

```lua
{
  delay_messages_ms = 30,
  delay_noice_ms = 50,
  retry_delay_ms = 60,
  attempts = 3,
}
```

**Capture Defaults:**

```lua
{
  debug = false,
  clipboard = true,
  save_file = true,
  output_dir = nil,
}
```

Beispiel:

```lua
require("debugging").setup({
  views = {
    keymaps = { enable = true, prefix = "<leader>d" },
    autocmds = { enable = true, auto_refresh = true },
    timings = { delay_messages_ms = 20, attempts = 5 },
    capture = { clipboard = true, save_file = true },
  }
})
```

---

### 2.5 Tools

| Option             | Typ      | Default | Beschreibung               |
| ------------------ | -------- | ------- | -------------------------- |
| `all`              | boolean? | `false` | Aktiviert alle Tools       |
| `buffer_inspector` | boolean? | `false` | Aktiviert Buffer-Inspektor |
| `cursor_state`     | boolean? | `false` | Zeigt Cursor-Zustand an    |
| `vardump`          | boolean? | `false` | Aktiviert Vardump-Funktion |

Beispiel:

```lua
require("debugging").setup({
  tools = { vardump = true, cursor_state = true }
})
```

---

### 2.6 Nvim Options

| Option           | Typ      | Default | Beschreibung                      |
| ---------------- | -------- | ------- | --------------------------------- |
| `all`            | boolean? | `false` | Aktiviert alle nvim_options Tools |
| `indent_helpers` | boolean? | `false` | Aktiviert Helper für Indentation  |

---

### 2.7 User Commands

| Option     | Typ      | Default | Beschreibung                                                 |
| ---------- | -------- | ------- | ------------------------------------------------------------ |
| `usercmds` | boolean? | `true`  | Aktiviert User Commands (:BufReport, :TabReport, :WinReport) |

Beispiel:

```lua
require("debugging").setup({
  usercmds = true
})
```

---

## 3. Beispiele für Setup

**Alle Views + Vardump aktivieren:**

```lua
require("debugging").setup({
  views = { all = true },
  tools = { vardump = true },
})
```

**Nur Views mit Keymaps aktivieren:**

```lua
require("debugging").setup({
  views = {
    keymaps = { enable = true, prefix = "<leader>d" }
  }
})
```

**Nur Tools aktivieren:**

```lua
require("debugging").setup({
  tools = { cursor_state = true, vardump = true }
})
```

**Alles aktivieren:**

```lua
require("debugging").setup({
  all = true
})
```

---

## 4. Keymaps (Standard `<leader>d`)

| Key          | Action                    |
| ------------ | ------------------------- |
| `<leader>dm` | Messages view             |
| `<leader>dn` | Noice all                 |
| `<leader>de` | Noice errors              |
| `<leader>dc` | Capture to file+clipboard |
| `<leader>dx` | Clear all debug windows   |

---

## 5. User Commands

```vim
:BufReport       " Buffer-Report
:TabReport       " Tab-Report
:WinReport       " Aktuelles Fenster
:WinReport 1000  " Bestimmtes Fenster
:DebugMessagesCapture
:DebugMessagesShow
:DebugWindowsClear
```

---

