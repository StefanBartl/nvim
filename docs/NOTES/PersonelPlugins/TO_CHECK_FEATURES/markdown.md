# Testing markdown.nvim

How to manually test every implemented feature of `markdown.nvim`. One-time
setup, then one section per feature: prerequisites, steps, what to expect.
Checkbox syntax (`- [ ]`) throughout.

Repo: `E:\repos\markdown.nvim`. Spec: `plugins/personal/init.lua` — `ft =
{ "markdown", "mdx", "md" }`, `opts = {}` (every default below is live
as-is), `dependencies = { "StefanBartl/color_my_ascii.nvim" }` (soft
dependency: only guarantees load order in this config, for §2's fenced-scope
provider — the plugin works without it, falling back to a built-in fence
scanner).

**Telemetry note**: 56 accumulated sessions, 570,740 calls, but 85% of that
is `hl_groups.blockquote.highlight_line` and another chunk is
`core.fold.foldexpr` — both per-line render hot paths, not feature signals.
What *is* a real entry-point signal: `hover.trigger`/`hover.show`/
`hover.link_under_cursor` each fired 288 times and `hover.float.close` 739 —
the link hover preview is by far the most exercised real feature on this
machine. `scope.enabled`/`scope.op_enabled`/`scope.row_fence_kind` each fired
~3,300 times — fenced-block scope is checked on nearly every heading-aware
operation, meaning this config edits documents with embedded Markdown
examples often enough for it to matter. `core.slug.slugify` (2,170) and
`core.slug.heading_anchors` (382) point at heavy TOC/anchor use.
`core.refs.baseline` (188) confirms `refs` reconciliation runs for real, not
just in theory. Ordering below leans on this signal first, then
README/WORKFLOW's own structure for everything telemetry is silent on.

## Setup

```vim
:checkhealth markdown
```

**Expect**: Neovim version OK, the cross-platform opener (`vim.ui.open`)
reported, `lib.nvim` OK (hard dependency for the whole `:Markdown`/
`:TableView*` command layer), which-key/picker-backend info, optional host
plugins (`render-markdown.nvim`, `markdown-preview.nvim`, `mdview.nvim` —
all three should show detected in this config, mdview.nvim especially since
it's installed here), and the `fenced_scope` state naming which fence-detection
backend is active — should say `color_my_ascii` here, not the built-in
scanner, since that soft dependency is installed.

A good test target: this repo's own `README.md` or any `docs/FEATURES/*.md`
file — both are real, link-and-heading-dense Markdown you already have.

---

## 1. Link hover preview

The single most-exercised real feature on this machine (288 triggers).

**Steps**

1. Open a file with a real internal link, e.g. `[Features](docs/FEATURES/README.md)`
   somewhere in this repo's own docs.
2. Rest the cursor on the link (default trigger `CursorHold`, `updatetime`-driven,
   `delay_ms = 250`) — or call it on demand: `:lua require("markdown").hover()`.

**Expect**: a small, cursor-relative float appears showing the target's first
lines, markdown-highlighted. Try the different target types in turn:

- [ ] A link to `#anchor` in another file — float shows **just that section**
      (heading + body, stopping at the next same-level heading), not the
      whole file.
- [ ] An in-page `#anchor` — shows that section from the current buffer.
- [ ] A link to a file that doesn't exist — float says so explicitly
      ("missing", with the path it tried), not a blank/error float. This is
      the case worth checking most: it's meant to catch broken links while
      you write, before `:Markdown links check` ever runs.
- [ ] A link to a directory — shows its entries, directories first.
- [ ] A bare URL — host/path/decoded query, purely local (no request) since
      `hover.url.fetch` defaults `false`. Flip it to `true` in a scratch
      `setup()` call and confirm `<title>`/description now actually get
      fetched and shown.
- [ ] An image link (if images.nvim is installed) — the picture itself,
      floated to its own aspect ratio, no filename/size text overlaid.
- [ ] A `<figure>` block's `<figcaption>` line — hovering the caption line
      (which itself contains no target) should show the figure's own image,
      not "missing target".

**Behavior checks**: the float never takes focus and closes on the next
cursor move, insert-mode entry, scroll, or buffer switch — confirm all four.
Hover on a link, edit the target's content elsewhere, hover again — should
show the updated content (mtime-keyed cache, not stale).

**Escalation** — no default keymap, so bind one for this test:
```lua
vim.keymap.set("n", "<CR>", require("markdown").hover_escalate, { buffer = true })
```
On a Markdown-file link, `<CR>` should open the full `:Markdown mdview`
(mdview.nvim, installed here) instead of the small float; on an image, a
full-screen `images.zen.open` view.

---

## 2. Fenced-block scope

Checked on nearly every heading-aware operation this session (~3,300 calls
across `scope.enabled`/`op_enabled`/`row_fence_kind`) — clearly load-bearing
for how this config's own documentation (full of embedded Markdown examples,
like this very file) gets edited.

