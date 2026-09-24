# images.nvim — Analyse für den Vergleich (vs. 3rd/image.nvim, snacks.image)

Stand: Worktree `$REPOS_DIR/images.nvim\.claude\worktrees\nvim-image-plugins-review-d6d0c2`, HEAD `8a865c2` (2026-09-20), 187 Commits seit 2026-08-05.
Alle Pfade relativ zum Repo-Root. Belegt sind `Datei:Zeile`. "UNVERIFIED" = nicht selbst geprüft.
Lokal verifiziert: Testsuite läuft grün (`LIB_NVIM_PATH=$REPOS_DIR/lib.nvim nvim --headless -u NONE -l TESTS/run.lua` -> `IMAGES_TESTS_OK`, Windows 11); Arbeitsbaum danach unverändert (`git status` sauber).

---

## 0. Kurzfazit zur Zentralfrage ("wie wird sichergestellt, dass wirklich gerendert wird?")

**Kurz: gar nicht. images.nvim hat KEINE aktive Terminal-Probe.** Es gibt keine Abfrage, die eine Antwort des Terminals erwartet.

- Die "Erkennung" ist reines Env-Var-Sniffing gegen eine Whitelist aus drei Terminals (WezTerm, iTerm2, Konsole): `lua/images/terminal.lua:81-101`, Auswertung `terminal.lua:114-155`.
- Nichts wird gesendet, kein Reply wird erwartet, kein Timeout: `grep TermResponse|DA1|XTVERSION|nvim_create_autocmd TermResponse` im gesamten `lua/` = 0 Treffer; headless verifiziert: nach `setup()` sind 0 `TermResponse`-Autocmds registriert.
- `:Image check` (`lua/images/bindings/usrcmds.lua:330-336` -> `images.recheck()` `lua/images/init.lua:752-762`) setzt nur den Memo-Cache zurück und liest dieselben Env-Vars nochmal. Es sendet nichts ans Terminal.
- Der "Probe" aus dem letzten Commit (`8a865c2`, "terminal probe is protocol-generic") ist ein **manueller Shell-Befehl in der Doku** (`printf '\033]1337;File=inline=1;preserveAspectRatio=1:%s\a' "$(base64 < picture.png | tr -d '\n')"`, `docs/troubleshooting.md:22-28`, `doc/images.txt` ~841-852). Der Mensch führt ihn außerhalb von Neovim aus und schaut aufs Bild. Kein Code im Plugin. Der Commit ändert nur Doku (3 Dateien: `doc/images.txt`, `docs/WORKFLOW.md`, `docs/troubleshooting.md`).
- **Doku-vs-Code-Mismatch (wichtig):** Mehrere Doku-Stellen behaupten, `:Image check` sage, ob OSC 1337 "actually getting through *right now*" (`docs/health.md:30-33`, `docs/commands.md:250-252`, `docs/troubleshooting.md:13`, `docs/installation.md:99-101`, `docs/quickstart.md:10`, `docs/CONTRIBUTING.md:52-54`: "Where the code assumes, `:Image check` has to be able to contradict it"). Der Code kann das nicht. Nur `docs/architecture.md:126` ("re-runs the detection") und `doc/images.txt:561` beschreiben es korrekt. `docs/architecture.md:121-131` und `docs/FEATURES/DISPLAY.md:38-45` sind ebenfalls ehrlich ("heuristic over environment variables").
- Was tatsächlich die Wahrscheinlichkeit erhöht, dass etwas erscheint (aber nicht "sicherstellt"):
  1. Protokollwahl OSC 1337 mit gemessener Eigenheit "nvim_ui_send statt io.stdout, ein Send, Cursor speichern/positionieren, flush vor Draw, defer um einen Tick" (`terminal.lua:14-45, 235-263`).
  2. Bei **nicht erkanntem** Terminal + ImageMagick: automatischer Fallback auf Unicode-Blockgrafik (Extmarks), die in jedem Terminal mit Truecolor sichtbar ist (`init.lua:108-120`, `ascii.lua`, `blocks.lua`).
  3. Bei nicht erkanntem Terminal ohne magick: einmalige Warnung + Draw wird trotzdem versucht (`guard.lua:28-43`, `terminal.lua:103-113`).
  4. Menschliche Verifikation: `:Image calibrate` (Testkarte, per Hand nudgen), `:Image debug report|columns|float`, `:checkhealth` druckt Blockglyph-Zeilen zum Ansehen (`health.lua:268-295`).
  5. Headless-Tests prüfen nur Reihenfolge (flush -> payload) und Env-Parsing, nie ein echtes Terminal (`TESTS/terminal_draw_spec.lua`, `TESTS/capability_spec.lua`, CI-Kommentar `.github/workflows/ci.yml:24-26`).
- Konsequenz für "grüner :checkhealth, aber nichts gerendert": **images.nvim kann dasselbe Szenario erzeugen.** Beispiele siehe 3.4 (WezTerm-Env-Var gesetzt + tmux ohne DCS-Wrapping; Terminal-Env vererbt, aber Terminal rendert nicht; Konsole-Version ohne Support). Der Unterschied zu den anderen Plugins ist die Erkennung von Anfang an ehrlich als "Heuristik" deklariert und es gibt einen sichtbaren Fallback, aber kein Beweis-Mechanismus.

---

## 1. ARCHITEKTUR

### 1.1 Modulübersicht (`lua/images/`, 38 Dateien, ~9.4k Zeilen inkl. Typen)

| Schicht | Module |
| --- | --- |
| Einstieg/API | `init.lua` (790 Z., öffentliche API), `plugin/images.lua` (nur Load-Guard `vim.g.loaded_images`, 3 Z.) |
| Bindings | `bindings/usrcmds.lua` (`:Image`-Routenbaum via `lib.nvim.bindings.usercmd.composer`), `bindings/keymaps.lua`, `bindings/autocmds.lua` |
| Config | `config/DEFAULTS.lua`, `config/init.lua` (Validierung vor Merge, ERR-50), `calibration.lua` (persistente Kalibrierung unter `stdpath("data")/images.nvim/calibration.json`), `cell.lua` |
| Terminal/Draw | `terminal.lua` (OSC-1337-Sequenz + Capability), `guard.lua` (Warn-once), `anchor.lua` (kanonischer Fenster-Draw), `scale.lua` (reine Zellen-Arithmetik), `pixels.lua` (Bildgröße aus Header ohne magick) |
| Fallback | `ascii.lua` (Fenster), `blocks.lua` (Sampling+Painting, half/quadrant/sextant) |
| Anzeige-Modi | `hover_float.lua`, `zen.lua`, `redact.lua`, `gallery.lua`, `compare.lua`, `browse.lua` |
| Quellen | `resolve.lua` (Link unter Cursor -> Pfad), `scan.lua`, `remote.lua`, `pdf.lua`, `screenshot.lua`, `paste.lua` |
| Verarbeitung | `convert.lua` (magick: svg->png, pdf, redact, crop, resize, optimise, format), `ocr.lua` (tesseract), `info.lua` |
| Diagnose | `health.lua`, `calibrate.lua`, `calibration.lua`, `debug.lua`, `testcard.lua` (handgeschriebener PNG-Writer) |
| Integrationen | `integrations/picker.lua` (Draw-Surface für fremde Picker), `integrations/menu.lua` (nvzone/menu-Einträge) |

`scripts/gen_map.lua` erzwingt Layer-Regeln (CI-Job `map`, `.github/workflows/ci.yml:51-76`), u.a. "Drawing getrennt vom Rest" (`docs/CONTRIBUTING.md:38-43`).

### 1.2 Datenfluss

