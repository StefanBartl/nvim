# repo_pickers README

## Usage

```vim
:RepoFiles               -> Repo wählen -> Files (per engine)
:RepoGrep                -> Repo wählen -> live_grep (per engine)
:RepoFilesFzf            -> Repo wählen -> fzf-lua files
:RepoGrepFzf             -> Repo wählen -> fzf-lua live_grep
:RepoFilesTelescope      -> Repo wählen -> Telescope files
:RepoGrepTelescope       -> Repo wählen -> Telescope live_grep
```
---# repo_pickers

Zweck

* Zentrale, sichere Auswahl eines Repositories unterhalb eines Basisordners und anschließendes Öffnen eines File-Pickers oder Live-Grep.
* Nutzbar mit Telescope, fzf-lua oder reinem `vim.ui.select` (Fallback), ohne Logikduplikate.

Funktionsweise (Überblick)

* Scannt die direkten Unterordner von `repos_dir` (standardmäßig aus `$REPOS_DIR`).
* Optional nur Git-Repos (`.git` vorhanden), inklusive Worktrees (`.git` als Datei).
* Auswahl-UI je nach Konfiguration: `telescope`, `fzf`, `vim_select` oder `auto` (bevorzugt Telescope → fzf-lua → Fallback).
* Führt danach bestehende User-Commands für Files/Grep aus (z. B. `RepoFilesFzf`, `RepoGrepTelescope`), sodass bestehende Picker-Setups weiterverwendet werden.

Verzeichnisstruktur

```
lua/custom/repo_pickers/
  types.lua
  config.lua
  fs.lua
  dispatch.lua
  actions.lua
  register.lua
  init.lua
  select/
    vim_select.lua
    telescope.lua
    fzf.lua
```

Abhängigkeiten

* Pflicht: Neovim ≥ 0.9 (empfohlen ≥ 0.10 wegen `vim.fs.normalize`), LibUV vorhanden.
* Optional: `nvim-telescope/telescope.nvim` für Telescope-Picker.
* Optional: `ibhagwan/fzf-lua` für fzf-Picker.
* Ohne diese Plugins erfolgt die Auswahl per `vim.ui.select`.

Installation / Einbindung

* Die Dateien unter `lua/custom/repo_pickers/…` in das eigene Neovim-Setup übernehmen.
* In der Init-Konfiguration aktivieren:

```lua
-- English comments per requirement:
-- Minimal enable with defaults; will use $REPOS_DIR as base if set.
require("custom.repo_pickers").enable({
  -- repos_dir = "/absolute/path/to/your/repos", -- optional; else $REPOS_DIR
  only_git = true,        -- list only folders containing .git
  selector = "auto",      -- "telescope" | "fzf" | "vim_select" | "auto"
  engine   = "auto",      -- "telescope" | "fzf" | "auto"
  show_relative = true,   -- labels shown relative to repos_dir or basename
  usercmd_names = {       -- map to existing usr_pickers commands if they differ
    find_files_telescope = "RepoFilesTelescope",
    grep_telescope       = "RepoGrepTelescope",
    find_files_fzf       = "RepoFilesFzf",
    grep_fzf             = "RepoGrepFzf",
  },
  keymaps_lhs = {
    repo_files = "<leader>rf",
    repo_grep  = "<leader>rg",
  },
}, { usercmds = true, keymaps = true })
```

Konfiguration

* `repos_dir`: Absoluter Pfad zum Wurzelordner mit Repositories; ansonsten wird `$REPOS_DIR` verwendet.
* `only_git`: Wenn wahr, werden nur Ordner mit `.git` berücksichtigt (inklusive Worktree-Dateien).
* `selector`: UI für die Repositories-Auswahl (`auto`|`telescope`|`fzf`|`vim_select`).
* `engine`: Engine für nachgelagerte Aktion Files/Grep (`auto`|`telescope`|`fzf`).
* `show_relative`: Labels als `repos_dir`-relativ statt voller Pfad.
* `usercmd_names`: Zuordnung auf bereits vorhandene User-Commands im System.
* `keymaps_lhs`: Optionale Tastenkürzel für Direkteinstiege.

Beispiel: Umgebungsvariable setzen

```
# Linux/macOS (bash/zsh)
export REPOS_DIR="$HOME/repos"

# Windows PowerShell (nur wenn nötig)
setx REPOS_DIR "C:\Users\Name\repos"
```

Befehle

* `:RepoFiles` → Repo auswählen, anschließend Files-Picker gemäß `engine`.
* `:RepoGrep` → Repo auswählen, anschließend Live-Grep gemäß `engine`.
* `:RepoFilesFzf` / `:RepoGrepFzf` → wie oben, Engine fest auf fzf-lua.
* `:RepoFilesTelescope` / `:RepoGrepTelescope` → wie oben, Engine fest auf Telescope.

Keymaps

* Werden nur gesetzt, wenn `keymaps_lhs.repo_files` bzw. `keymaps_lhs.repo_grep` nicht leer sind.
* Standardbeispiel siehe Einbindung (`<leader>rf`, `<leader>rg`).

Integrationsbeispiele

Telescope als bevorzugte Auswahl- und Aktions-Engine

