# Async-Audit: Blockierende Aufrufe in Config + eigenen Plugins

Stand: 2026-08-22

Ziel: Alle synchronen (den UI-Thread blockierenden) Aufrufe in der Neovim-Config
und in allen eigenen Plugins (`C:\repos\*.nvim`) erfassen, bewerten und - wo
sinnvoll - auf asynchrone Ausfuehrung umstellen.

## Methodik

Gesucht wurde nach den harten Blockern:

- `vim.fn.system()` / `vim.fn.systemlist()` - blockierender Subprozess
- `io.popen()` / `os.execute()` - blockierender Subprozess ueber die Shell
- `vim.wait()` / `jobwait()` - blockierende Event-Loop-Pumpe

Bewusst *nicht* als Blocker gewertet (aber separat gelistet, s. "Weiche Faelle"):

- `vim.fn.readfile()` / `vim.fn.writefile()` - synchrones IO, bei kleinen Dateien
  im Mikrosekundenbereich; Umbau auf `vim.uv.fs_*`-Callbacks lohnt nur bei
  Startup-Pfaden oder grossen Dateien.
- `vim.uv.fs_stat()` - synchron, aber ein einzelner Syscall.
- `vim.fn.executable()` - PATH-Lookup, auf Windows spuerbar; Fix ist Caching,
  nicht Async.

Ausgeschlossen: `docs/`, `tests/`, `*_spec.lua`, `scripts/` von Build-Tools
(laufen ausserhalb der interaktiven Session - `vim.wait`/`io.popen` dort ist
korrekt und wird nicht angefasst).

## Legende Status

- `OFFEN` - noch nicht bearbeitet
- `ERLEDIGT` - auf async umgebaut
- `BEHALTEN` - bewusst synchron gelassen (Begruendung dabei)
- `UNKLAR` - Umbau moeglich, aber Nebenwirkungen unsicher - Entscheidung noetig

## Inventar

(wird waehrend der Bearbeitung befuellt)

---

## 1. Neovim-Config (`C:\Users\StefanBartl\AppData\Local\nvim`)

| Datei:Zeile | Aufruf | Bewertung | Status |
|---|---|---|---|
| `init.lua:19` | `vim.fn.system({"git","clone",... lazy.nvim})` | Bootstrap. Laeuft nur beim allerersten Start und muss abgeschlossen sein, bevor `rtp:prepend` greift. Async ist hier fachlich falsch. | BEHALTEN |
| `init.lua:38` | `vim.fn.system({"git","clone",... lib.nvim})` | Wie oben: lib.nvim muss vor dem Spec-Import auf dem rtp liegen. | BEHALTEN |
| `lua/options.lua:233` | `vim.fn.systemlist("wl-paste ...")` | Callback des Clipboard-Providers. Neovims Provider-API verlangt einen synchronen Rueckgabewert - Async nicht moeglich. Greift ausserdem nur unter Wayland, auf der Windows-Workstation nie. | BEHALTEN |
| `lua/options.lua:239` | `vim.fn.systemlist("wl-paste ...")` | s. o. | BEHALTEN |
| `lua/lsp/usercmds/stop.lua:39` | `vim.wait(100)` in Polling-Schleife | Blockierte bis zu 3s **pro Client** beim `:LspStopHere`. Rueckgabewert wurde nirgends ausgewertet. | ERLEDIGT |
| `lua/lsp/languages/webdev/astro/keymaps.lua:161` | `vim.fn.system({"xdg-open", url})` | Blockierte bis der Opener zurueckkam; zusaetzlich nur Linux-tauglich. | ERLEDIGT |

### Durchgefuehrte Aenderungen

