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

### Revision completion for `diff`/`churn` (2026-08-25)

Closes the `RULES-flags-options.md` entry. Both take a revision, and both
used to fall through to the *action* list — so `:DocMap diff <Tab>` offered
`bindings`/`plugins`/…, which is worse than offering nothing: every
candidate was wrong. They now complete against the repo's own refs (local
branches, remote branches with their prefix, tags; newest commit first), and
`churn`, taking a range, continues an `A..`/`A...` lead and hands back the
whole `A..B` token.

The listing itself went into lib.nvim as `git.refs(dir, opts)` rather than
into this plugin's completion callback — "which revision?" is not a
documentation.nvim question. Two things there are load-bearing and easy to
get wrong: `for-each-ref` sorts by *refname* by default, which buries the
branch you were on ten seconds ago behind anything starting with `a`
(`-committerdate` fixes it), and remote branches must keep their prefix,
both because that is how git accepts them as a revision and because
stripping it collides with the identically named local branch.

Cached ~5s, not per session: branches appear and vanish while an editor is
open, so a session cache would be stale in the normal case; the TTL exists
only so a held `<Tab>` does not spawn one `git for-each-ref` per keystroke.

### `<Plug>` mappings for `DocBrowse` actions — n/a (2026-08-25)

Not a gap: `<Plug>` mappings are not this ecosystem's convention. `opts.keys`
(a string or list of lhs per action id, `false` to disable, typo-checked
against the known ids) plus `lib.nvim.bindings.keymap` already cover rebinding
completely; which-key labels are the only mandatory piece on top.

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
| `:DocMap bindings` | Every keymap / user command / autocmd in the tree → quickfix, sorted by lhs so **collisions land adjacent** (`[bound more than once]`). Needs `opts.bindings.wrappers` for this config's own helpers — see below. Shipped 2026-08-15. | no |
| `:DocMap tools` | This repo's own `lib.nvim.deps` manifest (`docs/install.json`/`docs/INSTALL.md`) → quickfix. Declared only — never a live "is it installed here" probe. Shipped 2026-08-10. | no |
| `:DocMap serve [stop]` | Local map server on `127.0.0.1`, OS-assigned port. Enables the History tab. | no |
| `:DocMap helptags` | Regenerate this plugin's own `doc/tags` | writes `doc/tags` |
| `:DocMap all` | Generate every project in `opts.generate_all.projects` — one real headless subprocess each. Only registered when that option is configured. See "opts.generate_all" below. Shipped 2026-08-14. | **yes**, per project |
| `:DocMap annotate [--write\|--sidecar]` | Geruest fuer einen `---@module`-Kopf — und, wenn die Datei eine Tabelle zurueckgibt, einen `---@class`-Block mit einem `---@field` je exportiertem Namen — fuer jede Datei, der er fehlt | nur mit `--write` (in die Quelldatei) oder `--sidecar` (`*.annot.lua`); ohne Flag reine Vorschau |
| `:DocMap browse` | Nur-Lese-Ansicht der Karte, in ein Kommando gefaltet | no |
| `:DocMap checklist [all]` | Das handgepruefte **Ledger** in die Quickfix-Liste: Eintraege, deren Richtigkeit manuell geprueft wurde, gegen `git log` gekreuzt, um zu markieren, welche seither veraltet sein koennten. `all` zeigt alles statt nur der auffaelligen | no |
| `:DocMap consumers [dir]` | **Wer diese Bibliothek tatsaechlich benutzt.** Liest jede `*/docs/map/module_map.json` unterhalb von `dir` (per Default das Elternverzeichnis, wo die Geschwister-Checkouts liegen) | no |
| `:DocMap endpoints` | Jede erkannte **call-basierte Routenregistrierung** im Baum in die Quickfix-Liste, nach Pfad sortiert. Sofort, wie `plugins` und `bindings` | no |
| `:DocMap mermaid [tree\|deps]` | Modulbaum oder Require-Graph als **Mermaid**-Quelltext in einem Scratch-Buffer | no |
| `:DocMap pick` | Fuzzy-Suche ueber jedes Modul und jede Funktion der Karte, landet auf der Quellzeile | no |
| `:DocMap untested` | Funktionen, die **diese Maschine wirklich ausgefuehrt hat** und die kein Spec nennt, in die Quickfix-Liste, meistgelaufene zuerst — die eine nuetzliche Zelle aus Coverage × Telemetrie | no |

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

