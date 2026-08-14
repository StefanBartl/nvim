# context_open

One keymap instead of five. `M-o` looks at whatever is under the cursor and
dispatches to the right plugin — `gopath.nvim`'s `gF`, `markdown.nvim`'s
`TableView`, `images.nvim`, `pdfport.nvim`, or `open.nvim` — instead of
having to remember which mapping belongs to which plugin. `M-O` lists every
openable target in the whole buffer.

Motivating example: cursor on a URL inside a markdown table cell. That's
both a table (toggle `TableView`) *and* a URL (open in the browser) — there
is no single correct answer, so `context_open` asks.

## Keymaps

| Keymap | Action |
|---|---|
| `M-o` (normal) | Open whatever is under the cursor |
| `M-O` (normal) | Pick from every openable target in the buffer |

## Usercmds

| Command | Same as |
|---|---|
| `:ContextOpen` | `M-o` |
| `:ContextOpen list` | `M-O` |

## How `M-o` decides

1. Every provider below runs against the cursor position. Each yields zero,
   one, or several candidates.
2. **Zero** candidates → the rest of the current line is searched instead
   (same providers' URL/path scanner, not the file-type-specific ones —
   see "Line-search fallback" below). Zero there too → a warning, nothing
   opens.
3. **One** candidate → runs immediately, no prompt.
4. **More than one** → a chooser (`lib.nvim.ui.kit.select`, "Open with…").

## Providers

| Provider | Detects | Runs |
|---|---|---|
| `gopath` | `require("gopath").resolve()` — treesitter/LSP/path resolution under the cursor | `gopath.commands.resolve_and_open("edit")` (`gF`) |
| `markdown_table` | Cursor line inside a parsed GFM table (`markdown.tableview.parser`) | `:TableViewToggle` |
| `images` | `images.resolve.under_cursor()` — a markdown image link or bare image filename | `images.hover()` |
| `pdfport` | `<cfile>`/resolved path ends in `.pdf` and exists (pure filesystem check, no plugin dependency) | two candidates: `open.nvim`'s `default` handler (system PDF viewer) *and* `:PdfPort text` (extract to buffer) |
| `open_nvim` | `open.context.candidate_targets(signals)` — tree-buffer node, URL, or existing path | `open.registry.dispatch(key, ctx)` for each candidate key (`filemanager`/`browser`/`notepad`/`split`/`vsplit`/`tab`/…) |

Provider order (also the picker's display order): `gopath`, `markdown_table`,
`images`, `pdfport`, `open_nvim` — specific matches before open.nvim's
generic file-target candidates.

`open_nvim` suppresses its own `split`/`vsplit`/`tab`/`filemanager`
candidates for extensions a more specific provider already owns (`.pdf`,
and whatever `images.nvim` is configured for) — nobody wants a PDF's raw
bytes loaded as a text buffer when `pdfport`/the system viewer are right
there.

## `M-O`: buffer-wide list

Scans the whole buffer with `open.viewer.scan` (open.nvim's own link/URL/path
extractor — markdown links, bare URLs, and existing-file paths) plus one
entry per markdown table, sorted by line. Selecting an entry jumps the
cursor there and runs the same action `M-o` would have. Entries pointing at
an image or a `.pdf` file are tagged and routed to `images.show()` /
`:PdfPort text` instead of the generic open.nvim dispatch.

**Not included:** gopath-resolvable code identifiers (symbols, imports).
There is no cheap whole-buffer API for those (gopath resolves at the cursor,
via treesitter/LSP), and a flat list of every resolvable identifier in a
code file would not be a usable picker anyway. Use `M-o` at the cursor for
those, same as plain `gF`.

## Line-search fallback (`M-o`, zero candidates under the cursor)

Reuses the same `open.viewer.scan` extractor as `M-O`, scoped to the current
line instead of the whole buffer (`scan.from_line`). This only ever fires
when open.nvim's own signals found nothing at all (no tree node, no
`<cfile>`, no `<cword>`) *and* none of the file-type-specific providers
matched — not on every "only one obvious answer" invocation, since
`open_nvim`'s own trivial "reveal buffer in file manager" fallback is
deliberately excluded from counting as a real candidate (see
`providers.lua`'s `has_open_target`).

## Design notes

- **Why `lib.nvim.ui.kit.select` and not a `pickers.nvim` picker.**
  `pickers.nvim`'s public surface (`pickers.sources.*`) is filesystem-source
  oriented (cwd/folder/repos/drives) — there is no "picker over an arbitrary
  Lua list" entry point. `kit.select` is the fallback already used in this
  exact situation by `open.nvim`'s own `open.picker` (its opt-in
  ambiguous-target chooser), `images.nvim`, and `bindings.usrcmds.case`/
  `bindings_explorer`. `respect_override = true` is used throughout, so a
  `vim.ui.select` override (telescope-ui-select, fzf-lua, dressing.nvim) is
  still picked up automatically if one is active.
- **Read-only detection.** Every provider's detection step is side-effect
  free (`gopath.resolve()` is documented as such; the rest are plain
  filesystem/buffer reads), so `M-o` can safely run every provider on every
  keypress without worrying about accidentally triggering something.
- **`cmd`-only plugins.** `open.nvim` and `pdfport.nvim` are `cmd`-gated in
  `plugins/personal/init.lua`, not `ft`/`event`-gated — unlike
  `gopath.nvim` (`event = "VeryLazy"`), `markdown.nvim` and `images.nvim`
  (both `ft`-gated, so already loaded in any buffer where their providers
  would apply). `util.ensure_loaded()` force-loads them via
  `lazy.core.loader.load` before use, so `M-o` works on its very first
  invocation in a session too. `pdfport`'s own *detection* deliberately
  avoids needing this at all — it's a pure filesystem check — only its
  `run()` actions need the plugin loaded, and `vim.cmd("PdfPort …")`
  triggers that itself.

## Adding a new provider

Add a `fun(signals): ContextOpen.Candidate[]` to `providers.lua` and list it
in `M.ORDER`. `signals` is `open.context`'s `OpenNvim.Signals` (`cfile`,
`cfile_path`, `cword`, `tree_path`, `visual`, `buffer_path` — see
`open.context`'s module doc in open.nvim). Return `{}` when not applicable;
never throw (the caller pcalls it, but don't rely on that).

## Status

Implemented directly in this nvim config
(`lua/bindings/usrcmds/context_open/`), not as a standalone plugin. May move
out into its own `*.nvim` repo later, following the same extraction pattern
as `gopath.nvim`/`open.nvim`/etc., if it turns out to be useful beyond this
config.
