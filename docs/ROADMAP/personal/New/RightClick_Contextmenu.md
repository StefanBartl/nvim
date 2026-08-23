# Right-Click Context Menu — Plugin Integration Survey

Original idea (kept for reference): wie filetree.nvim bereits ein Modul für das
`/menu`-Plugin bietet, weitere mögliche Einträge aus allen eigenen Plugins
sammeln. Idee: ein Text-Eintrag "MyPlugins" → jedes Plugin ein Entry → Aktion.

Full audit of all 31 `C:\repos\*.nvim` plugins against this idea, done via two
parallel Explore passes. Below: how the RightMouse menu actually works today
(more than either subagent saw in isolation), the concrete change needed to
get the "one fly-out entry per plugin" model, then the per-plugin verdicts.

---

## 1. How it already works today

Two independent things exist and compose:

1. **`nvzone/menu`** is installed via `lua/plugins/nvchad.lua`, initialized by
   `lua/config/menu/custom_menu/init.lua` (the "default"/"custom" named menu:
   Format Buffer, Code Actions, Lsp Actions ▸, Copy/Paste, Delete, Git
   Actions ▸, tools) and bound to keys by `lua/config/menu/mappings.lua`.
2. **`lua/config/menu/mappings.lua`** owns the actual `<RightMouse>` (and
   `<A-b>`) keymap. On every right-click it:
   - resolves the clicked window/buffer's filetype,
   - if the buffer is Markdown, calls
     `require("markdown.integrations.menu").items()` and flattens those items
     on top of the general custom menu (`markdown_menu_source()`),
   - otherwise routes to `"nvimtree"` / `"custom"` / `"default"` by filetype,
   - **but a buffer-local mapping always wins first** — e.g. filetree.nvim
     binds its own `<RightMouse>` directly on the Neo-tree buffer
     (`filetree/features/ui/context_menu/init.lua`), so this global handler's
     body never runs there at all.

So there are already **two distinct, working integration patterns**, not one:

| | Pattern A — "owns its buffer" | Pattern B — "contributes to the global menu" |
|---|---|---|
| Who binds `<RightMouse>` | the plugin itself, buffer-local, on a special buffer/window it creates | the shared `config/menu/mappings.lua` dispatcher, filetype-routed |
| Example today | **filetree.nvim** (Neo-tree buffer) | **markdown.nvim** (any `markdown`/`md`/`mdx` buffer) |
| Plugin ships | `integrations/menu.lua` (`M.items()`/`M.submenu()`) **+** `features/ui/context_menu` (soft-requires `menu`, calls `menu.open(items,{mouse=true})`) | only `integrations/menu.lua` — no trigger code, no `nvzone/menu` dependency at all |
| Fits plugins whose actions apply to... | a dedicated UI buffer only the plugin creates (tree, dashboard, list-view) | ordinary edit buffers, gated by filetype or "any buffer" |

Both `filetree.integrations.menu` and `markdown.integrations.menu` already
expose `M.submenu(label)` — a single `{name=label, items=…}` entry, i.e. the
fly-out shape from screenshot 3 ("Lsp Actions ▸"). The dispatcher just isn't
using it for markdown yet: `markdown_menu_source()` currently does
`vim.list_extend(composed, items)`, which spreads markdown's entries flat
into the top-level list instead of nesting them under one "Markdown ▸" entry.
**That's the one concrete fix needed to realize the "MyPlugins" idea**: swap
`items()` for `submenu("  Markdown")` in `markdown_menu_source`, and do the
same for every new Pattern-B plugin below.

Aside: `lib.nvim`'s own `lua/lib/nvim/ui/kit/menu.lua` is a *different*,
cursor-anchored (not mouse-anchored) menu primitive built on `ui.kit.chooser`.
It's unrelated to this feature — nothing here should be rebuilt on it, since
`relative="cursor"` doesn't give `nvzone/menu`'s `{mouse=true}` pointer
positioning that `<RightMouse>` needs.

---

## 2. Recommended model

Keep both patterns, applied by plugin shape:

