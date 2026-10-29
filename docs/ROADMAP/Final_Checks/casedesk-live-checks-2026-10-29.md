# casedesk.nvim — Live-Checks (Stand 2026-10-29)

Was in casedesk.nvim gebaut und headless mit Specs oder Wegwerf-Skripten geprüft ist, aber nur in
einem echten Neovim mit einem echten Case gegengelesen werden kann. Jeder Abschnitt gehört zu einer
Task im `tasks-vault` (Area `casedesk.nvim`); ist ein Abschnitt durch, die Task mit `done` schließen
(oder mir Bescheid geben). Ein Befund: unter "Befunde" eine Zeile, daraus wird eine `kind: bug`-Task.

**Vorher:** casedesk.nvim, spotlight.nvim, ui.nvim, lib.nvim aktuell (`:Lazy update`), Neovim neu
starten, `:checkhealth casedesk` ohne Fehler. Maschine: die Arbeitsmaschine mit dem echten Workspace.
Ein beliebiger **echter, offener Case** reicht für die Abschnitte 1, 3, 4 und 5; für Abschnitt 2 der
ganze Bestand. In der Datei selbst und in den Notizen stehen **keine** Kundennamen, Ticketinhalte
oder Pfade mit Kundenbezug: nur Case-Nummern-Platzhalter und Beobachtungen.

Reihenfolge-Empfehlung: 2 (Priorität 1) zuerst, dann 1, 3, 4, 5.

## Inhaltsverzeichnis

