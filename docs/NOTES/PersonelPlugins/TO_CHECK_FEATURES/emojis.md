# Testing emojis.nvim

How to manually test every implemented feature of `emojis.nvim` — a single
`:Emojis` command tree covering clear/count/list/replace/unreplace/wrap
across scopes (line, word, visual, whole buffer, project-wide via
ripgrep), an insert picker and a quick-insert overlay, cursor navigation
between emoji, and an emoji-checkbox cycle. One-time setup, then one
section per feature: steps, expected result. Checkbox syntax (`- [ ]`) is
standard Markdown.

Repo: `E:\repos\emojis.nvim`. Spec: `plugins/personal/init.lua` —
`cmd = "Emojis"` (command-lazy), `opts = {}` with a comment noting
`default_scope` is already `"%"` (whole buffer) so nothing extra is
needed there. **No `keymaps` table is set**, so `keymaps.preset` stays at
its own default `false` — none of `docs/BINDINGS.md`'s preset keys
(`<C-e>`, `<leader>ee`, `<leader>et`, `<leader>ec`, `<leader>el`) are bound
in this config. Every test below goes through `:Emojis` directly.

## Setup

No `:checkhealth emojis` is documented — the plugin has no external
dependencies beyond `lib.nvim` (required: `:Emojis` is built on
`lib.nvim.bindings.usercmd.composer`). Confirm it loaded:

```vim
:Emojis count %
```

on any buffer with a few emoji in it should print a real count. A quick
test buffer:

```
- [ ] task one 🔲
- [x] task two ✅
some text 🚀 with an emoji 🔥 mid-line and a ⚠️ VS16 one
```

---

## 1. `clear` / `count` / `list` across scopes — the core action

**Why first**: `clear %` is the plugin's own documented default (bare
`:Emojis` = `:Emojis clear %`), and it's the action every other scoped
command shares its scope-resolution code with. Telemetry is thin here (7
sessions total on this machine) but `core.ops.clear`/`core.scope.resolve`
each show 18 real calls — small but genuine signal this path gets
exercised, unlike the render hot path (`core.patterns.match_at`, 75.859
calls / 98% of the plugin's total) which this file's own methodology
explicitly excludes as a priority signal.

- [ ] `:Emojis` (bare, no args) → clears every emoji in the **whole
      buffer** (`= clear %`).
- [ ] `:Emojis clear line` → only the cursor line's emoji removed, rest of
      the buffer untouched.
- [ ] `:Emojis clear word` with the cursor inside `🚀`-adjacent text →
      clears just the contiguous, whitespace-free chunk under the cursor.
- [ ] `:'<,'>Emojis clear` (explicit Visual range) → the **range**
      overrides any scope keyword; confirm this by giving a range on a
      line that also has emoji outside the range and confirming only the
      ranged emoji are touched.
- [ ] **The double-space fix** — clear an emoji surrounded by single
      spaces (`"a 🚀 b"`) → result should be `"a b"` (one space), **not**
      `"a  b"` (two) — the old-version bug this plugin explicitly fixed.
- [ ] **VS16 handling** — clear a line containing `⚠️` (warning + VS16
      variation selector) → counts and removes as **one** emoji, not two.
- [ ] `:Emojis count %` / `:Emojis list %` → count matches the number of
      quickfix entries `list` produces for the same buffer/scope exactly.
- [ ] `preview.enable = true` (scratch config), `:Emojis clear %` on a
      buffer with several emoji → each one briefly highlights (~150ms)
      before removal — confirm this actually flashes rather than being a
      no-op with the option on.

---

## 2. `replace` / `unreplace` — round-trip fidelity

- [ ] `:Emojis replace %` on the test buffer → every emoji becomes a
      `:name:` placeholder (confirm `⚠️` becomes a single `:warning:`-style
      placeholder, not two separate ones for the base emoji and the VS16
      modifier — the same double-counting bug `clear`/`count` had, fixed
      here too per `docs/commands.md`).
- [ ] `:Emojis unreplace %` immediately after → every placeholder reverts
      to its original emoji glyph. Round-trip the whole buffer and diff
      against the original — should be byte-identical.
- [ ] `:Emojis wrap %` → emoji get surrounded by the configured marker
      (default `[[ ]]` per the usage examples) **without being removed** —
      confirm the emoji itself is still present, just bracketed.

---

## 3. `toggle` — the emoji checkbox cycle, line-scoped by design

`docs/WORKFLOW.md` is explicit this is a deliberate design choice, not a
missing feature (no `%`/`word`/`cwd` scope) — worth testing the range
behavior specifically since it's easy to misread as a limitation.

- [ ] `:Emojis toggle` on the `- [ ] task one 🔲` line → cycles the
      configured checkbox set's glyph one step forward (`🔲` → `✅` per the
      default two-state set).
