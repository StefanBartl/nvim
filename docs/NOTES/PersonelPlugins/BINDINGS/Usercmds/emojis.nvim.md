# emojis.nvim — User Commands Cheatsheet

One command tree, built via `lib.nvim.bindings.usercmd.composer` (migrated
2026-07-20). **First hard `lib.nvim` dependency this repo has ever had** —
previously fully standalone (`util/lib.lua`'s own module doc used to say "no
hard dependency is ever introduced"); now `:Emojis` fails to register without
it, no fallback. Matches the cmdlog precedent already established in the
roadmap for "zero lib.nvim dependency" repos: add the dependency as part of
the migration, not before.

Source: `lua/emojis/commands.lua`
Docs: `docs/commands.md`, `docs/BINDINGS.md`, `doc/emojis.txt`

| Command | Args | Effect |
| --- | --- | --- |
| `:Emojis` | — | `clear` the whole buffer (`%`) |
| `:Emojis {action}` | `[scope]` | `action` ∈ clear\|insert\|list\|count\|replace\|unreplace\|first\|next\|wrap\|overlay\|toggle |
| `:[range]Emojis {action}` | — | range overrides the scope keyword |
| `:Emojis {clear\|list\|count\|replace} cwd` | `[glob...]` | project-wide via ripgrep, extra tokens become `--glob` filters |
| `:Emojis overlay` | `[grid\|grid_keys\|list]` | quick-insert overlay (`config.overlay`), second arg is interaction mode, not scope |
| `:Emojis toggle` | `[set]` | cycles the checkbox glyph on the cursor line / range through `config.checkbox.sets`, second arg is a set name, not scope |

Command name is configurable (`setup({ command = "Emo" })`) — `composer.verb(cfg.command, ...)` registers under whatever name is configured, verified only that name exists afterward.

## Notes

- **First-ever `lib.nvim` dependency, not previously present at all**: unlike
  every other repo migrated so far (which already had *some* lib.nvim
  submodule usage, hard or soft), emojis.nvim had genuinely zero — `util/lib.lua`
  probed `lib.nvim.notify`/`lib.nvim.bindings.keymap` via `pcall` purely as an optional
  nicety. That soft-dependency pattern is untouched; only the `:Emojis`
  command's *registration* now hard-requires `lib.nvim.bindings.usercmd.composer`.
  Updated the "standalone plugin, no hard dependency" claims in README.md,
  `docs/installation.md`, `doc/emojis.txt`, and `util/lib.lua`'s own module
  doc to scope that claim correctly (soft helpers stay soft; the command
  layer does not).
- **CI gap found and fixed**: `.github/workflows/ci.yml`'s `tests` job ran
  `nvim --headless -u NONE -c "set rtp+=."` with no `lib.nvim` on the
  runtimepath at all — `commands_spec.lua` calls `emojis.setup()`, which now
  `require`s the composer module and would have failed outright. Fixed by
  checking out `StefanBartl/lib.nvim` as a sibling and adding it to `rtp`,
  mirroring cascade.nvim's exact CI pattern (`rtp+=.,../lib.nvim`,
  `working-directory: emojis.nvim`). `docs/TESTS/README.md` updated to match.
- **Reconstruct-and-forward, not a re-derived route tree**: `execute()` (the
  original dispatch/validation function) is completely unchanged. Each of
  the 9 literal action routes only reconstructs the
  `{fargs, range, line1, line2}` shape `nvim_create_user_command`'s callback
  always passed, and forwards straight into it.
- **Scope arg stays soft (`STRING` + `values`), not a hard `enum`, and this
  isn't a style choice**: `insert`/`first`/`next` ignore the scope argument
  entirely (`NO_SCOPE` bypass inside `execute()`), so `:Emojis insert
  garbage` is legal today — a garbage second token is just never read. A
  composer `enum` would validate *before* `execute()` ever got a chance to
  apply that bypass, silently breaking those three actions. Verified via a
  headless check that `:Emojis first garbage_token` / `:Emojis next
  garbage_token` still dispatch normally.
