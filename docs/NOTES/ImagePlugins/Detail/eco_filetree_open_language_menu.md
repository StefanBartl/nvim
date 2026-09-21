# Oekosystem-Recherche: filetree.nvim, open.nvim, language.nvim, nvzone/menu (+ volt)

Stand: 2026-09-21. Read-only; nur temporaere Testskripte im Scratchpad (`t_gsub.lua`, `t_ps.lua`, `t_job*.lua`, `t_amp.lua`). Pfade relativ zu `E:\repos\<plugin>` sofern nicht anders angegeben. "DOCS" = Behauptung in der Dokumentation, "CODE" = im Code gelesen, "VERIFIED" = ausgefuehrt/gemessen (Windows 11, Neovim 0.12.2), "UNVERIFIED" = nicht geprueft.

## 0. Wichtigste Befunde (Kurzfassung)

1. **Premisse zu nvzone/menu ist veraltet.** nvzone/menu ist im User-Setup bereits deinstalliert; das Menue wird von `lib.nvim.contextmenu` + `lib.nvim.ui.kit.menu` (und parallel `ui.nvim`: `ui.contextmenu` + `ui.kit.menu`) gezeichnet. Ein "eigenes Rechtsklick-UI" existiert also schon (Details Abschnitt B.0).
2. **filetree.nvim und open.nvim rufen `images.show(path)` auf, NICHT `images.draw()` und NICHT `images.integrations.picker.*`.** (filetree `lua/filetree/features/ui/preview/init.lua:153,159`; open `lua/open/handlers/image.lua:25-27`). language.nvim hat keinen Bildbezug im Code.
3. **Gemessener Sicherheitsfehler (language.nvim, Windows):** Argumente mit `"` erreichen bei Nicht-.exe-Shims (`cmd.exe /c <shim> ...`) cmd.exe unescaped -> Command-Injection (VERIFIED mit harmlosem Marker). Betroffen: `trans`-Provider (Buffer-Text als argv).
4. **Gemessener Sicherheitsfehler (filetree.nvim, Windows):** `trash_windows` escaped in PowerShell-Skript nur `'`, nicht die typografischen Quotes U+2018/U+2019 -> Dateiname mit `’` bricht aus dem String aus (VERIFIED mit harmlosem Marker). Gleiche Escaping-Luecke in `undo.lua:180-181`.
5. **Gemessener Bug (filetree.nvim):** `preview/init.lua:130` uebergibt durch fehlende Klammern den gsub-Zaehler als extra argv-Element an `explorer.exe` (VERIFIED: `{ "explorer.exe", "x\\y", 1 }`). Die Schwesterstelle `util/pdf.lua:41` hat die Klammern (`(path:gsub(...))`).
6. **Docs/Code-Drift open.nvim:** DOCS sagen, `:Open image` faellt auch bei `images.show()`-Fehlschlag auf die System-App zurueck (`docs/FEATURES/HANDLERS.md:107-110`); CODE tut das nur, wenn images.nvim fehlt (`lua/open/handlers/image.lua:25-38`, bei Fehlschlag `return false` ohne Fallback).
7. **Doppelte Logik gegenueber lib.nvim:** `system_open` steht 3x in filetree (preview:123, util/pdf.lua:34, open_with:45), obwohl `lib.nvim.cross.open_default` existiert (open.nvim nutzt es: `handlers/default.lua:22`, `handlers/image.lua:35`, `office_open.lua:40`). Die Provider-Kette images.nvim -> snacks -> image.nvim steht in filetree (`preview/init.lua:144-206`) UND in `lib.nvim.image_preview` (`lua/lib/nvim/image_preview/init.lua:41-58,122`), von hover.nvim genutzt.

---

## A) Die drei Plugins

### A.1 filetree.nvim

**Zweck:** Adapter-agnostische Feature-Sammlung ueber neo-tree/nvim-tree/netrw/oil/mini.files (README.md:22-25).

**Groesse/Reife:** 131 Lua-Dateien, ca. 30 546 Zeilen `lua/`, 422 Commits (2026-06-29 bis 2026-09-20), README-Banner "Beta stage" (README.md:1-3). Ca. 60 registrierte Features in `lua/filetree/features/init.lua:19-100`. Tests: `TESTS/*.lua` (ca. 12 060 Zeilen, `smoke.lua`, `gaps.lua`, `units.lua`, `menu.lua` ...). Hohe Reife, aber Beta.

**Bild-/PDF-/Medien-Funktionalitaet (CODE):**
- Feature `ui.preview` (Default on laut DOCS `docs/configuration.md:101-103`): `<Tab>` und `<CR>` dispatchen Bilder/PDFs, alles andere Text-/Verzeichnis-Preview (`preview/init.lua:518-570`, Keymaps `:618-634`).
- Bild-Erkennung nur per Endung: png, jpg, jpeg, gif, bmp, svg, webp, ico, tiff, tif, avif, heic (`:77-90`). Keine Magic-Byte-Pruefung. Video/Audio: **nichts** (grep `ffmpeg|thumb|mp4|video|audio` in `lua/` -> nur `refs/assets.lua:36` Endungsliste `mp4`, `mov` fuer Cascade-Delete und `refs/DEFAULTS.lua:69`).
- Backend-Kette `open_image` (`:144-206`), Config `image.backend = "auto"|"images.nvim"|"snacks"|"image.nvim"|"system"|false` (`:46-48`, Typ `@types/config.lua:555-559`):
  1. `pcall(require, "images")`, dann `pcall(images.show, path)`; nur `true` gilt als Erfolg (`:152-161`). Kommentar `:148-151`: images.nvim sei das einzige Backend, das auf nativem Windows-Neovim (WezTerm) zeichnet.
  2. snacks: `snacks.image.supports(path)` dann `:edit` (`:168-189`).
  3. `pcall(require, "image")` -> `img.open(path)` (`:191-201`); die Existenz von `open()` bei 3rd/image.nvim ist UNVERIFIED.
  4. Fallback `system_open(path)` (`:204`).
