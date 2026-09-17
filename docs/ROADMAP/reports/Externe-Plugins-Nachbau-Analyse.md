# External plugins — rebuild analysis

**Date:** 2026-09-17
**Scope:** every third-party plugin declared under `lua/plugins/**` of this config,
matched against the 37 own `*.nvim` repositories in `$REPOS_DIR`.
**Goal:** fewer external dependencies, and the features worth keeping pulled into
the own plugins that already own that problem domain.

---

## 1. Method, and what this report is not

What was actually checked:

- The full external spec set was extracted from `lua/plugins/*.lua`
  (54 third-party repositories, including pure dependency repos such as
  `plenary.nvim`, `nui.nvim` and `volt`).
- For every own plugin, the README one-liner **and the real module layout**
  (`lua/<name>/**`) were read, so the overlap verdicts below rest on modules that
  exist on disk, not on what a README promises.
- Where the overlap claim was load-bearing, the config's own wiring was read too
  (`lua/plugins/markdown.lua`, `webdev.lua`, `workflow.lua`, `misc.lua`,
  `snacks.lua`, `ui.lua`, `git.lua`, `lua/config/harpoon/**`).

What was **not** done, and is explicitly out of scope: no feature-by-feature
diff of large plugins. Nobody enumerated all of `snacks.nvim`'s modules,
`noice.nvim`'s routes or `telescope`'s extension surface. The verdicts here are
about the *obvious* overlaps — the ones where an own plugin already has a module
directory for exactly that job. Anything marked **"needs a closer look"** below
is a judgement that has not been verified against the external plugin's source.

Effort estimates are in **working sessions** (one focused sitting, roughly a
half day), not calendar time, and they assume `lib.nvim` is available — which
materially changes the picture, see §3.

---

## 2. The numbers

| | Count |
|---|---|
| Third-party repos in the config | **54** |
| Of those, realistic full replacements | **9** |
| Realistic partial replacements (feature harvest) | **11** |
| Keep — rebuild is not worth it | **34** |

Nine full removals is a meaningful cut, and five of them are in the cheap tier.

---

## 3. Why the effort numbers are lower than they look

`lib.nvim` already carries the infrastructure that usually *is* the work in a
rebuild of this kind. Its `lua/lib/nvim/` alone has, among 45 modules:

`terminal/`, `window/`, `ui/`, `notify/`, `progress/`, `async/`, `debounce/`,
`git/`, `net/`, `treesitter/`, `frecency/`, `fs/`, `store/`, `cache/`,
`image_preview/`, `usercmd/`, `map/`, `cross/`, `logger/`

and `lua/lib/lua/` adds `json/`, `yaml/`, `xml/`, `diff/`, `time/`, `uuid/`,
`strings/`, `tables/`, `range/`, `memo/`.

Concretely: a floating terminal, a window picker, an async job, a debounced
autocmd, a notification and a progress bar are all *already solved*. That is why
`lazygit.nvim` and `nvim-window-picker` land in the one-session tier — the
rebuild is wiring, not engineering.

It also means `plenary.nvim` is technically redundant for own code: `lib.nvim`
covers path, job, async and serialization. See the finding in §7.

---

## 4. Tier A — do these: high value, low effort

Ordered by value per session spent.

### A1 · `lima1909/resty.nvim` → **runtime-analysis.nvim** · full replacement

**Benefit: very high. Effort: 1–2 sessions. Risk: low.**

`runtime-analysis.nvim` already has, as its own top-level modules:
`curl.lua`, `runner.lua`, `parse.lua`, `env.lua`, `graphql.lua`,
`multipart.lua`, `assertions.lua`, `history.lua`, `view.lua`, `inspect.lua`.
That is a complete REST client. resty is a second one sitting next to it.

The decisive argument is in the config's own comment in
[webdev.lua](lua/plugins/webdev.lua): resty cost roughly **600 ms of startup**
because loading it drags in telescope, nvim-cmp and LuaSnip through its
`plugin/` and `after/plugin/` files, defeating their own lazy triggers. The
current spec is an elaborate `vim.filetype.add` + autocmd workaround built
purely to contain that damage. Deleting resty deletes the workaround too.

What is actually missing on the own side before removal: the `.http`/`.resty`
buffer format — parsing a request out of the file under the cursor and running
it. `parse.lua` exists; whether it covers resty's file syntax **needs a closer
look**.

**Also removes:** the `WebdevRestyLoader` autocmd and one `plenary` consumer.

---

### A2 · `jghauser/mkdir.nvim` → **fileops.nvim** · full replacement