- **Pattern A** (own the trigger) for plugins whose actions only make sense
  on a dedicated buffer/window *the plugin itself creates* — sandbox.nvim's
  list-views, github_stats.nvim's dashboard, documentation.nvim's
  `:DocBrowse`, reposcope.nvim's own UI. These plugins ship both
  `integrations/menu.lua` and their own `context_menu` feature, exactly like
  filetree.nvim — no change to `config/menu/mappings.lua` needed, since a
  buffer-local mapping shadows the global one automatically.
- **Pattern B** (contribute only) for plugins whose actions apply to normal
  filetype- or condition-scoped buffers — images.nvim (markdown/vimwiki/
  norg/text), cascade.nvim (list-capable filetypes), lsp.nvim (any
  LSP-attached buffer), open.nvim (any buffer). These ship only
  `integrations/menu.lua` (`M.items()` + `M.submenu()`), and
  `config/menu/mappings.lua` grows one more `<plugin>_menu_source(buf)`
  branch per plugin, each contributing its `submenu()` as one fly-out entry
  into the composed menu — literally the "MyPlugins → each plugin one entry"
  idea, just spread across the already-existing dispatcher instead of a new
  wrapper module. (A single extra "  My Plugins ▸" wrapper entry containing
  *all* Pattern-B submenus, instead of each at top level, is a five-line
  change in the dispatcher if preferred — worth deciding once there's more
  than 2–3 of them, see open question below.)

Either way: **the guard "is `nvzone/menu` installed?" only ever needs to live
in whichever module actually calls `require("menu")`/`menu.open()`** — that's
the plugin's own `context_menu` feature for Pattern A, or the shared
dispatcher for Pattern B. `integrations/menu.lua` itself stays pure data and
never needs to know nvzone/menu exists, in both plugins that already have it.

---

## 3. Per-plugin verdicts

Legend: **A** = Pattern A (owns trigger), **B** = Pattern B (contributes to
dispatcher), context = where the entry should fire.

### Already done
| Plugin | Pattern | Context | Status |
|---|---|---|---|
| filetree.nvim | A | Neo-tree buffer | ✅ complete |
| markdown.nvim | B | markdown/md/mdx buffers | ✅ complete, but flat — switch to `submenu()` |

### YES — worth building
| Plugin | Pattern | Context | Candidate entries |
|---|---|---|---|
| **sandbox.nvim** | A | its own list-view buffers (container/image/volume/network) | Start/Stop/Restart, Exec shell, Show/Follow logs, Remove, Inspect — `lua/sandbox/ui/list_actions.lua` already has a near-identical "item under cursor → action" dispatcher, this is the strongest structural match to filetree.nvim in the whole survey |
| **cascade.nvim** | B | list-capable filetypes (same buffers markdown.nvim already targets) | Toggle checkbox, Cycle list marker, Renumber list, Rotate list form, Sort A-Z, Strip checkboxes — natural as a submenu *contributed alongside* markdown.nvim's, not merged into it |
| **lsp.nvim** | B | any LSP-attached buffer | Rename symbol, Code action, Go to references/implementation, Format buffer, Toggle diagnostics — note this may overlap with the "Lsp Actions" section `config/menu/custom_menu` already ships; check for duplication before adding |
| **open.nvim** | B | any buffer, incl. when a tree buffer (Neo-tree/nvim-tree/netrw) is focused | Open (default), Open in browser, Open in file manager, Open in terminal, List links here — already the most cursor/click-context-aware plugin surveyed |
| **images.nvim** | B | markdown/vimwiki/norg/text buffers | Show image under cursor, Gallery, Next/Prev image, Paste from clipboard, Screenshot+insert — already has a `<2-LeftMouse>` hover binding, so mouse interaction is a natural extension, not a new idiom |
| **dap.nvim** | B | any buffer while debugging is active | Toggle breakpoint, Conditional breakpoint…, Log point…, Continue/Step Over/Into/Out, Evaluate expression, Toggle DAP UI — VS-Code-style gutter/line right-click precedent |
| **fileops.nvim** | B | any buffer (acts on "this open file") | Rename file…, Duplicate file…, Delete file, Copy path, Show file info, Next/Prev file in dir — direct analogue of filetree.nvim's own menu, scoped to the active buffer instead of a tree node |
| **github_stats.nvim** | A | its own dashboard buffer | Cycle sort, Cycle time range, Custom range…, Force refresh, Export… |
| **documentation.nvim** | A | its own `:DocBrowse` buffer | Open source at line, Send to quickfix, Blast radius → quickfix, Pin/unpin entry, Save/Load trail, Fuzzy search |
| **spotlight.nvim** | B | any buffer | Spotlight this occurrence, Spotlight every occurrence, Spotlight selection, Send matches to quickfix, Clear all |
| **color_my_ascii.nvim** | B | markdown buffers, when cursor is inside an ASCII fence | Toggle highlighting, Switch color scheme, Yank fence, Open fence in split, Format/Align fence, Wrap/Unwrap fence |

