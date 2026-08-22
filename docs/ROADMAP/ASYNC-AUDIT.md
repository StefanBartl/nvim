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