- Explizit gewaehltes `images.nvim` ohne Plugin: nur `notify.warn`, kein Fallback (`:162-165`).
- Live-Preview (Cursor bewegt sich, buffer-Modus): **routet Bilder nicht**. `do_cursor_update` ruft `buf_show(path)` fuer jede Nicht-Directory-Node (`:471-483`); `buf_show` macht `bufadd` + `bufload` (`:419-429`) ohne Bild-/Binaer-/Groessen-Pruefung. `is_binary` wird nur im Float-Modus benutzt (`:296`). Ergebnis (CODE-Lesung, UNVERIFIED per Ausfuehrung): Cursor ueber ein `.png`/`.mp4`/grosses Log im aktiven buffer-Preview laedt die Datei komplett als Buffer.
- PDF: `filetree.util.pdf` (`lua/filetree/util/pdf.lua`) ist die einzige Kontaktstelle zu pdfport: `pcall(require,"pdfport")` in `has_pdfport` (`:59-62`), `open` (`:189`), `pick_open` (`:233`), `create` (`:134`, ruft `pp.create{inputs,on_conflict,__callback}` sequenziell `:139-169`). Fehlt pdfport oder wirft `pp.open`: Warnung + `system_open` (`:200-207`). Features `pdf_open` (default off, Key `gp`, `system/pdf_open/init.lua:31-38`) und `pdf_create` (default off, `INTEGRATIONS.md:157`).
- "Open with default app": `open_with` (`system/open_with/init.lua`) mit `apps = {{name, cmd, args, keymap}}`; `open_system` bevorzugt `vim.ui.open` (`:76-82`), Fallback per-OS-argv (`:45-54,59-69`). `open_in_fm` delegiert an `lib.nvim.cross.reveal_in_fm` (`system/open_in_fm/init.lua:93,103`).
- Thumbnails: keine. Bildmetadaten: `node_info` (Groesse/mtime) laut DOCS `UI.md`, nichts Bildspezifisches.
- Cascade-Delete-Assets (`refs/assets.lua`): Bild-Endungen + Root `assets` bewusst an images.nvims `paste.dir` angelehnt (`:28-36`); Klassifizierer, in Delete-Dialog noch nicht verdrahtet laut Modulkommentar (`:17-20`; ob inzwischen verdrahtet: UNVERIFIED).
- Rechtsklick-Menue: `integrations/menu.lua` liefert Gruppen fileops/clipboard/delete/open/paths/search/info/marks/window (`:188-268`); "open" enthaelt vsplit/split/tab/system app/file manager (`:212-221`). **Kein Bild-/PDF-Eintrag** (kein Preview, OCR, Show image).
- DOCS: `docs/around-it.md:18-21` nennt images.nvim ("the same idea for image nodes in the preview pane"). Doc-Drift: `docs/configuration.md:110` listet `backend = "snacks" | "image.nvim" | "system" | false`, nennt `images.nvim`/`auto` nicht, obwohl Code-Default `"auto"` (`preview/init.lua:47`).
- Tests: Bild-Dispatch nur fuer den Fall `image.backend=false` getestet (`TESTS/gaps.lua:2660-2747`); kein Test des `images.show`-Pfads oder des Windows-`system_open` (grep `images.show` in `TESTS/` leer).

**Externe CLI-Tools und Aufruf:**
- Bilder/PDF/Open: `explorer.exe` (Win), `open` (mac), `wslview` (WSL oder wenn vorhanden), `xdg-open`; immer argv-Liste (`jobstart(args,{detach=true})`, `preview/init.lua:123-140`; `vim.system(cmd,{detach=true})`, `open_with/init.lua:59-69`). Nie Shell-String.
- **Bug** `preview/init.lua:130`: `args = { "explorer.exe", path:gsub("/", "\\") }` -> gsub liefert (string, count) und beide landen im Table-Konstruktor (VERIFIED `{ "explorer.exe", "x\\y", 1 }`). Wirkung von `explorer.exe <pfad> 1` bei der Shell: UNVERIFIED. Die identische Stelle in `util/pdf.lua:41` ist korrekt geklammert.
- `open_with` bevorzugt `vim.ui.open` (`:77`), das laut Neovim-Runtime `ui.lua:189-190` auf Windows `cmd.exe /c start ""` verwendet, obwohl derselbe Code im Fallback (`:47-50`) und der Kommentar in `preview/init.lua:126-129` `cmd /c start` wegen `&` meiden. Gemessen (VERIFIED, Neovim 0.12.2, `echo`-Emulation `t_amp.lua`): libuv quotet ein argv-Element mit `&` inzwischen, sodass der befuerchtete `&`-Abbruch hier nicht auftrat. Inkonsistenz bleibt, Schwere niedrig.
- Trash: PowerShell `Shell.Application` (`trash/platform.lua:44-68`), macOS `trash` oder `osascript` (mit AppleScript-Escaping `:77-79`, `:102-106`), Linux `gio trash` / `trash-put` / manuell `mv` (`:113-130`), WSL `wslpath -w` + PowerShell (`:136-159`). Async via `vim.system` + `vim.schedule` (`:22-38`).
- `grep_in_dir`: `rg`/`grep` via `vim.system` argv (`search/grep_in_dir/init.lua:166-192`). `shell_run`: absichtlich Shell-String an `jobstart(cmd,{term=true})` bzw. `termopen` (`shell_run/init.lua:71-77`), Befehl kommt aus User-Eingabe (`ui.kit.input`, `:94-99`).
- Weitere Prozesse: `git_status/init.lua:67`, `size_info/init.lua:137`, `refs/scan.lua:122` (`vim.system`).

