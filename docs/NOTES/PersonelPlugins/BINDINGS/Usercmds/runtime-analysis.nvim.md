# runtime-analysis.nvim — Usercmds Cheatsheet

Source: `lua/runtime-analysis/bindings/usrcmds.lua` (`:RA`, built via
`lib.nvim.bindings.usercmd.composer`, plus flat aliases `:RARequest`/`:RASend`)
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

## `:RA {subcommand}` — request/send/yank/cancel/history/env/import/export/provenance/inspect/usage/loaded

Built via `lib.nvim.bindings.usercmd.composer` — same verb-first shape `:DocMap`/
`:MDView` use, `<Tab>`-completed (`:RA <Tab>` →
`request | send | yank | cancel | history | env | import | export |
provenance | inspect | usage | loaded`).
`:RARequest`/`:RASend` still work too, unchanged: this plugin's oldest,
most-referenced surface, kept as flat aliases calling the same handlers
rather than replaced by `:RA`.

| Invocation | Does |
| --- | --- |
| `:RA request` / `:RARequest` | Opens a new scratch buffer (`filetype = "http"` by default), pre-filled with `GET https://`. One request per buffer — for a real, committed file with several, open it directly with `:e` instead (`###`-separated, see below). |
| `:RA send` / `:RASend` | Parses and sends whichever `###` block the cursor is in (nearest above it), via `lib.nvim.net.curl.fetch_raw` — **non-blocking**: a "sending ..." placeholder shows immediately, replaced by the real response/error/cancelled once known. A second `:RA send` before the first replies supersedes it (a monotonic token, not a queue). Shows status/headers/body in a persistent split; JSON bodies pretty-print with real folding. A `# @expect status N` (or `// @expect status N`) comment anywhere in the block is checked once the response arrives — match notifies, mismatch (incl. transport failure) replaces the quickfix list with one entry. Shipped 2026-08-04 (§2.5). Also understands GraphQL and multipart/form-data bodies — see below (§2.6). |
| `:RA yank` | Yanks just the last response's **body** (not status/headers) to the unnamed register. |
| `:RA cancel` | Discards the in-flight request's eventual result (`✗ cancelled`) — a *logical* cancel, curl itself keeps running in the background; `lib.nvim.net.curl.fetch_raw` doesn't hand back a killable handle. |
| `:RA history` | `vim.ui.select` over this project's recorded sends (method/url/status/timestamp — **no headers, no body, on either side**), newest first; picking one reopens it via `open_request`. Per-project via `lib.nvim.fs.project_key()` + `lib.nvim.cache.disk`. |
| `:RA history clear` | Clears this project's recorded history. No confirmation prompt. |
| `:RA env [name]` | With `name` (`<Tab>`-completed), selects it as the active environment `{{var}}` placeholders resolve against. With none, `vim.ui.select` over every name the project's env files define. **Session-scoped, not persisted.** See below. |
| `:RA import` | Parses a `curl` command line — system clipboard by default, or a visual/line-range selection's own lines (`'<,'>RA import`) — into a new request buffer. See below. |
| `:RA export` | The reverse: yanks the `###` block under the cursor as a shareable `curl` command to the unnamed register. See below. |
| `:RA provenance <path>` | "Who wrapped this function" — e.g. `:RA provenance vim.notify`. Exact for this plugin's own telemetry wraps (named by namespace), best-effort otherwise (`debug.getinfo` source location). Shipped 2026-08-04 (§5.2). `<path>` completes level by level since 2026-08-24 (argtype `RA_PROVENANCE_PATH`) — loaded state only, Tab never triggers a `require`. |
| `:RA inspect <module>` | Walks a live `package.loaded[module]` table — functions (upvalue counts, source location), nested tables (own shape, cycle-safe, `max_depth=3` for readability), metatables, keys that *shadow* a table `__index`. `<Tab>`-completes against `package.loaded`, live. `__index` reported, never called — a pure read. Renders via `lib.nvim.ui.kit.viewer`, `vim.notify` fallback. Shipped 2026-08-04 (§5.1). |
| `:RA usage` / `:RA usage start` / `:RA usage stop` | Keymap/command press counts — opt-in, local-only, the one feature here recording *what you did* rather than *what the code did*. `start` wraps `vim.keymap.set` (function-callback mappings only) plus a `CmdlineLeave` hook for typed commands; bare `:RA usage` reports; `stop` ends collection. Built on `runtime-analysis.telemetry` itself. Shipped 2026-08-04 (§7.1). |
| `:RA loaded snapshot <prefix> [name]` | Persists every currently-loaded module under `<prefix>` (itself, or anything beginning `<prefix>.` — same scoping `wrap_loaded(prefix)` uses) as a named snapshot, so it can be read later or from a different process — documentation.nvim's Loaded Analysis panel (`:DocMap serve`) is exactly that. `name` defaults to a timestamp. Always explicit — nothing here ever snapshots on its own. Shipped 2026-08-10 (§5.4). |
| `:RA loaded snapshots <prefix>` | Lists every saved snapshot for `<prefix>`, newest first. |

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

