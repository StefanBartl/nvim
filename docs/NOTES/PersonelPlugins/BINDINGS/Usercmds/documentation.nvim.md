# documentation.nvim — Usercmds Cheatsheet

Source: `lua/documentation/bindings/usrcmds/` — `init.lua` dispatches, one file
per action.
Cross-reference: the repo's `docs/BINDINGS.md` (generated) and
`docs/COMMANDS.md` (prose reference).

Two commands, split along one line: **`:DocMap` writes or verifies artifacts,
`:DocBrowse` only ever reads.** The viewer is deliberately not a `:DocMap`
subcommand — folding a read-only viewer into a command whose bare form rewrites
files on disk is the kind of surprise that gets a command bound to a key and
then regretted.

Both names are configurable (`opts.command_name`, `opts.browse_command_name`),
which is what lets a *consuming* plugin generate its own map without
overwriting these.

## Which repo do they act on? (2026-08-05)

**Per invocation, from the current buffer's file** — up to the nearest `.git`
(`opts.root_markers`), falling back to `:pwd` for a buffer with no file. Our
spec sets no `root` on purpose (the comment in `plugins/personal/init.lua` says
why: the repos here sit side by side), so this is the path we take.

Setting `opts.root` pins instead.

### The bug this replaced — worth remembering, it cost a night

The root used to be resolved **once, in `setup()`**. Our spec is
`cmd = { "DocMap", "DocBrowse" }`, so "once" meant *the first `:DocMap` of the
session*, and every later invocation regenerated **that first repo** no matter
which tree was open. Hit live: `:DocMap full` in `documentation.nvim` worked,
then the same command with a `lib.nvim` file open silently rewrote
`documentation.nvim`'s map a second time and reported success.

Two things hid it, and both are fixed:

- Switching buffers does not change `:pwd`, so even *per-invocation* `getcwd()`
  would have been wrong. The question is a buffer question, which is how every
  other plugin that has to answer it (LSP roots, gitsigns, pickers) answers it.
- **The report named no repo.** `Wrote 3 artifacts (4 modules, 0 errors)` — the
  giveaway was that "4 modules" was `documentation.nvim`'s own count both times.
  Now every report leads with the repo: `lib.nvim: wrote 3 artifacts (…)`.

Handles are cached per root, so bouncing between repos scans each once.
Completion deliberately never installs one — `<Tab>` in an unscanned repo
offers action names only, instead of blocking on a full scan.

## `:DocMap`

| Invocation | Does | Writes? |
| --- | --- | --- |
| `:DocMap` | Rescan and regenerate all artifacts | **yes** |
| `:DocMap full` | Same, with LuaLS enrichment (`@class`/`@alias` detail, type edges). Costs seconds. | **yes** |
| `:DocMap check` | Verify without writing; findings → quickfix. What the pre-commit hook runs. | no |
| `:DocMap open` | Open the generated HTML in the system browser | no |
| `:DocMap graph {deps\|calls} [module]` | Open the page on that graph, centered | no |
| `:DocMap dot [deps\|calls] [module]` | Graphviz DOT source in a scratch buffer (`:%!dot -Tsvg`) | no |
| `:DocMap why <a> <b>` | Shortest require path between two modules → quickfix, one entry per hop | no |
| `:DocMap diff [ref]` | What changed about the tree's *shape* since `ref` (default HEAD) | no |
| `:DocMap impact [ref]` | Where changed *lines* radiate to: functions → callers → quickfix | no |
| `:DocMap churn [range]` | Churn × complexity, hottest first → quickfix | no |
| `:DocMap plugins` | Every recognized lazy.nvim spec in the tree → quickfix, sorted by repo | no |
| `:DocMap tools` | This repo's own `lib.nvim.deps` manifest (`docs/install.json`/`docs/INSTALL.md`) → quickfix. Declared only — never a live "is it installed here" probe. Shipped 2026-08-10. | no |
| `:DocMap serve [stop]` | Local map server on `127.0.0.1`, OS-assigned port. Enables the History tab. | no |
| `:DocMap helptags` | Regenerate this plugin's own `doc/tags` | writes `doc/tags` |

**Only a genuinely empty argument regenerates.** An unknown action reports what
it expected. (Until 2026-07-28 the old if-chain fell through to the default, so
`:DocMap graph` with a missing argument — or any typo — silently rewrote files.)
An unknown verb is now rejected *before* a root is resolved, so a typo cannot
trigger a scan of a repo you never got to act on.

Completion is two-level: the action first, then real module paths once an
action that takes one is typed. It offers exactly what `find_node` resolves,
namespaces included.

## `:DocBrowse`

