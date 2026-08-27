# Testing pickers.nvim

How to manually test pickers.nvim's real feature surface. Telemetry
(Workstation dataset, **253 accumulated sessions** — the highest session
count of any of these four plugins, confirming this is genuinely a daily
tool) shows only 52 instrumented calls total, dominated by `config.get`
(46, a support call every action makes, not a feature of its own) and a
thin but real signal on the history subsystem: `history.dir` 3,
`history.fzf_opts` 3. That thinness is itself informative — most of
`:Pickers`' real work happens inside the resolved engine's own picker
(snacks/telescope/fzf-lua internals), which pickers.nvim doesn't
instrument, so 253 sessions of heavy daily use produce very few
instrumented calls by design, not because the plugin is lightly used.
`docs/WORKFLOW.md` is unusually thorough here — its own §8 "Traps worth
knowing" table is lifted directly into several items below.

Repo: `E:\repos\pickers.nvim`. Spec: `lua/plugins/personal/init.lua`
(`lazy = false` — required, since setup() derives ~20 keymaps from the
`collections` table and lazy-loading on `keys` would mean hand-listing
every lhs a second time, per this config's own spec comment;
`dependencies = { "StefanBartl/lib.nvim" }`). This config sets
`engine = "snacks"` **explicitly** (not the plugin's own `"auto"`
default), 8 real `collections` (notes, notes_lua, notes_nvim, checklists,
spickzettel, wkdbooks, wkdbooks_lua, wkdbooks_nvim — each with its own
`files`/`grep`/(sometimes)`smart` keymaps), top-level
`keymaps = { cwd_smart = "<leader>cw", config_smart = "<leader>cf" }`
(both opt-in in the plugin defaults, enabled here), `history = { enabled =
true, fzf_scope = "patch" }`, and `keys = { preview_scroll_left =
"<M-Left>", preview_scroll_right = "<M-Right>" }` (overriding the plugin's
own `<C-Left>`/`<C-Right>` default, kept for muscle-memory compatibility
with this config's older `config.telescope.keymaps`).

## Setup

```vim
:checkhealth pickers
```

**Expect**: dependencies, detected/configured engine (should confirm
`snacks` specifically, not auto-detected), `rg`/`fd` availability, every
configured collection listed with its resolved root, and — per
WORKFLOW.md §9 — an explicit statement of which config surfaces have "no
effect for this engine" (see §1 below) rather than leaving you to
rediscover that from behavior.

---

## 1. `history` is configured but engine is `snacks` — confirm it's genuinely a no-op for `:Pickers`, and where it actually *does* land instead

**The single most concrete thing worth verifying against the docs.**
`docs/CONFIGURATION.md` states in plain terms: *"This `history` config has
no effect on snacks.nvim... snacks.picker's history is a built-in,
always-on feature of the picker core itself."* Since this config's
`engine = "snacks"`, the `history = { enabled = true, fzf_scope = "patch"
}` block should be **entirely inert** for every `:Pickers` invocation —
snacks always has its own per-source history regardless.

**But `fzf_scope = "patch"` is not pure dead weight here.** This config's
*separate* `lua/config/fzf/fzf_opts/init.lua` (feeding this config's own
independent `fzf-lua.setup()`, used directly via `:FzfLua` and by other
plugins' fzf-lua previewers, e.g. pdfport.nvim's) has its own comment:
*"History is owned by pickers.nvim (`history.fzf_scope = "patch"` in its
setup()), which patches fzf-lua's `fzf_opts["--history"]` itself."* That's
the real explanation for the telemetry hits on `history.dir`/
`history.fzf_opts` (3 calls each) despite `:Pickers` itself running on
snacks — the "patch" side-effect reaches fzf-lua's *own* setup, a
completely separate code path from anything `:Pickers` dispatches.

**Steps**

- [ ] `<C-p>`/`<C-n>` inside a snacks-backed `:Pickers cwd files` session —
  confirm snacks' own native history still works (it always does,
  regardless of this config), and that it is **not** reading/writing to
  `stdpath("data")/pickers.nvim/history/*` (that file only matters to
  telescope/fzf-lua).
- [ ] Open `:FzfLua files` directly (this config's independent fzf-lua
  setup, not `:Pickers`) and check its `<C-p>`/`<C-n>` history — confirm it
  shares the **same** history file pickers.nvim's `"patch"` mode installed,
  by searching the same thing in two separate `:FzfLua` sessions and
  confirming the second one's history recall includes the first's query.
- [ ] `:checkhealth pickers` — confirm it states the snacks/history
  no-effect fact explicitly (WORKFLOW.md's own claim about what the health
  check should say), rather than you having to infer it.

