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

- [x] **`:Lazy sync` ausgeführt.** `dap.nvim` + `mfussenegger/nvim-dap`,
  `rcarriga/nvim-dap-ui`, `nvim-neotest/nvim-nio`,
  `theHamsta/nvim-dap-virtual-text`, `jbyuki/one-small-step-for-vimkind`,
  `igorlfs/nvim-dap-view` installiert und via `require('lazy').load(...)`
  verifiziert (alle `installed = true`).

- [x] **Adapter-Binaries via Mason installiert:** `js-debug-adapter`,
  `codelldb`, `delve` (`dlv.cmd`), `debugpy` — alle vier in
  `nvim-data/mason/bin/` bestätigt.

- [x] **End-to-End bis zur Registrierung verifiziert** (echter Import,
  keine Mocks): nach `require("dap_nvim").setup()` enthält das echte
  `require("dap").adapters` `codelldb, gdb, go, lldb, nlua, pwa-node, python`
  und `dap.configurations` alle 12 Sprachen/Aliase (`asm, c, cpp, gas, go,
  javascript, lua, nasm, python, rust, typescript, zig`). Ein voll
  interaktiver Breakpoint/Step-Durchlauf in einem echten Go/Python-Projekt
  steht noch aus (braucht eine laufende UI-Session, nicht headless
  automatisierbar).

## 🟡 Empfohlen

- [x] `languages = {}` bewusst beibehalten (alle 9) — Entscheidung: die
  Adapter validieren nur, sie schlagen nie hart fehl, wenn ein Binary fehlt
  (nur `:checkhealth`-Info-Zeile). Kein Grund zur Einschränkung.
- [x] `auto_install` bleibt `false` (Reserve-Feld, kein `MasonInstall`-Trigger
  im Plugin selbst); Binaries stattdessen manuell via `:MasonInstall
  js-debug-adapter codelldb delve debugpy` installiert (s.o.).
- [x] **`:checkhealth dap_nvim` gelaufen** — dabei einen echten Bug gefunden
  und behoben: `health.lua` prüfte `typescript`/`cpp` ohne Alias-Auflösung
  gegen `config.adapter_binaries` (die nur `javascript`/`c` kennt) und
  meldete fälschlich "Unknown adapter". Fix gepusht
  ([d6f09de](https://github.com/StefanBartl/dap.nvim/commit/d6f09de)) —
  jetzt zeigt `:checkhealth dap_nvim` für alle 10 Einträge ✅.
- [x] which-key-Gruppenlabel "DAP" — `:checkhealth` bestätigt `which-key
  present (keymap group label)`; da der Prefix jetzt `<leader>da` ist, keine
  Kollision mit anderen `<leader>d*`-Gruppen.

## 🟢 Nice-to-have

- [x] `nvim-dap-view` hinzugefügt: als zusätzliche Dependency + `require
  ("dap-view").setup()` (pcall-guarded) in `personal/init.lua` neben
  `nvim-dap-ui`, zum Ausprobieren als leichtere Alternative/Ergänzung.
- [ ] Altes `lua/plugins/dap.lua` (jetzt nur noch auskommentierter
  Referenz-Code, `return {}`) irgendwann ganz entfernen, sobald sich die
  dap.nvim-Wiring im echten Alltag (nicht nur beim Setup) bewährt hat.
- [ ] Custom `configurations`/`adapters`-Overrides (z. B. projektspezifische
  Go-`Debug Package`-Configs) bei Bedarf über die `opts`-Tabelle in
  `personal/init.lua` statt in dap.nvim selbst pflegen.
- [ ] Nach ein paar echten Debug-Sessions entscheiden, ob `nvim-dap-view`
  bleibt, `nvim-dap-ui` ersetzt, oder wieder entfernt wird (zwei UI-Layer
  parallel ist auf Dauer redundant).

---
