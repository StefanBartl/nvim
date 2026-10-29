# ui.nvim Sticky-Context — Handover (nur offene Punkte)

## Table of content

  - [Sichtprüfung im echten Fenster](#sichtprüfung-im-echten-fenster)
  - [Sichtprüfung ui.slots](#sichtprüfung-uislots)
  - [Neue Live-Checks (Stand 2026-10-29)](#neue-live-checks-stand-2026-10-29)

---

## Sichtprüfung im echten Fenster

Alles wurde headless getestet (und in deiner Config per Skript bestätigt), nichts
visuell. Einmal von Hand ansehen; ist etwas in Ordnung, den Punkt streichen, ist
etwas auffällig, hier eintragen.

1. Große Markdown-Datei öffnen, `:UI sticky status`, in eine H4/H5-Sektion scrollen.
2. `:UI sticky depth 3`: Kette endet bei H3, Anzeige zeichnet sofort neu.
3. `:UI sticky lines markdown 2`, danach `lines markdown 6`.
4. Gespeicherte Werte: `:UI sticky depth 3`, Neovim neu starten, `:UI sticky status`
   zeigt den Wert als gespeichert; `:UI sticky reset` räumt ihn weg.
5. Kleines Fenster (unter 6 Zeilen oder Cursor in den obersten Zeilen): kein
   Overlay, der Cursor wird nie verdeckt. Bei 6 Zeilen Markdown-Limit prüfen, dass
   das Overlay ein kleines Fenster nicht aufzehrt (`min_window_height = 6`).
6. Zusammenspiel mit dem Winbar-Breadcrumb aus lsp.nvim: der Winbar schneidet
   Markdown auf `winbar.max_symbols = { markdown = 1 }` (eine Heading), das
   Sticky-Overlay zeigt bis zu sechs. Doppelt sich das? **Entscheidung 2026-09-21:
   so lassen**, beides ergänzt sich (Winbar = H1, Overlay = Kette); nur ändern,
   wenn es beim Ansehen stört. Dann zwei Wege: das Overlay nur für Code
   (`markdown` in `exclude_filetypes`) und den Winbar in lsp.nvim auf mehr Ebenen
   erhöhen, oder den Winbar für Markdown abschalten und dem Overlay die Kette
   allein lassen.
7. Eine lange Rust-Funktion (oder ein Python-`elif`-Zweig) scrollen: erscheinen
   `if`/`for`/`match`/`elif` als Zeilen, und ist das Bild ruhig genug, oder pinnt
   es zu viel? Ein eingerückter Markdown-Heading (` ## x`) trägt Band und Icon
   auf dem `#`.
8. Eine tief verschachtelte YAML-Datei (CI-Workflow) scrollen: die Eltern-Schlüssel
   (`jobs:` > `build:` > `steps:`) stehen oben, nicht die Listeneinträge.
9. Eine Quelldatei mit Klammern auf eigener Zeile (C#/Java im Allman-Stil, falls
   vorhanden): keine Kontext-Zeile, die nur `{` enthält.

Wie man die Specs laufen lässt und einen Knotentyp am Cursor liest, steht im
Backlog-Eintrag unter „Handwerkszeug“.

---


---

## Sichtprüfung ui.slots

Task `ui.nvim/slots-live-check` (Plan `ui-slots`). Alles gebaut und headless
geprüft, nichts visuell in der echten Konfiguration. Vorher `ui.nvim` pullen
(mindestens `1b73a94`, Kind `expand`) und Neovim neu starten. Die lange
Befehls-/Tasten-Checkliste (Grundfluss, Yank, Leiste, Panel, Editor, Vorschau)
steht unverändert in `Checks-Blocker_0610.md` unter O3; hier nur, was nur ein
Blick im Alltag klärt. Wenn alles passt: Punkte streichen, Task
`slots-live-check` erledigen (`tasks.lua done`) und Plan `ui-slots` auf `done`
setzen; Auffälliges als eigenen Task anlegen (R9), nicht hier sammeln.

1. Chips in `rounded` und mindestens einem weiteren Preset (`double`, `ascii`,
   `solid`, `minimal`) ansehen, im hellen und im dunklen Thema.
2. Je einen Slot im Alltag benutzen: Datei, URL, Yank, Cmd, Lua. (`_` schaltet die
   Leiste, `<leader>_1`..`_9` führt aus, `<leader>_a` fügt hinzu, `<leader>_p`
   öffnet das Panel.)
3. Vorschau für eine Datei und eine URL ansehen (Panel, `K`; URL braucht
   `preview.fetch = true` und hover.nvim).
4. **Neu, Kind `expand`:** `<leader>_9` öffnet den Akronym-Float (alle drei
   Dateien aus `WKDBook-Tricentis`, Überschrift je Quelle). Erneut `<leader>_9`,
   `q` und `<Esc>` schließen ihn; scrollen und `/` suchen gehen; ein Wechsel in
   ein anderes Fenster schließt ihn. Liest sich der Text gut (Markdown-Farben)?
   Auf einem Rechner ohne `WKDBook-Tricentis` meldet der Slot "no file found",
   statt einen leeren Float zu öffnen.
5. Verhalten neben Filetree, Zen, mehreren Fenstern und beim Projektwechsel
   (anderes Projekt = andere Slots): in Ordnung?
6. Zusammenspiel mit Tabline und Statusline: überdeckt die Leiste etwas, springt
   etwas beim Öffnen und Schließen?

---

## Neue Live-Checks (Stand 2026-10-29)

Hinweis zu `ui.nvim/slots-live-check`: unverändert offen, die Checkliste steht
oben im Abschnitt „Sichtprüfung ui.slots“ (dort abarbeiten; Task nach
Durchlauf mit `done` schließen, Plan `ui-slots` auf `done`). Neu ist nur der
folgende Abschnitt.

### Option-Float von `:UI` in einer echten Sitzung

Task `ui.nvim/try-the-ui-option-float-in-a-real-session` (Code `ui.nvim@c5ab2ba`;
`:UI help` jetzt aus den Routen erzeugt, `ui.nvim@fd16dda`). Der Float war bisher
nur durch Specs gedeckt (Routen, Texte, Completion, Dispatch), nie angesehen.

Vorbereitung: `ui.nvim` gepullt (mindestens `c5ab2ba`, besser `fd16dda`),
Neovim neu starten. Ziel ist die echte nvim-Config (dort belegt die Config
`<M-h>` als Cheatsheet-Taste; das Plugin selbst hat keine Default-Taste).

- [ ] `:UI` ohne Argument — erwartet: der Option-Float öffnet sich; Zeilen und Texte sind lesbar und sinnvoll.
  Notiz:
- [ ] `:UI sticky` (und `:UI sticky <Tab>`) — erwartet: Ausgabe bzw. Completion mit den Sticky-Wörtern; Zeilen lesen sich gut.
  Notiz:
- [ ] Cheatsheet-Taste `<M-h>` — erwartet: derselbe Hilfe-Float wie bei bloßem `:UI`.
  Notiz:
- [x] `:UI help` — erwartet: aus den Routen erzeugte Hilfe, vollständig (jede Unterbefehls-Route kommt vor, nichts Veraltetes). _(auto 2026-10-29: ui.nvim/TESTS/usrcmd_help_spec.lua grün)_
  Notiz:
- [ ] Float schließen (`q`/`<Esc>`) — erwartet: sauber weg, kein Fokus-Rest.
  Notiz:
- [ ] Urteil: Lesen sich Zeilen und Texte gut? Was wirkt seltsam (Ausrichtung, Umbrüche, Icons, Farben)?
  Notiz:

Falls rot oder auffällig: jede Beobachtung als eigener Task (Regel R9), nicht hier
sammeln; Task kurz mit Befund referenzieren.

Offene Frage: Die Task nennt keine Soll-Optik; Maßstab ist dein Urteil
("rows and texts read well").

Danach: Task `ui.nvim/try-the-ui-option-float-in-a-real-session` mit `done` schließen.