**Sicherheit:**
- Kein Shell-String bis auf `shell_run` (User tippt selbst). Positiv: Kommentare zu SEC-Fixes (AppleScript-Backslash-vor-Quote, `platform.lua:91-101`).
- **Gemessen:** `trash_windows` (`trash/platform.lua:51-66`) und `restore_windows` (`undo.lua:180-181`) escapen nur `'` -> `''`. PowerShell behandelt U+2018/U+2019/U+201A/U+201B ebenfalls als Quote. Test `t_ps.lua`: Name `x’; Write-Output INJECTED_MARKER; ‘y` -> stdout `x`, `INJECTED_MARKER`, `y` (VERIFIED). Ein Dateiname in einem geklonten Repo reicht; wird beim Trash (Default-Aktion `d`, mit Bestaetigung) ausgefuehrt. Empfehlung: Pfad nicht in den Skripttext interpolieren, sondern als `-LiteralPath`-Parameter/`$args[0]` uebergeben.
- Bestaetigung: Trash `confirm = true` per Default, "permanent" ist opt-in (`trash/init.lua:75-85,103-115`); `safety`-Feature (Backup vor Delete/Move, dry_run) ist **default off** (`config/DEFAULTS.lua:~108`, `features/infra/safety/init.lua:24-47`). Batch-Dialog mit "delete all / confirm each / cancel" (`trash/init.lua:15-18`, `:489`).
- Geschuetzte Pfade (Home, Wurzel, Laufwerksroot): keine Logik gefunden (grep `protected|is_root` leer) -> UNVERIFIED, dass nichts anderswo davor schuetzt.
- DOCS vs CODE: `docs/installation.md` sagt "without [trash-put/gio], delete is a real delete"; CODE faellt auf `mv` nach `$XDG_DATA_HOME/Trash/files` zurueck (`platform.lua:124-129`) ohne `.trashinfo`, `mv` kann gleichnamige Trash-Datei ueberschreiben und `vim.env.HOME` ist auf Nicht-Linux nil (Fehler). Niedrige Schwere.
- Kein Executable-Schutz: `open_system` (`<leader>sm`) und der `system_open`-Fallback reichen jede Node an den OS-Default-Handler; bei `.exe/.bat/.lnk` fuehrt Explorer aus (Standardverhalten, UNVERIFIED per Ausfuehrung, bewusst nicht ausgefuehrt).

**Performance-Muster (CODE):**
- Debounce fuer CursorMoved-Preview 80 ms (`preview/init.lua:38,590`, `lib.nvim.debounce`), `eventignore` um bufload/set_buf, damit cwd_sync/auto_reveal nicht feuern (`:399-415`).
- Trash/grep/refs-Scan asynchron (`platform.lua:14-18`, `grep_in_dir:186-192`); batched Referenz-Scan (ein Scan statt N, `refs/assets.lua:80-125`); sequenzielles `pdf create` gegen Prozess-Sturm (`util/pdf.lua:117-121`).
- Schwaechen: `buf_show` ohne Groessen-/Binaer-Guard (s.o.); `is_binary` liest per `readfile(path,"b",1)` die erste "Zeile" (`:228-239`), bei Binaerdatei ohne `\n` potenziell die ganze Datei (UNVERIFIED).

**Anbindung an images.nvim:** weicher Zugriff, `pcall(require,"images")` (`preview/init.lua:153`), Funktion `images.show` (existiert: `images/init.lua:98`). Fehlt images.nvim: Auto-Modus geht weiter zu snacks/image.nvim/System; explizit `"images.nvim"`: Warnung, kein Fallback. Kein `images.draw`, kein `integrations.picker` (grep im ganzen Repo leer).

**Duplizierte Logik vs lib.nvim:** `system_open` 3x (`preview/init.lua:123`, `util/pdf.lua:34`, `open_with/init.lua:45`) gegen `lib.nvim.cross.open_default` (`lua/lib/nvim/cross/open_default/init.lua:81-137`: absolute Windows-Pfade, WSL-`wslpath`, saubere Fehlerrueckgabe, `run_detached`). Bild-Provider-Detektion doppelt gegen `lib.nvim.image_preview.detect()`. lib.nvim ist harte Abhaengigkeit: 77 `require("lib.nvim...")`-Stellen; einzige `pcall` sind Health/Deps (`health.lua:24,364,375`, `init.lua:276`). `ui.nvim` ist laut DOCS ebenfalls hart (`docs/installation.md`, `shell_run/init.lua:94` `require("ui.kit")` ungeschuetzt); nur `ui.contextmenu` degradiert zu einem Notify (`context_menu/init.lua:235-245`).

**Erweiterungspunkte:** Adapter-Interface fuer weitere Baeume (`docs/api.md`), Feature-Registry (`features/init.lua`), `hooks_api`-Feature (Infra), `bind`-Specs pro Feature (Keymap ueberschreib-/abschaltbar), `menu`-Config-Gruppen (`config/DEFAULTS.lua:40-53`), `integrations/menu.lua` `items()`/`submenu()`/`window_entry()` (`:136,178,277`). Kein Hook, um einen weiteren Datei-Typ-Previewer (z. B. Bild-Thumbnail) einzuhaengen; `_IMAGE_EXTS` und die Backend-Kette sind Modul-lokal (`preview/init.lua:77,144`).

### A.2 open.nvim

