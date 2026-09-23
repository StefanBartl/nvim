# GS-26 — `fileops`: Konflikt-/Blame-Duplikate → gitsuite delegieren

**Repos:** fileops.nvim (gitsuite.nvim als optionaler Konsument) ·
**Nutzen** 2 · **Aufwand** 0,5 · **Risiko** niedrig · **Welle** 5 · erledigt
2026-09-22.

## Ausgangslage

`fileops.features.conflict_marks.lua` markierte Konfliktmarker mit eigenen
festen `matchadd`-Mustern (`^<<<<<<< .\+$` usw.) — dieselbe Präfix-Schwäche,
die gitsuites eigener Parser seit `GS-07` nicht mehr hat: git-Marker haben
eine **exakte** Länge (`conflict-marker-size`), und diff3/zdiff3-Basissektionen
sowie mehrdeutige `=======`-Zeilen kennt das feste Muster gar nicht.
`fileops.features.on_hold.lua`s Vorschau-Fallback (Zeile vor dem Edit
zeigen) parste selbst `git blame --porcelain`, um die SHA der zuletzt
ändernden Revision zu finden — dieselbe Aufgabe, die gitsuites
`blame.for_location` (seit `GS-04`) bereits löst.

## Umsetzung

- **fileops.nvim** (`db78b5a`):
  - `features/conflict_marks.lua`s `BufWinEnter`-Handler ruft, wenn
    installiert, `gitsuite.features.conflict.refresh(bufnr)` statt der drei
    `matchadd`-Aufrufe — Extmarks sind Buffer-, nicht Fenster-gebunden,
    daher braucht dieser Pfad kein `BufWinLeave`-Gegenstück. Ohne
    gitsuite.nvim unverändertes `matchadd`-Verhalten (`hl_a`/`hl_b`/`hl_c`
    weiterhin honoriert).
  - `features/on_hold.lua`s `get_previous_line_async()`: der Blame-Halbschritt
    (SHA-Ermittlung) läuft über `gitsuite.features.blame.for_location`
    (immer mit reinem `"git"`, nicht `cfg.git_cmd`), wenn installiert; der
    `git show`-Halbschritt bleibt immer fileops' eigener (gitsuite hat
    keine Blob-Inhalt-Entsprechung, siehe Querschnittsbefund 1 des
    Cross-Feature-Reports). `show_line_at()` als gemeinsame Hilfsfunktion
    für beide Pfade extrahiert.

## Tests

`TESTS/autocmds_spec.lua`: neuer Block — gefaktes
`gitsuite.features.conflict`, belegt genau einen `refresh(bufnr)`-Aufruf
und dass der `matchadd`-Fallback nie erreicht wird.
`TESTS/on_hold_preview_spec.lua`: neuer Block (echter Throwaway-Git-Repo) —
gefaktes `gitsuite.features.blame.for_location` liefert die reale
Commit-SHA, belegt End-to-End, dass der `git show`-Schritt danach noch den
echten committeten Inhalt rendert. `stylua`/`luacheck` grün, volle Suite
grün (922 Checks, war 915 vor `GS-25`+`GS-26` zusammen).

## Ergebnis

CI grün auf allen Systemen (`gh run view 35761302388` bestätigt `completed
success`).

## Dokumentation mitgezogen

`docs/FEATURES/INTEGRATIONS.md` (neuer Abschnitt "gitsuite.nvim backing
conflict_marks and on_hold"), `docs/installation.md`, `doc/fileops.txt`
(`conflict_marks`/`on_hold`-Abschnitte erweitert).
