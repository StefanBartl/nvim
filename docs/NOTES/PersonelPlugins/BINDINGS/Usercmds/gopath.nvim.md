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
| `:Gopath open [mode]` | `edit\|split\|vsplit\|tab\|explorer` | resolve & open (`explorer` reveals in the system file manager instead) |
| `:Gopath copy` | — | copy `path:line:col` |
| `:Gopath debug` | — | resolution info |
| `:Gopath check` | — | check existence / offer create |
| `:[range]Gopath probe [mode]` | `edit\|split\|vsplit` | suffix/visual probe |
| `:Gopath cache build\|info\|add-root <dir>` | — | only registered if `truncated.enable = true` |
| `:GopathResolve` `:GopathOpen` `:GopathCopy` `:GopathDebug` `:GopathCheck` `:[range]GopathProbe[!]` `:GopathCacheBuild` `:GopathCacheInfo` `:GopathCacheAddRoot` | — | compat aliases, unchanged, individually toggleable via `config.commands.*` |

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
  pcall-guarded fallbacks). `bindings/usrcmds.lua`'s unconditional
  `require("lib.nvim.usercmd.composer")` was the first hard lib.nvim
  dependency in the repo. Fixed README/installation.md's "optional" framing
  (renamed the installation.md section from "Optional dependencies" to
  "Dependencies") and added a required-check to `health.lua` alongside its
  existing informational lib.nvim check.
- **Update (2026-07)**: `bindings/keymaps.lua` and `bindings/autocmds.lua`
  were folded into the same migration (`require("lib.nvim.map")` /
  `require("lib.nvim.autocmd")`, both unconditional) — lib.nvim is no longer
  a single-file dependency, it's required across the whole bindings layer.
  `lua/gopath/util/cross.lua`'s `lib.nvim.cross` usage remains the one
  genuinely soft (pcall-guarded, falls back to built-ins) usage in the repo.
- **CI added**: `.github/workflows/ci.yml` runs `stylua --check`, `luacheck`,
  and a headless smoke test (`scripts/ci/headless_tests.lua`) that clones
  `lib.nvim` onto the runtimepath, calls `setup()`, and executes every
  `docs/TESTS/*.lua` fixture — supersedes the "No CI for this repo" note.
- **`probe`'s visual selection was completely dead (fixed 2026-07-31)**:
  `get_visual_selection()` gated on `nvim_get_mode()` being `v`/`V`/CTRL-V —
  which can never hold at either call site (a `:Gopath probe` runs in command
  mode; the visual keymap feeds `<Esc>` before its `vim.schedule`d callback),
  so the guard was always false and every visual probe silently fell back to
  `<cfile>`/`<cword>`. Fixed by dropping the guard (the `'<`/`'>` marks it
  reads were fine all along) and having callers state whether a selection was
  actually given — the marks alone can't say, they outlive whatever set them.
  Both `:Gopath probe` and `:GopathProbe` now also declare `range = true` (they
  didn't before, so `:'<,'>` never reached the handler at all) and pass
  `selection = ctx.range.range > 0` / `opts.range > 0` respectively. Needs
  lib.nvim's `composer.checkhealth`/`ctx.range` work (lib.nvim commit
  `e2f018d`) to be present, though the fix itself doesn't depend on the new
  `ctx.range.mode`/`col1`/`col2` fields — only on `range` being wired at all.
- **2026-08-21**: `:Gopath open`/`:GopathOpen` gained a fourth-plus mode,
  `explorer` — reveals the resolved path in the system file manager
  (Explorer/Finder/…) instead of opening a buffer for it, via
  `gopath.external.reveal()` / `external/helpers/revealer.lua` (backed by
  lib.nvim's `cross.reveal_in_fm`, minimal per-OS fallback otherwise).
  `norm_mode()` in `bindings/usrcmds.lua` now passes `"explorer"` through
  unchanged instead of defaulting it to `"edit"`. New default keymap `gM`
  (`mappings.open_explorer`) added alongside, see `Keymaps/gopath.nvim.md`.
