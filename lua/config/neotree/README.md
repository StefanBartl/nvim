# config.neotree

What is left of this config's own neo-tree layer: the per-source
`window.mappings` tables under `keymaps/` (neo-tree command names and
`noop`s only) and one event handler. Everything that ran code of its own --
the source switcher, the Alt toggle keys, node utilities, a health check --
is filetree.nvim's since 2026-09-19 (`source_switcher`, `tree_toggle`; see
`plugins/personal/init.lua` for how they are configured here).
