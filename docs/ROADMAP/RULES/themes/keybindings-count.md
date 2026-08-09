# Keybindings: count-support audit (cross-plugin synthesis)

Synthesis of the per-plugin count-support audits (whether `2<leader>xy`,
`3<leader>xy`, ... `N<leader>xy` is respected). See each linked report's
"Keybindings-Audit" section for full file:line detail.

## Reference examples — count already done well

- **`dap.nvim` step keymaps (`<leader>ds`/`di`/`do`)** — the best example in the
  whole audit. A naive `for i=1,count do dap.step_over() end` would violate the
  DAP protocol (no new step request while the thread is still running).
  Instead the first step fires immediately, subsequent steps are chained via
  `dap.listeners.after.event_stopped`, with a hard `MAX_CHAINED_STEPS = 1000`
  cap and cleanup listeners on session termination. Zero overhead when
  count≤1 — from [dap.nvim](../plugins/dap.nvim.md)
  (`bindings/keymaps/init.lua:32-91`, `counted_step`).
- **`documentation.nvim` browser navigation** — `-`/`<BS>` (up) and `<C-o>`/`<C-i>`
  (history back/forward) use `vim.v.count1` directly; `+`/`_` (depth inc/dec)
  use `vim.v.count1` clamped to `[1,9]` so an invalid count can't produce an
  out-of-range value — from [documentation.nvim](../plugins/documentation.nvim.md)
  (`editor/browse/init.lua:1018-1176`).
- **`documentation.nvim` `j`/`k`** — deliberately *not* reimplemented, so native
  count and `scrolloff` behavior just work — the report calls this the
  strongest example of "don't rebuild what's already correct."
- **`fileops.nvim` cycle keymaps** (`<leader>nf`/`pf`/`nfn`/`pfn`/`nF`/`pF`/`NF`/`PF`)
  — all eight pass `vim.v.count1` straight to `cycle.navigate`; `3<leader>nf`
  jumps 3 files — from [fileops.nvim](../plugins/fileops.nvim.md)
  (`bindings/keymaps.lua:40-52`).
- **`github_stats.nvim` dashboard navigation** — `j`/`k` use `vim.v.count1`;
  `<C-d>`/`<C-u>` use raw `vim.v.count` (0 triggers its own default of 10
  lines — a deliberate choice of `count` over `count1`);
  `<C-f>`/`<C-b>` multiply page size by `vim.v.count1`; `Ngg`/`NgG` jump to
  repo index N (clamped), replicating native `gg`/`G` semantics inside a
  virtual (non-buffer-line) selection state — called "vorbildlich" — from
  [github_stats.nvim](../plugins/github_stats.nvim.md)
  (`bindings/keymaps.lua:58-127`).
- **`cascade.nvim` indent/dedent** (`<A-Right>`/`<A-Left>`) — a deliberate
  *double* count scheme: `N<A-Right>` = N sibling lines each raised one level;
  `N<leader><A-Right>` = one line raised N levels. The less common
  interpretation (levels) is deliberately moved behind `<leader>`, and both are
  documented explicitly rather than left as a silent divergence from vanilla
  Vim's "count = repeat" idiom — from [cascade.nvim](../plugins/cascade.nvim.md)
  (`init.lua:155-204`).
- **`nvim-config` `view_scroll.lua`** — reads `vim.v.count` explicitly, `0`
  falls back cleanly to "half window height." Best count-handling model in the
  config, though currently inactive/commented out — from
  [nvim-config](../nvim-config.md).
- **`language.nvim` translate operator-pending mapping** — inherits the
  following motion's count automatically (`3<leader>tww` = 3 words) via native
  Vim operator semantics, with zero manual `vim.v.count` handling needed — from
  [language.nvim](../plugins/language.nvim.md) (`bindings/keymaps/init.lua:1-67`).
