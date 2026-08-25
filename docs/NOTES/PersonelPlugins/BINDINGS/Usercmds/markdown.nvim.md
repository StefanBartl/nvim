# markdown.nvim — User Commands Cheatsheet

`:Markdown` (global, 13 subcommands) plus 25 buffer-local commands
(`OpenWithSystemApplication`, `MarkdownNvimUnderlineHeadings`,
`TableViewToggle`, `TableViewMarkdown`,
`TableViewBox`, `TableViewSelect`, `TableViewClose`, `TableViewOpenBrowser`,
`TableViewOpenBrowserNice`, plus 16 `:MDTable*` width-limited-wrapping
commands — see below) rebuilt via `lib.nvim.usercmd.composer` (migrated
2026-07-19) — the plugin that originally motivated Phase 7's
`spec.buffer = true|bufnr` buffer-local support. **No syntax change**.

Source: `lua/markdown/bindings/usrcmds.lua`
Docs: `doc/markdown.nvim.txt`, `docs/installation.md`, `README.md`, `docs/health.md`, `docs/table-wrap.md`

| Command | Scope | Grammar |
| --- | --- | --- |
| `:[range]Markdown {links\|toc\|refs\|table\|render\|preview\|mdview\|create\|scope\|list\|headline_spacing\|image\|export} [args…]` | global | see `commands/*.lua` per-subcommand grammar (list corrected 2026-08-09 — `gaps` no longer exists as a separate top-level subcommand, was stale; `export` is new; `list` added 2026-08-23) |
| `:OpenWithSystemApplication` | buffer-local | open image/url/file under cursor |
| `:MarkdownNvimUnderlineHeadings` | buffer-local | underline every ATX heading's text with `=` (Setext-style decoration, idempotent) |
| `:TableViewToggle\|Markdown\|Box [scope]` | buffer-local | toggle table preview (config/markdown/box style) |
| `:TableViewSelect` / `:TableViewClose` | buffer-local | select+preview / close persistent preview |
| `:TableViewOpenBrowser[Nice] [reopen]` | buffer-local | open table in browser (basic/nice HTML) |
| `:MDTableWrap` / `:MDTableUnwrap` | buffer-local | wrap/unwrap the table at cursor to/from the width plan |
| `:MDTableWrapVisual[!]` (range) / `:MDTableWrapVisible[!]` | buffer-local | wrap tables in selection / visible window; `!` unwraps first |
| `:MDTableReflowHeader` | buffer-local | reflow only header+separator, body untouched |
| `:MDTableFoldRow` / `:MDTableFoldAll` | buffer-local | fold continuation block(s) via `core/fold.lua`'s foldexpr |
| `:MDTableProfile {compact\|docs\|wide}` | buffer-local | load a named width-profile preset |
| `:MDTableCol {inc\|dec} [n]` | buffer-local | nudge column width under cursor, preserving row total |
| `:MDTableAlign {cycle\|left\|center\|right}` | buffer-local | cycle/set alignment of column under cursor |
| `:MDTableFlavor {github\|loose}` | buffer-local | strict GFM vs. loose separator style |
| `:MDTableLint` / `:MDTableFixMissingSeparator` | buffer-local | vim.diagnostic table lint / auto-fix missing separators |
| `:MDTableDebug` | buffer-local | print resolved column-width plan |
| `:MDTableToCSV [path]` / `:MDTableFromCSV [path]` | buffer-local | CSV export/import roundtrip |

## Notes

