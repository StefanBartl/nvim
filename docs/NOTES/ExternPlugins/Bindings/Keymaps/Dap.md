# nvim-dap (via StefanBartl/dap.nvim) — Keymaps

`nvim-dap` selbst bringt **keine einzige Default-Keymap** mit (Design-
Entscheidung des Plugins, siehe dessen README: "The arrow keys are good
candidates for keymaps…" — bewusst dem Nutzer überlassen). Alles, was hier
dokumentiert ist, stammt daher von `StefanBartl/dap.nvim` — einem
Wrapper-Plugin (eigenes Repo, `E:/repos/dap.nvim`), das über
`mfussenegger/nvim-dap` und die UI-Provider (`nvim-dap-view` /
`rcarriga/nvim-dap-ui`) sitzt und dessen rohe Lua-API bindet.

Deklariert in
[lua/plugins/personal/init.lua](../../../../../lua/plugins/personal/init.lua)
(`"StefanBartl/dap.nvim"`-Block), gesetzt via
`opts.keymaps.prefix = "<leader>da"` — überschreibt den Wrapper-Default
`<leader>d` bewusst, weil `<leader>d` allein bereits mit git-/fzf-Mappings
kollidiert (`dc` = DiffviewClose, `di` = ToggleInlineDiff, `do` = FzfLua
diagnostics).

Quelle im Wrapper: `lua/wkddap/bindings/keymaps/init.lua` im Repo
`E:/repos/dap.nvim` (eigenes Repo, liegt außerhalb dieser Config — kein
relativer Link möglich, anderes Laufwerk).

Alle Einträge sind **[custom]** — es gibt keine nvim-dap-Defaults, die sie
überschreiben oder ergänzen; der Wrapper *ist* die einzige Quelle für
Keymaps in diesem Setup.

---

## Gruppe `<leader>da` — "DAP"

### Session-Kontrolle

| Mapping | Aktion | nvim-dap-Funktion |
|---|---|---|
| `<leader>dac` | Continue / Start | `dap.continue()` |
| `<leader>das` | Step Over | `dap.step_over()` |
| `<leader>dai` | Step Into | `dap.step_into()` |
| `<leader>dao` | Step Out | `dap.step_out()` |
| `<leader>dat` | Terminate | `dap.terminate()` |
| `<leader>dar` | Restart | `dap.restart()` |

### Breakpoints

| Mapping | Aktion | nvim-dap-Funktion |
|---|---|---|
| `<leader>dab` | Toggle Breakpoint | `dap.toggle_breakpoint()` |
| `<leader>daB` | Conditional Breakpoint (Prompt für Condition) | `dap.set_breakpoint(cond)` |
| `<leader>daL` | Log Point (Prompt für Message) | `dap.set_breakpoint(nil, nil, msg)` |
| `<leader>dal` | List Breakpoints | `dap.list_breakpoints()` |

### UI (routet auf den aktiven Provider — Default `dap-view`)

| Mapping | Modus | Aktion |
|---|---|---|
| `<leader>dau` | n | Toggle UI (`wkddap.ui.provider`) |
| `<leader>dae` | n | Evaluate Expression |
| `<leader>dae` | v | Evaluate Selection |

### REPL

| Mapping | Aktion | nvim-dap-Funktion |
|---|---|---|
| `<leader>daR` | Open REPL | `dap.repl.open()` |

---

## which-key-Anbindung

Der Wrapper registriert nur ein **Gruppen-Label** für den Prefix (`+DAP`) via
`lua/wkddap/bindings/which_key/init.lua` (im Wrapper-Repo) —
which-key ist Soft-Dependency, unterstützt v2 (`register`) und v3 (`add`).
Die Beschreibungen der einzelnen Keys kommen wie bei Harpoon aus dem `desc`
der jeweiligen `vim.keymap.set`-Aufrufe, nicht aus dem which-key-Spec selbst.
Abschaltbar über `opts.which_key.enable = false`; in dieser Config nicht
gesetzt → Default `true` aktiv.

## Steuerung

Alle Keymaps sind an `opts.keymaps.enable` gekoppelt (Default `true`, in
dieser Config nicht überschrieben). `keymaps.setup()` requirt `dap` eager,
um die Funktionen direkt zu binden — schlägt das fehl (nvim-dap fehlt), wird
nur eine Warnung geloggt, which-key/Autocmds werden trotzdem gesetzt.