**Benefit: moderate. Effort: <1 session. Risk: none.**

mkdir.nvim is one `BufWritePre` autocmd that creates missing parent directories.
`fileops.nvim` is *the* plugin for "keep buffer and disk in agreement", already
has `ops/`, `features/` and does its I/O through libuv directly. This is
15–30 lines in a plugin that already owns the domain, and it removes a whole
repository.

Lowest-hanging fruit in the entire list.

---

### A3 · `dstein64/vim-startuptime` → **runtime-analysis.nvim** · full replacement

**Benefit: moderate. Effort: 1 session. Risk: low.**

`runtime-analysis.nvim` already advertises stall detection "including during
startup, where `--startuptime` falls short", and has `startup/` plus
`telemetry/`, `bench.lua` and `loaded.lua`. What vim-startuptime adds over that
is the *presentation*: repeated runs averaged, sorted, in a navigable buffer.

That is a view on data the own plugin already collects. Worth building as
`:RuntimeAnalysis startup profile` (or wherever the command grammar puts it),
because it also removes a VimScript plugin from the tree.

---

### A4 · `kdheepak/lazygit.nvim` → **lib.nvim** terminal + a command · full replacement

**Benefit: moderate. Effort: <1 session. Risk: low.**

lazygit.nvim is a floating terminal that runs `lazygit`, plus cwd/git-root
resolution and a "reload buffers on exit" autocmd. `lib.nvim` has `terminal/`,
`window/`, `git/` and `cross/`. All four pieces exist.

Open question: **where** it belongs. `diff.nvim` is git-adjacent but this is not
diffing; `open.nvim` is about routing targets to destinations, which is closer.
A `:Open lazygit`-style handler in `open.nvim`, or a small terminal-tool
registry in `lib.nvim`, are both defensible — decide before building.

**Also removes:** one `plenary` consumer.

---

### A5 · `s1n7ax/nvim-window-picker` → **lib.nvim** `window/` · full replacement

**Benefit: low-moderate. Effort: <1 session. Risk: low.**

Single consumer, and it is already guarded: `lua/config/neotree/keymaps/filesystem/files.lua:44`
does `if pcall(require, "window-picker")`. The feature is "overlay a letter on
each window, read one key, return the winid" — `lib.nvim/nvim/window/` is the
natural home, and `filetree.nvim` (adapter-agnostic, already wraps neo-tree)
is the natural consumer.

The fallback path already exists, so a half-finished rebuild degrades
gracefully instead of breaking the tree.

---

### A6 · `chrisbra/unicode.vim` → **emojis.nvim** · full replacement

**Benefit: low-moderate. Effort: 1–2 sessions. Risk: low.**

`emojis.nvim` already ships a **pure UTF-8 byte tokenizer** with no external
library — which is the hard half of `:UnicodeName`. What is left is the data
(a Unicode name table) and the digraph list, which Neovim partly exposes itself
via `vim.fn.digraph_get*` and `:h digraph-table`.

Caveat, and the reason this is not in the "trivial" bracket: shipping a full
Unicode name table is a few hundred KB of data. `:UnicodeTable` and
`:UnicodeSearch` over that is real work. If only `:UnicodeName` (name of the
character under the cursor) is genuinely used, the effort drops sharply —
**worth checking your own usage before committing.**

**Also removes:** the last VimScript plugin outside the tpope/targets group.

---

## 5. Tier B — worth it, but a real project

### B1 · `ThePrimeagen/harpoon` → **sessions.nvim** · full replacement

**Benefit: high. Effort: 3–5 sessions. Risk: medium.**

This is the most interesting entry in the report, because the rebuild is
already half-written — **as config code, in the wrong place.**
`lua/config/harpoon/` is **1707 lines** across nine modules:

| Module | Lines | What it is |
|---|---|---|
| `persist_paths.lua` | 647 | Pinned target specs, persisted |
| `usrcmds.lua` | 216 | Command surface |
| `hardening.lua` | 207 | Debounced saves, autocmd guards |
| `api.lua` | 187 | A wrapper API over harpoon2 |
| `preview.lua` | 181 | Entry preview |
| `pin_marks.lua` / `pin_guard.lua` | 173 | Pin semantics harpoon lacks |
| `health.lua` / `debug.lua` | 96 | Diagnostics |

Harpoon itself contributes a list of file marks with a persisted JSON store and
a quick menu. That is the *small* part of what is running here. And harpoon is
`lazy = false`, so it and `plenary` are both in the startup path unconditionally.

