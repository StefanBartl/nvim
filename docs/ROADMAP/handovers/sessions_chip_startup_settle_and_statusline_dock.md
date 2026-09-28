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
ultracode-reviewed across 5 rounds, 0 findings on the last). **P3 done and
reviewed** (Issue 4's dock preset/function-colour/mode-track primitives —
final state `ui.nvim` `276b05f`, `lib.nvim` `387a666`, ultracode-reviewed
across 2 rounds, round 1 found a severe group-clear regression, round 2:
0 findings). **P4 done and reviewed** (sessions.nvim adopts the dock
preset as its own default — final state `sessions.nvim` `1bfa3f8`,
ultracode-reviewed across 2 rounds, round 1 found a real anchor/shape
rendering defect, round 2 found a minor follow-up inconsistency in the
same fix, both resolved). **P5 done** (mode-colour wiring in this user's
own config — `nvim` config `a919264f`, live-verified against the real
statusline's own mode colours, not yet put through a dedicated ultracode
review round). **P6 done and reviewed** (`:Session stale`/`delete-stale`
— final state `sessions.nvim` `7ca6ad3`, ultracode-reviewed across 2
rounds; round 1 found a serious, live-reproduced correctness bug in
`branch_exists()`'s git-subprocess approach, round 2 found only two
low-severity notes on the filesystem-only rewrite — the packed-refs
field-boundary case, already folded into `7ca6ad3` itself, plus one
doc-comment wording nit left as-is). **P7 done and reviewed**
(configurable, icon-capable chip text — final state `sessions.nvim`
`39a098d`, ultracode-reviewed across 2 rounds; round 1 found the
`current_branch()`-on-a-hot-path bug in `chip_text.lua` itself plus two
smaller issues (`f39ae9c`), round 2 found the exact same hot-path bug
recurring in `sessions/marks/init.lua`'s `scope_key()` — fixed in
`39a098d`). **P2's live check (round 2, real terminal screenshots) found
two apparent bugs**, one real, one a misdiagnosis caught by a *third*
live check: an orange-then-turquoise startup colour race, real and
fixed (`St_<Mode>Mode` not yet defined when the chip's own P1 settle
pass wins its race against this config's `UIReady` wiring — `nvim`
config `ca926df4`, later corrected once more, see below); and a
`dock_left` left-edge gap that looked like a Neovim border-reservation
issue and got a `col = -1` fix plus an ultracode review (3 dimensions ×
3 adversarial verifiers; found and fixed a real HIGH incomplete-fix gap
and a MEDIUM staleness risk in that fix itself — `ui.nvim` `305e49b`,
`lib.nvim` `3296b7e`) — **but the whole diagnosis was wrong**: round 3's
live screenshots showed the fix had zero visible effect (identical pixel
position before/after), and the actual cause turned out to be this
user's own terminal emulator's `window_padding` setting, set
deliberately for an unrelated feature — outside anything Neovim can
reach. **Fully reverted** — `ui.nvim` `65f9032`, `lib.nvim` `83801f3` —
see P2's own section for the full account, including why the review
that found real bugs *in* the fix still didn't catch that the fix
itself was solving the wrong problem (adversarial review checks a
diff's own logic against the codebase; it has no way to know the
diff's premise doesn't match physical reality outside the code, which
only a live screenshot comparison can show). The colour-race fix's own
comment also got one correction along the way (`nvim` config
`54503920`, a pre-existing `ColorScheme`-staleness gap it had
overclaimed around) — that one stands, independent of the position
revert. **Live re-confirmation from the user, this time of the
now-correctly-scoped state (colour race fixed, position gap understood
as terminal padding, not a code bug), is what's left.**

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
  - [Shipped commits (ledger)](#shipped-commits-ledger)
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

**Status:** Partly done, 2026-09-28 — headless corroboration only; the
user's own live visual check is still open (see below, this is
fundamentally a "does it *look* right" question the original bug was
reported the same way).

~0.25 session. Repo: `sessions.nvim` (verification only, no code expected).

- Live-check Issue 1's original symptom (colour/position pop-in a few
  seconds after startup) is gone after P1. Issue 3 no longer needs
  re-confirming here — P0 already did, live, with real timers.

