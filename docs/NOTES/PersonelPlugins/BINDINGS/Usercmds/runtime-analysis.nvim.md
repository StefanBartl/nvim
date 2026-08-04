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

## `:RA {subcommand}` — request/send/yank/cancel/history/env/import/export/provenance/usage

Built via `lib.nvim.usercmd.composer` — same verb-first shape `:DocMap`/
`:MDView` use, `<Tab>`-completed (`:RA <Tab>` →
`request | send | yank | cancel | history | env | import | export |
provenance | usage`).
`:RARequest`/`:RASend` still work too, unchanged: this plugin's oldest,
most-referenced surface, kept as flat aliases calling the same handlers
rather than replaced by `:RA`.

| Invocation | Does |
| --- | --- |
| `:RA request` / `:RARequest` | Opens a new scratch buffer (`filetype = "http"` by default), pre-filled with `GET https://`. One request per buffer — for a real, committed file with several, open it directly with `:e` instead (`###`-separated, see below). |
| `:RA send` / `:RASend` | Parses and sends whichever `###` block the cursor is in (nearest above it), via `lib.nvim.net.curl.fetch_raw` — **non-blocking**: a "sending ..." placeholder shows immediately, replaced by the real response/error/cancelled once known. A second `:RA send` before the first replies supersedes it (a monotonic token, not a queue). Shows status/headers/body in a persistent split; JSON bodies pretty-print with real folding. A `# @expect status N` (or `// @expect status N`) comment anywhere in the block is checked once the response arrives — match notifies, mismatch (incl. transport failure) replaces the quickfix list with one entry. Shipped 2026-08-04 (§2.5). |
| `:RA yank` | Yanks just the last response's **body** (not status/headers) to the unnamed register. |
| `:RA cancel` | Discards the in-flight request's eventual result (`✗ cancelled`) — a *logical* cancel, curl itself keeps running in the background; `lib.nvim.net.curl.fetch_raw` doesn't hand back a killable handle. |
| `:RA history` | `vim.ui.select` over this project's recorded sends (method/url/status/timestamp — **no headers, no body, on either side**), newest first; picking one reopens it via `open_request`. Per-project via `lib.nvim.fs.project_key()` + `lib.nvim.cache.disk`. |
| `:RA history clear` | Clears this project's recorded history. No confirmation prompt. |
| `:RA env [name]` | With `name` (`<Tab>`-completed), selects it as the active environment `{{var}}` placeholders resolve against. With none, `vim.ui.select` over every name the project's env files define. **Session-scoped, not persisted.** See below. |
| `:RA import` | Parses a `curl` command line — system clipboard by default, or a visual/line-range selection's own lines (`'<,'>RA import`) — into a new request buffer. See below. |
| `:RA export` | The reverse: yanks the `###` block under the cursor as a shareable `curl` command to the unnamed register. See below. |
| `:RA provenance <path>` | "Who wrapped this function" — e.g. `:RA provenance vim.notify`. Exact for this plugin's own telemetry wraps (named by namespace), best-effort otherwise (`debug.getinfo` source location). Shipped 2026-08-04 (§5.2). |
| `:RA usage` / `:RA usage start` / `:RA usage stop` | Keymap/command press counts — opt-in, local-only, the one feature here recording *what you did* rather than *what the code did*. `start` wraps `vim.keymap.set` (function-callback mappings only) plus a `CmdlineLeave` hook for typed commands; bare `:RA usage` reports; `stop` ends collection. Built on `runtime-analysis.telemetry` itself. Shipped 2026-08-04 (§7.1). |

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

### curl import/export (`:RA import` / `:RA export`)

