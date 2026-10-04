# nvim

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

The personal Neovim configuration of Stefan Bartl. It is a configuration, not
a plugin: it is shaped for one person's workflow and is published as a
reference, not as a distribution to install as-is.

Many of the features started here and were later extracted into standalone
plugins under [github.com/StefanBartl](https://github.com/StefanBartl), for
example:

- [lib.nvim](https://github.com/StefanBartl/lib.nvim) - shared utilities the
  other plugins build on
- [filetree.nvim](https://github.com/StefanBartl/filetree.nvim) - file tree
- [pickers.nvim](https://github.com/StefanBartl/pickers.nvim) - pickers
- [markdown.nvim](https://github.com/StefanBartl/markdown.nvim) - Markdown
  editing helpers
- [sandbox.nvim](https://github.com/StefanBartl/sandbox.nvim) - container
  and compose helpers

## Layout

| Path | Contents |
| --- | --- |
| `init.lua` | entry point: bootstraps lazy.nvim and loads the config |
| `lua/config/` | per-plugin and core configuration (UI, statusline, telescope, fzf, ...) |
| `lua/plugins/` | lazy.nvim plugin specs; `personal/` holds the own `*.nvim` plugins |
| `lua/bindings/` | keymaps, user commands and autocmds |
| `lua/startup/` | startup diagnostics and reporting |
| `lua/tasks/` | the in-repo task system |
| `after/` | Tree-sitter query overrides (textobjects) |
| `docs/` | documentation: keybindings, installation notes, notes and roadmaps |
| `TESTS/` | test harness and specs, run headless with `nvim -n -i NONE --headless -u NONE -l TESTS/run.lua` |

See `docs/installation.md` for the external tools the configuration expects
and `docs/BINDINGS.md` for the keybindings.

## License

[MIT](LICENSE), Copyright (c) 2026 Stefan Bartl.
