# Testing sessions.nvim

How to manually test every implemented feature of `sessions.nvim`. One-time
setup, then one section per feature: prerequisites, steps, what to expect.
Checkbox syntax (`- [ ]`) throughout — togglable directly in Neovim (e.g.
with `cascade.nvim`'s `<leader>tc`).

Repo: `E:\repos\sessions.nvim`. Spec: `plugins/personal/init.lua`, `lazy =
false` — "setup() registers the VimEnter autoload and the VimLeavePre
autosave. Both are startup/shutdown events, so a lazy trigger would have to
fire before VimEnter to be of any use." `opts = {}` in this config (autoload
commented out), so every default below is live as-is on this machine.
`dependencies = { "stefanbartl/lib.nvim" }`.

**Priority note**: telemetry for this plugin (`docs/ROADMAP/TelemetryReport.md`)
is almost empty — 232 calls total across 73 sessions, and the only two
functions that ever fired are `core.mark_dirty` (230×, the statusline
dirty-tracking autocmds — background bookkeeping, not a feature a user
invokes) and `core.save` (2×). No `bindings.`/`commands.`/`usrcmds`-prefixed
entry point shows up at all, meaning the real command surface (`:Session
save`, `:Session load`, …) has essentially no recorded calls on this
machine — not because it's unused, but because `lazy = false` +
`autosave/autoload` mean most of the day-to-day value comes from autocmds
firing silently, which the telemetry does confirm happened constantly
(`mark_dirty` on every `BufAdd`/`WinNew`/etc.). Ordering below therefore
follows the README/FEATURES/WORKFLOW docs' own account of what matters most
day-to-day, not a call-count signal — there isn't one to trust here.

## Setup

```vim
:checkhealth sessions
```

**Expect**: Neovim ≥0.9 ok, `vim.json`/libuv/`vim.system` ok, "plugin loaded"
ok, `lib.nvim` sections (`usercmd.composer` required — error if missing;
`notify`/`keymap`/`git` soft-guarded — info if missing, not error/warn),
which-key and snacks/telescope info lines, resolved config values
(`root`/`default_name`/`branch_aware`/etc.), session root + count, and
`:Session`/`:LastSession`/`:SessionLoad` all registered.

---

## 1. The steady-state loop: autosave + `:LastSession`

