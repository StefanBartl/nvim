# Testing replacer.nvim

How to manually test every implemented feature of `replacer.nvim`.
One-time setup, then one section per feature: prerequisites, steps, what to
expect.

Repo: `$REPOS_DIR\replacer.nvim`. Spec: `plugins/personal/init.lua`
(`cmd = { "Replace", "Replacer", "Surround", "Wrap" }`, deps `fzf-lua` +
`lib.nvim`, `opts = { engine = "telescope", progress_style = "statusline" }`
— **note the engine is pinned to Telescope even though `fzf-lua` is also a
dependency here**; this matters for §11 below).

## Setup

```vim
:checkhealth replacer
```

**Expect**: Neovim >= 0.9 OK, `lib.nvim` OK (hard dependency for the whole
command layer — no `:Replace` at all without it), ripgrep found (version +
JSON support probed live), both pickers checked but only `engine = "telescope"`
matters here (should read "Picker engine: telescope", not "auto"), UTF-8
byte-index support OK, `lib.nvim.progress` OK (progress_style functional),
which-key optional. Also runs the composer's own pre-flight for `:Replace`
and `:Surround`.

Good test targets: `recommender.nvim`'s or `replacer.nvim`'s own repo (both
real, git-tracked Lua trees you already have) for anything that needs a
real project; a disposable scratch buffer for single-file tests you don't
want touching a real repo.

**Telemetry note**: only 4 accumulated sessions (74 instrumented
functions), too thin to rank features against each other in general, but
what little fired lines up with the obvious core path:
`command.parse_request`, `command.resolve_scope`, `rg.collect_async`,
`apply.apply_matches`, `history.add/load` — i.e. someone ran a real
`:Replace`, picked matches, applied, and it landed in history. The 1432
`encoding.strip_cr` calls are a per-line hot path inside file reading, not
a feature signal. Everything past the core flow (checkpoints, batch,
fnames, LSP rename, presets, hooks) has zero telemetry — with 4 sessions
that means "not exercised recently," not "unused"; ordering below follows
the README/WORKFLOW's own structure and depth of coverage instead.

---

## 1. `:Replace` — the core search/pick/apply flow

**Steps**

```vim
:Replace foo bar %
```
in a buffer containing a few occurrences of `foo`.

**Expect**: a Telescope picker opens (per the pinned `engine = "telescope"`
— confirm it's genuinely Telescope's UI, not fzf-lua's, since the opts
comment notes the plugin's own default would have been `"auto"` → fzf-lua
first) listing each occurrence as its own entry with a live preview and
`preview_context` lines of context. `<Tab>`/`<S-Tab>` toggle-select and
move; `<CR>` applies to the selection (or the single entry under cursor if
nothing is multi-selected). Confirm the buffer's `foo` occurrences you
selected became `bar`, and any you didn't select are untouched.

**Also check** `<C-a>` (apply ALL, should hit the `confirm_all` prompt
first since that defaults `true`) and `<C-r>` (apply the entry under
cursor, then reopen the picker with the remaining matches — confirm the
just-applied entry is genuinely gone from the reopened list, not just
visually skipped).

---

## 2. Scope — `%` / `cwd` / `.` / `root`

**Steps**

```vim
:Replace foo bar cwd
:Replace foo bar root
:ReplaceRoot foo bar
```

**Expect**: `cwd` scans the working directory; `root` auto-detects a
project root by walking up for `.git`/`package.json`/`go.mod`/etc. and, on
several nested candidates (e.g. a monorepo package folder), deterministically
prefers the outermost one with `.git` — **no prompt**, per the README.
`:ReplaceRoot` is the interactive counterpart: same grammar minus the scope
positional, and **does** prompt when detection finds more than one
candidate. Confirm the two genuinely differ in exactly that (silent
resolution vs. an explicit picker) rather than behaving identically.

---

## 3. `--dry` and `--export`

**Steps**

```vim
:Replace foo bar . --dry
:Replace foo bar . --dry --export=/tmp/rename.patch
:Replace foo bar . --dry --export=/tmp/plan.json
```

**Expect**: `--dry` shows a stats + diff summary and writes nothing —
confirm the target file(s) are genuinely untouched on disk afterward.
`--export=<path>.patch` writes a real git-applyable patch (try
`git apply --check /tmp/rename.patch` in a real repo); `--export=<path>.json`
writes structured plan data instead. `--export` should always imply `--dry`
even without typing it explicitly — try `--export=...` alone (no `--dry`)
and confirm it still doesn't write to the real files.

---

## 4. `--all` / `!` — non-interactive apply, and `--checkpoint` + `:ReplaceUndo`

**Steps**

