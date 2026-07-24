# sessions.nvim — Autocmds Cheatsheet

Source: `lua/sessions/bindings/autocmds/init.lua`, `M.enable()`
Cross-reference: `docs/BINDINGS.md` — accurate and current; points to `configuration.md#autoload--autosave` for the exact semantics rather than duplicating them.

Single augroup `SessionsNvim` (`clear=true`), unconditionally created.
Individual autocmds are feature-gated.

| Event | Condition | Action | desc |
| --- | --- | --- | --- |
| `VimEnter` (once, nested) | `cfg.autoload` (default **off**), and only if `fn.argc(-1) == 0` (no explicit file args) | Loads the contextual session (`sessions.core.load(nil)`); notifies "[sessions] autoloaded: `<path>`" on success | "sessions.nvim: autoload contextual session on startup" |
| `VimLeavePre` | `cfg.autosave` (default **on**) | If `cfg.autosave_name` is set (default `"last"`), saves to that fixed name; otherwise doesn't save | "sessions.nvim: autosave to fixed session name on exit" |

## Notes

- Autoload only triggers when Neovim starts with no explicit file arguments — opening a specific file skips it.