**Steps**

1. Open a file with a fenced ` ```markdown ` block containing its own
   headings — this repo's `docs/fenced-scope.md` has one built in.
2. Put the cursor **inside** the fenced example, run `<leader>toc`.
3. Move the cursor **outside** the fence, run `<leader>toc` again.

**Expect**: step 2 inserts/refreshes a TOC of the *example's own* headings,
placed inside the fence — not the outer document's headings. Step 3 produces
the outer document's TOC, and it should **not** include any heading that
lives inside the fenced block. Also check heading nav (`<C-f>`/`<C-p>`)
inside the fence stays within it, and outside the fence jumps *over* the
fenced block's `#`-looking lines instead of landing on them.

**Provider check**:
```vim
:Markdown scope status
```
**Expect**: reports scope on/off and which provider resolved fence
boundaries — should read `color_my_ascii` here (§Setup already confirmed
it's active). If a heading operation ever does something unexpected inside a
nested fence, this is the first thing to check — a provider mismatch
(color_my_ascii vs. the built-in scanner reporting different fence
boundaries) is the documented usual cause.

**Nesting**: build a fence-inside-a-fence (outer fence longer than inner,
per CommonMark, e.g. outer opened with ` ```` `) and confirm the detector
honors fence length correctly — `<leader>toc` from inside the inner block
should scope to the inner block only.

**Toggle**: `:Markdown scope off`, repeat step 2/3 — both should now use
whole-buffer behavior (fenced content included in the outer TOC). `:Markdown
scope on` restores scoping.

---

## 3. TOC, heading anchors, and `refs` reconciliation

Second-strongest telemetry signal (`slugify` 2,170×, `heading_anchors` 382×,
`refs.baseline` 188×) — real, frequent TOC/anchor/rename activity.

**Steps**

1. In a document with several H2+ headings, `{count}<leader>toc` (try both a
   bare `<leader>toc` and `3<leader>toc` for a level-3 cap).
2. Rename one of the headings' text.
3. `:Markdown refs check` (dry run), then `:Markdown refs sync`.

**Expect**: step 1 inserts/refreshes a TOC **and** enforces blank-dash-blank
spacing between H2+ sections in the same run (`ensure_headline_spacing`,
default on) — confirm both happen together, not just the TOC. Rerunning with
a different count re-derives the TOC from scratch (doesn't merge with what
was there). Step 2/3: the renamed heading's own `[text](#old-anchor)` links
and the TOC entry should update to the new anchor — `refs check` first lists
it as a dry-run finding in the quickfix list, `refs sync` actually
propagates it. Delete a heading a link points to and confirm `refs check`
reports it as broken/orphaned.

**Gap detection**: create a document with an H1 followed directly by an H3
(no H2), run `:Markdown gaps` (or just `<leader>toc`, which runs the same
check automatically). **Expect**: a notification naming the gap, offering to
renumber it on the spot — confirm accepting actually renumbers the offending
heading in the buffer.

**`refs.mode`**: this config uses the default `"save"` (`BufWritePre`).
Rename a heading, **don't** manually sync, just `:w` — confirm the rename
propagated automatically on save. Then try `:Markdown refs live on` for a
buffer, rename a heading, and confirm it propagates *before* saving (after
`refs.debounce_ms` = 2000ms of no typing) — this is a per-buffer opt-in, not
the config default.

---

## 4. Heading level shift and folding

**Steps**

```
<C-Right>   " on a heading line, normal mode
<C-Left>
<S-Right>   " whole buffer
zk          " toggle outline (keep H1+H2 open)
zi          " fold previous heading, center
```

**Expect**: `<C-Right>`/`<C-Left>` bump just the current heading's level
(`##` → `###` etc.); a `{count}` prefix multiplies it (`2<C-Right>`).
`<S-Right>`/`<S-Left>` shift **every** heading in the buffer by one level —
confirm sub-headings shift consistently with their parents (relative
structure preserved, not just the top-level ones). In visual mode,
`<C-Right>`/`<C-Left>` only affect **existing headings** within the
selection — text that isn't a heading should be left alone. `zk` toggles
between "everything open" and "H1+H2 open, rest folded" — confirm it's a
genuine toggle, not one-directional.

---

## 5. Cursor-action dispatcher — `ma` / `mi` / `mj` / double-click

**Steps**

Try each on a document with an anchor link, an image link, a URL, and a
local file link:

```
ma    " on/near any link
mi    " on an image link specifically
mj    " on an anchor link
<2-LeftMouse>
```

**Expect**: `ma` (or double-click) opens whatever's under the cursor via the
right mechanism per target type — `mj` jumps to the anchor in-buffer, `mi`
opens the image (system app, or an in-Neovim preview prompt if a provider is
installed — this config has images.nvim, so expect the "System app vs.
Preview in Neovim" prompt per `image.preview = "ask"`, the default).

**The "ask" trap, deliberately verify the asymmetry**: open a **PDF** link —
expect the System-vs-pdfport prompt to appear automatically (pdfport.nvim is
installed here), with **no** config knob controlling it (unlike images,
there's no `pdf.preview` setting). Open a plain text/media file via
`open.external_extensions` — expect **no** prompt at all, straight to the
system app or `:edit`. Confirm this three-way asymmetry (images: promptable;
PDFs: always-prompt; everything else: never-prompt) matches, rather than
reading as inconsistent.

**Windows/WezTerm provider trap**: since images.nvim (OSC 1337) is the
provider here, `mi` should actually draw inline. If it silently falls
through to the system viewer despite images.nvim being installed, check
`:lua print(vim.inspect(require("markdown.util.image_preview").detect()))`
directly — `:checkhealth markdown` deliberately does not check this.

---

## 6. Links — `show` / `check` / `sanitize` / `create`

**Steps**

```vim
:Markdown links show
:Markdown links show cwd
:Markdown links check
:Markdown links sanitize
:Markdown create fs
```

**Expect**: `show` (buffer scope, `%`) lists every link in a picker
(`hover_select` default backend) and opens whichever you pick — URL to
browser, `#anchor` to an in-buffer jump, file to system app/`:edit`. `show
cwd` scans every `*.md` under the working directory instead. If the scanned
links include an image and both `snacks.picker` and images.nvim are
installed (both true here), confirm it routes through `snacks.picker`
instead with a **live image preview per item** — different from the default
backend's picker.

`check` publishes real diagnostics (namespace `markdown_links`) for dead
relative-file links and duplicate heading titles, mirrored into the
**quickfix** list (not loclist — confirm `:copen`, not `:lopen`, shows them).
Deliberately break a link (typo a filename) first to confirm it's actually
caught.

`sanitize` normalizes inline-link spelling only — write a link with a
backslash path (`[t](.\doc\file.md)`) and confirm it becomes
`[t](./doc/file.md)` after `sanitize` (or automatically on save, since
`links.sanitize_on_save` defaults on — don't sanitize manually first, just
`:w` and check). Confirm a URL, `#anchor`, or absolute path is left
untouched.

`:Markdown create fs` on a link pointing at a file/directory that doesn't
exist yet — confirm the file/dir actually gets created, and a trailing `/`
in the link creates a **directory**, not a file with a trailing slash in its
name.

---

## 7. Tables — the four layers

Per WORKFLOW.md, these are independent and stack; test each's own job
rather than reaching for the heaviest one for everything.

**Steps**

```vim
:Markdown table new 3 2
:Markdown table format
:Markdown table mode on
:Markdown table view toggle
```

**Expect**: `table new 3 2` inserts an empty 3-column/2-row GFM template.
`table format` aligns columns/normalizes separators on the table at the
cursor — deliberately misalign a table by hand first to see it fixed.
`table mode on`, then edit a cell and leave insert mode — the table should
re-align **automatically**, no manual format step (debounced on
`InsertLeave`/`TextChanged`). `table view toggle` opens a floating,
nicely-formatted preview — try `<M-Right>`/`<M-Left>` to resize a column in
the popup (reading aid only) and `<M-Up>`/`<M-Down>` to reorder rows, then
`:w` inside the popup and confirm the **row order** change actually wrote
back to the source, while the column-width change did **not** (natural,
unpadded widths on write — confirm by reopening the preview).

**`tableize`**: select a few tab- or comma-delimited lines,
`:'<,'>Markdown table tableize`, confirm auto-detected separator produces a
correct GFM table. Try a quoted CSV field containing the delimiter
(`"Smith, John",42`) and confirm it becomes exactly two cells (RFC-4180
quoting honored).

**`import`**: copy a real HTML `<table>` to the clipboard, `:Markdown table
import clipboard` — confirm it becomes a GFM table with entities (`&amp;`
etc.) unescaped and inner tags stripped.

---

## 8. HTML `<figure>` / caption resolution

**Steps**

Write a captioned image as HTML:
```html
<figure>
  <img src="assets/start.png" alt="Start Screen">
  <figcaption>Figure 1: Start Screen</figcaption>
</figure>
```

**Expect**: hover on the `<figcaption>` line shows `assets/start.png`'s
preview (§1), `mi` opens/previews that same image, `:Markdown links show`
lists it as a real entry, and `:Markdown links check` flags it as dead if
the path doesn't actually exist — i.e. the figure behaves exactly like a
plain `![alt](assets/start.png)` for every tool in the plugin, confirming
the whole link machinery (not just hover) reads HTML targets now.

---

## 9. Integrations — `render` / `preview` / `mdview` / `export`

**Steps**

```vim
:Markdown mdview
:Markdown export pdf
```

**Expect**: `mdview` opens the current file in mdview.nvim's browser preview
(installed in this config) — starts a session or pushes to an already-running
one. `export pdf` delegates to pdfport.nvim; on an unmodified buffer with a
file on disk it exports the file directly, on an unsaved buffer it
materializes the live content to a tmpfile first — test both cases (save vs.
don't save before exporting) and confirm the exported PDF reflects unsaved
edits in the second case. Try `render`/`preview` too if those host plugins
are installed; if not, confirm a graceful "not installed" warning rather
than an error.

---

## 10. Underline headings and remapping

**Steps**

```vim
:MarkdownNvimUnderlineHeadings
```
Run it twice in a row, then rename a heading's text and run it a third time.

**Expect**: first run inserts a `=`-line under every ATX heading's text,
matching its length. Second run (nothing changed) leaves the buffer
byte-identical — idempotent. Third run, after the rename, corrects the `=`
count to match the new text length — confirm it updates rather than leaving
a stale-length underline.

**Remapping**: `require("markdown").setup({ keymaps = { toc = "<leader>T" }
})` in a scratch call — confirm `<leader>T` now runs TOC and the *old*
`<leader>toc` mapping (via `{count}<leader>toc`) is gone. `keymaps =
{ jump_anchor = false }` — confirm `mj` no longer does anything. If
which-key is installed, confirm the `<leader>t` prefix carries an automatic
group label with no extra config.

---

## What cannot be checked here, and why

- **URL metadata fetch** (`hover.url.fetch = true`) is off by default and
  deliberately not exercised in day-to-day use per the plugin's own privacy
  reasoning (a hover that silently fetches would leak every link you brush
  past) — turning it on is a scratch-config-only test (§1), not something to
  leave enabled afterward.
- **PDF hover rendering** needs pdfport.nvim's `pdftoppm` backend actually
  installed and working — if that's broken, the hover degrades to a size/
  reason float rather than the rasterized page, which looks similar to "not
  tested" from the outside; cross-check against `:checkhealth pdfport`
  separately if the PDF hover case in §1 doesn't render.
