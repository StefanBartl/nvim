# Testing fileops.nvim

How to manually test every implemented feature of `fileops.nvim`. One-time
setup, then one section per feature: prerequisites, steps, what to expect.
Checkbox syntax (`- [ ]`) is standard Markdown, togglable directly in Neovim
(e.g. with `cascade.nvim`'s `<leader>tc`).

Repo: `$REPOS_DIR\fileops.nvim`. Spec: `plugins/personal/init.lua`
(`event = "VeryLazy"`, `opts = { cycle = { open_target = "current" } }` — the
one non-default: cycling opens the next/prev file **replacing the buffer but
keeping it listed**, not the plugin's own default of `"replace"`, which is
closer to "throw the old buffer away").

Telemetry (Workstation, 83 sessions, 194 calls total) is thin and skewed by
one hot path: `ops.file.ensure_parent` alone is 174 of those 194 calls — that
is `auto_mkdir` firing on every `BufWritePre`, not a feature a user chose to
invoke, so it says nothing about priority (see the report's own caveat on
hot-path functions). The only real entry-point signal is `ops.cycle.
get_root_dir`/`navigate`/`open_path` at 3 calls each and `ops.file.copy_path`
at 1 — cycling got touched this window, rename/move/delete/duplicate did not
get a single recorded call. Per the report's other caveat, that is **not**
evidence those are unimportant on a window this thin (194 calls / 83
sessions) — they are `:File`'s core lifecycle operations regardless of what
telemetry caught. Ordering below follows that reasoning: the unified command
and its most consequence-bearing subcommands first, the weak-but-real cycling
signal next, then the rest by how much can plausibly go wrong.

## Setup

Already wired into this config — nothing extra to install.

```vim
:checkhealth fileops
```

**Expect**: Neovim >= 0.9, libuv, `vim.ui.select`, `vim.fs.dir`, the
`vim.g.loaded_fileops` guard, `lib.nvim` (hard requirement — `:File` cannot
register without it), which-key (optional), `git` executable, gitsigns.nvim
(optional) — all reported, none silently skipped.

---

## 1. `:File` — create/write and the two "relative to" bases

**Steps**

```vim
:File touch scratch.txt
:File new draft.md
:File write out.txt
```

Then, from a file at `src/deep/nested/file.lua` with cwd at the project
root:

```vim
:File touch sibling.lua
:File rename sibling2.lua
```

**Expect**: `touch`/`new`/`write`/`saveas`/`writeto` resolve a relative path
against **Neovim's cwd** (same base `:write` uses) — so `sibling.lua` above
lands at the project root. `rename`/`move`/`duplicate`/`copy` resolve
against the **current file's own directory** instead — `sibling2.lua` lands
next to `file.lua`, not at cwd. This split base is deliberate (per
`docs/WORKFLOW.md`), not a bug, and is the single most likely thing to
surprise you if you haven't read the source — confirm both really do land
where the docs say, not just that neither errors.

- [ ] `touch` creates without opening/writing a buffer; running it twice on
      the same path does **not** truncate the existing file (real `touch`
      semantics)
- [ ] `new`/`write`/`saveas`/`writeto` all auto-create missing parent
      directories
- [ ] Tab-completion on `:File rename <Tab>` browses the **buffer's own
      directory**, not cwd
- [ ] Omitting `[path]`/`[dest]` on any subcommand opens a `vim.ui.input`
      prompt instead of erroring; cancelling it is a silent no-op

## 2. `:File rename` / `:File move`

**Steps**

```vim
:File rename NEW.md
:File move ../other/NEW.md
```

**Expect**: both write unsaved changes first, both are git-aware/retry-aware
(§4). The only functional difference: `rename` **reloads the buffer from
disk** afterward (signs/diagnostics reset), `move` leaves buffer content and
undo history untouched — confirm this concretely (undo history survives a
`move`, does not survive a `rename`).

- [ ] `:File! rename`/`:File! move` bypass the modified-buffer confirm
- [ ] A destination that already exists is refused without `!`, overwritten
      with `!`

## 3. Delete — the three-way guard

**Steps**

```vim
:File delete
```

with unsaved changes in the buffer, then again after saving, then
`:File! delete`.

**Expect**: with unsaved changes, `:File delete` refuses outright — **nothing
is deleted, not even a partial write**. On a clean buffer it deletes and
closes, steering any window showing that buffer onto an alternate listed
buffer first (confirm no empty scratch buffer appears if other files are
open). `:File! delete` force-closes and deletes regardless of unsaved state.

- [ ] Set `delete.on_before_delete` to a function returning `false` once —
      confirm it vetoes the deletion before either safety check touches disk
- [ ] `delete.mode = "trash"` (opt-in, not this config's default) sends the
      file to the OS trash instead of `fs_unlink` — verify by checking the
      Recycle Bin, not just that the file is gone from disk

## 4. Sharing-violation retry and `git_aware`/`session_compat` interaction

This config leaves `git_aware`/`session_compat`/`retry` at plugin defaults
(none of the three appear in `plugins/personal/init.lua`'s `opts`), so what's
below is the **default** behavior, not a customized one.

**Steps**

```vim
:File rename renamed.lua
```

on a git-tracked file, then check the result message.

**Expect**: `git_aware.enable` defaults to `false`, so the message should
**not** mention git-tracked status and the rename goes through libuv only —
confirm this is really the case before assuming git-awareness is on just
because the repo is a git repo. Retry: `retry.attempts` is `6` on Windows
(this machine), `60`ms doubling backoff — trigger a real `EBUSY` if you can
(e.g. hold the file open in another process mid-rename) and watch for the
`User FileopsRetry` autocmd firing before each retry.

- [ ] `session_compat.enable` (default `true`) — with an active `:mksession`
      session (`v:this_session ~= ""`), rename/move should resave it in
      place. **The trap documented in WORKFLOW.md**: a bare `:mksession!`
      ignores `v:this_session` and would write a fresh `./Session.vim` at
      cwd instead — confirm fileops passes the actual session path
      explicitly (check the session file's mtime, not just that no error
      appeared)
- [ ] With no session ever loaded this session, confirm this is a true no-op
      (no `Session.vim` appears anywhere)

## 5. Directory cycling (`next`/`prev`/`first`/`last`) and its keymaps

The one feature with an actual (thin) telemetry signal this window.

**Steps**

Press `<leader>nf` / `<leader>pf` in a directory with several files. Then
try the other six default-bound variants: `<leader>nfn`/`<leader>pfn`
(stay listed), `<leader>nF`/`<leader>pF` (background), `<leader>NF`/`<leader>PF`
(vsplit). Then:

```vim
:2File next
:File next *.lua
```

**Expect**: cycling is alphabetical, `cycle.root = "buffer_dir"` (default —
not overridden here) means it lists the buffer's own directory, not cwd.
`:2File next` skips 2 (`v:count1`). `:File next *.lua` narrows via
`vim.fn.glob2regpat` first. Since `opts.cycle.open_target = "current"` in
this config (not the plugin default `"replace"`), confirm the bare
`<leader>nf`/`<leader>pf` keys actually **keep the current buffer listed**
now rather than replacing it — that's the one place this config's override
should visibly change stock behavior.

- [ ] `next_filtered`/`prev_filtered` and `delete_force`/`path`/`cd`/`info`/
      `lockinfo`/`bulk_rename` keymaps are **unset** in this config (commented
      out in `plugins/personal/init.lua`) — confirm none of those `<leader>`
      combinations do anything unexpected, since the plugin ships them
      possible-but-unbound by design
- [ ] Which-key popup on `<leader>n`/`<leader>p` shows two separate groups
      ("fileops: next file" / "fileops: prev file"), not one merged group

## 6. Duplicate & copy

**Steps**

```vim
:File duplicate copy1.lua
:File copy copy2.lua
```

**Expect**: `duplicate` opens the new file afterward, `copy` does the exact
same validation/copy but stays silent (no window change). Neither ever runs
a git command even with `git_aware.warn_only = false` set — confirm the
result message for a tracked source file only *notes* it, since
`duplicate`/`copy` have no git-native "copy" operation to route through.

## 7. Bulk rename — Lua pattern, not glob, non-recursive

**Steps**

In a scratch directory with a few `.txt` files:

```vim
:File bulk rename %.txt$ .md
```

**Expect**: a notification previews every `old → new` pair, **then**
`vim.ui.select` asks to confirm — read the preview before confirming, since
an unanchored pattern silently over-matches (e.g. `:File bulk rename .txt
.md` without the `%.` anchor and `$` end-marker also touches a name like
`footxt.md`, because Lua's `.` is "any character", not a literal dot). Only
the current directory is touched, never subdirectories.

- [ ] Without `!`, a colliding destination is skipped and reported while the
      rest of the batch proceeds (partial `N/total` result is expected, not
      a bug)
- [ ] Any open buffer pointing at a renamed file is re-pointed, not reloaded
      (same as `move`)

## 8. Lock diagnosis (`:File lockinfo`)

Real value on Windows (this machine) — worth exercising deliberately rather
than only when something actually locks up.

**Steps**

```vim
:File lockinfo
```

on a file, and ideally also right after a rename/delete that actually failed
with `EBUSY`/`EPERM`.

**Expect**: probes whether the file is renameable *right now* and, on
Windows, names the actual process holding it via the Restart Manager API (no
admin rights needed). The full report is also echoed to `:messages` — check
it's there after the popup times out. **The one thing it should never blame
is an open Neovim buffer itself** (Neovim keeps only a swap file open after
reading) — if the holder ever comes back as `nvim`, that means a leaked
watcher (e.g. neo-tree's), and the doc is explicit that no retry can outwait
that case; worth confirming the report text actually says so rather than
just naming `nvim` with no further explanation.

## 9. `path`, `cd`, `info`

**Steps**

```vim
:File path
:File path rel
:File cd
:File info
```

**Expect**: `path` copies to both the unnamed register and `+` (system
clipboard) in one of four modes (`abs` default, `rel`, `name`, `dir`). `cd`
sets cwd to the current file's directory at `cd.scope = "window"` (default,
`:lcd`) and refreshes any open explorer. `info` shows size (human + raw
bytes), mtime, and permissions via libuv `fs_stat` — on Windows the
permission bits are libuv's own synthesized approximation, worth noting if
they look unusual rather than assuming a bug.

## 10. Ambient autocmd features

**auto_mkdir** (default on, confirmed already firing 174 times in telemetry
this window) — write to a path with a non-existent parent directory and
confirm the directories appear before the write succeeds, without a warning.
Then check a buffer name matching `auto_mkdir.detect_remote_pattern`
(`^%w%w+:[\\/][\\/]`, e.g. an `ssh://` scratch buffer) is skipped — no local
`mkdir -p` attempted against a remote-looking name.

**conflict_marks** (default on) — open a file with real unresolved
`<<<<<<<`/`=======`/`>>>>>>>` markers (e.g. from an actual merge conflict, or
paste some in a scratch buffer) and confirm they highlight per-window via
`DiffDelete`/`DiffChange`/`DiffAdd` on `BufWinEnter`, clear on `BufWinLeave`.

**on_hold** — `opts.on_hold.enable` defaults to `false` and is not turned on
in this config's spec, so:

- [ ] Confirm `CursorHold` in a normal buffer does **not** show any ambient
      line-diff preview — the feature should be entirely inert here, not
      just quiet

## 11. Right-click menu integration (structurally verified only)

`fileops.integrations.menu` contributes Rename/Duplicate/Delete/Copy
path/Show info/Next/Previous entries in the shape `nvzone/menu` expects.
fileops itself never opens a menu — this config's own `<RightMouse>`
dispatcher would need to compose these entries in. **This cannot be checked
as "does fileops.nvim work" in isolation** — it can only be confirmed by
finding wherever this config's global right-click handler pulls fileops'
`M.items()`/`M.submenu()` in, and checking those specific entries appear
there. If nothing in this config wires it in, the menu items simply don't
exist anywhere to click — that's expected, not a fileops bug.

## 12. `:checkhealth fileops`

- [ ] Clean run: every section green given this real environment (lib.nvim
      present, git present, gitsigns present if installed)
- [ ] Temporarily rename `$REPOS_DIR\lib.nvim` out of the runtimepath (or
      simulate via a broken `require`) — confirm the health check reports
      "`lib.nvim` not found" with a useful message rather than `:File`
      simply failing to register with no explanation anywhere