**Zweck:** `:Open [target] [scope]` schickt Pfad/URL/Text unter dem Cursor an das passende Ziel (Default-App, Browser, File-Manager, Notepad, Terminal, Bild, Neovim-Split) plus `:Open viewer` (Link-Liste) (README.md:22-27).

**Groesse/Reife:** 26 Lua-Dateien, ca. 4 253 Zeilen, 118 Commits (2026-06-24 bis 2026-09-20), Beta-Banner (README.md:1-3), 18 Spec-Dateien in `TESTS/`. CI-Badge vorhanden. Kleiner, klar geschnitten.

**Bild-Funktionalitaet:**
- Genau ein Handler: `open.handlers.image` (`lua/open/handlers/image.lua:24-47`), Key `image`, per Default geladen (`config/DEFAULTS.lua:10-20`; Keymap-Key `open_image`).
- Ablauf: `pcall(require,"images")` -> `type(images.show)=="function"` -> `pcall(images.show, ctx.text)` (`:25-27`). `shown` truthy -> true; sonst `return false` ohne Fallback (`:28-31`). **Nur wenn images.nvim fehlt:** Info + `lib.nvim.cross.open_default(ctx.text)` (`:34-37`). DOCS behaupten mehr (`docs/FEATURES/HANDLERS.md:107-110`). Test deckt nur "fehlt" und "Erfolg" ab (`TESTS/handlers_spec.lua:50-92`).
- Keine Endungspruefung: `ctx.text` kann beliebiger Text/URL sein (`context.lua:376-382`); die Pruefung liegt bei `images.show`.
- Nebenfunktion: `office_open` (Default an) leitet `doc/docx/xls/xlsx/ppt/pptx` per `BufReadCmd` an die System-App (`office_open.lua:51-63`, `config/DEFAULTS.lua`). **Kein** entsprechender Redirect fuer Bild-Endungen.
- Rechtsklick: `integrations/menu.lua:47-96` liefert Open / Open in Browser / Reveal in File Manager / Open in Terminal / List Links Here; **kein "Open image"**. Menue-Bausteine aus `ui.contextmenu` per `pcall` (`:34-37`); ohne ui.nvim leere Liste.

**Externe CLIs:** keine Pflicht. Explorer/open/xdg-open/wslview, Browser (`chrome, chromium, firefox, edge, brave, opera, safari`), `notepad.exe`/`gedit`-Kandidaten, `wslpath`. Aufruf immer argv (`open/util.lua:24-36` -> `lib.nvim.cross.run.run_detached`). Ausnahme benannter Browser unter Windows: `{ "cmd.exe","/C","start",token, cmd_escape_unquoted(url) }` (`handlers/browser.lua:63-64`); Escaper (`util.lua:~80-84`) caret-escaped `& | < > ^`, nicht `%` (Umgebungsvariablen-Expansion, UNVERIFIED, niedrige Schwere). Default-Browser/System: `explorer.exe url` (`browser.lua:41-44`).

**Sicherheit:** Positiv: SEC-34 -- `expand_path` statt `vim.fn.expand`, weil letzteres Backtick-Spans ueber die Shell ausfuehrt (`context.lua:92-99`, `handlers/terminal.lua:26-31`, `browser.lua:27-29`, `filemanager.lua`); Keyword-Resolver per `pcall` (`context.lua:353-363`); argv statt Shell. Negativ/offen: `default`/`image`-Fallback oeffnen jeden Pfad ueber den OS-Handler ohne Allowlist (Executables laufen; UNVERIFIED per Ausfuehrung). Keine Bestaetigungsdialoge (read-only Plugin). Kontext-Text aus `<cWORD>`/Visual-Selection (`context.lua:241-257`) kann beliebig sein; `url_encode` fuer Suchtexte (`util.lua:~55-63`).

**Performance:** `context.with_cache` memoisiert `gather()` pro Aufruf (`context.lua:35-53`); Git-Root per `vim.fs.find` statt `git rev-parse` (`context.lua:117-125`); Lazy-Load nur ueber `cmd` empfohlen (`docs/installation.md`); `keywords.lua:53` `vim.system(...):wait()` synchron, nur bei Bedarf.

**Anbindung an images.nvim:** weich, `pcall(require,"images")`, Funktion `images.show`. Kein `images.draw`/`integrations.picker`.

**Duplizierte Logik:** Positiv: `default`, `image`-Fallback, `office_open` delegieren an `lib.nvim.cross.open_default`; `filemanager` an `lib.nvim.cross.reveal_in_fm`. Doppelung: eigene Tree-Node-Aufloesung fuer neo-tree/nvim-tree/netrw (`context.lua:132-210`) parallel zu filetrees Adapter-Interface; `resolve_neotree_path` greift zusaetzlich auf ein **User-Config-Modul** `config.neotree.utils.node` zu (`context.lua:146`, per `pcall`) -- Kopplung eines oeffentlichen Plugins an die persoenliche Config.

**Erweiterungspunkte:** `registry.register(handler)` (`registry.lua:22`), `custom_handlers` in der Config (`DEFAULTS.lua`), `keywords`, `open.integrations.{menu,telescope,urlview}`, `picker.enabled` (Handler-Auswahl), Viewer-Sinks (`viewer.output`). Bild-Handler koennte per `custom_handlers` ersetzt werden.

**Kleiner Punkt:** Mindestversion: README-Badge/`installation.md` "0.9+", `health.lua:23-26` kennt einen 0.10-Zweig; filetree-DOCS sagen, lib.nvim brauche 0.10 (`docs/installation.md` filetree) -> Angabe 0.9+ ist UNVERIFIED belastbar.

### A.3 language.nvim

**Zweck:** Spelling, Grammatik, Uebersetzung und Synonyme im aktuellen Buffer, asynchron (README.md:22-26).