- **`emojis.nvim` `<leader>et` (checkbox toggle)** — an unusual but sensible
  reinterpretation: `count > 1` in Normal mode expands the *scope* to the next
  `count` lines rather than repeating the toggle `count` times ("toggle 3
  lines" vs `3dd`-style repeat). Flagged as a documentation gap (only in code
  comments, not `BINDINGS.md`) rather than a design gap — from
  [emojis.nvim](../plugins/emojis.nvim.md) (`init.lua:70-84`).

## Missing but plausible — flagged in the reports

- `nvim-config`: `<leader>tn`/`tp` (tab next/prev) ignore `v:count` even though
  `:tabnext`/`:tabprevious` natively accept a count prefix; window-resize
  keymaps (`<S-h/l/j/k>`) use a fixed step of 5 instead of `v:count1 * 5`;
  `[q`/`]q`/`[l`/`]l` (quickfix/loclist nav) and `]w`/`[w` (Trouble workspace
  diagnostics) ignore count despite the underlying Ex-commands supporting it
  — from [nvim-config](../nvim-config.md).
- `cascade.nvim`: cycle (`<C-y>`/`<C-x>`), line move (`<A-Up>`/`<A-Down>`), and
  quick-toggle (`<A-->` etc.) in Normal mode have no count support, an
  inconsistency against the otherwise very deliberate indent/dedent count
  design — date-cycling in particular would benefit (`3<C-y>` = "+3 days") —
  from [cascade.nvim](../plugins/cascade.nvim.md).
- `markdown.nvim`: heading navigation (`<C-p>`/`[[`, `<C-f>`/`]]`, and the
  level variants), fold commands, and table-cell navigation (`]|`/`[|`) all
  read no count, though several (heading jumps, cell nav, level
  inc/dec) are classic count candidates — from
  [markdown.nvim](../plugins/markdown.nvim.md).
- `pickers.nvim`: `<leader>dp` (dir navigation) has no `vim.v.count1` hook even
  though the equivalent "N levels up" concept already exists via
  `:Pickers dir <number>` — a direct `2<leader>dp` would be a natural, small
  addition — from [pickers.nvim](../plugins/pickers.nvim.md).
- `spotlight.nvim`: none of its 7 mappings read `v:count`; `N]k`/`N[k`
  ("skip N occurrences") would be natural since `nav.lua` already encapsulates
  navigation — from [spotlight.nvim](../plugins/spotlight.nvim.md).
- `images.nvim`: `next`/`prev` (`<leader>in`/`ip`) and the redact-window `u`
  (undo last box) don't read `vim.v.count1` — `3<leader>in` (3 images forward)
  and `3u` (remove 3 boxes) would be natural — from
  [images.nvim](../plugins/images.nvim.md).
- `reposcope.nvim`: `nav_up`/`nav_down` move exactly one list entry per
  keypress; `3<Down>` for "3 entries" is flagged as plausible and absent — from
  [reposcope.nvim](../plugins/reposcope.nvim.md).
- `recommender.nvim`: no keymap reads count; a threshold-setting use
  (`N<leader>lr` → set threshold N) is suggested versus the current hardcoded
  `<leader>lrh` (threshold 5) — from [recommender.nvim](../plugins/recommender.nvim.md).
- `github_stats.nvim`: `cycle_sort`/`cycle_time_range` (`s`/`t`) could use
  count as "advance N steps" — not implemented — from
  [github_stats.nvim](../plugins/github_stats.nvim.md).
- `language.nvim`: the thesaurus-replace keymap could plausibly use count for
  direct Nth-suggestion selection (`3<leader>th`, analogous to `z=`) since a
  selection list already exists internally — not implemented — from
  [language.nvim](../plugins/language.nvim.md).
- `learn-cli.nvim`: `next_exercise`/`prev_exercise` never read `vim.v.count`;
  "skip N exercises" (`3<leader>lcn`) is a plausible, unimplemented extension —
  from [learn-cli.nvim](../plugins/learn-cli.nvim.md).
- `buffer-ctx.nvim`: `<S-m>` (toggle mark) ignores count; "mark N lines from
  cursor" is suggested as a plausible extension — from
  [buffer-ctx.nvim](../plugins/buffer-ctx.nvim.md).
