# IncRename — Keymaps

Registriert in
[lua/config/inc_rename/init.lua](../../../../../lua/config/inc_rename/init.lua),
aufgerufen aus dem `config`-Block des Plugin-Specs
([lua/plugins/lsp.lua](../../../../../lua/plugins/lsp.lua), `smjonas/inc-rename.nvim`,
`cmd = "IncRename"`).

**Wichtig:** `inc-rename.nvim` bringt selbst **kein** Keymap mit — nur den
Command `:IncRename`. Das README des installierten Plugins
(`nvim-data/lazy/inc-rename.nvim/README.md`, Abschnitt „Usage") *empfiehlt*
lediglich, sich selbst eine Map zu setzen, und zeigt dafür exakt das Snippet,
das hier 1:1 übernommen wurde. Die Map unten ist daher **[custom]**.

---

## Maps

| Mapping | Aktion | = Command | Status |
|---|---|---|---|
| `<leader>rn` | Incremental Rename starten, vorausgefüllt mit dem Wort unter dem Cursor (`expr`-Map, gibt `":IncRename " .. vim.fn.expand("<cword>")"` zurück, danach tippt man nur noch den neuen Namen) | `:IncRename <name>` | [custom] |

---

## Kontext zur Rename-Pipeline

- `require("inc_rename").setup({...})` läuft mit `cmd_name = "IncRename"`
  (= Default), `hl_group = "Substitute"`, `show_message = true`,
  `save_in_cmdline_history = true` und einem eigenen `post_hook`, der nach
  Anwenden des LSP-`WorkspaceEdit` automatisch alle betroffenen Buffer
  speichert (`write_uri_buffers`, Fallback `:silent wall`, falls der Server
  keine URIs liefert).
- `vim.o.inccommand = "split"` wird hier zusätzlich gesetzt, damit `:IncRename`
  eine Live-Vorschau im Split zeigt.
- Noice übernimmt die Cmdline-UI dafür über das `inc_rename`-Preset
  (`presets.inc_rename = true`, siehe
  [lua/config/noice/init.lua](../../../../../lua/config/noice/init.lua)) —
  betrifft nur die Eingabe-UI, nicht die Rename-Logik selbst.

Kein weiteres Keymap-Set, keine window-lokalen Maps — `:IncRename` läuft in
der normalen Cmdline (ggf. per Noice-Popup dargestellt), es öffnet kein
eigenes Fenster mit Bindings wie Trouble oder Diffview.
