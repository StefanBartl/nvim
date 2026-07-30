# Autocmds — by filetype / buffer scope

Same data again, re-grouped by *what kind of buffer* each autocmd actually
fires on — this is the axis where real cross-plugin interaction (not just
"many plugins happen to use the same event name") would show up, since it's
about multiple plugins touching the *same buffer* at the *same time*.

See also: [by plugin](autocmds-by-plugin.md), [by event](autocmds-by-event.md).

## Markdown-family buffers (`markdown`/`mdx`/`md`)

Two plugins hook `FileType` directly on markdown buffers, and a third
reacts near it:

| Plugin | Augroup(s) | What it sets up |
| --- | --- | --- |
| color_my_ascii.nvim | `ColorMyAscii` | ASCII-art highlighting + `:Fence` command family |
| markdown.nvim | `MarkdownNvimTableView`, `MarkdownNvimRefs`, `MarkdownNvimKeymaps`, `MarkdownNvimUserCommands`, `MarkdownNvimFold`, `MarkdownNvimHL` | TableView, refs/anchors, default keymaps, commands, fold options, blockquote highlight |

Plus, once a markdown buffer exists and stays open, all of the following
also run on it depending on what's enabled: `MarkdownNvimRefs`'s
`BufWritePre`/`TextChanged` sync, `color_my_ascii`'s `TextChanged`
re-highlight and `BufDelete` cleanup, `MarkdownNvimTableMode_<bufnr>`'s
`InsertLeave`/`TextChanged` realign (only while table mode is toggled on),
and — if you've turned it on — `language.nvim`'s live spell rescan.

**Not a bug, but worth knowing**: on a markdown file with color_my_ascii's
highlighting, markdown.nvim's full feature set, and language.nvim's live
spell all active, a single keystroke can trigger three independently
debounced re-render/re-scan cycles (color_my_ascii's ASCII highlight,
markdown.nvim's fold/HL bits it needs to keep current, and the spell
rescan). Each is cheap and debounced on its own, but if markdown editing
ever feels less snappy than plain text editing, this is where to look first
— not because anything's broken, just because there's more concurrently
active tooling on this filetype than any other.

**Not overlapping in practice**: color_my_ascii's job (ASCII-art blocks)
and markdown.nvim's job (headings/tables/folds/links) don't touch the same
visual regions of a typical markdown file, so there's no actual rendering
conflict — just concurrent independent work.

## Tree buffers (`neo-tree` / `NvimTree` / `oil` / `netrw`)

This is *intentional layering*, not incidental overlap — filetree.nvim
provides the tree itself, pdfport.nvim adds PDF-opening keymaps on top of
whichever tree/file-manager buffer you're in:

| Plugin | Pattern(s) | Role |
| --- | --- | --- |
| filetree.nvim | `neo-tree`/`NvimTree` (or adapter's filetypes) | The tree itself — 1 `FileType` autocmd (`tree_attach`) dispatching to ~28 features' keymap setup (nav, ui, fileops, search, paths, org, git, lsp, infra), as of 2026-07-26; was ~35 separate `FileType` autocmds before |
| pdfport.nvim | `NvimTree`, `oil`, `netrw` | Adds 4 PDF-related keymaps to whichever tree/file-manager buffer opens |

No conflict: pdfport.nvim's keymaps (`<leader>po/pt/ps/pi`) don't appear
anywhere in filetree.nvim's own catalog, and both plugins register
independent augroups — they compose cleanly. The only thing worth knowing:
if you're ever debugging "why does this key do X in the tree," check both
plugins' `FileType` autocmds for that buffer's filetype, not just
filetree.nvim's — pdfport.nvim's 4 keys are easy to forget about since
they're buried in a different repo.

## Debug/log/output buffers (`messages` / `noice`)

| Plugin | Pattern | Role |
| --- | --- | --- |
| debugging.nvim | `messages`, `noice` | Registers `q`/`<Esc>` close keymaps, auto-refreshes tagged windows |

No other plugin's autocmds target these filetypes — clean, single-owner.

## Global / no-pattern (fires on every buffer or window regardless of filetype)

Autocmds with no `pattern` restriction at all (matched, if at all, inside
the callback body instead): reposcope.nvim's `QuitPre` (checks
`reposcope://` buffer name in the callback), color_my_ascii.nvim's
`ColorScheme`/`BufDelete`/`BufWipeout` cache-invalidation ones,
markdown.nvim's `ColorScheme` ones, fileops.nvim's `BufWinEnter`/
`BufWinLeave` conflict-marker pair, cascade.nvim's `BufWritePre` (filtered
inside the callback to `lists.filetypes`), language.nvim's `BufDelete`,
filetree.nvim's `FiletreeBufferCache` `BufDelete`. These are all
"technically global registration, practically self-filtering inside the
callback" — a normal, safe pattern (cheaper than a real Vim pattern glob in
some cases, since the callback can consult live plugin state the pattern
syntax can't express), not a performance concern at this scale.

spotlight.nvim belongs here too, and is the one case that is global by
*design* rather than by convenience: its `spotlight_windows` group
(`WinNew`/`BufWinEnter`/`TabNewEntered`/`WinClosed`) genuinely has to reach
every window, because `matchadd()` is window-local and a `:split` would
otherwise show the same buffer with no highlights. Filtering is by window
*kind*, not by filetype: floating windows are skipped (transient UI), the
quickfix window is not (seeing the colors there is the point of
`:Spotlight qf`). Its `spotlight_highlights` group (`ColorScheme`,
`OptionSet background`) is likewise global — highlight groups are not
filetype-scoped in the first place.

## Buffer-local to a plugin's own special/scratch buffer

The largest category by count, and the safest by construction — these can
never collide with anything else because only one such buffer is ever
focused at a time, and the autocmd is scoped with `buffer = <bufnr>`:
color_my_ascii.nvim's `:Fence open` temp buffer, markdown.nvim's TableView
float and `MarkdownNvimTableMode_<bufnr>`, mdview.nvim's tab-preview sync,
filetree.nvim's per-instance rename-batch/filter/live-search input buffers,
github_stats.nvim's dashboard, pickers.nvim's `selected_index` overlay
(results + prompt buffers of one specific picker instance), reposcope.nvim's
prompt buffers, lib.nvim's kit surface/picker/preview floats.

## Not filetype-scoped at all (whole-Neovim-session events)

`VimEnter`, `VimLeavePre`, `User` events, `TermOpen`/`TermRequest` — see
[autocmds-by-event.md](autocmds-by-event.md) for these; "filetype" isn't a
meaningful axis for them.
