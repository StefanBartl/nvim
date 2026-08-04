# runtime-analysis.nvim — Autocmds Cheatsheet

**Corrected 2026-08-04** — this file previously claimed "None", which was
wrong: a repo-wide search only checked for the raw `vim.api.nvim_create_autocmd`
call and missed `lib.nvim`'s own `autocmd.create` wrapper used in
`telemetry/init.lua`. A second, full pass (both call shapes) found four real
registrations, none of them user-facing (no buffer/window UI, nothing a
keymap could shadow) — opt-in machinery only, and only for plugins telemetry
is actually enabled for.

| Event | File | Group | Does |
| --- | --- | --- | --- |
| `VimLeavePre` | `telemetry/init.lua` | `ra_telemetry_<namespace>`, one per live instance | Flush persisted counters on exit. `stop()` is deliberately not called here — the process is ending, no point restoring wrappers that cannot outlive it. |
| `VimEnter` | `telemetry/init.lua` | same, per instance | The one place the "data has been sitting on disk a while" reminder is checked outside a periodic flush. |
| `User LazyLoad` | `telemetry/lazy.lua` | `runtime_analysis_telemetry_lazyload` | Auto-instrumentation catch-up: wraps + starts a telemetry instance the moment lazy.nvim finishes loading a plugin listed in `opts.telemetry.plugins` — see `lua/config/telemetry.lua` in this config for the policy. |
| `UIEnter` (`once = true`) | `telemetry/startup.lua` | `runtime_analysis_startup` | Stops startup-cost timing once the UI is up — only fires at all if `require("runtime-analysis.telemetry.startup").autostart()` is wired into the plugin's own `init` hook (opt-in, see the Usercmds sheet's `:RATelemetry startup` section). |
| `CmdlineLeave` | `usage.lua` | `runtime_analysis_usage` | Counts a typed command by name, unless the cmdline was `<Esc>`-aborted — only active between `:RA usage start` and `:RA usage stop`. |

All five are scoped to opt-in machinery (telemetry instances, `:RA usage`)
rather than always-on — a config that never enables telemetry or usage
tracking installs none of them. None touches a buffer/window a keymap could
collide with, so no collision table is needed the way the Keymaps sheet has
one.

Every user-facing entry point is still one of the commands
(`:RA <subcommand>`, `:RARequest`, `:RASend`, `:RATelemetry`) — see the
[Usercmds sheet](../Usercmds/runtime-analysis.nvim.md).
