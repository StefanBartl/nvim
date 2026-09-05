# Testing insights.nvim

How to manually test every implemented feature of `insights.nvim`.
One-time setup, then one section per feature: prerequisites, steps, what
to expect.

Repo: `$REPOS_DIR\insights.nvim`. Spec: `plugins/personal/init.lua`
(`lazy = false` — not command-lazy, because the `conflicts`/`unimported`/
`devserver` autocmds have to be registered by `setup()` before the events
they listen for can fire; loading on `cmd = "Insights"` would mean they
never trigger at all).

## Setup

Already wired into this config — nothing extra to install.

```vim
:checkhealth insights
```

**Expect**: `rg` found (hard dependency — everything symbol/import-related
needs it), `dot`/Graphviz optionally reported (needed only for `:Insights
imports graph`), `lib.nvim` deps OK.

**A documentation/code discrepancy worth knowing before you start**:
`docs/BINDINGS.md` states the three automatic triggers are "gated by their
own `enable` key (all off by default)". That's not what
`lua/insights/config/DEFAULTS.lua` actually ships — `conflicts.enable`,
`unimported.enable` and `devserver.enable` all default to **`true`**, and
this config's own spec (`opts = { symbols = { progress_style =
"statusline" } }`) doesn't override any of them. So in this real session
all three are live from startup, not opt-in. The telemetry backs this up:
`devserver.consider`/`match`/`chan_cmd` (23 calls each) and
`devserver.kill_all` (78 calls) already have real activity across 82
sessions — meaning this is not a theoretical feature to switch on, it has
been running silently the whole time.

---

## 1. Automatic triggers — the features already running without being asked

These are the highest-priority section precisely because they're silent:
if one of them is subtly broken, nothing will ever tell you except a
missing quickfix list or a server left running.

### 1a. `conflicts` (`VimEnter`)

**Steps**

1. In a real git repo, deliberately create an unmerged conflict (start a
   merge/rebase that conflicts, or `git checkout --conflict=merge <path>`
   on a file with diverging history).
2. Quit and reopen Neovim from that repo (`VimEnter` only fires on a fresh
   start, not `:Insights conflicts` — that's the same underlying call but
   manual, see §7).

**Expect**: quickfix list populated with the conflicting file(s),
`:copen` opens automatically (`conflicts.open_qf = true`), and a notify
naming the files (`conflicts.notify = true`). On a clean repo or outside
git entirely: silent, no quickfix, no notify.

### 1b. `unimported` (`BufWritePost`)

**Prerequisites**: a buffer of one of `unimported.filetypes` — `astro`,
`javascriptreact`, `typescriptreact`, `vue`, `svelte`.

**Steps**

1. Open/create a `.tsx` file with a component tag that isn't imported or
   locally declared: `<Card />` with no `import Card` anywhere in the
   file.
2. `:w`.

**Expect**: a warning naming `Card` as used-but-unimported. Add the
import (or a local `const Card = ...`), save again — warning gone. A
lowercase tag (`<div>`) should never trigger this (HTML elements are
ignored by design). Since this is a textual check, not a type-checker,
it's expected to have false positives on generated/re-exported bindings —
that's what `unimported.ignore` is for, not a bug to chase.

### 1c. `devserver` (`TermOpen`/`TermRequest`/`VimLeavePre`)

**Steps**

1. `:terminal npm run dev` (or any command containing one of
   `devserver.patterns`: `astro dev`, `vite`, `pnpm dev`, …) — starting it
   *as the terminal's command* is the reliable trigger; typing it into an
   already-open shell only works if the program sets the terminal title
   via OSC 0/2.
2. A confirm prompt (`lib.nvim.ui.kit`) should appear asking whether to
   kill this server on exit. Answer yes.
3. `:Insights devserver list` — should show the tracked terminal.
4. Quit Neovim entirely (not just `:bd` the terminal buffer).

**Expect**: on quit, the server's process tree is killed
(`taskkill /T` on Windows, this machine's platform) — verify with Task
Manager/`Get-Process` that the `npm`/`node` process is actually gone
after Neovim exits, not just the terminal buffer closed.

**Also check**: start a second matching terminal, answer **no** (or
`<Esc>`) to the prompt — that one should survive Neovim's exit. And
confirm you're asked only **once** per terminal: change the terminal's
title again after answering (if the program re-emits OSC 0/2) and verify
no second prompt appears.

**Also check the scope boundary**: a dev server started in a terminal
*outside* this Neovim instance (a separate PowerShell window, or a tmux
pane) must never be touched — this is a deliberate trade-off the docs are
explicit about (no `pkill`-style sweep by name).

---

## 2. `:Insights symbols` — the flagship feature

Has its own dedicated keymaps (`<leader>ps` telescope, `<leader>pS`
fzf-lua) unlike anything else in this plugin — the README leads with it.

**Steps**

```vim
:Insights symbols
:Insights symbols buffer
:Insights symbols cwd telescope
:Insights symbols cwd fzf
:Insights symbols rebuild
:Insights symbols buffer tables
:Insights symbols buffer strings
```

Or `<leader>ps` / `<leader>pS` directly.

**Expect**: a picker (telescope/fzf-lua/scratch, whichever is available —
"best available" is the documented default resolution) listing functions
with real type labels (`local`/`global`/`module`/`method`/`anonymous`/
`exported`). `<Enter>` jumps to the real definition line. `tables`/
`strings` need `nvim-treesitter` with the `lua` parser — try them without
it once (temporarily disable the parser) and confirm a clear message
rather than an empty, unexplained picker.

**Cache**: `:Insights symbols rebuild` should visibly take longer (forces
a fresh `rg` pass) than a plain `:Insights symbols` right after (should
hit `cache.ttl_seconds`, default 3600s, and return fast). `:Insights cache
info` should show real stats after either; `:Insights cache clear` then
`:Insights symbols` again should be slow again (cache genuinely gone).

---

## 3. `:Insights imports` — the most elaborate single feature

**Steps**

```vim
:Insights imports
:Insights imports lua
:Insights imports lib
:Insights imports reverse insights.config
:Insights imports unused
```

**Expect**: a scratch report with **Count** (module, occurrence count,
language tag, `(extern)` where no local file matches) and **Occurrences**
(`path:line [lang] module imported-name (.field)`) sections. `gf` on an
occurrence line jumps to that `path:line`.

**Go-to-definition (Lua only)** — the part worth checking carefully since
it resolves *without* executing `require(...)`:

1. On an **Occurrence** line naming a specific field (e.g.
   `insights.util.notify   notify (.create)`), press `gd`.
2. On a **Count** line (just the module), press `gd`.

**Expect**: step 1 opens the field's own definition (`function M.create`
inside `notify.lua`), not just the module file — this is Tree-sitter-
accurate field location, worth confirming it lands on the exact
function line, not just "somewhere in the file". Step 2 opens the module
file itself. `gp` should always float-preview regardless of
`imports.definition.view`. On a **non-Lua** occurrence, both should just
notify "not supported yet" rather than erroring or silently doing
nothing.

**Filters**: `:Insights imports lib foo.bar` (two filters, OR-combined) —
confirm the report only contains entries matching either. `:Insights
imports lua python` should scope to those two languages' entries only —
try this against a real polyglot tree if one is on hand (none of the
current four plugins are polyglot, so this may need `documentation.nvim`
or another repo with JS/TS to see non-Lua rows at all).

**Graph**: `:Insights imports graph` — needs Graphviz (`dot`) on PATH.

**Expect**: a PNG rendered to `imports.graph.outdir`, shown inline via
`images.nvim` (installed in this config) if `images.nvim`'s own draw path
works (see `images.md` in this same folder) — otherwise just a reported
file path. External modules should **not** appear as nodes
(`include_external = false` is the default) — confirm the graph shows
only project files, not a cluttered mix of `vim`/stdlib nodes.

---

## 4. `:Insights metrics`

**Steps**

```vim
:Insights metrics
:Insights metrics --lua-only --no-top
:Insights metrics --current
```

**Expect**: a scratch report with per-file/per-folder line/word tables,
ratio analysis, top-N lists — written to `metrics.output_file`
(`{state}/insights/metrics.md`). Confirm the file actually landed there.
Try ending an explicit output path in `.pdf` (needs `pdfport.nvim`,
installed here) — should produce a real PDF via pandoc rather than a
plain-text file with a `.pdf` extension.

**Also check `--current`**: run it from a buffer, confirm the report is
scoped to just that one file's numbers, not the whole cwd.

---

## 5. `:Insights tree` / `count` / `clipboard`

**Steps**

```vim
:Insights tree
:Insights count
:Insights clipboard
```

**Expect**: `tree` writes a real file tree to `tree.outdir` (check the
file exists after). `count` reports a file count matching what you'd
expect from the project (excluding `.git`/`node_modules`/`.cache` per
`tree.exclude_patterns`). `clipboard` — paste (`p`) afterward and confirm
the tree text is genuinely on the system clipboard, not just the internal
register.

---

## 6. `:Insights fileinfo`

**Steps**

`<leader>fi` or `:Insights fileinfo`, twice in a row.

**Expect**: a float with `fs.stat` info (size, mtime, permissions) for
the current buffer's file. Second press **toggles it closed** — confirm
it's a real toggle, not two floats stacking.

---

## 7. `:Insights conflicts` / `:Insights unimported` — manual invocation

Same underlying logic as §1a/§1b, invoked directly rather than via the
autocmd — mainly worth confirming the manual path behaves identically
(same quickfix/notify shape) when called outside `VimEnter`/
`BufWritePost`.

---

## 8. `:Insights compress`

**Steps**

```vim
:Insights compress
```

from a small real directory (not this plugin's own huge tree — pick
something modest to keep the archive quick).

**Expect**: on this Windows machine, uses the `powershell` engine
(`compress.engine = "auto"` resolves to PowerShell on Windows per the
docs) and produces a `.zip` inside a `compressed/` subdirectory, alongside
a `file-list.txt`. Confirm `.git/` is excluded from the archive contents.
`:Insights compress . <outdir>` — archive should land in `<outdir>`
instead of the default location.

---

## 9. `:Insights devserver list` / `kill` — manual invocation

Covered mostly by §1c's automatic path; the manual command is worth a
quick separate check:

```vim
:Insights devserver list
:Insights devserver kill
```

**Expect**: `list` shows currently tracked terminals even before Neovim
exits (not just at `VimLeavePre`). `kill` should terminate them
immediately, on demand, rather than waiting for exit — confirm the
process is actually gone right after running it, not just marked for
later cleanup.