This is the path every real session on this machine already exercises
without you typing a single `:Session` command — worth confirming it
actually works before anything else, since a break here is silent (nothing
errors, it just doesn't save/restore).

**Steps**

1. Open Neovim in a real project, open a couple of files, arrange a split or
   two.
2. Quit entirely (`:qa`).
3. `nvim +LastSession` (no quotes needed — single word).

- [ ] The autosave on quit wrote to `opts.autosave_name` (default `"last"`)
      — check `stdpath("data")/sessions/last.vim` has a fresh mtime after
      step 2.
- [ ] `nvim +LastSession` restores the same buffers and split layout you had
      before quitting, silently (no floating prompt — `autoload` is not
      involved here, this is a direct convenience command over `:Session
      load last`).
- [ ] Repeat with `opts.autoload = true` (or `"ask"`) instead: a **bare**
      `nvim` (no file args) autoloads the contextual session on `VimEnter`.
      With `"ask"`, expect a floating y/n prompt naming the session before it
      loads — accept once, decline once, and confirm decline leaves you at an
      empty buffer rather than partially loading.
- [ ] `nvim somefile.lua` (an explicit file arg) does **not** trigger
      autoload — `fn.argc(-1) ~= 0` short-circuits it in
      `bindings/autocmds/init.lua`.

---

## 2. `:Session save` / `load` / `list` / `current` — the core lifecycle

**Steps**

```vim
:Session save my-test-session
:Session list
:Session current
:Session load my-test-session
```

- [ ] `save` with an explicit name writes `root/my-test-session.vim` (plus
      `.my-test-session.json` if `metadata = true`, the default).
- [ ] `list` shows it, newest info first is not required but the entry
      should be sorted alphabetically (`table.sort(files)` in `core.list`).
- [ ] `current` prints the active session name after a save/load, and "No
      session active." before any save/load has happened this session.
- [ ] `load my-test-session` restores it. Do this with a **modified,
      unsaved** buffer open first — expect no `E445` (Neovim's own
      `only`/`tabonly` error for a window with unsaved changes): `core.load`
      hides modified buffers before collapsing windows, doesn't discard them.
      The load's own notify should list them under "hidden (unsaved): ...".
- [ ] `:Session save` with **no** name, `branch_aware`/`project_aware` both
      on (defaults): auto-resolves to `<project>_<branch>` — confirm via
      `:Session current` or the filename in `root/`.
- [ ] `:Session load` with **no** name prefers the **remembered
      last-loaded** session (persisted in `root/.state.json`), not the
      auto-resolved project+branch name — these are genuinely different
      things (see §3's note). Load something by explicit name, then `:Session
      load` bare — should reload that same remembered name, not
      auto-resolve.

---

## 3. Branch- and project-aware naming

**Steps** (needs a real git repo with at least two branches)

```vim
:Session save
:!git checkout -b test-branch-2
:Session save
:Session list
```

- [ ] Two distinctly-named sessions appear, e.g. `myrepo_main` and
      `myrepo_test-branch-2` — genuinely separate workspaces per the docs'
      "that's the point, not a bug."
- [ ] `git checkout` alone does **not** reload anything — there is no
      branch-change hook (confirmed in `sessions.core`: names are resolved
      only at save/load time). Switching branches without an explicit
      `:Session save` before and `:Session load` after leaves you on the
      old branch's buffers.
- [ ] Metadata's `branch` field (visible in `:Session list`'s `[branch]`
      suffix and the picker preview) is populated **only** when
      `branch_aware` or `project_aware` is on — `sessions.git` is
      lazy-required and never shells out otherwise. Disable both, save,
      confirm `branch` is absent from that session's metadata/preview.

---

## 4. `:SessionLoad` — the picker

**Prerequisites**: Snacks.picker or telescope.nvim installed (both are —
check `:checkhealth sessions`' report on which one it picked).

**Steps**

```vim
:SessionLoad
```

- [ ] Opens with live preview: saved timestamp, branch, cwd, buffer list —
      for a session saved with `metadata = true`. For one with no metadata
      (or `metadata = false`), the preview should say so explicitly
      (`"(no metadata recorded — enable metadata = true ...)"`), not show a
      blank pane.
- [ ] `<CR>` on an entry loads it (same as `:Session load <name>`).
- [ ] Multi-select two or more sessions, `<C-d>` — deletes all selected in
      one go, notifies with every deleted name, and (Snacks backend) removes
      them from the picker's own list without a full re-open.
- [ ] `:SessionLoad` with **zero** saved sessions — expect a clean "no
      sessions saved yet" info notify, not an empty/broken picker window.

---

## 5. `:Session delete` / `:Session rename`

**Steps**

```vim
:Session save delete-me
:Session delete delete-me
:Session save rename-me
:Session rename rename-me renamed
```

- [ ] `delete` removes both the `.vim` file and its `.json` metadata
      companion (check `root/` directly). Deleting the **currently active**
      session clears `:Session current` back to "No session active."
- [ ] `rename` refuses if the new name already exists as a session
      (`"session already exists: ..."`) rather than silently overwriting.
- [ ] Renaming the currently active session updates `:Session current` to
      the new name without a reload.
- [ ] Neither of these two has a keymap option, by design (they take a
      required argument). Set `keymaps = { delete = "<leader>xd" }` anyway —
      expect a specific warning naming `:Session delete requires a name`
      and pointing at `keymaps.picker`/the command directly, **not** a
      generic "unknown keymap action" error. Same for `rename`.

---

## 6. `:Session toggle-track` — git skip-worktree

**Prerequisites**: `root` (or a session file) living inside a real git repo
— by default `stdpath("data")/sessions` is **not** one, so point `opts.root`
at somewhere inside e.g. this nvim-config repo for this test, or accept the
expected failure below as the actual test.

**Steps**

```vim
:Session save track-test
:Session toggle-track track-test
```

- [ ] With the default `root` (not inside a git repo): expect a clear error
      — `"session root is not inside a git repo (required for :Session
      toggle-track)"` — not a raw git-command failure. `toggle_track` walks
      upward from `cfg.root` looking for `.git` (`vim.fs.find(".git", {
      upward = true })`), so this is the expected, correct outcome for the
      default config.
- [ ] With `root` pointed inside a real git repo: first toggle marks the
      file `skip-worktree` (notify: "... marked as skip-worktree (excluded
      from git)"); `git status` on that repo should not show the file as
      modified even after another `:Session save track-test`. Toggle again
      → "... is now tracked in git", and `git status` should show it.
- [ ] This runs via `vim.system()` callbacks (Neovim 0.10+) — the command
      returns immediately, the notify arrives asynchronously a moment later.
      Confirm the UI doesn't freeze during the two git calls (`ls-files`
      then `update-index`).

