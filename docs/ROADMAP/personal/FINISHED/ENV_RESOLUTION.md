# Env-Var-Resolution — Analyse über alle Plugins

Ausgangsfrage (aus `MISC.md`): Sollen Pfad-Eingaben durch den User — in Usercmds
(`:Reposcope status $REPOS_DIR`, `:Pickers files $REPOS_DIR`), in Picker-Prompts
(Telescope/fzf-artige Query-Felder) und generell überall, wo `lib.nvim`s
`nvim.ui`-Module einen Prompt/Select anbietet — Umgebungsvariablen auflösen
können? Cross-Plattform (`$VAR`, `${VAR}`, `%VAR%`, `~`).

Analyse via 3 parallele Explore-Agents über alle 25 Repos unter `E:\repos`.

---

## Ergebnis in einem Satz

**Der Baustein existiert bereits** — `lib.nvim.cross.fs.expand_path` löst
`~`, `$VAR`, `${VAR}` und `%VAR%` korrekt auf — wird aber nur von **2 von 25
Plugins** (`pickers.nvim`, `nvim-cmdlog`) tatsächlich benutzt. Der Rest macht
entweder gar nichts (raw string), oder verlässt sich auf `vim.fn.expand`
(deckt `~`/`$VAR`, aber **nie** `%VAR%`) oder `vim.fn.fnamemodify(":p")`
(expandiert **gar nichts**, nur Pfad-Normalisierung).

Der mit Abstand größte Hebel: **`lib.nvim.usercmd.composer.argtypes`** — die
gemeinsame `PATH`/`DIR`/`FILE`-Argtyp-Definition, die von so gut wie jedem
Composer-basierten Usercmd in der ganzen Plugin-Landschaft verwendet wird.
Dort validiert `DIR` aktuell den **rohen, unexpandierten** String
(`vim.fn.fnamemodify(raw, ":p")` + `is_dir`-Check) — das ist exakt der Bug,
den der User mit `:Reposcope status $REPOS_DIR` beobachtet hätte: der Befehl
würde mit "not a directory" fehlschlagen, *bevor* überhaupt eine Expansion
stattfindet.

---

## Vorhandene Infrastruktur (lib.nvim)

| Baustein | Pfad | Deckt ab | Genutzt von |
|---|---|---|---|
| `expand_path` | `lib.nvim/lua/lib/nvim/cross/fs/expand_path/init.lua` | `~` (via `vim.uv.os_homedir()`), `$VAR`, `${VAR}`, `%VAR%` — alles über `vim.env` | nur `pickers.nvim` (`actions/dir.lua`), `nvim-cmdlog` (`core/shell.lua`) |
| re-export | `lib.nvim.cross.init.lua:29` (`M.fs.expand_path`) | — | — |
| `normalize_path` | `lib.nvim/lua/lib/nvim/normalize/utils.lua:66` | delegiert an `vim.fs.normalize` (expandiert laut Neovim-Doku ebenfalls `~`/env), aber primär Separator-Normalisierung | `debugging.nvim`, referenziert-aber-tot in `dap.nvim` |
| Composer `PATH`/`DIR`/`FILE`-Argtypen | `lib.nvim/lua/lib/nvim/usercmd/composer/argtypes.lua:129-161` | **keine** Expansion — nur `fnamemodify(":p")` + `is_dir`/`filereadable` | fast alle Composer-Plugins (gopath, mdview, nvim-containers, migrate, reposcope, filetree, fileops, debugging, …) |
| `lib.nvim.ui.kit` (nicht `lib.nvim.ui` — das Modul existiert nicht) | `lib.nvim/lua/lib/nvim/ui/kit/init.lua` | `input()`, `select()`, `prompt()`, `confirm()`, `picker()`, `popup()` — geben getippten Text **unverändert** zurück | alle Plugins, die `vim.ui.input`-artige Prompts brauchen |

Zwei überlappende Normalisierungs-Pfade (`expand_path` vs. `normalize_path`)
existieren parallel und sollten bei der Umsetzung konsolidiert werden statt
einen dritten daneben zu bauen.

---

## Pro-Plugin-Übersicht

Status-Legende: **YES** = `$VAR`/`~` wird aufgelöst (meist nur POSIX-Stil, kein `%VAR%`,
außer explizit vermerkt) · **PARTIAL** = nur `~`/`$VAR` via `vim.fn.expand`, kein `%VAR%`,
oder nur an einer von mehreren Stellen · **NO** = raw string, keine Expansion · **N/A** = kein Pfad-Input vorhanden

