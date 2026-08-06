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
| `:Image paste` | — | Bild aus der Zwischenablage ablegen und verlinken |
| `:Image screenshot` | — | Bildschirmausschnitt interaktiv aufnehmen und verlinken — spart die Zwischenablage als Zwischenschritt |
| `:Image replace [path]` | — | Bestehendes Bild durch Zwischenablage ersetzen, Link bleibt gleich |
| `:Image export [path]` | — | Bild als PDF exportieren, neben der Quelldatei (braucht ImageMagick) |
| `:Image redact [path]` | — | Zensur-Modus: Boxen markieren (Visual-Mode + `<CR>`), `w` schwärzt in eine neue Datei (braucht ImageMagick) |
| `:Image orphans` | — | Unverlinkte Bilder in `paste.dir` finden, mit Bestätigung löschen |
| `:Image pickers [cfile\|cwd\|path] [dir]` | — | Bilder unterhalb eines Scopes durchsuchen, Live-Vorschau mit snacks.picker |
| `:Image compare [cfile\|cwd\|path] [dir]` | — | Zwei Bilder auswählen, in echter relativer Größe vergleichen (braucht ImageMagick; sonst gleich groß nebeneinander) |
| `:Image zen [path]` | — | Bild groß in einem editierbaren Fenster zeigen (kein Preview-Float) |
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

- **`:Image paste`** ist der Alltagsfall für Support-Dokumentation:
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

  **außer bei SVG, `:Image export` und `:Image redact`.** WezTerm dekodiert
  PNG/JPEG/GIF/WebP/BMP selbst, aber kein SVG. `.svg` wird deshalb vor dem
  Zeichnen automatisch nach PNG konvertiert (`images.convert`, `magick
  datei.svg -background none out.png`, Cache in
  `stdpath("cache")/images.nvim/svg` benannt nach Pfad+mtime). `:Image
  export` exportiert umgekehrt ein Bild als PDF neben der Quelldatei
  (`bild.png` → `bild.pdf`, `magick datei.png out.pdf`, kein Cache —
  einmaliger Export statt wiederholtem Zeichenpfad). `:Image redact`
  schwärzt Rechtecke in einer neuen Datei (`magick bild.png -fill black
  -draw "rectangle …" bild.redacted.png`), ebenfalls kein Cache. Alle drei
  ohne Terminal-native Alternative — ohne ImageMagick kommt in jedem Fall
  ein klarer Fehler statt eines stillen Fehlschlags. Das sind bewusst die
  einzigen drei Fälle, in denen ImageMagick Voraussetzung statt Zugabe ist.

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
