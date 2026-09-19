# External plugins — what they are actually used for, and where each feature belongs

**Date:** 2026-09-17 · **status pass:** 2026-09-18
**Question:** every external plugin is installed for a reason. What is that reason
*as configured in this repository* — and if that feature family were rewritten,
which own plugin would it land in, and what would it cost?

---

## Table of content

  - [0. Status, 2026-09-18](#0-status-2026-09-18)
  - [1. Method, and what this report is not](#1-method-and-what-this-report-is-not)
  - [2. The central observation](#2-the-central-observation)
  - [3. Feature-family catalogue](#3-feature-family-catalogue)
    - [Git](#git)
    - [Pickers and navigation](#pickers-and-navigation)
    - [Tree](#tree)
    - [Tests](#tests)
    - [UI](#ui)
    - [Editing and text](#editing-and-text)
    - [Markdown](#markdown)
    - [Tooling and infrastructure](#tooling-and-infrastructure)
  - [4. Tier A — full replacement of a small plugin](#4-tier-a--full-replacement-of-a-small-plugin)
    - [A1 · `lima1909/resty.nvim` → runtime-analysis.nvim ✅](#a1--lima1909restynvim--runtime-analysisnvim-)
    - [A2 · `jghauser/mkdir.nvim` → fileops.nvim ✅](#a2--jghausermkdirnvim--fileopsnvim-)
    - [A3 · `dstein64/vim-startuptime` → runtime-analysis.nvim ✅](#a3--dstein64vim-startuptime--runtime-analysisnvim-)
  - [5. Tier B — full replacement that is a real build](#5-tier-b--full-replacement-that-is-a-real-build)
    - [B2 · `folke/todo-comments.nvim` → insights.nvim ✅](#b2--folketodo-commentsnvim--insightsnvim-)
    - [B3 · `iamcco/markdown-preview.nvim` → mdview.nvim ✅](#b3--iamccomarkdown-previewnvim--mdviewnvim-)
    - [B4 · `dhruvasagar/vim-table-mode` → markdown.nvim ✅](#b4--dhruvasagarvim-table-mode--markdownnvim-)
    - [B5 · `nvim-treesitter/nvim-treesitter-context` → ui.nvim `context/` ✅](#b5--nvim-treesitternvim-treesitter-context--uinvim-context-)
  - [6. Tier C — harvest one feature, keep the plugin](#6-tier-c--harvest-one-feature-keep-the-plugin)
  - [7. Findings worth acting on regardless](#7-findings-worth-acting-on-regardless)
    - [7.1 `snacks.image` was enabled and could not work here ✅](#71-snacksimage-was-enabled-and-could-not-work-here-)
    - [7.2 Keys were bound for four disabled snacks modules ✅](#72-keys-were-bound-for-four-disabled-snacks-modules-)
    - [7.3 `<leader>gd` had two owners ✅](#73-leadergd-had-two-owners-)
    - [7.4 The harpoon rebuild is already 90% written — in the wrong place ✅](#74-the-harpoon-rebuild-is-already-90-written--in-the-wrong-place-)
    - [7.5 `cmdlog.nvim` and plenary — already resolved when this was written ✅](#75-cmdlognvim-and-plenary--already-resolved-when-this-was-written-)
    - [7.6 The `plenary` dependency chain](#76-the-plenary-dependency-chain)
    - [7.7 `render-markdown.nvim` was kept disabled — now removed ✅](#77-render-markdownnvim-was-kept-disabled--now-removed-)
    - [7.8 `lua/config/gp_config/` was orphaned ✅](#78-luaconfiggp_config-was-orphaned-)
    - [7.9 `nvzone/menu` — not a leftover ✅](#79-nvzonemenu--not-a-leftover-)
  - [8. Where this lands](#8-where-this-lands)
  - [9. Suggested order](#9-suggested-order)

---

## 0. Status, 2026-09-18

**Done, and where.** Everything the suggested order calls free, plus the
three replacements that turned out to be rewires rather than builds:

| Finding | What changed | Where |
|---|---|---|
| A1 resty.nvim → runtime-analysis.nvim | nothing to build: `parse.lua` already reads the `.http` block format, `:RA send` runs the block under the cursor, and no `.http`/`.resty` file exists anywhere in `$REPOS_DIR` or the config; plugin, its 600 ms loader workaround and `lua/plugins/webdev.lua` dropped | nvim, 2026-09-19 |
| A2 mkdir.nvim → fileops.nvim | `auto_mkdir` BufWritePre autocmd, on by default (`fileops.nvim@329a65f`, 2026-07-15); plugin dropped from the spec | nvim `3fe8afd94`, 2026-09-17 |
| A3 vim-startuptime → runtime-analysis.nvim | `:RA startup profile [runs]`; plugin dropped | nvim `137c5f67f`, 2026-09-17 |
| B2 todo-comments.nvim → insights.nvim | `insights.todos`: the host's keyword table shipped as the default, `:Insights todos [KEYWORD...] [ui]` over the shared rg scanner, and an own extmark highlighter with signs; plugin, `config/todo_comments/` and two cheatsheets dropped, `<leader>sT`/`ST` on the insights spec | insights.nvim `638b0f7`/`45e2911`, nvim `03f4ead9a`, 2026-09-19 |
| B3 markdown-preview.nvim → mdview.nvim | `:Markdown preview` drives `:MDView start/stop`; plugin, yarn build and `mkdp_*` globals gone | nvim `83b7a627f`, 2026-09-18 |
| B4 vim-table-mode → markdown.nvim | nothing to build: `core/table_mode.lua` already is the vim-table-mode reimplementation (`:Markdown table mode\|tableize\|new`, cell motions); plugin and `plugins/experimental.lua` dropped | nvim, 2026-09-19 |
| B5 ts-context → ui.nvim | `ui.context`: a Tree-sitter ancestor walk from the first visible line, rendered in a per-window `relative="win"` float — not the winbar this entry named (see the section for why); `:UI context [on\|off\|up n]`, `ui.setup({ context = { max_lines = 3 } })` in the config; plugin dropped | ui.nvim `870a6bc`, nvim, 2026-09-19 |
| C · search.nvim → pickers.nvim | `pickers.tabs` built: tab groups over `:Pickers` targets with query carry-over, `:Pickers tabs`, opt-in `tab_next`/`tab_prev`; search.nvim stays on `<leader>s` | pickers.nvim, 2026-09-19 |
| C · telescope-github → pickers.nvim | `pickers.sources.github` built: `gh`-backed issue/PR lists fill the telescope/fzf branches of the `gh_*` builtins | pickers.nvim, 2026-09-19 |
| C · telescope-file-browser → pickers.nvim | `pickers.browse` built: directory browser on `pick_item` with fileops-backed new/rename/delete rows; fzf-lua's `explorer` | pickers.nvim, 2026-09-19 |
| C · devicons → lib.nvim | `lib.nvim.ui.icons` built: glyph/colour/name per extension, file name, filetype (curated devicons subset), ui.nvim's adapter falls back to it; the plugin stays for its other consumers | lib.nvim, ui.nvim, 2026-09-19 |
| C · which-key → ui.nvim | `ui.keys` built: `:UI keys [prefix]` menu over the mappings under a prefix, drill-down groups; which-key stays for the automatic popup | ui.nvim, 2026-09-19 |
| C · nvim-notify → ui.nvim | `ui.notify` built: toasts + history behind `vim.notify`, `:UI notify`; the plugin stays as noice's backend (the noice decision is separate) | ui.nvim, 2026-09-19 |
| C · bqf → pickers.nvim | `pickers.quickfix`: preview float following the cursor in the quickfix/location window, `pickers.refine` over the list (`zf`/`zF`), `p` preview toggle; bqf spec dropped | pickers.nvim, nvim, 2026-09-19 |
| C · zen-mode → ui.nvim | `ui.zen`: the buffer alone in a centred float over a dimmed backdrop, frame options hidden and restored, `:UI zen [on\|off]`; zen-mode spec dropped | ui.nvim, nvim, 2026-09-19 |
| C · colorizer → my.nvim | `hl_config.features.color_codes`: hex/rgb()/hsl()/CSS-name swatches on the visible lines, background/foreground/virtual, `highlight.color_codes.*`; colorizer spec dropped | my.nvim, nvim, 2026-09-19 |
| C · minty → ui.nvim | `ui.colorpicker`: hue row, saturation × lightness grid for that hue, shades of the pick, readout; the cursor selects, `<CR>` writes back over the `#hex` it opened on or after the cursor, `y` yanks; `:UI color [#hex]`; the right-click menu entry calls it; minty + volt dropped | ui.nvim, nvim, 2026-09-19 |
| C · puppeteer → cascade.nvim | the `strings` domain: template-string / f-string / (opt-in) Lua format-string conversion from an autocmd, `:Cascade strings`; puppeteer spec dropped (the harvest covered the whole plugin) | cascade.nvim, nvim, 2026-09-19 |
| neotest debug tooling → debugging.nvim | `:Debug neotest adapters\|state\|file\|root\|framework\|discover` — the five `:NeotestDebug*` commands and two keys, made adapter-generic (`file`/`root` ask the adapter tables' own `is_test_file`/`root` instead of id-matching or the TypeScript adapter; the parked "Root never resolves" bug is gone with it); `config/neotest/debug/` deleted, `<leader>ntr`/`<leader>ntD` map to the two most-used reports | debugging.nvim, nvim, 2026-09-19 |
| Tree: neo-tree config → filetree.nvim | the last code-bearing pieces of `config/neotree/` — source switcher, Alt toggle keys with the E95 self-heal, the `y` delegate, node utils, health — are filetree's `source_switcher` and `tree_toggle`; ~700 lines of per-source `noop` tables stay as neo-tree config | filetree.nvim `b7075fc`/`21db446`, nvim, 2026-09-19 |
| 7.4 harpoon → sessions.nvim (build + cut-over, same day) | `sessions.marks`: list, pins, defaults, edit float, pickers, preview, harpoon import; harpoon removed, keys moved to `<leader>h*`/`<C-e>`/`<M-1..9>` | sessions.nvim `acdbc70`, nvim, 2026-09-19 |
| 7.1 `snacks.image` | `enabled = false`, with the reason in the spec comment | nvim, 2026-09-18 |
| 7.2 dead snacks keys | eight keys for four disabled modules removed; `<leader>ns` conflict with Neo-tree's source switcher gone with them | nvim, 2026-09-18 |
| 7.3 `<leader>gd` | now diff.nvim's `:Diff target=git:HEAD` (suggested-order item 1); fugitive's `:Gdiffsplit` key removed; snacks' hunk picker moved to `<leader>gD` | nvim, 2026-09-18 |
| 7.5 cmdlog.nvim plenary | already gone — `cmdlog.nvim@104abc7`, 2026-07-30, seven weeks before this report claimed otherwise | — |
| 7.8 `config/gp_config/` | removed (`git rm -r`) | nvim, 2026-09-18 |
| 7.9 `nvzone/menu` | nothing to do; the disabled spec is a documented escape hatch | — |
| 7.7 `render-markdown.nvim` | removed on request, no replacement; mdview.nvim/markdown.nvim never covered in-buffer concealed rendering | nvim, 2026-09-19 |

**Corrections the status pass turned up.** Three findings were wrong or
incomplete as written, and all three were found by looking at the files
rather than the description:

- **7.2 said five modules, and named `toggle`.** `extended.lua` bound keys
  for four — `dim`, `profiler`, `scope`, `scratch`. `toggle` is disabled
  too but never had a key. Eight keys, not "five keys".
- **7.3 is a finding this report missed.** The Git table only saw fugitive's
  `<leader>gd`. `config/snacks/mappings/standard.lua` bound the same lhs to
  the `git_diff` hunk picker, and both are lazy `keys` specs, so whichever
  registered last won — silently, since both descriptions say "git diff".
  The rebind the suggested order asked for would have left two owners; it
  needed the picker moved as well.
- **7.5 was wrong when written.** It said `cmdlog.nvim` still required
  plenary in `core/favorites.lua` and `core/store.lua`. Both files had said
  "carries no plenary.nvim dependency" in their own docstrings since
  2026-07-30 (`cmdlog.nvim@104abc7`). The consequence for 7.6 stands
  anyway: plenary's presence is decided entirely by which external plugins
  survive.

**This file had been assembled from two drafts** and carried the seams:
two `## 1.` headings, two `## 6.`, the `snacks.image` finding twice (4.1 and
7.1), the cmdlog finding as an empty 4.4 stub *and* a filled 7.3, the A1
heading orphaned above the Git table with its body three paragraphs lower,
a "State: implemented in fileops.nvim" line under the `snacks.image`
finding where it clearly meant A2, and a suggested order that referenced
"A1–A6 plus 7.5" from a numbering that no longer existed. Reassembled
2026-09-18 into one sequence; the tier letters (A1–A3, B2–B5) are kept as
they were because other documents cite them, and the "regardless" findings
are numbered 7.x throughout.

**What remains, and what each one needs.** Nothing left is free. Every
open item is either a build of one to five sessions or a placement
decision this report deliberately left open (two candidate homes named,
neither chosen):

| Item | Effort | Blocked on |
|---|---|---|
| `:Git blame` (the last fugitive feature) | M | new code; home undecided: diff.nvim or `lib.nvim/nvim/git` |
| `:Gbrowse` → open.nvim / reposcope.nvim | S–M | placement |
| lazygit float + nvr bridge → lib.nvim / open.nvim | S + M | placement |
| window-picker → `lib.nvim/nvim/window` | S | a new primitive with tests in a shared checkout; the only call site is config code, not filetree.nvim |
| neo-tree extra sources (tests, diagnostics) as adapter-level sources | M each | build; the only Tree-table row left after 2026-09-19 |
| neo-tree config → filetree.nvim | L | ~1,500 lines |

---

## 1. Method, and what this report is not

The unit of analysis here is **not the plugin** but the *feature family this
config actually uses*. That surface was derived from three sources, in order of
authority:

1. **`lua/config/<plugin>/**`** — 8,959 lines of configuration code across
   eleven external plugins. Where you invested config effort is the most honest
   statement of what you use.
2. **The spec's `keys`, `opts`, `cmd`, `init`** in `lua/plugins/*.lua` — for the
   plugins with no config folder, this is the whole used surface.
3. **Call sites elsewhere** — `lua/bindings/**`, `lua/config/menu/**` — which
   reveal usage the spec does not mention.

The own-side targets were checked against the real module layout under
`lua/<name>/**` in `$REPOS_DIR`, not against README claims.

**Effort scale** (one session ≈ a focused half day, `lib.nvim` assumed available):

| | |
|---|---|
| **S** | under one session — wiring, not engineering |
| **M** | 1–2 sessions |
| **L** | 3–5 sessions |
| **XL** | more than that; listed only to record the verdict |

Where a judgement rests on something not verified against the external plugin's
source, it says **"unverified"**. No feature-by-feature diff of the large
plugins was attempted — that is out of scope and would not survive contact with
reality anyway.

**What this report did not check**, and what the status pass added to that
list: it read the spec's `keys` tables per plugin and never cross-checked
one lhs against another, which is how the `<leader>gd` double binding (7.3)
and the `<leader>ns` collision (7.2) went unseen. `:LibKeymapConflicts`
exists for exactly that and was not run.

---

## 2. The central observation

**For most plugins here, the configured surface is a small fraction of the
plugin.** That is what makes this exercise worth doing, and it is invisible if
you compare plugins as wholes:

| Plugin | Size of the thing | What this config uses |
|---|---|---|
| `vim-fugitive` + `vim-rhubarb` | a full git porcelain | **two commands** now: `:Git blame`, `:Gbrowse` (was three; `:Gdiffsplit` retired 2026-09-18) |
| `vim-visual-multi` | a multi-cursor engine | `VM_default_mappings = 0`, then **one** binding: `<C-n>` Find (Subword) Under |
| `nvim-treesitter-textobjects` | the whole textobject/move/swap/lsp_interop suite | the `move` module on `@block.outer`, for `[u`/`]u` — and the queries that make it work are **already yours** (`after/queries/*/textobjects.scm`) |
| `nvim-treesitter-context` | sticky context with fold/scroll integration | `enable = true, max_lines = 3` |
| `nvim-bqf` | a quickfix overhaul | `auto_enable`, `auto_resize_height` |
| `nvim-window-picker` | window selection UI | filter rules, one call site, already behind `pcall` |
| `snacks.nvim` | ~20 modules | picker engine (behind `pickers.nvim`), explorer, quickfile, debug |
| `zen-mode.nvim` | — | `cmd = "ZenMode"`, no `opts` at all |
| `nvzone/minty` | colour tooling | one `minty.huefy` call from the right-click menu |

The mirror image is equally important: **for a few plugins the configured
surface is larger than the plugin.** `lua/config/harpoon/` is 1,707 lines around
a plugin whose contribution is a persisted list of file marks. `lua/config/neotest/`
and `lua/config/neotree/` are ~1,500 lines each. Those are the places where a
rebuild moves *your* code into a tested repo, rather than reimplementing
somebody else's.

---

## 3. Feature-family catalogue

Every external plugin, its used feature families, the own plugin each would land
in, and the cost. Sorted by plugin.

### Git

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| ~~`vim-fugitive` → **`:Gdiffsplit`** (file vs HEAD)~~ | ~~`<leader>gd`, git.lua:77~~ | **Done 2026-09-18** — `<leader>gd` is diff.nvim's `:Diff target=git:HEAD` (see [7.3](#73-leadergd-had-two-owners-)). `core/git.lua` resolves `git:HEAD`, `git:HEAD~1`, `git:<sha>`, `git:<branch>` for the current file. | **done** |
| `vim-fugitive` → **`:Git blame`** | `<leader>gb`, git.lua | **diff.nvim** or **lib.nvim/nvim/git**. Nothing in the own tree does blame — a grep across `lib.nvim`, `diff.nvim`, `insights.nvim`, `ui.nvim`, `sessions.nvim` returns nothing. Genuinely new: `git blame --porcelain`, parse, render per line. **The last fugitive feature in use.** | **M** |
| `vim-rhubarb` → **`:Gbrowse`** (open file/selection at the host) | git.lua | **open.nvim** routes targets to destinations; **reposcope.nvim** already knows GitHub/GitLab/Codeberg. Remote URL → web URL + line anchor. | **S–M** |
| `gitsigns` → **signcolumn hunks, stage/reset/preview** | `config = true`; actions wired in `config/menu/git.lua` | Keep. Sign management plus incremental diff on every change is the plugin. | **XL** |
| `gitsigns` → **`:ToggleInlineDiff`** (invert `word_diff`+`linehl`, preview hunk inline) | `bindings/mappings/git.lua` | **diff.nvim** — the *logic* is already yours; only the gitsigns calls underneath would change. Tied to the line above, so it only moves if hunks move. | **M** |
| `diffview` → **side-by-side diff, file history** | `<leader>dv/dc/dh`; `config = true` | **diff.nvim** already delivers "split, inline, prompt, file, clipboard". File *history* (revision list + per-revision diff) is the missing half. | **L** |
| `neogit` → **magit-style status buffer** | `<leader>gg`, `kind = "split"` | Keep. A staging UI is a project, not a feature. | **XL** |
| `git-conflict.nvim` → **repo-level unmerged-file report** (`:GitConflictListQf`) | `config = true` | **insights.nvim** — `conflicts/` already asks git for files in the `unmerged` state and puts them in the quickfix list. This one family *is* already covered. | **S** |
| `git-conflict.nvim` → **buffer-level marker surgery** (9 commands, 6 buffer-local keys) | defaults; full command list in `docs/NOTES/ExternPlugins/Bindings/Usercmds/GitConflict.md` | **Not** covered by insights — that is a repo-level report, this is line-level text work on markers. Pure buffer parsing plus extmarks, no git plumbing. See [git_nvim.md](../LONG_RUN/IDEAS/git_nvim.md). | **M–L** |
| `lazygit.nvim` → **float terminal running `lazygit`** | `<leader>lg` | **lib.nvim** has `terminal/`, `window/`, `git/`, `cross/`. This is wiring. | **S** |
| `lazygit.nvim` → **`nvr` callback bridge** (`:LazygitBadd`, `:LazygitReplace` — LazyGit's `O` / `<C-o>` open files in the *parent* nvim) | `config/lazygit/**`, 146 lines | **This is the real content, and it is already yours.** The commands, path resolution and focus-safe replace are written; only `vim.g.lazygit_use_neovim_remote` belongs to the plugin. Home: **open.nvim** (routing a target into the right window) or **lib.nvim**. | **M** |

> **Net:** `:Gbrowse` and the lazygit float are cheap. That retires
> **fugitive + rhubarb + lazygit.nvim** — three repos — once blame is built,
> which is the only genuinely new piece. `<leader>gd` is done.

### Pickers and navigation

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| `snacks.nvim` → **picker engine** | `picker = picker_config.get_config()`; all but one binding in `snacks/mappings/standard.lua` is tagged `[pickers]` and dispatches through `builtin()`/`scope_action()` | Keep — `pickers.nvim` sits *on top* of it by design. Correct relationship. | **XL** |
| `snacks.nvim` → **explorer** | `<leader>F`, the one direct `snacks.explorer()` call | **filetree.nvim** — it is already an adapter over neo-tree/nvim-tree/netrw/oil/mini.files. | **M** |
| `snacks.nvim` → **quickfile** | `enabled = true` | Render the file before plugins load. **my.nvim** (per-buffer visual layer) or **lib.nvim**. | **S** |
| `snacks.nvim` → **debug inspector / overlay** | `<leader>ud`, `<leader>uD` | **debugging.nvim** — `:Debug {category} {action}` is exactly this dispatcher. | **M** |
| ~~`snacks.nvim` → **image**~~ | ~~`enabled = true`~~ | **Disabled 2026-09-18** — images.nvim owns this, and the snacks module could not work here. See [7.1](#71-snacksimage-was-enabled-and-could-not-work-here-). | **done** |
| `telescope.nvim` → **picker engine** | `cmd = "Telescope"` | Keep. Note `pickers.nvim` already patches telescope's `defaults.history` and preview-scroll/history-nav keys globally. | **XL** |
| `telescope-file-browser` → **browse + create/rename/delete from a picker** | `config/telescope/init.lua` merges its keymaps | **fileops.nvim** (the operations, already libuv-direct) + **pickers.nvim** (the list). Both halves exist; only the composition is missing. | **M** |
| `telescope-github` → **issues / PRs / gists as pickers** | `lazy = true` extension; GitHub bindings exist in `snacks/mappings/standard.lua` as `[pickers]` entries | **reposcope.nvim** (already talks to GitHub/GitLab/Codeberg) + **github_stats.nvim**, delivered through **pickers.nvim** so it is not telescope-bound. | **M** |
| `telescope-fzf-native` → **native sorter** | compiled C | Keep. Nothing to rebuild. | — |
| `search.nvim` → **tabbed picker groups** | one key, `config/search/init.lua` (86 lines of tab/collection definitions) | **pickers.nvim** — `:Pickers <scope> <action>` is already a grammar over scopes; tabs are a UI on top. The collections are already your data. | **M** |
| `fzf-lua` → **picker engine** | `config/fzf/**`, already consumes `pickers.entry_actions.adapters.fzf` | Keep. Same relationship as snacks/telescope. | **XL** |
| ~~`nvim-bqf` → **quickfix preview + auto-resize**~~ | ~~`auto_enable`, `auto_resize_height` — nothing else~~ | **Done 2026-09-19** — pickers.nvim `pickers.quickfix`: a cursor-following preview float over `:copen` (loaded buffers read directly, unloaded files from disk) and `pickers.refine` over the list (`zf`/`zF`), non-destructive. Auto-resize was not carried over (Neovim's own `:copen [height]` covers it). Plugin dropped. | **done** |
| `nvim-window-picker` → **pick a window by letter** | filter rules; single call site `config/neotree/keymaps/filesystem/files.lua:44`, already `pcall`-guarded | **lib.nvim/nvim/window** (the primitive) consumed by **filetree.nvim**. Fallback path already exists, so a partial build degrades safely. *Status pass:* the call site is config code calling neo-tree's `open_with_window_picker`, so the consumer is this config until the neo-tree keymaps move (Tree table below); the primitive itself is a new `lib.nvim` module with tests. | **S** |
| ~~`harpoon` → **pinned file marks + quick menu**~~ | ~~`config/harpoon/**`, **1,707 lines**, `lazy = false`~~ | **Done 2026-09-19** — `sessions.nvim`'s `marks` feature, cut over the same day the parallel run started (user's call, not the planned week). See [7.4](#74-the-harpoon-rebuild-is-already-90-written--in-the-wrong-place-). | **done** |

### Tree

`lua/config/neotree/**` is ~1,500 lines. `filetree.nvim` is deliberately an
*adapter* over neo-tree, so the tree itself is not a rebuild target. These are
the pieces that are config code today and should be plugin code:

| Feature family | Evidence | Target | Effort |
|---|---|---|---|
| ~~**Hover-based source switcher**~~ | ~~`sources/switcher.lua` (303 lines) — **already draws with `lib.nvim.ui.kit`**~~ | **Done 2026-09-19** — filetree.nvim `source_switcher` (`"`/`!` in place, `:Filetree source`, display names for `source_selector`); `filetree.nvim@b7075fc` | **done** |
| ~~**Centralized buffer-local keymaps + `only_lhs` variant**~~ | ~~`keymaps/**` (~460 lines …)~~ | **Done for what ran code** — `only_lhs` is filetree's `tree_toggle` (E95 self-heal in the adapter), the `y` delegate is `path_copy`'s key list, `"`/`!` the switcher. The per-source `noop` tables **stay**: they silence neo-tree's *own* defaults per source, which is neo-tree configuration, not a feature. | **done** |
| ~~**Node utilities**~~ | ~~`utils/node.lua` (158 lines)~~ | **Deleted** — the adapter already had every helper; the one remaining caller (`files.lua`'s `<CR>`) reads `state.tree:get_node()` itself | **done** |
| ~~**Checkhealth**~~ | ~~`checkhealth/**` (81 lines)~~ | **Deleted** — it only checked that the config's own modules load, and those are gone; `:checkhealth filetree` and `:Filetree source debug` are the replacements | **done** |
| `neo-tree-tests-source` / `neo-tree-diagnostics` → **extra sources** | spec `dependencies` | **filetree.nvim** as adapter-level sources | **M** each |
| `nui.nvim` | dependency of neo-tree and noice | Leaves only when both do. `lib.nvim.ui.kit` is the own equivalent. | — |

### Tests

`lua/config/neotest/**` is ~1,500 lines around a runner that should stay.

| Feature family | Evidence | Target | Effort |
|---|---|---|---|
| **Test running / discovery / adapters** | the plugin | Keep. | **XL** |
| ~~**Adapter debug tooling** — `:NeotestDebugAdapters`, `State`, `File`, `Root`, `Framework`~~ | ~~`debug/init.lua`, **309 lines**~~ | **Done 2026-09-19** — debugging.nvim's `:Debug neotest adapters\|state\|file\|root\|framework\|discover`. Not a straight move: `file`/`root` now ask each configured adapter's own `is_test_file()`/`root()` (from `neotest.config.adapters`), so the reports are adapter-generic and the TypeScript-only root check that never resolved is gone. `config/neotest/debug/` deleted. | **done** |
| **Adapter registration layer** (factory + a 239-line TypeScript adapter) | `adapters/**` (381 lines) | Structurally identical to **dap.nvim** ("a config layer that registers adapters and launch configurations, so `opts = {}` is a working debugger"). A `tests.nvim` sibling — or a `dap.nvim`-style neotest module — is the same pattern twice. | **L** |
| **whichkey / telescope / neo-tree integration wrappers** | `whichkey/`, `telescope/`, `neotree/`, `consumers/` (~240 lines) | **pickers.nvim** / **filetree.nvim** — engine-agnostic instead of per-integration. | **M** |

### UI

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| `noice.nvim` → **cmdline UI, message routing, LSP progress, popupmenu** | `config/noice/**`, 187 lines of routes/views/presets | Keep. Message-system interception is a project. | **XL** |
| `nvim-notify` → **toast backend** | only a noice dependency | Coupled to noice. `lib.nvim` has `notify/`; notification *history* is already reachable via `builtin("notifications")` through pickers. | — |
| ~~`nvim-treesitter-context` → **sticky context, 3 lines**~~ | ~~`enable = true, max_lines = 3`~~ | **Done 2026-09-19** — `ui.context` (ui.nvim `870a6bc`), a per-window float rather than the winbar; `max_lines = 3` kept. Plugin dropped. See [B5](#b5--nvim-treesitternvim-treesitter-context--uinvim-context-). | **done** |
| `vim-matchup` → **extended `%`** | `event`, `stopline = 500` | Keep. Per-language match definitions are the plugin. | **XL** |
| `vim-matchup` → **offscreen match shown in the status line** | `matchup_matchparen_offscreen = { method = "status" }` | **ui.nvim/statusline** — small, self-contained, and squarely in ui.nvim's domain. A nice piece to lift even though the host plugin stays. | **M** |
| `which-key.nvim` → **pending-key popup** | `opts = {}`; wired to `:WhichKey`, `<leader>wK`, `<leader>w?`, sessions.nvim marks, neotest | **ui.nvim.** Cheaper than it looks: the label/group data model is normally the hard part, and you already have a keymap corpus — `:Bindings` (search/browse over `docs/BINDINGS.md` per plugin plus the extern cheatsheets) and `:LibBindingsAudit*` / `:LibKeymapConflicts`. The popup can read what the explorer already parses. | **M–L** |
| ~~`zen-mode.nvim` → **distraction-free single window**~~ | ~~`cmd` only, no `opts` — pure defaults~~ | **Done 2026-09-19** — ui.nvim `ui.zen`: centred float over a dimmed backdrop, `laststatus`/`showtabline`/`ruler`/`showcmd` saved and restored, gutter emptied, cursor in and back out, restore on `WinClosed`. `:UI zen [on\|off]`. Plugin dropped. | **done** |
| ~~`nvim-colorizer.lua` → **inline hex / CSS / named colour swatches**~~ | ~~`opts = {}` — pure defaults~~ | **Done 2026-09-19** — my.nvim `hl_config/features/color_codes`: hex (3/6/8), `rgb()`/`hsl()`, CSS names in stylesheet filetypes; background/foreground/virtual; viewport-only + debounced + the shared skip/large-file guards, which is the whole "performance" answer. Plugin dropped. | **done** |
| ~~`nvzone/minty` → **colour picker**~~ | ~~one call: `minty.huefy` from the right-click menu's "Color Picker" entry~~ | **Done 2026-09-19** — `ui.colorpicker` (ui.nvim): hue row, saturation × lightness grid, shades row, `#hex`/`rgb()`/`hsl()` readout, driven by the window cursor; `:UI color [#hex]`, the menu entry calls it. minty and volt dropped. | **done** |
| ~~`nvim-web-devicons` → **filetype → icon + colour**~~ | ~~`ui.nvim/statusline/modules/file_icons/devicons.lua` already isolates it behind an adapter~~ | **Built 2026-09-19, plugin kept** — `lib.nvim.ui.icons`: a curated devicons subset as data (173 extensions, 52 file names, the filetype map), resolved in devicons' order, Nerd-Font-gated; the plugin is asked first when loaded. ui.nvim's adapter falls back to it, so the icon column is no longer blank without the plugin. devicons stays installed: neo-tree, telescope and the rest still read it, and it knows 500 extensions to the table's 173. | **built** |
| `vim-visual-multi` → **`<C-n>` find-under, edit all occurrences** | `VM_default_mappings = 0`; only `Find Under` / `Find Subword Under` bound | The tiny configured surface is misleading: the multi-cursor state machine is the difficulty, not the entry point. **spotlight.nvim** already marks every occurrence of a token and keeps the marks through searches and edits — the *selection* half is solved; simultaneous editing is not. Keep, but note the seam. | **L–XL** |
| `nvzone/menu` → **right-click menu** | `enabled = false` | **Already done** — `config/menu/**` (855 lines) draws through `lib.nvim.contextmenu` + `lib.nvim.ui.kit`, and `require("menu")` appears nowhere in the tree. The disabled spec is a documented escape hatch (`renderer = "nvzone"`), not a leftover. Leave it. | — |

### Editing and text

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| `nvim-puppeteer` → **quotes → template literal when `${}` is typed** | `lazy = false`, **no configuration at all** | **cascade.nvim.** Its stated pattern is *detect the context under the cursor → advance it one step → otherwise fall back to native behavior*. This is that pattern, in a small plugin, with no config to preserve. Best fit in the whole report. | **M** |
| `nvim-autopairs` → **auto-close pairs** | `opts = {}` | cascade.nvim is philosophically adjacent, but pair handling is an edge-case library. Keep. | **L–XL** |
| `nvim-ts-autotag` → **close + rename HTML/TSX tags** | `enable_close`, `enable_rename`, html close off | Treesitter query work per language. Keep. | **L** |
| `nvim-treesitter-textobjects` → **`[u`/`]u` climb out of the enclosing structure** | `bindings/mappings/treesitter_structure.lua`; `move` module on `@block.outer` — **and the queries extending it for lua/json/python/rust/toml/yaml are already yours** in `after/queries/` | **lib.nvim/nvim/treesitter** gets a `move` helper; the binding stays in config. Only the `move` module is used — not swap, not lsp_interop, not select. | **M** |
| `mini.ai`, `targets.vim` → **textobjects** | pure defaults | Keep. No own plugin owns this domain and creating one has no payoff. | **XL** |
| ~~`vim-table-mode` → **realign while typing, `:Tableize`**~~ | ~~`table_mode_corner = "|"`, `cmd` + `ft` gated~~ | **Done 2026-09-19** — markdown.nvim already had it: `core/table_mode.lua`, "a focused, dependency-free reimplementation of the vim-table-mode essentials" (`:Markdown table mode\|tableize\|new`, `]\|`/`[\|`). Plugin dropped. See [B4](#b4--dhruvasagarvim-table-mode--markdownnvim-). | **done** |
| `unicode.vim` → **`:UnicodeName`, `:UnicodeSearch`, `:UnicodeTable`, `:Digraphs`** | `cmd` list + `uni` key | **emojis.nvim** — it already ships a pure UTF-8 byte tokenizer with no external library, which is the hard half of `:UnicodeName`. The rest is a Unicode name table (a few hundred KB of data) plus digraphs, which Neovim partly exposes via `vim.fn.digraph_get*`. **If only `:UnicodeName` is really used, this drops to S — worth checking your own habit first.** | **M** |

### Markdown

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| ~~`markdown-preview.nvim` → **browser preview with scroll sync**~~ | ~~driven by `markdown.nvim`'s `:Markdown preview` through `vim.g.mkdp_*`; `build = "cd app && yarn install"`; hardcoded per-platform Chrome paths~~ | **Done — B3, shipped 2026-09-18.** `markdown.nvim` now drives `:MDView start`/`stop`; markdown-preview.nvim uninstalled. Scroll sync and combine-preview were already covered by mdview's `browser.behavior = "reuse"` and `:MDView sync` — no new feature work, only the rewire. | **done** |
| ~~`render-markdown.nvim` → **in-buffer concealed rendering**~~ | ~~installed and immediately `setup({ enabled = false })`; toggled by `:Markdown render`~~ | **Removed 2026-09-19** (7.7) — user decision; no rebuild, no replacement. A full rebuild into markdown.nvim would still mean concealed rendering of every GFM construct — **not recommended.** | **done** |

### Tooling and infrastructure

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| ~~`resty.nvim` → **HTTP client on `.http`/`.resty` buffers**~~ | ~~`config` is an elaborate `vim.filetype.add` + autocmd workaround, documented as containing a ~600 ms startup cost~~ | **Done 2026-09-19** — runtime-analysis.nvim already had all of it, including the "missing piece": `parse.lua` reads the `.http` block format and `:RA send` runs the block under the cursor. Plugin and workaround dropped. See [A1](#a1--lima1909restynvim--runtime-analysisnvim-). | **done** |
| ~~`vim-startuptime` → **repeated runs, averaged, sorted, navigable**~~ | ~~`cmd` only~~ | **Done 2026-09-17** — see [A3](#a3--dstein64vim-startuptime--runtime-analysisnvim-). Uninstalled. The "only the presentation is missing" reading in this row was wrong and is corrected there. | **done** |
| ~~`todo-comments.nvim` → **keyword scan**~~ | ~~`config/todo_comments/**` — the keyword table and colours are **already yours**; both keymaps call `snacks.picker.todo_comments()` directly, bypassing the plugin~~ | **Done 2026-09-19** — `:Insights todos`, on `scan/rg.lua`, the host's table as the shipped default. See [B2](#b2--folketodo-commentsnvim--insightsnvim-). | **done** |
| ~~`todo-comments.nvim` → **in-buffer highlight + signs**~~ | ~~`signs = true`~~ | **Done 2026-09-19** — `insights.todos.highlight`, an own extmark module rather than spotlight's (see B2 for why). | **done** |
| ~~`mkdir.nvim` → **create missing parent dirs on write**~~ | ~~`lazy = true`, no config~~ | **Done** — fileops.nvim's `auto_mkdir` BufWritePre autocmd, on by default; plugin dropped 2026-09-17. See [A2](#a2--jghausermkdirnvim--fileopsnvim-). | **done** |
| `mason.nvim` → **installer registry** | `lazy = false`; `lsp.nvim` and `:MasonInstallAll` `require("mason")` directly | Keep. | **XL** |
| `plenary.nvim` → **shared Lua helpers** | `lazy = false` — unconditionally in the startup path | Not a rebuild target; a *dependency-chain* question. See [7.6](#76-the-plenary-dependency-chain). | — |
| `nvim-treesitter` | — | Keep, obviously. | — |
| `blink.cmp` → **completion engine** | active engine (`vim.g.lsp_nvim.pack.completion` defaults to `"blink"`) | Keep. | **XL** |
| `nvim-cmp` | `lsp.nvim`'s cmp spec resolves `enabled = false`; **not installed** | Nothing to do — the spec fragment exists so flipping one option moves the accept/dismiss keys with it. | — |
| `tokyonight.nvim` → **palette** | — | Keep. `ui.nvim/theme/` *assembles* themes rather than authoring palettes — correct division already. | — |

---

## 4. Tier A — full replacement of a small plugin

### A1 · `lima1909/resty.nvim` → runtime-analysis.nvim ✅

**Done 2026-09-19, and it was S, not M–L.** The "first hour of the build"
this entry asked for — check whether `parse.lua` reads `.http` syntax —
answered the whole thing: it does, and has for a while. Its own docstring
names the format (VS Code REST Client / IntelliJ HTTP Client: `METHOD url`,
`Header: value` lines, blank line, body), `M.split` slices a buffer on
`###`, and `:RA send` runs the block under the cursor from a committed
`.http`/`.rest` file as well as from a `:RA request` scratch buffer. On top
of what resty offered: `{{var}}` environments from `http-client.env.json`,
`# @expect status` assertions, GraphQL and multipart shorthands, per-project
history. The one thing resty had that runtime-analysis does not is the
`.resty` extension, and a `find` across `$REPOS_DIR` and the config found
**no `.http`, `.rest` or `.resty` file at all** — the plugin was installed
for a workflow that had never produced a file.

The decisive argument was in the config's own comment in the now-deleted
`lua/plugins/webdev.lua`: resty cost roughly **600 ms of startup** because
loading it dragged in telescope, nvim-cmp and LuaSnip through its `plugin/`
and `after/plugin/` files, defeating their own lazy triggers. The spec was
an elaborate `vim.filetype.add` + autocmd workaround built purely to
contain that damage. Deleting resty deleted the workaround too — the file
held nothing else — along with its `WebdevRestyLoader` row in
`docs/BINDINGS.md`, its `:Resty` row in the usercmd overview, and its
lock-file entry (together with the stale `markdown-preview.nvim` and
`vim-startuptime` entries that `:Lazy clean` had not yet dropped).

### A2 · `jghauser/mkdir.nvim` → fileops.nvim ✅

fileops.nvim gained `auto_mkdir` — one `BufWritePre` autocmd that creates
the parent directory of the file about to be written, on by default
(`fileops.nvim@329a65f`, 2026-07-15, routed through `lib.nvim.autocmd` in
`1975fd7`). mkdir.nvim was dropped from the spec on 2026-09-17
(`3fe8afd94`). *(The earlier draft recorded this as "implemented in
fileops.nvim on 17.02.2026", under the wrong finding and with the wrong
date.)*

### A3 · `dstein64/vim-startuptime` → runtime-analysis.nvim ✅

Shipped 2026-09-17 as `:RA startup profile [runs]`; the plugin is uninstalled
(`137c5f67f`).

**The premise this entry was written on did not survive the build, and that is
the part worth keeping.** It read "that is a view on data the own plugin
already collects". It is not: `startup/init.lua` collects timer lateness, not
per-file cost, and never runs twice, while `telemetry/startup.lua` is blind by
construction to everything already in `package.loaded` when it arms — on a
real config that is Neovim's own runtime, lazy.nvim itself and every earlier
plugin. So the measurement half was new work (a sequential subprocess driver,
a `--startuptime` parser, the statistics); only the presentation was free.

It was worth building anyway for a reason this entry did not name: that
plugin's own `docs/FEATURES/STARTUP.md` had been telling readers to "compare
medians of three runs, not single numbers" with no command behind it.

The shipped version reports a **median with its sample spread beside it** and
`n/N` runs per row, so a noisy row cannot pass for a finding — the thing
vim-startuptime's single averaged column left out.

---

## 5. Tier B — full replacement that is a real build

### B2 · `folke/todo-comments.nvim` → insights.nvim ✅

**Done 2026-09-19** — `insights.nvim@638b0f7` (+ `45e2911`), config
`03f4ead9a`. One session, not the two or three budgeted, because two of the
three "pieces already distributed" turned out to be exactly that and the
third was smaller than it looked.

**What was built.** `insights.todos` in three files. `keywords.lua` is the
host's own table — icon, colour category, aliases per keyword, and the
colour categories as candidate lists — shipped as the default, so the
config keeps nothing; a host states only the difference (`FOO = { color =
"info" }` adds, `HACK = false` drops). `init.lua` is the report: one rg
pass through the scanner every other project report uses, case-sensitive
regardless of a `--smart-case` in the user's ripgreprc, word-bounded and
deliberately without the colon (a sample of the fleet found colon-less
annotations in a third of the hits); `:Insights todos [KEYWORD...] [ui]`
takes keywords or aliases and a UI name in any order, `<Tab>` completes
both, `ui = "auto"` goes snacks → telescope → fzf → quickfix. `highlight.lua`
colours the keyword as a filled block, the rest of the comment in the
foreground, and puts the icon in the sign column — visible range only,
re-scanned on scroll and (debounced) on change, groups redefined through
`lib.nvim.ui.hl.persist` after a theme change. Health section, keymap
actions (`todos`, `todos_qf`), autocmds and docs come with it;
`TESTS/todos_spec.lua` covers the table, the filter, vimgrep parsing with a
Windows drive path, the scan against a fake rg, and the highlight against
a real buffer with the Lua parser.

**Two things this entry had wrong, both about the shape of the build:**

- **The highlight did not go through spotlight.nvim.** Its public API is a
  *set of tokens* — `add(text)`, `remove`, `lock`, sets you save and switch —
  the model for following a request id through a log. An annotation
  highlighter needs a *pattern* over a keyword table, a comment gate, and a
  sign per category, none of which spotlight has a hook for; the honest
  reuse would have been its extmark loop, ~40 lines that are also the least
  interesting part. So insights has its own module and spotlight is left
  as what it is. The "same machinery" reading was true of the mechanism
  and wrong about the interface.
- **The list did not go through pickers.nvim either.** pickers.nvim runs
  *named builtins* of an engine (`run("git_diff")`); it has no "show this
  ad-hoc list" call, and adding one is a pickers.nvim feature this finding
  did not ask for. insights already had telescope and fzf adapters shaped
  for its symbol entries, and todo entries are shaped the same way so they
  work unchanged; snacks gets a direct `picker.pick({ items })` with the
  `file` format. Quickfix through `lib.nvim.ui.list` closes the gaps.

**One defect found by building it.** The first version asked
`vim.treesitter.get_captures_at_pos` whether a match sits in a comment,
and it said "no captures" for a buffer that had a parser but no active
Tree-sitter *highlighting* — which is where a wrong answer would have gone
unnoticed longest. `get_node` reads the tree itself; the range is parsed
before the scan.

The original reasoning, kept for the record:

- **Keywords and colors** are already yours — `lua/config/todo_comments/keywords.lua`
  and `colors/strong.lua`, passed into the external plugin.
- **The search** is already ripgrep — `insights.nvim/scan/rg.lua` + `scan/cache.lua`.
  insights already runs project-wide scans for conflicts, unused imports and stray
  dev servers; "lines matching a keyword set" is the same shape.
- **The picker** already bypasses todo-comments: both keymaps in
  [workflow.lua](../../../lua/plugins/workflow.lua) call `snacks.picker.todo_comments()`
  directly, and `pickers.nvim` is the engine-agnostic layer for exactly that.
- **The highlighting** is the only genuinely new part: extmarks on keyword
  matches in visible buffers, plus signs. `spotlight.nvim` already does
  "mark many tokens at once, in distinguishable colors, and keep them there
  through searches and edits" — that is the same machinery.

So: scan in `insights.nvim`, highlight through `spotlight.nvim`'s mechanism,
list through `pickers.nvim`. Three own plugins each gain a feature, and one
external plugin plus its `plenary` and `devicons` dependencies leave.

### B3 · `iamcco/markdown-preview.nvim` → mdview.nvim ✅

**Shipped 2026-09-18** (`83b7a627f`). `markdown.nvim`'s `commands/preview.lua`
now drives `:MDView start`/`:MDView stop` instead of `:MarkdownPreview`/
`:MarkdownPreviewStop`; markdown-preview.nvim and its `vim.g.mkdp_*` config
are gone from `lua/plugins/markdown.lua`. The BufEnter auto-refresh workaround
`preview.lua` used to carry for markdown-preview went with it — mdview.nvim
already follows buffer switches and drives scroll sync itself
(`browser.behavior`, default `"reuse"`), so nothing had to be rebuilt for
that.

**The premise this entry was written on was more pessimistic than the
codebase.** It read "what needs a closer look: scroll sync, and
`mkdp_combine_preview`/`combine_preview_auto_refresh` — if mdview lacks those,
they are the actual work item." mdview.nvim already had both, and had had them
for a while: `bindings/autocmds/buffer_switch.lua`'s `browser.behavior =
"reuse"` (the default) pushes the newly-focused buffer into the open tab's
room on every switch — that *is* combine-preview-with-auto-refresh, just
inherent to mdview's live-mirror design rather than a manual refresh call —
and `:MDView sync`/`bindings/autocmds/scroll_sync.lua` already covers scroll
sync. So there was no genuinely new feature work, only the rewire.

**Bonus find along the way:** `markdown.nvim`'s *other* mdview integration —
`:Markdown mdview [path]` (`commands/mdview.lua`) — was silently dead. It
called `:MDViewStart`, a command that no longer exists; mdview.nvim unified
its command surface into a single `:MDView <subcommand>` some time back, and
this call site (plus `health.lua`'s `:MDViewStart` detection check) never
followed. Fixed as part of this pass — `:MDView start <path>` is the correct
form.

**Payoff:** removes a node build step from the plugin set, stops
markdown.nvim's preview toggle from depending on a foreign plugin's globals,
and fixes `:Markdown mdview` which had not actually worked.

### B4 · `dhruvasagar/vim-table-mode` → markdown.nvim ✅

**Done 2026-09-19, and there was nothing to build.** This entry read the
`tableview/` folder and concluded the interactive half was missing. It is
not in that folder: `core/table_mode.lua` (492 lines) is markdown.nvim's
own "focused, dependency-free reimplementation of the vim-table-mode
essentials" — auto-realign as you type, `tableize` from delimited text
with the separator auto-detected, `]|`/`[|` cell motions, `insert_row` for
cascade.nvim's `o`/`O` — behind `:Markdown table mode|tableize|new` and
`<leader>tvm`, next to `table_fmt` (the GFM formatter) and `table_wrap`
(`:MDTable*`). Its own `docs/FEATURES/TABLES.md` says so in the first
sentence of the section. The plugin was installed for a workflow the
notes tree does not even contain (`grep '^|.*|.*|$'` over `Notes/` finds
no table at all), so nothing had to be migrated; the spec — the whole of
`plugins/experimental.lua` — is gone, with its `g:table_mode_corner` and
the cheatsheet rows.

The original reasoning, kept for the record:

`markdown.nvim` already has `tableview/` with `parser.lua`, `renderer.lua` and
`views/`, and the README names GFM tables as a core feature. So the table
*model* exists; what vim-table-mode adds is the **interactive** half: realign
as you type, `:Tableize` from delimited text, cell motions.

Reading and realigning a table you already parse is the natural next step, and
it is FileType-scoped in a plugin that is already FileType-scoped. The spec is
`cmd` + `ft` gated, so this is not a startup win — it is a
"one command grammar instead of two plugins" win.

### B5 · `nvim-treesitter/nvim-treesitter-context` → ui.nvim `context/` ✅

**Done 2026-09-19, in one session rather than the two to three budgeted,
and not in the winbar.** `ui.context` (ui.nvim `870a6bc`) is the replacement:
the first visible line's innermost Tree-sitter node, walked up through its
ancestors; every ancestor that starts above the top line and whose node type
matches a scope pattern (`function`, `method`, `^class`, `^if_statement$`,
`^for`, `switch`, … — Lua patterns over the type name, so one list covers
every grammar's spelling) contributes its first source line, outermost first,
capped at `max_lines = 3` with the *outer* ones dropped first (`trim`
selects). Rendered in a non-focusable `relative="win"` float at row 0 of the
window, full width, with the same parser started on the overlay buffer so
keywords keep their colours and the source line numbers reproduced in the
gutter in `LineNr`. Refresh on `WinScrolled`/`CursorMoved`/`BufEnter`/
`TextChanged`/`WinResized`, debounced through `lib.nvim.debounce`; the
overlay is never drawn over the focused window's cursor line, and floats,
special buffers, parser-less filetypes and windows shorter than six rows are
skipped before any parse runs. `:UI context [on|off]`, `:UI context up [n]`
jumps to the n-th enclosing scope (works with the overlay off), explicit-only
in `ui.setup` (`all = true` does not turn it on, because it draws over the
buffer). Ten plenary cases against a real window and the bundled Lua parser.

**Why a float and not `ui.winbar`.** The status-pass note below this entry
said a sticky-context line "has to go through `ui.winbar.set()` like the
other two" producers. Checked against what the winbar actually is: one line
per window, already contested between my.nvim's symbol breadcrumbs and
filetree.nvim's path trail. A sticky context is one to three lines that
must sit *inside* the text area, over the rows they replace, with the
window's own gutter — the upstream plugin draws a float for the same reason.
Putting it in the winbar would have meant a third producer fighting for one
line and a context capped at one entry. So the frame-owner argument still
holds (it is ui.nvim's module) but the surface is a per-window float via
Neovim's own `nvim_open_win`, not `ui.kit.surface` either, since the overlay
needs `relative="win"` with no border, no title and no focus.

**What the trade is.** Upstream ships a `context.scm` query per grammar;
this module matches node-type names by pattern. That is no per-language
file to maintain, at the price of an occasional scope a query would have
named differently — `cfg.node_types`/`cfg.exclude_node_types` are the knob,
and the Lua run in the real config showed exactly the upstream set for this
file (`function_declaration`, nothing for a multi-line table). The
"performance work" this entry warned about turned out to be two decisions:
parse only the range above the top line (incremental after the first) and
skip ineligible windows before parsing. Fold interaction is not special-cased;
a folded region's first line is still a real line and the walk starts there.

**Config side (nvim, 2026-09-19):** the `nvim-treesitter-context` spec is
gone from `lua/plugins/treesitter.lua`; `config/ui_statusline/init.lua`
passes `context = { max_lines = 3 }` to `ui.setup`; the Bindings corpus
(`Autocmds/Treesitter.md`, `TODO.md`) says where it went.

---

## 6. Tier C — harvest one feature, keep the plugin

These are not replacements. The external plugin stays; one idea moves in-house.
(In practice five of the eleven became replacements after all — see each row for why.)
**All eleven done 2026-09-19:** five replaced (puppeteer → cascade, minty → ui.colorpicker, colorizer → my.nvim, zen-mode → ui.zen, bqf → pickers.quickfix) and six built with the plugin kept (nvim-notify → ui.notify, which-key → ui.keys, devicons → lib.nvim.ui.icons, search.nvim → pickers.tabs, telescope-github → pickers.sources.github, telescope-file-browser → pickers.browse).

| External | Feature worth stealing | Own home | Effort |
|---|---|---|---|
| ~~`chrisgrieser/nvim-puppeteer`~~ | ~~Auto-convert quotes → template literal when `${}` is typed~~ | **Done 2026-09-19** — cascade.nvim's fifth domain, `strings` (`lua/cascade/strings/`): JS/TS template strings, Python f-strings, opt-in Lua `(…):format()`, with puppeteer's guards; `:Cascade strings on\|off\|toggle\|now`, `strings.*` config, autocmd-driven. The one Tier C item where the harvest *is* the whole plugin, so the plugin is gone from the config rather than kept — keeping both would convert every string twice. | **done** |
| ~~`nvzone/minty` (`Huefy`/`Shades`)~~ | ~~Interactive colour picker / shade ramp~~ | **Done 2026-09-19** — ui.nvim, not color_my_ascii: the picker is a themed `ui.kit.surface` float, and ui.nvim already owns palettes and the float toolkit. `ui.colorpicker` + `ui.colorpicker.color` (hex/rgb/hsl, lightness shift, WCAG contrast, hex-under-cursor); `:UI color [#hex]`; `open({ on_pick })` for hosts. minty and volt gone from the config. | **done** |
| ~~`catgoose/nvim-colorizer.lua`~~ | ~~Inline hex/rgb colour swatches~~ | **Done 2026-09-19** — my.nvim, as `highlight.color_codes`. "Harvest, not replace" turned into a replace after all: with the scan limited to the visible lines and the existing skip/large-file guards, the large-file problem the row worried about does not arise, and two colorizers would paint twice. | **done** |
| ~~`folke/zen-mode.nvim`~~ | ~~Distraction-free single window~~ | **Done 2026-09-19** — ui.nvim, for the reason the row gave: it owns the statusline and tabline, so hiding them is two options saved and restored. `ui.zen` with `width`/`height`/`backdrop`/`wo` tunables; no terminal-font or plugin bridges. Plugin dropped. | **done** |
| ~~`kevinhwang91/nvim-bqf`~~ | ~~Better quickfix: preview, in-list filtering~~ | **Done 2026-09-19** — `pickers.quickfix`, from a `FileType qf` autocmd, no engine involved; the refine stack the row pointed at is exactly what runs over the list. bqf's fzf mode is not reproduced (`:Pickers builtin quickfix` is the fuzzy pass). Plugin dropped. | **done** |
| ~~`rcarriga/nvim-notify`~~ | ~~Notification history, stacked toasts~~ | **Built 2026-09-19, plugin kept** — ui.nvim `ui.notify`: `vim.notify` as level-coloured `ui.kit.toast`s with per-level timeouts and a ring-buffer history (`:UI notify [on\|off\|history\|clear]`, `ui.setup({ notify = true })`, explicit-only). This config keeps nvim-notify as noice's backend, exactly as the row says: the removal is the noice decision, not this one. `:UI notify on` is the trial switch. | **built** |
| ~~`folke/which-key.nvim`~~ | ~~Pending-keymap hint popup~~ | **Built 2026-09-19, plugin kept** — ui.nvim `ui.keys`: the mappings under a prefix as a `ui.kit.menu` (rows from `desc`, drill-down groups named via `setup({ groups })`, a picked row feeds the keys), `:UI keys [prefix]`. Asked for, not timeout-triggered: the pending-key interception is the hard part of which-key and the part left to it. which-key stays for the automatic popup; the data model the row worried about turned out to be `nvim_get_keymap` plus the `desc`s the registry already writes. | **built** |
| ~~`nvim-tree/nvim-web-devicons`~~ | ~~Filetype → icon + colour~~ | **Built 2026-09-19, plugin kept** — `lib.nvim.ui.icons` (data + lookup, README), wired as ui.nvim's fallback behind the adapter seam the row named. Exactly the data import it predicted; the plugin stays for the consumers that are not ours. | **built** |
| ~~`FabianWirth/search.nvim`~~ | ~~Tabbed picker groups~~ | **Built 2026-09-19, plugin kept** — pickers.nvim `pickers.tabs`: named groups of `:Pickers` argument strings, `:Pickers tabs <group>`, opt-in in-picker `tab_next`/`tab_prev` (telescope + snacks; fzf-lua's `keymap.builtin` cannot run Lua) with the typed query carried into the next target (`command.handle` gained `query`). The closer look: `<leader>s` still opens search.nvim here, so it stays until the host rebinds. | **built** |
| ~~`nvim-telescope/telescope-github.nvim`~~ | ~~GitHub issues/PRs/gists as pickers~~ | **Built 2026-09-19, plugin kept** — not in reposcope or github_stats after all: pickers.nvim already had the four `gh_*` builtins for snacks, so `pickers.sources.github` (`gh <kind> list --json` → `pick_item`, a pick opens the entry in the browser) fills the telescope and fzf-lua branches. Gists were not carried (the extension was unused here). telescope-github stays installed but nothing in the config reaches it. | **built** |
| ~~`nvim-telescope/telescope-file-browser.nvim`~~ | ~~Browse + create/rename/delete from a picker~~ | **Built 2026-09-19, plugin kept** — the composition the row described: pickers.nvim `pickers.browse` (one directory per `pick_item` list, dirs first, `../`, new/rename/delete rows through fileops.nvim when installed), `:Pickers browse [dir]`, `:Pickers builtin browse`, and fzf-lua's `explorer` — the one engine that had none. telescope's `explorer` keeps the extension; the config's `<leader>.` still uses it. | **built** |

---

## 7. Findings worth acting on regardless

These came out of the analysis and are not "rebuild" items. *(Numbered 7.x
throughout since the 2026-09-18 reassembly; the earlier draft had them split
across 4.x and 7.x with two of them duplicated.)*

### 7.1 `snacks.image` was enabled and could not work here ✅

[snacks.lua](../../../lua/plugins/snacks.lua) set `image = { enabled = true }`,
with a comment naming the **Kitty graphics protocol** and WezTerm.
images.nvim's `docs/scope.md` records the finding this rests on: *"On native
Windows Neovim in WezTerm, Kitty sequences coming from Neovim are never
drawn — no error, no configuration that fixes it, nothing on screen. That is
the whole reason this plugin exists."* — which is why images.nvim draws
through **iTerm2 OSC 1337** instead.

So the module was enabled, loaded, and rendered nothing, while a second image
path that does work sat next to it. **Flipped to `false` 2026-09-18**, with
the reason and the condition for flipping it back in the spec comment. The
"verify once in the actual terminal first" this entry asked for was not done
in a live terminal; the documented finding in images.nvim was taken as that
verification, and a revert is one line if a terminal ever shows otherwise.

### 7.2 Keys were bound for four disabled snacks modules ✅

`config/snacks/mappings/extended.lua` registered keys for `dim`
(`<leader>uf`), `profiler` (`<leader>ps`/`pS`/`pr`), `scope` (`]s`/`[s`)
and `scratch` (`<leader>ns`/`nS`). All four are `enabled = false` in the
spec. The dispatcher is defensive — `safe_call` emits `[snacks] missing
<mod>.<fn>()` rather than erroring — so the failure mode was a warning, not a
crash. Still: eight keys that could not work. *(The earlier draft said "five
modules" and named `toggle`; it is disabled too but never had a key.)*

Three of the eight were also collisions the draft had not seen, each a dead
key contending with a live one for the same lhs: `<leader>ns` was Neo-tree's
source switcher (`config/neotree/keymaps/global.lua`) as well; `<leader>ps`
was insights.nvim's symbols picker — a headless start of the real config
after the removal reports it as "insights: symbols (telescope, cwd
functions)", which is what the key had been fighting; and `]s` was
language.nvim's, a clash the bindings explorer's own docs had already
recorded (`bindings_explorer/docs/FEATURES.md`) without anyone acting on it.

**Removed 2026-09-18**, along with their rows in
`docs/NOTES/ExternPlugins/Bindings/Keymaps/Snacks.md`. `debug`
(`<leader>ud`/`uD`) and `quickfile` (`<leader>uq`) stay — those modules are
on. The file's docstring now says what the rule is: enable the module in
the spec first, then its keys belong here. The own-side homes the draft
named still hold if the *feature* is wanted rather than the module:
**profiler → runtime-analysis.nvim** (`:RA` already exists), **scratch →
buffer-ctx.nvim or fileops.nvim**.

### 7.3 `<leader>gd` had two owners ✅

Not in the earlier draft. Suggested-order item 1 said "rebind `<leader>gd`
from `:Gdiffsplit` to `:Diff … git:HEAD` — already works", and it did, but
the key was bound twice: fugitive's `keys` spec in `plugins/git.lua`
(`:Gdiffsplit`) and snacks' `keys` spec via
`config/snacks/mappings/standard.lua` (`builtin("git_diff")`, the hunk
picker). Both lazy, both described as a git diff; whichever registered last
won, and nothing said so.

**Resolved 2026-09-18:** `<leader>gd` is diff.nvim's
`:Diff target=git:HEAD`, as a lazy `keys` entry on the diff.nvim spec in
`plugins/personal/init.lua` (not through diff.nvim's own `keymaps.diff_head`
option — the plugin is command-lazy, and an option-registered shortcut would
only exist after the first `:Diff`). Fugitive's key is gone; blame is the one
fugitive key left. The hunk picker moved to `<leader>gD`, following the
`gS`/`gL` capital-variant pattern the same table already uses. The three
cheatsheets that documented the old state (`Keymaps/Fugitive.md`,
`Keymaps/Snacks.md`, `Usercmds/Fugitive.md`) say the new one.

### 7.4 The harpoon rebuild is already 90% written — in the wrong place ✅

**Built 2026-09-19, in the parallel-run phase this entry asked for.**
`sessions.nvim@acdbc70` has a `marks` feature — the ordered list, a cursor
position per entry, pins and config defaults, `defaults sync`/`reset`, an
editable float with the pin flags and the pinned-removal prompt, snacks/
telescope/fzf pickers with shortened labels, the read-only preview, and a
one-time import of harpoon's bucket — behind `marks.enable`, off by
default. Config `54a17d253` turns it on next to harpoon: the
`target_specs` moved out of harpoon's spec into `config/marks/defaults.lua`
so both lists read one set; keys on `<leader>H*` and `<leader>H1..9` while
harpoon keeps `<leader>h*`, `<C-e>`, `<M-1..9>`; the first start took
harpoon's live list over (verified headless: harpoon's two entries in its
order with their cursor rows, then the three remaining defaults). One
session, not the three to five budgeted — the 1,707 lines were mostly
defence against harpoon's own list semantics (`remove_at` leaving nil
holes, `settings.key` re-resolved on every autosave, a debounced save
around a plugin that saves itself), none of which a store this plugin owns
needs.

**One premise of this entry was wrong, and the build kept the config's
behaviour rather than the report's.** It said marks "resolving per project
root and per git branch are a strictly better model than harpoon's flat
list". The config had deliberately gone the other way — one global list
pinned to `stdpath("config")`, documented in `featurelist.md` item 1 as the
fix for "an empty quick menu whenever the cwd differs from where the marks
were set" — because the list holds notes, cheatsheets and the plugin spec,
files wanted in every project. So `scope = "global"` is the default and
`"project"` (root plus branch, keyed like sessions) is the option, not the
reverse.

**Cut over 2026-09-19, same day rather than after a week's trial (user's
call).** The letter keys (`ha`/`hA`/`hp`/`hd`/`hm`/`hs`/`hD`/`he`) moved to
`<leader>h*` 1:1; `<C-e>` (quick menu) and `<M-1..9>` (full-screen preview)
are bound directly to `:Session marks`/`:Session marks preview <n>` in the
plugin spec's `config` function rather than through `keymaps.marks_menu`/
`marks.preview_key` — mixing those two non-`<leader>h`-prefixed keys into
that table would have broken `sessions.bindings.keymaps`' which-key
group-prefix detection (no single common prefix across `<leader>h*`,
`<C-e>` and `<M-%d>`), losing the "Session" group label on `<leader>h`
entirely, not just for those two keys. `select_key` moved to `<leader>h%d`
(a jump-to-entry-N capability harpoon's own bindings never had). Dropped:
harpoon's spec in `plugins/misc.lua` (now an empty scaffold), `bindings/
mappings/harpoon.lua`, `config/harpoon/` (1,707 lines), the four
Harpoon-specific doc files, and every dangling reference found by a
repo-wide grep. `plenary` did **not** leave the startup path the way this
entry expected: `plugins/essentials.lua` already has its own independent
`{ "nvim-lua/plenary.nvim", lazy = false }` spec, unrelated to harpoon's
dependency declaration — a discrepancy this cut-over surfaced rather than
one it caused (7.6 has the correction). The Harpoon cheatsheet is deleted,
not carried forward.

The original finding, kept for the record:

`lua/config/harpoon/` is **1,707 lines** across nine modules:

| Module | Lines | What it is |
|---|---|---|
| `persist_paths.lua` | 647 | pinned target specs, persisted |
| `usrcmds.lua` | 216 | command surface |
| `hardening.lua` | 207 | debounced saves, autocmd guards |
| `api.lua` | 187 | a wrapper API over harpoon2 |
| `preview.lua` | 181 | entry preview |
| `ui/menu_fzf.lua`, `ui/menu_telescope.lua` | 193 | two picker front-ends |
| `pin_marks.lua`, `pin_guard.lua` | 173 | pin semantics harpoon does not have |
| `utils/sanitize.lua`, `health.lua`, `debug.lua`, `types/` | 237 | the rest |

Harpoon contributes a list of file marks with a persisted JSON store and a quick
menu. Everything above is yours. It is also `lazy = false`, so harpoon **and**
plenary are unconditionally in the startup path.

**sessions.nvim** is the right home: already branch- and project-aware, with
`state.lua`, `git.lua`, `meta.lua`, `buforder.lua`, `picker.lua`,
`statusline.lua`, `portable.lua`. Marks resolving per project root and per git
branch are a strictly better model than harpoon's flat list — and the
machine-dependent `target_specs` block in [misc.lua](../../../lua/plugins/misc.lua)
(workstation vs. private) becomes ordinary session metadata instead of a
config-level `if machine.is("workstation")`.

Two front-ends (`menu_fzf`, `menu_telescope`) also collapse into one
`pickers.nvim` call.

**Risk:** this is a daily-driver workflow. Build behind a flag, dual-run for a
week, then cut. Not a plugin to do in a hurry.

### 7.5 `cmdlog.nvim` and plenary — already resolved when this was written ✅

The draft said: across all own repos, `plenary` appears only in
`TESTS/minimal_init.lua` — the busted harness, expected and fine — and two
files broke the pattern, `cmdlog.nvim/lua/cmdlog/core/favorites.lua` and
`core/store.lua`.

**They did not, and had not for seven weeks.** `cmdlog.nvim@104abc7`
(2026-07-30, "chore: drop the plenary.nvim dependency") moved both onto
`lib.nvim`'s `fs.write.to_file`, and each file's docstring says so in its
first lines. The report was written on 2026-09-17 from a stale reading. The
point it was making survives: plenary's presence in this config is now
decided *entirely* by which external plugins keep it (7.6).

### 7.6 The `plenary` dependency chain

**Open — it resolves as the items above do, not on its own. And the
"out of the startup path" half of this entry was wrong when written.**

Plenary is pulled in by harpoon, lazygit, diffview, neogit, telescope and
neotest (resty and todo-comments left 2026-09-19; harpoon left 2026-09-19,
7.4). Doing the lazygit item removes one more of the remaining five. It does
not remove plenary (telescope and neotest keep it) — that much still holds.

What did not hold: this entry assumed harpoon was "the only `lazy = false`
consumer", so cutting it over would take plenary out of the startup path.
Checked while doing that cut-over: `plugins/essentials.lua` has had its own
independent `{ "nvim-lua/plenary.nvim", lazy = false }` spec all along,
entirely unrelated to harpoon's `dependencies = { "nvim-lua/plenary.nvim" }`
declaration. Plenary was never *not* eager, regardless of harpoon. Removing
harpoon changes nothing about plenary's load timing; only dropping that
`essentials.lua` entry (or lazy-loading it) would.

### 7.7 `render-markdown.nvim` was kept disabled — now removed ✅

**Removed 2026-09-19, user decision, no feature carried over.** This entry
originally recommended keeping it: it was carried for an on-demand feature
(`setup({ enabled = false })`, toggled by `:Markdown render`), and a full
rebuild into `markdown.nvim` — concealed rendering of every GFM construct —
was and is **not recommended** (XL, see the Markdown catalogue table above).

That verdict still holds; the plugin left anyway because the feature itself
was no longer wanted, not because a replacement appeared. **Nothing in
mdview.nvim or markdown.nvim covers what render-markdown did.** mdview.nvim
is a browser preview in a separate tab; render-markdown's job was in-buffer
concealed rendering — headers, checkboxes, code-block backgrounds, list
bullets replaced while editing the same buffer. Mechanically unrelated, and
`markdown.nvim`'s `:Markdown render` was only ever a thin wrapper calling
`:RenderMarkdown enable/disable` (`lua/markdown/commands/render.lua`,
`docs/FEATURES/INTEGRATIONS.md`) — no rendering code of its own. With the
plugin gone, that command now just warns "not available", which is the
designed graceful-degradation path for an optional host and needed no
change.

Removed: the spec block in [markdown.lua](../../../lua/plugins/markdown.lua),
its `lazy-lock.json` entry, and its rows in
`docs/NOTES/ExternPlugins/Bindings/TODO.md` and
`docs/NOTES/ExternPlugins/Bindings/Usercmds/Overview.md`.

### 7.8 `lua/config/gp_config/` was orphaned ✅

85 lines configuring `gp.nvim` — API keys for openai/anthropic/ollama, five
agent definitions. **gp.nvim was not in the plugin set**, and `grep -rn gp_config`
across `lua/` returned nothing outside the folder itself. `ai.nvim` is the
replacement and is installed.

Removed 2026-09-18 (`git rm -r`); confirmed no remaining references to
`gp_config` or `require("gp")` anywhere in `lua/`.

### 7.9 `nvzone/menu` — not a leftover ✅

`plugins/nvchad.lua`'s `{ "nvzone/menu", enabled = false }` reads like a stale
fragment but is not: the file documents it as the switch for restoring
`renderer = "nvzone"`. `config/menu/**` runs entirely on `lib.nvim.contextmenu`
and `lib.nvim.ui.kit`, and `require("menu")` appears nowhere. **The replacement
is complete and the disabled spec is the documented escape hatch.** Leave it
alone.

---

## 8. Where this lands

Grouped by the own plugin that gains, so you can see which repos get busy.
Struck entries are done.

| Own plugin | Feature families it would absorb |
|---|---|
| **runtime-analysis.nvim** | ~~resty's `.http` runner~~ (already had it; A1) · ~~vim-startuptime's averaged report~~ (A3) · snacks profiler (the *feature*; its keys are gone, 7.2) |
| **filetree.nvim** | ~~neo-tree source switcher · centralized keymaps · node utils · checkhealth~~ (2026-09-19: `source_switcher`, `tree_toggle`; the noop tables stay as neo-tree config) · tests/diagnostics sources · snacks explorer · window picker (consumer) |
| **diff.nvim** | ~~`:Gdiffsplit`~~ (7.3) · `git blame` · `ToggleInlineDiff` · diffview side-by-side + file history |
| **insights.nvim** | ~~todo scan~~ and ~~todo highlight~~ (both; B2) · git-conflict detection + resolution |
| **sessions.nvim** | ~~harpoon marks, pins, persistence, preview~~ (built and cut over 2026-09-19; 7.4) |
| **debugging.nvim** | ~~neotest adapter debug tooling~~ (`:Debug neotest`, 2026-09-19) · snacks debug inspector |
| **pickers.nvim** | ~~search.nvim tabs~~ (`pickers.tabs`) · ~~bqf quickfix preview~~ (`pickers.quickfix`) · ~~telescope-github~~ (`pickers.sources.github`) · ~~file-browser list~~ (`pickers.browse`) — all 2026-09-19 · neotest picker integration |
| **lib.nvim** | window picker primitive · treesitter `move` helper · lazygit terminal + nvr bridge · ~~devicons data~~ (`lib.nvim.ui.icons`, 2026-09-19) |
| **ui.nvim (notify)** | ~~nvim-notify toasts + history~~ (`ui.notify`, 2026-09-19; the plugin stays until noice is decided) |
| **ui.nvim** | matchup offscreen status · ~~ts-context~~ (B5, as `ui.context`, a float — not the winbar) · ~~which-key popup~~ (`ui.keys`, on request; the plugin stays for the timeout popup) · ~~minty colour picker~~ (`ui.colorpicker`, 2026-09-19) · ~~zen mode~~ (`ui.zen`, 2026-09-19) |
| **markdown.nvim** | ~~table-mode realign + `:Tableize`~~ (already had it, `core/table_mode.lua`; B4) |
| **mdview.nvim** | ~~markdown-preview's scroll sync + combine-preview~~ (already had both; B3) |
| **fileops.nvim** | ~~mkdir-on-write~~ (A2) · ~~file-browser operations~~ (consumed by `pickers.browse`, 2026-09-19) · snacks scratch |
| **emojis.nvim** | unicode name/search/table/digraphs |
| **cascade.nvim** | ~~puppeteer template literals~~ (the `strings` domain, 2026-09-19) |
| **spotlight.nvim** | ~~todo highlight machinery~~ (went to insights instead; B2) · conflict marker highlight |
| **open.nvim** | `:Gbrowse` · lazygit nvr bridge · (`config/ui_open.lua`'s Windows URL fix) |
| **my.nvim** | ~~colorizer swatches~~ (`color_codes`, 2026-09-19) ·  quickfile · colorizer · zen mode |
| **images.nvim** | ~~the only working image path~~ — it already was; `snacks.image` merely stopped pretending (7.1) |

---

## 9. Suggested order

**Free or nearly free — all done 2026-09-18:**

1. ~~Rebind `<leader>gd` from `:Gdiffsplit` to `:Diff … git:HEAD`.~~ Done, and
   the second owner it had is resolved with it (7.3).
2. ~~`snacks.image = false`~~ (7.1).
3. ~~Resolve the dead snacks bindings~~ (7.2) — removed, eight of them.
4. ~~Decide `config/gp_config/`'s fate~~ (7.8) — folder removed.
5. Note: git-conflict and `insights.nvim/conflicts/` are **complementary**, not
   duplicates — repo-level report vs. buffer-level markers. Verified 2026-09-17.

**Cheap removals (S), open:** window-picker → lib/filetree · lazygit float →
lib/open · `:Gbrowse` → open/reposcope. ~~mkdir → fileops~~ (A2). Each of the
three needs its home chosen first; the report names two for each.

**Highest value per session (M), open:** ~~neotest debug tooling →
debugging.nvim~~ (done 2026-09-19, `:Debug neotest`) · ~~puppeteer → cascade~~ (done 2026-09-19) · matchup
offscreen → ui.nvim · `:Git blame` (the one new piece that retires fugitive
+ rhubarb). ~~resty → runtime-analysis~~ (A1, turned out to be S) ·
~~startuptime → runtime-analysis~~ (A3).

**Real projects (L), in order of payoff — all done:** ~~ts-context →
ui.nvim~~ (B5, 2026-09-19, one session: `ui.context`). ~~neo-tree config → filetree.nvim~~ (done 2026-09-19: the config's
2,035 lines were mostly already moved; the last three code-bearing pieces
became filetree's `source_switcher` and `tree_toggle`, ~700 lines of
neo-tree mapping tables stay as config) · ~~harpoon → sessions~~ (7.4,
built and cut over the same day, 2026-09-19) ·
~~todo-comments → insights~~ (B2, one session) · ~~markdown-preview →
mdview~~ (B3).

**Leave alone:** the three picker engines, treesitter, mason, blink, neogit,
gitsigns' hunk engine, noice, mini.ai/targets, autopairs, ts-autotag, matchup's
`%`, visual-multi, nvzone/menu, tokyonight.

~~`render-markdown.nvim`~~ — removed 2026-09-19 (7.7), user decision; was on
this list until then.
