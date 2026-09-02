# BINDINGS-Driftreport — 2026-09-02

Die Cheatsheets unter `docs/NOTES/` gegen die Bindings geprüft, die eine echte
Instanz dieser Config tatsächlich registriert. Punkt 4 aus
[TASKS-2026-09-02.md](TASKS-2026-09-02.md).

**Zum Pfad aus dem Auftrag:** `docs/NOTES/BINDINGS` gibt es nicht. Der Korpus
sind zwei Bäume — `docs/NOTES/PersonelPlugins/BINDINGS/` und
`docs/NOTES/ExternPlugins/Bindings/`. Denselben Irrtum trägt das alte
`:BindingsPath` (siehe den Moduldoc von `bindings_explorer/init.lua`).

## Lauf

```
nvim --headless -c "lua require('bindings.usrcmds.bindings_explorer.drift')
                      .check(nil, { repo = true })"
```

Entspricht `:Bindings check repo`, also allen vier Achsen. `repo` ist bewusst
opt-in und hier zwingend: ohne sie winkt `is_plugin_loaded` alles durch, was
lazy noch nicht geladen hat — in diesem Lauf 27 von rund 60 Plugins.

| | |
| --- | --- |
| Neovim | 0.12.2 |
| Config-Stand | `d1d642e0` |
| Laufzeit der Prüfung | 677 ms |
| Geladene Plugins in der Session | 27 |
| Repo-Achse: aufgelöste Checkouts | 32 |
| davon beantwortet | 21 |
| **Übersprungen (gar nicht geprüft)** | **0** |
| Befunde | 266 |

Null Übersprungene ist das eigentliche Qualitätsmerkmal des Laufs: jede
dokumentierte Bindung wurde von mindestens einer Achse angefasst.

## Die 266 auf einen Blick

| Befundart | n | Was es überwiegend ist |
| --- | ---: | --- |
| `usercmd-undocumented` | 166 | live, aber im Korpus nicht als Tabellenzeile |
| `keymap-not-live` | 88 | dokumentiert, in dieser Session nicht gebunden |
| `keymap-not-in-repo` | 7 | bekannte Falschbefunde der Grep-Achse |
| `usercmd-not-live` | 5 | drei Parserfehler, zwei „lazy nicht ausgelöst" |