## `:DocMapAll` fast by default, `:DocMapAllFull` added (2026-08-15)

Checked, per a direct question, whether `:DocMapAll` actually ran every
project with LuaLS enrichment — it did, unconditionally, every time, since
`generate_one_headless.lua` hardcoded `luals = true`. That was never a
config choice on our side; it was the only option the bulk path had. Now
split the same way single-repo `:DocMap`/`:DocMap full` already are:
`:DocMapAll` (bare `:DocMap all`) is a fast scan, `:DocMapAllFull` (`:DocMap
all full`) opts every project into LuaLS enrichment, same as before this
shipped. `opts.generate_all.autoload` (below) is unaffected — it still
always enriches, since it is establishing a project's first map, not a
routine re-run. Nothing in `plugins/personal/init.lua` needed to change;
this is purely a runtime dispatch flag on the command, not a config option.
Upstream: `documentation.nvim`'s own `docs/COMMANDS.md`, `:DocMap all
[full]` section.

## `opts.generate_all` — `:DocMap all` / `:DocMapAll`, now the plugin's own (2026-08-14)

Cross-repo generation used to be entirely config-internal
(`lua/bindings/usrcmds/docmap_all/`, see the now-mostly-historical
[`DocMapAll.md`](./DocMapAll.md) for the full backstory) — a personal
usercmd reaching into `documentation.generate_all.run()` directly and
reimplementing the progress/notify glue by hand. Moved into
`documentation.nvim` itself: `opts.generate_all = { projects = {{root,
title}, ...}, autoload? }` is plain data our own spec's `opts` function
still builds (from `plugins.personal.export.projects()`, unchanged), but
`setup()` now registers `:DocMap all` and a standalone `:DocMapAll` alias
itself — only when `projects` is non-empty, so an unconfigured `setup()`
elsewhere gains neither command. The plugin's own source still never
reads a config's plugin list; the list only ever arrives as data through
`opts`, the same way `runtime-analysis.nvim`'s `opts.telemetry` already
works one repo over.

**`autoload = true` in our own spec.** New option, off by default upstream
— checks each configured project for an existing `module_map.json` once,
at `setup()` time, and generates (async, non-blocking) only the ones
missing. Turned on here because listing a plugin in `plugins/personal/
init.lua` is already the active signal its data is wanted. Consequence
worth remembering: the **next `:DocMap` of any kind, in any repo**, is
what actually triggers `setup()` for a `cmd`-lazy plugin — so the first
time `:DocMap`/`:DocBrowse`/`:DocMapAll` gets typed after this shipped,
autoload silently ran once in the background and may have written new
`docs/map/` directories into any of the ~30 personal plugins that did not
have one yet.

Cross-reference: `documentation.nvim`'s own `docs/COMMANDS.md` (`:DocMap
all` / `:DocMapAll` section) and `README.md`/`doc/documentation.txt` for
the published, plugin-owned version of this — this note is the "what did
*I* configure" layer on top, not the source of truth for how the feature
itself works.

## Global-surface collision check (2026-08-14, re-checked after `:DocMapAll` moved into the plugin)

The command names are this plugin's only global surface. Checked against every
`Usercmds/*.md` in this folder: **`DocMap`, `DocBrowse` and `DocMapAll` are
unique** — no other personal plugin registers any of the three or a
`Doc`-prefixed command.

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

## `opts.mdview` — live preview via mdview.nvim (2026-08-10)

Closed the roadmap's long-standing "mdview.nvim integration — never built"
item. `install()`-scoped, off by default, same posture as `opts.watch`/
`opts.callhierarchy`/`opts.diagnostics`: pushes a live Markdown rendering of
the in-memory IR into an already-running
[mdview.nvim](https://github.com/StefanBartl/mdview.nvim) session on every
`on_change`, so a browser tab previewing this root's `overview.md` stays in
sync with the tree as it changes instead of only with whatever `generate()`
last wrote to disk.

**No new command, no new binding.** The room a browser tab watches is just
`<root>/<out_dir>/overview.md`'s absolute path — the same file `generate()`
already writes — so the whole setup is: open that file, run mdview's own
`:MDViewStart`. Nothing here adds a usercmd or an autocmd of its own (no
entry in `Autocmds/documentation.nvim.md` — it subscribes to `handle.
on_change`, not a Neovim event).

**Soft dependency**, same `pcall`-guarded posture `opts.pdf`'s pdfport.nvim
already has: silent no-op if mdview.nvim is not installed, and a per-push
check (`mdview.core.state.is_attached()`/`get_server()`) skips instead of
queuing a doomed request when installed but no session is attached — not
turned on in our own `plugins/personal/init.lua` spec, so it stays inert
here unless explicitly enabled per-project.

Only Tier A of the original roadmap concept (a Markdown render shaped for
what mdview's `ammonia` sanitizer keeps — no Mermaid, no custom classes)
shipped; Tier B (a real diagram inside mdview's own tab) needs a protocol
change on mdview.nvim's own side and stays that repo's decision, not
documentation.nvim's.

## `:DocMap bindings` + `opts.bindings.wrappers` (2026-08-15)

Keymaps, user commands and autocmds extracted **from the source**, into the
quickfix list. The counterpart to `:DocMap plugins`: between them they cover
what a Neovim config actually consists of, which is mostly not functions —
`lua/bindings/mappings/*.lua` has no functions and no symbols and was
therefore invisible on the map until now.

**The wrapper declaration is mandatory here, not optional.** The `vim.*`
APIs are recognized with no configuration, but this config barely uses them
directly — measured across `lua/`: **233×** `map(...)` against **4×**
`vim.keymap.set`, and **72×** `usercmd.create` against **12×**
`vim.api.nvim_create_user_command`. Without the declaration `:DocMap
bindings` finds ~10 registrations instead of ~300 and looks broken. Set in
`lua/plugins/personal/init.lua`:

```lua
opts.bindings = {
  wrappers = {
    ["map"] = "keymap",
    ["usercmd.create"] = "usercmd",
    ["autocmd.create"] = "autocmd",
    ["nvim_create_autocmd"] = "autocmd",
    ["nvim_create_user_command"] = "usercmd",
  },
}
```

Three genuinely different aliasing shapes live in this tree, and the third
was a surprise: `map` (`vim.g.__map_helper`, same argument order as
`vim.keymap.set`, which is why it can reuse that layout), lib.nvim's
`usercmd.create`/`autocmd.create`, and `local nvim_create_autocmd =
api.nvim_create_autocmd` called bare in `lua/autocmds/terminals/init.lua`.
The plugin never traces an alias back to what it points at — the same line
it draws for `local M = {...}; return M` — so the *name as called* is what
gets declared.

`composer.verb` is deliberately **not** declared: it registers a whole verb
tree rather than one command, so its first argument is not a command name
and no built-in argument layout describes it. Those commands are therefore
absent from `:DocMap bindings` — a known, stated gap rather than a silent
mis-parse.

**Why the plugin does not just guess these names:** a bare `map(...)` is
also the most natural name for a list-mapping helper, so guessing would
silently report `vim.tbl_map` calls as keymaps. Reported counts here:
**228 keymaps, 66 user commands, 10 autocmds**.

**What it is for beyond an inventory:** rows sort by left-hand side so
collisions land next to each other. The same `<leader>x` bound in two files
is a real bug — whichever module loads last silently wins, and nothing else
surfaces it. Buffer-local bindings are excluded from collision counting,
since shadowing a global mapping in an ftplugin is intended.

**Relationship to `:Bindings check`** (`bindings_explorer`'s drift report,
see `bindings_explorer.md`): different questions, deliberately. `:DocMap
bindings` reads the **source** — what is written, including a binding in a
branch that never runs. `:Bindings check` compares the hand-written
BINDINGS tables against **live** `nvim_get_keymap`/`nvim_get_commands`.
Source vs. documented vs. live are three axes; the plan is for the source
axis to feed `drift.lua` as a third input, which is **not yet wired**.
