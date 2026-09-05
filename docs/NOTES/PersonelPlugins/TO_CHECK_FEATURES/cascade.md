# Testing cascade.nvim

How to manually test every implemented feature of `cascade.nvim` — four
domains under one roof: **lists** (continue, renumber, checkbox, cycle
type, rotate, sort, reverse, strip, indent/dedent, move), **cycle**
(word/boolean/date/number, global), **sequence** (renumber ordinals inside
a Visual selection, global), **transpose** (char/word swap, global).
One-time setup, then one section per feature: steps, expected result.
Checkbox syntax (`- [ ]`) is standard Markdown, togglable directly in
Neovim with this very plugin's own `<A-c>`/quick-toggle keys.

Repo: `$REPOS_DIR\cascade.nvim`. Spec: `plugins/personal/init.lua` — **both**
`ft = { "markdown", "markdown.mdx", "text", "tex", "norg" }` **and**
`event = "VeryLazy"` are set together (README recommends `VeryLazy` alone
for the global cycle to reach code buffers; this config layers `ft` on top
too — harmless since `VeryLazy` fires first in practice, but worth knowing
if load timing ever looks off). `opts = { keymaps = { preset = true } }` —
the opinionated keymap preset is explicitly turned on (it defaults to
`false`), so every keymap in `docs/BINDINGS.md` should actually be bound.

## Setup

```vim
:checkhealth cascade
```

**Expect**: Neovim version, per-domain status (lists/cycle/sequence/
transpose all enabled by default), `lib.nvim` availability — **required**,
not soft: `:Cascade` fails to load outright without it (built on
`lib.nvim.bindings.usercmd.composer`).

A Markdown scratch buffer covers the `lists` domain; any buffer (including
a `.lua` one) covers `cycle`/`transpose`/`sequence`, since those three are
global by design — that's the detail most worth double-checking below,
since it's also the detail people misread as a bug (expecting `cycle` to
be Markdown-only, or `<CR>`-continuation to work in a code comment).

---

## 1. List continuation — `<CR>`/`o`/`O`, the everyday habit

**Why first**: telemetry on this exact install (58 sessions, 32.463 total
calls) shows `lists.marker.parse` (10.645 calls) and
`lists.marker.is_continuation`/`is_blank_line` (3.019 each) dominate
everything else in the plugin — list-context detection on every `<CR>`/
`o`/`O` press is, by a wide margin, the most-exercised code path here.

- [ ] In a Markdown buffer, `- one<CR>` → `- two` auto-continues the
      bullet. Same for `1. one<CR>` → `2. two` (increments).
- [ ] `<CR>` on an **empty** bullet (`- ` with nothing after it) → deletes
      the empty marker and ends the list, rather than continuing it.
- [ ] `<M-CR>` → a plain literal newline, list continuation deliberately
      skipped.
- [ ] `o` / `O` in Normal mode on a list line → opens a new continued item
      below/above. `O` **directly below a bullet** (cursor on the line
      right after one, itself not a list line) should still open a new
      item above correctly — the one `O` edge case called out in
      `docs/BINDINGS.md`.
