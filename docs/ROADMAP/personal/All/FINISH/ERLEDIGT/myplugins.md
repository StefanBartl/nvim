# wkdbook-myplugins usrcmd (`plugins_book`)

## Notes

- Branch/Worktree, in dem das analysiert wurde: `claude/nvim-autocomplete-usrcmd-c6fdae`
  (Worktree `casedesk-area-refactor-f23a72`, wegen des Themas eigentlich fehlgeleitet —
  neuer Task/Branch sinnvoll, bevor hier Code entsteht).
- never start more than 1 agent simultaneously; if more are needed, run multiple rounds of up to 1 agent each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Keine Co-Autorenschaft von Claude in den Commits
- Wenn fertig: committen/pushen/pullen, sodass main sofort aktuell ist
- Betrifft **zwei Repos**: `nvim-config` (Config-Eintrag) und `pickers.nvim` (neue Source + Commands) —
  in `pickers.nvim` gilt `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOL-PLACEMENT.md` /
  `HEREDOC.md` ebenfalls.
- Code muss luacheck/stylua-grün sein (beide Repos haben eigene CI dafür, siehe
  `ci-fleet-conventions`-Memory: stylua v2.5.2, luacheck 1.2.0).

---

## Handover Notes

### Ausgangsfragen des Users

1. **Warum schlägt `---` (drei Bindestriche) im Insert-Mode irrelevante Sachen wie
   `my.nvim`/`ui.nvim` vor?** → geklärt, siehe unten. Kein offener Task, nur Diagnose.
2. **Neuer usrcmd speziell für `E:\repos\WKDBooks\Development\wkdbook-myplugins`**,
   analog zu `:RepoFiles`/`:WkdBookFiles` — Namenskollision mit bestehendem `:MyPlugins`
   (Git-Lifecycle-Verb, nvim-config) und `:WkdBookFiles`/`:WkdBookGrep` (alle Bücher,
   pickers.nvim) musste vermieden werden. → **Konzept fertig, Umsetzung noch offen.**

### 1. `---`-Completion-Befund (erledigt, nur zur Doku)

Root cause in `lsp.nvim`:

- [`lua/lsp/completion/personal_names/init.lua:174`](E:\repos\lsp.nvim\lua\lsp\completion\personal_names\init.lua) setzt `keyword_pattern`,
  der laut [`lua/lsp/completion/register.lua:42`](E:\repos\lsp.nvim\lua\lsp\completion\register.lua) **nur für nvim-cmp gilt**
  (`-- nvim-cmp only; blink derives its own.`).
- Unter blink.cmp (aktives Backend) liefert
  [`lua/lsp/completion/blink.lua:57`](E:\repos\lsp.nvim\lua\lsp\completion\blink.lua) bei jeder Anfrage die
  komplette, ungefilterte Item-Liste — Filterung passiert komplett in blink.cmp selbst,
  über `iskeyword`.
- `-` zählt standardmäßig nicht als Keyword-Zeichen → nach `---` ist der Keyword-Kontext
  für blink leer → Fuzzy-Matcher bewertet alle ~30 Items nahezu gleich und zeigt sie
  trotzdem, sortiert nach Frecency/Nutzung statt nach Textbezug.
- Passiert nach jedem reinen Satzzeichen-Präfix (`===`, `///`, ...), nicht nur `---`.
- **Möglicher Fix, falls gewünscht:** `min_keyword_length` oder eine `enabled()`-Guard
  für den `personal_names`-Provider in
  [`lua/lsp/pack/completion_blink.lua:86`](E:\repos\lsp.nvim\lua\lsp\pack\completion_blink.lua). Nicht umgesetzt,
  nur als Option genannt — User hat nicht nach einem Fix gefragt, nur nach der Ursache.

### 2. Konzept `plugins_book` (Entscheidungen bereits getroffen)

