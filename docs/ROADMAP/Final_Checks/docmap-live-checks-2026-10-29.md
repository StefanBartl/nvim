# docmap.nvim — Live-Checks (Stand 2026-10-29)

Zwei Dinge aus `docmap.nvim` (bis 2026-10-24 `documentation.nvim`), die nur in einer echten Sitzung
prüfbar sind: das Tab-Verhalten der Keyword-Karte in einem Fenster mit echtem Fokus und der gebaute
`docmap`-Binary auf einem echten Windows mit echten Verknüpfungen (Junctions, OneDrive). Jeder
Abschnitt gehört zu einer Task im `tasks-vault` (Area `docmap.nvim`); ist ein Abschnitt durch, die
Task mit `done` schließen (oder Bescheid geben). Ein Befund: unter „Falls rot“ eine Zeile, daraus wird
eine `kind: bug`-Task.

Verwandte Dateien: `docmap-desktop-live-tests-2026-10-02.md` (Engine-Panel und Kanten-Popup stehen
dort, nicht hier).

**Vorher:** Windows 11, Neovim 0.10 oder neuer, `docmap.nvim` aktuell (Commit notieren: ______).
Für Abschnitt 1 zusätzlich `docmap-desktop` installiert. Für Abschnitt 2 die Release-Binary
`docmap-x86_64-pc-windows-msvc.exe` (oder lokal gebaut) und Wegwerf-Ordner, nicht echte Projekte.

---

## 1. Keyword-Karte: Tab-Navigation im echten Fenster — offen

Task `docmap.nvim/keyword-card-tab-navigation-live-check`. Code: `lua/docmap/core/render/html.lua`
(Elemente mit `data-kw` und `tabindex="0"`, Karte `#kwpop`, Listener für `focusin`, `keydown`
Escape, `scroll`, `resize`). Hintergrund: In den automatischen Läufen nahm ein nicht-compositing
Pane nie den Fokus, `focusin` feuerte nie; gesehen hat es noch niemand.

Vorbereitung: eine generierte Seite öffnen, die Funktions-Snippets mit Keywords enthält (z. B. das
eigene `docs/map` eines Lua-Projekts, `:DocMap` bzw. **Generate map** in `docmap-desktop`), einmal
im Browser, einmal in `docmap-desktop`.

- [ ] Browser: in einem Funktions-Snippet mit der Maus kurz auf einem Keyword verweilen (Dwell): die
      Karte öffnet sich
- [ ] Browser: mit Tab zu einem Keyword (die Spans sind fokussierbar): die Karte öffnet sich beim
      Fokus (`focusin`)
- [ ] Browser: Tab und Shift-Tab weiter: Fokus wandert nachvollziehbar (zum nächsten Keyword bzw. in
      die Karte zum Referenzlink und zurück), die Karte springt nicht weg oder bleibt hängen
- [ ] Browser: Escape schließt die Karte, der Fokus liegt danach wieder **auf dem Keyword**
- [ ] `docmap-desktop` (WebView2): dieselben vier Punkte
- [ ] Beobachten: schließen Scrollen oder Fenstergröße ändern die Karte (erwartet laut Code: ja)

Falls rot: Browser oder App, Tastenfolge, wo der Fokus gelandet ist; `kind: bug` in `docmap.nvim`.

Offene Frage: Die Task sagt „Fokus kehrt zum Keyword zurück“; im Code habe ich beim Lesen keine
explizite Fokus-Rückgabe nach Escape gefunden (`keydown` ruft nur `kwClose()`). Bleibt der Fokus
einfach auf dem Keyword, weil er nie wegging, ist der Punkt erfüllt. Ist er nach Escape aus der
Karte heraus verloren, ist das der Befund.

Danach: Task `keyword-card-tab-navigation-live-check` mit `done` schließen, Ergebnis in die Task-Notizen.

---

## 2. Gebauter `docmap`-Binary und Verknüpfungen auf Windows — Rest offen

