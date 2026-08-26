# language.nvim — `:Spellcheck` / `:Translate` / `:TranslateReplace` Cheatsheet

Three independent top-level commands (not a flat family under one verb —
they're already distinct, well-known entry points), each its own
`lib.nvim.bindings.usercmd.composer` verb built on the `path = {}` root-route trick.

Source: `lua/language/bindings/usrcmds/init.lua`
Docs: `docs/BINDINGS.md`, `doc/language.txt`

| Command | Effect |
| --- | --- |
| `:Spellcheck [lang] [buffer\|visible\|cwd\|path=<p>\|clear\|refresh]` | Spell/grammar review |
| `:[range]Translate <lang> [--nocode\|--output=<m>\|--files=<m>] [scope]` | Translate (popup by default); `!` opens the interactive window |
| `:[range]TranslateReplace <lang> [--nocode] [scope]` | Translate and replace in place |

## Notes

- **Depends on a same-day lib.nvim bug fix for bare `:Spellcheck` to work at
  all.** `parse.dispatch`'s zero-arg branch unconditionally used
  `spec.default`/auto-usage, bypassing a registered `path = {}` root route
  entirely even when it resolves fine via `tree.walk(root, {})`. Since this
  verb's root route has no `default` set (bare `:Spellcheck` is meant to
  fall straight through to `spellcheck_handler` with empty args — "review
  the current buffer" is the whole point of the bare form), a bare
  invocation would have silently printed usage instead of running, until
  the fix landed in `lib.nvim` itself (see `usrcmd_composer.md`'s "Phase 8"
  section) — no code change needed here, confirmed working post-fix
  (`:Spellcheck` with no args headless-verified end to end).
- **`ctx.raw`-bypass dispatch, not composer's bound `ctx.args`/`ctx.flags`**:
  same technique replacer.nvim's `:Replace` uses (`lua/replacer/command.lua`,
  migrated in the same rollout). The route still declares `args`/`flags` —
  that's what drives `<Tab>` completion — but `run` ignores composer's own
  parsed `ctx.args`/`ctx.flags` and instead re-invokes the ORIGINAL
  token-scanning handlers (`spellcheck_handler`, `dispatch_translate`)
  against `ctx.raw` (composer's untouched nvim-callback opts — identical
  `.args`/`.bang`/`.range`/`.line1`/`.line2` shape to the pre-migration
  callback). Two reasons this repo needed the bypass instead of a straight
  positional-args port:
  1. The real grammar classifies each token by **shape**, in **any order**
     (a scope word, `path=<p>`, `--flag[=value]`, or the bare language
     code) — not strict positional slots. `:Spellcheck buffer en` and
     `:Spellcheck en buffer` both already worked identically pre-migration;
     composer's `bind_args` binds strictly by position.
  2. `:Translate`/`:TranslateReplace` accept **both** `--nocode` and the
     undocumented single-dash `-nocode` alias — composer's short-flag
     support is single-*character* only (`-n`), so a 7-character `-nocode`
     token can't be declared as a short flag at all. The original
     hand-scan is the only thing that recognizes both spellings.
- **Intentional behavior tightening: unknown `--flag` now hard-errors**.
  Composer's `flags.split()` runs unconditionally before `run` — even
  though `run` itself never reads `ctx.flags` — so declaring
  `flags = {...}` on the route to get `<Tab>` completion for `--nocode`/
  `--output=`/`--files=` also means an undeclared `--typo=x` now stops the
  command with `"unknown flag '--typo'"` + auto-generated usage, instead of
  the old behavior (silently dropped, dispatch proceeded as if the flag
  were never typed). Headless-verified: `:Translate EN --bogus=x` now
  produces a clear error notification. Judged a net improvement (catches
  typos loudly, consistent with composer's documented fail-loud stance) and
  explicitly disclosed here rather than silently absorbed into "just a
  refactor."
- **`--output=`/`--files=` values are now enum-validated** (`TR_OUTPUT_MODES`/
  `TR_FILES_MODES` on the `FlagSpec`), where before any string was accepted
  silently and passed through unchecked. Same fail-loud rationale as above.
- **Composer's bare `--`/`-` (nothing after the dash) doesn't trigger flag
  completion** — a pre-existing composer library characteristic (the
  ambiguity between "start typing a flag" and the literal flags-stop
  sentinel token), not something introduced by this migration. `--n<Tab>` →
  `--nocode` works fine; a bare `--<Tab>` falls through to positional-arg
  completion instead (harmless empty result here). Not worth working around
  in this repo.
- **`nargs` is always `"*"` under composer**, never `"+"` — `:TranslateReplace`
  used `nargs = "+"` pre-migration, so a bare `:TranslateReplace` used to
  fail at the Ex-command level with Neovim's own `E471: Argument required`.
  Now a bare invocation reaches the route with `lang`/`scope` both unset and
  falls through to `dispatch_translate`'s existing nil-target handling
  (`language.translate.run` already tolerates a nil target). Judged a
  reasonable, low-risk behavior shift, not worth fighting since composer
  doesn't expose a way to require `nargs = "+"` per verb.
- No test suite and no CI exist for this repo, so no fix needed there.
- No keymap coupling: all keymaps in `bindings/keymaps/init.lua` call Lua
  functions directly (`spell.run`, `translate.motion.expr/visual`,
  `thesaurus.replace_under_cursor`) — no `<Cmd>Translate<CR>`-style string
  refs to update.
- lib.nvim was already documented as a required dependency (health.lua even
  labeled its check "lib.nvim (required dependency)") — no outdated
  "optional" claims to fix.
- Headless-verified: registration (`nargs=*`, `bang`/`range` flags per
  command), 1st/2nd-arg completion for all three commands, `--flag`
  completion (`--n<Tab>` → `--nocode`), `--output=`/`--files=` enum
  completion, `Spellcheck clear`/`refresh` dispatch, `Translate!` interactive
  window dispatch, unknown-flag hard error with usage text, and
  `:checkhealth language` reporting the new `lib.nvim.bindings.usercmd.composer` line
  — all pass.