**As done (headless half):** reproduced the real `:LastSession` sequence
headlessly against the actual user config (`nvim --headless -u
<real init.lua>`, cwd `E:\repos\ui.nvim` so a real saved session exists to
load — `autoload` is off in this config, so `:LastSession` was called
explicitly to force the same load→`chip.refresh()`→`chip.pulse()` path
Issue 1/3 are about), instrumenting `VimEnter`/the settle-pass's own
`vim.schedule()` tick to sample the chip window's colour/position at each
step. Result: the chip picks up the pulse's warning colour
(`#e0af68`, tokyonight's orange) immediately on load, the new
`VimEnter` settle-pass correctly leaves it alone while the pulse is active
(`pulse_active` doing its job live, not just in the unit tests), and it
reverts to the steady colour (`#2ac3de`) deterministically within its
configured `duration_ms` — not "eventually, whenever some unrelated event
happens to fire", which is what made the original report read as an
arbitrary multi-second pop-in. Position (`row`/`col`) stayed constant
across every sample in this run, but that is expected and not conclusive
either way: headless Neovim never attaches a real terminal UI, so it can't
reproduce the specific "real terminal geometry settles a beat after the
process starts" half of Issue 1 that motivated the settle-pass in the
first place — only a real interactive session can.

**Caution for whoever repeats this kind of live headless check:** running
it against a real project's cwd with `:LastSession` + `qa!` **does**
trigger `sessions.nvim`'s real `VimLeavePre` autosave on quit, which
overwrote this machine's actual `ui-nvim_main` saved session (emptied its
buffer list, since the headless probe process itself had none open) —
not something the diagnosis needed and not something a plain unit test
harness would do. Prefer a scratch/throwaway cwd (or a config with
autosave disabled) for anything that calls `:LastSession` outside
`TESTS/`.

**Still open:** the user opening this config normally, in a real terminal,
and watching the corner chip at a real startup (ideally right after
`git pull`ing `ui.nvim`'s `c9fd0f3`/`lib.nvim`'s `cd9534f` into their local
checkouts) to confirm the pop-in they originally saw in screenshots is
actually gone end-to-end, position included.

**Live check, round 2 (2026-09-28, real terminal screenshots):** the user
did the live check the headless half above could not do, and it surfaced
two real, independent bugs the headless probe's own blind spots explain
exactly why neither one showed up there:

1. **Left-edge gap, not flush.** Two screenshots showed the docked chip's
   green content starting ~1 cell in from the real screen edge, not
   touching it. Root cause: `dock_left`'s border array leaves the left
   corners/edge as `""` (nothing drawn), but Neovim still reserves 1
   screen column for that position regardless of whether its char is a
   glyph or `""` (`:h nvim_open_win()`'s `border`; confirmed live with a
   real floating window opened at `col = 0` using this exact array — its
   first *visible* column landed one cell in from the real edge). The
   existing "flush left, no gap" test only ever asserted the *configured*
   `col` value (0, which was in fact correct) — it could never have caught
   this, since a reserved-but-blank border cell is invisible to
   `nvim_win_get_config()`, only to an actual rendered screen (which
   headless Neovim never attaches). Fixed: `reflow()` now uses `col = -1`
   for `dock_left` specifically, pushing the blank cell off-screen so the
   first real, visible column lands at the true edge. `ui.nvim` `96e695d`,
   `lib.nvim` `d2c8d49` (mirrored).
2. **Orange-then-turquoise on startup, not turquoise-from-the-first-paint.**
   The chip painted `ui.kit.chip`'s own "Special" fallback (amber/orange in
   this colourscheme) for roughly 1-2 seconds, then flipped to the real
   mode-accent colour. Root cause: P5's `chip.color` function reads
   `St_<Suffix>Mode`, which is only *defined* once
   `ui.statusline.highlights.ensure()` has run — and this config wires
   that in at `UIReady` (`VimEnter` + `vim.schedule()`,
   `config/ui_statusline/init.lua`), the exact same deferred pattern
   `ui.kit.chip`'s own P1 settle pass uses for its `VimEnter` re-resolve.
   Whichever of the two `vim.schedule()` callbacks happened to queue first
   won the race; the chip's settle pass won it, read an undefined group,
   got `nil`, and fell back to the default colour until whatever
   incidental dirty-tracking event or `ModeChanged` happened to refresh it
   next (real, human-timescale usage rather than any fixed delay — matches
   the "~1-2s" report far better than an instant VimEnter fix would). The
   headless corroboration above never caught this because it drove a
   `nvim --headless -u <real init.lua>` run against `ui.nvim`'s own repo,
   not `sessions.nvim`'s real chip.color wiring, and it sampled colour at
   the `VimEnter` settle tick specifically rather than checking what an
   *undefined* highlight group resolves to that early. Fixed: the colour
   function now calls `require("ui.statusline.highlights").ensure()`
   (idempotent, reads the live colourscheme fresh) before reading the
   group, closing the race outright regardless of load order — confirmed
   live (headless): calling the function before `ensure()` has ever run
   returns `nil` without the fix, a real `{fg,bg}` pair with it. `nvim`
   config `ca926df4`.

**Round-2 fixes, ultracode-reviewed (2026-09-28):** a multi-agent review
(3 dimensions — correctness, security, performance — each independently
verified by 3 adversarial skeptics per finding) checked `96e695d`/
`d2c8d49`/`ca926df4`. Security and performance: 0 findings. Correctness:
**3 confirmed findings, all live-reproduced, 0 refuted**:

