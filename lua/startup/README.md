# startup

Startup phase runner with built-in measurement. Replaces the previous
`vim.defer_fn(..., 10|50)` scheme — wall-clock timers were never a real
policy, since `defer_fn` can't run before the event loop goes idle, which on
this config happens ~2s after `VimEnter`.

| File | Role |
| --- | --- |
| `init.lua` | runner: `now`, `on`, `marks`, `pending`, `failed`, `total`, `slowest`, `:StartupReport` / `:StartupCheck` |
| `heartbeat.lua` | event-loop heartbeat for the first 6 s (10 ms timer, stops itself): stalls > 60 ms and busy time per second; pure `analyse()` |
| `report.lua` | the float behind `:StartupReport` (phases plus an "Event loop" section from `heartbeat`), `check()` |

Policy and rationale: `docs/NOTES/ARCHITECTURE/startup.md`.

## Which tool when

- **`:StartupReport`** — the session you are sitting in, at no extra cost:
  did every phase run, how long were the phase bodies, how many stalls and
  how busy was the loop in the first seconds. Good for "was this start slow,
  and roughly where in time". The heartbeat is the same method as the
  `stall` probe, so the numbers read the same way.
- **`scripts/startup-probe/`** — when you need a *cause* or a *comparison*:
  who owns a stall (`PROBE=stall,where`), which `require`, `exepath`, spawn or
  lazy.nvim load costs what, and medians over several starts (`bench.lua`) for
  an A/B. It spawns its own Neovim with a UI and wraps hot functions, so it
  costs time and does not describe your current session.

Switch the heartbeat off for an A/B run:
`--cmd "lua vim.g.startup_heartbeat = false"` (e.g. behind `bench.lua 5 tui`).
