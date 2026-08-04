# runtime-analysis.nvim — Usercmds Cheatsheet

Source: `lua/runtime-analysis/bindings/usrcmds.lua` (`:RA`, built via
`lib.nvim.usercmd.composer`, plus flat aliases `:RARequest`/`:RASend`)
+ `lua/runtime-analysis/telemetry/command.lua` (`:RATelemetry`). All four
command *names* are registered unconditionally by
`require("runtime-analysis").setup()`. Cross-reference: the repo's own
`docs/COMMANDS.md` (prose) and `docs/BINDINGS.md` (cheatsheet, generated the
same way this file is — hand-maintained, small enough that a generator
would cost more than it saves).

Runtime truth, paired with [documentation.nvim](./documentation.nvim.md)'s
static truth (see that repo's `docs/ECOSYSTEM.md`). Two things: an in-editor
HTTP request runner, and `runtime-analysis.telemetry` — opt-in call counting
moved here from lib.nvim (see [lib.nvim's own Usercmds sheet](./lib.nvim.md)
for how a *consuming* plugin uses the telemetry module directly, as
opposed to this file's `:RATelemetry` command surface).

## `:RA {subcommand}` — request/send/yank/cancel/history/env

Built via `lib.nvim.usercmd.composer` — same verb-first shape `:DocMap`/
`:MDView` use, `<Tab>`-completed (`:RA <Tab>` →
`request | send | yank | cancel | history | env`). `:RARequest`/`:RASend`
still work too, unchanged: this plugin's oldest, most-referenced surface,
kept as flat aliases calling the same handlers rather than replaced by
`:RA`.

| Invocation | Does |
| --- | --- |
| `:RA request` / `:RARequest` | Opens a new scratch buffer (`filetype = "http"` by default), pre-filled with `GET https://`. One request per buffer — for a real, committed file with several, open it directly with `:e` instead (`###`-separated, see below). |
| `:RA send` / `:RASend` | Parses and sends whichever `###` block the cursor is in (nearest above it), via `lib.nvim.net.curl.fetch_raw` — **non-blocking**: a "sending ..." placeholder shows immediately, replaced by the real response/error/cancelled once known. A second `:RA send` before the first replies supersedes it (a monotonic token, not a queue). Shows status/headers/body in a persistent split; JSON bodies pretty-print with real folding. |
| `:RA yank` | Yanks just the last response's **body** (not status/headers) to the unnamed register. |
| `:RA cancel` | Discards the in-flight request's eventual result (`✗ cancelled`) — a *logical* cancel, curl itself keeps running in the background; `lib.nvim.net.curl.fetch_raw` doesn't hand back a killable handle. |
| `:RA history` | `vim.ui.select` over this project's recorded sends (method/url/status/timestamp — **no headers, no body, on either side**), newest first; picking one reopens it via `open_request`. Per-project via `lib.nvim.fs.project_key()` + `lib.nvim.cache.disk`. |
| `:RA history clear` | Clears this project's recorded history. No confirmation prompt. |
| `:RA env [name]` | With `name` (`<Tab>`-completed), selects it as the active environment `{{var}}` placeholders resolve against. With none, `vim.ui.select` over every name the project's env files define. **Session-scoped, not persisted.** See below. |

Request shape (VS Code REST Client / IntelliJ HTTP Client's own convention,
deliberately not invented here):

```http
POST https://api.example.com/users
Content-Type: application/json
Auth: Bearer abc123

{"name": "Alice"}
```

`Auth:` is a shorthand header — `Auth: Bearer <token>` passes through
verbatim as `Authorization: Bearer <token>`; `Auth: Basic <user>:<pass>`
base64-encodes into `Authorization: Basic <...>` (RFC 7617). More than one
request per buffer (or per real `.http`/`.rest` file), `###`-separated —
`:RA send` always resolves to the block the cursor is in, never the whole
buffer.

`M.open_request(lines)` is also this plugin's public integration surface —
documentation.nvim's `:DocBrowse` Endpoints mode (`gs` on a route) calls it
directly with a pre-filled `METHOD path`, soft dependency
(`pcall(require, "runtime-analysis")`).

### Variables and environments (`:RA env`)

`{{baseUrl}}/users/:id` in a request buffer resolves against the
environment `:RA env` selected. Two per-project JSON files at the project
root, the same split IntelliJ's HTTP Client already uses — matched, not
invented:

```
http-client.env.json          shared, safe to commit (baseUrl, tenant id)
http-client.private.env.json  gitignored, per-machine — real tokens here
```

Both optional, merged per environment name, private wins on overlap.
Resolution happens **exactly once**, immediately before curl — request
history and the "sending ..." placeholder both keep the literal
`{{token}}` forever, never the resolved value; a `vim.notify` `WARN` fires
once per session if the private file exists but isn't listed in this
project's own `.gitignore`. Module: `lua/runtime-analysis/env.lua`.
Shipped 2026-08-04 (`docs/ROADMAP.md` §2.1, now `docs/FINISHED.md`).

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

## Global-surface collision check (2026-08-04, re-checked after `:RA env` was added)

Checked against every `Usercmds/*.md` in this folder: `RA`, `RARequest`,
`RASend` and `RATelemetry` are unique — no other personal plugin registers
any of the four, and no other plugin owns an `RA`-prefixed command.
