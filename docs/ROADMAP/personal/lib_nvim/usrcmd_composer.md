# `lib.nvim.usercmd.composer` — rollout across all `.nvim` plugins

Tracks migrating every personal plugin's flat `:PluginFeatureA` /
`:PluginFeatureB` command family to a single `:Verb <subcommand>` built on
`lib.nvim.usercmd.composer`. Design + module itself live in the `lib.nvim`
repo (`docs/ROADMAP/usrcmd_builder.md`, `lua/lib/nvim/usercmd/composer/`).

**Established pattern per plugin** (do this for every remaining one):
1. Survey: find `nvim_create_user_command` call site(s), check for keymap
   coupling (string `<cmd>X<cr>` refs vs. direct Lua function calls — the
   latter is unaffected), CI (does a test job actually exercise the command
   layer, needing a `lib.nvim` sibling checkout?), README/vimdoc `cmd = {...}`
   lazy-load lists, and any "lib.nvim is optional / standalone-first" policy
   claims (now outdated — lib.nvim is a required dependency wherever the
   composer verb is used; update those claims, but leave dated
   `docs/ROADMAP/**` audit snapshots alone).
2. Design the route tree; reuse Phase 6 flags (`--flag=value`) for anything
   with a flag-style or `key=value` grammar; reuse the `path = {}` root-route
   trick for flat positional(+flag) grammars with no natural subcommand word;
   register a custom `composer.register_type()` when a plugin's existing
   completion logic is meaningfully smarter than the built-in types (PATH/
   STRING/enum/etc.) — don't downgrade completion UX to migrate.
3. Decide alongside-vs-replace per plugin (published standalone plugins have
   so far all chosen **replace** — no lingering flat aliases; ask if a repo
   has a reason to differ, e.g. an established compat-alias convention like
   `pickers.nvim` already has).
4. Full doc sweep: README, `docs/*.md`, `doc/*.txt` (regenerate `:helptags`,
   check for individual `*:PluginX*` tags to convert to `*:Verb-sub*`),
   health.lua (add a `lib.nvim.usercmd.composer` check, keep unrelated
   soft-deps soft). Fix CI if a test job needs a `lib.nvim` sibling checkout.
5. Headless-verify: registration, `<Tab>` completion, at least one real
   dispatch per subcommand, old flat commands gone.
