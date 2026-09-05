# Testing color_my_ascii.nvim

How to manually test every implemented feature of `color_my_ascii.nvim` —
colorful, language-aware highlighting of ASCII art / diagrams in Markdown
fenced code blocks, plus the `:Fence` literate-programming toolkit for the
block under the cursor (export, yank, edit-in-split, run, format, align,
…). One-time setup, then one section per feature: steps, expected result.
Checkbox syntax (`- [ ]`) is standard Markdown.

Repo: `$REPOS_DIR\color_my_ascii.nvim`. Spec: `plugins/personal/init.lua` —
`ft = "markdown"` (loads only once a Markdown buffer opens), dependency on
`lib.nvim` (required — `:ColorMyAscii` is built on it). This config sets
**one** non-default option: `treesitter = { block_detection = false }` —
deliberately overriding the plugin's own default (`true`). The comment
explains why: the installed `markdown` grammar version isn't lockfile-
pinned across machines, and some versions mis-parse a shorter fence nested
inside a longer one as its own block, causing spurious fence-line
highlights. This means **on this machine specifically**, fence-boundary
detection always runs the heuristic line-scanner, never treesitter — worth
confirming that's actually true (§1) before assuming any fence-detection
bug is treesitter's fault. **No `keymaps` table is set** in this config, so
none of `docs/BINDINGS.md`'s preset keymaps (`<leader>ah`, `<leader>fy`,
etc.) are bound — every test below goes through `:ColorMyAscii`/`:Fence`
directly.

## Setup

```vim
:checkhealth color_my_ascii
```

**Expect**: Neovim version, `lib.nvim` presence, whether
`treesitter.syntax_highlight` has the per-fence-language parsers it needs
for any fence currently open (should list any missing ones by name, not
just "treesitter broken"), and confirmation that `block_detection` is
running the heuristic scanner in this config (not treesitter — see above).

A good test buffer, in Markdown:

````markdown
```ascii
┌─────────────────────┐
│  Hello World!        │
└─────────────────────┘
```
````

---

## 1. Automatic highlighting on a `` ```ascii `` block — the baseline

- [ ] Open a Markdown buffer, type the fenced block above. **Expect**:
      box-drawing characters colorize live as you type (debounced ~100ms),
      no save required.
- [ ] `:ColorMyAscii debug` → confirms the plugin loaded and is tracking
      the current buffer.
- [ ] Delete the whole block and retype it → highlighting reappears from
      scratch, no stale extmarks left behind from the deleted version.
- [ ] `:ColorMyAscii toggle buffer` → highlighting in **this buffer only**
      turns off; open a second Markdown buffer and confirm it's
      unaffected. `:ColorMyAscii toggle` (bare, defaults to `global`) →
      turns it off/on for **every** managed buffer at once — confirm the
      second buffer's highlighting changes too this time.

---

## 2. Fence-boundary detection: confirm the heuristic path, not treesitter

**This config specifically forces the heuristic scanner** — the one
override in `plugins/personal/init.lua` — so this is worth testing
directly rather than assuming the default (treesitter-assisted) behavior
applies.

- [ ] Nest a **shorter fence inside a longer one** (a 4-backtick outer
      fence containing a 3-backtick example inside its content) → the
      heuristic scanner should treat the whole thing as **one** block
      (matching fence length matters), not misparse the inner backticks
      as their own nested block. This is the exact bug `block_detection =
      false` exists to avoid.
