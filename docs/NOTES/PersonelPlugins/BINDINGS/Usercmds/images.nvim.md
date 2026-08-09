# images.nvim — `:Image [subcommand]` Cheatsheet

Ein Verb über `lib.nvim.usercmd.composer`. Bare `:Image` ohne Subcommand zeigt
das Bild unter dem Cursor — der häufigste Fall braucht kein Schlüsselwort.

Source: `lua/images/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `docs/ROADMAP/`, `README.md`, `doc/images.txt`

| Command | Range | Effect |
| --- | --- | --- |
| `:Image` | — | Bild unter dem Cursor anzeigen (Markdown-Link oder Dateiname) |
| `:Image show [path]` | — | `path` anzeigen (auch eine URL bei `display.remote.enabled`); ohne Argument wie bare `:Image` |
| `:Image list` | ja | Bildlinks des Buffers sammeln und eines auswählen |
| `:'<,'>Image list` | ja | …beschränkt auf die Selektion |
| `:Image gallery [cols]` | — | Alle Bilder des Buffers nebeneinander im Raster |
| `:Image next` | — | Zum nächsten Bild springen und es zeigen |
| `:Image prev` | — | Rückwärts; beide laufen um |
| `:Image info [path]` | — | Format, Abmessungen, Dateigröße |
| `:Image paste [name]` | — | Bild aus der Zwischenablage ablegen und verlinken; mit `name` direkt benannt statt Abfrage/Template |
| `:Image screenshot` | — | Bildschirmausschnitt interaktiv aufnehmen und verlinken — spart die Zwischenablage als Zwischenschritt |
| `:Image replace [path]` | — | Bestehendes Bild durch Zwischenablage ersetzen, Link bleibt gleich |
| `:Image export [path]` | — | Bild als PDF exportieren, neben der Quelldatei (über pdfport.nvim, falls installiert, sonst braucht ImageMagick) |
| `:Image redact [path]` | — | Zensur-Modus: Boxen markieren (Visual-Mode + `<CR>`), `w` schwärzt in eine neue Datei (braucht ImageMagick) |
| `:Image orphans` | — | Unverlinkte Bilder in `paste.dir` finden, mit Bestätigung löschen |
| `:Image pickers [cfile\|cwd\|path] [dir]` | — | Bilder unterhalb eines Scopes durchsuchen, Live-Vorschau mit snacks.picker |
| `:Image compare [cfile\|cwd\|path] [dir]` | — | Zwei Bilder auswählen, in echter relativer Größe vergleichen (braucht ImageMagick; sonst gleich groß nebeneinander) |
| `:Image zen [path]` | — | Bild groß in einem editierbaren Fenster zeigen (kein Preview-Float) |
| `:Image draw <position> [path]` | — | Bild an einer benannten Position im aktuellen Fenster zeichnen ("full" oder eine von acht Ecken/Kanten), auch als `images.draw()` |
| `:Image pin` | — | Anzeige festhalten statt bei Cursorbewegung aufzuräumen |
| `:Image check` | — | Terminal-Fähigkeit neu prüfen und melden |
| `:Image clear` | — | Angezeigte Bilder entfernen, Pin lösen, offenes Zen-Fenster schließen |

Der Command-Name folgt der Option `command`.

## Notes

- **Warum nicht snacks.image**: snacks.image und image.nvim sprechen
  ausschließlich Kitty-APC. Auf nativem Windows-Neovim in WezTerm werden
  Kitty-Sequenzen, die aus Neovim kommen, nie gezeichnet — dieselben Sequenzen
  funktionieren aus einer rohen Shell. images.nvim nutzt OSC 1337.

- **Range nur bei `list`**: Die anderen Subcommands arbeiten auf einer
  einzelnen Position oder dem ganzen Buffer, wo ein Range keine Bedeutung
  hätte.

- **`:Image list`** nutzt das UI-Kit aus lib.nvim, wenn vorhanden, sonst
  `vim.ui.select`. Bei genau einem Treffer wird direkt angezeigt statt einen
  Picker mit einem Eintrag zu öffnen.

- **`:Image gallery`** deckelt die Spaltenzahl automatisch auf vier — darüber
  werden die Kacheln in einem üblichen Terminal zu schmal. Bei zu wenig Platz
  kommt eine Meldung statt unlesbarer Miniaturen.

- **`:Image paste [name]`** ist der Alltagsfall für Support-Dokumentation:
  Screenshot machen, Command ausführen, das PNG landet unter
  `assets/<dokument>-<zeitstempel>.png` und `![](assets/…)` steht an der
  Cursorposition. Braucht Bilddaten in der Zwischenablage — eine *kopierte
  Datei* genügt nicht.

  Mit `paste.ask_filename = true` fragt es vorher nach einem Namen
  (vorbelegt mit dem Template-Namen); ein eingegebener Pfadanteil wird
  verworfen, die Endung immer auf `.png` erzwungen. Anders als bei
  `paste.ask_alt_text` bricht ein Abbruch hier den ganzen Vorgang ab — an
  dieser Stelle wurde noch nichts aus der Zwischenablage gelesen, ein Abbruch
  bedeutet also wirklich "nichts tun". Beide Abfragen sind default `false`,
  damit der schnelle Fall ohne Unterbrechung bleibt.

  `:Image paste {name}` (das optionale Argument) sanitisiert `{name}` genauso
  wie die Abfrage und verwendet es direkt — überspringt sowohl die
  interaktive Abfrage als auch `paste.ask_filename`, weil ein am Aufruf schon
  mitgegebener Name nichts mehr zu erfragen übrig lässt.

  Zielverzeichnis: existiert im Dokumentverzeichnis bereits ein Ordner namens
  `Resources` oder `Ressourcen` (case-insensitiv, `paste.existing_dir_names`),
  wird dieser statt `paste.dir` verwendet — kein zweiter, paralleler
  `assets`-Ordner. Und: die Zielverzeichnis-Auflösung (inkl. `mkdir`) läuft
  jetzt erst NACH einer erfolgreichen Aufnahme, nicht mehr davor — vorher legte
  `:Image paste` bei leerer Zwischenablage trotzdem ein leeres `assets`
  an, weil `target_paths()` vor dem eigentlichen Zwischenablage-Lesen lief.
  Betrifft auch `:Image screenshot` (teilt denselben Pfad) — ein abgebrochener
  Screenshot (`<Esc>`) legt jetzt ebenfalls kein Verzeichnis mehr an.

- **`:Image screenshot`** nimmt die Bildschirmauswahl selbst auf, statt die
  Zwischenablage zu lesen — sonst identisch zu `:Image paste` (Zielpfad,
  Namens-/Alt-Text-Abfrage, Link). Durchgehend asynchron: `vim.system(...)
  :wait()` würde Neovims Event-Loop für die gesamte interaktive Auswahl
  blockieren (Sekunden bis zu einer Minute) — dasselbe Prinzip wie
  `lib.nvim.system.job`, das aus genau diesem Grund nie `:wait()` nutzt.

  Plattformen: macOS `screencapture -i` und Linux `grim`+`slurp`/`maim -s`
  schreiben direkt in die Zieldatei, synchron genug über den async
  `vim.system`-Callback abzuwarten. Windows ist unsicherer — es gibt keinen
  dokumentierten Weg, das moderne Snipping-Tool (`ms-screenclip:`) direkt in
  eine Datei schreiben zu lassen, nur in die Zwischenablage, ohne
  Fertig-Signal. Der Windows-Pfad startet das Tool und pollt die
  Zwischenablage per `vim.uv.new_timer()` (nicht blockierend) auf ein
  *neues* Bild, mit Timeout (`display.screenshot.windows_*`). Die Polling-/
  Vergleichslogik wurde manuell gegen eine künstlich zeitversetzt
  geänderte Zwischenablage verifiziert (Änderung nach 2s korrekt bei Tick 5
  erkannt); `ms-screenclip:` selbst live durchzuklicken war nicht
  automatisierbar (öffnet eine echte Auswahl-Oberfläche, keine Maus
  verfügbar) — `:Image paste` bleibt der unveränderte Fallback.

- **`:Image info`** zeigt Abmessungen nur mit ImageMagick; ohne bleiben Größe
  und Änderungsdatum. ImageMagick ist bewusst nirgends Voraussetzung —

  **außer bei SVG und `:Image redact`; `:Image export` seit 2026-08-09 nur
  noch OHNE pdfport.nvim.** WezTerm dekodiert
  PNG/JPEG/GIF/WebP/BMP selbst, aber kein SVG. `.svg` wird deshalb vor dem
  Zeichnen automatisch nach PNG konvertiert (`images.convert`, `magick
  datei.svg -background none out.png`, Cache in
  `stdpath("cache")/images.nvim/svg` benannt nach Pfad+mtime). `:Image
  export` exportiert umgekehrt ein Bild als PDF neben der Quelldatei
  (`bild.png` → `bild.pdf`) — über pdfport.nvim (asynchron, verlustfrei),
  falls installiert, sonst `magick datei.png out.pdf`; kein Cache in beiden
  Fällen — einmaliger Export statt wiederholtem Zeichenpfad. `:Image redact`
  schwärzt Rechtecke in einer neuen Datei (`magick bild.png -fill black
  -draw "rectangle …" bild.redacted.png`), ebenfalls kein Cache. Alle drei
  ohne Terminal-native Alternative — ohne ImageMagick kommt in jedem Fall
  ein klarer Fehler statt eines stillen Fehlschlags. Der ASCII-Fallback
  (`images.ascii`, siehe unten) ist der vierte, aus demselben Grund:
  Pixelfarben lassen sich ohne echten Decoder nicht lesen. Das sind bewusst
  die einzigen vier Fälle, in denen ImageMagick Voraussetzung statt Zugabe
  ist.

- **ASCII-Fallback (`display.ascii_fallback`, `images.ascii`)**: Wenn die
  Terminal-Fähigkeitsprüfung fehlschlägt, zeichnen `:Image show`/Hover eine
  farbige Blockgrafik statt der wirkungslosen OSC-1337-Sequenz — jede Zelle
  ein "█" mit eigener Truecolor-Vordergrundfarbe (`nvim_set_hl` + Extmarks),
  gesampelt via ImageMagick (`magick … -resize WxH! -alpha off -depth 8
  RGB:-`), nicht ein Helligkeits-Zeichensatz. Braucht ImageMagick zwingend —
  vierte bewusste Ausnahme neben SVG/`:Image export`/`:Image redact`. Ohne
  ImageMagick oder mit `display.ascii_fallback.enabled = false` bleibt das
  bisherige Verhalten (Warnung einmal pro Sitzung, Zeichenversuch trotzdem).
  Nur der Einzelbild-Pfad (`show`/Hover), dieselbe Scope-Grenze wie bei
  Remote-Bildern — `gallery`/`compare`/`pickers`/`zen` bekommen es (noch)
  nicht. Ursprünglich als `docs/ROADMAP/CROSS-PLUGIN.md`-Idee mit
  color_my_ascii.nvim als Färbe-Backend angedacht; dessen Highlighter färbt
  aber Muster-basiert bekannte Zeichenklassen gegen ein Schema, nicht
  beliebige Pixel-RGB pro Zelle — passt architektonisch nicht, deshalb ein
  eigener Pfad ohne die Abhängigkeit.

- **Kein Inline-Rendering**: Bilder liegen über dem Text und verschwinden bei
  der nächsten Cursorbewegung (außer nach `:Image pin`). Echtes Inline setzt
  Unicode-Placeholders voraus, die nur Kitty und Ghostty können; beide gibt es
  für Windows nicht.

  Mit `display.hover_mode = "float"` erscheint das Bild stattdessen in einem
  kleinen, unfokussierten Floating-Window unter dem Cursor —
  `images.hover_float`, dieselbe Technik wie `:Image zen` (Fenster öffnen,
  dann an dessen eigener Geometrie zeichnen), nur cursor-positioniert statt
  zentriert und klein statt groß. Betrifft nur `:Image show`/Hover, nicht
  die Galerie. Default bleibt `"overlay"` (das bisherige Verhalten
  unverändert) — die Technik war über `:Image zen` bereits belegt
  funktionsfähig, das Float ist eine Parametrisierung davon, kein neues
  Risiko.

- **Remote-Bilder (`http(s)://…`)** unterstützt `:Image show <url>` und
  Hover, aber `display.remote.enabled` steht default auf `false` — ein
  Hover über einen Remote-Link soll nicht ungefragt eine Netzwerkanfrage
  auslösen, dasselbe Prinzip wie "externe Bilder laden" in E-Mail-Clients.
  Download gecacht in `stdpath("cache")/images.nvim/remote`, benannt nach
  URL-Hash. `:Image list`/`gallery`/`next`/`prev`/`orphans` (Bulk-Scan) lösen
  Remote-Links bewusst NICHT auf — sonst würde ein bloßes Auflisten der
  Bilder eines Buffers N Netzwerkanfragen auslösen. Auch `gallery`/`compare`/
  `pickers`/`zen` unterstützen Remote-Bilder (noch) nicht, nur der
  Einzelbild-Pfad (`show`/Hover) tut es.

