# `dap.nvim`

Extrahiert aus dem alten `lua/wkddap`-Prototyp nach
[StefanBartl/dap.nvim](https://github.com/StefanBartl/dap.nvim). Wiring in
`lua/plugins/personal/init.lua` (Sektion 3, direkt nach `debugging.nvim`).

## 🟢 Nice-to-have

- [x] `nvim-dap-view` hinzugefügt: als zusätzliche Dependency + `require
  ("dap-view").setup()` (pcall-guarded) in `personal/init.lua` neben
  `nvim-dap-ui`, zum Ausprobieren als leichtere Alternative/Ergänzung.
- [ ] Custom `configurations`/`adapters`-Overrides (z. B. projektspezifische
  Go-`Debug Package`-Configs) bei Bedarf über die `opts`-Tabelle in
  `personal/init.lua` statt in dap.nvim selbst pflegen.
- [x] Zwei parallele UI-Layer aufgelöst: dap.nvim verdrahtet jetzt über
  `ui.provider` **genau eine** Panel-UI. Default ist das modernere
  `nvim-dap-view`, `nvim-dap-ui` ist opt-in (`ui.provider = "dap-ui"`);
  daneben `"auto"` (erste installierte) und `"none"`. Ist die bevorzugte
  UI nicht installiert, fällt dap.nvim auf die andere zurück und warnt.
  `<leader>dau` / `:DapToggleUI` und `<leader>dae` / `:DapEval` laufen über
  `ui/provider.lua`, bleiben also beim Umschalten identisch. Der doppelte
  `dap_view.setup()`-Call in `personal/init.lua` ist entfallen — dap.nvim
  besitzt das Wiring. Live geprüft: `provider.active() == "dap-view"`,
  Toggle öffnet/schließt (1 → 2 → 1 Fenster), alle vier Modi verhalten sich
  wie dokumentiert, `:checkhealth dap_nvim` meldet Preference + aktive UI.

---