Die 88 `keymap-not-live` erscheinen im Bericht als 50 Einzelzeilen plus 38
Schlüssel in 7 Tabellen, die als Block gemeldet werden („nicht von hier aus
prüfbar").

**266 Befunde sind nicht 266 Probleme.** Aufgeteilt nach dem, was zu tun wäre:

| | n |
| --- | ---: |
| Echte Doku-Lücke, sollte nachgetragen werden | **57** |
| Werkzeugfehler (Scraper/Matcher), sollte gefixt werden | ~45 |
| Erwartbar und korrekt (Fremdinfra, buffer-lokale UIs, lazy) | ~164 |

---

## 1. Echte Lücke: 57 Commands stehen nirgends im Korpus

Der größte Einzelposten des Berichts ist die Zeile *„88 live commands, origin:
via lib.nvim usercmd helpers — owner not recorded"*. Von diesen 88 habe ich
jedes einzeln gegen beide Bäume gegrept — auch gegen Fließtext, nicht nur
gegen Tabellen:

* **31** kommen im Korpus vor, aber **nur im Fließtext**. Der Scraper liest
  Tabellenzeilen, also zählen sie als undokumentiert. Das ist ein
  Werkzeugfehler, siehe Abschnitt 3.
* **57** kommen **überhaupt nicht** vor. Das ist die echte Drift.

Und sie ist nicht gestreut, sie hat drei Ursachen:

**23 — von pickers.nvim erzeugte Scope-Familien.**
`:NotesFiles`/`:NotesGrep`/`:NotesSmart`, dasselbe für `Wkdbooks`,
`WkdbooksLua`, `WkdbooksNvim`, `NotesLua`, `NotesNvim`, `Spickzettel`,
`Checklists`. Die entstehen aus einer Scope-Liste in der Config, nicht aus
handgeschriebenem Code. Sie einzeln in ein Cheatsheet zu schreiben wäre genau
die handgeführte Liste, die überall sonst in diesem Repo als Fehlerquelle
gilt — **das Cheatsheet sollte den Generator dokumentieren, nicht seine
Ergebnisse**, und `:Bindings check` sollte eine so beschriebene Familie als
abgedeckt akzeptieren.

**21 — lsp.nvims serverspezifische Commands.**
`:Astro*` (8), `:TypeDef*` (5), `:LuaLs*` (3), `:MdRebuildWords`/`:MdSetRoot`/
`:MdWordStats`, `:PrettierFormat`, `:LintAndFormat`, `:CmpReloadWords`.
`Usercmds/lsp.nvim.md` führt `:Lsp`, `:LspDoctor` und die Legacy-Aliase, aber
nicht die filetype-gebundenen — obwohl dieselbe Datei in Zeile 170 erklärt,
*warum* sie eigene Namen behalten. Der Grund steht da, die Liste nicht.

**7 — Commands dieser Config selbst.** `:MyOptList`/`:MyOptSet`/`:MyOptShow`
und `:WKDOptionsHLDebugCtx`/`HLList`/`HLSet`/`HLShow`. Kein Plugin, also auch
kein Cheatsheet-Eigentümer — der Korpus ist nach Plugins geschnitten und hat
für die Config selbst keinen Platz. Das ist eine Lücke im Aufbau des Korpus,
nicht im Fleiß.

**Rest (6):** `:ContextOpen`, `:LibAutocmdDocsCheck`, `:LibUsercmdDocsCheck`,
`:SystemInfo`, `:ToggleInlineDiff`, `:ToggleLintFormatOnSave`. Die beiden
`*Check`-Varianten sind besonders bezeichnend: ihre Basisformen
(`:LibAutocmdDocs`, `:LibUsercmdDocs`) **stehen** im Korpus, die
`Check`-Zwillinge nicht.

## 2. Der Befund hinter dem Befund: lib.nvim merkt sich den Eigentümer nicht

Alle 88 tragen dieselbe Herkunftsangabe: *„via lib.nvim usercmd helpers —
owner not recorded"*. Die Registry, durch die diese Config und ihre Plugins
ihre Commands anlegen, hält nicht fest, wer registriert hat.

Damit kann `:Bindings check` einen undokumentierten Command eines eigenen
Plugins nicht von einem undokumentierten Fremd-Command unterscheiden, und der
Bericht muss beide in denselben Topf werfen. Genau deshalb steht unter der
Überschrift die entschuldigende Note *„mostly third-party infra this corpus
never covered"* — die stimmt für die anderen 78, und für diese 88 ist sie
falsch: es sind fast ausschließlich eigene.

**Ein Feld in lib.nvims Usercmd-Registry wäre die wirksamste Einzelmaßnahme
dieses ganzen Berichts.** Es würde 88 Zeilen nach Eigentümer aufteilen, den
Abschnitt nach „eigene" und „fremde" trennen, und die Prüfung könnte auf die
eigenen zuspitzen. Verwandt mit dem bereits bekannten Fund `:RATelemetry`
(steht in `Usercmds/lib.nvim.md`, registriert wird es von
runtime-analysis.nvim) — dieselbe fehlende Zuordnung, andere Richtung.

## 3. Werkzeugfehler: was der Scraper falsch liest

Vier Klassen, alle im selben Modul (`bindings_explorer/records.lua`):

**a) Platzhalter in der Key-Spalte werden als Taste gelesen.**
`Keymaps/lib.nvim.md:34` hat `—` in der Key-Spalte (Bedeutung: *keine* Taste,
das Feature ist aus), `Keymaps/buffer-ctx.md:26` hat `*(unset)*`, dieselbe
Datei `*(your lhs)*`. Alle drei landen als „dokumentierte Taste, nicht live".

**b) Commandnamen aus dem Fließtext einer Zelle.**
`Usercmds/buffer-ctx.md:32` beschreibt den `location`-Subcommand, und im
Beispieltext steht `path:L1-L2`. Gemeldet wird ein fehlender Command `:L1`.

**c) Meta-Dateien werden wie Plugin-Cheatsheets behandelt.**
`Collisions.md` (11 Befunde) dokumentiert *Kollisionen*, `Overview.md` (3)
ist eine Zusammenfassung. Beide haben Tabellen, deren Zellen Tastennamen und
Commandnamen enthalten — aber keine davon ist eine Bindung, die irgendwer
registriert. 14 Befunde aus zwei Dateien, die gar keine Plugins sind.