**Bestehender Mechanismus (kein Neubau nötig):** `pickers.nvim` registriert für jeden
Eintrag in `collections` (Config in
`lua/plugins/personal/init.lua:391`, diese Config hier — Pfad ist
worktree-relativ) automatisch `:{Pascal}Files`/`:{Pascal}Grep`/`:{Pascal}Smart` über
[`pickers/bindings/collections.lua`](E:\repos\pickers.nvim\lua\pickers\bindings\collections.lua) +
[`pickers/sources/collection.lua`](E:\repos\pickers.nvim\lua\pickers\sources\collection.lua). Mit `prefix = ""`
listet das Modul alle unmittelbaren Unterordner von `dir` in einem Picker (nicht deren
Dateien); Auswahl liefert dann `files`/`grep`/`smart` innerhalb dieses einen Ordners.
Genau das Muster nutzt schon die `wkdbooks`-Collection (prefix `"wkdbook-"`, listet alle
Bücher) — `wkdbook-myplugins` braucht denselben Mechanismus eine Ebene tiefer, ohne
Präfix-Filter (Plugin-Ordner heißen `cascade.nvim`, `ui.nvim`, ... — nicht `wkdbook-*`).

**Namens-Check:** `to_pascal()` ([`pickers/bindings/util.lua:44`](E:\repos\pickers.nvim\lua\pickers\bindings\util.lua))
kapitalisiert nur nach `_`, kennt keine Bindestriche. Vim/Neovim-Usercmd-Namen dürfen
**keinen Bindestrich** enthalten — `:WkdBook-PLUGINNAME` (User-Idee) ist also nicht
möglich. Collection-Name muss mit Unterstrichen geschrieben werden.

**Getroffene Entscheidungen** (User, via AskUserQuestion):

| Frage | Entscheidung |
| --- | --- |
| Name | `plugins_book` → Commands `:PluginsBookFiles` / `:PluginsBookGrep` / `:PluginsBookSmart` |
| Direkt-Sprung mit Argument (wie `:RepoFiles [repo]`) | **Ja**, mit Tab-Completion |
| Vierte Aktion "nur Ordner öffnen/root wechseln" | **Nicht nötig** — files/grep/smart reichen |

### 3. Konkreter Plan

**a) `nvim-config` — Collection-Eintrag** in
`lua/plugins/personal/init.lua` (gleiche Stelle wie `notes`/`wkdbooks`, ca. Zeile 391 ff.):

```lua
{
  name = "plugins_book",
  dir = repos .. "/WKDBooks/Development/wkdbook-myplugins",
  prefix = "",        -- listet alle Unterordner (cascade.nvim, ui.nvim, ...) im Picker
  only_git = true,    -- blendet ALL/, TEMPLATES/, TOOLS/, _Telemetry/ etc. aus
  keys = { files = "<leader>?f", grep = "<leader>?g", smart = "<leader>?s" },  -- Leader-Kürzel noch offen!
},
```

`only_git = true` filtert automatisch Nicht-Plugin-Ordner aus `wkdbook-myplugins` raus
(dort liegen neben den `*.nvim`-Repos auch `ALL/`, `TEMPLATES/`, `TOOLS/`, `_Telemetry/`,
`HEREDOC.md`, `README.md`, `ROADMAP.md`).

**Offen:** Leader-Kürzel für `keys.files`/`keys.grep`/`keys.smart` noch nicht vergeben —
mit bestehender Belegung abgleichen (siehe `<leader>wkf/wkg/wks` für `wkdbooks`,
`<leader>mnf/mng/mns` für `notes` als Vorbild).

**b) `pickers.nvim` — Direkt-Sprung mit Tab-Completion**, analog zu `:RepoFiles`/`:RepoGrep`
in [`lua/pickers/bindings/usrcmds.lua:139`](E:\repos\pickers.nvim\lua\pickers\bindings\usrcmds.lua):

```vim
:PluginsBookFiles [plugin]   " ohne Arg: Picker; mit Arg (tab-completed): direkt Dateisuche in [plugin]
:PluginsBookGrep [plugin]    " gleiches Prinzip für Grep
```

Umsetzung:

- Neue Source-Funktionen `resolve`/`complete`/`list_names` analog zu
  [`lua/pickers/sources/repos.lua`](E:\repos\pickers.nvim\lua\pickers\sources\repos.lua), aber gegen
  `wkdbook-myplugins` als Root statt `cfg.repos_dir` (neue Datei, z. B.
  `lua/pickers/sources/plugins_book.lua`, oder Erweiterung von `repos.lua` um einen
  optionalen `base_dir`-Parameter — Design-Entscheidung beim Implementieren treffen).
