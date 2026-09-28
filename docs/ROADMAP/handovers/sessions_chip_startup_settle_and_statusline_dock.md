# sessions.nvim chip: startup settle, auto-hide, statusline-docked default — handover

Status: **Planned (2026-09-28). Nothing built yet.** Designed 2026-09-28,
from four issues the user spotted live (screenshots) after the chip
preset/session-pin work shipped, plus a fifth ("why so many saved
sessions") added the same day.

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

`schedule_hide()`/`hide_generation`
([`sessions/chip.lua:59-82`](E:\repos\sessions.nvim\lua\sessions\chip.lua))
reads correctly on a static pass: every `pulse()`/`ensure_mounted()` call
reschedules one hide, guarded against an earlier, now-stale one firing
late. `M.refresh()` (chip.lua lines 119-127, wired to the dirty-tracking
events) does **not** reschedule or cancel the hide — so on paper the 3s
timer should fire regardless of ordinary editing activity.

Best current hypothesis: **the same mechanism as Issue 1.** I cannot find,
from reading the code alone, a path that actually *prevents* the 3s hide
firing — so before writing a fix, this needs a **live reproduction**
(P0 below), not a guess. If Issue 1's settle-pass fix (P1) also happens to
resolve this (plausible: a late, unrelated `M.refresh()` could be
re-showing/re-drawing the chip in a way that looks like "never hid"), P2 is
a confirmation step, not new code.

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

## Plan, phased

### P0 — Diagnose Issue 3 live

~0.25 session. Repo: none (a live nvim session with the real config).

- Reproduce with the actual config: start Neovim, run `:LastSession` (or
  let autoload fire, whichever matches the user's real workflow),
  instrument `schedule_hide()`/`hide_generation`
  ([`sessions/chip.lua:65-82`](E:\repos\sessions.nvim\lua\sessions\chip.lua))
  with a temporary `vim.notify`/debug log to see: does the 3s deferred
  callback ever actually fire? If it fires, what re-shows the chip
  afterward (which event, calling which function)? This confirms or
  refutes the "same root cause as Issue 1" hypothesis *before* writing a
  fix for it.

### P1 — ui.kit.chip: post-startup settle pass + pulse-revert fix

~0.5 session. Repo: `ui.nvim`. Fixes Issue 1, likely Issue 3.

1. Add a one-time (`once = true`) handler in
   [`ensure_hooks()`](E:\repos\ui.nvim\lua\ui\kit\chip.lua) (lines
   432-465) for `VimEnter` (or `UIEnter` — pick whichever P0's
   instrumentation shows fires more reliably after the real settle point)
   that, wrapped in `vim.schedule()` (or a short `vim.defer_fn` if a
   single scheduled tick proves too early — decide from real
   measurements, not a guess), re-resolves colours **and** calls
   `reflow()` for every currently mounted chip. Same shape as the existing
   `ColorScheme` handler (lines 450-464) — "re-settle everything" — just
   triggered by "Neovim's own startup finished" instead of "the
   colorscheme changed".
2. Fix `M.pulse()`'s revert-callback stale-window guard (lines 621-627):
   compare against the **current** `chips[id].win` at revert time, not the
   `win` local captured when the pulse started, so a text/width-driven
   window replacement mid-pulse can no longer leave a chip stuck in its
   pulse colour.
3. Tests (`TESTS/ui_kit_chip_spec.lua`): a regression spec that pulses a
   chip, closes+reopens its window mid-pulse (simulating the width-change
   race), and asserts the colour still reverts to the steady one; a
   VimEnter-settle spec asserting `reflow()`/recolour runs once after the
   event fires (and is genuinely deferred, not synchronous with the
   autocmd).

### P2 — sessions.nvim: confirm Issue 3

~0.25 session. Repo: `sessions.nvim` (verification only, code only if P1 turns out insufficient).

- Re-run P0's live repro against the P1 build. If the hide still does not
  fire, escalate with fresh instrumentation — do not guess a second fix
  blind.

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
5. P0/P2's live-diagnosis steps mean P1's exact fix (VimEnter vs UIEnter,
   `vim.schedule()` vs a short `vim.defer_fn`) is provisional until that
   data comes back — do not implement P1 blind without running P0 first.
6. P6's staleness check re-derives the branch from the session's recorded
   `cwd`, not from the session *name* (name-parsing a `<project>_<branch>`
   string back apart is ambiguous whenever either half itself contains an
   underscore — e.g. `nvim-usercmds-env-vars-3560c9_claude-cursor-jump-save-1f9524`
   above has underscores on both sides of the real project/branch split).
   Confirm `sessions.meta`'s stored `cwd` is reliably the right directory
   to re-run the branch lookup from (it should be — `cwd` is captured at
   save time from wherever the session was actually saved from) before
   building on that assumption.

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
