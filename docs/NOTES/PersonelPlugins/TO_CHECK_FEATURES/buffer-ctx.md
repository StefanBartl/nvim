# Testing buffer-ctx.nvim

How to manually test every implemented feature of `buffer-ctx.nvim` — four
independent command trees that generate or manipulate small pieces of text
about the current buffer: `:Insert`/`:Copy` (context text: path, module,
timestamp, UUID, annotations, boilerplate, snippets), `:Format`
(buffer/selection formatting), and `:Mark` (persistent per-line marks).
One-time setup, then one section per feature: prerequisites, steps, what to
expect. Checkbox syntax (`- [ ]`) is standard Markdown — togglable directly
in Neovim with `cascade.nvim`'s `<leader>tc`.

Repo: `E:\repos\buffer-ctx.nvim`. Spec: `plugins/personal/init.lua` — command-
lazy (`cmd = { "Insert", "Copy", "Format", "Mark", "MarkLineToggle",
"MarkLinesYank", "CopyFilepathAbsolute", "CopyFilepathRelative" }`) plus
key-lazy (`keys = { "<leader>cnl", "<leader>cnm", "<leader>cnf", "<S-m>",
"<C-p>" }`), `opts = {}` (pure defaults — no keymap/format/mark overrides in
this config).

## Setup

```vim
:checkhealth buffer_ctx
```

**Expect**: `lib.nvim` detected (the command layer is built on
`lib.nvim.bindings.usercmd.composer` — a hard dependency, not optional), the
two compat commands registered, and separate `format`/`mark` sections each
reporting enabled. Any real Lua/Markdown buffer works as a test target for
everything below.

---

## 1. `:Copy filepath` (clipboard target) — the dominant real usage