- Zwei handgeschriebene `usercmd`-Registrierungen (`nargs = "?"` + Completion-Funktion)
  in `usrcmds.lua`, nach dem Muster von `run_repo_action`/`complete_repo`
  (Zeilen 33–64 und 139–157 der Datei).
- Diese handgeschriebenen `Files`/`Grep`-Commands **ersetzen** die generischen aus
  `collections.lua` für `plugins_book` (die Collection-Registrierung würde sie sonst
  doppelt anlegen — `collections.lua` prüft zwar `vim.fn.exists(":" .. files_cmd) ~= 2`
  und überspringt dann, aber Reihenfolge beachten: `usrcmds.lua`/`M.register()` muss
  **vor** der Collection-Iteration in `pickers/bindings/init.lua:24` laufen, sonst
  gewinnt die generische Variante ohne Arg-Support). `:PluginsBookSmart` bleibt die
  generische, unveränderte Collection-Command (kein Arg-Support gefordert).
- `docs/BINDINGS.md`, `docs/cheatsheet.md`, `docs/commands.md`,
  `doc/pickers.txt` in `pickers.nvim` mitpflegen (dort stehen `:RepoFiles`/`:WkdBookFiles`
  bereits dokumentiert — `:PluginsBookFiles`/`:PluginsBookGrep` dort ergänzen).

### 4. Umsetzung (erledigt, 2026-09-14)

Implementiert in beiden Repos, siehe Details unten. Eine Planänderung gegenüber
Abschnitt 3 war nötig:

**`only_git = true` funktioniert nicht** — die Unterordner in `wkdbook-myplugins`
(`cascade.nvim/`, `ui.nvim/`, ...) sind reine Doku-Ordner (nur `ROADMAP/` drin),
**kein** `.git`. Die echten Repo-Klone liegen direkt unter `REPOS_DIR`. Mit
`only_git = true` blieben 0 Einträge übrig (per Headless-Smoke-Test verifiziert).
Fix: neues generisches Collection-Feld `exclude` (`string[]`, exakte Basenamen)
in `pickers.nvim` ergänzt — filtert `ALL`, `TEMPLATES`, `TOOLS`, `_Telemetry`
per Namen statt per `.git`-Test. Betrifft `pickers/sources/collection.lua`,
`pickers/config/init.lua`, `pickers/sources/@types/init.lua`,
`docs/collections.md`.

Leader-Kürzel: `<leader>pbf/pbg/pbs` (Präfix `pb` war frei, kollidiert nicht
mit dem bestehenden `<leader>p*`-Fileops/Gopath/Insights/Profiler-Cluster).

Verifiziert per Headless-`nvim --headless -u NONE`-Smoke-Test: `list_names`/
`resolve`/`complete` gegen den echten `wkdbook-myplugins`-Pfad, sowie voller
`require("pickers").setup(...)` mit Prüfung von `:PluginsBookFiles`-Registrierung
(nargs `?` + Completion, überschreibt die generische Collection-Variante),
`:PluginsBookSmart` (bleibt generisch) und den drei Keymaps.

---

## Tasks

- [x] Leader-Kürzel für `plugins_book`-Collection festlegen (`pbf`/`pbg`/`pbs`)
- [x] Collection-Eintrag in `lua/plugins/personal/init.lua` einfügen
- [x] `pickers.nvim`: Source-Layer für `wkdbook-myplugins`
      (`lua/pickers/sources/plugins_book.lua`: resolve/complete/list_names)
- [x] `pickers.nvim`: `:PluginsBookFiles [plugin]` / `:PluginsBookGrep [plugin]` mit
      Tab-Completion registriert, generische Collection-Files/Grep-Variante dafür
      ausgespart (usrcmds.register() läuft vor der Collections-Loop)
- [x] `pickers.nvim`-Docs aktualisiert (`docs/BINDINGS.md`, `docs/cheatsheet.md`,
      `docs/commands.md`, `doc/pickers.txt`, `docs/collections.md`)
- [x] luacheck/stylua in beiden Repos grün, commit/push auf main
- [ ] Optional, falls gewünscht: `---`-Fix für `personal_names`-Provider in
      `lsp.nvim` (`min_keyword_length` oder `enabled()`-Guard) — war nur Diagnose,
      kein bestätigter Auftrag
