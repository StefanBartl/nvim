# Image-Plugins im Vergleich: 3rd/image.nvim · snacks.image · eigener Plugin-Verbund

Stand: 2026-09-21 · Windows 11, natives Neovim 0.12.2, WezTerm 20240203 · Recherche read-only.

Untersuchte Stände:

| Plugin | Stand |
| --- | --- |
| 3rd/image.nvim | Shallow-Clone `365e2ac` (2026-09-05); letzter Release v1.5.1 (2026-02-21) |
| snacks.nvim `image` | lokal installiert, `882c996` (2026-05-25), v2.31.0 |
| images.nvim (eigen) | `8a865c2` (2026-09-20), 187 Commits |
| nvzone/menu (+volt) | Shallow-Clone `7a0a4a2` (2025-06-01) |
| übrige Plugins | jeweils HEAD von `E:\repos\<name>` |

Alle Belege sind `Datei:Zeile`. **UNVERIFIED** = nicht selbst gemessen. Das betrifft vor allem alles, was ein echtes Terminal-Rendering braucht. Ich habe kein Bild live in WezTerm gezeichnet.

Die Rohberichte mit allen Zeilenbelegen liegen unter [`Detail/`](Detail/).

---

## 0. Kurzfassung

1. **Keines der drei Plugins stellt sicher, dass ein Bild wirklich erscheint.** Auch dein eigenes images.nvim nicht.
   - 3rd/image.nvim hat gar keinen Health-Check und keine Terminal-Erkennung.
   - snacks prüft PATH-Tools und fragt den Terminalnamen ab (XTVERSION), sendet aber nie ein Testbild.
   - images.nvim liest nur Umgebungsvariablen und hat keine Probe. Die Doku behauptet an sechs Stellen, `:Image check` probiere das. Der Code tut es nicht (siehe 2.3).
2. **Warum es bei dir nie ging (wahrscheinlichste Erklärung):**
   - **3rd/image.nvim ist auf nativem Windows strukturell nicht lauffähig.** Die Zellgröße kommt nur per `ioctl(TIOCGWINSZ)`, das es dort nicht gibt. Danach bricht jedes Rendern still ab (`renderer.lua:271-272`). Es bleibt ein leerer Buffer ohne Fehler.
   - **snacks.image:** Der Health-Check ist grün, weil er nur Tool-Präsenz und den Terminalnamen prüft. Ob das Kitty-APC-Escape aus nvim.exe (ConPTY) bei WezTerm ankommt, wird nie getestet. Deine eigene Messung in `images.nvim/docs/architecture.md:16-24` sagt: kommt nicht an. Ich habe das nicht reproduziert.
3. **Kein Plugin ist überall besser.**

   | Plugin | Stärke | Schwäche |
   | --- | --- | --- |
   | snacks | Inline-Bilder, die mit dem Text scrollen (nur Kitty/Ghostty) | Windows/WezTerm, stille Fehler |
   | 3rd/image.nvim | Integrationsbreite | Windows unbrauchbar, keine Diagnose |
   | images.nvim | läuft auf nativem Windows + WezTerm | kein Inline, ein Protokoll, keine echte Probe |

4. **Security:** Alle drei nutzen Argument-Listen statt Shell. Die Sicherheitsunterschiede liegen im URL-Abruf und bei Code aus Buffer-Inhalten (Details in Abschnitt 4). images.nvim ist beim Remote-Fetch am besten aufgestellt (Opt-in, Scheme-Allowlist, Limits), aber ohne SSRF-Schutz.
5. **Bundle-Frage:** Ein Monolith wäre falsch. Eine dünne **Suite** (Meta-Paket) plus vorher eine Konsolidierung in `lib.nvim` ist sinnvoll. Begründung und Zuschnitt in Abschnitt 8.
6. **Nebenbefunde im eigenen Ökosystem:** Mehrere gemessene Sicherheits- und Korrektheitsfehler in filetree, language, lib, hover und images (Abschnitt 6). Die zwei gefährlichsten sind Injection-Lücken unter Windows.

### Korrekturen an den Annahmen der Aufgabe

- „4rd/image.nvim" gibt es nicht. Gemeint ist **3rd/image.nvim**.
- 3rd/image.nvim ist in deiner Config **nicht installiert**. Es gibt keinen Treffer in `lazy-lock.json`.
- `snacks.image` ist seit `986842d6c` (2026-09-18) **abgeschaltet** (`lua/plugins/snacks.lua:56`, `image = { enabled = false }`). Davor lief es mit Default-Optionen, ohne `debug` und ohne `convert.notify`, also ohne jede Diagnose.
- **nvzone/menu ist bereits deinstalliert.** Das Menü zeichnen `lib.nvim.contextmenu` und `ui.nvim`'s `ui.contextmenu`. Das „eigene Rechtsklick-UI" existiert also schon, sogar doppelt (siehe 7.4).
- **language.nvim** hat keine einzige Zeile Bildcode. Es ist nur nachgelagert relevant: OCR-Text → Buffer → `:Translate`.

---

## 1. Checkliste aus deiner Aufgabe

- [x] **Architektur / Bereitstellung der Bild-Implementierung** → Abschnitt 1
- [x] **CLI-Tools und ihre Anbindung** → Abschnitt 1.2
- [x] **Wie wird sichergestellt, dass Bilder wirklich erscheinen?** → Abschnitt 2 (Kernfrage)
- [x] **Vor-/Nachteile** → Abschnitt 1.4
- [x] **Feature-Vergleich** → Abschnitt 3
- [x] **Security** → Abschnitt 4
- [x] **Performance-Ideen/-Patterns** → Abschnitt 5
- [x] **Rest des Verbunds** (hover, pdfport, markdown, gopath, lib, pickers, filetree, open, media, language, menu) → Abschnitt 7
- [x] **Bundle-Plugin / „Image-Suite"?** → Abschnitt 8

---

## 1. Architektur

### 1.1 Überblick

