# GS-23 — `:Git status relink` (Markdown-Links nach Rename)

**Repos:** gitsuite.nvim (filetree.nvim als optionaler Konsument) ·
**Nutzen** 3 · **Aufwand** 1,0 · **Risiko** hoch · **Welle** 5 · erledigt
2026-09-22.

## Ausgangslage

`git status` erkennt Renames (Code `R`), aber nichts aktualisiert die
Markdown-Links (oder Lua/Python/TS-JS-Importe), die noch auf den alten Pfad
zeigen. `filetree.nvim`s Referenz-Engine (`filetree.refs`) löst genau dieses
Problem bereits für den eigenen `smart_rename`-Flow — die Bausteine
existierten, waren aber laut Report ungenutzt für einen bereits *extern*
passierten Rename (z. B. `git mv` außerhalb von filetree.nvim).

## Umsetzung

- **gitsuite.nvim** (`43876d1`): neues Modul
  `lua/gitsuite/features/status/relink.lua`. `M.relink()`:
  1. `git.status_porcelain()` nach Einträgen mit `code:sub(1,1)=="R"` oder
     `code:sub(2,2)=="R"` filtern (reine Kopien — Code `C` ohne `R` — bleiben
     unangetastet: die alte Datei existiert dort noch, ihre Referenzen sind
     weiterhin korrekt).
  2. `filetree.refs.scan(old_paths, {op="rename", mode="ask"})` — der
     Scan-Schritt plant rein aus dem Basename des alten Pfads (siehe
     `providers/markdown.lua`s `plan()`), liest die alte Datei selbst nie,
     kümmert sich also nicht darum, dass sie zum Zeitpunkt des Aufrufs schon
     umbenannt ist.
  3. `filetree.refs.handle_result(result, moves, {op="rename", mode="ask"})`
     — `mode="ask"` erzwungen (unabhängig von filetree.nvim's eigenem
     `refs.on_rename`-Default), damit `:Git status relink` nie still in
     fremde Dateien schreibt: immer Preview/Diff/Auswahl über
     `filetree.refs.ui.apply_with_confirmation` ("Update all" / "Select…" /
     "Show diff" / "Leave as-is").
  4. Neue Route `:Git status relink` in `lua/gitsuite/bindings/usrcmds.lua`.

## Tests

`TESTS/gitsuite/relink_spec.lua` (3 Fälle, echter Throwaway-Git-Repo): ohne
filetree.nvim installiert (klare Fehlermeldung, kein Crash), ohne renamte
Dateien (kein `refs.scan()`-Aufruf), und der Kernfall — echter `git mv` in
einem committeten Repo, gefaktes `filetree.refs` fängt `scan()`/
`handle_result()`-Aufrufe ab und belegt die korrekten absoluten Pfade
(`old_abs -> new_abs`) sowie `mode="ask"` in beiden Aufrufen. `stylua`/
`luacheck` grün, volle gitsuite-Suite grün.

## Ergebnis

CI grün auf allen drei Systemen (`gh run view 35758424579` bestätigt
`completed success`).

## Dokumentation mitgezogen

`docs/BINDINGS.md` (neue Zeile zwischen `quickfix` und `repo`, alphabetisch),
`docs/requirements.md` (neue Zeile für filetree.nvim als optionale
Abhängigkeit).