| Plugin | Pfad-Eingaben (Commands/Prompts/Config) | Status | Vorhandenes Path-Util |
|---|---|---|---|
| `buffer-ctx.nvim` | `:BufferCtx table scope=PATH`, `snippet.set_sources()` | YES | `util/path.lua` (ohne Env) |
| `cascade.nvim` | keine | N/A | — |
| `color_my_ascii.nvim` | `:Fence export/import <path>`, `vim.ui.input` Export-Ziel | YES | inline in export/import.lua |
| `debugging.nvim` | `autocmds sources root=`, `keylogger start [path]`, `output_dir` config | YES (via `lib.nvim.normalize`) | delegiert an lib.nvim |
| `dap.nvim` | „Path to executable" Prompts (assembly/c/rust/zig) | **NO** | `utils/paths.lua` existiert, ist aber **totes/ungenutztes Code** — würde die 4 Prompts sofort fixen |
| `diff.nvim` | `prompt_file()`, Picker-Specifier | YES | zentral in `core/resolve.lua` |
| `emojis.nvim` | keine | N/A | — |
| `fileops.nvim` | `:File new/write/saveas/writeto/rename/duplicate <path>` | YES | `resolve_path()` in `ops/file.lua` — **Referenz-Implementierung** |
| `filetree.nvim` | `:Filetree find [dir]`, `smart_create` Name-Prompt, `safety.backup_dir` config | **NO** | `util/path.lua` — vollständiges Modul, aber `to_absolute()` expandiert nicht |
| `github_stats.nvim` | `:GithubStatsExport ... <filepath>` | YES | inline `vim.fn.expand` |
| `gopath.nvim` | `:Gopath cache add-root <dir>` (Composer) / `:GopathCacheAddRoot` (Legacy) | **inkonsistent**: Legacy YES, Composer-Route **NO** (DIR-Validator blockt vor Expansion) | `resolvers/common/env_path.lua` (eigener $VAR-Resolver für Buffer-Text, nicht für Command-Input) |
| `language.nvim` | `:Spellcheck path=<p>`, `:Translate ... path=<p>` | YES | `scope/init.lua` |
| `lib.nvim` | Composer `PATH`/`DIR`/`FILE`-Typen, `ui.kit.input/prompt` | **NO** (der zentrale Gap) | hat `expand_path` fertig, nur nicht verdrahtet |
| `markdown.nvim` | `table view <path>`, `create <target>`, `links show <scope>`, mdview-Forward | YES | `util/path.lua` — **Referenz-Implementierung** |
| `mdview.nvim` | `:MDView start [file] [cwd=<dir>]`, `file-log <path>`, `browser_cmd`/`server_cwd` config | **NO** für `start`/`cwd=`/Config (nur Slash-Unify), YES nur für `file-log` | `helper/normalize.lua` — guter Hook-Punkt |
| `migrate.nvim` | keine | N/A | — |
| `nvim-cmdlog` | `favorites_path`, `shell_history_path` (YES, via `expand_path`), `notes.dir` (**NO**) | gemischt | `core/shell.lua` — **Referenz-Implementierung** für `expand_path`-Nutzung |
| `nvim-containers` | keine (nur IDs/Distro-Namen) | N/A | — |
| `open.nvim` | `:Open [scope]` (`path=<dir>`, Keyword-Pfade) | PARTIAL (`vim.fn.expand`, kein `%VAR%`), zusätzlich **Bug**: nativer-Windows-Zweig in `lib.nvim.cross.open_default` expandiert gar nicht | keins lokal |
| `pdfport.nvim` | `:PdfPort [path]` | PARTIAL | keins lokal |
| `pickers.nvim` | `:Pickers dir <nav>`, `path=`-Prompt, `repos_dir`/Collection-`dir` Config, `system`-Suchtoken | **YES für `dir`/`path=`** (volle Expansion inkl. `%VAR%`) — **Referenz-Implementierung**; aber `repos_dir`/Collection-`dir` aus `setup()` und `system`-Suchtoken **NO** | `actions/dir.lua:expand_vars` |
| `project-insight.nvim` | `metrics [root] [--file=] `, `compress [path] [outdir]`, 4 Config-Pfade | inkonsistent: `root`/`path` PARTIAL, `--file=`-Flag und alle Config-Optionen **NO** | keins, jeweils inline |
| `recommender.nvim` | keine | N/A | — |
| `replacer.nvim` | `:Replace <old> <new> [scope]` | **NO** (`fnamemodify` ohne `expand`) | keins |
| `reposcope.nvim` | `:Reposcope status [dir] --to=<path>`, `update [dir]`, `clone.std_dir` Config | `status`s `dir` **NO — hard block** (DIR-Validator lehnt `$REPOS_DIR` als "not a directory" ab, bevor Expansion läuft); `update`s `dir` PARTIAL; `--to=` PARTIAL; Config PARTIAL | `utils/repos.lua:resolve_base_dir` |
| `sessions.nvim` | `root` Config (Session-Storage-Verzeichnis) | **NO** | keins |