| | 3rd/image.nvim | snacks.image | images.nvim (eigen) |
| --- | --- | --- | --- |
| **Grafikprotokoll** | Kitty-Graphics; außerdem `ueberzug`- und `sixel`-Backend (`init.lua:9-13`) | nur Kitty-Graphics (`terminal.lua`) | nur **iTerm2 OSC 1337**, bewusst kein Kitty/Sixel (`docs/CONTRIBUTING.md:44-47`) |
| **Fallback ohne Protokoll** | keiner | Text „terminal does not support…" im Bild-Buffer (`buf.lua:13-28`) | Unicode-Blockgrafik (`half/quadrant/sextant`) über Extmarks, nur im Einzelbildpfad (`init.lua:108-120`) |
| **Wie kommen Pixel zum Terminal** | `stdout:write` über `uv.new_tty(1)`, am Neovim-TUI vorbei (`helpers.lua:9-10,53`) | `nvim_ui_send` (0.12), sonst `io.stdout:write` (`terminal.lua:184-191`) | `nvim_ui_send`, ein einziger Send pro Draw (`terminal.lua:297`) |
| **Wie kommt das Bild ans Terminal** | Default `t=f` (Dateipfad base64, Terminal liest selbst), über SSH `t=d` in Chunks | `t=f` lokal, `t=d` in 4-KB-Chunks per SSH | Original-Bytes der Datei als base64 in der OSC-Sequenz, Terminal skaliert (`terminal.lua:191-205`) |
| **Positionierung** | Decoration Provider pro Redraw + `screenpos`, Cursor-Positionierung + `a=p` | Kitty/Ghostty: **Unicode-Placeholder-Grid als Extmarks** (Neovim scrollt/clippt das Bild „von selbst"); sonst Fallback per Cursor-Move | absolute Bildschirmkoordinaten (`CSI row;col H`), **keine Placement-IDs**, Entfernen per `:mode`-Repaint (`terminal.lua:347-353`) |
| **Inline im Text** | ja (Markdown, Neorg, Typst, Org, Asciidoc, HTML, CSS) | ja, **aber nur mit `placeholders=true`** (Kitty/Ghostty), nicht WezTerm (`terminal.lua:24`) | **nein** (Kernlimitierung, `docs/architecture.md:151`) |
| **Scroll/Fold/Resize** | Fold-, Scroll-, Konceal-Korrektur; Resize räumt **alle** Bilder und rendert neu (im Code als „horrible performance" markiert, `renderer.lua:265`) | Placeholder-Extmarks folgen dem Buffer; Debounce 100 ms | Bild wird bei `CursorMoved/WinScrolled/...` gelöscht, scrollt nicht mit |
| **Konvertierung** | ImageMagick fast immer nötig (auch für PNG, weil `needs_resize` fast immer wahr ist, `renderer.lua:643`) | ImageMagick immer, weil der Schritt `identify` auch bei PNG angehängt wird (`convert.lua:339`) | im Normalfall **keine**; ImageMagick nur für SVG, Blockgrafik und Bildbearbeitung |
| **Debug-/Log-Fläche** | `debug`-Log, Default `/tmp/image.nvim.log` (unter Windows wirkungslos, `logger.lua:176-184`); `:ImageReport` | `debug={request,convert,placement}`, `convert.notify`, `:checkhealth snacks` | `:Image debug`, `:Image calibrate`, `:checkhealth images` |
| **Wartung** | v1.5.1 (2026-02-21), 58 offene Issues (WebFetch), HEAD 2026-09-05 | folke, v2.31.0 | Beta, 187 Commits in 6 Wochen |
| **Tests** | `tests/` (busted), kein Windows-CI (`ci.yml:14`) | im Snacks-Repo (nicht untersucht) | 34 Specs, ~709 Assertions, CI Linux/Win/macOS; **rendert in CI nie ein Bild** |

### 1.2 CLI-Tools und wie sie aufgerufen werden

| Tool | 3rd/image.nvim | snacks.image | images.nvim |
| --- | --- | --- | --- |
| **ImageMagick** | `magick`/`convert`+`identify` per `vim.loop.spawn` (Arg-Liste); Erkennung **einmal beim Laden** des Moduls (`magick_cli.lua:3-5`); Fallback `convert` trifft unter Windows `System32\convert.exe` (`magick_cli.lua:8`) | `magick` per `uv.spawn`; `convert` nur nicht unter Windows (`convert.lua:194`), Kollision sauber gelöst | `magick` per `vim.system`; `identify` mit Header-Fallback (`info.lua:84`), Kollision unter Windows gelöst (`info.lua:81-83`) |
| **Ghostscript** | nur indirekt (ImageMagick-Delegate) | nur indirekt, nur im Health | über pdfport/`pdftoppm` |
| **PDF** | ImageMagick | ImageMagick, `[page]`-Selektor | `pdfport.render_page` → `pdftoppm` (`pdf.lua:176`) |
| **LaTeX/Typst/Mermaid** | nein | `tectonic` oder `pdflatex`, `typst`, `mmdc` | nein |
| **Download** | `curl -L -s -o` (`image.lua:384-388`), keine Existenzprüfung | `curl -L -o` oder `wget` (`convert.lua:59-79`) | `curl -fsSL --max-time --max-filesize` oder `wget` (`remote.lua:97-114`), Opt-in |
| **Weitere** | `ueberzug`, `tmux`, `tty`, `ps` (POSIX-only) | `sips` (macOS) | `tesseract`, `powershell.exe`, `pngpaste`/`wl-paste`/`xclip`, `screencapture`/`grim`/`maim`, `pdftoppm` (via pdfport) |
| **Shell-Strings** | Sixel-Backend: `vim.fn.system("magick '<pfad>' …")` (`sixel.lua:90-101`) | keine (`spawn.lua:147-156`) | keine, alles argv (per Grep über `lua/` bestätigt) |
| **Timeouts** | keine; `vim.wait` bis 5–10 s blockierend | `Spawn` kann Timeouts, `Convert:step` übergibt keinen (`convert.lua:435-448`); hängende Prozesse blockieren einen der 3 Slots | curl/wget ja; lokale `magick`/`tesseract`-Aufrufe **nein**, teils sync `:wait()` |
| **Cache** | Transform-Cache im Speicher + PNGs in `tempname()`, Key = Pfad + **mtime + size** + Geometrie; nie geräumt | `%TEMP%\nvim/snacks/image`, Key = `sha256(src..page)[1:8]`, **ohne mtime** → alte Bilder bleiben stehen, nie aufgeräumt | Remote: TTL 1 Tag; SVG-Cache Key path+mtime; PDF-Cache; SVG/PDF ohne Größenlimit |

Auf deinem System (per `Get-Command`, aus dem snacks-Bericht): `magick` (Scoop), `gs`, `curl`, `ffmpeg` vorhanden. Es fehlen `tectonic`, `pdflatex`, `mmdc`, `typst`. Math- und Mermaid-Rendering in snacks konnte also gar nicht laufen. Für PNG/JPG/PDF waren die Tools da. Das Problem liegt beim Terminal-Pfad, nicht bei fehlenden Programmen.

### 1.3 Terminal-Erkennung und Protokoll-Wahl

| | 3rd/image.nvim | snacks.image | images.nvim |
| --- | --- | --- | --- |
| **Erkennung** | **keine**, `backend = "kitty"` ist Default (`init.lua:18`) | **XTVERSION-Query** `ESC[>q`, Antwort per `TermResponse` geparst, Timeout 1 s (`terminal.lua:268-290`); Env-Overrides `SNACKS_*`; `force=true` | **Env-Whitelist** WezTerm / iTerm2 / Konsole (`terminal.lua:81-101`); sendet nichts |
| **Erkannt = unterstützt?** | – | ja, bei Namen „kitty/ghostty/wezterm" | ja, bei Env-Treffer; sonst `assume_supported=true` als Ausweg |
| **Falsch-Positive** | jedes Terminal mit Default-Backend | ja (Namen ≠ Fähigkeit) | ja (z. B. WezTerm-Env-Var gesetzt, aber tmux dazwischen) |
| **Falsch-Negative** | – | Timeout → „unknown" → unsupported; `M.env()` cached das für die Sitzung (`terminal.lua:111`) | unbekanntes OSC-1337-Terminal → Blockgrafik statt Bild (sichere Fehlrichtung) |
| **tmux** | Passthrough-Prüfung, DCS-Wrapping, `setup` wirft ohne `allow-passthrough` | setzt `allow-passthrough all` selbst (Fehler per `pcall` ignoriert), DCS-Wrapping | nur Hinweistext, **kein DCS-Wrapping im Code** (ob `allow-passthrough on` dann reicht: UNVERIFIED) |
| **Zellgröße in Pixeln** | `ioctl(TIOCGWINSZ)`, unter Windows `nil` → Render bricht still ab | `ioctl`, unter Windows Fallback 9×18 px, Health meldet die Zeile trotzdem OK | von Neovim aus nicht messbar → `cell_aspect` (Annahme 0,5) + `:Image calibrate` |
| **WezTerm** | „nicht offiziell unterstützt" (README:37) | `supported=true, placeholders=false` → nur Fallback-Pfad, kein Inline | `WEZTERM_*` erkannt → OSC 1337 (Hauptzielplattform) |

### 1.4 Vor- und Nachteile

**3rd/image.nvim**
- Pro: ausgereifte Kitty-Pipeline (Crop im Terminal, Virtual Padding per Extmark, Fold-/Scroll-/Konceal-Handling); die meisten Dokument-Integrationen; Transform-Cache mit **mtime** im Key; gute Testbasis.
- Contra: **kein Windows-Support** (ioctl, `tty`, `ps`, POSIX-Quoting, Pfadauflösung, kein Windows-CI); keine Terminal-Erkennung, kein Health, `q=2` verschluckt Terminal-Fehler; viele `pcall`, die Fehler schlucken; Cache ohne Räumung; blockierende `vim.wait`/`uv.sleep`-Pfade.

**snacks.image**
- Pro: eleganteste Inline-Lösung, wo sie greift (Placeholder-Extmarks statt Positionsraten); Sichtbarkeits-Begrenzung + Debounce; Math/Mermaid/Typst; Picker-Preview; aktiv gepflegt; **einzige echte Terminal-Abfrage** der drei.
- Contra: Health beweist nichts über das Rendering; Windows: Zellgröße per Fallback geraten, APC-Zustellung aus nvim.exe **vermutlich** nicht gegeben (UNVERIFIED); WezTerm ohne Inline; Cache ohne mtime und ohne Aufräumen; keine Timeouts; `hover()` ignoriert `enabled=false` und sendet trotzdem APC (`doc.lua:369-434`); Health verspricht „nur PNG geht auch ohne ImageMagick", der Code braucht es immer.

**images.nvim (eigen)**
- Pro: läuft dort, wo die anderen nicht laufen (natives Windows + WezTerm); kein Decode im Normalfall; Escape-Injection konstruktionsbedingt ausgeschlossen (nur Integer + base64); breiter Funktionsumfang (Paste, Screenshot, OCR, Redact, Compare, Zen, Galerie); sichtbare Degradierung statt Stille; Kalibrier-/Debug-Werkzeuge.
- Contra: **keine aktive Probe** (Kern, Abschnitt 2); Bilder nicht inline; Overlay scrollt nicht mit; nur eine Protokollfamilie, Whitelist mit 3 Terminals; kein DCS-Wrapping für tmux; sync base64 der ganzen Datei (kein Größenlimit lokal); einige `:wait()` ohne Timeout; harte Abhängigkeit von `lib.nvim`.

---

## 2. Wie wird sichergestellt, dass Bilder wirklich erscheinen?

Das war deine Hauptfrage.

### 2.1 Antwort: gar nicht, bei allen dreien

| Prüfung | 3rd/image.nvim | snacks.image | images.nvim |
| --- | --- | --- | --- |
| Gibt es `:checkhealth`? | **nein** (nur `:ImageReport`, das nichts prüft) | ja, `:checkhealth snacks` | ja, `:checkhealth images` |
| Tool im PATH geprüft? | nein | ja (`kitty`/`wezterm`/`ghostty`, `magick`, `gs`, …) | ja (`magick`, `tesseract`, `pdftoppm`, …) |
| Terminal identifiziert? | nein | ja, per XTVERSION-Antwort | per Env-Var |
| Grafik-Roundtrip (Kitty `a=q`, Testbild, Ack)? | nein | **nein**, im ganzen Plugin nicht (Grep: kein Treffer) | **nein** (OSC 1337 hat keine Query; das Plugin versucht keinen Ersatz) |
| Terminal-Fehler sichtbar? | nein, `q=2` | nein, `q=2` (`terminal.lua:160`) | nein, keine Antworten gelesen |
| Menschliche Prüfschleife | `:ImageReport` (Textdump) | Debug-Flags | `:Image calibrate`, `:Image debug`, Blockglyph-Zeilen im Health |

### 2.2 Warum ein grüner Health-Check nichts bedeutet

- **snacks:** `Snacks.health.have_tool({kitty, wezterm, ghostty})` prüft `vim.fn.executable`, also ob `wezterm.exe` im PATH liegt. Das ist unabhängig davon, in welchem Terminal Neovim gerade läuft. „Terminal Dimensions" wird immer als `ok` gemeldet, auch beim 9×18-Fallback (`init.lua:333-342`). Die XTVERSION-Antwort beweist nur, dass ein CSI/DCS-Reply ankommt. Ein APC-Escape (`ESC _ G …`) ist eine andere Klasse und wird nie getestet.
- **3rd/image.nvim:** Es existiert kein Health-Modul. Die „grünen" Checks, die du gesehen hast, kamen also von anderen Plugins, sehr wahrscheinlich von `:checkhealth snacks`.
- **Beide** senden alle Kitty-Kommandos mit `q=2` (keine Antworten/Fehler) und lesen nie zurück. Ein Terminal, das APC verwirft, erzeugt keinerlei Rückmeldung.
- **Stille Abbruchstellen** (Auswahl, Beleg jeweils im Detailbericht):
  - image.nvim: `term_size == nil` → `return` ohne Log (`renderer.lua:271-272`); `pcall` schluckt `from_file`-Fehler (`document.lua:238-250`); curl ohne `-f` speichert HTTP-Fehlerseiten und der Cache merkt sich fehlgeschlagene URLs (`image.lua:405-408`).
  - snacks: Convert-Fehler nur bei `convert.notify=true` (Default `false`); Inline und Hover-Float schlucken Fehler (`placement.lua:113-115`, `doc.lua:405-411`); Cache ohne Invalidierung.

### 2.3 Auch dein images.nvim hat diese Lücke, und die Doku behauptet das Gegenteil

Ich habe den Kern selbst nachgeprüft:

- `terminal.lua:81-155`: `capability()` wertet nur `WEZTERM_*`, `TERM_PROGRAM`/`LC_TERMINAL` (iTerm) und `KONSOLE_VERSION` aus. Es wird nichts gesendet und keine Antwort erwartet. Der Kommentar dort sagt selbst „OSC 1337 has no capability query, so a list of names is all there is".
- `init.lua:752-762`: `recheck()` (`:Image check`) setzt nur den Memo-Cache zurück und liest dieselben Env-Vars erneut.
- **Commit `8a865c2`** („terminal probe is protocol-generic") ändert nur `doc/images.txt`, `docs/WORKFLOW.md` und `docs/troubleshooting.md`. Der „Probe" ist ein `printf`-Befehl, den ein Mensch außerhalb von Neovim ausführt.
- **Doku-vs-Code-Widersprüche** (aus dem Agent-Bericht, Stellen dort gelistet):
  - `docs/health.md:30-33`, `docs/commands.md:250-252`, `docs/troubleshooting.md:13`, `docs/installation.md:99-101`, `docs/quickstart.md:10`, `docs/CONTRIBUTING.md:52-54` sagen, `:Image check` zeige, ob OSC 1337 „right now" ankommt. Der Code kann das nicht.
  - `assume_supported`: Doku sagt „changes nothing about drawing" (`DEFAULTS.lua:48-51`), der Code überspringt damit den ASCII-Fallback (`init.lua:108`).
  - `health.lua:40` schreibt „OSC 1337 is supported" als Tatsache, obwohl es nur eine Env-Var ist.
- **Ordnungs-Bug** (vom Agent headless nachgestellt): `:checkhealth` ruft `capability(false)` (`health.lua:37`). Ist das der erste Aufruf der Sitzung, wird `ok=false` gememoized. Spätere Draws mit `assume_supported=true` bekommen dann trotzdem `false`. Nur `:Image check` hilft.

Was images.nvim ehrlicher macht als die anderen: Die Erkennung ist offen als Heuristik deklariert, es gibt einen sichtbaren Fallback (Blockgrafik oder einmalige Warnung mit Testrezept), und es gibt menschliche Feedback-Schleifen, die reale Fehler gefunden haben. Es beweist aber ebenfalls nichts selbst.

### 2.4 Diagnose in Schichten (Vorschlag)

Die Fehlerquelle liegt bei Windows-Neovim in WezTerm in genau einer von drei Schichten. Jede lässt sich getrennt prüfen:

| Schicht | Test | Aussage |
| --- | --- | --- |
| 1. Terminal | Sequenz **aus einer nackten PowerShell** in WezTerm ausgeben: OSC 1337 (`printf`-Rezept aus `docs/troubleshooting.md:22-28`) und Kitty-APC | Kann das Terminal das Protokoll? |
| 2. Neovim-Ausgabepfad | dieselben Bytes per `nvim_ui_send` aus nvim.exe senden | Kommt es durch ConPTY/Neovim-TUI? |
| 3. Plugin | erst jetzt das Plugin | Plugin-Logik (Größen, Position, Cache) |

Dein Repo behauptet, Schicht 1 klappt für beide Protokolle, Schicht 2 nur für OSC 1337 (`docs/architecture.md:16-24`). Ob dort echte Kitty-APC-Sequenzen oder nur `wezterm imgcat` (nutzt iTerm2-Protokoll) getestet wurden, ist offen (UNVERIFIED).

Kitty-Query zum direkten Ausprobieren (aus der Kitty-Dokumentation, **von mir nicht ausgeführt**): Aus nvim.exe `vim.api.nvim_ui_send("\27_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\27\\")` senden und mit einem `TermResponse`-Autocmd mithören. Kommt `i=31;OK` zurück, erreicht APC das Terminal. Kommt nichts, ist die Ausgabe-Schicht die Ursache. Ob `TermResponse` APC-Antworten überhaupt an Lua weitergibt, ist UNVERIFIED (das Plugin dokumentiert es in `cell.lua:14-21` so).

### 2.5 Was eine echte Probe leisten könnte (Ideen für images.nvim)

Alle Ideen sind **ungeprüft**, ein Spike wäre nötig:

1. **XTVERSION (`CSI > q`) statt Env-Sniffing.** snacks beweist, dass dieser Reply-Pfad unter WezTerm/Windows funktioniert (sonst wäre Health nicht grün gewesen). Er identifiziert das *tatsächliche* Terminal, auch durch SSH/tmux hindurch, wo Env-Vars lügen.
2. **Cursor-Vorschub als Beweis.** OSC-1337-Inline-Bilder bewegen den Cursor. Ein winziges Bild plus Cursor-Position-Report (`CSI 6n`) vor/nach dem Senden würde zeigen, dass das Terminal die Sequenz als Bild *konsumiert* hat. Ein Terminal, das OSC ignoriert, rührt den Cursor nicht. Voraussetzung: Neovim reicht die CPR-Antwort an Lua durch.
3. **Zellgröße messen** (XTWINOPS `CSI 16 t` bzw. iTerm2 `ReportCellSize`), statt `cell_aspect` zu raten. Ob WezTerm das beantwortet: UNVERIFIED.
4. **Selbsttest-Befehl** (`:Image selftest`): Testkarte zeichnen und das Ergebnis der Punkte 1–2 als Ja/Nein ausgeben, statt nur einen Text „supported".
5. **Doku sofort an den Code angleichen** (die sechs Stellen aus 2.3) oder die Probe bauen. Beides ist besser als der jetzige Zustand.

---

## 3. Feature-Vergleich

| Feature | 3rd/image.nvim | snacks.image | images.nvim |
| --- | --- | --- | --- |
| Formate | per Magic-Bytes: png, jpeg, webp, gif, bmp, heic, ico, avif, svg, pdf | `png jpg jpeg gif bmp webp tiff heic avif mp4 mov avi mkv webm pdf icns`; **SVG nicht im Default** (`init.lua:52-69`) | `png jpg jpeg gif webp bmp svg` (`DEFAULTS.lua:11`); PDF-Seite als Bild über pdfport |
| GIF-/Video-Animation | nein (erster Frame) | nein (Video = Standbild, erster Frame) | nein (bewusst gestrichen); Video-Standbild/Playback über hover+media |
| Inline im Buffer-Text | ja | ja, nur Kitty/Ghostty | nein |
| Markdown | Treesitter (`![]()`, Shortcut, data-URI, vimwiki) | Treesitter (+ Wikilink-Bilder) | Link unter Cursor (`![]()`, `<img>`, `<figure>` über markdown.nvim), kein Scan des ganzen Buffers |
| Weitere Sprachen | Neorg, Typst, Org, Asciidoc, HTML, CSS (RST vorhanden, aber nicht Default) | html, norg, tsx, js, css, scss, vue, svelte, latex, typst | – |
| Math (LaTeX/Typst) | nein | ja (`tectonic`/`pdflatex`, `typst`) | nein |
| Mermaid | nein | ja (`mmdc`) | nein |
| Remote-URLs | ja, **Default an** | ja, automatisch bei Sichtbarkeit | ja, **Default aus**, nur Einzelbildpfad |
| PDF | ja (ImageMagick + gs) | ja (ImageMagick + gs, `#page=N`) | Seite via pdfport, für Host-Picker/hover |
| Picker-Preview | nein | ja (`snacks.picker`) | ja, Draw-Surface für fremde Picker (`integrations/picker.lua`) |
| Hover-/Float-Vorschau | Popup-Modus `only_render_image_at_cursor` | `Snacks.image.hover()` | Overlay- oder Float-Hover |
| Galerie, Compare, Zen | nein | nein | ja |
| Paste aus Clipboard / Screenshot | nein | nein | ja (Windows/macOS/Linux) |
| OCR | nein | nein | ja (`tesseract`) |
| Redact / Scale / Optimise / Convert / Export | nein | nein | ja |
| Orphans (verwaiste Bilder) | nein | nein | ja |
| Kalibrierung / Debug-Tools | `:ImageReport` | Debug-Flags | `:Image calibrate`, `:Image debug` |
| User-Commands | nur `:ImageReport` | keine | 25 `:Image`-Routen |
| Öffentliche API | `from_file`, `from_url`, `hijack_buffer`, `get_images`, … | `Snacks.image.{hover, supports, doc, placement, …}` | `show`, `draw`, `gallery`, `ocr`, …; Untermodule `terminal`, `anchor`, `scale`, `integrations.picker` |
| Windows nativ | **nein** | eingeschränkt, Bildpfad ungeklärt | ja (Zielplattform) |

Was images.nvim (in Richtung Kitty-Plugins) fehlt: Inline-Rendering, ID-basiertes Placement, partielles Löschen, Kitty/Sixel, Math/Mermaid, Aufräumen alter Bilder nach mtime im Cache, aktive Terminal-Abfrage.

---

## 4. Security

### 4.1 Vergleich

| Aspekt | 3rd/image.nvim | snacks.image | images.nvim |
| --- | --- | --- | --- |
| Prozessstart | Arg-Listen (`vim.loop.spawn`); **Ausnahme** Sixel-Backend: Shell-String mit `'`-Quoting | Arg-Listen (`uv.spawn`), keine Shell | Arg-Listen (`vim.system`) |
| Argument-Injection (`-`-Präfix) | Pfade absolut (`fnamemodify(:p)`); URL nur `http(s)://`; kein `--` vor der URL | Pfade absolut, URLs `^%w%w+://` | URL nur `^https?://`, eigenes argv-Element |
| Remote-Scheme | `http://`/`https://` (`document.lua:31-33`) | **jedes** Schema mit ≥2 Zeichen (`ftp://`, `dict://`, `gopher://`, …), `file://` wird umgeschrieben (`convert.lua:472-480`) | Allowlist `^https?://`, `ftp://`/`file://` explizit abgelehnt, Test vorhanden (`remote.lua:24-26`) |
| Remote Default | **an** (`download_remote_images = true`) | an, Abruf schon beim Sichtbarwerden | **aus** (Opt-in) |
| curl-Flags | `-L -s -o`; **kein** `-f`, Timeout, Größenlimit, `--proto` | `-L -o`; nichts davon | `-fsSL --max-time --max-filesize`; **kein** `--max-redirs`/`--proto` |
| SSRF / private IPs | kein Schutz | kein Schutz | **kein Schutz** (nur Opt-in als Mitigation) |
| Größenlimit Download | keins | keins | curl `--max-filesize` (greift bei unbekannter Länge laut curl-Doku nicht, UNVERIFIED); wget `-Q` bei Einzeldatei vermutlich wirkungslos (UNVERIFIED) |
| Code-Ausführung aus Buffer-Inhalt | nein | **ja:** LaTeX (`pdflatex` **ohne** `-no-shell-escape`, `convert.lua:104`), Typst (`@preview`-Pakete laden), Mermaid (Headless-Chromium). Rendering startet automatisch beim Öffnen der Datei | nein |
| ImageMagick-Angriffsfläche | svg/xml/pdf gelten als Bild; nur `policy.xml` schützt | Inhalt wird von IM geparst, keine `-limit`/Delegate-Beschränkung | nur bei SVG/Blockgrafik/Bildbearbeitung; keine `-limit`-Flags |
| Escape-Sequenz-Injection | nur selbst erzeugte Sequenzen (Pfad base64); Ausnahme Sixel-Daten aus IM | nur Zahlen + base64 | nur Integer + base64, **kein** Freitext in der Sequenz |
| Inhaltsprüfung vor Verarbeitung | Magic-Byte-Gate (`image.lua:275`) | keine für Inline-`src` | nur Endung, keine Magic-Bytes |
| Pfad-Confinement | keins (Dokument darf beliebige lokale Bilder referenzieren) | keins (`../..` erlaubt) | keins; `sanitize_filename` beim Paste |
| Temp-/Cache-Dateien | `tempname()`-Verzeichnis, Namen `sha256`; nie gelöscht | vorhersagbare Namen `sha8-base.ext`, `io.open(...,"w")` ohne Symlink-Schutz | `stdpath("cache")`; nur Remote hat TTL |
| Command-Substitution-Lücken | – | – | **gefunden und behoben** (`vim.fn.expand` auf Link-Text führte Backticks aus; Commit `0518fd7`, Regressionstest) |
| Persistente Daten | – | – | `calibration.json` als untrusted validiert (SEC-33) |

### 4.2 Einordnung

- **Das ernsteste Muster der Konkurrenz:** snacks führt LaTeX/Typst/Mermaid-Werkzeuge mit Buffer-Inhalt aus, ohne dass jemand nachfragt. Das Öffnen einer fremden Markdown-Datei kann Werkzeuge mit deren Inhalt starten. Bei dir ist das durch das Fehlen der Tools und `enabled = false` aktuell nicht wirksam.
- **Das ernsteste Muster bei image.nvim:** Remote-Download ist standardmäßig an, ohne Limits, mit Redirects und ohne Schema-Grenze außerhalb des Dokument-Pfads. Ein geöffnetes Markdown löst automatisch Requests aus (SSRF-artig, Tracking-Pixel).
- **images.nvim ist beim Remote-Fetch am besten.** Es fehlen `--max-redirs`, `--proto`/`--proto-redir` und eine Private-IP-Sperre. Die Lücke wird nur durch das Opt-in gemildert.
- **Nicht exploitbar geprüft** wurden ImageMagick-Delegates (SVG/MSL/PDF via Ghostscript). Die Standardpolicy deiner Scoop-Installation ist UNVERIFIED.
- Ehrlicher Punkt: **keines der drei** setzt `-limit memory/time` für ImageMagick.

---

## 5. Performance: umgesetzte Ideen und Patterns

| Pattern | 3rd/image.nvim | snacks.image | images.nvim |
| --- | --- | --- | --- |
| **Async Konvertierung** | `transform` async mit Dedup-Queue (`renderer.lua:692-737`) | `uv.spawn`, Queue mit `MAX_PROCS=3` (`convert.lua:201-218`) | Remote/Redact/PDF-Export async (Serie 2026-08-23), PDF-Rendern mit In-Flight-Dedupe |
| **Disk-Cache** | PNGs in `tempname()`, Key inkl. mtime+size+Geometrie (`transform_cache.lua:40-53`) | `stdpath("cache")/snacks/image`, **ohne mtime** | Remote (TTL 1 d), SVG (path+mtime), PDF (path+mtime+page+dpi) |
| **Memory-Cache** | `transmitted_images`, `remote_cache`, Treesitter-Matches pro `changedtick` | `images[file]`, `dims`, Buffer-Cache pro `changedtick` | `cache.memory`-Namespaces (TTL 300 s) für `pixels`/`info` |
| **Cache-Eviction** | keine | LRU nur für an das Terminal gesendete Bilder (200 MB), Disk nie | Remote-TTL (nur beim Wiederaufruf derselben URL); SVG/PDF unbegrenzt |
| **Nur Sichtbares rendern** | Viewport ± Overscan (`document.lua:92-102`) | Treesitter nur über `topline-1..botline` (`doc.lua:213-241`) | nicht nötig (ein Bild zur Zeit) |
| **Debounce/Coalescing** | Event-Loop-Coalescing pro Key (`render_scheduler.lua`, 29 Zeilen) | 100 ms Inline, 10 ms Placement; Placement-Update bricht bei gleichem State ab | – |
| **Kein Subprozess für Bildmaße** | Header-Parser (`utils/dimensions.lua`) vor `identify` | PNG-Header (`util.lua`) | Header-Parsing PNG/JPEG/GIF/BMP/WebP (`pixels.lua`), `identify` nur als Fallback |
| **Batching** | – | ein Prozess pro Schritt | **ein** `magick` für alle Frames (186 ms statt 1593 ms für 24 PNGs, `blocks.lua:5-11`) |
| **Lokal keine Pixelübertragung** | `t=f` (Pfad) | `t=f` (Pfad) | Datei komplett lesen + base64 (dafür kein Decode) |
| **Lazy Loading** | Backend/Processor lazy beim ersten Zugriff | Module lazy per `__index`; Formatliste absichtlich dupliziert, damit das Modul nicht geladen werden muss (`snacks/init.lua:27`) | `require` in Funktionskörpern; `plugin/images.lua` hat 3 Zeilen |
| **Hot-Path-Kosten** | `on_win` bei jedem Redraw, O(botline) Fold-Schleife | Erkennung `vim.wait` bis 1,5 s sync | Payload wird bei jedem Redraw neu gelesen und kodiert (z. B. Zen bei `WinResized`) |
| **Blockierend** | `vim.wait` 5–10 s, `uv.sleep(1)` pro Chunk im Render (`helpers.lua:87,138`) | SSH: `uv.sleep(1)` pro 4-KB-Chunk (`image.lua:178`) | `:wait()` ohne Timeout bei SVG, `identify`, Block-Sampling (Einzelbild), `tesseract --list-langs` |

**Was jeder vom anderen lernen könnte:**
- images.nvim ← snacks: XTVERSION-Probe; Sichtbarkeits-Begrenzung nur wenn Inline kommt; LRU über gesendete Payloads.
- images.nvim ← 3rd/image.nvim: Cache-Key mit mtime+size für **alle** Caches; Payload-/Transform-Cache statt jedes Mal neu lesen + base64.
- snacks/3rd ← images.nvim: Batching, Header-Parsing ohne Subprozess, Timeouts und TTL.

Eigene Performance-Bilanz von images.nvim: Das Commit-Log hat eine saubere PERF-/SEC-/ERR-Serie (Details im Detailbericht, Abschnitt 6). Offen bleiben: keine Payload-Cache, sync base64 der ganzen Datei ohne Größenlimit, ein paar `:wait()` ohne Timeout, SVG-/PDF-Cache wächst unbegrenzt.

---

## 6. Funde im eigenen Ökosystem (Security und Korrektheit)

Gemessen (von den Agents mit harmlosem Marker nachgestellt, Windows 11, Neovim 0.12.2):

| # | Plugin | Fund | Beleg | Schwere |
| --- | --- | --- | --- | --- |
| 1 | filetree.nvim | **PowerShell-Injection über typografische Quotes** (U+2018/U+2019) im Dateinamen: nur `'` wird verdoppelt. Ein Dateiname in einem geklonten Repo reicht, ausgelöst beim Trash (`d`, mit Bestätigung) | `trash/platform.lua:51-66`, `undo.lua:180-181` | hoch |
| 2 | language.nvim | **cmd.exe-Injection** bei Nicht-`.exe`-Shims: Argumente mit `"` werden nicht escaped (`cmd.exe /c <shim> …`). Betroffen: `trans`-Provider (Buffer-Text als argv); ob `trans` bei dir ein Shim ist: UNVERIFIED | `util/job/init.lua:21-40` | hoch, bedingt |
| 3 | lib.nvim | `cross.open_default` verstümmelt auf Windows Nicht-http-Schemes (`ssh://` → `ssh:\\host\x`, `mailto:` → Temp-Pfad, `file:///C:/x` kaputt). Betrifft gopath ohne open.nvim. Logik headless nachgebaut, nicht Ende-zu-Ende | `open_default/init.lua:29-33,57-66` | mittel |
| 4 | filetree.nvim | `explorer.exe` bekommt den gsub-Zähler als extra argv (`{ "explorer.exe", "x\\y", 1 }`); Schwesterstelle `util/pdf.lua:41` ist korrekt geklammert | `preview/init.lua:130` | niedrig |
| 5 | filetree.nvim | Live-Preview lädt jede Datei per `bufload` (auch Bilder/Binärdateien) ohne Größen-/Binär-Guard (nur gelesen, nicht ausgeführt) | `preview/init.lua:419-429` | mittel |
| 6 | images.nvim | Ordnungs-Bug `:checkhealth` → `capability` memoized `false` (siehe 2.3) | `health.lua:37`, `terminal.lua:115` | mittel |
| 7 | images.nvim | Windows-Clipboard: Pfad in PowerShell-`-Command`-String interpoliert, nur `'` verdoppelt (gleiche Klasse wie Fund 1, theoretisch) | `paste.lua:73` | niedrig–mittel |
| 8 | hover.nvim | schreibt Skripte nach `stdpath("cache")` und führt sie mit `-ExecutionPolicy Bypass` aus; bei hover leerer Float, wenn nur snacks/image.nvim installiert ist (`draw_into` zeichnet nur für images.nvim) | `monitor.lua:153`; `media.lua:300-305` | niedrig / Korrektheit |
| 9 | pdfport.nvim | `render_page` ohne Timeout und ohne Pfad-Kanonisierung; Terminal-Renderer baut Shell-String (`:terminal chafa …`) | `rasterize.lua:80-133`; `renderers/terminal.lua:90-98` | niedrig–mittel |
| 10 | media.nvim | ffmpeg/ffprobe ohne `-protocol_whitelist`; Cache ohne TTL/Limit; `audio.lua` ohne `--` vor dem mpv-Pfad | `core/cache.lua`; `audio.lua:60-77` | niedrig |
| 11 | markdown.nvim / gopath.nvim | Default-Öffnen-Listen enthalten `exe`, `msi`, `dmg`, `app` → per `ma` startet ein Link auf `x.exe` ohne Rückfrage | markdown `DEFAULTS.lua:295-298`; gopath `detector.lua:49-51` | niedrig (nutzerinitiiert) |
| 12 | lib.nvim | `cross.run` ist ein Shell-String-Runner (`sh -lc`/PowerShell); nur `run_detached(argv)` ist argv; `run_argv.run_blocking` ohne Timeout | `run/init.lua:9-19` | Risikoquelle für Konsumenten |
| 13 | Doku-Drift | open.nvim verspricht System-App-Fallback bei `images.show`-Fehlschlag (`HANDLERS.md:107-110`), Code gibt nur `false` zurück (`handlers/image.lua:28-31`); markdown `WORKFLOW.md:132` nennt ein nicht existierendes Modul; gopath deklariert fd/rg, nutzt sie im Produktivpfad nicht | – | niedrig |

Positiv, sofern in deinem Verbund vorhanden: Command-Substitution-Fix (`vim.fn.expand` → `expand_path`) in images, markdown, open; Escape-Injection-freie Sequenzen; Opt-in für Netz/Screenshot/Office in hover (`links.web=false`, `links.fetch=false`, …); `lib.nvim.fs.is_subpath` existiert, wird aber von markdown/gopath/pickers nirgends genutzt; `lib.nvim.net.curl` legt Credentials per stdin-Config statt argv.

---

## 7. Der Verbund

### 7.1 Größe, Reife, Rolle beim Bild

| Plugin | Lua-Dateien / Zeilen | Commits | Tests | Rolle beim Bild |
| --- | --- | --- | --- | --- |
| images.nvim | 76 / ~9,4k (38 Kernmodule) | 187 | 34 Specs | **einziger echter Renderer** (OSC 1337, Blockgrafik) |
| lib.nvim | 476 / 51k | 582 | 64 Specs | Infrastruktur: `image_preview`, `deps`, `cross.executable`, `net.curl`, `cache`, `notify`, `contextmenu` |
| hover.nvim | 40 / 16k | 155 | 576 `it(` | Bild-/PDF-/Video-/URL-Hover; zeichnet **nie selbst**, ruft `images.anchor.draw` |
| pdfport.nvim | 52 / 7,1k | 129 | 21 Specs (kein Tool wird ausgeführt) | `render_page` (pdftoppm→PNG); hat einen **eigenen**, images-unabhängigen Terminal-Renderer (chafa/kitten/imgcat) |
| media.nvim | 39 / 8,3k | 48 | 35 Specs | erzeugt PNGs (ffmpeg), zeigt über `images.show`; sonst System-Viewer |
| markdown.nvim | 81 / 15,7k | 220 | 43 Specs | Link-/Bild-Aktion `mi`, Link-Scanner (von images genutzt), Hover-Quelle |
| gopath.nvim | 77 / 11,1k | 179 | 17 Specs | Pfadauflösung; öffnet Bilder **nur extern** |
| pickers.nvim | 75 / 9,7k | 184 | **1** Datei | Picker-Preview via `images.integrations.picker` (sauberste Integration) |
| filetree.nvim | 131 / 30,5k | 422 | ~12k Zeilen Tests | Baum-Preview; ruft `images.show`, eigene Provider-Kette |
| open.nvim | 26 / 4,3k | 118 | 18 Specs | Handler `:Open image` → `images.show` |
| language.nvim | 51 / 8,2k | 112 | 31 Specs | **kein Bildcode**; nur nachgelagert (OCR-Text) |

Alle sind Beta (README-Banner), keines hat Versions-Tags. lib.nvim nutzt den Branch `ci-verified` als CI-Pin.

### 7.2 Abhängigkeitsgraph (bare `require`-Zählung + Agent-Befunde)

```
                       ┌──────────── lib.nvim (Pflicht für alle) ────────────┐
                       │   image_preview · deps · cross.* · net.curl · cache │
                       └───▲────▲────▲────▲────▲────▲────▲────▲────▲────▲────┘
                           │    │    │    │    │    │    │    │    │    │
 images ◄─(soft)─► markdown ◄─(soft)─ hover ◄─(Registry)─ markdown/language/…
   ▲  ▲ ▲ ▲  ▲          │                 │
   │  │ │ │  └── media ──┘                 └─(soft)─► images (anchor/scale/convert/blocks/terminal)
   │  │ │ └── filetree ─(soft)─► images.show,   pdfport
   │  │ └──── open ─────(soft)─► images.show
   │  └────── pickers ───(soft)─► images.integrations.picker.*
   └── pdfport ◄─(soft)── images/pdf.lua:176 (render_page)
 gopath ─(soft)─► images.resolve nutzt gopath.resolve_at_cursor;  gopath öffnet Bilder selbst nur extern
```

Kernpunkte:
- **Hart:** alles → `lib.nvim`. Die Richtung „lib zeigt nie auf Konsumenten" wird durch `image_preview` (pcall auf `images.*`) verletzt.
- **Zyklisch weich:** images ↔ markdown; hover greift in images-Interna (`images.blocks.*`, `images.anchor`) und media-Interna (`media.core.*`), nicht nur in öffentliche APIs.
- **Stabile Einstiege in images.nvim:** `images.draw(target, position, path, opts)` und `images.integrations.picker.*`; historisch `images.browse.draw_in_window`. filetree/open/media rufen nur `images.show(path)`.
- **Erweiterungspunkte:** eine echte Registry gibt es nur in **hover.nvim** (`hover.registry.register`, sieben Beitragende bestätigt). Sonst nur gopath `custom_resolvers`, open.nvim `registry.register`, pdfport `register_backend/producer`. **Kein einziges `User`-Autocmd** im Verbund, keine Versionsnummern.

### 7.3 Doppelt implementiert (Kandidaten für lib.nvim)

| Was | Wo überall |
| --- | --- |
| **Bild-/Medien-Endungslisten** | markdown (2×), gopath, hover (`classify`, `formats`), images.nvim, media (eigene Tabellen, `.ts` weicht ab) |
| **Terminal-/Provider-Erkennung** | images.nvim (`terminal.lua`), pdfport (`platform/init.lua:110-116`), lib (`is_kitty`), hover/lib `image_preview.detect()` |
| **System-Opener** | markdown `util/platform.lua`, gopath `opener.lua`, filetree (3×: `preview/init.lua:123`, `util/pdf.lua:34`, `open_with:45`), open.nvim, lib `cross.open_default` (lib nennt es selbst „three independent copies") |
| **Tool-Erkennung** | fd/fdfind in pickers 5× + gopath 1×; ≥5 Varianten im Verbund; `platform.has` in pdfport ist PATH-only, während `chromium`/health `deps.detect` mit Pfaden nutzen |
| **pdftoppm-argv** | 3× allein in pdfport (`rasterize`, `tesseract`, `ollama`) |
| **PDF-Seite → PNG-Cache** | hover (Memory), images.nvim (Disk), pdfport (keiner) |
| **curl-Download** | images `remote.lua`, hover `webpdf.lua`, `lib.net.curl` |
| **Provider-Kette images→snacks→image.nvim** | filetree `preview/init.lua:144-206` und lib `image_preview` |
| **Chrome-Erkennung** | hover `shot.lua`, pdfport `producers/chromium.lua` |
| **tesseract/OCR** | pdfport, `images.ocr`, media (als Vermittler) |
| **PDF-Chooser-UI** | markdown (2 Optionen), gopath (4 Modi) |
| **Preview-Float + Zeichnen** | markdown `commands/links.lua`, lib `image_preview`, hover `media.lua` |
| **Binär-Datei-Cache** | fehlt in lib (`cache.disk` ist JSON), stattdessen ≥4 eigene Cache-Wurzeln |
| **Soft-Fallback-Klone von lib** | markdown und gopath tragen tote Fallbacks für lib, obwohl lib dort Pflicht ist |

Positives Gegenbeispiel: `lib.nvim.frecency` wurde aus pickers extrahiert und wird von gopath+pickers geteilt.

### 7.4 nvzone/menu und das Rechtsklick-UI

- **Stand:** nvzone/menu ist **nicht mehr installiert** (`lua/plugins/nvchad.lua:1-27`: `enabled = false`; toter Eintrag `lazy-lock.json:17`; `volt`/`minty` verwaist). Gezeichnet wird vom eigenen Stack.
- **Zwei parallele Implementierungen im Umlauf:**
  - `lib.nvim.contextmenu` (346 Z.): von deiner Config genutzt, `config/menu/init.lua:23`.
  - `ui.nvim`'s `ui.contextmenu` (379 Z.): von filetree (hart), images (`integrations/menu.lua:19`, top-level `require`) und open.nvim (pcall) genutzt.
  - Ebenso doppelt: `lib.nvim.ui.kit.*` und `ui.nvim`'s `ui.kit.*`. Laufende Migration (`PLAN-ui-kit-migration.md`). Ob beide gleichzeitig laden: UNVERIFIED.
- **nvzone/menu selbst** (Clone): ~805 Zeilen + volt ~1,2k; **GPL-3.0**; letzter Push 2025-06-01 (menu), 2025-09-13 (volt). Items-Schema ohne `icon`, `disabled`/`visible`, `on_close`, Kontextobjekt; Singleton-State; volt setzt global `mousemev` und einen `on_key`-Handler, der nie zurückgenommen wird; globales `<LeftMouse>`-Mapping bleibt teils bestehen. **Keine Preview-/Bildfläche** im Menü.
- **Was ein Rechtsklick-UI für die Bild-Suite bräuchte** (und was auch dein eigener Stack noch nicht hat):
  1. Kontextobjekt `{kind, path, buf, win, tree_node, selection[], is_remote}` statt „jedes Plugin liest den Cursor selbst".
  2. Provider-Registry `register({id, applies(ctx), items(ctx), order})` statt handgepflegter `CONTRIBUTORS`-Liste (`config/menu/mappings.lua:47-140`).
  3. Item-Schema mit `enabled`/`disabled`-Grund, `visible`, Heading/Group, Submenu, `busy`-Status. Das Kit hat `icon`, `heading`, `group`, `submenu`, blendet aber nur aus statt auszugrauen.
  4. Preview-Fläche mit Lifecycle (`on_open/on_select_change/on_close`), Muster: `ui.kit.compare`.
  5. Multi-Selection (Marks/Visual) für Batch-Aktionen.
  6. Bild-Einträge im **Tree-** und **Bild-Buffer-Kontext**. Heute gibt es Bildeinträge nur in markdown/vimwiki/norg/text-Buffern (`images/integrations/menu.lua:36-40`). Die filetree- und open-Menüs haben **keine** Bild-/PDF-Einträge.
  7. Aktionen: Show, Open externally, Reveal, Copy path / Markdown-Link, OCR → Buffer → `:Translate`, Info, Scale/Convert/Optimise/Export, Redact, Replace, Compare/Gallery, Delete (Trash). **Rotate/Flip gibt es in images.nvim nirgends.**

### 7.5 Was jedes Plugin ohne images.nvim tut

| Plugin | Verhalten |
| --- | --- |
| hover | Metadaten-Float; **bei nur snacks/image.nvim leerer Float** (Fund 8) |
| pdfport | unverändert (kennt images.nvim gar nicht) |
| media | PNG im System-Viewer |
| markdown | System-Viewer / Metadaten |
| filetree | Auto-Modus → snacks → image.nvim → System; explizit `"images.nvim"` → nur Warnung |
| open | System-App-Fallback nur, wenn images.nvim **fehlt**, nicht bei `show`-Fehlschlag |
| gopath | unverändert (öffnet Bilder ohnehin extern) |
| pickers | Engine-eigene Previewer |

---

## 8. Sollte es ein „Bundle"/„Image-Suite"-Plugin geben?

### 8.1 Kurzantwort

**Ja, aber als dünne Suite, nicht als Monolith. Vorher lohnt sich eine Konsolidierung in lib.nvim.**

### 8.2 Warum kein Monolith

- Die Plugins sind eigenständig nützlich: gopath, language, pickers, open haben keinen Bildbezug oder einen sehr kleinen. Ein Monolith würde (ohne lib.nvim) über 100k Zeilen Beta-Code koppeln.
- Alle sind Beta, ohne Versionen. Ein Bundle würde Breaking Changes über Plugin-Grenzen multiplizieren.
- Die Kopplung ist schon jetzt weich (pcall) und ehrlich dokumentiert. Das ist eine Stärke.
- Der Aufwand wäre nicht das Zusammenlegen, sondern das Auflösen der Duplikate. Das geht in lib.nvim billiger.

### 8.3 Was eine Suite konkret leisten würde

Das Muster gibt es schon zweimal in kleinem Maßstab: `lib.nvim.deps` mit `:Lib deps status` (suite-weite Werkzeugsicht) und `docs/install.json` pro Plugin.

1. **Ein lazy.nvim-Spec / Profile:** `minimal` (images + lib), `browse` (+ pickers, filetree, open), `docs` (+ markdown, hover, pdfport, media), `full`. Ein Eintrag statt zehn.
2. **Ein Health/Selftest über alles:** `:ImageSuite health` merged die Einzel-Healths und `deps status` und führt den **Ende-zu-Ende-Test** aus (Abschnitt 2.5). Genau das fehlt heute allen drei Konkurrenten und dir.
3. **Eine gemeinsame Konfiguration** für die querschnittlichen Defaults: Endungsliste, Remote-Policy, Cache-Wurzel, Provider-Reihenfolge. Heute sind das ≥4 abweichende Kopien.
4. **Verdrahtung der Integrationspunkte:** Kontextmenü-Provider registrieren, `hover.registry`-Beiträge, Picker-Preview, Tree-Preview. Ein Ort statt sieben `pcall(require, …)`-Stellen.
5. **Ein Kompatibilitäts-Vertrag:** eine versionierte `images.api` (v1) statt „by shape" (`pickers/integrations/images/init.lua:71-87`, gopath „older checkout"). Damit werden Tags möglich.

### 8.4 Was vorher in lib.nvim gehört (sonst überdeckt die Suite nur Duplikate)

| Baustein | Begründung |
| --- | --- |
| **Terminal-Capability-Modul** (Env + XTVERSION + optional Probe, memoisiert) | 4 Kopien im Verbund; genau der Punkt, an dem die Konkurrenz scheitert |
| **`media_kinds`** (Endungen → image/pdf/video/audio/office, einmal) | ≥6 abweichende Tabellen |
| **Ein System-Opener** (Schemes korrekt, Windows-Pfade, WSL) | 5 Kopien; Fund 3 |
| **Tool-Erkennung mit Suchpfaden** (`executable.find` + `paths` aus `install.json`) | 5+ Varianten |
| **Binär-Datei-Cache mit TTL/Größenlimit** | fehlt; ≥4 eigene Cache-Wurzeln, teils unbegrenzt |
| **Sicherer Fetch** (`--proto =http,https`, `--max-redirs`, Private-IP-Sperre, Größenlimit) | drei verschiedene curl-Aufrufe; die SSRF-Lücke schließt man einmal |
| **`rasterize.args`/PDF-Seite→PNG mit Cache und Timeout** | 3 pdftoppm-Kopien |
| **Windows-sichere Prozessaufrufe** (Quoting für PowerShell/cmd) | Funde 1, 2, 7 |

### 8.5 Vorschlag zur Reihenfolge

| Phase | Inhalt | Aufwand (grob) |
| --- | --- | --- |
| **P0** | Sicherheitsfunde 1, 2, 3 beheben; images.nvim-Doku an den Code angleichen oder Probe bauen; Ordnungs-Bug fixen | klein |
| **P1** | Spike: XTVERSION + Cursor-Vorschub-Probe für images.nvim (Abschnitt 2.5), `:Image selftest` | mittel |
| **P2** | lib.nvim-Konsolidierung (Tabelle 8.4), zuerst Capability + Opener + `media_kinds` | mittel–groß |
| **P3** | Kontextmenü: Kontextobjekt + Provider-Registry, die beiden Menü-Stacks (lib vs ui.nvim) zusammenführen | mittel |
| **P4** | Suite-Repo (Spec-Profile, gemeinsamer Health, gemeinsame Config), `images.api` v1 + Tags | klein–mittel, sobald P2/P3 stehen |

Hinweis zum Namen: ein neues Repo braucht einen Namen, der nicht mit `images.nvim` kollidiert (z. B. `imagesuite.nvim`). Das ist reine Konvention und dir überlassen.

### 8.6 Alternativen und Grenzen

- **Nichts tun:** funktioniert, aber jede neue Integration wiederholt das `pcall`-Muster, und Diagnose bleibt verstreut.
- **Nur lib.nvim konsolidieren, keine Suite:** räumt den größten Teil der Duplikate weg. Es fehlen der Ein-Klick-Install und der gemeinsame Selftest.
- **Auf snacks.image aufsetzen statt eigenes Rendering:** unter Windows-WezTerm nicht tragfähig (Abschnitt 2), solange die APC-Frage offen ist. Die Kitty-Plugins sind der Weg, falls du später nach WSL2 oder ein Kitty-fähiges Terminal wechselst. Dann wäre der `image_preview`-Provider-Wrapper in lib schon die richtige Abstraktion.
- **Ehrliche Grenze dieses Berichts:** Ich habe **nicht** in einem echten Terminal getestet. Alle Aussagen zum Rendering (APC kommt nicht an, OSC 1337 geht) stützen sich auf deine eigene Doku und Code-Lesung.

---

## 9. Nicht verifiziert und offene Fragen

- Ob Kitty-APC aus nvim.exe in WezTerm/ConPTY wirklich nie ankommt (Herstellerbehauptung im eigenen Plugin) und ob `wezterm imgcat` oder echte Kitty-Sequenzen getestet wurden.
- WezTerm-Default von `enable_kitty_graphics`: der snacks-Agent liest `default_true` aus `config.rs` im Tag 20240203 (moderat verlässlich); der image.nvim-Agent erinnerte sich an `false` (UNVERIFIED). In deiner WezTerm-Config ist die Option nirgends gesetzt.
- tmux-Verhalten (DCS-Passthrough) und OSC-1337-Unterstützung konkreter Konsole-/Ghostty-/Warp-Versionen.
- curl `--max-filesize` bei fehlendem Content-Length; wget `-Q` bei Einzeldatei; Redirect-Defaults.
- ImageMagick: SVG-/MSL-Delegate-Risiken in deiner Scoop-Policy; EXIF-Thumbnails bei `redact` ohne `-strip`.
- Ob `trans` (language.nvim) bei dir ein `.cmd`-Shim ist; Explorer-Verhalten beim `explorer.exe … 1`-Extra-Argument; ob beide Menü-Stacks gleichzeitig laden.
- Ob `TermResponse` APC-/CPR-Antworten an Lua liefert (Voraussetzung für die Ideen in 2.5).
- Issue-Themen von 3rd/image.nvim nur oberflächlich (WebFetch); Issue #332 nennt `ioctl` als Grund, die Antworten waren nicht abrufbar.

---

## Anhang: Quellen

- Rohberichte: [`Detail/snacks.md`](Detail/snacks.md), [`Detail/image_nvim_3rd.md`](Detail/image_nvim_3rd.md), [`Detail/images_nvim.md`](Detail/images_nvim.md), [`Detail/eco_hover_pdfport_media.md`](Detail/eco_hover_pdfport_media.md), [`Detail/eco_markdown_gopath_lib_pickers.md`](Detail/eco_markdown_gopath_lib_pickers.md), [`Detail/eco_filetree_open_language_menu.md`](Detail/eco_filetree_open_language_menu.md)
- Extern (von den Agents gelesen, nicht von mir im Terminal verifiziert): WezTerm Issue #5757 „Kitty image protocol doesn't work on Windows"; 3rd/image.nvim Discussion #93 (Windows) und Issue #332; WezTerm `config.rs`/`apc.rs` @20240203.
