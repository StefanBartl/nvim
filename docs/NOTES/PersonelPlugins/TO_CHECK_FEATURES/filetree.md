# Testing filetree.nvim

How to manually test filetree.nvim's real feature surface. filetree.nvim
ships 50+ opt-out features (`lua/filetree/features/<category>/<name>/`);
this checklist does not walk all of them one by one — it prioritizes by
what this config actually turns on/off and by what telemetry shows is
genuinely exercised, then covers the rest at a level matched to how much
each one differs from "it's a toggle, it either works or it doesn't."

Repo: `E:\repos\filetree.nvim`. Spec: `lua/plugins/personal/init.lua`
(`event = "VeryLazy"` — must load after neo-tree's own `config()` runs;
`dependencies = { "StefanBartl/lib.nvim", "nvim-neo-tree/neo-tree.nvim" }`).
This config's `setup()` call is not the plugin's bare defaults — it
explicitly sets: `adapter = "neotree"`, `cwd_sync = { enabled = true,
reveal = false }` (cwd_sync is opt-in and off by default upstream — this
config turns it **on**), `cwd_mode.indicator.enabled = false` with
`labels.follow = "FOLLOW"` (the mode badge is rendered externally, by this
config's own statusline component, not filetree's in-tree float),
`current_hl = { enabled = true, icon = "▸" }` (opt-in, on here),
`handle_guard = { enabled = true }` (opt-in, on here — Windows-specific),
`window_style = { statusline = false, highlights_isolate = true }`. Trash
and `watcher_quarantine` are already on by default and just re-asserted in
the config comments.

Telemetry (Workstation dataset, 50 sessions) is dominated by
`features.nav.cwd_mode.*` (`badge` 86,821 calls — same figure as the raw
`feature`/dispatch counter, `resolve` 4,813, `pinned` 4,591,
`refresh_indicator` 4,004) and `features.ui.breadcrumbs.update` (4,136) —
both render on every relevant redraw, not on a deliberate keypress, but
their sheer share of all calls confirms `cwd_mode` and `breadcrumbs` are
the two features actually live and interacted with in daily use, which is
why they lead this checklist. `adapter.neotree.*` (`is_open`,
`get_winid`, `get_current_node`, `refresh`, …) are support calls other
features make, not their own entry points — not useful as a priority
signal on their own.

## Setup

```vim
:checkhealth filetree
```

**Expect**: `lib.nvim` found (hard dependency for the `:Filetree` command
layer), the resolved adapter reported as `neotree`, optional CLI tools
(`trash-put`/`gio`, `rg`) reported present/missing with a reason each —
not required. Open Neovim from a real git repo with a few directories deep
enough to exercise cwd/breadcrumbs meaningfully — this nvim config repo
itself, or `E:\repos\lib.nvim`, both work.

---

## 1. CWD Mode — the policy stack this config actually turns on

The single most-exercised feature by telemetry, and the one place this
config's settings differ most from upstream defaults.

**Steps**

```vim
:Filetree cwd status
```

**Expect**: reports the active mode (default `follow`), scope, resolved
root, and the actual `getcwd()` — confirm these three agree before relying
on anything below.

```vim
L
```

(in the tree window) — cycles through `cycle` (default `{"follow",
"project","lock"}`). Watch this config's own statusline component (not an
in-tree float — `indicator.enabled = false` here) update on each cycle,
since that's what this session actually wired up instead of the default
badge.

- [ ] `L` to `project`: open a file inside a git repo, open a file in a
  different git repo — the resolved root should follow (this depends on
  `cwd_sync` being enabled, which it is here — see below).
