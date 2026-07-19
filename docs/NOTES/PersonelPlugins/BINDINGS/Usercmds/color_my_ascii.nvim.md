# color_my_ascii.nvim — `:ColorMyAscii <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion).
Replaces the old 14 flat `:ColorMyAsciiX` commands (fully removed, no
alongside period). **Distinct from the separate `:Fence` toolkit**
(buffer-local, `nvim_buf_create_user_command`, already had good subcommand
syntax — left untouched; composer doesn't support buffer-local commands yet).

Source: `lua/color_my_ascii/bindings/usrcmds.lua` +
`lua/color_my_ascii/debug/commands.lua` (debug-gated routes)
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `README.md`, `docs/README-de.md`,
`docs/QUICKSTART.md`, `docs/QUICKSTART-de.md`, `doc/color_my_ascii.txt`

## Core

| Command | Effect |
| --- | --- |
| `:ColorMyAscii` | Manually highlight the current buffer (bare form) |
| `:ColorMyAscii toggle` | Enable/disable plugin |
| `:ColorMyAscii debug` | Show basic debug information |
| `:ColorMyAscii show-config` | Show detailed configuration |
| `:ColorMyAscii check-fences` | Check for unmatched fenced code blocks |
| `:ColorMyAscii ensure-blank-lines` | Ensure blank lines around code blocks |

## Schemes

| Command | Effect |
| --- | --- |
| `:ColorMyAscii schemes list` | List available color schemes |
| `:ColorMyAscii schemes switch <name>` | Switch scheme (tab-completed) |
| `:ColorMyAscii schemes pick` | Pick scheme with Telescope (live preview) |

## Debug (only registered when `config.debug_enabled == true`)

| Command | Effect |
| --- | --- |
| `:ColorMyAscii inspect char <char>` | Groups/highlight a character belongs to |
| `:ColorMyAscii inspect group <group>` | Every character in a group (tab-completed) |
| `:ColorMyAscii inspect inline` | Inspect inline code on the current line |
| `:ColorMyAscii inspect highlight <hl>` | Every group using a highlight |
| `:ColorMyAscii stats` | Comprehensive plugin statistics |

## Notes

- **Debug-gating quirk**: the plugin loads with default config (`debug_enabled
  = false`) at `plugin/` startup time, *before* the user's own `setup()` call
  runs. So `usrcmds.enable()` was made **idempotent/re-callable** — it checks
  `debug_enabled` fresh each time, and `debug/init.lua` now calls it again
  (rebuilding the whole `:ColorMyAscii` verb) once debug mode turns on at
  runtime, instead of self-registering separately as before.
- **lib.nvim policy flip**: same as cascade.nvim — was "optional", is now a
  **required** dependency (the command itself needs
  `lib.nvim.usercmd.composer`). `lib.nvim.map` stays soft-guarded for keymaps.
  Also fixed a pre-existing health-check bug: it probed the wrong path
  (`lib.map` instead of `lib.nvim.map`), so it always reported "not found"
  even when lib.nvim was installed.
- No CI test job exists for this repo (lint/format only), so no CI checkout
  fix was needed (unlike cascade.nvim).
- **Pre-existing bug spotted** (not fixed, out of scope, flagged separately):
  `:ColorMyAscii stats` crashes after switching to the `dracula` scheme — a
  type error in the statistics-gathering logic, unrelated to the command
  migration.