```vim
:Replace foo bar % --all --checkpoint
```
then, after confirming the change:
```vim
:ReplaceUndo
```

**Expect**: `--all` (or `:Replace!`) skips the picker and applies to every
match directly, respecting `confirm_all` first. `--checkpoint` snapshots
every about-to-be-touched file under
`stdpath("data")/replacer/checkpoints/<id>/` before writing — confirm a new
checkpoint directory actually appears. `:ReplaceUndo` (no id) restores the
**most recent** checkpoint byte-exact; `:ReplaceUndo <id>` (tab-completes
over real saved ids) restores a specific one. Confirm the restore is a
plain file write-back, not a git operation — check `git status` before and
after and confirm nothing about the git index changed, only the file
contents.

---

## 5. `--to-quickfix` / `--to-loclist`

**Steps**

```vim
:Replace TODO DONE . --to-quickfix
```

**Expect**: the quickfix list opens with every match, navigable via
`:cnext`/`:cprev` — and **nothing was written**. Confirm re-running the
identical `:Replace TODO DONE .` without the flag genuinely applies it (the
quickfix run was purely a review step, not a stateful first phase).

---

## 6. `:Surround` / `:Wrap` — wrap every match

**Steps**

```vim
:Surround word `
:Surround word b        " alias for backtick, same result
:Surround "foo bar" ** cwd
:Surround word           " no delimiter — should prompt "Surround with: "
```

**Expect**: each occurrence of `word` wrapped as `` `word` ``. The alias
form (`b`/`q`/`s`/`star`/`bold`/`italic`/`paren`/`bracket`/`brace`/`angle`)
resolves to the same literal delimiter as typing it directly. Omitting the
delimiter prompts rather than erroring.

**Also check idempotency** — the concrete, code-grounded claim worth
verifying: run `:Surround test **` on a line that already reads `**test**`
and confirm it stays exactly `**test**` (not `****test****`). Then run
`:Surround test ** --nested` on the same line and confirm it *does* add
another layer this time.

**Also check the charwise-selection narrowing**: on a line with `foo bar
foo baz`, visually select (`v`) just the first `foo` (single line,
charwise) and `:'<,'>Surround foo *` — only that one occurrence should be
wrapped. Redo with a linewise `V` selection instead — now every `foo` on
that line should wrap, not just the selected one. This distinction is easy
to get backwards by accident; worth confirming it's the right way round.

---

## 7. Regex mode, backreferences, and the two regex helper commands

**Steps**

```vim
:Replace '\(\w\+\)=\(\w\+\)' '\2_\1' % --regex
```
on a line containing `foo=bar` (expect `bar_foo` after applying).

```vim
:ReplaceEscape some.special+text
:ReplaceTest '\d\+' 'abc123def'
```

**Expect**: the backreference substitution works as shown. `:ReplaceEscape`
echoes the escaped pattern and copies it to the unnamed register — paste
(`p`) somewhere and confirm it matches what was echoed. `:ReplaceTest`
opens a small floating panel; typing in the pattern (line 1) live-highlights
matches against the sample (line 2) as you type, `<Esc>`/`q` closes it.

---

## 8. History and presets

**Steps**

1. Run a real `:Replace foo bar %` (apply it).
2. `:ReplaceHistory`.
3. `:ReplaceSavePreset test-preset foo bar % --type=lua`
4. `:ReplacePreset test-preset` (try `<Tab>` completion on the name first).

**Expect**: step 2 opens a `vim.ui.select` over the last (up to 50) real
applies — picking one re-runs it exactly. Confirm a `--dry`/`--export`/
`--to-quickfix` run does **not** show up in history (README states history
only records real applies). Step 4 re-runs the saved preset's exact
old/new/scope/flags without retyping them — confirm the flags (`--type=lua`
here) actually carried over, not just old/new/scope.

---

## 9. `:ReplaceBatch` — multiple pairs in one run

**Steps**

Create a scratch file `pairs.txt`:
```
fooOld => fooNew
barOld => barNew
```
then:
```vim
:ReplaceBatch pairs.txt % --dry
:ReplaceBatch! pairs.txt %
```

**Expect**: each pair runs as its own full `:Replace` dispatch, sequentially,
inheriting the passed flags. `--dry` shows the combined plan without
writing; the bang form applies both non-interactively. Try the same with
`clipboard`/`+`  and `qf`/`quickfix` as the source, and a JSON-array-shaped
file (`[{"old":"a","new":"b"}]`, auto-detected by the leading `[`) — confirm
all three source forms parse correctly.

---

## 10. `:ReplaceFNames` and `--also-rename-file`

**Steps**

In a scratch directory, create `old_widget.lua` and a subdirectory
`old_widget/` with a file inside it.

```vim
:ReplaceFNames old_widget new_widget . --dry
:ReplaceFNames! old_widget new_widget .
```

**Expect**: `--dry` previews every rename first. The real run renames both
the file and the directory — confirm the **nested** case behaves as
documented: when a directory match contains a file whose name also
matches, only the outer (directory) rename happens this pass, the inner
file just moves along for free (re-run afterward if its own name still
matches and you want it renamed on its own).

**`--also-rename-file`** (single-file scope only):
```vim
:Replace MyWidget MyButton % --also-rename-file --all
```
on a buffer literally named `MyWidget.lua`. **Expect**: after the content
replace, a prompt "Also rename MyWidget.lua -> MyButton.lua?". Try it on a
buffer whose basename does **not** contain `MyWidget` — expect no prompt
at all (a documented no-op), and try it with a directory scope — expect it
to refuse (single-file only, `:ReplaceFNames` is the tree-wide tool).

---

## 11. Soft LSP integration — `--lsp`

**Prerequisites**: a buffer with an attached LSP client that supports
`textDocument/rename` (any Lua file in a repo with `lsp.nvim`'s LuaLS
attached works).

**Steps**

```vim
:Replace oldFn newFn % --lsp --all
```
on an identifier used across a couple of files/scopes the LSP can see.

**Expect**: a real workspace-wide symbol rename via the LSP client, not a
plain text substitution — check it renamed the symbol correctly scoped
(didn't touch an unrelated string/comment containing the same text).
Then try `--lsp` on a **non-identifier** match (e.g. a chain like
`"old-fn-name"` with a hyphen, or a multi-word phrase) — expect it to fall
back to a plain text replace for that match specifically, with no error
and no visible difference in the notification style (mixed LSP/plain
results in one run is documented as normal).

---

## 12. Hooks

**Steps**

```lua
require("replacer").setup({
  hooks = {
    before_apply = function(ctx)
      if ctx.path:match("%.generated%.lua$") then return false end
    end,
    after_write = function(ctx)
      if ctx.ok then vim.notify("wrote " .. ctx.path) end
    end,
  },
})
```

**Steps**: run a `:Replace` that matches both a `.generated.lua` file and a
normal one, `--all`.

**Expect**: the `.generated.lua` file is **skipped** (vetoed by
`before_apply` returning `false`), the normal file gets replaced and the
`after_write` notification fires for it. Then deliberately make a hook
`error()`: confirm it's caught and warned, and the **rest of the apply
still completes** — this is the concrete claim worth checking, since a
naive implementation might abort the whole run on one hook's error.

---

## 13. Flags that compose — `--changed`, `--safe`, `--confirm-per-file`, `[range]`

**Steps**

```vim
:Replace foo bar . --changed=modified,staged --dry
```
(needs a real git repo with at least one modified/staged file matching
`foo`)

```vim
:Replace foo bar . --safe --confirm-per-file --all
:'<,'>Replace foo bar --dry
```

**Expect**: `--changed` intersects with (never widens) the resolved scope
— combine with `--type=lua` and confirm it's still just changed `.lua`
files. `--safe` removes oversized/read-only/binary files from
consideration *before* `--confirm-per-file` prompts, so you should never
be asked to confirm a file that `--safe` already excluded. `[range]`
(visual selection then `:'<,'>Replace`) restricts matching to just those
lines regardless of scope — confirm a match just outside the selected
range is excluded.

---

## 14. Progress indicator (`progress_style = "statusline"`)

This config pins `progress_style = "statusline"` (draws nothing itself —
you read live text from your own statusline component).

**Steps**

Trigger a `cwd`-scope search on a large-ish tree (this repo or
`$REPOS_DIR\lib.nvim` work) — something that takes a couple of seconds.

```lua
:lua print(vim.inspect(require("lib.nvim.progress.styles.statusline").active()))
```
run while the search is still in flight.

**Expect**: `active()` returns a non-empty string array while the search
runs (e.g. `"[replacer] N match(es) found... (x/y)"`), and an empty table
once it finishes. Since this is headless (no custom statusline component
wired up in this config to display it), this is the one place structural
verification stands in for a visible UI — confirm the data updates live by
polling `active()` a few times during a slow search, rather than assuming
the plumbing works.

---

## 15. `:ReplaceDebug` (developer utility)

**Steps**

```vim
:ReplaceDebug status
:ReplaceDebug on
:ReplaceDebug test
:ReplaceDebug analyze <line> <pattern>
:ReplaceDebug off
```

**Expect**: `on`/`off` toggle debug logging, `status` reports current
state, `test`/`inspect`/`analyze` are diagnostic aids for match matching —
not something you'd use day to day, but worth a quick pass since it's a
real registered command and easy to overlook.
