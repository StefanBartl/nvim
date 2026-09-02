# BINDINGS-Driftreport â 2026-09-02

## Table of content

  - [Intro](#intro)
  - [Lauf](#lauf)
  - [Die 266 auf einen Blick](#die-266-auf-einen-blick)
  - [1. Echte LÃ¼cke: 57 Commands stehen nirgends im Korpus](#1-echte-lcke-57-commands-stehen-nirgends-im-korpus)
  - [2. Der Befund hinter dem Befund: lib.nvim merkt sich den EigentÃ¼mer nicht](#2-der-befund-hinter-dem-befund-libnvim-merkt-sich-den-eigentmer-nicht)
  - [3. Werkzeugfehler: was der Scraper falsch liest](#3-werkzeugfehler-was-der-scraper-falsch-liest)
  - [4. Korrekte Befunde, die trotzdem kein Handlungsbedarf sind](#4-korrekte-befunde-die-trotzdem-kein-handlungsbedarf-sind)
  - [5. Was daraus folgt](#5-was-daraus-folgt)
  - [Anhang: der Bericht im Original](#anhang-der-bericht-im-original)

---

## Intro

Die Cheatsheets unter `docs/NOTES/` gegen die Bindings geprÃ¼ft, die eine echte
Instanz dieser Config tatsÃ¤chlich registriert. Punkt 4 aus
[TASKS-2026-09-02.md](./FINISH/ERLEDIGT/TASKS-2026-09-02.md).

**Zum Pfad aus dem Auftrag:** `docs/NOTES/BINDINGS` gibt es nicht. Der Korpus
sind zwei BÃ¤ume â `docs/NOTES/PersonelPlugins/BINDINGS/` und
`docs/NOTES/ExternPlugins/Bindings/`. Denselben Irrtum trÃ¤gt das alte
`:BindingsPath` (siehe den Moduldoc von `bindings_explorer/init.lua`).

---

## Lauf

```
nvim --headless -c "lua require('bindings.usrcmds.bindings_explorer.drift')
                      .check(nil, { repo = true })"
```

Entspricht `:Bindings check repo`, also allen vier Achsen. `repo` ist bewusst
opt-in und hier zwingend: ohne sie winkt `is_plugin_loaded` alles durch, was
lazy noch nicht geladen hat â in diesem Lauf 27 von rund 60 Plugins.

| | |
| --- | --- |
| Neovim | 0.12.2 |
| Config-Stand | `d1d642e0` |
| Laufzeit der PrÃ¼fung | 677 ms |
| Geladene Plugins in der Session | 27 |
| Repo-Achse: aufgelÃ¶ste Checkouts | 32 |
| davon beantwortet | 21 |
| **Ãbersprungen (gar nicht geprÃ¼ft)** | **0** |
| Befunde | 266 |

Null Ãbersprungene ist das eigentliche QualitÃ¤tsmerkmal des Laufs: jede
dokumentierte Bindung wurde von mindestens einer Achse angefasst.

---

## Die 266 auf einen Blick

| Befundart | n | Was es Ã¼berwiegend ist |
| --- | ---: | --- |
| `usercmd-undocumented` | 166 | live, aber im Korpus nicht als Tabellenzeile |
| `keymap-not-live` | 88 | dokumentiert, in dieser Session nicht gebunden |
| `keymap-not-in-repo` | 7 | bekannte Falschbefunde der Grep-Achse |
| `usercmd-not-live` | 5 | drei Parserfehler, zwei âlazy nicht ausgelÃ¶st" |

Die 88 `keymap-not-live` erscheinen im Bericht als 50 Einzelzeilen plus 38
SchlÃ¼ssel in 7 Tabellen, die als Block gemeldet werden (ânicht von hier aus
prÃ¼fbar").

**266 Befunde sind nicht 266 Probleme.** Aufgeteilt nach dem, was zu tun wÃ¤re:

| | n |
| --- | ---: |
| Echte Doku-LÃ¼cke, sollte nachgetragen werden | **57** |
| Werkzeugfehler (Scraper/Matcher), sollte gefixt werden | ~45 |
| Erwartbar und korrekt (Fremdinfra, buffer-lokale UIs, lazy) | ~164 |

---

## 1. Echte LÃ¼cke: 57 Commands stehen nirgends im Korpus

Der grÃ¶Ãte Einzelposten des Berichts ist die Zeile *â88 live commands, origin:
via lib.nvim usercmd helpers â owner not recorded"*. Von diesen 88 habe ich
jedes einzeln gegen beide BÃ¤ume gegrept â auch gegen FlieÃtext, nicht nur
gegen Tabellen:

* **31** kommen im Korpus vor, aber **nur im FlieÃtext**. Der Scraper liest
  Tabellenzeilen, also zÃ¤hlen sie als undokumentiert. Das ist ein
  Werkzeugfehler, siehe Abschnitt 3.
* **57** kommen **Ã¼berhaupt nicht** vor. Das ist die echte Drift.

Und sie ist nicht gestreut, sie hat drei Ursachen:

**23 â von pickers.nvim erzeugte Scope-Familien.**
`:NotesFiles`/`:NotesGrep`/`:NotesSmart`, dasselbe fÃ¼r `Wkdbooks`,
`WkdbooksLua`, `WkdbooksNvim`, `NotesLua`, `NotesNvim`, `Spickzettel`,
`Checklists`. Die entstehen aus einer Scope-Liste in der Config, nicht aus
handgeschriebenem Code. Sie einzeln in ein Cheatsheet zu schreiben wÃ¤re genau
die handgefÃ¼hrte Liste, die Ã¼berall sonst in diesem Repo als Fehlerquelle
gilt â **das Cheatsheet sollte den Generator dokumentieren, nicht seine
Ergebnisse**, und `:Bindings check` sollte eine so beschriebene Familie als
abgedeckt akzeptieren.

**21 â lsp.nvims serverspezifische Commands.**
`:Astro*` (8), `:TypeDef*` (5), `:LuaLs*` (3), `:MdRebuildWords`/`:MdSetRoot`/
`:MdWordStats`, `:PrettierFormat`, `:LintAndFormat`, `:CmpReloadWords`.
`Usercmds/lsp.nvim.md` fÃ¼hrt `:Lsp`, `:LspDoctor` und die Legacy-Aliase, aber
nicht die filetype-gebundenen â obwohl dieselbe Datei in Zeile 170 erklÃ¤rt,
*warum* sie eigene Namen behalten. Der Grund steht da, die Liste nicht.

**7 â Commands dieser Config selbst.** `:MyOptList`/`:MyOptSet`/`:MyOptShow`
und `:WKDOptionsHLDebugCtx`/`HLList`/`HLSet`/`HLShow`. Kein Plugin, also auch
kein Cheatsheet-EigentÃ¼mer â der Korpus ist nach Plugins geschnitten und hat
fÃ¼r die Config selbst keinen Platz. Das ist eine LÃ¼cke im Aufbau des Korpus,
nicht im FleiÃ.

**Rest (6):** `:ContextOpen`, `:LibAutocmdDocsCheck`, `:LibUsercmdDocsCheck`,
`:SystemInfo`, `:ToggleInlineDiff`, `:ToggleLintFormatOnSave`. Die beiden
`*Check`-Varianten sind besonders bezeichnend: ihre Basisformen
(`:LibAutocmdDocs`, `:LibUsercmdDocs`) **stehen** im Korpus, die
`Check`-Zwillinge nicht.

---

## 2. Der Befund hinter dem Befund: lib.nvim merkt sich den EigentÃ¼mer nicht

Alle 88 tragen dieselbe Herkunftsangabe: *âvia lib.nvim usercmd helpers â
owner not recorded"*. Die Registry, durch die diese Config und ihre Plugins
ihre Commands anlegen, hÃ¤lt nicht fest, wer registriert hat.

Damit kann `:Bindings check` einen undokumentierten Command eines eigenen
Plugins nicht von einem undokumentierten Fremd-Command unterscheiden, und der
Bericht muss beide in denselben Topf werfen. Genau deshalb steht unter der
Ãberschrift die entschuldigende Note *âmostly third-party infra this corpus
never covered"* â die stimmt fÃ¼r die anderen 78, und fÃ¼r diese 88 ist sie
falsch: es sind fast ausschlieÃlich eigene.

**Ein Feld in lib.nvims Usercmd-Registry wÃ¤re die wirksamste EinzelmaÃnahme
dieses ganzen Berichts.** Es wÃ¼rde 88 Zeilen nach EigentÃ¼mer aufteilen, den
Abschnitt nach âeigene" und âfremde" trennen, und die PrÃ¼fung kÃ¶nnte auf die
eigenen zuspitzen. Verwandt mit dem bereits bekannten Fund `:RATelemetry`
(steht in `Usercmds/lib.nvim.md`, registriert wird es von
runtime-analysis.nvim) â dieselbe fehlende Zuordnung, andere Richtung.

**Nachtrag, noch am 2026-09-02 â erledigt, und der Befund war zur HÃ¤lfte
falsch.** Die Registry hÃ¤lt den Aufrufort sehr wohl fest:
`Lib.UserCommand.Record.src`, gesetzt aus `caller_site(3)`. Was fehlte, war
etwas Kleineres und Konkreteres:

* `:Bindings check` hat die Registry nie gefragt. Es las
  `debug.getinfo(def.callback)` â und das ist die pcall-HÃ¼lle, die
  `usercmd.create` baut, also lib.nvim, fÃ¼r *jedes* so angelegte Command.
* `composer.verb` hat `create`s `src`-Option nie durchgereicht, also lagen
  alle zwÃ¶lf Verben der Session auf einer Zeile von `composer/init.lua`.

Beides behoben (lib.nvim `bfa09e5`, nvim-config im Commit unter diesem
Nachtrag). Gemessen: 136 von 139 Registry-EintrÃ¤gen nennen jetzt einen echten
EigentÃ¼mer, und die 109 undokumentierten Live-Commands teilen sich in **53
eigene mit `file:line` und 56 fremde**. Die drei verbleibenden
lib.nvim-EintrÃ¤ge (`:KitPreview`, `:Lib`, `:SystemInfo`) sind lib.nvims eigene
Commands, also richtig zugeordnet. Die entschuldigende Note unter der
Ãberschrift im Anhang ist ersetzt: sie sagt jetzt, wie die Spalte zu lesen
ist, statt zu raten, was in ihr steht.

---

## 3. Werkzeugfehler: was der Scraper falsch liest

Vier Klassen, alle im selben Modul (`bindings_explorer/records.lua`):

**a) Platzhalter in der Key-Spalte werden als Taste gelesen.**
`Keymaps/lib.nvim.md:34` hat `â` in der Key-Spalte (Bedeutung: *keine* Taste,
das Feature ist aus), `Keymaps/buffer-ctx.md:26` hat `*(unset)*`, dieselbe
Datei `*(your lhs)*`. Alle drei landen als âdokumentierte Taste, nicht live".

**b) Commandnamen aus dem FlieÃtext einer Zelle.**
`Usercmds/buffer-ctx.md:32` beschreibt den `location`-Subcommand, und im
Beispieltext steht `path:L1-L2`. Gemeldet wird ein fehlender Command `:L1`.

**c) Meta-Dateien werden wie Plugin-Cheatsheets behandelt.**
`Collisions.md` (11 Befunde) dokumentiert *Kollisionen*, `Overview.md` (3)
ist eine Zusammenfassung. Beide haben Tabellen, deren Zellen Tastennamen und
Commandnamen enthalten â aber keine davon ist eine Bindung, die irgendwer
registriert. 14 Befunde aus zwei Dateien, die gar keine Plugins sind.

**d) Nur Tabellenzeilen zÃ¤hlen.** Die 31 aus Abschnitt 1: dokumentiert, aber
im FlieÃtext. `:LuaLsReloadLibrary` etwa steht in `Usercmds/lsp.nvim.md:170`,
`:AllDrives`/`:RepoGrep` in `Usercmds/pickers.nvim.md:39-40` als
AufzÃ¤hlung mit `Â·` statt als Tabelle.

Dazu der schon bekannte Defekt: `split_cells` zerlegt escapte Pipes, eine
Zelle mit `\|` wird an genau dieser Stelle getrennt.

---

## 4. Korrekte Befunde, die trotzdem kein Handlungsbedarf sind

**50 + 38 `keymap-not-live`** â fast alle sind buffer-lokale Tasten einer UI,
die in einer headless-Session nicht offen ist: reposcope.nvim (17),
cmdlog.nvim (9), pickers.nvim (8), github_stats.nvim (2). Der Bericht sagt
das selbst und bietet den nÃ¤chsten Schritt an (âOpen it and re-run"). Die 38
in 7 Tabellen sind derselbe Fall, nur dass *keine* Taste der Tabelle live war
â der Melder fasst sie deshalb richtigerweise zur Tabelle zusammen statt 38
Einzelzeilen zu erzeugen.

**7 `keymap-not-in-repo`** â alle sieben sind debugging.nvims `prefix .. "m"`,
der dokumentierte Falschbefund einer Grep-Achse: ein `lhs`, den das Plugin zur
Laufzeit zusammensetzt, steht als Literal nirgends im Quelltext. Bekannt seit
dem Bau der Achse, unverÃ¤ndert.

**~78 der `usercmd-undocumented`** â Fremdinfrastruktur, die dieser Korpus nie
abgedeckt hat: `:Gitsigns`, `:Lazy`, `:Mason*`, `:Noice*`, `:Diffview*`,
Neovims eigene `:Inspect`/`:Man`, Vimscript-Plugins. Korrekt gemeldet und
korrekt zu ignorieren.

**2 `usercmd-not-live` sind âlazy, Trigger nicht ausgelÃ¶st":**
`:LibLogger` dokumentiert selbst âregistriert automatisch beim ersten
`logger.new()`", und `:Markdown` wird erst mit dem ersten Markdown-Buffer
angelegt. Die Bedingung steht im Cheatsheet (Spalte *âRegistered when"*), der
PrÃ¼fer kann sie nur nicht lesen.

---

## 5. Was daraus folgt

Nach Wirkung sortiert:

1. **lib.nvims Usercmd-Registry merkt sich den EigentÃ¼mer.** Ordnet 88 der 166
   zu und macht den grÃ¶Ãten Abschnitt des Berichts erst auswertbar.
2. **`records.lua` reparieren** â Platzhalterzellen, Commandnamen aus Prosa,
   escapte Pipes, und Meta-Dateien (`Collisions.md`, `Overview.md`) aus dem
   Plugin-Korpus nehmen. RÃ¤umt rund 45 Befunde ab. GehÃ¶rt zu Punkt 7 des
   Aufgabenblocks.
3. **Die 21 serverspezifischen lsp.nvim-Commands nachtragen.** Kleinste echte
   Arbeit mit dem grÃ¶Ãten Ehrlichkeitsgewinn; die BegrÃ¼ndung steht schon in
   der Datei.
4. **FÃ¼r die 23 generierten Scope-Commands den Generator dokumentieren**, und
   `:Bindings check` beibringen, eine Familie als abgedeckt zu akzeptieren.
   Eine handgefÃ¼hrte Liste wÃ¤re hier die falsche Antwort.
5. **Einen Ort fÃ¼r die Commands der Config selbst schaffen** (`:MyOpt*`,
   `:WKDOptions*`) â der Korpus ist nach Plugins geschnitten und hat fÃ¼r sie
   heute keinen.
6. **Prosa-Dokumentation als gÃ¼ltig anerkennen** oder die 31 FÃ¤lle in
   Tabellen Ã¼berfÃ¼hren. Eine der beiden, nicht keine.

---

## Anhang: der Bericht im Original

UnverÃ¤ndert die Ausgabe von `drift.describe`, wie sie `:Bindings check repo`
in den Viewer schreibt.

```text
Usercmds â documented, not registered (5)
  -- highest-signal axis; a documented-lazy command may need its feature exercised first
  buffer-ctx             :L1                  docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/buffer-ctx.md:32
  lib.nvim               :LibLogger           docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/lib.nvim.md:151
  Overview               :Markdown            docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/Overview.md:28
  Overview               :File                docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/Overview.md:64
  Overview               :Debug               docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/Overview.md:133

Keymaps â documented, not registered (50)
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
  lib.nvim               Ã¢Â                docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/lib.nvim.md:34
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
  :AllDrives                   via lib.nvim usercmd helpers â owner not recorded
  :AllDrivesGrep               via lib.nvim usercmd helpers â owner not recorded
  :AstroBuild                  via lib.nvim usercmd helpers â owner not recorded
  :AstroCheckStructure         via lib.nvim usercmd helpers â owner not recorded
  :AstroDevStart               via lib.nvim usercmd helpers â owner not recorded
  :AstroDevStop                via lib.nvim usercmd helpers â owner not recorded
  :AstroFindUsage              via lib.nvim usercmd helpers â owner not recorded
  :AstroListComponents         via lib.nvim usercmd helpers â owner not recorded
  :AstroNewComponent           via lib.nvim usercmd helpers â owner not recorded
  :AstroNewPage                via lib.nvim usercmd helpers â owner not recorded
  :AstroPreview                via lib.nvim usercmd helpers â owner not recorded
  :Case                        via lib.nvim usercmd helpers â owner not recorded
  :Cases                       via lib.nvim usercmd helpers â owner not recorded
  :ChecklistsFiles             via lib.nvim usercmd helpers â owner not recorded
  :ChecklistsGrep              via lib.nvim usercmd helpers â owner not recorded
  :ChecklistsSmart             via lib.nvim usercmd helpers â owner not recorded
  :CmpReloadWords              via lib.nvim usercmd helpers â owner not recorded
  :ContextOpen                 via lib.nvim usercmd helpers â owner not recorded
  :DiagLoc                     via lib.nvim usercmd helpers â owner not recorded
  :DiagPrevLoc                 via lib.nvim usercmd helpers â owner not recorded
  :DiagPrevQF                  via lib.nvim usercmd helpers â owner not recorded
  :EslintFix                   via lib.nvim usercmd helpers â owner not recorded
  :FindConfig                  via lib.nvim usercmd helpers â owner not recorded
  :FindInFolder                via lib.nvim usercmd helpers â owner not recorded
  :FindOnSystem                via lib.nvim usercmd helpers â owner not recorded
  :GrepConfig                  via lib.nvim usercmd helpers â owner not recorded
  :LibAutocmdDocs              via lib.nvim usercmd helpers â owner not recorded
  :LibAutocmdDocsCheck         via lib.nvim usercmd helpers â owner not recorded
  :LibUsercmdDocs              via lib.nvim usercmd helpers â owner not recorded
  :LibUsercmdDocsCheck         via lib.nvim usercmd helpers â owner not recorded
  :LintAndFormat               via lib.nvim usercmd helpers â owner not recorded
  :LspRestartHere              via lib.nvim usercmd helpers â owner not recorded
  :LspStopHere                 via lib.nvim usercmd helpers â owner not recorded
  :LuaLsInspectLibrary         via lib.nvim usercmd helpers â owner not recorded
  :LuaLsReloadLibrary          via lib.nvim usercmd helpers â owner not recorded
  :LuaLsSetProfile             via lib.nvim usercmd helpers â owner not recorded
  :MdRebuildWords              via lib.nvim usercmd helpers â owner not recorded
  :MdSetRoot                   via lib.nvim usercmd helpers â owner not recorded
  :MdWordStats                 via lib.nvim usercmd helpers â owner not recorded
  :MyOptList                   via lib.nvim usercmd helpers â owner not recorded
  :MyOptSet                    via lib.nvim usercmd helpers â owner not recorded
  :MyOptShow                   via lib.nvim usercmd helpers â owner not recorded
  :MyPluginsDashboard          via lib.nvim usercmd helpers â owner not recorded
  :NotesFiles                  via lib.nvim usercmd helpers â owner not recorded
  :NotesGrep                   via lib.nvim usercmd helpers â owner not recorded
  :NotesLuaFiles               via lib.nvim usercmd helpers â owner not recorded
  :NotesLuaGrep                via lib.nvim usercmd helpers â owner not recorded
  :NotesLuaSmart               via lib.nvim usercmd helpers â owner not recorded
  :NotesNvimFiles              via lib.nvim usercmd helpers â owner not recorded
  :NotesNvimGrep               via lib.nvim usercmd helpers â owner not recorded
  :NotesNvimSmart              via lib.nvim usercmd helpers â owner not recorded
  :NotesSmart                  via lib.nvim usercmd helpers â owner not recorded
  :PrettierFormat              via lib.nvim usercmd helpers â owner not recorded
  :RARequest                   via lib.nvim usercmd helpers â owner not recorded
  :RASend                      via lib.nvim usercmd helpers â owner not recorded
  :RATelemetryResetAll         via lib.nvim usercmd helpers â owner not recorded
  :RATelemetrySetupAllFull     via lib.nvim usercmd helpers â owner not recorded
  :RATelemetryStopAll          via lib.nvim usercmd helpers â owner not recorded
  :RepoFiles                   via lib.nvim usercmd helpers â owner not recorded
  :RepoGrep                    via lib.nvim usercmd helpers â owner not recorded
  :SessionLoad                 via lib.nvim usercmd helpers â owner not recorded
  :SpickzettelFiles            via lib.nvim usercmd helpers â owner not recorded
  :SpickzettelGrep             via lib.nvim usercmd helpers â owner not recorded
  :SpickzettelSmart            via lib.nvim usercmd helpers â owner not recorded
  :SystemInfo                  via lib.nvim usercmd helpers â owner not recorded
  :ToggleInlineDiff            via lib.nvim usercmd helpers â owner not recorded
  :ToggleLintFormatOnSave      via lib.nvim usercmd helpers â owner not recorded
  :Tricentis                   via lib.nvim usercmd helpers â owner not recorded
  :TypeDefAttachNoiceKeys      via lib.nvim usercmd helpers â owner not recorded
  :TypeDefFindInNodeModules    via lib.nvim usercmd helpers â owner not recorded
  :TypeDefGoTo                 via lib.nvim usercmd helpers â owner not recorded
  :TypeDefPeek                 via lib.nvim usercmd helpers â owner not recorded
  :TypeDefPick                 via lib.nvim usercmd helpers â owner not recorded
  :WKDOptionsHLDebugCtx        via lib.nvim usercmd helpers â owner not recorded
  :WKDOptionsHLList            via lib.nvim usercmd helpers â owner not recorded
  :WKDOptionsHLSet             via lib.nvim usercmd helpers â owner not recorded
  :WKDOptionsHLShow            via lib.nvim usercmd helpers â owner not recorded
  :WkdBookFiles                via lib.nvim usercmd helpers â owner not recorded
  :WkdBookGrep                 via lib.nvim usercmd helpers â owner not recorded
  :WkdbooksFiles               via lib.nvim usercmd helpers â owner not recorded
  :WkdbooksGrep                via lib.nvim usercmd helpers â owner not recorded
  :WkdbooksLuaFiles            via lib.nvim usercmd helpers â owner not recorded
  :WkdbooksLuaGrep             via lib.nvim usercmd helpers â owner not recorded
  :WkdbooksLuaSmart            via lib.nvim usercmd helpers â owner not recorded
  :WkdbooksNvimFiles           via lib.nvim usercmd helpers â owner not recorded
  :WkdbooksNvimGrep            via lib.nvim usercmd helpers â owner not recorded
  :WkdbooksNvimSmart           via lib.nvim usercmd helpers â owner not recorded
  :WkdbooksSmart               via lib.nvim usercmd helpers â owner not recorded
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

Keymaps â not verifiable from here (38 in 7 tables)
  -- not one key of these tables is live, globally or in any open buffer:
  -- a buffer-local scope whose UI is not open right now, not drift.
  -- Open it and re-run, or :Bindings check <plugin> to list them in full.
  github_stats.nvim      12 keys   ## Configurable bindings (`map_key()`, disable-able via `keybindings`)   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/github_stats.nvim.md:28
  github_stats.nvim       9 keys   ## Fixed bindings (direct `vim.keymap.set`, not configurable)   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/github_stats.nvim.md:45
  insights.nvim           2 keys   ## Imports report buffer (via `ui.scratch.open`)   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/insights.nvim.md:55
  lib.nvim                2 keys   ## `keymap.modifier` â run another mapping and capture its result   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/lib.nvim.md:73
  pickers.nvim            5 keys   ## 1. Base default keymaps   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:26
  pickers.nvim            4 keys   ## 3. `selected_index` overlay â Telescope engine only   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md:85
  reposcope.nvim          4 keys   ## Close-UI keymaps (`M.set_close_ui_keymaps`, over background/preview/list/all-prompt buffers, tagged `"reposcope_ui"`)   docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/reposcope.nvim.md:45

Checked against their local checkout, not live (21): cascade.nvim, color_my_ascii.nvim, dap.nvim, debugging.nvim, diff.nvim, documentation.nvim, emojis.nvim, fileops.nvim, filetree.nvim, gopath.nvim, images.nvim, language.nvim, markdown.nvim, mdview.nvim, migrate.nvim, open.nvim, pdfport.nvim, recommender.nvim, replacer.nvim, sandbox.nvim, spotlight.nvim
```

---

