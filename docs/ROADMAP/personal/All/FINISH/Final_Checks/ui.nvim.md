# ui.nvim Sticky-Context — Handover (nur offene Punkte)

## Table of content

  - [Sichtprüfung im echten Fenster](#sichtprfung-im-echten-fenster)

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

