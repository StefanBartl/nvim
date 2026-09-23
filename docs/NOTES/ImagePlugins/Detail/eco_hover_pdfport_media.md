# Okosystem-Recherche: hover.nvim / pdfport.nvim / media.nvim (Bezug zu Bildanzeige)

Read-only. Stand: 2026-09-21, alle drei Repos auf HEAD von `E:\repos\<name>`. Pfade relativ zum jeweiligen Repo,
`lua/`-Prefix meist weggelassen wo eindeutig. "DOCS" = Behauptung in README/Docs, "CODE" = im Quelltext gelesen.
Nichts ausgefuehrt (keine Tests gestartet, keine Tools aufgerufen) -> Laufzeitverhalten ist "gelesen", nicht "gemessen".

---------------------------------------------------------------------------------------------------

## 0. Kurzfassung (Kernaussagen fuer die Bundle/Suite-Frage)

1. **Nur hover.nvim rendert Bilder "im Sinn von images.nvim"; pdfport und media zeigen selbst nichts an.**
   - hover: zeichnet nie selbst, sondern ruft images.nvim (`images.anchor.draw`, Fallback `images.browse.draw_in_window`) auf
     (`hover/preview/media.lua:298-331`). Textfallback = Metadaten (`media.lua:526-544`) bzw. Unicode-Bloecke
     fuer Video (`images.blocks`, `preview/video.lua:271-380`).
   - pdfport: erzeugt PNG-Pfade (`core/rasterize.lua:80`), eigener Terminal-Renderer ueber `:terminal` + chafa/kitten/imgcat
     (`renderers/terminal.lua:65-100`) -- **komplett unabhaengig von images.nvim** (0 Treffer fuer `require("images` in `lua/pdfport`).
   - media: erzeugt PNGs (ffmpeg), zeigt sie ueber `images.show(png)` -> Fallback `open_default` -> Pfad per notify
     (`media/ui.lua:167-182`).
2. **Harte Abhaengigkeiten**: hover -> lib.nvim (hart), pdfport -> lib.nvim (hart, weit mehr als docs sagen), media -> lib.nvim (WEICH, alles pcall).
   Alle uebrigen Querverbindungen (images/pdfport/media/gopath/open/ui.nvim/ai.nvim) sind weich via `pcall(require, ...)`.
3. **Mehrfach implementiert** (Suite-relevant): Endungs-Tabellen (4x), Tool-Erkennung (>=5 Varianten), PDF-Seite->PNG-Cache (3x),
   Chrome-Erkennung (2x), tesseract/pdftoppm-Aufruf (3x pdftoppm-argv in pdfport allein), Terminal-/Provider-Erkennung (3x), Cache-Wurzeln (>=4).
4. **Gefundene Ungereimtheiten** (Details in Abschnitt 9): snacks/image.nvim-only -> leerer Float in hover; soffice-Erkennung
   health-vs-runtime inkonsistent in pdfport; `pdfport.render_page` ohne Timeout/Cancel; media-Cache ohne TTL/Cap.

---------------------------------------------------------------------------------------------------

## 1. hover.nvim

### 1.1 Zweck / Groesse / Reife
- **Zweck**: Cursor ruht auf Dateipfad/Markdown-Link -> Float zeigt, worauf es zeigt (Text-Kopf, Bild, PDF-Seite, Office-Seite, Video-Standbild, URL-Status/Screenshot). (`README.md:24-25`)
- **Groesse**: 40 Lua-Dateien, ~16.2k Zeilen (`init.lua` allein 2283, `config/DEFAULTS.lua` 993, `preview/media.lua` 976, `status_view.lua` 914).
- **Reife**: 155 Commits (2026-09-01 .. 2026-09-20 = 20 Tage!), Beta-Banner (`README.md:1-3`), 29 Spec-Dateien / 576 `it(` (plenary/busted, `TESTS/README.md`),
  CI Ubuntu/Windows/macOS mit `stylua --check` + `luacheck` (`TESTS/README.md`, `.github/workflows/ci.yml`). Ungewoehnlich viele gemessene Design-Notizen im Code.