- [ ] `:Emojis! toggle` (bang = backward) on the now-`✅` line → cycles
      back to `🔲`.
- [ ] `:5,12Emojis toggle status` (explicit line range **and** an explicit
      set name) → cycles just the `status` set on lines 5-12, confirming
      both the range-not-scope behavior and that naming a set narrows
      which glyph gets matched on a line with more than one candidate.
- [ ] `:'<,'>Emojis toggle` (Visual range, no set given) → cycles every
      configured set's first match per line — on a multi-line selection
      where different lines have different glyphs, confirm each line
      cycles the set that actually matches on *that* line, not a single
      set applied uniformly.
- [ ] **The count-widens-scope behavior** (documented, not obvious from
      the name): if the preset keymap were bound, `3<leader>et` would
      widen scope to 3 lines, not repeat the toggle 3 times — since no
      keymap is bound in this config, exercise the equivalent directly via
      a 3-line range (`:.,.+2Emojis toggle`) and confirm each of the 3
      lines toggles independently.
- [ ] The glyph is found **anywhere on the line**, not just under the
      cursor — put the cursor at end-of-line text (not on the glyph) and
      confirm `:Emojis toggle` still finds and cycles it.

---

## 4. `insert` and `overlay` — the two pickers, and how they differ

Telemetry shows `actions.edit` at 18 calls — real, if thin, evidence this
path gets used; `docs/WORKFLOW.md` frames the two pickers as solving
different problems (full-catalog search vs. muscle-memory grid), which is
the distinction worth actually confirming rather than assuming they're
interchangeable.

- [ ] `:Emojis insert` → a searchable picker (Telescope/fzf-lua if
      available, else `vim.ui.select`) over the **full** catalog (60+
      entries) opens at the cursor; search by a name fragment ("warning",
      "bug") and confirm fuzzy matching finds it, then confirm selecting
      one inserts it exactly at the cursor position.
- [ ] `:Emojis overlay` (no mode arg, defaults to `config.overlay.mode`) →
      a small float with ~20 curated glyphs. `h`/`j`/`k`/`l` or arrows
      move, `<CR>` inserts, `<Esc>`/`q` closes without inserting.
- [ ] `:Emojis overlay grid_keys` → same grid, but confirm a **single
      keypress** per cell inserts directly, no `<CR>` needed.
- [ ] `:Emojis overlay list` → one glyph per row with its shortcode via
      the `lib.nvim` kit chooser, instead of the 2D grid.
- [ ] Insert the **same** glyph from the overlay 3-4 times in a row
      (frecency is on by default), close and reopen the overlay → confirm
      that glyph has moved toward the front of the grid — the reordering
      is real, not cosmetic.
- [ ] Confirm the overlay **never adds** a glyph you didn't configure in
      `overlay.picks` — it only ever reorders the configured set, however
      often you use something outside it via `insert`.

---

## 5. `first` / `next` — cursor navigation