**`lua/lsp/usercmds/stop.lua`** - `graceful_stop()` komplett auf async umgebaut:
Statt `while ... vim.wait(100)` feuert die Funktion den graceful Shutdown und
pollt ueber einen `vim.uv`-Timer (50ms Intervall). Der Poll-Body laeuft in
`vim.schedule()`, weil `lsp.get_client_by_id()` Neovim-State anfasst. Nach
Ablauf von `timeout_ms` wird hart gestoppt. Neuer optionaler Parameter
`on_done(success)`. Fallback ohne Timer-Handle: einmaliges `vim.defer_fn`.
Ein `done`-Flag verhindert doppeltes Schliessen des Timers.
Verhaltensaenderung: die Notify-Meldung erscheint jetzt sofort statt nach dem
Shutdown - das war vorher der einzige Grund fuer das Blockieren.

**`lua/lsp/languages/webdev/astro/keymaps.lua`** - `vim.fn.system({"xdg-open"})`
ersetzt durch `vim.ui.open(url)` in `pcall`. `vim.ui.open` waehlt den
Plattform-Opener selbst und spawnt detached ueber `vim.system()`; damit
nicht-blockierend **und** plattformuebergreifend korrekt.

### Weiche Faelle in der Config (nicht umgebaut)

- `vim.fn.executable(...)` an ~15 Stellen (u. a. `lua/config/mason/ensure_install/init.lua:133/138`,
  `lua/lsp/servers/mobiledev/*`, `lua/bindings/usrcmds/case/export.lua:33/36/107`).
  Kein Subprozess, aber ein PATH-Scan - auf Windows mit vielen PATH-Eintraegen
  messbar. Richtiger Fix waere ein Memo-Cache, nicht Async. UNKLAR/OFFEN.
- `vim.fn.readfile()` / `vim.fn.writefile()` an ~10 Stellen. Kleine Dateien,
  ausserhalb des Startup-Pfades. BEHALTEN.
- `lua/autocmds/explorer-singleton.smoke.lua` - Smoke-Test, `vim.wait` ist dort
  korrekt. BEHALTEN.

---

## Querschnitts-Entscheidung: `health.lua` bleibt synchron

Betrifft: `mdview.nvim/lua/mdview/health.lua:160`,
`github_stats.nvim/lua/github_stats/health.lua:136`,
`replacer.nvim/lua/replacer/health.lua:136`,
`pdfport.nvim/lua/pdfport/health.lua:116`,
`lib.nvim/lua/lib/nvim/deps/health.lua:31`.

Neovims Health-Framework sammelt die Reports synchron ein: `vim.health.ok()`
& Co. muessen waehrend des Durchlaufs von `check()` aufgerufen werden. Ein
asynchron nachgereichtes Ergebnis landet nach dem Rendern des Reports und
taucht dort nie auf. `:checkhealth` ist ausserdem ein bewusst angestossener,
seltener Vorgang, bei dem eine kurze Blockade erwartbar ist.

=> Alle Subprozess-Aufrufe in `health.lua`-Dateien: **BEHALTEN**.

---

## 2. cmdlog.nvim - ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/cmdlog/core/project_history.lua:36` | `vim.fn.systemlist({"git","rev-parse","--show-toplevel"})` | ERLEDIGT |

`get_git_root()` lief bei jedem Cache-Miss (TTL 3s) beim Tippen von `:` in einen
Prozess-Spawn. Ersetzt durch `vim.fs.find(".git", { upward = true, limit = 1 })`
- der Subprozess entfaellt komplett, uebrig bleiben `stat()`-Aufrufe. Gitfiles
(Worktrees/Submodule) sind mit abgedeckt, da `vim.fs.find` Datei *und*
Verzeichnis matcht.

## 3. open.nvim - ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/open/context.lua:113` | `vim.fn.system({"git","rev-parse","--show-toplevel"})` | ERLEDIGT |

Identischer Umbau wie bei cmdlog.nvim; lief bei jeder `:Open`-Aufloesung.