`sessions.nvim` is the right home: it is already branch- and project-aware,
already has `state.lua`, `git.lua`, `meta.lua`, `buforder.lua`, `picker.lua`
and `statusline.lua`. Marks that resolve per project root and per git branch are
a strictly better model than harpoon's, and the machine-dependent
`target_specs` block in [misc.lua](lua/plugins/misc.lua) (workstation vs.
private) becomes ordinary session metadata instead of a config-level `if`.

Payoff beyond the removal: 1707 lines move out of the config into a tested
plugin with CI, and the `plugins.personal` extraction pattern gets applied to
the last big config-resident feature.

**Risk:** this is a daily-driver workflow. Build it behind a flag, run both for
a week, then cut. Do not do this one in a hurry.

---

### B2 · `folke/todo-comments.nvim` → **insights.nvim** · full replacement

**Benefit: high. Effort: 2–3 sessions. Risk: low.**

The pieces are already distributed across own code:

- **Keywords and colors** are already yours — `lua/config/todo_comments/keywords.lua`
  and `colors/strong.lua`, passed into the external plugin.
- **The search** is already ripgrep — `insights.nvim/scan/rg.lua` + `scan/cache.lua`.
  insights already runs project-wide scans for conflicts, unused imports and stray
  dev servers; "lines matching a keyword set" is the same shape.
- **The picker** already bypasses todo-comments: both keymaps in
  [workflow.lua](lua/plugins/workflow.lua) call `snacks.picker.todo_comments()`
  directly, and `pickers.nvim` is the engine-agnostic layer for exactly that.
- **The highlighting** is the only genuinely new part: extmarks on keyword
  matches in visible buffers, plus signs. `spotlight.nvim` already does
  "mark many tokens at once, in distinguishable colors, and keep them there
  through searches and edits" — that is the same machinery.

So: scan in `insights.nvim`, highlight through `spotlight.nvim`'s mechanism,
list through `pickers.nvim`. Three own plugins each gain a feature, and one
external plugin plus its `plenary` and `devicons` dependencies leave.

---

### B3 · `iamcco/markdown-preview.nvim` → **mdview.nvim** · full replacement

**Benefit: high. Effort: 2–4 sessions. Risk: medium.**

`mdview.nvim` *is* this plugin, already written: browser-based preview, buffer
text streamed to a tab, rendered client-side by a Rust/WASM module with
sanitization. markdown-preview is the thing it was built to replace.

Two reasons it is still installed:

1. `markdown.nvim` owns the toggle (`:Markdown preview`) and drives
   markdown-preview through `vim.g.mkdp_*`. The integration points at the wrong
   backend — this is a rewire in `markdown.nvim/integrations/`, not new
   functionality.
2. markdown-preview has `build = "cd app && yarn install"` — a **node/yarn
   toolchain requirement**, with per-platform Chrome path detection hardcoded in
   the spec. mdview explicitly needs no toolchain to run.

What genuinely **needs a closer look** before the cut: scroll sync, and
`mkdp_combine_preview` / `combine_preview_auto_refresh`, which are in active use
in the current spec. If mdview lacks those, they are the actual work item.

**Payoff:** removes a node build step from the plugin set, and stops
markdown.nvim's preview toggle from depending on a foreign plugin's globals.

---

### B4 · `dhruvasagar/vim-table-mode` → **markdown.nvim** · full replacement

**Benefit: moderate. Effort: 2–3 sessions. Risk: low.**

`markdown.nvim` already has `tableview/` with `parser.lua`, `renderer.lua` and
`views/`, and the README names GFM tables as a core feature. So the table
*model* exists; what vim-table-mode adds is the **interactive** half: realign
as you type, `:Tableize` from delimited text, cell motions.

Reading and realigning a table you already parse is the natural next step, and
it is FileType-scoped in a plugin that is already FileType-scoped. The spec is
`cmd` + `ft` gated, so this is not a startup win — it is a
"one command grammar instead of two plugins" win.

---

### B5 · `nvim-treesitter/nvim-treesitter-context` → **ui.nvim** `winbar/` · full replacement

**Benefit: moderate. Effort: 2–3 sessions. Risk: low-medium.**

`ui.nvim` already owns the frame: `statusline/`, `tabline/`, `winbar/`,
`highlights/`, `theme/`. And `lib.nvim` has a `treesitter/` module. Sticky
context is "walk the TS tree upward from the top visible line, render those
lines in the winbar" — both halves are in-house.