**Groesse/Reife:** 51 Lua-Dateien, ca. 8 178 Zeilen (+ `node/cspell_server.js`), 112 Commits (2026-07-13 bis 2026-09-20), Beta-Banner, 31 Spec-Dateien in `TESTS/`.

**Bezug zu Bildern -- ehrlich:** **Keiner im Code.** Grep `image|ocr|tesseract|png|jpg|screenshot` ueber `lua/ docs/ doc/ README.md TESTS/` ist leer; einziger Filetype-Bezug `vim.filetype.match` beim Anlegen uebersetzter Datei-Buffer (`lua/language/translate/files.lua:125`). Kein i18n der UI-Strings (grep `gettext|i18n|locale` leer), keine Sprach-Erkennung ausser Provider-Autodetektion (`google.lua:72` `sl=auto`, bei `trans` leeres Source-Feld `shell.lua:31`). Der einzige Bezug ist **einseitig aus images.nvim**:
- `images/ocr.lua:9-17` begruendet ausdruecklich, dass es keine Bruecke zu language.nvim gibt (alle Einstiege buffer-gebunden).
- `images/init.lua:539-540`: OCR-Ergebnis-Buffer bekommt `filetype=markdown`, "das ist was language.nvims Spellcheck und `:Translate` ... als Prosa behandelt".
- User-Config: `ocr = { lang = "deu+eng" }` (`nvim/lua/plugins/personal/init.lua`, images-Spec ca. Z. 541).
- Code-Mismatch fuer einen kuenftigen Zusammenhang: language.nvim nutzt DeepL-Stil-Codes `EN, DE, FR, ZH, JA` (`config/DEFAULTS.lua:82`) und Vim-`spelllang` (`:17`); tesseract will `deu+eng`. Ein Mapping in beide Richtungen existiert nirgends (UNVERIFIED, dass es ausserhalb der drei Repos eines gibt).
- Indirekt: `language/hover.lua` registriert eine `on_request`-Position-Preview bei hover.nvim (`:1-30`); hover.nvim zeigt Bilder (nicht in diesem Auftrag).

**Externe Tools/Aufruf:** `curl` Pflicht (Google-keyless + DeepL; `google.lua:76-86` argv `curl -s --compressed -G --data-urlencode q=<text>`), optional `node` (persistenter cspell-Sidecar, `cspell_server.lua:222` `jobstart({"node", script, entry})`), `cspell`, `codespell`, `typos`, `trans` (`docs/requirements.md`). Alles ueber `language.util.job` (argv, `vim.system`, Timeout, cancel, `stdin` fuer Geheimnisse, `util/job/init.lua:1-9,44-47`).
- **Windows-Sonderfall** `util/job/init.lua:21-40`: alles, was nicht `.exe/.com` ist (npm-Shims), laeuft als `{"cmd.exe","/c",path,args...}`; Argumente werden **nicht** escaped. Test `t_job2.lua` mit Fake-Shim `fakeshim.cmd`: Argument `a" & echo INJECTED_C & "b` -> `INJECTED_C` lief als eigener Befehl, `"b"` als unbekannter Befehl (VERIFIED). Ohne `"` blieb es sicher (libuv quotet Argumente mit `&`/Space). Praktisch betroffen: `trans` (Buffer-Text als ein argv, `translate/providers/shell.lua:33-42`) wenn `trans` ein Shim ist; cspell/typos/codespell bekommen nur Pfade (Windows-Dateinamen enthalten kein `"`). curl ist `.exe` -> nicht betroffen. Ob `trans` auf dem User-Rechner ein Shim ist: UNVERIFIED.
- Datenschutz (DOCS+CODE): jeder Uebersetzungsaufruf sendet Text an einen Web-Endpunkt; deshalb `on_request` fuer die Hover-Integration (`hover.lua:16-22`).

**Sicherheit weiter:** `--files=replace` verifiziert vor dem Ueberschreiben, dass sich die Datei nicht geaendert hat (`translate/files.lua:~127-140`), Bestaetigungs-Workflow laut `docs/WORKFLOW.md`. Pfadbehandlung per `scope`-Modul (`scope/init.lua`); nicht vertieft.

**Performance:** async Jobs mit Timeout 8000 ms (`google.lua:87`, `shell.lua:42-44`), Cache (`spell/core/cache.lua`), Live-Spell (`spell/live.lua`), Sidecar gegen Prozessstart (`docs/requirements.md`).

**Anbindung an images.nvim:** keine. **Duplikate vs lib.nvim:** eigener Job-Runner `language.util.job` statt `lib.nvim.cross.run_argv`/`run`; UI ueber `ui.kit` (optional, `docs/requirements.md`). **Erweiterungspunkte:** `translate.providers.registry`, Custom-Provider (`translate/providers/custom.lua`, `spell/providers/custom.lua`), Thesaurus `custom`-Funktion (`DEFAULTS.lua:118`).

**Fazit A.3:** Fuer die Bild-Suite ist language.nvim nur als *Downstream* relevant (OCR-Text -> Buffer -> `:Translate`/Spell). Kein Code muss angepasst werden; sinnvoll waere hoechstens ein gemeinsames Sprachcode-Mapping (tesseract <-> DeepL/spelllang) in lib.nvim.

---

## B) nvzone/menu (+ volt)

### B.0 Realer Zustand im User-Setup (wichtig)