---

## Konkrete Bugs, die exakt den Use-Case des Users treffen

1. **`:Reposcope status $REPOS_DIR`** schlägt heute vermutlich fehl — der
   Composer-`DIR`-Argtyp validiert den rohen String (`is_dir(fnamemodify(raw, ":p"))`)
   *bevor* irgendeine Expansion passiert. `update`s Argument nutzt dagegen einen
   permissiven Custom-Typ und expandiert erst im Handler — funktioniert also
   bereits. Ungleichheit zwischen zwei sehr ähnlichen Subcommands im selben Plugin.
2. **`:Pickers dir $REPOS_DIR` / `path=$REPOS_DIR` funktioniert bereits vollständig**,
   inklusive `%VAR%` auf Windows (`pickers/actions/dir.lua:expand_vars`) — das ist
   die sauberste vorhandene Implementierung im gesamten Audit und die beste Vorlage.
3. `gopath.nvim`s `:Gopath cache add-root <dir>` über die Composer-Route hat
   denselben Blocker-Bug wie Reposcope; die Legacy-Variante `:GopathCacheAddRoot`
   funktioniert, weil sie nicht über den Composer-`DIR`-Typ läuft.
4. `mdview.nvim`: `:MDView start file.md cwd=$REPOS_DIR/proj` würde den rohen,
   unexpandierten String direkt an den Server-Start weiterreichen.
5. `dap.nvim`: alle 4 "Path to executable"-Prompts (assembly/c/rust/zig) ignorieren
   ein bereits vorhandenes, aber totes Utility-Modul (`utils/paths.lua`), das
   an `lib.nvim.normalize` delegiert.

---

## Setup()-Config-Optionen, die nie expandiert werden

Diese sind leicht zu übersehen, weil sie nicht interaktiv getippt werden, aber
genauso ein Pfad-String vom User sind (in der jeweiligen `setup({...})`-Config):

- `pickers.nvim`: `repos_dir`, Collection-`dir`
- `project-insight.nvim`: `symbols.cache.dir`, `metrics.output_file`, `tree.outdir`, `imports.output_file`
- `sessions.nvim`: `root`
- `nvim-cmdlog`: `notes.dir`
- `filetree.nvim`: `safety.backup_dir`
- `mdview.nvim`: `browser_cmd`, `server_cwd`
- `open.nvim`: `keywords`-Werte (teilweise gedeckt, s.o.)

---

## Empfehlung / Umsetzungsreihenfolge

