# lib.nvim — `:Lib <subcommand>` Cheatsheet

lib.nvim is the library itself — this is its **own dogfooding** use of
`lib.nvim.bindings.usercmd.composer` (`lua/lib/nvim_usrcmds/init.lua`), registered
**alongside** the pre-existing flat commands (kept for muscle memory — this
repo, unlike published standalone plugins, opted for alongside not replace).

| Command | Effect | Flat equivalent |
| --- | --- | --- |
| `:Lib cwd-here` | lcd to the current buffer's directory | `:CwdHere` (still works) |
| `:Lib ps-profile` | Open the active PowerShell profile | `:PowershellProfile` (still works, Windows only) |
| `:Lib helptags` | Regenerate all helptags now | (was autocmd-only before) |
| `:Lib deps show [plugin]` | Declared external tools for `plugin` (why each matters, present/missing), or every plugin shipping a spec if omitted | none — new surface |
| `:Lib deps install plugin` | Compose an install command for whatever `plugin` is missing, confirm, hand off to a terminal | none — new surface |
| `:Lib hover toggle` / `on` / `off` | Den Pfad-/Link-Hover fuer diese Sitzung aus- und wieder einschalten; `on`/`off` sagen es ausdruecklich, statt zu kippen |
| `:Lib hover web toggle` / `on` / `off` | Whether http(s) links hover at all. Off by default — see below | none — new surface |
| `:Lib hover web fetch toggle` / `on` / `off` | Whether a hovered link is fetched for its status code, `<title>` and description. Implies `web on` | none — new surface |
| `:Lib hover office toggle` / `on` / `off` | Whether `.docx`/`.xlsx`/`.pptx`/… are rendered through a PDF (pdfport.nvim + LibreOffice) instead of showing a badge | none — new surface |

Gated by `nvim_usrcmds.setup({ lib_verb = true })` (default: on). Set
`lib_verb = false` to disable the `:Lib` verb and keep only the flat commands.
`deps = false` disables just the `deps` routes and keeps the rest of `:Lib`.

### `:Lib hover web` / `:Lib hover office` — the two opt-in previews

Both are off by default, and both are commands rather than settings because
they are things you switch **while chasing something** and switch back
afterwards.

**`web`** — links do not hover unless asked. Dev documentation is made of
links; with the hover on, resting the cursor almost anywhere in a paragraph
opens a float over the sentence being read. Two levels:

```vim
:Lib hover web on          " parsed offline: host, path, decoded query
:Lib hover web fetch on    " …plus HTTP status, <title>, content type
:Lib hover web off         " silence on links again
```

`fetch` is what answers "is this link dead": the float leads with
`HTTP 404 Not Found` / `HTTP 500 Internal Server Error`, marked through
`LibHoverError`. It is separate from `web on` because fetching discloses every
link the cursor rests on to its host. Results are cached for the session;
toggling drops the cache.

Works in **every** filetype, not only markdown — markdown.nvim finds links
inside `.md`, lib.nvim's own `bare_url` source finds a URL in a Lua comment, a
`.txt` or a `:messages` dump. `http:\\example.com` (Windows-keyboard typo) and
`www.example.com` are both recognized and repaired.

**`office`** — a `.docx` cannot be read as text; it is a ZIP container, and
the hover used to show its bytes. Now it shows a badge (`◆ Word document ·
DOCX · 24 KB`), and so does anything else whose bytes are not text — archives,
executables, media — decided by looking at the bytes, not at a list of
extensions. With `:Lib hover office on`, pdfport.nvim converts the document to
a PDF through LibreOffice and the first page is drawn like any other picture,
with the same paging keys. Opt-in because the first conversion of each
document starts LibreOffice (seconds); afterwards it is cached per file and
mtime.

Needs `soffice` on `PATH` — `:Lib deps show pdfport.nvim` says whether it is
there, and the badge itself says so when it is not.

### `:Lib deps` — declared external tools (`lib.nvim.deps`)

