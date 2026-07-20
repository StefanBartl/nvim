# Implementierungsplan: NVIM Custom Modules Refactoring

## Table of content

  - [Kontext](#kontext)
  - [Globale Konventionen (für alle Tasks)](#globale-konventionen-fr-alle-tasks)
  - [Task A — `usrcmds/reload` → `debugging.nvim`](#task-a-usrcmdsreload-debuggingnvim)
    - [Zieldateien im Plugin](#zieldateien-im-plugin)
    - [Implementierung](#implementierung)
    - [nvim-Config](#nvim-config)
  - [Task B — `usrcmds/compress_dir` → `insights.nvim`](#task-b-usrcmdscompress_dir-insightsnvim)
    - [Zieldateien im Plugin](#zieldateien-im-plugin-1)
    - [Implementierung](#implementierung-1)
    - [nvim-Config](#nvim-config-1)
  - [Task C — `custom.open` → Neues Plugin `open.nvim`](#task-c-customopen-neues-plugin-opennvim)
    - [Neue Repo-Struktur (`E:\repos\open.nvim`)](#neue-repo-struktur-ereposopennvim)
    - [Implementierung](#implementierung-2)
    - [nvim-Config](#nvim-config-2)
  - [Task D — `custom.format` (non-markdown) → `buffer-ctx.nvim`](#task-d-customformat-non-markdown-buffer-ctxnvim)
    - [Zieldateien im Plugin](#zieldateien-im-plugin-2)
    - [Implementierung](#implementierung-3)
    - [nvim-Config](#nvim-config-3)
  - [Task E — `custom.format.markdown` → `markdown.nvim`](#task-e-customformatmarkdown-markdownnvim)
    - [Situation](#situation)
    - [Vorgehen](#vorgehen)
    - [Zieldateien im Plugin](#zieldateien-im-plugin-3)
  - [Task F — `custom.line_marker` → `wkdoptions/ui`](#task-f-customline_marker-wkdoptionsui)
    - [Implementierung](#implementierung-4)
  - [Task G — `custom.mynotes` → `pickers.nvim` Collections-System](#task-g-custommynotes-pickersnvim-collections-system)
    - [Neue Config-Struktur](#neue-config-struktur)
    - [Collection-Typen (via `prefix`-Feld)](#collection-typen-via-prefix-feld)
    - [Zieldateien im Plugin](#zieldateien-im-plugin-4)
    - [`collection.lua` Kern-API](#collectionlua-kern-api)
    - [Command-Registrierung](#command-registrierung)
    - [nvim-Config](#nvim-config-4)
  - [Reihenfolge der Implementation](#reihenfolge-der-implementation)
  - [Verifikation (pro Task)](#verifikation-pro-task)

---

## Kontext

Mehrere eigenständige Module in der nvim-Config (`lua/custom/`, `lua/usrcmds/`) sollen in bestehende oder neue Plugins ausgelagert werden. Ziel ist es, die Config-Seite schlank zu halten und die Logik dort zu bündeln, wo sie thematisch hingehört. Jedes Ziel-Plugin bekommt danach `:checkhealth`, vollständige Doku und, wo sinnvoll, neue Features.

---

## Globale Konventionen (für alle Tasks)

- **Docs-Struktur**: `README.md` (ASCII-Art + Badges + ToC Level-2), `doc/{plugin-name-ohne-.nvim}.txt`, `docs/ROADMAP.md`
- **Kein Co-Author** in Commit-Messages
- **`:checkhealth`** in jedem Plugin aktuell halten
- **Require-Pfade** in der nvim-Config nach jeder Migration anpassen und alten Code löschen
- **Leitlinien**: Arch&Coding-Regeln.md / Checklist.md / Zentrale-Prinzipien.md

---

## Task A — `usrcmds/reload` → `debugging.nvim`

### Zieldateien im Plugin
- NEU: `lua/debugging/usercmds/module_reload.lua`
- MOD: `lua/debugging/commands.lua` (neuer Eintrag in `build_registry()`)
- MOD: `lua/debugging/config/DEFAULTS.lua` (neues Feature-Flag)
- MOD: `lua/debugging/health.lua` (Checks für neue Kategorie)
- MOD: `lua/debugging/@types/init.lua` (optionales Typ-Update)

### Implementierung

**`module_reload.lua`** übernimmt direkt die zwei Hilfsfunktionen aus dem original Modul:
- `path_to_module(filepath)` — Dateipfad → Lua-Modulname
- `reload_module(module_name)` — `package.loaded` + `vim.loader` leeren + `pcall(require)`

Öffentlich: `M.reload_current()` (heutiger `reload_current_module`-Body).

**`commands.lua`** bekommt einen neuen Registry-Eintrag:
```lua
module = {
  feature = "module_reload",
  actions = { "reload" },
  run = {
    reload = function() require("debugging.usercmds.module_reload").reload_current() end,
  },
},
```
Befehl: `:Debug module reload`

**`DEFAULTS.lua`**: `features.module_reload = true`

### nvim-Config
`lua/usrcmds/reload/` löschen. In `lua/usrcmds/init.lua` den require-Call entfernen oder durch Hinweis auf `:Debug module reload` ersetzen.

---

## Task B — `usrcmds/compress_dir` → `insights.nvim`

### Zieldateien im Plugin
- NEU: `lua/insights/archive/init.lua`
- MOD: `lua/insights/usercommands.lua` (neuer Eintrag in SUBCOMMANDS + Handler)
- MOD: `lua/insights/config.lua` (Archive-Config-Block)
- MOD: `lua/insights/health.lua`

### Implementierung

**Cross-Platform-Strategie** (wichtig — insights wirbt mit Windows-Support):
- Unix/macOS: `find` + `tar --exclude=.git -czf` (bestehende Logik)
- Windows/WSL: PowerShell `Compress-Archive -Path . -DestinationPath archive.zip -Force` (neuer Fallback)
- Erkennung via `vim.fn.has("win32")` oder `vim.uv.os_uname().sysname`

**`archive/init.lua`**:
- `M.compress(on_complete)` — öffentliche Funktion mit Callback
- Interne `_run_async(cmd_array, on_exit)` — nutzt `vim.system()` ≥0.10 / `uv.spawn` Fallback (identisch zu heute)
- `M.compress_unix()` + `M.compress_windows()` — plattformspezifische Kommandos

**Config-Block** (in `config.lua`):
```lua
archive = {
  enable   = true,
  outdir   = vim.fn.expand("~/temp"),  -- Zielverzeichnis
},
```

**usercommands.lua**: `:Insights archive` → ruft `archive.compress()` auf.

### nvim-Config
`lua/usrcmds/compress_dir/` löschen, require entfernen.

---

## Task C — `custom.open` → Neues Plugin `open.nvim`

### Neue Repo-Struktur (`E:\repos\open.nvim`)
```
plugin/open.lua           -- Load-Guard (vim.g.loaded_open_nvim)
lua/open_nvim/
  init.lua                -- setup() + M.open(target?, scope?)
  registry.lua            -- Handler-Registry (Pfade angepasst)
  context.lua             -- Signals + Context-Resolving
  platform.lua            -- Platform-Detection
  util.lua                -- run_detached, url_encode, find_exec
  @types/init.lua
  handlers/
    filemanager.lua
    browser.lua
    notepad.lua
    nvim_internal.lua
  config.lua              -- NEU: setup-Optionen + Defaults
  health.lua              -- NEU: :checkhealth open_nvim
doc/open.txt
docs/ROADMAP.md
README.md
CHEATSHEET.md
```

### Implementierung

**Renames**: alle `require("custom.open.*")` → `require("open_nvim.*")`

**`config.lua`** (neu): Default-Handler + optionale Handler-Whitelist
```lua
{
  default_filemanager = "filemanager",
  default_browser     = "browser",
  handlers            = { "filemanager", "browser", "notepad", "nvim_internal" },
  command             = "Open",
}
```

**`setup(opts)`** in `init.lua`: merged config, registriert Handler-Module, legt `:Open` an — genau wie heute `M.setup()`, nur über `config.lua` gesteuert.

**`health.lua`**: prüft Neovim-Version, Platform-Executables (explorer.exe / xdg-open / open), ob lib.nvim vorhanden.

**`CHEATSHEET.md`**: Tabelle aller Handler mit Beispielbefehlen.

### nvim-Config
`lua/custom/open/` löschen. lazy.nvim-Spec auf `dir = vim.env.REPOS_DIR .. "/open.nvim"` zeigen.

---

## Task D — `custom.format` (non-markdown) → `buffer-ctx.nvim`

### Zieldateien im Plugin
- NEU: `lua/buffer_ctx/format/` (komplettes Verzeichnis)
- NEU: `lua/buffer_ctx/format/init.lua` — `:Format`-Command-Registrierung + Subcommand-Registry
- NEU: `lua/buffer_ctx/format/column_align.lua`
- NEU: `lua/buffer_ctx/format/table_fmt.lua`
- NEU: `lua/buffer_ctx/format/text_width.lua`
- NEU: `lua/buffer_ctx/format/filter_lines.lua`
- NEU: `lua/buffer_ctx/format/enum_lines.lua`
- NEU: `lua/buffer_ctx/format/misc.lua` (trim, sort, unique, case, indent, clear)
- MOD: `lua/buffer_ctx/init.lua` (setup ruft `format/init.lua` auf)
- MOD: `lua/buffer_ctx/health.lua`
- MOD: `lua/buffer_ctx/config.lua` (Format-Config-Block: `format = { enable = true }`)
- MOD: `README.md` + `doc/buffer-ctx.txt`

### Implementierung

Die Subcommand-Registry-Logik (register/dispatch/complete) aus `custom.format.init` wird **1:1 nach `format/init.lua` portiert** — sie ist bereits sauber abstrahiert. Die Leaf-Module (column_align.core, enum_lines.core usw.) werden ebenfalls portiert.

**`buffer_ctx.init` setup()** bekommt einen optionalen Block:
```lua
format = { enable = true }
```
Wenn `enable`, wird `require("buffer_ctx.format").setup(register_fn)` gerufen und `:Format` registriert.

**Kein Paradigmenbruch** im Plugin: `:Insert`/`:Copy` bleiben unberührt. `:Format` ist ein eigenständiger Command-Baum in `format/init.lua`.

### nvim-Config
`lua/custom/format/` löschen (außer markdown-Submodul, das separat behandelt wird). require in init ersetzen.

---

## Task E — `custom.format.markdown` → `markdown.nvim`

### Situation
`custom.format.markdown.headlines.separators` implementiert `apply_headl_separators()`. `markdown.nvim` hat bereits ein `headline_spacing`-Feature.

### Vorgehen
1. Lesen von `markdown.nvim/lua/markdown_nvim/…` um zu prüfen, ob `headline_spacing` dieselbe Logik hat.
2. **Fall A (identisch)**: `custom.format.markdown` löschen, kein neuer Code nötig. `:Format markdown headline_separators` wird gestrichen oder zeigt auf `markdown_nvim`-API.
3. **Fall B (unterschiedlich)**: Logik aus `custom.format.markdown.headlines.separators` nach `lua/markdown_nvim/headline_spacing/` mergen. Öffentliche Funktion `require("markdown_nvim").apply_headline_separators(bufnr)` exportieren.

In jedem Fall: `custom.format.markdown/` danach löschen.

### Zieldateien im Plugin
- ggf. MOD: `lua/markdown_nvim/headline_spacing/init.lua`
- MOD: `lua/markdown_nvim/init.lua` (public API-Export)
- MOD: `lua/markdown_nvim/health.lua`

---

## Task F — `custom.line_marker` → `wkdoptions/ui`

### Implementierung
Einfachstes Task.

1. `lua/custom/line_marker/init.lua` → `lua/wkdoptions/ui/line_marker/init.lua` (Inhalt unverändert)
2. Alle require-Stellen in der Config von `custom.line_marker` auf `wkdoptions.ui.line_marker` umstellen
3. `lua/custom/line_marker/` löschen

Kein Plugin-Wechsel, nur internes Verschieben innerhalb der nvim-Config.

---

## Task G — `custom.mynotes` → `pickers.nvim` Collections-System

Das größte Task. Kernidee: `repos` und `wkdbooks` sind bereits "benannte Verzeichnis-Collections" — das wird zum generischen System.

### Neue Config-Struktur

`wkdbooks_dir`, `wkdbooks_dir` und `wkdbook_prefix` fallen weg (**breaking change**). Alles wandert in `collections`. Die bisherige WkdBooks-Konfiguration wird zu einem normalen Collection-Eintrag mit `prefix`.

```lua
require("pickers").setup({
  repos_dir = vim.env.REPOS_DIR,  -- bleibt als Basis-Pfad-Variable

  -- Alle Scopes jetzt als Collections (inkl. ehemaliges wkdbooks)
  collections = {
    -- Feste Verzeichnisse (ehemals mynotes specs)
    { name = "notes",      dir = vim.env.REPOS_DIR .. "/Notes",
      keys = { files = "<leader>mnf", grep = "<leader>mng" } },
    { name = "notes_lua",  dir = vim.env.REPOS_DIR .. "/Notes/Lua",
      keys = { files = "<leader>mlf", grep = "<leader>mlg" } },
    { name = "checklists", dir = vim.env.REPOS_DIR .. "/Checklists" },

    -- Prefix-Collections (ehemals wkdbooks, jetzt generisch konfigurierbar)
    { name = "wkdbooks",   dir = vim.env.REPOS_DIR .. "/WKDBooks",
      prefix = "wkdbook-",
      keys = { files = "<leader>wkf", grep = "<leader>wkg" } },

    -- Beispiel: eigene Prefix-Collection für andere Nutzer des Plugins
    -- { name = "projects", dir = "/home/user/projects", prefix = "proj-" },
  },
})
```

### Collection-Typen (via `prefix`-Feld)

| prefix-Wert | Verhalten |
|---|---|
| nicht gesetzt / nil | `dir` direkt als Root verwenden |
| `""` (leer) | alle unmittelbaren Unterordner von `dir` auflisten |
| `"xyz-"` | nur Unterordner mit diesem Präfix auflisten |

Damit wird das `wkdbooks`-Feature zu einer Built-in Collection mit `prefix = wkdbook_prefix`.

### Zieldateien im Plugin

- NEU: `lua/pickers/sources/collection.lua` — generischer Collection-Source
- MOD: `lua/pickers/sources/wkdbooks.lua` → dünner Wrapper um `collection.lua`
- MOD: `lua/pickers/sources/repos.lua` → dünner Wrapper um `collection.lua` (prefix = "")
- MOD: `lua/pickers/config/defaults.lua` — `collections = {}` hinzufügen
- MOD: `lua/pickers/config/init.lua` — Collections validieren + normalisieren
- MOD: `lua/pickers/command/init.lua` — Collections als Scopes registrieren
- MOD: `lua/pickers/bindings.lua` — per-Collection Keymaps registrieren
- MOD: `lua/pickers/health.lua` — Collections prüfen (dir existiert?)
- MOD: `lua/pickers/@types/init.lua` — `Pickers.Collection` Typ
- NEU: `CHEATSHEET.md` — alle registrierten Scopes + Compat-Commands (inkl. user collections)
- MOD/NEU: `README.md` auf Deutsch mit Abschnitt "Built-in vs. User Collections"
- MOD: `docs/ROADMAP.md`

### `collection.lua` Kern-API

```lua
-- Gibt Source zurück: entweder direkt (kein prefix) oder via Sub-Picker (mit prefix)
M.get(collection_spec, cfg, callback, engine_mod)
```

Interne Logik aus `wkdbooks.lua` (`list_wkdbooks`) generalisiert zu:
```lua
local function list_subdirs(dir, prefix)  -- prefix="" → alle, "xyz-" → gefiltert
```

### Command-Registrierung

Für jede Collection in `cfg.collections`:
- Scope `:Pickers {name} files` und `:Pickers {name} grep` registrieren
- Compat-Commands auto-generieren: `{PascalName}Files`, `{PascalName}Grep`
  - z.B. `notes` → `NotesFiles`, `NotesGrep`
  - z.B. `notes_lua` → `NotesLuaFiles`, `NotesLuaGreep`
- Keymaps aus `keys`-Feld registrieren (wenn gesetzt)

**Scope-Picker** (`ui/scope_picker.lua`): Collections erscheinen neben den Built-in Scopes.

### nvim-Config

`lua/custom/mynotes/` vollständig löschen. Die Specs werden zu Collection-Einträgen in der lazy.nvim-Spec von pickers.nvim.

---

## Reihenfolge der Implementation

Tasks sind weitgehend unabhängig. Empfohlene Reihenfolge:

1. **F** (line_marker) — trivial, sofort erledigt, kein Plugin-Risiko
2. **A** (debugging.nvim) — kleines, isoliertes Modul
3. **E** (markdown.nvim) — Merge-Check zuerst, dann entscheiden
4. **B** (insights.nvim) — cross-platform Arbeit
5. **D** (buffer-ctx.nvim) — größere Portierung
6. **G** (pickers.nvim) — größtes Refactoring
7. **C** (xopen.nvim) — neues Plugin, braucht Docs

---

## Verifikation (pro Task)

- **A**: `:Debug module reload` auf einer Lua-Datei → Modul wird neu geladen; `:checkhealth debugging` grün
- **B**: `:Insights archive` → Archiv in `~/temp/`; auf Windows mit PowerShell; `:checkhealth insights` grün
- **C**: `:Open` auf URL → Browser öffnet; auf Datei → Explorer/Finder; `:checkhealth open_nvim` grün
- **D**: `:Format trim`, `:Format sort`, `:Format column 40` auf Testbuffer; `:checkhealth buffer_ctx` grün
- **E**: `:Format markdown headline_separators` (falls API-Redirect) oder komplett gestrichen; markdown.nvim-Test
- **F**: require-Pfad in Config testen, `MarkLineToggle` + `MarkLinesYank` funktionieren
- **G**: `:Pickers notes files` → Picker öffnet; `NotesFiles` als Compat-Command; prefix-Collection listet Unterordner; `:checkhealth pickers` grün; alle alten `:Nvim*Files`-Commands funktionieren als Compat-Aliases
