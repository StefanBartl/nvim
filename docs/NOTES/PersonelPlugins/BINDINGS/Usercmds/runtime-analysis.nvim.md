# runtime-analysis.nvim — Usercmds Cheatsheet

Source: `lua/runtime-analysis/bindings/usrcmds.lua` (`:RA`, built via
`lib.nvim.usercmd.composer`, plus flat aliases `:RARequest`/`:RASend`)
+ `lua/runtime-analysis/telemetry/command.lua` (`:RATelemetry`). All four
registered unconditionally by `require("runtime-analysis").setup()`.
Cross-reference: the repo's own `docs/COMMANDS.md` (prose) and
`docs/BINDINGS.md` (cheatsheet, generated the same way this file is —
hand-maintained, four commands is small enough that a generator would cost
more than it saves).

Runtime truth, paired with [documentation.nvim](./documentation.nvim.md)'s
static truth (see that repo's `docs/ECOSYSTEM.md`). Two things: an in-editor
HTTP request runner, and `runtime-analysis.telemetry` — opt-in call counting
moved here from lib.nvim (see [lib.nvim's own Usercmds sheet](./lib.nvim.md)
for how a *consuming* plugin uses the telemetry module directly, as
opposed to this file's `:RATelemetry` command surface).

## `:RA request` / `:RA send` (aliases: `:RARequest` / `:RASend`)

Built via `lib.nvim.usercmd.composer` — same verb-first shape `:DocMap`/
`:MDView` use, `<Tab>`-completed (`:RA <Tab>` → `request | send`).
`:RARequest`/`:RASend` still work too, unchanged: this plugin's oldest,
most-referenced surface, kept as flat aliases calling the same handlers
rather than replaced by `:RA` (updated 2026-08-03 — was flat-only until
then).

| Invocation | Does |
| --- | --- |
| `:RA request` / `:RARequest` | Opens a new scratch buffer (`filetype = "http"` by default), pre-filled with `GET https://`. One request per buffer. |
| `:RA send` / `:RASend` | Run from inside a request buffer: parses it, sends it via `lib.nvim.net.curl.fetch_raw_blocking`, shows status/headers/body in a persistent split. Blocking — no async yet. |

Request shape (VS Code REST Client / IntelliJ HTTP Client's own convention,
deliberately not invented here):

```http
POST https://api.example.com/users
Content-Type: application/json
Authorization: Bearer abc123

{"name": "Alice"}
```

`M.open_request(lines)` is also this plugin's public integration surface —
documentation.nvim's `:DocBrowse` Endpoints mode (`gs` on a route) calls it
directly with a pre-filled `METHOD path`, soft dependency
(`pcall(require, "runtime-analysis")`).

## `:RATelemetry`

Stays a second, separate compound command rather than folding under
`:RA telemetry ...` — the same split documentation.nvim draws between
`:DocMap` (does something) and `:DocBrowse` (reports on something); see
the repo's own `docs/COMMANDS.md` for the full reasoning.

| Invocation | Does |
| --- | --- |
| `:RATelemetry` | report across every live instance, in a kit float |
| `:RATelemetry <ns>` | report for one namespace |
| `:RATelemetry start [ns]` / `stop [ns]` / `reset [ns]` | every instance, or just one |
| `:RATelemetry disable [ns]` / `enable [ns]` | stop + persist "off" across restarts / clear that |
| `:RATelemetry disabled` | list namespaces currently disabled |
| `:RATelemetry coverage` | which wrapped functions were never called |
| `:RATelemetry export [path]` | JSON, or Markdown if `path` ends `.md` |
| `:RATelemetry open [ns]` | render + open externally (`report_style`: `auto`/`kit`/`mdview`/`file`) |

`<Tab>` after `start `/`stop `/`reset `/`open ` completes namespaces only.
Full API this command is a front-end over (instances, `wrap`/`wrap_loaded`,
`auto()`, the lazy.nvim adapter, argument profiling): see
[lib.nvim.md's Telemetry section](./lib.nvim.md) for how this personal
config actually wires `opts.telemetry` into the plugin's own spec
(`lua/plugins/personal/init.lua`'s `runtime-analysis.nvim` entry,
`lua/config/telemetry.lua` for the policy), and
`lua/runtime-analysis/telemetry/README.md` in the repo for the module's own
full reference.

## Global-surface collision check (2026-08-03, re-checked after `:RA` was added)

Checked against every `Usercmds/*.md` in this folder: `RA`, `RARequest`,
`RASend` and `RATelemetry` are unique — no other personal plugin registers
any of the four, and no other plugin owns an `RA`-prefixed command.