`lua/runtime-analysis/curl.lua` — a real, bounded `curl`-argument parser
(own quote-aware tokenizer; no shared one existed anywhere in lib.nvim),
not templating. Recognizes `-X`, `-H` (repeatable), `-d`/`--data-raw`/
`--data-binary` (repeatable, joined with `&`), `-u` (→ base64 `Authorization:
Basic`), `-b`, `-A`, `-e`, drops flags meaningless here (`-s`, `-v`, `-o`,
timeouts, TLS material, ...) without eating the URL, and mirrors curl's
own "`-d` with no `-X` implies POST" default. `:RA export` (the reverse)
never resolves `{{var}}` placeholders — the identical §2.1 trap, closed
the identical way, since exporting is sharing too. Shipped 2026-08-04
(`docs/ROADMAP.md` §2.3, now `docs/FINISHED.md`).

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
| `:RATelemetry compare [ns] [days]` | "this window vs the one before it" (default 7d) — newly-hot/gone-cold/changed functions. Shipped 2026-08-04 (§4.2). |
| `:RATelemetry startup [top]` | Which *module* a plugin's startup cost sits in, as a waterfall (self vs. total time, grouped per module and per module root). Shipped 2026-08-04 (§3.3). **Needs the opt-in below.** |
| `:RATelemetry cost` | Startup cost vs. call count per namespace, worst (expensive, underused) first. Shipped 2026-08-04 (§7.2). Joins `startup`'s per-module-root data against each instance's own `resolved_modules()` on real module paths — never guesses a namespace ("markdown.nvim") matches a module root ("markdown") by string similarity. |

`<Tab>` after `start `/`stop `/`reset `/`open `/`compare ` completes
namespaces only; `compare`'s third token (a day count) isn't completed,
and `startup` takes no namespace at all (its second token is a `top`
count).

### Startup attribution is opt-in, via the plugin's own `init` hook

`:RATelemetry startup` reports nothing unless this is in the
`runtime-analysis.nvim` spec (`lua/plugins/personal/init.lua`):

```lua
{
  "StefanBartl/runtime-analysis.nvim",
  init = function()
    require("runtime-analysis.telemetry.startup").autostart()
  end,
}
```

It wraps the global `require` and times every cache miss; only modules
required *after* it are ever seen (anything already in `package.loaded` is
invisible, not free). Stops itself at `UIEnter`.

**Why `init` and not `init.lua`** — lazy.nvim's `loader.M.startup` runs
*every* plugin's `init` in one pass before it loads any plugin at all
(step 1 of 4), so `init` is already the earliest per-plugin hook, and it
lives in the spec — deleting the plugin deletes it too. A line in
`init.lua` would have to be removed by hand forever, since an uninstalled
plugin runs no code and could never take it back out. (Same reason the
plugin doesn't write that line itself on install: tempting, unfixable.)
And it can't ride `setup()` either — by then most of the config is loaded
— nor lazy's `User LazyLoad`, which fires *after* `config()` and is
per-plugin, not per-module.

Also shipped 2026-08-04, no new command surface:
- **Error fingerprinting (§3.4)** — `errors` now also records *what* a
  wrapped function raised (bounded, same machinery as argument profiling),
  in `entry.error_fp` and both renderers. Rides the existing `errors` opt-in.
- **Sampling (§3.2)** — `sample = N` in `wrap()` opts: only every Nth call
  pays for timing/arg-profiling/error-fingerprinting; `calls` stays exact.
Full API this command is a front-end over (instances, `wrap`/`wrap_loaded`,
`auto()`, the lazy.nvim adapter, argument profiling): see
[lib.nvim.md's Telemetry section](./lib.nvim.md) for how this personal
config actually wires `opts.telemetry` into the plugin's own spec
(`lua/plugins/personal/init.lua`'s `runtime-analysis.nvim` entry,
`lua/config/telemetry.lua` for the policy), and
`lua/runtime-analysis/telemetry/README.md` in the repo for the module's own
full reference.

## Global-surface collision check (2026-08-04, re-checked after `:RA usage` was added)

Checked against every `Usercmds/*.md` in this folder: `RA`, `RARequest`,
`RASend` and `RATelemetry` are unique — no other personal plugin registers
any of the four, and no other plugin owns an `RA`-prefixed command.
