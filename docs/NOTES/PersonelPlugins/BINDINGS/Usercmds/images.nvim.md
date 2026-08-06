# images.nvim — `:Image [subcommand]` Cheatsheet

Ein Verb über `lib.nvim.usercmd.composer`. Bare `:Image` ohne Subcommand zeigt
das Bild unter dem Cursor — der häufigste Fall braucht kein Schlüsselwort.

Source: `lua/images/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `docs/ROADMAP/`, `README.md`, `doc/images.txt`

| Command | Range | Effect |
| --- | --- | --- |
| `:Image` | — | Bild unter dem Cursor anzeigen (Markdown-Link oder Dateiname) |
| `:Image show [path]` | — | `path` anzeigen; ohne Argument wie bare `:Image` |
| `:Image list` | ja | Bildlinks des Buffers sammeln und eines auswählen |
| `:'<,'>Image list` | ja | …beschränkt auf die Selektion |
| `:Image gallery [cols]` | — | Alle Bilder des Buffers nebeneinander im Raster |
| `:Image next` | — | Zum nächsten Bild springen und es zeigen |
| `:Image prev` | — | Rückwärts; beide laufen um |
| `:Image info [path]` | — | Format, Abmessungen, Dateigröße |
| `:Image paste` | — | Bild aus der Zwischenablage ablegen und verlinken |
| `:Image replace [path]` | — | Bestehendes Bild durch Zwischenablage ersetzen, Link bleibt gleich |
| `:Image orphans` | — | Unverlinkte Bilder in `paste.dir` finden, mit Bestätigung löschen |
| `:Image pickers [cfile\|cwd\|path] [dir]` | — | Bilder unterhalb eines Scopes durchsuchen, Live-Vorschau mit snacks.picker |
| `:Image compare [cfile\|cwd\|path] [dir]` | — | Zwei Bilder aus einem Scan auswählen, nebeneinander vergleichen |
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

- **`:Image info`** zeigt Abmessungen nur mit ImageMagick; ohne bleiben Größe
  und Änderungsdatum. ImageMagick ist bewusst nirgends Voraussetzung.

- **Kein Inline-Rendering**: Bilder liegen über dem Text und verschwinden bei
  der nächsten Cursorbewegung (außer nach `:Image pin`). Echtes Inline setzt
  Unicode-Placeholders voraus, die nur Kitty und Ghostty können; beide gibt es
  für Windows nicht.

- **`:Image pickers`/`:Image compare`** durchsuchen das Dateisystem selbst
  (anders als `list`, das nur Bildlinks *im Buffer* sammelt) — mit
  Live-Vorschau über `snacks.picker`, falls installiert, sonst ein einfacher
  `vim.ui.select`-Fallback ohne Vorschau. `<Tab>` multi-selektiert in snacks;
  mehr als eine Auswahl zeigt eine Galerie statt eines Einzelbilds.

- **`:Image zen`** öffnet ein echtes, editierbares Fenster (`lib.nvim.window.
  make_scratch`) statt eines Preview-Floats — bleibt bestehen, auch wenn
  daneben ein snacks-Hover-Popup aufgeht, das an Fokusverlust gekoppelt wäre.

- 2026-08-06: Sheet war seit der ersten Fassung veraltet — `replace`,
  `orphans`, `pickers`, `compare`, `zen` und `check` fehlten komplett (das
  Plugin ist seither um diese Subcommands gewachsen). Bei der
  Checklisten-Runde gegen `bindings/usrcmds.lua` und `docs/BINDINGS.md`
  nachgezogen.
