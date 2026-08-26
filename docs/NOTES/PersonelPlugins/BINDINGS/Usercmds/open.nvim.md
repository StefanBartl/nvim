# open.nvim — `:Open [target] [scope]` / `:Open viewer` Cheatsheet

One command, built via `lib.nvim.bindings.usercmd.composer` (`<Tab>` completion via two
custom types — `OPEN_TARGET` for the live handler-registry keys, `OPEN_SCOPE`
for `%`/`cfile`/`path=`/named-keyword/file completion). No flat-command
family existed to remove — this was already a single `:Open` command, so the
migration is purely internal (typed args + docgen consistency), no user-
visible syntax change at all.

Source: `lua/open/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `CHEATSHEET.md`, `README.md`, `doc/open.txt`

| Command | Effect |
| --- | --- |
| `:Open` | Context-aware default (tree → filemanager, URL → browser) |
| `:Open [target]` | Explicit handler key (see `:Open <Tab>` for all registered keys) |
| `:Open [target] [scope]` | Explicit handler + explicit scope (`%`, `cfile`, `path=<path>`, named keyword, or verbatim text) |
| `:Open viewer [kind] [scope] [opts]` | List links in a scope, then open / export |
| `:UrlView [scope] [opts]` | Wrapper pinning `kind=urls` (name from `viewer.commands.urls`) |
| `:MDLinksView [scope] [opts]` | Wrapper pinning `kind=mdlinks` (name from `viewer.commands.mdlinks`) |
| `:Open terminal [scope]` | Terminal split in the target's directory (added later, see below) |
| `:Open <target> git` | `git` is now a special scope token — nearest Git root (added later, see below) |

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
  `lib.nvim.bindings.usercmd.composer` line — all pass.

## `:Open viewer` / `:UrlView` / `:MDLinksView` (added later)

Replaces the `axieax/urlview.nvim` dependency, which is now removed from
`lua/plugins/misc.lua`. Collects links from a scope and either opens a pick
or exports the list.

| Part | Where |
| --- | --- |
| Scope → lines with provenance | `lib.nvim.harvest.scope` (new lib.nvim module) |
| Lines → links | `lua/open/viewer/scan.lua` |
| Filter / sort / format / open | `lua/open/viewer/init.lua` |
| Rows → GFM table / CSV | `lib.nvim.harvest.render` |
| Text → clipboard/file/scratch/picker | `lib.nvim.harvest.sink` |
| The results list itself | `lib.nvim.ui.kit.chooser` (already existed) |

```
:UrlView                                 URLs in this buffer → picker
:MDLinksView cwd                         every markdown link in the project
:Open viewer cwd sort=file out=table     everything, as a table
:'<,'>UrlView                            just the selection
```

Kinds: `all` (default), `urls`, `mdlinks`, `files`, `paths`.
Scopes: *(omitted)*/`%`, `cwd`, `buffers`, `<path>`, or a range.
Options: `sort=`, `out=`, `match=`, `--paths`, `--anchors`, `--dupes`, `--flat`.

### Notes

- **lib.nvim needed no new UI module.** The requested list behavior — whole
  current line highlighted, cursor locked to up/down, `<CR>` acts on the row —
  was already implemented in `lib.nvim.ui.kit.chooser`: it sets
  `cursorline` + `winhighlight=CursorLine:KitSelection` and maps
  `h l 0 ^ $ w e b W E B <Left> <Right>` to `<Nop>`. `harvest.sink.select`
  routes through `kit.select` → `chooser`, so the viewer got that for free.
  Verified headlessly (500-item list: window height clamps to 20, buffer keeps
  all 500 rows, cursorline on, horizontal keys blocked).
- **`urls` vs `mdlinks` filter on different axes on purpose**: `urls` selects
  on the *target* (a `[docs](https://x)` counts), `mdlinks` on the *syntax*
  (a `[doc](./a.md)` counts). They overlap. This is what makes `:UrlView`
  mean "things a browser can open" rather than "things without brackets" —
  the original complaint was that `:UrlView` was flooded with local
  document links.
- **The kind argument is disambiguated in the handler, not by an `enum`.**
  Declaring `enum` on the positional would make `:Open viewer cwd` a hard
  error instead of reading it as "all kinds, cwd scope". `run_viewer` checks
  the first positional against `viewer.kinds()` and shifts it into the scope
  slot when it does not name one.
- **Relative markdown targets are resolved against the source file's
  directory**, not the cwd. Without this, `[x](../../lua/init.lua)` found in
  a nested doc was reported verbatim and could not be opened at all.
- **Bare in-document anchors (`[Kontext](#kontext)`) are dropped by default**
  (`--anchors` re-includes them). A repo-wide scan of the config turned up
  dozens of TOC entries, none of them openable.
- **`<CR>` on a local file opens a Neovim split, not the file manager**
  (`viewer.open_file`, default `"split"`). A `file.md#heading` target has its
  fragment stripped before dispatch and jumps to the heading afterwards.
- **Column alignment must pad by display width, not bytes.** Lua's
  `("%-24s"):format(s)` counts bytes, and a shortened cell contains a `…`
  that is 3 bytes but 1 cell — byte-padding stopped short and the target
  column started two cells left on every elided row. Caught by a test that
  compares `strdisplaywidth` of the prefix, not `find()` byte offsets.
- **Literal route + root route still coexist**: `:Open viewer` works because
  composer's `tree.walk` consumes literal children greedily. `viewer` is
  therefore a reserved handler key; a test asserts no handler claims it.
- **Range only counts when actually typed** (`ctx.range.range > 0`), else
  nvim reports line1/line2 as the cursor line and a plain `:UrlView` would
  scan one line.
- Renamed from the initial `:Open urlview` / `open_nvim.urlview` to
  `viewer` so the module name matches the command. Config moved from
  `urlview = { command = … }` to `viewer = { commands = { urls, mdlinks, all } }`.

## Pre-existing bug (since fixed)

`docs/configuration.md` and `doc/open.txt` §4 CONFIGURATION used to list the
default `handlers` table as `{filemanager, browser, notepad, nvim_internal}`
while `lua/open/config/DEFAULTS.lua` defaulted to that plus `"default"`.
Both docs now include `"default"` and match the code — verified, no action
needed.

## Module root rename (`lua/open_nvim/` → `lua/open/`)

The plugin's own Lua module root dropped the `_nvim` suffix at some point
after the notes above were written (repo commit `b6b3a88`, "refactor: drop
_nvim suffix from lua module root") — `require("open_nvim...")` became
`require("open...")` throughout. Purely internal; no user-visible command or
config-key change. The stale `open_nvim` paths in the older notes above have
been corrected in place; anything below this point already uses `open`.

## Roadmap features (all of docs/ROADMAP.md implemented, then cleared)

Every item that was tracked in `docs/ROADMAP.md` got implemented in one
commit each and the file was then emptied (nothing left to track). New
surface added to `:Open`/`setup()`:

| Feature | What changed |
| --- | --- |
| `custom_handlers` | `setup({ custom_handlers = { {key, desc, run}, ... } })` registers user handlers alongside the built-in `handlers` modules — no need to call `registry.register()` by hand. |
| `terminal` handler | New handler key `terminal`, in the default `handlers` list. `:Open terminal` opens a terminal split in the buffer's directory; a file target resolves to its parent dir. Added to `context.PATH_TARGETS` alongside filemanager/split/vsplit/tab. |
| `keymaps` config | `setup({ keymaps = { open_default=, open_browser=, open_manager= } })` registers fixed-target keymaps via a new `lua/open/bindings/keymaps.lua`. Still **none by default** — the "no default keymaps" claim in `docs/BINDINGS.md`/this file's Keymaps note is about the shipped defaults, not the absence of the option now. |
| `brave` / `opera` handlers | Two more `make_named_handler(...)` registrations in `handlers/browser.lua`, same pattern as chrome/firefox/edge. |
| `git` scope token | `:Open filemanager git` resolves the nearest Git root via `git rev-parse --show-toplevel`, added as a third special scope token alongside `%`/`cfile` (before the keyword-lookup fallback) in `context.resolve()`. |
| `picker` config | `setup({ picker = { enabled = true } })` — a no-target `:Open`/`open.open()` call whose context has more than one meaningful handler (see `context.candidate_targets()`) shows a `vim.ui.select` prompt (new `lua/open/picker.lua`) instead of the automatic pick. Off by default; an explicit target always bypasses it. |
| `filemanager.reveal` | `setup({ filemanager = { reveal = false } })` makes a file target navigate to its parent directory instead of being selected/revealed there. Directories are always navigated into regardless. Rewrote every platform branch in `handlers/filemanager.lua` to compute the file-vs-reveal target explicitly. |
| `debug` config | `setup({ debug = true })` logs `context.gather()`, `context.resolve()`, and `registry.dispatch()` steps to `:messages`, tagged `[open.context]`/`[open.registry]`. Off by default. |
| Context cache | New `context.with_cache(fn)` memoizes `gather()`'s result for the duration of `fn`. `open.open()` and the `:Open` user-command handler both now run through it; nested `with_cache` calls reuse the outermost cache rather than clearing it early. |
| Telescope integration | New opt-in `lua/open/integrations/telescope.lua` (`picker()` / `extension()`) — lists registered handlers with a live "would open: ..." preview per row, dispatches the chosen one on `<CR>`. Not loaded by `setup()`, matching the existing `open.integrations.urlview` opt-in convention. |

All ten shipped with test coverage added to a new `TESTS/features_spec.lua`
(registered in `TESTS/run.lua`), verified against a real headless run with
`lib.nvim` on `$LIB_NVIM_PATH` — full suite green after every commit.
