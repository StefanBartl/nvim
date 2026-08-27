# Testing recommender.nvim

How to manually test every implemented feature of `recommender.nvim`.
One-time setup, then one section per feature: prerequisites, steps, what to
expect.

Repo: `E:\repos\recommender.nvim`. Spec: `plugins/personal/init.lua`
(`ft = { "lua" }`, `cmd = { "Recommender" }`, `opts = {}` — lazy-loaded on
either a Lua buffer or the first `:Recommender` call, whichever comes
first). Pairs with `replacer.nvim` (both `"dir"` in `source.lua`, so both
load locally) for replace mode — see §6.

## Setup

```vim
:checkhealth recommender
```

**Expect**: Neovim >= 0.9 OK, `lib.nvim.bindings.usercmd.composer` found
(hard dependency — no `:Recommender` at all without it), Lua Tree-sitter
parser found/not-found (gates `analyzer = "treesitter"` only, not the
plugin as a whole), `float_layout` echoed, plugin-loaded guard set,
which-key optional, keymaps enabled/disabled, and — worth checking
specifically — `:Replace command found` since `replacer.nvim` is loaded in
this config (§6 depends on this line reading OK, not the fallback info).

A good test target: `recommender.nvim`'s own repo (real Lua, real repeated
`vim.api`/`vim.fn` chains) or any other Lua-heavy personal plugin.