Quelle (Markdown-Link / `<figure>` / gopath / `<cfile>` / URL / Datei-Arg) -> `resolve.under_cursor` (`resolve.lua:190-214`) -> Pfad (lokal) oder Download (`remote.fetch`, nur `M.show`, `init.lua:155-164`) -> optional SVG->PNG via magick (`terminal.lua:170-184`, `convert.lua:76-100`) bzw. PDF->PNG via pdfport (`pdf.lua`) -> `images.pixels.read` (Header-Parsing PNG/JPEG/GIF/BMP/WebP, `pixels.lua:215-260`) -> `scale.fit_cells` (Box formen wie das Bild) -> `terminal.draw` (Datei komplett lesen, base64, eine Sequenz, `nvim_ui_send`) -> Terminal.
Kein Decode/Convert im Normalfall: die Bytes der Originaldatei gehen als base64 in die OSC-Sequenz (`terminal.lua:191-205`); das Terminal dekodiert.

### 1.3 Backends / Protokolle

- **Einziges Grafikprotokoll: iTerm2 inline image (OSC 1337)** (`terminal.lua:194-205`: `ESC ]1337;File=inline=1;size=N;width=C;height=R;preserveAspectRatio=1:<b64> BEL`). Width/height in **Zellen**, Terminal skaliert.
- **Kein Kitty** (bewusst: `docs/CONTRIBUTING.md:44-47` "No Kitty graphics protocol. Not as a fallback, not as an option"), **kein Sixel** (0 Treffer in lua/docs/doc), **kein Unicode-Placeholder**.
- **Fallback: Blockgrafik** über Extmarks/Highlight-Gruppen, Geometrien `half` (1x2), `quadrant` (2x2), `sextant` (2x3) (`config/DEFAULTS.lua:96-125`, `blocks.lua`), Quantisierung `levels=8` gegen die Neovim-Grenze von 19 602 HL-Gruppen (`blocks.lua:13-31`, `DEFAULTS.lua:98-103`). Nur für den **Einzelbildpfad** (`show`/hover), nicht Galerie/Zen/Compare/Picker (`ascii.lua:36-37`, `DEFAULTS.lua:90-95`). Erfordert ImageMagick (`blocks.lua:228-230`).
- Plattformen laut Badge/Doku: Linux/macOS/Windows/WSL. Motivation ist native Windows-Neovim in WezTerm (`README.md:24-29`, `docs/architecture.md:16-31`).
  CLAIM (Doku): Kitty-APC aus Neovim komme dort nie an; selbst NICHT verifiziert (UNVERIFIED), die Plugin-Kommentare sprechen von "measured".

### 1.4 Placement-Tracking

- **Keine Placement-Registry, keine Image-IDs** (Protokoll hat keine): ein einziges Boolean `showing` (`terminal.lua:53`), Entfernen = `:mode` erzwingt Full-Repaint (`terminal.lua:347-353`).
- Overlay-Modus (Default): Bild wird an absolute Bildschirmkoordinaten gezeichnet (`init.lua:83-86, 144`), `display.clear_events = CursorMoved, CursorMovedI, InsertEnter, BufLeave, WinScrolled` räumt per `once`-Autocmd ab (`DEFAULTS.lua:52`, `init.lua:47-69`). Das Bild scrollt also NICHT mit dem Text mit; es gibt keine Inline-Bilder im Textfluss (dokumentierte Kernlimitierung, `docs/architecture.md:151`).
- Fenster-Modi: Zen redrawt auf `WinResized`/`VimResized` (`zen.lua:151-156`), alle Fenster-Pfade haben `WinClosed`-Cleanup (`zen.lua:157`, `hover_float.lua:111`, `redact.lua:223`, `integrations/picker.lua:151`, `ascii.lua:117`), `VimLeavePre` räumt auf (`bindings/autocmds.lua:17`).
- Positionierung: `images.anchor.draw` (`anchor.lua:314-334`) berücksichtigt Border-Inset, Float-Overhang-Korrektur (`placed_position`, `anchor.lua:142-150`), `display.draw_inset` (Default 1 Zelle), `display.terminal_padding`, Aspekt-Fit (`anchor.lua:282-288`). Zellgröße ist von Neovim aus nicht messbar -> `display.cell_aspect` (Annahme 0,5) bzw. `:Image calibrate` (`cell.lua:14-33`).

### 1.5 Öffentliche API (`require("images")`, `init.lua`)

`setup`, `show(path|url)` (98), `hover` (177), `gallery(paths?, cols?)` (190), `gallery_range` (243), `list` (261), `step(delta)` (300), `info` (340), `paste(name?, force_ask?)` (373), `screenshot(force_ask?)` (383), `replace` (391), `export` (403), `scale` (433), `optimise` (460), `convert` (509), `ocr(path?, opts?)` (545), `redact` (575), `orphans` (584), `browse` (642), `zen` (651), `draw(target, position, path?, opts?)` (671, kanonischer Primitive), `compare` (700), `statusline(opts?)` (708, für lualine), `pin(on?)` (719), `clear` (740), `recheck` (752). Vimdoc-Tags in `doc/tags` (`images.*()`).
Untermodul-APIs: `images.integrations.picker.{available,is_image,is_pdf,is_previewable,extensions,preview,clear}` (`integrations/picker.lua`), `images.integrations.menu.{items,submenu}`, `images.terminal.{draw,draw_many,clear,capability,reset_capability,is_showing}`, `images.anchor.{draw,resolve_window}`, `images.scale.{fit_cells,anchor_box,POSITIONS,valid_box}`, `images.info.collect`, `images.convert.crop` u.a., `images.ocr.{run,bin,available,languages}`, `images.guard.{check,reset}`, `images.browse.draw_in_window`.

### 1.6 Commands (`:Image`, 25 Routen, `usrcmds.lua:68-345`)

`show|list|gallery|next|prev|info|paste|screenshot|replace|export|scale|optimise|convert|ocr|redact|pickers|orphans|calibrate|debug|compare|zen|draw|pin|check|clear`; bare `:Image` = hover, mit Range (`:'<,'>Image`) = Galerie (`usrcmds.lua:59-66`). Command-Name konfigurierbar (`command = "Image"`). Typ `IMAGE_TARGET` erlaubt http(s)-URL (`usrcmds.lua:26-39`).

### 1.7 Config (`config/DEFAULTS.lua`)

Top-Level: `command`, `extensions`, `display{max_cols=60,max_rows=25,cell_aspect,draw_inset=1,terminal_padding,gallery_gap,hover_mode="overlay"|"float",assume_supported=false,clear_events,browse_exclude,browse_max_entries=20000,zen,remote{enabled=false,timeout_ms=10000,max_bytes=20MiB,cache_ttl_s=86400},screenshot,redact,ascii_fallback{enabled,levels,cells},gopath_fallback}`, `paste{dir="assets",existing_dir_names,name_template,link_template,ask_alt_text,alt_link_template,ask_filename}`, `ocr{lang,args,bin}`, `deps_popup`, `pdf{enabled,page,dpi}`, `menu{enable}`, `keymaps{show,gallery,next,prev,paste,screenshot,double_click,filetypes}`.
`setup()` validiert gegen ein Schema **vor** dem Merge, warnt einmal und meldet in `:checkhealth` (`config/init.lua:22-71, 111-132, 157-174`), inkl. "did you mean" (Levenshtein). Prioritäten: Defaults < Kalibrierung < explizite Optionen (`config/init.lua:143-174`).

### 1.8 Events/Autocmds

Keine `User`-Events (`grep nvim_exec_autocmds|User ` in `lua/` = 0). Autocmds: siehe 1.4 plus `FileType` für buffer-lokale Keymaps (`keymaps.lua:169-177`). Kein Hook-/Callback-System außer `opts.on_done`/`on_ready` (anchor/picker).

---

## 2. CLI-TOOLS