- **`:Image pickers`/`:Image compare`** durchsuchen das Dateisystem selbst
  (anders als `list`, das nur Bildlinks *im Buffer* sammelt) — mit
  Live-Vorschau über `snacks.picker`, falls installiert, sonst ein einfacher
  `vim.ui.select`-Fallback ohne Vorschau. `<Tab>` multi-selektiert in snacks;
  mehr als eine Auswahl zeigt eine Galerie statt eines Einzelbilds.

- **`:Image zen`** öffnet ein echtes, editierbares Fenster (`lib.nvim.window.
  make_scratch`) statt eines Preview-Floats — bleibt bestehen, auch wenn
  daneben ein snacks-Hover-Popup aufgeht, das an Fokusverlust gekoppelt wäre.
  Genau daran hing ein Bug: Fenster auf, Bild im selben Tick hineingezeichnet,
  Neovim malt danach die leeren Zellen des Fensters darüber — Popup da, Bild
  weg. `images.terminal.draw` erzwingt jetzt den ausstehenden Repaint, bevor
  die Payload rausgeht; das gilt für jeden Zeichenpfad, nicht nur zen.

- **`:Image redact`** löst einen echten Konflikt: ein per OSC 1337
  gezeichnetes Bild ist für Neovim nicht interaktiv, Maus/Cursor liefern nur
  Zellkoordinaten, nie Pixelkoordinaten im Bild. Lösung: die Auswahl
  passiert komplett in Zellen, über echten Neovim-Visual-Mode auf einem mit
  Leerzeichen gefüllten Scratch-Buffer in Bildgröße (`v`/`<C-v>` + `<CR>`
  markiert eine Box, `u` entfernt die letzte, `w` brennt via ImageMagick und
  speichert als `bild.redacted.png`, Original bleibt unangetastet). Damit
  `preserveAspectRatio=1` beim Zeichnen kaum noch etwas letterboxen muss,
  wählt `images.scale.fit_cells` die Zeichenbox passend zum
  Bildseitenverhältnis, über eine angenommene, dokumentierte
  Zellbreite/-höhe (`images.scale.CELL_ASPECT = 0.5`, keine echte
  Zellmessung). Der verbleibende Fehler wird nicht weggerechnet, sondern
  über eine Sicherheitsmarge absorbiert (`display.redact.padding_cells`,
  Default 1 Zelle) — jede Box wächst vor dem Brennen nach außen, nie nach
  innen: lieber zu viel geschwärzt als zu wenig. Volles Konzept inklusive
  der ursprünglich offenen Fragen: `docs/ROADMAP/REDACT.md`. Auslöser war
  casedesk (`Ressources/`-Anhänge mit Kundendaten, die vor einer künftigen
  KI-Übergabe unkenntlich gemacht werden müssen).

