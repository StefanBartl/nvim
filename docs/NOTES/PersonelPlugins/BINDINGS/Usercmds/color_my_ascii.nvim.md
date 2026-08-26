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
| `:ColorMyAscii toggle [global\|buffer]` | Enable/disable the plugin (`global`, the default — unchanged behaviour) or just the current buffer (`buffer`, **added 2026-08-24**). `toggle` was always global; the audit recorded it as current-buffer-only, which was backwards. |
| `:ColorMyAscii debug` | Show basic debug information |
| `:ColorMyAscii show-config` | Show detailed configuration |
| `:ColorMyAscii check-fences` | Check for unmatched fenced code blocks |
| `:ColorMyAscii ensure-blank-lines` | Ensure blank lines around code blocks |
| `:ColorMyAscii fence-jump` | Jump between a fence's opening/closing delimiter (%-style); falls back to built-in `%` elsewhere |

## `:Fence` (buffer-local, markdown only)

Not a `:ColorMyAscii` subcommand — a separate dispatcher registered
buffer-local on `FileType markdown` (`nvim_buf_create_user_command`), source
`lua/color_my_ascii/commands/fence/*.lua`. Was just `export` for a while;
now a full small literate-programming toolkit:

| Command | Effect |
| --- | --- |
| `:Fence export [path] [--open] [--replace]` | Extract the block under the cursor into a file |
| `:Fence yank [register]` | Copy block content (no delimiters) to a register |
| `:Fence open [--split\|--vsplit\|--tab\|--edit]` | Edit the block in a real split (full LSP/formatter), synced back on `:w` |
| `:Fence run` | Run the block with its language's interpreter, output in a scratch split |
| `:Fence format` | Format the block in place with the language's formatter |
| `:Fence import <file>` | Replace block content with a file's content (inverse of export) |
| `:Fence lang <language>` | Change the fence's language tag |
| `:Fence select` | Visually (linewise) select the block interior |
| `:[range]Fence wrap [language]` | Wrap the current line/range in a fence |
| `:Fence unwrap` | Remove the fence delimiters around the block under the cursor |

Each of the argument-less ones above also has an opt-in default keymap action
(`fence_yank`, `fence_open`, `fence_run`, `fence_format`, `fence_select`,
`fence_wrap`, `fence_unwrap`) — see `Keymaps/color_my_ascii.nvim.md`.

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
