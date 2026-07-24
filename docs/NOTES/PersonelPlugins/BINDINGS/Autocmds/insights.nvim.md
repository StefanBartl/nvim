# insights.nvim — Autocmds Cheatsheet

Source: `lua/insights/bindings/autocmds.lua`
Cross-reference: `docs/BINDINGS.md` and `docs/automatic-triggers.md` — both current and accurate.

The plugin's "only automatic triggers" — each individually gated by its own
feature's `enable` flag. Every augroup uses a local `augroup(name)` helper →
`nvim_create_augroup("Insights_" .. name, { clear = true })`, called
**unconditionally** (so a previously-registered autocmd is torn down even
when the feature becomes disabled — makes re-running `setup()` idempotent
and makes `enable = false` actually tear down a previously enabled feature).

| Event(s) | Augroup | Condition | Action |
| --- | --- | --- | --- |
| `cfg.conflicts.events` (default `{"VimEnter"}`) | `Insights_conflicts` | `cfg.conflicts.enable` | Populates quickfix with unresolved git merge conflicts |
| `cfg.unimported.events` (default `{"BufWritePost"}`) | `Insights_unimported` | `cfg.unimported.enable`, filetype ∈ {astro,jsx,tsx,vue,svelte} | Warns about used-but-unimported components |
| `TermOpen` | `Insights_devserver` | — | Reads `vim.b[buf].terminal_job_id`, detects a dev-server command the terminal was opened with |
| `TermRequest` | `Insights_devserver` | Neovim 0.10+ | Same detection, triggered by an OSC 0/2 terminal-title change — catches a command typed into an already-open shell, which only shows up when the program sets the terminal title |
| `VimLeavePre` | `Insights_devserver` | — | Kills tracked dev-server processes on exit |

## Details

- **Dev-server kill scoping**: `docs/automatic-triggers.md` explains this only kills terminals *this Neovim instance* started — never a blind `pkill -f` sweep.
- All three features (`conflicts`, `unimported`, `devserver`) are individually gated by `cfg.<feature>.enable`; nothing fires if that flag is `false`.