- **2026-08-23: added `:Markdown list [headings] [%|cwd|<file>]`** (13th
  subcommand, `commands/list.lua`, gated by new feature `list`). Collects
  document items in a picker and jumps to the chosen one — `headings` is
  the only option so far. Same scope vocabulary as `:Markdown links show`
  (`%` current buffer default, `cwd` every `*.md` below the cwd, or a file
  path). New reusable scanner `core/heading_scan.lua`
  (`from_lines`/`from_buffer`/`from_file`), the heading-side counterpart to
  `core/link_scan.lua`; skips YAML frontmatter and fenced code blocks so
  results match what `:Markdown toc` would generate. Picking an entry opens
  its file first if it isn't the current buffer, then jumps (via `m'`, so
  undoable with `<C-o>`). New `config.list.picker` option, same backend
  vocabulary/fallback as `links.picker`. Had to add `list` to
  `SUBCOMMAND_NAMES` in `bindings/usrcmds.lua` as well as the dispatch table
  in `commands/init.lua` — same "two places" trap `gaps` hit in 2026-07-21
  below: `commands/init.lua`'s dispatch table alone doesn't register the
  live `:Markdown` route.
  **Known gap found while testing, not fixed here**: `:Markdown list
  headings <Tab>` doesn't complete the scope argument (`%`/`cwd`) — the
  `MARKDOWN_SUBARG` composer type reconstructs a synthetic one-argument
  cmdline instead of passing the real one through, and each route only
  declares one arg spec. Pre-existing, also affects `:Markdown links show`
  and `:Markdown table format`'s second argument; not new here. Flagged as
  a separate background task in the markdown.nvim repo
  (`task_46386019`, "Fix second-arg completion for :Markdown subcommands").
- **2026-08-09: added `:Markdown export pdf`** (new subcommand,
  `commands/export.lua`) — thin delegator to pdfport.nvim's `create()`
  (soft dep, `pcall`-guarded), exactly the same pattern as `:Markdown image`
  for images.nvim: `pdfport.can_create("markdown")` gates whether the
  subcommand does anything; an unmodified buffer with a file on disk exports
  that file directly, an unsaved/new buffer exports the live buffer content
  instead. Gated by the new `export` feature name (`FEATURES` in
  `config/init.lua`). From pdfport.nvim's own `docs/ROADMAP/PDF_CREATE.md`
  (P2, caller wiring) — the third and last of its three callers
  (`filetree.nvim`/`images.nvim`/`markdown.nvim`) to get wired.
- **2026-08-09: added the `:MDTable*` width-limited table-wrapping family**
  (16 new buffer-local commands, feature `table_wrap`, default on) — the
  Kernfeature from `docs/ROADMAP/personal/markdown.nvim.md`'s
  `md_tablewrap` analysis. New modules: `lua/markdown/core/table_wrap.lua`
  (plan/wrap_cell/render/unwrap_rows/find_issues/fix_missing_separators/
  to_csv/from_csv/on-hooks — builds on `table_fmt.lua`'s now-exported
  parse/format primitives rather than duplicating them) and
  `lua/markdown/commands/mdtable.lua` (opt resolution: config ->
  `wrap_profiles[b:mdtable_profile]` -> per-table `<!-- mdwrap: ... -->`
  directive -> explicit overrides; cursor/logical-cell restore after
  reflow; `↳` continuation-row gutter signs via extmarks, virtual only —
  the buffer text stays clean GFM). `core/fold.lua`'s existing
  heading-foldexpr got a small extension (buffer-local
  `vim.b.mdtable_fold_continuations`) rather than a competing manual-fold
  pass, so `:MDTableFoldRow`/`FoldAll` nest continuation blocks one level
  under their heading section. Debounced `VimResized`/`WinResized` reflow
  and a `BufWritePre` selective-reflow (only tables whose text actually
  changed since last save) are wired in `bindings/autocmds.lua`, both
  opt-in via `config.table.wrap.auto_resize`/`.selective_reflow` (default
  off). Two real bugs caught by headless tests during implementation: (1)
  a single unbreakable token wider than the planned column width overflowed
  the cell but the separator line still used the smaller planned width,
  misaligning the column — fixed with a two-pass render (wrap everything
  first, then compute the *effective* width per column from the actual
  wrapped output); (2) the `↳` gutter-sign extmark silently failed to place
  because `marker:sub(1,2)` byte-sliced the multi-byte UTF-8 arrow mid-
  codepoint — fixed with `vim.fn.strcharpart` (character-, not byte-,
  based). Vim user-command names can't contain `+`/`-`, so the roadmap's
  `:MDTableCol+`/`:MDTableCol-` became `:MDTableCol inc|dec [n]`. Unwrap
  detects continuation rows structurally (≤1 non-empty cell, directly after
  another row of the same table) since no marker is written to the buffer
  — documented caveat: a genuine one-cell data row right after another row
  is indistinguishable and gets merged too. Details: `docs/table-wrap.md`
  in the markdown.nvim repo.
- **2026-08-09: added `:MarkdownNvimUnderlineHeadings`** (buffer-local, off
  `docs/ROADMAP/personal/markdown.nvim.md`'s "Randnotiz" item — an old
  NvChad snippet: under every ATX heading, insert/correct a line of `=`
  matching the heading text's length. Purely visual Setext-style decoration
  (the `#` marker stays; applies at every level, not just H1/H2, unlike real
  Setext). Idempotent — a correctly-sized underline is left alone, a
  wrongly-sized one corrected, fenced-code interiors skipped. New module
  `lua/markdown/core/underline_headings.lua` (`apply`/`apply_range`).
  New `config.underline_headings.char` (default `"="`); new gateable feature
  name `underline_headings` (`features.disable = { "underline_headings" }`
  turns the command off). Registered in `bindings/usrcmds.lua` alongside
  `OpenWithSystemApplication`, gated by the new feature flag.