Alle Aufrufe über `vim.system(<argv-Liste>, …)` (kein Shell-String, kein `os.execute`/`io.popen`/`jobstart`; verifiziert per Grep über `lua/`). Erkennung: `lib.nvim.cross.executable.exists(name)` = `vim.fn.executable(name)==1`, **pro Name memoisiert** (`$REPOS_DIR/lib.nvim\lua\lib\nvim\cross\executable\init.lua:24-46`); `clear()` nötig nach Installation.

| Tool | Wofür | Aufruf / Stelle | Async? | Timeout | Fehlt es |
| --- | --- | --- | --- | --- | --- |
| `magick` (ImageMagick 7) | SVG->PNG | `{"magick", path, "-background","none", out}` `convert.lua:93` | **sync `:wait()`** | keiner | klarer Fehler `convert.lua:77-79` |
| | Bildinfo | `{"magick","identify","-format","%m %w %h", path.."[0]"}` `info.lua:84` | **sync** | keiner | Fallback auf `pixels.lua` (Header) `info.lua:95-100` |
| | Block-Sampling | `magick p1[0] p2[0] … -resize WxH! -alpha off -depth 8 RGB:-` `blocks.lua:331-348`; einmal sync (`blocks.lua:383`, von `ascii.open` genutzt `ascii.lua:90`), einmal async (`blocks.lua:404`) | gemischt | keiner | ASCII-Fallback entfällt (`ascii.lua:74`) |
| | PDF-Export (ohne pdfport) | `{"magick", path, out}` `convert.lua:155` | async | keiner | Fehlermeldung |
| | Redact | `magick path -fill black -draw "rectangle x1,y1 x2,y2"… out` `convert.lua:204-211` (Koordinaten via `%d`) | async | keiner | Fehler |
| | crop/resize/optimise/convert | `convert.lua:338-345, 397, 443-457, 510` (Geometrie vorher per Muster validiert `convert.lua:274-296`; `-strip`, `png:compression-level=9`) | async | keiner | Fehler |
| `curl` / `wget` | Remote-Bild | curl: `-fsSL --max-time N --max-filesize B -o out url`; wget: `-q --timeout=N -QB -O out url` `remote.lua:97-114` | async | ja (`--max-time`/`--timeout`) | "neither curl nor wget found" `remote.lua:113` |
| `tesseract` | OCR | `{bin, input, "stdout", "-l", lang, …args}` `ocr.lua:172-177`; `--list-langs` sync `ocr.lua:118` | async (Sprachliste sync) | keiner | Info in health; Windows: Probe `C:/Program Files/Tesseract-OCR/` `ocr.lua:46-49, 91-96`; Override `ocr.bin` |
| `powershell.exe -NoProfile -NonInteractive -STA -Command` | Clipboard-Bild (Windows) | `paste.lua:69-75`; Pfad wird in einen PS-String interpoliert mit `'`-Verdopplung `paste.lua:73` | async | keiner | Fehler |
| | Screenshot-Poll (Windows) | `screenshot.lua:138-152` (Base64 des Clipboards, Timer-Poll) | async, Einzelschuss-Poll | `windows_timeout_ms=60000` | Timeout-Meldung |
| `explorer.exe ms-screenclip:` | Snipping Tool | `screenshot.lua:175` | async | s.o. | Fehler |
| `pngpaste` (macOS), `wl-paste`/`xclip` (Linux) | Clipboard | `paste.lua:81-90`, Linux schreibt stdout selbst in die Datei (kein `sh -c "> '%s'"` mehr, Fix `89a6b6f`) | async | keiner | Fehler |
| `screencapture -i`, `grim`+`slurp`, `maim -s` | Screenshot | `screenshot.lua:84-131` | async | keiner | `M.available()` |
| `pdftoppm` (poppler, via pdfport.nvim) | PDF-Seite -> PNG | `pdf.lua:176` (`pdfport.render_page`), Erkennung `pdf.lua:64-71` | async, In-Flight-Dedupe `pdf.lua:124-171` | (in pdfport) | PDF-Eintrag wird nicht "beansprucht" |
| `img2pdf` (nur indirekt via pdfport) | Verlustfreier Bild->PDF | `convert.lua:118-133` | async | (pdfport) | magick-Pfad |

