# hover.nvim — Live-Checks (Stand 2026-10-29)

Was in hover.nvim gebaut und mit Specs abgedeckt ist (Zwischenablage dort gestubbt), aber nur mit
der echten Zwischenablage und echten Bildern prüfbar ist. Ist der Abschnitt durch, die Task mit
`done` schließen (oder Bescheid geben). Ein Befund: unter "Befunde" eine Zeile, daraus wird eine
`kind: bug`-Task.

**Vorher:** hover.nvim mindestens auf `hover.nvim@6765e59` (`:Hover copy` / `Y`), Neovim neu
gestartet, `:checkhealth hover` ohne Fehler. Auf dieser Maschine (Windows) ist die System-
Zwischenablage `win32yank`; in einer Spec-Sitzung am 2026-10-22 kam dort `OS error 5`.

Bildvorschau braucht ein Terminal mit Grafikprotokoll (wie sonst auch für Hover-Bilder bei dir).
Testmaterial: eine Textdatei, ein Bild (PNG), eine PDF-Datei und eine Seite für den Seiten-
Screenshot (Link auf eine Webseite), jeweils als Markdown-Link oder Pfad in einer `.md`-Datei.

---

## 1. `:Hover copy` / `Y` mit echter Zwischenablage und Zoom-Ausschnitt — offen

Task `hover.nvim/copy-live-check`. Ergebnis gehört zusätzlich in die Zeile "A hover copied" in
`$REPOS_DIR/tasks-vault/hover.nvim/NOTES/MANUAL-EVIDENCE.md` (Abschnitt "A hover copied").

### Text-Hover

- [ ] Cursor auf einen Link/Pfad zu einer Textdatei, Hover öffnen, `Y` drücken
- [ ] In einem **anderen Buffer** einfügen (`p`): die Zeilen, die auf dem Schirm standen, **ohne
      Titel**
- [ ] In einem **anderen Programm** einfügen (z. B. Editor, Browser-Adressleiste): derselbe Text;
      die Meldung nennt die Zwischenablage (nicht nur "the unnamed register")
- [ ] Hover scrollen (`<C-Down>`), `Y` erneut: eingefügt werden die Zeilen, die **jetzt** zu sehen
      sind

### Bild-Hover

- [ ] Bild-Hover öffnen, zweimal `>` (Zoom), mit `l` verschieben, `Y`
- [ ] Die Meldung nennt eine Datei unter `stdpath("cache")/hover.nvim/copies`
      (`:echo stdpath("cache")` für den Ordner)
- [ ] Datei öffnen: sie zeigt den **vergrößerten Ausschnitt** wie auf dem Schirm, nicht das ganze
      Bild
- [ ] Dasselbe bei einer **PDF-Seite** (Ausschnitt, nicht die ganze Seite)
- [ ] Dasselbe bei einem **Seiten-Screenshot** (Ausschnitt, nicht der ganze Screenshot)

### Falls rot

- Ganzes Bild statt Ausschnitt nach dem Zoom: vermutlich hat `present` die Quelle statt des
  Ausschnitts gemerkt. Notieren: Art (Bild/PDF/Screenshot), Zoomstufe, Dateipfad der Kopie.
- Meldung sagt nur "the unnamed register", Einfügen in anderen Programmen leer: die System-
  Zwischenablage greift nicht. Notieren: Fehlertext, `:checkhealth provider` (clipboard),
  `:echo g:clipboard`.
- Jeder Befund wird eine eigene `kind: bug`-Task.

### Danach

- [ ] Ergebnis (auch ein Fehlschlag) in Zeile "A hover copied" in `MANUAL-EVIDENCE.md` eintragen
      (Checked, On, Datum)
- [ ] Task `hover.nvim/copy-live-check` mit `done` schließen

### Offene Fragen

- Die Task nennt `NOTES/MANUAL-EVIDENCE.md` ohne Repo: die Datei liegt im `tasks-vault`
  (`tasks-vault/hover.nvim/NOTES/`), nicht im Plugin-Repo. Stimmt das so?

---

## Befunde

<!-- eine Zeile pro Befund: Abschnitt, was passiert ist, was erwartet war -->
