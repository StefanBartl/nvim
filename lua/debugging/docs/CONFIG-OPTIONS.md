# Debugging.nvim Configuration

Diese Datei dokumentiert alle Optionen, die in `require("debugging").setup(opts)` gesetzt werden können.

## Table of content

  - [Top-Level Setup (`Dbg.Setup`)](#top-level-setup-dbgsetup)
  - [Autocmds (`Dbg.Autocmds.Modules`)](#autocmds-dbgautocmdsmodules)
  - [Markdown (`Dbg.Markdown.Modules`)](#markdown-dbgmarkdownmodules)
  - [Terminals (`Dbg.Terminals.Modules`)](#terminals-dbgterminalsmodules)
  - [Tools (`Dbg.Tools.Modules`)](#tools-dbgtoolsmodules)
  - [Views (`Dbg.Views.Setup`)](#views-dbgviewssetup)
  - [Nvim Options (`Dbg.NvimOpts.Modules`)](#nvim-options-dbgnvimoptsmodules)

---

## Top-Level Setup (`Dbg.Setup`)

| Option        | Typ                                      | Default | Beschreibung |
|---------------|-----------------------------------------|---------|--------------|
| `all`         | boolean                                 | false   | Aktiviert alle Module gleichzeitig |
| `autocmds`    | `Dbg.Autocmds.Modules`                  | nil     | Optionen für Autocmd-bezogene Module |
| `markdown`    | `Dbg.Markdown.Modules`                   | nil     | Optionen für Markdown-bezogene Module |
| `terminals`   | `Dbg.Terminals.Modules`                  | nil     | Optionen für Terminal-bezogene Module |
| `views`       | `Dbg.Views.Setup`                        | nil     | Optionen für Debug Views (:messages, Noice, Fenster) |
| `usercmds`    | boolean                                 | true    | Aktiviert alle User Commands (Reports, Neotree Safety) |
| `tools`       | `Dbg.Tools.Modules`                      | nil     | Verschiedene Utilities (Vardump, Cursor State, Buffer Inspector) |
| `nvim_options`| `Dbg.NvimOpts.Modules`                   | nil     | Optionen für Neovim-spezifische Helpers |

---

## Autocmds (`Dbg.Autocmds.Modules`)

| Option             | Typ     | Default | Beschreibung |
|-------------------|---------|---------|--------------|
| `all`             | boolean | false   | Aktiviert alle Autocmd Module |
| `list_autocmds`   | boolean | false   | Listet alle registrierten Autocmds über Usercommand |

---

## Markdown (`Dbg.Markdown.Modules`)

| Option                  | Typ     | Default | Beschreibung |
|-------------------------|---------|---------|--------------|
| `all`                   | boolean | false   | Aktiviert alle Markdown Module |
| `inline_debug_fixed`    | boolean | false   | Aktiviert Inline-Debugging für Markdown |

---

## Terminals (`Dbg.Terminals.Modules`)

| Option             | Typ     | Default | Beschreibung |
|-------------------|---------|---------|--------------|
| `all`             | boolean | false   | Aktiviert alle Terminal Module |
| `keylogger`        | boolean | false   | Aktiviert Keylogger Terminal Plugin |

---

## Tools (`Dbg.Tools.Modules`)

| Option                 | Typ     | Default | Beschreibung |
|------------------------|---------|---------|--------------|
| `all`                  | boolean | false   | Aktiviert alle Tools |
| `buffer_inspector`     | boolean | false   | Aktiviert Buffer Inspector |
| `cursor_state`         | boolean | false   | Aktiviert Cursor State Tracker |
| `vardump`              | boolean | false   | Aktiviert Vardump Utility |

---

## Views (`Dbg.Views.Setup`)

| Option        | Typ                              | Default | Beschreibung |
|---------------|---------------------------------|---------|--------------|
| `keymaps`     | `Dbg.Views.Keymaps`              | siehe Code | Einstellungen für Tastenkürzel innerhalb der Views |
| `autocmds`    | `Dbg.Views.Autocmds`             | siehe Code | Einstellungen für Auto-Refresh der Views |
| `timings`     | `Dbg.Views.Timings`              | siehe Code | Zeitverzögerungen für Anzeige & Wiederholungen |
| `capture`     | `Dbg.Views.CaptureOpts`          | siehe Code | Optionen für Message Capture (Clipboard, Save) |

---

## Nvim Options (`Dbg.NvimOpts.Modules`)

| Option            | Typ     | Default | Beschreibung |
|------------------|---------|---------|--------------|
| `all`            | boolean | false   | Aktiviert alle Nvim Option Helpers |
| `indent_helpers` | boolean | false   | Hilft beim Anzeigen & Wechseln von Indentation-Providern |

---
