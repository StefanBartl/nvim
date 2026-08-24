# Keybindings: count-support audit (cross-plugin synthesis)

> **Backlog, keine Regel.** Count-Support-Audit aus dem Code-Audit vom 2026-08-08:
> wo Count schon vorbildlich gelöst ist, wo er fehlt und plausibel wäre, und wo sein
> Fehlen begründet ist. Die daraus abgeleitete **allgemeine Regel** steht in
> `Checklists/regeln/LUA_NVIM.md` § UI und Bedienbarkeit → Count-Support (`UI-C*`).
> Hier steht nur die Lückenliste — abarbeiten und streichen.


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
  count≤1. **Hoisted into `lib.nvim.count.chain` on 2026-08-24** — use that
  rather than copying this, and use `lib.nvim.count`'s `get`/`raw`/`clamp`/
  `times` for the plain cases below — from [dap.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/dap.nvim.md)
  (`bindings/keymaps/init.lua:32-91`, `counted_step`).
- **`documentation.nvim` browser navigation** — `-`/`<BS>` (up) and `<C-o>`/`<C-i>`
  (history back/forward) use `vim.v.count1` directly; `+`/`_` (depth inc/dec)
  use `vim.v.count1` clamped to `[1,9]` so an invalid count can't produce an
  out-of-range value — from [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md)
  (`editor/browse/init.lua:1018-1176`).
- **`documentation.nvim` `j`/`k`** — deliberately *not* reimplemented, so native
  count and `scrolloff` behavior just work — the report calls this the
  strongest example of "don't rebuild what's already correct."
- **`fileops.nvim` cycle keymaps** (`<leader>nf`/`pf`/`nfn`/`pfn`/`nF`/`pF`/`NF`/`PF`)
  — all eight pass `vim.v.count1` straight to `cycle.navigate`; `3<leader>nf`
  jumps 3 files — from [fileops.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/fileops.nvim.md)
  (`bindings/keymaps.lua:40-52`).
- **`github_stats.nvim` dashboard navigation** — `j`/`k` use `vim.v.count1`;
  `<C-d>`/`<C-u>` use raw `vim.v.count` (0 triggers its own default of 10
  lines — a deliberate choice of `count` over `count1`);
  `<C-f>`/`<C-b>` multiply page size by `vim.v.count1`; `Ngg`/`NgG` jump to
  repo index N (clamped), replicating native `gg`/`G` semantics inside a
  virtual (non-buffer-line) selection state — called "vorbildlich" — from
  [github_stats.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/github_stats.nvim.md)
  (`bindings/keymaps.lua:58-127`).
- **`cascade.nvim` indent/dedent** (`<A-Right>`/`<A-Left>`) — a deliberate
  *double* count scheme: `N<A-Right>` = N sibling lines each raised one level;
  `N<leader><A-Right>` = one line raised N levels. The less common
  interpretation (levels) is deliberately moved behind `<leader>`, and both are
  documented explicitly rather than left as a silent divergence from vanilla
  Vim's "count = repeat" idiom — from [cascade.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/cascade.nvim.md)
  (`init.lua:155-204`).
- **`nvim-config` `view_scroll.lua`** — reads `vim.v.count` explicitly, `0`
  falls back cleanly to "half window height." Best count-handling model in the
  config, though currently inactive/commented out — from
  [nvim-config](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/nvim-config.md).
- **`language.nvim` translate operator-pending mapping** — inherits the
  following motion's count automatically (`3<leader>tww` = 3 words) via native
  Vim operator semantics, with zero manual `vim.v.count` handling needed — from
  [language.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/language.nvim.md) (`bindings/keymaps/init.lua:1-67`).
- **`emojis.nvim` `<leader>et` (checkbox toggle)** — an unusual but sensible
  reinterpretation: `count > 1` in Normal mode expands the *scope* to the next
  `count` lines rather than repeating the toggle `count` times ("toggle 3
  lines" vs `3dd`-style repeat). Was flagged as a documentation gap (only in
  code comments, not `BINDINGS.md`) rather than a design gap; **documented
  2026-08-24**. The reinterpretation itself is the reference — cascade.nvim's
  quick-toggle count follows it — from
  [emojis.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/emojis.nvim.md) (`init.lua:70-84`).

## Missing but plausible — flagged in the reports

- `nvim-config`: `<leader>tn`/`tp` (tab next/prev) ignore `v:count` even though
  `:tabnext`/`:tabprevious` natively accept a count prefix; window-resize
  keymaps (`<S-h/l/j/k>`) use a fixed step of 5 instead of `v:count1 * 5`;
  `[q`/`]q`/`[l`/`]l` (quickfix/loclist nav) and `]w`/`[w` (Trouble workspace
  diagnostics) ignore count despite the underlying Ex-commands supporting it
  — from [nvim-config](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/nvim-config.md).
- `spotlight.nvim`: none of its 7 mappings read `v:count`; `N]k`/`N[k`
  ("skip N occurrences") would be natural since `nav.lua` already encapsulates
  navigation — from [spotlight.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/spotlight.nvim.md).
- `reposcope.nvim`: `nav_up`/`nav_down` move exactly one list entry per
  keypress; `3<Down>` for "3 entries" is flagged as plausible and absent — from
  [reposcope.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/reposcope.nvim.md).
- `learn-cli.nvim`: `next_exercise`/`prev_exercise` never read `vim.v.count`;
  "skip N exercises" (`3<leader>lcn`) is a plausible, unimplemented extension —
  from [learn-cli.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/learn-cli.nvim.md).
## Explicitly justified "n/a" — not a gap

Most single-shot, toggle, or picker-launching actions correctly have no count
handling, and the reports are consistent about calling this out as *not* a
deficiency:

- Session save/load/list (idempotent, singular) — [sessions.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sessions.nvim.md).
- Opening any picker/UI (no iterable target) — [open.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/open.nvim.md),
  [pickers.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pickers.nvim.md), [cmdlog.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/cmdlog.nvim.md),
  [reposcope.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/reposcope.nvim.md) (`<leader>rs`/`rc`).
- Container/image/volume list-view actions in [sandbox.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sandbox.nvim.md)
  — each acts on exactly one item under the cursor; the report notes
  Visual-mode multi-select is the better-fitting mechanism for "N items"
  here, not a count prefix.
- `filetree.nvim`: **no** keymap supports count meaningfully — "N items"
  is handled instead via marks (mark-then-act), a deliberate alternate UX — from
  [filetree.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/filetree.nvim.md).
- `gopath.nvim`: all path-under-cursor actions (`gP`, `g|`, `g\`, `g}`, `gY`,
  `g?`, `gC`, `<leader>pp` probe) — no natural repeat semantics, since they
  act on "the one thing under the cursor," not a motion — from
  [gopath.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/gopath.nvim.md).
- `debugging.nvim`: all five `:Debug`-view keymaps are one-shot toggles — from
  [debugging.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/debugging.nvim.md).
- `diff.nvim`: `<Esc><Esc>` (exit diff mode) and `q`/`<Esc>` (close float) —
  pure toggle/exit, no repeat semantics — from [diff.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/diff.nvim.md).