- [x] **`lib.nvim`**: `expand_path` und `normalize_path` konsolidieren.
      `normalize_path` delegiert Env-Expansion jetzt an `expand_path` (bringt
      `%VAR%`-Support), danach `vim.fs.normalize(..., {expand_env=false})`
      nur noch für Separator/`.`/`..`. — [343bbde](https://github.com/StefanBartl/lib.nvim/commit/343bbde)
- [x] **Höchster Hebel — `lib.nvim.usercmd.composer.argtypes`**: `PATH`/`DIR`/`FILE`-Typen
      expandieren jetzt vor `fnamemodify`/`is_dir`/`filereadable` und geben
      den expandierten Wert zurück (nicht mehr den rohen String). Fixt
      `reposcope.nvim status`, `gopath.nvim cache add-root`, `filetree.nvim
      find` und jeden zukünftigen Composer-Verb mit Pfad-Argument in einem
      Schritt. — [343bbde](https://github.com/StefanBartl/lib.nvim/commit/343bbde)
- [x] **`lib.nvim.ui.kit`**: `input()`/`prompt()` haben jetzt eine opt-in
      `expand_env = true`-Option, die das Ergebnis vor dem Callback durch
      `expand_path` schickt. — [343bbde](https://github.com/StefanBartl/lib.nvim/commit/343bbde)
      (Callsites, die davon Gebrauch machen, sind noch offen — s. Punkt 4c unten.)
- [x] `reposcope.nvim`: `:Reposcope status $REPOS_DIR` end-to-end verifiziert
      (funktioniert über den Composer-Fix); `clone.std_dir` und `--to=` von
      `vim.fn.expand` auf `expand_path` gehoben (`%VAR%`-Support).
      — [e415b83](https://github.com/StefanBartl/reposcope.nvim/commit/e415b83)
- [x] `gopath.nvim`: Composer-Route `:Gopath cache add-root <dir>` verifiziert;
      Handler + Legacy-Alias `:GopathCacheAddRoot` von `vim.fn.expand` auf
      `expand_path` gehoben. — [2cca22d](https://github.com/StefanBartl/gopath.nvim/commit/2cca22d)
- [x] **Einzel-Fixes** (kein gemeinsamer Hook, da individuelle Config-Reads):
  - [x] `pickers.nvim`: `repos_dir`, Collection-`dir` (und `history.dir`) in
        `config/init.lua` expandiert — bereits vorher erledigt, verifiziert.
        — [26b7e67](https://github.com/StefanBartl/pickers.nvim/commit/26b7e67)
  - [x] `project-insight.nvim`: `symbols.cache.dir`, `metrics.output_file`,
        `tree.outdir`, `compress.outdir`, `imports.output_file` und das
        `--file=`-Flag expandiert (`config/init.lua`, `bindings/usrcmds.lua`).
        — [4bb3720](https://github.com/StefanBartl/project-insight.nvim/commit/4bb3720)
  - [x] `sessions.nvim`: `root`-Config expandiert.
        — [e06d86a](https://github.com/StefanBartl/sessions.nvim/commit/e06d86a)
  - [x] `nvim-cmdlog`: `notes.dir` an `expand_path`-Pattern von `shell.lua` angeglichen.
        — [bdc290a](https://github.com/StefanBartl/nvim-cmdlog/commit/bdc290a)
  - [x] `filetree.nvim`: `util/path.lua:to_absolute()` (soft-dependency-Pattern,
        analog zu `unify_slashes`/`relpath`) + `safety.backup_dir` expandiert.
        — [d9aadcf](https://github.com/StefanBartl/filetree.nvim/commit/d9aadcf)
  - [x] `mdview.nvim`: nicht über `helper/normalize.lua:path()` (zu riskant —
        wird auch auf bereits aufgelöste Buffer-Namen angewendet, ein Dollar
        im Dateinamen könnte fehlinterpretiert werden), sondern gezielt an
        den tatsächlichen Eintrittspunkten: `adapter/runner.lua:resolve_spawn_cwd()`
        (deckt `cwd=`-Arg *und* `server_cwd`-Config in einem Rutsch ab) und
        `config/browser.lua:resolve_and_validate()` (`browser_cmd` — dort lag
        sogar ein zweiter Bug: `resolved_browser_cmd` speicherte den
        unexpandierten String, obwohl die Executable-Prüfung selbst schon
        expandierte). 24/24 Tests grün.
        — [32754c7](https://github.com/StefanBartl/mdview.nvim/commit/32754c7)
  - [x] `open.nvim` / `lib.nvim.cross.open_default`: nativer-Windows-Zweig
        expandiert jetzt (vorher gar keine Expansion); WSL/macOS/Linux von
        `vim.fn.expand` auf `expand_path` gehoben (`%VAR%`-Support).
        — [94d1180](https://github.com/StefanBartl/lib.nvim/commit/94d1180)
        `open.nvim`: `path=`-Arg und String-Keyword-Overrides in
        `context.lua:M.resolve()` sowie die eingebauten Keyword-Pfade in
        `keywords.lua` auf `expand_path` gehoben.
        — [9a86b3c](https://github.com/StefanBartl/open.nvim/commit/9a86b3c)
  - [x] `replacer.nvim`: `resolve_scope()` bekommt `expand_path` vor
        `fnamemodify` (auch vor dem "%"-Autodetect-Vergleich, unschädlich für
        die Keyword-Token `%`/`buf`/`cwd`/`.`).
        — [455d184](https://github.com/StefanBartl/replacer.nvim/commit/455d184)
- [x] `dap.nvim`s totes `utils/paths.lua` an die 4 Executable-Prompts
      (assembly/c/rust/zig) angeschlossen — delegiert an
      `lib.nvim.normalize`, das seit dem Konsolidierungs-Commit oben selbst
      an `expand_path` delegiert.
      — [4b3e022](https://github.com/StefanBartl/dap.nvim/commit/4b3e022)
- Referenzimplementierungen als Vorlage: `pickers.nvim/actions/dir.lua`
  (`expand_vars`) und `nvim-cmdlog/core/shell.lua` (`expand_path_template`)
  zeigten bereits vor diesem Umbau den korrekten Umgang mit `expand_path`.

Kein Plugin aus der Liste braucht eine komplett neue Utility — `lib.nvim`
liefert den Baustein bereits; die verbleibenden Punkte sind Einzel-Callsites,
die noch nicht darauf verdrahtet sind.