A plugin that needs an optional CLI tool (pandoc, ImageMagick, tesseract,
poppler-utils, …) to unlock a feature can declare it in its own
`docs/INSTALL.md` or `docs/install.json`, instead of only warning about it
in `:checkhealth`. Each declared tool carries a **required** `why` — "install
X because it enables Y" — not just a bare "X is missing".

```
:Lib deps show pdfport.nvim
```
```
# pdfport.nvim — external tools

Package manager: scoop
Tools declared: 14  ·  present: 9  ·  missing: 5

[missing] tesseract
    Enables OCR extraction for scanned or image-only PDFs...
    scoop install tesseract
...
```

`pdfport.nvim` is the first plugin to ship a spec
(`docs/install.json`, 6 tools originally for the extraction backends; grew
to 14 on 2026-08-09 when the create()/merge() producers — img2pdf, magick,
pandoc, weasyprint, soffice, qpdf, pdftk, ghostscript — got their own
entries alongside the extraction ones, and to 15 on 2026-08-30 with
`ueberzugpp`). Nothing installs on its own:
`:Lib deps install` composes the command for whatever package manager is on
this host (winget/scoop/choco here, apt/dnf/pacman/zypper/apk on Linux,
brew on macOS), asks for confirmation, then **types** the command into a
terminal split without submitting it — the sudo/UAC prompt, if any, is
answered at that real terminal, not by a backgrounded job.

### One tool, several spellings — `bin_alternatives` (2026-08-30)

A tool entry may declare `bin_alternatives`: other executable names the
**same** program is installed as on some platform. Ghostscript is `gs` on
Linux and macOS and `gswin64c`/`gswin32c` on Windows — same program, same
package, same reason to want it.

```json
{ "bin": "gs", "bin_alternatives": ["gswin64c", "gswin32c"], "why": "…", "pkg": { … } }
```

Detection only. `bin` stays canonical for identity, display label, install
target and the `pkg` map; the report names the spelling that answered:

```
gs found (as gswin64c)
```

Without it, this machine got the contradiction the field was added for:
`:checkhealth pdfport` said "ghostscript producer: ready (exe: gswin64c)" in
one section and "gs NOT found" in the next.

It is **not** a list of substitutes — a different program that would also do
the job is a different tool with its own `why` and `pkg` (`qpdf` and `pdftk`
both merge PDFs and stay two entries). A bare string instead of a list is
rejected at validation, because a string iterates as an empty list and the
alternative would silently never be probed.

Shared by all three callers that ask "is it here" via `lib.nvim.deps.detect`:
the `:checkhealth` line, `install.plan` (so a tool present under its Windows
name is not planned for installation) and `:Lib deps show`'s `i` key.

Under the hood the lookup needed a fix that's worth knowing about if
`:Lib deps` ever looks like it's missing a plugin: `runtimepath` alone only sees
plugins lazy.nvim has actually **loaded**. Measured on this config while
building it — 120 plugins configured, 44 loaded at startup, 76 pending —
`lib.nvim.deps.spec.find`/`plugins` therefore also consults
`lazy.core.config`'s registry (via `pcall`, no hard dependency) for
plugins that are installed but not yet loaded.

Full design, the format spec, and the package-manager list:
`lua/lib/nvim/deps/README.md` and `docs/ROADMAP/dependency-installer.md` in
the lib.nvim repo, `:help lib.nvim-deps`.

## Module control commands (separate from the `:Lib` verb)

Some modules ship their own flat control command. None goes through the
composer — they predate/sit outside the verb and are about *runtime state of
that module*, not about lib.nvim as a plugin. (No count in that sentence on
purpose: the previous one said "two" while the table listed three.)