- **2026-08-07: added `:Markdown image [paste|screenshot]`** (12th
  subcommand, `commands/image.lua`) — thin delegator to images.nvim's
  `:Image paste`/`:Image screenshot` (soft dep, pcall-guarded), for
  discoverability from `:Markdown <Tab>` rather than a reimplementation.
  Also gave `:Markdown links show` a live image preview: when the scanned
  links include an image and both `snacks.picker` + images.nvim are
  installed, it now routes through a dedicated snacks picker
  (`images.browse.draw_in_window()` for the per-item preview) instead of
  the generic `links.picker`-selected backend, none of which support a
  cross-backend live preview — same constraint images.nvim's own
  `docs/ROADMAP/CROSS-PLUGIN.md` documents for `pickers.nvim`. Falls back
  to the unchanged picker without both deps or with no image link.
  **Side fix while there**: `mi`'s existing in-Neovim image preview
  (`markdown/util/image_preview.lua`) used only snacks.nvim/image.nvim as
  providers — both Kitty-APC-only, which native Windows Neovim in WezTerm
  never draws (same root cause as images.nvim's whole reason for existing,
  see its README's "Why not snacks.image or image.nvim"). images.nvim is
  now the preferred provider there too, via the same `draw_in_window()`
  helper; snacks/image.nvim stay as fallback for Kitty-capable terminals.
  From images.nvim's `docs/ROADMAP/CROSS-PLUGIN.md` (markdown.nvim entry).
- **2026-07-26: worked through `docs/ROADMAP.md` end to end** (branch
  `claude/markdown-nvim-roadmap-bindings-194495`, merged/pushed straight to
  `main` — does **not** include the `sanitize`/`gaps` work below, which are
  still on their own unmerged branches). No new *top-level* `:Markdown`
  subcommands (still the original 10); two new nested ones:
  - **`:Markdown links check`** — flags dead relative-file links and
    duplicate heading titles in the current buffer via `vim.diagnostic`
    (namespace `markdown_links`; new module `core/link_diagnostics.lua`,
    reusing `link_scan.lua` + the anchor-slug logic in the new
    `core/slug.lua`). New `config.links.diagnostics.mode` (`"off"` default |
    `"save"` for an automatic `BufWritePost` rerun — see the Autocmds
    cheatsheet, `MarkdownNvimLinkDiagnostics`).
  - **`:Markdown table import [clipboard|PATH]`** — parses an HTML
    `<table>` into a GFM table, round-tripping with the existing TableView
    HTML export. New `table_fmt.parse_html_table`/`rows_to_gfm`.
  Also new, not user-command-facing but config-relevant: `links.picker` gained
  `"telescope"`/`"fzf"` backends in `util/picker.lua` (soft deps, fall back to
  `vim.ui.select` with a warning); `config.toc` (header/marker/min_level/
  max_level/anchor_style/anchor_separator) now drives `:Markdown toc`, which
  also accepts `min=`/`max=`/`marker=` per-call args; `config.table`
  (header_align/entry_align/col_overrides) now supplies `:Markdown table
  format` defaults; `blockquote_hl.marker_fg`/`text_fg` are unset by default
  and derived from the active colorscheme instead of a hard-coded hex.
- **2026-07-23: added `:Markdown links sanitize [%|cwd|<file>]`**
  (**on `main` since 2026-08-25**; it sat on `claude/markdown-links-sanitize-4a5e72`
  for a month, alongside the `gaps` subcommand noted below on its own branch —
  both landed together in that pass, so `:Markdown` now carries all 14
  subcommands, `links sanitize` and `gaps` included). Normalizes inline-link targets: backslashes -> forward slashes,
  bare relative paths get a `./` prefix (`[t](doc.md)` ->
  `[t](./doc.md)`; `[t](.\doc\file.md)` -> `[t](./doc/file.md)`). Leaves
  URLs, `mailto:`/drive-letter scheme targets, `#anchor`-only links,
  absolute paths, and `~`-relative paths alone. New module
  `lua/markdown/core/link_sanitize.lua` (`sanitize_target`/`sanitize_line`/
  `sanitize_lines`/`buffer`/`file`/`path`), reusing `link_scan.lua`'s
  fenced-code-block skip so an example inside a ``` block is never touched.
  Wired into `commands/links.lua`'s existing `show|create` subcommand router
  (same `%|cwd|<file>` scope convention as `links show`) — no changes needed
  to `commands/init.lua` or `usrcmds.lua`'s `SUBCOMMAND_NAMES` since
  `sanitize` nests *under* the already-registered `links` route rather than
  adding a new top-level one (unlike `gaps`, which needed its own top-level
  entry in both places).
  Also **runs automatically on `BufWritePre`** (new `MarkdownNvimLinksSanitize`
  augroup in `bindings/autocmds.lua`, see the Autocmds cheatsheet), gated by
  the new `config.links.sanitize_on_save` option (default `true`) — same
  independent-opt-in-by-default pattern as `config.refs.mode = "save"`.
- **2026-07-21: added `gaps` subcommand** (heading-level gap checker; **on
  `main` since 2026-08-25**).
  `<leader>toc` / `:Markdown toc` now also detect skipped heading levels
  (e.g. `#` -> `###` with no `##` in between) after each refresh, notify,
  and offer (`vim.fn.confirm`) to renumber the offending headings on the
  spot. Toggle with the new `check_heading_gaps` config option (default
  `true`); per-call override via `:Markdown toc --check-gaps` /
  `--no-check-gaps`. Explicit on-demand form: `:Markdown gaps`. New module
  `lua/markdown/core/heading_gaps.lua` (`find_gaps`/`fix_gaps`/`check`).
  Gated by the existing `toc` feature (not its own feature name), same
  pattern as `ensure_headline_spacing` — added to `SUBCOMMAND_FEATURES` in
  both `commands/init.lua` and the mirrored `enabled()` gate in
  `bindings/usrcmds.lua` (`gaps -> {"toc"}`), and to `SUBCOMMAND_NAMES` in
  `usrcmds.lua` (now 11 entries) so the real `:Markdown` composer
  registration path actually creates the route — easy to miss since
  `commands/init.lua`'s own dispatch table alone isn't what wires the
  live `:Markdown` command.

- **Found and fixed a real, already-shipped composer bug while migrating
  this repo**: `parse.dispatch`'s bare-invocation branch (`#fargs == 0`)
  unconditionally used `spec.default` or the auto-usage listing,
  *completely bypassing* a registered `path = {}` root route — even
  though `tree.walk(root, {})` resolves to that exact route correctly.
  Every one of markdown.nvim's buffer-local commands here is either
  always invoked bare (`OpenWithSystemApplication`, `TableViewSelect`,
  `TableViewClose` take no arguments at all) or usually invoked bare
  (`TableViewToggle`'s only arg is optional) — a
  `session_features_spec.lua` regression test caught it immediately
  (config-style view toggle silently no-op'd instead of rendering).
  **This was a real, already-shipped regression, not specific to this
  repo**: verified it also broke `pdfport.nvim`'s bare `:PdfPort` (the
  plugin's primary documented use case — the interactive mode picker
  never opened) and `diff.nvim`'s `:DiffClear`/`:DiffOrig`/`:DiffExit`
  (zero-arg commands that never ran) and bare `:Diff`, and `language.nvim`
  (externally migrated)'s bare `:Spellcheck`. Fixed in `lib.nvim` itself
  (`composer/parse.lua`, commit in the `lib.nvim` repo) with 3 new
  regression tests — no code changes needed in any of the affected repos,
  since the fix lives entirely in the shared dependency. Verified directly
  against `pdfport.nvim` and `diff.nvim` after the fix.
- **`:Markdown`'s 10 subcommands**: dispatch bypasses composer's own bound
  `ctx.args` and calls the ORIGINAL, unmodified
  `markdown.commands.execute(ctx.raw.fargs, {range,...})` directly —
  `ctx.raw.fargs` already includes the subcommand token itself, the exact
  shape `M.execute` expects (it does its own `table.remove(argv,1)`).
  First-arg `<Tab>` completion reuses `M.complete()` *itself* (not a
  reimplementation) by synthesizing the `"Markdown {subcmd} {arg_lead}"`
  cmdline string its own parsing expects — avoids duplicating the 8
  per-subcommand completion delegates already defined in
  `commands/init.lua`.
- **Feature-gating snapshotted at registration time**: matches
  `create_markdown_command()`'s own pre-existing idempotency guard
  (`:Markdown` is only ever registered once per session, on the first
  buffer that triggers it — a feature flag flipped after that point was
  never live-checked either, even before this migration). Same accepted
  tradeoff as debugging.nvim's disabled categories: a disabled subcommand
  typed by name gets composer's generic "unknown subcommand" instead of
  the specific "feature disabled" message.
- **8 buffer-local commands via `spec.buffer = bufnr`** — the case Phase 7
  was built for. `TableViewToggle`/`Markdown`/`Box` share one
  `make_view_handler(style)` factory (unchanged) and one
  `MARKDOWN_TABLEVIEW_SCOPE` composer type (`%`/`cwd`/file completion,
  matching the original `complete_scope` exactly). `TableViewOpenBrowser`/
  `OpenBrowserNice`'s `reopen` arg uses `values = {"reopen"}` (a hint, not
  an enum — an unrecognized value still just means "don't force a new
  tab", matching the original's `:lower() == "reopen"` check exactly).
- **CI was already broken before this migration** (unrelated, found while
  fixing it for the lib.nvim-sibling-checkout reason): `.github/workflows/
  ci.yml` and `TESTS/run.lua`'s own header comment both referenced
  `docs/TESTS/run.lua`, but the actual test directory is `TESTS/` at the
  repo root (`docs/TESTS/` doesn't exist) — a stale path left over from an
  apparent directory reorganization. Fixed both, and added the lib.nvim
  sibling checkout the test job needs (the run.lua script itself already
  had `$LIB_NVIM_PATH` support, just unused by CI).
- **One remaining test failure is pre-existing and unrelated** —
  `session_features_spec.lua`'s `platform.open: launched via vim.system`
  check fails identically on unmodified `main` (confirmed via `git
  stash`), nothing to do with this migration. Flagged as a separate
  background task.
- **README/vimdoc "self-contained... no external tools" claims were
  already false before this migration** (`core/table_mode.lua` already
  hard-required `lib.nvim.debounce.buffer`) — corrected throughout
  (README, `docs/installation.md`, `doc/markdown.nvim.txt`, `health.lua`,
  `docs/health.md`) to note lib.nvim as required.