- **Range plumbing verified end-to-end**: `spec.range = true` at the verb
  level (not per-route, since any of the 9 actions can carry a range) —
  `ctx.range.{range,line1,line2}` is populated by composer from the same raw
  `nvim_create_user_command` callback opts `execute()` always read, so
  forwarding it through changes nothing. Checked headlessly: `:2,3Emojis
  clear` only touched lines 2–3, matching pre-migration behavior.
- **`cwd`'s extra `--glob` tail**: the *only* declared arg per route is
  `scope`; anything beyond it (the cwd-only glob filters) automatically lands
  in `ctx.rest`, appended after `ctx.pos[1]` when reconstructing `fargs` —
  verified `:Emojis count cwd *.md *.lua` passes `extra_globs = {"*.md",
  "*.lua"}` through to `search.run` unchanged.
- **Message-text change, accepted**: an unrecognized action (`:Emojis
  bogus`) now gets composer's own "unknown subcommand" usage block (every
  registered action, one per line) instead of the old `unknown action %q.
  Valid: ...` string — same tradeoff every other migrated repo has already
  accepted. `execute()`'s own `has(ACTIONS, action)` check is unreachable
  from the CLI now but stays as defense-in-depth (same status as its scope
  check, which *is* still reachable via the NO_SCOPE bypass — see above).
- **Completion order changed, cosmetic only**: composer alphabetizes literal
  subcommand children, so `:Emojis <Tab>` now lists `clear count first
  insert list next replace unreplace wrap` instead of the original
  declaration order (`clear insert list count replace unreplace first next
  wrap`). `doc/emojis.txt`'s Tab-completion example updated to match.
- **No pre-existing bugs found** while verifying. Full `docs/TESTS/run.lua`
  suite (7 specs, including `commands_spec.lua`'s real `vim.cmd("Emojis
  ...")` calls) passes unmodified against the composer-based registration.
- **v0.3 (2026-07-24): `overlay`/`toggle` routes added** to the same
  composer verb — `overlay` (quick-insert grid) and `toggle` (emoji
  checkbox cycling) round out the action set to 9. Both repurpose the
  second CLI token as something other than a scope (interaction mode /
  set name respectively), same `NO_SCOPE`-style bypass pattern as
  `insert`/`first`/`next`. `docs/ROADMAP.md` was emptied the same day (all
  prior roadmap items shipped, nothing pending); the "Nicht geplant"
  cross-references repo-wide were *not* actually cleaned up, though — see
  the 2026-08-06 correction below.
- **2026-08-06 (checklist compliance pass)**: `docs/ROADMAP.md` was still
  empty and `lua/emojis/bindings/autocmds.lua` still pointed at its "Nicht
  geplant" section — a dead cross-reference, not a cleaned-up one as the
  note above claimed. Restored `docs/ROADMAP.md` with a short "Status"
  summary (everything through v0.3.0 implemented, nothing currently
  pending) and the "Nicht geplant" section (autocmd-driven auto-clear, own
  Unicode DB, font/rendering — unchanged content). No source code changed
  by this; `.luarc.json` was also added at the repo root (was missing) and
  `README.md` gained ASCII art/badges/ToC/a sister-plugin paragraph per the
  RELEASE.md gate.

## `:Emojis` grew a bang and a count (2026-08-24)

**`:Emojis next [count]`** jumps N emoji forward, wrapping past the last.
A positional, not a command count — `:3Emojis next` would be an address
(line 3). Applied by stepping, not by scanning for the Nth match, which is
what keeps the wrap correct at every step.

**`:Emojis!`** means "the alternate form of this action". The two it applies
to are disjoint, so one bang carries both without ambiguity:

| invocation | effect |
| --- | --- |
| `:Emojis! toggle` | Steps the checkbox **backward**. `checkbox.toggle` always took a direction; only the Lua API could reach it. |
| `:Emojis! {action} cwd` | Forces `--no-ignore` for that call only, without mutating `search.no_ignore`. |

Note `forward()` now stringifies positionals before handing them to
`execute`: `fargs` mirrors nvim's own callback table, which is always
strings, and `execute` lowercases `fargs[2]` to read it as a scope — which
raised once `next` had an INT-typed positional.
