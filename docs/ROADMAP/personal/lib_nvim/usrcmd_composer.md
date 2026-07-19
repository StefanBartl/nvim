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

## Composer capability extensions (Phase 7, shipped)

Three gaps found while planning the remaining migrations below, built ahead
of hitting them (all opt-in, zero behavior change for routes that don't use
them — see `lib.nvim`'s own `docs/ROADMAP/usrcmd_builder.md` §12 Phase 7 and
`lua/lib/nvim/usercmd/composer/README.md` for full docs):

- **Buffer-local commands** — `composer.verb(name, { buffer = true|bufnr, ... })`
  routes through `nvim_buf_create_user_command`. Unblocks markdown.nvim's
  per-buffer `:TableView`/`OpenWithSystemApplication`.
- **Short-flag aliases** — `FlagSpec.short = "r"` matches `-r` alongside
  `--replace`; next-token-value only (no `-o=value`); unrecognized `-x`
  (e.g. a negative number) stays a lenient positional, not an error.
  Unblocks recommender.nvim's `-r`/`--replace`.
- **Bare `key=value` grammar** — new `Route.kv` (`KvSpec[]`), its own module
  (`kv.lua`, separate from `flags.lua` since the leniency stance differs —
  an undeclared `key=value` stays positional, no hard error, unlike `--name`).
  Composes freely with `flags` on the same route (`ctx.kv` + `ctx.flags` both
  populated). Unblocks diff.nvim's `target=`/`view=vsplit`.

All three previously-blocked plugins below are now unblocked — see the
updated "Needs Phase 6" and "Needs a real design decision" sections.

## Checklist

| plugin | erledigt |
| -------------------------------- | --- |
| `buffer-ctx.nvim`         | ✅ |
| `cascade.nvim`          | ✅ |
| `color_my_ascii.nvim`       | ✅ |
| `debugging.nvim`         |  |
| `dap.nvim`            | ✅ |
| `diff.nvim`            |  |
| `emojis.nvim`           |  |
| `fileops.nvim`          |  |
| `filetree.nvim`          |  |
| `github_stats.nvim`        | ✅ |
| `gopath.nvim`           |  |
| `language.nvim`          |  |
| `lib.nvim`            | ✅ |
| `markdown.nvim`          |  |
| `mdview.nvim`           | ✅ |
| `migrate.nvim`          |  |
| `nvim-cmdlog`           | ✅ |
| `nvim-containers`         | ✅ |
| `open.nvim`            | ✅ |
| `pdfport.nvim`          | ✅ |
| `pickers.nvim`          |  |
| `project-insight.nvim`      |  |
| `recommender.nvim`        |  |
| `replacer.nvim`         |  |
| `reposcope.nvim`         |  |
| `sessions.nvim`          | ✅ |

12 of 26 done.

## Remaining plugins — what's known so far

Grouped by shape, not priority order — pick whichever fits the next session.

### Flat anti-pattern (clear win — command count drops, completion is new)


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
  **Unblocked**: use the new `Route.kv` (Phase 7) directly — `kv = {
  { key = "target", type = "STRING" }, { key = "view", type = "STRING",
  enum = {...} } }`, no reframing needed.

### Needs a real design decision (doesn't fit the tree model cleanly)

- **`migrate.nvim`** — dispatches on **argument shape** (empty / `%` / `cwd`
  / range) via a command factory, not a subcommand string. Doesn't map onto
  composer's token-tree model directly; closest existing precedent is
  `mdview.nvim`'s `ctx.rest` escape hatch or a `path = {}` root route with
  no declared args (falls through to `ctx.rest`, handler does its own
  shape-sniffing) — needs a short design pass before implementing, not just
  a mechanical port. (Still open — buffer-local/short-flag/kv extensions
  don't help this one.)
- **`markdown.nvim`** — `:Markdown` + **buffer-local** commands
  (`OpenWithSystemApplication`, `TableView*`, registered via
  `nvim_buf_create_user_command`). **Unblocked**: composer now supports
  `spec.buffer = true` (Phase 7) — register the buffer-local commands as
  their own composer verbs from the same `FileType` autocmd that used to
  call `nvim_buf_create_user_command` directly. `:Markdown` itself migrates
  as a normal global verb alongside.

### Single command / low priority (little to no win)

- **`emojis.nvim`** — one configurable command, small 2-arg-position
  completion idiom. Low risk, low value — fine to batch with something else
  or skip.
- **`recommender.nvim`** — one command, flag+positional mixed parsing
  (`-r`/`--replace`, single-dash short flag). **Unblocked**: `FlagSpec.short
  = "r"` (Phase 7) matches `-r` alongside `--replace` directly — still
  low-value (single command, no subtree), but no longer blocked if worth
  doing for consistency.