The honest caveat: ts-context's difficulty is not the concept, it is the
performance work — incremental updates, large files, fold interaction, and
correct behaviour on scroll. `ui.nvim/winbar/` is currently a single `init.lua`,
so this is a genuine build, not a wiring job. Budget the sessions.

---

## 6. Tier C — harvest one feature, keep the plugin

These are not replacements. The external plugin stays; one idea moves in-house.

| External | Feature worth stealing | Own home | Effort |
|---|---|---|---|
| `chrisgrieser/nvim-puppeteer` | Auto-convert quotes → template literal when `${}` is typed | **cascade.nvim** — its whole thesis is *detect context → advance it one step*. This is that pattern exactly, and it is a small plugin. Closest thing to a free win in Tier C. | 1–2 |
| `nvzone/minty` (`Huefy`/`Shades`) | Interactive colour picker / shade ramp | **color_my_ascii.nvim** or **ui.nvim/theme** — both already reason about colour. Removes `nvzone/volt` as a dependency too. | 2 |
| `catgoose/nvim-colorizer.lua` | Inline hex/rgb colour swatches | **my.nvim** (per-buffer visual features) or **color_my_ascii.nvim**. Concept is trivial, the performance work on large files is not — hence "harvest", not "replace". | 2–3 |
| `folke/zen-mode.nvim` | Distraction-free single window | **my.nvim** or **ui.nvim** — `lib.nvim/nvim/window/` + `ui/` covers the mechanics; ui.nvim already controls statusline/tabline visibility, which is the fiddly part. | 1–2 |
| `kevinhwang91/nvim-bqf` | Better quickfix: preview, in-list filtering | **pickers.nvim** already has a `refine` filter stack (wired as `<C-f>` in replacer.nvim). Quickfix preview is adjacent. | 2–3 |
| `rcarriga/nvim-notify` | Notification history, stacked toasts | **lib.nvim** already has `notify/` and **ui.nvim** owns the frame. Note the config runs it *only* as a noice backend, and `snacks.notifier` is explicitly off — so removal is coupled to the noice decision. | 2 |
| `folke/which-key.nvim` | Pending-keymap hint popup | **ui.nvim**. Genuinely useful and self-contained, but the label/group data model is the real work. Non-trivial despite looking simple. | 3 |
| `nvim-tree/nvim-web-devicons` | Filetype → icon + colour | **lib.nvim**. `ui.nvim/statusline/modules/file_icons/devicons.lua` already isolates it behind an adapter, so this is a *data* import, not an architecture change. Low value (devicons is stable and cheap), but it would make `ui.nvim` and `lsp.nvim` dependency-free. | 2 |
| `FabianWirth/search.nvim` | Tabbed picker groups | **pickers.nvim** — `:Pickers <scope> <action>` is already a grammar over scopes. Tabs are a UI on top of it. Arguably already redundant; **needs a closer look** at whether it is still used at all. | 1–2 |
| `nvim-telescope/telescope-github.nvim` | GitHub issues/PRs/gists as pickers | **reposcope.nvim** (already talks to GitHub/GitLab/Codeberg) + **github_stats.nvim**. Picker delivery via `pickers.nvim` so it is not telescope-bound. | 2–3 |
| `nvim-telescope/telescope-file-browser.nvim` | Browse + create/rename/delete from a picker | **fileops.nvim** (the operations) + **pickers.nvim** (the list). Both halves exist; only the composition is missing. | 2–3 |

---

## 7. Findings worth acting on independently

These came out of the analysis and are not "rebuild" items.

### 7.1 `snacks.image` is enabled and almost certainly dead weight

[snacks.lua:52](lua/plugins/snacks.lua) sets `image = { enabled = true }`, with a
comment describing the **Kitty graphics protocol**. Per the established finding
in this setup, Kitty-APC never renders from inside nvim on this machine — which
is precisely why `images.nvim` draws through **iTerm2 OSC 1337** instead, and
says so in its README.

So this module is enabled, loads, and renders nothing. Setting it to `false` is
a one-line change that costs nothing and removes a confusing second image path.
**Verify once in the actual terminal, then flip it.**

### 7.2 `render-markdown.nvim` is installed permanently disabled

[markdown.lua](lua/plugins/markdown.lua) installs it and immediately calls
`setup({ enabled = false })`, with `:Markdown render` as the toggle. So it is
carried for an on-demand feature. Fine as-is — but note that a *full* rebuild
into `markdown.nvim` is a large project (concealed rendering of every GFM
construct) and is **not** recommended. Left out of the tiers deliberately.

### 7.3 `cmdlog.nvim` has a runtime dependency on plenary