### GraphQL and multipart request bodies (§2.6, shipped 2026-08-04)

Both VS Code REST Client's own conventions. `X-Request-Type: GraphQL`
marks a body as query text + optional blank-line-separated JSON
variables — `:RA send` builds the real `{"query":...,"variables":{...}}`
payload and strips the directive header before sending; `:RA export`
applies the same transform (never `{{var}}` resolution). A
`Content-Type: multipart/form-data; boundary=...` body with `< ./path`
part references gets those paths resolved to real file bytes on send
(`lua/runtime-analysis/multipart.lua`), or turned into curl's own
`-F "field=@path"` flags on export — never inlined as shell text, since
a binary file's raw bytes are not safe shell-embeddable strings.

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
| `:RATelemetry export [path]` | JSON; Markdown if `path` ends `.md`; PDF if `.pdf` (via pdfport.nvim, optional dependency) |
| `:RATelemetry export-all <dir>` | one Markdown file per namespace found **on disk**, into `<dir>` — unlike `export`, not limited to this session's live instances (`telemetry.export_all()`, `store.namespaces()` scans the cache dir directly). Shipped 2026-08-12. |
| `:RATelemetry open [ns]` | render + open externally (`report_style`: `auto`/`kit`/`mdview`/`file`/`html`) |
| `:RATelemetry compare [ns] [days]` | "this window vs the one before it" (default 7d) — newly-hot/gone-cold/changed functions. Shipped 2026-08-04 (§4.2). |
| `:RATelemetry startup [top]` | Which *module* a plugin's startup cost sits in, as a waterfall (self vs. total time, grouped per module and per module root). Shipped 2026-08-04 (§3.3). **Needs the opt-in below.** |
| `:RATelemetry cost` | Startup cost vs. call count per namespace, worst (expensive, underused) first. Shipped 2026-08-04 (§7.2). Joins `startup`'s per-module-root data against each instance's own `resolved_modules()` on real module paths — never guesses a namespace ("markdown.nvim") matches a module root ("markdown") by string similarity. |
| `:RATelemetry snapshot <ns> [name]` | Save a named, device-tagged capture of `ns`'s current aggregate, without resetting the live counters. Always explicit — nothing here ever snapshots on its own. |
| `:RATelemetry snapshots <ns>` | List `ns`'s saved snapshots, newest first. |
| `:RATelemetry snapshot-compare <ns> <a> <b>` | Diff two named snapshots' call counts directly — **not** a calendar window like `compare` above. See "Snapshot device tagging + snapshot-compare" below. Shipped 2026-08-14. |
| `:RATelemetry setup [ns]` | Backup + reset + re-wrap + (re)start — every configured target, or just one. The **only** way to select a non-plugin target such as this config itself (`:RATelemetry setup nvim-config`), which has no repo to name it by. Shipped 2026-08-15. |
| `:RATelemetry full [ns]` | Same, forcing `profile_args` + `timing` on regardless of the target's own policy. `:RATelemetry full nvim-config`. Shipped 2026-08-15. |
| `:RATelemetryStartAll` / `:RATelemetryStopAll` / `:RATelemetryResetAll` | Standalone aliases for bare `start`/`stop`/`reset` above — see below. `StartAll`/`StopAll` shipped 2026-08-14, `ResetAll` 2026-08-15. |
| `:RATelemetrySetupAll` / `:RATelemetrySetupAllFull` | Bare forms of `:RATelemetry setup`/`full`: backup (prompted once) + reset + re-wrap + restart across every target `lua/config/telemetry.lua` configures (plugins **and** `extra`) that is loaded right now. `Full` forces `profile_args`/`timing` on for everyone. Shipped 2026-08-15 — see below. |
| `:RATelemetryNvimConfig` / `:RATelemetryNvimConfigFull` | **This config's own flat aliases** (`lua/bindings/usrcmds/telemetry_nvim_config/`) for `:RATelemetry setup\|full nvim-config`. No mechanism of their own — see below. Shipped 2026-08-15. |