**Why first**: telemetry on this exact install (10 sessions, 52 calls total)
shows `commands._dispatch`'s own argument profile is 89 % `("filepath",
<table>, "clip"[, nil])` — this one subcommand-plus-target combination
*is* the plugin's real usage on this machine so far; everything else below
has zero recorded calls.

- [ ] `:Copy filepath` → cwd-relative, unix-style path on the `+`/unnamed
      register (paste to confirm).
- [ ] `:Copy filepath abs` → absolute path.
- [ ] `:Copy filepath nvim` → relative to `stdpath("config")` — meaningful
      only when tested from inside this config repo itself.
- [ ] `:Copy filepath lua` → dotted Lua module form (`buffer_ctx.ops.filepath`
      style), only correct from inside a real `/lua/` tree.
- [ ] `:Copy filepath 1` (depth arg) → last path segment only (filename); try
      `2`/`3` too and confirm it's always "last N+1 segments", not "first N".
- [ ] `:CopyFilepathAbsolute` / `:CopyFilepathRelative` compat aliases — same
      output as their `:Copy filepath absolute` / `relative` equivalents.
- [ ] `<leader>cnf` (filepath_copy keymap) — same result as bare
      `:Copy filepath`.

---

## 2. `:Insert boilerplate` (cursor target) — second-highest real usage

The remaining 11 % of `commands._dispatch`'s recorded calls are
`("boilerplate", <table>, "cursor", nil)` — this is the only other
subcommand with any recorded use at all.

- [ ] `:Insert boilerplate` (no args) → `vim.ui.select` picker listing all 18
      templates with descriptions.
- [ ] Pick `lua-module` from the picker → full module skeleton, already
      containing a correct `---@module` line derived from the buffer's own
      path.
- [ ] `:Insert boilerplate lua-class MyService` (template + name given
      directly, no picker) → class skeleton named `MyService`.
- [ ] `:Insert boilerplate guard-clause` — the one template that prompts
      interactively for its own inputs instead of taking a name arg; confirm
      it actually prompts rather than erroring on a missing argument.
- [ ] Try at least one of the nine HTML fragment templates (figure, code
      listing, blockquote, formula table, aside, pagination nav, accordion,
      table, section) and one non-Lua glue template (`nvim_create_autocmd`
      block or `vim.keymap.set` stub).
- [ ] `:Copy boilerplate <template>` — same generated text, but on the
      clipboard instead of inserted, multi-line joined with `\n` as one
      pasteable block.

---

## 3. Everything else in `:Insert`/`:Copy` — zero telemetry, still core

None of these have a single recorded call yet on this machine, but they're
listed in the command catalog as first-class subcommands — worth exercising
directly rather than assuming "unused = unimportant" per this file's own
methodology.

- [ ] `:Copy location` → `path:line`. `:'<,'>Copy location range` on a
      visual selection → `path:L1-L2` instead; a single-line range should
      collapse back to plain `path:42`, not emit a pointless `L5-L5`.
- [ ] `:Copy module` → `require("buffer_ctx.ops.filepath")`-style string;
      `:Copy module lua_ls` → `---@module '...'` line instead. **Then
      deliberately open a buffer that is not under any `/lua/` directory**
      (e.g. a Markdown file) and run `:Insert module` — the code returns the
      literal error `"not inside a /lua/ directory"` for this case; confirm
      it surfaces as a real, readable notification rather than a raw Lua
      traceback.
- [ ] `:Insert timestamp` and `:Insert timestamp short --utc` — spot-check
      2-3 of the 13 documented formats (`iso`, `unix`, `human`, `filename`,
      `rfc2822`) actually match their documented shape.
- [ ] `:Insert uuid` and each of its four styles
      (`standard`/`compact`/`upper`/`braced`).
- [ ] `:Insert annotation module/class/param/return` — a couple of the nine
      one-line annotation types, confirming an omitted argument falls back
      to an interactive `vim.fn.input()` prompt rather than erroring.
- [ ] `:Insert annotation function` — the guided multi-parameter dialog:
      description, then repeated name/type prompts until one is left empty,
      then a return type, assembled into one `---@param`/`---@return` block
      in a single motion.
- [ ] `:Insert annotation overload fun(a: string): bool` and
      `:Insert annotation deprecated use M.new instead` — both reassemble
      multi-word input into one string; confirm the space-containing
      argument isn't truncated to its first word.
- [ ] `:Insert snippet` with `opts.snippets.paths` pointed at a real VSCode-
      format JSON file — picker opens, resolves by either display key or
      `prefix`; a `${1:i}`-style placeholder should flatten to plain `i`
      text (no tabstop navigation, since buffer-ctx has none).
- [ ] `:Insert env HOME` (or another real env var) and `:Insert git branch`
      (from inside a real git repo).
- [ ] `:Insert linecount` and `:Insert bufnr`.

---

## 4. `:Mark` — dedicated keymaps, zero telemetry

`<S-m>`/`<C-p>` are bound directly in this config (`keys` in the lazy spec),
but no calls into `mark/init.lua` are in the telemetry sample — worth
checking this whole subsystem actually works end to end.

- [ ] `<S-m>` on a line → sign-column `●` appears (or a virtual-text overlay
      on Neovim 0.9 — check `:version` first). `<S-m>` again on the same
      line removes it.
- [ ] `3<S-m>` (count) → marks the cursor line and the two below it, clamped
      at the end of the buffer.
- [ ] Select a 5-line visual range with two lines already marked, then
      `:'<,'>Mark toggle` — **expect the whole range to end up marked**, not
      a per-line checkerboard toggle (this is a deliberate, documented
      design choice: any unmarked line in the range means "mark everything").
      Only when every line in the range is already marked does the range
      unmark.
- [ ] `<C-p>` (yank) → every marked line, sorted by buffer position, newline-
      joined on the clipboard — paste to confirm order and content.
- [ ] Configure `opts.mark.categories` with two named categories (e.g.
      `todo`/`done`), then `:Mark toggle todo` / `:Mark toggle done` on
      different lines, `:Mark yank todo` — only the `todo` lines come back.
      Then `:Mark toggle todo` on a line already marked `done` — it should
      **replace** the category (now `todo`), not unmark the line.
- [ ] `:Mark clear` (no keymap by default) removes every mark in the buffer;
      `:Mark clear todo` removes only that category.
- [ ] **The 0.9-vs-0.10 gotcha, if you have a way to test 0.9**: mark a
      line, then delete it. On 0.10+ the mark should be deleted outright
      (`invalidate = true`); on 0.9 it should slide onto the line that took
      its place instead — a real, documented behavioral difference, not a
      bug, but worth confirming which one your actual Neovim exhibits before
      trusting `:Mark yank`'s output blindly after an edit-heavy session.
- [ ] Mark a line, then `:bd` (or `:bw`) that buffer — reopen it, marks
      should be gone (`BufferCtxMarkCleanup` autocmd), not silently carried
      over from stale state.

---

## 5. `:Format` — buffer/selection formatting, zero telemetry

- [ ] `:Format trim` — strips trailing whitespace on every line.
- [ ] `:'<,'>Format table` on a hand-misaligned Markdown table — columns
      realign; try `header=center cell=left` too.
- [ ] `:Format column 40` on a **charwise** (`v`) or **blockwise** (`<C-v>`)
      selection — aligns to column 40. Then deliberately try
      `Vjj:Format column 40` (linewise `V` selection) — **expect a real
      error**, not silent misalignment; this is a documented deliberate
      refusal since a linewise selection carries no usable column geometry.
- [ ] `:Format textwidth 80` and `:Format textwidth max` (current window
      width) — both set `textwidth` and reflow in the same step.
- [ ] `:Format filter TODO` (keep matching) vs `:Format filter --remove
      TODO` (drop matching) — before/after line count reported either way.
- [ ] `:'<,'>Format enum roman sep=") "` on a visual selection of tokens.
- [ ] `:Format squeeze` on a buffer with several multi-blank-line runs —
      collapses each run to at most one blank line; try the range-aware form
      too (`:'<,'>Format squeeze`).
- [ ] `:Format sort -r -i`, `:Format unique -i`, `:Format case title`,
      `:Format indent --spaces 2` — one pass each is enough; these are
      simple whole-buffer line operations.
- [ ] `:Format case sentence` on a buffer with **multiple** sentences
      (`[.!?]\s+` boundaries) — confirm every sentence gets capitalized, not
      just the very first letter of the buffer (this module deliberately
      does not delegate to lib.nvim's own `sentence` mode, which only
      handles the first one).

---

## 6. Telescope boilerplate picker (optional integration)

Only if `telescope.nvim` is installed and loaded.

- [ ] `require("telescope").load_extension("buffer_ctx")`, then
      `:Telescope buffer_ctx boilerplate` (or bare `:Telescope buffer_ctx`)
      — same template list as `:Insert boilerplate`'s picker, but with a
      live preview pane showing the exact lines before committing.
- [ ] Hover `guard-clause` in that picker specifically — since it's the one
      interactive template, the preview should show a static placeholder
      instead of actually triggering the prompt just from being highlighted.

---

## 7. Config toggles and `:checkhealth` differentiation

- [ ] `commands = false` → `:Insert`/`:Copy`/`:Format`/`:Mark` all fail to
      register as commands at all (`:command Insert` finds nothing); the
      Lua API (`require("buffer_ctx").insert(...)`/`.copy(...)`) still
      works.
- [ ] `format = false` → `:Format` is gone; `:checkhealth buffer_ctx`'s
      format section reports **disabled**, not a missing-command warning.
- [ ] `mark = false` → `:Mark` gone, `<S-m>`/`<C-p>` unbound, and — the
      detail worth actually checking, not just assuming — the
      `BufferCtxMarkCleanup` autocmd group should not be registered either
      (`:augroup BufferCtxMarkCleanup` / `:autocmd BufferCtxMarkCleanup`
      should show nothing).
- [ ] `keymaps = false` → the 3 core keymaps unbound, commands unaffected
      (unlike `format`/`mark`, this one is keymap-only).
- [ ] Run `:checkhealth buffer_ctx` again after each toggle above — each
      subsystem should be independently reported, so a disabled `format`
      doesn't make the `mark` section (or the core Insert/Copy section)
      report anything misleading.
