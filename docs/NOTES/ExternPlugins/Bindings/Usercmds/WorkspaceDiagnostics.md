# workspace-diagnostics.nvim — User-Commands

Registriert in
[lua/lsp/usercmds/workspace_diagnostics.lua](../../../../../lua/lsp/usercmds/workspace_diagnostics.lua),
aufgerufen aus dem `config`-Block in
[lua/lsp/init.lua](../../../../../lua/lsp/init.lua) (`M.setup`).

Alle Kommandos sind **[custom]** — `workspace-diagnostics.nvim` selbst bringt
keinerlei Usercmds, Keymaps oder Autocmds mit (reine Library-API: eine
Funktion `populate_workspace_diagnostics(client, bufnr)`, die alle Dateien des
Repos per `git ls-files` in Buffer lädt und Diagnostics dafür einsammelt). Das
Wann/Ob dieses Aufrufs steuert vollständig
[lua/lsp/core/workspace_diagnostics.lua](../../../../../lua/lsp/core/workspace_diagnostics.lua).

---

## Hintergrund

`workspace-diagnostics.nvim` populiert Diagnostics workspace-weit bei jedem
LSP-Attach. In großen Repos ist das teuer — Auslöser war ein 60-90s-Freeze
beim Start in einem ~600-Datei-Non-Code-Repo (siehe Kommentar in
`lsp/init.lua`). Der Startup-Default wird dort per Maschinenrolle gesetzt
(`use_workspace_diagnostics = not machine.is("workstation")`, aus in
`lsp/plugins/lsp.lua`s LazySpec übernommen). Dieses Modul macht daraus einen
**Live-Schalter obendrauf**: umschaltbar ohne Neovim-Neustart, wirkt aber erst
beim *nächsten* LSP-Attach (neuer Buffer, `:LspRestartHere`, …) — bereits
attachte Buffer werden nicht rückwirkend an-/abgeschaltet.

## Kommandos

| Kommando | Wirkung |
|---|---|
| `:LspWorkspaceDiagnosticsToggle` | Live-Schalter umlegen (an → aus / aus → an). |
| `:LspWorkspaceDiagnosticsOn` | Schalter explizit auf **an**. |
| `:LspWorkspaceDiagnosticsOff` | Schalter explizit auf **aus**. |
| `:LspWorkspaceDiagnosticsStatus` | Aktuellen Zustand anzeigen (`ON`/`OFF`). |
| `:LspWorkspaceDiagnosticsNow` | Sofort-Populate für die am aktuellen Buffer hängenden LSP-Clients — **unabhängig vom Schalter**, kein Attach/Restart nötig. |

Alle fünf sind **[custom]** — es gibt keine Plugin-Defaults, mit denen sie
kollidieren oder die sie ersetzen könnten.

## Keymaps / Autocmds

Keine. Für dieses Plugin existieren in der Config weder Keymaps noch
Autocmds — die gesamte Steuerung läuft über die fünf Usercmds oben plus den
startup-seitigen Default in `lsp/init.lua`.
