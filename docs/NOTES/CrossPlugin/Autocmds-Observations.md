# Autocmds — cross-plugin observations (untriaged)

Hand-written cross-plugin insights extracted from the three "Sammelseiten"
(`autocmds-by-event.md`, `autocmds-by-filetype.md`, `autocmds-by-plugin.md`)
that lived under `docs/NOTES/PersonelPlugins/BINDINGS/` before `BND-05`
removed that tree. `:Bindings browse` already replaces the raw table rows
those three pages carried — this file exists only for the prose that a live
picker cannot reproduce: authored observations about how two or more
plugins' autocmds interact, found by reading rather than by querying.

**Not yet triaged.** Each entry below stays here until a decision is made on
whether it is worth promoting into the plugin(s) it concerns, or into a
WKDBooks/`wkdbook-myplugins` note, or whether it can simply be dropped as
now-stale. Every entry names its source page and the plugins it concerns so
that decision can be made without re-deriving the finding.

---

## The one real ordering dependency: `BufWritePre`

**Source:** `autocmds-by-event.md`, `## BufWritePre` section.
**Concerns:** cascade.nvim, fileops.nvim, markdown.nvim, language.nvim.

Four plugins hook `BufWritePre` on what can be the same buffer (any `.md`
file with cascade's list-renumber, fileops' auto-mkdir, markdown.nvim's
refs-sync/links-sanitize, and language.nvim's `block_write_on_error` all
enabled). Neovim runs `BufWritePre` autocmds in **registration order**
(roughly: plugin setup-call order in this config). If `language.nvim`'s
`block_write_on_error` is ever turned on and the buffer has spelling errors,
whichever of the other three registered *after* it never runs for that
write. Low-risk today since none of the other three depend on one another's
side effects, but it is the one spot in this config where write-time plugin
order actually matters — `fileops.nvim`'s `auto_mkdir` in particular would be
worth keeping registered early (before anything that could abort a write),
since a missing parent directory should probably still get created even if
the write is later aborted for spelling.

## Markdown buffers: three independently debounced re-render cycles

**Source:** `autocmds-by-filetype.md`, `## Markdown-family buffers` section.
**Concerns:** color_my_ascii.nvim, markdown.nvim, language.nvim.

On a markdown file with color_my_ascii's ASCII-art highlighting,
markdown.nvim's full feature set, and language.nvim's live spell all active,
a single keystroke triggers three independently debounced re-render/re-scan
cycles. Each is cheap and debounced on its own; if markdown editing ever
feels less snappy than plain text editing, this is where to look first — not
because anything is broken, just because there is more concurrently active
tooling on this filetype than any other. Not overlapping in practice: the
two plugins' visual regions (ASCII blocks vs. headings/tables/folds/links)
don't touch the same parts of a typical markdown file.

## Tree buffers: intentional layering, not overlap

**Source:** `autocmds-by-filetype.md`, `## Tree buffers` section.
**Concerns:** filetree.nvim, pdfport.nvim.

filetree.nvim provides the tree itself; pdfport.nvim adds 4 PDF-opening
keymaps on top of whichever tree/file-manager buffer is open (`NvimTree`,
`oil`, `netrw`). No conflict — pdfport's keys don't appear in filetree's own
catalog and both register independent augroups. Worth remembering when
debugging "why does this key do X in the tree": check both plugins'
`FileType` autocmds for that buffer's filetype, not just filetree.nvim's —
pdfport's 4 keys are easy to forget since they live in a different repo.

## Global-by-convenience vs. global-by-design

**Source:** `autocmds-by-filetype.md`, `## Global / no-pattern` section.
**Concerns:** hover.nvim, spotlight.nvim, reposcope.nvim, color_my_ascii.nvim,
markdown.nvim, fileops.nvim, cascade.nvim, language.nvim, filetree.nvim.

Most "technically global registration" autocmds in this config are actually
self-filtering inside the callback (reposcope's `QuitPre` checks the buffer
name, color_my_ascii's cache-invalidation ones are cheap regardless) — a
normal, safe pattern. Two plugins are global **by design**, not convenience,
and are worth remembering as the two real exceptions:

- **hover.nvim**: `HoverEnable`'s pattern really is `*` by default — a path
  written as plain text is a target in any buffer. Filtered by buffer *kind*
  (non-empty `'buftype'` is never attached to) rather than filetype.
- **spotlight.nvim**: `spotlight_windows` genuinely has to reach every
  window, because `matchadd()` is window-local and a `:split` would
  otherwise show the same buffer with no highlights. Filtered by window
  *kind* (floating windows skipped, quickfix window is not — seeing the
  colors there is the point of `:Spotlight qf`).

## `ColorScheme`: eight independent re-apply routines

**Source:** `autocmds-by-event.md`, `## ColorScheme` section.
**Concerns:** color_my_ascii.nvim (×2), markdown.nvim (×2), filetree.nvim
(×2, opt-in), lib.nvim, spotlight.nvim.

All idempotent, no shared state — just what it costs to switch colorschemes
with this many plugins installed. Not a correctness issue, only relevant if
a colorscheme switch ever feels slow: it's plausible several of these plus
the colorscheme's own setup are what is being felt, not any single one.

## `WinEnter`/`WinClosed`: the explorer singleton is this config's own code

**Source:** `autocmds-by-event.md`, `## WinEnter / WinLeave` section (listed
there as `autocmds.explorer-singleton`, which is **not a plugin** — it is
this config's own `lua/autocmds/explorer-singleton.lua`).
**Concerns:** neo-tree (via filetree.nvim), snacks.picker's `explorer` source
(via pickers.nvim).

neo-tree (`<A-l>`) and snacks.picker's `explorer` source (`<leader>.`) have
zero awareness of each other by default, so opening one would leave the
other open alongside it. This config's own `WkdExplorerSingleton` augroup
closes whichever is the *other* one when either opens (`WinEnter`), and
reopens the just-displaced one exactly once (`WinClosed`). Both handlers
defer a tick before reading current win/buf, since a newly created window
can still briefly report the previous window's buffer at the instant
`WinEnter` fires. This is genuinely this config's own mechanism, already
documented in the new root `docs/BINDINGS.md`'s Autocmds section — restated
here only because the source Sammelseite filed it under the same
cross-plugin-interaction heading as the plugin findings above.

## `BufWritePost`: no overlap concerns

**Source:** `autocmds-by-event.md`, `## BufWritePost` section.
**Concerns:** insights.nvim, gopath.nvim, filetree.nvim, markdown.nvim,
mdview.nvim, color_my_ascii.nvim, lib.nvim.

Recorded as a negative finding, not a gap: these all touch either the tree
buffer specifically (filetree.nvim) or distinct, unrelated concerns. No
migration candidate here — kept only so a future audit does not re-derive
"nothing to see" from scratch.
