# Testing cmdlog.nvim

How to manually test every implemented feature of `cmdlog.nvim` —
interactive recall/reuse of `:` command-line history and shell history via
Telescope or fzf-lua, plus favorites, tags, project scoping, stats, and a
handful of safety features (risky-command highlighting, a privacy redact
filter). One-time setup, then one section per feature: steps, expected
result. Checkbox syntax (`- [ ]`) is standard Markdown, togglable with
`cascade.nvim`'s `<leader>tc` if that's bound.

Repo: `E:\repos\cmdlog.nvim`. Spec: `plugins/personal/init.lua` —
`lazy = false`, `opts = {}` (picker defaults to `"telescope"`). This is
**deliberate, not just "no lazy trigger configured"**: a comment right
above the spec explains why — `setup()` starts the `CmdlineLeave` tracker
that records every `:` command, so lazy-loading on a command/key would
mean everything typed before the first `:Cmdlog` invocation is simply
missing from the history. No `keymaps` table is set, so the optional
which-key-aware entry-point keymaps (`opts.keymaps`) are **not** active in
this config — every test below goes through `:Cmdlog <subcommand>`
directly, not a bound key.

**Beta-stage warning from the README applies directly here**: "Expect
bugs, especially with the history feature on Windows systems" — this
machine is Windows, so the shell-history and `histdel()` paths below are
exactly where to look first if something misbehaves.

## Setup

```vim
:checkhealth cmdlog
```

**Expect**: Neovim version, `lib.nvim` presence (required — the `:Cmdlog`
command tree is built on `lib.nvim.bindings.usercmd.composer`), which
picker backend is configured (`telescope`, the default here) and whether
it's actually installed, and shell-history detection — on Windows this
should report the PowerShell `PSReadLine` history file
(`%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`),
not one of the POSIX shell paths.

Run a handful of real `:` commands first (`:w`, `:e somefile`, a couple of
`:lua` ones) so the pickers below have something real to show — the
tracker only ever has what's been typed since this session's `setup()`
ran.

---

## 1. Bare `:Cmdlog` — the everyday entry point

**Why first**: per `docs/WORKFLOW.md`, this is meant to be the default
reflex ("don't pick a subcommand first"), and telemetry confirms the
background tracker is genuinely active on this machine (71 sessions,
`core.store.save_json` ×43, `core.project_history.record` ×20,
`core.stats.record` ×20) even though no picker-open call itself was
captured — worth specifically confirming the picker side actually works,
not just the recording side.

- [ ] `:Cmdlog` (no args) → combined favorites + history, **deduplicated**
      (each command shown once, most recent occurrence kept).
- [ ] `<CR>` on an entry → inserts it into the `:` cmdline **without
      executing** — confirm nothing runs automatically.
- [ ] `<Tab>` on an entry → toggles favorite status; reopen `:Cmdlog
      favorites` and confirm it now appears there with a `★`.
- [ ] `<C-r>` → refreshes the picker in place (run a new `:` command in
      another window first, then refresh, confirm it now appears).
- [ ] In the **combined** picker specifically, confirm each non-favorite
      entry is labeled `nvim`/`shell`/`extra` by origin, and (Telescope
      only) a `── nvim history ──`-style divider row appears before each
      origin block — but only once you've confirmed at least two origins
      are non-empty; a single-origin list should show no dividers at all.
      Start typing in the prompt and confirm the divider rows disappear
      (they have an empty `ordinal`, dropped by the fuzzy sorter).

---

## 2. Favorites — toggle, tag, undo, reorder, export/import

Zero direct telemetry for the UI layer, but this is the feature the
README leads with structurally (five bullet points), and `docs/WORKFLOW.md`
walks through it as "a real combo" end to end.

- [ ] `:Cmdlog shell` → find a real shell command, `<Tab>` to favorite it.
- [ ] `:Cmdlog favorites` → the favorited command appears, `★`-marked.
- [ ] `<C-t>` on it → prompts for a free-form tag; confirm the tag shows
      alongside the entry afterward.
- [ ] `<C-e>` → add/edit a note via `vim.ui.input()`; submit a blank input
      on an existing note → confirm it **removes** the note, not just
      leaves it unchanged.
- [ ] `<C-g>` → peeks the note in a floating popup (Telescope only).
- [ ] `<C-z>` right after a `<Tab>` toggle → undoes just that one toggle
      (single-level only — toggle two different entries, `<C-z>` once,
      confirm only the **second** toggle is undone, not both).
- [ ] `<C-Up>`/`<C-Down>` in the favorites picker → reorders the selected
      entry in the **persisted** list order (display order here is that
      persisted order, unlike other pickers' Telescope-sort order — close
      and reopen `:Cmdlog favorites` to confirm the new order survives).
- [ ] `:Cmdlog export` (no path) → writes `<favorites path>.export.json`;
      check the file exists and contains real JSON.
- [ ] Favorite one more command, then `:Cmdlog import <that exported
      path>` → confirm the **existing** favorites are kept, the
      previously-exported ones merge in additively, no duplicates.

---

## 3. `:Cmdlog project` and `:Cmdlog stats` — the two derived views

Direct telemetry evidence the recording pipeline runs
(`core.project_history.get_git_root`/`.record`, `core.stats.record`, 20
calls each) — worth confirming the **read** side matches what's being
written.