- `nvzone/menu` ist **nicht installiert**: `C:\Users\bartl\AppData\Local\nvim-data\lazy\` enthaelt kein `menu/` (nur Reste `volt/`, `minty/`); `lazy-lock.json:17` fuehrt `menu` noch als toter Eintrag (Commit `7a0a4a2`, identisch mit dem Shallow-Clone). `lua/plugins/nvchad.lua:1-27` setzt `{ "nvzone/menu", enabled = false }` und sagt, ein `require("menu")` komme im gesamten Plugin-Baum nicht mehr vor. `Menu.md:3-9` (docs\NOTES\ExternPlugins\Bindings\Keymaps\Menu.md) bestaetigt: seit 2026-09-08 `lib.nvim.ui.kit.menu` ueber `lib.nvim.contextmenu`; die Datei liegt "nur noch aus Link-Stabilitaet" unter `ExternPlugins/`. Der User-Satz "nur Platzhalter, bis ein eigenes Rechtsklick-UI geschrieben ist" ist damit **bereits eingeloest**.
- `volt`/`minty` sind laut `lua/plugins/nvchad.lua:17-20` und `lua/plugins/ui.lua:57` seit 2026-09-19 nirgends mehr deklariert; die Ordner in `lazy/` sind verwaist.
- Dispatcher: `lua/config/menu/init.lua:23-37` (`contextmenu.setup{renderer="kit"}`), `lua/config/menu/mappings.lua` (`<A-b>` Cursor, `<RightMouse>` Zeiger, `CONTRIBUTORS`-Liste `:47-140`).
- **Zwei parallele Implementierungen im Umlauf:** `lib.nvim.contextmenu` (346 Z., von der User-Config genutzt: `config/menu/init.lua:23`) und `ui.nvim`'s `ui.contextmenu` (379 Z.; von filetree hart genutzt: `filetree/features/ui/context_menu/init.lua:235`, von `images.integrations.menu` als Top-Level-`require`: `images/integrations/menu.lua:19`, von open.nvim per `pcall`: `open/integrations/menu.lua:34`). ui.nvims README sagt noch, filetree zeige auf `lib.nvim.contextmenu` (`ui.nvim/lua/ui/contextmenu/README.md:1-6`), der filetree-Code tut das nicht mehr (Doc-Drift). Ebenso doppelt: `lib.nvim.ui.kit.*` und `ui.nvim`'s `ui.kit.*` (`lib.nvim/lua/lib/nvim/ui/kit/menu.lua` vs. `ui.nvim/lua/ui/kit/menu.lua`, 820 Z.). Laufende Migration ("PLAN-ui-kit-migration.md" im ui.nvim-README erwaehnt). Welche der beiden zur Laufzeit im User-Setup gewinnt bzw. dass beide gleichzeitig geladen werden: UNVERIFIED.

### B.1 Architektur von nvzone/menu (CODE, Clone `scratchpad/src/menu`)

- 5 Dateien Kern (`lua/menu/`: `init.lua` 111 Z., `ui.lua` 74, `utils.lua` 94, `mappings.lua` 69, `state.lua` 7, `layout.lua` 6) plus Beispielmenues `lua/menus/{default,gitsigns,lsp,neo-tree,nvimtree}.lua`. ca. 805 Zeilen gesamt. Lizenz **GPL-3.0** (GitHub-API), also nur als lose Laufzeit-Abhaengigkeit sinnvoll, nicht als kopierbarer Code fuer MIT-Plugins.
- Rendering: `menu.open(items, opts)` erzeugt einen Scratch-Buffer und ein Float (`nvim_open_win`, `relative = "mouse"|"cursor"`, `border="single"`, `zindex = 99 + #bufids`, `menu/init.lua:22-64`). Der Buffer enthaelt nur Leerzeichen; Text/Farben sind **Virtual-Text-Extmarks** (`volt/draw.lua:44-48`, `virt_text_win_col`). `filetype=NvMenu`, dann `volt.run`.
- volt (`lazy/volt/lua/volt/`, ca. 1 206 Z.): kleines UI-Toolkit (`gen_data`, `redraw`, `run`, `close`, Komponenten in `ui/`), Klick-/Hover-Tabellen pro Zeile (`draw.lua:20-38`).
- Items-Schema: `{ name, cmd = string|function, rtxt = right hint (im Keyboard-Modus zugleich die Taste!), items = nested, hl, title=true, keybind (nur fuer Nested) }`, Separator `{ name = "separator" }` (`ui.lua:8-11,54`, `mappings.lua:8-33`). **Kein** `icon`-Feld, kein `disabled`/`visible`/`enabled`, kein `on_close`, kein Kontextobjekt, keine Async-Items, keine Ueberschriften/Gruppen.
- Nested: Klick auf ein Item mit `items` toggelt ein zweites Float **rechts daneben** (`utils.toggle_nested_menu`, `menu/init.lua:41-54`); Hover oeffnet nicht. Eingabe per Tastatur nur im Nicht-Maus-Modus: `h/l` wechselt Fenster, `q` schliesst, `rtxt`-Taste loest aus (`mappings.lua:8-45`).
- Kontexte (NvimTree/neo-tree): keine Automatik; der Host waehlt per Filetype (README-Beispiel `vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"`, README:40-49). Menues als benannte Module `menus.<name>`.
- Globaler Zustand: `menu/state.lua` (`bufs`, `bufids`, `config`), also nur ein Menue gleichzeitig; `state.config` wird beim ersten Open gesetzt und erst beim Schliessen geleert (`init.lua:24-27,68-77`).
- Ausfuehrung: Menue wird **vor** `cmd` geschlossen (`volt.close(buf)`, `ui.lua:39`), Fehler per `vim.notify` (`ui.lua:42-51`); danach Fokus/Cursor zurueck ins alte Fenster (`init.lua:68-81`). Deshalb eignet sich das Ziel-Fenster/Node als Kontext (so nutzt es filetree: `integrations/menu.lua:10-11`).

### B.2 Kann es Bilder/Preview im Menue?