### 1.2 Wie Bilder/bildartige Ausgabe entstehen
| Zieltyp (`classify.lua:143-157`) | Pfad | Backend |
|---|---|---|
| image (png/jpg/jpeg/gif/webp/bmp/ico/avif/**svg**, `classify.lua:22-32`) | `media.image` -> leerer Float im Seitenverhaeltnis + `draw_into` (`media.lua:526-531`, `272-275`) | **images.nvim** (`images.anchor.draw(win,"full",png,{defer=true})`, `media.lua:307-309`; Fallback `images.browse.draw_in_window`, `:313-323`) |
| pdf | `media.pdf` (`media.lua:760`): `pdfport.render_page(path,page,{dpi,crop},cb)` -> PNG -> wie Bild | pdfport (PNG) + images.nvim (Zeichnen) |
| office (`hover/formats.lua:36-55`) | nur wenn `office.convert=true`: `pdfport.create{from="office"}` -> PDF -> wie PDF (`preview/office.lua:230-296`) | pdfport(soffice) + pdfport.render_page + images.nvim |
| video (`formats.lua:90-115`) | `media.frame` -> PNG -> Bild; Scrub = Paging-Tasten (`preview/video.lua:411-582`) | media.nvim (ffmpeg) + images.nvim |
| video "play" | (a) mpv-Fenster via `media.play_window` (Default `video.playback="window"`), (b) System-Player via `media.play` (`preview/external.lua:100-140`), (c) inline **Unicode-Halbbloecke** `media.frames` + `images.blocks.sample_async/paint` (`video.lua:271-380`, `playback.lua`) | media.nvim + images.blocks (Zellen-Text) |
| url | Status/Titel via curl (`url.lua:760`), PDF-Antwort -> `webpdf` (curl -o + pdfport), optional **Headless-Chrome-Screenshot** (`shot.lua:336-364`) -> PNG | curl / Chrome + images.nvim |
| image + `opts.zoom>0` | `images.convert.crop` (ImageMagick) (`media.lua:465-509`) ; PDF-Zoom = 2. Rasterisierung mit hoeherem DPI + `crop` (`media.lua:760-974`) | images.convert / pdfport |

**Entscheidung Grafikprotokoll vs. Textfallback** (hover selbst kennt KEIN Terminal-Detection; 0 Treffer fuer TERM/WEZTERM/KITTY/OSC in `lua/hover`):
- `lib.nvim.image_preview.detect()` (`/e/repos/lib.nvim/lua/lib/nvim/image_preview/init.lua:40-56`) prueft nur *Plugin-Praesenz*: images.nvim > snacks > image.nvim.
- `provider and opts.inline_images ~= false` -> Canvas, sonst Metadaten (`media.lua:526-544`: "N x M px", "PNG - 10 KB", "(no image provider installed)").
- PDF ohne pdfport: `metadata("(pdfport.nvim not installed - no page preview)")` (`media.lua:770-772`); ohne Provider: `(no image provider installed)` (`:778-781`).
- Video ohne media: Badge `(media.nvim not installed - no frame preview)`; ohne ffmpeg: Badge (`video.lua:411-423`).
- **Wichtig (CODE)**: `draw_into` liefert `nil`, wenn Provider ~= "images.nvim" (`media.lua:300-305`) -> siehe Abschnitt 9, Punkt 1.

Eigene Bildlogik in hover (kein Renderer, aber Geometrie): Header-Parser fuer PNG/GIF/BMP/JPEG-Groesse ohne Decoder (`media.lua:46-160`),
`canvas_cells` (Inset-Kompensation aus `images.config.get().display.draw_inset`, `media.lua:204-263`), Zoom-Mathematik (`media.lua:337-393`, `pdf_dpi/pdf_window` `:651-693`).

### 1.3 Externe CLI-Tools
| Tool | Wo | Wie | Timeout | Detection | Windows |
|---|---|---|---|---|---|
| curl | `preview/url.lua:760-766` (via `lib.nvim.net.curl.fetch_raw`, argv `curl -sS -X GET ...`, `lib/nvim/net/curl/init.lua:171`, `-L --max-filesize 2000000`) | Arg-Liste, kein Shell | `url.timeout_ms` Default 2000 (`DEFAULTS.lua:207`) | `pcall(require,"lib.nvim.net.curl")` | - |
| curl (PDF-Download) | `preview/webpdf.lua:333-352`: `curl -sSL --max-filesize <cap> --max-time <s> -H Accept -o <out> <url>` | `vim.system` Arg-Liste, `text=false` | 30 s Default, Cap 25 MB (`DEFAULTS.lua:233-237`) | `vim.fn.executable("curl")` (`webpdf.lua:321`) | - |
| Chrome/Chromium/Edge/Brave | `preview/shot.lua:336-364`: `--headless=new ... --user-data-dir=<cache>/profile --screenshot=<out> <url>` | `vim.system` Arg-Liste | `shot.timeout_ms` 20000 (`shot.lua:373-376`) | `lib.nvim.deps.detect.found_as(chrome_tool())` inkl. `paths` aus `docs/install.json` (`shot.lua:78-116`) | Ja: Standard-Installpfade, weil `chrome` auf Windows selten im PATH (`DEFAULTS.lua:347`) |
| pdftoppm / soffice / ffmpeg | **nie direkt** - immer ueber pdfport/media (nur `vim.fn.executable` in `health.lua:446-495`) | - | - | - | - |
| mpv | nie direkt; ueber `media.core.player`/`audio` | - | - | - | Kill-Tree-Logik in media (`core/proc.lua`) |
| vlc | `preview/external.lua:97-140` `KNOWN_PLAYERS`, Arg-Liste, Windows Program-Files-Suche (`:34-49`) | `pcall(vim.system, argv, {})` | keiner | `vim.fn.executable` + Install-Pfade | Ja |
| powershell.exe / bash | `preview/monitor.lua:153-158`, `align_win.lua:408-419`: **schreibt Skript nach `stdpath("cache")` und fuehrt es aus** (`-NoProfile -NonInteractive -ExecutionPolicy Bypass -File`) | Arg-Liste; nur Monitor-Erkennung (`:wait(1000)`) bzw. optional `system_player_align` (Default false, `DEFAULTS.lua:558`) | 1000 ms (`monitor.lua:178`) | - | Kernfall Windows |
| git / xdotool / wmctrl | `preview/git.lua`, `align_win.lua` | Arg-Liste / generiertes sh-Skript | - | - | - |
| ImageMagick `magick` | nur indirekt: `images.info.collect`, `images.convert.crop`; `can_zoom()` prueft `lib.nvim.cross.executable.exists("magick")` (`media.lua:437-443`) | - | - | - | - |

### 1.4 Bild-/Medien-/Preview-Features
Bild-Hover im eigenen Seitenverhaeltnis (kein Titel/Caption); PDF-Seite + Paging (`scroll={page}`) + scharfer Zoom (2. pdftoppm-Lauf mit `-x -y -W -H`, DPI 216..2400, `media.lua:632-668`);
Bild-Zoom per Crop; Resize (`hover.resize`); Full-screen "zen"; Office-Erste-Seite (opt-in, LibreOffice); Video-Standbild + Scrub + Prefetch der naechsten Position
(`video.lua:545-560`); Video-Play: mpv-Fenster / System-Player / inline Block-Grafik mit mpv-Ton, Clock-Sync ueber IPC (`playback.lua:1-70`);
Web-PDF-Seite; Web-Screenshot; URL-Metadaten; Git-Hover; Position-Previews (nicht-Datei) ueber Registry; `:Hover`-Statusdashboard (`status_view.lua`, nutzt `ui.kit` weich).

### 1.5 Sicherheit
- Default-**Off** fuer alles Netz/Schwere: `links.web=false`, `links.fetch=false`, `links.pdf.enabled=false`, `links.shot.enabled=false`, `office.convert=false` (`DEFAULTS.lua:196-204,233,278-280,428`).
  Nur `auto_hover.image=true, pdf=true` sind an (`DEFAULTS.lua:86-87`).
- Alle Prozesse als **Arg-Listen** (keine Shell-Strings), `--max-filesize`, `--max-time`, `vim.system{timeout}`; URL nur wenn `^https?://` (`url.lua:736`, `shot.lua`-Analogon) -> kein `-`-Praefix moeglich.
- Chrome: **Wegwerf-Profil** (`--user-data-dir` unter Plugin-Cache), bewusst **kein** `--no-sandbox` (`shot.lua:315-334`).
- Web-PDF: bricht bei `Content-Length` > Cap vor dem Download ab; nach Download `looks_complete()`-Check, unvollstaendige Datei wird geloescht (`webpdf.lua:277-296`).
- Text-Vorschau: zeilenbasiertes Lesen (`text.lua:24-60`) + Byte-Test `preview.binary.is_binary` (`binary.lua:27-60`) -> kein Ganzdatei-Read.
- Header-Parser mit Iterationsgrenze (`media.lua:47`: max 256 JPEG-Segmente).
- Persist-Datei wird durch `sanitize()` gefiltert (`persist.lua:269-334`).
- **Nicht vorhanden / Beobachtung**: kein Escape-Sequenz-Sanitizing fuer URL-Titel/-Text (0 Treffer "sanitiz/control char" ausser `persist` und `binary`); `nvim_buf_set_lines` interpretiert sie nicht,
  daher vermutlich unkritisch (UNVERIFIED). Kein SSRF-/Private-IP-Filter beim URL-Fetch (nur opt-in). `curl` ohne `--proto`/`--proto-redir` (UNVERIFIED ob Default von curl reicht).
  Das `-ExecutionPolicy Bypass`-Skript liegt in `stdpath("cache")` (Nutzer-eigen) - lokal geringes Risiko, aber vom Zweck her "generierte Datei ausfuehren".

### 1.6 Performance
- Async + **Generationszaehler**: veraltete Ergebnisse werden verworfen (`init.lua:394-421`, `_generation` `:59,859,977,...`); Platzhalter erst nach Gnadenfrist `placeholder_grace_ms=250`.
- Debounce `delay_ms=250` ueber `lib.nvim.debounce` (`init.lua:1913-1935`), Trigger `CursorHold` (`DEFAULTS.lua:141`), Autocmds nur auf Buffern, die es brauchen (`bindings/autocmds.lua:95-135`).
- LRU der gebauten Previews (64) `hover/cache.lua:29-42` (Key inkl. mtime); Schalter drop the cache.
- Caches: PDF-Seiten/Zoom-Sichten in-Session, geloescht bei `VimLeavePre` (`media.lua:553-579`); Office-PDF + Web-PDF + Shot **ueber Sessions** in `stdpath("cache")/hover.nvim/...` mit `cache_days=7` Sweep einmal pro Session (`office.lua:101-115`, `DEFAULTS.lua:440`).
- In-flight-Guards `_running[key]` (office, webpdf, shot); Shot: genau 1 Browser + `delay_ms`, neuer Request killt laufenden (`shot.lua:24-34`).
- Prefetch nur vorwaerts (`video.lua:545-560`); Video-`play` erst auf Tastendruck.
- Lazy `require` pro Preview (`init.lua:431+`); `plugin/hover.lua` registriert nur `:Hover` (18 Zeilen).
- **Gemessene** Zahlen im Code (nicht von mir verifiziert): PDF-Seite 1150 ms, Crop 258 ms, Chrome-Start ~710 ms (`media.lua:447-459`, `shot.lua:19-27`).

### 1.7 Abhaengigkeiten
| Ziel | Art | Belege |
|---|---|---|
| lib.nvim | **HART** (bare `require` beim Laden: `float.lua:16,21`, `notify.lua:22`, `classify.lua:16`, `bare_path.lua:38`, `autocmds.lua:28`) | README `:38` "one hard dependency" stimmt |
| images.nvim | weich (`pcall`), Namen: `images.info/.config/.scale/.anchor/.browse/.convert/.blocks/.terminal` (`media.lua:176,225,234,307,313,438,480`; `video.lua:224,272`; `playback.lua:312`); `images.terminal.clear()` im Teardown-Closure (`media.lua:326-330`, in pcall) | alle 17 verwendeten Funktionen existieren in `images.nvim/lua/images` (geprueft per grep) |
| pdfport | weich: `render_page`, `can_render_page_crop`, `create`, `can_create` (`media.lua:704-709,769`; `office.lua:230-236`) | vorhanden (`pdfport/init.lua:199,226,~270`) |
| media | weich: `media.frame/.frames/.prefetch_frame/.probed/.available/.play/.play_window/.player_available/.is_media`, `media.ui.*`, **`media.core.play.player()`** (`init.lua:1286`), `media.core.audio` (`playback.lua:715`) | greift in media-Interna (`media.core.*`), nicht nur oeffentliche API |
| gopath | weich: `gopath.resolve.resolve_at_cursor` (`bare_path.lua:222`) | |
| open.nvim | weich: `open.open`, `open.registry.list_keys` (`init.lua:1302-1329`) | |
| ui.nvim (`ui.kit`) | weich (`status_view.lua:582,750,835`) | |
| markdown.nvim / reposcope / migrate / documentation / spotlight / insights / sandbox / language | **inbound** ueber `hover.registry` (docs `integrations.md`); per grep in E:\repos bestaetigt: markdown, documentation, insights, language, reposcope, sandbox, spotlight registrieren tatsaechlich (`grep hover.registry`); migrate.nvim nicht gepruefte (Repo nicht in Liste, UNVERIFIED) | |
| snacks.nvim / image.nvim | nur indirekt ueber `lib.nvim.image_preview.detect` (`media.lua:299,527,778`) | siehe Abschnitt 9 |

**Dupliziert (hover)**: Endungs-Tabellen (`classify.lua:22-32` IMAGE_EXT, `formats.lua:31-140` Video/Office), Chrome-Tool-Aufloesung (`shot.lua:78-116` ~ `pdfport/producers/chromium.lua:42-56`),
PDF-Seiten-PNG-Cache in-Session (`media.lua:553`) neben `images.pdf` (Disk) und pdfport (kein Cache), Office->PDF-Cache (`office.lua:59`) neben pdfport-tmp, eigenes Header-Groessen-Parsing (`media.lua:46-160`) neben `images.info`,
eigener curl-Aufruf fuer PDFs (`webpdf.lua:333`) neben `lib.nvim.net.curl` und `images.remote`, `chrome` Erkennung statt `lib.nvim.deps` einheitlich, eigene Video-/Office-Formatlisten neben `media.formats`.
Cache-Verzeichnisse: `stdpath("cache")/hover.nvim/{office,zoom,...,profile}` + lose Skripte `stdpath("cache")/hover_detect_monitor.*`, `hover_align_video_window.*` (`monitor.lua:165`, `align_win.lua:430`).

### 1.8 Erweiterungspunkte
- **`hover.registry.register(name, {sources, previews, positions})`** (`registry.lua:96`); `sources`/`positions` duerfen `{fn=..., on_request=true}` sein (`registry.lua:70-90`); Previews sind pro Target-Typ ersetzend (`init.lua:439-449`),
  Typen: `anchor,directory,file,git,image,markdown,missing,office,pdf,url,video` (`classify.lua:179-191`). `setup({contribute=...})` registriert unter Name `"user"`.
  -> Ein Suite-Plugin koennte `previews.image/pdf/video/office` ueberschreiben (**Achtung**: gleicher Typ = Ersatz, kein Konflikt-Handling).
- **Keine `User`-Autocmds** (0 Treffer `nvim_exec_autocmds` in hover/pdfport/media).
- Config-Haken: `links.shot.command`, `video.play_*`, `video.system_player_*`, `contribute`.
- Registry-Erweiterung fuer neue Ziel-Typen (z.B. "audio", "svg") existiert nicht: `Hover.Target.type` ist geschlossene Union (`classify.lua:179` + Test `switches_spec`).

### 1.9 Verhalten OHNE images.nvim
- Bild: Metadaten-Float (`media.lua:533-543`) mit Hinweis "(no image provider installed)"; **falls snacks/image.nvim installiert: leerer Float** (Abschnitt 9.1).
- PDF: `PDF - <size>` + Hinweis (`media.lua:761-781`).
- Video: Standbild-Pfad scheitert am Provider -> Badge mit Summary; Inline-Playback braucht `images.blocks` (`video.lua:271-281`) -> faellt auf mpv-Fenster/System-Player/Standbild.
- Zoom deaktiviert (`can_zoom()` false, `media.lua:437-443`).
- Alles ohne Fehler: Alle `images.*`-Zugriffe hinter `pcall(require,...)` (`media.lua:176,225,234,307,313,438,480`, `video.lua:224,272`); TESTS-README sagt: Zoom-Specs "pending" ohne images.nvim (`TESTS/README.md`).

---------------------------------------------------------------------------------------------------

## 2. pdfport.nvim

### 2.1 Zweck / Groesse / Reife
- **Zweck**: PDFs in beide Richtungen: lesen (Text/Markdown-Extraktion ueber austauschbare Backends, Anzeige in Buffer/Float/Terminal/System) und schreiben (aus Bild/Markdown/Text/HTML/Office; Merge). (`README.md:24-29`)
- **Groesse**: 52 Lua-Dateien, ~7.1k Zeilen; 8 Extraktions-Backends (`backends/`: pdftotext, pdfplumber, marker, docling, tesseract, ollama, claude, gemini), 9 Producer (`producers/`), 4 Renderer, 6 File-Tree-/Picker-Integrationen.
- **Reife**: 129 Commits (2026-06-23 .. 2026-09-20), Beta-Banner, 21 Spec-Dateien, ~1140 Assertions (grep `H.eq/ok/match`, Naeherung), framework-freie Headless-Harness (`TESTS/README.md`): **kein Tool wird je ausgefuehrt**, es wird das argv geprueft. CI vorhanden.

### 2.2 Wie Bilder entstehen
- **`pdfport.render_page(path,page,opts,cb)`** (`init.lua:199`) -> `core/rasterize.lua:80`: `uv.spawn("pdftoppm", {-png -r DPI -f P -l P -singlefile [-x -y -W -H] path base})` (`rasterize.lua:37-78,106-110`). Liefert **caller-eigenes PNG** (Default `vim.fn.tempname()`, oder `opts.output_path`). `can_render_page_crop()` ist konstantes `true` (`init.lua:226`).
- **Terminal-Renderer** (`renderers/terminal.lua`): pro Seite pdftoppm -> `vim.cmd("split | terminal chafa --size=WxH <shellescape(png)>")` bzw. `kitten icat`/`kitty icat`/`imgcat` (`terminal.lua:90-100`); PNG wird nach 2 s geloescht (`:91-93`). Werkzeugwahl `platform.best_terminal_renderer()` (`platform/init.lua:110-119`): `TERM=xterm-kitty`/`TERM_PROGRAM=kitty` + kitten/kitty -> kitty; sonst imgcat, sonst chafa, sonst nil -> Fehlermeldung "install chafa".
  **Das ist eine eigene, images.nvim-unabhaengige Bildanzeige** und eigene (rudimentaere) Terminal-Erkennung. Das Kommentar `platform/init.lua:100-108` verweist explizit auf `lib.nvim.image_preview` als "in-Neovim overlay rendering".
- Text-Renderer: `buffer`, `float` (via `lib.nvim.window.make_scratch`, `renderers/float.lua`), `system` (via `lib.nvim.cross.open_default`, `renderers/system.lua`).
- **Kein** eigener Umgang mit SVG/Video/Audio. Office: nur als **Eingabe fuer PDF-Erzeugung** (`producers/soffice.lua`). Bilder: nur als Eingabe (`img2pdf`/`magick` -> PDF, `producers/magick.lua:38-44`).
- Extraktion (kein Bild): pdftotext/pdfplumber/marker/docling/tesseract/ollama(Vision)/claude/gemini (`config/DEFAULTS.lua:11-31`).

### 2.3 Externe CLI-Tools
| Tool | Wo | Wie | Timeout | Detection | Windows |
|---|---|---|---|---|---|
| pdftoppm | `rasterize.lua:106`, `backends/tesseract.lua:94-106`, `backends/ollama.lua:64-108` | `uv.spawn` args (rasterize); `spawn_capture` argv (tesseract); `vim.system` argv (ollama) | **rasterize: keiner** (kein Timer/Kill, `:80-133`); tesseract: `timeout_ms`; ollama-Raster: **keiner** (`ollama.lua:106`) | `platform.has` = `lib.nvim.core.has_exec` = `vim.fn.executable` (PATH-only, memoisiert, `platform/init.lua:41`, `lib/nvim/core/init.lua:13-20`) | PATH-only; `.exe` ok, kein Shim-/Pfad-Fallback |
| pdftotext, marker_single, python (docling/pdfplumber), tesseract | `backends/*.lua` | `spawn_capture` argv (kein Shell), `timeout_ms` Default 30000 (`extract_opts`) | ja | `platform.has` | env-Vervollstaendigung `util/spawn_env.lua` |
| curl, ollama, ai.nvim | `backends/ollama.lua`, `claude/gemini` ueber `ai.ask` / `ai.attachments.from_file` (`claude.lua:110`) | HTTP durch ai.nvim | `timeout_ms` | `ai() ~= nil` (`pcall(require,"ai")`) | - |
| soffice | `producers/soffice.lua:47-66` `--headless --convert-to pdf --outdir <cache>/soffice-<hrtime> input` | argv, Scratch-Dir + `fs_rename` auf Zielpfad, `cleanup` | 60000 ms (`create_opts.timeout_ms`) | **`platform.has("soffice")` PATH-only** (`soffice.lua:36-38`) | **Inkonsistenz zu `health.lua:345`** (Abschnitt 9.2) |
| chromium | `producers/chromium.lua` (`--headless --print-to-pdf`), Aufloesung via `lib.nvim.deps.detect.found_as` inkl. `paths` (`chromium.lua:42-56`) | argv | 60000 | deps-Spec | Windows-freundlich |
| magick, img2pdf, pandoc, weasyprint, qpdf, pdftk, gs/gswin64c/gswin32c | `producers/*.lua` | `spawn_capture` argv; magick `magick <inputs...> <output>` (`magick.lua:38-44`) | 60000 | `platform.has` / `first_available` | gs-Varianten fuer Windows |
| chafa / kitten / kitty / imgcat | `renderers/terminal.lua` | **Shell-String** ueber `:terminal` + `vim.fn.shellescape` (`terminal.lua:90-98`) | - | `platform.has` | shellescape haengt von `'shell'` ab (UNVERIFIED unter Windows) |
| python `-c "import X"` | `platform/init.lua:74` | `vim.fn.system` (SYNCHRON, blockiert) fuer `has_python_module` | - | | |

### 2.4 Bild-/Medien-/Preview-Features
`render_page` (+ `crop`, `output_path`); Terminal-Seitenvorschau (mehrere Seiten, 500 ms Pause zwischen Seiten `terminal.lua:135`); Seitenbereich-Parser (`util/page_range.lua`);
Extraktion mit Auto-Fallback-Kette (`fallback_chain`); Text-Cache (`util/cache.lua`); Create/Merge-API; File-Tree-Integrationen (neo-tree, nvim-tree, oil, netrw, telescope, fzf; `integrations/*`);
`pick_open(path)` als gemeinsamer Oeffnen-Dialog fuer andere Plugins (`init.lua:137`).

### 2.5 Sicherheit
- Alle Aufrufe als **Arg-Listen** (Ausnahme: Terminal-Renderer `:terminal <shell string>`).
- **Pfad-Kanonisierung** (`util/path.lua:28-...`, `dispatcher.lua:155`): absolut, symlink-aufgeloest -> auch verhindert `-`-Praefix bei Extraktion. **`render_page` kanonisiert NICHT** (`rasterize.lua:80-`), Pfad geht als Positionsargument an pdftoppm; ein Pfad mit `-`-Anfang koennte als Option gelesen werden (UNVERIFIED ob pdftoppm das so tut; Aufrufer hover/images liefern absolute Pfade).
- `validate_path`: existiert + regulaere Datei (`dispatcher.lua:69-78`).
- API-Keys: `pdfport.config()` liefert Kopie mit `"<redacted>"` (`init.lua:163-172`).
- Cache-Datei wird beim Laden **typvalidiert**, korrupte Datei nach `.corrupt` gesichert (`util/cache.lua` Header).
- Timeouts: Standard `30000` (Extraktion), `60000` (Create); `rasterize.render_page` **ohne**.
- `on_conflict` Standard `"overwrite"` beim Erzeugen (`DEFAULTS`, `composer.lua:253,284`) - hover nutzt bewusst overwrite im eigenen Cache.
- Schreibt Zwischenpuffer in `stdpath("cache")/pdfport.nvim/tmp` und raeumt auf (`util/tmpfile.lua`).
- Terminal-Renderer: `sanitize_size_ratio` gegen ungueltige Ratio (`terminal.lua:29-48`).
- Keine Sandbox um soffice/marker/docling/python. ImageMagick `magick <inputs> <out>` ohne Policy/Coder-Pruefung (Pfade mit `msl:`/`@file`-Praefixen nur bei benutzerkontrollierten Eingaben relevant, UNVERIFIED).

### 2.6 Performance
- Alles async ueber `uv.spawn`/`spawn_capture`; Progress-Indikator (`lib.nvim.progress`, `dispatcher.lua:23-42`) - **kein Cancel** ("spawn_capture liefert keinen killbaren Handle", `dispatcher.lua:27-33`).
- Lazy Backends/Producers (Proxy-Registrierung `backends.load_all`, `producers.load_all`, `init.lua:38-47`); `plugin/pdfport.lua` (7 Zeilen) registriert nichts.
- Text-Cache: `lib.nvim.cache.disk` Namespace `pdfport_extract`, mtime-Invalidierung, `MAX_ENTRIES=500` (`util/cache.lua:48`), Key = Pfad::Backend::Variante (Prompt-Hash) (`dispatcher.lua:96-118`).
- **Kein** Cache/TTL fuer `render_page`-PNGs (Konsumenten besitzen ihre Dateien, `init.lua:181-195`).
- `platform.has` memoisiert; `deps_popup` einmalig.
- Tesseract/ollama arbeiten seitenweise **sequenziell** (`tesseract.lua:91-140`); Terminal-Renderer mit `defer_fn(500ms)` zwischen Seiten.
- Kein Debounce/Visible-only-Konzept (kein CursorHold-Trigger).

### 2.7 Abhaengigkeiten
| Ziel | Art | Belege |
|---|---|---|
| lib.nvim | **HART, weit ueber den Docs-Satz "built on its user-command composer"** (`docs/requirements.md`): Top-Level-`require` in `platform/init.lua:12-15` (`cross.platform.*`), `lib.nvim.core` (has_exec), `cache.disk`, `notify`, `window.make_scratch`, `cross.uv.spawn_capture`, `cross.run.env`, `cross.open_default`, `cross.uv.wait_until`, `lua.strings.distance` (`grep`-Liste oben) | nur `progress`, `deps`, `deps.health` per pcall |
| images.nvim | **KEINE** (0 Code-Treffer; nur Kommentare `init.lua:183,220`, `magick.lua:4`) | |
| hover / media | **KEINE** | |
| ai.nvim | weich: `pcall(require,"ai")`, `ai.attachments.from_file` (`backends/claude.lua:58-61,110`); ohne ai.nvim melden sich claude/gemini/ollama als unavailable (`ollama.lua:56-70`) | |
| ui.nvim | weich (`ui.kit`, `util/page_range.lua:56`, `util/picker.lua:138`, `health.lua:445`) | |
| neo-tree / nvim-tree / oil / telescope / fzf-lua / which-key | weich | `integrations/*` |

**Dupliziert (pdfport)**: drei separate pdftoppm-argv-Konstruktionen (`rasterize.lua:37-78`, `tesseract.lua:94-106`, `ollama.lua:64-76`) statt `rasterize.args`; Tool-Erkennung PATH-only (`platform.has`) waehrend `health` und `chromium` `lib.nvim.deps.detect` mit `paths` nutzen;
eigene Terminal-Tool-Erkennung (`best_terminal_renderer`); eigenes tesseract-OCR (PDF) neben `images.ocr` (Bild) und `media.hub.text`; eigene Kanonisierung (`util/path.lua`) neben `lib`/anderen.
Cache-Verzeichnis: `stdpath("cache")/pdfport.nvim/tmp` + disk-cache-Namespace.

### 2.8 Erweiterungspunkte
- `pdfport.register_backend`, `pdfport.register_producer`, `core.registry.register_renderer(mode, fn)` (`init.lua:~330,~296`; `registry.lua:122`); `fallback_chain`, `create_chain` in Config (`DEFAULTS.lua:11-53`).
- Oeffentliche API fuer Konsumenten: `render_page`, `can_render_page_crop`, `extract{__callback}`, `create/can_create/merge`, `pick_open`, `config()`.
- `integrations.*` fuer Datei-Baeume; keine `User`-Autocmds, keine Registry fuer Bild-Ziele.

### 2.9 Verhalten OHNE images.nvim
- **Unveraendert.** pdfport kennt images.nvim nicht. Der eigene Terminal-Renderer braucht chafa/kitten/imgcat + ein passendes Terminal; ohne alle: Fehlermeldung "no image renderer (install chafa)" (`terminal.lua:66-70`).
- Buffer/Float/System-Renderer und alle Extraktion/Creation laufen normal.

---------------------------------------------------------------------------------------------------

## 3. media.nvim

### 3.1 Zweck / Groesse / Reife
- **Zweck**: "Was steckt in dieser Mediendatei, ein Bild davon, und die Sprache als Text": ffprobe-Metadaten, ffmpeg-Standbild/Kontaktbogen/Waveform/Spektrogramm/Frame-Runs, mpv-Wiedergabe/-Audio, whisper.cpp-Transkription, Hub-Dashboard ueber Bild/PDF/Audio/Video. (`README.md:23-34`)
- **Groesse**: 39 Lua-Dateien, ~8.3k Zeilen. **Reife**: 48 Commits (2026-09-08 .. 2026-09-20 = 12 Tage), Beta, 35 Spec-Dateien / ~675 Assertions (Naeherung), framework-freie Harness, CI vorhanden; Tests fuehren nie ffmpeg aus (`TESTS/harness.lua:1-6`).

### 3.2 Wie Bilder entstehen / gezeigt werden
- **Erzeugt nur PNGs** (nie Anzeige durch eigenes Protokoll): `frame` (`core/frame.lua:37-...`), `frames` (Run in **einem** ffmpeg-Lauf, cancelbar, `core/frames.lua:17-20`), `sheet`, `waveform`, `spectrogram` (ffmpeg-Filter), alles im Cache `stdpath("cache")/media.nvim/<sha256>.png` (`core/cache.lua:77-83`, `M.dir()`).
- **Anzeige**: `ui.show_image(png)`: `images.show(png)` -> sonst `lib.nvim.cross.open_default(png)` -> sonst Pfad per `vim.notify` (`ui.lua:167-182`). => **images.nvim-Nutzung ist die einzige Bild-Bruecke; kein eigenes Terminal-/Zellen-Rendering.**
- Entscheidung Protokoll vs. Text: **keine**. media entscheidet nichts ueber Grafikprotokolle. (Doc: "does not play video ... a consumer that draws text: hover.nvim" `init.lua:14-25`.)
- PDF: nur Textextraktion ueber `pdfport.extract` (`hub/text.lua:213`), Bild: OCR ueber `images.ocr.run` (`hub/text.lua:181`), Audio/Video: whisper. **SVG/Office: nicht behandelt.**
- Kinds: `media.hub.kinds.of(path)` (`hub/kinds.lua:120-140`): video/audio aus eigenen Tabellen, pdf per Endung, image ueber `images.integrations.picker.is_image` mit Fallback-Tabelle (`kinds.lua:98-110`).

### 3.3 Externe CLI-Tools
| Tool | Wo | Wie | Timeout | Detection | Windows |
|---|---|---|---|---|---|
| ffprobe | `core/probe.lua:243-262` `-v error -hide_banner -print_format json -show_format -show_streams <path>` | `vim.system` argv, `pcall`-gekapselt | `timeout_ms` 15000 (`DEFAULTS.lua:41`) | `core/bin.lua:84-115` | |
| ffmpeg | frame/frames/sheet/waveform/normalize: immer `-nostdin -hide_banner -loglevel error` (`frame.lua:42`, `frames.lua:53`, `sheet.lua:70`, `waveform.lua:52`, `normalize.lua:25`), `-y`, `-i <path>` | `vim.system` argv, Ausgabe in `*.tmp-<pid>.png` + `fs_rename` (`cache.lua`) | frame 15 s, sheet/waveform/normalize 120 s (`DEFAULTS.lua:118-144,202`) | `bin.find` | |
| mpv | `core/audio.lua:60-77` (`--no-video --no-terminal --idle=no --keep-open=no --input-ipc-server=<sock> [--start] [--pause=yes] <path>`), `core/player.lua:115-145` (`--force-window=immediate ... -- <path>`) | `vim.system(argv,{})` unawaited, **JSON-IPC** ueber Unix-Socket im Cache-Dir bzw. `\\.\pipe\media.nvim-<pid>-<rnd>` (`audio.lua:91-94`) | keiner (Lebensdauer ueber `stop`/`VimLeavePre`) | `bin.find("mpv")` | **Windows: `mpv.com`-Wrapper-Problem geloest** durch `taskkill /PID /T /F` (`core/proc.lua:40-76`) - gemessen dokumentiert |
| whisper-cli | `engines/whisper_cpp.lua:200-222` argv, JSON-Ausgabe in `tempname()` | `vim.system` | **`transcribe.timeout_ms = 0` = keiner** (Default, `DEFAULTS.lua:196`) | `bin.find("whisper-cli")` | |
| tesseract | nie direkt; `images.ocr.run` | | | Hinweis `hub/text.lua:88-98` | |
| konfigurierter Player | `core/play.lua:36-77`: `player` string/argv | `vim.system(argv,{})` unawaited; sonst `open_default`, sonst `vim.ui.open` | keiner | `lib.nvim.cross.executable.exists` | |
| taskkill | `proc.lua:75` | `:wait(2000)` | 2 s | | |

**Tool-Detection `core/bin.lua`**: Reihenfolge: `config.bin[name]` (immer gewinnt, auch wenn nicht existent) -> `lib.nvim.cross.executable.exists` (Fallback `vim.fn.executable`) -> "well_known" Verzeichnisse (winget-Links, scoop shims, chocolatey, `C:/ffmpeg/bin`, `/opt/homebrew/bin`, `/usr/local/bin`) (`bin.lua:43-56,84-115`);
Cache pro Sitzung, Schluessel enthaelt Config-Wert (`bin.lua:...`), Reset auf `VimResume` (`bindings/autocmds.lua`). Der Kommentar nennt explizit `images.ocr` als Vorbild "same exception" (`bin.lua:13-15`) -> bewusstes Duplikat.

### 3.4 Features
`:Media` (probe/frame/sheet/waveform/spectrogram/dashboard/text/transcribe/engines/play/window/cache clear/health) (`docs/commands.md`), Keymaps `<leader>Mp/f/s/o` (`docs/what-you-get.md`),
Hub-Dashboard: ein Blick ueber Bild/PDF/Audio/Video mit Zustand `fine / missing / stale` der Sidecar-Texte, Scan mit Iterations-Cap, Detail lazy per `media.probed` + begrenzte Probe-Nebenlaeufigkeit (`hub/scan.lua`, `hub/dashboard.lua`),
Kontextmenue-Integration (`integrations/menu.lua`), Ausgabe als Buffer / `.transcript.md` Sidecar / SRT / VTT (`output/*`), Frame-Prefetch API (`init.lua:127`), Frames-Run-API mit Cancel-Handle (`init.lua:140`), Audio-Handle mit `pause/resume/seek/time_pos/stop` (`audio.lua:...`).

### 3.5 Sicherheit
- **Alle Prozesse Arg-Listen** (kein Shell). ffmpeg/ffprobe `-nostdin`, `-y` nur auf tmp+rename.
- `mpv`: `player.lua` nutzt `--` vor dem Pfad (`player.lua:143`), **`audio.lua` nicht** (`audio.lua:60-77`, Pfad letztes Argument) - minimale Inkonsistenz; Aufrufer liefern absolute Pfade.
- Kein `-protocol_whitelist` bei ffmpeg/ffprobe (`grep` 0 Treffer) -> Playlist/`concat`-Demuxer aus Dateiinhalt koennte lokale/entfernte Ziele anfassen (Bedeutung UNVERIFIED; hover uebergibt nur existierende lokale Dateien nach Endung, ffmpeg erkennt aber nach Inhalt).
- `expand` nur `~`/Env, **nie** `vim.fn.expand` mit Backtick/`%` (SEC-34, `hub/scan.lua` Kommentar).
- mpv-IPC-Socket im Cache-Dir (POSIX, `audio.lua:91-94`) - keine explizite Berechtigungssetzung (UNVERIFIED).
- Timeouts/Konkurrenz: `render_concurrency=4` (`DEFAULTS.lua:240`) - eigene Warteschlange mit Prioritaeten high/normal/low; "30 Prozesse beim Halten der Paging-Taste gemessen" (Kommentar `DEFAULTS.lua:234-236`).
- Whisper-Default ohne Timeout (bewusst, `DEFAULTS.lua:192-196`).
- **Kein Cache-Limit / keine TTL**: nur `:Media cache clear` (`cache.lua:245`); `grep` findet kein max/TTL in `core/cache.lua` -> unbegrenztes Wachstum von PNG-/WAV-/Transkript-Cache (im Gegensatz zu hover `cache_days`, pdfport `MAX_ENTRIES`).
- Keine Escape-Sequenz-Sanitierung noetig (zeichnet nichts selbst).

### 3.6 Performance
- Alles async (`vim.system` Callback), Callbacks immer auf Main-Loop ("exactly once", `init.lua:47-51` + `vim.schedule`).
- **Persistenter Content-Cache** (sha256 aus kind/path/mtime/Parametern, `cache.lua:77-83`), In-Flight-Dedup + Warteschlange mit Prioritaet + Cancel von nicht mehr benoetigten Eintraegen (`cache.lua:120-330`), atomarer Write via tmp+rename.
- Probe-Cache im Speicher mit mtime (`probe.lua:270-272`), `M.probed()` blockiert nie (`init.lua:100`).
- Prefetch mit Prioritaet "low" (`frame.lua:M.prefetch`).
- `frames`: ein ffmpeg-Lauf statt N (`frames.lua:9-15`, Messung 186 ms vs 1593 ms im Kommentar), cancelbar.
- `bin.find` memoisiert inkl. negativer Antworten; `plugin/media.lua` (8 Zeilen) registriert nichts; jeder Call `require("media.core.x")` lazy.
- Hub: Scan ohne Prozesse, Detail-Probes begrenzt (PROBE_LIMIT/Nebenlaeufigkeit), Namen-Spalte auf 56 Zellen gedeckelt (`hub/dashboard.lua` Kommentar).

### 3.7 Abhaengigkeiten
| Ziel | Art | Belege |
|---|---|---|
| lib.nvim | **WEICH, komplett** - jede Benutzung `pcall(require,"lib.nvim...")` (`bin.lua:98`, `cache.lua:56`, `play.lua:50,76`, `ui.lua:22,125,174`, `usrcmds.lua:30,147,467`, `health.lua:107` in pcall); Docs stimmen (`README.md:52-60`) | einziges Plugin der drei ohne harte lib-Abhaengigkeit |
| images.nvim | weich: `images.show` (`ui.lua:168`), `images.ocr.run/.bin` (`hub/text.lua:82-98,181`), `images.integrations.picker.is_image` (`hub/kinds.lua:98`) | alle drei existieren (`images.show` `init.lua:98`, `ocr.run` `:146`, `ocr.bin` `:74`, `picker.is_image` `integrations/picker.lua:102`) |
| pdfport | weich: `pdfport.extract{path,__callback}` (`hub/text.lua:112,213`) | |
| hover | **KEINE** (hover greift in media) | |

**Dupliziert (media)**: Tool-Erkennung (`core/bin.lua`, "same exception images.ocr makes"), Endungs-Tabellen (`formats.lua:22-...` **inkl. `ts`,`mts`** vs. hover `formats.lua:107-110` schliesst sie bewusst aus; `hub/kinds.lua` IMAGE-Tabelle vs. hover `classify.lua` vs. `images.integrations.picker.is_image`),
Scope-Woerter `cfile/cwd/path=` (`hub/scan.lua` Kommentar: "same three words as images.browse.roots() and language.scope", bewusst neu implementiert), Verzeichnis-Walk (`images.browse.walk`-Form neu gebaut), eigener Kill-Tree-/Prozess-Stop (nur hier).

### 3.8 Erweiterungspunkte
- **Transkriptions-Engines**: `media.core.registry.register(engine)` (`core/registry.lua:20-28`, Pflichtfelder `id/available/transcribe`), `media.engines.load_all` mit BUILTIN-Liste; nicht in `media.init` re-exportiert.
- Konfig: `bin.*`, `player`, `frame.*`, `frames.*`, `transcribe.engine/whisper_cpp.*/output`, `cache.dir`, `render_concurrency`.
- Public API `media.*` (`init.lua:58-259`, ca. 20 Funktionen) ist das Vertragsobjekt fuer Konsumenten (`pcall(require,"media")`).
- Hub-Aktionen (`hub/actions.lua`) + `lib.nvim.contextmenu` (`integrations/menu.lua`) - Erweiterbarkeit durch Dritte nicht geprueft (UNVERIFIED).
- Keine `User`-Autocmds; einziger Autocmd `VimResume` (`bindings/autocmds.lua`).

### 3.9 Verhalten OHNE images.nvim
- `:Media frame/sheet/waveform/spectrogram`: PNG entsteht trotzdem; Anzeige -> `open_default(png)` (System-Viewer) -> sonst Pfad per notify (`ui.lua:167-182`).
- `:Media text` fuer Bilder: Meldung "images.nvim is not installed - it is the plugin that owns OCR in this ecosystem" (`hub/text.lua:85-93`); Hub-Klassifikation faellt auf eigene IMAGE-Tabelle (`kinds.lua:98-110`).
- Alles andere (probe, transcribe, mpv-Wiedergabe, Hub fuer Audio/Video) unberuehrt.

---------------------------------------------------------------------------------------------------

## 4. Abhaengigkeitsmatrix (wer ruft wen; H=hart, W=weich per pcall)

| von \ nach | lib.nvim | images.nvim | pdfport | media | hover |
|---|---|---|---|---|---|
| hover | **H** (`float.lua:16`) | W (`media.lua:176-480`, `video.lua:224`, `playback.lua:312`) | W (`media.lua:704,769`, `office.lua:230`) | W (`video.lua:166`, `external.lua:195`, `init.lua:1283-1286`, `window.lua:48`) | - |
| pdfport | **H** (`platform/init.lua:12`) | **-** | - | - | - |
| media | **W** (alles pcall) | W (`ui.lua:168`, `hub/text.lua:82`, `hub/kinds.lua:98`) | W (`hub/text.lua:112`) | - | - |
| images (Referenz) | ? | - | W `images/pdf.lua:176`, `convert.lua:118-120` | - | - |
| lib.nvim | - | W (`image_preview/init.lua:40-56,125`) | - | - | - |

- **Zyklen**: keine harten. Weiche: hover<->media (hover ruft media; media nennt hover nur in Kommentaren), images<->pdfport (beidseitig weich: `images.pdf`->`pdfport.render_page`, `images.convert.to_pdf`->`pdfport.create`).
- **lib.nvim kennt images.nvim namentlich** (`image_preview`): wichtiger Suite-Befund - die "Provider-Erkennung" lebt in der Bibliothek, nicht in einem der Plugins.
- Vertragsflaeche hover->images (17 Funktionen, alle vorhanden): `terminal.clear`, `anchor.draw`, `browse.draw_in_window`, `info.collect`, `config.get`, `scale.fit_cells`, `convert.crop`, `blocks.{available,fit_cells,geometry,sample_async,prepare,canvas_lines,paint}`; plus lib->images: `images.show`, `guard.check`, `browse.draw_in_window`, `terminal.clear`; media->images: `show`, `ocr.run`, `ocr.bin`, `integrations.picker.is_image`.
  => **hover haengt an images-INTERNA** (`images.blocks.*`, `images.anchor`), nicht nur an `images.show`; eine Suite muss diese Modul-API stabil halten.

---------------------------------------------------------------------------------------------------

## 5. Duplikations-Inventar (fuer "Bundle/Suite-Plugin?")

| Thema | Wo implementiert | Bemerkung |
|---|---|---|
| **Extension -> Typ** (Bild/Video/Audio/Office/PDF) | hover `classify.lua:22-32` + `formats.lua:31-140`; media `formats.lua:22-...`; media `hub/kinds.lua` IMAGE; images `integrations/picker.is_image`/`resolve.is_image` | 4-5 Tabellen; **divergieren** (`.ts/.mts` hover aus, media an; Audio nur media; SVG hover=image, media=?) |
| **Tool-Erkennung** | pdfport `platform.has` (PATH, `lib.nvim.core.has_exec`); media `core/bin.lua` (PATH + well-known + config); hover `shot.lua` + pdfport `chromium.lua` (`lib.nvim.deps.detect` + `docs/install.json paths`); `images.ocr` (well-known dirs); hover `health` `vim.fn.executable`; `lib.nvim.cross.executable` | mind. 5 Varianten; Windows-Verhalten unterschiedlich |
| **pdftoppm-Aufruf** | pdfport `rasterize.lua`, `tesseract.lua`, `ollama.lua` (3 argv-Bauten); zusaetzlich images ueber pdfport | nur `rasterize` unterstuetzt crop |
| **PDF-Seite->PNG Cache** | hover in-Session Tabelle `_pages` (`media.lua:553`) + `_crops`; `images.pdf` Disk sha256(path+mtime+page+dpi); pdfport keiner | 2 Caches fuer dieselbe Rasterisierung, nicht geteilt |
| **Office->PDF** | pdfport `producers/soffice.lua`; hover `office.lua` Cache `stdpath("cache")/hover.nvim/office` | Cache nur in hover |
| **Web-PDF / Download** | hover `webpdf.lua` (curl), `url.lua` (lib.nvim.net.curl), `images.remote` (curl/wget) | 3 Download-Pfade, unterschiedliche Caps |
| **Terminal-/Provider-Erkennung** | pdfport `best_terminal_renderer` (TERM/TERM_PROGRAM + chafa/imgcat); lib `image_preview.detect` (Plugin-Praesenz); `images.terminal` (Referenz) | hover/media haben keine eigene |
| **Bildanzeige in Float** | hover `draw_into` (`images.anchor`); lib `image_preview.preview` (`images.browse.draw_in_window`); `images.hover_float` (`images.nvim/lua/images/hover_float.lua`, `display.hover_mode="float"`); pdfport `renderers/terminal.lua` | 3-4 Wege, hover umgeht `lib.image_preview.preview` bewusst (Defer-Tick, `media.lua:277-296`) |
| **OCR** | pdfport `backends/tesseract.lua` (PDF, PATH-only); `images.ocr` (Bild, well-known dirs); media `hub/text.lua` (Dispatcher darueber) | media ist hier bereits ein "Suite-Kleber" |
| **Chrome-Aufloesung** | hover `shot.lua:78-116`, pdfport `chromium.lua:42-56` | identische Logik |
| **Scope-Woerter (cfile/cwd/path=), Verzeichnis-Walk** | images `browse`, media `hub/scan.lua`, language | bewusst dupliziert (Kommentar) |
| **Cache-Wurzeln** | `stdpath("cache")/hover.nvim/*`, `.../media.nvim`, `.../pdfport.nvim/tmp` + `lib.nvim.cache.disk`, images (Referenz) | jeweils eigene Eviction-Policy: hover `cache_days=7`, pdfport `MAX_ENTRIES=500` (Text) , media **keine** |
| **Prozess-Stop (Windows)** | nur media `core/proc.lua` (taskkill /T /F); hover `external.lua` (VLC) ohne Stop; pdfport/hover ohne | |
| **Kanonische Pfade** | pdfport `util/path.lua`; andere nicht | |
| **Formatierung/Notify** | alle ueber `lib.nvim.*` (hover H, pdfport H, media W mit Fallbacks) | |

`docs/install.json` deklariert pro Plugin die Tools (hover: soffice, chrome, pdftoppm, ffmpeg; pdfport: 15 Tools; media: ffmpeg, ffprobe, mpv, whisper-cli, tesseract; images: magick, tesseract, pdftoppm)
-> Ueberschneidungen pdftoppm (3), soffice (2), chrome (2), tesseract (3), ffmpeg (2), magick (2); gelesen von `lib.nvim.deps` (`:Lib deps show <plugin>`). **Es gibt also bereits einen ecosystem-weiten Manifest-Mechanismus** (Suite-Anknuepfungspunkt).

---------------------------------------------------------------------------------------------------

## 6. Erweiterungspunkte-Uebersicht (fuer ein Suite-Plugin)

| Plugin | Registry / Hook | Was man einhaengen kann | Notiz |
|---|---|---|---|
| hover | `hover.registry.register(name,{sources,previews,positions})` (`registry.lua:96`) | Ziel-Erkennung, Preview-Ersatz pro Typ, Position-Previews (+`on_request`) | 7 Fremd-Plugins nutzen es bereits; Typ-Union geschlossen |
| hover | `setup{contribute=...}` -> Name `"user"`; `links.shot.command`; `video.*` | | |
| pdfport | `register_backend/register_producer/register_renderer` | neue Extraktions-/Erzeugungs-/Anzeigearten | `renderers` keine oeffentliche Wrapper-Funktion in `pdfport` (nur `core.registry.register_renderer`, `init.lua:63-67` intern) |
| pdfport | `pick_open(path,opts)`, `integrations.*` | Datei-Baeume | |
| media | `media.core.registry.register(engine)` | Transkriptions-Engines | nicht in `media.init` |
| media | `hub.actions`, `integrations.menu` | Hub-Aktionen | UNVERIFIED wie oeffentlich |
| alle | **keine `User`-Autocmds**; keine Event-Bus | | Suite haette hier freie Bahn (z.B. `User ImagesProviderChanged`) |
| lib | `lib.nvim.deps` (`docs/install.json`), `lib.nvim.image_preview.detect/preview` | zentrale Tool-Deklaration, Provider-Erkennung | bereits "Suite-artig" |

---------------------------------------------------------------------------------------------------

## 7. Docs-Behauptung vs. Code-Realitaet

| Behauptung | Quelle | Befund |
|---|---|---|
| "lib.nvim is the one hard dependency" (hover) | hover `README.md:38` | CODE bestaetigt (bare requires). |
| "pdfport: lib.nvim - :PdfPort is built on its user-command composer" | pdfport `docs/requirements.md` | CODE: Abhaengigkeit **breiter** (platform, core, cache.disk, spawn_capture, ...; `platform/init.lua:12-15`). Docs untertreiben. |
| "media: lib.nvim soft; every place that uses it falls back" | media `README.md:52-60` | CODE bestaetigt (kein bares `require("lib.` ausser innerhalb pcall `health.lua:107`). |
| "hover: drawing goes through lib.nvim.image_preview provider detection (images.nvim / snacks / image.nvim)" | hover `preview/media.lua:15-19` | CODE: nur images.nvim zeichnet tatsaechlich (`media.lua:298-305`). |
| "Both hover and images.nvim use render_page" | pdfport README + `init.lua:181-195` | CODE bestaetigt (`media.lua:827-832`, `images/pdf.lua:176`). |
| "hover.registry contributors: markdown, reposcope, migrate, documentation, spotlight, insights, sandbox, language" | hover `docs/integrations.md` | per `grep` in E:\repos bestaetigt fuer 7 von 8; migrate.nvim nicht geprueft (UNVERIFIED). |
| "media does not draw / images.nvim does" | media `README.md:36-40` | CODE bestaetigt (`ui.lua:167`). |
| hover "no HTML/JS executed on fetch; shot does execute" | `shot.lua:1-12` | CODE stimmt zu Docstring; default off. |
| pdfport "render_page... caller owns PNG" | `init.lua:181-195` | CODE bestaetigt (`rasterize.lua` loescht nie). |

---------------------------------------------------------------------------------------------------

## 8. Verhalten ohne images.nvim - Tabelle

| Situation | hover | pdfport | media |
|---|---|---|---|
| images.nvim fehlt, nichts sonst | Text-Metadaten + Hinweis; Video: Badge; Zoom aus | voll funktionsfaehig; eigener chafa/kitten/imgcat-Renderer | PNGs entstehen; Anzeige ueber System-Viewer/Pfad; Bild-OCR meldet Fehlgrund |
| images.nvim fehlt, snacks/image.nvim vorhanden | **Leerer Float** im Seitenverhaeltnis (`media.lua:529-531` + `300-305`) | wie oben | wie oben |
| lib.nvim fehlt | **Plugin unbenutzbar** (Ladefehler) | **Plugin unbenutzbar** (`platform/init.lua:12`) | funktioniert mit Fallbacks (kein Tab-Completion, kein Progress, Dashboard als Notify-Liste) |

---------------------------------------------------------------------------------------------------

## 9. Auffaelligkeiten / moegliche Bugs (CODE, nicht ausgefuehrt)

1. **hover + nur snacks/image.nvim**: `M.image` gibt Canvas zurueck sobald `detect()` irgendeinen Provider kennt (`media.lua:526-531`), `draw_into` kehrt aber fuer Provider ~= images.nvim mit `nil` zurueck (`:300-305`) -> Float ohne Bild und ohne Metadaten. PDF/Shot/Video-Standbild teilen den Pfad.
2. **pdfport soffice**: `soffice.available()` = PATH-only (`producers/soffice.lua:36-38`) und `argv[1]="soffice"` (`:47`), waehrend `health.lua:345` `lib.nvim.deps.detect` mit `paths` nutzt und "ready" meldet -> Health gruen, `can_create("office")` false, hover meldet "LibreOffice not on PATH" (`office.lua:236-238`). hover `health.lua:446-457` kennt das Problem fuer Windows. (chromium-Producer macht es richtig, soffice nicht.)
3. **`pdfport.render_page` ohne Timeout/Cancel** (`rasterize.lua:80-133`), ebenso ollama-Raster (`ollama.lua:106`); ein haengender pdftoppm meldet nie zurueck. hover hat keinen In-Flight-Guard im PDF-Pfad (`media.lua:760-974`, nur bei office/webpdf/shot) -> UNVERIFIED ob wiederholte Trigger parallele pdftoppm starten (hover-Generation verwirft nur das Ergebnis, kein Kill).
4. **media-Cache wachst unbegrenzt** (nur `:Media cache clear`, `cache.lua:245`); Default-Cache `stdpath("cache")/media.nvim`.
5. **Endungs-Divergenz**: `.ts/.mts` sind in media Video (`formats.lua:34-35`), in hover bewusst nicht (`formats.lua:107-110`) - dieselbe Datei wird verschieden klassifiziert (relevant fuer `:Media` vs. Hover).
6. **hover -> media-Interna**: `require("media.core.play").player()` (`init.lua:1286`), `media.core.audio` (`playback.lua:715`) statt oeffentliche API -> Kopplung an Modulstruktur.
7. `hover/preview/media.lua:328` `require("images.terminal").clear()` steht in `pcall(function() ... end)` (ok), aber Teardown wird auch registriert, wenn nichts gezeichnet wurde (dokumentiert, `media.lua:290-294`).
8. mpv-Aufruf in `audio.lua` ohne `--` vor Pfad (`:60-77`), `player.lua` mit `--` (`:143`).
9. Skript-Generierung + Ausfuehrung mit `-ExecutionPolicy Bypass` (`monitor.lua:153`, `align_win.lua:412`) bei Default-Video-Fenster-Wiedergabe (Monitor-Erkennung `window.lua:53-66`): statischer Inhalt (nicht injizierbar, soweit gelesen), aber "schreibe Datei in Cache und fuehre sie aus".
10. pdfport Terminal-Renderer baut Shell-String (`terminal.lua:90-98`); auf Windows haengt `shellescape` an `'shell'` (UNVERIFIED).

---------------------------------------------------------------------------------------------------

## 10. UNVERIFIED / nicht geprueft
- Kein Test/Skript ausgefuehrt; alle "gemessen"-Zahlen stammen aus Code-Kommentaren der Repos.
- migrate.nvim (hover-Registry-Contributor) nicht gelesen.
- ffmpeg-Protokoll-/Playlist-Risiko, curl `--proto-redir`, pdftoppm-`-`-Pfade, ImageMagick-Coder-Praefixe: nur als Beobachtung markiert.
- Wie tief `images.nvim` SVG/Provider intern behandelt: nicht Teil dieser Recherche (anderer Agent).
- Assertion-Zahlen fuer pdfport/media sind grep-Naeherungen (`H.*`/`it(`).
- `media.hub.actions`-Erweiterbarkeit durch Dritte nicht geprueft.