`<Tab>` after `start `/`stop `/`reset `/`open `/`compare `/`snapshot `/
`snapshots `/`snapshot-compare ` completes namespaces only; `compare`'s
third token (a day count) isn't completed, and `startup` takes no
namespace at all (its second token is a `top` count).

### `:RATelemetryStartAll` / `:RATelemetryStopAll` (2026-08-14)

Standalone alias commands, registered by the same `command.setup()` call as
`:RATelemetry` itself, for exactly what bare `:RATelemetry start`/`stop`
(no namespace) already do — every live instance in this process, at once.
Used to be a personal-config-only usercmd
(`lua/bindings/usrcmds/ratelemetry_all/`, now removed); moved into
`runtime-analysis.nvim` itself once it became clear the underlying
operation (`telemetry.start_all()`/`stop_all()`, both iterating the
module-level `instances` registry) needs **zero** personal-config
knowledge — unlike `:DocMapAll` (see `documentation.nvim.md`), which
genuinely does need a caller-supplied repo list. `telemetry.start_all()`
is new too, symmetric with the pre-existing `stop_all()` — the bare
`:RATelemetry start` case used to have its "every instance" loop written
inline in the command dispatcher instead of calling a real function.

### `:RATelemetrySetupAll` / `:RATelemetrySetupAllFull` (2026-08-15)

Answers a question that came up directly: for some plugins, some functions
never show argument data in a report, even though `lua/config/
telemetry.lua`'s own `profile_args = true` default is already on for every
personal plugin. **Root cause was never a settings problem** —
`wrap_loaded()` walks `package.loaded` exactly once, at catch-up-scan or
this plugin's own `User LazyLoad` moment. A submodule `require`d *after*
that (a command handler pulled in on first use, a UI module loaded on
first keypress) is never retroactively wrapped: not profiled-without-args,
genuinely never hooked at all, so it shows zero calls and no argument
fingerprint forever, indistinguishable at a glance from "profiling is off."

`:RATelemetrySetupAll` is the fix: for every plugin `config.telemetry`
configures that is loaded right now, it re-runs `wrap_loaded()` (a no-op
for anything already wrapped, but it picks up whatever loaded since) after
backing up and resetting existing data. Practical habit: use the feature
whose module you suspect loaded late at least once this session, then run
`:RATelemetrySetupAll`(`Full`) — the previously-invisible functions join
the wrap from then on.

**The backup step, concretely:** if any configured, loaded plugin already
has persisted telemetry data, one `vim.ui.input()` prompt (not one per
plugin) asks for a directory — defaults to `stdpath("cache")/
runtime-analysis.nvim/setup-all-backups`, created if it does not exist yet.
Declining aborts the whole run; nothing is reset without either being
backed up or genuinely having nothing to lose. Each plugin with data gets
its own `<namespace>-<timestamp>.json` in that directory.

`SetupAll` restarts each plugin with **its own already-configured**
`profile_args`/`timing` (for this config, that is already `profile_args =
true` — see `lua/config/telemetry.lua`). `SetupAllFull` forces both on for
every plugin regardless of individual policy — a temporary "give me
everything, once" override, the `setup_all` equivalent of `:DocMap full`'s
LuaLS enrichment one repo over (see `documentation.nvim.md`). `lib.nvim`'s
own aggregate is out of scope for both — it wraps through a different
mechanism (`lib.strategies.telemetry_wrap`), not the generic `wrap_loaded()`
re-scan this feature is built on.

