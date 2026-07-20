# gopath.nvim — User Commands Cheatsheet

`:Gopath` rebuilt via `lib.nvim.usercmd.composer` (migrated 2026-07-19).
**No syntax change** to `:Gopath`. The 9 individual legacy alias commands
are **kept alongside**, unchanged — same "keep alongside" call as
pickers.nvim's compat flat aliases (both are explicit, individually
config-toggleable backward-compat layers by the plugin's own design, not
accidental duplication).

Source: `lua/gopath/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `docs/installation.md`, `README.md`

| Command | Args | Notes |
| --- | --- | --- |
| `:Gopath open [mode]` | `edit\|split\|vsplit\|tab` | resolve & open |
| `:Gopath copy` | — | copy `path:line:col` |
| `:Gopath debug` | — | resolution info |
| `:Gopath check` | — | check existence / offer create |
| `:Gopath probe [mode]` | `edit\|split\|vsplit` | suffix/visual probe |
| `:Gopath cache build\|info\|add-root <dir>` | — | only registered if `truncated.enable = true` |
| `:GopathResolve` `:GopathOpen` `:GopathCopy` `:GopathDebug` `:GopathCheck` `:GopathProbe[!]` `:GopathCacheBuild` `:GopathCacheInfo` `:GopathCacheAddRoot` | — | compat aliases, unchanged, individually toggleable via `config.commands.*` |

## Notes

- **Cache subcommand bodies extracted, not duplicated**: the original
  unified `:Gopath cache build/info/add-root` logic was inline inside one
  giant `nvim_create_user_command` callback (distinct from — and slightly
  differently worded than — the separate `:GopathCacheBuild`/`Info`/
  `AddRoot` compat commands' own inline copies, a pre-existing minor
  wording drift between the two paths, e.g. "Cache build complete" vs
  "Cache built"). Extracted into three local functions
  (`cache_build`/`cache_info`/`cache_add_root`) used only by the new
  composer routes; the separate compat commands' own inline bodies were
  left completely untouched, wording drift and all — not worth "fixing"
  as part of a migration that's supposed to be behavior-neutral.
- **`cache *` routes only registered when `truncated.enable = true`**,
  snapshotted at `setup()` time — matches the original's own gating (which
  otherwise printed "truncated cache is disabled in config" on dispatch).
  Same accepted, documented tradeoff as debugging.nvim's disabled
  categories: typing `:Gopath cache build` with truncated disabled now
  gets composer's generic "unknown subcommand" instead of that specific
  message, since an unregistered subcommand has no route to carry it.
- **lib.nvim was genuinely optional before this migration** (unlike most
  other repos in this series where it was already a hidden hard dependency
  — gopath's `health.lua`/`util.log`/create-on-missing dialog all had real
  pcall-guarded fallbacks). `bindings/usrcmds.lua`'s new unconditional
  `require("lib.nvim.usercmd.composer")` is the *only* hard lib.nvim
  dependency in the whole repo now. Fixed README/installation.md's
  "optional" framing (renamed the installation.md section from "Optional
  dependencies" to "Dependencies") and added a required-check to
  `health.lua` alongside its existing informational lib.nvim check.
- No CI for this repo — pre-existing, not part of this migration's scope.
