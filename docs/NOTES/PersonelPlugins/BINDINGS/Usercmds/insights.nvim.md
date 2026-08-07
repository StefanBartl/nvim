# insights.nvim — User Commands Cheatsheet

One command tree, built via `lib.nvim.usercmd.composer` (migrated
2026-07-20). Replaced the hand-rolled `nvim_create_user_command` + custom
`complete()` pair — the 12 handler functions in `bindings/usrcmds.lua` are
byte-for-byte unchanged, only their registration changed.

Source: `lua/insights/bindings/usrcmds.lua`
Docs: `docs/commands.md`, `docs/BINDINGS.md`, `doc/insights.txt`

| Command | Args | Effect |
| --- | --- | --- |
| `:Insights symbols` | `[cwd\|buffer] [functions\|tables\|strings] [telescope\|fzf\|scratch] [rebuild]` | Symbol index / picker (tokens in any order) |
| `:Insights metrics` | `[--flags...] [dir]` | Lua code metrics report |
| `:Insights tree` \| `count` \| `clipboard` \| `fileinfo` | — | File tree / count / clipboard / fs.stat float |
| `:Insights cache {build\|info\|clear}` | — | Symbol index cache |
| `:Insights compress` | `[path] [outdir]` | Archive a directory |
| `:Insights imports` | `[filter/lang...] [telescope\|fzf\|graph]` | Import/require usage report across Lua, Python, JS/TS, Go, Rust, C/C++ — filterable by group, module prefix, or language; optional picker view; `graph` renders a Graphviz dependency PNG via images.nvim |
| `:Insights imports reverse` | `<module>` | Every file that imports `<module>` |
| `:Insights imports unused` | `[filter/lang...]` | Bound import names never referenced again in their file |
| `:Insights conflicts` \| `unimported` | — | Quickfix conflicts / unimported-component check |
| `:Insights devserver` | `[list\|kill]` | List/kill tracked dev servers (bare = list) |

## Notes

- **2026-08-07 — `imports graph` added**: new `"graph"` UI token on the base
  `imports` route (`lua/insights/imports/graph.lua`), same filter args as
  the text report. `insights.imports`'s entries were already a full edge
  list (`filename` imports `module`) — the graph is `M.build_dot` turning
  that into a Graphviz `digraph` (files filled blue, external modules
  dashed grey and off by default — `imports.graph.include_external`), then
  `dot -Tpng` (or whichever `imports.graph.layout` names) and
  `images.nvim`'s `show()` (soft dep — without it, just reports the PNG
  path). Needs Graphviz on PATH, reported as a clear error rather than a
  silent no-op when missing — matches images.nvim's own ImageMagick stance.
  From images.nvim's `docs/ROADMAP/CROSS-PLUGIN.md` (insights.nvim entry).
  Deliberately scoped to the dependency graph only, the one place in
  insights.nvim where the data is already graph-shaped — the roadmap's
  wider "call trees, symbol distribution" idea would need new analysis
  this plugin doesn't have (symbols.lua is a flat, uncorrelated list), not
  just a new view over data that already exists.
- **2026-07-25 — imports went multi-language**: `insights/imports/init.lua` now
  dispatches across a `langs/` registry (Lua, Python, JS/TS, Go, Rust, C/C++;
  Lua keeps its Tree-sitter/ripgrep dual backend, the other five are
  regex/text scanners). Two new composer routes were added as literal
  children of `imports` — `{"imports","reverse"}` (takes one required
  `STRING` module arg) and `{"imports","unused"}` (repeated filter args,
  same as the base route) — coexisting with the base `imports` route's
  6 repeated `INSIGHTS_IMPORT_GROUP` slots exactly like `devserver`'s
  `list`/`kill` children already did: composer's tree-walk (`tree.lua`
  `M.walk`) greedily consumes literal children before falling back to
  parsing remaining tokens as the parent route's positional args, so a
  group/filter literally named `reverse` or `unused` would be shadowed
  (accepted, same tradeoff `devserver` already has for `list`/`kill`). The
  base route also grew an optional trailing `telescope`/`fzf` token (picker
  view over the occurrence list, reusing the existing generic
  `ui/telescope.lua`/`ui/fzf.lua` pickers via a `{filename,lnum,name,
  func_type}` field mapping — no picker code duplicated).