- [ ] `L` to `lock`, then `gp` on a directory node — pins the cwd there;
  switch buffers across project boundaries afterward and confirm the root
  does **not** move (that's the whole point of `lock`).
- [ ] `L` back to `follow` — `decide()` should return `nil` and cwd_sync's
  own resolution chain applies unchanged.

**The one dependency worth actually triggering**: `project`/`nearest`
modes only *seed* the initial pin — the thing that keeps following the
file across project boundaries is `cwd_sync`'s own `BufEnter` hook. This
config has `cwd_sync.enabled = true`, so that should genuinely work; if
you ever see `set_mode()`'s one-time warning about this, that means
`cwd_sync` got disabled somewhere, not that `cwd_mode` itself is broken.

- [ ] `+` (tree_traverse, root here) while under `lock` — the pin should
  *move* to match, not get reverted a tick later (`lock.follow_manual_root`,
  on by default). `:Filetree cwd status` right after confirms where it
  actually landed.

---

## 2. CWD Sync — why `reveal = false` matters here specifically

**Steps**

Switch buffers between two files in different git repositories (or two
directories with different `.git` ancestors), with the tree window
visible.

**Expect**: the tree's root silently follows to the new file's project
root on `BufEnter` (`root_markers = {".git"}`), **without** neo-tree's own
native "File not in cwd. Change cwd to...?" prompt ever appearing — that
suppression is automatic the moment `setup({ adapter = "neotree" })` runs.

- [ ] Because `reveal = false` here (deliberately, per the config
  comment — neo-tree already follows the buffer via
  `bind_to_cwd`/`follow_current_file`), the newly-focused file should
  still get revealed in the tree, just via neo-tree's own native
  mechanism, not filetree's. If you ever flip this to `reveal = true` for
  a test, watch for the double-reveal race the comment warns about.

---

## 3. Breadcrumbs

**Steps**

Navigate the cursor into a file several directories deep in the tree.

**Expect**: the breadcrumb line shows the path from the tree root down to
the current node — legible without scrolling up through every parent.

- [ ] `:Filetree breadcrumbs update` — manual trigger, should match
  whatever the automatic update already showed.

---

## 4. The reference engine — the most elaborate single feature

Every mutating fileops feature (`r` smart rename, `<leader>rb` batch
rename, `M` move, `x`/`p` cut+paste, `d` trash) routes through
`filetree.refs`. This is worth testing deliberately once, not just
trusting it works because a rename didn't error.

**Steps**

1. In a scratch copy of a small repo with real cross-references (a
   markdown file linking to a `.lua` file, and a Lua file `require()`-ing
   another), rename the target file with `r` (smart rename).
2. Watch for the chooser: `N reference(s) in M file(s) (... markdown, ...
   lua) — Update all / Select… / Show diff / Leave as-is`.

**Expect**:

- [ ] **Show diff** first — a read-only unified diff, then back to the
  chooser (nothing applied yet).
- [ ] **Update all** — every reference rewritten, preserving how it was
  originally written (`./x` keeps its `./`, an absolute link stays
  absolute).
- [ ] `:Filetree refs undo` — reverts that whole batch in one call.
- [ ] Repeat with `M` (move) instead of rename — the scan should start the
  **moment you press `M`**, overlapping with you typing the destination
  (this is the point: the file is still at its old path when the scan
  runs, so it can't miss anything).
- [ ] Repeat with `d` (trash) on the same file — since something still
  links to it, the plain trash confirm should become the reference-aware
  chooser: **Delete + remove refs** (blanks the dangling markdown link to
  `REF!`), **Inspect first**, **Delete, keep refs**, **Cancel**. Confirm
  code references (the `require()`) are left alone even when you pick
  "remove refs" — that asymmetry (markdown always scrubbed, code never) is
  deliberate, not a bug.
- [ ] `ts_js` provider is **off by default** — if testing a TS/JS tree,
  confirm imports are *not* rewritten unless you explicitly turned
  `refs.providers.ts_js = true` on.

---

## 5. `handle_guard` and `watcher_quarantine` — both explicitly enabled here, Windows-specific

This machine is Windows, and this config turns `handle_guard` on
(opt-in, off upstream) specifically to fix the neo-tree directory-watcher
file-lock bug at its source.

**Steps**

1. Expand a directory in the tree (arms neo-tree's libuv watcher on it).
2. Rename or trash that same directory (or a file inside it) via `r`/`M`/`d`.

**Expect**: the operation succeeds without an `EPERM`/
`ERROR_SHARING_VIOLATION` — `handle_guard` should have released the libuv
handle before the fileop ran, transparently.

- [ ] `:Filetree handles` — lists tracked watcher handles; flags any
  pointing at a path that no longer exists (the leak signature). Should be
  clean (or self-correcting) in normal use.
- [ ] If you ever see a lock error anyway, check whether
  `watcher_quarantine` (also on here) is the only thing catching it — it
  suppresses the *notification*, not the handle itself, so persistent
  errors under quarantine-only point at `handle_guard` being the thing
  that's actually missing, not broken.

---

## 6. Trash, undo, and Copy/Move

**Steps**

```
d           " trash the node under cursor
U           " undo it
<leader>th  " trash history
```

**Expect**: `d` moves to the OS trash (not permanent delete) — check it's
recoverable from the system trash, not just from `U`. `U` restores it in
place. `<leader>th` shows history back to `max_history` (default 50).

- [ ] Mark 3+ nodes (`m` on each, or `V` + `m` in Visual mode over a
  range), then `d` — one batch confirmation, not three, plus a progress
  indicator (via `lib.nvim.progress`) for the batch.
- [ ] `c`/`x` then `p` — copy/cut-stage then paste. Create a name
  collision on purpose (paste into a directory that already has a
  same-named file) — expect the **Overwrite / Keep both / Skip / Cancel**
  prompt, not a silent overwrite. A skipped *cut* item should stay staged
  (check `:Filetree clipboard show`), not vanish.
- [ ] `M` (move) on a single node to a destination that doesn't exist yet
  — should double as move-and-rename. `M` on 2+ marked nodes to an
  existing directory — should move all of them *into* it.
- [ ] `:Filetree copymove dry-run` then a paste — should log the plan and
  touch nothing; toggle back off before relying on a real paste.

---

## 7. Marks — the selection mechanism other features build on

**Steps**

```
m       " mark node under cursor
]m [m   " mark all / unmark all visible
V m     " Visual-mode: mark every node in the range
gm      " jump to Nth mark (count-prefixed, e.g. 2gm)
]M [M   " cycle next/prev mark, with wrap
```

**Expect**: `<C-m>` lists current marks. `]M`/`[M` follow the tree **as
rendered**, not alphabetical order — a mark inside a collapsed directory
has no line to jump to; expand first if `]M` seems to skip one. An
out-of-range count on `gm` clamps to the last mark rather than erroring
(same as `G`).

- [ ] `diff_marked()` — mark exactly two files, `:Filetree diff marked` —
  diffs them against each other, not against the current buffer.

---

## 8. Create From Template

**Steps**

```
A
```

**Expect**: prompts for the **filename first**, then a picker filtered to
that extension's templates only (`foo.lua` → only `.lua` templates) — a
typo'd extension falls back to the *full* list rather than showing empty.
Variables (`${filename}`, `${date}`, `${module}`, …) substitute against
the real destination.

- [ ] `<M-j>`/`<M-k>` in the picker with an empty filter — reorders
  templates, persisted to a `.order.json` sidecar; reopen the picker and
  confirm the new order stuck.
- [ ] Drop a file into `stdpath("data")/filetree/templates/` with the
  **same name** as a built-in — confirm it shadows the built-in entirely.

---

## 9. Search & paths

**Steps**

```
/           " filter (live, narrows listing)
gs          " live search (jumps between matches, doesn't narrow)
f    tf     " find files (auto-detected picker / forced telescope)
gr   tg     " grep in directory (auto / forced telescope)
[a  ]a      " copy absolute path (node / parent)
[R  ]R      " copy path relative to project root
rq          " copy as require("...") string
[f ]f [F ]F " copy file list (files/dirs, abs/rel)
ML MR MM    " markdown links (node/recursive/marked)
```

**Expect**: `/` and `gs` behave differently — confirm `/` actually
narrows the listing while `gs` only jumps without hiding anything. `rq`
resolved against a real `lua/` directory should produce the same dotted
path `create_from_template`'s `${module}` variable would. Paste an `ML`
result somewhere — a real, working relative markdown link.

---

## 10. UI: Preview, Node Info, Cheatsheet, Context Menu, current_hl

**Steps**

```
<Tab>  <CR>          " preview toggle / dispatch (image/PDF routes elsewhere)
I                    " node info float
```

- [ ] `I` on a directory — recursive item count + aggregate size, computed
  fresh each press (not cached).
- [ ] Open the cheatsheet (however this config's `?`/help binding is set,
  or check `:nmap` in the tree buffer) — confirm it lists the **actual**
  enabled-feature keymaps, and that it's the same data
  `docs/BINDINGS/KEYMAPS.md` documents.
- [ ] Since `current_hl.enabled = true` here: the file backing the active
  editor window should be visibly marked in the tree with the `▸` icon
  (this config's override) plus the `FiletreeCurrentFile`/
  `FiletreeCurrentParent` highlight groups — switch buffers, confirm the
  marker follows.
- [ ] Right-click (`<RightMouse>`) — context menu via `nvzone/menu` if
  installed; if not, confirm it's silently inert, not an error.
- [ ] Native neo-tree `?` cheatsheet — confirm filetree's own keys appear
  there too, labelled `filetree: …` (the injected-config integration).

---

## 11. Navigation: Tree Traverse, Auto Reveal, Reveal Alt, Layout Guard

**Steps**

```
-   " up to parent, sets new root
+   " root here
B   " reveal alternate buffer (#)
```

- [ ] Close every editor window but leave the tree open (Layout Guard) —
  a new empty editor window should open automatically, on the screen edge
  **away** from the tree (not flipped to the tree's side — this was a
  known historical bug tied to `'splitright'`).
- [ ] `B` on a file in a different project than the current root — root
  should adjust to reach it, the tree-buffer analogue of `:e #`.

---

## 12. Integrations: Diff, Open in FM/With, Shell Run, PDF bridge

**Steps**

```
D             " diff node under cursor
<leader>fm    " open in file manager
<leader>sm    " open with configured external app
i             " shell_run — prompt + run in node's directory
```

- [ ] `D` against the working tree and against a git revision — both
  should use native diffmode, nothing custom-rendered.
- [ ] `i` — run something harmless (`git status`) scoped to a subdirectory
  node, confirm it actually ran *there*, not at the tree root.

**PDF bridge (`gp`) — off by default, and it collides with `cwd_mode`'s
own `gp` (lock-here) if turned on.** This config leaves `pdf_open`
disabled, so `gp` unambiguously means "lock cwd here" (§1). Only test the
PDF bridge if you deliberately enable `features.pdf_open.enabled = true`
for the session — and if you do, remap one of the two `gp` bindings
first, since whichever feature's `setup()` runs later silently wins the
key otherwise.

---

## What this checklist does not cover in depth

`file_watcher` (opt-in, off by default here — `handle_guard` is this
config's actual answer to the Windows lock bug, not the watcher), `safety`
backups (opt-in, off, no visible effect until another feature's
`use_safety` opts into it), session persistence, git status/LSP diagnostic
decoration (both adapter-native, nothing filetree-specific to click
through), and the nvim-tree/netrw/oil.nvim/mini.files adapters (this
config only runs neo-tree — the per-adapter caveats in
`docs/FEATURES/BACKENDS.md` only matter if you switch `opts.adapter`).