- **`:Image compare`s relative Skalierung**: Mit ImageMagick bekommt das
  kleinere der beiden Bilder (verglichen über die Pixeldiagonale) eine
  proportional kleinere, zentrierte Box statt seine Hälfte zu füllen — sonst
  sähen ein Icon und ein großes Foto gleich groß aus. Dafür wurde
  `lib.nvim.ui.kit.compare` um einen `on_compare(a, b)`-Hook ergänzt, der
  einmalig vor beiden `render`-Aufrufen mit beiden Bildern zugleich feuert —
  der einzige Punkt im bisherigen Vertrag, an dem `render(item, surface)`
  seinen Vergleichspartner noch nicht kannte. Reine Berechnung in
  `images.scale`, ohne Terminal testbar.

- **`:Image draw`/`images.draw()`** ist die eine kanonische Stelle für "Bild
  zuverlässig in einem Fenster (oder dem Fenster, das einen Buffer zeigt) an
  einer benannten Position zeichnen" — `images.anchor.draw(target, position,
  file, opts)`. `target`: Fenster-Handle, Buffer-Handle (aufgelöst auf ein
  Fenster, das ihn zeigt) oder nil/0 für das aktuelle Fenster. `position`:
  `"full"` (füllt das Fenster) oder eine der acht Ecken/Kanten
  (`"top-left"`, `"center"`, `"bottom-right"`, …), die eine skalierte,
  zentrierte Box an diesem Anker platzieren statt das ganze Fenster zu
  füllen (`images.scale.anchor_box`, ersetzt das frühere `images.scale.box`).
  `opts.defer = true` verschiebt das Zeichnen per `vim.schedule` auf den
  nächsten Tick — nötig, wenn `target` im selben Aufruf erst geöffnet wurde
  (siehe unten, derselbe Fehler wie beim ursprünglichen `:Image zen`-Bug).
  `opts.on_done(ok, err)` läuft garantiert genau einmal, synchron oder
  verzögert. `:Image zen`, der Hover-Float, `:Image redact` und die
  Picker-Vorschau (`images.browse`) bauten das Muster vorher jeweils
  unabhängig nach — mit leicht unterschiedlicher Sorgfalt, nur drei der vier
  hatten den `vim.schedule`-Fix. Alle vier laufen jetzt über `images.anchor`;
  `images.browse.draw_in_window()` bleibt als namensgleicher Wrapper
  bestehen, weil markdown.nvim das bereits als API konsumiert.

## Changelog

- 2026-08-09 (2): `:Image draw`/`images.draw()` ergänzt (siehe oben,
  `images.anchor`, `images.scale.anchor_box`). Konsolidiert eine vierfach
  unabhängig nachgebaute Stelle (`zen`, `hover_float`, `redact`,
  `browse`s Picker-Vorschau) in ein einziges, getestetes Modul —
  `images.scale.box` (nur zentriert) wurde dabei durch das allgemeinere
  `anchor_box` (neun benannte Positionen + "full") ersetzt, sein einziger
  bisheriger Aufrufer (`browse.draw_in_window`) ist jetzt selbst ein
  dünner Wrapper um `images.anchor.draw`. Neue Tests: `TESTS/anchor_spec.lua`
  (Fenster-/Buffer-Auflösung, defer/sofort-Timing per `nvim_ui_send`-Mock,
  dieselbe Technik wie `terminal_draw_spec.lua`).
- 2026-08-09: `:Image export`/`images.convert.to_pdf` bekamen eine
  pdfport.nvim-Weiche (soft dep, `pcall`'d): ist pdfport installiert und
  meldet `can_create("image")` einen Producer, läuft der Export asynchron
  darüber (verlustfrei via `img2pdf`, sonst `magick` — welcher Producer
  greift, entscheidet pdfports eigene `create_chain`, nicht images.nvim
  selbst). Ohne pdfport.nvim bleibt der bisherige synchrone `magick`-Pfad
  unverändert. `to_pdf()` bekam dafür ein `on_done(ok, out_or_err)`-Callback
  als einzigen verlässlichen Weg, das Ergebnis über beide Pfade einheitlich
  zu beobachten — der Rückgabewert allein reicht seither nicht mehr (der
  pdfport-Pfad liefert synchron `nil, nil`). Aus pdfport.nvims eigenem
  `docs/ROADMAP/PDF_CREATE.md` (P2, Aufrufer-Anbindung).
- 2026-08-06: Sheet war seit der ersten Fassung veraltet — `replace`,
  `orphans`, `pickers`, `compare`, `zen` und `check` fehlten komplett (das
  Plugin ist seither um diese Subcommands gewachsen). Bei der
  Checklisten-Runde gegen `bindings/usrcmds.lua` und `docs/BINDINGS.md`
  nachgezogen.
- 2026-08-06 (2): `:Image compare` um die relative Skalierung ergänzt (siehe
  oben), inklusive Ergänzung in `lib.nvim.ui.kit.compare`.
- 2026-08-06 (3): `paste.ask_filename` ergänzt (siehe oben). Dabei einen
  echten Bug in der Alt-Text-Abfrage gefunden und behoben: ohne `on_cancel`
  ruft `kit.input` bei `<Esc>` gar nichts auf, der Link wurde bei Abbruch also
  nie eingefügt und das Bild blieb verwaist auf der Platte — der Code
  widersprach damit dem eigenen Kommentar, der das Gegenteil behauptete.
- 2026-08-06 (4): SVG-Unterstützung ergänzt (siehe oben, `images.convert`).
  Dabei fiel auf, dass `:checkhealth images` nie geprüft hat, ob ImageMagick
  überhaupt installiert ist, obwohl `:Image info`/`compare` schon lange davon
  abhingen — eine `check_imagemagick()`-Prüfung nachgezogen.
- 2026-08-06 (5): Remote-Bilder ergänzt (siehe oben, `images.remote`). Dafür
  einen neuen Composer-Argtyp `IMAGE_TARGET` gebraucht: das eingebaute `FILE`
  validiert über `filereadable`, was jede URL als "keine lesbare Datei"
  abgelehnt hätte, bevor `:Image show <url>` überhaupt lief. Der echte
  Download-Pfad wurde manuell gegen einen lokalen HTTP-Server verifiziert
  (byteidentisch, plus Cache-Hit bei totem Server) — das ist nicht Teil der
  committeten Testsuite, da ein echter Netzwerkzugriff dort nicht
  reproduzierbar wäre.
- 2026-08-06 (6): `:Image screenshot` ergänzt (siehe oben, `images.screenshot`).
  `images.paste`s bisher synchroner Zwischenablage-Lesevorgang wurde dabei auf
  einen einheitlichen `capture(out, callback)`-Vertrag umgestellt, den beide
  Befehle teilen — nötig, weil eine interaktive Bildschirmauswahl (Sekunden
  bis eine Minute) niemals blockierend abgewartet werden darf, ohne Neovim für
  diese Zeit einzufrieren. `:checkhealth images` bekam eine `grim`/`slurp`/
  `maim`-Prüfung nachgezogen, die vorher fehlte.
- 2026-08-06 (7): `display.hover_mode = "float"` ergänzt (siehe oben,
  `images.hover_float`). Zoom/Ausschnitt und mehrere gleichzeitige Pins aus
  der Roadmap gestrichen (nicht gebraucht).
- 2026-08-06 (8): `:Image export` ergänzt (siehe oben, `images.convert.
  to_pdf`) — die Gegenrichtung von `pdfport.nvim`s "PDF-Seite als Bild".
  Dabei den Cursor-oder-Pfad-Resolve, der in `replace` und `zen` schon
  identisch stand, als `images.resolve.path_or_cursor` zusammengezogen. Die
  Thumbnail-Leiste aus der Roadmap gestrichen (nicht gebraucht).
- 2026-08-06 (9): `:Image redact` ergänzt (siehe oben, `images.redact`,
  `images.scale.fit_cells`/`cell_box_to_pixels`, `images.convert.redact`) —
  Zensur-Modus für casedesk-Anhänge vor einer künftigen KI-Übergabe. Vorher
  als Konzept in `docs/ROADMAP/REDACT.md` ausgearbeitet (inkl. einer
  ursprünglich offenen "Anker"-Frage bei `preserveAspectRatio`, die sich bei
  der Umsetzung als Teil eines größeren, bewusst umgangenen Problems
  herausstellte — siehe dort §2.2/§3). "PDF-Seiten als Bild" (die
  Gegenrichtung von `:Image export`, über `pdfport.nvim`) von dieser
  Roadmap gestrichen — pdfport soll seine vorhandene, bisher private
  Rasterisierung stattdessen selbst als API anbieten, siehe
  `docs/ROADMAP/CROSS-PLUGIN.md` (Eintrag entfernt) und pdfport.nvims
  eigene `docs/ROADMAP.md`.
- 2026-08-07: ASCII-Fallback ergänzt (siehe oben, `images.ascii`,
  `display.ascii_fallback`) — erstes umgesetztes Item aus
  `docs/ROADMAP/CROSS-PLUGIN.md` (color_my_ascii.nvim-Abschnitt). Die dort
  angedachte color_my_ascii-Integration erwies sich beim Bauen als
  Fehlgriff (Muster-basierte Zeichenklassen-Färbung, keine beliebige
  Pixel-RGB pro Zelle) — stattdessen ein eigener Pfad über `nvim_set_hl`/
  Extmarks, ImageMagick-Sampling bleibt die einzige echte Abhängigkeit.
- 2026-08-07 (2): `:Image zen` zeigte ein leeres Popup — Bild wurde gesendet,
  aber sofort wieder überschrieben. Ursache war die Reihenfolge, nicht das
  Protokoll: `nvim_ui_send` schreibt sofort ans Terminal, Neovims eigener
  Repaint läuft erst beim Rücksprung in die Hauptschleife, also nach der
  Payload. Betraf jeden Pfad, der ein Fenster öffnet und im selben Tick
  hineinzeichnet (`zen`, `hover_float`, `redact`) — nicht aber `show`
  (zeichnet über bestehenden Text) oder `pickers`/`compare` (zeichnen in ein
  bereits gemaltes Fenster, aus einem späteren Callback). Fix sitzt deshalb
  in `images.terminal.draw`/`draw_many` statt bei den Aufrufern, mit
  Regressionstest (`TESTS/terminal_draw_spec.lua`).
- 2026-08-07 (3): Nachschlag — der Flush allein reichte nicht, danach
  rendeten nur noch die ersten Zeilen. Er räumt weg, was VOR dem Senden
  anstand; den Repaint, den das Öffnen des Fensters selbst einreiht,
  kann er nicht abfangen. `zen`/`hover_float`/`redact` zeichnen deshalb
  jetzt per `vim.schedule` erst im nächsten Tick, also nachweislich nach
  Neovims eigener Farbe. `show`/Hover bleiben synchron (kein Fenster,
  nichts malt darüber).
- 2026-08-07 (4): Drei `:Image paste`-Verbesserungen (User-Feedback nach
  echtem Gebrauch). Erstens ein echter Bug: bei leerer Zwischenablage
  entstand trotzdem ein leeres `assets`-Verzeichnis, weil `target_paths()`
  (inkl. `mkdir`) vor dem Zwischenablage-Lesen lief statt danach — jetzt
  schreibt `capture()` erst in eine Temp-Datei, das Zielverzeichnis wird nur
  bei Erfolg aufgelöst/angelegt und die Datei dorthin verschoben (betrifft
  auch `:Image screenshot`, teilt denselben Pfad). Zweitens
  `paste.existing_dir_names` (Default `{ "Resources", "Ressourcen" }`):
  existiert im Dokumentverzeichnis bereits so ein Ordner, wird der statt
  `paste.dir` verwendet, kein zweiter `assets` daneben. Drittens
  `:Image paste {name}` als optionales Argument — sanitisiert wie die
  `ask_filename`-Abfrage, überspringt aber jede Abfrage, weil der Name schon
  beim Aufruf feststeht. Neue Tests: `TESTS/paste_target_spec.lua` (Fake-
  `capture`, kein echtes Clipboard nötig — dieselbe Technik wie
  `orphans_spec.lua` für Dateisystem-Tests ohne Terminal).
- 2026-08-07 (5): Changelog in eine eigene Überschrift gezogen, per
  `docs/NOTES/BINDINGS-FORMAT.md`.
