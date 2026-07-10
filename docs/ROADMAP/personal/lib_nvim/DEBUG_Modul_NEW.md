shada.tmp.X files exist — das entsteht, wenn nvim-Sessions abstürzen/gekillt werden und .shada.tmp-Reste hinterlassen. Deine eingefrorenen Sessions haben genau solche Leichen hinterlassen. 






# Kernidee

Ein **`lib.nvim.debug`**-Modul: *ein* Logging-Ansatz, den alle deine Plugins übernehmen, statt ihn jedes Mal neu zu bauen. Es ist ein **Superset von `notify`**, das `notify` *benutzt* statt es zu ersetzen (deine ~Call-Sites bleiben unangetastet).

Deine Skizze `lib.nvim.SOMENAME("msg", 5, { KEY=VAL, DUMPINGPATH="..." })` wird zu einem **Logger-Objekt**:

```lua
local log = require("lib.nvim.debug").new({ name = "myplugin", level = "debug",
                                            notify_level = "warn", file = nil, capture = true })
log.info("cache warm", { entries = 128, took_ms = 12 })
log.error("write failed", { path = p, err = err })   -- flusht sofort auf Platte
```

Also: Message + strukturierter Context, und der **Dumping-Pfad wird einmal beim `new()` konfiguriert** (statt bei jedem Call — das ist meine bewusste Verbesserung gegenüber der Skizze, per-Call-Override bleibt möglich).

## Vier Sinks (wohin ein Record geht)
- **notify** → über dein `notify.create`/`notify.safe`
- **memory (Ring-Buffer)** → letzte N Records im RAM (bounded, wie `memo.lru`) — das ist der Crash-Dump-Inhalt
- **file (JSONL)** → append, async via `vim.uv`, Default-Pfad `stdpath("log")/lib-debug/<name>.jsonl`
- **echo** (optional)

## Der schwierigste Punkt — „zuverlässig bei Crash ausgeben"
Ich bin hier **ehrlich über Neovims Grenzen** statt zu überversprechen. Es gibt keinen globalen „uncaught error"-Hook. Zuverlässig ist eine Kombination:
1. **Flush-on-error (immer an):** jeder ERROR-Record schreibt den Ring-Buffer **sofort synchron** auf Platte → selbst wenn Neovim danach stirbt, ist der Kontext schon da. Braucht keine Mitwirkung des Callers.
2. **`log.guard(fn)` / `log.wrap(fn)`:** `xpcall`-Wrapper mit Traceback — Plugins wrappen ihre Entrypoints (Command-/Autocmd-Callbacks), Fehler landen mit Traceback + Ring-Snapshot im Dump. **Das** fängt genau die Fehler, die Neovim sonst nur nach `:messages` druckt.
3. **`VimLeavePre`-Flush:** Sicherheitsnetz beim Exit.
4. **Optionaler `vim.notify`-Intercept** (invasiv, default aus).

## Extras
Scopes+Timing (via `time.diff`), `once`/`count`, `assert`, `:LibDebug`-Command (via `usercmd`), Redaction für Secrets, Health-Integration.

## Reused (alles vorhanden)
`notify.create`/`.safe`, `resolve_log_level`, `memo.lru`, `fs.write`, `cross.uv`, `system.env`, `time.diff`, `usercmd`, `autocmd`. **Neu nötig:** ein kleiner JSON-**Encoder** (`lib.lua.json` kann nur decode) und ein `fs.write.append` (aktuell nur truncate) — beides in §12 als Entscheidung vermerkt.

## Offene Entscheidungen (§12, mit Empfehlung)
1. **Name** `debug` (deine Bezeichnung) vs. `log` (konventioneller)
2. **`DUMPINGPATH` → `file`**, einmal konfiguriert statt per-Call
3. **JSONL** als Dateiformat

Soll ich beide Konzepte (UI + Debug) jetzt gemeinsam committen, oder lässt du sie erstmal uncommitted zum Durchlesen liegen?
