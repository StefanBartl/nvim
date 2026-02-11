# Snacks UserCommands Documentation

Dieses Modul bietet umfassende UserCommands für alle Features des [snacks.nvim](https://github.com/folke/snacks.nvim) Plugins.

## Table of content

- [Snacks UserCommands Documentation](#snacks-usercommands-documentation)
  - [Installation & Setup](#installation-setup)
  - [Features](#features)
  - [Hauptcommand](#hauptcommand)
    - [`:Snacks`](#snacks)
  - [Command-Übersicht](#command-bersicht)
    - [Schnellreferenz-Tabelle](#schnellreferenz-tabelle)
  - [Detaillierte Command-Referenz](#detaillierte-command-referenz)
    - [Misc Commands](#misc-commands)
      - [`:SnacksExplorer`](#snacksexplorer)
      - [`:SnacksNotifications`](#snacksnotifications)
      - [`:SnacksCommandHistory`](#snackscommandhistory)
    - [Find Commands](#find-commands)
      - [`:SnacksFindBuffers`](#snacksfindbuffers)
      - [`:SnacksFindFiles`](#snacksfindfiles)
      - [`:SnacksFindGitFiles`](#snacksfindgitfiles)
      - [`:SnacksFindConfig`](#snacksfindconfig)
      - [`:SnacksFindRecent`](#snacksfindrecent)
      - [`:SnacksFindProjects`](#snacksfindprojects)
    - [Git Commands](#git-commands)
      - [`:SnacksGitBranches`](#snacksgitbranches)
      - [`:SnacksGitLog`](#snacksgitlog)
      - [`:SnacksGitLogLine`](#snacksgitlogline)
      - [`:SnacksGitStatus`](#snacksgitstatus)
      - [`:SnacksGitStash`](#snacksgitstash)
      - [`:SnacksGitDiff`](#snacksgitdiff)
      - [`:SnacksGitLogFile`](#snacksgitlogfile)
    - [GitHub Commands](#github-commands)
      - [`:SnacksGithubIssues`](#snacksgithubissues)
      - [`:SnacksGithubIssuesAll`](#snacksgithubissuesall)
      - [`:SnacksGithubPRs`](#snacksgithubprs)
      - [`:SnacksGithubPRsAll`](#snacksgithubprsall)
    - [Grep Commands](#grep-commands)
      - [`:SnacksGrep`](#snacksgrep)
      - [`:SnacksGrepLines`](#snacksgreplines)
      - [`:SnacksGrepBuffers`](#snacksgrepbuffers)
      - [`:SnacksGrepWord`](#snacksgrepword)
    - [Search Commands](#search-commands)
      - [`:SnacksSearchRegisters`](#snackssearchregisters)
      - [`:SnacksSearchHistory`](#snackssearchhistory)
      - [`:SnacksSearchAutocmds`](#snackssearchautocmds)
      - [`:SnacksSearchCommands`](#snackssearchcommands)
      - [`:SnacksSearchCommandHistory`](#snackssearchcommandhistory)
      - [`:SnacksSearchDiagnostics`](#snackssearchdiagnostics)
      - [`:SnacksSearchDiagnosticsBuffer`](#snackssearchdiagnosticsbuffer)
      - [`:SnacksSearchHelp`](#snackssearchhelp)
      - [`:SnacksSearchHighlights`](#snackssearchhighlights)
      - [`:SnacksSearchIcons`](#snackssearchicons)
      - [`:SnacksSearchJumps`](#snackssearchjumps)
      - [`:SnacksSearchKeymaps`](#snackssearchkeymaps)
      - [`:SnacksSearchLoclist`](#snackssearchloclist)
      - [`:SnacksSearchMarks`](#snackssearchmarks)
      - [`:SnacksSearchMan`](#snackssearchman)
      - [`:SnacksSearchLazy`](#snackssearchlazy)
      - [`:SnacksSearchQflist`](#snackssearchqflist)
      - [`:SnacksSearchResume`](#snackssearchresume)
      - [`:SnacksSearchUndo`](#snackssearchundo)
      - [`:SnacksSearchColorschemes`](#snackssearchcolorschemes)
    - [LSP Commands](#lsp-commands)
      - [`:SnacksLspDefinitions`](#snackslspdefinitions)
      - [`:SnacksLspDeclarations`](#snackslspdeclarations)
      - [`:SnacksLspReferences`](#snackslspreferences)
      - [`:SnacksLspImplementations`](#snackslspimplementations)
      - [`:SnacksLspTypeDefinitions`](#snackslsptypedefinitions)
      - [`:SnacksLspIncomingCalls`](#snackslspincomingcalls)
      - [`:SnacksLspOutgoingCalls`](#snackslspoutgoingcalls)
      - [`:SnacksLspSymbols`](#snackslspsymbols)
      - [`:SnacksLspWorkspaceSymbols`](#snackslspworkspacesymbols)
  - [Konfiguration](#konfiguration)
    - [Grundlegende Konfiguration](#grundlegende-konfiguration)
    - [Erweiterte Konfiguration](#erweiterte-konfiguration)
    - [Minimale Konfiguration (nur oft genutzte Commands)](#minimale-konfiguration-nur-oft-genutzte-commands)
  - [Tipps & Best Practices](#tipps-best-practices)
    - [1. Nutze das Hauptcommand mit Autocompletion](#1-nutze-das-hauptcommand-mit-autocompletion)
    - [2. Erstelle eigene Keybindings](#2-erstelle-eigene-keybindings)
    - [3. Integration mit which-key](#3-integration-mit-which-key)
    - [4. Lazy-Loading](#4-lazy-loading)
    - [5. Conditional Loading](#5-conditional-loading)
  - [Troubleshooting](#troubleshooting)
    - [Commands werden nicht gefunden](#commands-werden-nicht-gefunden)
    - [snacks.nvim nicht verfügbar](#snacksnvim-nicht-verfgbar)
    - [Picker öffnet nicht](#picker-ffnet-nicht)
    - [LSP Commands funktionieren nicht](#lsp-commands-funktionieren-nicht)
    - [GitHub Commands schlagen fehl](#github-commands-schlagen-fehl)
  - [Siehe auch](#siehe-auch)
  - [Lizenz](#lizenz)

---

## Installation & Setup

```lua
-- In deiner Neovim-Konfiguration
require("config.snacks.usrcmds").setup({
  -- Optional: Konfiguriere welche Kategorien aktiviert sein sollen
  find = { enabled = true },
  git = { enabled = true },
  github = { enabled = true },
  grep = { enabled = true },
  search = { enabled = true },
  lsp = { enabled = true },
  misc = { enabled = true },
})
```

## Features

- ✅ **Autocompletion**: Alle Commands unterstützen Tab-Completion
- ✅ **Modulare Struktur**: Kategorien können einzeln aktiviert/deaktiviert werden
- ✅ **Granulare Kontrolle**: Einzelne Commands innerhalb von Kategorien togglebar
- ✅ **Sichere Fehlerbehandlung**: Alle Commands verwenden pcall für robuste Ausführung
- ✅ **LuaLS Typisierung**: Vollständige Type-Annotations für IDE-Support

## Hauptcommand

### `:Snacks`

Das Hauptcommand bietet eine intuitive Interface mit Autocompletion:

```vim
:Snacks find files          " SnacksFindFiles
:Snacks git branches        " SnacksGitBranches
:Snacks search help         " SnacksSearchHelp
:Snacks explorer           " SnacksExplorer
```

## Command-Übersicht

### Schnellreferenz-Tabelle

| Command | Beschreibung | Kategorie |
|---------|--------------|-----------|
| `:SnacksExplorer` | Öffnet den File Explorer | Misc |
| `:SnacksNotifications` | Notification History Picker | Misc |
| `:SnacksCommandHistory` | Command History Picker | Misc |
| `:SnacksFindBuffers` | Buffer Picker | Find |
| `:SnacksFindFiles` | File Picker | Find |
| `:SnacksFindGitFiles` | Git Files Picker | Find |
| `:SnacksFindConfig` | Config Files Picker | Find |
| `:SnacksFindRecent` | Recent Files Picker | Find |
| `:SnacksFindProjects` | Projects Picker | Find |
| `:SnacksGitBranches` | Git Branches Picker | Git |
| `:SnacksGitLog` | Git Log Picker | Git |
| `:SnacksGitLogLine` | Git Log Line Picker | Git |
| `:SnacksGitStatus` | Git Status Picker | Git |
| `:SnacksGitStash` | Git Stash Picker | Git |
| `:SnacksGitDiff` | Git Diff (Hunks) Picker | Git |
| `:SnacksGitLogFile` | Git Log File Picker | Git |
| `:SnacksGithubIssues` | GitHub Issues (open) Picker | GitHub |
| `:SnacksGithubIssuesAll` | GitHub Issues (all) Picker | GitHub |
| `:SnacksGithubPRs` | GitHub Pull Requests (open) Picker | GitHub |
| `:SnacksGithubPRsAll` | GitHub Pull Requests (all) Picker | GitHub |
| `:SnacksGrep` | Grep Picker | Grep |
| `:SnacksGrepLines` | Buffer Lines Picker | Grep |
| `:SnacksGrepBuffers` | Grep Open Buffers Picker | Grep |
| `:SnacksGrepWord` | Grep Word/Selection Picker | Grep |
| `:SnacksSearchRegisters` | Registers Picker | Search |
| `:SnacksSearchHistory` | Search History Picker | Search |
| `:SnacksSearchAutocmds` | Autocmds Picker | Search |
| `:SnacksSearchCommands` | Commands Picker | Search |
| `:SnacksSearchCommandHistory` | Command History Picker | Search |
| `:SnacksSearchDiagnostics` | Diagnostics Picker | Search |
| `:SnacksSearchDiagnosticsBuffer` | Buffer Diagnostics Picker | Search |
| `:SnacksSearchHelp` | Help Pages Picker | Search |
| `:SnacksSearchHighlights` | Highlights Picker | Search |
| `:SnacksSearchIcons` | Icons Picker | Search |
| `:SnacksSearchJumps` | Jumps Picker | Search |
| `:SnacksSearchKeymaps` | Keymaps Picker | Search |
| `:SnacksSearchLoclist` | Location List Picker | Search |
| `:SnacksSearchMarks` | Marks Picker | Search |
| `:SnacksSearchMan` | Man Pages Picker | Search |
| `:SnacksSearchLazy` | Plugin Specs Picker | Search |
| `:SnacksSearchQflist` | Quickfix List Picker | Search |
| `:SnacksSearchResume` | Resume Last Picker | Search |
| `:SnacksSearchUndo` | Undo History Picker | Search |
| `:SnacksSearchColorschemes` | Colorschemes Picker | Search |
| `:SnacksLspDefinitions` | LSP Definitions Picker | LSP |
| `:SnacksLspDeclarations` | LSP Declarations Picker | LSP |
| `:SnacksLspReferences` | LSP References Picker | LSP |
| `:SnacksLspImplementations` | LSP Implementations Picker | LSP |
| `:SnacksLspTypeDefinitions` | LSP Type Definitions Picker | LSP |
| `:SnacksLspIncomingCalls` | LSP Incoming Calls Picker | LSP |
| `:SnacksLspOutgoingCalls` | LSP Outgoing Calls Picker | LSP |
| `:SnacksLspSymbols` | LSP Symbols Picker | LSP |
| `:SnacksLspWorkspaceSymbols` | LSP Workspace Symbols Picker | LSP |

---

## Detaillierte Command-Referenz

### Misc Commands

#### `:SnacksExplorer`

Öffnet den snacks.nvim File Explorer.

**Syntax:**
```vim
:SnacksExplorer
```

**Beschreibung:**
Öffnet den integrierten File Explorer von snacks.nvim. Der Explorer bietet eine moderne, performante Alternative zu klassischen File-Explorern.

**Verwendung:**
- Navigiere durch dein Dateisystem
- Erstelle, lösche, umbenenne Dateien und Verzeichnisse
- Öffne Dateien in verschiedenen Split-Modi

**Äquivalent zu:**
```lua
require("snacks").explorer()
```

---

#### `:SnacksNotifications`

Öffnet den Notification History Picker.

**Syntax:**
```vim
:SnacksNotifications
```

**Beschreibung:**
Zeigt alle Benachrichtigungen in einem Picker, sodass du durch deine Notification-Historie browsen kannst.

**Verwendung:**
- Überprüfe vergangene Benachrichtigungen
- Suche nach bestimmten Messages
- Filtere nach Notification-Level (Info, Warning, Error)

**Äquivalent zu:**
```lua
require("snacks").picker.notifications()
```

---

#### `:SnacksCommandHistory`

Öffnet den Command History Picker.

**Syntax:**
```vim
:SnacksCommandHistory
```

**Beschreibung:**
Zeigt die Historie der ausgeführten Vim/Neovim Commands mit Fuzzy-Finding.

**Verwendung:**
- Durchsuche kürzlich ausgeführte Commands
- Führe Commands erneut aus
- Kopiere Commands für Mappings

**Äquivalent zu:**
```lua
require("snacks").picker.command_history()
```

---

### Find Commands

#### `:SnacksFindBuffers`

Öffnet den Buffer Picker.

**Syntax:**
```vim
:SnacksFindBuffers
```

**Beschreibung:**
Zeigt alle offenen Buffer in einem Fuzzy-Finder, ermöglicht schnelles Wechseln zwischen Buffern.

**Verwendung:**
- Schnelles Buffer-Switching
- Suche Buffer nach Namen
- Zeige Buffer-Metadaten (modified, line count, etc.)

**Äquivalent zu:**
```lua
require("snacks").picker.buffers()
```

---

#### `:SnacksFindFiles`

Öffnet den File Picker.

**Syntax:**
```vim
:SnacksFindFiles
```

**Beschreibung:**
Fuzzy-Finder für Dateien im aktuellen Working Directory (rekursiv).

**Verwendung:**
- Schnelles Finden von Dateien im Projekt
- Berücksichtigt .gitignore
- Ignoriert node_modules, .git, etc.

**Äquivalent zu:**
```lua
require("snacks").picker.files()
```

---

#### `:SnacksFindGitFiles`

Öffnet den Git Files Picker.

**Syntax:**
```vim
:SnacksFindGitFiles
```

**Beschreibung:**
Zeigt nur Dateien, die in Git getrackt werden.

**Verwendung:**
- Schneller als normaler File-Finder bei großen Projekten
- Zeigt nur versionierte Dateien
- Perfekt für Git-Repositories

**Äquivalent zu:**
```lua
require("snacks").picker.git_files()
```

---

#### `:SnacksFindConfig`

Öffnet den Config Files Picker.

**Syntax:**
```vim
:SnacksFindConfig
```

**Beschreibung:**
Zeigt Dateien aus deinem Neovim Config-Verzeichnis.

**Verwendung:**
- Schnelles Editieren von Config-Dateien
- Durchsuche Plugin-Konfigurationen
- Navigiere durch deine nvim-Struktur

**Äquivalent zu:**
```lua
require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
```

---

#### `:SnacksFindRecent`

Öffnet den Recent Files Picker.

**Syntax:**
```vim
:SnacksFindRecent
```

**Beschreibung:**
Zeigt kürzlich geöffnete Dateien (oldfiles).

**Verwendung:**
- Springe zurück zu kürzlich bearbeiteten Dateien
- Durchsuche deine Datei-Historie
- Filtere nach Projekt oder CWD

**Äquivalent zu:**
```lua
require("snacks").picker.recent()
```

---

#### `:SnacksFindProjects`

Öffnet den Projects Picker.

**Syntax:**
```vim
:SnacksFindProjects
```

**Beschreibung:**
Zeigt erkannte Projekte (Git-Roots) aus deinen recent files.

**Verwendung:**
- Wechsle schnell zwischen Projekten
- Öffne Projekte in neuem CWD
- Optional: Session-Management Integration

**Äquivalent zu:**
```lua
require("snacks").picker.projects()
```

---

### Git Commands

#### `:SnacksGitBranches`

Öffnet den Git Branches Picker.

**Syntax:**
```vim
:SnacksGitBranches
```

**Beschreibung:**
Zeigt alle Git-Branches (lokal und remote) mit Checkout-Möglichkeit.

**Verwendung:**
- Wechsle zwischen Branches
- Erstelle neue Branches
- Zeige Branch-Informationen (last commit, author, etc.)

**Äquivalent zu:**
```lua
require("snacks").picker.git_branches()
```

---

#### `:SnacksGitLog`

Öffnet den Git Log Picker.

**Syntax:**
```vim
:SnacksGitLog
```

**Beschreibung:**
Zeigt die Git Commit-Historie des Repositories.

**Verwendung:**
- Browse durch Commits
- Suche Commits nach Message, Author, Hash
- Preview Commit-Diffs

**Äquivalent zu:**
```lua
require("snacks").picker.git_log()
```

---

#### `:SnacksGitLogLine`

Öffnet den Git Log Line Picker.

**Syntax:**
```vim
:SnacksGitLogLine
```

**Beschreibung:**
Zeigt die Git-Historie für die aktuelle Zeile (git blame erweitert).

**Verwendung:**
- Sehe wer und wann eine Zeile geändert wurde
- Browse durch alle Änderungen dieser Zeile
- Jump zu Commits

**Äquivalent zu:**
```lua
require("snacks").picker.git_log_line()
```

---

#### `:SnacksGitStatus`

Öffnet den Git Status Picker.

**Syntax:**
```vim
:SnacksGitStatus
```

**Beschreibung:**
Zeigt den aktuellen Git-Status (modified, staged, untracked files).

**Verwendung:**
- Schneller Überblick über Änderungen
- Stage/Unstage Dateien
- Diff-Preview

**Äquivalent zu:**
```lua
require("snacks").picker.git_status()
```

---

#### `:SnacksGitStash`

Öffnet den Git Stash Picker.

**Syntax:**
```vim
:SnacksGitStash
```

**Beschreibung:**
Zeigt alle Git-Stashes mit Apply/Drop-Funktionalität.

**Verwendung:**
- Browse durch Stashes
- Apply Stashes
- Delete Stashes
- Preview Stash-Diffs

**Äquivalent zu:**
```lua
require("snacks").picker.git_stash()
```

---

#### `:SnacksGitDiff`

Öffnet den Git Diff (Hunks) Picker.

**Syntax:**
```vim
:SnacksGitDiff
```

**Beschreibung:**
Zeigt alle Diff-Hunks (Änderungen) im Repository.

**Verwendung:**
- Springe direkt zu Änderungen
- Review Code-Änderungen
- Stage einzelne Hunks

**Äquivalent zu:**
```lua
require("snacks").picker.git_diff()
```

---

#### `:SnacksGitLogFile`

Öffnet den Git Log File Picker.

**Syntax:**
```vim
:SnacksGitLogFile
```

**Beschreibung:**
Zeigt die Git-Historie nur für die aktuelle Datei.

**Verwendung:**
- File-spezifische Historie
- Sehe alle Commits die diese Datei betreffen
- Vergleiche verschiedene Versionen

**Äquivalent zu:**
```lua
require("snacks").picker.git_log_file()
```

---

### GitHub Commands

#### `:SnacksGithubIssues`

Öffnet den GitHub Issues (open) Picker.

**Syntax:**
```vim
:SnacksGithubIssues
```

**Beschreibung:**
Zeigt offene GitHub Issues für das aktuelle Repository.

**Verwendung:**
- Browse offene Issues
- Suche nach Issue-Nummer, Titel, Label
- Öffne Issues im Browser

**Voraussetzung:**
- `gh` CLI muss installiert und authentifiziert sein
- Repository muss GitHub-Remote haben

**Äquivalent zu:**
```lua
require("snacks").picker.gh_issue()
```

---

#### `:SnacksGithubIssuesAll`

Öffnet den GitHub Issues (all) Picker.

**Syntax:**
```vim
:SnacksGithubIssuesAll
```

**Beschreibung:**
Zeigt alle GitHub Issues (offen UND geschlossen).

**Verwendung:**
- Durchsuche alle Issues inklusive geschlossener
- Historische Issue-Recherche

**Voraussetzung:**
- `gh` CLI muss installiert und authentifiziert sein

**Äquivalent zu:**
```lua
require("snacks").picker.gh_issue({ state = "all" })
```

---

#### `:SnacksGithubPRs`

Öffnet den GitHub Pull Requests (open) Picker.

**Syntax:**
```vim
:SnacksGithubPRs
```

**Beschreibung:**
Zeigt offene Pull Requests für das aktuelle Repository.

**Verwendung:**
- Browse offene PRs
- Checkout PR-Branches
- Review PR-Informationen

**Voraussetzung:**
- `gh` CLI muss installiert und authentifiziert sein

**Äquivalent zu:**
```lua
require("snacks").picker.gh_pr()
```

---

#### `:SnacksGithubPRsAll`

Öffnet den GitHub Pull Requests (all) Picker.

**Syntax:**
```vim
:SnacksGithubPRsAll
```

**Beschreibung:**
Zeigt alle Pull Requests (offen, geschlossen, merged).

**Verwendung:**
- Historische PR-Recherche
- Vergleiche merged PRs

**Voraussetzung:**
- `gh` CLI muss installiert und authentifiziert sein

**Äquivalent zu:**
```lua
require("snacks").picker.gh_pr({ state = "all" })
```

---

### Grep Commands

#### `:SnacksGrep`

Öffnet den Grep Picker.

**Syntax:**
```vim
:SnacksGrep
```

**Beschreibung:**
Live Grep durch alle Dateien im Projekt (verwendet `rg` oder `grep`).

**Verwendung:**
- Suche nach Text in allen Dateien
- Live-Updates während du tippst
- Regex-Support

**Äquivalent zu:**
```lua
require("snacks").picker.grep()
```

---

#### `:SnacksGrepLines`

Öffnet den Buffer Lines Picker.

**Syntax:**
```vim
:SnacksGrepLines
```

**Beschreibung:**
Fuzzy-Finder für Zeilen im aktuellen Buffer.

**Verwendung:**
- Schnelle Navigation innerhalb einer Datei
- Suche nach Funktionen, Klassen, etc.
- Alternative zu `/` Search

**Äquivalent zu:**
```lua
require("snacks").picker.lines()
```

---

#### `:SnacksGrepBuffers`

Öffnet den Grep Open Buffers Picker.

**Syntax:**
```vim
:SnacksGrepBuffers
```

**Beschreibung:**
Grep durch alle offenen Buffer (nicht alle Dateien).

**Verwendung:**
- Suche nur in geöffneten Dateien
- Schneller als Project-Grep
- Perfekt für Multi-File-Editing

**Äquivalent zu:**
```lua
require("snacks").picker.grep_buffers()
```

---

#### `:SnacksGrepWord`

Öffnet den Grep Word/Selection Picker.

**Syntax:**
```vim
:SnacksGrepWord
```

**Beschreibung:**
Grep nach dem Wort unter dem Cursor (Normal Mode) oder der Selection (Visual Mode).

**Verwendung:**
- Schnelles Finden aller Vorkommen eines Wortes
- Refactoring-Helper
- Code-Navigation

**Äquivalent zu:**
```lua
require("snacks").picker.grep_word()
```

---

### Search Commands

#### `:SnacksSearchRegisters`

Öffnet den Registers Picker.

**Syntax:**
```vim
:SnacksSearchRegisters
```

**Beschreibung:**
Zeigt alle Vim-Register mit Preview.

**Verwendung:**
- Durchsuche Register-Inhalte
- Paste aus Registern
- Inspect Macro-Register

**Äquivalent zu:**
```lua
require("snacks").picker.registers()
```

---

#### `:SnacksSearchHistory`

Öffnet den Search History Picker.

**Syntax:**
```vim
:SnacksSearchHistory
```

**Beschreibung:**
Zeigt die Historie von `/` und `?` Suchen.

**Verwendung:**
- Wiederhole frühere Suchen
- Durchsuche Search-Pattern-Historie

**Äquivalent zu:**
```lua
require("snacks").picker.search_history()
```

---

#### `:SnacksSearchAutocmds`

Öffnet den Autocmds Picker.

**Syntax:**
```vim
:SnacksSearchAutocmds
```

**Beschreibung:**
Zeigt alle definierten Autocommands.

**Verwendung:**
- Debugging von Autocommands
- Inspect Event-Listener
- Find conflicting Autocmds

**Äquivalent zu:**
```lua
require("snacks").picker.autocmds()
```

---

#### `:SnacksSearchCommands`

Öffnet den Commands Picker.

**Syntax:**
```vim
:SnacksSearchCommands
```

**Beschreibung:**
Zeigt alle verfügbaren User-Commands.

**Verwendung:**
- Entdecke verfügbare Commands
- Fuzzy-Suche nach Commands
- Execute Commands interaktiv

**Äquivalent zu:**
```lua
require("snacks").picker.commands()
```

---

#### `:SnacksSearchCommandHistory`

Öffnet den Command History Picker.

**Syntax:**
```vim
:SnacksSearchCommandHistory
```

**Beschreibung:**
Zeigt die Historie aller ausgeführten `:` Commands.

**Verwendung:**
- Wiederhole Commands
- Kopiere Commands für Mappings
- Debugging

**Äquivalent zu:**
```lua
require("snacks").picker.command_history()
```

---

#### `:SnacksSearchDiagnostics`

Öffnet den Diagnostics Picker.

**Syntax:**
```vim
:SnacksSearchDiagnostics
```

**Beschreibung:**
Zeigt alle LSP Diagnostics (Errors, Warnings, Hints) im gesamten Workspace.

**Verwendung:**
- Überblick über alle Probleme
- Navigate zu Errors/Warnings
- Filter nach Severity

**Äquivalent zu:**
```lua
require("snacks").picker.diagnostics()
```

---

#### `:SnacksSearchDiagnosticsBuffer`

Öffnet den Buffer Diagnostics Picker.

**Syntax:**
```vim
:SnacksSearchDiagnosticsBuffer
```

**Beschreibung:**
Zeigt Diagnostics nur für den aktuellen Buffer.

**Verwendung:**
- Quick-Fix für aktuelles File
- Navigate durch Errors im Buffer

**Äquivalent zu:**
```lua
require("snacks").picker.diagnostics_buffer()
```

---

#### `:SnacksSearchHelp`

Öffnet den Help Pages Picker.

**Syntax:**
```vim
:SnacksSearchHelp
```

**Beschreibung:**
Durchsuche die Vim/Neovim Hilfe-Seiten.

**Verwendung:**
- Fuzzy-Finder für `:help`
- Schneller als `:help <topic>`
- Tag-Completion

**Äquivalent zu:**
```lua
require("snacks").picker.help()
```

---

#### `:SnacksSearchHighlights`

Öffnet den Highlights Picker.

**Syntax:**
```vim
:SnacksSearchHighlights
```

**Beschreibung:**
Zeigt alle definierten Highlight-Groups mit Live-Preview.

**Verwendung:**
- Theme-Development
- Inspect Colorscheme
- Debug Syntax-Highlighting

**Äquivalent zu:**
```lua
require("snacks").picker.highlights()
```

---

#### `:SnacksSearchIcons`

Öffnet den Icons Picker.

**Syntax:**
```vim
:SnacksSearchIcons
```

**Beschreibung:**
Durchsuche verfügbare Nerd Font Icons.

**Verwendung:**
- Finde Icons für Plugins/Configs
- Kopiere Icon-Unicode
- Preview Icons

**Äquivalent zu:**
```lua
require("snacks").picker.icons()
```

---

#### `:SnacksSearchJumps`

Öffnet den Jumps Picker.

**Syntax:**
```vim
:SnacksSearchJumps
```

**Beschreibung:**
Zeigt die Jumplist (`Ctrl-O` / `Ctrl-I` Historie).

**Verwendung:**
- Navigate durch Jump-Historie
- Jump zu früheren Positionen
- Inspect Jumplist

**Äquivalent zu:**
```lua
require("snacks").picker.jumps()
```

---

#### `:SnacksSearchKeymaps`

Öffnet den Keymaps Picker.

**Syntax:**
```vim
:SnacksSearchKeymaps
```

**Beschreibung:**
Durchsuche alle definierten Keymaps.

**Verwendung:**
- Finde Mapping für bestimmte Funktion
- Inspect Buffer-Local Mappings
- Detect Mapping-Konflikte

**Äquivalent zu:**
```lua
require("snacks").picker.keymaps()
```

---

#### `:SnacksSearchLoclist`

Öffnet den Location List Picker.

**Syntax:**
```vim
:SnacksSearchLoclist
```

**Beschreibung:**
Zeigt die Location List mit Preview.

**Verwendung:**
- Navigate durch Loclist-Entries
- Alternative zu `:lopen`

**Äquivalent zu:**
```lua
require("snacks").picker.loclist()
```

---

#### `:SnacksSearchMarks`

Öffnet den Marks Picker.

**Syntax:**
```vim
:SnacksSearchMarks
```

**Beschreibung:**
Zeigt alle gesetzten Marks (global und buffer-local).

**Verwendung:**
- Navigate zu Marks
- Inspect Mark-Positionen
- Delete Marks

**Äquivalent zu:**
```lua
require("snacks").picker.marks()
```

---

#### `:SnacksSearchMan`

Öffnet den Man Pages Picker.

**Syntax:**
```vim
:SnacksSearchMan
```

**Beschreibung:**
Durchsuche Man-Pages (Unix Manual).

**Verwendung:**
- Fuzzy-Finder für Man-Pages
- Quick-Reference
- Alternative zu `man -k`

**Äquivalent zu:**
```lua
require("snacks").picker.man()
```

---

#### `:SnacksSearchLazy`

Öffnet den Plugin Specs Picker.

**Syntax:**
```vim
:SnacksSearchLazy
```

**Beschreibung:**
Zeigt alle Lazy.nvim Plugin-Specs.

**Verwendung:**
- Browse installierte Plugins
- Inspect Plugin-Config
- Quick-Access zu Plugin-Files

**Äquivalent zu:**
```lua
require("snacks").picker.lazy()
```

---

#### `:SnacksSearchQflist`

Öffnet den Quickfix List Picker.

**Syntax:**
```vim
:SnacksSearchQflist
```

**Beschreibung:**
Zeigt die Quickfix List mit Preview und Navigation.

**Verwendung:**
- Navigate durch Quickfix-Entries
- Alternative zu `:copen`
- Fuzzy-Filter für QF-Entries

**Äquivalent zu:**
```lua
require("snacks").picker.qflist()
```

---

#### `:SnacksSearchResume`

Öffnet den letzten Picker erneut.

**Syntax:**
```vim
:SnacksSearchResume
```

**Beschreibung:**
Öffnet den zuletzt verwendeten Picker mit allen Filtern und State.

**Verwendung:**
- Schnelles Zurückkehren zu letztem Picker
- Spart Zeit bei wiederholten Suchen

**Äquivalent zu:**
```lua
require("snacks").picker.resume()
```

---

#### `:SnacksSearchUndo`

Öffnet den Undo History Picker.

**Syntax:**
```vim
:SnacksSearchUndo
```

**Beschreibung:**
Zeigt die Undo-Tree-Historie mit Diff-Preview.

**Verwendung:**
- Visual Undo-Tree
- Time-Travel durch Änderungen
- Preview einzelner Undo-States

**Äquivalent zu:**
```lua
require("snacks").picker.undo()
```

---

#### `:SnacksSearchColorschemes`

Öffnet den Colorschemes Picker.

**Syntax:**
```vim
:SnacksSearchColorschemes
```

**Beschreibung:**
Durchsuche und ändere Colorschemes mit Live-Preview.

**Verwendung:**
- Browse installierte Colorschemes
- Live-Preview beim Durchscrollen
- Schnelles Theme-Switching

**Äquivalent zu:**
```lua
require("snacks").picker.colorschemes()
```

---

### LSP Commands

#### `:SnacksLspDefinitions`

Öffnet den LSP Definitions Picker.

**Syntax:**
```vim
:SnacksLspDefinitions
```

**Beschreibung:**
Zeigt alle LSP Definitions für das Symbol unter dem Cursor.

**Verwendung:**
- Goto Definition
- Multiple Definitions (z.B. Interfaces)
- Preview Definition

**Voraussetzung:**
- LSP muss für Buffer aktiv sein

**Äquivalent zu:**
```lua
require("snacks").picker.lsp_definitions()
```

---

#### `:SnacksLspDeclarations`

Öffnet den LSP Declarations Picker.

**Syntax:**
```vim
:SnacksLspDeclarations
```

**Beschreibung:**
Zeigt LSP Declarations (z.B. Forward-Declarations in C/C++).

**Verwendung:**
- Navigate zu Declarations
- Unterscheidung Definition vs Declaration

**Voraussetzung:**
- LSP muss für Buffer aktiv sein

**Äquivalent zu:**
```lua
require("snacks").picker.lsp_declarations()
```

---

#### `:SnacksLspReferences`

Öffnet den LSP References Picker.

**Syntax:**
```vim
:SnacksLspReferences
```

**Beschreibung:**
Zeigt alle References (Verwendungen) des Symbols unter dem Cursor.

**Verwendung:**
- Find all usages
- Refactoring
- Code-Analyse

**Voraussetzung:**
- LSP muss für Buffer aktiv sein

**Äquivalent zu:**
```lua
require("snacks").picker.lsp_references()
```

---

#### `:SnacksLspImplementations`

Öffnet den LSP Implementations Picker.

**Syntax:**
```vim
:SnacksLspImplementations
```

**Beschreibung:**
Zeigt alle Implementations eines Interfaces/Abstracts.

**Verwendung:**
- Find Implementations
- Navigate zu konkreten Klassen
- Interface-Analyse

**Voraussetzung:**
- LSP muss für Buffer aktiv sein

**Äquivalent zu:**
```lua
require("snacks").picker.lsp_implementations()
```

---

#### `:SnacksLspTypeDefinitions`

Öffnet den LSP Type Definitions Picker.

**Syntax:**
```vim
:SnacksLspTypeDefinitions
```

**Beschreibung:**
Zeigt die Type-Definition des Symbols (z.B. Type-Alias, Interface-Definition).

**Verwendung:**
- Navigate zu Type-Definitions
- Inspect komplexe Types

**Voraussetzung:**
- LSP muss für Buffer aktiv sein

**Äquivalent zu:**
```lua
require("snacks").picker.lsp_type_definitions()
```

---

#### `:SnacksLspIncomingCalls`

Öffnet den LSP Incoming Calls Picker.

**Syntax:**
```vim
:SnacksLspIncomingCalls
```

**Beschreibung:**
Zeigt alle Funktionen, die die Funktion unter dem Cursor aufrufen (Call Hierarchy).

**Verwendung:**
- Find Callers
- Code-Flow-Analyse
- Impact-Analyse

**Voraussetzung:**
- LSP muss für Buffer aktiv sein
- LSP muss Call Hierarchy unterstützen

**Äquivalent zu:**
```lua
require("snacks").picker.lsp_incoming_calls()
```

---

#### `:SnacksLspOutgoingCalls`

Öffnet den LSP Outgoing Calls Picker.

**Syntax:**
```vim
:SnacksLspOutgoingCalls
```

**Beschreibung:**
Zeigt alle Funktionen, die von der Funktion unter dem Cursor aufgerufen werden.

**Verwendung:**
- Find Callees
- Code-Flow-Analyse
- Dependency-Analyse

**Voraussetzung:**
- LSP muss für Buffer aktiv sein
- LSP muss Call Hierarchy unterstützen

**Äquivalent zu:**
```lua
require("snacks").picker.lsp_outgoing_calls()
```

---

#### `:SnacksLspSymbols`

Öffnet den LSP Symbols Picker.

**Syntax:**
```vim
:SnacksLspSymbols
```

**Beschreibung:**
Zeigt alle Symbols (Funktionen, Klassen, etc.) im aktuellen Buffer.

**Verwendung:**
- Quick-Navigation innerhalb File
- Outline-View
- Alternative zu Tree-Sitter-Outline

**Voraussetzung:**
- LSP muss für Buffer aktiv sein

**Äquivalent zu:**
```lua
require("snacks").picker.lsp_symbols()
```

---

#### `:SnacksLspWorkspaceSymbols`

Öffnet den LSP Workspace Symbols Picker.

**Syntax:**
```vim
:SnacksLspWorkspaceSymbols
```

**Beschreibung:**
Durchsuche alle Symbols im gesamten Workspace (Projekt).

**Verwendung:**
- Project-wide Symbol-Suche
- Quick-Navigation zu Funktionen/Klassen
- Alternative zu Tags/Ctags

**Voraussetzung:**
- LSP muss für Buffer aktiv sein
- LSP muss Workspace Symbols unterstützen

**Äquivalent zu:**
```lua
require("snacks").picker.lsp_workspace_symbols()
```

---

## Konfiguration

### Grundlegende Konfiguration

```lua
require("config.snacks.usrcmds").setup({
  -- Alle Kategorien sind standardmäßig aktiviert
  -- Du kannst einzelne Kategorien deaktivieren:

  find = {
    enabled = true,
    -- Deaktiviere einzelne Commands innerhalb der Kategorie:
    projects = false, -- SnacksFindProjects wird nicht registriert
  },

  git = {
    enabled = true,
  },

  github = {
    enabled = false, -- Deaktiviere gesamte Kategorie
  },

  grep = {
    enabled = true,
  },

  search = {
    enabled = true,
    -- Granulare Kontrolle:
    colorschemes = false,
    undo = false,
  },

  lsp = {
    enabled = true,
  },

  misc = {
    enabled = true,
  },
})
```

### Erweiterte Konfiguration

```lua
require("config.snacks.usrcmds").setup({
  find = {
    enabled = true,
    buffers = true,
    files = true,
    git_files = true,
    config = true,
    recent = true,
    projects = true,
  },

  git = {
    enabled = true,
    branches = true,
    log = true,
    log_line = true,
    status = true,
    stash = true,
    diff = true,
    log_file = true,
  },

  github = {
    enabled = true,
    issues = true,
    issues_all = false, -- Deaktiviere "all" Variante
    prs = true,
    prs_all = false,
  },

  grep = {
    enabled = true,
    grep = true,
    lines = true,
    buffers = true,
    word = true,
  },

  search = {
    enabled = true,
    -- Aktiviere nur häufig genutzte Commands:
    registers = true,
    history = true,
    autocmds = false,
    commands = true,
    command_history = true,
    diagnostics = true,
    diagnostics_buffer = true,
    help = true,
    highlights = false,
    icons = false,
    jumps = true,
    keymaps = true,
    loclist = false,
    marks = true,
    man = false,
    lazy = true,
    qflist = true,
    resume = true,
    undo = true,
    colorschemes = true,
  },

  lsp = {
    enabled = true,
    definitions = true,
    declarations = true,
    references = true,
    implementations = true,
    type_definitions = true,
    incoming_calls = true,
    outgoing_calls = true,
    symbols = true,
    workspace_symbols = true,
  },

  misc = {
    enabled = true,
    explorer = true,
    notifications = true,
    command_history = true,
  },
})
```

### Minimale Konfiguration (nur oft genutzte Commands)

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
    log = false,
    log_line = false,
    status = true,
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
    command_history = true,
    help = true,
    keymaps = true,
    -- Alle anderen false
  },

  lsp = {
    enabled = true,
    definitions = true,
    references = true,
    implementations = false,
    -- Rest false
  },

  misc = {
    enabled = true,
    explorer = true,
    notifications = false,
    command_history = false,
  },
})
```

## Tipps & Best Practices

### 1. Nutze das Hauptcommand mit Autocompletion

```vim
:Snacks <Tab>           " Zeigt alle Kategorien
:Snacks find <Tab>      " Zeigt find-Subcategories
:Snacks git <Tab>       " Zeigt git-Subcategories
```

### 4. Lazy-Loading

Da das Modul `lib.usercmd` nutzt, kannst du es mit Lazy.nvim optimal lazy-loaden:

```lua
{
  dir = "~/.config/nvim/lua/usrcmds/snacks",
  name = "usrcmds-snacks",
  lazy = false, -- Oder event = "VeryLazy"
  dependencies = {
    "folke/snacks.nvim",
  },
  config = function()
    require("config.snacks.usrcmds").setup({
      -- deine Config
    })
  end,
}
```

### 5. Conditional Loading

Lade nur Commands wenn snacks.nvim verfügbar ist:

```lua
local has_snacks = pcall(require, "snacks")

if has_snacks then
  require("config.snacks.usrcmds").setup({
    -- Config
  })
end
```

## Troubleshooting

### Commands werden nicht gefunden

**Problem:** `:Snacks` oder `:SnacksFindFiles` nicht verfügbar.

**Lösung:**
1. Prüfe ob `setup()` aufgerufen wurde: `:lua print(vim.inspect(require("config.snacks.usrcmds")))`
2. Prüfe ob Kategorie aktiviert ist in deiner Config
3. Restart Neovim

### snacks.nvim nicht verfügbar

**Problem:** Error "snacks.nvim not available"

**Lösung:**
1. Prüfe ob snacks.nvim installiert ist: `:Lazy`
2. Prüfe ob snacks.nvim geladen ist: `:lua print(require("snacks"))`
3. Stelle sicher dass snacks.nvim vor config.snacks.usrcmds geladen wird

### Picker öffnet nicht

**Problem:** Command führt nichts aus.

**Lösung:**
1. Prüfe ob snacks.picker enabled ist: `:lua print(require("snacks").picker)`
2. Check snacks.nvim Config: `opts.picker = { enabled = true }`
3. Check Logs: `:messages`

### LSP Commands funktionieren nicht

**Problem:** `:SnacksLspDefinitions` zeigt nichts.

**Lösung:**
1. Prüfe ob LSP aktiv: `:LspInfo`
2. Stelle sicher dass LSP attached ist zum Buffer
3. Manche LSP-Server unterstützen nicht alle Features

### GitHub Commands schlagen fehl

**Problem:** GitHub-Commands zeigen Error.

**Lösung:**
1. Installiere `gh` CLI: `brew install gh` / `apt install gh`
2. Authentifiziere: `gh auth login`
3. Prüfe ob Repository GitHub-Remote hat: `git remote -v`

## Siehe auch

- [snacks.nvim GitHub Repository](https://github.com/folke/snacks.nvim)
- [snacks.nvim Dokumentation](https://github.com/folke/snacks.nvim/tree/main/docs)
- [Neovim UserCommand API](https://neovim.io/doc/user/api.html#nvim_create_user_command())

