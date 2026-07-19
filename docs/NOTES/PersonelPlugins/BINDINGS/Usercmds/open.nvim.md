# open.nvim — `:Open [target] [scope]` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion via two
custom types — `OPEN_TARGET` for the live handler-registry keys, `OPEN_SCOPE`
for `%`/`cfile`/`path=`/named-keyword/file completion). No flat-command
family existed to remove — this was already a single `:Open` command, so the
migration is purely internal (typed args + docgen consistency), no user-
visible syntax change at all.

Source: `lua/open_nvim/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `CHEATSHEET.md`, `README.md`, `doc/open.txt`

| Command | Effect |
| --- | --- |
| `:Open` | Context-aware default (tree → filemanager, URL → browser) |
| `:Open [target]` | Explicit handler key (see `:Open <Tab>` for all registered keys) |
| `:Open [target] [scope]` | Explicit handler + explicit scope (`%`, `cfile`, `path=<path>`, named keyword, or verbatim text) |

## Notes

- **`path = {}` root route, no subcommand tree**: `:Open` has always been a
  flat 2-positional-slot grammar with no subcommand word, so this reuses the
  same root-route trick as pdfport.nvim/replacer.nvim rather than a route
  tree. `target` and `scope` are both `optional = true` positional args on
  that one route.
- **Bare `:Open` bypasses the route entirely**: composer's dispatch handles
  0-arg invocations via `spec.default` *before* ever walking the tree — a
  verb with a `path = {}` root route but no `default` set would print usage
  on a truly bare invocation instead of running that route. Set
  `default = function() run_open(nil, nil) end` explicitly to reproduce the
  original bare-`:Open` context-aware behavior; discovered by reading
  `lib.nvim`'s `composer/parse.lua` `M.dispatch`, not from the composer
  README (worth calling out for the next repo hitting a `path = {}` root
  route with 0 required args).
- **Two custom types, not the built-ins**: `target` completion needs a
  *live* `registry.list_keys()` call (handlers are registered dynamically
  from `cfg.handlers` at `setup()` time, not a static list), and `scope`
  completion has a genuinely bespoke grammar (`path=<lead>` strips/re-adds
  the prefix around file completion, plus prefix-filtered named keywords
  merged with general file completion) — both are meaningfully smarter than
  composer's built-in STRING/PATH types, so both got `composer.register_type()`
  calls (`OPEN_TARGET`, `OPEN_SCOPE`) with the exact original completion logic
  ported verbatim rather than reframed.
- **Validation stays soft on both args**: `registry.dispatch()` already
  reports "Unknown target" itself, and `context.resolve()` already treats any
  non-special scope string as verbatim text — so both custom types validate
  with `return true, raw, nil`, matching the original's complete absence of
  target/scope validation at the parse layer.
- **lib.nvim was already a required (non-optional) dependency** in this
  repo's README/installation docs/vimdoc before this migration — no outdated
  "optional" claims to fix, unlike pdfport.nvim.
- No test suite and no CI exist for this repo, so no fix needed there.
- No keymap coupling: open.nvim ships zero default keymaps; the one example
  in `docs/BINDINGS.md` (`<Cmd>Open<CR>`) still targets the same command name
  and is unaffected.
- Headless-verified: registration (`nargs = "*"`), 1st-arg completion (13
  live handler keys), 2nd-arg completion (`%`/`cfile`/`path=`/keywords/files,
  byte-identical to the pre-migration list), `path=<Tab>` file completion,
  keyword-prefix filtering, bare `:Open`, explicit dispatch, unknown-target
  handling (no crash), and `:checkhealth open_nvim` reporting the new
  `lib.nvim.usercmd.composer` line — all pass.

## Pre-existing bug found (flagged separately, not fixed here)

`docs/configuration.md` and `doc/open.txt` §4 CONFIGURATION both list the
default `handlers` table as `{filemanager, browser, notepad, nvim_internal}`,
but `lua/open_nvim/config/DEFAULTS.lua` actually defaults to
`{filemanager, browser, notepad, nvim_internal, default}` (includes
`"default"`) — a pre-existing doc/code drift unrelated to this migration.
