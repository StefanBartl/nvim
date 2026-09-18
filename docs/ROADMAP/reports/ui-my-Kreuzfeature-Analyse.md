# `ui.nvim` + `my.nvim` — cross-feature check against the sibling plugins

**Date:** 2026-09-17
**Scope:** one pass for both plugins together, as both roadmaps ask for
(`my.nvim/ROADMAP/ROADMAP.md` → "Cross-plugin checks" → "Cross-feature check
against sibling plugins"; `ui.nvim/NOTES.md` → "Offene Punkte (Backlog)" → 3).

**Question:** is there overlap, or usefully shareable functionality, between
`ui.nvim`/`my.nvim` and the other ~30 personal plugins under `$REPOS_DIR/repos`?

**The yardstick** is the division of labour both roadmaps state as the scope
boundary: **`my.nvim` paints INSIDE the window** (cursorline, mode tinting,
indent guides, breadcrumb content), **`ui.nvim` is the FRAME** (statusline,
tabline, theme). Every overlap finding below is measured against that line.

---

## Table of content

  - [0. Status — the S-tier is done, 2026-09-17](#0-status--the-s-tier-is-done-2026-09-17)
  - [1. Method, and what this report is not](#1-method-and-what-this-report-is-not)
  - [2. The numbers](#2-the-numbers)
  - [3. The central observation](#3-the-central-observation)
  - [4. Tier A — the same code exists twice, both copies live](#4-tier-a--the-same-code-exists-twice-both-copies-live)
    - [A1 · `lib.nvim.ui.kit` ↔ `ui.kit` — duplicated on purpose, diverging by accident — resolved 2026-09-17](#a1--libnvimuikit--uikit--duplicated-on-purpose-diverging-by-accident--resolved-2026-09-17)
    - [A2 · `lib.nvim.contextmenu` ↔ `ui.contextmenu` — and ui.nvim uses the wrong one](#a2--libnvimcontextmenu--uicontextmenu--and-uinvim-uses-the-wrong-one)
  - [5. Tier B — the same feature built twice, across the ui/my boundary](#5-tier-b--the-same-feature-built-twice-across-the-uimy-boundary)
    - [B1 · Symbol breadcrumbs exist in both plugins; my.nvim's LSP half is dead](#b1--symbol-breadcrumbs-exist-in-both-plugins-mynvims-lsp-half-is-dead)
    - [B2 · Two mode classifiers that disagree](#b2--two-mode-classifiers-that-disagree)
  - [6. Tier C — a shareable primitive that only one side has](#6-tier-c--a-shareable-primitive-that-only-one-side-has)
    - [C1 · Nobody owns "keep these highlight groups defined"](#c1--nobody-owns-keep-these-highlight-groups-defined)
    - [C2 · `winhighlight` merging: my.nvim has the safe one, four others hand-roll](#c2--winhighlight-merging-mynvim-has-the-safe-one-four-others-hand-roll)
    - [C3 · `vim.wo.winbar` ownership has one adopter and two non-adopters](#c3--vimwowinbar-ownership-has-one-adopter-and-two-non-adopters)
    - [C4 · Soft-require centralization: my.nvim did it, ui.nvim did not](#c4--soft-require-centralization-mynvim-did-it-uinvim-did-not)
    - [C5 · Nerd-font glyph probing — three approaches, and the library one is unused](#c5--nerd-font-glyph-probing--three-approaches-and-the-library-one-is-unused)
    - [C6 · `vim.on_key` capture](#c6--vimon_key-capture)
  - [7. Tier D — defects this check turned up at the seams](#7-tier-d--defects-this-check-turned-up-at-the-seams)
    - [D1 · `move_buffer_to_tab` leaves a ghost chip in the source tab](#d1--move_buffer_to_tab-leaves-a-ghost-chip-in-the-source-tab)
    - [D2 · `my.ui.line_numbers` uses a filesystem ignore list as a filetype list](#d2--myuiline_numbers-uses-a-filesystem-ignore-list-as-a-filetype-list)
    - [D3 · `:checkhealth ui` hard-requires a module ui.nvim no longer uses](#d3--checkhealth-ui-hard-requires-a-module-uinvim-no-longer-uses)
    - [D4 · Diagnostic virtual-text background is restored by any `:colorscheme`](#d4--diagnostic-virtual-text-background-is-restored-by-any-colorscheme)
    - [D5 · `github_stats_badge`: German text and an unguarded emoji — widened, 2026-09-17](#d5--github_stats_badge-german-text-and-an-unguarded-emoji--widened-2026-09-17)
  - [8. Tier E — asymmetry in who owns a sibling's statusline component](#8-tier-e--asymmetry-in-who-owns-a-siblings-statusline-component)
  - [9. Checked, and there is no overlap](#9-checked-and-there-is-no-overlap)
  - [10. Findings inside my.nvim's own scope boundary](#10-findings-inside-mynvims-own-scope-boundary)
  - [11. Suggested order](#11-suggested-order)

---

## 0. Status — the S-tier is done, 2026-09-17

Everything the suggested order below marks **S** has been implemented and
pushed. What changed, and where:

| Finding | Where | Commit |
|---|---|---|
| A2 `git_clickable` on the wrong contextmenu | ui.nvim | `d039075` |
| C4 `ui.util.soft_require` + health section | ui.nvim | `d039075` |
| C5 glyph probes unified on `nerd_font.glyph` | ui.nvim | `d039075` |
| D1 ghost tabline chip after move-to-tab | ui.nvim | `d039075` |
| D3 stale `lib.nvim.ui.kit.select` health entry | ui.nvim | `d039075` |
| D4 diagnostic backgrounds restored by `:colorscheme` | ui.nvim | `d039075` |
| D5 German UI surface + unguarded emoji | ui.nvim | `d039075` |
| **`nvim-treesitter.ts_utils` rot** (new, see below) | ui.nvim | `d039075` |
| B2 disagreeing mode classifiers | my.nvim | `8388b57` |
| D2 filesystem ignore list used as a filetype list | my.nvim | `8388b57` |
| F3 `indent_per_ft` unconfigurable, forced `expandtab` | my.nvim | `8388b57` |
| B1 (non-breaking half) dead-provider health probe | my.nvim | `46df434` |
| C3 winbar ownership | filetree.nvim | `4c8cd88` |
| E "Around it" cross-references | 5 sibling READMEs | — |

**The M tier followed, 2026-09-17.**

| Finding | Where | Commit |
|---|---|---|
| C1 `lib.nvim.ui.hl.persist` | lib.nvim | `24b2985` |
| C2 `lib.nvim.ui.winhighlight` | lib.nvim | `24b2985` |
| C1 adopted (8 sites) | ui.nvim | `e19a3a5` |
| C1 + C2 adopted | my.nvim | `9308dca` |
| C2 adopted | filetree.nvim `fc3cb0b`, hover.nvim `e94261e`, reposcope.nvim `c31f335` | |
| C6 `getcharstr` → `vim.on_key` | debugging.nvim | `42a909a` |
| B1 symbol context moved | my.nvim `8066777`, ui.nvim `ef78f27` | |
| E four components moved | recommender `81570db`, github_stats `f01dd85`, runtime-analysis `3c6e6bd`, casedesk `c80dd80`, ui.nvim `9afcc07` | |
| A1 kit fixes ported + drift guard | lib.nvim `679e64b`/`92eb7d1`, ui.nvim `3c2eac2`/`bfd12e7` | |

**F1 and F2, decided and built, 2026-09-18.**

| Finding | Where | Commit |
|---|---|---|
| F1 diffopt profiles moved to their consumer | diff.nvim `03b6359`, my.nvim `1c147de` | |
| F2 `gh` gitsigns hunk peek moved to diff.nvim | diff.nvim `03b6359`, my.nvim `1c147de` | |

**A1 was the last one, and this report had it wrong.** It said lib.nvim's
copy "was never removed", implying an oversight. `PLAN-ui-kit-migration.md`
step 6 shows the opposite: *"Keine Löschung nötig … bleibt unangetastet im
Baum liegen … bekommt nur keine neuen Features mehr."* Keeping both copies
was decided deliberately, because eleven of lib.nvim's own call sites use
the kit and lib.nvim cannot require ui.nvim without inverting the fleet's
dependency direction. That decision stands and was not reopened.

The real defect was the half of the deal nothing enforced. "No new
features" had become "keeps known bugs": measured across all 21 files the
copies differed in **53 lines**, of which three were defects fixed only in
ui.nvim — a `WinClosed` augroup leaked per surface, a picker debounce timer
that outlived its picker, and a submenu mis-anchored near the bottom of the
screen — plus a security note saying the theme-preview buffer is executed
as Lua on every edit. All ported. The remaining differences were cosmetic
and were aligned too, so the next real one stands out instead of hiding in
style noise.

`contextmenu` was measured the same way and needs nothing: its 36 differing
lines are **all additions** (`set_enabled`/`is_enabled`), zero changed —
precisely what the freeze is supposed to look like.

Nothing compared the copies, which is why it went unnoticed for weeks.
`ui.nvim/TESTS/kit_drift_spec.lua` does now, in CI, which already checks
lib.nvim out at `ci-verified`. Two rules, because the two cases differ:
strict equality for the kit, and for `contextmenu` the weaker "lib.nvim has
no line ui.nvim has since corrected", which tolerates a deliberate feature
gap while still catching a one-sided fix. Both were verified to fail, and
to name the file, when drift is injected.

Byte-identity is not achievable and is not the goal: undoing the rename
lengthens `ui.kit.sync` to `lib.nvim.ui.kit.sync`, pushing one `error()`
past the shared 100-column budget so stylua wraps it on one side only. The
guard compares code, not formatting.

**B1 was left to judgement and decided for `my.nvim`.** Three precedents
point the same way. The fleet already resolves a shared surface by asking
*whose concern is this* (`vim.diagnostic.config()` → lsp.nvim owns, my.nvim
contributes) and *who produces versus who places* (`vim.wo.winbar` →
my.nvim produces, ui.nvim writes). Symbol context is content, and both
roadmaps say content is my.nvim's. `lsp.nvim` was checked as a third
candidate and has no symbol engine at all — only keymaps bound to
`vim.lsp.buf.document_symbol` — so building one there would have been a
larger move than the finding scoped. my.nvim also already had the whole
composition layer (provider ordering, separators, length limits, skip
rules, a debug command) that ui.nvim lacked. The result is one direction
of flow on both shared surfaces: my.nvim produces, ui.nvim places.

**Three more corrections, all found by implementing:**

- **C1's numbers were wrong.** "8 plugins, 21 call sites" counted two
  entries that are not registrations at all: `debugging.nvim`'s
  `autocmds/sources.lua` and `lib.nvim`'s `autocmd/docs.lua` both merely
  *list* `"ColorScheme"` as an event name. The real figure is **19 sites in
  7 plugins**, and that is what the module's own documentation says.
- **C6's M half was unnecessary and has been dropped.** The finding
  proposed a `lib.nvim` registry so several consumers could share one
  `vim.on_key` hook. Neovim's own namespace argument already does exactly
  that — verified against a live session: two callbacks under different
  namespaces both fire, and `vim.on_key(nil, ns)` detaches one without
  disturbing the other. Both `ui.nvim` modules were already using it
  correctly. Only the S half was real, and `debugging.nvim`'s keylogger is
  fixed.
- **E was wrong about `filetree.nvim`.** See that section.

**Two defects surfaced while moving code**, neither of which the report had
seen:

- `locate_in_hierarchical` recorded the breadcrumb chain **only at a leaf**,
  so a symbol that matched while none of its children did — the cursor on a
  `class` or `def` line itself — produced no breadcrumb at all. Found by the
  first test ever written against that path, which could not have existed
  before: the provider it belonged to read a buffer variable, so a test
  would only have asserted that the test set a variable.
- `my.nvim`'s `winhighlight` validated group names as `^[%w_]+$`, silently
  dropping every mapping to a Tree-sitter capture (`Normal:@comment` parsed
  to nothing). Neovim accepts `@`, `.` and `-` — measured against a real
  window — and the shared version does too.

**One finding the fixing pass turned up that this report had missed.**
`ui.nvim`'s statusline Tree-sitter breadcrumb fallback resolved its node
through `nvim-treesitter.ts_utils`. nvim-treesitter deleted that module
upstream, so the `pcall` answered "absent" on every call and all 191 lines
of `modules/lsp/symbols/treesitter.lua` returned nil forever — the fallback
for every buffer with no LSP attached had been doing nothing, silently.
Identical defect, and identical fix, to `my.nvim@c622695` earlier the same
day; found only because C4's audit made the plugin's soft-dependency probes
a list you could read. That is now the stated reason the
`ui.util.soft_require` module and its health section exist.

**Two findings this report got wrong, corrected below.** [C5](#c5--nerd-font-glyph-probing--three-approaches-and-the-library-one-is-unused)
claimed `my.nvim` used `lib.nvim.ui.nerd_font`; it does not, and neither did
`ui.nvim`. [D5](#d5--github_stats_badge-german-text-and-an-unguarded-emoji--widened-2026-09-17)
called one German string an outlier when the whole `:UI` surface was German
by intent. Both sections now say what is actually there.

**Not fixed, and why.** `lsp.nvim`'s winbar rewriter — the second half of
[C3](#c3--vimwowinbar-ownership-has-one-adopter-and-two-non-adopters) — turns
out to need no change at all; see that section. `F1` and `F2` were decisions
about where a feature belongs rather than defects — both decided 2026-09-18
(move to diff.nvim, see [§10](#10-findings-inside-mynvims-own-scope-boundary))
and built the same session. Everything at **M**, **L** and **XL** beyond that
is untouched, including the kit deduplication
([A1](#a1--libnvimuikit--uikit--duplicated-on-purpose-diverging-by-accident--resolved-2026-09-17)),
which is the one that needs a decision rather than typing.

## 1. Method, and what this report is not

The unit of analysis is a **feature family**, not a plugin. The pass ran in
four sweeps over all 38 `*.nvim` repositories under `$REPOS_DIR/repos`
(`.claude/worktrees/**` and `ARCHIV_NICHT_BEARBEITEN/**` excluded throughout):

1. **A module-path index** of all 2,898 non-worktree Lua modules, searched for
   the concept vocabulary of both plugins (`statusline`, `winbar`, `tabline`,
   `breadcrumb`, `cursorline`, `indent`, `theme`, `palette`, `transparen`,
   `highlight`, `colorscheme`, `screenkey`, `keylog`).
2. **Symbol sweeps** for the shared surfaces both plugins write to, because a
   shared *surface* is where an overlap actually hurts: `vim.wo.winbar`,
   `winhighlight`, `"ColorScheme"`, `vim.t.bufs`, `diffopt`,
   `vim.b.lsp_current_function`, `vim.on_key`, `devicons`, `nerd_font`.
3. **Require-graph checks** in both directions — who requires `ui.*`/`my.*`,
   and what `ui.*`/`my.*` require from siblings.
4. **Byte-level diffs** where two modules looked like copies.

**Every finding below names the file that proves it.** That is deliberate, and
it is the lesson of the 2026-09-17 analysis in this same directory, which
found 15 roadmap points listed as open that were long since built: a feature's
*description* is not evidence. Where a claim rests on absence (nothing sets
this variable, no plugin does this), the sweep that produced the absence is
named so it can be re-run.

Every citation and every count here was **re-verified against the working
tree after the report was first written** — 63 file:line references, of which
6 had drifted by a line or two and one (`ctx/init.lua`'s provider chain) was
wrong outright. That mattered more than usual: two commits landed in
`my.nvim` while this pass was running — `fdeacd4` (20:19, retires the
`container` breadcrumb provider) and `c622695` (20:30, gets the Tree-sitter
node from core after `nvim-treesitter` deleted the `ts_utils` module the
code required) — and both touch the modules [B1](#b1--symbol-breadcrumbs-exist-in-both-plugins-mynvims-lsp-half-is-dead)
is about. B1 survives both, and `c622695`'s own commit message
("with `lsp_func` already dead") reaches the same conclusion independently.
Counts are as of 2026-09-17 and this fleet moves daily; re-run the sweeps in
section 1 rather than trusting the figures a month from now.

**What this report did NOT check:**

- **Behaviour at runtime.** Nothing here was verified in a live Neovim. The
  findings are source-level; the ones that predict a visible symptom say so
  and can be falsified in one session.
- **The two large siblings feature-by-feature.** `filetree.nvim` (28,553 LOC)
  and `casedesk.nvim` (12,895 LOC) were searched by symbol, not read. An
  overlap buried in them with no shared surface and no shared vocabulary would
  not have been found.
- **`documentation.nvim`** (53,951 LOC) beyond its `ui.*` call sites. It is a
  consumer of `ui.kit`/`ui.contextmenu`, not a competitor for any surface.
- **The host config** (`lua/config/**`) except for the single absence check in
  B1. The sibling-plugin question is about the plugins.
- **External plugins.** That is the other report's subject
  ([Externe-Plugins-Nachbau-Analyse.md](./Externe-Plugins-Nachbau-Analyse.md)).
- **Test suites.** `TESTS/**` was excluded from every count, and the migration
  comments found there were read as evidence of history, not as code.

**Effort scale** (one session ≈ a focused half day):

| | |
|---|---|
| **S** | under one session — wiring, not engineering |
| **M** | 1–2 sessions |
| **L** | 3–5 sessions |
| **XL** | more; listed only to record the verdict |

---

## 2. The numbers

| | |
|---|---|
| Plugin repositories examined | **38** (the 36 siblings, plus the two under review) |
| Non-worktree Lua modules indexed | **2,898** |
| `ui.nvim` | 93 files, **14,787 LOC** |
| `my.nvim` | 71 files, **8,481 LOC** |
| Lines found duplicated verbatim-modulo-paths | **~5,100** (Tier A) |
| Plugins hand-rolling a `ColorScheme` re-registration | **7**, across 19 call sites |
| Plugins writing `vim.wo.winbar` | **3** producers; **1** uses `ui.winbar` |
| Siblings wired into `ui.nvim`'s statusline | **7** |
| …of which ship their own component | **2** |
| Sibling READMEs carrying the "Around it" convention | **22** |
| …that name `my.nvim` | **1** |
| …that name `ui.nvim` | **3** |

---

## 3. The central observation

**The two plugins do not overlap each other much, and they barely overlap the
siblings at all — but they sit on four surfaces that have no owner, and that
is where every real finding is.**

`vim.wo.winbar`, `winhighlight`, the highlight-group table after a
`:colorscheme`, and `vim.t.bufs` are all global or window-global, all written
by more than one plugin in this fleet, and none of them has an arbiter the way
`vim.diagnostic.config()` now does (`lsp.nvim` owns the call, `my.nvim`
contributes — `my.nvim/lua/my/diagnostics.lua:1-14`, resolved 2026-09-08). Two
plugins can each be correct in isolation and still produce a wrong screen.

The second observation is a mirror of the first: **`ui.nvim` carries the
presentation logic of five siblings that do not know it exists.** Two of the
seven siblings on the statusline ship their own component and `ui.nvim` reduces
to a 24-line adapter. For the other five, 760 lines of their logic live in
`ui.nvim` and reach into their internals. The convention exists; it is just not
applied evenly.

---

## 4. Tier A — the same code exists twice, both copies live

### A1 · `lib.nvim.ui.kit` ↔ `ui.kit` — duplicated on purpose, diverging by accident — resolved 2026-09-17

The 2026-09 migration moved the UI kit from `lib.nvim` into `ui.nvim`.

**This section originally said the source copy "was never removed", as
though it had been forgotten. That was wrong**, and checking the migration
plan rather than the tree would have caught it:
`PLAN-ui-kit-migration.md` step 6 says *"Keine Löschung nötig … bleibt
unangetastet im Baum liegen … bekommt nur keine neuen Features mehr."*
Both copies exist by decision. The identical 21-file layout:

| | `lib.nvim/lua/lib/nvim/ui/kit/` | `ui.nvim/lua/ui/kit/` |
|---|---|---|
| Files | 21 (20 + `@types`) | 21 (20 + `@types`) |
| LOC | 4,793 + 294 | 4,812 + 294 |

A file-by-file diff shows most of the delta is the rename
(`lib.nvim.ui.kit.*` → `ui.kit.*`, `Lib.UI.Kit.*` → `Ui.Kit.*`). But not all
of it — the copies have already started to drift:

- `ui.nvim/lua/ui/kit/surface.lua:67-73` carries an augroup-leak fix
  (`nvim_del_augroup_by_id` on close, with the comment that window ids are
  never reused so the group would otherwise accumulate per surface). The
  `lib.nvim` copy at `lib.nvim/lua/lib/nvim/ui/kit/surface.lua` does not have it.
- `ui.nvim/lua/ui/kit/picker.lua` is 187 lines against `lib.nvim`'s 182;
  `chooser.lua` 853 against 847; `sync.lua` 74 against 77.

**Why the `lib.nvim` copy cannot simply be deleted:** it has seven live
internal consumers, which is not what the migration comments in the test
harnesses suggest. `lib.nvim/lua/lib/nvim/bindings/audit.lua:712`,
`bindings/keymap/init.lua:145`, `deps/view.lua:324`, `dev/duplicates.lua:215`,
`harvest/sink.lua:105`, `progress/styles/kit.lua`, and
`contextmenu/init.lua:287` all require it. `lib.nvim` cannot depend on
`ui.nvim` — that inverts the dependency direction of the whole fleet.

Outside `lib.nvim` the migration *is* complete: a sweep for
`lib\.nvim\.ui\.kit` across all repositories returns only test-harness
comments and one stale health check (see [D3](#d3--checkhealth-ui-hard-requires-a-module-uinvim-no-longer-uses)).

The real decision is not "delete the duplicate" but **which of `lib.nvim`'s
seven consumers actually need a themed float**, and whether the kit belongs in
`lib.nvim` with `ui.nvim` re-exporting it, or in `ui.nvim` with `lib.nvim`'s
seven sites degrading to plain `vim.ui.*`/notify when it is absent (five of
them already `pcall` it, so they are written for its absence).

**What was actually wrong, and what was done.** Not the duplication — that
is decided — but the unenforced half of it. "No new features" had become
"keeps known bugs". Across all 21 files the copies differed in 53 lines:
three real defects fixed only in `ui.nvim` (the surface augroup leak above,
a picker debounce timer outliving its picker, a submenu mis-anchored near
the bottom of the screen), a security note on the theme-preview buffer, and
the rest cosmetic. All of it is now aligned, so the next genuine difference
is visible rather than buried in style noise.

`contextmenu` was measured the same way and needed nothing: 36 differing
lines, **all additions** (`set_enabled`/`is_enabled`), zero changed.

`ui.nvim/TESTS/kit_drift_spec.lua` compares both in CI from now on —
strict equality for the kit, containment for `contextmenu` — and was
verified to fail, naming the file, when drift is injected.

**Effort: L as scoped, but the scope was wrong.** The expensive part it
imagined — deciding which copy survives and migrating seven call sites —
was already decided in 2026-09 and did not need doing. The part that did
need doing was an afternoon.

### A2 · `lib.nvim.contextmenu` ↔ `ui.contextmenu` — and ui.nvim uses the wrong one

Same shape, smaller: `lib.nvim/lua/lib/nvim/contextmenu/init.lua` (331 lines)
and `ui.nvim/lua/ui/contextmenu/init.lua` (364 lines). The 33-line delta is
real functionality — `ui.contextmenu` gained `set_enabled()` and the
`ui.setup({ menu = false })` gate that renders nothing while keeping the item
builders available.

Six siblings have migrated to `ui.contextmenu`: `cascade.nvim`,
`color_my_ascii.nvim`, `dap.nvim`, `documentation.nvim`, `fileops.nvim`,
`filetree.nvim`.

**`ui.nvim` itself has not.** `ui.nvim/lua/ui/statusline/modules/git_clickable/init.lua:66`
still does `pcall(require, "lib.nvim.contextmenu")`, with a docstring claiming
it is "the same builder API every other menu in this ecosystem uses" — which
was true when written and is now false.

This is not cosmetic. That call site bypasses `ui.contextmenu`'s own
`set_enabled` gate, so **a host that sets `ui.setup({ menu = false })` still
gets a context menu** when it right-clicks the git segment in the statusline.

**Effort: S** for the call site (a one-line require change plus the docstring).
The dedup itself rides along with A1.

---

## 5. Tier B — the same feature built twice, across the ui/my boundary

### B1 · Symbol breadcrumbs exist in both plugins; my.nvim's LSP half is dead

This is the one place where the two plugins genuinely build the same thing,
and it sits exactly on the declared scope boundary — breadcrumb *content* is
`my.nvim`'s by the roadmaps' own division of labour.

| | `my.nvim` | `ui.nvim` |
|---|---|---|
| Where | `lua/my/hl_config/breadcrumbs/**` | `lua/ui/statusline/modules/lsp/**` |
| LOC | 2,154 (whole subtree); 1,034 in the pipeline files themselves | 1,224 (whole subtree); 737 in the three files below |
| Shape | provider pipeline: `lsp_func → ts_symbol → lang_extra → word`, first non-nil wins (`ctx/init.lua:10-14`; `container` is a provider but not a link in the chain — it is reachable only from the debug report) | LSP `documentSymbol`, async + debounced + cached, with a treesitter fallback |
| Treesitter node whitelist | `ctx/providers/ts_symbol.lua:13-25`, 11 types | `symbols/treesitter.lua:15-50`, the same 11 plus 17 more — 28 in total |
| LSP path | reads `vim.b.lsp_current_function` | `symbols/document_symbols.lua`, 451 lines, full `LspKind` enum, own debounce |

`ui.nvim`'s own module docstring calls its output "LSP-first breadcrumbs …
with Treesitter fallback" (`modules/lsp/init.lua:2`). That is breadcrumb
content produced inside the frame plugin.

**And the duplication is not symmetric — my.nvim's half of it does not work.**
`my.nvim`'s highest-priority provider is `lsp_func` (priority 100,
`ctx/providers/lsp_func.lua:5`), enabled by default
(`config/data/highlight.lua:63`: `prefer_lsp_function = true`). Its entire
implementation is `local s = vim.b.lsp_current_function`
(`ctx/providers/lsp_func.lua:25`).

A sweep for `lsp_current_function` across all 38 repositories **and** the host
config at `vim.fn.stdpath('config')` returns five hits, all of them inside
`my.nvim` itself, all of them readers. **Nothing in this setup ever sets that
variable.** The provider can never fire; `my.nvim`'s breadcrumbs are
treesitter-only in practice, while the sibling next to it holds a complete,
debounced, cached LSP implementation of the same thing.

The clean resolution follows the pattern this fleet already uses twice
(`vim.diagnostic.config()`, and `ui.winbar` itself): the symbol-context
producer becomes one module with one owner, and the other plugin consumes it.
Given the scope boundary, content belongs in `my.nvim` and `ui.nvim`'s
statusline asks for a string — which is the exact inverse of the current
`ui.winbar` arrangement and would make the pair symmetric.

**Effort: M.** The code both sides need already exists; this is a move plus an
API, not new engineering. Add **S** if the interim fix is preferred: drop
`prefer_lsp_function` and its provider rather than leave a default-on,
never-firing stage in a documented pipeline.

### B2 · Two mode classifiers that disagree

Both plugins map the current Vim mode to a highlight group, independently:

- `ui.nvim/lua/ui/statusline/utils/primitives.lua:33-76` — 37 raw mode strings
  into 9 buckets (`Normal`, `NTerminal`, `Visual`, `Insert`, `Terminal`,
  `Replace`, …), consumed by
  `modules/highlighting/init.lua:49` as `St_<Name>Mode`.
- `my.nvim/lua/my/hl_config/features/cursorline.lua:103-120` — 8 keys into 4
  buckets (`CursorLineN/V/I/R`), reached with a mode string truncated to its
  first character (`features/mode_tint.lua:22`, `:30`, `:36`).

They disagree wherever the first character is not the whole story. In
terminal-normal mode (`nt`) `ui.nvim`'s statusline chip says **NTERMINAL** in
its own colour, while `my.nvim` sees `n` and tints the cursorline
**CursorLineN**. Terminal-insert (`t`) is not in `my.nvim`'s map at all and
falls through to `CursorLineN`, against the statusline's **TERMINAL**. Same
for `no`, `niI`, `niR`, `niV`.

`enable_insert_submode_colors` does not change this — it is only the on/off
switch for the four-bucket map (`hl_config/core/state.lua:85`).

The frame and the inside of the window telling the user two different things
about the mode is the most literal possible violation of the scope boundary
these roadmaps set up. The map belongs to whichever plugin loads first; the
other reads it.

**Effort: S.**

---

## 6. Tier C — a shareable primitive that only one side has

### C1 · Nobody owns "keep these highlight groups defined"

A `:colorscheme` clears user-defined highlight groups. **Seven plugins** each
hand-roll their own `ColorScheme` autocmd to put theirs back, across 19 call
sites: `ui.nvim` (7), `my.nvim` (3), `filetree.nvim` (2), `markdown.nvim` (2),
`lib.nvim` (1, in `ui/kit/theme.lua`), `spotlight.nvim`, `reposcope.nvim`.

*(Corrected while implementing: the original said 8 plugins and 21 sites. It
had counted `debugging.nvim`'s `autocmds/sources.lua` and `lib.nvim`'s
`autocmd/docs.lua`, which merely list `"ColorScheme"` as an event name.)*

`lib.nvim`'s highlight helper offers exactly two functions —
`lib.nvim/lua/lib/nvim/ui/hl/init.lua:13` `namespace()` and `:23` `set()`.
Neither knows anything about persistence.

The implementations are not equivalent, which is the point. `spotlight.nvim`
re-applies on `ColorScheme` **and** on `OptionSet background`, because
switching background selects its other palette
(`spotlight.nvim/lua/spotlight/core/palette.lua:10-14`). `my.nvim`'s
`cword_occurrences` highlight cache (`HLCACHE`,
`hl_config/cword_occurrences/init.lua:26`) handles neither event by itself.
And one module handles nothing at all — see [D4](#d4--diagnostic-virtual-text-background-is-restored-by-any-colorscheme).

A `lib.nvim.ui.hl.persist(defs)` that registers the groups, re-applies them on
both events and returns a detach handle would replace 21 hand-written blocks
with one tested one, and would make "did you remember `OptionSet background`?"
a property of the library rather than of each author's memory.

**Effort: M** for the primitive with tests; **S** per adopting call site.

### C2 · `winhighlight` merging: my.nvim has the safe one, four others hand-roll

`my.nvim/lua/my/hl_config/utils/winhighlight.lua` (119 lines) is a validated,
memoized `winhighlight` parser whose stated purpose is preventing `E5248`
(invalid character in group name) — it splits on commas, trims, and rejects
anything outside `[%w_]` on both sides of the colon.

Nobody outside `my.nvim` can reach it, and four other places do the job by
hand:

| Site | What it does |
|---|---|
| `filetree.nvim/lua/filetree/features/ui/cursor_hide/init.lua:62-79` | its own merge **and** its own strip-on-detach, with a comment explaining why merging matters |
| `ui.nvim/lua/ui/kit/{picker,chooser,compare}.lua` (3 sites) | read-then-append, no validation |
| `hover.nvim/lua/hover/float.lua:440` | `vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"` — **assigns**, discarding anything already set |
| `reposcope.nvim/lua/reposcope/ui/background/background_window.lua:45` | same, `"Normal:ReposcopeBackground"` |

The last two are the failure mode the `my.nvim` module exists to prevent,
reached from a different plugin. They are on the plugins' own floats, so the
blast radius is small today — but "it is my window" is exactly the assumption
that broke when `ui.nvim`'s kit started theming other people's floats.

Promoting the module to `lib.nvim.ui.hl.winhighlight` is a lift-and-shift: it
depends only on `lib.lua.strings.core` and `lib.lua.memo`, both already in
`lib.nvim`.

**Effort: M.**

### C3 · `vim.wo.winbar` ownership has one adopter and two non-adopters

`ui.winbar` was created on 2026-09-12 precisely to give `vim.wo.winbar` the
owner it lacks, explicitly modelled on the `vim.diagnostic.config()`
resolution — its docstring says so (`ui.nvim/lua/ui/winbar/init.lua:1-16`).
`my.nvim` adopted it: `hl_config/breadcrumbs/winbar.lua:179` hands its line to
`ui.winbar.set()` when present and self-applies otherwise, and
`my.nvim/lua/my/health.lua:336` reports which of the two is happening.

Two other plugins write the same surface and do not participate:

- **`filetree.nvim/lua/filetree/features/ui/breadcrumbs/init.lua:107-116`** —
  `update_winbar()` loops over *every* non-tree, non-floating window in the
  tab and sets `winbar` on each, on every `CursorMoved` in the tree buffer.
  Its `mode` defaults to `"winbar"` (`:26`). With both plugins loaded, moving
  the cursor in the tree overwrites `my.nvim`'s breadcrumbs in every editor
  window — the exact collision `ui.winbar` was built to arbitrate, from the
  one direction it was not told about.
- **`lsp.nvim/lua/lsp/integrations/lspsaga.lua:138-154`** — reads the current
  `winbar`, splits it on lspsaga's separator and truncates. A rewriter
  rather than a producer.

  **Re-checked while fixing this, 2026-09-17: it needs no change, and the
  original wording here was too pessimistic.** It said the rewriter "will
  re-cut whatever is there, including a `my.nvim` line whose separator
  happens to match". It cannot: `winbar_shape()` builds the separator as
  `"%#SagaSep#" .. cfg.separator .. "%*"` (`lspsaga.lua:95`), carrying
  lspsaga's *own highlight group name*. Nothing else in the fleet emits
  `%#SagaSep#`, so any other producer's line splits into one part, hits the
  `#parts <= keep` guard at `:150`, and is returned untouched.

  Routing it through `ui.winbar.set()` would also be wrong on its own terms:
  it does not own the content, it trims lspsaga's, and `ui.winbar.set()`
  schedules — deferring an already-scheduled trim by another tick, for no
  gain. Left alone deliberately.

**Effort: S** per plugin to route through `ui.winbar` (soft-required, exactly
as `my.nvim` does it) — the module's whole API is one function.

### C4 · Soft-require centralization: my.nvim did it, ui.nvim did not

`my.nvim/lua/my/util/soft_require.lua` exists because of the `rules.nvim` pass
(`PRIN-07`): four scattered `pcall(require, …)` probes became one place that
decides what "soft dependency present" means.

`ui.nvim` has **37** hand-written `pcall(require` sites in `lua/` and no such
module. It has as many optional siblings as `my.nvim` does — more, given the
seven statusline integrations.

Two notes keep this honest. First, `my.nvim`'s own roadmap records a
deduplication claim that turned out to be wrong because it was taken from a
description rather than checked, so: `lib.nvim` **does** already have
`lib.nvim.require.safe(name)`
(`lib.nvim/lua/lib/nvim/require/init.lua:13-25`), and it is **not** the same
function — it returns `(ok, mod)` where `soft_require.try` returns `mod|nil`
and additionally requires `type(mod) == "table"`. Second, `lib.nvim.require`
has exactly two consumers fleet-wide (`documentation.nvim` and `lib.nvim`
itself), against 1,127 hand-rolled `pcall(require` sites across the fleet —
so this is a fleet-wide habit, not a `ui.nvim` failing, and only the
`ui.nvim` half of it is in scope here.

**Effort: S** to give `ui.nvim` the same one-module treatment `my.nvim` got.
The fleet-wide version is a separate, larger question and is not proposed here.

### C5 · Nerd-font glyph probing — three approaches, and the library one is unused

`lib.nvim/lua/lib/nvim/ui/nerd_font/init.lua:49` is `glyph(hex, fallback)` —
decode a codepoint, check it renders, fall back otherwise, with
`available()`, `chars()` and `sep()` beside it. Outside `lib.nvim` it has
exactly **one** real consumer fleet-wide:
`filetree.nvim/lua/filetree/integrations/menu.lua:19`.

Neither plugin under review uses it, and they do not agree with each other
either:

| | How it decides whether a glyph is usable |
|---|---|
| `lib.nvim.ui.nerd_font` | the primitive — 1 external consumer |
| `my.nvim` | reads `vim.g.have_nerd_font` directly (`hl_config/utils/separator.lua:40`) |
| `ui.nvim` | decodes and measures by hand: `hex_to_string(SEP_HEX)` then `SEP_GLYPH ~= "" and vim.fn.strdisplaywidth(SEP_GLYPH) == 1` (`modules/lsp/init.lua:56-58`) |
| `ui.nvim`, again | no check at all — `modules/github_stats_badge/init.lua:105`, see [D5](#d5--github_stats_badge-german-text-and-an-unguarded-emoji--widened-2026-09-17) |

The three are not equivalent: `vim.g.have_nerd_font` is a user assertion,
`strdisplaywidth` is a measurement, and `nerd_font.available()` combines
both. `ui.nvim` does reference the module — but only inside a docstring
example (`ui/contextmenu/init.lua:29`), not as a require, which is how this
was initially mis-read for both plugins.

**Effort: S** per call site.

### C6 · `vim.on_key` capture

Three modules in the fleet capture keystrokes:

- `ui.nvim/lua/ui/screenkey/init.lua` — `vim.on_key()` + `vim.fn.keytrans()`,
  hook registered only while enabled.
- `ui.nvim/lua/ui/statusline/modules/macro_counter/init.lua` — the same
  pattern, bracketed by `RecordingEnter`/`RecordingLeave`; screenkey's
  docstring explicitly cites it as the model.
- `debugging.nvim/lua/debugging/terminals/keylogger.lua:63-95` — a
  `vim.schedule`d recursion around **`vim.fn.getcharstr()`**, which blocks and
  *consumes* the key rather than observing it, plus a hand-written "did we
  leave the terminal buffer" guard to stop the chain dying silently.

`ui.nvim` has the right primitive twice over; `debugging.nvim` has the wrong
one. A `lib.nvim` keystroke-observer registry (one `on_key` hook, N
subscribers) would serve all three, and would also fix the case `on_key` has
that neither `ui.nvim` module handles: two consumers both registering.

**Effort: M** for the registry; **S** if only `debugging.nvim` is re-pointed
at `on_key`.

---

## 7. Tier D — defects this check turned up at the seams

These are not overlaps. They are bugs that only become visible when you look
at two plugins at once, which is what this pass was for.

### D1 · `move_buffer_to_tab` leaves a ghost chip in the source tab

`lib.nvim/lua/lib/nvim/buf_win_tab/move_buffer_to_tab/init.lua` moves the
current buffer into the next (or a new) tab. It has exactly **one** consumer
fleet-wide: `ui.nvim/lua/ui/bindings/keymaps/init.lua:23,136`, bound as "move
current buffer into a new tab".

`ui.nvim` also owns `vim.t.bufs`, the per-tab buffer list its tabline renders
(`ui/bindings/keymaps/tabufline/state.lua`). That list is maintained by
autocmds on `BufAdd`/`BufEnter`/`tabnew` (`:75`) and `BufDelete` (`:105`).

The helper never touches `vim.t.bufs`. The `BufEnter` in the destination tab
adds the buffer there — but nothing removes it from the source tab's list,
because the buffer is not deleted. **The moved buffer keeps a chip in the tab
it left**, until it is closed.

The helper is also a `lib.nvim` module with one consumer, which is itself the
finding: it either belongs in `ui.nvim` next to the state it must keep
consistent, or it must call into `ui.nvim`'s state module — and `lib.nvim`
cannot.

**Effort: S.**

### D2 · `my.ui.line_numbers` uses a filesystem ignore list as a filetype list

`my.nvim/lua/my/ui/line_numbers/init.lua:7-9`:

```lua
local ignore_lib = require("lib.nvim.fs.ignore.list")
local ignore_filetypes = ignore_lib.as_set()
```

`as_set()` returns the **basenames** set
(`lib.nvim/lua/lib/nvim/fs/ignore/list/init.lua:94-100`): `.git`, `.github`,
`node_modules`, `.venv`, `__pycache__`, `build`, `dist`, `target`, `bin`,
`obj`, `.vscode`, `package-lock.json`, … — 31 entries, **not one of
which is ever a `&filetype`**.

The whole seeded set is inert. Only the seven hardcoded additions on `:12-18`
(`qf`, `help`, `alpha`, `dashboard`, `trouble`, `neo-tree`, `neo-tree-popup`)
do anything, and the module's own `@brief` advertises a "centralized ignore
list" that is not the list it needed.

`my.nvim` already *has* the right thing: `my.hl_config.utils.skip.std_skip`,
the configurable filetype/name-pattern buffer skip used by nearly every hot
handler in `hl_config`. `line_numbers` does not use it, so the plugin carries
two skip mechanisms and this one uses a third, wrong list.

Two further side-effects of the same file, noted while reading it:
`vim.opt.number` / `vim.opt.relativenumber` are set at **module load**
(`:4-5`), before any config is consulted, and `_G.custom_line_numbers` is a
bare global (`:56`) because `statuscolumn` needs `v:lua`.

**Effort: S.**

### D3 · `:checkhealth ui` hard-requires a module ui.nvim no longer uses

`ui.nvim/lua/ui/health.lua:81` lists `"lib.nvim.ui.kit.select"` among the
`lib.nvim` modules whose absence is reported as a hard **error** ("all N
required lib.nvim modules resolve" otherwise).

`ui.nvim` does not use it. It uses its own:
`ui/bindings/usrcmds/themes/picker.lua:15` requires `ui.kit.select`;
`ui/contextmenu/init.lua:320` requires `ui.kit.menu`;
`ui/screenkey/init.lua:20` requires `ui.kit.surface`. The health list is a
leftover from before the migration.

Today it merely reports a dependency that is not one. The moment A1 is
resolved by removing `lib.nvim`'s copy, `:checkhealth ui` fails on a
perfectly healthy install.

**Effort: S** (delete one line).

### D4 · Diagnostic virtual-text background is restored by any `:colorscheme`

`ui.nvim/lua/ui/highlights/diagnostics.lua` clears the background on the four
`DiagnosticVirtualText*` groups. It is called once, from
`ui/config/init.lua:196`, at the end of config assembly — **not from a
`ColorScheme` autocmd**, and nothing else re-invokes it.

Every other highlight module in `ui.nvim` re-registers on `ColorScheme`
(`statusline/highlights.lua`, `tabline/highlights.lua`, `theme/transparency.lua`,
`kit/theme.lua`, `modules/file_icons/devicons.lua`,
`modules/filetree_cwd_mode`, `modules/formatters`). This one does not, so the
first `:colorscheme` — including the one `:UI toggle` and `:UI picker` fire —
brings the backgrounds back and nothing puts them away again.

This is [C1](#c1--nobody-owns-keep-these-highlight-groups-defined) with the
consequence attached, and the clearest argument for the primitive.

**Effort: S** standalone, or free as C1's first adopter.

### D5 · `github_stats_badge`: German text and an unguarded emoji — widened, 2026-09-17

`ui.nvim/lua/ui/statusline/modules/github_stats_badge/init.lua:105`:

```lua
return " \xF0\x9F\x91\x81 " .. count .. " diese Woche "
```

**This section originally claimed `diese Woche` was "the only German
user-facing string found in either plugin's Lua". That was wrong**, and only
true of the one file that had been read. A proper sweep of string literals
across both plugins found **28** German user-facing strings in `ui.nvim`,
plus the entire `:UI help` panel, which a literal-only sweep misses because
it is a `[[ ]]` block. `my.nvim` has none.

The fleet context, which the original also lacked:

| Plugin | German strings | Verdict |
|---|---|---|
| `ui.nvim` | 28 + the help panel | the whole `:UI` command surface |
| `casedesk.nvim` | 24 | domain content — German-language support cases |
| `cascade.nvim` | 3 | an explicit `cycle/packs/de.lua` language pack |
| `lsp.nvim`, `lib.nvim` | 1 each | incidental |

So `ui.nvim` was the outlier, but not in the way a single stray string
suggests: it was consistent, which makes it intent rather than an accident.
Two plugins have German *by design* and neither looks like `ui.nvim` —
casedesk's is data, cascade's is a named language pack.

**Resolved by the plugin's owner, 2026-09-17: English throughout**,
consistent with `ui.nvim`'s own README, `docs/` and vimdoc, and with every
sibling that is not German-by-design.

The second half stands as written, and got wider too. The icon was
`\xF0\x9F\x91\x81` — U+1F441 (👁) — emitted with no width or availability
check, and it was not alone: `✨` (U+2728), `🎨` (U+1F3A8) and
`⌨️` (U+2328 U+FE0F) appeared the same way across the `:UI` output.
Emoji are commonly East-Asian-Wide, so each rendered two cells and shifted
every segment after it. All of them now go through
`lib.nvim.ui.nerd_font.glyph`, which answers both questions — see
[C5](#c5--nerd-font-glyph-probing--three-approaches-and-the-library-one-is-unused).
Same `UI`-family finding the `rules.nvim` pass already fixed once in
`my.nvim`.

**Effort: S** as scoped; the widened version was closer to **M**.

---

## 8. Tier E — asymmetry in who owns a sibling's statusline component

Seven siblings appear in `ui.nvim`'s statusline. They are handled in two
completely different ways, and the split is not a design decision — it is
whichever plugin happened to ship a component.

**The good pattern**, where the sibling owns its own presentation and
`ui.nvim` is a thin adapter:

| Sibling | Sibling ships | `ui.nvim` module | LOC |
|---|---|---|---|
| `sandbox.nvim` | `lua/sandbox/statusline.lua` (130) + `docs/statusline.md` | `modules/sandbox_ambient` | **24** |
| `sessions.nvim` | `lua/sessions/statusline.lua` + `docs/statusline.md` | `modules/session_status` | **24** |

Both adapters are the same eight lines: read `package.loaded[...]` (not
`require`, so the statusline's first redraw does not defeat the sibling's lazy
trigger), call `status()`, return `""` on anything unexpected. `sandbox.nvim`
does its own TTL caching and stale-while-revalidate refresh; `ui.nvim` does
not know or care.

**The other pattern**, where `ui.nvim` holds the sibling's logic and reaches
into its internals:

| Sibling | `ui.nvim` module | LOC | Reaches into |
|---|---|---|---|
| `filetree.nvim` | `modules/filetree_cwd_mode` | 266 | `package.loaded["filetree"]` |
| `casedesk.nvim` | `modules/casedesk` | 169 | `casedesk.meta`, `casedesk.resolve` |
| `runtime-analysis.nvim` | `modules/runtime_analysis_ampel` | 140 | `runtime-analysis.telemetry` |
| `github_stats.nvim` | `modules/github_stats_badge` | 106 | `github_stats.analytics`, `github_stats.config` |
| `recommender.nvim` | `modules/recommender_badge` | 79 | `recommender.config` |

**760 lines against 48.** Each of the five re-implements presentation
decisions — `github_stats_badge` even carries its own `STATS_TTL_SECONDS`
cache over `analytics.query_metric`, next to a plugin that already has
`storage.lua` and `retention.lua`. Every one of them breaks if the sibling
renames an internal module, and none of the five siblings has a test that
would notice.

There is a third pattern in the same directory that is better than both:
`modules/plugin_progress` (36 lines) reads `lib.nvim.progress`'s shared
headless registry and therefore knows about **no** plugin at all —
"a new plugin needs no change here, only `progress_style = 'statusline'` in
its spec" (`modules/plugin_progress/init.lua:12-14`). Seven plugins feed it
and none of them is named in the code.

**Effort: M per sibling** to move its component into it behind a documented
`statusline.lua`, following `sandbox.nvim`'s file as the template.

### Done for four of the five, 2026-09-17 — and the fifth was a mistake in this finding

`recommender.nvim`, `github_stats.nvim`, `runtime-analysis.nvim` and
`casedesk.nvim` each ship a `statusline.lua` and a `docs/statusline.md`
now; the four segments here are ~24 lines apiece. What moved with the code
mattered more than the code: each carried the sibling's own design rules —
when an SLA badge appears and when it deliberately does not, what counts
as a slow function, how a repo slug is resolved — restated in `ui.nvim`
where no test in the owning repository could hold them.

**`filetree_cwd_mode` is not the same case, and this finding was wrong to
count it.** The table above grouped it with the other four on line count.
The call sites say otherwise: it uses
`filetree.feature("cwd_mode").badge()`, which filetree.nvim **documents as
its external-statusline API**, next to a `component()` sibling and a
`User FiletreeCwdModeChanged` autocmd for refresh. It reaches into nothing
internal.

The other ~200 lines are `ui.nvim`'s own presentation — the bg-filled
capsule, `ui.theme.palette` accents, `get_separators()`, the `St_*`
groups — plus the history-dots option, which is a `ui.nvim` idea and not a
filetree concept. Moving that into filetree.nvim would make it depend on
this plugin's palette and separator vocabulary and emit ui.nvim-specific
statusline syntax: coupling in the wrong direction, to satisfy a finding
that counted lines instead of reading call sites.

So the real split is **six of seven** siblings own their component, and the
seventh is already correct as it stands.

**A documentation symptom of the same asymmetry.** 22 sibling READMEs carry
the "Around it" section naming their neighbours. `my.nvim` is named in exactly
**one** of them (`ui.nvim`'s). `ui.nvim` is named in **three** (`my.nvim`,
`replacer.nvim`, `reposcope.nvim`) — and not in any of the seven whose data it
renders. `spotlight.nvim`'s section, for instance, names `buffer-ctx.nvim`,
`hover.nvim` and `cmdlog.nvim`, but not `my.nvim`, whose `cword_occurrences`
is its closest neighbour in the whole fleet. **Effort: S** for the seven
README paragraphs.

---

## 9. Checked, and there is no overlap

Recorded so the next pass does not re-open them.

| Candidate | Verdict |
|---|---|
| `lib.nvim.ui.statusline` vs `ui.statusline` | **Different concern.** `lib.nvim/lua/lib/nvim/ui/statusline/init.lua` is a per-window *badge* that resolves `laststatus = 3` by falling back to a one-line float. `ui.nvim` renders the global statusline. No shared code and no shared surface. |
| `spotlight.nvim` vs `my.hl_config.cword_occurrences` | **Adjacent, not overlapping.** Spotlight marks N manually chosen tokens and keeps them through searches and splits; `cword_occurrences` auto-follows `<cword>` transiently. Different lifetime, different trigger. They should cross-reference each other (see Tier E), not merge. |
| `insights.nvim` vs `modules/time_in_buffer`, `since_last_save`, `undo_depth` | **No overlap.** `insights.nvim` is code metrics, imports, symbols, smells — no time tracking anywhere in its 49 modules. |
| `buffer-ctx.nvim` vs breadcrumbs | **No overlap.** It *inserts or copies* buffer facts as text; it does not display context. |
| `mdview.nvim/core/breadcrumbs.lua` | **Name collision only.** A session history of which heading you were in and when. Unrelated to a winbar. |
| Devicon resolution | **No duplication.** Only `ui.nvim` (5 files) and `lsp.nvim` (1) touch `nvim-web-devicons`/`get_icon` fleet-wide. |
| `my.diagnostics` vs `lsp.nvim` | **Already resolved**, 2026-09-08 — `lsp.nvim` owns the `vim.diagnostic.config()` call, `my.nvim` contributes (`my.nvim/lua/my/diagnostics.lua:1-14`). This is the pattern the rest of the report keeps pointing back to. |
| `ui.bindings.keymaps.tabufline.state.move_buf` vs `lib.nvim…move_buffer_to_tab` | **Different operations** — reorder within a tab vs move across tabs. But see [D1](#d1--move_buffer_to_tab-leaves-a-ghost-chip-in-the-source-tab). |
| `filetree.nvim` cursor/window highlighting vs `my.hl_config` | **No overlap in intent** — filetree highlights *its own* tree buffer via extmarks. The only contact point is `winhighlight`, covered in [C2](#c2--winhighlight-merging-mynvim-has-the-safe-one-four-others-hand-roll). |
| `color_my_ascii.nvim` theme presets vs `ui.theme` | **No overlap.** `color_my_ascii` colours ASCII art content; `ui.theme.palette` derives accents from `nvim_get_hl` anchors for statusline segments. |
| `cmdlog.nvim` vs `ui.screenkey` | **No overlap.** cmdlog records executed commands for a picker; screenkey displays keystrokes live. Different data, different lifetime. (The *capture primitive* question is [C6](#c6--vimon_key-capture), and that is `debugging.nvim`.) |

---

## 10. Findings inside my.nvim's own scope boundary

Not sibling overlap; surfaced by the same pass and recorded here because they
are the same kind of question — does this feature live in the right plugin?

**F1 · `my.set_diff_profile` owns `diffopt`, and `diff.nvim` has no diffopt
handling at all — resolved 2026-09-18.** `my.nvim/lua/my/set_diff_profile/
profiles.lua` defined four profiles (`minimal`, `context`, `review`,
`strict`) of `diffopt` flag sets —
`algorithm:histogram`/`patience`, `linematch:60`, `indent-heuristic`, `iwhite`
— and `selector.lua:16` wrote `vim.o.diffopt`. `<leader>` cycling and
"which profile does the current `diffopt` match" lived in
`bindings/keymaps.lua:32-59`.

A grep for `diffopt` across all 23 of `diff.nvim`'s modules returned **zero**
hits. `diff.nvim` renders splits, resolves `git:HEAD`, does directory and
image compare — and had no opinion about the algorithm Neovim uses to compute
the diff it is showing. It turned out to have more of a stake than that:
`view=vsplit`/`split`/`tab` (the default view) all call `diffmode.set()` —
`diff.nvim` is the plugin that actually puts a window into native diffmode,
which is what makes `diffopt` matter in the first place.

**Decided: move to diff.nvim.** `diff.nvim@03b6359` gained
`features/diffopt_profile/` (the same four profiles, `names()`/`get()`/
`set()`/`current()`/`cycle()`) and `:DiffProfile {name}`, gated by
`features.diffopt_profile` (default on) and applying nothing at `setup()`
unless `diff.diffopt_profile` is explicitly set — so an existing
diff.nvim-only install sees no behaviour change. `my.nvim@1c147de` replaced
the owned module with `my.diff_profile`, a thin soft-require delegate:
`<leader>od` and `:My diff` still work exactly as before, now calling into
diff.nvim, and notify instead of erroring when it is absent.

**F2 · `my.hl_config.features.diff_peek` is a gitsigns hunk-preview keymap —
resolved 2026-09-18.** `features/diff_peek.lua` cleared and re-bound `gh` to
`gitsigns.preview_hunk` behind a soft-require. It was a git operation wearing a
highlight-feature's clothes, and it sat next to
[Externe-Plugins-Nachbau-Analyse.md](./Externe-Plugins-Nachbau-Analyse.md)'s
own `gitsigns → :ToggleInlineDiff → diff.nvim` entry — the same gitsigns
surface, assigned there to `diff.nvim`.

**Decided: move to diff.nvim, together with F1.** `diff.nvim@03b6359` gained
`features/gitsigns_peek.lua`, gated by `features.gitsigns_peek` (default on,
setup-time only like `diff_origin`/`diff_exit` — no runtime toggle). Removed
from `my.nvim@1c147de` entirely, along with every state/health/type reference
to it (`enable_diff_peek`, `hl_config.core.state`, `:checkhealth my`'s "Diff
peek" section) — unlike F1 there was nothing left in my.nvim to delegate
from, since the feature had no highlight content of its own.

**F3 · `my.indent_per_ft` is a hardcoded table with a config flag that only
turns it on.** `my.nvim/lua/my/indent_per_ft/init.lua` is 31 lines: a
12-filetype `INDENT_BY_FT` map, `DEFAULT_INDENT = 2`, and a `FileType`
autocmd. `indent_per_ft` appears in `@types/init.lua:34`,
`README.md:78`, `doc/my.txt:306` and `health.lua:143` — always as a
**boolean**. The table itself cannot be configured, extended or overridden by
a host, which is out of line with the rest of `my.nvim` (`config/DEFAULTS.lua`
exposes everything else).

Two consequences worth a line each. The autocmd sets
`vim.bo.expandtab = true` unconditionally for every filetype including `go`
(`:28`), where `gofmt` will convert it straight back to tabs on save. And it
runs on `FileType` with `pattern = "*"`, so it overrides whatever an
`.editorconfig` or a runtime `ftplugin` just set.

The mild sibling contact: `debugging.nvim/lua/debugging/nvim_options/indent_helpers.lua`
(`:Debug indent show`) reports exactly the four options this module writes, and
`:Debug indent treesitter` toggles `cindent`/`smartindent`, which it does not.
That is a useful pairing rather than a duplication — but it means the
diagnostic tool and the thing being diagnosed are in different plugins with no
link between them. **Effort: S.**

---

## 11. Suggested order

Cheapest-with-a-real-symptom first, then the two structural decisions.

| # | Finding | Effort | Why here |
|---|---|---|---|
| 1 | [D3](#d3--checkhealth-ui-hard-requires-a-module-uinvim-no-longer-uses) stale health entry | S | One line, and it blocks A1 |
| 2 | [A2](#a2--libnvimcontextmenu--uicontextmenu--and-uinvim-uses-the-wrong-one) `git_clickable` require | S | One line; today `menu = false` is not honoured |
| 3 | [D5](#d5--github_stats_badge-german-text-and-an-unguarded-emoji--widened-2026-09-17) German string + emoji | S | One line; already a known rule violation class |
| 4 | [D2](#d2--myuiline_numbers-uses-a-filesystem-ignore-list-as-a-filetype-list) wrong ignore list | S | 43 inert entries; `std_skip` is right there |
| 5 | [D1](#d1--move_buffer_to_tab-leaves-a-ghost-chip-in-the-source-tab) ghost tabline chip | S | Visible bug, and settles where the helper lives |
| 6 | [B2](#b2--two-mode-classifiers-that-disagree) mode map | S | The scope boundary's most literal violation |
| 7 | [C1](#c1--nobody-owns-keep-these-highlight-groups-defined) + [D4](#d4--diagnostic-virtual-text-background-is-restored-by-any-colorscheme) `hl.persist` | M | D4 is its first adopter; 21 sites follow |
| 8 | [C3](#c3--vimwowinbar-ownership-has-one-adopter-and-two-non-adopters) winbar adopters | S ×2 | The mechanism exists; two plugins need to use it |
| 9 | [C4](#c4--soft-require-centralization-mynvim-did-it-uinvim-did-not) / [C5](#c5--nerd-font-glyph-probing--three-approaches-and-the-library-one-is-unused) ui.nvim housekeeping | S | Brings `ui.nvim` level with `my.nvim`'s `rules.nvim` pass |
| 10 | [B1](#b1--symbol-breadcrumbs-exist-in-both-plugins-mynvims-lsp-half-is-dead) symbol breadcrumbs | M | Needs the ownership decision first; S for the interim fix |
| 11 | [C2](#c2--winhighlight-merging-mynvim-has-the-safe-one-four-others-hand-roll) winhighlight to lib | M | Lift-and-shift, then four call sites |
| 12 | [E](#8-tier-e--asymmetry-in-who-owns-a-siblings-statusline-component) statusline components | M ×5 | One sibling at a time; `sandbox.nvim` is the template |
| 13 | [A1](#a1--libnvimuikit--uikit--duplicated-on-purpose-diverging-by-accident--resolved-2026-09-17) kit deduplication | L | The largest, and the one that needs a decision, not typing |
| 14 | ~~[F1](#10-findings-inside-mynvims-own-scope-boundary)–F3 scope questions~~ | S–M | Done — all three resolved 2026-09-18 |