Nein. Zeilen sind Text-Extmarks in einem Leerbuffer; es gibt weder Preview-Pane noch Bild-Slot. Bild-Preview waere nur ein separates Overlay (z. B. `images.browse.draw_in_window`, wie `lib.nvim.image_preview` es fuer Floats nutzt, `lib/nvim/image_preview/init.lua:128-153`); das Menue bekaeme davon kein Lifecycle-Signal (`on_close` fehlt). Im User-Kit-Renderer gibt es zwar `surf:on_close` (`filetree/.../context_menu/init.lua:252`, `ui.contextmenu` `@types` `open` gibt die Surface zurueck) und `ui.kit.compare` erlaubt terminalgezeichnete Bilder (`kit/compare.lua:35-44`), aber kein eingebautes Menue+Preview.

### B.3 Abhaengigkeiten, Wartung

- Abhaengig von `nvzone/volt`. Highlight-Gruppen `ExBlack2Bg`, `ExBlack2Border`, `ExLightGrey`, `ExBlack3Bg` werden von volt (`volt/highlights.lua`) aus base46 oder aus `Normal`/`Comment` abgeleitet; im base46-Zweig heisst eine Gruppe `ExBlack2border` (kleines b, `highlights.lua:17`), das Menue nutzt `ExBlack2Border` (`menu/init.lua:60`) -> Tippfehler-Drift (kosmetisch, UNVERIFIED sichtbar).
- Wartung (GitHub-API, 2026-09-21): **menu**: 667 Sterne, letzter Push 2025-06-01 (`7a0a4a2 feat: support for nested menus hotkeys (#28)`), 4 offene Issues, nicht archiviert. **volt**: 399 Sterne, letzter Push 2025-09-13, 5 offene Issues; volt-README: "Docs to be added soon before 2026" (`volt/README.md`). Also ca. 15 Monate ohne Code-Commit bei menu. (`updated_at 2026-09-19` betrifft nur Repo-Metadaten.)

### B.4 Maus-Eigenheiten Windows/WezTerm (CODE; Verhalten selbst UNVERIFIED)

- volt schaltet beim ersten Menue **global** `vim.o.mousemev = true` und registriert einen `vim.on_key`-Handler, der nie entfernt oder zurueckgesetzt wird (`volt/events.lua:92-114`; `volt/init.lua` `if not vim.g.extmarks_events then enable()`). Der Kit-Renderer sichert/restauriert `mousemoveevent` dagegen (`ui.nvim/lua/ui/kit/chooser.lua:303-337`).
- Hover/Klick basieren auf `getmousepos()` und dem `<MouseMove>`-Pseudo-Key; setzt Terminal-Anymotion-Reporting voraus (WezTerm unterstuetzt es grundsaetzlich; auf dem User-Rechner UNVERIFIED). Kommentar im Kit (`chooser.lua:228-236`) nennt genau diese Frontend-Fragilitaet.
- Maus-Modus installiert ein **globales** `<LeftMouse>`-Mapping (nicht buffer-lokal) fuer "Klick ausserhalb schliesst", das nur im Zweig "ausserhalb geklickt" wieder geloescht wird (`menu/mappings.lua:52-66`) -> bleibt sonst bestehen (Code-Smell, UNVERIFIED wie sichtbar).
- `relative="mouse"` und `nvim_open_win(buf, not config.mouse, ...)` (Fokus bleibt im Maus-Modus im alten Fenster, `menu/init.lua:36,57`). Die Nested-Position berechnet sich aus `getmousepos()` (`:47-53`) -> in Keyboard-Modus abweichende Formel.
- Neovims eigenes Popup: `mousemodel=popup` (Default) zeigt bei Klicks ohne Mapping das native Menue; `ui.contextmenu.setup` setzt daher `mousemodel="extend"` (`ui.nvim/lua/ui/contextmenu/init.lua:104-127`, `README.md`).

### B.5 Was der User heute an Bild-Eintraegen hat

- Kontribuenten-Liste enthaelt `images.integrations.menu` (`config/menu/mappings.lua:~99-109`, Icon `icons.lua:71`). Der Inhalt (`images/integrations/menu.lua:36-92`): Show image under cursor, Gallery, Next/Previous, Paste from clipboard, Take a screenshot, Show image info. **Nur** in Buffern mit `keymaps.filetypes` (markdown/vimwiki/norg/text; `:36-40`). Nicht im Tree-Buffer, nicht in einem Bild-Buffer.
- filetree-Rechtsklick (`integrations/menu.lua`) und `open`-Fly-out haben **keine** Bild-/PDF-Eintraege (siehe A.1, A.2). Filetree bindet seinen eigenen buffer-lokalen `<RightMouse>` (`context_menu/init.lua:268-270`), der globale Dispatcher wird im Tree nie erreicht (`Menu.md`, "Trigger-Keymaps").
- Nicht vorhanden in `images.nvim` (grep leer): Rotate/Flip. Vorhandene Funktionen, die ein Menue anbieten koennte: `scale` (`images/init.lua:433`), `optimise` (`:460`), `convert` (`:509`), `ocr` (`:545`), `redact` (`:575`), `export` (`:403`), `replace` (`:391`), `info` (`:340`), `zen` (`:651`), `compare` (`:700`).

### B.6 API, die ein Rechtsklick-UI fuer die Bild-Suite braeuchte, und was fehlt