```lua
-- Force Telescope for both selecting the repo and running the file/grep action.
require("custom.repo_pickers").enable({
  selector = "telescope",
  engine   = "telescope",
  keymaps_lhs = { repo_files = "<leader>tf", repo_grep = "<leader>tg" },
}, { usercmds = true, keymaps = true })
```

fzf-lua als bevorzugte Auswahl- und Aktions-Engine

```lua
-- Force fzf-lua for both selecting the repo and running the file/grep action.
require("custom.repo_pickers").enable({
  selector = "fzf",
  engine   = "fzf",
  keymaps_lhs = { repo_files = "<leader>ff", repo_grep = "<leader>fg" },
}, { usercmds = true, keymaps = true })
```

Fallback ohne Plugins (nur `vim.ui.select`)

```lua
-- Works even without Telescope/fzf-lua installed; selection via vim.ui.select.
require("custom.repo_pickers").enable({
  selector = "vim_select",
  engine   = "auto", -- resolves to whichever user command names are mapped
}, { usercmds = true })
```

Technische Details

Auswahl-Adapter

* `select/vim_select.lua`: Nutzung von `vim.ui.select`.
* `select/telescope.lua`: Nutzung von Telescope-Picker (falls vorhanden), sonst Rückgabe `false`.
* `select/fzf.lua`: Nutzung von fzf-lua (falls vorhanden), sonst Rückgabe `false`.
* Dispatcher wählt je `selector` und fällt bei Bedarf auf `vim.ui.select` zurück.

Filesystem-Scan

* `fs.scan_repos(root, only_git)`: Liest direkte Unterordner, filtert optional `.git`, sortiert stabil nach Ordnernamen.
* Pfadoperationen sind portabel (`normalize`, `join`), inkl. Windows-Trennzeichen und Worktrees.

Sicherheit und Performance

* Defensive Guards für externe Abhängigkeiten (`pcall(require)`), keine stillen Fehler; UI-`notify` nur an klaren Boundaries.
* Kein Shell-Spawn für das Scannen; ausschließlich LibUV (`uv.fs_scandir`) zur Minimierung von Overhead.
* Vorallokation bekannter Listenlängen (`{ [#repos] = "" }`) für UI-Labels, um Reallokationen zu vermeiden.
* Argumente werden vor `:Cmd {arg}` über `vim.fn.fnameescape()` sicher gequotet.
* Reiner Kern (FS/Dispatch/Actions) ohne globale Seiteneffekte; kleine, testbare Module (Single-Responsibility).

Kompatibilität

* Linux/macOS nativ.
* Windows: Pfadtrennzeichen werden gewahrt, Argumente werden korrekt escaped; UNC-Pfade und Laufwerkswurzeln sind möglich.

Troubleshooting

* Keine Repositories gelistet:

  * `repos_dir` korrekt gesetzt? Existiert der Pfad? Ggf. `$REPOS_DIR` exportieren oder in der Konfiguration setzen.
  * `only_git = true`: Enthalten die Unterordner wirklich `.git`? Bei Worktrees liegt `.git` oft als Datei vor, wird aber unterstützt.
* Auswahl-Picker öffnet sich nicht:

  * Bei `selector = "telescope"` oder `"fzf"` prüfen, ob das jeweilige Plugin installiert und geladen ist. Andernfalls auf `"auto"` oder `"vim_select"` stellen.
* Picker-Befehle nicht gefunden:

  * `usercmd_names` an die im Setup vorhandenen User-Commands anpassen (z. B. andere Namen in der eigenen `usr_pickers`-Schicht).
* Windows-Pfade mit Leerzeichen:

  * `fnameescape` wird verwendet; falls Custom-User-Commands Pfade selbst parsen, dort ebenfalls robust escapen.

Erweiterungen

* Optionales Caching der Repo-Liste (Zeit-/Event-basiert) für sehr große `repos_dir`.
* Filter-Eingabe vor der Auswahl (einfaches `vim.fn.input("filter: ")`), um die Liste vorzufiltern.
* Weitere Engines/Picker als Adapter ergänzen (z. B. Mini.Pick).

API-Kurzreferenz

Lua-Aufruf

```lua
-- Enable with custom options; both user commands and keymaps may be toggled.
require("custom.repo_pickers").enable(user_cfg, { usercmds = true, keymaps = true })

-- Internal tiny entry points used by keymaps (not for public config):
-- :lua require("custom.repo_pickers")._entry_files()
-- :lua require("custom.repo_pickers")._entry_grep()
```

Konfigurationsschema

```
repos_dir        string|nil     Basisordner; sonst $REPOS_DIR
only_git         boolean        nur .git-Repos (Default: true)
selector         enum           auto|telescope|fzf|vim_select (Default: auto)
engine           enum           auto|telescope|fzf (Default: auto)
show_relative    boolean        Labels relativ/basename (Default: true)
usercmd_names    table          Mapping für Files/Grep-Befehle
keymaps_lhs      table|nil      { repo_files = "<lhs>", repo_grep = "<lhs>" }
```

Beispiel-User-Commands (Erwartung)

```
RepoFilesTelescope
RepoGrepTelescope
RepoFilesFzf
RepoGrepFzf
```

