# Testing diff.nvim

How to manually test every implemented feature of `diff.nvim`. One-time
setup, then one section per feature: what to do, what to expect, and —
where the code gives a concrete reason to suspect something — what to
watch for specifically. Checkbox syntax (`- [ ]`) is standard Markdown,
togglable directly in Neovim (e.g. with `cascade.nvim`'s `<leader>tc`).

Repo: `$REPOS_DIR\diff.nvim`. Spec: `plugins/personal/init.lua` —
`cmd = { "Diff", "DiffClear", "DiffOrig", "DiffExit" }`, `opts = {}` (all
three features on by default). Note the config's own spec doesn't list
`DiffBuffers` in `cmd` even though the plugin registers it — first-loading
via `:DiffBuffers` directly (rather than `:Diff` first) is worth confirming
still works, since lazy.nvim's own command-stub mechanism should cover it
regardless of what's explicitly listed.

**No telemetry data exists for this plugin at all** — it has never loaded
in either recorded window, on this machine or the workstation dataset. Every
priority call below comes from `docs/WORKFLOW.md` (which is explicit about
which combinations "actually get reached for, and when") and
`docs/FEATURES.md`, not from usage data.

## Setup

```vim
:checkhealth diff
```

Expect: Neovim version, `git`/`curl` availability (needed for `git:` and
`http(s)://` specifiers respectively), and `lib.nvim`/pickers.nvim/
images.nvim detection. Everything below works from any file-backed buffer;
the git-revision and directory-diff sections specifically need to be run
from inside a real git repository with some history — this nvim config repo
or any of the `$REPOS_DIR\*` plugin repos both work.

---

## 1. Bare `:Diff` — the default reflex

**Steps**

- [ ] Open any file-backed buffer, `:Diff` with no arguments — the
      interactive picker for `target=` opens (a file path, an open buffer,
      `clipboard`, or `git:HEAD` should all be selectable entries).
- [ ] Pick a target — the diff opens in `output=buffer`/`view=vsplit`
      (both defaults), source is `source=current` (the buffer you started
      from) by default.
- [ ] `<Esc>` to cancel the picker — expect a "Diff cancelled" notification
      (this is the plain `vim.ui.select` engine's own cancel behavior; see
      §11 for the pickers.nvim-backed case, which differs).
- [ ] Visual-select a few lines, then `:'<,'>Diff target=...` — confirm
      only the selected range is used as `source=current`, while the
      target side is taken in full regardless.

---

## 2. `output=stat` — the fast pre-check reflex

**Steps**

- [ ] `:Diff target=git:HEAD~1 output=stat` (needs at least one prior
      commit touching the current file) — expect a plain notification,
      `+N -M, K hunks`, **no window opened at all**.
- [ ] Set `opts.diff.stat_list = "qf"` (or `"loc"`) temporarily and re-run —
      confirm the hunks now also land in the quickfix/location list as
      real, jumpable entries, not just the notification.
- [ ] Run `output=stat` twice in a row with `stat_list_mode = "add"`
      (default) — the list should **accumulate** both runs' hunks. Switch
      to `stat_list_mode = "replace"` and run again — the list should now
      hold only the latest run's hunks.

---

## 3. `git:{rev}` sources — and the trap this exists to prevent

**Steps**

- [ ] `:Diff target=git:HEAD` on a file with uncommitted changes — confirm
      it diffs against the last commit **without** checking anything out,
      stashing, or touching the working tree (check `git status` stays
      unchanged afterward).
- [ ] `:Diff target=git:HEAD~3..HEAD~1` (a revision range, no `source=`
      needed) — sugar for diffing the file directly between two
      revisions; confirm both sides really are historical, not one of them
      silently falling back to the working buffer.
- [ ] **The corollary gotcha, worth actually seeing once**: pick a file
      that was renamed or moved at some point in this repo's history (or
      rename one temporarily and commit it), then `:Diff target=git:{rev
      before the rename}` from the new path. Expect it to **fail to
      resolve** (no path-following, unlike `git log --follow`) rather than
      silently diffing against an unrelated file or the wrong content.

---

## 4. Three-way diff (`base=`) — merge-conflict resolution

