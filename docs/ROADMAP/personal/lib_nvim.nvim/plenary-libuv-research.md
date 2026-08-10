# `lib.nvim`: plenary.nvim & libuv — Research

> Stand: 2026-08-10. Beantwortet die offene Frage aus dem persönlichen Todo:
> "plenary: was fehlt um es zu ersetzen? zu optimieren? zu erweitern?" und
> "libuv: eigene, optimierte native Implementierung". Basis: Vergleich von
> `E:/repos/lib.nvim` gegen den lokalen Checkout
> `$LOCALAPPDATA/nvim-data/lazy/plenary.nvim` sowie gegen `vim.uv`.

---

## Kurzfazit

Die plenary-Migration ist faktisch **abgeschlossen**: kein Modul in
`E:/repos/lib.nvim` ruft noch `require("plenary...")` auf — die einzigen
Treffer sind Prosa-Kommentare in `system/job.lua` und `system/README.md`, die
erklären, dass `system/job.lua` `plenary.job` bewusst ersetzt. Es gibt sogar
einen zweiten, bisher nicht in `lib.md` erwähnten Baum
`E:/repos/lib.nvim/lua/lib/lua/` (reines Lua, kein `vim`-API-Bezug), der einen
Großteil von plenarys Utility-Funktionen (functional/tbl, strings, errors)
bereits abdeckt — teils breiter als plenary selbst.

Verbleibende echte Lücken sind klein und gezielt (siehe Checkliste unten),
keine davon rechtfertigt aktuell größere neue Arbeit ohne konkreten Bedarfsfall.

---

## 1. plenary.nvim: Ersetzen / Optimieren / Erweitern

