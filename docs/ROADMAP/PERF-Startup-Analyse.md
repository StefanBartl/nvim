# Startup- und Hänger-Analyse

Stand: 2026-08-22. Untersucht wurde ein reproduzierbares Symptom: Cursor ist
sofort da, dann friert Neovim ~0,5 s später für 1–3 s ein („zweite
Verzögerung"). Subjektiv schlimmer, wenn beim Start eine Datei mitgeöffnet wird.

Alle Zahlen unten sind gemessen, nicht geschätzt. Die Messwerkzeuge liegen in
[`perf-tools/`](./perf-tools) und sind gegen künstlich erzeugte Blockaden
gegengetestet.

---

## Ergebnis in einem Satz

**Gefunden: `workspace-diagnostics.nvim`**, aufgerufen aus
[`lsp/core/attach.lua:58`](../../lua/lsp/core/attach.lua) beim `LspAttach` von
lua_ls. Es lädt per `git ls-files` **jede Datei des Repos** in Puffer, um
Workspace-Diagnostics zu befüllen — synchron auf dem Main-Loop. Das ist der
300–420-ms-Hänger **und** die Quelle der „Diagnosing workspace 1729".

Der Schalter existiert bereits: `:LspWorkspaceDiagnosticsOff` (live) bzw. der
Startup-Default in [`lsp/init.lua:62`](../../lua/lsp/init.lua)
(`use_workspace_diagnostics = not machine.is("workstation")`) — auf dieser
Maschine also **an**.

> Die Modul-Doku von
> [`lsp/core/workspace_diagnostics.lua`](../../lua/lsp/core/workspace_diagnostics.lua)
> beschreibt genau diesen Fehlerfall bereits, inklusive eines früheren
> 60–90-s-Freezes in einem ~600-Dateien-Repo. Der Toggle wurde damals dafür
> gebaut. Hier schlägt derselbe Mechanismus in kleinerer Dosis zu.

**Umgesetzt (2026-08-22).** Statt den Toggle umzulegen wurde die Ursache
behandelt — siehe [Umsetzung](#umsetzung-2026-08-22) unten. Kurz: der Populate
läuft nicht mehr synchron im Attach, ohne `git`-Subprozesse, auf einer
gefilterten Dateiliste (522 statt 1729) und hinter einem Größen-Gate.

> **Noch nicht gegengemessen.** Der Nachweis, dass der spürbare Hänger weg ist,
> steht aus: er braucht einen interaktiven Lauf mit `stall.lua`. Headless ist
> dafür untauglich — zwei Kontrollläufe (Workspace-Diagnostics an vs. aus)
> lieferten 3559 ms und 3729 ms Gesamtblockade, also *mehr* Blockade im
> abgeschalteten Lauf. Das Rauschen übersteigt den Effekt.

---

## Was ausgeschlossen ist

| Verdacht | Status | Beleg |
|---|---|---|
| gopath.nvim / dessen FS-Cache | **ausgeschlossen** | kommt in `--startuptime` 0× vor; mit gestubbtem gopath ist der Stall unverändert da (+4,69 s / 311 ms) |
| JSON-Parsing des gopath-Caches | **ausgeschlossen** | gemessen: decode 6 ms, encode 5 ms, kompletter Load 23 ms |
| Synchroner FS-Walk in gopath | **ausgeschlossen** | der Walk ist `uv.fs_scandir` mit Callback, bounded concurrency 16 |
| Größe der lua_ls `workspace.library` | **ausgeschlossen** | mit `LUA_LS_PROFILE=minimal` ist der Stall unverändert (+2,57 s / **418 ms**), „Loading workspace 0/131" identisch |
| lua_ls Diagnostics-Flut | **ausgeschlossen** als Ursache *dieses* Stalls | „Diagnosing workspace 17/1729" beginnt erst bei +10,58 s, der Stall liegt bei +2,4…2,6 s |
| `vim.lsp.handlers` / `vim.diagnostic.set` | **ausgeschlossen** | 36 Wrapper aktiv, keine einzige Zeile über 30 ms |

## Was bewiesen ist

**Es ist lua_ls.** Kontrollierter A/B mit identischem Ablauf:

| Lauf | später Stall | subjektiv |
|---|---|---|
| Baseline | +5,20 s / 331 ms | spürbar |
| ohne LSP (`vim.lsp.start` gestubbt) | **keiner** | **nicht spürbar** |
| ohne gopath | +4,69 s / 311 ms | spürbar |
| nur lua_ls gestubbt | **keiner** | **nicht spürbar** |
| `LUA_LS_PROFILE=minimal` | +2,57 s / 418 ms | spürbar |

Der Stall liegt konsistent **nach `LspAttach`** und **vor lua_ls' erster
Fortschrittsmeldung** — also im Fenster, in dem der Client die ersten
Server-Antworten verarbeitet.

Typische Zeitachse (Lauf mit `minimal`):

```
+0,98 s  lsp.start   lua_ls (13 ms)      ← zweimal aufgerufen, 2. ist Reuse (0 ms)
+1,38 s  STALL       321 ms
+1,52 s  LspAttach   lua_ls -> buf 1
+2,57 s  STALL       418 ms              ← der spürbare Hänger
+4,28 s  progress    begin: Initializing...
+6,13 s  progress    begin: Loading workspace — 0/131
+8,81 s  progress    end:   Loading workspace
+10,1 s  progress    begin: Processing file symbols...
```

Auffällig nebenbei: zwischen `lsp.start` (+0,98 s) und `LspAttach` (+1,52 s)
liegen 0,5 s, und bis „Initializing" vergehen weitere 2,8 s.

---

## Der Beweis

Stack-Sampling (`luaprof.lua`) liefert genau einen Eintrag, der im
LSP-Attach-Pfad wurzelt — Eintrag [10], 60 Samples ≈ 120 ms:

```
vim/_core/shared.lua:286
workspace-diagnostics.nvim/lua/workspace-diagnostics/init.lua:43
workspace-diagnostics.nvim/lua/workspace-diagnostics/init.lua:92
workspace-diagnostics.nvim/lua/workspace-diagnostics/init.lua:149
[builtin#20]
nvim/lua/lsp/core/attach.lua:58            ← pcall(wd.populate_workspace_diagnostics, …)
nvim/lua/lsp/servers/lua_ls/init.lua:52
[builtin#20]
vim/lsp/client.lua:515
vim/lsp/client.lua:1158                    ← LSP-Attach
```

Das passt lückenlos zu allen bisherigen Beobachtungen:

- **Warum ohne LSP kein Stall?** Kein Attach → kein `populate`.
- **Warum hat `LUA_LS_PROFILE=minimal` nichts gebracht?** Die Library-Größe ist
  irrelevant; das Plugin zählt *Projektdateien* per `git ls-files` selbst auf.
- **Warum haben die Handler-Wrapper nichts gefunden?** Der Code läuft im
  Attach-Callback, nicht in einem Response-Handler.
- **Warum 1729 diagnostizierte Dateien?** Das ist nicht lua_ls' Eigeninitiative
  — dieses Plugin fordert es explizit an.

Die Sample-Zahl (120 ms) liegt unter dem gemessenen Stall (300–420 ms), weil
der Sampler nur Lua-Frames sieht; das Öffnen der Puffer und die
`textDocument/didOpen`-Runden dazu passieren in C bzw. verteilt. Die
Zuordnung ist dadurch nicht schwächer — es ist der einzige Attach-verwurzelte
Stack überhaupt.

---

## Dauerlast: die 1729 Dateien

Gleiche Ursache — `workspace-diagnostics.nvim` fordert die Diagnose aller
Projektdateien an. Mit `:LspWorkspaceDiagnosticsOff` sollte auch das entfallen.

Falls Workspace-Diagnostics gewünscht bleibt, gilt für die Erwartungshaltung —
zwei naheliegende Annahmen stimmen nicht:

- **Markdown/Docs ignorieren bringt für die 1729 nichts.** lua_ls
  diagnostiziert ohnehin nur `.lua`. Ignorieren reduziert den
  Verzeichnis-Scan („Loading workspace"), nicht die Diagnose-Zahl.
- **`lua/plugins/github-stats` enthält 0 `.lua`-Dateien.** Die 2049 Files
  kosten also ebenfalls nur Scan, nicht Diagnose. Trotzdem sinnvoll zu
  ignorieren — 2049 Einträge Verzeichnis-Walk sind nicht gratis.

Die 1729 kommen aus den **eigenen 2606 Lua-Dateien** der Config. Wer die
Diagnose-Last senken will, braucht daher einen anderen Schalter als
`ignoreDir`:

- `Lua.diagnostics.workspaceDelay` hochsetzen oder
  `Lua.diagnostics.workspaceRate` drosseln
- Workspace-Diagnostics ganz aus und nur offene Puffer prüfen
- oder Teile der Config aus dem Workspace nehmen

Vorhandene Hebel: [`.luarc.json`](../../.luarc.json) und
[`lua/lsp/servers/lua_ls/ignore.lua`](../../lua/lsp/servers/lua_ls/ignore.lua)
(baut auf `lib.nvim.fs.ignore.list`, exportiert `as_luals_patterns()` für
`Lua.workspace.ignoreDir`) — der Mechanismus existiert also schon, es fehlen
nur Einträge.

---

## Weitere Fundstellen aus dem Sampling

Der Sampler aggregiert über 12 s, diese Posten sind also **nicht** dem akuten
Hänger zuzuordnen — aber sie sind die benannten Verursacher des frühen
Clusters und der allgemeinen Zähigkeit. Aus `luaprof.log`:

| Samples | ≈ ms | Stelle |
|---|---|---|
| 350 + 312 + 275 | ~1870 | `lazy/manage/git.lua:149/161/192` → `process.lua` — lazy.nvim spawnt Git-Prozesse. Läuft der Update-Checker beim Start? |
| 253 | ~506 | `which-key.nvim/lua/which-key/state.lua:158` |
| 173 | ~346 | `vim/_core/editor.lua:630` |
| 140 | ~280 | `vim/_core/system.lua:244` — Prozess-Spawns |
| 107 | ~214 | `lspsaga.nvim/lua/lspsaga/codeaction/lightbulb.lua:134` — läuft auf Cursor-Bewegung |
| 67 | ~134 | `lspsaga/symbol/winbar.lua:248` → `lspsaga/util.lua:252` → `vim/version.lua:512` — `vim.version` im Hot-Path |
| 54 | ~108 | `nvim-treesitter-context/lua/treesitter-context.lua:45` |

Der Spitzenreiter (581 Samples, `vim/_core/editor.lua:523`) ist ohne
Aufrufer-Frames und dürfte die Timer-/Scheduler-Maschinerie selbst sein — als
Einzelposten nicht verwertbar.

Die drei größten davon (lazy-Git, which-key, lspsaga) sind eigenständige
Baustellen und gehören in
[TASK-Startup-Blockaden.md](./TASK-Startup-Blockaden.md).

## Methodik

`nvim --startuptime` endet beim ersten Screen-Update (hier ~828 ms) und sieht
den Hänger deshalb gar nicht. `:profile` erfasst nur Vimscript-/Lua-Aufrufe und
ist blind für libuv-Callbacks — also genau für das, worin
Dateisystem-Operationen und LSP-Verarbeitung laufen.

Stattdessen drei eigene Werkzeuge in [`perf-tools/`](./perf-tools):

| Werkzeug | Prinzip | wofür |
|---|---|---|
| `stall.lua` | Timer misst seine **eigene Verspätung** | findet *jede* Main-Loop-Blockade, egal woher |
| `lspprof.lua` | wrappt `vim.lsp.handlers`, `vim.diagnostic.set`, loggt `lsp.start`/`LspAttach`/`LspProgress` | ordnet Stalls LSP-Ereignissen zu |
| `luaprof.lua` | LuaJIT-Stack-Sampling (`jit.profile`) | benennt die blockierende `datei:zeile` |

Alle drei wurden gegen künstlich erzeugte Blockaden gegengetestet (600 ms bzw.
400 ms) und melden diese korrekt.

Nützliche Isolierungen ohne Config-Änderung:

```powershell
# ohne LSP
nvim --cmd "lua vim.lsp.start=function() end; vim.lsp.enable=function() end" <datei>

# ohne ein bestimmtes Plugin (Beispiel gopath)
nvim --cmd "lua package.preload['gopath']=function() return {setup=function() end} end" <datei>

# nur einen LSP-Server aussparen (lspprof.lua)
nvim --cmd "lua vim.g.lspprof_skip='lua_ls'" --cmd "luafile .../lspprof.lua" <datei>
```

Eine Falle, die einmal zugeschlagen hat: die erste Version von `lspprof.lua`
installierte ihre Wrapper per `vim.defer_fn(1200)`. Auf einem ausgelasteten
Loop kam dieser Callback erst bei +4,57 s dran — **nach** dem Stall, den er
erklären sollte. Deferred Instrumentierung taugt nicht zum Messen von
Blockaden. v2 wrappt deshalb sofort, bei jedem `LspAttach` und per
Wiederhol-Timer, idempotent.

---

## Nebenbefunde

- **`lsp.start lua_ls` wird zweimal aufgerufen.** Der zweite Aufruf kehrt in
  0 ms zurück (Reuse), kostet also nichts — aber zwei Codepfade triggern den
  Start. Wert, sich anzusehen.
- **`provider/clipboard.vim` kostet 28 ms** beim Start: Neovim probt
  Clipboard-Tools per Prozess-Spawn. Entfällt vollständig, wenn
  `vim.g.clipboard` explizit gesetzt ist.
- **Der frühe Blockade-Cluster (+0,1…1,4 s, 600–800 ms)** ist in *allen*
  Läufen da, unabhängig von LSP und gopath. Eigener Task:
  [TASK-Startup-Blockaden.md](./TASK-Startup-Blockaden.md).

## Umsetzung (2026-08-22)

### workspace-diagnostics: drei Kostentreiber, nicht einer

Beim Lesen des Plugin-Codes zeigte sich, dass `populate_workspace_diagnostics`
auf drei getrennten Wegen teuer ist — alle auf dem Main-Loop, alle im
`on_attach`:

1. zwei synchrone `vim.fn.system`-Aufrufe (`git rev-parse --show-toplevel` und
   `git ls-files`) — auf Windows mit EDR/AV im Spawn-Pfad allein dreistellig;
2. `vim.fn.filereadable()` **und** `vim.filetype.match()` für *jeden* der
   ~2600 Einträge;
3. pro Treffer ein `vim.defer_fn(.., 0)`, das die Datei per `vim.fn.readfile()
   ` komplett synchron liest, um daraus ein `didOpen` zu bauen.

Punkt 3 erklärt auch, warum das Stack-Sampling nur 120 der gemessenen 300–420
ms sah: der Rest liegt in C-Frames und ist über die Timer-Queue verteilt.

Der Umbau in [`lsp/core/workspace_diagnostics.lua`](../../lua/lsp/core/workspace_diagnostics.lua)
und [`lsp/core/attach.lua`](../../lua/lsp/core/attach.lua):

- Dateiermittlung über `lib.nvim.fs.collect_recursive.files_async` — kein
  Subprozess, prunt ignorierte Teilbäume über `lib.nvim.fs.ignore.list`,
  filtert Extensions bereits während des Walks
- `schedule_populate()` läuft 1,5 s **nach** dem Attach statt darin
- Größen-Gate `max_files` (Default 800) statt Maschinenrolle. Der
  Startup-Default in [`lsp/init.lua`](../../lua/lsp/init.lua) ist deshalb jetzt
  schlicht `true`: `machine.is("workstation")` war immer nur ein Stellvertreter
  für „großes Repo" und ein schlechter — er schaltete das Feature auf kleinen
  Repos der workstation ab und ließ es auf großen anderswo an.
- Die Extensions kommen aus `client.config.filetypes`. Das war nötig: mit einer
  festen breiten Liste kamen 2963 Dateien zusammen und das Gate kippte, obwohl
  lua_ls davon nur `.lua` je angefasst hätte. Pro Client sind es für lua_ls
  **522 statt 1729**.

Bekannte Einschränkung, im Modul dokumentiert: das Plugin memoisiert das
Ergebnis von `workspace_files` modul-lokal, also gewinnt bei mehreren Clients
der erste. Hier ist lua_ls beides — erster Attacher und einziger Nutznießer —,
praktisch also folgenlos. Sauber lösen hieße, den Populate (~20 Zeilen
didOpen-Notifications) selbst zu implementieren statt über das Plugin zu gehen.

### lspsaga-Lightbulb war nie abgeschaltet

[`plugins/lsp.lua`](../../lua/plugins/lsp.lua) setzte `lightbulb = { enabled =
false }`. Lspsaga liest aber `enable` (`saga.config.lightbulb.enable`,
`lspsaga/init.lua:204`); `tbl_deep_extend` legte `enabled` still als toten
Extra-Key daneben. Die Lightbulb lief also weiter — das sind die ~214 ms im
Sample **und** Dauerlast bei jeder Cursorbewegung. Ein Zeichen.

### Telescope wurde trotz `cmd = "Telescope"` immer geladen

Ein Top-level-`require` hebelt lazy.nvims Lazy-Loading still aus. Zwei
Auslöser, per `lazy.core.config.plugins[..]._.loaded` ermittelt — Details in
[TASK-Startup-Blockaden.md](./TASK-Startup-Blockaden.md) Punkt 6. Beide gefixt
(einer hier, einer in `pickers.nvim`). Verifiziert: telescope.nvim,
telescope-github.nvim und pdfport.nvim sind aus dem Start verschwunden, die
Patches greifen beim späteren Laden weiterhin.

### Zwei Befunde, die stehen bleiben

- **Der Registry-Loop enabled Server unter falschem Namen.**
  `lsp.core.registry.setup_all` liefert Namen wie `"webdev.astro"` zurück, und
  [`lsp/init.lua:160`](../../lua/lsp/init.lua) ruft damit
  `vim.lsp.enable("webdev.astro")` — kein gültiger Servername, der `pcall`
  schluckt es. Die Server laufen nur, **weil** die Module sich zusätzlich
  selbst enablen. Das ist auch die Erklärung für den Nebenbefund „`lsp.start
  lua_ls` wird zweimal aufgerufen". Das Selbst-Enablen zu entfernen hätte alle
  webdev-Server abgeschaltet.
- **`on_new_config` ist toter Code.**
  [`lsp/servers/lua_ls/init.lua`](../../lua/lsp/servers/lua_ls/init.lua)
  registriert über `vim.lsp.config` (nativ), aber `on_new_config` ist ein
  lspconfig-Konzept und wird vom nativen API nie aufgerufen. Damit wird
  `Lua.workspace.library` nie gesetzt und `LUA_LS_PROFILE` ist wirkungslos —
  was das A/B-Ergebnis „`minimal` ändert nichts" besser erklärt als „die
  Library-Größe ist irrelevant". Ändert LSP-Verhalten, nicht nur Performance,
  daher bewusst nicht mitgefixt.

## Was dabei bereits gefixt wurde

- **lib.nvim** `bd98496` — `cross.executable` memoisiert PATH-Lookups.
  Gemessen: 10 Namen kalt ~155 ms (~15 ms pro Lookup, Windows + AV), warm
  praktisch gratis. Erklärt die ~13 ms großen un-attribuierten Lücken in der
  LSP-Server-Kette im `--startuptime`-Log; 22 Call-Sites in `lua/lsp/`.
- **gopath.nvim** `0d319a7` — Periodic-Timer feuerte mit Initial-Delay 0 und
  stieß beim Start einen zweiten Full-Rebuild an; `git rev-parse`-Subprozess
  durch `lib.nvim.fs.find_root` ersetzt; `cache.search` 13,7 ms → 4,9 ms.
