# autocmds

Entry point wiring up this config's autocmd suite: floating-explorer
auto-centering, a neo-tree/snacks "singleton" open/close guard (not yet
exercised against a live session), and the toggleable `general` feature set
(Kitty padding, cursorline-on-focus, last-cursor-position, ...). The `git`,
`terminals` and `text` subtrees are separate, self-contained feature groups
with their own `enable(cfg)` entry point — see their own READMEs.