| Invocation | Opens on |
| --- | --- |
| `:DocBrowse` | the structure list, from the committed artifact (~10 ms) |
| `:DocBrowse live` | same, but installing a watching handle that rescans on write (~0.65 s once) |
| `:DocBrowse {module}` | centered on one module |
| `:DocBrowse history` | the commit list |
| `:DocBrowse trail` | the pinned positions |
| `:DocBrowse endpoints` | every call-based route registration across the whole tree, not centered on any node. Enriched with coverage (`○` badge) when `runtime-analysis.nvim` is installed and has request history for this project — `gs` sends the selected route as a request. Shipped 2026-08-03/04. |
| `:DocBrowse telemetry` | the static × runtime join against `runtime-analysis.telemetry` — `✕`/`!`/`○`/blank per function, soft dependency on `runtime-analysis.nvim`. Shipped 2026-08-03 (ECOSYSTEM.md step 8). |
| `:DocBrowse loaded` | diff loaded-vs-declared against `runtime-analysis.loaded` (`runtime-analysis.nvim`'s own §5.3) — `✕` declared, not loaded this session; `!` loaded, not declared. Soft dependency. Shipped 2026-08-04. |

`live` is a prefix a module name may follow; `history`, `trail`, `endpoints`,
`telemetry` and `loaded` stand *where* a module name would — none of them
takes one, so anything typed after is meaningless. Modes are positional
(`1`…`9` inside the browser): structure, deps, calls, types, history, trail,
endpoints, telemetry, loaded.

## Two new tabs on the generated page (2026-08-05)

Nothing to bind — no command reaches them, they are in `index.html` — but worth
knowing they exist, because neither is discoverable from `:DocMap`'s help text.

**Quicks** (leads the tab bar, but the page still *lands* on Tree so old links
and habits are untouched). The tree stated in sentences: *"Most of your
published API is never named in a spec — 12% — 9 of 72"*. Negatives first, five
of each polarity. Every verdict prints what it actually measured and links to
the panel with the rows — the plugin refuses confident-but-uncheckable numbers
everywhere else (`calls_heuristic`, `dead_code` off by default), so a prose
verdict has to carry its own basis or it breaks that rule. Empty tab = every
measure landed between its cut points = fine, not broken. Tune with
`opts.quicks.thresholds`.

Purity ("N% pure functions") is deliberately absent — not derivable from the
IR, and guessing it is exactly what the paragraph above rules out.

**Compare**. The `+` next to the `ⓘ` on any function or module marks it; the
`Compare (N)` button by the filter opens them. Matrix layout (attributes down,
objects across, differing rows lit) is the one worth using — Columns/Stacked
are just the annotation cards side by side. Marks live in the URL *and*
`localStorage`, so a set is shareable and survives a `:DocMap` regenerate.

The `+` is a separate control on purpose: clicking the `ⓘ` already pins the
annotation popup, which is what makes a long `@example` readable.

## Global-surface collision check (2026-07-28)

The command names are this plugin's only global surface. Checked against every
`Usercmds/*.md` in this folder: **`DocMap` and `DocBrowse` are unique** — no
other personal plugin registers either name or a `Doc`-prefixed command.

Note `:checkhealth documentation` is also registered, implicitly, by the
presence of `lua/documentation/editor/health.lua`.

## `opts.pdf` — overview.pdf via pdfport.nvim (2026-08-09)

Fourth artifact alongside `index.html`/`overview.md`/`module_map.json`
(and the existing opt-in `coverage.svg`/`opts.badge`): set
`opts.pdf = true` and a bare `:DocMap`/`:DocMap full` also writes
`docs/map/overview.pdf` — byte-for-byte the same content `overview.md`
gets, handed to [pdfport.nvim](https://github.com/StefanBartl/pdfport.nvim)
(optional dependency, `pcall`-guarded) as text via `pdfport.create()`
instead of read back from a written `.md` file.

Off by default, and **asynchronous** unlike every other artifact — pdfport's
markdown producer shells out to `pandoc`, so it cannot be folded into
`write_artifacts()`'s synchronous `written` list. `bindings/usrcmds/generate.lua`
fires it as a second step after the normal "wrote N artifacts" notification
and reports it separately once pdfport's callback returns
(`documentation.write_pdf_artifact(ir, findings, ctx.cfg, callback)`, new
function in `init.lua`). `:checkhealth documentation` gained a line for it
in the "optional tools" section. Test coverage in
`TESTS/pdf_artifact_spec.lua`, same stub-`package.loaded["pdfport"]` pattern
as `github_stats.nvim`/`markdown.nvim`.

## `opts.godbolt` — Compiler Explorer links, experimental (2026-08-10)

Reopened from the roadmap after feedback corrected an earlier wrong premise:
Compiler Explorer (godbolt.org) does compile Lua — its `lua` compiler class
runs `luac -l -l -p` and shows real, verbose bytecode disassembly with
source-line association, a genuine analog to assembly output for a compiled
language. Off by default upstream (**experimental**, opt-in); set to `true`
in our own `plugins/personal/init.lua` spec.

Unlike `opts.pdf`, this is `generate()`/`scan_full()`-scoped, not
`install()`-scoped: it bakes `meta.godbolt` into the generated static HTML
itself (mirroring the existing render-time-only `meta.out_depth` pattern), so
the link works for anyone opening the committed `docs/map/index.html` cold —
no live Neovim session or watch handle required.

**What it does**: a small icon (`godboltTrigger`, modeled on the existing
`sigTrigger`/`docTrigger` click-icon idiom) appears next to a module heading
and next to each function in the detail pane, when `opts.godbolt` is on. It
opens a `https://godbolt.org/clientstate/<base64(JSON)>` link in a new tab,
pre-loaded with that function's source (or, at module level, that module's
functions concatenated in declaration order) and the `lua547` compiler
selected. No new IR field: it reuses `fn.snippet`, already serialized for the
hover-preview feature and already bounded by `core/snippet.lua`'s own line
cap.

**"Whole project" loading — investigated, not implemented.** Compiler
Explorer's multi-file project support is build-system-specific (CMake) and
scoped to C/C++/Java; there is no Lua-specific multi-file mechanism to hook
into, so a genuine "load the whole project" feature does not exist on the
target site to build against. The per-function/per-module snippet link is the
honest substitute, and it is explicitly disclosed (in the client-side code
comment) as an approximation rather than a byte-perfect file reconstruction —
which is also the stated reason this ships marked experimental rather than
promoted to a default-on artifact like `opts.pdf`.