The single highest-value combination per `WORKFLOW.md`.

**Steps**

- [ ] With a real (or simulated) merge conflict available: `:Diff
      target=git:MERGE_HEAD base=git:HEAD`. Expect three windows — your
      working copy (left, editable), the common ancestor (middle,
      read-only), the incoming branch (right, read-only).
- [ ] `:diffget`/`:diffput` between panes — confirm changes actually write
      into the **left** (your working buffer), the one you'll save, not
      into either read-only scratch side.
- [ ] Try `:Diff target=... base=... view=inline` and separately
      `output=stat` on a three-way — both should be **rejected up front
      with an error**, since neither means anything once there are three
      sides. Confirm the error is a clear rejection, not a crash or a
      silently-wrong two-way diff.
- [ ] Mix specifier types: `base=git:HEAD~5` against `target=<a file path
      or URL>` — confirm the three-way still opens correctly with mismatched
      specifier kinds on each side.

---

## 5. `view=` — reading vs. resolving

**Steps**

- [ ] `:Diff target=... view=vsplit` (default) vs `view=split` vs
      `view=tab` — confirm each opens real native diffmode in the expected
      layout, and that `:diffget`/`:diffput` work in all three.
- [ ] `:Diff target=... view=inline` — a single scratch buffer with unified
      diff text, `ft=diff`. With `opts.diff.word_diff = true` (default),
      confirm changed spans within a paired removed/added line get
      intra-line `DiffText` highlighting, not just whole-line coloring.
- [ ] Find or construct a hunk where the removed and added line counts
      **don't** match (e.g. one line removed, three added) — confirm word-
      level highlighting falls back to whole-line-only for that hunk
      specifically, rather than misaligning the highlight.
- [ ] `:Diff target=... view=float` — same content as `inline` but in a
      floating window; `q`/`<Esc>` closes it. Confirm closing it disturbs
      nothing about the current window layout (that's the documented
      reason to reach for `float` specifically).
- [ ] If your buffer has any non-ASCII/multi-byte characters on a changed
      line (e.g. an emoji or accented character), confirm the word-diff
      highlight boundary lands on a whole codepoint, never splitting a
      multi-byte character across a highlighted/unhighlighted edge.

---

## 6. `:DiffOrig` — pre-write sanity check

**Steps**

- [ ] Edit a saved file without writing it, `:DiffOrig` — always opens a
      native diffmode split (never `inline`/`float`, even if
      `opts.diff.default_view` is set to one of those — `default_orig_view`
      is a separate setting).
- [ ] `:DiffClear` afterward — confirm the snapshot buffer `:DiffOrig`
      created is cleaned up (not left as a hidden/listed buffer), and that
      diffmode is turned off in every window it touched.

---

## 7. Directory diff

**Steps**

- [ ] `:Diff source=<dir1> target=<dir2>` where both resolve to real
      directories (two nearby commits' checkouts, or two similar plugin
      repos) — expect a per-file summary (`M`/`A`/`D` + `+added -removed`
      + path), not a meaningless single unified diff over concatenated
      bytes.
- [ ] Confirm hidden path segments (`.git`, `.hg`, …) are excluded from the
      comparison.
- [ ] Try `view=vsplit` alongside a directory diff — confirm `view=` is
      silently ignored (documented behavior) rather than erroring.
- [ ] `output=stat` on a directory diff — expect the rolled-up
      file-count + `+N -M` total, and (with `stat_list` on) one real
      jump-able entry per changed file, not one entry for the whole
      directory.

---

## 8. `http(s)://` URL sources

**Steps**

- [ ] `:Diff target=https://raw.githubusercontent.com/<any small public raw
      file> source=<a local copy>` — command returns control to the editor
      **immediately**; confirm the diff window/notification appears only
      once the background `curl` fetch resolves, not synchronously.
- [ ] Try chaining another command right after the `:Diff target=https://…`
      call in a script/macro — confirm it does **not** find the diff
      window already open (this is the documented async gotcha, not a race
      condition to "fix").
- [ ] Point at a URL that returns a non-2xx status — expect a clear error
      reported, not the error page's HTML diffed as if it were content.