- [ ] Open Neovim from a **non-list filetype** (`.lua`) and confirm `<CR>`
      inside a comment does **not** try to continue anything — this domain
      is scoped to `lists.filetypes`, not global (the "expecting it in code
      buffers" surprise `docs/WORKFLOW.md` calls out explicitly).

---

## 2. Renumber — automatic (edit/save) and manual

Telemetry: `lists.renumber.tree` (555), `.at` (218), `.all` (97) — real,
frequent usage, consistent with `renumber.on = { "edit", "save" }` being
the default (auto-fires on every qualifying edit, plus a `BufWritePre`
safety net).

- [ ] Type a numbered list by hand with every line starting `1.` (out of
      habit) → on save (`:w`), every line should renumber to a clean
      sequence — the safety net firing.
- [ ] `<leader>cr` (`renumber`) on a block mid-edit → immediate renumber,
      no save required.
- [ ] A **blank line** inside a numbered block ends the sequence (default
      `blank_break = 0`) — the next list after it restarts at its own
      offset. A **non-marker, non-blank** continuation line (wrapped
      prose under an item) does **not** break the sequence — confirm a
      note line directly under item `1.` with no blank line before the
      next real item still renumbers that next item to `2`, not leaves it
      at whatever number you typed (this is the exact example in
      `README.md`'s "Renumber and continuation paragraphs").
- [ ] `<leader>cR` in Visual mode (`renumber_selection`, global —
      `sequence.enable`) on a selection covering ordinal tokens **mid-prose**
      (not list markers) — e.g. `"see steps 1, 2, 3"` — renumbers just the
      selected ordinals, any filetype, not just `lists.filetypes`.
- [ ] `:Cascade renumber all` on a buffer with several independent lists →
      every list in the buffer renumbers, not just the one under the
      cursor.

---

## 3. Indent/dedent — level-aware, and the count-meaning trap

**The one genuine trap in the binding surface**, per `docs/WORKFLOW.md` —
worth testing deliberately, not just once in passing.

- [ ] `<A-Right>` on a numbered list line with no count → indents just that
      line one level, and **every level** renumbers correctly (a deeper
      level restarts at `1.`, a shallower level continues, the level you
      left closes its gap — see the ASCII diagrams in `README.md`).
- [ ] `2<A-Right>` on two **sibling** lines (cursor on the first) → shifts
      **2 lines**, one level each — not "the current line by 2 levels".
- [ ] `2<leader><A-Right>` (`indent_levels`) on a **single** line → shifts
      that **one** line by 2 levels — the old count meaning, deliberately
      moved to a separate mapping. Confirm these two genuinely differ; per
      the docs this is exactly the pair muscle memory gets wrong under
      time pressure.
- [ ] Indenting a line with a **subtree** (deeper-indented children or
      wrapped continuation text directly below it) carries the subtree
      along by the same shift, instead of leaving it behind.
- [ ] `<Tab>`/`<S-Tab>` (Normal and Visual) — **not** in the preset
      (deliberately, to avoid a completion-menu conflict); confirm they
      are genuinely unbound in this config, native `<Tab>` behavior
      applies.
- [ ] Outside `lists.filetypes` (a `.lua` buffer), `<A-Right>`/`<A-Left>`
      still work but as a **plain** `>>`/`<<` — no renumbering (correct;
      it is not a list).

---

## 4. Move lines — reindent + renumber together

Telemetry: `lists.move.line` (98) / `_move` (98) — real usage.

- [ ] `<A-Up>`/`<A-Down>` on a line inside a numbered list → the line
      moves **and** the list renumbers around the move in the same step
      (this is the exact payoff `docs/WORKFLOW.md` names — manual
      reordering never keeps numbering in sync the way this does).
- [ ] `3<A-Down>` → moves 3 lines total, one step at a time (not a single
      3-line jump) — confirm reindenting/renumbering stays correct at
      each intermediate step, and that it stops cleanly at the buffer
      edge rather than erroring.
- [ ] `<A-Up>`/`<A-Down>` in Visual mode on a multi-line selection →
      the whole block moves together.
- [ ] Outside a list (plain prose/code line) → falls back to a plain
      `:move` with an `==` reindent, no renumbering attempted.

---

## 5. Quick toggles — bullet/star/number/checkbox without an existing marker

`core.patterns.unordered_class` (9.205 calls) is the plugin's #2 hottest
path after list-marker parsing — these toggles (and cycle-type detection)
drive it.

- [ ] `<A-->` on a **plain text line with no marker at all** → adds a `-`
      bullet. `<A-->` again → removes it (no marker required either way).
- [ ] `<A-*>` / `<A-0>` / `<A-c>` — same toggle behavior for `*` bullet,
      `1.` number, and `- [ ]` checkbox respectively.
- [ ] `3<A-->` (count) → widens the **scope** to the next 3 lines, each
      toggled independently — not "toggle this line 3 times" (would be a
      no-op for even counts; this is the count-audit fix from
      2026-08-24, per `docs/BINDINGS.md`).
- [ ] Visual-select several plain lines, `<A-->` → every line in the
      selection gets toggled independently (not a single shared marker).
- [ ] `<leader>cx` (`toggle_checkbox`) cycles an **existing** checkbox
      through its configured N-state cycle (default `[ ]`→`[x]`).

---

## 6. Word/boolean/number/date cycle — global, `<C-y>`/`<C-x>`/`+`/`-`

Global by design (`cycle.filetypes = nil`) — confirm this explicitly in a
non-prose buffer, since it's the surprise people miss in the other
direction (not expecting it to work outside Markdown).

- [ ] In a **`.lua` buffer** (not a list filetype), `<C-y>`/`<C-x>` on
      `true`/`false` or `on`/`off` cycles case-preservingly.
- [ ] `+`/`-` on the same word do the same thing; `+`/`-` on an arbitrary
      line with no date/group/number falls through to **native** Vim
      behavior (first non-blank of next/prev line) — confirm this reads
      as correct fallback, not a dead key.
- [ ] `+`/`-` on a plain integer → native `<C-a>`/`<C-x>` (number
      fallback), re-emitting any count (`3+` = `<C-a>` three times).
- [ ] `+`/`-` (or `<C-y>`/`<C-x>`) on an **ISO date** (`2026-08-30`) steps
      the day/month/year segment under the cursor with calendar rollover
      — `3<C-y>` on `2026-08-30` should give `2026-09-02`, not day 33.
- [ ] `<leader>cp` (`cycle_pick`) on a cycle-group word → `vim.ui.select`
      picker lists the group's values directly (Telescope-backed if
      registered).
- [ ] Operator flips: cursor on `==`, `&&`, `<`, `+` → `<C-y>`/`+` flips to
      `!=`, `||`, `>`, `-` respectively, matched by cursor **position**,
      not `iskeyword` (should work mid-operator, not just word-boundary).

---

## 7. Transpose — char/word/selection swap, global

- [ ] `<leader><Right>`/`<leader><Left>` on a character → swaps with its
      right/left neighbor, UTF-8 safe (test on a line with a multi-byte
      character, e.g. an emoji or accented letter, not just ASCII).
- [ ] `3<leader><Right>` → swaps 3 times in a row (count = repeat count,
      not "3 positions over" — confirm the distinction on a short word).
- [ ] `<leader><C-Right>`/`<leader><C-Left>` → same for the **word** under
      the cursor vs. its neighbor word.
- [ ] Visual-select a same-line span, `<leader><Right>` → swaps the
      selection with its right neighbor char/word as a block.

---

## 8. Form rotation, sort, reverse, strip — block/selection-wide

`docs/WORKFLOW.md` singles out rotation as the thing to reach for instead
of a `:s` substitution.

- [ ] `<leader>cf` (`rotate_form_next`) on a numbered checklist → rotates
      `1.` → `1. [ ]` → `- [ ]` → `-` one step per press, **existing
      checkbox states (`[x]`) preserved** across the rotation, ordered
      targets renumbered automatically.
- [ ] `<leader>cF` rotates backward through the same forms.
- [ ] `:Cascade! rotate` (bang on the **verb**, not the subcommand) →
      backward, same as `<leader>cF` — confirm `:Cascade rotate!` is
      **not** valid syntax (bang moved to the command name in the
      composer migration).
- [ ] `<leader>cs` (`sort`) / `:Cascade! sort` → sorts a list block A-Z /
      Z-A and renumbers if ordered.
- [ ] `<leader>cv` (`reverse`) → reverses block order + renumbers.
- [ ] `<leader>cX` (`strip_checkbox`) → strips `[ ]`/`[x]` from every line
      in the block, markers themselves stay.
- [ ] Each of the above also works range-aware from Visual mode on a
      selection, not just the list block at the cursor.

---

## 9. `:Cascade` user command surface

- [ ] `:Cascade <Tab>` → completes `rotate`, `sort`, `reverse`, `strip`,
      `indent`, `dedent`, `renumber`.
- [ ] `:Cascade indent 2` / `:Cascade dedent 2` (explicit level arg) with
      a Visual range → indents/dedents the whole range by 2 levels.
- [ ] Bang on an action that ignores it (`:Cascade! strip`,
      `:Cascade! indent`) → should simply no-op the bang, not error.

---

## 10. Feature toggles and `:checkhealth` differentiation

- [ ] `lists.features.rotate = false` (scratch config) → `<leader>cf` (if
      manually bound) becomes a true no-op, **not** just an unbound key —
      confirm the action itself refuses, matching the "turning a feature
      off vs. rebinding it" distinction in `docs/WORKFLOW.md`.
- [ ] `cycle.features.word = false` → `<C-y>`/`<C-x>` fall through to
      whatever native/other-plugin behavior would otherwise apply.
- [ ] `:checkhealth cascade` after a toggle → reports the domain's status
      accurately (though not yet per-individual-feature, per the docs —
      confirm that limitation still holds).

---

## 11. Treesitter precision (opt-in) and context menu (optional)

Lower priority — both are opt-in and have zero telemetry signal, but each
has a specific, documented failure mode worth seeing once.

- [ ] `lists.precision = "treesitter"` (scratch config), in a Markdown
      buffer with a fenced code block containing a line that looks like a
      list marker (`- flag` in a shell snippet, `# 1. note` in Python) —
      `<CR>`/quick-toggle on that line inside the fence should **not**
      trigger list behavior, unlike the `"off"` default which is blind to
      this.
- [ ] Same test on a filetype with **no** installed Treesitter parser —
      confirm it falls back to `"off"`-equivalent behavior via `pcall`
      rather than erroring.
- [ ] If a right-click menu host (`nvzone/menu` or similar) is wired into
      this config: right-click in a list buffer, confirm cascade's entries
      (checkbox, cycle type, renumber, rotate, sort, reverse, strip)
      appear and each fires the same action as its keymap. If no host is
      configured, `require("cascade.integrations.menu").items()` should
      still return a real table without erroring.
