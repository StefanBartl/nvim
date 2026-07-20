# recommender.nvim — User Commands Cheatsheet

One command tree, built via `lib.nvim.usercmd.composer` (migrated
2026-07-20). **The last plugin in the rollout — `usrcmd_composer.md` is now
26/26.** Second (after emojis.nvim) repo that had genuinely zero prior
`lib.nvim` dependency; now `:Recommender` fails to register without it.

Source: `lua/recommender_nvim/bindings/usrcmds.lua`
Docs: `docs/commands.md`, `docs/BINDINGS.md`, `doc/recommender.nvim.txt`

| Command | Args | Effect |
| --- | --- | --- |
| `:Recommender` | `[-r\|--replace] [regex\|treesitter] [threshold]` | Toggle the suggestion float; flags/positionals in any order |

## Notes

- **Textbook `path = {}` root-route case**: no subcommand word at all —
  exactly the grammar shape the roadmap's step 2 flags this trick for. The
  entire verb is ONE route (`path = {}`), so `tree.walk` resolves to it for
  every invocation regardless of tokens, including bare `:Recommender`
  (confirmed the Phase 8 "bare root-route" fix — shipped in `lib.nvim` mid
  rollout, no code changes needed on this end — is active: bare invocation
  correctly resolved analyzer="regex"/threshold=3 defaults through the same
  route rather than being silently skipped).
- **The actual motivating case for Phase 7's short-flag aliases**:
  `FlagSpec.short = "r"` was built specifically to unblock this repo's
  `-r`/`--replace` grammar (see the roadmap's Phase 7 section). One
  `FlagSpec` (`{name="replace", short="r", bool=true}`) covers both forms.
- **`ctx.flags`/`ctx.pos` fed the original logic directly — no
  reconstruction needed, unlike every prior "flags" migration
  (project-insight.nvim's `metrics`, emojis.nvim)**: composer's flag/
  positional split is *the same algorithm* the original inline loop already
  used (strip `-r`/`--replace` tokens, keep everything else as positional,
  in order) — not just format-compatible, semantically identical. So
  `execute(cfg, ctx.flags.replace or false, ctx.pos)` calls straight into
  the extracted-but-otherwise-unchanged dispatch function; no round-trip
  through reconstructed `--flag` strings was required.
- **Accepted behavior tightening, narrower than usual**: an undeclared
  `--flag` (e.g. `--bogus`) is now a hard composer error — previously it
  silently fell through to `pos_args` as an inert positional value (harmless
  no-op, since `tonumber("--bogus")` and the `regex`/`treesitter` string
  checks both just failed silently). An undeclared *short* `-x` is
  unaffected either way — composer leaves it as a lenient positional too,
  matching the original (which also only special-cased `-r` exactly).
- **All 5 of `keymaps.lua`'s `<cmd>Recommender...<cr>` string-coupled
  mappings verified dispatching correctly** post-migration (bare, `-r`,
  `regex`, `treesitter`, `regex 5`), plus flag-position independence
  (`-r regex 5` / `regex -r 5` / `regex 5 -r` all resolve identically) and
  the threshold-only edge case (`:Recommender 5` → analyzer stays default,
  threshold=5, since `pos_args[1]="5"` isn't `"regex"`/`"treesitter"` so
  falls through to `tonumber(pos_args[1])` for threshold).
- **No test suite in this repo** (CI is stylua+luacheck only, no headless
  `nvim` test job) — nothing to fix for a `lib.nvim` sibling checkout, unlike
  emojis.nvim/cascade.nvim.
- **`README.md` had a stale "Pure Neovim — no external dependencies" claim**
  that predates even the soft `lib.nvim.notify`/`map` bridge — now false
  outright since composer is hard-required. Fixed alongside every other
  "optional"/`lib.nvim` requirements-table mention across README, `docs/
  installation.md`, and `doc/recommender.nvim.txt` (none of which previously
  listed `lib.nvim` as a dependency at all, required or optional).
- **No pre-existing bugs found** while verifying.