- **Order-independent and variadic grammars, not a fixed tree**: `symbols`
  (scope/type/ui/`rebuild` in any order), `metrics` (flags in any order +
  one directory), and `imports` (a variadic list of filter names) don't map
  onto composer's position-means-something route model directly. Solved by
  declaring N optional positional slots of the *same* custom type per route
  (`repeated_args("INSIGHTS_SYMBOLS_TOKEN", 4)`, 6 for imports) so every position
  offers the identical candidate set — then `run` merges `ctx.pos` +
  `ctx.rest` back into one flat token list and forwards it, unmodified, into
  the original `handle_symbols`/`handle_imports`, whose own order-independent
  parsing loops do the real work exactly as before. Verified via a headless
  check that `:Insights symbols buffer` and `:Insights symbols
  rebuild buffer` produce the same `scope="buffer"` with only `rebuild`
  differing.
- **`metrics` needed real `Route.flags`, not the same trick**: composer's
  completion engine intercepts any arg_lead starting with `--`
  *unconditionally*, before a route's own `args` completers ever run
  (confirmed by testing — a repeated-custom-type route, like symbols/imports
  above, silently returned no completions for `--<Tab>`, the single most
  common thing to type after `:Insights metrics `). Fixed by declaring
  real `Route.flags` (one `FlagSpec` per literal `--flag`) purely so
  composer's flag completion fires — dispatch still goes through the
  original, unchanged `parse_metrics_args`: `reconstruct_metrics_tokens()`
  re-derives the `"--flag"`/`"--flag=value"` string tokens from `ctx.flags`/
  `ctx.pos` first, so `parse_metrics_args`'s semantics (`--lua-only` setting
  *two* different `opts` fields) never had to be re-expressed in the route
  declaration. Verified: `--lua-only --no-top` → `{analyze_lua=true,
  analyze_misc=false, show_top_lists=false}`, `--topn=5 --colwidth=20 /tmp` →
  `{top_n=5, col_width=20, root="/tmp"}` — identical to pre-migration output.
- **Accepted behavior tightening**: an undeclared `metrics` flag (e.g.
  `--bogus-flag`) is now a hard composer error instead of the original's
  silent no-op ignore — composer's flags are fail-loud by design. Everything
  else (`cache`/`devserver`'s unknown-subcommand branches, the top-level
  "unknown subcommand" case) already used composer's own tree-walk error
  reporting rather than the old hand-written one-liners, matching every
  other migrated repo's accepted tradeoff.
- **`compress`'s path/outdir stay soft, deliberately not `DIR`**: composer's
  built-in `DIR` type hard-validates the token is an *existing* directory —
  wrong for `outdir`, which is routinely a path that doesn't exist yet
  (`compress` creates it). Registered `INSIGHTS_DIR_SOFT` instead (soft validate,
  dir-only completion) for both slots, matching the original's actual
  behavior (neither slot was ever validated at parse time either).
- **`devserver`'s bare form kept**: `:Insights devserver` (no
  subcommand) still defaults to `list`, via a route directly on the
  `devserver` node itself (`path = {"devserver"}`) *alongside* its two
  literal children (`{"devserver","list"}`, `{"devserver","kill"}`) — a node
  can carry both a terminal route and children in the same composer tree.
- **Minor completion regression, accepted**: `metrics`'s `--flag` names now
  only appear in `<Tab>` completion once you've actually typed the leading
  `--` (composer's flag-completion branch only fires then) — the original
  `metrics_complete()` offered flags and directory names together at every
  position regardless of what was typed. A one-time "type `--` first" UX
  change, not a functional loss.
- **Minor completion fix, not a regression**: the old `symbols`/`cache`/
  `devserver` completers never filtered their candidate lists by what was
  already typed (only `metrics`/`imports` did) — composer's built-in
  filtering now applies uniformly everywhere, an inconsistency fixed rather
  than carried forward.
- **No CI to fix**: this repo has no `.github/workflows/`, nothing to gate on
  a `lib.nvim` sibling checkout.
- **No pre-existing code bugs found** while verifying. One pre-existing
  **doc** gap fixed in passing (in scope for the required doc sweep, not
  spun off): `docs/BINDINGS.md`'s user-command table was missing
  `conflicts`/`unimported`/`devserver` entirely, and its "Autocmds: None"
  section flatly contradicted `bindings/autocmds.lua`, which registers three
  gated autocmds (`VimEnter`/`BufWritePost`/`TermOpen`+`TermRequest`+
  `VimLeavePre`). Both corrected.
