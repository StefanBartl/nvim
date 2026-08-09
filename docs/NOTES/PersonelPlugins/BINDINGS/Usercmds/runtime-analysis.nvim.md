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

## `:RA {subcommand}` — request/send/yank/cancel/history/env/import/export/provenance/inspect/usage

Built via `lib.nvim.usercmd.composer` — same verb-first shape `:DocMap`/
`:MDView` use, `<Tab>`-completed (`:RA <Tab>` →
`request | send | yank | cancel | history | env | import | export |
provenance | inspect | usage`).
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
| `:RA provenance <path>` | "Who wrapped this function" — e.g. `:RA provenance vim.notify`. Exact for this plugin's own telemetry wraps (named by namespace), best-effort otherwise (`debug.getinfo` source location). Shipped 2026-08-04 (§5.2). |
| `:RA inspect <module>` | Walks a live `package.loaded[module]` table — functions (upvalue counts, source location), nested tables (own shape, cycle-safe, `max_depth=3` for readability), metatables, keys that *shadow* a table `__index`. `<Tab>`-completes against `package.loaded`, live. `__index` reported, never called — a pure read. Renders via `lib.nvim.ui.kit.viewer`, `vim.notify` fallback. Shipped 2026-08-04 (§5.1). |
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
| `:RATelemetry open [ns]` | render + open externally (`report_style`: `auto`/`kit`/`mdview`/`file`/`html`) |
| `:RATelemetry compare [ns] [days]` | "this window vs the one before it" (default 7d) — newly-hot/gone-cold/changed functions. Shipped 2026-08-04 (§4.2). |
| `:RATelemetry startup [top]` | Which *module* a plugin's startup cost sits in, as a waterfall (self vs. total time, grouped per module and per module root). Shipped 2026-08-04 (§3.3). **Needs the opt-in below.** |
| `:RATelemetry cost` | Startup cost vs. call count per namespace, worst (expensive, underused) first. Shipped 2026-08-04 (§7.2). Joins `startup`'s per-module-root data against each instance's own `resolved_modules()` on real module paths — never guesses a namespace ("markdown.nvim") matches a module root ("markdown") by string similarity. |

`<Tab>` after `start `/`stop `/`reset `/`open `/`compare ` completes
namespaces only; `compare`'s third token (a day count) isn't completed,
and `startup` takes no namespace at all (its second token is a `top`
count).

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

## Global-surface collision check (2026-08-04, re-checked after `:RA usage` was added)

Checked against every `Usercmds/*.md` in this folder: `RA`, `RARequest`,
`RASend` and `RATelemetry` are unique — no other personal plugin registers
any of the four, and no other plugin owns an `RA`-prefixed command.
