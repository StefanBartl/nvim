# sessions.nvim chip: startup settle, auto-hide, statusline-docked default — handover

Status: **Partly built (2026-09-28).** Designed 2026-09-28, from four
issues the user spotted live (screenshots) after the chip
preset/session-pin work shipped, plus a fifth ("why so many saved
sessions") and a sixth ("configurable chip text, icons") added the same
day. **P0 done and reviewed** (Issue 3 root-caused and fixed for real —
`ui.nvim` `a78b319`, `lib.nvim` `2cd6bc3`, ultracode-reviewed 0 findings).
**P1 done and reviewed** (Issue 1's startup pop-in fixed, plus the pulse
revert bug found while reading the code for it — see P1's own section
below; final state `ui.nvim` `c9fd0f3`, `lib.nvim` `cd9534f`,
ultracode-reviewed across 5 rounds, 0 findings on the last). Everything
else still planned.

**Keep this file current:** update it whenever a step is finished or
something worth knowing turns up.

## Table of contents

  - [Read this first](#read-this-first)
  - [Findings, grounded in code](#findings-grounded-in-code)
    - [Issue 1 — startup pop-in (colour + position)](#issue-1--startup-pop-in-colour--position)
    - [Issue 2 — "nvim_main" instead of "last"](#issue-2--nvim_main-instead-of-last)
    - [Issue 3 — chip outlives timeout_ms](#issue-3--chip-outlives-timeout_ms)
    - [Issue 4 — statusline-docked, mode-tracking default](#issue-4--statusline-docked-mode-tracking-default)
    - [Issue 5 — why so many saved sessions](#issue-5--why-so-many-saved-sessions)
    - [Issue 6 — configurable chip text (icons, folder/branch)](#issue-6--configurable-chip-text-icons-folderbranch)
  - [Plan, phased](#plan-phased)
  - [Open questions / assumptions made](#open-questions--assumptions-made)
  - [Practical notes](#practical-notes)
  - [Where things are](#where-things-are)

---

## Read this first

Four things the user observed in a real session, from screenshots plus
their own description (colour names below are the user's, not independently
re-verified against the screenshots — the compressed images did not show a
clear enough colour difference for me to confirm them myself):

1. The `sessions.nvim` corner chip shows a brownish/yellow colour for
   roughly 4-5 seconds after it first appears, then flips to a mint-green
   colour — at the same moment the statusline's own mode indicator becomes
   visible/settles. The chip's *position* also shifts slightly (a few
   rows/cols down-left) at that same moment, ending up flush above the
   statusline. User's question: shouldn't this be right from the first
   paint?
2. After running `nvim +LastSession`, the chip shows `nvim_main`, not the
   literal word `last`.
3. The chip stays up permanently; `chip.timeout_ms` defaults to `3000`
   (configurable, `false` for the old always-on behaviour) and should have
   hidden it after 3s.
4. Feature request: a new **default** chip style for `sessions.nvim` that
   visually fuses with `ui.nvim`'s own statusline — sitting flush against
   it (not floating with a gap above), using the same `rounded_chip` look
   the statusline's own mode pill uses, **except** the left edge must stay
   square (that edge sits at the screen border), and its colour should
   track the statusline's current mode colour (e.g. green in Normal,
   turquoise-ish in Insert per the user's screenshots).

Triage: (1) and (3) are most likely two symptoms of the *same* root cause,
one of which (a real, independent bug) is already identified from reading
the code; (2) is **not a bug** — explained below, no code change proposed;
(4) is a real feature needing a small, precedented primitive extension in
`ui.kit.chip` plus a design decision on where the statusline-specific
wiring should live.

## Findings, grounded in code

### Issue 1 — startup pop-in (colour + position)

- The chip mounts **synchronously** during `sessions.setup()`:
  [`sessions/init.lua:28`](E:\repos\sessions.nvim\lua\sessions\init.lua)
  (`bindings.autocmds.enable()`) →
  [`bindings/autocmds/init.lua:116`](E:\repos\sessions.nvim\lua\sessions\bindings\autocmds\init.lua)
  (`chip.ensure_mounted()`) — which runs during lazy.nvim's `lazy = false`
  spec-loading phase, i.e. **before `VimEnter`**, before Neovim's own
  startup geometry (`cmdheight`, the real post-attach `&lines`/`&columns`)
  has necessarily settled. `tokyonight.nvim` is `priority = 1000` (see
  [`plugins/colorscheme/tokyonight.lua`](C:\Users\bartl\AppData\Local\nvim\lua\plugins\colorscheme\tokyonight.lua)),
  so the colorscheme itself is very likely already active by then — the
  bug is about **layout**, not (only) about colours not being themed yet.
- [`ui.kit.chip`'s `reflow()`](E:\repos\ui.nvim\lua\ui\kit\chip.lua) (lines
  392-430) computes row/col from **live** `vim.o.lines`/`cmdheight`/
  `laststatus` every time it runs — correct in principle, but it only
  re-runs on specific trigger events (`M.refresh`, `VimResized`,
  `TabEnter`), none of which mean "Neovim's own startup has actually
  settled". The very first `reflow()` (from `mount()` → `M.refresh()`,
  lines 482-512 / 520-604) can use values that are still mid-settle.
- **A real, independent bug**: `M.pulse()`'s deferred revert callback
  (chip.lua lines 611-628) guards on `e.win == win` — `win` is the window
  handle captured *when the pulse started*. If the chip's window gets
  closed and reopened in between (e.g. because the session name/text
  changed width right after `:LastSession` loads it — very plausible,
  since `do_load()` calls `chip.refresh()` immediately before `chip.pulse()`,
  see below) before the pulse's `duration_ms` (default 300ms) elapses, the
  captured `win` no longer matches `chips[id].win`, the guard fails
  silently, and the chip is left stuck showing the pulse's `DiagnosticWarn`
  colour — until some *later*, unrelated `M.refresh()` call happens to
  re-resolve it back to the steady colour. That "later, unrelated call" is
  whatever the next dirty-tracking event
  ([`BufAdd`/`BufDelete`/`WinNew`/`WinClosed`/`TabNewEntered`/`TabClosed`](E:\repos\sessions.nvim\lua\sessions\bindings\autocmds\init.lua))
  happens to be — no defined bound, hence an arbitrary-looking "~4-5s"
  before it self-corrects.
- `:LastSession` → [`do_load(nil)`](E:\repos\sessions.nvim\lua\sessions\bindings\usercmds\init.lua)
  (lines 134-151) calls `chip.refresh()` **then** `chip.pulse()` — exactly
  the sequence that can trigger the width-change-mid-pulse race above.
- Net effect: the chip's *first* paint can be using stale layout and/or a
  stuck pulse colour, and only reaches its correct, final state whenever
  the next incidental event fires `M.refresh()` — which is what reads as
  "pops into the right place/colour a few seconds later, in sync with
  something else settling", because that "something else" is really just
  whichever unrelated event happened to fire next.

### Issue 2 — "nvim_main" instead of "last"

**Not a bug.** `cfg.default_name = "last"`
([`config/DEFAULTS.lua:17`](E:\repos\sessions.nvim\lua\sessions\config\DEFAULTS.lua))
names the **fallback** session slot, used only when neither the current
project/branch's own session file nor a remembered last-loaded pointer
exists — see
[`core.lua`'s `resolve()`](E:\repos\sessions.nvim\lua\sessions\core.lua)
(lines 115-157). `:LastSession` deliberately does **not** hardcode
`do_load("last")` — the code says exactly why, verbatim, right above the
registration:

> Used to hardcode `do_load("last")` instead, on the theory that the
> literal "last" was always what autosave wrote to. That stopped being
> true once `autosave_name = true` (the default) started auto-resolving
> autosave by branch/project like a real save — a hardcoded "last" would
> then load a stale or nonexistent file instead of what was actually just
> autosaved.
> — [`bindings/usercmds/init.lua:515-527`](E:\repos\sessions.nvim\lua\sessions\bindings\usercmds\init.lua)

In this user's case, `branch_aware`/`project_aware` are both `true`
(defaults), and a session file `nvim_main.vim` already exists (saved
before) — `resolve()`'s step 1 picks that over the `"last"` fallback,
correctly. The chip is showing the *actually loaded* session's real name,
which is strictly more useful than a static `"last"` label would be. No
code change proposed here.

### Issue 3 — chip outlives timeout_ms

**Status:** Root-caused, fixed, and reviewed — 2026-09-28, `ui.nvim`
`a78b319`, `lib.nvim` `2cd6bc3`. Reviewed the same day by an adversarial
multi-agent pass across correctness/bugs, security, and performance (3
dimensions, each independently checked against both diffs plus every other
caller of `resolve_visible()`/`M.refresh()`): **0 findings**. (Heading kept
short on purpose, matching the Table of contents above — a `— DONE (...)`
suffix appended straight into a heading silently breaks its own ToC
anchor, a real mistake the sibling chip-presets-and-pins handover hit and
had to fix; not repeating it here.)

Root-caused via a live reproduction, not the "same as Issue 1" guess this
section originally proposed — a real, independent bug, unrelated to
Issue 1's startup-timing hypothesis:

`sessions/chip.lua`'s `schedule_hide()`/`hide_generation`
([lines 59-82](E:\repos\sessions.nvim\lua\sessions\chip.lua)) turned out to
read correctly, confirmed by instrumenting it live: the deferred callback
fires exactly on schedule, correctly identifies itself as the current
generation, sets `visible = false`, and calls
`kit_mod.chip.refresh(CHIP_ID)` — all of that works. The chip still stayed
on screen anyway.

The actual bug was one layer down, in `ui.kit.chip`'s own
`resolve_visible()`
([`ui/kit/chip.lua:224-233`](E:\repos\ui.nvim\lua\ui\kit\chip.lua)). Its
function branch used the classic `a and b or c` ternary idiom:

```lua
local ok, out = pcall(v)
return ok and out and true or (ok and false or nil)
```

That idiom cannot express a provider **returning `false`**: the moment
`out` is `false`, `ok and out` is already `false`, so the whole expression
always falls through to the `or` branch — and `(ok and false or nil)` is
`nil` regardless of `ok`, by the exact same flaw. So a `visible = function()
... end` provider returning `false` was **indistinguishable from one
returning `nil`/erroring** — `M.refresh()`'s own fallback
(`if visible == nil then visible = text ~= "" end`) then took over and
re-showed the chip anyway, since its text was still non-empty. `sessions.chip`'s
auto-hide is exactly this shape (`visible = function() return visible end`,
the closure flipping to `false`), so it could never actually hide,
regardless of `timeout_ms`.

Confirmed with a real, unstubbed headless reproduction before touching any
code: mounted the real chip, loaded a real session (the same
`core.load()` → `chip.refresh()` → `chip.pulse()` sequence `:LastSession`
runs), and sampled `require("ui.kit").chip.active()` over several seconds
with real timers running (`vim.wait`) — the chip was still active at
4000ms+ with the bug, and correctly gone by ~3200ms once
`resolve_visible()` was fixed to return the provider's actual boolean.

Fixed by rewriting `resolve_visible()`'s function branch as a plain
`if`/`return` instead of the broken ternary. Regression test added
(`TESTS/ui_kit_chip_spec.lua`: "a visible PROVIDER (function) returning
false wins over non-empty text"). Full suite green in both repos (one
unrelated pre-existing failure each: `ui.nvim`'s
`context_languages_spec.lua` kotlin case, `lib.nvim`'s `git_sync_spec.lua`
async-timing test — both untouched by this fix, both already documented
elsewhere in this repo's own history). Ported to `lib.nvim`'s frozen copy
per the usual drift-guard convention, `kit_drift_spec.lua` confirmed clean
afterward.

This bug is not `sessions.nvim`-specific — **any** `ui.kit.chip` consumer
passing a `visible` *function* that can return `false` was affected (a
`visible = false` *literal*, the other code path, was always fine — see
the pre-existing "an explicit visible = false wins over non-empty text"
test, which never caught this because it only exercised the boolean-literal
path, not the function path).

### Issue 4 — statusline-docked, mode-tracking default

- `ui.kit.theme.lua`'s preset registry already supports a **raw 8-element
  border array**, not just Neovim's named presets — see the existing
  `ascii` preset,
  `border = { "+", "-", "+", "|", "+", "-", "+", "|" }`
  ([`ui/kit/theme.lua:70-71`](E:\repos\ui.nvim\lua\ui\kit\theme.lua)). A
  "rounded everywhere except the left edge" look is therefore a small,
  precedented addition: a new preset (name TBD, e.g. `dock_left`) with
  `border = { "", "─", "╮", "│", "╯", "─", "", "" }` (square/no glyph on
  the left corners and edge, rounded top-right/bottom-right).
- Sitting flush against the statusline (not floating with a gap above it)
  needs new row/col behaviour in
  [`reflow()`](E:\repos\ui.nvim\lua\ui\kit\chip.lua) (lines 392-430):
  currently `row = ... - status_rows - offset - box_h + 1` always leaves a
  gap-free but *separate* box just above the statusline row. A docked
  variant needs `row` to land *on* the statusline row itself
  (`vim.o.lines - vim.o.cmdheight - 1`), flush left (`col = 0`), no
  `MARGIN` inset on that side.
- Mode-colour tracking: `ui.nvim`'s statusline names mode groups
  `St_<Suffix>Mode`/`...ModeSep`/`...ModeText` **per mode**
  ([`ui/statusline/utils/primitives.lua:29-76`](E:\repos\ui.nvim\lua\ui\statusline\utils\primitives.lua))
  — there is no single stable group whose *own* colour changes with mode;
  the statusline switches *which group it references* as the mode
  changes. `ui.kit.chip`'s `color` option today accepts a string (group
  name) or a `{fg,bg}` table, resolved fresh on every `M.refresh()`
  ([`resolve_colors()`](E:\repos\ui.nvim\lua\ui\kit\chip.lua), lines
  144-154) — extending it to **also accept a function**
  (`fun(): string|table`) is small and precedented: `text`/`visible`
  already work exactly this way (`resolve_text`/`resolve_visible`).
- For the chip to visually track mode changes *as they happen* (not just
  at the next incidental dirty-tracking event), something needs to call
  `chip.refresh()` on `ModeChanged`. Proposed as an **opt-in** hook
  (registered only for a chip that asks for it), so this does not add an
  unconditional high-frequency autocmd for every `ui.kit.chip` consumer
  that never wants it.
- **Architecture call, flagged rather than silently assumed:** keep
  `ui.kit.chip`/`ui.kit.presets` statusline-*agnostic* — the dock
  geometry and function-valued colour are generic, reusable primitives.
  The `ui.nvim`-statusline-*specific* `St_<Mode>Mode` group-name lookup
  should live in **this user's own personal install spec**
  ([`lua/plugins/personal/init.lua`](C:\Users\bartl\AppData\Local\nvim\lua\plugins\personal\init.lua)'s
  `sessions.nvim` `opts.chip.color` function), not inside `sessions.nvim`
  itself. This matches the soft-coupling pattern already used everywhere
  in this plugin family (`sessions.chip`'s own module doc: "soft
  dependency on ui.kit" — never a hard, silent coupling to one specific
  consumer's internals). The alternative — baking `St_<Mode>Mode`
  awareness directly into `sessions.nvim` — is simpler for this one user
  but couples a portable, public plugin to one specific statusline's
  naming convention, breaking silently for anyone on a different
  statusline (or no `ui.nvim` statusline at all). **Recommendation: the
  former.** See [Open questions](#open-questions--assumptions-made) if you
  disagree.

### Issue 5 — why so many saved sessions

Checked live: [`sessions/`](C:\Users\bartl\AppData\Local\nvim-data\sessions)
holds **11 distinct sessions** (`.vim` + matching `.json` metadata pairs,
plus `marks/` and the shared `.state.json` pointer), all saved between
2026-09-26 and 2026-09-28:

| Session name | Repo it belongs to (by name pattern) | Still exists? |
|---|---|---|
| `WKDBooks_main` | `WKDBooks`, branch `main` | yes |
| `case-number-pin-position-8abe97_claude-case-number-pin-position-8abe97` | some repo, branch `claude/case-number-pin-position-8abe97` | **branch not found** — likely a merged/removed Claude worktree |
| `github_stats-nvim_main` | `github_stats.nvim`, branch `main` | yes |
| `insights-nvim_main` | `insights.nvim`, branch `main` | yes |
| `last` | the `default_name` fallback slot (see Issue 2) | n/a |
| `lib-nvim_main` | `lib.nvim`, branch `main` | yes |
| `nvim-usercmds-env-vars-3560c9_claude-cursor-jump-save-1f9524` | this nvim config, branch `claude/cursor-jump-save-1f9524` | yes — active worktree `nvim-usercmds-env-vars-3560c9` |
| `nvim_main` | this nvim config, branch `main` | yes |
| `rules-nvim-review-277-071e53_claude-ui-nvim-statusline-integration-ece8e4` | some repo, branch `claude/ui-nvim-statusline-integration-ece8e4` | **branch not found** — likely a merged/removed Claude worktree |
| `ui-nvim_main` | `ui.nvim`, branch `main` | yes |

This is **not really "too many"** for three days of active multi-repo work
with `branch_aware`/`project_aware` both on (the defaults): one session per
distinct `(project, branch)` combination the user actually worked in is
exactly what that naming scheme is designed to produce
([`sessions/git.lua`'s `resolve_name()`](E:\repos\sessions.nvim\lua\sessions\git.lua),
lines 111-148 — `<project-root-basename>_<sanitized-branch>`, see Issue 2's
full explanation above for the mechanism). What IS a real gap: **two of
these are already orphaned** — their git branch no longer exists (a merged
and deleted Claude Code worktree branch), so nothing will ever resolve to
or load them again by name, yet they sit in `sessions/` forever. Grepped
`sessions.nvim`'s `bindings/usercmds/init.lua` for every registered
`:Session <verb>` — there is `save`/`save-timestamp`/`load`/`delete`/
`rename`/`list`/`current`/`toggle-track`/`save-tab`/`load-tab`/
`save-layout`/`load-layout`/`marks *`, but **no prune/gc verb** — the only
way to remove a stale session today is a manual `:Session delete <name>`
per file, and nothing ever tells the user which ones are stale in the
first place.

### Issue 6 — configurable chip text (icons, folder/branch)

Feature request: the chip currently shows the raw resolved session name as
one line of plain text (e.g. `nvim_main`) — the user wants a nicer default
(a folder icon + project name, and *below it* a git-branch icon + branch
name), while keeping today's plain-text look available as an explicit
opt-out, and the whole thing user-customizable (which icon, what order),
not just a fixed on/off switch.

- Today's chip text comes straight from
  [`sessions.statusline.component()`](E:\repos\sessions.nvim\lua\sessions\statusline.lua)
  (lines 48-57: `resolved.icon .. name .. dirty`, one line) — `chip.lua`'s
  `ensure_mounted()` wires `text = function() return
  require("sessions.statusline").component() end` directly. That function
  also feeds the *plain statusline segment*, which genuinely cannot go
  multi-line — so the chip needs its **own** formatter, not a reuse of
  that single-line one.
- `ui.kit.chip` already supports multi-line text via embedded `\n`
  (`split_lines()`, [`ui/kit/chip.lua`](E:\repos\ui.nvim\lua\ui\kit\chip.lua))
  — `casedesk.nvim`'s pin chip already renders two lines
  (case number / title) this way, so a two-line "folder / branch" chip is
  not new ground, just a new caller.
- The folder/branch values should come from a **live** lookup
  ([`sessions.git`](E:\repos\sessions.nvim\lua\sessions\git.lua)'s
  `project_root()`/`current_branch()`), **not** by parsing the resolved
  session *name* back apart — the same ambiguity Issue 5's own Open
  Question 6 already flags for P6's staleness check (a name like
  `nvim-usercmds-env-vars-3560c9_claude-cursor-jump-save-1f9524` has
  underscores on both sides of the real split, so there is no reliable way
  to un-concatenate it). Querying live also means the chip stays accurate
  even for a session loaded under an unrelated custom name.
- Proposed shape: two named presets plus full custom control —
  - `"classic_text"` — today's exact behaviour (one line, plain resolved
    name), for anyone who wants the current look back outright.
  - `"modern"` — the new **default**: two lines, `{icon} {folder}` then
    `{icon} {branch}`.
  - A template string for anyone who wants something in between, using
    `folder`/`branch` as keywords, with each icon settable *separately*
    from the layout (so swapping one glyph does not mean rewriting the
    whole template) — e.g. (exact keys/names TBD at implementation time)
    `chip.text = { preset = "modern", icons = { folder = "<glyph>", branch
    = "<glyph>" }, template = "{icon.folder} {folder}\n{icon.branch}
    {branch}" }`. Icons accept a literal glyph string (nerd-font icon or
    plain unicode/ASCII) — no dependency on `nvim-web-devicons`/`mini.icons`
    being installed, though the *default* glyphs should match whatever this
    user's own `filetree.nvim` setup already shows for a folder, for visual
    consistency. `filetree.nvim` itself delegates its own folder glyph to
    whichever icon provider is installed (`nvim-web-devicons`/`mini.icons`)
    rather than hardcoding one — the exact default glyph needs a live check
    against this user's actual setup at implementation time, not a guess
    here.
  - Graceful fallback: when `branch_aware`/`project_aware` are both off, or
    the loaded session has a custom name unrelated to the live
    folder/branch, `"modern"` falls back to `"classic_text"`'s single-line
    behaviour rather than showing an icon next to something that isn't
    really a folder/branch pair.

## Plan, phased

### P0 — Diagnose Issue 3 live

**Status:** Done and reviewed — 2026-09-28, `ui.nvim` `a78b319`, `lib.nvim`
`2cd6bc3` (ultracode multi-agent review, 0 findings across
correctness/security/performance — see Issue 3's own section above).

~0.25 session, as estimated. Repo: none for the diagnosis itself (a real
headless reproduction, not a guess); `ui.nvim` + `lib.nvim` for the fix
the diagnosis led straight to.

**As done.** Instrumented `schedule_hide()`/`hide_generation`
([`sessions/chip.lua:65-82`](E:\repos\sessions.nvim\lua\sessions\chip.lua))
with temporary prints in a real headless reproduction (real `setup()`,
real `core.load()` → `chip.refresh()` → `chip.pulse()`, the exact
`:LastSession` sequence, sampled with `vim.wait()` so real timers fire).
Result: the deferred hide **does** fire exactly on schedule and **does**
correctly call `refresh()` with `visible = false` — `sessions.chip`'s own
logic was never the problem. The bug was one layer down, in
`ui.kit.chip.resolve_visible()`. Full write-up, the fix, and its
regression test are now in Issue 3's own section above — **this was not
the same mechanism as Issue 1** (the original hypothesis in this phase's
description), a genuinely separate, now independently confirmed-fixed bug.
Debug prints removed from `sessions.nvim` before committing (that repo has
no changes from this phase — the fix lives entirely in `ui.nvim`/`lib.nvim`).

### P1 — ui.kit.chip: post-startup settle pass (Issue 1 only)

**Status:** Done and reviewed — 2026-09-28. Final state: `ui.nvim`
`c9fd0f3`, `lib.nvim` `cd9534f` (mirrored, `kit_drift_spec.lua` clean).
ultracode-reviewed across 5 rounds (correctness/bugs, security,
performance, each independently checked and adversarially verified) — the
first 4 rounds each found and got a real, live-reproduced fix; round 5
found nothing. Full suite green in both repos afterward (the two
pre-existing, already-documented failures aside: `ui.nvim`'s
`context_languages_spec.lua` kotlin case, `lib.nvim`'s `git_sync_spec.lua`
async-timing test — neither touched by this work).

**As done**, item 1 (settle pass): a one-time (`once = true`) `VimEnter`
handler in `ensure_hooks()`, wrapped in `vim.schedule()`, re-resolves
colour and calls `reflow()` for every mounted chip. `VimEnter`, not
`UIEnter` — confirmed live (a headless repro) that `UIEnter` never fires
at all in a `--headless` run, which would make the settle pass silently
skip there; this also matches an identical, already-made choice in this
user's own nvim config (`lua/startup/init.lua`'s `UI_READY`: "does NOT use
lazy.nvim's `User VeryLazy`... measured not firing at all in headless
runs").

Item 2 (the pulse-revert guard) turned out to need **four** follow-up
fixes past the one originally scoped here, each found by the next
adversarial review round catching a real regression or gap in the
previous one — the full chain, in order:

1. `746d510`/`c48b460` — as planned: stopped comparing the revert
   callback's captured window handle (`e.win == win`) against the
   **current** one, fixing the original "stuck in pulse colour after a
   window replacement" bug.
2. `249800e`/`cece91c` — review found (1) alone let an **earlier** pulse's
   now-unconditional revert cut a **later**, still-active pulse short once
   the window had been replaced in between. Fixed with a per-entry
   `pulse_generation` counter (same shape as `sessions.nvim`'s own
   `hide_generation`).
3. `8d5f071`/`ceaac1a` — review found the counter alone still wasn't
   enough: `M.unmount(id)` + `M.mount(id, ...)` allocates a brand-new
   entry table whose own counter restarts from scratch, so a stale
   callback from the orphaned old entry could numerically collide with the
   new entry's first pulse. Fixed by also requiring `chips[id] == target`
   (the entry table captured at pulse-start), not just a matching
   generation.
4. `dc704be`/`077658b` — review found a much bigger, pre-existing gap none
   of the above touched: `M.refresh()`'s own colour reconciliation (and
   `M.mount()`, which always tail-calls it) had no idea a pulse could be
   in flight and would unconditionally snap the colour back to
   `entry.color` on **any** refresh — a path that never goes through
   `M.pulse()`'s guarded callback at all. Since `sessions.nvim` wires
   `chip.refresh()` into ordinary `BufAdd`/`BufDelete`/`WinNew`/
   `WinClosed`/`TabNewEntered`/`TabClosed` dirty-tracking, this fired on
   nearly every real pulse. Fixed with `entry.pulse_active`, set by
   `M.pulse()` and read (not touched) by `M.refresh()`'s colour block and
   the `ColorScheme`/`VimEnter` re-tint handlers, which now all skip
   colour reconciliation while it's `true`.
5. `c9fd0f3`/`cd9534f` — review found `open_window()` (reopening a chip's
   window, e.g. `ensure_current_tab()`'s tab-switch reopen) always
   repaints the steady colour by design, but left `pulse_active` still
   `true` — desyncing the flag from reality and wrongly blocking a
   **later, unrelated** colour change for up to the rest of the original
   pulse's `duration_ms`. Fixed by having `open_window()` clear
   `pulse_active` alongside its existing repaint.

Item 3 (tests): `TESTS/ui_kit_chip_spec.lua` grew one regression spec per
fix above (9 new specs total) — each confirmed to fail against the prior
commit's code (reverted locally, ran the suite, restored) before being
committed, not just asserted to pass against the new one.

### P2 — sessions.nvim: confirm the pop-in is gone

~0.25 session. Repo: `sessions.nvim` (verification only, no code expected).

- Live-check Issue 1's original symptom (colour/position pop-in a few
  seconds after startup) is gone after P1. Issue 3 no longer needs
  re-confirming here — P0 already did, live, with real timers.

### P3 — ui.kit.chip: docked-left preset + function-valued colour + mode-track hook

~1 session. Repo: `ui.nvim`.

1. New `ui/kit/theme.lua` preset (name TBD): border array with a flush
   (non-rounded, no glyph) left edge, rounded top-right/bottom-right —
   see [Issue 4](#issue-4--statusline-docked-mode-tracking-default) above
   for the exact array.
2. New anchor value or boolean opt (name TBD, e.g. `dock = true`
   alongside the existing `anchor` values) in `reflow()`: row lands
   directly on the statusline row, col flush at 0, no `MARGIN` gap on
   that side. Reuses `bottom_statusline_rows()` (lines 370-385) to decide
   whether there even *is* a statusline row to dock against — degrades to
   the existing "float just above" behaviour when there isn't one (e.g.
   `laststatus = 0`, or no real statusline plugin at all), so this stays
   safe as a default even without `ui.nvim`'s own statusline active.
3. `color` option gains function support: a `resolve_color`-style helper
   alongside `resolve_text`/`resolve_visible`, called inside
   `resolve_colors()`.
4. Opt-in mode-tracking (name TBD, e.g. `track_mode = true`): when set,
   `ensure_hooks()` also refreshes that one chip on `ModeChanged`. Scoped
   per-chip (only chips that ask for it get the extra autocmd work), not
   a blanket subscription.
5. Tests: the new preset's border shape; the dock option's row/col math
   (flush against the statusline, no gap, degrading correctly without a
   statusline row); function-valued colour resolving fresh on every
   refresh; `track_mode` firing exactly one extra refresh per
   `ModeChanged` when on, none when off.

### P4 — sessions.nvim: adopt the new preset as its own default

~0.5 session. Repo: `sessions.nvim`.

- `config/DEFAULTS.lua`: document the new dock preset as an allowed
  `chip.shape` value. Per the user's own ask ("als Default-Preset"), make
  it `sessions.nvim`'s actual default — the degrade-safely behaviour from
  P3 step 2 is exactly what makes this safe to default without breaking
  anyone not running `ui.nvim`'s statusline.
- Update `docs/configuration.md`/`docs/statusline.md` accordingly.

### P5 — This config: wire mode-colour tracking for the session chip

~0.25 session. Repo: this nvim config (`C:\Users\bartl\AppData\Local\nvim`).

- `lua/plugins/personal/init.lua`'s `sessions.nvim` spec: add
  `chip = { shape = "<new dock preset>", track_mode = true, color =
  function() ... end }`, mapping `vim.fn.mode()` through
  `ui.statusline.utils.primitives.modes`'s suffix table to build the
  matching `St_<Suffix>Mode` group name. Visually confirm it against the
  live editor — the "hellgrün Normal / türkis-ish Insert" look from the
  user's own screenshots — not just the automated tests, since this is
  fundamentally a visual-fit feature.

### P6 — sessions.nvim: surface (and optionally clean up) stale sessions

~0.5 session. Repo: `sessions.nvim`.

- New `:Session stale` (name TBD): for every saved session whose name
  matches the `<project>_<branch>` pattern (i.e. was `branch_aware`-
  resolved, not a custom name), re-run
  [`sessions.git`](E:\repos\sessions.nvim\lua\sessions\git.lua)'s branch
  lookup against that session's own recorded `cwd`
  ([`sessions.meta`](E:\repos\sessions.nvim\lua\sessions\meta.lua) already
  stores `cwd`/`branch` per save) and list the ones whose branch no longer
  exists there. Read-only by default — just a list, same shape as
  `:Session list`.
- `:Session delete-stale` (name TBD): same detection, deletes what it
  finds, after one confirm for the whole batch (same "ask once, not once
  per item" pattern `close_bufs`/`close_all_bufs` already use elsewhere in
  this plugin family) — never silently, and never on a session whose
  branch lookup itself fails/errors (ambiguous is not the same as
  confirmed-gone).
- Explicitly **not** proposed: automatic deletion on its own (e.g. on
  `VimLeavePre`) — a session for a branch that is merely checked out
  elsewhere right now (a worktree not currently open) must never look
  "stale" and get swept.
- Tests: a fixture with one live-branch session and one session whose
  recorded `cwd`/branch no longer resolves, asserting `stale` lists
  exactly the second and `delete-stale` removes exactly the second's
  `.vim`/`.json`/sidecar files.

### P7 — sessions.nvim: configurable, icon-capable chip text

~0.75 session. Repo: `sessions.nvim`.

1. New chip-text formatter (name TBD, e.g. `sessions/chip_text.lua`),
   separate from `sessions.statusline.component()` — the latter stays
   exactly as-is (single line, used by the plain statusline segment); the
   new one is what `chip.lua`'s `ensure_mounted()` wires as `text` instead.
2. `"classic_text"` preset: today's exact one-line output (delegates
   straight to the existing `sessions.statusline.component()` — no
   behaviour change for anyone who picks it).
3. `"modern"` preset (new **default**): two lines via `\n`, live
   `sessions.git.project_root()`/`current_branch()` lookups (not a
   session-name parse — see Issue 6), each prefixed by its own
   separately-configurable icon; falls back to `"classic_text"`'s output
   when `branch_aware`/`project_aware` are off or the live lookup comes up
   empty.
4. Template/icon override support for anyone who wants a custom layout
   (exact option shape TBD, see Issue 6's proposed sketch).
5. `docs/configuration.md`/`docs/statusline.md`: document the new
   `chip.text` option, both presets, and the template override.
6. Tests: `"classic_text"` byte-for-byte matches today's output;
   `"modern"`'s two-line output and icon placement; the fallback path when
   git-awareness is off; a custom template round-tripping through the
   formatter correctly.

## Open questions / assumptions made

1. The exact "~4-5 seconds" in Issue 1 is environment/session-specific
   noise (whatever the next dirty-tracking event happens to be) — P1's
   settle-pass fix does not *guarantee* correction lands within some
   specific millisecond budget, only that the chip reaches its correct,
   final state deterministically on the next `VimEnter`/`UIEnter` tick
   instead of "whenever". Acceptable, or does this need a tighter bound?
2. New preset/option names (`dock_left`, `dock`, `track_mode`,
   `resolve_color`) are placeholders — bikeshed at implementation time
   against this codebase's existing naming conventions (same caution as
   the chip-presets plan's own "Open questions" item 3, which turned out
   fine as guessed).
3. Architecture call in Issue 4 (generic `ui.kit.chip` primitives +
   user-owned mode-colour wiring, vs. baking `St_<Mode>Mode` knowledge
   into `sessions.nvim` directly) — flagged above, recommendation given,
   not yet confirmed by the user.
4. Should the docked style also become `casedesk.nvim`'s pin default
   (bottom-right corner)? Recommendation: no, not yet — ship it for
   `sessions.nvim` first, `casedesk.nvim` can adopt later once the look is
   proven live, rather than defaulting two consumers to an unproven style
   at once.
5. **Superseded by P0's actual finding**: P0 turned out to be unrelated to
   Issue 1's startup-timing hypothesis (it root-caused Issue 3 to a plain
   `ui.kit.chip` logic bug instead). P1's exact fix (VimEnter vs UIEnter,
   `vim.schedule()` vs a short `vim.defer_fn`) still needs its *own* live
   measurement before implementation — just not from P0's data, which
   doesn't speak to it. Do the same "instrument first, then fix" discipline
   P0 just used, fresh, inside P1 itself.
6. P6's staleness check re-derives the branch from the session's recorded
   `cwd`, not from the session *name* (name-parsing a `<project>_<branch>`
   string back apart is ambiguous whenever either half itself contains an
   underscore — e.g. `nvim-usercmds-env-vars-3560c9_claude-cursor-jump-save-1f9524`
   above has underscores on both sides of the real project/branch split).
   Confirm `sessions.meta`'s stored `cwd` is reliably the right directory
   to re-run the branch lookup from (it should be — `cwd` is captured at
   save time from wherever the session was actually saved from) before
   building on that assumption.
7. P7's default icon glyphs are an open lookup, not a guess made here:
   `filetree.nvim` delegates its own folder icon to whichever provider
   (`nvim-web-devicons`/`mini.icons`) is installed rather than hardcoding
   one — check this user's actual live setup (`:checkhealth` or a direct
   provider query) at implementation time for the exact default glyph, and
   pick a conventional git-branch glyph (nerd-font `nf-oct-git_branch` or
   similar) to match it stylistically.

## Practical notes

- Workflow rule for this project: max **one** repo touched per work
  session/agent; go phase by phase in the order above, commit + push to
  `main` after each phase, tests green before moving on.
- `ui.nvim`'s `ui/kit/*` is manually frozen-copied into `lib.nvim`'s
  `lib/nvim/ui/kit/*` — any change to `ui/kit/chip.lua`/`ui/kit/theme.lua`
  in P1/P3 must be ported by hand into `lib.nvim`'s copy afterward, then
  checked with `kit_drift_spec.lua` (see the `ui-kit-lib-nvim-drift-guard`
  memory, and the P1 phase of the chip-presets-and-pins handover this one
  follows on from).
- Commit messages: English body, no Claude co-authorship line (per this
  user's global `CLAUDE.md`).
- `sessions.nvim`, `ui.nvim`, `lib.nvim`, `casedesk.nvim` all load from
  their local `$REPOS_DIR` checkouts on this machine (confirmed via
  `plugins/personal/utils.lua`'s `local_dev()` — see
  [`plugins/personal/README.md`](C:\Users\bartl\AppData\Local\nvim\lua\plugins\personal\README.md)),
  not a separately cached copy — no "stale installed plugin" risk to
  account for while testing changes live.

## Where things are

- `ui.nvim` — `E:\repos\ui.nvim` (chip: `lua/ui/kit/chip.lua`, theme:
  `lua/ui/kit/theme.lua`, statusline mode groups:
  `lua/ui/statusline/utils/primitives.lua`)
- `lib.nvim` — `E:\repos\lib.nvim` (frozen-copy target for `ui/kit/*`)
- `sessions.nvim` — `E:\repos\sessions.nvim` (chip wiring:
  `lua/sessions/chip.lua`; autoload/`:LastSession`:
  `lua/sessions/bindings/autocmds/init.lua`,
  `lua/sessions/bindings/usercmds/init.lua`; name resolution:
  `lua/sessions/core.lua`, `lua/sessions/git.lua`; saved metadata (`cwd`/
  `branch`, for P6): `lua/sessions/meta.lua`)
- Saved session files on this machine: `C:\Users\bartl\AppData\Local\
  nvim-data\sessions\` (11 sessions as of 2026-09-28, see Issue 5)
- `casedesk.nvim` — `E:\repos\casedesk.nvim` (referenced only for the P3
  "should the dock style spread there too" open question)
- This nvim config — `C:\Users\bartl\AppData\Local\nvim` (sessions.nvim's
  own install spec: `lua/plugins/personal/init.lua`; colorscheme:
  `lua/plugins/colorscheme/tokyonight.lua`)
