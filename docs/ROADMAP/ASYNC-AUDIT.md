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