---

## 2. Collections — the actual daily namespace, all 8 of them

**Steps**

Try each collection's compat command and/or bound key at least once:

```
<leader>mnf / <leader>mng / <leader>mns    " notes
<leader>mlf / <leader>mlg                   " notes_lua
<leader>mvf / <leader>mvg                   " notes_nvim
<leader>chf / <leader>chg                   " checklists
<leader>spf / <leader>spg                   " spickzettel
<leader>wkf / <leader>wkg / <leader>wks     " wkdbooks (prefix = "wkdbook-")
<leader>wlf / <leader>wlg                   " wkdbooks_lua
<leader>wvf / <leader>wvg                   " wkdbooks_nvim
```

**Expect**: each opens a snacks picker rooted at that collection's `dir`.

- [ ] `<leader>wkf` (the `wkdbooks` collection, `prefix = "wkdbook-"`) —
  since it has a prefix, confirm it opens a **subdir picker first**
  (matching directories starting `wkdbook-`), *then* runs files inside
  whatever you picked — one definition covering multiple actual repos, per
  WORKFLOW.md §7, not a direct files-in-`WKDBooks` search.
- [ ] The equivalent PascalCase compat command for one collection, e.g.
  `:NotesFiles`/`:NotesGrep`/`:NotesSmart` — should behave identically to
  its bound key.
- [ ] `:PickersScopes` — confirm all 8 collections appear, each with its
  real resolved root directory, alongside the built-in scopes.

---

## 3. `smart` — the flagship combined action, and its `both`-bonus

**Enabled here via `<leader>cw` (cwd) / `<leader>cf` (config)** — both
opt-in in the plugin defaults, both bound in this config. `frecency` and
`dedup_grep_rows` are **not** overridden, so both stay at their plugin
defaults (off) — ranking here is pure `weights` (filename 1.0, content
1.0, both 25), no recency boost.

**Steps**

`<leader>cw`, type a query that matches **both** a filename and file
content somewhere in this repo — e.g. a word that's both in a Lua module's
name and mentioned in its own comments.

**Expect**: that file floats to the top of the merged, ranked list (the
`both = 25` flat bonus), rather than appearing as two separate
filename/content entries.

- [ ] Type a query matching **only** file content (a string literal, not
  part of any filename) — confirm it still surfaces via the grep half.
- [ ] Type a query matching **only** a filename fragment — confirm it
  surfaces via the fd half, with no phantom grep hits.
- [ ] A file with many matching content lines — since `dedup_grep_rows =
  false` here (plugin default, unmodified), confirm **every** matching
  line from that file appears as its own row, potentially crowding the
  list — this is the documented default behavior, not a bug; compare
  mentally against what `dedup_grep_rows = true` would collapse it to.
- [ ] `<leader>cf` (config scope) on a query you know exists in this nvim
  config's Lua — same dual-source ranking, scoped to `stdpath("config")`.

---

## 4. Default (always-on) keymaps

**Steps**

```
<leader>dp     " :Pickers dir — nav picker, count = depth
<leader>.      " :Pickers builtin explorer — snacks native tree (engine = snacks here)
<leader>fb     " :Pickers folder files
<leader>fc     " :Pickers config files
<leader>gc     " :Pickers config grep
<leader>li     " :Pickers cwd grep
```

**Expect** each opens the documented picker.

- [ ] `2<leader>dp` — a **count is the depth**: should open the nav picker
  two directories above cwd, not "2 of something else." Try `1<leader>dp`
  and bare `<leader>dp` too, confirm the count genuinely changes the
  starting point.
- [ ] `<leader>.` — since `engine = "snacks"` here, this should give a real
  native tree explorer (per WORKFLOW.md §4, snacks is the one engine with
  a genuine explorer; telescope needs `telescope-file-browser.nvim`,
  fzf-lua has none at all) — confirm you can walk directory structure, not
  just a flat file list.

---

## 5. In-picker keys — the `<M-Left>`/`<M-Right>` override, and what else is patched

**This config overrides the horizontal preview-scroll keys away from the
plugin default** (`<C-Left>`/`<C-Right>` → `<M-Left>`/`<M-Right>`) to keep
muscle memory from the old `config.telescope.keymaps` module.

**Steps**

Open any picker with a preview pane (`<leader>li`, or `<leader>cwf` for a
files picker with a preview), on an entry whose preview is wider than the
pane:

- [ ] `<M-Left>`/`<M-Right>` scrolls the preview horizontally — confirm the
  *default* `<C-Left>`/`<C-Right>` does **not** (it was overridden, not
  added alongside).
