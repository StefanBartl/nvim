# autocmds

Entry point wiring up this config's autocmd suite: floating-explorer
auto-centering, a neo-tree/snacks "singleton" open/close guard (not yet
exercised against a live session), and the toggleable `general` feature set
(cursorline-on-focus, the spurious [No Name] buffer guard). The `git`,
`terminals` and `text` subtrees are separate, self-contained feature groups
with their own `enable(cfg)` entry point — see their own READMEs. Kitty
padding lives in `terminals`, last-cursor-position in `text`; `general` used
to duplicate both (removed 2026-09-12).