Task `docmap.nvim/engine-links-binary-check`. Code: `standalone/win_links.lua`, Doku
`docs/SECURITY.md` (Abschnitt „Links, junctions and the output directory“). Der Lauf vom 2026-10-17
(Release-Binary, Windows 11 Home 10.0.26200, de-DE) hat sieben der elf Punkte abgehakt; die Befunde
dazu stehen in der Task. **Hier stehen nur die offenen Punkte.**

Vorbereitung: Wegwerf-Ordner mit Projekt `proj`, daneben `outside/` mit einer Canary-Datei (eigener
Text). Nachweis „nichts gelesen“ über die LastAccessTime der Canary (vorher auf 2020 zurücksetzen,
NTFS aktualisiert sie nur, wenn sie älter als eine Stunde ist).

- [x] **`docs/map` als Junction:** Junction `docs/map` anlegen und `docmap .` (generate) sowie
      `docmap . --check` ausführen: beide verweigern mit klarer Meldung. Stand 2026-10-17: Verweigerung
      ja, aber generate druckt sie als **Lua-Traceback** (`[string "documentation"]:594:`), deshalb
      damals nicht abgehakt; dazu gibt es die Bug-Task `docmap-generate-prints-a-refusal-as-a-lua-traceback`.
      Prüfen: ist das inzwischen behoben (saubere Meldung ohne Traceback, Exit-Code)?
      **2026-10-30 behoben:** Rolling-Binary `standalone-latest` (aus 9609462): generate und `--check`
      verweigern mit einer Zeile, ohne Traceback, Exit 2, Link-Report bleibt erhalten; nichts nach
      `outside/` geschrieben, Canary-atime unverändert (Positivkontrolle ok). Junction im Projekt:
      generate verweigert ebenso (Exit 2), `--check` liest durch (so dokumentiert). Details in der Task.
- [ ] **OneDrive „Files on demand“:** ein Ordner mit Platzhaltern (nur online verfügbare Dateien) wird
      weiter gelesen (Platzhalter sind keine Links). Voraussetzung: laufender OneDrive-Client mit
      aktivierten On-Demand-Dateien; am 2026-10-17 nicht testbar (Client lief nicht, nur `desktop.ini`).
- [ ] **OneDrive-Platzhalter mit ` [` im Namen** (z. B. `Project [2024]`): wird als Link behandelt und
      nicht gefolgt; aufschreiben, wie häufig so ein Name bei dir vorkommt
- [ ] **Listing-Typ `file`/`directory` ist nie ein Link:** Junctions, Verzeichnis-Symlinks und
      OneDrive-Platzhalter neben normalen Dateien; der Teil mit Junctions und Symlinks ist am
      2026-10-17 geprüft, offen ist die **OneDrive-Platzhalter-Hälfte**
- [ ] (optional, nicht in der Task, aus ihren Notizen) Laufzeit: der Census startet pro Verzeichnis
      ein `cmd` (ca. 16 ms je Verzeichnis, 2347 Verzeichnisse etwa 9 s). Falls Optimierung
      (ein `dir /s /a:l` je Baum oder gecachter Census) angegangen wird, die Messung wiederholen:
      ______ s vorher / ______ s nachher

Nicht mehr offen (am 2026-10-17 erledigt): Junction aus dem Projekt heraus, Junction im Projekt, Zeitmessung,
deutsches Windows, Zeilenumbruch im Ziel und ` evil`/`evil`, UNC-Arbeitsverzeichnis, `docmap .` unter
einer Junction.

Offene Fragen: Französisches Windows wurde nicht getestet (die Task nennt „German, French“). Reicht
Deutsch, oder soll Französisch offen bleiben? Außerdem hängen die Bug-Tasks
`docmap-generate-prints-a-refusal-as-a-lua-traceback` und
`windows-census-takes-a-real-directory-for-a-link-when-the-na` an dieser Task; vor dem Schließen
klären, ob sie Bedingung sind.

Falls rot: Befehl, Ausgabe, erwartetes Verhalten; `kind: bug` in `docmap.nvim`.

Danach: Task `engine-links-binary-check` mit `done` schließen (wenn die offenen Punkte durch oder
bewusst als „nicht testbar“ notiert sind), Ergebnis in die Task-Notizen.
