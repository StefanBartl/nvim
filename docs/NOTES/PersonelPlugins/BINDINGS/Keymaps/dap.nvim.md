# dap.nvim — Keymaps Cheatsheet

Source: `lua/wkddap/bindings/keymaps/init.lua`, `M.setup(opts)`
Cross-reference: `docs/BINDINGS.md` in this repo — verified accurate and complete.

No-op unless `opts.enable` (`config.keymaps.enable`, default on). Maps via
`lib.nvim.bindings.keymap` when available, falling back to bare `vim.keymap.set`
otherwise (since 2026-08-06 — `lib.nvim.bindings.keymap` doesn't ship yet; same
`pcall(require, "lib.nvim.bindings.keymap")`-with-fallback pattern as `sessions.nvim`'s
`bindings/keymaps/init.lua`; `health.lua` reports which one is active).
Prefix `opts.prefix` (default `<leader>d`). Every mapping:
`desc = "[DAP] " .. d, silent = true`. Wired from `bindings/init.lua` inside a
`pcall`, since `keymaps.setup()` `require("dap")`s eagerly to bind functions
directly — a missing nvim-dap degrades gracefully instead of aborting the
rest of `setup()` (which-key/autocmds still get wired). `B`/`L` prompt via
`lib.nvim.ui.kit.input` (non-blocking), not `vim.fn.input`.

## Session control -- step and continue

| lhs (after prefix) | mode | action | desc |
| --- | --- | --- | --- |
| `c` | n | `dap.continue` | "[DAP] Continue" |
| `s` | n | `dap.step_over` | "[DAP] Step Over" |
| `i` | n | `dap.step_into` | "[DAP] Step Into" |
| `o` | n | `dap.step_out` | "[DAP] Step Out" |

**Count support (since 2026-07-31):** `3<prefix>s` steps over 3 times. Not a
naive `for i=1,count do step_over() end` — a step command assumes the thread
is currently stopped, and firing several back-to-back before the adapter
processes the first one is invalid per the DAP spec. Instead
`counted_step()` (in `bindings/keymaps/init.lua`) fires the first step
immediately, then chains the rest one at a time via
`dap.listeners.after.event_stopped`, only issuing the next step once the
adapter confirms the thread actually stopped again. `event_terminated`/
`event_exited` clean up the listener if the session ends mid-chain, and a
1000-step cap bounds a fat-fingered count. With no count (the common case)
this is unchanged — `step_fn()` is called directly, no listener registered.

**Since 2026-08-24 the chaining lives in `lib.nvim.count.chain`**, hoisted out
of this plugin: the cap, the teardown, the no-count fast path and the refusal
to advance after an abort are the library's behavior now. `counted_step()`
keeps only the DAP-specific half — which events mean "finished" and "gone".
Behavior is unchanged; verified against a stubbed adapter (one step per
`event_stopped`, a stale stop after the count is satisfied ignored, the
listener removed both on completion and on `event_terminated`).

**Pre-filled prompts (since 2026-08-24):** `B` and `L` no longer open empty.
They pre-fill with this line's existing condition/log message if it has one
(`dap.breakpoints.get`), else the last value submitted this session, tracked
separately per kind — see `core/breakpoints.lua`. Submitting an empty line
clears the value rather than cancelling; `<Esc>` cancels. The same module now
backs `:Dap conditional-breakpoint`/`log-point` and the nvzone/menu entries,
which each used to carry their own copy of the empty prompt. The `desc`
strings are unchanged.

## Breakpoints, panels and the REPL

| lhs (after prefix) | mode | action | desc |
| --- | --- | --- | --- |
| `t` | n | `dap.terminate` | "[DAP] Terminate" |
| `r` | n | `dap.restart` | "[DAP] Restart" |
| `b` | n | `dap.toggle_breakpoint` | "[DAP] Toggle Breakpoint" |
| `B` | n | Prompt (pre-filled) for a condition string, set a conditional breakpoint | "[DAP] Conditional Breakpoint" |
| `L` | n | Prompt (pre-filled) for a log message, set a log point | "[DAP] Log Point" |
| `l` | n | `dap.list_breakpoints` | "[DAP] List Breakpoints" |
| `u` | n | Toggle the active panel UI (dap-view or dap-ui) | "[DAP] Toggle UI" |
| `e` | n | Evaluate expression under cursor | "[DAP] Evaluate Expression" |
| `e` | v | Evaluate selection | "[DAP] Evaluate Selection" |
| `R` | n | `dap.repl.open` | "[DAP] Open REPL" |

## which-key

`<leader>d` → "DAP" group label, only if which-key is installed and
`cfg.which_key.enable` (default on).

## Notes

- No other keymap registrations exist anywhere else in the repo (`ui/`, `languages/`, `adapters/`, `configurations/`, `core/` register none).