**Telemetry note**: only 82 accumulated sessions with a near-flat spread
across entry points (`float.rendering.open/close/is_open` at 3-5 calls
each, `project.find_files/read_lines/supports_cwd` at 3 each) — too thin
to rank sub-features against each other. `blacklist.is_blacklisted` shows
46.8k calls (100% of the plugin's telemetry) but that's a per-candidate-chain
hot path inside every single analysis run, not a feature entry point — see
`lua/recommender/blacklist.lua`, called once per chain found regardless of
which analyzer or scope you used. Ordering below follows the README/
WORKFLOW's own "most sessions don't need a flag" framing plus what little
the entry-point telemetry does show (cwd/path scope was exercised a few
times, not zero).

---

## 1. Default invocation — `:Recommender` / `<leader>lr`

**Steps**

1. Open a Lua file with a few repeated chains (e.g. three or more
   `vim.api.nvim_buf_...` calls, or just open this plugin's own
   `lua/recommender/project.lua`).
2. `:Recommender` (or `<leader>lr`).

**Expect**: a floating picker (`lib.nvim.ui.kit.select` under the hood)
listing chains that repeat at least `threshold` (default `3`) times, each
suggestion showing the chain, hit count, and generated alias
(`"detailed"` layout: 3 lines per entry). `j`/`k` navigate one *logical*
suggestion at a time. `Enter` inserts the highlighted alias declaration
into the buffer that was active when you ran the command. `A` inserts
**all** visible aliases at once — per WORKFLOW.md this is the recommended
default over walking the list one at a time.

**Also check the toggle**: run `:Recommender` again while the float is
open — it should just close, no second float stacking on top.

---

## 2. Non-buffer scopes — `cwd`, `path`, `cfile`, `line`

**Steps**

```vim
:Recommender cwd
:Recommender path
:Recommender cfile      " cursor on a filename first
:Recommender line
```

**Expect**:
- `cwd` — scans every `*.lua` file under `getcwd()` (skip-list
  `.git`/`node_modules`/`.venv`/etc. from `cwd_ignore`), aggregates counts
  across all of them. If the repo has more than `cwd_max_files` (default
  500) matching files, expect a warning naming that config key.
- `path` — same scan, rooted at the **current buffer's own directory**
  instead of `cwd`. On an unnamed buffer, expect a clear error ("path
  scope requires the current buffer to have a file path"), not a crash.
- `cfile` — resolves the filename under the cursor via the same order
  `gf` uses (as typed → buffer-relative → `'path'`); error if nothing
  file-like is under the cursor.
- `line` — scans only the current line; threshold silently defaults to
  `1` here (not `config.threshold`) since a single line can only ever
  produce one hit per chain — confirm a chain appearing once on that line
  still surfaces a suggestion.

**The concrete trap to verify** (documented in WORKFLOW.md, not obvious
from the command alone): run `:Recommender cwd` from one buffer, then
press `A` — the aliases still get inserted into **that** buffer, not
wherever the chain actually occurred. Deliberately run `cwd` from a buffer
that barely uses any of the suggested chains and confirm `A` still dumps
them all in there — this is a real, sharp-edged behavior, not a bug, but
worth seeing once before it surprises you for real.

**Also check the hard error**: `:Recommender treesitter cwd` (or `path`/
`cfile`/`line`) — should fail immediately naming the analyzers that *do*
support non-buffer scope (`regex, javascript, python, perf`), never
silently fall back to buffer scope.

---

## 3. Analyzer override — `treesitter` / `javascript` / `python`

**Steps**

```vim
:Recommender treesitter    " needs the Lua TS parser, in a .lua buffer
:Recommender javascript    " in a .js/.ts buffer or via cwd/path scope
:Recommender python        " in a .py buffer or via cwd/path scope
```

**Expect**: same float, real chain suggestions from that language's own
dotted-chain conventions (`treesitter` should catch chains a naive regex
might miss inside strings/comments, since it parses the real AST — worth
comparing its suggestion count against `regex`'s on the same buffer once).
`treesitter.lua` should only be `require`d the first time you actually
pick it — confirm no error if the Lua TS parser is missing and you never
select `treesitter` at all.

---

## 4. `perf` analyzer — Lua anti-patterns

**Steps**

Write a small scratch `.lua` buffer with a `for` loop containing
`table.insert(t, v)`, a `for _, v in ipairs(t) do`, an `s = s .. chunk`
accumulator, and a `string.format(...)` call inside a loop. Then:

```vim
:Recommender perf 1
```

**Expect**: each of the four patterns flagged, one suggestion per
occurrence (the `1` threshold shows every instance regardless of count —
this analyzer's `threshold` means "how many instances exist", not a
repetition cutoff like the other analyzers). `Enter`/`A` insert a plain
`-- perf: ...` comment above/at the flagged line, never an automatic code
rewrite — confirm nothing outside a comment actually changes.

**Worth checking the known false-positive surface**: put one of the four
patterns inside a `--[[ ... ]]` comment or a string literal — per
`FEATURES.md` this is a "lightweight line-based block tracker, not a real
parser," so it can misfire there. Confirm whether it does (this is
exactly the kind of thing worth a real look rather than trusting the
doc's caveat blindly).

---

## 5. Threshold forms — positional, `--threshold=N`, count-prefixed keymap

**Steps**

```vim
:Recommender regex 5
:Recommender regex --threshold=5
:Recommender -t 5
```
then, on a keymap:
```
5<leader>lrr
```

**Expect**: all four produce the same threshold-5 regex run. Then try
`:Recommender regex --threshold=3 5` — the flag should win over the
positional `5`. Confirm a bare `<leader>lrr` (no count) uses
`config.threshold`, not `1` — the code path distinguishes "no count typed"
from "count of 1" via `v:count`, worth a specific check since a `<cmd>...`
mapping (which this deliberately isn't) would swallow the count silently.

---

## 6. Replace mode — `-r` / `<leader>lR`

**Prerequisites**: `replacer.nvim` providing `:Replace` (already loaded in
this config — confirm via `:checkhealth recommender`'s "`:Replace` command
found" line from Setup above).

**Steps**

```vim
:Recommender -r
```
Pick a suggestion, `<CR>`.

**Expect**: this runs `:Replace <chain> <alias> %` first (a Telescope-style
prompt appears via replacer.nvim), and only *after* that prompt's window
closes does the `local alias = chain` declaration get inserted — confirm
the insert genuinely waits for the replace to finish, not both firing at
once. The detection is a one-shot `WinClosed` autocmd keyed specifically
on a `TelescopePrompt`-filetype window (`lua/recommender/float/autocmds.lua`)
— if you ever swap `replacer.nvim`'s `engine` option away from
`"telescope"` (it's currently set to `"telescope"` in this config's
`opts`), this detection would silently stop firing. Worth a mental note,
not necessarily a thing to test today unless you've changed that option.

**Also check**: temporarily rename `:Replace` unavailable (or test in a
scratch config without replacer.nvim) — replace mode's `Enter` should have
nothing to drive and never insert the alias at all (chained behind the
replace finishing, not run unconditionally per WORKFLOW.md) — confirm this
degrades quietly rather than erroring.

---

## 7. Per-buffer ignore — `Backspace` / `U`

**Steps**

1. `:Recommender`, `Backspace` on one suggestion.
2. Close and reopen `:Recommender` on the **same** buffer.
3. Open a **different** buffer with the same chain, `:Recommender`.
4. Back in the first buffer, `:Recommender`, `U`.

**Expect**: step 2 — the dismissed suggestion stays gone (session-scoped
per buffer). Step 3 — the same chain still shows up in the other buffer
(ignore is not global). Step 4 — `U` restores it in the first buffer.

---

## 8. Blacklist and custom aliases (config)

**Steps**

```lua
require("recommender").setup({
  blacklist = { "vim.fn" },
  custom_aliases = { ["vim.keymap.set"] = "km_set" },
})
```
then `:Recommender` on a buffer using both `vim.fn.*` and
`vim.keymap.set`.

**Expect**: no `vim.fn.*` chain ever suggested (prefix match — blocks
`vim.fn`, `vim.fn.expand`, `vim.fn.system`, everything under it), and
`vim.keymap.set` suggested with alias name `km_set` rather than the
auto-generated default. This is the permanent, cross-buffer counterpart
to §7's session-only ignore — confirm the two don't get confused (a
blacklisted chain should never even appear to be dismissed with
`Backspace`, since it's already filtered out).

---

## 9. Float layout — `"detailed"` vs `"compact"`

**Steps**

```lua
require("recommender").setup({ float_layout = "compact" })
```
`:Recommender` with `threshold = 2` on a large file or a `cwd` scan.

**Expect**: one line per suggestion instead of three. `j`/`k` still move
suggestion-by-suggestion (not line-by-line) — confirm this holds in
compact mode specifically, since detailed mode's 3-line grouping makes
this easy to get right by accident and compact's 1-line grouping is the
real test of the "logical suggestion" navigation logic.

---

## 10. Keymap configurability

**Steps**

```lua
require("recommender").setup({
  keymaps = { regex = "<leader>zr", python = false },
})
```

**Expect**: `<leader>zr` now runs the regex analyzer (old default
`<leader>lrr` for regex should be gone unless also declared), and the
`python` binding is entirely absent. Try a deliberately misspelled action
name (`{ regeex = "<leader>x" }`) — should report the mistake rather than
silently binding nothing, per `BINDINGS.md`.

Same check for `float_keymaps = false` — open the float, confirm `y`/`A`/
`Backspace`/`U` no longer do anything, and `?` reflects only what's
actually bound (not the full default list).
