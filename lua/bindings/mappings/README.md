# bindings.mappings

Entry point that registers all keymaps, grouped one file per topic (LSP,
NvChad, terminal, tabufline, buffer-jump, ...). Each topic module exposes
its own `setup()`; this one just calls them all.
