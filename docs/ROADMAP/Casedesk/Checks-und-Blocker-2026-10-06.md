# Casedesk: Checks und Blocker (Stand 2026-10-06)

Ergebnis der Umsetzung von `NEW.md` (`:Case clipboard`, Spotlights pro Case,
spotlight.nvim <-> mdview.nvim) und der anschliessenden Aufraeum-Runden.
Alles hier ist **von dir zu pruefen** oder **durch Externes blockiert**.
Die Spotlight-/mdview-Checks, die nicht direkt casedesk betreffen, stehen in
`../Final_Checks/Spotlight-mdview-ai-Checks-2026-10-06.md`.

## A. Checks fuer dich (casedesk.nvim)

Task: `casedesk.nvim/clipboard-spotlight-live-check` (wkdbook-myplugins). Fehler
als eigene bug-Tasks anlegen.

### `:Case clipboard`

- [ ] `:Case clipboard` ohne Argument: Mehrfachauswahl-Picker (`kit.select`,
      `multi`) in der echten TUI; Felder abhaken, Werte stimmen, Zwischenablage
      enthaelt das Erwartete (bisher nur mit gestubbtem `kit.select` geprueft).
- [ ] `:Case clipboard number,title --labels` gegen einen echten Case.
- [ ] `:Case clipboard number title --sep=pipe` bzw. `--sep=\n` (Escapes
      `\n`, `\t`, `\\` werden dekodiert) gegen einen echten Case.
- [ ] Explizite Case-Angabe (`AREA/Nummer`, `.`, volle SNOW-ID) an beliebiger
      Position; zwei verschiedene Cases ergeben einen Fehler.
- [ ] Feld ohne Wert (z. B. `title` ohne Titel, `link` ohne `snow_url_format`):
      Warnung mit Grund, Rest wird kopiert, Zwischenablage nie leer.
- [ ] Tab-Completion: Feldnamen, Felder nach dem Komma, Case-Nummern, und auch
      ab dem dritten Token (variadisch, lib.nvim `f0d76b9`).

### Spotlights pro Case (`:Case spotlight`)

- [ ] Markierungen in Case A setzen, nach Case B wechseln (leer), dort
      markieren, zurueck nach A: `:Case spotlight list` und `show` stimmen,
      A hat wieder seine eigenen Markierungen, nichts vermischt sich.
- [ ] Neustart von Neovim in einem Case: Markierungen kommen zurueck, kein
      Hinweis-Dauerlaerm (Session-Restore von spotlight.nvim).
- [ ] Origin-Filter: in einer Datei **ausserhalb** des gebundenen Cases
      markieren; Markierung bleibt live, wird aber nicht in `.spotlight.json`
      geschrieben; einmalige Info erscheint; `:Case spotlight save` speichert
      alles.
- [ ] Case-Wechsel (BufEnter) mit zurueckgehaltenen Markierungen: Bindung wird
      geloest, Markierungen bleiben, eine Info nennt den Weg
      (`:Case spotlight load` fragt vor dem Ersetzen, `save` weist zu).
- [ ] Unlesbare `.spotlight.json` in einem betretenen Case: Warnung, Bindung am
      alten Case wird geloest (kein stilles Schreiben in den falschen Case).
- [ ] Portable Origins: gespeicherte absolute Pfade unter `$REPOS_DIR` stehen
      als `$REPOS_DIR/...` in der Datei; auf einer zweiten Maschine mit anderem
      `$REPOS_DIR` kommen die Markierungen richtig zurueck.
- [ ] `:checkhealth casedesk`: zeigt `follow`, `origin_filter`,
      `warn_unignored`; Gitignore-Warnung fuer `.spotlight.json`,
      `.spotlight.json.tmp`, `.spotlight.json.corrupt`; mit
      `spotlight.warn_unignored = false` verschwindet sie.
- [ ] Datenschutz-Stichprobe: `.spotlight.json` taucht weder im Export-Bundle
      noch in Anonymisierung oder KI-Prompts auf.

### Uebersetzer-Policy (`:Case translate`)

- [ ] Mit leerer `translate_allowed_engines` wird Kundentext von jeder Engine
      abgelehnt; mit einem Eintrag (`CASEDESK_TRANSLATE_ALLOWED`) nur diese
      Engine erlaubt.

