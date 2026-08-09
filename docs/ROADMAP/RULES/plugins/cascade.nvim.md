# cascade.nvim

## Zweck
Kontextbewusste Listen- und Zeichen-Manipulation: Listen fortsetzen/renumerieren/Checkboxen
togglen/Marker-Typen zyklen (Markdown/Prose-Filetypes), Wörter/Zahlen/Daten unter dem Cursor
zyklen (global), sowie UTF-8-sicheres Zeichen-Swap mit dem Nachbarn (global). Ein durchgängiges
Muster trägt das ganze Plugin: "detect context → advance one step → sonst nativer Fallback".

## Nicht-standard Patterns / Algorithmen

- `lua/cascade/init.lua:155-184` (`indent_lines_work`) — der `count` bei `<A-Right>`/`<A-Left>`
  bedeutet bewusst "wie viele Zeilen", nicht "wie viele Ebenen" (das alte Verhalten wandert nach
  `<leader><A-Right>`, siehe `indent_levels_work:186-204`). Grund laut Kommentar: Für nummerierte
  Outlines ist "N Geschwisterzeilen gemeinsam eine Ebene höher/tiefer" der häufigere Wunsch als
  "eine Zeile N Ebenen tief" — bewusste, dokumentierte Abkehr vom naiven "count = repeat native key"
  Vim-Idiom.
- `lua/cascade/lists/renumber.lua` (via README + init.lua:222-236) — Renumbering ist Level-aware:
  beim Einrücken einer nummerierten Liste startet jede tiefere Ebene neu bei `1.`, beim Verlassen
  wird die Lücke der Ausgangsebene geschlossen. Zusätzlich behandelt es "lazy continuation"
  (Markdown-Regel: eine Nicht-Marker-/Nicht-Leerzeile ohne vorausgehende Leerzeile bricht die
  Sequenz nicht) korrekt statt naiv jede Nicht-Marker-Zeile als Blockende zu werten.
- `lua/cascade/init.lua:32-118` (`lists_active`, `ft_in`, `lf`/`cf`/`xf`) — jede Aktion baut genau
  EINEN `CascadeContext` pro Aufruf (`Context.new()`) und reicht ihn durch, statt Cursor-Position/
  Zeile/Filetype mehrfach frisch abzufragen — vermeidet TOCTOU-artige Inkonsistenzen zwischen
  Gating-Check und Ausführung innerhalb desselben Tastendrucks.
- `lua/cascade/dispatch/init.lua:32-44` — generisches Chain-of-Responsibility `M.try(handlers, ctx)`
  mit `pcall` um jeden einzelnen Handler: ein werfender Handler wird als "nicht gehandhabt"
  gewertet statt den ganzen Keymap-Callback abzureißen — verhindert, dass ein Bug in einem
  Detector die komplette Tastenbindung (und damit z.B. `<CR>` im Insert-Mode) lahmlegt.
- `lua/cascade/core/patterns.lua:14-39` — Lua-Pattern-Fragmente (z.B. Marker-Charclass aus
  `unordered_markers`-Config) werden über einen simplen String-Join-Key memoisiert, weil sie sich
  nur bei Config-Änderung ändern, aber potenziell bei jedem Tastendruck (jeder `<CR>`/`o`/Cycle)
  neu gebraucht würden — Vermeidung wiederholter Pattern-String-Konstruktion im Hot Path.
- `lua/cascade/util/dotrepeat.lua` — zentrale Dot-Repeat-Fassade: jede wiederholbare Aktion
  registriert sich unter einem stabilen String-Key in einer Store-Tabelle; `.` repliziert über
  Neovims `operatorfunc`+`g@`-Mechanismus. Vermeidet, dass jedes einzelne Feature (checkbox toggle,
  cycle, transpose, rotate, sort, …) den operatorfunc-Trick selbst re-implementiert; ruft zusätzlich
  optional `vim-repeat`s `repeat#set` mit auf, ohne davon abhängig zu sein (rein additiv, siehe
  `util/lib.lua`-Bridge).
- `lua/cascade/init.lua:318-360` (`cycle_word_work`) — dreistufige Fallback-Kaskade pro Tastendruck:
  ISO-Datum (kalenderbewusst) → Wort/Boolean-Cycle → natives `<C-a>`/`<C-x>` bei rein numerischem
  Token → native Bedeutung der drückenden Taste selbst (`+`/`-` bewegen dann normal die Zeile).
  Bewusst so geschichtet, damit z.B. `+`/`-` niemals ihre eingebaute Vim-Bedeutung verlieren, wenn
  keine der spezialisierten Interpretationen zutrifft.