---

## 7. Portability: `relative_paths` / `root_remap`

**Steps**

```vim
:lua require("sessions").setup({ relative_paths = true })
:Session save portable-test
```

- [ ] Open `root/portable-test.vim` in a text editor/`:e` — the saved `cd`/
      buffer paths under the save-time `cwd` should read as the literal
      placeholder `{{SESSION_ROOT}}`, not an absolute host path.
- [ ] `:Session load portable-test` from a **different** `cwd` (a copy of
      the same project elsewhere, or just a different working directory)
      re-anchors correctly — the placeholder resolves to the *current*
      `cwd` at load time, on an in-memory copy (`prepare_for_load` writes a
      tempfile, sources that, then deletes it) — the stored `.vim` file
      itself is never rewritten by loading.
- [ ] **The retroactivity trap** (called out explicitly in
      `docs/WORKFLOW.md`): save a session with `relative_paths = false`
      first, *then* flip the config to `true` and reload/re-save nothing —
      the already-saved file should **not** have magically become portable.
      Only sessions saved *after* the flag changes get the placeholder
      treatment.
- [ ] `root_remap = { ["C:/old/path"] = "D:/new/path" }`: save a session
      with paths under `C:/old/path` (or fake it by hand-editing a saved
      `.vim` file), load with the remap configured — paths should resolve
      to `D:/new/path` on load, and (unlike `relative_paths`) this applies
      on **every** load regardless of whether the file was saved before or
      after the remap was configured, since it's a load-time, in-memory
      substitution.

---

## 8. Tab-scoped sessions: `save-tab` / `load-tab`

**Steps**

```vim
:tabnew
:Session save-tab tab-test
:tabclose
:Session load-tab tab-test
```

- [ ] `save-tab` writes to `root/.tabs/tab-test.vim`, a separate directory —
      confirm it does **not** appear in `:Session list` or the `:SessionLoad`
      picker afterward.
- [ ] `load-tab` opens a **new** tab and restores into it, leaving whatever
      other tabs were already open untouched — unlike `:Session load`,
      which collapses to a single tab.
- [ ] Saving a tab session should not disturb `:Session current` or the
      remembered last-loaded name — `M.save_tab` deliberately never touches
      `_current`/`_dirty`/`state`.
- [ ] `:Session load-tab` with a name that has no required argument omitted
      — should error "tab session name required" rather than falling back to
      any default (unlike full sessions, tab snapshots have no
      remembered-last/`default_name` fallback).

---

## 9. Window-layout snapshots: `save-layout` / `load-layout`

**Steps**

1. Arrange a nontrivial split layout — e.g. a vertical split with the left
   side further split horizontally (three windows, mixed row/col).
2. `:Session save-layout my-layout`
3. Close all but one window (`:only`), open different, unrelated buffers.
4. `:Session load-layout my-layout`

- [ ] The exact split *structure* and relative sizes reappear, applied to
      whatever buffers happen to be open right now — it does **not** try to
      reopen the files from step 1 (this snapshot deliberately captures
      layout only, no buffer identity).