**d) Nur Tabellenzeilen zählen.** Die 31 aus Abschnitt 1: dokumentiert, aber
im Fließtext. `:LuaLsReloadLibrary` etwa steht in `Usercmds/lsp.nvim.md:170`,
`:AllDrives`/`:RepoGrep` in `Usercmds/pickers.nvim.md:39-40` als
Aufzählung mit `·` statt als Tabelle.

Dazu der schon bekannte Defekt: `split_cells` zerlegt escapte Pipes, eine
Zelle mit `\|` wird an genau dieser Stelle getrennt.

## 4. Korrekte Befunde, die trotzdem kein Handlungsbedarf sind

**50 + 38 `keymap-not-live`** — fast alle sind buffer-lokale Tasten einer UI,
die in einer headless-Session nicht offen ist: reposcope.nvim (17),
cmdlog.nvim (9), pickers.nvim (8), github_stats.nvim (2). Der Bericht sagt
das selbst und bietet den nächsten Schritt an („Open it and re-run"). Die 38
in 7 Tabellen sind derselbe Fall, nur dass *keine* Taste der Tabelle live war
— der Melder fasst sie deshalb richtigerweise zur Tabelle zusammen statt 38
Einzelzeilen zu erzeugen.

**7 `keymap-not-in-repo`** — alle sieben sind debugging.nvims `prefix .. "m"`,
der dokumentierte Falschbefund einer Grep-Achse: ein `lhs`, den das Plugin zur
Laufzeit zusammensetzt, steht als Literal nirgends im Quelltext. Bekannt seit
dem Bau der Achse, unverändert.

**~78 der `usercmd-undocumented`** — Fremdinfrastruktur, die dieser Korpus nie
abgedeckt hat: `:Gitsigns`, `:Lazy`, `:Mason*`, `:Noice*`, `:Diffview*`,
Neovims eigene `:Inspect`/`:Man`, Vimscript-Plugins. Korrekt gemeldet und
korrekt zu ignorieren.

**2 `usercmd-not-live` sind „lazy, Trigger nicht ausgelöst":**
`:LibLogger` dokumentiert selbst „registriert automatisch beim ersten
`logger.new()`", und `:Markdown` wird erst mit dem ersten Markdown-Buffer
angelegt. Die Bedingung steht im Cheatsheet (Spalte *„Registered when"*), der
Prüfer kann sie nur nicht lesen.

## 5. Was daraus folgt

Nach Wirkung sortiert:

1. **lib.nvims Usercmd-Registry merkt sich den Eigentümer.** Ordnet 88 der 166
   zu und macht den größten Abschnitt des Berichts erst auswertbar.
2. **`records.lua` reparieren** — Platzhalterzellen, Commandnamen aus Prosa,
   escapte Pipes, und Meta-Dateien (`Collisions.md`, `Overview.md`) aus dem
   Plugin-Korpus nehmen. Räumt rund 45 Befunde ab. Gehört zu Punkt 7 des
   Aufgabenblocks.
3. **Die 21 serverspezifischen lsp.nvim-Commands nachtragen.** Kleinste echte
   Arbeit mit dem größten Ehrlichkeitsgewinn; die Begründung steht schon in
   der Datei.
4. **Für die 23 generierten Scope-Commands den Generator dokumentieren**, und
   `:Bindings check` beibringen, eine Familie als abgedeckt zu akzeptieren.
   Eine handgeführte Liste wäre hier die falsche Antwort.
5. **Einen Ort für die Commands der Config selbst schaffen** (`:MyOpt*`,
   `:WKDOptions*`) — der Korpus ist nach Plugins geschnitten und hat für sie
   heute keinen.
6. **Prosa-Dokumentation als gültig anerkennen** oder die 31 Fälle in
   Tabellen überführen. Eine der beiden, nicht keine.

---

## Anhang: der Bericht im Original

Unverändert die Ausgabe von `drift.describe`, wie sie `:Bindings check repo`
in den Viewer schreibt.

```text
Usercmds — documented, not registered (5)
  -- highest-signal axis; a documented-lazy command may need its feature exercised first
  buffer-ctx             :L1                  docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/buffer-ctx.md:32
  lib.nvim               :LibLogger           docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/lib.nvim.md:151
  Overview               :Markdown            docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/Overview.md:28
  Overview               :File                docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/Overview.md:64
  Overview               :Debug               docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/Overview.md:133

Keymaps — documented, not registered (50)
  -- not found globally, nor in any buffer open right now
  buffer-ctx             *(unset)*            docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/buffer-ctx.md:26
  cmdlog.nvim            <CR>                 docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md:34
  cmdlog.nvim            <C-R>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md:36
  cmdlog.nvim            <C-X>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md:37
  cmdlog.nvim            <C-Space>            docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md:38
  cmdlog.nvim            <C-Z>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md:40
  cmdlog.nvim            <C-Up>               docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md:41
  cmdlog.nvim            <C-Down>             docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md:42
  cmdlog.nvim            ctrl-f               docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md:78
  cmdlog.nvim            ctrl-t               docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cmdlog.nvim.md:79
  Collisions             <Space>nf            docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:51
  Collisions             gP                   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:52
  Collisions             <Space>ss            docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:54
  Collisions             ls*                  docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:55
  Collisions             <Space>lr            docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:57
  Collisions             <Space>rs            docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:58
  Collisions             <Space>sk            docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:59
  Collisions             <C-Y>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:60
  Collisions             gP                   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:117
  Collisions             +                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:118
  Collisions             +                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md:144
  github_stats.nvim      h                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/github_stats.nvim.md:22
  github_stats.nvim      <BS>                 docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/github_stats.nvim.md:62
  insights.nvim          gf                   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/insights.nvim.md:43
  lib.nvim               â�                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/lib.nvim.md:34
  pickers.nvim           <PageDown>           docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:109
  pickers.nvim           <PageUp>             docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:110
  pickers.nvim           <C-Left>             docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:111
  pickers.nvim           <C-Right>            docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:112
  pickers.nvim           <C-N>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:114
  pickers.nvim           <C-V>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:117
  pickers.nvim           <C-T>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:118
  pickers.nvim           <S-CR>               docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:152
  reposcope.nvim         <CR>                 docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:27
  reposcope.nvim         <Up>                 docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:28
  reposcope.nvim         <Down>               docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:29
  reposcope.nvim         <C-V>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:32
  reposcope.nvim         <BS>                 docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:35
  reposcope.nvim         <C-D>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:37
  reposcope.nvim         ?                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:38
  reposcope.nvim         <C-F>                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:39
  reposcope.nvim         q                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:57
  reposcope.nvim         q                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:58
  reposcope.nvim         q                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:59
  reposcope.nvim         S                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:62
  reposcope.nvim         s                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:63
  reposcope.nvim         r                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:64
  reposcope.nvim         y                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:65
  reposcope.nvim         ?                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:66
  reposcope.nvim         q                    docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:67

Documented, and nowhere in the plugin's own checkout (7)
  -- source grep, not an API query: an lhs the plugin computes at runtime is a false finding here
  debugging.nvim         <lt>m                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/debugging.nvim.md:13
  debugging.nvim         <lt>n                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/debugging.nvim.md:14
  debugging.nvim         <lt>e                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/debugging.nvim.md:15
  debugging.nvim         <lt>c                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/debugging.nvim.md:16
  debugging.nvim         <lt>f                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/debugging.nvim.md:17
  debugging.nvim         <lt>y                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/debugging.nvim.md:18
  debugging.nvim         <lt>x                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/debugging.nvim.md:19

Live commands with no cheatsheet, by origin (166)
  -- mostly third-party infra this corpus never covered; grouped so it can be skimmed
  :ConformInfo                 conform.nvim
  :DiffviewClose               diffview.nvim (lazy cmd stub)
  :DiffviewFileHistory         diffview.nvim (lazy cmd stub)
  :DiffviewFocusFiles          diffview.nvim (lazy cmd stub)
  :DiffviewOpen                diffview.nvim (lazy cmd stub)
  :DiffviewToggleFiles         diffview.nvim (lazy cmd stub)
  :DocMapAllFull               documentation.nvim (lazy cmd stub)
  :GitConflictChooseBase       git-conflict.nvim
  :GitConflictChooseBoth       git-conflict.nvim
  :GitConflictChooseNone       git-conflict.nvim
  :GitConflictChooseOurs       git-conflict.nvim
  :GitConflictChooseTheirs     git-conflict.nvim
  :GitConflictListQf           git-conflict.nvim
  :GitConflictNextConflict     git-conflict.nvim
  :GitConflictPrevConflict     git-conflict.nvim
  :GitConflictRefresh          git-conflict.nvim
  :Gitsigns                    gitsigns.nvim
  :IncRename                   inc-rename.nvim (lazy cmd stub)
  :Lazy                        lazy.nvim
  :MarkdownPreview             markdown-preview.nvim (lazy cmd stub)
  :MarkdownPreviewStop         markdown-preview.nvim (lazy cmd stub)
  :MarkdownPreviewToggle       markdown-preview.nvim (lazy cmd stub)
  :Mason                       mason.nvim (lazy cmd stub)
  :MasonInstall                mason.nvim (lazy cmd stub)
  :MasonUpdate                 mason.nvim (lazy cmd stub)
  :MigrateHl                   migrate.nvim (lazy cmd stub)
  :MigrateLsp                  migrate.nvim (lazy cmd stub)
  :Huefy                       minty (lazy cmd stub)
  :Shades                      minty (lazy cmd stub)
  :Neotree                     neo-tree.nvim (lazy cmd stub)
  :Neogit                      neogit (lazy cmd stub)
  :EditQuery                   neovim runtime: _core/defaults.lua
  :Inspect                     neovim runtime: _core/defaults.lua
  :InspectTree                 neovim runtime: _core/defaults.lua
  :Man                         neovim runtime: plugin/man.lua
  :Noice                       noice.nvim (lazy cmd stub)
  :NoiceAll                    noice.nvim (lazy cmd stub)
  :NoiceDismiss                noice.nvim (lazy cmd stub)
  :NoiceError                  noice.nvim (lazy cmd stub)
  :NoiceHistory                noice.nvim (lazy cmd stub)
  :PuppeteerDisable            nvim-puppeteer
  :PuppeteerEnable             nvim-puppeteer
  :PuppeteerToggle             nvim-puppeteer
  :NvimTreeFocus               nvim-tree.lua (lazy cmd stub)
  :NvimTreeToggle              nvim-tree.lua (lazy cmd stub)
  :TSInstallFromGrammar        nvim-treesitter
  :TSLog                       nvim-treesitter
  :TSUninstall                 nvim-treesitter
  :TSUpdate                    nvim-treesitter
  :TSInstall                   nvim-treesitter (lazy cmd stub)
  :NvimWebDeviconsHiTest       nvim-web-devicons
  :RenderMarkdown              render-markdown.nvim (lazy cmd stub)
  :Replace                     replacer.nvim (lazy cmd stub)
  :Surround                    replacer.nvim (lazy cmd stub)
  :Resty                       resty.nvim (lazy cmd stub)
  :Screenkey                   screenkey.nvim (lazy cmd stub)
  :Telescope                   telescope.nvim (lazy cmd stub)
  :Trouble                     trouble.nvim (lazy cmd stub)
  :NvCheatsheet                ui
  :Nvdash                      ui
  :AllDrives                   via lib.nvim usercmd helpers — owner not recorded
  :AllDrivesGrep               via lib.nvim usercmd helpers — owner not recorded
  :AstroBuild                  via lib.nvim usercmd helpers — owner not recorded
  :AstroCheckStructure         via lib.nvim usercmd helpers — owner not recorded
  :AstroDevStart               via lib.nvim usercmd helpers — owner not recorded
  :AstroDevStop                via lib.nvim usercmd helpers — owner not recorded
  :AstroFindUsage              via lib.nvim usercmd helpers — owner not recorded
  :AstroListComponents         via lib.nvim usercmd helpers — owner not recorded
  :AstroNewComponent           via lib.nvim usercmd helpers — owner not recorded
  :AstroNewPage                via lib.nvim usercmd helpers — owner not recorded
  :AstroPreview                via lib.nvim usercmd helpers — owner not recorded
  :Case                        via lib.nvim usercmd helpers — owner not recorded
  :Cases                       via lib.nvim usercmd helpers — owner not recorded
  :ChecklistsFiles             via lib.nvim usercmd helpers — owner not recorded
  :ChecklistsGrep              via lib.nvim usercmd helpers — owner not recorded
  :ChecklistsSmart             via lib.nvim usercmd helpers — owner not recorded
  :CmpReloadWords              via lib.nvim usercmd helpers — owner not recorded
  :ContextOpen                 via lib.nvim usercmd helpers — owner not recorded
  :DiagLoc                     via lib.nvim usercmd helpers — owner not recorded
  :DiagPrevLoc                 via lib.nvim usercmd helpers — owner not recorded
  :DiagPrevQF                  via lib.nvim usercmd helpers — owner not recorded
  :EslintFix                   via lib.nvim usercmd helpers — owner not recorded
  :FindConfig                  via lib.nvim usercmd helpers — owner not recorded
  :FindInFolder                via lib.nvim usercmd helpers — owner not recorded
  :FindOnSystem                via lib.nvim usercmd helpers — owner not recorded
  :GrepConfig                  via lib.nvim usercmd helpers — owner not recorded
  :LibAutocmdDocs              via lib.nvim usercmd helpers — owner not recorded
  :LibAutocmdDocsCheck         via lib.nvim usercmd helpers — owner not recorded
  :LibUsercmdDocs              via lib.nvim usercmd helpers — owner not recorded
  :LibUsercmdDocsCheck         via lib.nvim usercmd helpers — owner not recorded
  :LintAndFormat               via lib.nvim usercmd helpers — owner not recorded
  :LspRestartHere              via lib.nvim usercmd helpers — owner not recorded
  :LspStopHere                 via lib.nvim usercmd helpers — owner not recorded
  :LuaLsInspectLibrary         via lib.nvim usercmd helpers — owner not recorded
  :LuaLsReloadLibrary          via lib.nvim usercmd helpers — owner not recorded
  :LuaLsSetProfile             via lib.nvim usercmd helpers — owner not recorded
  :MdRebuildWords              via lib.nvim usercmd helpers — owner not recorded
  :MdSetRoot                   via lib.nvim usercmd helpers — owner not recorded
  :MdWordStats                 via lib.nvim usercmd helpers — owner not recorded
  :MyOptList                   via lib.nvim usercmd helpers — owner not recorded
  :MyOptSet                    via lib.nvim usercmd helpers — owner not recorded
  :MyOptShow                   via lib.nvim usercmd helpers — owner not recorded
  :MyPluginsDashboard          via lib.nvim usercmd helpers — owner not recorded
  :NotesFiles                  via lib.nvim usercmd helpers — owner not recorded
  :NotesGrep                   via lib.nvim usercmd helpers — owner not recorded
  :NotesLuaFiles               via lib.nvim usercmd helpers — owner not recorded
  :NotesLuaGrep                via lib.nvim usercmd helpers — owner not recorded
  :NotesLuaSmart               via lib.nvim usercmd helpers — owner not recorded
  :NotesNvimFiles              via lib.nvim usercmd helpers — owner not recorded
  :NotesNvimGrep               via lib.nvim usercmd helpers — owner not recorded
  :NotesNvimSmart              via lib.nvim usercmd helpers — owner not recorded
  :NotesSmart                  via lib.nvim usercmd helpers — owner not recorded
  :PrettierFormat              via lib.nvim usercmd helpers — owner not recorded
  :RARequest                   via lib.nvim usercmd helpers — owner not recorded
  :RASend                      via lib.nvim usercmd helpers — owner not recorded
  :RATelemetryResetAll         via lib.nvim usercmd helpers — owner not recorded
  :RATelemetrySetupAllFull     via lib.nvim usercmd helpers — owner not recorded
  :RATelemetryStopAll          via lib.nvim usercmd helpers — owner not recorded
  :RepoFiles                   via lib.nvim usercmd helpers — owner not recorded
  :RepoGrep                    via lib.nvim usercmd helpers — owner not recorded
  :SessionLoad                 via lib.nvim usercmd helpers — owner not recorded
  :SpickzettelFiles            via lib.nvim usercmd helpers — owner not recorded
  :SpickzettelGrep             via lib.nvim usercmd helpers — owner not recorded
  :SpickzettelSmart            via lib.nvim usercmd helpers — owner not recorded
  :SystemInfo                  via lib.nvim usercmd helpers — owner not recorded
  :ToggleInlineDiff            via lib.nvim usercmd helpers — owner not recorded
  :ToggleLintFormatOnSave      via lib.nvim usercmd helpers — owner not recorded
  :Tricentis                   via lib.nvim usercmd helpers — owner not recorded
  :TypeDefAttachNoiceKeys      via lib.nvim usercmd helpers — owner not recorded
  :TypeDefFindInNodeModules    via lib.nvim usercmd helpers — owner not recorded
  :TypeDefGoTo                 via lib.nvim usercmd helpers — owner not recorded
  :TypeDefPeek                 via lib.nvim usercmd helpers — owner not recorded
  :TypeDefPick                 via lib.nvim usercmd helpers — owner not recorded
  :WKDOptionsHLDebugCtx        via lib.nvim usercmd helpers — owner not recorded
  :WKDOptionsHLList            via lib.nvim usercmd helpers — owner not recorded
  :WKDOptionsHLSet             via lib.nvim usercmd helpers — owner not recorded
  :WKDOptionsHLShow            via lib.nvim usercmd helpers — owner not recorded
  :WkdBookFiles                via lib.nvim usercmd helpers — owner not recorded
  :WkdBookGrep                 via lib.nvim usercmd helpers — owner not recorded
  :WkdbooksFiles               via lib.nvim usercmd helpers — owner not recorded
  :WkdbooksGrep                via lib.nvim usercmd helpers — owner not recorded
  :WkdbooksLuaFiles            via lib.nvim usercmd helpers — owner not recorded
  :WkdbooksLuaGrep             via lib.nvim usercmd helpers — owner not recorded
  :WkdbooksLuaSmart            via lib.nvim usercmd helpers — owner not recorded
  :WkdbooksNvimFiles           via lib.nvim usercmd helpers — owner not recorded
  :WkdbooksNvimGrep            via lib.nvim usercmd helpers — owner not recorded
  :WkdbooksNvimSmart           via lib.nvim usercmd helpers — owner not recorded
  :WkdbooksSmart               via lib.nvim usercmd helpers — owner not recorded
  :TableModeToggle             vim-table-mode (lazy cmd stub)
  :Tableize                    vim-table-mode (lazy cmd stub)
  :StartupTime                 vimscript script_id=10
  :PlenaryBustedDirectory      vimscript script_id=11
  :PlenaryBustedFile           vimscript script_id=11
  :TodoFzfLua                  vimscript script_id=13
  :TodoLocList                 vimscript script_id=13
  :TodoQuickFix                vimscript script_id=13
  :TodoTelescope               vimscript script_id=13
  :TodoTrouble                 vimscript script_id=13
  :DoMatchParen                vimscript script_id=18
  :NoMatchParen                vimscript script_id=18
  :MatchupReload               vimscript script_id=20
  :MatchupWhereAmI             vimscript script_id=20
  :MatchupClearTimes           vimscript script_id=21
  :MatchupShowTimes            vimscript script_id=21
  :WhichKey                    which-key.nvim (lazy cmd stub)
  :ZenMode                     zen-mode.nvim (lazy cmd stub)

Keymaps — not verifiable from here (38 in 7 tables)
  -- not one key of these tables is live, globally or in any open buffer:
  -- a buffer-local scope whose UI is not open right now, not drift.
  -- Open it and re-run, or :Bindings check <plugin> to list them in full.
  github_stats.nvim      12 keys   ## Configurable bindings (`map_key()`, disable-able via `keybindings`)   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/github_stats.nvim.md:28
  github_stats.nvim       9 keys   ## Fixed bindings (direct `vim.keymap.set`, not configurable)   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/github_stats.nvim.md:45
  insights.nvim           2 keys   ## Imports report buffer (via `ui.scratch.open`)   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/insights.nvim.md:55
  lib.nvim                2 keys   ## `keymap.modifier` — run another mapping and capture its result   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/lib.nvim.md:73
  pickers.nvim            5 keys   ## 1. Base default keymaps   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:26
  pickers.nvim            4 keys   ## 3. `selected_index` overlay — Telescope engine only   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:85
  reposcope.nvim          4 keys   ## Close-UI keymaps (`M.set_close_ui_keymaps`, over background/preview/list/all-prompt buffers, tagged `"reposcope_ui"`)   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:45

Checked against their local checkout, not live (21): cascade.nvim, color_my_ascii.nvim, dap.nvim, debugging.nvim, diff.nvim, documentation.nvim, emojis.nvim, fileops.nvim, filetree.nvim, gopath.nvim, images.nvim, language.nvim, markdown.nvim, mdview.nvim, migrate.nvim, open.nvim, pdfport.nvim, recommender.nvim, replacer.nvim, sandbox.nvim, spotlight.nvim
```
