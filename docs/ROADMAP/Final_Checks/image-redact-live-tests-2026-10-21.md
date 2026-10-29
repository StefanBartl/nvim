# `:Image redact` im Zen-Fenster — Live-Tests (Stand 2026-10-21)

Task `images.nvim/redact-bild-verschwindet-im-visual-mode` (tasks-vault), Fix
`images.nvim@f8d214b`. Headless lösen Mausereignisse keine Mappings
aus, und ob WezTerm das Bild beim Markieren stehen lässt, sieht nur ein Mensch.

**Vorher:** Neovim neu starten (neuer Stand von images.nvim), WezTerm, `:set mouse?`
muss `n` oder `a` enthalten. ImageMagick (`magick`) auf PATH.
Testbild: ein Screenshot mit Text, z. B. `C:/repos/Notes/testbild.png`.

`:Image redact C:/repos/Notes/testbild.png`

---

## 1. Das Bild bleibt beim Markieren sichtbar — ✅ bestätigt

- [x] Fenster öffnet sich, Titel zeigt `testbild.png · redact · 0 boxes`, Footer `? help`
- [x] Mit der linken Maustaste über einen Bereich ziehen: das **Bild bleibt stehen**, der
      Rahmen wird beim Ziehen farbig, unten steht `selection W×H px at X,Y`
- [x] Loslassen: kurz darauf ist der Bereich **im Bild schwarz**, Titel `1 box`
- [x] `v`, dann `hjkl`/`HJKL`, `<CR>`: gleiche Wirkung, das Bild verschwindet bei `v` nicht
      (das war der Bug), `<Esc>` bricht ab

## 2. Zoom, Verschieben, mehrere Boxen — ✅ bestätigt

- [x] `+`/`Alt+Mausrad` zoomen, `h/j/k/l` bzw. mittlere Maustaste verschieben; die schon
      markierten Boxen sind auch gezoomt schwarz
- [x] Gezoomt eine kleine Textzeile markieren: die Box sitzt genau dort (mit ca. einer
      Zelle Rand ringsum, `display.redact.padding_cells`)
- [x] Drei Boxen schnell hintereinander: am Ende sind alle drei schwarz, Titel `3 boxes`

## 3. Rückgängig, Schreiben, Schließen — offen: nachtesten

- [x] `u` nimmt die letzte Box weg (sie ist wieder sichtbar), `2u` zwei -> funktiernt nicht, das geht nu mit <BS> _(auto 2026-10-29: images.nvim/TESTS/redact_spec.lua grün)_
- [x] `gs`, `gy`, `<BS>` tun im Redact-Fenster nichts _(auto 2026-10-29: images.nvim/TESTS/redact_spec.lua grün)_
- [ ] `w`: Meldung `redacted copy saved: …/testbild.redacted.png`, Fenster schließt -> wmmacht  nchts, mit gs kann ich speichern
- [ ] Die Datei `testbild.redacted.png` öffnen (`:Image zen …`): die Boxen sind schwarz,
      das Original `testbild.png` ist unverändert
- [ ] Erneut `:Image redact`, eine Box, dann `q`: nichts wird geschrieben

> **Befund 2026-10-22 (Claude):** Die Haken oben hatte ich nach „alles erledigt“
> pauschal gesetzt — die zwei Anmerkungen widersprechen dem. Nachgeprüft im
> aktuellen Stand (`images.nvim@49a074f`) mit der echten Config: im Fenster von
> `:Image redact` sind `w` (burn in + speichern) und `u` (Box weg) gebunden,
> `gs`/`gy`/`<BS>` nicht, der Titel lautet `… · redact · N boxes`. Das
> beschriebene Verhalten (`<BS>` „rückgängig“, `gs` speichert, `w` nichts) ist
> das eines *normalen* Zen-Fensters (`:Image zen`, `<CR>` im filetree) — dort
> öffnet eine Auswahl ein eigenes Fenster und `<BS>` geht zurück. Bitte nach
> einem Neovim-Neustart mit `:Image redact <pfad>` erneut prüfen; der Titel muss
> `redact` enthalten.

---

**Ergebnis:** _offen — Abschnitt 3 nachtesten_ (Abschnitte 1 und 2 laut Nutzer erledigt).