## 4. sessions.nvim - ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/sessions/bindings/usercmds/init.lua:246` | `vim.system(...):wait()` (git rev-parse) | ERLEDIGT - Subprozess entfaellt |
| `lua/sessions/bindings/usercmds/init.lua:255` | `vim.fn.system("git ... rev-parse")` | ERLEDIGT - Subprozess entfaellt |
| `lua/sessions/bindings/usercmds/init.lua:266/275` | `git ls-files -v` | ERLEDIGT - vim.system-Callback |
| `lua/sessions/bindings/usercmds/init.lua:286/297` | `git update-index` | ERLEDIGT - vim.system-Callback |
| `lua/sessions/git.lua:18` | `vim.system({"git","symbolic-ref"}):wait()` | ERLEDIGT - Subprozess entfaellt |
| `lua/sessions/git.lua:25` | `vim.fn.system("git symbolic-ref --short HEAD")` | ERLEDIGT - Subprozess entfaellt |

- `toggle_track()`: git-Root per `vim.fs.find`. Die zwei verbleibenden echten
  git-Aufrufe laufen als verkettete `vim.system()`-Callbacks, Notify in
  `vim.schedule()`. Blockierender Pfad nur noch als Fallback fuer Neovim < 0.10.
- `current_branch()`: liest den Branch jetzt aus `.git/HEAD`
  (`ref: refs/heads/<branch>`) inkl. `gitdir:`-Aufloesung fuer Worktrees.
  Detached HEAD liefert korrekt `nil` (dort gibt es keinen Branchnamen).

## 5. emojis.nvim - ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/emojis/actions.lua:45` | `vim.wait(cfg.duration_ms)` | ERLEDIGT |

`preview_spans()` hielt den Highlight per `vim.wait()` - der Editor stand fuer
die gesamte Preview-Dauer. Jetzt `vim.defer_fn()`. Damit die Reihenfolge
(erst hervorheben, dann mutieren) erhalten bleibt, ist die Buffer-Mutation in
`M.edit()` in ein `apply()`-Callback gewandert.

**Verhaltensaenderung**: waehrend des Preview-Fensters ist der Buffer jetzt
editierbar. Wird in diesem Moment getippt, mutiert `apply()` auf dem
inzwischen geaenderten Inhalt. Bei Default-`duration_ms` praktisch irrelevant,
aber bewusst in Kauf genommen. `docs/TESTS/commands_spec.lua` angepasst (der
Test haengte sich vorher in `vim.wait` ein).

## 6. dap.nvim - ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/wkddap/utils/validation.lua:20` | `vim.fn.systemlist("ps -eo pid,comm")` | ERLEDIGT |

`pick_process()` holt die Prozessliste jetzt ueber `vim.system()`-Callback, der
Picker oeffnet in `vim.schedule()`. Fehlerfall liefert eine leere Liste, damit
`kit.select` weiterhin `on_cancel` feuert und die DAP-Coroutine nicht haengt.

**Separater Befund (nicht Async)**: `ps -eo` ist Unix-only. Unter Windows hat
diese Auflistung nie funktioniert; noetig waere `tasklist` oder eine
WMI-Abfrage. Als Code-Kommentar vermerkt, nicht behoben.

## 7. debugging.nvim - ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/debugging/tools/startup.lua:72` | `vim.fn.system({nvim --headless --startuptime})` | ERLEDIGT |

Der schlimmste Einzelfall im Bestand: `measure_once()` startete eine zweite
Neovim-Instanz und blockierte fuer deren komplette Startzeit - multipliziert
mit `runs` (bis 20). `:Debug performance startup 20` fror den Editor also
zwanzigmal hintereinander ein.

`measure_once()` nimmt jetzt ein Callback, nutzt `vim.system()`, und
Log-Lesen/Parsen laeuft in `vim.schedule()`. `M.startup()` verkettet die
Laeufe rekursiv statt sie zu schleifen. Sequentiell bleibt es bewusst -
parallele Spawns wuerden genau die gemessenen Zahlen verfaelschen.
Neu: Info-Notify beim Start, da das Kommando sofort zurueckkehrt.