1. **HIGH.** The `col = -1` compensation was scoped only to `reflow()`'s
   `docked` branch, but `docked` requires a bottom anchor **and** a
   visible statusline row. A `dock_left`-shaped chip anchored `top-left`,
   or `bottom-left` with `dock = true` but no statusline row visible
   (`laststatus = 0`, or `laststatus = 1` with a single window —
   `sessions.nvim`'s own shipped defaults under a lone window), fell into
   the *other* branch's unguarded `col = 0` and reproduced the exact gap
   `96e695d` was meant to close. Untested by the original fix's own new
   spec, which only exercised the `docked` branch.
2. **MEDIUM.** The offset was keyed on `entry.shape == "dock_left"` by
   *name*, not the actual resolved border. `theme.setup()` lets any
   consumer fully replace the `"dock_left"` preset at runtime; one doing
   so with a real left border glyph would still get `col = -1` and lose a
   column of their own border. Currently latent (no shipped consumer does
   this), but reachable by design of the preset-override system.
3. **LOW, pre-existing.** `resolve_colors()` always marks a table-valued
   `color()` result `themed = false`, so `ui.kit.chip`'s own `ColorScheme`
   re-tint handler (gated on `themed`) permanently skips this chip. A real
   `:colorscheme` switch during an idle session (no mode change, no
   buffer/window/tab churn) can leave it stale until an unrelated refresh.
   Predates `ca926df4` — that commit's own new comment just overclaimed
   "can never drift", which review caught and a follow-up commit corrected
   to state this gap accurately instead of fixing the underlying
   architecture (a `ColorScheme`-handler change was judged disproportionate
   for a low-severity, long-pre-existing gap).

**Fixed (at the time):** finding 1+2 together, by computing the
blank-left-border offset once from `entry.border`'s own left corners/edge
(indices 1, 7, 8) instead of the shape name, and applying it in both
`reflow()` branches — `ui.nvim` `305e49b`, `lib.nvim` `3296b7e` (mirrored,
`kit_drift_spec` confirmed this file in sync). Three new regression tests
(top-left anchor, degraded bottom-left-dock without a statusline row, a
`theme.setup()` override with a real border). Finding 3: comment
corrected, architecture left as a known, documented gap — `nvim` config
`54503920` (this one still stands, see below). Full `ui.nvim` suite green
(62/62 files) both before and after merging in a concurrent session's
unrelated `ui.kit` work (`c2da442`..`6d3a46a`, a clean merge, no
conflicts).

**Round 3 (live check, 2026-09-29): the whole `col = -1` diagnosis was
wrong.** The user sent a *third* round of live screenshots after
`305e49b` shipped, describing the chip as sitting even further wrong
("zu weit links... übersteht"). Direct pixel comparison this time,
instead of another speculative fix:

```
img1 (before 96e695d) row 760: ...(3,3,3)×10... (179,246,192)  -- content starts at x=11
img3 (after  305e49b) row 760: ...(3,3,3)×10... (224,175,104)  -- content ALSO starts at x=11
```

Identical screen column, before and after two rounds of "fixes" to
`col`. That is decisive: `col` was never the variable that mattered, so
every findings/fix cycle up to this point (`96e695d` → review → `305e49b`
→ another review) had been debugging the wrong layer — real, logically
sound findings about code that was solving a problem it didn't actually
have. Asked the user which terminal they view this in
([`AskUserQuestion`]): WezTerm. Grepped their `Configs` repo and found
`terminals/wezterm/config/experimental.lua:68`:

```lua
-- Padding in Zell-Einheiten statt Pixeln: WezTerm rechnet selbst um, das
-- Ergebnis ist damit per Definition ein glattes Vielfaches der Zellgröße.
-- Nötig, weil WezTerms OSC-1337-Bildplatzierung das Fenster-Padding nicht
-- mitrechnet -- bei einem Pixelwert, der keine ganze Zelle ist (vorher 9/8),
-- bleibt ein Sub-Zellen-Versatz, den kein Plugin ausgleichen kann.
-- Messprotokoll: images.nvim, docs/ROADMAP/TERMINALS.md.
Config.window_padding = { left = "1cell", right = "1cell", top = "1cell", bottom = "1cell" }
```

A full cell of padding on every side, set **deliberately**, for
`images.nvim`'s OSC-1337 image placement — matching the measured ~10-11px
gap exactly (one cell at this font size). This is WezTerm's own grid
inset, applied entirely outside anything Neovim draws into; no floating
window `col` value, on any shape, can reach into or compensate for
padding the terminal emulator adds around its whole grid from the
outside. The original "gap" was never a `ui.kit.chip`/Neovim bug at all.

**Why the ultracode review didn't catch this:** it couldn't have —
adversarial review checks a diff's logic against the rest of the
codebase (and it did real, valuable work: `305e49b`'s HIGH/MEDIUM fixes
were genuine bugs *in* `96e695d`'s own logic). It has no way to know a
diff's starting premise fails to match physical reality *outside* the
code (a specific user's terminal config) — only a live screenshot,
compared pixel-for-pixel against an earlier one, can show that. This is
exactly why P2 (a live human confirmation step) existed as its own phase
in this plan to begin with, separate from the ultracode gate the other
phases rely on.

**Reverted:** the entire `col = -1` compensation (and `border_left_is_blank()`)
removed, `reflow()` back to a plain `col = 0` for every left-anchored
shape including `dock_left` — `ui.nvim` `65f9032`, `lib.nvim` `83801f3`
(mirrored). The 4 dock_left/`col=-1` regression tests replaced with one
confirming `col = 0` for a docked `dock_left` chip too, locking in the
reverted (correct) behaviour rather than leaving no coverage. Full suite
green (62/62 files), `kit_drift_spec` confirms this file in sync.
`ca926df4`/`54503920` (the colour-race fix and its comment correction)
are unaffected and still stand — that diagnosis was independently
verified via a pure Lua-level headless proof (calling the function
before/after `ensure()`), not a screen-pixel-dependent claim, and
nothing in round 3 contradicts it.

**Open, for the user to decide, not for me:** the ~1-cell gap that
started this whole investigation is real, visible, and will stay
exactly as-is unless `window_padding` in
`terminals/wezterm/config/experimental.lua` changes — which trades away
whatever `images.nvim`/OSC-1337 benefit that setting exists for (see
that file's own comment and `docs/ROADMAP/TERMINALS.md` in the `Configs`
repo). Not touched here: this repo (`nvim` config here) has no
authority over the `Configs` repo, and the tradeoff is a personal
preference call, not a bug to fix.

### P3 — ui.kit.chip: docked-left preset + function-valued colour + mode-track hook

**Status:** Done and reviewed — 2026-09-28. Final state: `ui.nvim`
`276b05f`, `lib.nvim` `387a666` (mirrored, `kit_drift_spec.lua` clean).
ultracode-reviewed across 2 rounds: round 1 (3 dimensions, adversarially
verified) found and got a real, live-reproduced fix; round 2: 0 findings.
Full suite green in both repos afterward (the same two pre-existing,
already-documented failures aside: `ui.nvim`'s `context_languages_spec.lua`
kotlin case, `lib.nvim`'s `git_sync_spec.lua` async-timing test — neither
touched by this work).

**As done**, items 1–4 landed close to the plan below, with three review
fixes on top of the first pass (`667b1be`/`fe803c8` → `276b05f`/`387a666`):

- Preset named `dock_left` (not `dock`, which became the separate
  `chip.mount()` boolean opt instead — see item 2): `ui/kit/theme.lua`'s
  `BUILTIN` table gains `dock_left = { border = { "", "─", "╮", "│", "╯",
  "─", "", "" } }`, exactly the array this section already specified.
  Also fixed `theme.lua`'s `border_glyphs()` (the static preset-preview
  helper) to read glyphs straight out of any raw 8-element border array
  instead of only recognizing the hardcoded `"ascii"` case — otherwise
  `dock_left`'s own preview would have silently shown `"single"`'s glyphs.
- `chip.mount()` gained `opts.dock` (boolean, nil-checked like `visible`)
  and `reflow()` special-cases it exactly as planned — row on the
  statusline row, col 0, degrading to the ordinary placement without a
  statusline row. A docked entry also no longer advances the corner's
  `offset` accumulator (it doesn't occupy a stacked slot at all) — a
  review finding, low severity (extra spacing only, never an overlap with
  the pre-fix code), fixed anyway.
- `resolve_colors()` accepts a zero-arg function, resolved fresh every
  call — used by every one of its callers automatically (`M.refresh()`,
  `M.pulse()`, the `ColorScheme`/`VimEnter` handlers) without touching
  each call site.
- `chip.mount()` gained `opts.track_mode` (boolean); a new
  `ensure_mode_tracking()` registers/tears down a **per-entry** `ModeChanged`
  autocmd (its id stored on the entry, deleted on `M.unmount()` or when
  `track_mode` flips back off).
- **Review round 1's finding, severity high, live-reproduced:**
  `ensure_mode_tracking()` first called `autocmd.group("UiKitChip", true)`
  — re-requesting an *already-existing* group with `clear = true` re-clears
  it (`lib.nvim.bindings.autocmd`'s own documented behaviour), silently
  wiping every autocmd already in it — `ensure_hooks()`'s own
  `VimResized`/`TabEnter`/`ColorScheme`/`VimEnter`, and any *other* chip's
  own `ModeChanged` tracker — the moment **any** chip opted into
  `track_mode`. No error, nothing logged; chips would just silently stop
  re-tinting/repositioning/following tabs for the rest of the session.
  Exactly the hazard `ui.kit.picker` already documents for itself (its own
  comment on why it suffixes its group name per-window rather than reusing
  one shared name with `clear = true`). Fixed by dropping the `true` —
  `ensure_hooks()` already creates/clears the group once.
- Same round also flagged `entry.border`'s new shape-keyed caching
  (an optimization added to avoid a `theme.resolve()` deep-copy on every
  `refresh()`) as capable of going stale if a preset is redefined at
  runtime via `theme.setup({presets=...})` without the chip's own shape
  changing — removed the caching entirely rather than adding a
  generation-counter fix; `theme.resolve()`'s deep-copy is negligible next
  to `resolve_colors()` already doing comparable work on every `refresh()`.
- Item 5 (tests): `TESTS/ui_kit_chip_spec.lua` grew 6 new specs (border
  shape, dock row/col — compared directly against a non-docked chip's own
  placement rather than hand-computed arithmetic, so it doesn't silently
  drift from the real formula — function-colour freshness, `track_mode`'s
  exactly-one-extra-refresh, and a regression spec for the group-clear
  finding: snapshot every autocmd id in the shared group, enable
  `track_mode` on a second chip, assert every pre-existing id survived).
  Confirmed the group-clear spec fails against the pre-fix commit
  (reverted locally, ran the suite, restored) before committing the fix.
- **Architecture call from this section's own write-up, followed as
  written:** `ui.kit.chip`/`ui.kit.theme` stayed statusline-agnostic — no
  `St_<Mode>Mode` awareness anywhere in `ui.nvim`. That wiring is P5's job,
  in this user's own config.

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

**Status:** Done and reviewed — 2026-09-28. Final state `sessions.nvim`
`1bfa3f8`. ultracode-reviewed across 2 rounds: round 1 found a real,
confirmed rendering defect (below), round 2 found one more minor
follow-up inconsistency in that same fix, both resolved.

~0.5 session. Repo: `sessions.nvim`.

- `config/DEFAULTS.lua`: document the new dock preset as an allowed
  `chip.shape` value. Per the user's own ask ("als Default-Preset"), make
  it `sessions.nvim`'s actual default — the degrade-safely behaviour from
  P3 step 2 is exactly what makes this safe to default without breaking
  anyone not running `ui.nvim`'s statusline.
- Update `docs/configuration.md`/`docs/statusline.md` accordingly.

**As done**, plus two review fixes: `chip.shape` defaults to `"dock_left"`
and `chip.dock` to `true` (both landed together, `bc74979`) — the plan
above only mentions `shape`, but per the original request ("sitting flush
against it, not floating with a gap above") the shape alone does not
deliver the fused-with-the-statusline look without `dock` too.

- **Round 1 finding, confirmed:** `"dock_left"`'s left-side border is only
  correct paired with a left anchor (`bottom-left`/`top-left`, the
  default) — a right-side anchor (`bottom-right`/`top-right`, both
  documented, first-class values, and the latter was this plugin's own
  *old* default) left it rendering backwards: the blank edge facing into
  the screen, the rounded edge touching nothing. `sessions/chip.lua`
  gained `effective_shape(anchor, shape)`, forwarding `"rounded_chip"`
  instead whenever `shape == "dock_left"` and `anchor` isn't a left one —
  scoped to exactly that shape; an explicit `"chip"`/`"classic"` override
  passes through untouched. Fixed in `c022fb5`.
- **Round 2 finding, confirmed (minor):** that same fallback checked the
  *raw*, unvalidated `cfg.chip.anchor` string against exactly
  `"bottom-left"`/`"top-left"` — but config validation accepts any string
  unchecked, and `ui.kit.chip.mount()` itself resolves an unrecognized
  anchor to `"bottom-left"`. A typo'd anchor therefore fell back to
  `"rounded_chip"` even though the chip actually ends up anchored
  bottom-left, where `"dock_left"` would have been correct. Harmless
  (`rounded_chip` never renders backwards), but real. Fixed in `1bfa3f8`
  by resolving an unrecognized anchor to `"bottom-left"` first, matching
  `ui.kit.chip`'s own fallback exactly.

### P5 — This config: wire mode-colour tracking for the session chip

**Status:** Done — 2026-09-28. `nvim` config `a919264f`. Live-verified,
not yet put through a dedicated ultracode review round (a small, single-
file config change calling already-reviewed primitives from P3 — `chip.
color`/`track_mode` — and an already-existing helper this config's own
statusline already relies on; low enough risk that a round is optional
here, not skipped by oversight).

~0.25 session. Repo: this nvim config (`C:\Users\bartl\AppData\Local\nvim`).

- `lua/plugins/personal/init.lua`'s `sessions.nvim` spec: add
  `chip = { shape = "<new dock preset>", track_mode = true, color =
  function() ... end }`, mapping `vim.fn.mode()` through
  `ui.statusline.utils.primitives.modes`'s suffix table to build the
  matching `St_<Suffix>Mode` group name. Visually confirm it against the
  live editor — the "hellgrün Normal / türkis-ish Insert" look from the
  user's own screenshots — not just the automated tests, since this is
  fundamentally a visual-fit feature.

**As done:** `shape`/`dock` are left unset (P4 made `"dock_left"`/`true`
sessions.nvim's own defaults, so nothing to override here). `chip.color`
is a function calling `ui.statusline.modules.highlighting.mode_band_group()`
(the exact helper the real statusline's own mode pill already resolves its
colour through, `St_<Suffix>Mode`, already cached/invalidated on
`ModeChanged`) and returns that group's `{fg,bg}` pair verbatim — not the
group *name*, which `ui.kit.chip` would only tint the `fg` of rather than
use the actual accent `bg` the statusline pill shows. `track_mode = true`
alongside it. Live-verified headlessly against the real config (from a
throwaway scratch cwd, not a tracked project — see the caution below):
Normal `bg = #b3f6c0` (light green), Visual `bg = #1abc9c` (teal) — both
confirmed to match `St_NormalMode`/`St_VisualMode` exactly by calling
`cfg.chip.color()` directly and comparing. Insert (`#0db9d7`, turquoise)
and the others were read directly off the materialized highlight groups
rather than actually entered (headless keystroke simulation cannot
reliably enter insert/replace/etc.), matching the "hellgrün Normal /
türkis Insert" look from the original screenshots.

**Caution for whoever repeats this kind of live check:** the first probe
attempt ran from `E:\repos\ui.nvim` (to force a real session load) and
its `qa!` triggered `sessions.nvim`'s real `VimLeavePre` autosave,
overwriting that project's actual `ui-nvim_main` saved session with an
empty buffer list — not something this diagnosis needed. The second,
corrected attempt ran from a scratch temp directory instead (no tracked
project, so nothing of value to overwrite even if autosave fires) and
avoided the repeat.

### P6 — sessions.nvim: surface (and optionally clean up) stale sessions

**Status:** Done and reviewed — 2026-09-28. Final state `sessions.nvim`
`7ca6ad3`. ultracode-reviewed across 2 rounds: round 1 (on the first
implementation, `1efe68e`) found a serious, live-reproduced correctness
bug in the staleness check itself; round 2 (checking the rewrite that
replaced it, `7ca6ad3`) found only two low-severity notes — the
packed-refs field-boundary case (a branch name embedding the literal
substring `refs/heads/` as a path component) was already handled by the
shipped `needle = " refs/heads/" .. branch` check, and one doc-comment
wording nit left as-is, neither worth another commit on its own.

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

**As done**, `:Session stale`/`:Session delete-stale` landed as named
(`1efe68e`), with `sessions.git.branch_exists(cwd, branch)` as the
detection primitive and `find_stale()` (a local helper in
`bindings/usercmds/init.lua`) as the collector, exactly as planned. The
detection primitive itself needed a full rewrite after review, though:

- **Round 1 finding, confirmed, high severity, live-reproduced:** the
  first `branch_exists()` went through `lib.nvim.git`'s
  `in_git_repo()`/`refs()` (real `git` subprocess calls) and tried to
  keep the "ambiguous is not the same as confirmed-gone" guarantee this
  plan itself calls for by catching a *raised* Lua error via `pcall` — on
  the theory that a failed lookup would raise. It does not: the real
  `lib.nvim.git` swallows *every* subprocess failure (a missing `git`
  binary, a `safe.directory` refusal, a stale/disconnected network mount
  the worktree used to live on, a corrupted pack, ...) into a plain
  `false`/empty table and never raises — so the "ambiguous" branch was
  dead code in production. A purely transient git failure on a perfectly
  healthy, still-checked-out session read as confirmed-stale, and
  `delete-stale` could then permanently delete it after one confirm.
  Live-reproduced (a fake failing `git` on PATH flipped a real, existing
  branch's answer from `true` to `false`).
- **Fix, `7ca6ad3`:** `branch_exists()` rewritten to be purely
  filesystem-based — no `git` subprocess at all. A new `find_gitdir()`
  (shared with `current_branch()`'s own existing fallback in the same
  file, which already avoids spawning `git` for an unrelated reason — the
  hot "every session name resolution" path) walks upward for `.git`,
  follows a worktree's `.git` FILE redirect, and `branch_exists()` then
  checks for a loose `refs/heads/<branch>` file or a matching line in
  `packed-refs`. No external binary to be missing, refuse, or hang on —
  this eliminates the whole class of failure round 1 found, not just its
  specific manifestation, and (as a side effect) also closes a smaller
  round-1 finding about `lib.nvim.git` itself being an optional,
  soft-guarded submodule per this project's own docs/health check, which
  the first version's "lib.nvim is a hard dependency" reasoning had
  wrongly conflated with the whole `lib.nvim` package.
- Tests rewritten to match: real hand-written `.git` fixtures (a loose
  ref, `packed-refs` including a same-named *tag* to confirm branch/tag
  disambiguation, a worktree `.git`-file redirect, an upward walk from a
  subdirectory, a real empty repo with zero refs) instead of stubbing
  `lib.nvim.git` with failure modes the real dependency cannot actually
  produce (which is exactly what let the original bug through
  undetected).

### P7 — sessions.nvim: configurable, icon-capable chip text

**Status:** Done and reviewed — 2026-09-28. Final state `sessions.nvim`
`39a098d`. ultracode-reviewed across 2 rounds: round 1 (`89edc35` →
`f39ae9c`) found `chip_text.lua`'s "modern" default calling the
subprocess-spawning `sessions.git.current_branch()` on every `ui.kit.chip`
refresh (an editing-rate hot path) plus two smaller issues (a
packed-refs-style field-boundary gap in the placeholder regex, and a
`%w`-vs-`_` placeholder-matching typo); round 2 (checking `f39ae9c`)
found the exact same hot-path hazard recurring one call away, in
`sessions/marks/init.lua`'s `scope_key()` — fixed in `39a098d`, plus a
regression test stubbing `sessions.git.current_branch` to raise if
called, asserting only `current_branch_no_spawn()` runs. A further check
of `39a098d` itself was judged disproportionate: it repeats an
already-twice-reviewed fix shape (swap `current_branch()` for
`current_branch_no_spawn()`) verbatim, with its own passing regression
test.

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

**As done**, landed close to the plan, with two resolutions the plan
itself left open:

- **Default icon glyphs (Open question 7, resolved):** `folder` is
  neo-tree's own built-in `folder_closed` default (U+E5FF) — this user's
  *own* neo-tree spec (`plugins/neotree.lua`) currently overrides that
  same field to an empty string, which turned out to be the exact same
  silent-glyph-loss accident this whole convention exists to avoid (see
  below), confirmed by reading its raw bytes; unrelated to this feature
  and not this module's place to fix, so used neo-tree's own intended
  default instead of the corrupted override. `branch` matches
  `ui.statusline.utils.primitives`'s own `ICON_GIT_BRANCH` (U+EA68)
  exactly, for visual consistency with what this user's own statusline
  already shows elsewhere — a stronger match than just "conventional".
  Both byte-escaped in source (`"\xEE\x97\xBF"`/`"\xEE\xA9\xA8"`), not
  literal glyphs — the exact same convention `ICON_GIT_BRANCH` itself
  already uses, after a private-use-area glyph pasted straight into a Lua
  file there once silently stripped to nothing going through some
  editor/tool. Writing this handover's own two doc examples hit that
  *exact* failure live while drafting them (one glyph substituted for a
  different, wrong codepoint; the other silently vanished to zero bytes)
  — independent, live corroboration of exactly the risk that convention
  exists to guard against, caught and fixed by re-deriving the correct
  bytes programmatically rather than trusting what had been typed.
- **"modern"'s shape is one line per part that resolved, not always
  two:** the plan's own step 3 says "two lines via `\n`" as the default
  shape, but implemented as one icon-prefixed line per part that
  *actually* resolved instead (`branch_aware = false`, or a detached
  HEAD, means just the folder line) — matching Issue 6's own explicit
  "rather than showing an icon next to something that isn't really a
  folder/branch pair" reasoning more precisely than a fixed two-line
  template would (which would still render an icon next to an empty
  string for whichever half is missing). An *explicit* custom `template`
  still renders literally even with one part empty, since that is the
  caller's own layout, asked for outright — the omit-the-line behaviour
  is specifically "modern"'s own built-in shape, not the module's only
  option.
- `config/init.lua`'s `KNOWN.chip` gained `text = true` (an unvalidated
  leaf, same as `color`) rather than a nested per-field schema — `icons`
  only ever needs the keys a caller wants to override, which a fixed
  schema would fight rather than help.

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

## Shipped commits (ledger)

Archive of every commit this handover's work has produced, reviewed and
pushed — kept here so a chat's own running commit list only has to show
what's new *this* session instead of re-listing everything again each
turn. Intermediate commits superseded by a same-phase follow-up fix are
marked as such rather than dropped, since the follow-up commit messages
reference them by SHA.

| Repo | Commit | Phase | Description | Review |
| --- | --- | --- | --- | --- |
| `ui.nvim` | `a78b319` | P0 | `resolve_visible()` ternary bug fix (Issue 3) | ✅ 0 findings |
| `lib.nvim` | `2cd6bc3` | P0 | mirror of `a78b319` | ✅ 0 findings |
| `ui.nvim` | `746d510` | P1 | settle pass + pulse-revert fix v1 | ✅ (superseded by `c9fd0f3`) |
| `lib.nvim` | `c48b460` | P1 | mirror of `746d510` | ✅ (superseded by `cd9534f`) |
| `ui.nvim` | `249800e` | P1 | pulse-revert generation counter | ✅ (superseded) |
| `lib.nvim` | `cece91c` | P1 | mirror of `249800e` | ✅ (superseded) |
| `ui.nvim` | `8d5f071` | P1 | pulse-revert entry-table identity | ✅ (superseded) |
| `lib.nvim` | `ceaac1a` | P1 | mirror of `8d5f071` | ✅ (superseded) |
| `ui.nvim` | `dc704be` | P1 | `pulse_active` guard (refresh/mount) | ✅ (superseded) |
| `lib.nvim` | `077658b` | P1 | mirror of `dc704be` | ✅ (superseded) |
| `ui.nvim` | `c9fd0f3` | P1 | `open_window()` syncs `pulse_active` — **final** | ✅ 5 rounds, 0 findings on the last |
| `lib.nvim` | `cd9534f` | P1 | mirror of `c9fd0f3` — **final** | ✅ same |
| `nvim` (config) | `3c480aa7` | P1 | this handover, marked P1 done | ✅ docs-only |
| `nvim` (config) | `ed2c1f55` | P1 | added this ledger section | ✅ docs-only |
| `nvim` (config) | `304a7e3b` | P2 | headless corroboration documented, live check flagged open | ✅ docs-only |
| `ui.nvim` | `667b1be` | P3 | dock preset + function-colour + mode-track, first pass | ✅ (superseded by `276b05f`) |
| `lib.nvim` | `fe803c8` | P3 | mirror of `667b1be` | ✅ (superseded by `387a666`) |
| `ui.nvim` | `276b05f` | P3 | group-clear + preset-staleness + dock-offset fixes — **final** | ✅ 2 rounds, 0 findings on the last |
| `lib.nvim` | `387a666` | P3 | mirror of `276b05f` — **final** | ✅ same |
| `nvim` (config) | `5f88892f` | P3 | this handover, marked P3 done | ✅ docs-only |
| `sessions.nvim` | `bc74979` | P4 | `chip.shape`/`dock` default to `"dock_left"`/`true` | ✅ (superseded by `c022fb5`) |
| `sessions.nvim` | `c022fb5` | P4 | anchor/shape fallback fix — round-1 finding | ✅ (superseded by `1bfa3f8`) |
| `sessions.nvim` | `1bfa3f8` | P4 | invalid-anchor resolution fix — round-2 finding — **final** | ✅ 2 rounds |
| `sessions.nvim` | `1efe68e` | P6 | `:Session stale`/`delete-stale`, first pass | ✅ (superseded by `7ca6ad3`) |
| `sessions.nvim` | `7ca6ad3` | P6 | `branch_exists()` rewritten filesystem-only — **final** | ✅ round 1 found the bug this fixes; round 2 pending |
| `sessions.nvim` | `89edc35` | P7 | configurable, icon-capable chip text, first pass | ✅ (superseded by `f39ae9c`) |
| `sessions.nvim` | `f39ae9c` | P7 | `current_branch_no_spawn()` hot-path fix + 2 smaller fixes — round-1 finding | ✅ (superseded by `39a098d`) |
| `sessions.nvim` | `39a098d` | P7 | same hot-path fix applied to `marks.scope_key()` — round-2 finding — **final** | ✅ 2 rounds |
| `nvim` (config) | `a919264f` | P5 | mode-colour wiring for the session chip | ✅ live-verified, no dedicated review round |
| `nvim` (config) | `067c7c46` | P6/P7 | handover updated, P6/P7 marked done and reviewed | ✅ docs-only |
| `ui.nvim` | `96e695d` | P2 (live check round 2) | `dock_left` shifts `col = -1` for its invisible left border, first pass | ✅ (superseded by `305e49b`, later reverted) |
| `lib.nvim` | `d2c8d49` | P2 (live check round 2) | mirror of `96e695d`, first pass | ✅ (superseded by `3296b7e`, later reverted) |
| `nvim` (config) | `ca926df4` | P2 (live check round 2) | `chip.color` forces `St_<Mode>Mode` via `highlights.ensure()` — **final, stands** | ✅ 1 round, 0 correctness findings on this commit itself |
| `ui.nvim` | `305e49b` | P2 (live check round 2) | `dock_left` offset covers the else branch + keys on border | ✅ 1 round, 3 confirmed findings (1 HIGH, 1 MEDIUM, 1 LOW) fixed — **later reverted, round 3 found the whole diagnosis wrong** |
| `lib.nvim` | `3296b7e` | P2 (live check round 2) | mirror of `305e49b` | ✅ same — **later reverted** |
| `nvim` (config) | `54503920` | P2 (live check round 2) | `chip.color` comment corrected (LOW finding on `ca926df4`) — **final, stands** | ✅ same review round |
| `ui.nvim` | `65f9032` | P2 (live check round 3) | revert: drop `col = -1` entirely, real cause was WezTerm's own `window_padding` — **final** | ✅ live pixel-comparison proof, no ultracode round needed (a revert to prior-reviewed behaviour) |
| `lib.nvim` | `83801f3` | P2 (live check round 3) | mirror of `65f9032` — **final** | ✅ same |

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