### MAYBE — plausible but lower value
| Plugin | Pattern | Context | Why only maybe |
|---|---|---|---|
| language.nvim | B | any buffer / own float | infrequent use; existing keymaps already fast |
| mdview.nvim | B | markdown buffers | ~30 subcommands total, only start/stop/toggle/theme/cursor are menu-shaped |
| migrate.nvim | B | any buffer | keymaps are opt-in/disabled by default already — author doesn't treat this as high-frequency |
| recommender.nvim | B | lua/js/ts/python buffers | the float it opens is a richer surface than the menu would add |
| replacer.nvim | B | any buffer + own picker | only "replace/surround word or selection" compresses into a menu item |
| reposcope.nvim | A | its own prompt/list windows | already has a `?` cheatsheet; modest value-add |
| runtime-analysis.nvim | B | `.http`-style request/response buffers | plugin explicitly documents "zero keymaps by design" — would be a deliberate exception |
| buffer-ctx.nvim | B | any buffer | competes with an already fast single-key command surface |
| debugging.nvim | A/B mixed | its own report/display buffers | curated subset only; full `:Debug` surface too broad |
| emojis.nvim | B | any buffer | most of the surface is scope-flag driven, doesn't map to discrete entries |
| gopath.nvim | B | any buffer | mostly duplicates the one keymap the plugin already optimizes for |
| insights.nvim | B | any buffer + own float | most of `:Insights` is project-batch tooling, not buffer-local |

### NO
| Plugin | Why not |
|---|---|
| pickers.nvim | it *is* a picker/menu launcher already — a context menu on top would be redundant |
| cmdlog.nvim | the Telescope/fzf picker window is already the interaction surface |
| sessions.nvim | pure global/background facility, nothing buffer-local to anchor a right-click to |
| lib.nvim | pure shared library, no interactive surface of its own |

### Separate track (not this feature)
**pdfport.nvim** already ships `lua/pdfport/integrations/{neotree,netrw,nvim_tree,oil}.lua` — real, working native command/keymap merging into those tree plugins' own APIs, gated on `is_pdf(path)`. That's a different, already-solved mechanism from `nvzone/menu` and doesn't need anything from this doc; flagging only so it isn't duplicated by mistake if filetree.nvim's own menu is ever extended to gate entries by file extension.

---

## 4. Suggested rollout order

1. Fix markdown.nvim's dispatcher entry to use `submenu()` instead of flat
   `items()` (five-line change, makes the fly-out shape consistent).
2. **sandbox.nvim** (Pattern A) — closest existing match to filetree.nvim,
   `list_actions.lua` already has the dispatcher shape.
3. **cascade.nvim** (Pattern B) — pairs naturally with the markdown.nvim
   submenu already wired up, same buffers.
4. **open.nvim** and **fileops.nvim** (Pattern B, global) — highest everyday
   utility, both already resolve "the thing under the cursor" internally.
5. Everything else in the YES table, then MAYBE only on request.

## 5. Open questions for you

- Single "  My Plugins ▸" wrapper containing every Pattern-B submenu, vs.
  each plugin as its own top-level fly-out entry (current markdown.nvim
  style, matches screenshot 3's flat "Lsp Actions ▸" placement)? Wrapper
  keeps the top-level menu shorter as more plugins are added; flat is less
  indirection for the 2–3 that exist today.
- lsp.nvim's candidate entries overlap with `config/menu/custom_menu`'s
  existing "Lsp Actions" section (built from `menus.lsp`) — confirm whether
  that section should be replaced by lsp.nvim's own `integrations/menu.lua`
  (single source of truth) or left as-is and lsp.nvim skipped.