- [ ] From inside a real Git repo, run a few `:` commands, then
      `:Cmdlog project` → shows exactly those commands, deduplicated.
- [ ] Run `:Cmdlog project` from **outside any Git repo** (a scratch
      buffer with no `.git` upward) → a clear notify, not an empty picker
      or an error.
- [ ] Run `:Cmdlog project` from a **second, unrelated** repo → confirm it
      shows only that repo's own recorded commands, not the first one's
      (per-project isolation).
- [ ] `:Cmdlog stats` → commands sorted by usage frequency, each annotated
      `[used Nx, last <date>]`. Run the same command 3 times, re-open
      stats, confirm the count actually incremented and it moved toward
      the top.
- [ ] `:Cmdlog lua` after running a few `:lua`/`:lua=`/`:=` commands →
      shows only those, nothing else.

---

## 4. `full`/`-full` variants — duplicates preserved on purpose

- [ ] Run the exact same `:` command 3 times in a row, then `:Cmdlog nvim`
      → appears **once** (dedup, most recent kept). `:Cmdlog nvim-full` →
      appears **3 times**. Same pairing for `:Cmdlog shell` vs.
      `shell-full`, and `:Cmdlog` vs. `:Cmdlog full`.

---

## 5. Safety features — risky-command highlighting and the redact filter

Both exist specifically to keep a history picker from being the thing
that hurts you — worth exercising deliberately, not assuming they work.

- [ ] Run (or just have present in history) something matching a risky
      pattern — `git reset --hard`, `rm -rf`, `:qa!` — and open a picker
      containing it (Telescope only). Confirm it's visually flagged with
      the `CmdlogRiskyCommand` highlight, distinct from ordinary entries.
- [ ] `:Cmdlog risky test git reset --hard HEAD~3` → reports which
      pattern(s) matched, independent of whether `highlight_risky` is on
      or off (this usercmd evaluates regardless — confirm it says so if
      you've turned `highlight_risky` off).
- [ ] Run a command containing a secret-shaped string, e.g.
      `:!curl -H "Authorization: Bearer sk-fake-test-token"` → confirm it
      does **not** show up in `:Cmdlog stats` or the error log afterward
      (redacted from cmdlog's own JSON stores) — but **does** still show
      up in plain Neovim `:` history / shell history if you check those
      directly (the docs are explicit this filter protects cmdlog's own
      storage only, not the underlying history sources).

---

## 6. Deleting entries — `<C-x>`, including the Windows shell-history path

Beta-warned as the most Windows-fragile area — worth testing directly on
this machine rather than trusting it works.

- [ ] `<C-x>` on a Neovim `:` history entry → removed via `histdel()`, no
      confirmation prompt; re-run `:Cmdlog nvim` and confirm it's gone.
- [ ] `<C-x>` on a **shell** history entry (PowerShell's `PSReadLine`
      file on this machine) → should prompt for confirmation before
      touching it (rewrites a real file on disk). Confirm the entry is
      actually gone from the file afterward, and that declining the
      prompt leaves the file untouched.
- [ ] `<C-Space>` to mark several entries, then `<C-x>` → deletes every
      marked entry in one pass, not just the one under the cursor.

---

## 7. Cycling sources and previews (Telescope-only features)

- [ ] Mid-search in `:Cmdlog nvim` with some prompt text typed, `<C-s>` →
      rotates to the next picker (nvim → shell → favorites → project →
      back to nvim) **keeping the typed prompt text** — confirm the text
      survives the rotation, not just that the picker switches.
- [ ] Highlight (don't select) an `:edit <realfile>` entry → live file
      preview in the Telescope preview pane.
- [ ] Highlight a `:help <topic>` entry → preview renders the real help
      page (via a headless Neovim instance — allow a moment for it).
- [ ] Highlight a `:lua <expr>` entry → preview shows the evaluated
      result.
- [ ] Switch `picker = "fzf"` (scratch config) and repeat a couple of the
      above — confirm previews still work on Windows are **not**
      available (documented limitation: fzf-lua's shell-command preview
      mechanism isn't supported there), rather than silently broken.

---

## 8. Known-error highlighting

- [ ] Run a `:` command that deliberately errors (a typo'd command name).
      Reopen a picker containing it (Telescope only) → flagged with a `✗`
      marker/highlight, confirming `vim.v.errmsg` detection (deferred via
      `vim.schedule()`) actually caught it.

---

## 9. `extra_files` and project-scoped favorites (opt-in, off by default)

Lowest priority — neither is enabled in this config's `opts = {}`.

- [ ] `opts.extra_files = { "path/to/some.txt" }` (scratch config) → its
      lines appear in the combined pickers labeled `extra`, read-only
      (confirm `<Tab>`/`<C-x>` are no-ops on an `extra`-origin row, or at
      least don't corrupt the source file).
- [ ] `opts.project_scoped.enabled = true` (scratch config), favorite
      something inside a Git repo, then open `:Cmdlog favorites` from
      **outside** any repo → falls back to the global favorites file
      (not an empty one) — the specific trap `docs/WORKFLOW.md` calls
      out: a missing favorite here usually means "wrong repo", not "lost
      data".
