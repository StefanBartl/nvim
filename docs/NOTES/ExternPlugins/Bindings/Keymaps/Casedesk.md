# casedesk.nvim — Keymaps

Plugin-Spec in
[lua/plugins/personal/init.lua:1414](../../../../../lua/plugins/personal/init.lua)
(`opts = {}` — keine Overrides, alle vier Keys sind casedesk.nvim's eigene
Defaults aus `bindings/keymaps.lua`).

Vier Aktionen, zwei Achsen (ein Case vs. jeder Case, Dateiname vs. Inhalt),
über `lib.nvim.bindings.keymap`s Registry gebunden — Klein-/Großschreibung
markiert die Achse: klein = aktueller Case, groß (letztes Zeichen geshiftet)
= alle Cases.

| Mapping | Modus | Aktion | = Ex-Command |
|---|---|---|---|
| `<leader>cf` | Normal | Fuzzy-Find über die Dateien des **aktuellen** Case (pickers.nvim) | `:Case files` |
| `<leader>cg` | Normal | Live-Grep im **aktuellen** Case (pickers.nvim) | `:Case grep` |
| `<leader>cF` | Normal | Fuzzy-Find über **jeden** Case in jedem Bereich (pickers.nvim) | `:Cases files` |
| `<leader>cG` | Normal | Live-Grep über **jeden** Case in jedem Bereich (pickers.nvim) | `:Cases livegrep` |

Alle vier sind weiche Abhängigkeiten von `pickers.nvim`
(telescope/fzf-lua/snacks, je nachdem was auflöst) — ohne installiertes
`pickers.nvim`, oder installiert aber ohne auflösbare Engine, meldet der
Tastendruck nur eine Warnung statt eines Fehlers.

`:Cases livegrep` (nicht `:Cases grep`) ist absichtlich: `:Cases grep
<pattern>` existiert schon länger (ripgrep → Quickfix, festes Suchmuster)
und bleibt unverändert; die neue interaktive Live-Suche über alle Cases
bekommt deshalb einen eigenen Namen statt den bestehenden Befehl zu
ersetzen.

Individuell umlegbar/deaktivierbar über `config.keymaps` (siehe casedesk.nvim
docs/configuration.md#keymaps), oder alle vier auf einmal mit
`keymaps = false`.

## Bekannte Kollision: `<leader>cf`

`<leader>cf` ist in diesem Config bereits als `config_smart` belegt
(personal/init.lua, "smart grep+find in nvim config" — snacks/pickers-Picker
gescoped auf `$NVIM_CONFIG_DIR`). casedesk.nvim's `setup()` bindet seinen
eigenen `<leader>cf` (`find_files` → `:Case files`) darüber, je nach
Ladereihenfolge — bewusst noch nicht aufgelöst (2026-09-29): siehe
casedesk.nvim's eigenes `bindings/keymaps.lua` für den `config.keymaps`-Weg,
den `find_files` dort auf einen anderen Key umzulegen, ohne den
Plugin-Default selbst zu ändern.