New module `lua/runtime-analysis/telemetry/setup_all.lua`, and
`telemetry.lazy.candidates()`/`.configured()` (new) reuse the exact
`opts.telemetry.plugins` policy `config.telemetry.build()` already produces
— no new personal-config wiring needed, the same "the list only ever
arrives as data" posture `:DocMapAll` already established one repo over.

### Telemetry for THIS config — `opts.telemetry.extra` (2026-08-15)

The namespace **`nvim-config`**: this config's own Lua tree is counted the
same way every personal plugin already is, and appears in `:RATelemetry`,
`coverage`, `compare`, `snapshot`, `export` and the HTML dashboard like any
other namespace.

The mechanism is entirely the plugin's own new `opts.telemetry.extra` —
generic support for targets no plugin manager can resolve (no repo, no
spec, several unrelated root prefixes instead of one `main`). Built
deliberately **in the plugin, not as a config-side shim**, so any Neovim
user can instrument their own config; a shim here would by definition never
have done that. This config only supplies data, in `lua/config/telemetry.lua`:

```lua
extra = {
  { namespace = "nvim-config",
    mains = SELF_PREFIXES,   -- the 11 top-level lua/ prefixes
    profile_args = true, timing = false },
}
```

`SELF_PREFIXES` is the **one** place that list lives.

**Wrap timing is the whole subtlety.** When `runtime-analysis.setup()` runs
it is still inside `lazy.setup()`, before `startup.now(...)`/`startup.on(
"UIReady", ...)` have required most of this config — and `wrap_loaded()`
only ever sees what is already in `package.loaded`. So the plugin defers
the wrap to **VimEnter** by default (`wrap_at`, overridable per target with
`"setup"`/`"manual"`). An earlier draft solved this config-side with a
`startup.on("UIReady", "telemetry_self", ...)` phase after `mappings`; that
phase and its `lua/config/telemetry_self.lua` are **gone** — the plugin
handles it, and keeping both would have meant two prefix lists that drift.

**Selecting it:** a config has no repo, so `:RATelemetry setup|full
nvim-config` (the new namespace-taking subcommands) is how it is named.

#### `:RATelemetryNvimConfig` / `:RATelemetryNvimConfigFull`

Flat aliases **local to this config** (`lua/bindings/usrcmds/
telemetry_nvim_config/init.lua`), for `:RATelemetry setup nvim-config` and
`:RATelemetry full nvim-config` respectively. They exist only because that
namespace is reached for often enough here to earn a name that completes in
one Tab — the same reasoning the plugin's own `:RATelemetryStartAll` flat
aliases already document. They contain **no mechanism of their own**: an
earlier version wrapped the prefixes itself, which meant a second prefix
list beside `config.telemetry`'s that could silently drift apart.

**Note for other configs:** `mains` are top-level `lua/` directory names,
so any user's list differs. Nothing about the feature is specific to this
config.

### Snapshot device tagging + `snapshot-compare` (2026-08-14)

`telemetry.snapshot(ns, name, opts)` gained a third argument: `opts.device`
tags the capture (default `vim.uv.os_gethostname()`, an explicit string to
override, or `false` for no tag at all), stored in the snapshot's own
`Data.info.device` — rendered wherever `info` already renders, no new UI.
The motivating case: read data, change something, read data again —
possibly on a different machine — compare, and know which snapshot came
from where.