## 8. mdview.nvim - ERLEDIGT (Health: BEHALTEN)

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/mdview/bindings/usrcmds/standalone.lua:44` | `vim.fn.system({bin, "--mdview-capability-probe"})` | ERLEDIGT |
| `lua/mdview/health.lua:160` | `vim.fn.system({"curl", ... /health})` | BEHALTEN (s. Querschnitts-Entscheidung) |

`supports_watch()` nutzt jetzt `vim.system()` mit Callback und memoisiert das
Ergebnis pro Binary-Pfad - der Flag-Satz eines Binaries aendert sich waehrend
einer Neovim-Sitzung nicht, also probed `:MDView standalone` nur noch einmal.
stdout und stderr werden zusammengefasst, weil Gos `flag`-Paket die Usage nach
stderr schreibt. Alles, was von der Probe abhaengt, liegt in einer Continuation.

## 9. github_stats.nvim / replacer.nvim - BEHALTEN

Jeweils genau ein blockierender Aufruf, beide in `health.lua`
(`io.popen(version_cmd)` bzw. `io.popen("echo test | rg --json -e test")`).
Siehe Querschnitts-Entscheidung oben.

## 10. insights.nvim - BEHALTEN (bewusst blockierend)

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/insights/scan/rg.lua:70` | `vim.wait(TIMEOUT_MS, ...)` | BEHALTEN |

