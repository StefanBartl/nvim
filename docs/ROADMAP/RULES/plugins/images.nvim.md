# images.nvim

## Zweck
Zeigt Bilder direkt im Terminal-Neovim an (hover, gallery, zen, compare, redact/censor),
über das iTerm2-Protokoll (OSC 1337) statt des Kitty-Graphics-Protokolls, damit es auch auf
nativem Windows-Neovim in WezTerm funktioniert. Unterstützt Clipboard-Paste, Screenshot,
Remote-URLs (opt-in), ASCII-Fallback für nicht unterstützte Terminals, sowie einen
Redact-Modus zum Schwärzen von Bildbereichen. Quelle: README.md,
lua/images/terminal.lua, lua/images/remote.lua, lua/images/redact.lua,
lua/images/bindings/keymaps.lua.

## Nicht-standard Patterns / Algorithmen

1. `lua/images/terminal.lua` (gesamtes Modul, Header-Kommentar) + README "Why not
   snacks.image" — vier speziell gelernte Eigenheiten der Bildausgabe im Terminal: (a)
   Ausgabe über `vim.api.nvim_ui_send`, nicht `io.stdout:write` (letzteres zeichnet laut
   Kommentar nur einmal pro Terminal-Session); (b) Cursor wird vor dem Payload explizit
   gespeichert/positioniert (`ESC[s`/`ESC[<row>;<col>H`/Payload/`ESC[u`), sonst landet das
   Bild am unteren Rand und schiebt die Statusline hoch; (c) Breite/Höhe werden in
   Terminal-Zellen statt Pixeln angegeben (`preserveAspectRatio=1`), wodurch die
   Pixelgröße einer Zelle nie bekannt sein muss — genau der Punkt, an dem snacks.image auf
   Windows bricht (`ioctl(TIOCGWINSZ)` funktioniert dort nicht); (d) Zeichnen wird explizit
   gegen Neovims eigenen Repaint sequenziert: `nvim_ui_send` schreibt sofort, Neovim malt
   aber erst beim Rücksprung in den Main-Loop — jeder Pfad, der zuerst ein Fenster öffnet
   (`zen`, `hover_float`, `redact`), verzögert seinen Draw-Call daher explizit um einen Tick
   (`vim.schedule`), weil ein Flush *vor* dem Senden den Repaint durch das neue Fenster
   selbst nicht abdecken kann. WARUM: alle vier Punkte sind Terminal-Protokoll-Eigenheiten,
   die nicht aus der OSC-1337-Spezifikation direkt folgen, sondern nur durch Ausprobieren
   auf konkreten Terminal-Emulatoren gefunden wurden — direkt im Code als Warnung für
   künftige Änderungen dokumentiert.

2. `lua/images/terminal.lua:56-80` (`KNOWN`-Liste + Capability-Check) — da OSC 1337 keine
   Fähigkeitsabfrage kennt, wird die Terminal-Unterstützung heuristisch über bekannte
   Umgebungsvariablen erkannt (WezTerm/iTerm2/Konsole), einmal pro Session gecacht
   (`capability`). Ein unbekanntes Terminal löst nur einmal pro Session eine Warnung aus und
   zeichnet trotzdem weiter ("false negative must not break a working setup" laut README).
   WARUM: eine harte Blockade bei unbekanntem Terminal würde funktionierende, aber nicht
   gelistete Terminals unbenutzbar machen — die Heuristik bevorzugt bewusst falsch-negative
   Toleranz gegenüber falsch-positiver Blockade.

3. README "ASCII fallback" — wenn die Terminal-Prüfung fehlschlägt, fällt `:Image show`/hover
   auf eine Block-Zeichen-Darstellung zurück (volle `█`-Zellen mit True-Color-Vordergrund pro
   Zelle, direkt aus den Bildpixeln gesampelt) statt einer Helligkeits-Zeichen-Rampe
   (`" .:-=+*#%@"`), "the same technique graphics-protocol-less terminal viewers like
   chafa/viu use". WARUM: Farb-Sampling pro Zelle liefert bei einem Terminal ohne
   Graphics-Protokoll ein visuell deutlich brauchbareres Ergebnis als reine
   Helligkeits-ASCII-Kunst.

4. `lua/images/redact.lua` (Header-Kommentar + `confirm_box`/`write_redacted`) — da ein per
   OSC 1337 gezeichnetes Bild für Neovim nicht interaktiv ist (Maus/Cursor liefern nur
   Zell-, nie Pixelkoordinaten), findet die Box-Auswahl komplett in Neovims echtem
   Visual-Mode auf einem mit Leerzeichen gefüllten Scratch-Buffer in Bildgröße statt — kein
   eigenes Eingabesystem, keine Pixelmathematik während der Auswahl. Erst beim Schreiben
   (`w`) rechnet `images.scale.fit_cells`/`cell_box_to_pixels` einmalig von Zellen auf
   Pixelkoordinaten um, mit einer konfigurierbaren Sicherheitsmarge
   (`display.redact.padding_cells`). WARUM (Kommentar): "over-redacting is the safe failure
   mode, under-redacting is not" — bei einer Zensur-Funktion für sensible Daten ist ein zu
   großzügig geschwärzter Bereich ein akzeptabler Fehler, ein zu kleiner (Daten bleiben
   sichtbar) nicht.