| Bereich | Status | Begründung |
|---|---|---|
| async (`plenary/async`, `async_lib`) | **Lücke, niedrige Priorität** | Kein Coroutine-Async über libuv in lib.nvim. `debounce/init.lua` und `cross/uv/spawn_stream` lösen die üblichen Anwendungsfälle (Debounce, Streaming-Spawn) bereits mit Callbacks/`vim.schedule`. `a.wrap`/`Condvar`/`Semaphore` nachzubauen wäre aufwändig und ohne konkreten Callback-Pyramiden-Schmerzpunkt nicht klar nötig — beobachten, nicht bauen.
| job control (`plenary/job.lua`) | **Ersetzbar, aber bewusst schmaler** | `system/job.lua` (zeilenweises `on_stdout`/`on_stderr` über `vim.system`) plus `cross/uv/spawn_stream` und `cross/uv/spawn_capture` decken Start/Stream/Capture/Kill/Timeout ab. Fehlt gegenüber plenary: `Job.chain`/`and_then*`/`after_success`-Verkettung, `Job:sync()` (Start+Wait kombiniert), Stdin-Writer-Chaining. **Env-Lücke behoben** (siehe `lib.md`, jetzt entfernt): `cross/run/env/init.lua` existiert (PATH-Vervollständigung, Login-Shell-Recovery, Session-Variablen — stärker als plenarys Äquivalent) und ist seit dem `cross.run`-Env-Enrichment-Commit standardmäßig in `cross/run.M.run`/`M.run_blocking` verdrahtet (siehe Abschnitt 3 unten).
| path/fs/scandir | **Ersetzbar, eine echte Lücke** | Stärkster Bereich von lib.nvim: `fs/collect_recursive`, `fs/scan_cached`, `fs/scan_roots`, `fs/find_root`, `fs/find_upward_dir`, `fs/mkdirp`, `fs/is_dir`, `fs/trash`, `cross/fs/*` (Separatoren, wslpath, Lock, Mutate) übertreffen `plenary/path.lua` + `plenary/scandir.lua` in Cross-Platform-Korrektheit — Windows/WSL-Pfadnormalisierung hat bei plenary kein Äquivalent. **Lücke:** kein OOP-`Path`-Objekt; `fs/path/init.lua` ist eine flache Funktionstabelle statt eines verkettbaren `:exists()`/`:read()`/`:joinpath()`/`:iter()`-Objekts wie `plenary.Path`. Niedrige Priorität — der funktionale Stil ist ohnehin lib.nvim-Konvention.
| curl/HTTP | **Teilweise** | `net/curl/init.lua` (`fetch_json`/`fetch_raw` + `_blocking`-Varianten) deckt Method/Headers/Query/Body/Bearer-Token/Timeout ab und ist mit dem expliziten ok/data/raw-Contract eher klarer als plenary. Fehlt: Multipart `form`, `auth` (Basic), `raw`-Passthrough-Args, `output` (Download-in-Datei), `http_version`, `proxy`, `insecure`. Nur bei konkretem Bedarf ergänzen.
| testing (busted/test_harness) | **Nicht übernommen — muss auch nicht** | Eigener, schlanker Harness bereits vorhanden: `docs/TESTS/harness.lua` (`H.eq`/`H.ok`/`H.tmpfile`) + `docs/TESTS/run.lua`, führt headless 24 `*_spec.lua`-Dateien aus, ohne `plenary.busted`-Abhängigkeit. Kein neotest-plenary-Lock-in zu befürchten.
| functional/collections | **Ersetzbar** | Paralleler reiner Lua-Baum `lua/lib/lua/tables/{core,functional,dict,array,set,with,unique_table}.lua` deckt `map`/`filter`/`reduce`/`find`/`any`/`all`/`flat_map` u. Ä. ab — Gegenstück zu `plenary/functional.lua`, `tbl.lua`, `collections/py_list.lua`, `enum.lua`, Teilen von `operators.lua`. (Hinweis: `lib.nvim/normalize` und `lib.nvim/map`, beide unter `lua/lib/nvim/`, sind unabhängig davon — Validierung bzw. Keymap-Wrapper, keine Funktional-Helfer.)
| class.lua / context_manager.lua / errors.lua | **errors: ersetzbar. class/context-manager: echte Lücke, niedrige Priorität** | `lua/lib/lua/error/init.lua` bietet strukturierte Fehler (`M.new(kind, message, data)`, `M.is`, `__lib_error`-Tag) plus `M.safe_call` (xpcall+Traceback, Multi-Return-sicher) — mehr als plenarys 15-Zeilen-`errors.lua`. Kein Gegenstück zu `plenary/class.lua` (Prototyp-OOP/`extend`/Mixins) oder `plenary/context_manager.lua` (Python-artiges `with`) — echte Lücken, passen aber evtl. nicht zum funktionstabellen-basierten Stil von lib.nvim.
| log.lua | **lib.nvim klar stärker** | `logger/init.lua` + `logger/ring.lua`, `logger/sinks.lua`, `logger/config.lua`, `logger/record.lua`, `logger/serialize.lua`, `logger/command.lua`: Level/Tag-Gating pro Logger, begrenzter In-Memory-Ring, JSONL-File-Sink, Registry — gegenüber plenarys einzelner flacher `default_config` (Console/File/Quickfix). Kein Handlungsbedarf.
| strings.lua | **Ersetzbar, größerer Umfang** | `lua/lib/lua/strings/{core,case,format,patterns,wrap,distance,utf8,encoding,links,location}.lua` ist deutlich breiter als plenarys Einzeldatei (v. a. `strdisplaywidth`/`strcharpart`-FFI-Helfer für Tab-bewusste Spaltenmathematik). Kleine Lücke: nicht klar, ob `strings/core.lua` diesen FFI-Trick für Tab-/Multibyte-Spaltenbreite abdeckt — bei Bedarf (Display-Width-Bugs) kurz prüfen.
| popup/, window/ | **Ersetzbar** | `window/init.lua` (`nice_quit`, `set_title`, `make_scratch`, `close_on_focus_lost`, `center`, `find_usable`, `focus_helpers`, `open_named_scratch`, `open_scratch_split`, `tag`) plus `ui/kit/*` (Picker/Menu/Form/Confirm/Toast) decken die praktisch genutzten Teile von `plenary/popup` und `plenary/window/*` über natives `nvim_open_win` ab. Kein Handlungsbedarf.

---

## 2. libuv (`vim.uv`): native/optimierte Implementierung

**Bereits gut verdrahtet — kein Nachbesserungsbedarf:**

- Prozess-Spawn: `cross/uv/spawn_capture/init.lua` (gepuffert, Timeout, Kill)
  und `cross/uv/spawn_stream/init.lua` (zeilenweises Streaming, EOF-bewusste
  Settle-Logik, Timeout+Kill) sind sorgfältige libuv-Wrapper mit korrekter
  Pipe-Lifecycle und dokumentierter `vim.schedule`-Grenze.
- Timer/Debounce: `debounce/init.lua` (`M.new`, `M.new_with_counter`) ist ein
  sauberer `uv.new_timer()`-Wrapper mit korrektem Close/Cancel.
