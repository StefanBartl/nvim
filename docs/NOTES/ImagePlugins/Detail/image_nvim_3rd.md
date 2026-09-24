# 3rd/image.nvim — Analyse (Windows 11 / native Neovim / WezTerm)

Quelle: Shallow Clone, Commit `365e2ac` (2026-09-05, Merge PR #382), letzter Release laut `CHANGELOG.md:3` v1.5.1 (2026-02-21).
Alle Pfade unten relativ zu `.../scratchpad/src/image.nvim/` (Kurzform `lua/...`). Zeilenangaben = Stand des Clones.
Was ich nicht selbst nachpruefen konnte, ist als **UNVERIFIED** markiert.

---

## 0. Kurzfazit (TL;DR)

1. **3rd/image.nvim ist in der Config des Users gar nicht konfiguriert.** Kein Treffer fuer `image.nvim` / `3rd/image` in `$NVIM_CONFIG_DIR/init.lua`, `lua/**`, `after/**`, `lazy-lock.json`. Der Plugin-Spec fuer Bilder ist `StefanBartl/images.nvim` (`lua/plugins/personal/init.lua:526-552`). `snacks.image` ist explizit **deaktiviert**: `lua/plugins/snacks.lua:48-56` (`image = { enabled = false }`, Kommentar dort begruendet es mit "Kitty sequences from native Windows Neovim in WezTerm are never drawn"). Die Beobachtung "war alles gruen und hat nie etwas angezeigt" stammt also aus einem frueheren Versuch / anderer Config-Zeit.
2. **image.nvim ist auf nativem Windows strukturell nicht lauffaehig**, unabhaengig vom Terminal:
   - `lua/image/utils/term.lua:18-32`: die Zellgroesse kommt nur aus `ioctl(TIOCGWINSZ)`, und die Konstante wird nur fuer `linux`/`mac`/`bsd` gesetzt. Auf Windows ist `TIOCGWINSZ == nil` -> einmaliges `vim.notify(..., WARN)` "unsupported OS" -> `cached_size` bleibt `nil`.
   - `lua/image/renderer.lua:271-272`: `local term_size = utils.term.get_size(); if not term_size then return end` -> **stiller Abbruch** jedes Renderings, ohne Fehler, ohne Log.
   - Upstream-Issue #332 "Any chance for Windows Terminal support?" (closed 2026-02-10) nennt genau `ioctl` als Grund (WebFetch, Issue-Beschreibung; Antworten nicht sichtbar).
3. **`:checkhealth image` existiert nicht.** Das Plugin hat kein Health-Modul (`grep -ri health lua/` -> 0 Treffer; kein `lua/image/health.lua`). Ein gruenes `:checkhealth` kam daher von etwas anderem (siehe Abschnitt 3.4: `:checkhealth snacks` prueft nur Tools + Env-Var-Erkennung, nie ob Grafik-Sequenzen ankommen).
4. **Es gibt keine Terminal-Erkennung.** Default `backend = "kitty"` (`lua/image/init.lua:18`), kein Env-Var-Check, keine Escape-Sequenz-Abfrage, kein Response-Parsing (`grep` nach `vim.env|os.getenv|TermResponse|stdin` liefert nur `SSH_*`, `TMUX*`, `KITTY_PID` im Report). Alle Kitty-Kommandos gehen mit `q=2` (Antworten/Fehler unterdrueckt): `lua/image/backends/kitty/init.lua:60,70,88,...`.
5. **Windows-spezifische Zusatzfallen** (auch wenn man die Groessenabfrage patchen wuerde): Kitty-APC (`ESC _ G`) geht im Windows-Neovim-Ausgabepfad (ConPTY/libuv) nicht durch — das ist eine Messung des Users in `docs/architecture.md:16-24` des eigenen Repos (nicht von mir reproduziert, **UNVERIFIED**); Windows-Pfade in Markdown werden falsch aufgeloest (`lua/image/utils/document.lua:8-15`); `io.popen("tty 2>/dev/null")` (`term.lua:74`); Sixel-Backend nutzt Shell-Strings mit `'`-Quoting (`sixel.lua:29-31,90-101`) -> unter `cmd.exe` kaputt; `convert`-Fallback trifft auf `C:\Windows\System32\convert.exe` (`magick_cli.lua:3-8`).
6. Sicherheits- und Robustheitsbild ist gemischt: Prozesse werden per `vim.loop.spawn` mit Arg-Liste gestartet (keine Shell-Injection im Default-Pfad), aber Remote-Download ohne Timeout/Groessenlimit/Protokoll-Whitelist und ohne `-f`, Download-Cache-Fehler bleiben haengen, viele `pcall` schlucken Fehler, Debug-Log-Default-Pfad `/tmp/image.nvim.log` ist auf Windows wirkungslos.

---

## 1. ARCHITEKTUR

### 1.1 Schichten

```
Integrations (markdown, neorg, asciidoc, rst, typst, syslang, org, html, css)
   └─ utils/document.lua  (gemeinsame Engine: Treesitter-Scan, Viewport-Filter, Queue)
        └─ init.lua  (API, globaler State, Autocmds, Decoration Provider)
             ├─ image.lua   (Image-Objekt, Extmark/Virtual-Padding, from_file / from_url)
             ├─ renderer.lua (Geometrie, Crop/Resize-Entscheidung, Transform-Queue)
             │    ├─ processors/  magick_cli | magick_rock   (Format, Dimensionen, Transform)
             │    └─ utils/transform_cache.lua (In-Memory-Index + PNG-Dateien in tmp_dir)
             └─ backends/  kitty | ueberzug | sixel   (Ausgabe an Terminal)
```

- **Backends** (`lua/image/init.lua:9-13`): `kitty` (`backends/kitty/init.lua`, `helpers.lua`, `codes.lua`), `ueberzug` (`backends/ueberzug.lua`), `sixel` (`backends/sixel.lua`). Lazy geladen ueber Proxy-Metatable (`init.lua:94-111`): `require` + `backend.setup(state)` passieren erst beim **ersten Zugriff** (also mitten im ersten Render, nicht bei `setup()`).
- **Processors** (`lua/image/processors/init.lua`): `magick_cli` (Default, `init.lua:19`) und `magick_rock` (LuaRocks `magick`, FFI). Ebenfalls lazy (`processors/init.lua:25-38`).
- **Integrations** (`init.lua:26-51`, geladen in `init.lua:131-143` per `pcall(require, ...)`): Defaults an: `markdown`, `asciidoc`, `typst`, `neorg`, `syslang`; aus: `html`, `css`, `org`. `rst` existiert (`integrations/rst.lua`) steht aber nicht in `default_options` -> ist per Default **nicht aktiv**, obwohl README:416-418 `rst.enabled = true` als Default zeigt (README/Code-Drift, Code entscheidet).
- `lua/image/utils/document.lua` ist die gemeinsame Engine; jede Integration liefert nur `query_buffer_images(buffer)` (Treesitter-Query -> Liste `{range, url}`), z. B. Markdown `integrations/markdown.lua:14-62` (Queries auf `markdown_inline`: `(image (link_destination) @url)` und Shortcut-Form).

### 1.2 Lebenszyklus eines Bildes

1. **Erzeugen**: `api.from_file(path, opts)` -> `image.from_file` (`lua/image/image.lua:251-368`): Pfad absolut machen (`fnamemodify(:p)`, z. 259), `%xx`-Fallback (261-272), **Magic-Byte-Pruefung** `utils.magic.is_image` (275; sonst `log.info` + `nil`), Klon-Shortcut falls dieselbe Datei schon existiert (281-321), sonst Format via `processor.get_format` (327, erst Magic-Bytes, dann `identify`), Dimensionen via `utils/dimensions.lua` (Header-Parser) bzw. `identify` (329). `createImage` vergibt `internal_id` (`image.lua:22-23`, wird als Kitty-`i=`/`p=` benutzt).
2. **Rendern**: `Image:render(geometry)` (`image.lua:48-165`): bricht ab bei `state.enabled == false` (49), im Cmdline-Window (55), invalidiert Caches wenn `getftime` sich aendert (58-79), ruft `renderer.render(self)` (82). Danach Extmark / Virtual-Padding (`with_virtual_padding` -> `virt_lines` als Platzhalter, `image.lua:100-164`) und Nachrendern darunterliegender Bilder (150-163).
3. **`renderer.render`** (`lua/image/renderer.lua:269-781`): holt `term_size` (271), berechnet Zeilen/Spalten, begrenzt per `max_width/height(_window_percentage)`, `adjust_to_aspect_ratio` (440, `utils/math.lua`), ermittelt Bildschirmposition via `vim.fn.screenpos` (472) inkl. Sonderfaelle Topline/teilweise gescrollt (475-570), Konceal-Korrektur `resolve_concealed_screen_x` (83-259), Fold-Check (357-370), Out-of-bounds (585-601), Crop/Resize-Entscheidung (608-660), asynchroner Transform (699-737), Skip-Rerender wenn Geometrie gleich (748-760), dann `state.backend.render(image, x, y, w, h)` (776).
4. **Clearen**: `Image:clear(shallow)` (`image.lua:168-188`) -> `backend.clear(id, shallow)`, Extmark loeschen. `shallow=true` behaelt das Image-Objekt in `state.images`, `false` entfernt es.
5. **Ende**: kitty registriert `VimLeavePre -> backend.clear()` (`backends/kitty/init.lua:37-41`); tmp-Dateien liegen in `vim.fn.tempname()` (`init.lua:77`), das Neovim beim Beenden selbst wegraeumt (Plugin loescht nichts explizit, **UNVERIFIED** dass tempname-Dir auf Windows zuverlaessig geloescht wird).

### 1.3 Globaler State (`init.lua:68-81`)

`state = { backend, processor, options, images = {}, extmarks_namespace = nvim_create_namespace("image.nvim"), remote_cache = {}, tmp_dir = vim.fn.tempname(), disable_decorator_handling, hijacked_win_buf_images, enabled = true }`. Ein einziger Modul-lokaler State; `state.images` ist die "Wahrheit" fuer "ist gerade gerendert" (`is_rendered`-Flag pro Image + Backend-Index). Module-lokale Zusatzstates: `buf_extmark_map` (`image.lua:6`), `transmitted_images` (`kitty/init.lua:20`), `pending_transform_owners` (`renderer.lua:6`), `popup_window` (`document.lua:6`), `transform_cache` (`utils/transform_cache.lua:4-7`).

### 1.4 Window-/Scroll-/Extmark-Tracking

- **Decoration Provider** `nvim_set_decoration_provider(ns, { on_win = ... })` (`init.lua:185-290`): pro Redraw pro Fenster; bricht ab wenn nicht Normalmodus (194; Kommentar: "in visual mode this callback gets called CONTINUOUSLY"), vergleicht `topline/botline/height/gefaltete Zeilen` mit `window_history` (259-273) und schedult dann `render_window_images(winid)` (281-286). Der Callback gibt immer `false` zurueck (keine Decoration).
- **Autocmds** (Group `image.nvim`, `init.lua:293`): `BufLeave/WinClosed/TabEnter` -> ungueltige/nicht sichtbare Bilder clearen (296-339; Achtung `return` nach erstem `clear()` in Schleife 316/322 -> nur das erste betroffene Bild wird pro Event bereinigt); `WinScrolled` -> Fenster neu rendern (342-348); `WinResized/WinNew` -> alle Fenster: `backend.clear(id,true)` + neu rendern (351-357, Kommentar in `renderer.lua:265`: "horrible performance when you resize a window"); `VimSuspend/VimResume` (361-379); `FocusLost/FocusGained` nur wenn `editor_only_render_when_focused` oder tmux-Option (382-445); Hijack-Autocmd `WinNew/BufWinEnter/TabEnter` mit `pattern = hijack_file_patterns` (448-467); Extmark-Sync `BufWritePost/TextChanged/TextChangedI/InsertEnter` (470-488); User-Command `:ImageReport` (491-493). Kitty: `VimResized` leert `transmitted_images` (`kitty/init.lua:21-25`), `term.lua:69-71` aktualisiert die Groesse.
- **Document-Integrationen** haben eigene Autocmds (`document.lua:342-410`, Group `image.nvim:<name>`): `WinNew/BufWinEnter/BufEnter/TabEnter`, `WinScrolled`, `BufAdd/BufNew/BufNewFile/BufWinEnter`, `nvim_buf_attach(on_lines)` (331-339, pro Buffer einmal), `CursorMoved` nur bei `only_render_image_at_cursor`, `InsertEnter/InsertLeave` nur bei `clear_in_insert_mode`.
- **Extmarks**: Ein Image mit `inline`/`with_virtual_padding` bekommt genau einen Extmark (id = `internal_id`), Padding via `virt_lines` (`image.lua:122-146`); `Image:has_extmark_moved()` (36-45) wird im Sync-Autocmd benutzt (`init.lua:476-486`).
- **Overlap/Masks**: `utils/window.lua:91-136` berechnet fuer Normalfenster ueberlappende Floating-Fenster (`masks`), nur wenn `window_overlap_clear_enabled = true` (Default false, `init.lua:59`).

### 1.5 Debounce/Coalescing
`utils/render_scheduler.lua` (29 Zeilen): pro Key wird nur der **letzte** Callback pro `vim.schedule`-Tick ausgefuehrt (kein Zeit-Debounce, sondern Event-Loop-Coalescing). Sixel hat zusaetzlich einen 50-ms-Timer (`sixel.lua:5,247-249`).

### 1.6 API (`init.lua:113-626`, Typen `lua/types.lua:3-12`)
`setup`, `from_file`, `from_url(url, opts, cb)`, `hijack_buffer(path, win, buf, opts)`, `clear(id?)`, `get_images({window,buffer,namespace})`, `create_report()` (`:ImageReport`), `is_enabled/enable/disable`. Image-Methoden: `render(geometry)`, `clear(shallow)`, `move(x,y)`, `brightness/saturation/hue` (`image.lua:190-245`). Kein `:Image`-Command ausser `:ImageReport`; keine Health-Funktion.

---

## 2. CLI-TOOLS / RUNTIME-DEPS

| Abhaengigkeit | Wozu | Wie aufgerufen | Erkennung |
|---|---|---|---|
| ImageMagick `magick` (v7) oder `convert`+`identify` (v6) | Format-Fallback, Resize/Crop/Konvertierung nach PNG | `vim.loop.spawn(cmd, {args = {...}, hide = true})` — **Arg-Liste, keine Shell** (`processors/magick_cli.lua:31,71,110,147,183,243,...`) | `vim.fn.executable()` **einmal beim Laden des Moduls** (`magick_cli.lua:3-5`), danach gecacht -> spaeter installiertes magick braucht Neovim-Neustart |
| `magick` LuaRock (optional) | Alternative zu CLI, FFI | `require("magick")` (`lua/image/magick.lua:1`), bei fehlendem Rock `nvim_err_writeln` (magick.lua:9-12,16-19) | `pcall(require)` |
| Ghostscript `gs` | PDF | indirekt ueber ImageMagick (README:67) | keine Pruefung im Code |
| `curl` | Remote-Bilder | `vim.loop.spawn("curl", { "-L","-s","-o",tmp_path,url })` (`image.lua:384-388`) | **keine** Pruefung, ob `curl` existiert |
| `ueberzug` (README meint ueberzugpp) | `ueberzug`-Backend | `vim.loop.spawn("ueberzug", {"layer","--silent"})` (`backends/ueberzug.lua:13-15`), JSON auf stdin | keine Pruefung; bei fehlender Binary `error("image: failed to spawn ueberzug")` (`ueberzug.lua:26`) |
| ImageMagick mit Sixel-Delegate | `sixel`-Backend | **Shell-String** `vim.fn.system("magick '<pfad>' -resize WxH sixel:-")` (`sixel.lua:90-101`) | `executable("magick"/"convert")` (`sixel.lua:82-89,256-259`) |
| `tmux` | passthrough, Pane-Position | `vim.fn.system({...})` Arg-Listen (`utils/tmux.lua`) | `TMUX`-Env, `allow-passthrough`-Abfrage (tmux.lua:1-10) |
| `tty`, `ps` | Editor-TTY (Kitty ueber SSH), `:ImageReport` | `io.popen("tty 2>/dev/null")` (`term.lua:74`), `vim.fn.system("ps -o ppid= -p N")` (`report.lua:23-27`) | keine |
| LuaJIT `ffi`, `bit` | `ioctl`, Hashing, Dimensions | `require("ffi")` (`term.lua:7`) | — |
| Treesitter-Parser `markdown`, `markdown_inline`, `norg`, `html`, `css`, `typst` ... | Bild-Suche im Dokument | `vim.treesitter.get_parser(buf, "markdown")` (`markdown.lua:16`) | keine Pruefung; fehlender Parser -> Lua-Fehler im schedule-Callback (Verhalten je nach Neovim-Version, **UNVERIFIED**) |

**Windows-Status**: README erwaehnt Windows **nirgends** (`grep -i windows README.md` -> nichts). Kein Windows-CI (`.github/workflows/ci.yml:14`: `runs-on: ubuntu-latest`; Rockspec-Test-Plattform nur `unix`, `image.nvim-scm-1.rockspec:33-37`). Issue #332 (closed) fragt nach Windows Terminal, Ursache `ioctl`. Was auf Windows konkret passiert:

1. `require("image")` -> `utils/term.lua` laedt und ruft `update_size()` sofort auf (`term.lua:68`): `TIOCGWINSZ` bleibt `nil` (`has("linux")`, `has("mac")`, `has("bsd")` alle 0, Zeilen 18-25) -> `vim.notify("image.nvim: unsupported OS — cannot query terminal size", WARN)` einmalig (`term.lua:27-32`), `cached_size = nil`.
2. Jeder Render: `renderer.lua:271-272` -> `return` (nil), kein Log. `Image:render` behandelt nil wie "nicht gerendert" (`image.lua:82,95`) und macht still weiter. Der Popup-Modus (`only_render_image_at_cursor_mode = "popup"`) bricht ebenfalls still ab (`document.lua:142-143`). `hijack_buffer` leert den Buffer auf eine leere Zeile, setzt `buftype=nowrite`, `filetype=image_nvim` (`init.lua:509-518`) -> **leerer Buffer, kein Bild, kein Fehler**. Das passt exakt zum Symptom "Mappings feuern, nichts erscheint".
3. `backends/kitty/init.lua:6` ruft beim Laden `utils.term.get_tty()` -> `io.popen("tty 2>/dev/null")`: unter `cmd.exe` schlaegt `2>/dev/null` fehl, Ergebnis leer -> `nil` (harmlos, aber laeuft ueber cmd.exe).
4. `magick_cli.lua:8`: Ohne `magick` im PATH faellt der Code auf `convert` zurueck; auf Windows ist das `C:\Windows\System32\convert.exe` (FAT->NTFS-Tool). `vim.fn.executable("convert")` ist dort `1`, der Guard (`magick_cli.lua:10-15`) greift nicht, der Fehler kommt erst als Exit-Code != 0. Beim User ist `magick` via Scoop im PATH (`.../scoop/apps/imagemagick/current`), daher hier eher theoretisch. `report.lua:62-66` meldet ausserdem faelschlich "ImageMagick CLI Available" wenn nur `convert.exe` da ist.
5. `document.lua:8-15` `resolve_absolute_path`: nur ein fuehrendes `/` gilt als absolut; `C:\bild.png` / `C:/bild.png` wird an `document_dir .. "/"` angehaengt -> falscher Pfad, `from_file` wirft "file not found", der `pcall` in `document.lua:238` schluckt es (nur `log.debug`, Zeile 249).
6. `report.lua:23-27` (`ps`) liefert unter Windows leere Prozessbaum-Info.
7. Sixel-Backend: `sixel.lua:29-31` schuetzt nur `'` (POSIX-Shell); unter `cmd.exe` sind Single-Quotes keine Quotes -> Pfade mit Leerzeichen brechen, und die Ausgabe geht ueber `vim.fn.chansend(vim.v.stderr, ...)` (`sixel.lua:150`), Verhalten unter ConPTY **UNVERIFIED**.
8. Ueberzug(++) unterstuetzt Windows nicht (**UNVERIFIED**, aus Kenntnis des Projekts, nicht aus dem Clone).

---

## 3. TERMINAL-ERKENNUNG & PROTOKOLL

### 3.1 Erkennung
- **Keine.** Die Backend-Wahl ist reine Konfiguration (`init.lua:18`, `create_lazy_backend`, `init.lua:94-111`). Kein `TERM`/`TERM_PROGRAM`/`KITTY_WINDOW_ID`/`WEZTERM_*`-Check, keine Kitty-Query (`a=q`) obwohl `codes.lua:41` die Konstante `query = "q"` kennt, kein DA1/`TermResponse`. `grep vim.env|os.getenv` im Plugin: nur `SSH_CLIENT/SSH_TTY` (`kitty/init.lua:7`, `helpers.lua:12`), `TMUX/TMUX_PANE` (`tmux.lua:1-2`), `TERM` und `KITTY_PID` nur im Report (`report.lua:37,83`).
- Der Kitty-Backend schreibt fire-and-forget: alle Kommandos mit `quiet = 2` (`kitty/init.lua:60,70,88,...; clear: 178,196`), das Plugin liest **nie** von stdin. Ein Terminal, das APC ignoriert, erzeugt keine sichtbare Rueckmeldung.

### 3.2 Ausgabe-Mechanik
- `helpers.lua:9-10`: `stdout = vim.loop.new_tty(1, false)`; alle Sequenzen via `stdout:write(payload)` (`helpers.lua:53`), am Neovim-TUI vorbei. Bei nicht-TTY-stdout: `error("failed to open stdout")` beim ersten Laden des Backends. (Im eigenen Repo des Users steht als Messung: `io.stdout:write` "draws exactly once per terminal session and then silently stops", `nvim_ui_send` sei noetig — `docs/architecture.md:~46-48`; nicht von mir reproduziert, **UNVERIFIED**.)
- Transmit: Default `t=f` (Dateipfad, base64), `f=100` (PNG) (`kitty/init.lua:47,53-63`); ueber SSH `t=d` mit Chunking (`kitty/init.lua:49`, `helpers.lua:111-143`; Chunkgroesse `kitty_direct_chunk_size`, Default 4096). Anzeige: `a=p`, `z=-1`, `C=1`, `p=<id>`, Cursor-Positionierung mit `ESC[s` `ESC[y;xH` ... `ESC[u` in synchronisiertem Update `?2026h/l` (`helpers.lua:146-161`). Zuschnitt (`crop = true`) direkt per `x/y/w/h` (`kitty/init.lua:113-148`).
- `kitty_method = "unicode-placeholders"` (`init.lua:57`, `kitty/init.lua:35,45,81-102`): schreibt `U+10EEEE` + Diakritika (`helpers.lua:163-175`, `codes.lua:71-…`), deaktiviert dann `crop`.

### 3.3 tmux
- `utils/tmux.lua`: `is_tmux = vim.env.TMUX ~= nil`; `allow-passthrough` per `tmux show -Apv allow-passthrough` (Zeilen 6-10); `backend.setup` **wirft** wenn tmux ohne passthrough (`kitty/init.lua:30-33`); Sequenzen werden mit `ESC Ptmux; ... ESC \` und verdoppeltem ESC gewrappt (`tmux.lua:83-85`, angewendet in `helpers.lua:38`); Pane-Offset via `tmux display-message` (`tmux.lua:25-45`, in `helpers.lua:147-151`). README: tmux >= 3.3, `allow-passthrough on`, `visual-activity off`, `focus-events on` (README:176-183).
- Nicht relevant fuer den User (kein tmux unter Windows-WezTerm, `TERM=xterm-256color` in dieser Session).

### 3.4 Offiziell unterstuetzte Terminals & WezTerm
- README:34-47: Kitty >= 28.0 empfohlen; WezTerm "implements it, but the performance is bad and it's not fully compliant ... not officially supported"; Ghostty "not that much information yet"; ueberzugpp fuer beliebige Terminals; Sixel fuer XTerm/WezTerm/foot u. a.
- WezTerm-Kitty: Unicode-Placeholders sind in WezTerm nicht implementiert (Aussage stuetzt sich auf `snacks.nvim/lua/snacks/image/terminal.lua:20-24` `wezterm ... placeholders = false` sowie den eigenen Repo-Text `docs/architecture.md:151`; im image.nvim-Clone gibt es keine WezTerm-spezifische Logik). Ob WezTerm-Kitty-Grafik ueberhaupt aktiv ist, haengt an `enable_kitty_graphics` (Default laut meiner Erinnerung `false`, **UNVERIFIED**, die Doku-Seiten waren per WebFetch nicht abrufbar). In der WezTerm-Config des Users (`$REPOS_DIR/Configs\Terminals\wezterm\config\terminal_safety.lua:23`) ist nur `enable_kitty_keyboard = false` gesetzt; `enable_kitty_graphics` wird **nirgends** gesetzt (grep) -> Default.
- Wichtiger: Der User hat in `docs/architecture.md:16-24` und `docs/scope.md:3-6` seines Repos dokumentiert, dass auf nativem Windows-Neovim in WezTerm Kitty-APC aus Neovim heraus nie gezeichnet wird, obwohl dieselben Sequenzen aus einer rohen Shell funktionieren. Das deckt sich mit der Vermutung, dass Neovims Windows-Ausgabepfad (libuv-TTY/ConPTY) APC verwirft; **UNVERIFIED**, von mir nicht gemessen. OSC 1337 (iTerm2) geht laut derselben Doku durch.

### 3.5 Was `:checkhealth` prueft — und was nicht
- **image.nvim: gar nichts** — es gibt kein Health-Modul (siehe TL;DR 3). `:checkhealth image` -> "No healthcheck found for image"-artige Meldung (Neovim-Standardverhalten). Es gibt nur `:ImageReport` (`init.lua:491-493`, `report.lua`), das OS, Prozessbaum (`ps`), `TERM`, Config-JSON, ImageMagick-Version und Backend-Features **ausgibt**, aber nichts verifiziert.
- **snacks.image** (im Blick, weil der User beides erwaehnt): `Snacks.image.health` (`nvim-data/lazy/snacks.nvim/lua/snacks/image/init.lua:303-363`) prueft (a) Tool-Praesenz `kitty|wezterm|ghostty`, `magick`, `gs`, `tectonic|pdflatex`; (b) **passive Terminal-Erkennung** ueber Env-Var/Terminal-Name (`terminal.lua:6-37`, `M.env()` ab Zeile 110) -> "`wezterm` detected and supported"; (c) Terminalgroesse in Pixeln; (d) Treesitter-Parser fuer Markdown/LaTeX. Es sendet **kein** Testbild und wartet auf keine Antwort. Deshalb kann `:checkhealth snacks` komplett gruen sein, waehrend das Terminal/der Neovim-Ausgabepfad Kitty-Grafik verwirft. Das entspricht der Beobachtung des Users.

---

## 4. FAILURE MODES (stille Fehlerpfade)

Nach Wahrscheinlichkeit fuer Windows/WezTerm sortiert; jeweils file:line.

1. **Terminalgroesse `nil` -> `renderer.render` returnt still** — `renderer.lua:271-272`, Ursache `term.lua:18-43`. Nur ein einmaliges WARN-Notify beim Laden (`term.lua:30`), das leicht in Startup-Meldungen untergeht.
2. **Kitty `q=2` + kein Response-Read** — Terminal-seitige Fehler (unbekannte Sequenz, falscher Pfad, verweigerte `t=f`-Datei) bleiben unsichtbar (`kitty/init.lua:60,70,88,...`).
3. **APC im Windows-Ausgabepfad verworfen / WezTerm-Kitty nicht aktiv** — siehe 3.4 (**UNVERIFIED**).
4. **Kein Health-Check, keine Terminal-Erkennung** — Fehlkonfiguration (`backend="kitty"` in unpassendem Terminal) faellt nie auf (`init.lua:18`).
5. **Log-Default unbrauchbar**: `debug.enabled = false` (`init.lua:20-25`), `file_path = "/tmp/image.nvim.log"`; `logger.output_log` oeffnet die Datei und macht bei `io.open == nil` **nichts** (`logger.lua:176-184`). Unter Windows existiert `\tmp\` auf dem Laufwerks-Root nicht -> selbst mit `debug.enabled = true` bleibt das Log leer, solange `file_path` nicht auf einen gueltigen Windows-Pfad gesetzt wird. Zusaetzlich: `logger.lua:14` Default-`level = "detailed"` ist kein gueltiger Level-Name, faellt aber in `levels[...] or levels.debug` zurueck (`logger.lua:169`).
6. **`pcall` schluckt Fehler**:
   - `document.lua:238-250` (`from_file` aus Dokument): Fehler nur `log.debug` (nur sichtbar mit Debug-Log).
   - `document.lua:214-225` (`from_url`): `pcall` ohne Fehlerausgabe.
   - `image.lua:410-413` (Download-Nachlauf): `pcall(from_file, ...)`; bei Fehler wird `callback` **nie** aufgerufen.
   - `init.lua:135-137`: Integration-Load-Fehler nur `log.error` (also lautlos ohne Debug-Log). Ein Fehler in der Integration = Feature fehlt, ohne Hinweis.
   - `transform_cache.lua:165-168`: Fehler im Transform -> Entry `failed`, nur `log.error` (`renderer.lua:708,729`).
   - `utils/magic.lua`/`dimensions.lua`: mehrere `pcall(file:seek)`.
7. **Nicht-Bild-Erkennung ist strikt**: `magic.is_image` (`magic.lua:88-90`) -> `log.info("not an image")` + `nil` (`image.lua:275-278`). JPEGs muessen mit `FF D9` enden (`magic.lua:27-34,73-77`); JPEGs mit Trailer-Daten werden als "kein Bild" abgelehnt. `webp`-Signatur ist nur `RIFF` (matcht auch WAV/AVI).
8. **`only_render_image_at_cursor`** (`document.lua:104-107`): nur Bilder in der Cursor-Zeile; im Default-Modus `popup` (`markdown.lua:9`) wird ein Floating-Window geoeffnet (`document.lua:139-190`) und bei `CursorMoved` sofort wieder geschlossen; im Popup-Pfad returnt `utils.term.get_size() == nil` ebenfalls still (142-143).
9. **`window_overlap_clear_enabled`** (Default false): wenn an, werden Bilder bei jedem ueberlappenden Floating-Window (Notifier, Completion, Neo-tree-Preview...) `clear`ed (`init.lua:215-237`, `renderer.lua:342-347`); Ausnahme-Filetypes nur `cmp_menu`, `cmp_docs`, `snacks_notif`, `scrollview*` (`init.lua:60`). Andere Plugins-Fenster loeschen also Bilder.
10. **Falsches `backend`** -> `utils.throw("image.nvim: backend not found: ...")` bei `setup` (`init.lua:88-90`, das ist laut, gut). Aber ein *plausibler* falscher Backend (kitty in Terminal ohne Kitty) ist lautlos (Punkt 4).
11. **Fehlende `integrations`/Filetype**: Integration greift nur bei `filetype in options.filetypes` (`document.lua:38-40`, Markdown-Default `{markdown, vimwiki}`, `markdown.lua:12`). Bei z. B. `filetype=quarto`/`mdx`/`text` passiert nichts. `rst` ist per Default aus (siehe 1.1).
12. **Backend-Init wirft lazy**: `backend.setup` laeuft erst beim ersten Render (`init.lua:94-102`); der Fehler (z. B. tmux ohne passthrough, `kitty/init.lua:30-32`) erscheint als Fehler in einem `vim.schedule`-Callback und der Backend-Proxy gilt danach als "geladen" (`backend` ist schon gesetzt, `init.lua:99-100`).
13. **`hijack_file_patterns`** nur `png,jpg,jpeg,gif,webp,avif` (`init.lua:64`): `.svg/.bmp/.ico/.pdf` werden nicht gehijackt, obwohl `magic.lua:3-16` sie kennt.
14. **Auto-clear-Race**: `FocusLost` schaltet mit `editor_only_render_when_focused` `disable_decorator_handling = true` (`init.lua:403`); bleibt `FocusGained` aus (Terminal ohne Focus-Events, z. B. manche Windows-Setups, **UNVERIFIED**), bleiben Bilder dauerhaft aus.
15. **Download-Fehler**: `state.remote_cache[url] = tmp_path` wird bei jedem `read_start`-Callback gesetzt, auch bei Fehlschlag (`image.lua:405-408`); spaetere `from_url`-Aufrufe fuer dieselbe URL nehmen dann den kaputten Pfad (`image.lua:375-379`). `curl -s` ohne `-f`: HTTP 404/500 gibt Exit 0 und schreibt die Fehlerseite als Datei -> `is_image` false -> `nil` -> Callback mit `nil` -> Dokument-Code macht `if not image then return end` (`document.lua:221`), lautlos. `ignore_download_error` (Default false) entscheidet nur ob `utils.throw` (`image.lua:390-398`); `throw` passiert in einem libuv-Callback ausserhalb `schedule`.
16. **Debug-Option-Merge**: `logger.setup(opts.debug)` nur bei truthy `opts.debug` (`init.lua:119`) — Default-Tabelle ist truthy, aber `enabled = false`.

### Debug-/Log-Facility
`debug = { enabled, level = "debug|info|warn|error", file_path, format = "compact|detailed" }` (`types.lua:38-42`, `logger.lua`). Schreibt via `io.open(file_path, "a")` pro Zeile (`logger.lua:176-184`, kein Buffering, oeffnet/schliesst die Datei jedes Mal). Zusaetzlich `:ImageReport` (Floating-Window mit Config-JSON, Prozessbaum, Backend-Features, Liste der Bilder inkl. `Rendered: true/false`, `report.lua:88-100`). Beides hilft unter Windows wenig (Pfad-Default, `ps`).

---

## 5. FEATURES

- **Formate**: per Magic-Bytes: png, jpeg, webp (RIFF), gif, bmp, heic, xpm, ico, avif, svg (`<svg`), xml (`<?xml`), pdf (`magic.lua:3-16`). Dimensions-Header-Parser in `utils/dimensions.lua` (u. a. ISOBMFF fuer AVIF/HEIC); Fallback `identify`. Nicht-PNG wird per ImageMagick nach PNG transformiert (`renderer.lua:657`, `needs_transform = needs_resize or crop or source_format ~= "png"`). Weil `needs_resize = image.image_width ~= pixel_width` (`renderer.lua:643`) fast immer wahr ist, ist ImageMagick praktisch immer noetig (auch fuer PNG). GIFs: nur erster Frame (`magick_cli.lua:69,108,213`, kein Animation).
- **Markdown**: Treesitter (`![alt](url)` und Shortcut-Form) (`markdown.lua:14-62`), relative Pfade (`document.lua:8-15`), `~`-Pfade, `data:image/...;base64,...` (`document.lua:17-29,231-232`), `resolve_image_path`-Callback (`document.lua:229-230`). Vimwiki-Filetype inklusive.
- **Neorg** (`integrations/neorg.lua`: `.image`-Infirm-Tag, optional `$workspace`-Expansion via `neorg.core`), **Asciidoc, rst, Typst, Syslang, Org** (eigene Dateien), **HTML** (`src="..."` per Treesitter, Webroot-Suche mit `vim.fs.find`, `html.lua:11-58`), **CSS** (`url(...)`, `css.lua`). Neorg-Query hat einen Tippfehler `(#eq? name "image")` (ohne `@`, `neorg.lua:38`), Auswirkung **UNVERIFIED**.
- **Remote-Bilder**: `download_remote_images = true` (Default) fuer alle Document-Integrationen; nur URLs mit `http://`/`https://`-Praefix (`document.lua:31-33`); Download per `curl`, Ziel `tmp_dir/<sha256(url)>.png` (`image.lua:381-388`); In-Memory-Cache pro URL (`state.remote_cache`, `image.lua:375-379`), **kein** Ablauf.
- **Resize/Crop**: ImageMagick `-scale WxH` und `-crop WxH+X+Y`, Ausgabe `png:<pfad>` (`magick_cli.lua:211-229`). Bei Kitty-Backend wird Crop im Terminal erledigt (`features.crop = true`), bei ueberzug/sixel/placeholders per ImageMagick (`renderer.lua:648-655`).
- **Groessenlimits**: `max_width`, `max_height`, `max_width_window_percentage` (Code-Default **100**, `init.lua:54`; README zeigt `nil`), `max_height_window_percentage` (50), `scale_factor`.
- **Only-at-cursor**: `only_render_image_at_cursor` + Modus `popup|inline` (`document.lua:104-107,139-203`).
- **Window-Overlap**: `window_overlap_clear_enabled` + `window_overlap_clear_ft_ignore` (`init.lua:59-60`, `utils/window.lua:91-136`).
- **tmux**: Passthrough-Wrapping, Pane-Offset, `tmux_show_only_in_active_window` (`init.lua:62,382-445`).
- **`editor_only_render_when_focused`** (`init.lua:61,382-445`).
- **`hijack_file_patterns`** (`init.lua:64,447-467`): Bilddateien als Buffer oeffnen und rendern.
- **Virtual Padding / Inline / Overlap**: `with_virtual_padding`, `inline`, `overlap`, `render_offset_top` (`types.lua:81-91`, `utils/virtual_padding.lua`).
- **Konceal-Korrektur** (`renderer.lua:83-259`, juengster Merge PR #382).
- **Bildmanipulation**: `Image:brightness/saturation/hue` (`image.lua:190-245`).
- **API**: siehe 1.6.

---

## 6. SECURITY

**Positiv**
- ImageMagick-/curl-/ueberzug-Aufrufe im Default-Pfad ueber `vim.loop.spawn` mit **Argument-Liste** (`magick_cli.lua`, `image.lua:384`, `ueberzug.lua:13`), keine Shell -> keine klassische Command-Injection ueber Dateinamen/URLs. Pfade sind absolut (`image.lua:259`), beginnen also nicht mit `-` (kein Argument-Injection-Problem fuer ImageMagick). Die URL fuer `curl` beginnt zwingend mit `http://`/`https://` (`document.lua:31-33`), damit ist `-K/-o`-artige Argument-Injection ueber den Dokumentinhalt nicht moeglich (die Public-API `api.from_url` selbst prueft nichts, `image.lua:374-415`; ein `--` vor der URL fehlt).
- Tempdateien: `vim.fn.tempname()`-Verzeichnis (`init.lua:77`), Dateinamen `sha256(url)` bzw. `transform-<sha256>.png` (`transform_cache.lua:102-104`), also keine nutzerkontrollierten Namen im Tempdir.
- Magic-Byte-Gate vor jeder Verarbeitung (`image.lua:275`).

**Negativ / Risiken**
1. **Remote-Download ohne Haertung** (`image.lua:384-388`): `curl -L -s -o <tmp> <url>` — kein `-f` (Fehlerseiten werden gespeichert), kein `--max-time`/`--connect-timeout`, kein `--max-filesize`, keine `--proto`/`--proto-redir`-Whitelist (curl-Defaults gelten), Redirects werden bedingungslos gefolgt (`-L`), kein Host-/IP-Filter (SSRF-artig: ein oeffentlich/unvertraut bezogenes Markdown-Dokument loest **automatisch** GET-Requests auf beliebige URLs inkl. `localhost`/Metadaten-Endpunkte aus; Antwort wird nicht exfiltriert, aber Requests/Tracking sind moeglich). Default `download_remote_images = true` in allen Integrationen (`markdown.lua:8`, `html.lua:8`, ...).
2. **Angriffsflaeche ImageMagick**: `svg`/`xml`/`pdf` gelten als Bild (`magic.lua:13-15`) und gehen an `magick`/`convert` (`renderer.lua:657` -> `processors/magick_cli.lua:243`). Damit sind ImageMagick-Delegates (SVG/MSVG-Referenzen, Ghostscript fuer PDF) erreichbar; Gegenmassnahme liegt allein in der ImageMagick-`policy.xml`. Ob konkret exploitbar: **UNVERIFIED**.
3. **Base64-Data-URIs** landen unbegrenzt gross in `vim.fn.tempname()`-Dateien (`document.lua:17-29`), `vim.base64.decode` ausserhalb `pcall` (`document.lua:232`), ungueltiges Base64 wirft im schedule-Callback.
4. **Sixel-Backend nutzt Shell-String** (`sixel.lua:29-31,90-101`): nur `'`-Escaping fuer POSIX; unter Windows `cmd.exe` wirkungslos/inkonsistent. Auf POSIX ist das Escaping korrekt, aber Fehleranfaellig; `width/height` werden mit `%d` formatiert (sicher).
5. **Pfad-Sanitizing**: `fnamemodify(:p)` und `%xx`-Dekodierung (`image.lua:259-272`), `resolve_image_path` vom User frei ueberschreibbar (`document.lua:229`). Ein Dokument kann beliebige lokale Bildpfade referenzieren; die Datei wird vom Terminal (`t=f`) oder ImageMagick gelesen (Info-Leck nur ueber Bildinhalt in der Anzeige).
6. **Terminal-Escape-Injection**: Es werden nur selbst erzeugte Sequenzen geschrieben (Pfad base64-kodiert, `helpers.lua:127`); Dateiinhalt gelangt nicht roh ins Terminal (ausser Sixel-Daten aus ImageMagick, `sixel.lua:124-150`).
7. **Temp-Cleanup**: Transform-Ausgaben und Downloads werden vom Plugin nie geloescht, `transform_cache.entries` wird nie geraeumt (`transform_cache.lua:118-119` fuehrt `last_access`, benutzt es aber nicht fuer Eviction, `clear()` nur bei `setup`, `init.lua:129`/`transform_cache.lua:179-184`). Speicher-/Plattenwachstum ueber lange Sessions.
8. **Unbeschraenkte `vim.wait`-Blockaden** im CLI-Processor (5-10 s) bei haengendem `magick` (`magick_cli.lua:50,85,130,166,...`), UI friert dann ein (DoS-artig bei boeswilligem Bild).

---

## 7. PERFORMANCE

- **Caching**:
  - `transform_cache` (`utils/transform_cache.lua`): Schluessel = sha256 aus (kanonischer Quellpfad, mtime, size, Format, Zielgroesse, Crop, Processor, backend_crop, Output-Format) (`transform_cache.lua:40-53`); Ergebnis-PNG in `tmp_dir`; Invalidierung bei geaenderter Quelle (`93-100`); Validierung `filereadable` (140). Kein LRU/Limit.
  - Kitty: `transmitted_images[image.id] = "id-resize_hash"` verhindert erneutes Transmit bei gleicher Transformation (`kitty/init.lua:66-78`); Reset bei `VimResized` (20-25).
  - Sixel: LRU-Cache der Sixel-Daten (max 50 Eintraege, `sixel.lua:4,33-52,65-78`).
  - `document.lua:73-90`: Treesitter-Matches gecacht pro Buffer/`changedtick`.
  - Klon-Shortcut fuer dieselbe Datei (`image.lua:281-321`), `remote_cache` (`image.lua:375`).
  - Render-Skip wenn Geometrie/Hashes gleich (`renderer.lua:748-760`).
- **Async vs. Sync**:
  - **Async**: `MagickCliProcessor.transform` (`magick_cli.lua:231-271`, spawn + Callback), Transform-Queue mit Pending-Dedup (`renderer.lua:692-737`, `transform_cache.lua:135-171`), curl-Download (`image.lua:384`).
  - **Sync/blockierend**: `get_format`/`get_dimensions`-Fallbacks (`vim.wait` bis 5 s, `magick_cli.lua:50,130`) — nur wenn Magic-Bytes/Header-Parser versagen; `resize/crop/brightness/saturation/hue/convert_to_png` (`vim.wait` bis 10 s); Kitty schreibt mit `uv.sleep(1)` pro Chunk und pro Cursor-Move (`helpers.lua:87,138`) -> blockierend, bei grossen `t=d`-Uebertragungen (SSH) spuerbar; Sixel: `vim.fn.system` synchron (`sixel.lua:101`), `noautocmd mode` Redraw pro Flush (`sixel.lua:217`); `magick_rock.transform` laeuft in `vim.schedule` auf dem Main-Thread (`magick_rock.lua:56-78`), also **nicht** wirklich parallel.
- **Debounce/Throttle**: Event-Loop-Coalescing pro Key (`render_scheduler.lua`), Sixel-Timer 50 ms (`sixel.lua:5`). Kein Zeit-Debounce fuer `WinScrolled`/Decoration-Provider.
- **Nur sichtbarer Bereich**: `document.lua:92-102` rendert nur Matches innerhalb Viewport +/- Overscan (`max_height_window_percentage`% der Fensterhoehe); ausserhalb wird das Bild geclear-ed (302-304). Renderer clear-t Out-of-bounds/hinter Folds (`renderer.lua:357-370,585-601`).
- **Clear on scroll**: kein globales Clear; Neuberechnung/`clear(true)` pro Fenster ueber `WinScrolled` + Decoration-Provider (`init.lua:342-348,185-290`); bei Resize werden **alle** Bilder geleert und neu gerendert (`init.lua:165-180`) — im Code selbst als FIXME "horrible performance" markiert (`renderer.lua:265-266`).
- **Hot Paths**: `on_win` im Decoration-Provider laeuft bei jedem Redraw (Iteration ueber alle Bilder `api.get_images()` in `init.lua:208`, Fold-Schleife `while i < botline` mit `foldclosed`, `init.lua:262-272` -> O(botline) pro Redraw), `utils.window.get_windows` mit `win_execute` pro Fenster (`window.lua:9`).
- `max_width_window_percentage` Default 100, Hoehe 50 (`init.lua:54-55`).

---

## 8. PROS / CONS / RISIKEN / WARTUNG

**Pros**
- Sehr ausgereifte Kitty-Pipeline (Crop im Terminal, Extmark-basiertes Virtual Padding, Fold-/Scroll-/Konceal-Handling, tmux-Passthrough), gute Integrationsbreite (Markdown/Neorg/Typst/Org/Asciidoc/RST/HTML/CSS), kleine API, Test-Suite (`tests/`, busted; z. B. `tests/renderer/overlap_spec.lua`, `tests/backends/kitty_backend_spec.lua`).
- Arg-Listen statt Shell im Hauptpfad; asynchroner Transform mit Cache und Dedup.
- Aktiv gepflegt: v1.5.0 (2026-02-15), v1.5.1 (2026-02-21), Merge PR #382 am 2026-09-05 (Clone-HEAD). Shallow Clone: nur 1 Commit sichtbar; genaue Commit-Historie **UNVERIFIED**.

**Cons**
- **Kein Windows-Support** (ioctl, `tty`, `ps`, POSIX-Quoting, Pfad-Aufloesung, kein Windows-CI). Fehlermodus ist still (Abschnitt 4/1-Punkt).
- Keine Terminal-Erkennung, kein Health-Check, `q=2` verschluckt Terminal-Fehler; Default-Log-Pfad `/tmp/...`.
- WezTerm nur "not officially supported" (README:37).
- ImageMagick fast immer Pflicht; GIF ohne Animation; `magick_rock` braucht Build-Toolchain (README:59-65).
- Viele Module-Level-Seiteneffekte beim `require` (ffi.cdef, `io.popen("tty")`, `new_tty(1)`), `pcall`-lastige Fehlerbehandlung.
- Cache-Wachstum ohne Eviction, synchrone `vim.wait`-Pfade, `uv.sleep` im Render.
- README/Code-Drift (`rst` Default, `max_width_window_percentage`).

**Issue-Themen (leichtgewichtig, per WebFetch von github.com/3rd/image.nvim/issues, Stand Abruf)**: 58 offene Issues laut Repo-Header; sichtbare Windows-Treffer: #332 "Any chance for Windows Terminal support?" (closed 2026-02-10, Grund `ioctl`), #365 "Images sometime still rendered after switching tabs" (open, 2026-06-10). Keine WezTerm-spezifischen Issues in der Trefferliste. Weitere Themenanalyse: nicht durchgefuehrt (**UNVERIFIED**).

**Risiken fuer den User-Kontext (Windows 11 + WezTerm + natives Neovim)**
- Direkter Einsatz von 3rd/image.nvim: laut Code **nicht funktionsfaehig** (Punkt 1-5 im TL;DR). Ein Patch der Groessenabfrage (z. B. Zellgroesse per anderem Weg) wuerde nur den ersten Blocker beseitigen; der APC-Durchgang bleibt (laut User-Messung) offen.
- WSL-Neovim in WezTerm (Linux-Pfad, `ioctl` vorhanden) waere die einzige Konstellation, in der image.nvim plausibel laeuft; dort bleibt WezTerms Kitty-Halbunterstuetzung (README:37) und `enable_kitty_graphics` als Voraussetzung (**UNVERIFIED**).
- Design-Beobachtung fuer den eigenen Plugin-Vergleich: image.nvim loest das Problem "Zellgroesse in Pixeln" per `ioctl` und Ausgabe per direktem `stdout:write`; `images.nvim` des Users umgeht beides (OSC 1337 mit Zellmassen, `nvim_ui_send`), siehe `docs/architecture.md:26-31`.

---

## Anhang: Config-Befunde beim User (Beleg fuer "ist es ueberhaupt konfiguriert?")

- `$NVIM_CONFIG_DIR/lazy-lock.json`: Eintraege `snacks.nvim` (Zeile 50), **kein** `image.nvim`.
- `lua/plugins/snacks.lua:48-56`: `image = { enabled = false }`, Kommentar erklaert Kitty-Problem unter Windows/WezTerm.
- `lua/plugins/personal/init.lua:526-552`: `StefanBartl/images.nvim` mit `cmd = { "Image" }`, `opts = { display = { cell_aspect = 0.46 } }` (OSC-1337-Plugin als Ersatz).
- `lua/plugins/personal/init.lua:83,115`: `hover.nvim` mit `inline_images`-Option (auskommentiert `-- inline_images = true`).
- Terminal: WezTerm (`C:\Program Files\WezTerm` im PATH; Config-Loader `C:\Users\bartl\.config\wezterm\wezterm.lua` -> `$REPOS_DIR/Configs\Terminals\wezterm`; `enable_kitty_graphics` nirgends gesetzt). `magick` via Scoop im PATH (`.../scoop/apps/imagemagick/current`). Aktuelle Session `TERM=xterm-256color` (Git-Bash-Umgebung des Agenten, nicht zwingend die des Users).