Mindest-Vertrag (Vorschlag):
1. **Kontextobjekt statt "cursor lesen":** `ctx = { kind = "image_file"|"image_link"|"pdf"|"text", path, buf, win, tree_node, selection[], is_remote }`, einmal vom Trigger ermittelt (Tree-Node, `<cfile>`, Markdown-Link, Bild-Buffer) und an alle Provider gereicht. Heute rekonstruiert jedes Plugin das selbst (`open/context.lua:132-210`, filetree Adapter, images `resolve.path_or_cursor`).
2. **Provider-Registry:** `register({ id, applies(ctx), items(ctx), order })` statt handgepflegter `CONTRIBUTORS`-Liste (`config/menu/mappings.lua:47-140`) und statt `require("<plugin>.integrations.menu")` per Namenskonvention.
3. **Item-Schema:** `label, icon, hint/keymap, action(ctx), enabled(ctx)|disabled reason, visible(ctx), submenu, toggle/checked, group/heading, mnemonic, async status (busy/progress)`. Die Kit-Variante hat schon `icon`, `icon_hl`, `heading`, `group`, `submenu`, `rtxt` (`ui.contextmenu/@types/init.lua:4-21`), aber nur `entry(available,...)` = ausblenden statt "ausgegraut mit Grund" (`ui.contextmenu` `entry`, `:174`).
4. **Aktionen fuer Bilder:** Show/Preview (`images.show`), Open externally (`lib.nvim.cross.open_default`), Reveal in file manager, Copy path / Copy as Markdown link / Copy image to clipboard (letzteres in images.nvim UNVERIFIED), OCR (`images.ocr` -> Buffer -> `:Translate`), Info, Scale/Convert/Optimise/Export, Redact, "Replace", Compare/Gallery, Delete (via filetree-Trash), Rotate (heute nirgends implementiert).
5. **Preview im Menue:** optionale Preview-Spalte/-Flaeche mit Lifecycle (`on_open/on_select_change/on_close`) fuer terminalgezeichnete Bilder; `ui.kit.compare` zeigt das Muster (`render(item, surface)` + `opts.clear`).
6. **Multi-Selection:** Marks (filetree `marks`) / Visual-Selection als `ctx.selection`, Batch-Aktionen (Convert alle, Optimise alle).
7. **Lifecycle/Positionierung:** `open()` gibt Handle mit `on_close`, `close()`, `relative/win/anchor` (existiert im Kit: `ui.contextmenu` `OpenOpts`, `:47-56`), kein globaler Singleton-State.
8. **Robustheit:** `mousemoveevent`-Sicherung/Restore, Fallback ohne Hover, Tastatur-Navigation auch im Maus-Modus, Test-Harness fuer Trigger.

Was **nvzone/menu** davon nicht kann: 2 (keine Registry), 1 (kein Kontext), 3 (kein Icon-Feld, kein disabled/visible, keine Headings), 5 (keine Preview), 6, 7 (kein `on_close`, Singleton-State, globaler `LeftMouse`-Map), 8 (globales `mousemev`), Tastatur im Maus-Modus, Nested nur per Klick, GPL-3.0. Was der eigene Stack (ui.nvim/lib.nvim) schon kann: Icon-Spalte, Gruppen mit Rahmen, Drill-down mit Back, Hover mit Restore, `surf:on_close`, Positionierung `win/anchor/row/col`, `native_popup`-Steuerung, `bind_buffer`. Was **auch dort noch fehlt**: 1, 2, 3 (disabled/visible), 5, 6, 7-Registry, Bild-Eintraege im Tree- und Bild-Buffer-Kontext, Vereinheitlichung der doppelten Stacks (lib.nvim vs ui.nvim).

---

## Empfehlungen fuer die Bild-Suite (aus dieser Recherche)

1. filetree und open sollten die Provider-Detektion/Preview ueber **eine** Stelle laufen lassen (`lib.nvim.image_preview` oder eine images.nvim-API), statt eigener Ketten (`preview/init.lua:144-206`, `image.lua`).
2. filetree: `system_open` durch `lib.nvim.cross.open_default` ersetzen (behebt auch den gsub-Bug `preview/init.lua:130`); `buf_show` mit Bild-/Binaer-/Groessen-Guard versehen (Bilder auch im Live-Preview an images.nvim routen).
3. filetree-Rechtsklick: Gruppe "Image/PDF" (Preview, Open externally, OCR, Info) fuer `is_image`/`is_pdf`-Nodes; open.nvim-Menue: "Open image" ergaenzen; docs/HANDLERS.md an das reale Fallback-Verhalten angleichen oder Code nachziehen.
4. Escaping-Luecken schliessen: `trash/platform.lua:51`, `undo.lua:180-181` (Pfad als PS-Parameter statt Skript-Interpolation), `language.util.job` (kein `cmd.exe /c` mit rohen Argumenten; Shim per `.cmd`-Aufloesung ohne Nutzertext oder Text ueber stdin).
5. Rechtsklick-UI: Kontext + Provider-Registry in `ui.nvim` konsolidieren (lib.nvim-Duplikat abbauen), dann Bild-Provider dort registrieren.

## Unverifiziert / nicht geprueft

- Verhalten von `explorer.exe <pfad> 1` (Extra-Argument) und von Explorer beim Oeffnen von Executables.
- Ob `trans` auf dem User-Rechner ein `.cmd`-Shim ist (Voraussetzung fuer die language.nvim-Injection).
- Ob `3rd/image.nvim` `image.open(path)` bereitstellt (`preview/init.lua:193`).
- Maus-Hover/`mousemoveevent` in WezTerm auf dem User-Rechner; sichtbare Folgen des verbleibenden globalen `<LeftMouse>`-Maps von nvzone/menu.
- Ob beide Stacks (lib.nvim vs ui.nvim) im User-Setup gleichzeitig geladen werden; ob `cascade-delete-assets` inzwischen im Delete-Dialog verdrahtet ist.
- images.nvim-Clipboard-Copy-Funktion fuer Bilder; Stargazer-Zahlen sind Stand der GitHub-API-Abfrage von heute.
