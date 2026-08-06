# markdown.nvim — User Commands Cheatsheet

`:Markdown` (global, 12 subcommands) plus 8 buffer-local commands
(`OpenWithSystemApplication`, `TableViewToggle`, `TableViewMarkdown`,
`TableViewBox`, `TableViewSelect`, `TableViewClose`, `TableViewOpenBrowser`,
`TableViewOpenBrowserNice`) rebuilt via `lib.nvim.usercmd.composer` (migrated
2026-07-19) — the plugin that originally motivated Phase 7's
`spec.buffer = true|bufnr` buffer-local support. **No syntax change**.

Source: `lua/markdown/bindings/usrcmds.lua`
Docs: `doc/markdown.nvim.txt`, `docs/installation.md`, `README.md`, `docs/health.md`

| Command | Scope | Grammar |
| --- | --- | --- |
| `:[range]Markdown {links\|toc\|refs\|table\|render\|preview\|mdview\|create\|scope\|headline_spacing\|gaps\|image} [args…]` | global | see `commands/*.lua` per-subcommand grammar |
| `:OpenWithSystemApplication` | buffer-local | open image/url/file under cursor |
| `:TableViewToggle\|Markdown\|Box [scope]` | buffer-local | toggle table preview (config/markdown/box style) |
| `:TableViewSelect` / `:TableViewClose` | buffer-local | select+preview / close persistent preview |
| `:TableViewOpenBrowser[Nice] [reopen]` | buffer-local | open table in browser (basic/nice HTML) |

## Notes

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
- **2026-07-23: added `:Markdown links sanitize [%|cwd|<file>]`** (branch
  `claude/markdown-links-sanitize-4a5e72`, off `main` — does **not** include
  the `gaps` subcommand noted below, which lives on the separate
  `claude/leader-toc-gap-checker-357f5b` branch; the two haven't been merged
  together yet, so `:Markdown` here still has its original 10 subcommands,
  not 11). Normalizes inline-link targets: backslashes -> forward slashes,
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
- **2026-07-21: added `gaps` subcommand** (heading-level gap checker).
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
