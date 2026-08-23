# `cascade.nvim`
kannst du dias feature in C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\cascade.nvim.md umsetzen, docs/vimdoc updaten, auch C:/Users/bartl/AppData/Local/nvim/docs/NOTES/BINDINGS, und auf main comitten/pushen und dann pulen
> **Status: umgesetzt am 2026-08-23** — cascade.nvim `main`, Commits
> `0632216` (feat) und `bf6db1b` (docs). Umsetzung folgt dem Konzept unten
> unverändert; Details siehe „Ergebnis" am Ende.

## Konzept: Renumbering nur innerhalb einer Selektion

Motiviert durch zwei Fälle, die das heutige `:Cascade renumber` /
`lists/renumber.lua` **nicht** abdeckt (`marker.parse` verlangt die Nummer
als allererstes Token der Zeile — [`lua/cascade/lists/marker.lua:86`](file:///E:/repos/cascade.nvim/lua/cascade/lists/marker.lua)):

1. Markdown-Headlines mit eingebetteter Nummer (`### 2. iwas` … `### 3. sad`)
   — nur der markierte Headline-Block soll neu nummeriert werden, nicht die
   ganze Datei/alle Ebenen.
2. Reine Inline-Zahlen in Prosa/`.txt`, auch **mitten in einer Zeile**
   selektiert (z. B. `te 4. text der nur als 5. beispiel ... um wa`) — filetype-
   unabhängig, kein Listenkontext.

Beides ist strukturell derselbe Vorgang: „scanne die Selektion nach einem
Nummer-Pattern in Erscheinungsreihenfolge, schreibe die Treffer sequenziell
neu" — unabhängig davon, was vor der Zahl steht. Deckt automatisch auch den
Headline-Fall ab, ohne dass Markdown-Sonderwissen nötig ist.

### Entscheidungen (2026-08-17)

- **Eigene Domäne**, nicht Erweiterung von `lists/renumber.lua` — analog zu
  `cycle`/`transpose` (global, filetype-unabhängig, kein `marker.parse`
  nötig). Vorschlag Modulname: `lua/cascade/sequence/renumber.lua` +
  Config-Key `sequence`.
- **Pattern-Scope: alles** — digit (`1.`), alpha (`a.`), roman (`I.`), wie bei
  den echten Listenmarkern (`kind`-Erkennung aus `lists/marker.lua`
  wiederverwendbar für die Wert→Zahl/Zahl→Wert-Konvertierung, auch wenn das
  Parsing selbst neu ist).
- **Startwert: beide Optionen**, konfigurierbar (kein fest verdrahtetes
  Verhalten):
  - `keep` (Default) — erster Treffer legt den Startwert fest (Konsistenz mit
    `lists/renumber.lua`s bestehendem Verhalten, z. B. `base_start`/`start_val`
    in [`renumber.lua:157`](file:///E:/repos/cascade.nvim/lua/cascade/lists/renumber.lua)).
  - `one` — erzwingt Neustart bei `1`/`a`/`i`, unabhängig vom ersten Treffer.
- **Trennzeichen (`.` vs `)`): pro Treffer beibehalten**, nicht auf den ersten
  Treffer vereinheitlichen — geringste Überraschung, erlaubt gemischte Stile
  im selektierten Text unverändert zu lassen; nur die Zahl wird ersetzt.
- **`lib.nvim` verwenden wo möglich.** `lib.nvim.selection` liefert bereits
  genau die zwei Selektions-Formen, die die beiden Motivationsfälle brauchen:
  - `M.lines()` — 0-based Row-Range der aktiven linewise (`V`) Selektion → Fall 1
    (Headline-Block).
  - `M.chars()` — 0-based Row + inclusive Byte-Spalten der aktiven
    **einzeiligen** charwise (`v`) Selektion → Fall 2 (Inline-Zahlen mitten in
    einer Zeile).
  - Beide sind in [`E:\repos\lib.nvim\lua\lib\nvim\selection\init.lua`](file:///E:/repos/lib.nvim/lua/lib/nvim/selection/init.lua)
    bereits fertig und getestet (u. a. von `_swap_visual` in cascade selbst
    genutzt) — nicht neu bauen.
  - **Bekannte Lücke:** eine *mehrzeilige* charwise-Selektion (`v` über
    Zeilenumbruch hinweg) deckt `lib.nvim.selection` heute nicht ab
    (`M.chars()` gibt `nil` zurück, sobald `row_v ~= row_d`). Für v1 bewusst
    nicht lösen (passt zur Haltung aus dem verworfenen
    Renumbering-Anchor-Konzept in `cascade.nvim` — kein Subsystem für einen
    Fall bauen, der (noch) nicht konkret gebraucht wurde). Deckt beide
    genannten Use-Cases trotzdem vollständig ab. Falls der Bedarf real wird:
    `lib.nvim.selection` um ein `M.chars_multiline()` erweitern (gehört dort
    hin, nicht cascade-lokal nachgebaut).
  - Für den Schreibvorgang bei Fall 2 (Teil-Zeile) `nvim_buf_set_text` nutzen
    (exakte Byte-Range), nicht `nvim_buf_set_lines`.
  - Reselect nach dem Edit über `lib.nvim.selection.keep_lines`/`keep_chars`
    (Wrapper, die genau „capture → mutate → reselect" kapseln) statt eigener
    `feedkeys`-Logik.
  - `:Cascade`-Subcommand weiterhin über `lib.nvim.usercmd.composer`
    (bestehende Konvention), Keymap über `lib.map`/`cascade.util.lib`-Bridge.

### Bedienung (Vorschlag)

- Visual-Mode-Keymap (nicht nur `:`-Ex-Command!), weil Ex-Command-Ranges
  (`:'<,'>...`) in Vim immer linewise sind und die Spalteninfo für Fall 2
  verwerfen würden — Vorschlag `<leader>cR` (Großbuchstabe, Abgrenzung zu
  `<leader>cr` = ganzer Block).
- `:Cascade renumber selection` als Ex-Command-Pendant für den linewise-Fall
  (Fall 1), das den vorhandenen `:Cascade renumber`-Ast ergänzt, nicht ersetzt.

### Nicht vergessen bei der Umsetzung

- [x] `cascade.nvim`: `docs/BINDINGS.md` (Source of Truth im Plugin-Repo)
- [x] `cascade.nvim`: neue `docs/FEATURES/SEQUENCE.md` (eigene Domäne, daher
      nicht in `LISTS.md`); `docs/WORKFLOW.md` + `docs/TESTS/README.md`
      Index-Zeilen, `doc/cascade.txt` neuer Abschnitt `cascade-sequence`
- [x] `cascade.nvim`: `README.md` Feature-Tabelle
- [x] nvim-Config: [`docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/cascade.nvim.md`](../../NOTES/PersonelPlugins/BINDINGS/Keymaps/cascade.nvim.md)
- [x] nvim-Config: [`docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/cascade.nvim.md`](../../NOTES/PersonelPlugins/BINDINGS/Usercmds/cascade.nvim.md)
- [x] `Checklists/belege/plugins/cascade.nvim.md`
      (`C:/repos/WKDBooks/Development/wkdbook-Lua/Checklists`, nicht mehr `E:`)
      — `<leader>cR` im Keybindings-Audit ergänzt

### Offen

- [x] Implementierung `lua/cascade/sequence/renumber.lua` (Pattern-Scan,
      Start-Modus `keep`/`one`, Separator-per-Treffer)
- [ ] `lib.nvim.selection`: ggf. `chars_multiline()` ergänzen, falls Bedarf
      über die beiden o.g. Fälle hinaus entsteht (bewusst zurückgestellt)
- [x] Config-Schema (`sequence = { enable, start = "keep"|"one", types = {...} }`)
- [x] Keymap `<leader>cR` (x-Mode) + `:Cascade renumber selection`

### Ergebnis (2026-08-23)

Umgesetzt wie entworfen, ohne Abweichung vom Konzept:

- `lua/cascade/sequence/renumber.lua` — reines `rewrite(text, opts, state)`
  plus die zwei Buffer-Einstiege `range` (linewise) und `span` (einzeilig
  charwise, via `nvim_buf_set_text`). Der `state`-Table trägt Zähler *und*
  festgelegte `kind` über mehrere Zeilen einer Selektion.
- **Kind-Lock:** der *erste* Treffer legt digit/ascii/roman fest (Reihenfolge
  aus `sequence.types`); Treffer anderer Arten werden danach übersprungen
  statt in dieselbe Sequenz gefaltet — ein `a)` mitten in nummerierten Items
  bleibt unangetastet.
- **Prosa-Abgrenzung:** der alphanumerische Run wird greedy gematcht (die `1`
  in `v1.2` wird nie einzeln gesehen), und nach dem Delimiter muss Whitespace
  oder Zeilenende folgen — damit fallen Dezimalzahlen (`3.14`) und
  Abkürzungen (`e.g.`) raus.
- Separator pro Treffer beibehalten, Groß-/Kleinschreibung vom ersetzten
  Token übernommen (`ii.`→`iii.`, `II.`→`III.`).
- `<leader>cR` ist bewusst **nur** x-Mode; `:Cascade renumber selection` deckt
  den linewise-Fall als Ex-Pendant ab.
- `config/init.lua` normalisiert `sequence` (unbekannter `start` → `keep`,
  leere `types` → Default), damit ein Tippfehler nicht mitten im Scan knallt.
- `:checkhealth cascade` meldet die Domäne mit `types` und Start-Modus.
- Specs: `docs/TESTS/sequence_spec.lua`, im Runner registriert; Suite grün
  (`nvim --headless -u NONE -c "set rtp+=." -c "set rtp+=C:/repos/lib.nvim"
  -c "luafile docs/TESTS/run.lua" -c "qa!"` → `CASCADE_TESTS_OK`).

Weiterhin offen bleibt bewusst nur die mehrzeilige charwise-Selektion — die
gehört, falls der Bedarf real wird, als `chars_multiline()` in `lib.nvim`.

---