- [ ] `:Diff target=https://... source=... output=stat` — same fast
      pre-check idea as §2, applied to a downloaded file before trusting
      it (e.g. a vendored dependency or install script).

---

## 9. Image comparison (via images.nvim)

**Steps**

- [ ] `:Diff target=<some>.png source=<other>.png` (two real raster
      images) — with `images.nvim` installed, expect a side-by-side
      gallery view, not a byte-level text diff. Confirm any `view=`/
      `output=` flag passed alongside is silently ignored.
- [ ] Without `images.nvim` installed (or temporarily disable it): same
      command — expect a **clear warning**, not a silent fallback into a
      meaningless raw-byte text diff.
- [ ] `opts.diff.image_compare = false` — re-run the same PNG pair, confirm
      it now does fall through to the old raw-byte text-diff path (the
      "mostly useless" behavior the docs describe, restored deliberately).
- [ ] A `.svg` pair should **not** trigger image comparison at all (SVG is
      text, and diffs as text) — confirm it goes through the normal
      text-diff pipeline instead.

---

## 10. Exit key: buffer scope vs. `native_diffthis`

**Steps**

- [ ] Open a diff via `:Diff`, then `<Esc><Esc>` — confirm it exits
      diffmode from that buffer.
- [ ] With `exit.scope = "buffer"` (default), try `<Esc><Esc>` on a plain,
      **native** `:diffthis`/`:diffthis` pair opened entirely outside
      diff.nvim — confirm the key does **nothing** there (documented gap,
      not a bug) unless `native_diffthis` is enabled.
- [ ] `opts.exit.native_diffthis = true` (needs `scope = "buffer"`), then
      repeat the native `:diffthis` case — confirm `<Esc><Esc>` now works
      there too, via the `OptionSet diff` watcher.
- [ ] `:DiffExit` directly — confirm it exits diffmode regardless of how
      the key/scope is configured, including with `exit.scope = false`.

---

## 11. `:DiffBuffers`, `:DiffClear`, picker resolution

**Steps**

- [ ] Open two or three buffers, `:DiffBuffers` — picker lists every other
      **listed, loaded** buffer (not the current one); pick one and
      confirm the diff opens with the current buffer as source.
- [ ] `:DiffClear` with several diff.nvim windows open at once (from
      different `:Diff`/`:DiffOrig` calls) — confirm all of them close and
      diffmode is disabled everywhere diff.nvim touched, without closing
      unrelated windows/buffers it didn't open.
- [ ] If `pickers.nvim` is installed and `use_pickers_nvim` is left at its
      default (`true`): trigger the picker (bare `:Diff`) and cancel it
      with `<Esc>`. Per the docs, pickers.nvim's underlying engines
      (telescope/fzf-lua/snacks) have **no reliable cross-engine cancel
      signal** — confirm the "Diff cancelled" notification from §1 may be
      **absent** here, and that this silence is expected, not evidence the
      command hung.

---

## 12. Statusline component

**Steps**

- [ ] `:lua print(require("diff").status())` with no diff active — expect
      an empty string.
- [ ] Open a `:Diff`, re-run the same `:lua print(...)` — expect
      `diff:N` where `N` is the count of active diff.nvim scratch buffers
      (open a second concurrent diff and confirm `N` increments).
- [ ] If a statusline plugin is wired to call this, confirm it actually
      shows/hides the indicator live as diffs open and close — otherwise
      this is a Lua-API-only check, which is fine to leave at that.

---

## 13. Renameable commands, and `opts.keymaps` shortcuts

Lowest priority — nothing is bound by default (`opts.keymaps = {}`), and
this config leaves it that way.

**Steps**

- [ ] Confirm no `diff`/`diff_head`/`diff_merge`/etc. keymaps exist in this
      config (`:verbose map <leader>d` or similar shows nothing bound by
      diff.nvim) — the plugin imposes none by design, and this config
      hasn't added any.
- [ ] Structurally only, unless you set one temporarily: `opts.keymaps =
      { diff_head = "<leader>xh" }` in a scratch config should bind a key
      that runs `:Diff target=git:HEAD` directly. Set a shortcut for a
      command whose `features.*` flag is off — expect a refusal warning at
      setup time, not a keymap that errors on first press.