- `emojis.nvim`: `:Emojis next` has no count-driven "jump N emoji forward" —
  from [emojis.nvim](../plugins/emojis.nvim.md).

## Explicitly justified "n/a" — not a gap

Most single-shot, toggle, or picker-launching actions correctly have no count
handling, and the reports are consistent about calling this out as *not* a
deficiency:

- Session save/load/list (idempotent, singular) — [sessions.nvim](../plugins/sessions.nvim.md).
- Opening any picker/UI (no iterable target) — [open.nvim](../plugins/open.nvim.md),
  [pickers.nvim](../plugins/pickers.nvim.md), [cmdlog.nvim](../plugins/cmdlog.nvim.md),
  [reposcope.nvim](../plugins/reposcope.nvim.md) (`<leader>rs`/`rc`).
- Container/image/volume list-view actions in [sandbox.nvim](../plugins/sandbox.nvim.md)
  — each acts on exactly one item under the cursor; the report notes
  Visual-mode multi-select is the better-fitting mechanism for "N items"
  here, not a count prefix.
- `filetree.nvim`: **no** keymap supports count meaningfully — "N items"
  is handled instead via marks (mark-then-act), a deliberate alternate UX — from
  [filetree.nvim](../plugins/filetree.nvim.md).
- `gopath.nvim`: all path-under-cursor actions (`gP`, `g|`, `g\`, `g}`, `gY`,
  `g?`, `gC`, `<leader>pp` probe) — no natural repeat semantics, since they
  act on "the one thing under the cursor," not a motion — from
  [gopath.nvim](../plugins/gopath.nvim.md).
- `debugging.nvim`: all five `:Debug`-view keymaps are one-shot toggles — from
  [debugging.nvim](../plugins/debugging.nvim.md).
- `diff.nvim`: `<Esc><Esc>` (exit diff mode) and `q`/`<Esc>` (close float) —
  pure toggle/exit, no repeat semantics — from [diff.nvim](../plugins/diff.nvim.md).

## General rule for when count support is worth adding

Drawn from the pattern across all reports:

1. **Count is worth adding when the action is inherently a motion, a
   step, or a scroll** — i.e. it has a natural "do this N times" or "move N
   units" reading that a user would expect from Vim muscle memory (navigation,
   debugger stepping, cycling through a list, scrolling, indent/dedent,
   date/word cycling). The stronger the resemblance to a native Vim motion or
   `j`/`dd`/`gg`-style command, the stronger the expectation that `count`
   works.
2. **Count is not worth adding — and its absence is not a gap — for:**
   single-shot toggles, picker/UI-launch actions, actions with no ordered
   target ("the file under the cursor," "all marked items"), and actions where
   a richer input already exists (an explicit numeric argument, a Range, or
   Visual-mode selection covers the "N items" case better than a count
   prefix would).
3. **When an action's target is inherently unordered or plural** (e.g.
   "toggle N items"), consider Visual-mode multi-select or a mark-then-act
   workflow as the idiomatic alternative to `count` rather than forcing count
   semantics onto it — this is the explicit design choice in
   [sandbox.nvim](../plugins/sandbox.nvim.md) and [filetree.nvim](../plugins/filetree.nvim.md).
4. **For asynchronous/stateful external actions** (debugger stepping, LSP
   requests), naive `for i=1,count do action() end` loops are unsafe if the
   underlying protocol requires strict request/response ordering — chain via
   the protocol's own completion event instead, with a hard upper bound. See
   [dap.nvim](../plugins/dap.nvim.md)'s `counted_step` as the reference
   implementation, and the idea (in [dap.nvim](../plugins/dap.nvim.md)'s "Ideen"
   section) to generalize this into a `lib.nvim.chained_action` helper.
5. **When two different count meanings are both plausible** (repeat count vs.
   depth/level count), pick the more common one for the bare key and move the
   rarer one behind `<leader>`, and document both explicitly rather than
   leaving a silent divergence — the [cascade.nvim](../plugins/cascade.nvim.md)
   indent/dedent precedent.
</content>
