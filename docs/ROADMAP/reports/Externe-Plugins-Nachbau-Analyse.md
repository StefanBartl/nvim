# External plugins — what they are actually used for, and where each feature belongs

**Date:** 2026-09-17
**Question:** every external plugin is installed for a reason. What is that reason
*as configured in this repository* — and if that feature family were rewritten,
which own plugin would it land in, and what would it cost?

---

## Table of content

  - [1. Method, and what this report is not](#1-method-and-what-this-report-is-not)
  - [1. Method](#1-method)
  - [2. The central observation](#2-the-central-observation)
  - [3. Feature-family catalogue](#3-feature-family-catalogue)
    - [A1 · `lima1909/resty.nvim` → **runtime-analysis.nvim** · full replacement](#a1-lima1909restynvim-runtime-analysisnvim-full-replacement)
    - [Git](#git)
    - [Pickers and navigation](#pickers-and-navigation)
    - [Tree](#tree)
    - [Tests](#tests)
    - [UI](#ui)
    - [Editing and text](#editing-and-text)
    - [Markdown](#markdown)
    - [Tooling and infrastructure](#tooling-and-infrastructure)
    - [A2 · `jghauser/mkdir.nvim` → **fileops.nvim** · full replacement ✅](#a2-jghausermkdirnvim-fileopsnvim-full-replacement)
    - [A3 · `dstein64/vim-startuptime` → **runtime-analysis.nvim** · full replacement ✅](#a3-dstein64vim-startuptime-runtime-analysisnvim-full-replacement)
  - [4. Findings worth acting on regardless](#4-findings-worth-acting-on-regardless)
    - [4.1 `snacks.image` is enabled and cannot work here](#41-snacksimage-is-enabled-and-cannot-work-here)
    - [4.2 Keys are bound for five disabled snacks modules](#42-keys-are-bound-for-five-disabled-snacks-modules)
    - [4.3 The harpoon rebuild is already 90% written — in the wrong place](#43-the-harpoon-rebuild-is-already-90-written-in-the-wrong-place)
    - [4.4 `cmdlog.nvim` is the only own runtime consumer of plenary](#44-cmdlognvim-is-the-only-own-runtime-consumer-of-plenary)
    - [B2 · `folke/todo-comments.nvim` → **insights.nvim** · full replacement](#b2-folketodo-commentsnvim-insightsnvim-full-replacement)
    - [B3 · `iamcco/markdown-preview.nvim` → **mdview.nvim** · full replacement ✅](#b3-iamccomarkdown-previewnvim-mdviewnvim-full-replacement)
    - [B4 · `dhruvasagar/vim-table-mode` → **markdown.nvim** · full replacement](#b4-dhruvasagarvim-table-mode-markdownnvim-full-replacement)
    - [B5 · `nvim-treesitter/nvim-treesitter-context` → **ui.nvim** `winbar/` · full replacement](#b5-nvim-treesitternvim-treesitter-context-uinvim-winbar-full-replacement)
  - [6. Tier C — harvest one feature, keep the plugin](#6-tier-c-harvest-one-feature-keep-the-plugin)
  - [7. Findings worth acting on independently](#7-findings-worth-acting-on-independently)
    - [7.1 `snacks.image` is enabled and almost certainly dead weight](#71-snacksimage-is-enabled-and-almost-certainly-dead-weight)
    - [7.2 `render-markdown.nvim` is installed permanently disabled](#72-render-markdownnvim-is-installed-permanently-disabled)
    - [7.3 `cmdlog.nvim` has a runtime dependency on plenary](#73-cmdlognvim-has-a-runtime-dependency-on-plenary)
    - [7.4 The `plenary` dependency chain](#74-the-plenary-dependency-chain)
    - [4.5 `lua/config/gp_config/` is orphaned](#45-luaconfiggp_config-is-orphaned)
    - [4.6 `nvzone/menu` — not a leftover ✅](#46-nvzonemenu-not-a-leftover)
  - [5. Where this lands](#5-where-this-lands)
  - [6. Suggested order](#6-suggested-order)

---

## 1. Method, and what this report is not

## 1. Method

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

---

## 2. The central observation

**For most plugins here, the configured surface is a small fraction of the
plugin.** That is what makes this exercise worth doing, and it is invisible if
you compare plugins as wholes:

| Plugin | Size of the thing | What this config uses |
|---|---|---|
| `vim-fugitive` + `vim-rhubarb` | a full git porcelain | **three commands**: `:Gdiffsplit`, `:Git blame`, `:Gbrowse` |
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

---

### A1 · `lima1909/resty.nvim` → **runtime-analysis.nvim** · full replacement

### Git

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| `vim-fugitive` → **`:Gdiffsplit`** (file vs HEAD) | `<leader>gd`, git.lua:77 | **diff.nvim — already implemented.** `core/git.lua` resolves `git:HEAD`, `git:HEAD~1`, `git:<sha>`, `git:<branch>` for the current file, and `git:HEAD` is already in the `:Diff` source/target completion list. | **S** (rebind only) |
| `vim-fugitive` → **`:Git blame`** | `<leader>gb`, git.lua:79 | **diff.nvim** or **lib.nvim/nvim/git**. Nothing in the own tree does blame — a grep across `lib.nvim`, `diff.nvim`, `insights.nvim`, `ui.nvim`, `sessions.nvim` returns nothing. Genuinely new: `git blame --porcelain`, parse, render per line. | **M** |
| `vim-rhubarb` → **`:Gbrowse`** (open file/selection at the host) | git.lua:84 | **open.nvim** routes targets to destinations; **reposcope.nvim** already knows GitHub/GitLab/Codeberg. Remote URL → web URL + line anchor. | **S–M** |
| `gitsigns` → **signcolumn hunks, stage/reset/preview** | `config = true`; actions wired in `config/menu/git.lua` | Keep. Sign management plus incremental diff on every change is the plugin. | **XL** |
| `gitsigns` → **`:ToggleInlineDiff`** (invert `word_diff`+`linehl`, preview hunk inline) | `bindings/mappings/git.lua:17,79` | **diff.nvim** — the *logic* is already yours; only the gitsigns calls underneath would change. Tied to the line above, so it only moves if hunks move. | **M** |
| `diffview` → **side-by-side diff, file history** | `<leader>dv/dc/dh`; `config = true` | **diff.nvim** already delivers "split, inline, prompt, file, clipboard". File *history* (revision list + per-revision diff) is the missing half. | **L** |
| `neogit` → **magit-style status buffer** | `<leader>gg`, `kind = "split"` | Keep. A staging UI is a project, not a feature. | **XL** |
| `git-conflict.nvim` → **repo-level unmerged-file report** (`:GitConflictListQf`) | `config = true` | **insights.nvim** — `conflicts/` already asks git for files in the `unmerged` state and puts them in the quickfix list. This one family *is* already covered. | **S** |
| `git-conflict.nvim` → **buffer-level marker surgery** (9 commands, 6 buffer-local keys) | defaults; full command list in `docs/NOTES/ExternPlugins/Bindings/Usercmds/GitConflict.md` | **Not** covered by insights — that is a repo-level report, this is line-level text work on markers. Pure buffer parsing plus extmarks, no git plumbing. See [git_nvim.md](../LONG_RUN/IDEAS/git_nvim.md). | **M–L** |
| `lazygit.nvim` → **float terminal running `lazygit`** | `<leader>lg` | **lib.nvim** has `terminal/`, `window/`, `git/`, `cross/`. This is wiring. | **S** |
| `lazygit.nvim` → **`nvr` callback bridge** (`:LazygitBadd`, `:LazygitReplace` — LazyGit's `O` / `<C-o>` open files in the *parent* nvim) | `config/lazygit/**`, 146 lines | **This is the real content, and it is already yours.** The commands, path resolution and focus-safe replace are written; only `vim.g.lazygit_use_neovim_remote` belongs to the plugin. Home: **open.nvim** (routing a target into the right window) or **lib.nvim**. | **M** |

> **Net:** `<leader>gd` is replaceable today with no new code. `:Gbrowse` and the
> lazygit float are cheap. That retires **fugitive + rhubarb + lazygit.nvim** —
> three repos — once blame is built, which is the only genuinely new piece.

The decisive argument is in the config's own comment in
[webdev.lua](./lua/plugins/webdev.lua): resty cost roughly **600 ms of startup**
because loading it drags in telescope, nvim-cmp and LuaSnip through its
`plugin/` and `after/plugin/` files, defeating their own lazy triggers. The
current spec is an elaborate `vim.filetype.add` + autocmd workaround built
purely to contain that damage. Deleting resty deletes the workaround too.

---

### Pickers and navigation

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| `snacks.nvim` → **picker engine** | `picker = picker_config.get_config()`; all but one binding in `snacks/mappings/standard.lua` is tagged `[pickers]` and dispatches through `builtin()`/`scope_action()` | Keep — `pickers.nvim` sits *on top* of it by design. Correct relationship. | **XL** |
| `snacks.nvim` → **explorer** | `<leader>F`, the one direct `snacks.explorer()` call | **filetree.nvim** — it is already an adapter over neo-tree/nvim-tree/netrw/oil/mini.files. | **M** |
| `snacks.nvim` → **quickfile** | `enabled = true` | Render the file before plugins load. **my.nvim** (per-buffer visual layer) or **lib.nvim**. | **S** |
| `snacks.nvim` → **debug inspector / overlay** | `<leader>ud`, `<leader>uD` | **debugging.nvim** — `:Debug {category} {action}` is exactly this dispatcher. | **M** |
| `snacks.nvim` → **image** | `enabled = true` | **images.nvim owns this, and the snacks module cannot work here.** See §4.1. | **S** (disable) |
| `telescope.nvim` → **picker engine** | `cmd = "Telescope"` | Keep. Note `pickers.nvim` already patches telescope's `defaults.history` and preview-scroll/history-nav keys globally. | **XL** |
| `telescope-file-browser` → **browse + create/rename/delete from a picker** | `config/telescope/init.lua` merges its keymaps | **fileops.nvim** (the operations, already libuv-direct) + **pickers.nvim** (the list). Both halves exist; only the composition is missing. | **M** |
| `telescope-github` → **issues / PRs / gists as pickers** | `lazy = true` extension; GitHub bindings exist in `snacks/mappings/standard.lua` as `[pickers]` entries | **reposcope.nvim** (already talks to GitHub/GitLab/Codeberg) + **github_stats.nvim**, delivered through **pickers.nvim** so it is not telescope-bound. | **M** |
| `telescope-fzf-native` → **native sorter** | compiled C | Keep. Nothing to rebuild. | — |
| `search.nvim` → **tabbed picker groups** | one key, `config/search/init.lua` (86 lines of tab/collection definitions) | **pickers.nvim** — `:Pickers <scope> <action>` is already a grammar over scopes; tabs are a UI on top. The collections are already your data. | **M** |
| `fzf-lua` → **picker engine** | `config/fzf/**`, already consumes `pickers.entry_actions.adapters.fzf` | Keep. Same relationship as snacks/telescope. | **XL** |
| `nvim-bqf` → **quickfix preview + auto-resize** | `auto_enable`, `auto_resize_height` — nothing else | **pickers.nvim** — it already has a `refine` filter stack (wired as `<C-f>` in replacer.nvim), and preview is core picker machinery. | **M** |
| `nvim-window-picker` → **pick a window by letter** | filter rules; single call site `config/neotree/keymaps/filesystem/files.lua:44`, already `pcall`-guarded | **lib.nvim/nvim/window** (the primitive) consumed by **filetree.nvim**. Fallback path already exists, so a partial build degrades safely. | **S** |
| `harpoon` → **pinned file marks + quick menu** | `config/harpoon/**`, **1,707 lines**, `lazy = false` | **sessions.nvim** — see §4.3. | **L** |

---

### Tree

`lua/config/neotree/**` is ~1,500 lines. `filetree.nvim` is deliberately an
*adapter* over neo-tree, so the tree itself is not a rebuild target. These are
the pieces that are config code today and should be plugin code:

| Feature family | Evidence | Target | Effort |
|---|---|---|---|
| **Hover-based source switcher** | `sources/switcher.lua` (303 lines) — **already draws with `lib.nvim.ui.kit`** | **filetree.nvim** | **M** |
| **Centralized buffer-local keymaps + `only_lhs` variant** | `keymaps/**` (~460 lines across filesystem/buffers/git_status/diagnostics/document_symbols) | **filetree.nvim** — it already owns `d` (trash), buffer-local, "always wins, verified" | **M** |
| **Node utilities** | `utils/node.lua` (158 lines) | **filetree.nvim** adapter interface | **S** |
| **Checkhealth** | `checkhealth/**` (81 lines) | **filetree.nvim** `health.lua` | **S** |
| `neo-tree-tests-source` / `neo-tree-diagnostics` → **extra sources** | spec `dependencies` | **filetree.nvim** as adapter-level sources | **M** each |
| `nui.nvim` | dependency of neo-tree and noice | Leaves only when both do. `lib.nvim.ui.kit` is the own equivalent. | — |

---

### Tests

`lua/config/neotest/**` is ~1,500 lines around a runner that should stay.

| Feature family | Evidence | Target | Effort |
|---|---|---|---|
| **Test running / discovery / adapters** | the plugin | Keep. | **XL** |
| **Adapter debug tooling** — `:NeotestDebugAdapters`, `State`, `File`, `Root`, `Framework`; "diagnosing why an adapter isn't finding tests in a file" | `debug/init.lua`, **309 lines** | **debugging.nvim.** Its entire thesis is that debugging tools accumulate as scattered one-off commands and belong behind one dispatcher with two-level completion. This is a textbook case, and the code already exists. | **M** |
| **Adapter registration layer** (factory + a 239-line TypeScript adapter) | `adapters/**` (381 lines) | Structurally identical to **dap.nvim** ("a config layer that registers adapters and launch configurations, so `opts = {}` is a working debugger"). A `tests.nvim` sibling — or a `dap.nvim`-style neotest module — is the same pattern twice. | **L** |
| **whichkey / telescope / neo-tree integration wrappers** | `whichkey/`, `telescope/`, `neotree/`, `consumers/` (~240 lines) | **pickers.nvim** / **filetree.nvim** — engine-agnostic instead of per-integration. | **M** |

---

### UI

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| `noice.nvim` → **cmdline UI, message routing, LSP progress, popupmenu** | `config/noice/**`, 187 lines of routes/views/presets | Keep. Message-system interception is a project. | **XL** |
| `nvim-notify` → **toast backend** | only a noice dependency | Coupled to noice. `lib.nvim` has `notify/`; notification *history* is already reachable via `builtin("notifications")` through pickers. | — |
| `nvim-treesitter-context` → **sticky context, 3 lines** | `enable = true, max_lines = 3` | **ui.nvim/winbar/** — it owns the frame, and `lib.nvim` has `treesitter/`. The concept is easy; the incremental-update/large-file/fold behaviour is the actual work, and `winbar/` is one `init.lua` today. | **L** |
| `vim-matchup` → **extended `%`** | `event`, `stopline = 500` | Keep. Per-language match definitions are the plugin. | **XL** |
| `vim-matchup` → **offscreen match shown in the status line** | `matchup_matchparen_offscreen = { method = "status" }` | **ui.nvim/statusline** — small, self-contained, and squarely in ui.nvim's domain. A nice piece to lift even though the host plugin stays. | **M** |
| `which-key.nvim` → **pending-key popup** | `opts = {}`; wired to `:WhichKey`, `<leader>wK`, `<leader>w?`, harpoon, neotest | **ui.nvim.** Cheaper than it looks: the label/group data model is normally the hard part, and you already have a keymap corpus — `:Bindings` (search/browse over `docs/BINDINGS.md` per plugin plus the extern cheatsheets) and `:LibBindingsAudit*` / `:LibKeymapConflicts`. The popup can read what the explorer already parses. | **M–L** |
| `zen-mode.nvim` → **distraction-free single window** | `cmd` only, no `opts` — pure defaults | **my.nvim** or **ui.nvim**. `lib.nvim/nvim/window` + `ui/` cover the mechanics; ui.nvim already controls statusline/tabline visibility, which is the fiddly half. | **S–M** |
| `nvim-colorizer.lua` → **inline hex / CSS / named colour swatches** | `opts = {}` — pure defaults | **my.nvim** (per-buffer visual features) or **color_my_ascii.nvim**. Concept trivial, large-file performance is not. | **M–L** |
| `nvzone/minty` → **colour picker** | one call: `minty.huefy` from the right-click menu's "Color Picker" entry | **ui.nvim/theme** or **color_my_ascii.nvim**. Takes `nvzone/volt` with it. | **M** |
| `nvim-web-devicons` → **filetype → icon + colour** | `ui.nvim/statusline/modules/file_icons/devicons.lua` already isolates it behind an adapter | **lib.nvim.** A *data* import, not an architecture change — the adapter seam exists. Low value (devicons is cheap and stable), but it makes ui.nvim and lsp.nvim dependency-free. | **M** |
| `vim-visual-multi` → **`<C-n>` find-under, edit all occurrences** | `VM_default_mappings = 0`; only `Find Under` / `Find Subword Under` bound | The tiny configured surface is misleading: the multi-cursor state machine is the difficulty, not the entry point. **spotlight.nvim** already marks every occurrence of a token and keeps the marks through searches and edits — the *selection* half is solved; simultaneous editing is not. Keep, but note the seam. | **L–XL** |
| `nvzone/menu` → **right-click menu** | `enabled = false` | **Already done** — `config/menu/**` (855 lines) draws through `lib.nvim.contextmenu` + `lib.nvim.ui.kit`, and `require("menu")` appears nowhere in the tree. The disabled spec is a documented escape hatch (`renderer = "nvzone"`), not a leftover. Leave it. | — |

---

### Editing and text

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| `nvim-puppeteer` → **quotes → template literal when `${}` is typed** | `lazy = false`, **no configuration at all** | **cascade.nvim.** Its stated pattern is *detect the context under the cursor → advance it one step → otherwise fall back to native behavior*. This is that pattern, in a small plugin, with no config to preserve. Best fit in the whole report. | **M** |
| `nvim-autopairs` → **auto-close pairs** | `opts = {}` | cascade.nvim is philosophically adjacent, but pair handling is an edge-case library. Keep. | **L–XL** |
| `nvim-ts-autotag` → **close + rename HTML/TSX tags** | `enable_close`, `enable_rename`, html close off | Treesitter query work per language. Keep. | **L** |
| `nvim-treesitter-textobjects` → **`[u`/`]u` climb out of the enclosing structure** | `bindings/mappings/treesitter_structure.lua`; `move` module on `@block.outer` — **and the queries extending it for lua/json/python/rust/toml/yaml are already yours** in `after/queries/` | **lib.nvim/nvim/treesitter** gets a `move` helper; the binding stays in config. Only the `move` module is used — not swap, not lsp_interop, not select. | **M** |
| `mini.ai`, `targets.vim` → **textobjects** | pure defaults | Keep. No own plugin owns this domain and creating one has no payoff. | **XL** |
| `vim-table-mode` → **realign while typing, `:Tableize`** | `table_mode_corner = "|"`, `cmd` + `ft` gated | **markdown.nvim** — `tableview/` already has `parser.lua`, `renderer.lua`, `views/`. The model exists; the interactive half is missing. | **M** |
| `unicode.vim` → **`:UnicodeName`, `:UnicodeSearch`, `:UnicodeTable`, `:Digraphs`** | `cmd` list + `uni` key | **emojis.nvim** — it already ships a pure UTF-8 byte tokenizer with no external library, which is the hard half of `:UnicodeName`. The rest is a Unicode name table (a few hundred KB of data) plus digraphs, which Neovim partly exposes via `vim.fn.digraph_get*`. **If only `:UnicodeName` is really used, this drops to S — worth checking your own habit first.** | **M** |

---

### Markdown

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| ~~`markdown-preview.nvim` → **browser preview with scroll sync**~~ | ~~driven by `markdown.nvim`'s `:Markdown preview` through `vim.g.mkdp_*`; `build = "cd app && yarn install"`; hardcoded per-platform Chrome paths~~ | **Done — B3, shipped 2026-09-18.** `markdown.nvim` now drives `:MDView start`/`stop`; markdown-preview.nvim uninstalled. Scroll sync and combine-preview were already covered by mdview's `browser.behavior = "reuse"` and `:MDView sync` — no new feature work, only the rewire. | **done** |
| `render-markdown.nvim` → **in-buffer concealed rendering** | installed and immediately `setup({ enabled = false })`; toggled by `:Markdown render` | Keep, deliberately. Same shape as the `nvzone/menu` entry: carried for an on-demand feature. A full rebuild into markdown.nvim means concealed rendering of every GFM construct — **not recommended.** | **XL** |

---

### Tooling and infrastructure

| Plugin → feature family | Evidence | Target | Effort |
|---|---|---|---|
| `resty.nvim` → **HTTP client on `.http`/`.resty` buffers** | `config` is an elaborate `vim.filetype.add` + autocmd workaround, documented as containing a ~600 ms startup cost | **runtime-analysis.nvim** already has `curl.lua`, `runner.lua`, `parse.lua`, `env.lua`, `graphql.lua`, `multipart.lua`, `assertions.lua`, `history.lua`, `view.lua`, `inspect.lua` — a complete REST client. Missing piece: running the request under the cursor out of an `.http` buffer. Whether `parse.lua` already speaks that syntax is **unverified**. Deleting resty deletes the workaround with it. | **M–L** |
| `vim-startuptime` → **repeated runs, averaged, sorted, navigable** | `cmd` only | **runtime-analysis.nvim** — **done 2026-09-17**, see A3 below. Uninstalled. The "only the presentation is missing" reading in this row was wrong and is corrected there. | **done** |
| `todo-comments.nvim` → **keyword scan** | `config/todo_comments/**` — the keyword table and colours are **already yours**; both keymaps call `snacks.picker.todo_comments()` directly, bypassing the plugin | **insights.nvim** — `scan/rg.lua` + `scan/cache.lua` already run project-wide ripgrep scans for conflicts, unused imports, stray dev servers. | **M** |
| `todo-comments.nvim` → **in-buffer highlight + signs** | `signs = true` | **spotlight.nvim** — "mark any number of tokens at once, in colours you can tell apart, and keep them there through searches" is the same machinery. | **M** |
| `mkdir.nvim` → **create missing parent dirs on write** | `lazy = true`, no config | **fileops.nvim** — one `BufWritePre` autocmd, in the plugin whose stated job is keeping buffer and disk in agreement. 15–30 lines. | **S** |
| `mason.nvim` → **installer registry** | `lazy = false`; `lsp.nvim` and `:MasonInstallAll` `require("mason")` directly | Keep. | **XL** |
| `plenary.nvim` → **shared Lua helpers** | `lazy = false` — unconditionally in the startup path | Not a rebuild target; a *dependency-chain* question. See §4.4. | — |
| `nvim-treesitter` | — | Keep, obviously. | — |
| `blink.cmp` → **completion engine** | active engine (`vim.g.lsp_nvim.pack.completion` defaults to `"blink"`) | Keep. | **XL** |
| `nvim-cmp` | `lsp.nvim`'s cmp spec resolves `enabled = false`; **not installed** | Nothing to do — the spec fragment exists so flipping one option moves the accept/dismiss keys with it. | — |
| `tokyonight.nvim` → **palette** | — | Keep. `ui.nvim/theme/` *assembles* themes rather than authoring palettes — correct division already. | — |

---

### A2 · `jghauser/mkdir.nvim` → **fileops.nvim** · full replacement ✅

### A3 · `dstein64/vim-startuptime` → **runtime-analysis.nvim** · full replacement ✅

Shipped 2026-09-17 as `:RA startup profile [runs]`; the plugin is uninstalled.

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

## 4. Findings worth acting on regardless

### 4.1 `snacks.image` is enabled and cannot work here

[snacks.lua:52](./lua/plugins/snacks.lua) sets `image = { enabled = true }`, with a
comment naming the **Kitty graphics protocol** and WezTerm. Per the established
finding in this setup, Kitty-APC never renders from inside nvim on this machine
— which is exactly why `images.nvim` draws through **iTerm2 OSC 1337** and says
so in its README.

So the module is enabled, loads, and renders nothing, while a second image path
that does work sits next to it. Flipping it to `false` is one line.
**Verify once in the actual terminal first.**

State: Implementiert in fileops.nvim am 17.02.2026

---

### 4.2 Keys are bound for five disabled snacks modules

`config/snacks/mappings/extended.lua` registers `<leader>u*` bindings for
`dim`, `profiler`, `scope`, `scratch` and `toggle`. All five are
`enabled = false` in the spec. The dispatcher is defensive — `safe_call` emits
`[snacks] missing <mod>.<fn>()` rather than erroring — so the failure mode is a
warning, not a crash. Still: five keys that cannot work.

Either enable the modules or drop the bindings. Two of them have own-side homes
if you want the feature rather than the module: **profiler → runtime-analysis.nvim**,
**scratch → buffer-ctx.nvim or fileops.nvim**.

---

### 4.3 The harpoon rebuild is already 90% written — in the wrong place

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

`sessions.nvim` is the right home: it is already branch- and project-aware,
already has `state.lua`, `git.lua`, `meta.lua`, `buforder.lua`, `picker.lua`
and `statusline.lua`. Marks that resolve per project root and per git branch are
a strictly better model than harpoon's, and the machine-dependent
`target_specs` block in [misc.lua](./lua/plugins/misc.lua) (workstation vs.
private) becomes ordinary session metadata instead of a config-level `if`.
**sessions.nvim** is the right home: already branch- and project-aware, with
`state.lua`, `git.lua`, `meta.lua`, `buforder.lua`, `picker.lua`,
`statusline.lua`, `portable.lua`. Marks resolving per project root and per git
branch are a strictly better model than harpoon's flat list — and the
machine-dependent `target_specs` block in [misc.lua](./lua/plugins/misc.lua)
(workstation vs. private) becomes ordinary session metadata instead of a
config-level `if machine.is("workstation")`.

Two front-ends (`menu_fzf`, `menu_telescope`) also collapse into one
`pickers.nvim` call.

**Risk:** this is a daily-driver workflow. Build behind a flag, dual-run for a
week, then cut. Not a plugin to do in a hurry.

---

### 4.4 `cmdlog.nvim` is the only own runtime consumer of plenary

### B2 · `folke/todo-comments.nvim` → **insights.nvim** · full replacement

**Benefit: high. Effort: 2–3 sessions. Risk: low.**

The pieces are already distributed across own code:

- **Keywords and colors** are already yours — `lua/config/todo_comments/keywords.lua`
  and `colors/strong.lua`, passed into the external plugin.
- **The search** is already ripgrep — `insights.nvim/scan/rg.lua` + `scan/cache.lua`.
  insights already runs project-wide scans for conflicts, unused imports and stray
  dev servers; "lines matching a keyword set" is the same shape.
- **The picker** already bypasses todo-comments: both keymaps in
  [workflow.lua](./lua/plugins/workflow.lua) call `snacks.picker.todo_comments()`
  directly, and `pickers.nvim` is the engine-agnostic layer for exactly that.
- **The highlighting** is the only genuinely new part: extmarks on keyword
  matches in visible buffers, plus signs. `spotlight.nvim` already does
  "mark many tokens at once, in distinguishable colors, and keep them there
  through searches and edits" — that is the same machinery.

So: scan in `insights.nvim`, highlight through `spotlight.nvim`'s mechanism,
list through `pickers.nvim`. Three own plugins each gain a feature, and one
external plugin plus its `plenary` and `devicons` dependencies leave.

---

### B3 · `iamcco/markdown-preview.nvim` → **mdview.nvim** · full replacement ✅

**Benefit: high. Effort: 2–4 sessions. Risk: medium.**

**Shipped 2026-09-18.** `markdown.nvim`'s `commands/preview.lua` now drives
`:MDView start`/`:MDView stop` instead of `:MarkdownPreview`/
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

---

### 7.1 `snacks.image` is enabled and almost certainly dead weight

[snacks.lua:52](./lua/plugins/snacks.lua) sets `image = { enabled = true }`, with a
comment describing the **Kitty graphics protocol**. Per the established finding
in this setup, Kitty-APC never renders from inside nvim on this machine — which
is precisely why `images.nvim` draws through **iTerm2 OSC 1337** instead, and
says so in its README.

So this module is enabled, loads, and renders nothing. Setting it to `false` is
a one-line change that costs nothing and removes a confusing second image path.
**Verify once in the actual terminal, then flip it.**

---

### 7.2 `render-markdown.nvim` is installed permanently disabled

[markdown.lua](./lua/plugins/markdown.lua) installs it and immediately calls
`setup({ enabled = false })`, with `:Markdown render` as the toggle. So it is
carried for an on-demand feature. Fine as-is — but note that a *full* rebuild
into `markdown.nvim` is a large project (concealed rendering of every GFM
construct) and is **not** recommended. Left out of the tiers deliberately.

---

### 7.3 `cmdlog.nvim` has a runtime dependency on plenary

Everywhere else in the own repos, `plenary` appears only in
`TESTS/minimal_init.lua` (the busted harness — expected and fine). Two files
break that pattern:
Across all own repos, `plenary` appears only in `TESTS/minimal_init.lua` — the
busted harness, expected and fine. Two files break the pattern:

- `cmdlog.nvim/lua/cmdlog/core/favorites.lua`
- `cmdlog.nvim/lua/cmdlog/core/store.lua`

`lib.nvim` covers path, fs and JSON. It is a small migration, and it matters
because afterwards plenary's presence is decided *entirely* by which external
plugins survive.

---

### 7.4 The `plenary` dependency chain
The chain: plenary is pulled in by harpoon, todo-comments, resty, lazygit,
diffview, neogit, telescope, neotest — and cmdlog. Doing the resty, lazygit,
harpoon, todo-comments and cmdlog items removes five of nine. It does not remove
plenary (telescope and neotest keep it), but it does take it **out of the
startup path**, since harpoon is the only `lazy = false` consumer.

---

### 4.5 `lua/config/gp_config/` is orphaned

85 lines configuring `gp.nvim` — API keys for openai/anthropic/ollama, five
agent definitions. **gp.nvim is not in the plugin set**, and `grep -rn gp_config`
across `lua/` returns nothing outside the folder itself. `ai.nvim` is the
replacement and is installed.

---

### 4.6 `nvzone/menu` — not a leftover ✅

`plugins/nvchad.lua`'s `{ "nvzone/menu", enabled = false }` reads like a stale
fragment but is not: the file documents it as the switch for restoring
`renderer = "nvzone"`. `config/menu/**` runs entirely on `lib.nvim.contextmenu`
and `lib.nvim.ui.kit`, and `require("menu")` appears nowhere. **The replacement
is complete and the disabled spec is the documented escape hatch.** Leave it
alone.

---

## 5. Where this lands

Grouped by the own plugin that gains, so you can see which repos get busy:

| Own plugin | Feature families it would absorb |
|---|---|
| **runtime-analysis.nvim** | resty's `.http` runner · ~~vim-startuptime's averaged report~~ (done 2026-09-17, A3) · snacks profiler |
| **filetree.nvim** | neo-tree source switcher · centralized keymaps · node utils · checkhealth · tests/diagnostics sources · snacks explorer · window picker (consumer) |
| **diff.nvim** | `:Gdiffsplit` (done) · `git blame` · `ToggleInlineDiff` · diffview side-by-side + file history |
| **insights.nvim** | todo scan · git-conflict detection + resolution |
| **sessions.nvim** | harpoon marks, pins, persistence, preview |
| **debugging.nvim** | neotest adapter debug tooling · snacks debug inspector |
| **pickers.nvim** | search.nvim tabs · bqf quickfix preview · telescope-github · file-browser list · neotest picker integration |
| **lib.nvim** | window picker primitive · treesitter `move` helper · lazygit terminal + nvr bridge · devicons data |
| **ui.nvim** | matchup offscreen status · ts-context winbar · which-key popup · minty colour picker · zen mode |
| **markdown.nvim** | table-mode realign + `:Tableize` |
| **mdview.nvim** | ~~markdown-preview's scroll sync + combine-preview~~ (already had both; done 2026-09-18, B3) |
| **fileops.nvim** | mkdir-on-write · file-browser operations · snacks scratch |
| **emojis.nvim** | unicode name/search/table/digraphs |
| **cascade.nvim** | puppeteer template literals |
| **spotlight.nvim** | todo highlight machinery · conflict marker highlight |
| **open.nvim** | `:Gbrowse` · lazygit nvr bridge · (`config/ui_open.lua`'s Windows URL fix) |
| **my.nvim** | quickfile · colorizer · zen mode |

---

## 6. Suggested order

**Free or nearly free — do these first:**

A1–A6 plus 7.5 is **seven repositories removed** for roughly six sessions.
Adding B1–B4 brings it to eleven, for roughly ten more.

---

1. Rebind `<leader>gd` from `:Gdiffsplit` to `:Diff … git:HEAD`. Already works.
2. `snacks.image = false` (§4.1), after one terminal check.
3. Resolve the five dead snacks bindings (§4.2).
4. Decide `config/gp_config/`'s fate (§4.5).
5. Note: git-conflict and `insights.nvim/conflicts/` are **complementary**, not duplicates — repo-level report vs. buffer-level markers. Verified 2026-09-17.

**Cheap removals (S):** mkdir → fileops · window-picker → lib/filetree ·
lazygit float → lib/open · `:Gbrowse` → open/reposcope.

**Highest value per session (M):** resty → runtime-analysis (removes a repo, an
autocmd workaround and a documented 600 ms startup hazard) · neotest debug
tooling → debugging.nvim (309 lines, already written) · puppeteer → cascade ·
startuptime → runtime-analysis · matchup offscreen → ui.nvim.

**Real projects (L), in order of payoff:** todo-comments → insights + spotlight ·
~~markdown-preview → mdview (removes the node/yarn build)~~ done 2026-09-18, B3 ·
harpoon → sessions (1,707 lines out of the config; flag it, dual-run it, then
cut) · neo-tree config → filetree.nvim (~1,500 lines, same argument).

**Leave alone:** the three picker engines, treesitter, mason, blink, neogit,
gitsigns' hunk engine, noice, mini.ai/targets, autopairs, ts-autotag, matchup's
`%`, visual-multi, render-markdown, nvzone/menu, tokyonight.

---

