# Testing learn-cli.nvim

How to manually test every implemented feature of `learn-cli.nvim`. One-time
setup, then one section per feature: prerequisites, steps, what to expect.
Checkbox syntax (`- [ ]`) throughout.

Repo: `E:\repos\learn-cli.nvim`. Spec: `plugins/personal/init.lua` (`lazy =
false`, `config()` calls `require("learn_cli").setup({ exercises_path = ... })`
— fixed 2026-08-28, was `exercises_dir`, see §1)
— **but** `plugins/personal/source.lua` lists this repo as `["learn-cli.nvim"]
= "disabled"`, which sets `spec.enabled = false` unconditionally (a repo-level
`"disabled"` wins over everything, per that file's own `resolve()`). Net
effect: **this plugin never loads on this machine, full stop** — not lazy, not
deferred, actually `enabled = false`. That matches the telemetry report
exactly: no telemetry file at all, in either dataset, over the plugin's whole
lifetime — the strongest possible "never loaded" signal, and this is why.

## Setup

To test any of this you first have to make it load. Two ways, least to most
invasive:

1. Temporarily comment out the `["learn-cli.nvim"] = "disabled"` line in
   `plugins/personal/source.lua`'s `plugins.modes({...})` table (defaults the
   repo to `"dir"`), restart Neovim.
2. Or bypass the plugin system for this session only:
   ```lua
   :lua vim.opt.rtp:prepend("E:/repos/learn-cli.nvim")
   :lua require("learn_cli").setup({ exercises_path = vim.fn.stdpath("config") .. "/learn_cli_exercises" })
   ```

**Use option 2's config key deliberately** — see §1 below, it's the actual
first thing to check.

---

## 1. Config key mismatch — fixed 2026-08-28, confirm the real path is now used

**Was a real bug, now fixed — this section is a regression check, not an
open question.** `plugins/personal/init.lua` used to call:

```lua
require("learn_cli").setup({
  exercises_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "plugins", "learn-cli.nvim", "exercises"),
})
```

But `lua/learn_cli/config/init.lua`'s `M.setup()` only ever reads
`user_config.exercises_path` — `exercises_dir` was never checked, so the
option was silently dropped and `M.exercises_path` stayed at its hardcoded
default, `stdpath("config") .. "/exercises"`. Fixed by renaming the spec's
key to `exercises_path`.

**Note**: this plugin is still `["learn-cli.nvim"] = "disabled"` in
`source.lua` (see intro above) — that's a deliberate, separate choice, left
untouched. The `exercises_path` fix only matters once/if the plugin is
re-enabled.

**Steps** (after enabling the plugin per Setup above, using the real spec —
i.e. actually go through `plugins/personal/init.lua`, not the manual
`exercises_path=` workaround)

```vim
:lua print(require("learn_cli.config").exercises_path)
```

**Expect**: prints `<config>/lua/plugins/learn-cli.nvim/exercises` — the path
the spec actually intends, not the hardcoded `<config>/exercises` default.
Then `:LearnCLIDashboard` — since that directory doesn't exist yet either,
still expect the "No exercise loaded" state (§3) and a `WARN` notify on
setup ("Exercises path does not exist: ...") — but now pointing at the
*intended* path, which is the correct failure mode to scaffold from, not a
silently wrong one.

---

## 2. First run: `:LearnCLICreateCycle` — there is no content until you make it

Per `docs/WORKFLOW.md`, the plugin ships **no** built-in cycle — this is not
optional setup, it's required before anything else in this checklist can show
real data.

**Steps**

```vim
:LearnCLICreateCycle cycle_01
```

**Expect**: notifies "Creating cycle template: cycle_01..." then "Cycle
template created: <path>/cycles/cycle_01". Check on disk: `metadata.yaml` at
the cycle root, `iteration_1/day_01/` through `iteration_3/day_07/` (3
iterations × 7 days = 21 day-folders), each with an `exercises.yaml`
containing two starter exercises (`grep`, `find`) and four
`info_{a,b,c,d}.md` stubs, plus a shared `references/commands/{grep,find,
sed,awk,echo}.md` created once at the cycle-set level (not per day).

**Also check** re-running the same command a second time with the same name —
should not error or silently overwrite in a way that loses hand-edited
content (confirm what actually happens: overwrite, skip, or error).

**Tab-completion**: `:LearnCLICreateCycle <Tab>` only ever offers the three
literal strings `cycle_01`/`cycle_02`/`cycle_03` (hardcoded in
`commands.lua`, not derived from existing cycles on disk) — confirm this
doesn't look like it's discovering real cycle names.

