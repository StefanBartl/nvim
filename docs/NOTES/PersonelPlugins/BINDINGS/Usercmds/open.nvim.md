# open.nvim — `:Open [target] [scope]` / `:UrlView` Cheatsheet

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
| `:Open urlview [scope] [opts]` | List every link in a scope, then open / export |
| `:UrlView [scope] [opts]` | Shallow wrapper over `:Open urlview` (name from `urlview.command`, `false` disables) |

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
- ~~No test suite and no CI exist for this repo~~ — a headless suite now
  exists at `TESTS/run.lua` (added with `:UrlView`, see below). Run it with
  `nvim --headless -u NONE -l TESTS/run.lua` from the repo root; it locates
  `lib.nvim` via `$LIB_NVIM_PATH`, a sibling checkout, or the lazy clone.
- No keymap coupling: open.nvim ships zero default keymaps; the one example
  in `docs/BINDINGS.md` (`<Cmd>Open<CR>`) still targets the same command name
  and is unaffected.
- Headless-verified: registration (`nargs = "*"`), 1st-arg completion (13
  live handler keys), 2nd-arg completion (`%`/`cfile`/`path=`/keywords/files,
  byte-identical to the pre-migration list), `path=<Tab>` file completion,
  keyword-prefix filtering, bare `:Open`, explicit dispatch, unknown-target
  handling (no crash), and `:checkhealth open_nvim` reporting the new
  `lib.nvim.usercmd.composer` line — all pass.

## `:Open urlview` / `:UrlView` (added later)

Replaces the `axieax/urlview.nvim` dependency, which is now removed from
`lua/plugins/misc.lua`. Collects links from a scope and either opens a pick
or exports the list.

| Part | Where |
| --- | --- |
| Scope → lines with provenance | `lib.nvim.harvest.scope` (new lib.nvim module) |
| Lines → links | `lua/open_nvim/urlview/scan.lua` |
| Rows → GFM table / CSV | `lib.nvim.harvest.render` |
| Text → clipboard/file/scratch/picker | `lib.nvim.harvest.sink` |

```
:UrlView                                 current buffer → picker
:UrlView cwd sort=file out=table         project-wide table
:UrlView cwd match=%.md$ out=mdlinks     docs links as markdown → clipboard
:'<,'>UrlView                            just the selection
```

Scopes: *(omitted)*/`%`, `cwd`, `buffers`, `<path>`, or a range.
Options: `sort=none|file|kind|alpha`, `out=picker|table|clipboard|mdlinks|csv|echo|file:<path>`,
`match=<lua pattern>`, `--paths`, `--all`, `--flat`.

### Notes

- **Literal route + root route coexist**: `:Open urlview` works *because*
  composer's `tree.walk` consumes literal children greedily — the token
  matches the literal child node and never reaches the root route's
  `OPEN_TARGET` positional. The corollary is that **`urlview` is now a
  reserved handler key**: a handler registered under that name would be
  unreachable via `:Open urlview`. There's a test asserting no handler
  claims it.
- **`:UrlView` is a second `composer.verb` over the same route body**, not a
  `vim.cmd` alias — same precedent as replacer.nvim's `:Replace`/`:Replacer`
  (`command.lua:405-406`). It keeps its own completion and usage listing.
- **Command-name conflict with urlview.nvim**: both want `:UrlView`, and
  whichever registers last wins. Since urlview.nvim is now removed from the
  config this is moot, but `urlview.command = false` is the escape hatch.
- **Range only counts when actually typed**: nvim reports `line1`/`line2` as
  the cursor line even with no range, so the handler gates on
  `ctx.range.range > 0`. Without that gate a plain `:UrlView` would silently
  scan one line instead of the buffer.
- **Why lib.nvim got `harvest` and not a "flow framework"**: the picker step
  already existed (`lib.nvim.ui.kit.select`), and the collect/action steps are
  domain logic. Only the *scope resolution* and *render/sink* halves were
  genuinely duplicated (markdown.nvim carried two copies of scope collection),
  so only those moved into lib.nvim, as three independently-usable modules.
- Verified end-to-end headlessly, not just unit-tested: all four sinks
  (`table`/`csv`/`mdlinks`/`file:`), fenced-code exclusion, and the bad-scope
  error path were driven through a real `:UrlView` invocation.

## Pre-existing bug (since fixed)

`docs/configuration.md` and `doc/open.txt` §4 CONFIGURATION used to list the
default `handlers` table as `{filemanager, browser, notepad, nvim_internal}`
while `lua/open_nvim/config/DEFAULTS.lua` defaulted to that plus `"default"`.
Both docs now include `"default"` and match the code — verified, no action
needed.