6. Write the cheatsheet: `nvim/docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/
   <plugin>.md` (mirror the ones already there for the 7 done repos — mention
   any notable design decision, bug found in passing, or breaking-syntax
   change like cascade.nvim's bang-position move).
7. Update this file's checklist + the plugin's own repo: commit + push.

Flag any genuinely pre-existing, unrelated bug found while verifying as a
background task rather than fixing it inline (this has already turned up
real bugs in 3 of the 7 done repos — mdview.nvim's log-buffer E95, dap.nvim/
cascade.nvim's CI gaps, color_my_ascii.nvim's `dracula`-scheme stats crash and
wrong `lib.map` health-check path).

## Checklist

| plugin | erledigt |
| -------------------------------- | --- |
| `buffer-ctx.nvim`         |  |
| `cascade.nvim`          | ✅ |
| `color_my_ascii.nvim`       | ✅ |
| `debugging.nvim`         |  |
| `dap.nvim`            | ✅ |
| `diff.nvim`            |  |
| `emojis.nvim`           |  |
| `fileops.nvim`          |  |
| `filetree.nvim`          |  |
| `github_stats.nvim`        |  |
| `gopath.nvim`           |  |
| `language.nvim`          |  |
| `lib.nvim`            | ✅ |
| `markdown.nvim`          |  |
| `mdview.nvim`           | ✅ |
| `migrate.nvim`          |  |
| `nvim-cmdlog`           |  |
| `nvim-containers`         |  |
| `open.nvim`            |  |
| `pdfport.nvim`          | ✅ |
| `pickers.nvim`          |  |
| `project-insight.nvim`      |  |
| `recommender.nvim`        |  |
| `replacer.nvim`         |  |
| `reposcope.nvim`         |  |
| `sessions.nvim`          | ✅ |

7 of 26 done.

## Remaining plugins — what's known so far

Grouped by shape, not priority order — pick whichever fits the next session.

### Flat anti-pattern (clear win — command count drops, completion is new)

- **`nvim-containers`** — biggest win by command count: ~24 flat commands
  across `Container*`/`Image*`/`Wsl*`/`*Buffer` families. Collapses to
  `:Container`, `:Image`, `:Wsl` (maybe 3 separate verbs, not one — each
  family is its own resource type).
- **`github_stats.nvim`** — 10 flat commands. **Investigate first**: possible
  duplicate registration bug (registered in both `commands.lua` *and*
  `bindings/usrcmds/init.lua` in an earlier survey pass) — confirm before
  migrating, flag separately if real.
- **`buffer-ctx.nvim`** — `:Insert`, `:Copy`, each with their own dispatch
  table already (not fully flat, but command *names* aren't plugin-prefixed —
  collision risk). Migration is also a chance to prefix them properly
  (`:BufferCtx insert|copy` or similar — decide the verb name).
- **`nvim-cmdlog`** — 7 flat commands. **The only repo with zero lib.nvim
  dependency currently** — add the dependency as part of this migration, not
  before.

### Already has a decent hand-rolled subcommand tree (port for consistency + docgen)

- **`filetree.nvim`** — `:Filetree`/`:Ft`, the best existing prior art (a
  `TREE` table walked by dispatch, completion, *and* a `command_paths()`
  doc-walker — literally the design composer generalized). Port carefully;
  this one is well-tested, don't regress it.
- **`pickers.nvim`** — already has `:Pickers [scope] [nav|action] [action]`
  (hand-rolled `pickers.command.handle`/`.complete()`) *plus* ~11 "compat"
  flat aliases (`:DirPicker`, `:FindConfig`, `:LiveGrep`, `:RepoFiles
  [repo]`, …) that all translate into calls against the same dispatcher —
  same shape as gopath.nvim's legacy-alias pattern. Decide what happens to
  the compat aliases (they're explicitly *designed* as a compat layer, so
  "keep alongside" may be the right call here specifically, unlike other
  repos' default of removing flat commands).
- **`debugging.nvim`** — `:Debug` category→action table, lazily
  `require`s leaf modules. Composer's `route.run` already supports a
  module-path string (lazy `require` on first dispatch) — use it here.
- **`gopath.nvim`** — `:Gopath` + 8 legacy flat aliases, 3-level dispatch,
  completion computed from live cmdline token count. Decide alongside/replace
  specifically for the *legacy aliases* (the main `:Gopath` verb itself is
  the obvious composer target either way).
- **`reposcope.nvim`** — `:Reposcope` subcommand table carries its own
  `.desc` + a hand-rolled `print_usage()` — composer's auto-usage-on-error
  and `document()` replace that printer outright.
- **`fileops.nvim`** — already the *ideal* single-verb case (`:File
  [options?]`), a `SUBCMDS` list reused for dispatch+completion. Low
  functional change; port mainly for typed args + docgen consistency with
  everything else.
- **`project-insight.nvim`** — `:ProjectInsight`, 12 subcommands incl. nested
  `cache build/info/clear`. Straightforward port of an already-decent tree.

### Needs Phase 6 (flag-style / `key=value` grammar) — now buildable

- **`replacer.nvim`** — the plugin that originally motivated Phase 6.
  `:Replace {old} {new} [scope] [--flags]` (flat grammar, no subcommand word
  — use the `path = {}` root-route trick) + `--dry`/`--type=`/`--engine=`
  flags via the new `Route.flags`. `:Surround`/`:Wrap` is a **separate**
  root verb (confirmed correct by the original design sketch — not a
  subcommand of `:Replace`). `:ReplaceDebug` is a small flat dispatch, lower
  priority, could fold into `:Replace debug` or stay separate.
- **`language.nvim`** — `:Spellcheck`/`:Translate`/`:TranslateReplace`,
  token-based grammar distinguishing control verbs from `--flag=value` pairs
  from positional scope args. Now has a real answer via `Route.flags`.
- **`diff.nvim`** — `:Diff` + companions (`:DiffClear`, `:DiffBuffers`,
  `:DiffOrig`, `:DiffExit`), `key=value` grammar (`target=`, `view=vsplit`).
  Same flags mechanism as above, though the `key=value` (no `--` prefix)
  shape doesn't map 1:1 onto `--flag=value` — may need `key=value` support as
  a small follow-up variant of Phase 6, or reframe as named positional args.

### Needs a real design decision (doesn't fit the tree model cleanly)

- **`migrate.nvim`** — dispatches on **argument shape** (empty / `%` / `cwd`
  / range) via a command factory, not a subcommand string. Doesn't map onto
  composer's token-tree model directly; closest existing precedent is
  `mdview.nvim`'s `ctx.rest` escape hatch or a `path = {}` root route with
  no declared args (falls through to `ctx.rest`, handler does its own
  shape-sniffing) — needs a short design pass before implementing, not just
  a mechanical port.
- **`markdown.nvim`** — `:Markdown` + **buffer-local** commands
  (`OpenWithSystemApplication`, `TableView*`, registered via
  `nvim_buf_create_user_command`). Composer currently only wraps
  `nvim_create_user_command` (global commands) — same limitation hit with
  color_my_ascii.nvim's separate `:Fence` system, left untouched there. Two
  options: (a) migrate only `:Markdown` itself and leave the buffer-locals as
  they are (matches the color_my_ascii.nvim precedent), or (b) extend
  composer with buffer-local support first — a real composer feature, not a
  plugin-migration task. Decide before starting.

### Single command / low priority (little to no win)

- **`emojis.nvim`** — one configurable command, small 2-arg-position
  completion idiom. Low risk, low value — fine to batch with something else
  or skip.
- **`open.nvim`** — one configurable command, 2 positional slots, no real
  subtree. Possibly not worth migrating at all beyond typed-arg/docgen
  consistency — low priority.
- **`recommender.nvim`** — one command, flag+positional mixed parsing
  (`-r`/`--replace`, single-dash short flag — composer's flags are `--name`
  only, no short-flag support yet). Check whether the short-flag form is
  load-bearing before deciding to migrate; may need a Phase 6 follow-up
  (short-flag aliases) or just isn't worth forcing into composer's grammar.