- [1. `:Case clipboard` und Case-Spotlights](#1-case-clipboard-und-case-spotlights--offen)
- [2. `:Cases doctor` gegen den echten Bestand](#2-cases-doctor-gegen-den-echten-bestand--offen)
- [3. Case-Pin bei Meldungen](#3-case-pin-bei-meldungen--offen)
- [4. `hover.nvim` auf Case-Links](#4-hovernvim-auf-case-links--offen)
- [5. Schwesterplugins ohne Wiring](#5-schwesterplugins-ohne-wiring--offen)
- [Befunde](#befunde)

---

## 1. `:Case clipboard` und Case-Spotlights — offen

Task `casedesk.nvim/clipboard-spotlight-live-check`. Der Mehrfachauswahl-Picker von
`:Case clipboard` (ohne Argument) und der Case-Wechsel mit echtem spotlight.nvim sind nur per Spec
und headless-Wegwerf-Skript geprüft. Passt zu `casedesk.nvim/live-tests-run` (dort die große
Checkliste); hier nur die zwei neuen Wege vom 2026-10-06. Doku: `docs/commands.md`
(`:Case clipboard`, `:Case spotlight ...`), `docs/FEATURES.md` ("Markierungen pro Case").

**Vorbereitung:** zwei echte offene Cases A und B (beliebig). Ein Zwischenablage-Betrachter zum
Gegenlesen (z. B. `:put +` in einem Scratch-Buffer, `:enew`).

### 1a. Picker ohne Argument

- [ ] In Case A: `:Case clipboard` (ohne Argument) öffnet die Mehrfachauswahl (`kit.select`, `multi`)
- [ ] Mindestens drei Felder abhaken (z. B. `number`, `title`, `link`): die Auswahl bestätigen
- [ ] Zwischenablage (`:enew`, `"+p`): enthält genau die gewählten Werte, in der erwarteten
      Reihenfolge, Werte stimmen mit dem Case überein
- [ ] Abbrechen im Picker (`<Esc>`): nichts in der Zwischenablage geändert, keine Fehlermeldung

### 1b. Mit Argumenten

- [ ] `:Case clipboard number,title --labels`: jeder Wert trägt seinen Namen als Präfix
- [ ] `:Case clipboard number,title --sep=pipe`: die Werte sind mit dem Pipe-Zeichen verbunden
      (Erwartung laut Task: `--sep=pipe` wird als Trenner aufgelöst; wenn stattdessen der Text
      "pipe" erscheint, ist das ein Befund)
- [ ] Beides gegen den echten Case: die Werte decken sich mit `Summary.md`/dem Pin-Chip

### 1c. Spotlights pro Case

Voraussetzung: spotlight.nvim aktiv, `spotlight.follow` an (Default).

- [ ] In Case A einen Activity Stream öffnen, 2 bis 3 Begriffe markieren (spotlight.nvim)
- [ ] Nach Case B wechseln (Buffer von B fokussieren): die Markierungsliste ist **leer**
- [ ] In B einen anderen Begriff markieren
- [ ] Zurück nach A: A-Markierungen sind wieder da, die von B nicht
- [ ] `:Case spotlight list`: beide Cases mit ihrer Anzahl
- [ ] `:Case spotlight show` (in A): Text, Farb-Slot, Match-Modus, Ursprungsdatei stimmen
- [ ] Neovim beenden und in einem Case neu starten: Markierungen kommen zurück, **kein**
      Hinweis-Dauerlärm (höchstens eine Meldung beim ersten Betreten)

### Falls rot

Notieren: welcher Punkt, Meldungstext (wörtlich, ohne Kundendaten), `:messages`-Ausschnitt,
`:checkhealth casedesk`. Fehler als eigene `kind: bug`-Task festhalten (Tag `needs-live-test`
entfernen, sobald reproduziert).

**Danach:** Task `casedesk.nvim/clipboard-spotlight-live-check` mit `done` schließen; Ergebnis in
die Notizen.

---

## 2. `:Cases doctor` gegen den echten Bestand — offen

Task `casedesk.nvim/doctor-stale-unconfirmed-live-run` (Priorität 1). Die Doctor-Regel
`stale-unconfirmed` (`204ccd0`, `ccfcef7`) ist nur gegen eine Wegwerf-Struktur getestet. Ihr Fix
benennt `Solution/`-Entwurf in `UNCONFIRMED-Solution.md` um **und verschiebt den Case-Ordner von
`Open` nach `Closed`** (zwei Schritte, keine Transaktion). Das sind echte Kundendaten, deshalb nur
durch dich. Regel: offener Case, dessen Solution-Entwurf einen unbekannten Status trägt oder seit
`config.stale_unconfirmed_days` (Default 14) Tagen unberührt ist, **und** nichts anderes im Case ist
neuer. Quellen: `lua/casedesk/doctor.lua`, `lua/casedesk/config/DEFAULTS.lua`,
`Backlog/TASKS/implementierungsplan-2026-09-30.md` §3.

**Vorbereitung:** Backup oder Sicherheit des Workspace (Datei-Historie/Backup), damit ein
unerwünschtes Verschieben rückholbar ist. Vorher `:Cases doctor` nur lesen: es schreibt nie.

- [ ] `:Cases doctor` einmal gegen den echten Bestand laufen lassen; der Bericht öffnet sich
- [ ] Befunde durchgehen: jeder `stale-unconfirmed`-Befund nennt Case und Alter des Entwurfs
      ("solution draft untouched for over 14 day(s)")
- [ ] Stichprobe: bei jedem vorgeschlagenen Case prüfen, ob er wirklich verwaist ist (kein
      neuerer Reply, keine neue Recherche, kein neuer Activity Stream)
- [ ] `:Cases normalize`: der Trockenlauf zeigt je Case "Umbenennen in `UNCONFIRMED-Solution.md`,
      danach nach `Closed`" und fragt vor dem Anwenden
- [ ] Bestätigen **oder** verwerfen, je Vorschlag entscheiden; bei Zweifel verwerfen
- [ ] Nach dem Anwenden: die verschobenen Cases liegen unter `Closed`, `:Cases solutions` findet
      den Entwurf weiter (jetzt als UNCONFIRMED markiert)
- [ ] Zweiter Lauf `:Cases doctor`: kein `stale-unconfirmed`-Befund für dieselben Cases mehr
      (Schutz gegen halb ausgeführten Fix: Rename ok, Verschieben fehlgeschlagen)

### Falls rot

Falsche Treffer (Case ist doch aktiv), zu strenge oder zu laxe Frist (`stale_unconfirmed_days = 14`),
Rename ohne Verschieben (Windows-Lock, anderes Laufwerk) oder Fehlermeldung in `:messages`
notieren. Nur Anzahl und Art festhalten, **keine** Case-Titel oder Kundennamen in Task oder Datei.
Auffälligkeiten als Notiz in der Task oder als `kind: bug`-Task.

**Danach:** Task `casedesk.nvim/doctor-stale-unconfirmed-live-run` mit `done` schließen. Daran
hängt `open-cases-recheck`; `Q-4` (`unconfirmed-outcome-or-status`) ist unabhängig.

---

## 3. Case-Pin bei Meldungen — offen

Task `casedesk.nvim/pin-message-windows-live-check` (Rest aus `pin-ignore-message-windows`, Fix
`casedesk.nvim@49fcb44`). Headless sieht man weder "more"-Meldungen noch noice-Fenster. Doku:
`docs/pin.md`.

**Vorbereitung:** einen Case öffnen (z. B. dessen `Summary.md`); rechts unten steht der Pin-Chip
(`pin.anchor = "bottom-right"` ist der Default).

- [ ] `:w` in einem Case: der Chip rechts unten bleibt stehen
- [ ] `:lua vim.notify("x")`: der Chip bleibt, auch nachdem die Meldung wieder weg ist
- [ ] `:echo "a\nb\nc"` (mehrzeilig, "more"/Enter): der Chip bleibt bzw. ist nach Enter sofort
      wieder da
- [ ] Optional: im Meldungsfenster `:lua print(vim.bo.buftype, vim.api.nvim_win_get_config(0).relative)`
      und das Ergebnis hier notieren: ______

### Falls rot

Notieren: welche Meldungsart (`:w`, notify, mehrzeilig), ob noice aktiv ist, ob der Chip dauerhaft
oder nur bis zum nächsten Redraw fehlt; `:Hover`-unabhängig. Ein Fund geht als `kind: bug` in
casedesk.nvim.

**Danach:** Task `casedesk.nvim/pin-message-windows-live-check` mit `done` schließen.

---

## 4. `hover.nvim` auf Case-Links — offen

Task `casedesk.nvim/try-hover-on-case-links` (kind: research, Aufwand praktisch null).
Frage: trifft `hover.nvim` ohne Wiring relative `assets/`-Pfade und Doku-URLs in Case-Markdown?
Quelle: `casedesk.nvim/ROADMAP/ROADMAP.md` §6 (RM-28),
`ROADMAP/ANALYSEN/casedesk-cross-plugin-features-2026-09-29.md` §B.2. Hover-Befehle:
`:Hover show` (ein Hover jetzt, hier), `:Hover why` (warum nichts erscheint).

**Vorbereitung:** ein echter Case mit einem Eintrag unter `assets/` (z. B. eine Log-Datei) und eine
Markdown-Datei im Case, die darauf verlinkt. Den Link am einfachsten mit `:Case insert asset`
erzeugen (liefert die Form `../assets/<Datei>`). Dazu ein Link auf eine Doku-URL
(`docs.tricentis.com/...`).

- [ ] Cursor auf den relativen Link `../assets/<Datei>`, `:Hover show`: ein Hover erscheint
      (Vorschau der Datei) oder nicht? Ergebnis: ______
- [ ] Zielfall: ein Link der Form `<casenr>/assets/third/...` (Unterordner `third`) ausprobieren
- [ ] Cursor auf die Doku-URL, `:Hover show`: Hover erscheint oder nicht? Ergebnis: ______
- [ ] Wenn nichts erscheint: `:Hover why` und die Antwort notieren (welches Gate hat abgelehnt)

### Falls rot (kein Hover)

Das ist kein Fehler, sondern das Ergebnis der Recherche: festhalten, was fehlt (Pfadauflösung
relativ zur Datei? URL-Erkennung?). Ergibt sich ein wiederkehrender Handgriff, wird daraus ein
eigener Task; die zwei anderen `hover.nvim`-Ideen der Inbox (Zoom-Vollbild, persistenter
Doku-Cache) gehören zu `hover.nvim`, nicht hierher.

**Danach:** Ergebnis in die Notizen von `casedesk.nvim/try-hover-on-case-links`, dann `done`.

---

## 5. Schwesterplugins ohne Wiring — offen

Task `casedesk.nvim/try-sibling-plugins-no-wiring` (kind: research). Vier vorhandene Plugins am
Case-Alltag ausprobieren, ohne Code zu schreiben. Nur wenn sich ein **wiederkehrender Handgriff**
zeigt, wird daraus ein eigener Task; sonst die Task schließen. Quelle:
`casedesk.nvim/ROADMAP/ROADMAP.md` §6 (RM-29),
`ROADMAP/ANALYSEN/casedesk-cross-plugin-features-2026-09-29.md` §B.4 bis §B.7.

**Vorbereitung:** ein echter Case; alle vier Plugin-Repos liegen unter `E:\repos`.

- [ ] `data.nvim`: `:JSON pretty` auf der `.case.json` des Cases oder einem eingefügten JSON-Blob
      (`:JSON pretty --reg=+` formatiert das Register, ohne den Buffer anzufassen). Brauchbar? ______
- [ ] `insights.nvim`: `:Insights compress <Case-Ordner>` bzw. nur `assets/` (nativ unter
      Windows): Archiv entsteht, Größe plausibel. Brauchbar? ______
- [ ] `cmdlog.nvim`: protokolliert `:Case ...` ohnehin; nach ein paar `:Case`-Befehlen das Log
      öffnen (Befehle siehe `cmdlog.nvim/docs/commands.md`): erscheinen die Einträge? ______
- [ ] `mdview.nvim`: `Summary.md` oder einen Reply vor dem Einfügen ins SNOW-Ticket gegenlesen
      (`:MDView start`): Darstellung brauchbar? ______
- [ ] Wiederkehrender Handgriff dabei? Wenn ja, welcher (wird eigener Task): ______

### Falls rot

Notieren: Plugin, Befehl, Fehlermeldung, ob es an Windows-Pfaden oder an der Case-Struktur liegt.

**Danach:** Task `casedesk.nvim/try-sibling-plugins-no-wiring` mit `done` schließen (oder Folge-Task
anlegen).

---

## Befunde

Hier pro Befund eine Zeile (Abschnitt, was, Meldungstext ohne Kundendaten):

-
