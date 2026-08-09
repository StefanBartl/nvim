# migrate.nvim

## Zweck
Findet und ersetzt veraltete Neovim-API-Aufrufe (`nvim_buf_set_option`, `vim.notify`,
`vim.highlight.*`, `vim.lsp.buf_get_clients()`/`get_active_clients()`) in der aktuellen
Zeile, einem Range, dem ganzen Buffer oder dem ganzen Arbeitsverzeichnis. Für alles
über Zeilen-Scope hinaus gibt es einen Telescope-Picker mit Preview und Batch-Apply.
Quelle: `E:\repos\migrate.nvim\README.md`.

## Nicht-standard Patterns / Algorithmen
- `lua/migrate/notify/parser/patterns.lua:18-52` (`M.track_long_string`): Ein
  zeilenbasierter State-Tracker für offene Lua-Long-Bracket-Strings (`[[ ]]`,
  `[=[ ]=]`, ...), der über mehrere Zeilen hinweg mitgeführt wird, damit ein
  `vim.notify(...)`-Aufruf *innerhalb* eines mehrzeiligen String-Literals nicht
  fälschlich als echter Code erkannt wird. Der Docstring selbst benennt die Grenze:
  "naive/line-based ... does not distinguish a bracket that's itself inside a quoted
  string or comment". Bewusster Trade-off: korrekt genug für den Regex-basierten
  Ansatz des Plugins (kein Treesitter/AST), aber explizit als unvollständig markiert
  (siehe auch `docs/Regex-statt-TS.md` im Repo — dokumentierte Entscheidung gegen
  Treesitter).
- `lua/migrate/notify/parser/extractor.lua:6-40,44-77,83-119` (`find_call_end`,
  `extract_vim_notify`, `extract_aliased`): Klammerzählung (`paren_count`) Zeichen für
  Zeichen statt eines Regex für "matching parens", weil Lua-Pattern keine
  rekursiven/balancierten Klammern unterstützen — nötig um mehrzeilige
  `vim.notify(...)`-Aufrufe korrekt zu erfassen.
- `lua/migrate/notify/parser/patterns.lua:100-129` (`is_existing_notify`): Mehrere
  Ausschluss-Checks hintereinander (nicht `vim.notify`, nicht bereits migriert, nicht
  `lib.notify`-Require) plus eine eigene Tiefenzählung für den Fall, dass die
  Level-Angabe erst in einer Folgezeile steht — Abwägung gegen False Positives bei
  einem rein zeilenbasierten Parser ohne echten Parser-Kontext.
- `lua/migrate/opt/migrator.lua:19-101`: Iteriert über eine `prefix_map`
  (`vim.api.`, `api.`, "") um denselben Migrationsschritt für alle drei üblichen
  Aufrufstile abzudecken, statt drei separate Funktionen zu schreiben — reduziert
  Code-Duplikation bei mehreren Formulierungsvarianten desselben API-Calls.

## Abgeleitete Guidelines
1. Bei zeilenbasierten Text-/Code-Transformationen ohne AST/Treesitter: Long-String-
   und Kommentar-State explizit über Zeilen hinweg tracken, nicht nur pro Zeile prüfen
   — sonst entstehen False Positives in String-Literalen oder mehrzeiligen Blöcken.
   Grenzen dieses Ansatzes im Docstring offen benennen, nicht verschweigen.
2. Für "Ende der Klammer finden" bei potenziell mehrzeiligen Aufrufen: eigene
   Klammerzählung statt Lua-Pattern verwenden (Lua-Patterns können das nicht).
3. Wiederkehrende Aufrufvarianten (verschiedene Präfixe/Aliase) über eine Lookup-
   Tabelle (`prefix_map`) iterieren statt Code zu duplizieren.
4. Reine Migrations-/Transformationslogik (z. B. `migrate_line`) von Side-Effect-Code
   (Picker, Notify, Telescope) trennen, damit sie ohne schwere Abhängigkeiten testbar
   bleibt (`lua/migrate/opt/migrator.lua:4-6` Kommentar begründet das explizit).
5. Ein generischer, wiederverwendbarer Picker (`migrate/common/picker.lua`) für
   mehrere strukturgleiche Migrations-Typen spart Duplikation gegenüber je einem
   eigenen Picker pro Migrationsart.
6. Registry-Pattern (`migrate/registry.lua`) für Enable/Disable/Command-Zuordnung
   nutzen, damit neue Migrationsmodule nur an einer Stelle registriert werden müssen
   statt an mehreren verteilten if/else-Ketten.

## Keybindings-Audit
Standardmäßig **keine** Keymaps (`config.keymaps = false`); optional aktivierbar über
`setup({ keymaps = { opt = "<leader>mo", ... } })`. Quelle:
`lua/migrate/bindings/keymaps.lua`, `docs/BINDINGS.md`.

- `keymaps.opt/notify/hl/lsp` (n, optional): Führen die jeweiligen Commands nur im
  "current line"-Modus aus (kein Argument übergeben).
  - Count sinnvoll unterstützt? **Nein.** Die Keymaps rufen den Command immer ohne
    Argument auf (`string.format("<cmd>%s<cr>", entry.command)`); ein vorangestellter
    Count (`3<leader>mo`) hat keinen Effekt. Da die Commands aber Range-fähig sind
    (`:'<,'>MigrateOpt`), wäre ein Count-Handling ("migriere N Zeilen ab Cursor")
    grundsätzlich sinnvoll möglich, ist aber nicht implementiert.
  - Autocompletion für Ex-Commands: Aus dem gelesenen Code nicht ersichtlich; die
    Commands akzeptieren `[%|cwd]` als Argument, ein `complete = function(...)`
    für diese beiden Literale wäre naheliegend, wurde aber in den gelesenen Dateien
    nicht gefunden (nicht in `usrcmds.lua` selbst implementiert, liegt vermutlich in
    `lib.nvim.usercmd.composer` — nicht Teil dieses Repos, daher nicht geprüft).
  - Fehlende Flags/Ideen: Ein "dry-run"/"preview only ohne Apply"-Flag für den
    Single-Line-Fall; Count-basiertes "migriere die nächsten N Zeilen".

Picker-Keys (Telescope-Prompt, `lua/migrate/common/picker.lua:104-163`):
  - `<CR>` (Apply Selection/Multi-Select), `<C-a>`/`<S-A>`/`<M-a>`/`<C-y>` (Apply All)
    — vier verschiedene Bindings für denselben "Apply All"-Effekt, offenbar aus
    Kompatibilitätsgründen (Kommentar: "Multiple keybindings for compatibility").
  - Count n. a. (Picker-Buffer, kein normaler Count-Kontext).
  - Autocompletion n. a. (kein Text-Input hier, nur Selektion).

## Ideen für andere Plugins
- Ein generisches "Regex/Pattern-Migrations-Framework" als eigenes Utility-Plugin
  (Registry + generischer Picker + Long-String-Tracker), das andere `*.nvim`-Projekte
  für eigene API-Migrationen wiederverwenden könnten, statt dass jedes Plugin eigene
  Parser baut.
- Ein "Deprecation-Watcher", der bei `:checkhealth` oder beim Speichern warnt, wenn
  im Buffer noch unmigrierte veraltete Calls existieren (Kombination aus
  `patterns.lua`-Erkennung + Autocommand, die migrate.nvim selbst bewusst nicht hat).