| Command | Registered when | Effect |
| --- | --- | --- |
| `:LibLogger [show\|on\|off\|level <l>\|dump\|clear\|tags]` | automatically, on the first `logger.new()` | Flip logging on/off, change level, inspect/dump/clear the ring buffer |
| `:RATelemetry [report\|start\|stop\|reset\|coverage\|export\|open]` | **only** after `require("runtime-analysis.telemetry.command").setup()` | Read/steer call-counting across every live telemetry instance |
| `:KitPreview` | `require("lib.nvim.ui.kit")` dev-tool | Live theme playground (see the Keymaps cheatsheet for its in-buffer keys) |
| `:LibAutocmdDocs` / `:LibAutocmdDocsCheck` | `autocmd.docs.create_usercmd()` | Write the registered autocmds into `bindings/autocmd` as markdown / report whether that folder still matches what is registered, naming the stale files |
| `:LibUsercmdDocs` / `:LibUsercmdDocsCheck` | `usercmd.docs.create_usercmd()` | Same for user commands, into `bindings/usercmd` |

**Why the `…Check` halves are easy to miss.** Each pair comes out of a single
`create_usercmd(name)` call that registers `base` and `base .. "Check"` — so
grepping a source tree for the literal string `LibAutocmdDocsCheck` finds
nothing, and a cheatsheet written from such a grep lists only the base. Same
shape as the `:MyOpt*` / `:WKDOptions*` registrar in
[nvim-config.md](./nvim-config.md#options): document the generator, not one of
its results. `name` is the caller's, so a repo that renames the base renames
its `Check` twin with it.

### `:RATelemetry`

`runtime-analysis.telemetry` counts how often functions are called, persists the
counts across restarts, and — with argument profiling on — tells you when one
argument dominates. Bare `:RATelemetry` reports across every live instance in
a kit float; a bare namespace argument narrows it to one.

| Form | Effect |
| --- | --- |
| `:RATelemetry` | Report across all instances |
| `:RATelemetry markdown.nvim` | Report for that namespace only |
| `:RATelemetry start [ns]` / `stop [ns]` | Install / restore the wrappers — every instance, or just one, for this session only |
| `:RATelemetry disable [ns]` / `enable [ns]` | Same, but **persisted** — survives a restart. Stops/resumes a running instance immediately too |
| `:RATelemetry disabled` | List every namespace currently disabled |
| `:RATelemetry reset [ns]` | Drop collected data (memory **and** disk) — every instance, or just one |
| `:RATelemetry coverage` | Which wrapped functions were called **zero** times |
| `:RATelemetry export [path]` | JSON snapshot (defaults under `stdpath("cache")`); Markdown instead if `path` ends `.md` |
| `:RATelemetry open [ns]` | Render + open externally — mdview browser tab if loadable, else the same kit float `report` shows |

`start`/`stop`/`reset`/`disable`/`enable`/`open` all take the namespace as a
second token (`:RATelemetry stop markdown.nvim`); `<Tab>` after any of them
completes namespaces only, not the subcommand list again.

**`stop` vs. `disable`**: `stop` is for "pause it for now" — the next Neovim
session starts it again exactly as `config/telemetry.lua` always has.
`disable` is for "I'm done watching this one" — it survives restarts without
touching that file, and works even before the plugin has loaded (disable it
ahead of time, e.g. `:RATelemetry disable markdown.nvim` right after
opening Neovim, before any `.md` buffer triggers its `ft=markdown` load).

Opt-in registration is deliberate — the module itself never claims a
user-command name on its own; a library that did would collide with someone's
own mapping. **This config does opt in**, via `runtime-analysis.nvim`'s own
plugin spec in `plugins/personal/init.lua`: its `opts.telemetry` (built by
`lua/config/telemetry.lua`) drives `runtime-analysis.telemetry.lazy`, which
registers `:RATelemetry`, does a catch-up scan of everything already loaded,
then wraps+starts an instance for `lib.nvim` itself plus every personal
plugin as each one loads (namespace = the plugin's lazy.nvim name). No
special early-init.lua call, and no hardcoded module name per plugin — see
that adapter's own doc-comment (in runtime-analysis.nvim) for the catch-up
mechanism, and `lua/config/telemetry.lua`'s for the policy this config feeds
it.

### What this config actually collects

**Depth.** Each plugin is wrapped with `wrap_loaded(<its main module>)`, not
just its `init.lua`. That matters more than it sounds: a plugin's entry module
is usually a thin façade, and the functions its keymaps really call sit in
submodules. Measured on markdown.nvim — `require("markdown")` is 11 one-line
delegators; the 35 loaded `markdown.*` modules hold **125** functions:

| Plugin | wrapped |
| --- | ---: |
| filetree.nvim | 381 |
| cascade.nvim | 138 |
| markdown.nvim / mdview.nvim | 125 |
| color_my_ascii.nvim | 94 |
| lib.nvim (aggregate, see below) | 282 |

**Arguments.** `profile_args` is on for personal plugins, so the report shows
*which* arguments and how often — the part that turns a count into a decision:

```
config.feature_enabled                78 calls
    └  64 %  ("keymaps")
    └  26 %  ("fenced_scope")
core.fold.foldexpr                    42 calls
```

**lib.nvim itself is counting-only.** Its instance uses lib.nvim's own thin
caller, `lib.strategies.telemetry_wrap` (the public aggregate — the
interesting question there is which exported keys get used) and
deliberately skips argument profiling: the aggregate reaches
`lib.tables.core`-style primitives that genuinely run in loops. Measured,
counting costs 0.014 µs/call while argument profiling costs 0.619 µs — nothing
on a keypress-driven plugin surface, a real cost in an inner loop.

Tune it in `plugins/personal/init.lua`'s `runtime-analysis.nvim` spec entry
— `opts` there calls straight into this policy:

```lua
opts = function(_, opts)
  opts.telemetry = require("config.telemetry").build({
    deep         = true,                    -- or { "markdown.nvim", ... }
    profile_args = { "markdown.nvim" },     -- narrow it if a plugin is hot
    timing       = false,
    exclude      = { "github_stats.nvim" }, -- skip a plugin entirely
    lib_profile_args = false,               -- args for lib.nvim's aggregate
  })
  return opts
end,
```

### Blind spot worth knowing (verified, not theoretical)

A keymap that captured a function reference **before** the wrap holds the raw
function and is invisible. For `ft`-triggered plugins this permanently affects
the **first** buffer of a session: lazy.nvim runs the plugin's FileType
handlers — which bind the keymaps — *before* `User LazyLoad` fires, so even the
earliest possible hook is too late for that one buffer. Every buffer after it
is instrumented normally.

Irrelevant for week-long counting, confusing if you press a key once and expect
the counter to move. Open a second buffer and press again.

### Manual setup

For something not covered by the generic pass:

```lua
require("runtime-analysis.telemetry.command").setup()  -- idempotent; already done above

local t = require("runtime-analysis.telemetry").new({ namespace = "my-thing" })
t.wrap_loaded("my_thing", { module_filter = function(n) return not n:find("@types", 1, true) end })
t.start({ profile_args = true })   -- nothing is wrapped until this runs
```

Nothing is installed before `start()` — until then the shipped functions *are*
the original functions, so leaving the module required costs nothing. Details:
`lua/runtime-analysis/telemetry/README.md` in the runtime-analysis.nvim repo.

### Reading a namespace from a different process

`telemetry.load(namespace, opts)` reads a namespace's counts straight off
disk — no live instance, no `t = telemetry.new(...)` needed. Returns `nil`
when nothing was ever persisted for that namespace (distinct from a
well-formed-but-empty table), so a caller can tell "never collected here"
from "collected, zero calls". Built for a tool that only wants to *read*
someone else's counts from a fresh Neovim process — e.g. documentation.nvim's
planned `dead-function` cross-check (static "no caller found" vs. telemetry
"actually called" — each blind spot is the other's evidence; see
`docs/ROADMAP/telemetry-documentation-bridge.md` in the lib.nvim repo). Not
consumed by anything in this config yet.

Alongside it, a wrapped key can now resolve back to the real Lua module it
came from: `wrap_loaded()` records this automatically (its keys already come
from `package.loaded`), a plain `wrap()` only if given `opts.module_id`
explicitly, and the map is queryable live (`t.resolved_modules()`) or off
disk (`data.modules` from `telemetry.load()`). A key with no entry is
*unmatched*, never "zero calls" — the two are different claims.

### Browser report (Markdown + `:RATelemetry open`)

In runtime-analysis.telemetry: `t.markdown(opts)` / `telemetry.markdown_all(opts)` render
the same report data as `t.lines()`/`:RATelemetry`, but as a GFM table
instead of terminal box-drawing — pastable into an issue, diffable across
weeks. `:RATelemetry export report.md` writes it (format is inferred from
the `.md` extension, no separate flag).

`report_file = true` on `telemetry.new({...})` keeps a namespace's Markdown
report on disk, rewritten at every flush
(`stdpath("cache")/runtime-analysis.nvim/telemetry/<namespace>.md`). Point mdview.nvim's
`:MDView standalone` at that same path — or just run `:RATelemetry open
<ns>` — and the browser tab becomes a **self-updating live dashboard**: the
relay already watches a file for `:MDView standalone`, telemetry already
flushes periodically, so nothing new is wired up on either side.

`report_style` (module-level default, `telemetry.setup({ report_style =
"auto" })`) picks what `:RATelemetry open` renders with: `"auto"` (mdview if
loadable, else the kit float — this config's plugins would resolve to mdview
automatically, nothing to configure), `"kit"`, `"mdview"`, or `"file"`
(write-only, no window). Verified against mdview.nvim's actual source while
building this: **both** `:MDView start` and `:MDView standalone` self-install
the same relay binary from GitHub Releases on first use (checksum-verified,
mason.nvim-style) — no separate manual build step for either mode, contrary
to an earlier assumption in this config's own notes. Not consumed by anything
in this config yet — `config/telemetry.lua` would need `report_file = true`
added per plugin (or just globally) to make it useful here. Details: the
"Browser report" section of `lua/runtime-analysis/telemetry/README.md` in
the runtime-analysis.nvim repo.

## The composer module itself

`lua/lib/nvim/bindings/usercmd/composer/` — the actual reusable module every other
plugin's cheatsheet in this directory is built on.

- Design doc: `docs/ROADMAP/usrcmd_builder.md` (in the lib.nvim repo)
- API docs: `lua/lib/nvim/bindings/usercmd/composer/README.md`, `:h lib.nvim-composer`
- Access: `require("lib.nvim.bindings.usercmd.composer")`, `require("lib").composer`,
  or `require("lib").usercmd.composer`

### Route spec shape (quick reference)

```lua
local composer = require("lib.nvim.bindings.usercmd.composer")

composer.verb("Verb", {
  desc    = "…",
  default = function(ctx) end,        -- bare `:Verb` (zero tokens)
  bang    = true,                     -- or per-route
  routes  = {
    { path = { "sub" },
      args  = { { name = "x", type = "STRING", enum = {"a","b"}, optional = true } },
      flags = { { name = "dry", bool = true } },  -- Phase 6, opt-in per route
      desc  = "…",
      run   = function(ctx) end },    -- ctx.args, ctx.flags, ctx.rest, ctx.bang, ctx.range, ctx.raw
  },
})
```

`path = {}` = the verb's **root route** (matches even with zero literal
subcommand tokens — used for flat positional+flag grammars like
`replacer.nvim`'s `:Replace {old} {new} [--flags]`).

### Argument types

`STRING` (default) · `INT` · `FLOAT` · `BOOL` · `PATH` · `DIR` · `FILE` ·
`BUFFER` · `enum = {...}` on any arg (case-insensitive, closed set). Custom
types via `composer.register_type(name, { validate, complete })`.

### Docgen

`composer.document()` / `handle:document()` → `docs/BINDINGS/Usercmds.md` by
default (`composer.setup({ docs = { path, mode } })` to override; `mode =
"section"` updates a delimited block instead of overwriting the whole file).
