# Bindings-Doku — offene Plugins

Fortschritt der Doku-Initiative unter `docs/NOTES/ExternPlugins/Bindings/{Keymaps,Autocmds,Usercmds}/`.
Ziel: alle extern per `require`/Lazy-Spec eingebundenen Plugins mit tatsächlich
aktiven Bindings dokumentieren, jeweils `[default]` vs. `[custom]` markiert.

Basis: Survey vom 2026-07-29 über `lua/plugins/*.lua` (~60 externe Specs, davon
26 mit aktiven Bindings — reine Dependencies/Type-Stubs/deaktivierte Specs ohne
eigene Bindings sind ausgeschlossen).

Nachtrag 2026-09-01: `blink.cmp` stand im Survey noch als „deaktiviert" in der
Ausschlussliste. Seit dem Default-Wechsel in `lsp.nvim` (2026-08-24) ist es die
aktive Completion-Engine und hat eigene `[custom]`-Keys — daher 27 statt 26,
siehe [Keymaps/Blink.md](Keymaps/Blink.md).

## Erledigt (27 / 27) — komplett

- [x] `ThePrimeagen/harpoon` — bereits vor dieser Initiative dokumentiert
- [x] `nvim-telescope/telescope.nvim` + `nvim-telescope/telescope-file-browser.nvim`
- [x] `nvim-neo-tree/neo-tree.nvim` + `mrbjarksen/neo-tree-diagnostics.nvim` + `TimCreasman/neo-tree-tests-source.nvim` + `s1n7ax/nvim-window-picker`
- [x] `folke/snacks.nvim`
- [x] `lewis6991/gitsigns.nvim`
- [x] `tpope/vim-fugitive`
- [x] `sindrets/diffview.nvim`
- [x] `kdheepak/lazygit.nvim`
- [x] `NeogitOrg/neogit`
- [x] `folke/trouble.nvim`
- [x] `smjonas/inc-rename.nvim`
- [x] `stevearc/conform.nvim`
- [x] `artemave/workspace-diagnostics.nvim`
- [x] `mfussenegger/nvim-dap` (via `StefanBartl/dap.nvim`)
- [x] `nvim-treesitter/nvim-treesitter`
- [x] `folke/noice.nvim`
- [x] `folke/todo-comments.nvim`
- [x] `mg979/vim-visual-multi`
- [x] `nvzone/menu`
- [x] `nvchad/ui`
- [x] `nvim-neotest/neotest`
- [x] `chrisbra/unicode.vim`
- [x] `FabianWirth/search.nvim`
- [x] `saghen/blink.cmp` — nachgezogen 2026-09-01, siehe Nachtrag oben

## Findings aus der Doku-Initiative — Status

- [x] **Snacks.nvim**: War bereits durch einen parallelen Commit des Users gefixt
      (`62b939dd fix(snacks): restore setup() and drop the custom dashboard`).
      `setup()` läuft jetzt über lazy.nvims implizites `config` (nur `opts`,
      kein eigener `config`-Block mehr), `custom_dashboard/` wurde komplett
      entfernt. Doku (Keymaps/Autocmds/Usercmds/Snacks.md) wurde entsprechend
      nachgezogen/bereinigt.
- [x] **NeoTree `git_status`**: Kein Bug — beim Nachprüfen stellte sich heraus,
      dass `A`/`gr` in `git_status.lua` **einmal** vorkommen (kein doppelter
      Key im selben Table). Die ursprüngliche Analyse hat zwei Layer verwechselt:
      neo-tree-eigener Default (`git_add_all`/`git_revert_file` aus
      `defaults.lua`) vs. bewusster `noop`-Override in dieser Config für die
      `git_status`-Quelle — Absicht laut Datei-Kommentar, keine Kollision.
      Doku korrigiert.
- [x] **Lazygit**: `:LazyGitLog` fehlte in der `cmd`-Liste des Lazy-Specs
      (`lua/plugins/git.lua`) — ergänzt.
- [x] **Conform**: `conform.setup()` wurde zweimal aufgerufen (`lsp.lua` und
      `lsp/formatter/conform.lua`). Redundanten ersten Call (in `lsp.lua`)
      entfernt — `lsp/formatter/conform.lua`s `M.setup()` (aufgerufen aus
      `lsp/init.lua`, mit `resolve()`/Mason-Pfad/mehr Formattern) ist jetzt der
      einzige Call.
- [x] **Treesitter**: `lua/lsp/core/treesitter.lua` nutzte die alte
      `nvim-treesitter.configs`-API, die im installierten main-Branch nicht
      mehr existiert (`pcall(require, "nvim-treesitter.configs")` schlägt
      fehl → No-op). Datei + Aufruf in `lsp/init.lua` entfernt; Highlight/
      Fold/Indent laufen bereits vollständig über die `FileType`-Autocmds in
      `lua/plugins/treesitter.lua`.
- [x] **Neotest**: `<leader>ntr`/`<leader>ntD` waren in `keymaps/init.lua`
      UND `config/neotest/debug/init.lua` definiert; `debug.setup_all()` läuft
      nach `keymaps.setup()` und hat die erste Definition still überschrieben.
      Die (identische) Top-Level-Definition in `keymaps/init.lua` entfernt,
      Kommentar hinterlassen, welche Datei jetzt die einzige Quelle ist.

## Explizit ausgeschlossen (kein Doku-Bedarf)

Reine Dependencies, Type-Stubs oder Specs ohne aktive Bindings (deaktiviert,
auskommentiert, oder schlicht ohne `keys`/`vim.keymap.set`/Autocmd/Usercmd):
`wezterm-types`, `render-markdown.nvim`, `nui.nvim`, `screenkey.nvim`,
`structlog.nvim`, `git-conflict.nvim`, `vim-matchup`, `nvim-lsp-file-operations`,
`nvim-puppeteer`, `vim-table-mode`, `vim-startuptime`,
`mini.ai`, `mini.icons`, `mini.nvim`, `lazydev.nvim`, `zen-mode.nvim`,
`autolist.nvim` (deaktiviert), `nvim-cmp` (nicht installiert; die schlafende
Keymap dafür steht in [Keymaps/Blink.md](Keymaps/Blink.md)),
`csharp.nvim` (deaktiviert),
`markdown-preview.nvim`, `mkdir.nvim`, `resty.nvim`,
`nvim-tree.lua` (nicht installiert), `nvim-web-devicons`,
`treesitter-context`, `treesitter-textobjects`, `lspsaga.nvim`, `lensline.nvim`,
`nvim-notify`, `triptych.nvim` (nicht installiert),
`vim-rhubarb`, `vim-wakatime` (deaktiviert), `targets.vim`, `mason.nvim`,
`nvim-ts-autotag`, `telescope-fzf-native.nvim`, `telescope-github.nvim` (ungenutzt),
`plenary.nvim`.