Erklärungen:
- `docs/install.json` deklariert `magick`, `tesseract`, `pdftoppm` (mit Paketnamen für apt/dnf/pacman/zypper/apk/brew/winget/scoop/choco) für `lib.nvim.deps` (Erst-Setup-Popup, abschaltbar `deps_popup=false`, `init.lua:784-787`).
- Windows: `magick` statt `convert/identify` (Kollision mit System32, `info.lua:81-83`), `powershell.exe` 5.1 mit `-STA` (`paste.lua:14-18`), Tesseract-Pfadprobe, Snipping Tool per Clipboard-Polling, Pfad-Normalisierung `\`->`/` (`resolve.lua:84-89`). CI läuft auf windows-latest.
- Kein `chafa`/`viu` (Doku erwähnt sie nur als "gleiche Technik", `docs/installation.md:46-49`).
- Nicht async, aber UI-blockend: SVG-Konvertierung (`convert.lua:93`), `identify` (`info.lua:84`, aber TTL-gecacht), Block-Sampling im Einzelbildpfad (`ascii.lua:90` -> `blocks.lua:383`), `tesseract --list-langs`. Keiner dieser `:wait()`-Aufrufe hat einen Timeout.

---

## 3. RELIABILITY / "wird wirklich gerendert"

### 3.1 Was tatsächlich gesendet/erwartet wird

- Beim Erkennen: **nichts**. Nur `vim.env`-Lookups (`terminal.lua:85, 91-92, 98`).
- Beim Zeichnen (`terminal.lua:235-244`): `ESC[s` (Cursor sichern) `ESC[?7l` (Autowrap aus) `ESC[row;colH` + `ESC]1337;File=inline=1;size=..;width=..;height=..;preserveAspectRatio=1:<base64> BEL` + `ESC[?7h` `ESC[u`. In **einem** `nvim_ui_send` (`terminal.lua:297`).
- Kein Reply, kein Timeout, kein Cache-Ergebnis einer Probe. Einzig memoisiert: das Env-Ergebnis in `capability` (`terminal.lua:75, 115`), zurücksetzbar per `reset_capability()`.
- Nicht gewrappt für tmux/screen: es gibt keinen `ESC P tmux;`-DCS-Wrapper (`grep tmux` in `lua/`: nur der Hinweis-Text `terminal.lua:148-152`). Der Hinweis lautet "`set -g allow-passthrough on` is required". Nach meinem Wissen über tmux reicht die Option allein nicht, tmux leitet nur DCS-gewrappte Sequenzen durch (UNVERIFIED hier, nicht gegen tmux getestet). Doku-Aussage (`docs/troubleshooting.md:36-37`) ist daher möglicherweise unvollständig; der Code wrappt jedenfalls nichts.
- Nicht genutzt, obwohl Neovim es könnte: `TermResponse` leitet **DA1, OSC, DCS, APC** weiter (das Plugin selbst dokumentiert das: `cell.lua:14-21`, `docs/architecture.md:90`). Damit wäre eine echte Probe (z.B. DA1-Barriere + OSC-/DCS-Query wie XTVERSION, oder OSC-1337-Query) prinzipiell möglich. Das Plugin verwirft die Idee mit "OSC 1337 has no capability query" (`terminal.lua:78`, `docs/architecture.md:121`); eine positive Beweisführung (Query/Reply) wird nicht versucht. (Meine Einschätzung, UNVERIFIED gegen die Terminal-Implementierungen.)

### 3.2 Backend-Auswahl / Fallback-Kette

`images.show` (`init.lua:98-173`):
1. `cap = terminal.capability(assume_supported)` (Env-Whitelist).
2. `cap.ok == false` **und** `ascii_fallback.enabled ~= false` **und** magick vorhanden -> Blockgrafik in Float (`init.lua:108-120`).
3. sonst `guard.check()` (Warnung einmal/Session, `guard.lua:28-43`) und OSC-Draw wird **trotzdem** versucht (Overlay oder `hover_float`).
4. Draw-Fehler (Datei unlesbar/leer, magick fehlt bei SVG) -> `notify().error`.
Andere Pfade (`gallery`, `zen`, `compare`, `redact`, `draw`, Picker): Guard warnt einmal, zeichnet immer OSC, **kein** Blockgrafik-Fallback. Einzige "Strict"-Ausnahme: `integrations.picker.available()` = harte Env-Entscheidung, damit ein fremder Preview-Window nicht leer bleibt (`integrations/picker.lua:91-95`, Begründung `:32-51`).
`assume_supported=true` erzwingt OSC-Draw und überspringt den ASCII-Fallback (`init.lua:108`). Die Config-Kommentare behaupten "only silences the warning, changes nothing about drawing" (`DEFAULTS.lua:48-51`, `docs/FEATURES/DISPLAY.md:50-51`): **Mismatch**, es ändert die Draw-Route.

### 3.3 `:checkhealth images` (`lua/images/health.lua`) — was geprüft wird / was nicht

Geprüft:
- `nvim_ui_send` existiert (API-Level 14) (`health.lua:22-31`)
- Terminal: dieselbe Env-Whitelist (`health.lua:34-53`), WARN bei nicht erkannt; `cap.hint` (tmux) als WARN
- Clipboard-Tool, Screenshot-Tool, `magick`, `tesseract` (+Sprachdaten, `ocr.lang`), `pdfport`+`pdftoppm`, Konfigurationsfehler des letzten `setup()`, kaputte Kalibrierungsdatei, `lib.nvim`, `markdown.nvim`, `lib.nvim.deps`-Pointer
- Blockgrafik-Geometrien: druckt je eine Zeile `half/quadrant/sextant` "zum Anschauen" (`health.lua:268-295`) — die einzige Stelle, die die menschliche Beobachtung explizit einbindet.
NICHT geprüft:
- Ob das Terminal OSC 1337 tatsächlich rendert (nur "WezTerm detected — OSC 1337 is supported", `health.lua:40`; das ist eine Behauptung aus einer Env-Var, kein Test).
- Ob tmux `allow-passthrough` gesetzt ist (nur generischer Hinweis).
- Ob Sequenzen überhaupt ankommen, Zellgröße, Padding.
- `health.lua` ist laut `TESTS/README.md:73` ungetestet ("checked manually").

**Nebenwirkung, headless verifiziert:** `health.check_terminal` ruft `capability(false)` (`health.lua:37`). Wird das als ERSTER Capability-Aufruf der Session ausgeführt (typisch: frisches Neovim, `:checkhealth images`), wird `ok=false` memoisiert (`terminal.lua:115, 140-145`). Spätere Draw-Pfade mit `display.assume_supported=true` erhalten dann trotzdem `ok=false` (Test: `capability(false)` dann `capability(true)` -> `false`; frisch `capability(true)` -> `true`). Abhilfe nur `:Image check`. Reales Ordnungs-Bug, nicht getestet in `TESTS/capability_spec.lua`.

### 3.4 Selbsttest / Diagnose-Kommandos

- Es gibt **keinen "zeige ein Testbild und bestätige"-Befehl**, der ein Ja/Nein liefert. Am nächsten:
  - `:Image calibrate` (`calibrate.lua`): generiert per Hand-PNG-Writer (`testcard.lua`, unkomprimierte zlib-Blöcke, CRC32/Adler32, keine externen Tools, `testcard.lua:12-18, 143-181`) eine Testkarte in exakt der Box-Proportion, der Mensch nudget (`hjkl`, `+/-` für cell_aspect) bis sie sitzt; Ergebnis wird persistiert. Verifiziert Position/Form, setzt aber voraus, dass überhaupt etwas erscheint.
  - `:Image debug report|columns|float|disarm` (`debug.lua`): loggt die tatsächlich gesendeten Koordinaten gegen eine unabhängig neu berechnete Erwartung, zeichnet die Karte in vier Spalten (konstanter vs. skalierender Offset), prüft ob ein Float dort ist, wo Neovim es behauptet. Das misst die Neovim-seitige Arithmetik, nicht die Terminal-Seite. `report` wrappt `terminal.draw` und bleibt gewrappt bis `disarm` (`debug.lua:91-99`, Commit `83808c8`).
  - Manueller Shell-Probe in der Doku (siehe 0).
- Diagnose/Logging: `notify` über `lib.nvim.notify` mit Präfix `[images]`; kein Log-File, kein Debug-Flag. `images.statusline()` zeigt, ob gerade ein Bild "angeblich" auf dem Schirm ist (Flag, keine Bestätigung).

### 3.5 Konkrete Szenarien "grün, aber leer" bei images.nvim

- `WEZTERM_*`-Env gesetzt, aber Sequenz erreicht das Terminal nicht (tmux ohne funktionierendes Passthrough/kein DCS-Wrap; Multiplexer; SSH-Weiterleitung ohne Env-Reset). Health zeigt OK + WARN-Hinweis, kein Beweis.
- `TERM_PROGRAM` enthält "iterm" oder `LC_TERMINAL` (`terminal.lua:91-92`) -> als iTerm2 akzeptiert, auch wenn ein anderes Terminal dahinter hängt.
- Konsole: nur `KONSOLE_VERSION` wird geprüft (`terminal.lua:98`); ob diese Konsole-Version OSC 1337 unterstützt, wird nicht geprüft (UNVERIFIED, welche Versionen es können).
- Unbekanntes Terminal, das OSC 1337 doch kann (z.B. Ghostty/Warp/mintty/Tabby/…; UNVERIFIED welche): wird "unsupported" -> ASCII-Fallback statt echtem Bild bis `assume_supported=true`. Das ist die sichere Fehlrichtung.

### 3.6 Robustheit der Sequenz selbst (Code-Belege)

- `nvim_ui_send` statt `io.stdout:write` ("zeichnet nur einmal pro Session", `terminal.lua:14-16`).
- Cursor sichern/positionieren/restore + Autowrap-Aus in EINEM String (`terminal.lua:235-244`).
- `redraw` vor jedem Draw (`terminal.lua:259-263, 295`), `defer` um einen Tick für alle Pfade, die ein Fenster öffnen (`anchor.lua:323-329`, Zen/Hover-Float/Redact).
- Clamp auf Bildschirm minus eine Zeile, weil OSC 1337 den Cursor nach unten schiebt (`terminal.lua:220-222`); Box wird wie das Bild geformt (`anchor.lua:282-288`, `scale.fit_cells`), weil ein Terminal sonst auf die Breite skaliert und unten überläuft ("993x1404-PDF in 82x25 -> 57 Zeilen", `terminal.lua:26-42`).
- Nach Overflow-Scroll hilft nur `:mode`-Repaint (`terminal.lua:26-29, 347-353`).

### 3.7 Tests / CI

- `TESTS/`: 34 `*_spec.lua` + `harness.lua` + `run.lua`, ~4.3k Zeilen, ~709 Assertion-Aufrufe (`H.ok/eq/falsy/contains…`), ohne plenary/busted (eigenes Mini-Harness). Lokal: `IMAGES_TESTS_OK`.
- Abgedeckt: Arithmetik (`anchor`, `scale`, `gallery`, `pixels`, `cell`), Config-Validierung, Capability-Env-Parsing, Draw-Reihenfolge (flush -> payload; Zen zeichnet erst im nächsten Tick), Remote-TTL-Semantik, Fileops-Argumente, Keymaps/Routing, Testkarte-PNG-Korrektheit, Regression für die Shell-Injection in `resolve` (`TESTS/README.md:86`).
- **Nicht abgedeckt** (laut `TESTS/README.md:35-52`, `.github/workflows/ci.yml:24-26`, `docs/CONTRIBUTING.md:38-43`): alles, was ein echtes Terminal braucht. Kein Test prüft die genauen OSC-Bytes (`preserveAspectRatio`/`inline=1` kommen in `TESTS/` nur in Kommentaren vor; der Test `terminal_draw_spec.lua:37` sucht nur den Substring "1337"), keine echte `magick`/`curl`-Ausführung (argv-Aufbau z.T. gestubbt; die curl/wget-Argumentliste in `remote.lua:97-111` hat keinen Test), `health.lua`, `calibrate.lua`, `debug.lua` ohne Spec.
- CI (`.github/workflows/ci.yml`): Jobs `lint` (stylua v2.5.2 + luacheck 1.2.0), `test` (Matrix ubuntu/windows/macos, `nvim --headless -u NONE -l TESTS/run.lua`, lib.nvim `ci-verified`-Branch gepinnt), `map` (Layer-Regeln). CI rendert nie ein Bild.

### 3.8 Unterschied zu bloßem Env-Sniffing

Ehrliche Antwort: **kein prinzipieller Unterschied in der Erkennung.** Vorteile gegenüber "nur Env-Vars + Stille":
1. Whitelist + explizite Falsch-Negativ-Politik (nie hart blocken).
2. Sichtbare, nicht stille Degradierung (Blockgrafik oder einmalige Warnung mit konkretem Testrezept und `assume_supported`-Ausweg, `terminal.lua:141-145`).
3. Menschliche Feedback-Schleifen (`calibrate`/`debug`/Glyph-Zeilen im Health), die reale Fehlerklassen fanden (Doku nennt "two real bugs", `docs/FEATURES/DISPLAY.md:194`).
4. Ein dokumentiertes, protokoll-generisches Shell-Verfahren zur Trennung "Terminal kann's nicht" vs. "Neovim/Plugin liefert's nicht" (`docs/troubleshooting.md:16-37`).
Nachteil: alles davon ist Handarbeit. Nichts im Plugin bestätigt selbst, dass ein Bild ankam.

---

## 4. FEATURES

Anzeige: Bild unter Cursor (Markdown-Link inkl. `<img>`/`<figure>` wenn markdown.nvim da, bloßer Pfad via gopath.nvim, `<cfile>`), Overlay- oder Float-Hover (`display.hover_mode`), Doppelklick (`<2-LeftMouse>`), Pin, Galerie (Raster, Range-Variante), next/prev (Wrap, Count), Zen (großes editierbares Fenster, folgt Resize), Compare (echte relative Skalierung; braucht magick + ui.nvim), `:Image draw <position>` (full + 9 Anker), Statusline-Segment, Testkarte/Calibrate.
Formate: `png jpg jpeg gif webp bmp svg` (`DEFAULTS.lua:11`); Bytes gehen 1:1 ans Terminal; SVG -> PNG (magick) mit Cache `stdpath("cache")/images.nvim/svg` (Key sha256(path:mtime)); GIF = statisch (Animation gestrichen, `git 0cbe6a9`); PDF-Seite als Bild (nur für Host-Picker, via pdfport+pdftoppm, `images/pdf.lua`).
Browsing: `:Image pickers cfile|cwd|path` mit snacks.picker-Live-Preview (eigene Preview-Funktion, nicht `snacks.image`, `browse.lua:193-238`) oder `ui.kit`/`vim.ui.select`; BFS-Scan mit `browse_exclude`, Cap `browse_max_entries=20000`, folgt keinen Symlinks (nur `kind=="directory"/"file"`, `browse.lua:88-93`); `:Image list` (Buffer-Bilder), `:Image orphans` (verwaiste Bilder in `paste.dir`, Löschen nach Bestätigung, `orphans.lua`, `init.lua:584-635`).
Capture: `:Image paste [name]` (Clipboard -> PNG neben Dokument, Link einfügen, Alt-Text/Dateiname optional, sanitisiert, nur `.png`), `:Image screenshot` (macOS/Linux/Windows), `:Image replace`, Nachbarordner `Resources/Ressourcen` wird wiederverwendet.
Verarbeitung: `:Image redact` (Boxen markieren -> `.redacted.<ext>`), `scale`, `optimise` (strip + PNG-Level 9, verwirft Ergebnis wenn nicht kleiner), `convert <fmt>`, `export` (PDF, pdfport oder magick), `ocr` (tesseract -> Markdown-Scratch-Split), `info`. Alle schreiben NEUE Dateien neben die Quelle, Original bleibt (`convert.lua:46-56`).
Remote: `display.remote.enabled=false` Default (Opt-in wie "load external images", `remote.lua:3-9`), nur `show`/hover; `timeout_ms`, `max_bytes`, `cache_ttl_s=86400` (Commit `cd6099d`, Tests `TESTS/remote_spec.lua:59-144`), Disk-Cache `stdpath("cache")/images.nvim/remote/<sha256(url)>.<ext>`; Galerie/Compare/Zen/Picker lösen keine URLs auf.
Integrationen: siehe Abschnitt 8. Keymaps: `<leader>im/ig/in/ip/iv/is` (buffer-lokal für markdown/vimwiki/norg/text), `which-key`-Gruppe automatisch.
Sonstiges: Health, Vimdoc (`doc/images.txt`, 800+ Zeilen), CONTRIBUTING, `docs/` mit Feature-Katalog, i18n-Bereinigung (alles englisch).

---

## 5. SICHERHEIT

| Bereich | Befund | Beleg |
| --- | --- | --- |
| Escape-Sequenz-Injection | Sehr gute Lage konstruktionsbedingt: Sequenz enthält nur Integer (`size`, `width`, `height`, `row`, `col` per `%d`/`..`) und base64 (`vim.base64.encode`). Kein Dateiname/`name=`-Parameter, kein User-String in OSC/APC. Es gibt keine Sanitize-Funktion, weil kein Freitext in die Sequenz gelangt. | `terminal.lua:191-205, 235-244` |
| Inhaltsprüfung | Nur Endungscheck (`is_image`), keine Magic-Byte-Prüfung vor dem Senden; eine als `.png` benannte beliebige Datei geht base64-kodiert ans Terminal (Terminal muss robust sein). | `resolve.lua:22-37`, `terminal.lua:170-184` |
| Shell-Injection | Alle Subprozesse argv-basiert. **Echte Lücke gefunden und behoben:** `vim.fn.expand(link_text)` führte Backtick-Command-Substitution aus (`![x](\`mkdir /tmp/pwned; echo a.png#\`)`), Commit `0518fd7`; jetzt `lib.nvim.cross.fs.expand_path` (nur `~`, `$VAR`, `%VAR%`, kein Shell/Glob) `resolve.lua:108-117`; Regressionstest in `resolve_spec`. `sh -c "> '%s'"` beim Linux-Clipboard entfernt (`89a6b6f`, `paste.lua:54-65`). SEC-34: `:Image`-Argumente und `debug`/`browse` laufen durch `expand_path` (`usrcmds.lua:26-39`, `browse.lua:133-135`, `debug.lua:245, 321`, Commits `39e460b`, `540f0ce`). Restrisiko: Windows-Clipboard/`ms-screenclip`: Pfad wird in einen PowerShell-`-Command`-String interpoliert, nur `'` verdoppelt (`paste.lua:73`); PowerShell behandelt auch typografische Anführungszeichen als Quote (mein Wissen, UNVERIFIED) -> theoretisch Injection über einen Zielpfad mit solchen Zeichen; `out` ist meist `tempname` bzw. ein aufgelöster Link-Pfad (`replace`). | s. links |
| URL-Handling (Remote) | **Scheme-Allowlist:** nur `^https?://` (`remote.lua:24-26`; `ftp://`, `file://` explizit ausgeschlossen, Test `remote_spec.lua:31`). Default aus (`enabled=false`). Größe: curl `--max-filesize` (`remote.lua:104`), wget `-Q` (`remote.lua:111`). Timeout: `--max-time`/`--timeout`. Cache-Name = sha256(URL) + nur `[%w]+`-Extension (`remote.lua:42-47`), kein Pfad aus URL. URL kommt als eigenes argv-Element, führt wegen `^https?://` nie mit `-`. | s. links |
| SSRF / private IPs / Redirects | **Nicht vorhanden.** Kein Block von localhost/RFC1918/Link-Local/Metadata-IPs, keine DNS-Rebinding-Abwehr. curl läuft mit `-L` (`-fsSL`), folgt also Redirects **ohne** `--max-redirs`, `--proto`, `--proto-redir` (`remote.lua:98-108`). Mitigation ist nur das Opt-in-Default. | `remote.lua:80-114` |
| Größenlimits (Remote) | curl `--max-filesize` greift laut curl-Doku nur, wenn die Größe vorab bekannt ist (Content-Length); bei chunked/unbekannter Länge kein Abbruch (curl-Verhalten, UNVERIFIED hier). wget `-Q` greift laut wget-Handbuch **nie** bei einem einzelnen Download (`-O`-Einzeldatei) -> die "Äquivalenz" im Kommentar `remote.lua:110-111` stimmt vermutlich nicht (UNVERIFIED). Nach dem Download keine Größen- oder Typprüfung (nur `size==0`, `remote.lua:126-131`). | `remote.lua:98-131` |
| Lokale Dateigröße | **Kein Limit:** `lib.nvim.fs.read` liest die ganze Datei (`$REPOS_DIR/lib.nvim\lua\lib\nvim\fs\read\init.lua:17-33`), dann base64 im Hauptthread und ein `nvim_ui_send` (`terminal.lua:180-205, 297`). Ein sehr großes Bild = UI-Blockade + RAM (Faktor >2). Kein Chunking. Terminal-seitige Limits UNVERIFIED. | `terminal.lua` |
| Pfadbehandlung | Kein Confinement der Link-Ziele: `to_path` löst auch `../..`/absolute Pfade auf (`resolve.lua:97-131`) -> jede lesbare Datei mit Bild-Endung; Dokument = vom Benutzer geöffnet, kein Netzwerk-Bezug. Paste: `sanitize_filename` verwirft Pfadanteile (auch `\` auf Linux), erzwingt `.png` (`paste.lua:155-165`, Test `sanitize_filename_spec`). Nicht-http(s)-Schemata werden von `to_path` abgewiesen (`resolve.lua:98-100`). `browse` Root nur aus `expand_path` + `isdirectory`. | s. links |
| Temp-/Cache-Dateien | Test-/Paste-Zwischendateien via `vim.fn.tempname()`; Caches unter `stdpath("cache")/images.nvim/{remote,svg,pdf}`. Keine restriktiven Dateirechte gesetzt (Neovim-Default). **Cache-Cleanup:** nur Remote hat TTL (und auch nur beim Wiederaufruf derselben URL, kein Sweep). SVG- und PDF-Cache wachsen unbegrenzt (Key enthält mtime, alte Einträge bleiben liegen). | `remote.lua:88-90`, `convert.lua:65-70`, `pdf.lua:87-122` |
| Ressourcen-Caps | Blockgrafik: `levels` -> max levels³ HL-Gruppen, Budget + Grobpalette bei Erschöpfung (`blocks.lua:249-280`), `GROUP_BUDGET`; `browse_max_entries=20000` (`browse.lua:38-47, 84`); JPEG-Headerwalk auf 512 Segmente begrenzt (`pixels.lua:165-167`); Berechnungs-/Config-Sanitisierung (`valid_positive`, `valid_box`, ERR-22-Serie: 6 Commits, u.a. `e7fc84b`). Kein Cap für die Anzahl gleichzeitiger Downloads/Prozesse; keine ImageMagick-`-limit`-Flags (Speicher/Zeit/`policy.xml` bleiben Sache des Systems); ImageMagick wird auf beliebige Benutzerdateien (SVG-Delegates, externe Referenzen) losgelassen, ohne `-limit`/Delegate-Beschränkung (mein Wissen zu ImageMagick-SVG/MSL-Risiken; UNVERIFIED hier). | s. links |
| Redaction-Integrität | `convert.redact` zeichnet mit `-draw` ohne `-strip` (`convert.lua:204-209`); bei JPEG-Quellen könnten Metadaten/Thumbnails (EXIF) das Original-Bild noch enthalten (mein Wissen; UNVERIFIED). `optimise` hat `-strip`, ist aber ein separater Befehl. Nicht getestet. | `convert.lua:188-226` |
| Persistente Daten | `calibration.json` wird als **untrusted** validiert (SEC-33: Felder-Typcheck; kaputte Datei -> `.corrupt`-Kopie, kein stilles Überschreiben) (`calibration.lua:60-125`, Commit `214a7da`). `setup()`-Optionen: Schema-Validierung vor dem Merge (`config/init.lua:111-132`). | s. links |
| Löschen | `:Image orphans` löscht nur nach expliziter Auswahl + Bestätigung, prüft echten Unlink-Rückgabewert (`orphans.lua:71-85`, Commit `cf331b4`). Alle anderen Operationen schreiben Kopien; `to_format`/`scale` überschreiben eine vorhandene Zieldatei ohne Nachfrage (`convert.lua:12-16, 500-510`). | s. links |
| Datenschutz | Remote-Bilder standardmäßig aus. Keine Telemetrie. Kein Netzwerkzugriff sonst. | `DEFAULTS.lua:62-68` |

Mismatch Doku/Code (Sicherheit): Der Kommentar in `remote.lua:110-111` (wget `-Q` = "closest equivalent" zu `--max-filesize`) trifft nach wget-Handbuch vermutlich nicht zu (UNVERIFIED).

---

## 6. PERFORMANCE

Muster: 
- **Async statt Blockieren** (Serie 2026-08-23): Remote-Download (`e17c57d`), Redact (`8dccfb7`), PDF-Export (`5bd6746`), `identify` gecacht (`bfb1487`). Weiterhin sync: siehe 2.
- **Header-Parsing statt Subprozess** für Bildmaße (`pixels.lua`, "one open, one small read"), Cache-Key path:mtime:size, `false` wird mit-gecacht.
- **In-Memory-TTL-Caches** über `lib.nvim.cache.memory.namespace(..., {ttl=300})`: `images.pixels` (`pixels.lua:49`), `images.info` (`info.lua:36`) — Commit `94d3ea9` (PERF-42).
- **Disk-Caches:** Remote (TTL 1 Tag, `cd6099d`/`a8b1eed`), SVG->PNG (Key path+mtime), PDF-Seiten (Key path+mtime+page+dpi, In-Flight-Dedupe `pdf.lua:124-171`); alle immer nach Bytes-Key, ohne Größenbegrenzung.
- **Batching:** Ein `magick`-Prozess für alle Frames/Bilder (186 ms vs. 1593 ms für 24 PNGs, `blocks.lua:5-11`), 71 ms Prozessstart auf Windows -> `crop` mit optionalem `-resize` in einem Aufruf (`convert.lua:313-317`).
- **Hoisting/Micro:** `paint_cells`-Row-Closure (`cbd63d1`, PERF-25), HL-Gruppen vor dem Malen erzeugen (`e27a73f`), Config-Lookup aus der Walk-Schleife (`9af8374`), `table.concat` statt `..` für den base64-Payload (`terminal.lua:191-205`), `draw_many` sendet pro Tile eine eigene Sequenz, statt alle Payloads zu konkatenieren (`terminal.lua:310-342`).
- **Lazy `require`** überall in Funktionskörpern (`require("images.x")` erst bei Nutzung); `plugin/images.lua` ist 3 Zeilen; `lib.nvim.cross.executable` memoisiert Tool-Lookups.
- **Sichtbarkeit:** Es gibt kein "nur sichtbare Bilder rendern"-Konzept, weil es keine Inline-Bilder gibt; ein Bild zur Zeit (Overlay/Float/Zen), Galerie zeichnet nur, was in den Bildschirm passt (`gallery.lua`, `clamp_to_screen`).
- **Schwächen:** keine Payload-/Base64-Cache (jeder Redraw liest + kodiert neu, z.B. Zen bei `WinResized`, Picker-Preview), Overlay clear per `:mode` (Vollrepaint), kein Debounce für Picker-Preview außer PDF-Ticket (`integrations/picker.lua:78-85`, 254-273).

Commit-Liste (PERF-/SEC-/ERR-bezogen):

| Commit | Datum | Inhalt |
| --- | --- | --- |
| `a8b1eed` | 09-20 | docs(remote): `cache_ttl_s` dokumentiert + Tests (PERF-42) |
| `cd6099d` | 09-19 | perf(remote): TTL für Remote-Disk-Cache (PERF-42) |
| `cbd63d1` | 09-19 | perf(blocks): `paint_cells`-Closure aus Zeilenschleife gehoben (PERF-25) |
| `94d3ea9` | 09-19 | perf(pixels,info): Header-/Metadaten-Cache mit TTL (PERF-42) |
| `9af8374` | 09-19 | perf(browse): Config-Lookup aus Walk-Loop (ERR-01) |
| `540f0ce` | 09-19 | fix(SEC-34): `debug.lua` -> `expand_path` |
| `39e460b` | 09-19 | fix(SEC-34): `:Image`-Argumente -> `expand_path` |
| `214a7da` | 09-19 | fix(calibration): geladenen Snapshot validieren, corrupt vs. missing (SEC-33, ERR-11) |
| `e27a73f` | 09-08 | perf(blocks): HL-Gruppen vor dem Malen anlegen |
| `89a6b6f` | 09-05 | fix(sec): Clipboard-Zielpfad nicht mehr in Shell interpolieren (Linux) |
| `0518fd7` | (früher) | fix(resolve): Link-Ziel ist kein Vim-Filename-Pattern (Command-Substitution-RCE per Markdown-Link) |
| `bfb1487`, `e17c57d`, `8dccfb7`, `5bd6746` | 08-23 | perf/async: identify-Cache, Download, Redact, PDF-Export nicht mehr blockierend |
| `5590f77`, `e7fc84b`, `85c5c03`, `eb845ec`, `c85362d`, `fef6148`, `bc7fdb3` | 09-19 | ERR-50 Config-Schema-Validierung, ERR-22 degradieren statt crashen bei falschformatiger Config |
| `5fd5cab`, `c9abde2` | 09-19 | Windows-Clipboard-Poll single-shot, Timeout entkoppelt (ERR-03) |
| `83808c8` | 09-19 | `debug.disarm()` implementiert (PRIN-10) |

---

## 7. BEKANNTE LÜCKEN / CONS (Doku-eingeräumt + eigene Befunde)

Doku-eingeräumt (`docs/scope.md`, `docs/architecture.md:143-154`, `docs/troubleshooting.md`):
1. **Keine Bilder inline im Textfluss** (nur Overlay über Text oder Float; wird bei Cursorbewegung/Scroll gelöscht).
2. **Placement nur ganzzellig** (`CSI row;col H`), Pixel-Padding/Zellgröße nicht auslesbar -> Kalibrierung per Hand, `draw_inset=1` als Puffer.
3. **SVG braucht ImageMagick.**
4. **Terminalunterstützung wird geraten** (kein Capability-Query).
5. Remote nur im Einzelbildpfad; Galerie/Compare/Zen/Picker überspringen URLs (`docs/troubleshooting.md:179-184`).
6. `:Image screenshot` unter Windows über Clipboard-Polling ("least certain of the three platforms", `docs/troubleshooting.md:139-146`).
7. Blockgrafik-Fallback nur im Einzelbildpfad.
8. Roadmap-Gestrichenes: animierte GIFs, mehrere gleichzeitige Pins, Zoom (Commits `0cbe6a9`, `4e5e71b`, `efee8f3`), PDF-Seiten-als-Bild als eigene Funktion -> pdfport.

Eigene Befunde:
- **Keine aktive Probe / keine Ende-zu-Ende-Bestätigung** (Kern, s. 0). Mismatch der Doku zu `:Image check`.
- **Ordnungs-Bug**: `:checkhealth` als erster Capability-Aufruf poisoned das Memo (3.3, verifiziert).
- `assume_supported` ändert die Draw-Route, Doku sagt das Gegenteil.
- Nur **eine** Protokollfamilie (OSC 1337). Terminals ohne OSC 1337 (z.B. Kitty-Terminal, foot, Alacritty, Windows Terminal — Support-Stand extern UNVERIFIED) bekommen nur Blockgrafik; kein Kitty/Sixel-Weg. Das ist ein bewusster Design-Verzicht (`docs/CONTRIBUTING.md:44-47`), aber ein großer Reichweiten-Nachteil gegenüber Kitty-basierten Plugins.
- Erkennungs-Whitelist hat nur 3 Einträge (`terminal.lua:81-101`); Nutzer anderer OSC-1337-Terminals sind auf `assume_supported` angewiesen.
- tmux: kein DCS-Wrapping im Code (3.1).
- Keine Animation, keine Video-Frames, keine Überlagerung mehrerer Bilder mit z-Order/IDs, keine partielle Löschung (nur `:mode`-Vollrepaint).
- UI-Blockade bei großen Dateien (sync base64) und bei den sync-`magick`-Pfaden; keine Timeouts für Lokalprozesse.
- Cache-Wachstum (SVG/PDF) ungebunden.
- Redaction: kein `-strip` (s. 5, UNVERIFIED).
- Beta ("Beta stage — active development", `README.md:1-3`); Breaking Changes möglich; harte Abhängigkeit von `lib.nvim` (eigene Ökosystem-Bibliothek des Users), optional `ui.nvim` (für `compare`, `list`-Picker, `menu`).
- Doku-Drift (kleinere): `docs/FEATURES/CAPTURE.md:78-79` sagt PDF-Export ohne pdfport laufe "synchronously", Code ist async (`convert.lua:155`); `blocks.lua:24` Kommentar "default of 16 levels ... 4 096" vs. `DEFAULTS.lua:103` `levels = 8`; `README.md:64` "sixteen routes" vs. 25 Routen im Code (gemeint "die 16 Wichtigsten").

Was gegenüber 3rd/image.nvim und snacks.image fehlt (aus Sicht dieses Codes, ohne deren Code hier geprüft zu haben):
- Kitty-Protokoll, Unicode-Placeholder, Sixel, ID-basiertes Placement, Inline-Rendering im Buffer-Text (Markdown/Neorg/HTML-Integrationen mit Scroll-/Fold-Tracking), Bildcache-Invalidierung pro Placement, Animationen.
- Aktive Terminal-Detection per Query. (Bei den anderen Plugins ist das Verhalten UNVERIFIED und gehört in deren Reports.)
Was images.nvim hat, das andere (vermutlich) nicht: Läuft auf nativer Windows-Neovim in WezTerm (OSC-1337-Weg; CLAIM), Clipboard-Paste/Screenshot mit Link-Einfügen, Redact/OCR/Scale/Optimise/Convert, Orphans, Compare, Kalibrierungs-/Debug-Werkzeuge, fremde Picker-Preview-Surface, PDF-Seitenvorschau via Ecosystem.

---

## 8. INTEGRATIONSFLÄCHE (Geschwister-Plugins)

Aus images.nvim (Aufrufe nach außen, alle soft/`pcall`, ausser lib.nvim):

| Ziel | Aufruf | Stelle |
| --- | --- | --- |
| **lib.nvim** (harte Abhängigkeit) | `lib.nvim.bindings.usercmd.composer` (`:Image`), `lib.nvim.bindings.keymap`/`autocmd`, `lib.nvim.notify`, `lib.nvim.cross.executable`, `lib.nvim.cross.platform.is_windows/is_macos`, `lib.nvim.cross.fs.expand_path`, `lib.nvim.fs.read`/`mkdirp`, `lib.nvim.window.make_scratch`/`open_named_scratch`, `lib.nvim.cache.memory`, `lib.lua.strings.distance`, `lib.nvim.deps` (+`.health`) | Import-Zählung per Grep; `health.lua:228-232`, `init.lua:784-787` |
| **markdown.nvim** | `markdown.core.link_scan.from_line`, `markdown.core.html_links.figure_at`, `markdown.util.path.resolve` | `resolve.lua:51-58, 102-106, 202-206` |
| **gopath.nvim** | `gopath.resolve.resolve_at_cursor` (nur Treffer mit `exists` + Bild-Endung) | `resolve.lua:173-184`, Config `display.gopath_fallback` |
| **pdfport.nvim** | `pdfport.can_create("image")`, `pdfport.create({inputs, from="image", __callback})` (Export); `pdfport.render_page(path, page, {dpi, output_path}, cb)` (PDF-Seite) | `convert.lua:118-133`, `pdf.lua:64-71, 176`, `health.lua:186-206` |
| **ui.nvim** | `ui.kit` (`select`, `viewer`, `confirm`, `compare`, per `pcall`); `ui.contextmenu` (hart in `integrations/menu.lua:19`) | `init.lua:42-44`, `compare.lua`, `browse.lua:254` |
| **nvzone/menu** | liefert Einträge, öffnet nie selbst | `integrations/menu.lua:41-93` |
| **snacks.nvim** | `snacks.picker` für `:Image pickers` (eigene Preview-Funktion) | `browse.lua:157-238` |
| **language.nvim** | keine Code-Kopplung: OCR-Buffer hat `filetype=markdown` | `init.lua:560-565`, `docs/FEATURES/INTEGRATIONS.md:273-294` |

In images.nvim hineinrufende Plugins (im Nachbar-Repo unter `$REPOS_DIR/` per Grep verifiziert):

| Plugin | Aufruf in images.nvim | Beleg |
| --- | --- | --- |
| **hover.nvim** | `images.info` (`collect`), `images.scale.fit_cells`, `images.anchor.draw` (deferred, `opts.defer`), `images.terminal.clear`, Fallback `images.browse.draw_in_window`; `images.convert.crop` (Zoom) | `$REPOS_DIR/hover.nvim\lua\hover\preview\media.lua:176,234,307-328,433-480` |
| **pickers.nvim** | `images.integrations.picker`: `available`, `is_previewable`, `is_pdf`, `is_image`, `preview(winid, file, {on_ready,on_done,page,dpi,position,scale,inset,defer})`, `clear` | `$REPOS_DIR/pickers.nvim\lua\pickers\integrations\images\init.lua:77-211`, Adapter `snacks.lua:61-99`, `telescope.lua:50-119` |
| **markdown.nvim** | `require("images").paste()` / `.screenshot()`; `images.terminal.clear()`; `images.browse.draw_in_window` (per Doku `INTEGRATIONS.md:30-34`) | `$REPOS_DIR/markdown.nvim\lua\markdown\commands\image.lua:14-35`, `commands\links.lua:221` |
| **lib.nvim** (`image_preview`) | bevorzugt images.nvim vor snacks/image.nvim: `pcall(require,"images")`+`images.show`, `images.guard.check`, `images.browse.draw_in_window`, `images.terminal.clear` (Erkennung prüft nur "Modul ladbar", nicht "rendert") | `$REPOS_DIR/lib.nvim\lua\lib\nvim\image_preview\init.lua:42-45, 129-151` |
| **filetree.nvim** | `images.show(path)` als erstes Preview-Backend | `$REPOS_DIR/filetree.nvim\lua\filetree\features\ui\preview\init.lua:153-159` |
| **open.nvim** | `images.show(ctx.text)` für `:Open image` | `$REPOS_DIR/open.nvim\lua\open\handlers\image.lua:25-27` |
| **media.nvim** | `images.show(png)`; `images.ocr.run(path, nil, cb)`, `images.ocr.bin()` | `$REPOS_DIR/media.nvim\lua\media\ui.lua:168-170`, `hub\text.lua:82, 181` |
| **pdfport.nvim** | ruft nicht in `images` (Grep leer); Kopplung nur in Gegenrichtung (`render_page`/`create`) | Grep |
| **gopath.nvim**, **language.nvim** | keine Aufrufe in `images` gefunden | Grep |

Fazit Integration: Der stabile öffentliche Einstieg für andere ist **`require("images").draw(target, position, path, opts)`** bzw. **`images.integrations.picker.*`**; historisch noch `images.browse.draw_in_window` (als "kept for markdown.nvim" markiert, `browse.lua:172-175`). Es gibt **keine** `User`-Events und keine Callback-Registrierung; Kopplung läuft ausschließlich über direkte `pcall(require, ...)`-Aufrufe.
Anmerkung: Die Doku (`docs/FEATURES/INTEGRATIONS.md`) beschreibt die Beziehungen im Wesentlichen korrekt; die im README genannten "soft" Plugins passen zum Code, mit `ui.nvim` als zusätzlicher (README nicht erwähnter) optionaler Abhängigkeit für `compare`/`menu`.

---

## 9. LISTE DER DOKU-VS-CODE-MISMATCHES (kompakt)

1. `:Image check` "probe … getting through right now": `docs/health.md:30-33`, `docs/commands.md:250-252`, `docs/troubleshooting.md:13`, `docs/installation.md:99-101`, `docs/quickstart.md:10`, `docs/CONTRIBUTING.md:52-54` vs. Code `init.lua:752-762` (nur Env-Re-Sniff).
2. `assume_supported` "changes nothing about drawing": `DEFAULTS.lua:48-51`, `docs/FEATURES/DISPLAY.md:50-51` vs. `init.lua:108-120` (überspringt ASCII-Fallback).
3. PDF-Export ohne pdfport "synchronously": `docs/FEATURES/CAPTURE.md:78-79` vs. `convert.lua:155` (async).
4. wget `-Q` als Größenlimit: `remote.lua:110-111` (vermutlich wirkungslos bei Einzeldatei, UNVERIFIED).
5. tmux: Doku "allow-passthrough on" genügt (`docs/troubleshooting.md:36-37`, `terminal.lua:151`) vs. kein DCS-Wrap im Code (Behauptung zu tmux UNVERIFIED).
6. `blocks.lua:24` "default 16 levels" vs. `DEFAULTS.lua:103` `levels = 8`.
7. `docs/health.md:12-13` "terminal: whether it is believed to speak OSC 1337" ist korrekt formuliert, aber `health.lua:40` schreibt "OSC 1337 is supported" als Tatsachenaussage.

## 10. UNVERIFIED (nicht selbst geprüft)

- Ob Kitty-APC aus Neovim in nativer Windows-WezTerm wirklich nie ankommt (Herstellerbehauptung im Plugin).
- tmux-Verhalten (DCS-Passthrough), Unterstützung von OSC 1337 in konkreten Konsole-/Ghostty-/Warp-/etc.-Versionen.
- curl `--max-filesize`-Verhalten bei fehlender Content-Length; wget `-Q` bei Einzeldatei; curl-Redirect-Defaults.
- ImageMagick: EXIF-Thumbnail-Erhalt bei `-draw` ohne `-strip`; SVG-Delegate-Risiken; PowerShell-Quote-Sonderfälle.
- Terminal-seitige Größenlimits für sehr große OSC-1337-Payloads.
- Keine Ausführung in einem echten OSC-1337-Terminal (headless, Windows-Shell, kein Rendern beobachtet).
- Verhalten der Vergleichs-Plugins (gehört in deren Reports).