- README (Safety & performance design decisions, Zeile 75-80) — bewusster Verzicht auf
  `CursorMoved`/`TextChanged`-Autocmds (nur explizite Tastenanschläge lösen Arbeit aus) und auf
  Treesitter als harte Abhängigkeit (nur Opt-in via `lists.precision = "treesitter"` für den einen
  Fall, den reines Line-Scanning nicht erkennen kann: Listenmarker innerhalb eines Markdown-Fenced-
  Code-Blocks). Explizite Performance-Entscheidung gegen ständig laufende Autocmd-Handler.
- `lua/cascade/init.lua:640-672` (`_swap_visual`) — beim Selection-Swap wird nach dem Tausch die
  *neue*, vom Aufruf zurückgegebene Spannweite reselektiert (`new_scol, new_ecol`), nicht die
  ursprüngliche — weil der Nachbar eine andere Byte-Breite als die Selektion haben kann und sich
  die Selektion dadurch verschiebt (UTF-8-Bewusstsein).

## Abgeleitete Guidelines

1. Bei kontextabhängigen Tastenbelegungen konsequent das Muster "detect → advance → native
   fallback" verwenden, mit EINEM Kontextobjekt pro Aufruf, nicht mehrfachem Nachfragen von
   Cursor/Buffer-Zustand über den Aufruf verteilt.
2. Handler-Ketten (Chain of Responsibility) grundsätzlich mit `pcall` je Handler umschließen,
   damit ein einzelner defekter Detector nie den gesamten Tastendruck/Fallback zerstört.
3. Bei `count`-Semantik für ungewöhnliche Editier-Operationen (Indent-Level vs. Zeilenanzahl)
   die naheliegendere/häufiger gebrauchte Bedeutung auf die bloße Taste legen, die seltenere
   hinter `<leader>` verschieben — und beides im Docstring/README explizit benennen, damit es
   nicht zu stillem Verhaltensunterschied gegenüber Vim-Konventionen wird.
4. Dot-Repeat über eine zentrale Fassade (Key-Store + `operatorfunc`/`g@`) anbieten statt je
   Feature eigene Repeat-Logik zu schreiben; optional zusätzlich `vim-repeat` bedienen, aber nie
   davon abhängen.
5. Teure/wiederholt gebrauchte, aber Config-stabile Artefakte (z.B. aus Lua-Patterns generierte
   Charclasses) mit einem simplen Join-Key memoisieren statt bei jedem Tastendruck neu zu bauen.
6. Autocmd-getriebene "always watching" Mechanik (`CursorMoved`/`TextChanged`) vermeiden, wenn
   explizite Tastenbindungen ausreichen — spart Overhead und unerwartete Seiteneffekte beim reinen
   Cursor-Bewegen.
7. Teure Analyse (Treesitter) nur opt-in für den einen Fall anbieten, den der günstige Default
   (Line-Scan) nachweislich nicht lösen kann — nicht pauschal als harte Abhängigkeit einführen.
8. Bei Selection-basierten Transformationen, die die Selektionsgröße verändern können (z.B.
   durch unterschiedliche Byte-Breiten bei UTF-8-Zeichen), immer die tatsächlich neue Spannweite
   vom Transform zurückgeben lassen und reselektieren — nie die alte Spannweite blind wiederverwenden.
9. Globale vs. Filetype-scoped Domains im Config-Schema explizit trennen (`lists.filetypes` vs.
   `cycle.filetypes = nil` für global) und das in der README tabellarisch dokumentieren — Nutzer
   sollen nie raten müssen, ob ein Feature überall oder nur in bestimmten Buffern wirkt.
10. Jede Aktion als einfache Funktion auf dem Public-Facade-Modul exportieren (kein `<Plug>`-
    Mapping-Umweg), damit Nutzer sie 1:1 mit `vim.keymap.set` binden können.

## Keybindings-Audit

Aus `lua/cascade/bindings/keymaps.lua` + README (Preset, `keymaps.preset = true`):

- `<CR>` (insert, list filetypes) — Continue list. Count n/a (Insert-Mode-Aktion).
- `o` / `O` (normal, list filetypes) — Open item below/above. Count n/a (single-shot).
- `<leader>cx` (normal) — Toggle/cycle checkbox. Dot-repeatable, aber kein `count`-Handling
  gesehen (`checkbox_work` in init.lua:242-252 liest keinen `vim.v.count`) — für "N Zeilen ab
  Cursor togglen" fehlt Unterstützung; wäre plausible Erweiterung.
- `<A-->`/`<A-*>`/`<A-0>`/`<A-c>` (normal+visual) — Quick bullet/star/number/checkbox toggle.
  Visual-Variante deckt Multi-Line ab (jede Zeile individuell), Normal-Variante hat keinen
  Count-Support — `3<A-->` togglet nur die aktuelle Zeile, nicht 3 Zeilen. Lücke, aber Visual-Mode
  deckt den Use-Case funktional ab.