`M.exec_sync()` ist **absichtlich** so gebaut und im Code ausfuehrlich
begruendet: `vim.system` + `vim.wait` statt `vim.fn.systemlist`, weil nur die
`vim.wait`-Pumpe `vim.schedule`-Callbacks durchlaesst. `lib.nvim.progress`
haengt daran (Delay-Guard ist `vim.schedule_wrap`'d, der Statusline-Style
`:redrawstatus` ist `vim.schedule`'d). Gemessen am eigenen Tree: 0
Statusline-Updates mit `systemlist`, 75 mit der `vim.wait`-Pumpe.

Ein echter Async-Umbau wuerde bedeuten, dass **alle** Aufrufer von
`exec_sync()` callback-basiert werden muessen (`symbols.rg_index` und
dessen Aufrufer). Das ist machbar, aber ein eigenstaendiger Umbau mit
deutlich groesserer Reichweite als die uebrigen Punkte hier.
**Entscheidung noetig, ob das angegangen werden soll.**

---

## WICHTIGER ZUSATZBEFUND: `lib.nvim.cross.run_argv.run_blocking*`

Die erste Suche nach `vim.fn.system` & Co. hat einen ganzen Layer uebersehen:
`lib.nvim.cross.run_argv.run_blocking()` und `.run_blocking_captured()` sind
duenne Wrapper um `vim.fn.system()`. **Jeder Aufrufer davon blockiert genauso**,
nur sieht man es an der Aufrufstelle nicht mehr.

Verteilung der Aufrufstellen (ohne Tests/Docs):

| Repo | Aufrufstellen |
|---|---|
| sandbox.nvim | ~110 (87x `run_blocking_captured` + Adapter-Wrapper) |
| filetree.nvim | 10 (davon 5 erledigt, s. u.) |
| lib.nvim | 14 (inkl. eigener API-Definition) |
| replacer.nvim | 3 |
| pickers.nvim | 2 |
| sessions.nvim | 2 (nur noch Fallback-Pfad, s. Abschnitt 4) |
| reposcope.nvim | 1 |

Das ist der mit Abstand groesste Einzelposten im gesamten Bestand.

**Vorschlag (noch nicht umgesetzt, Entscheidung noetig):** `lib.nvim` bekommt ein
`cross.run_argv.run_async_captured(cmd, on_done)` als offizielles Gegenstueck -
sandbox.nvim hat in `lua/sandbox/util/run_argv.lua` bereits genau so eine
Implementierung (inkl. Progress-Handle und `:stop()`), die sich als Vorlage
anbietet. Danach koennen die Aufrufer schrittweise migriert werden.

Ein Komplettumbau von sandbox.nvim (110 Stellen quer durch alle Adapter plus die
komplette UI-Schicht, die heute synchrone Rueckgabewerte erwartet) ist ein
eigenes Projekt, kein Patch. **BEWUSST NICHT in diesem Durchgang angefasst.**

## 11. sandbox.nvim - UNKLAR (bewusste Architektur, aber real blockierend)

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/sandbox/util/run_argv.lua:43` | `vim.fn.system(cmd, input)` (Fallback ohne lib.nvim) | UNKLAR |
| ~87 Aufrufer von `run_blocking_captured` | | UNKLAR |

Das Plugin unterscheidet bereits sauber: `run_async_captured()` (28 Aufrufer,
mit Progress-Handle und Abbruch) fuer lange Operationen wie `pull`/`build`/
`prune`, `run_blocking_captured()` (87 Aufrufer) fuer die kurzen. Die
Architektur ist also bewusst.

Trotzdem: `docker ps`, `docker inspect`, `docker logs` brauchen real 100-500ms,
und die blockieren jedes Mal. **Entscheidung noetig**, ob der Adapter-Layer
(und die davon abhaengige UI) auf Callbacks umgestellt werden soll.

## 12. filetree.nvim - TEILWEISE ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `features/search/grep_in_dir/init.lua:139` | `vim.system(rg):wait()` | ERLEDIGT |
| `features/search/grep_in_dir/init.lua:145` | `vim.fn.systemlist(grep)` | ERLEDIGT |
| `features/fileops/trash/platform.lua:31` | `run_blocking(powershell ...)` | ERLEDIGT |
| `features/fileops/trash/platform.lua:42` | `run_blocking({"trash"})` | ERLEDIGT |
| `features/fileops/trash/platform.lua:50` | `os.execute(osascript ...)` | ERLEDIGT |
| `features/fileops/trash/platform.lua:60/65/75` | `run_blocking(gio/trash-put/mv)` | ERLEDIGT |
| `features/fileops/trash/platform.lua:83` | `vim.fn.system({"wslpath"})` | ERLEDIGT |
| `features/fileops/trash/init.lua:119` | `vim.wait(20)` | ERLEDIGT |
| `features/fileops/trash/undo.lua:116/139/145` | `run_blocking(powershell/gio/mv)` | OFFEN |
| `features/infra/safety/backup.lua:48/50` | `run_blocking(xcopy/cp -r)` | OFFEN |

### grep_in_dir

Suche laeuft als `vim.system()`-Callback; Quickfix-Befuellung nach
`builtin_search_done()` ausgelagert. Der Progress-Indikator, den die Funktion
direkt vor der Suche startet, konnte vorher gar nicht zeichnen. Der
grep-Zweig baute zudem einen Shell-String mit `shellescape` - jetzt dieselbe
argv-Liste wie rg, damit entfaellt auch das Git-Bash-als-`&shell`-Quoting-Problem
unter Windows.

### Trash

Der wichtigste Fall auf dieser Workstation: auf Windows startet jedes
Trash-Kommando PowerShell, allein dessen Start kostet mehrere hundert
Millisekunden - jedes `d` im Tree fror Neovim ein, bei markierten Nodes
multipliziert mit deren Anzahl.

- Alle vier Backends laufen ueber einen gemeinsamen `run()`-Helper mit
  `vim.system()`-Callback. `M.send(path, cb)`.
- AppleScript-Fallback von `os.execute(Shell-String)` auf argv-Liste - kein
  Shell-Quoting des Pfads mehr noetig.
- WSL kettet `wslpath` und PowerShell asynchron.
- `do_trash(path, cb)`; das `vim.wait(20)` nach `watch.release()` ist jetzt
  `vim.defer_fn(20)`. Das ist inhaltlich sogar korrekter: der Kommentar
  begruendet das Warten damit, dass libuv Handles *asynchron* schliesst -
  genau dafuer muss die Loop laufen, was `vim.wait` ohne Prediate nicht
  zuverlaessig tut.
- `run_all()` verkettet statt zu schleifen, bewusst sequentiell.

**BREAKING**: `M.delete(path)` liefert das Ergebnis nicht mehr als
Rueckgabewert, sondern ueber den neuen optionalen `on_done(ok)`. Ebenso
`platform.M.send(path, cb)`. Im Plugin selbst gibt es keine weiteren
Aufrufer - betroffen waeren nur programmatische Nutzer der Public API.

**OFFEN**: `trash/undo.lua` (Restore aus dem Papierkorb, ebenfalls PowerShell)
und `infra/safety/backup.lua` (`xcopy`/`cp -r`, kann bei grossen Verzeichnissen
lange laufen). Beide haengen an derselben `run_blocking`-Frage wie oben.

## 13. pdfport.nvim - TEILWEISE ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/pdfport/backends/claude.lua:46` | `vim.fn.system({"base64","-w","0",path})` | ERLEDIGT - Subprozess entfaellt |
| `lua/pdfport/backends/ollama.lua:61` | `vim.system(pdftoppm):wait()` | ERLEDIGT |
| `lua/pdfport/backends/ollama.lua:277` | `vim.system(pdftotext):wait()` | ERLEDIGT |
| `lua/pdfport/health.lua:116` | `vim.fn.system({"curl", ...})` | BEHALTEN (health) |
| `lua/pdfport/platform/init.lua:74` | `vim.fn.system({python,"-c","import X"})` | OFFEN / UNKLAR |

- **base64**: `read_base64()` rief `base64 -w 0` und blockierte fuer den
  kompletten Encode einer potenziell mehrere MB grossen PDF. Der Aufruf war
  ausserdem nie portabel: `-w` ist ein GNU-coreutils-Flag (scheitert unter
  macOS mit BSD base64), und unter Windows gibt es gar kein `base64`-Binary.
  Jetzt Datei per `vim.uv` lesen und mit `vim.base64.encode` kodieren -
  Prozess-Spawn entfaellt vollstaendig. `health.lua` prueft entsprechend
  `vim.base64.encode` statt des Binaries.
- **ollama**: `rasterize_sync()` (pdftoppm, 150 DPI) und `pdftotext` liefen
  einmal pro Seite blockierend. Ein 20-seitiges PDF fror Neovim zwanzigmal
  ein. Beide jetzt callback-basiert; die umgebende Seitenschleife war mit
  `process_next()` bereits eine Callback-Kette.
- **has_python_module** (OFFEN): Python-Start kostet 150-400ms. Das Ergebnis
  wird gecacht, faellt also nur einmal je Modul an. Der Umbau ist trotzdem
  unangenehm, weil die Funktion ein `boolean` liefert und in
  `available()`-Ketten haengt, die alle synchron sind. Entscheidung noetig.

## 14. lib.nvim - API ERGAENZT, Rest bewusst synchron

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/lib/nvim/cross/run_argv/init.lua:29/56` | `vim.fn.system` (Legacy-Fallback) | BEHALTEN - async Gegenstueck ergaenzt |
| `lua/lib/nvim/deps/health.lua:31` | `vim.fn.system({python,...})` | BEHALTEN (health) |
| `lua/lib/nvim/ui/kit/sync.lua:67` | `vim.wait(timeout_ms, ...)` | BEHALTEN - genau das ist der Zweck des Moduls |
| `lua/lib/nvim/buf_win_tab/capture/init.lua:213` | `vim.wait(interval)` | BEHALTEN - dokumentierter Sync-Fallback, Async-Pfad via `cb` existiert |
| `lua/lib/nvim/cross/fs/mutate/init.lua:95` | `vim.wait(backoff)` | UNKLAR |
| `lua/lib/nvim/safe_api/init.lua:338` | `vim.wait(10)` | UNKLAR |

**Neu**: `cross.run_argv.run_async_captured(cmd, on_done, input)` - additiv,
keine bestehende Signatur geaendert. `on_done` laeuft immer auf der Main-Loop
(`vim.schedule`), liefert `ok`, `stdout` und den Exitcode; Rueckgabe ist ein
Handle mit `stop()` (SIGTERM). Der `pcall` um `vim.system` spiegelt
`run_blocking`: `vim.system` wirft synchron, wenn `cmd[1]` gar nicht spawnbar
ist (ENOENT), statt ein fehlgeschlagenes `SystemCompleted` zu liefern.
Typdeklaration in `cross/@types/run.lua` ergaenzt.

Das ist die Grundlage fuer die Migration der ~130 `run_blocking*`-Stellen.

**UNKLAR-Faelle**: `mutate.retry()` und `safe_api.with_retry()` sind
Retry-Schleifen mit Backoff, die synchron `(ok, err)` liefern. Der Backoff in
`mutate.retry` summiert sich auf 50+100+200 = 350ms bei drei Versuchen. Ein
Umbau bricht die Kern-API von `cross.fs` bzw. `safe_api`. Sinnvoller waere ein
zusaetzliches `retry_async()` neben dem bestehenden - Entscheidung noetig.

## 15. documentation.nvim - BEHALTEN / UNKLAR (bewusst blockierend)

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/documentation/bindings/usrcmds/checklist.lua:49` | `vim.wait(120000, ...)` | UNKLAR |
| `lua/documentation/bindings/usrcmds/churn.lua:52` | `vim.wait(120000, ...)` | UNKLAR |
| `lua/documentation/core/luals.lua:67` | `vim.wait(timeout_ms + 3000, ...)` | UNKLAR |
| `lua/documentation/mcp/tools.lua:395` | `vim.wait(120000, ...)` | UNKLAR |
| `scripts/bundle_manifest.lua:183`, `scripts/package.lua:135/173/297/392/437` | `io.popen` / `os.execute` | BEHALTEN - Build-Skripte, keine UI |
| `standalone/docmap.lua:353` | `io.popen` | BEHALTEN - Neovim-freier CLI-Einstieg, keine UI |

Alle vier Interaktiv-Faelle sind dasselbe bewusste Muster und im Code
begruendet: `vim.system` (async) + `vim.wait`-Pumpe, nicht `:wait()`, weil
`:wait()` keine `vim.schedule`-Callbacks abarbeitet und der Progress-Indikator
dann gar nicht sichtbar wird (gemessen: 0 sichtbare Samples unter `:wait()`
gegen 62 unter `vim.wait`).

Das ist die am wenigsten schlimme Form von Blockieren - die Loop laeuft, nur
Eingaben stehen. Trotzdem: `lua-language-server --doc` ueber einen ganzen Baum
braucht real Sekunden, `git log` ueber die Vollhistorie ebenso.

Ein echter Umbau bedeutet, dass `scan_full()`, `rescan()`, `generate()` und
`install()` callback-basiert werden - alles Funktionen, die in
`@types/init.lua` als synchron zurueckgebende Public API dokumentiert sind.
Das ist ein API-Redesign, kein Patch. Bewusst nicht angefasst.

## 16. runtime-analysis.nvim - BEHALTEN

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `scripts/telemetry.lua:237` | `vim.wait(60000, ...)` | BEHALTEN |

`nvim --headless -l scripts/telemetry.lua` - es gibt keine UI, die blockieren
koennte. Der Kommentar an der Stelle sagt genau das.

## 17. replacer.nvim - OFFEN

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/replacer/rg.lua:331/338` | `vim.system(rg):wait()` / `run_blocking_captured` | OFFEN |
| `lua/replacer/gitfiles.lua:18/24` | `vim.system(git):wait()` / `run_blocking_captured` | OFFEN |
| `lua/replacer/health.lua:136` | `io.popen` | BEHALTEN (health) |

`collect_ripgrep()` und `git_lines()` liefern ihre Ergebnisse synchron an eine
synchrone Aufruferkette. Im selben Modul existiert bereits ein Streaming-Pfad
mit Progress-Throttling (`PROGRESS_THROTTLE_MS`), die async-faehige
Infrastruktur ist also da - `collect_ripgrep` ist der Nicht-Streaming-Zweig.
Umbau machbar, braucht aber einen Blick darauf, welcher Pfad wann gewaehlt
wird. Nicht in diesem Durchgang angefasst.

## 18. pickers.nvim - ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/pickers/sources/drives.lua:31/34` | `vim.system(Get-PSDrive/df):wait()` | ERLEDIGT |

Unter Windows ist das Kommando PowerShell, deren Start allein mehrere hundert
Millisekunden kostet - der `drives`-Scope fror Neovim ein, bevor der Picker
ueberhaupt erschien. `run_captured(cmd, cb)`, `windows_roots(cb)`,
`posix_roots(cb)` und `get_roots(cb)` sind jetzt callback-basiert;
`wsl_roots()` bleibt inline (probt nur Verzeichnisse, kein Prozess).
`M.get(_cfg, callback)` war bereits callback-foermig - die oeffentliche
Signatur des Moduls aendert sich nicht. Session-Cache greift unveraendert.

## 19. reposcope.nvim - ERLEDIGT

| Datei:Zeile | Aufruf | Status |
|---|---|---|
| `lua/reposcope/utils/protection.lua:204` | `run_blocking_captured` (git clone) | ERLEDIGT |

Der laengste blockierende Aufruf im gesamten Bestand: `git clone` ist eine
Netzwerkoperation - Sekunden, bei grossen Repos oder langsamer Leitung
Minuten - und Neovim stand die gesamte Zeit.

Neu: `protection.safe_execute_shell_async(argv, on_done)` auf Basis des frisch
ergaenzten `run_argv.run_async_captured`. Nur die argv-Form, weil genau die der
Clone-Pfad nutzt. `clone_executor.M.execute()` wertete nie einen Rueckgabewert
aus (notifiziert und schreibt Metriken), der Umbau aendert also keinen
Aufrufer. Die Dauermessung umfasst weiterhin die echte Wall-Clock-Zeit.

## 20. Vollstaendig sauber (keine blockierenden Aufrufe ausserhalb von Tests)

`images.nvim`, `markdown.nvim`, `color_my_ascii.nvim`, `diff.nvim`,
`fileops.nvim`, `buffer-ctx.nvim`, `migrate.nvim`, `recommender.nvim`,
`language.nvim`, `spotlight.nvim`, `lsp.nvim`, `cascade.nvim`.

Die Treffer, die die erste Zaehlung dort gemeldet hat, lagen ausnahmslos in
`tests/`, `docs/TESTS/` oder `*_spec.lua`.

---

## Offene Entscheidungen (Zusammenfassung)

1. **`run_blocking*`-Migration** - ~130 Stellen. Die Basis
   (`run_async_captured`) steht jetzt in lib.nvim. Groesster Brocken:
   sandbox.nvim (87 Stellen + UI-Schicht).
2. **documentation.nvim** - API-Redesign noetig (`scan_full`/`rescan`/
   `generate`/`install` callback-basiert).
3. **insights.nvim `exec_sync`** - alle Aufrufer muessten callback-basiert
   werden; die `vim.wait`-Pumpe ist dort messbar begruendet.
4. **lib.nvim `mutate.retry` / `safe_api.with_retry`** - zusaetzliche
   `*_async`-Varianten statt Umbau der bestehenden.
5. **pdfport `has_python_module`** - haengt an synchronen
   `available()`-Ketten.
6. **replacer.nvim `collect_ripgrep` / `git_lines`**.
7. **filetree.nvim `trash/undo.lua` + `infra/safety/backup.lua`**.
8. **`vim.fn.executable()`-Caching** in der Config (~15 Stellen) - kein
   Async-Thema, sondern ein Memo-Cache.