Everywhere else in the own repos, `plenary` appears only in
`TESTS/minimal_init.lua` (the busted harness — expected and fine). Two files
break that pattern:

- `cmdlog.nvim/lua/cmdlog/core/favorites.lua`
- `cmdlog.nvim/lua/cmdlog/core/store.lua`

`lib.nvim` covers path, fs and JSON, so this is a small, self-contained
migration. It matters because it is the only thing standing between the own
plugin set and "plenary is a third-party-only dependency" — after which
plenary's presence is decided entirely by which *external* plugins survive.

### 7.4 The `plenary` dependency chain

`plenary` is pulled in by: harpoon (B1), todo-comments (B2), resty (A1),
lazygit (A4), diffview, neogit, telescope, neotest, and cmdlog (7.3).

Doing A1 + A4 + B1 + B2 + 7.3 removes five of those nine. It does not remove
plenary — telescope and neotest keep it — but it does mean plenary is no longer
in the *startup* path, since harpoon is the only `lazy = false` consumer.

### 7.5 `nvzone/menu` is already disabled

[nvchad.lua:26](lua/plugins/nvchad.lua) has `enabled = false`, and
`ui.nvim/contextmenu/` exists with its own README. This replacement appears to
be **already done** — the spec is a leftover. Deleting the file is housekeeping,
not a project. Worth confirming `:UI` covers the cases you used it for, then
removing.

---

## 8. Keep — rebuilding is not worth it

For completeness, with the reason stated once:

- **Engines that are someone's life's work:** `nvim-treesitter` (+`-textobjects`),
  `nvim-cmp`, `blink.cmp`, `neotest`, `mason.nvim`, `telescope.nvim`, `fzf-lua`,
  `snacks.nvim`. `pickers.nvim` correctly sits *on top of* the last three rather
  than replacing them — that is the right relationship and should stay.
- **Git suite:** `gitsigns`, `diffview`, `neogit`, `vim-fugitive`, `vim-rhubarb`,
  `git-conflict.nvim`. `diff.nvim` overlaps diffview partially and
  `insights.nvim/conflicts/` overlaps git-conflict's detection — but a real git
  porcelain is years of edge cases. Note `git-conflict`'s *detection* half is
  arguably already duplicated by insights; if you ever trim here, that is the
  seam.
- **Neo-tree and its sources** (`neo-tree.nvim`, `nui.nvim`,
  `neo-tree-tests-source`, `neo-tree-diagnostics`): `filetree.nvim` is
  deliberately an *adapter* over these. Rebuilding the tree itself would
  contradict its own design.
- **Text objects:** `mini.ai`, `targets.vim`. Large, well-understood, no own
  plugin owns this domain and creating one has no obvious payoff.
- **Editing mechanics:** `nvim-autopairs`, `nvim-ts-autotag`, `vim-matchup`.
  `cascade.nvim` is philosophically adjacent, but these are deep
  edge-case libraries — the "steal the idea" version (puppeteer) is in Tier C
  precisely because it is the tractable one.
- **`noice.nvim`, `vim-visual-multi`:** very large, very stateful. No.
- **`tokyonight.nvim`:** `ui.nvim/theme/` assembles themes rather than authoring
  a palette. Keep the palette, keep the assembly. Correct division already.
- **`telescope-fzf-native`:** a compiled C sorter. Nothing to rebuild.
- **`nvzone/volt`:** dependency of minty; leaves with it if C2 is done.

---

## 9. Suggested order

1. **A2** (mkdir → fileops) — an hour, one repo gone, warms up the pattern.
2. **A5** (window-picker → lib) — guarded fallback already exists, safe.
3. **A4** (lazygit → lib/open) — decide the home first (see A4).
4. **A1** (resty → runtime-analysis) — biggest single payoff: a repo, an
   autocmd workaround, and a documented 600 ms startup hazard, all at once.
5. **7.1 / 7.5** — two config one-liners, free.
6. **A3** (startuptime → runtime-analysis) — same plugin as A1, do them adjacent.
7. **B2** (todo-comments) — three own plugins gain a feature.
8. **B3** (markdown-preview → mdview) — removes the node/yarn build step.
9. **B1** (harpoon → sessions) — the big one. Flag it, dual-run it, then cut.
10. Tier C opportunistically, **C1 (puppeteer → cascade) first** — it is the
    cheapest and the best thematic fit.

A1–A6 plus 7.5 is **seven repositories removed** for roughly six sessions.
Adding B1–B4 brings it to eleven, for roughly ten more.