- Env-Aufbau für Spawns: `cross/run/env/init.lua` — deutlich ausgereifter als
  alles, was plenary bietet (s. o.).

**Ehemals bestätigte, konkrete Lücken — Stand nach Abschnitt 3:**

1. **Async-Filesystem — geschlossen.** `fs/collect_recursive` bot bislang nur
   den **synchronen** `walk` (blockierender `uv.fs_scandir`/`fs_scandir_next`,
   blockiert den Main-Loop bei großen Bäumen wie `node_modules`). Jetzt ergänzt
   um `collect_async`/`files_async`/`dirs_async` — Coroutine-getriebener,
   nicht-blockierender Walk über die Async-Form derselben libuv-Aufrufe (siehe
   Abschnitt 3). `scan_cached`/`scan_roots` haben passend `scan_async`
   bekommen. `fs/read/init.lua`s blockierendes `io.open`/`f:read("*a")` bleibt
   unverändert — kein Konsument mit erkennbarem Bedarf für Async-Read bislang.
2. **`fs/write/async/init.lua:44-55` ist Callback-Pyramide statt Coroutine**
   (`uv.fs_open` → verschachteltes `uv.fs_write` → verschachteltes
   `uv.fs_close`). Funktioniert heute korrekt; ein Coroutine-Wrapper würde vor
   allem helfen, sobald mehr async-fs-Ketten dazukommen — nicht dringend für
   sich allein. Noch offen; der `await`/`run_async`-Baustein aus
   `collect_recursive` (Abschnitt 3) ist bewusst privat/modul-lokal gehalten,
   könnte aber bei Bedarf als gemeinsamer Helfer extrahiert werden.
3. **Kein generischer File-/Dir-Watch-Primitiv.** Einzig
   `neotree/watch/init.lua` existiert — ein neo-tree-spezifischer
   `fs_event`-Handle-Leak-Workaround, kein wiederverwendbarer "watch this
   path, debounced, call me on change"-Helfer. `uv.fs_event`/`uv.fs_poll`
   sind sonst ungewrapt. Da `debounce/init.lua` bereits existiert, wäre ein
   `fs.watch` aus `uv.new_fs_event()` + vorhandenem Debounce-Handle ein
   naheliegender, kleiner Baustein — aber nur bei konkretem Konsumenten bauen
   (z. B. Config-Datei-Live-Reload). Noch offen.
4. **Pipes/IPC:** `system/rpc_pipe.lua` ist ein schmaler, zweckgebundener
   Windows-Named-Pipe-RPC-Bootstrap für neotest-Kompatibilität — kein
   allgemeiner Pipe/Socket-Wrapper und muss auch keiner werden.

---

## 3. Priorisierte nächste Schritte

> Stand 2026-08-10: beide Punkte umgesetzt, siehe lib.nvim-Commit
> `feat(cross,fs): default env-enriched run/run_blocking + async directory walk`.

- [x] `cross/run.M.run`/`run_blocking` um optionales `env` erweitern und
      standardmäßig durch `cross/run/env` anreichern lassen (deckt sich mit
      dem bereits in `lib.md` offenen `cross.run`-Env-Punkt — beide dort
      zusammengeführt). Umgesetzt als `opts.env` (Overrides, oder `false` zum
      Opt-out) + `opts.env_opts` (durchgereicht an `env.build()`); Details:
      `lua/lib/nvim/cross/run/README.md`,
      `docs/FEATURES/subprocess-env.md` (Abschnitt "Wired in by default").
- [x] Async-Scandir/Stat/Read (Coroutine über `vim.uv`) für
      `fs/collect_recursive`, `fs/scan_cached`, `fs/scan_roots` — größter
      real messbarer Nutzen aus diesem Research. Umgesetzt als
      `collect_async`/`files_async`/`dirs_async` (`collect_recursive`) sowie
      `scan_async` auf beiden Wrappern; Coroutine-Async/Await (`await`/
      `run_async`), keine Parallelisierung (ein Verzeichnis nach dem
      anderen — Fix für Main-Loop-Stalls, kein Wall-Clock-Speedup),
      `cancel()`-Funktion. Details: `docs/FEATURES/async-directory-walk.md`.
      "Read" (`fs/read`) blieb bewusst außen vor — kein erkennbarer Bedarf.

Verbleibend aus Abschnitt 2, bewusst zurückgestellt (kein konkreter
Konsument): `fs/write/async`-Coroutine-Wrapper, generischer `fs.watch`-Helfer.

---