- `<leader>ct`/`<leader>cT` (normal) — Cycle list type vor/zurück. Kein Count (n/a, zyklische
  Einzelaktion).
- `<leader>cr` (normal) — Renumber block. Kein Count nötig (deterministische Blockoperation).
- `<leader>cf`/`<leader>cF` (normal+visual) — Rotate form vor/zurück. Kein Count-Bedarf ersichtlich.
- `<leader>cs`/`<leader>cv`/`<leader>cX` (normal+visual) — Sort/Reverse/Strip. Blockweite
  Operationen, Count n/a.
- `<C-y>`/`<C-x>`, `+`/`-` (normal, global) — Word/number cycle. Kein `count`-Support in
  `cycle_word_work` (init.lua:330-361) — `3<C-y>` würde z.B. dreimaliges Zyklen erwarten können,
  aktuell wird `count` verworfen. Für Boolean-Zyklen semantisch fragwürdig, aber bei
  Datumsschritten (`date.step`) wäre `3<C-y>` = "+3 Tage" naheliegend und fehlt.
- `<leader>cp` (normal) — Interactive picker für Cycle-Gruppe. Nutzt `vim.ui.select`
  (Telescope-backed falls registriert) — hat also Auswahl-Autocompletion im Sinne eines Pickers.
  Kein `count`-Bezug, n/a.
- `<A-Right>`/`<A-Left>` (normal/visual/insert) — Indent/Dedent. **Hat** durchdachten
  Count-Support: `N<A-Right>` = N Zeilen je 1 Ebene, `N<leader><A-Right>` = 1 Zeile N Ebenen
  (init.lua:155-204) — vorbildlich explizit dokumentiertes Doppel-Count-Schema.
  Insert-Mode fällt auf natives `<C-t>`/`<C-d>` zurück (kein eigenes Count-Handling nötig).
- `<A-Up>`/`<A-Down>` (normal/visual/insert) — Move line/selection. Kein Count-Handling in
  `M._move`/`_move_visual` erkennbar — `3<A-Down>` bewegt nur eine Zeile, nicht 3-fach. Lücke.
- `<leader><Right>`/`<leader><Left>` (normal/visual) — Char/selection swap. Kein Count-Support
  (`swap_work`, init.lua:628-637) — `3<leader><Right>` würde 3 Positionen weiterschieben können,
  ist aber nicht implementiert.
- `:Cascade <subcommand>` — hat vollständige `<Tab>`-Completion über `lib.nvim.usercmd.composer`
  (laut README), Range-aware, `!`-Bang für Rückwärtsrichtung. Vorbildliche Ex-Command-UX.

Fehlende Flags/Optionen (Ideen):
- Kein `count`-Support bei Cycle (`<C-y>`/`<C-x>`), Move (`<A-Up>`/`<A-Down>`) und Quick-Toggle
  im Normal-Mode — durchgängige Lücke gegenüber dem sonst sehr bewussten Count-Design bei
  Indent/Dedent. Wert für Konsistenz: alle genannten könnten `vim.v.count1`-Wiederholungen
  respektieren, analog zu `indent_lines_work`.
- `cycle.groups`/`per_filetype` sind rein statisch aus Config; kein Live-Add/Edit-Command
  (z.B. `:Cascade cycle add {a},{b}`), obwohl das Plugin sonst viel über `:Cascade` exponiert.

## Ideen für andere Plugins

- Die zentrale `dotrepeat.lua`-Fassade (Store + `operatorfunc`/`g@`-Bridge, optionale
  `vim-repeat`-Interop) ist generisch genug, um als eigenständiges kleines lib.nvim-Modul für
  alle Plugins herausgelöst zu werden, statt dass künftige Plugins sie erneut nachbauen.
  (cascade.nvim tut das bereits über `util/lib.lua` als Bridge — konsequent auf lib.nvim heben.)
- Das "detect → advance → native fallback"-Muster mit einem pro-Aufruf-Kontextobjekt und
  Chain-of-Responsibility-Dispatch (`dispatch/init.lua`) ist ein wiederverwendbares Architektur-
  Template für jedes Plugin, das native Tasten kontextabhängig überlagert (z.B. ein smartes
  `<Tab>` für Snippets/Completion/Indent) — lohnt sich als dokumentiertes Pattern in den
  Plugin-Guidelines, nicht nur als Cascade-internes Detail.
- Das kalenderbewusste ISO-Datum-Cycling (`cycle/date.lua`) könnte als eigenständiges Feature/
  Plugin "datewalker.nvim" verallgemeinert werden: Cursor-Position im Datum bestimmt Jahr/Monat/
  Tag-Segment, inkl. Rollover-Handling — nützlich auch außerhalb von Listen-Kontexten (z.B. in
  Log-Dateien, Commit-Messages).