---

## 3. Dashboard — `:LearnCLIDashboard` / `<leader>ld`

**Steps**

```vim
:LearnCLIDashboard
```

**Expect**: a centered floating window showing the active cycle's
name/description/difficulty, a day progress bar, the current exercise's
title/command/description, and a static keybindings cheat-sheet. `q` closes
it. Run the command again while it's open — should close it (toggle), not
stack a second float.

**In-buffer keys** — `n`/`p` inside the dashboard step to the next/previous
exercise and refresh the view **in place** (per `docs/WORKFLOW.md`, these are
literally the same code path as `:LearnCLINext`/`:LearnCLIPrev`, not a
separate in-dashboard counter) — confirm stepping with `n` here and later
running `:LearnCLINext` from a normal buffer continue the same sequence
rather than resetting.

---

## 4. Exercise navigation — `:LearnCLINext` / `:LearnCLIPrev` / `<leader>ln` / `<leader>lp`

**Steps**

```vim
:LearnCLINext
:LearnCLIPrev
```

**Expect**: each prints `Exercise N/M` via `vim.notify` and, if the dashboard
is open, refreshes it. At the last exercise of the day, `:LearnCLINext` says
"Last exercise of the day" instead of wrapping past the end; symmetrically
`:LearnCLIPrev` at the first says "First exercise of the day". Confirm
neither actually moves past the boundary (re-run `:LearnCLIInfo` to check the
counter didn't change).

---

## 5. Cycle info — `:LearnCLIInfo`

**Steps**

```vim
:LearnCLIInfo
```

**Expect**: a `vim.notify` block with the cycle name/description and
Day/Iteration/Exercise counters as `current/total` on each line — cross-check
the numbers against what §4's navigation just did.

---

## 6. Progress reset — `:LearnCLIReset`

**Steps**

```vim
:LearnCLIReset
```

**Expect**: a yes/no confirm dialog (`lib.nvim.ui.kit.confirm`, "Reset all
progress?"). Decline first — confirm nothing changes. Accept — the
day/iteration/exercise counters rewind to 1 and that day's exercises reload;
the dashboard refreshes if open.

**The concrete claim to verify** (from `docs/WORKFLOW.md`): despite the
prompt's wording, this **only** resets position counters — the
scoring/persistence subsystem (`core/scorer.lua`, `core/scoring.lua`,
`data/persistence.lua`) is real code in the tree but never wired into
`setup()`. There is no score/streak/history to actually check survives or
resets, since none is tracked live — confirm there's genuinely no state file
being written anywhere under `stdpath("data")/learn_cli/` after normal use
(§2-§5), which would indicate persistence is silently live after all.

---

## 7. Hand-editing exercise YAML — the naive parser's real limits

Per `docs/WORKFLOW.md`, `state.lua`'s `parse_yaml_simple` is a one-line
`key: value` matcher, not real YAML — no nesting, no list syntax.

**Steps**

1. Open a generated `exercises.yaml` (from §2) and edit the `hints:` field
   to use real YAML list syntax:
   ```yaml
   hints:
     - "first hint"
     - "second hint"
   ```
2. Save, `:LearnCLIReset` (or navigate to reload that day), `:LearnCLIInfo` /
   open the dashboard.

**Expect**: the hints silently fail to load as a list (missing or malformed
in whatever the dashboard/info view shows) — **no parse error** — this is the
documented sharp edge, confirm it reproduces exactly as described rather than
something worse (a crash) or something better (it turns out to parse fine).
Revert the edit back to flat `key: value` afterward.

---

## What cannot be checked here, and why

- **README vs. actual command surface.** The top-level `README.md` documents
  a considerably larger plugin — `:LearnCliStart`, `:LearnCliStats`,
  `:LearnCliExport`/`Import`, a terminal-integrated exercise view,
  spaced-repetition scheduling. None of these exist under those names in the
  current `lua/` tree; the real commands are the six covered above
  (`LearnCLIDashboard`/`Next`/`Prev`/`Info`/`Reset`/`CreateCycle`). Nothing to
  test here — just don't go looking for the README's command table and
  conclude something is broken when it's actually just aspirational
  (`docs/padagogical-concept.md` is the design target, not current state).
- **The unwired subsystem** (`core/exercise_runner.lua`, `core/validator.lua`,
  `core/scorer.lua`/`scoring.lua`, `data/persistence.lua`,
  `ui/exercise_view.lua`) — real, substantial code that no command or keymap
  currently reaches. Not testable through the UI because there is no UI path
  into it yet.