- [ ] `<PageDown>`/`<PageUp>` — vertical preview scroll, untouched default,
  should still work.
- [ ] `<C-p>`/`<C-n>` inside the picker prompt — per §1, this is snacks'
  own native history here, not pickers.nvim's `history.*` config; confirm
  it does something (snacks always has history) even though the plugin's
  own `history` setting is inert for this engine.
- [ ] `<S-CR>` or `<C-o>` (`open_background`) on a file entry — should
  preload the buffer (`bufadd`+`bufload`) **without** moving focus or
  opening a window (this config doesn't set `keys.open_background_show`,
  so it stays at the off-by-default "preload only" behavior) — confirm
  with `:ls` that the buffer is now listed, but the window layout hasn't
  changed.
- [ ] `<C-s>`/`<C-v>`/`<C-t>` on an entry — split/vsplit/tab open,
  confirmed working the same way regardless of preview-scroll overrides
  (unrelated translation-table entries).

---

## 6. `:Pickers builtin <name>` — the 52-entry registry

**Steps**

```vim
:Pickers builtin <Tab>
```

**Expect**: the full registry, tab-completable — don't guess a name, per
WORKFLOW.md §5.

- [ ] `:Pickers builtin git_branches`, `:Pickers builtin lsp_definitions` —
  both should dispatch straight into snacks' native picker for that
  concept.
- [ ] A **snacks-only** entry, e.g. `:Pickers builtin lazy_specs` or
  `:Pickers builtin notifications` — confirm it works here (engine is
  snacks) — then, only if you want to see the documented gap, temporarily
  force telescope via the Lua API (`pickers.command.handle({ fargs =
  {"builtin","lazy_specs"}, engine = "telescope" })`) and confirm it warns
  about the missing telescope equivalent rather than erroring blankly.
- [ ] `:PickersResume` (= `:Pickers builtin resume`) — should reopen the
  last picker with its typed prompt intact, since snacks supports resume
  (unlike fzf-lua's documented no-op there).

---

## 7. `:PickersRepeat` vs `:PickersResume` — genuinely different, confirm both

**Steps**

1. `<leader>li`, type a query, dismiss with `<Esc>` (don't select
   anything).
2. `:PickersRepeat` — should reopen the **same resolved scope/action**
   (cwd grep) with an **empty** prompt, not your dismissed query.
3. `<leader>li` again, type a **different** query, dismiss with `<Esc>`.
4. `:PickersResume` — should reopen with that **exact query text still
   in the prompt**, cursor where you left it.

**Expect**: step 2 and step 4 visibly differ — confirm you don't mix them
up going forward. Also try `:PickersRepeat` right after a `dir`-scope
picker (e.g. `<leader>dp` → pick something) — WORKFLOW.md states `dir` is
included in what `:PickersRepeat` can replay, unlike `mappings`'
declarative-keymap surface, which explicitly excludes `dir`.

---

## 8. Search-flag escalation (`hidden`/`no_ignore`/`follow`/`all`)

**No dedicated keymap bound in this config** (`cwd_find_all` stays `nil`,
the plugin default) — test via the command directly.

**Steps**

```vim
:Pickers cwd files hidden
:Pickers cwd files hidden+follow
:Pickers cwd files no_ignore
:Pickers cwd files all
```

**Expect**: `hidden` alone reaches dotfiles but still respects
`.gitignore`; `no_ignore` alone reaches ignored files but not dotfiles;
`all` is all three combined. Confirm they're genuinely different result
sets, not all producing the same list.

- [ ] `:Pickers cwd grep all` — per docs, `all` should be silently ignored
  here (live grep already searches `--hidden --no-ignore-vcs`
  unconditionally) — confirm no error, no behavior change vs. plain
  `:Pickers cwd grep`.
- [ ] An unknown flag, e.g. `:Pickers cwd files bogus` — should be reported
  and the escalation dropped, not silently applied in part.

---

## What this checklist does not cover in depth

`dir` scope's `path=`/named `depth_aliases` nav forms beyond the basic
count-as-depth case in §4 (same mechanism, just more argument shapes).
`mappings` (the declarative per-entry engine-override surface) — not used
in this config (only the fixed `keymaps.*`/collection `keys.*` fields
are). `repos`/`wkdbooks`/`system`/`drives` built-in scopes and the
`repos_files`/`repos_grep`/`system_files` keymaps — all opt-in and left
unbound in this config (collections cover the equivalent daily need
instead). `create_file`/`open_background`'s manual-merge requirement for a
from-scratch engine setup — not applicable here since this config already
uses pickers.nvim's own patched setup path.
