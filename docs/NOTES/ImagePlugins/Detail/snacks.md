# snacks.nvim `image` – Analyse (Commit 882c996, 2026-05-25, snacks v2.31.0)

Quelle: `C:\Users\bartl\AppData\Local\nvim-data\lazy\snacks.nvim`. Alle Pfade unten relativ dazu (`lua/snacks/image/…`).
Zeilenangaben beziehen sich auf genau diesen Stand. "UNVERIFIED" = nicht selbst nachgewiesen (vor allem alles, was ein *echtes* Terminal-Rendering voraussetzt).

---

## 0. Kurzfassung (warum "health gruen, aber nie ein Bild")

1. **Health prueft den Datenpfad nie.** Es wird nur geprueft: Binaries im PATH (`wezterm`, `magick`, `gs`, ...), ein XTVERSION-Reply (Terminalname) und Treesitter-Parser. Es gibt **keine einzige Kitty-Graphics-Abfrage** (`a=q`) im ganzen Plugin (Grep ueber `lua/snacks`: kein Treffer). Ob das APC-Escape (`ESC _G ... ESC \`) ueberhaupt beim Terminal ankommt und dort gezeichnet wird, wird nie getestet.
2. **Alle Terminal-Fehlermeldungen sind stumm geschaltet:** jedes Kitty-Kommando wird mit `q=2` gesendet (`terminal.lua:160`). WezTerm/Kitty melden Fehler daher nie zurueck, und Snacks liest ohnehin keine Antworten auf Grafik-Kommandos.
3. **Windows ist nicht wirklich unterstuetzt:** `terminal.size()` nutzt `ffi.C.ioctl` (`terminal.lua:63,88`), das unter Windows nicht existiert (selbst nachgewiesen: `cannot resolve symbol 'ioctl'`). Der `pcall` (`terminal.lua:85`) verschluckt das, es bleibt der hart codierte Fallback 9x18 px pro Zelle (`terminal.lua:73-83`). Health meldet diese Zeile trotzdem als **OK** (`init.lua:333-342`).
4. **WezTerm ist "eingeschraenkt"**: `placeholders=false` (`terminal.lua:24`) -> kein Inline-Rendering im Text; nur der Fallback-Pfad (`placement.lua:415-440`: Cursor positionieren + `a=p`), und der ist an Neovims Redraw-Reihenfolge gekoppelt.
5. **Wahrscheinlichste Ursache auf nativem Windows (Plausibilitaet, UNVERIFIED im Live-Terminal):** APC-Sequenzen aus nvim.exe erreichen WezTerm nicht (ConPTY/Neovim-Ausgabeschicht). Belege: eigene Repo-Doku (`E:\repos\images.nvim\docs\architecture.md:17-21`, `lua\images\terminal.lua:4-10`), WezTerm Issue #5757 ("Kitty image protocol doesn't work on Windows", iTerm2 funktioniert), 3rd/image.nvim Discussion #93 (Maintainer: kein natives Windows). Der XTVERSION-Reply (CSI/DCS) kommt durch – sonst waere Health nicht gruen – das ist mit "APC wird verschluckt, andere Klassen nicht" vereinbar.
6. **Aktuelle User-Config: `image = { enabled = false }`** (siehe Abschnitt 9). Hover/Placement-API laeuft trotzdem, wenn man sie direkt aufruft.

---

## 1. Architektur

### Modul-Layout (`lua/snacks/image/`)
| Datei | Zeilen | Rolle |
|---|---|---|
| `init.lua` | 381 | Defaults/Config (51-167), `supports*`, `hover()`, `setup()` (Autocmds), `health()` (303-379). Lazy Submodule-Loader via `__index` (10-18). |
| `terminal.lua` | 293 | Terminal-Erkennung, Env-Tabelle, `request()`/`write()` (Kitty-APC), Zellgroesse `size()`, tmux-Wrapping. |
| `convert.lua` | 500 | Konvertierungs-Pipeline (Schritte je Zieltyp), Prozess-Queue, Cache-Pfade. |
| `image.lua` | 216 | `snacks.Image`: eine (konvertierte) PNG-Datei + Kitty-Image-ID, `send()`, LRU. |
| `placement.lua` | 582 | `snacks.image.Placement`: ein Bild in einem Buffer/Fenster; Extmarks/Placeholder-Grid, Fallback-Rendering, State/Update. |
| `doc.lua` | 476 | Treesitter-Suche nach Bildern in Dokumenten, Transforms (latex/typst/norg/data-URI), `hover()`. |
| `inline.lua` | 152 | Inline-Verwaltung pro Buffer (Sichtbarkeitsfenster, Conceal bei Cursor, Debounce). |
| `buf.lua` | 54 | Bild-Buffer (`filetype=image`) fuer `BufReadCmd` und Picker-Preview. |
| `util.lua` | 89 | PNG-Header-Dimensionen, `fit()` in Zellen. |
| Queries | | `queries/{markdown,markdown_inline,latex,typst,html,css,scss,javascript,tsx,vue,svelte,norg}/images.scm` |

### Datenfluss Datei/Buffer -> Bildschirm
1. **Einstieg**
   - `BufReadCmd` auf `*.png,*.jpg,...` (`snacks/init.lua:195-204` -> `image.setup`, `image/init.lua:261-268`) -> `buf.attach` (`buf.lua:44-52`).
   - Dokumente: `FileType`-Autocmd; wenn der Treesitter-Lang eine `queries/<lang>/images.scm` hat (`init.lua:280-296`) -> `doc.attach` (`doc.lua:466-474`).
   - Picker-Preview: `preview.lua:45-49,118-120` -> `Snacks.image.buf.attach(buf, {src=path})`.
   - Manuell: `Snacks.image.hover()` (`init.lua:223`), `Snacks.image.placement.new(buf, src, opts)` (`placement.lua:51`, ruft selbst `Snacks.image.setup()`, Zeile 54).
2. **Terminal-Erkennung** asynchron/blockierend (`Terminal.detect(cb)`, siehe 3.), Callback erst danach.
3. **Convert** (`Image.new` -> `Convert.new`, `image.lua:50-75`, `convert.lua:252-274`): Kette von Schritten bis eine `.png` vorliegt (`Convert:resolve`, 327-341). Immer zum Schluss `identify` (339) – auch bei PNG-Quellen.
4. **Senden** (`Image:send`, `image.lua:141-182`): lokal `t=f` (Dateipfad base64-kodiert, das Terminal liest die Datei selbst, 145-151); bei SSH `t=d` in 4096-Byte-Chunks (152-180).
5. **Placement** (`Placement:update`, `placement.lua:517-576`):
   - Kitty/Ghostty (`placeholders=true`): `a=p, U=1` (virtuelles Placement, 551-560) + **Unicode-Placeholder-Grid** (`U+10EEEE` + Diakritika fuer Zeile/Spalte, 24-35, 226-369). Bild-ID steckt in der Vordergrundfarbe (`fg=img.id`, `sp=placement id`, 227-235). Das Grid liegt als **Extmarks** (`virt_text` inline / `overlay` / `virt_lines`, 276-368) im Buffer -> Neovim positioniert/scrollt/clippt das Bild "von selbst".
   - Alle anderen (WezTerm, tmux ohne Placeholder-Flag): **Fallback** (`render_fallback`, 415-440): `CSI row;col H` via `terminal.set_cursor` und `a=p, C=1, c=cols, r=rows`. Die Position wird aus `nvim_win_get_position` + Border berechnet (heuristische Tabline-Korrektur 423-430). Das Bild ist dem Terminal, nicht Neovim, "bekannt" -> anfaellig fuer Redraw-Reihenfolge und Scrollen. Fallback kennt kein Inline; nur Fenster (Hover-Float / Bild-Buffer / Picker-Preview).
6. **Lokalisierung/Groesse:** `Placement:state()` (449-508) berechnet Zellen aus `identify`-Info (Pixel/DPI * 96 * scale) oder PNG-Header (`util.fit`, `util.lua:50-87`), begrenzt durch Fensterbreite/-hoehe und `opts.max_width/max_height` (Default 80x40, `init.lua:82-83`).

### Inline Markdown/LaTeX/Mermaid
- `inline.lua`: pro Buffer eine Instanz; Autocmds `BufWritePost`, `WinScrolled`, `BufWinEnter` (19-23) + `on_lines` (33-35) -> `update` mit 100 ms Debounce (15-17). `update()` (90-150): `doc.find_visible` findet Treffer im **sichtbaren Bereich** (topline-1..botline, `doc.lua:213-229`), gleicht mit vorhandenen Placements ab (per `src`), erzeugt neue, aktualisiert bestehende, schliesst nicht mehr sichtbare.
- `doc.lua` nutzt Treesitter-Queries (`images.scm`), Captures `@image`, `@image.src`, `@image.content`, Metadaten `image.ext`, `image.type`, `image.lang` (32-36, 234-274).
  - Markdown: Standardbilder, Wikilink-Bilder (`![[x.png|opts]]`), `math`-Fencing (Blocks) -> `ext=math.tex`; **Mermaid**-Fencing -> `ext=chart.mmd` (`queries/markdown/images.scm`).
  - LaTeX-Inline/Display/Umgebungen (`queries/latex/images.scm`), Typst-`image()` und `math`.
  - Transforms (`doc.lua:39-102`): `latex` baut aus einem Template (`init.lua:151-165`) ein Standalone-Dokument (`\documentclass[preview,...]{standalone}`, Pakete aus Config + `\usepackage` des Dokuments, Header aus `snacks: header start/end`-Kommentaren, Farbe aus `SnacksImageMath`), `typst` analog, `data_img` dekodiert `data:image/...;base64` (55-70), `norg`.
  - `_img()` (277-339): Content wird als Datei `<sha256[1:8]>-content.<ext>` in den Cache geschrieben (324-337) und laeuft dann wie jede andere Datei durch die Convert-Pipeline (`.math.tex` -> tex-Schritt -> pdf -> magick -> png; `.chart.mmd` -> mmdc -> png).
- Inline nur wenn Terminal `placeholders` hat (`doc.lua:445`), sonst Hover-Float bei `CursorMoved` (455-462, `doc.hover` 369-434). "conceal" nur fuer `math` (`init.lua:88-90`); `conceal_lines` braucht nvim >= 0.11.4 (`placement.lua:323`).

### Picker-Integration
- `Snacks.picker.preview.file` uebergibt Dateien mit unterstuetzter Endung an `preview.image` (`preview.lua:118-120`) -> `Snacks.image.buf.attach` in einen Scratch-Buffer des Preview-Fensters (45-49). **Keine Terminal-Pruefung an dieser Stelle**; `buf._attach` zeigt im Nicht-Support-Fall einen Markdown-Text "terminal does not support..." (`buf.lua:13-28`). Ist `image.enabled=false`, greift der Text/Binary-Preview (`preview.lua:118`).
- Markdown-Previews (z. B. GitHub-Buffer) haengen `Snacks.image.doc.attach` ein (`picker/util/markdown.lua:39-41`).

---

## 2. CLI-Tools

Aufruf immer ueber `snacks.util.spawn` = `uv.spawn(cmd, {args=<Liste>, hide=true, stdio=pipes})` (`util/spawn.lua:147-156`), **keine Shell**. Platzhalter `{src}`, `{file}`, `{page}`, `{cache}`, `{dirname}`, `{scale}` werden per `Snacks.picker.util.tpl` in einzelnen Argumenten ersetzt (`convert.lua:429-433`).

| Schritt | Tool(s) | Argumente | Zeilen |
|---|---|---|---|
| `url` | `curl`, Fallback `wget` | `curl -L -o {file} {src}`; `wget -O {file} {src}` | 59-79 |
| `convert` (Raster/PDF/SVG/Video->PNG) | `magick`; **nicht-Windows** zusaetzlich `convert` | `{src}[0] -scale 1920x1080>` (raster), vector/pdf/math mit `-density 192 {src}[{page}] ...` (pdf: `-background white -alpha remove -trim`), angehaengt `-write {file} -identify -format "%m %[fx:w]x%[fx:h] %xx%y" {file}.info` | 165-197, Config `init.lua:129-135` |
| `identify` | `magick identify`, Fallback `identify` | `-format "%m %[fx:w]x%[fx:h] %xx%y" {src}[{page}]` | 129-164 |
| `tex` | `tectonic`, Fallback `pdflatex` | `tectonic -Z continue-on-errors --outdir {cache} {src}`; `pdflatex -output-directory={cache} -interaction=nonstopmode {src}`; `cwd={dirname}` | 89-119 |
| `typ` | `typst` | `typst compile --format pdf --pages 1 {src} {file}` | 80-88 |
| `mmd` | `mmdc` | `-i {src} -o {file} -b transparent -t <neutral|dark> -s {scale}` | 120-128, Config `init.lua:125-128` |
| `icns` | `sips` (macOS) | | 50-58 |
| PDF -> PNG | ImageMagick + **Ghostscript** (`gs`; nur ueber Health-Check, im Code kein direkter Aufruf) | ImageMagick-Delegate | Health `init.lua:349-353` |

- **Detection:** `vim.fn.executable(cmd) == 1`, Ergebnis pro Session gecacht in `have[]` (`convert.lua:200,226-233`). Erster verfuegbarer Kandidat gewinnt. Nicht verfuegbar -> Fehler `"No command available"` (411-414).
- **ffmpeg wird nie aufgerufen.** Videos (`mp4,mov,avi,mkv,webm`) laufen durch `magick file[0]`, also ImageMagicks eigenes Video-Delegate (braucht ffmpeg im PATH, UNVERIFIED). Nur der erste Frame; keine Animation.
- **Windows `magick` vs `convert.exe`:** Snacks behandelt die Kollision explizit: `convert`-Fallback nur wenn `not Snacks.util.is_win` (`convert.lua:194`), Health analog (`init.lua:312-313`). `C:\WINDOWS\system32\convert.exe` (Dateisystem-Tool) wird also nie aufgerufen. Umgekehrt gibt es **keinen** Fallback, wenn nur `convert` (alt IM6) vorhanden waere. `identify` als Fallback (`convert.lua:139-142`) ist unter Windows unkritisch.
- **PNG braucht trotzdem ImageMagick**: `Convert:resolve` haengt immer `identify` an (339). Ohne `magick`/`identify` -> Schritt-Fehler -> Bild schlaegt fehl. Die Health-Meldung "Only PNG files will be displayed" (`init.lua:314`) ist damit falsch/irrefuehrend (Ausnahme: der Schritt ist "done", wenn `.info` bereits im Cache liegt, 312, 405-409).
- **Timeouts:** `Spawn` unterstuetzt `timeout` (`spawn.lua:171-176`), `Convert:step` uebergibt aber **keinen** (`convert.lua:435-448`). Haengende Prozesse (mmdc/Chromium, tectonic beim Paket-Download, curl) blockieren fuer immer einen der `MAX_PROCS=3` Slots (203-218).
- **Cache:** `stdpath("cache") .. "/snacks/image"` (`init.lua:107`); auf dieser Maschine `C:\Users\bartl\AppData\Local\Temp\nvim/snacks/image` (selbst per `nvim --clean --headless` geprueft; gemischte Separatoren, weil `/snacks/image` angehaengt wird). Dateiname = `sha256(src..page)[1:8] .. "-" .. base` mit `base` bereinigt (`[^%w%.]+` -> `-`, `convert.lua:260-264`); Endung nach Schritt (`.png`, `.pdf`, `.data`, `.<bg>.png`, `.info`).
- **Kein Invalidieren:** Schritt gilt als erledigt, wenn die Zieldatei existiert (`convert.lua:312, 405-409`), Schluessel enthaelt nur den Pfad, **nicht mtime**. Wird ein Bild an gleicher Stelle geaendert, sieht man dauerhaft den alten Cache-Stand. In-Memory `images[file]` (`image.lua:20,54`) ebenfalls ohne Invalidierung. Keine Cache-Bereinigung im ganzen Modul (kein `fs_unlink` von Cache-Dateien ausser bei `url`-Fehler, 74-78).
- Wegen 8-Hex-Praefix (32 Bit) sind Kollisionen theoretisch moeglich, praktisch harmlos.

---

## 3. Terminal-Erkennung & Protokoll

### Env-Tabelle (`terminal.lua:7-38`)
| Name | Match | supported | placeholders |
|---|---|---|---|
| kitty | XTVERSION-Terminalname enthaelt `kitty` | true | true |
| ghostty | `ghostty` | true | true |
| **wezterm** | `wezterm` | true | **false** |
| tmux | Env `TERM~tmux` oder `TMUX` gesetzt | (erbt) | (erbt); `allow-passthrough all` + DCS-Wrapping (`\ePtmux;...`) |
| zellij | Env `TERM~zellij` / `ZELLIJ` | **false** | false |
| ssh | `SSH_CLIENT`/`SSH_CONNECTION` | | `remote=true` -> Bilddaten werden komplett uebertragen |

- **Nur XTVERSION, keine Env-Sniffing fuer Terminals:** `terminal.lua:290` sendet `ESC[>q`; `TermResponse` (268-281) parst `P>|<name> <version>` (272). Timeout **1000 ms** (283-288), danach `terminal="unknown"` -> unsupported. Sync-Variante wartet bis 1500 ms (`vim.wait`, 197-209) und wird von `M.env()` genutzt, wenn noch nie erkannt wurde (114-116) -> potenzielle Startblockade bis 1,5 s.
- Env-Variablen (`SNACKS_KITTY`, `SNACKS_WEZTERM`, `SNACKS_GHOSTTY`, `SNACKS_TMUX`, ... = `0/false` oder sonst an) uebersteuern die Erkennung (`terminal.lua:122-125`). `config.force=true` erzwingt `supports_terminal` (`init.lua:70,219`), aber die `placeholders`-Entscheidung bleibt am Env haengen.
- **tmux:** `allow-passthrough all` wird per `tmux set -p` gesetzt (`terminal.lua:30,250`), Fehler per `pcall` ignoriert; Sonderpfad bei `extended-keys on`: Terminalname per `tmux display-message #{client_termname}` (254-265). Ohne tmux-Rechte/aeltere tmux-Versionen still kein Bild. Unter Windows praktisch irrelevant.
- **`M.env()` wird beim ersten Aufruf gecacht (`terminal.lua:111`)** – eine Fehlerkennung bleibt fuer die ganze Sitzung.
- **WezTerm unter Windows:** Kein Sonderfall im Code. WezTerm zaehlt als `supported=true, placeholders=false`, sobald XTVERSION "WezTerm <ver>" zurueckkommt. Es gibt keinen `jit.os`/`is_win`-Zweig in `terminal.lua`.
- Zellgroesse: `ioctl(TIOCGWINSZ)` mit `TIOCGWINSZ` nur fuer linux/mac/bsd gesetzt (`terminal.lua:66-71`); unter Windows `nil` + `ffi.C.ioctl` unresolvable -> Fallback 9x18 (`73-83`), `scale = 9/8`. Keine CSI-`16t`-Abfrage. Konsequenz: falsche Zellzahlen (`util.pixels_to_cells`, `util.lua:30-36`), Mermaid-Scale `-s 1.125` (`convert.lua:270`). Auch das Beispiel aus 3rd/image.nvim (`ioctl` unresolvable, Discussion #93) ist dieselbe Ursache – Snacks faengt es per `pcall` ab und ist damit "still degradiert" statt abzustuerzen.
- Ausgabe: `vim.api.nvim_ui_send` wenn vorhanden (nvim 0.12), sonst `io.stdout:write` (`terminal.lua:184-191`). Die eigene Repo-Doku behauptet, `io.stdout:write` zeichne nur einmal pro Terminal-Session (`images.nvim/lua/images/terminal.lua:12-14`); mit 0.12.2 nutzt Snacks `nvim_ui_send` (also die "richtige" Variante).
- WezTerm liest `t=f` Dateipfade (Base64-Pfad, kein Windows-Sonderfall im Quelltext `termwiz/src/escape/apc.rs`, `KittyImageData::File`, Tag 20240203) -> Transfer per Datei ist auf Windows *nicht* das Problem (UNVERIFIED im Live-Betrieb).

### Was Health prueft / nicht prueft (`init.lua:303-379`)
Prueft (alles "existiert / wurde gemeldet"):
- `Snacks.health.have_tool({kitty, wezterm, ghostty})` -> `vim.fn.executable` + `--version` (`health.lua:75-122`). Das prueft **PATH**, nicht ob Neovim in diesem Terminal laeuft. Gruen, sobald `wezterm.exe` im PATH liegt (hier: `C:\Program Files\WezTerm\wezterm.exe`).
- `magick` (Windows ohne `convert`), Detected-Env aus XTVERSION-Erkennung, "Terminal Dimensions" (immer `ok`, auch bei Fallback), Treesitter-Parser, `gs`, `tectonic|pdflatex`, `mmdc`, Abschluss "your terminal supports the kitty graphics protocol" wenn `env.supported`.

Prueft **nicht**:
- Ob APC ueberhaupt beim Terminal ankommt (kein `a=q`-Roundtrip, kein `q=1/0`-Test, keine Antwort-Auswertung).
- Ob WezTerm-Kitty-Support aktiv ist (`enable_kitty_graphics`).
- Ob die echte Zellgroesse bekannt ist (Fallback wird als "ok" ausgegeben).
- Ob eine Kette Windows/ConPTY/Multiplexer die Sequenzen weiterreicht (Ausnahme nur tmux-Passthrough-Setzung).
- Ob Bild-Konvertierung tatsaechlich funktioniert (kein Testlauf `magick`, kein Test von gs-Delegate).
- Ob PNG ohne ImageMagick geht (Health verspricht es, Code nicht, siehe 2.).

---

## 4. Failure-Modes (stumm oder fast stumm)

| # | Pfad | Beleg | Sichtbarkeit |
|---|---|---|---|
| 1 | Alle Kitty-Kommandos mit `q=2` | `terminal.lua:160` | Terminal-Fehler nie sichtbar |
| 2 | Kein Kitty-Query/Probe; nur XTVERSION | `terminal.lua:268-290` | Falsch-Positive: erkannt = "supported" |
| 3 | APC durch ConPTY/Neovim-Output nicht durchgereicht (UNVERIFIED) | s. 0.5 | Health gruen, Bildschirm leer |
| 4 | `ffi.C.ioctl` unter Windows -> `pcall` -> Fallback 9x18 | `terminal.lua:85-101` | Bild ggf. falsch skaliert; Health "OK" |
| 5 | Inline-Fehler: `Placement:error()` kehrt bei `opts.inline` sofort zurueck | `placement.lua:113-115` | Kein Hinweis |
| 6 | Hover-Float wird erst in `on_update_pre` angezeigt (`win:show()`), das nur nach erfolgreicher Konvertierung feuert | `doc.lua:405-411` | Bei Convert-Fehler erscheint nichts |
| 7 | Convert-Fehler werden nur bei `convert.notify=true` gemeldet (Default `false`) | `init.lua:123`, `convert.lua:372-379` | still |
| 8 | Bild-Datei nicht gefunden -> `_err` gesetzt, sonst nichts | `convert.lua:457-461` | still |
| 9 | Format-Filter fehlt fuer Doc-Inline: beliebige `src` wird an ImageMagick gegeben; Ergebnis unklar/Fehler | `doc.lua:321`, `inline.lua:109` | still |
| 10 | `M.env()` cached Fehlerkennung fuer die ganze Sitzung | `terminal.lua:111` | dauerhaft |
| 11 | Detection-Timeout 1 s (`unknown`) | `terminal.lua:283-288` | unsupported ohne Hinweis ausser Health |
| 12 | Neovim antwortet auf XTVERSION nicht (tmux `extended-keys`, Mux) | `terminal.lua:254-265` Kommentar | Workaround nur fuer tmux |
| 13 | tmux: `allow-passthrough` Setzung via `pcall(vim.fn.system,...)` | `terminal.lua:30,250` | fehlende Rechte still |
| 14 | Cache nie invalidiert -> veraltete Bilder | `convert.lua:312,405` | Fehlbild statt Fehler |
| 15 | Prozess ohne Timeout blockiert Queue-Slot | `convert.lua:203-218,435` | "Bild laedt ..." ewig (`placement.lua:144-173`) |
| 16 | `treesitter`-Parser fehlt -> `find` liefert `{}` (`pcall(get_parser)`) | `doc.lua:235-238`, Health `init.lua:344-347` (nur warn) | still |
| 17 | `zellij` explizit `supported=false` | `terminal.lua:36` | nur Health rot |
| 18 | Fallback-Position ueber `set_cursor` + Border/Tabline-Heuristik | `placement.lua:423-430` | leichte Versaetze (kein Kalibrierwerkzeug) |
| 19 | `image.enabled=false` (User): `BufReadCmd`/Doc-Attach aus (`snacks/init.lua:195`, `init.lua:280`), `hover()` aber weiterhin ungeschuetzt (`doc.lua:369-434` prueft weder `enabled` noch `supports_terminal`) | | sendet Kitty-APC selbst auf nicht-Kitty-Terminals |

### Debug-/Log-Facility
- `config.debug = { request, convert, placement }` (`init.lua:108-112`): `request` -> `Snacks.debug.inspect(opts)` fuer jedes gesendete Kommando (`terminal.lua:173-175`, nur `m ~= 1`); `convert` -> `Proc:debug()`-Notification pro Prozess (`convert.lua:437`, `spawn.lua:83-106`); `placement` faerbt Placeholder-Zellen rosa `#FF007C` (`placement.lua:232`) – `Placement:debug()` selbst ist hart deaktiviert (`if true or ...`, `442-444`).
- `convert.notify = true` (`init.lua:123`) zeigt Fehler inkl. Kommando/Output.
- `:checkhealth snacks`. Interaktiv: `:lua =Snacks.image.terminal.env()`, `:lua =Snacks.image.terminal._terminal`, `:lua =Snacks.image.terminal.size()`.
- Es gibt **keine** User-Commands (`grep create_user_command` in `snacks/image`: keine Treffer), kein Logfile.

---

## 5. Features
- **Formate:** `png jpg jpeg gif bmp webp tiff heic avif mp4 mov avi mkv webm pdf icns` (`init.lua:52-69`; dupliziert in `snacks/init.lua:27-…`, damit das Modul nicht geladen werden muss). **SVG nicht in der Default-Liste**, aber die Convert-Logik kennt `svg/eps/ai/mvg` als Vector (`convert.lua:173`); man muss `svg` selbst in `formats` eintragen. Docs (`docs/image.md:8-9`) nennen zusaetzlich nichts Weiteres.
- **Konvertierung nach PNG** via ImageMagick, PDF (Seite mit `#page=N`, `convert.lua:487-493`), Typst-Dokumente (`.typ`), TeX-Dokumente (`.tex`), Mermaid (`.mmd`), macOS `.icns`.
- **Inline-Doc-Rendering** fuer markdown, html, norg, tsx, javascript, css, scss, vue, svelte, latex, typst (`Snacks.image.langs()` = Liste der `images.scm`, `init.lua:228-233`), Unicode-Placeholder-abhaengig (nur Kitty/Ghostty).
- **Math:** LaTeX in markdown (`$..$`, `$$..$$`, ```` ```math ````) und LaTeX-Buffer, Typst-Math; Theme-Farbe aus `SnacksImageMath` (`init.lua:180-185`); `doc.conceal` nur fuer math.
- **Mermaid:** ```` ```mermaid ```` in markdown via `mmdc`; Theme nach `vim.o.background` (`init.lua:125-128`).
- **Remote-URLs:** `curl`/`wget` (siehe 2.), Query-String im Cache-Namen entfernt (`convert.lua:262`).
- **data-URIs** (`doc.lua:55-70`).
- **Animation:** keine (nur erster Frame: `{src}[0]`, `convert.lua`/`init.lua:131`). Video = Standbild.
- **Skalierung:** `doc.max_width/max_height` = 80/40 (`init.lua:82-83`); `placement.opts.width/height/min_*/max_*` (`placement.lua:468-475`); raster `-scale 1920x1080>` (`init.lua:131`); PDF-Density 192.
- **Cursor-Follow / Hover:** `Snacks.image.hover()` mit Float-Style `snacks_image` (`relative=cursor`, `init.lua:170-178`), schliesst bei `CursorMoved/ModeChanged/BufLeave/BufWritePost` (`doc.lua:421-432`). Fuer Nicht-Inline-Terminals automatisch aktiv (`doc.float=true`, `doc.lua:455-462`).
- **Bild-Buffer** (`filetype=image`) beim Oeffnen von Bilddateien mit `auto_resize` (`buf.lua:30-38`, `placement.lua:65-83`); `BufWriteCmd` unterbindet Ueberschreiben (`init.lua:270-278`).
- **Picker-Preview:** ja (Abschnitt 1).
- **API:** `Snacks.image.{hover, supports, supports_file, supports_terminal, langs, setup, health, doc, buf, placement, convert, terminal, inline, util, image}`; Config `resolve(file, src)` fuer Pfadaufloesung (`init.lua:46-49`, `doc.lua:181-209`), `img_dirs` (`init.lua:93`).
- **Commands:** keine.

---

## 6. Security
- **Kein Shell-String, keine Shell-Injection**: alle Aufrufe per `uv.spawn` mit Argumentliste (`spawn.lua:147-156`). `src` kann nicht mit `-` beginnen (lokale Pfade werden absolut gemacht: `norm`, `convert.lua:477-485`; URLs muessen `^%w%w+://` matchen, 472-474).
- **URL-Fetch ohne Haertung:**
  - `curl -L -o {file} {src}` (`convert.lua:63`): **kein** `--proto =http,https`, **kein** `--max-filesize`, **kein** `--max-time`, folgt Redirects. `is_uri` akzeptiert jedes Schema mit >=2 Zeichen (`^%w%w+://`, 472-474); nur `file://` wird umgeschrieben (478-480). Also werden auch `ftp://`, `dict://`, `gopher://`, `sftp://` usw. an curl gereicht (Verhalten haengt von der curl-Build ab).
  - Ergebnis: Ein geoeffnetes Markdown mit `![](http://intern/…)` loest beim **blossen Sichtbarwerden** einen Request aus (SSRF-aehnlich: localhost, Metadaten-Endpunkte, Tracking-Pixel; Antwort wird dann von ImageMagick geparst). Kein Allow-/Deny-Listing, keine Nachfrage, kein Limit.
- **ImageMagick-Angriffsflaeche:** Inhalt (auch heruntergeladene Fremd-Bytes, Dateiendung `.data`) wird von `magick` anhand des Inhalts erkannt -> alle in der IM-Policy freigegebenen Coder (SVG/MVG/MSL/PDF/PS ueber Ghostscript). Snacks setzt keine `-limit`-/`-define`-Optionen, keine `policy.xml`-Pruefung (UNVERIFIED, wie gut die Scoop-Standardpolicy ist). Ghostscript bei PDF/PS ebenfalls (historische `-dSAFER`-Themen; hier nur ueber IM-Delegate).
- **LaTeX/Typst/Mermaid = Codeausfuehrung aus Buffer-Inhalt:**
  - `pdflatex`-Aufruf **ohne** `-no-shell-escape` (`convert.lua:104`); es gilt die Distribution-Default (TeX Live: restricted shell escape). Mit `\input`/`\openin` lassen sich beliebige Dateien einlesen und rendern. Inhalt kommt aus Markdown-`math`-Bloecken (`doc.lua:71-101`, unsanitisiert).
  - `tectonic` laedt Pakete/Bundles nach; `typst compile` kann `@preview`-Pakete laden (Netzwerkzugriff durch Dokumentinhalt).
  - `mmdc` startet Headless-Chromium (Puppeteer) fuer Mermaid-Inhalt aus dem Buffer.
  - Da Rendering automatisch beim Oeffnen einer Datei passiert (Doc-Attach ist bei aktiviertem Modul Default `doc.enabled=true`, `init.lua:71-74`), gilt: **das Oeffnen unvertrauenswuerdiger Markdown/LaTeX-Dateien kann Tools mit deren Inhalt ausfuehren.**
- **Dateinamen:** Cache-Namen werden bereinigt (`[^%w%.]+ -> -`, `convert.lua:264`), Endung stammt aus `image.ext` (Query-Meta, nicht vom Nutzer) bzw. Format. Pfade werden nicht gegen Traversal begrenzt: `doc.resolve` probiert `cwd`, Dateiverzeichnis und `img_dirs` (`doc.lua:188-207`), `../../`-Pfade sind erlaubt. Kein Format-Filter fuer Inline (siehe Failure #9).
- **Temp/Cache:** Vorhersagbare Namen (`<sha8>-<base>.<ext>`) in `%TEMP%\nvim` (Windows pro Benutzer, okay); `io.open(img.src, "w")` ohne Symlink-/Exists-Race-Schutz (`doc.lua:332-336`, nur Bedeutung auf Mehrbenutzer-/tmp-Systemen).
- **Limits:** `MAX_FSIZE = 200 MB` nur fuer die LRU der *gesendeten* Bilder (`image.lua:15,40-44`), kein Limit fuer Download-/Datei-Groesse, Bildaufloesung oder Prozessdauer.
- **Terminal-Injection:** Der Escape-Output enthaelt nur Snacks-generierte Zahlen + Base64 (`terminal.lua:159-177`), keine rohen Nutzerdaten.

---

## 7. Performance
- **Async Konvertierung**, `uv.spawn`, globale Queue mit `MAX_PROCS=3` (`convert.lua:201-218`).
- **Disk-Cache** (ohne Eviction/Invalidierung, s. o.) + **Memory-Cache** `images[file]`, `dims[file]` (`util.lua:4`), `dir_cache` (`doc.lua:106`), Buffer-Cache pro `changedtick` fuer Header/Pakete (`doc.lua:112-121`).
- **Sichtbarkeitsbegrenzung:** Inline arbeitet nur im Fensterbereich `topline-1..botline` (`doc.lua:213-229`, `inline.lua:58-67`); Treesitter nur ueber diesen Bereich (`Snacks.util.parse(parser, {from,to})`, `doc.lua:241`).
- **Debounce:** Inline-Update 100 ms (`inline.lua:15-17`), Placement-Update 10 ms (`placement.lua:105-108`). `Placement:update` bricht bei `vim.deep_equal(state, self._state)` ab (`placement.lua:531-535`) -> Duplikat-Vermeidung.
- **Dedupe:** Bilder pro konvertierter Datei (`image.lua:54-55`), Placements per `src` in `inline.update` (`inline.lua:100-106`).
- **LRU** der an das Terminal gesendeten Bilder bis 200 MB, danach `sent=false` -> Neu-Senden (`image.lua:26-47`); Ghostty-Groessenschaetzung (`image.lua:82-84`).
- **Lokal `t=f`**: nur der Pfad wird uebertragen (kein Pixeltransfer). **SSH**: 4 KB-Chunks mit `uv.sleep(1)` pro Chunk -> **blockiert die UI** (`image.lua:152-180`); bei 5 MB ca. 1300 Chunks (~1,3 s+).
- **Groessen-Caps:** Raster `-scale 1920x1080>`, PDF `-density 192` + `-trim`; Grid maximal `#diacritics` (297) Zellen je Achse (`placement.lua:237-238`).
- **Lazy Loading:** Modul wird erst bei `BufReadCmd`/`FileType`/API-Zugriff geladen; Formate absichtlich dupliziert in `snacks/init.lua`.
- **Kosten/Risiken:** synchrones `vim.wait` bis 1,5 s in `Terminal.detect()`-sync/Health (`terminal.lua:206`, `init.lua:308`); `Snacks.health.have_tool` startet `--version` per `vim.fn.system` (blockierend, nur Health).
- Spawn pro Bild: Raster (nicht-PNG) = 1 Prozess (Info wird via `-write ... -identify ... .info` mitgeschrieben, deshalb ist der `identify`-Schritt "done", `convert.lua:191,312`); PNG = 1 `magick identify`; URL = curl + identify + convert.

---

## 8. Pro / Contra / Risiken
**Pro**
- Sehr runde Kitty-Integration mit Unicode-Placeholders: Bilder sind echte Buffer-Inhalte (Extmarks), scrollen/clippen/falten mit, Inline-Markdown/Math/Mermaid sind elegant; Sichtbarkeits-/Debounce-Design gut.
- Async-Pipeline mit Prozess-Queue, Disk-Cache, LRU; lokal keine Pixeluebertragung.
- Breite Formatabdeckung ueber ImageMagick (inkl. PDF, HEIC, AVIF), Doc-Integration in 11 Sprachen, Picker-Preview.
- Keine Shell, sauber ueber Argumentlisten.
- Gute Config-/Debug-Hooks (`debug.*`, `convert.notify`, `SNACKS_*`).

**Contra / Risiken**
- **Health beweist nichts ueber das Rendering** (keine Grafik-Probe, `q=2`, OK-Zeile auch bei Fallback-Zellgroesse).
- **Windows:** `ioctl` nicht vorhanden -> feste Zellgroesse; unter WezTerm/ConPTY vermutlich keine APC-Zustellung (UNVERIFIED); keine Windows-spezifische Erkennung/Dokumentation.
- WezTerm: keine Placeholders -> kein Inline, nur Fallback; laut Docs "limited support" (`docs/image.md:18-20`), laut Maintainer von image.nvim schlechte Performance bei WezTerm (Discussion #93, Zitat aus der Diskussion, nicht selbst geprueft).
- Cache ohne Invalidierung/Eviction; alte Bilder bleiben.
- Keine Timeouts; keine Download-Limits; kein Protokoll-Whitelisting -> SSRF/Parsing-Risiko bei fremden Dokumenten; LaTeX ohne `-no-shell-escape`.
- Viele stumme Fehlerpfade (Inline und Hover schlucken Konvertierungsfehler).
- `hover()` ignoriert `enabled`/`supports_terminal`.
- Video/GIF nur Standbild; kein SVG in den Default-Formaten.
- Einzelne tote/deaktivierte Debugpfade (`Placement:debug`).

---

## 9. Die tatsaechliche User-Konfiguration und Fehlkonfigurationen

### Snacks
`C:\Users\bartl\AppData\Local\nvim\lua\plugins\snacks.lua:37-63`: `image = { enabled = false }` (Zeile 56), mit Kommentar 48-55 (Kitty-Sequenzen aus nativem Windows-nvim in WezTerm werden nie gezeichnet). Rest: `debug.enabled=true`, `quickfile=true`, `picker=config.snacks.picker`; `dim/profiler/scope/scratch/toggle/words/bigfile/notifier` aus.
- Historie (`git log -S image`, nvim-Config-Repo): `image = { enabled = true }` seit Initial-Commit (336ddeb92, 2026-07-24) bis `986842d6c` (2026-09-18, "snacks.image off"). Also lief die Modul-Variante tatsaechlich mit Default-Optionen (`formats`, `doc.inline=true`, `doc.float=true` usw.) ohne `force`, ohne `debug`, ohne `convert.notify`.
- Kein `image`-Override von `formats`, `convert`, `cache`, `env`, `force`, `debug`.
- Weitere Nutzung: keine `Snacks.image.*`-Aufrufe im Lua-Tree (Grep `lua`: 0 Treffer). Doku-Verweis `docs/ROADMAP/reports/Externe-Plugins-Nachbau-Analyse.md:606-621` (Abschnitt 7.1) bestaetigt die Deaktivierung und weist darauf hin, dass sie nicht live verifiziert wurde, sondern auf `images.nvim/docs/scope.md` beruht.

### Terminal
- WezTerm `20240203-110809-5046fc22`, `C:\Program Files\WezTerm\` (mit `conpty.dll` + `OpenConsole.exe` gebuendelt).
- Einstieg `C:\Users\bartl\.config\wezterm\wezterm.lua` -> laedt `E:\repos\Configs\Terminals\wezterm\init.lua` (`REPOS_DIR=E:\repos`). Dort **keine** Einstellung `enable_kitty_graphics` (Grep: nur `terminal_safety.lua:23 enable_kitty_keyboard = false`). Padding in Zellen wegen OSC-1337 (`config/experimental.lua:60-68`), `default_prog` via `config/powershell.lua`.
- **`enable_kitty_graphics` ist damit kein Konfigurationsfehler:** laut `config/src/config.rs` im Tag 20240203 (Zeilen 273-274, `#[dynamic(default = "default_true")]`, gelesen ueber WebFetch, moderat verlaesslich) ist der Default `true`. (Ein Web-Suchtreffer behauptete Gegenteiliges – wohl Altstand; hier nicht anwendbar.) Widerspruch/Offene Frage: die eigene Repo-Doku sagt, "in a raw pwsh both protocols work" – ob das mit `wezterm imgcat` (nur iTerm2) oder echten Kitty-APC getestet wurde, ist UNVERIFIED.
- Neovim `0.12.2` (`nvim_ui_send` vorhanden, `vim.base64` vorhanden – selbst geprueft), LuaJIT 2.1, `jit.os = Windows`.

### Tools im PATH (PowerShell `Get-Command`)
| Tool | Ergebnis |
|---|---|
| `magick` | `C:\Users\bartl\scoop\apps\imagemagick\current\magick.exe` (zusaetzlich `WindowsApps\magick.exe`, App-Alias, Funktion UNVERIFIED) |
| `identify` | scoop + WindowsApps |
| `convert` | `C:\WINDOWS\system32\convert.exe` (Dateisystem-Tool) – von Snacks unter Windows korrekt **nicht** benutzt |
| `gs` / `gswin64c` | scoop-Shim + `C:\Program Files\gs\gs10.05.1\bin\gswin64c.exe` |
| `curl` | `C:\WINDOWS\system32\curl.exe` (+ Git-mingw curl); `wget` fehlt |
| `tectonic`, `pdflatex`, `mmdc`, `typst` | **nicht gefunden** (Math/Mermaid/Typst-Doku-Rendering kann nicht funktionieren; Health nur `warn`) |
| `ffmpeg` | vorhanden (winget), von Snacks nie direkt genutzt |
| `kitty` | nicht installiert |

-> Fuer PNG/JPG/PDF sind die Konvertierungstools also vorhanden; das Problem liegt nicht bei fehlenden CLI-Tools, sondern beim Terminal-Pfad. (`TERM_PROGRAM`/`TERM` waren in meiner Tool-Shell leer – die liegt nicht in WezTerm, daher ohne Aussage.)

### Identifizierte Fehlkonfigurationen / Auffaelligkeiten
1. `image.enabled` war bis 2026-09-18 an, ohne `force`/Debug/Notify -> alle Fehler stumm. Jetzt aus (bewusste Entscheidung).
2. `mmdc`, `tectonic`/`pdflatex`, `typst` fehlen -> Mermaid/Math/`.typ`/`.tex`-Rendering unmoeglich (Health warnt nur).
3. Kein `convert.notify = true`, kein `debug.request/convert` -> kein Diagnosepfad.
4. `wezterm.exe` im PATH -> Health-`have_tool` gruen, unabhaengig davon, in welchem Terminal Neovim laeuft.
5. Windows-Zellgroesse-Fallback aktiv (9x18).
6. Wichtig: `Snacks.image.hover()` bleibt trotz `enabled=false` aufrufbar und sendet APC.

---

## 10. Vorschlag fuer minimale Diagnose (nur lesend/kurz, nicht ausgefuehrt)
1. In WezTerm-nvim: `:lua =Snacks.image.terminal.env()` und `:lua =Snacks.image.terminal._terminal` (zeigt `wezterm`, `supported`, `placeholders=false`).
2. `debug = { request = true }`, `convert = { notify = true }` setzen und `Snacks.image.hover()` auf einem PNG-Link aufrufen.
3. Direkttest der Zustellung: aus `nvim_ui_send` ein Kitty-APC mit `q=0` (Antwort erwuenscht) senden und mit `TermResponse` mithoeren; ausserdem dasselbe Bild ueber `t=d` (Direktdaten) statt `t=f`. Wenn nichts ankommt: APC wird vor WezTerm verschluckt (ConPTY).
4. Vergleich: gleiche APC-Bytes aus reiner PowerShell (ohne nvim) ausgeben.
5. Alternativen: WSL2 (nvim unter Linux; WezTerm-Kitty-Rendering dort), oder OSC 1337 wie `images.nvim`.

---

## Quellen (extern, nicht selbst im Terminal verifiziert)
- WezTerm Issue #5757 "Kitty image protocol doesn't work on Windows": https://github.com/wezterm/wezterm/issues/5757
- 3rd/image.nvim Discussion #93 (Windows): https://github.com/3rd/image.nvim/discussions/93
- WezTerm `config/src/config.rs` @20240203-110809-5046fc22 (`enable_kitty_graphics` default_true) und `termwiz/src/escape/apc.rs` (`KittyImageData::File`): https://github.com/wezterm/wezterm