`telemetry.compare_snapshots(ns, name_a, name_b)` / `:RATelemetry
snapshot-compare <ns> <a> <b>` diffs two named snapshots' function call
counts directly. **Not** the same as `compare` (`this week vs last week`,
reading one dataset's own rolling day buckets) — two snapshots are
independent captures, `Data.functions[key].calls` a lifetime total in
each. Classifies by the **A→B delta**, not raw totals: a lifetime counter
only ever grows, so "silent since `name_a`" can never fire between two
chronologically ordered snapshots — "no new calls happened in this
period" is the question that actually has an answer. New report functions
`report.compare_snapshots_lines()`/`compare_snapshots_markdown()`, same
shape as the existing `compare_lines()`/`compare_markdown()` pair.

### `export .pdf` via pdfport.nvim (2026-08-09)

`:RATelemetry export report.pdf` and `nvim --headless -l scripts/telemetry.lua
export <ns> report.pdf` both route through
[pdfport.nvim](https://github.com/StefanBartl/pdfport.nvim) (optional
dependency, `pcall`-guarded) — the exact same combined Markdown document the
`.md` export writes (`telemetry.markdown_all()`) is handed to
`pdfport.create()` as text instead of written to a `.md` file first. Fails
clearly if pdfport.nvim isn't installed or has no available markdown
producer (pandoc + a PDF engine), rather than silently falling back to
another format.

Asynchronous, unlike `.md`/`.json` — `lua/runtime-analysis/telemetry/
command.lua`'s `export()` gained a `pdf_callback` param used only by the
`.pdf` branch (`export_pdf()`), and the `:RATelemetry export` dispatcher
now branches on the extension before deciding sync-return vs.
callback-based reporting. The headless CLI (`scripts/telemetry.lua`)
mirrors `add_lib_nvim()`'s three-candidate rtp search
(`PDFPORT_DIR`/`.deps/pdfport.nvim`/sibling checkout) as a new
`try_add_pdfport()` — best-effort, unlike the mandatory `add_lib_nvim()`,
since only `export ... .pdf` needs it — then blocks on `vim.wait()` for
pdfport's async callback before the script can exit. `:checkhealth
runtime-analysis` gained an "optional tools" line for pdfport.nvim
availability. Test coverage in `docs/TESTS/telemetry_spec.lua` (stubs
`package.loaded["pdfport"]`, same pattern as `github_stats.nvim`/
`documentation.nvim`/`markdown.nvim`).

### `scripts/bench_overhead.lua` — instrumentation overhead, not a usercmd (2026-08-10)

Not bound to anything, deliberately — a one-time (or occasional) dev-side
benchmark (`nvim --headless -l scripts/bench_overhead.lua [--calls=N]`),
same posture `scripts/telemetry.lua` above already has as a headless
companion to a real command. Answers docs/ROADMAP.md §3.7 ("measuring
this module's own instrumentation overhead"): unwrapped baseline vs.
counting/+timing/+argument profiling/+`call_tree`/+`errors`, timed via
`vim.uv.hrtime()`. Explicitly not a `:RATelemetry` subcommand or anything
user-toggleable — that exclusion is what lets it exist without reopening
§3.5's "not a general profiler" rejection; see the decision record in
`docs/FINISHED.md` for the full reasoning. Numbers feed
`lua/runtime-analysis/telemetry/README.md`'s own overhead table, which now
points back at the script rather than citing bare decimals with nothing
backing them.

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

**HTML dashboard (§4.4, `report_style = "html"`)** — `:RATelemetry open`
with this style renders a sortable/filterable HTML table (one row per
function: calls, errors, mean timing, top argument/caller fingerprint,
click to expand the full breakdown) and opens it in the system browser
via `lib.nvim.fs.open.url.system_opener` — the same opener `:DocMap
open` uses. New module `lua/runtime-analysis/telemetry/renderers/html.lua`
— a small, self-contained page reusing documentation.nvim's own CSS
design tokens (not its ~4,500-line renderer code).

Full API this command is a front-end over (instances, `wrap`/`wrap_loaded`,
`auto()`, the lazy.nvim adapter, argument profiling): see
[lib.nvim.md's Telemetry section](./lib.nvim.md) for how this personal
config actually wires `opts.telemetry` into the plugin's own spec
(`lua/plugins/personal/init.lua`'s `runtime-analysis.nvim` entry,
`lua/config/telemetry.lua` for the policy), and
`lua/runtime-analysis/telemetry/README.md` in the repo for the module's own
full reference.

## Global-surface collision check (2026-08-15, re-checked after `ResetAll`/`SetupAll`/`SetupAllFull` were added)

Checked against every `Usercmds/*.md` in this folder: `RA`, `RARequest`,
`RASend`, `RATelemetry`, `RATelemetryStartAll`, `RATelemetryStopAll`,
`RATelemetryResetAll`, `RATelemetrySetupAll` and `RATelemetrySetupAllFull`
are unique — no other personal plugin registers any of the nine, and no
other plugin owns an `RA`-prefixed command.
