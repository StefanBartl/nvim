# `dap.nvim`

Extrahiert aus dem alten `lua/wkddap`-Prototyp nach
[StefanBartl/dap.nvim](https://github.com/StefanBartl/dap.nvim). Wiring in
`lua/plugins/personal/init.lua` (Sektion 3, direkt nach `debugging.nvim`).

---

## 🔴 Kritisch — vor erstem produktivem Einsatz

- [x] **Keymap-Kollision mit `<leader>d`-Prefix auflösen.** Gelöst: Prefix in
  `personal/init.lua` per `opts.keymaps.prefix` auf `<leader>da` gesetzt (statt
  `<leader>d`), damit `<leader>dc`/`<leader>di`/`<leader>do` (Diffview/gitsigns/
  FzfLua) unangetastet bleiben. dap.nvim-Keys liegen jetzt unter
  `<leader>dac/das/dai/dao/dat/dar/dab/daB/daL/dal/dau/dae/daR`.

- [ ] **`:Lazy sync` ausführen**, um `dap.nvim` + neue Dependencies zu
  installieren: `mfussenegger/nvim-dap`, `rcarriga/nvim-dap-ui`,
  `nvim-neotest/nvim-nio`, `theHamsta/nvim-dap-virtual-text`,
  `jbyuki/one-small-step-for-vimkind`.

- [ ] **End-to-End-Test** für mindestens die täglich genutzten Sprachen (Go,
  Python vermutlich Priorität) — Breakpoint setzen, Continue, Step, UI öffnet
  sich automatisch (`event_initialized`).

## 🟡 Empfohlen

- [ ] `languages = {}` (= alle 9) bedeutet: `registry.register_all()` versucht
  bei jedem `setup()` alle Adapter zu laden/validieren, auch für nie genutzte
  Sprachen (Zig, Assembly, Rust falls nicht gebraucht). Ggf. explizit auf die
  tatsächlich genutzten Sprachen eingrenzen für saubereren `:checkhealth`-Output
  und minimal schnelleren Start.
- [ ] `auto_install` steht auf `false` (Default) und ist im Plugin selbst noch
  ein reines Reserve-Feld (kein `MasonInstall`-Trigger implementiert — siehe
  dap.nvim's eigene `docs/ROADMAP.md`). Vorerst Adapter-Binaries manuell/via
  `:MasonInstall js-debug-adapter codelldb delve debugpy` sicherstellen.
- [ ] `:checkhealth dap_nvim` einmal laufen lassen nach dem Sync, um zu sehen
  welche Adapter-Binaries auf diesem Rechner tatsächlich fehlen.
- [ ] which-key-Gruppenlabel "DAP" unter `<leader>d` — nach Prefix-Fix (s.o.)
  prüfen, ob das Label sauber neben den anderen `<leader>d*`-Gruppen erscheint.

## 🟢 Nice-to-have

- [ ] Prüfen, ob `nvim-dap-view` (`igorlfs/nvim-dap-view`, im alten
  auskommentierten `lua/plugins/dap.lua.md` schon mal angedacht) als leichtere
  Alternative/Ergänzung zu `nvim-dap-ui` Sinn macht.
- [ ] Altes `lua/plugins/dap.lua` (jetzt nur noch auskommentierter
  Referenz-Code, `return {}`) irgendwann ganz entfernen, sobald sich die
  dap.nvim-Wiring bewährt hat.
- [ ] Custom `configurations`/`adapters`-Overrides (z. B. projektspezifische
  Go-`Debug Package`-Configs) bei Bedarf über die `opts`-Tabelle in
  `personal/init.lua` statt in dap.nvim selbst pflegen.

---