- [ ] `:ColorMyAscii check-fences` on a buffer with a deliberately
      unclosed fence (delete the closing ` ``` `) → reports the unmatched
      fence with a real location, doesn't silently ignore it.
- [ ] `:ColorMyAscii ensure-blank-lines` on a fence with no blank line
      before/after it → inserts one on each side that's missing.

---

## 3. Language detection — standard tag, `ascii-` prefix, and the hover check

- [ ] `` ```go `` (standard tag) with real Go-flavored keywords inside →
      keyword coloring applies via `fence_language_map`'s alias table —
      confirm this works for at least one non-obvious alias too (`` ```rs
      `` for Rust, `` ```py `` for Python).
- [ ] `` ```ascii-go `` (explicit prefix) on a block that's ASCII art
      **containing** Go-flavored words (e.g. `if`/`else` labels in a
      diagram) → same keyword coloring, but confirm this block would
      **not** be picked up as "real code" by tooling that only recognizes
      standard tags (this is the documented reason to prefer the prefix
      form for diagrams-with-keywords).
- [ ] `:ColorMyAscii hover` on a character inside a keyword — a float
      shows the highlight group/keyword info for **that exact character**,
      and the summary is also copied to a register automatically (paste
      to confirm). This is the fastest way documented to confirm language
      detection actually did what you expected — use it on an ambiguous
      short block and confirm it explains what would be painted even if
      nothing is currently colored there.
- [ ] A block with **no** explicit tag, short/ambiguous content → falls
      back through heuristic keyword detection, then buffer filetype.
      Deliberately trigger a wrong guess (a short snippet ambiguous
      between two languages) and confirm an explicit tag (either form)
      fixes it immediately.

---

## 4. `:Fence` toolkit — extract/inspect (never mutates)

Telemetry gives no usable signal here (this plugin's own instrumented
functions are 43% one hot-path render function, `config.get_char_highlight`
— explicitly excluded as a priority signal per this file's own
methodology), so priority here follows the toolkit's own documented
three-way split: extract/inspect first (safest, most reusable), then
edit-in-place, then fence-structure changes.

- [ ] `:Fence yank` (cursor inside a block) → block content (fence markers
      stripped) on the `"`/`+` registers; paste to confirm.
- [ ] `:Fence yank --ansi` → paste into a terminal or ANSI-rendering chat
      client — the pasted text should carry the **actual on-screen
      colors** as 24-bit escape codes, not plain text.
- [ ] `:Fence export` (no path) → prompts for a path with a suggested
      filename (extension derived from the fence's language tag) and file
      completion; confirm the written file's content matches the block.
- [ ] `:Fence export --html` → suggested filename always ends `.html`
      regardless of the fence's own language tag; open the file in a
      browser and confirm the colors match what's on screen (a `<span
      class="cma-...">` per highlighted run, plus a scoped stylesheet
      covering only the groups actually used in that block).
- [ ] `:Fence export --replace` → the block in the buffer is swapped for a
      link reference to the exported file (a literate tangle) — confirm
      the original fence content is genuinely gone from the buffer, not
      just duplicated.
- [ ] `:Fence select` → Visually selects exactly the block's interior
      (not the fence lines themselves) — confirm `gv` afterward reselects
      the same range.

---

## 5. `:Fence` toolkit — edit in place

- [ ] `:Fence open` on a block tagged with a real language (`` ```lua ``)
      → opens in a split with real LSP/formatter attachment (check
      completion or diagnostics actually work in the split). Edit
      something, `:w` → the change syncs back into the fence in the
      original buffer via extmark anchors — confirm the original buffer's
      content actually updated, not just the temp file.
- [ ] `:Fence run` on a runnable language (`` ```lua ``/`` ```python ``
      with real code, not ASCII art) → output appears in a scratch split.
      Try it on an `ascii-go`-tagged block that's actually a diagram, not
      valid Go — confirm it attempts to run and fails as broken Go, rather
      than detecting "this is art" and refusing (documented: `run`
      doesn't distinguish art from code, only language).
- [ ] `:Fence format` on a block with a real formatter available for its
      language → reformats in place.
- [ ] `:Fence import <file>` → replaces the block's content with the
      file's content, fence markers untouched.
- [ ] `:Fence align` on a box-drawing box whose right edge was hand-edited
      out of alignment → straightens it; `u` undoes cleanly as a normal
      buffer edit. Try it on a **non-rectangular** shape (a directory-tree
      connector, `├──`) → should be left untouched deliberately, not
      "fixed" into a rectangle.

---

## 6. `:Fence` toolkit — change the fence itself

- [ ] `:Fence lang <language>` → retags the fence's opening line; confirm
      highlighting immediately re-resolves under the new language.
- [ ] `:'<,'>Fence wrap [lang]` on a Visual range of plain lines → wraps
      them in a new fence with the given language tag (or none).
- [ ] `:Fence unwrap` on a fenced block → removes the fence markers,
      leaving the bare content.

---

## 7. Fence-line and fence-content highlighting (background, always-on)

- [ ] Confirm the **whole** opening/closing fence line is painted as one
      block (not just the backticks) — the `preset = "auto"` default
      should visually match the current colorscheme; switch colorscheme
      (`:colorscheme <other>`) and confirm the fence highlighting
      re-applies automatically (the `ColorScheme` autocommand), not wiped
      by Neovim's implicit `hi clear`.
- [ ] On an **indented** fenced block (inside a list item, say) → the
      highlight rectangle starts at the block's own indent column on
      every row (including blank interior lines), not column 0.
- [ ] Resize the Neovim window → the highlight's right-edge inset
      (`right_pad`) recomputes; confirm it doesn't run off-screen or leave
      a stale gap after the resize.
- [ ] Fence-content (interior) highlighting should read as a visibly
      related but distinguishable tint from the fence-line color (shaded
      darker/lighter by default), not identical or jarring.

---

## 8. Comment-ASCII (opt-in, off by default) and the right-click menu

Lowest priority — both off in this config.

- [ ] `comment_ascii.filetypes = { "lua" }` (scratch config) with an
      explicitly marked `-- ascii … -- /ascii` block in a `.lua` file →
      gets the same character/keyword highlighting as a Markdown fence,
      but confirm `:Fence`/fence-line/fence-content chrome does **not**
      apply there — comments only get character/keyword highlighting,
      never the fence background painting.
- [ ] If a right-click menu host is wired into this config: right-click in
      a Markdown buffer, cursor inside a fence, confirm color_my_ascii's
      entries appear (and that argument-needing ones like `ensure_blank_lines`,
      `check_fences`, `fence_lang` are correctly **absent** from the menu
      by design). If no host is configured,
      `require("color_my_ascii.integrations.menu").items()` should still
      return a real table without erroring.

---

## 9. Highlight read-back API (new 2026-08-31)

Not a user-facing feature — a surface other plugins consume. Checked here
because a break in it is invisible from inside this repo, and because it
already has a consumer in this very config.

- [ ] `:lua =vim.tbl_keys(require("color_my_ascii").highlight)` in a Markdown
      buffer → `runs_for_block` and `attrs_for_group`, without `setup()`
      having been called explicitly.
- [ ] `:lua =require("color_my_ascii").highlight.attrs_for_group("Comment")`
      → colors as `"#rrggbb"` strings, not integers; an unset attribute is
      absent rather than a default.
- [ ] The real check is the consumer: with `highlighter = "nvim"` in mdview's
      spec, code blocks in the browser preview match the buffer — see section
      3c of [mdview.md](mdview.md). If those colors are right, this API is
      right; if the preview shows uncolored blocks where the buffer is
      colored, this is the first place to look.