5. `lua/images/remote.lua:60-103` (`M.fetch`) — Remote-Bild-Downloads sind (a) standardmäßig
   deaktiviert (`display.remote.enabled = false`), mit explizitem Vergleich zu E-Mail-Clients,
   die externe Bilder aus Datenschutzgründen blocken; (b) nur beim expliziten
   Einzelbild-Anzeigen aktiv, nicht beim bloßen Scannen/Auflisten (`:Image list`/`gallery`/
   `orphans`), damit ein Listing nicht N Netzwerkanfragen auslöst; (c) über
   `curl --max-time`/`--max-filesize` (bzw. `wget -Q`) mit konfigurierbarem Timeout und
   Byte-Limit begrenzt; (d) URL-gehasht gecacht (`vim.fn.sha256(url)`), damit derselbe Link
   nicht zweimal geladen wird; (e) bei Fehlschlag/leerer Datei wird die (Teil-)Datei aktiv
   gelöscht (`pcall(vim.uv.fs_unlink, out)`) statt eine kaputte Datei im Cache zu belassen.
   WARUM: jeder einzelne Punkt ist eine bewusste Sicherheits-/Ressourcen-Entscheidung
   gegen unerwünschten Netzwerk-Traffic bzw. unbegrenzten Download.

6. `lua/images/bindings/keymaps.lua:79-104` (`common_prefix`) — berechnet das längste
   gemeinsame Präfix aller konfigurierten Keymap-lhs, um automatisch eine
   which-key-Gruppenbezeichnung zu registrieren, auch wenn der Nutzer alle Tasten komplett
   umgemappt hat. Bricht explizit ab, wenn das errechnete Präfix selbst bereits eine
   vollständige Bindung ist ("würde als Gruppenname irreführend sein — which-key würde dann
   sowohl eine Aktion als auch eine Gruppe unter derselben Taste zeigen"). WARUM: vermeidet
   eine hartkodierte Gruppentaste (`<leader>i`), die bei Remapping falsch würde.

7. README "SVG/export/redact/ascii_fallback als vier bewusste ImageMagick-Ausnahmen" — das
   Plugin verfolgt sonst konsequent "kein ImageMagick als Pflicht", macht aber an genau vier
   dokumentierten Stellen eine Ausnahme (SVG-Rasterung, `:Image export`, `:Image redact`,
   ASCII-Fallback-Pixel-Sampling), weil diese vier Funktionen ohne Pixelzugriff/Rasterung
   fundamental nicht möglich sind. WARUM: explizite, dokumentierte Ausnahmeliste statt
   stillschweigend wachsender harter Abhängigkeiten — Guideline-würdiges Muster für
   optionale externe Tools.

## Abgeleitete Guidelines

1. Terminal-Escape-Sequenz-Eigenheiten (Schreibmethode, Cursor-Handling, Einheiten,
   Repaint-Reihenfolge), die durch Ausprobieren gefunden wurden, IMMER als Kommentar direkt
   im Code festhalten — nicht nur in der README —, damit ein künftiger Refactor sie nicht
   versehentlich rückgängig macht.
2. Bei Draw-Calls, die gegen Neovims eigenen Repaint antreten (Fenster wird im selben Tick
   geöffnet UND bemalt), das Zeichnen explizit per `vim.schedule` um einen Tick verzögern;
   Pfade ohne neues Fenster brauchen das nicht — diese Unterscheidung im Code kommentieren.
3. Capability-Detection für Protokolle ohne eigene Abfrage-Möglichkeit heuristisch über
   Umgebungsvariablen lösen, mit Session-Cache (einmal ermitteln) und einer
   Einmal-pro-Session-Warnung statt einer harten Blockade — falsch-negativ ist tolerierbar,
   falsch-positiv-Blockade eines funktionierenden Setups nicht.
4. Bei Zensur-/Sicherheits-relevanten Approximationen (Redact-Box, Blur-Radius, o.ä.)
   IMMER so runden/padden, dass der Fehler in Richtung "zu vorsichtig" ausschlägt, nie in
   Richtung "zu wenig geschützt".
5. Interaktive Pixel-genaue Auswahl in einem zellenbasierten Terminal-UI nicht simulieren —
   stattdessen echte Neovim-Editing-Primitive (Visual-Mode auf einem Scratch-Buffer)
   wiederverwenden und die Umrechnung in die Zieleinheit erst am Ende, einmalig, durchführen.
6. Jede Netzwerk-Funktionalität, die durch bloßes Öffnen/Hovern eines Dokuments ausgelöst
   werden könnte, standardmäßig deaktivieren (opt-in) und nur beim explizitesten
   Nutzer-Trigger aktiv werden lassen, nicht beim bloßen Scannen/Listen.
7. Downloads/externe Fetches immer mit Timeout UND Byte-Limit versehen (beides, nicht nur
   eins), URL-gehasht cachen, und bei Fehlschlag/leerem Ergebnis die Zieldatei aktiv wieder
   löschen statt sie kaputt liegen zu lassen.
8. Which-key-Gruppenbezeichnungen dynamisch aus den tatsächlich konfigurierten
   Keymap-lhs ableiten (längstes gemeinsames Präfix), statt eine feste Gruppentaste
   anzunehmen — bleibt auch nach vollständigem Remapping korrekt.
9. Optionale externe Tool-Abhängigkeiten (ImageMagick, curl/wget) als explizite,
   dokumentierte Ausnahmeliste von einer sonst harten "kein X als Pflicht"-Regel führen,
   nicht implizit wachsen lassen.
10. Bei zwei funktional konkurrierenden Backends für dasselbe Problem (Kitty-APC vs. OSC
    1337) die Entscheidung für eines explizit mit den konkreten technischen Gründen
    dokumentieren (README "Why not snacks.image or image.nvim"), damit spätere
    Contributor die Wahl nicht in Frage stellen, ohne die Historie zu kennen.

## Keybindings-Audit
Aus README.md "Usage"-Tabelle und `lua/images/bindings/keymaps.lua`, buffer-lokal an
`keymaps.filetypes` gebunden:

- `<leader>im` show, `<leader>ig` gallery, `<leader>in`/`<leader>ip` next/prev,
  `<leader>iv` paste, `<leader>is` screenshot:
  - count: n.a. für alle — Bild-unter-Cursor-Anzeige, Gallery-Aufbau, Clipboard-Paste sind
    keine wiederholbaren Aktionen. `next`/`prev` (`images.step(1)`/`step(-1)`) könnten
    theoretisch von einem count profitieren (`3<leader>in` = 3 Bilder vor), ist aber laut
    gelesenem Code (`step(1)`, kein `vim.v.count1`) nicht implementiert — kleine Lücke.
  - Autocompletion: n.a. für Keymaps selbst. Für die Ex-Command-Pendants (`:Image next`,
    `:Image pickers [cfile|cwd|path] [dir]`, `:Image compare [cfile|cwd|path] [dir]`) ist aus
    den gelesenen Dateien nicht ersichtlich, ob feste Werte (cfile/cwd/path) per
    Tab-Completion vorgeschlagen werden — nicht verifiziert (usrcmds.lua nicht im Detail
    gelesen).
  - Fehlende Flags: `paste`/`screenshot` als Keymap nehmen keinen Namen entgegen (nur das
    Ex-Command `:Image paste {name}` kann das) — für Power-User evtl. wünschenswert, aber
    als Keymap ohnehin unpraktisch (kein Text-Input über reines lhs möglich).

- `<2-LeftMouse>` (Doppelklick): zeigt Bild bei Treffer, fällt sonst auf normale
  Wortauswahl zurück (`normal! viw`), statt den Klick stumm zu schlucken — sauberer
  Fallback, kein Bug.
  - count: n.a.

- Im Redact-Fenster (buffer-lokal, nur während `images.redact.open()` aktiv): `w` schwärzen
  + speichern, `u` letzte Box entfernen, `<CR>` (Visual-Mode) Box bestätigen.
  - count: n.a. — `u` entfernt genau eine Box pro Aufruf; ein count (`3u` = 3 Boxen
    entfernen) wäre denkbar, ist aber nicht implementiert (`table.remove(boxes)` ohne
    Count-Berücksichtigung) — kleine, konsistente Lücke mit dem next/prev-Fall oben.
  - Autocompletion: n.a. (reine Modal-Keymaps, kein Text-Input).
  - Fehlende Flags: keine ersichtlich; alle drei Mappings sind mit `nowait = true` gesetzt,
    was für eine sekundenkritische Zensur-Interaktion sinnvoll ist (kein Warten auf
    mögliche längere Sequenzen).

- Alle Keymaps sind einzeln per `false` deaktivierbar (README Konfigurationsblock
  `keymaps = { show = "<leader>im", ... }`), which-key wird automatisch nur bei ≥2
  konfigurierten Bindungen mit gemeinsamem Präfix registriert.

## Ideen für andere Plugins
1. Ein generisches "Terminal-Capability-Detection"-Modul in lib.nvim (Umgebungsvariablen-
   Heuristik + Session-Cache + Einmal-Warnung-Pattern), wiederverwendbar für jedes Plugin,
   das terminalabhängige Escape-Sequenzen sendet.
2. Ein generisches "Zell-Selektion auf Scratch-Buffer → Pixel-Umrechnung"-Hilfsmodul für
   jedes Plugin, das eine visuelle Auswahl über eine nicht-interaktive Terminal-Ausgabe
   legen muss (denkbar für andere OSC-1337-basierte Overlays).
3. Ein generisches "sicherer externer Download mit Timeout+Bytelimit+URL-Cache"-Modul in
   lib.nvim, das das Muster aus `remote.lua:M.fetch` kapselt — github_stats.nvim's
   api.lua könnte davon direkt profitieren (dort fehlt aktuell ein explizites Bytelimit).