### KI-Kette / Copilot (casedesk-seitig)

- [ ] `:Case ki --send` mit dem Copilot-Provider (nur harmlose Testdaten!):
      Anonymisierung greift, Antwort wird abgelegt. Jeder Lauf kostet einen
      Premium-Request.
- [ ] `docs/KI.md` liest sich stimmig zum Ist-Stand.

## B. Blocker (alle, auch ausserhalb von casedesk)

| Blocker | Betrifft | Wartet auf | Task / Ort |
|---|---|---|---|
| IT-Antwort zur Datenfreigabe | `ki-datenfreigabe-klaeren` | schriftliche IT-Antwort je Datenklasse (kunde, anhang, intern) und je Provider; Google Translate/DeepL fuer Kundentext. Bis dahin strenge Variante (Owner-Entscheidung 2026-10-06: Anonymisierung Pflicht, Policy-Texte nur mit `--inline`, Uebersetzer nur per Allow-List). Task bleibt `decision`. | casedesk.nvim/ROADMAP/tasks |
| Claude: Live-Lauf | ai.nvim `review-restpunkte` | Account mit API-Guthaben (der eingeloggte meldet "Credit balance is too low"). Ungeprueft: reale stream-json-Ereignisform, Wirkung der Deny-Regel gegen `@pfad`, `CLAUDE_CODE_DISABLE_ATTACHMENTS`, Label `User message:` gegen lokale Slash-Befehle. | ai.nvim/ROADMAP/tasks/review-restpunkte |
| Claude: Websuche | ai.nvim `capabilities-web` | Guthaben + Aktivierung im Konto + Datenschutzentscheidung (Websuche schickt Anfragetext an Dritte). Kein Provider setzt `web = true`, bevor der Such-Parameter an der echten API geprueft ist. Task kann auch verworfen werden. | ai.nvim/ROADMAP/tasks/capabilities-web |
| Copilot: Fehlerform | ai.nvim `copilot-fehlerereignis-mitten-im-lauf-aufzeichnen` | ein Konto, das gerade scheitert (Guthaben alle, Rate-Limit, kein Login), um die Fehlerereignisse aufzuzeichnen. Bis dahin als "unverifiziert" markiert; der Provider faellt auf Exit-Code/stderr zurueck und liefert nie eine halbe Antwort. | ai.nvim/ROADMAP/tasks |
| Copilot "auto" | Datenschutzfrage | Entscheidung, ob `model` fest gepinnt wird (`auto` routet ueber Modelle mehrerer Anbieter). | ai.nvim `copilot`-Provider |

## C. Entscheidungen, die schon gefallen sind (zur Kontrolle)

- Anonymisierung bleibt Pflicht, auch fuer Copilot/Claude.
- Interne Policy-Texte nur mit `--inline`, nie automatisch.
- Externe Uebersetzer fuer Kundentext nur per Allow-List.
- `spotlight.follow = true` bleibt Default.
- Kein Feld `spotlight` in `:Case clipboard`, kein Statusline-Segment.
- `.spotlight.json` wird **nicht** in die `.gitignore` des Case-Repos
  (WKDBook-Tricentis) eingetragen, damit die Markierungen per Git zwischen
  Geraeten mitreisen; Option `spotlight.warn_unignored = false` schaltet die
  Health-Warnung ab.
- Absolute Origins unter `$REPOS_DIR` werden als `$REPOS_DIR/...` gespeichert.

## D. Bekannte Restpunkte (klein, ohne Handlungsdruck)

- Optionale Spec: `REPOS_DIR` als Symlink (Verhalten sicher, Pfad wird nur nicht
  kompaktiert).
- Aendert sich die Projekt-Root von spotlight.nvim mitten in der Session
  (`:cd`), werden relative Origins neuer Live-Items gegen die neue Root
  aufgeloest (bekannte Items sind geschuetzt).
- `GITHUB_TOKEN` enthaelt ein klassisches `ghp_`-Token: der Copilot-Provider
  reicht es bewusst nicht weiter; fuer die Copilot-CLI direkt in der Shell die
  Variable entfernen.