- [ ] `:Emojis first` on a buffer with several emoji, cursor anywhere →
      jumps to the first emoji in the buffer (by buffer position, not
      cursor-relative).
- [ ] `:Emojis next` from that position → jumps to the next one; run it
      repeatedly past the last emoji in the buffer → **wraps** back to the
      first, doesn't error or stop.
- [ ] `:Emojis next 3` → jumps 3 emoji forward in one call — confirm this
      is a positional argument (three emoji onward), and separately that
      `:3Emojis next` (a **command count/address**, `:3` before the
      command name) does something different (addresses line 3), not the
      same "jump 3 forward" behavior — this exact ambiguity is called out
      in `docs/BINDINGS.md`.

---

## 6. Project-wide `cwd` scope — `list` before `clear`/`replace`, always

`docs/WORKFLOW.md` calls this "the one action pair where skipping the dry
run has real consequences" — worth testing the safety behavior
specifically, not just that the async search works.

- [ ] `:Emojis list cwd` in a real project with emoji scattered across a
      few files → quickfix list populated with real `file:line` entries
      (async via ripgrep — give it a moment on a larger repo).
- [ ] `:Emojis count cwd *.md` → count restricted to Markdown files only
      (the glob passed through to ripgrep as an extra filter) — confirm
      it's genuinely narrower than an unfiltered `count cwd`.
- [ ] `:Emojis clear cwd` → a confirmation dialog appears **before** any
      file is touched, default answer **cancel**. Confirm cancelling
      truly changes nothing on disk.
- [ ] **The open-but-unsaved-buffer trap**: open one of the target files
      in a buffer, make an unsaved edit (don't write it), then run
      `:Emojis clear cwd` and confirm. Expect the summary to report that
      file as **"skipped"** — its emoji should still be present, both in
      the buffer and on disk — while every other matching file gets
      cleared normally. This is documented as a safety feature, not a
      bug: confirm it behaves exactly this way rather than silently
      overwriting the buffer or silently skipping without reporting it.
- [ ] `:Emojis! clear cwd` (bang) → forces `--no-ignore` for that one
      call, reaching gitignored files, **without** having changed
      `search.no_ignore` in the config — confirm a `.gitignore`d file with
      emoji in it gets touched this way but not by a plain (non-bang)
      `clear cwd`.

---

## 7. `cascade_groups()` bridge (only if cascade.nvim is also active)

`docs/WORKFLOW.md` frames this as "one vocabulary, two cycling styles" —
worth a quick cross-check if `cascade.nvim` is installed in this config
(it is — see `cascade.md` in this same folder).

- [ ] `require("emojis").cascade_groups()` wired into cascade's
      `cycle.groups` (scratch config addition) → on a line with a
      checkbox glyph, cascade's `<C-y>`/`<C-x>` (cursor-precise) should
      cycle the **same** glyph set `:Emojis toggle` (line-scoped) uses —
      confirm both land on the identical next/previous glyph for the same
      starting state, since they read from one shared `checkbox.sets`
      table.

---

## 8. Tab completion and the `!` bang's two disjoint meanings

- [ ] `:Emojis <Tab>` → completes `clear count first insert list next
      overlay replace toggle unreplace wrap`, alphabetical.
- [ ] `:Emojis clear <Tab>` → completes `word line visual % cwd`.
- [ ] `:Emojis overlay <Tab>` → completes `grid grid_keys list` instead
      (a different completion set for the same argument position).
- [ ] `:Emojis toggle <Tab>` → completes the **configured**
      `config.checkbox.sets` names, not a fixed list — confirm it reflects
      any custom sets if `config.checkbox.sets` has been changed from
      default.
- [ ] Confirm the bang's two meanings stay genuinely disjoint: `:Emojis!
      toggle` reverses direction (checkbox context), `:Emojis! clear cwd`
      forces `--no-ignore` (cwd-search context) — there's no third
      action where `!` would be ambiguous between the two.