- [ ] Sizes are close to what was saved (width/height in cells, captured via
      `nvim_win_get_width/height` at save time, reapplied via
      `nvim_win_set_width/height` after the whole tree is rebuilt — check
      the module comment: sizing mid-build gets clobbered by later splits,
      which is why it's a two-pass capture-then-size).
- [ ] Stored under `root/layouts/*.json`, separate from both full sessions
      and tab sessions — not in `:Session list`.

---

## 10. Statusline component + dirty tracking

**Prerequisites**: a statusline plugin (lualine/heirline) or just call the
function directly for this test.

**Steps**

```lua
:lua print(require("sessions.statusline").component())
```

- [ ] Right after a save/load: no dirty marker.
- [ ] Open a new split, close a buffer, open a new tab — any of
      `BufAdd`/`BufDelete`/`WinNew`/`WinClosed`/`TabNewEntered`/`TabClosed`
      — then re-check the component: a dirty indicator should now be
      present (this is exactly what the telemetry's 230 `core.mark_dirty`
      calls on this machine were — these autocmds fire constantly in normal
      use).
- [ ] Save again — dirty clears.
- [ ] **Structural changes only**: editing text inside a buffer (not
      touching window/buffer structure) should **not** mark dirty —
      `mark_dirty` is wired to layout-shape autocmds, not `TextChanged`.
      Confirm typing in a buffer alone leaves the indicator clean.

---

## 11. Metadata companion file

**Steps**

```vim
:Session save meta-test
:lua print(vim.inspect(require("sessions").metadata("meta-test")))
```

- [ ] Returns a table with `saved_at` (ISO-ish UTC timestamp), `cwd`,
      `branch` (nil unless git-aware, see §3), and `buffers` (real absolute
      paths of every loaded buffer with a name at save time).
- [ ] Delete the session (`:Session delete meta-test`) — the `.json`
      companion should be gone too, not left orphaned in `root/`.
- [ ] With `opts.metadata = false`: save a session, confirm no `.json` file
      is written at all, and `:Session list`/the picker preview degrade
      gracefully (no timestamp/branch column, no crash).

---

## 12. Keymaps (opt-in; `keymaps = false` by default)

**Steps**

```lua
require("sessions").setup({
  keymaps = { save = "<leader>ssa", load = "<leader>slo", list = { "<leader>sli", "<leader>sl2" } },
})
```

- [ ] `<leader>ssa` and `<leader>slo` work as `:Session save`/`load`.
- [ ] `list` accepting a **list** of two lhs — both `<leader>sli` and
      `<leader>sl2` should independently trigger `:Session list` (an lhs may
      be a list, per `lib.nvim.bindings.keymap`).
- [ ] which-key (if installed) shows a "Session" group label on the longest
      shared prefix of whatever you configured — reconfigure with keys that
      share no common prefix at all (e.g. `save = "<leader>a"`,
      `load = "<leader>zzz"`) and confirm **no** group label appears rather
      than a wrong one (`common_prefix` returns `nil` when there's nothing
      shared).
- [ ] Every mapped action carries a real `desc` (`:map <leader>ssa` shows
      "Session: save" or similar, not a blank description).

---

## 13. `:checkhealth sessions` — the broken paths

Most of `:checkhealth` is covered by §0. Worth triggering the paths that
only show up when something is actually wrong:

- [ ] Temporarily rename/disable `lib.nvim` on the runtimepath (or check
      this reasoning against the code without doing it destructively): health
      should report `lib.nvim.bindings.usercmd.composer` as **error**
      (`:Session`/`:LastSession` will fail to load), but
      `notify`/`keymap`/`git` as **info**, not error — they're soft-guarded
      fallbacks, not hard requirements.
  - [ ] Same for snacks.nvim/telescope.nvim both absent: `:SessionLoad`
        should report info-level "will error until one is installed", not a
        warning that overstates the severity (every other `:Session`
        command works fine without either).
- [ ] Point `opts.root` at a path that doesn't exist yet — health should say
      "session root does not exist yet (will be created on first save)",
      not report an error or silently show 0 sessions as if that were
      normal for an existing-but-empty root.
