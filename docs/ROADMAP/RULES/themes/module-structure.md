# Module structure

Architecture and naming conventions, `lib.nvim` integration, module
boundaries, and config-validation patterns pulled from the per-plugin reports.

## lib.nvim as shared dependency

- [lib.nvim](../plugins/lib.nvim.md) is a deliberate, no-third-party-deps
  standard library split into three strict namespaces: `lib.lua.*`
  (editor-independent), `lib.nvim.*` (Neovim API adapters), `lib.vim.*`
  (classic-vim mirror of `lib.nvim.*`) — `docs/architecture.md:3-11`. Splitting
  code this way keeps the generic parts independently testable/extractable —
  lib.nvim guideline 1.
- Plugins declare `lib.nvim` as either a **hard** dependency (ungapped
  `require`, no fallback — [buffer-ctx.nvim](../plugins/buffer-ctx.nvim.md),
  [insights.nvim](../plugins/insights.nvim.md),
  [debugging.nvim](../plugins/debugging.nvim.md)) or a **soft** dependency
  (`pcall(require, ...)` + local fallback with an identical interface —
  [buffer-ctx.nvim](../plugins/buffer-ctx.nvim.md) (`util/notify.lua`,
  `util/path.lua:8-11`, `ops/uuid.lua:8`),
  [markdown.nvim](../plugins/markdown.nvim.md), [sessions.nvim](../plugins/sessions.nvim.md)).
  Whichever it is, keep it consistent and don't advertise a hard dependency as
  optional in docs — see the "Doku muss der Realität folgen" case in
  [fileops.nvim](../plugins/fileops.nvim.md) (`health.lua:71-75`).
- Rather than duplicate a fix in a private copy, upstream security/cross-cutting
  fixes into `lib.nvim` once they're found — from
  [debugging.nvim](../plugins/debugging.nvim.md) (a command-injection bug in a
  clipboard fallback was fixed by moving the logic to
  `lib.nvim.cross.copy_to_clipboard`, not patched locally).
- Thin, fully-delegating modules (e.g. `utils/executable.lua` re-exporting
  `lib.nvim.cross.executable`) should be commented explicitly as such ("thin
  re-export of X, upstreamed") so the source of truth stays clear — from
  [dap.nvim](../plugins/dap.nvim.md) (`utils/executable.lua`).

## Pure core / impure shell

Recurring architectural split: keep analysis/transform logic free of
`vim.api`/`vim.fn` calls, returning plain data or `(result, err)`; push all
buffer/UI/IO mutation into a separate outer layer.

- [emojis.nvim](../plugins/emojis.nvim.md) (`core/*.lua` — zero `vim.api`
  calls, headless-testable).
- [diff.nvim](../plugins/diff.nvim.md) (`core/resolve.lua`, `core/git.lua`,
  `core/url.lua` vs. `core/render.lua`/`core/init.lua`).
- [fileops.nvim](../plugins/fileops.nvim.md) (`ops/*.lua` vs. `util/notify.lua`).
- [replacer.nvim](../plugins/replacer.nvim.md) (`compute_file_edits` vs.
  `apply_matches` — enables dry-run/export without buffer mutation).
- [migrate.nvim](../plugins/migrate.nvim.md) (`migrate_line` kept free of
  Picker/Telescope/Notify dependencies, `opt/migrator.lua:4-6`).
- [insights.nvim](../plugins/insights.nvim.md) (`build_dot` — "pure function —
  reused directly by the test suite, no Graphviz/terminal needed to check
  it", `imports/graph.lua:1-24`).

## Registry / provider patterns for pluggable backends

- Language/format backends register themselves via `M.register(name, backend)`
  at file end instead of the walker hard-coding a filetype branch, enforcing a
  layer boundary structurally, not just by convention — from
  [documentation.nvim](../plugins/documentation.nvim.md) (`core/lang_registry.lua`).
- Two mutually-exclusive backend plugins for the same job (e.g. two panel-UIs)
  should be abstracted behind one internal dispatch module, chosen via
  `pcall(require, ...)` install checks with a warned fallback, not scattered
  if/else — from [dap.nvim](../plugins/dap.nvim.md) (`ui/provider.lua:19-63`).
- Multiple interchangeable engines (telescope/fzf-lua/snacks) should be
  abstracted through a narrow function-interface contract per adapter (e.g.
  `pick_files/pick_item/live_grep/pick_dir`), not shared inheritance — from
  [pickers.nvim](../plugins/pickers.nvim.md) (`engines/init.lua:6-8`); prefer
  "user wish → fallback chain → explicit fail only if truly nothing available"
  with a visible warning on every downgrade.
- Hexagonal ports & adapters (`core/ports` + `core/usecases` +
  `adapters/<impl>`) pays off once a plugin has more than one swappable
  backend implementation — enables testing against a faked interface instead
  of real binaries — from [sandbox.nvim](../plugins/sandbox.nvim.md) (3
  container engines + WSL).
- A registry pattern for enable/disable/command mapping keeps new modules
  registering in exactly one place instead of scattered if/else chains — from
  [migrate.nvim](../plugins/migrate.nvim.md) (`migrate/registry.lua`).

## Feature-module conventions

- One feature = one folder (`features/<category>/<name>/init.lua`), registered
  in exactly one name→modulepath table; never hardcode a feature's require
  path from a consumer — from [filetree.nvim](../plugins/filetree.nvim.md)
  (`features/init.lua`).
- Every feature module has the same shape: local `_cfg` defaults,
  `M.setup(config, adapter)`, `M.teardown()`, plain action functions;
  `setup()` no-ops when disabled, `teardown()` cleans up for idempotent
  re-setup — from [filetree.nvim](../plugins/filetree.nvim.md).
- Config is opt-out by default (new features ship active); only join a small,
  individually-justified `DEFAULT_DISABLED` list with an inline reason — from
  [filetree.nvim](../plugins/filetree.nvim.md) (`init.lua:29-53`).
- Idempotent `setup()` via a module-local flag (not `vim.g`, which is only for
  cross-plugin-visible signals) prevents duplicate command/autocmd
  registration on re-source — from [diff.nvim](../plugins/diff.nvim.md)
  (`init.lua:20-30`), [recommender.nvim](../plugins/recommender.nvim.md)
  (`init.lua:11,16-19`), [fileops.nvim](../plugins/fileops.nvim.md)
  (`init.lua:5,10-13`, redundantly layered with a `vim.g.loaded_fileops` guard).
- A single dispatch chokepoint (one function that's the only path that
  actually opens/executes an action) keeps session-level state trivial to
  maintain in one place — from [pickers.nvim](../plugins/pickers.nvim.md)
  (`command.handle`/`dispatch_action`), [debugging.nvim](../plugins/debugging.nvim.md)
  (`commands.lua` as the sole category→action registry; leaf modules never
  register commands themselves).

## Command/completion single-source-of-truth

- A single declarative route table should drive dispatch, Tab-completion, AND
  generated documentation simultaneously — divergence becomes structurally
  impossible — from [filetree.nvim](../plugins/filetree.nvim.md)
  (`commands.lua:311-399,457-478`, the `TREE` table),
  [pickers.nvim](../plugins/pickers.nvim.md) ("Route Tree"),
  [debugging.nvim](../plugins/debugging.nvim.md) (`docs/BINDINGS.md` links each
  table back to its source file with "any change there must be reflected
  here").
- When migrating to a new command-registration layer (e.g. `composer`), don't
  rewrite a proven flag parser — reconstruct its expected input shape from the
  new layer's parsed context instead, to avoid re-implementing edge cases —
  from [insights.nvim](../plugins/insights.nvim.md) (`bindings/usrcmds.lua:104-129`,
  `reconstruct_metrics_tokens`).
- When a command grammar classifies tokens by *form* (flags, `key=value`, bare
  words in any order) rather than *position*, keep the declarative
  completion schema and the actual dispatch logic deliberately decoupled — a
  strict positional-Composer binding can't express "any order" — from
  [language.nvim](../plugins/language.nvim.md)
  (`bindings/usrcmds/init.lua:6-19`), [insights.nvim](../plugins/insights.nvim.md)
  (`repeated_args`, identical optional slots of the same type).
- Ex-command and Lua-API completion synthesized by re-invoking the real
  dispatch function (not a parallel completion table) avoids drift — from
  [markdown.nvim](../plugins/markdown.nvim.md) (`bindings/usrcmds.lua:49-56`).

## Keymap-as-data

- Model default keymaps as a data table with a stable `id` per entry
  (overridable/disableable via `config.keymaps[id]`), not a sequence of
  `vim.keymap.set` calls — from [markdown.nvim](../plugins/markdown.nvim.md)
  (`bindings/keymaps.lua:41-70`, `DEFAULT_KEYMAPS`).
- Every keymap action should be individually disableable via a config key,
  plus a global master switch, with `lhs` accepting either a single string or
  a list of strings — from [gopath.nvim](../plugins/gopath.nvim.md)
  (guideline 11).
- Decouple action *names* from the underlying command strings in a keymap
  table, so users only need to name an action, not know the Ex-command behind
  it — from [color_my_ascii.nvim](../plugins/color_my_ascii.nvim.md)
  (`bindings/keymaps.lua` `ACTIONS` table).

## Soft dependencies

- Soft/optional dependencies always go through `pcall(require, ...)` with an
  identical-interface fallback, never a bare `require` for a "nice to have" —
  this pattern recurs almost everywhere: 
  [buffer-ctx.nvim](../plugins/buffer-ctx.nvim.md),
  [cascade.nvim](../plugins/cascade.nvim.md) (`util/lib.lua` bridge to
  `vim-repeat`, purely additive, never a hard dependency),
  [diff.nvim](../plugins/diff.nvim.md) (`pickers_bridge.lua:28-36`, checks
  both module existence AND expected function shape before using it),
  [sandbox.nvim](../plugins/sandbox.nvim.md), [filetree.nvim](../plugins/filetree.nvim.md).
- A single central `util/lib.lua`-style module should be the only place that
  attempts the `pcall(require, "lib...")` probe; other modules call that
  wrapper, never `pcall(require, ...)` directly at scattered call sites — from
  [emojis.nvim](../plugins/emojis.nvim.md) (`util/lib.lua`).
- Health checks with three distinct severities (hard-dependency error vs.
  soft-dependency-with-fallback warning vs. purely-informational note) map
  cleanly onto how hard/soft each dependency actually is in code — from
  [emojis.nvim](../plugins/emojis.nvim.md) (`health.lua:19-32`).

## Empty / dead repos

Two plugins in the audited set have no implementation and were reported as
such rather than invented content:
[neotree-fs-refactor.nvim](../plugins/neotree-fs-refactor.nvim.md) (empty
directory, not even a `.git`) and [lsp.nvim](../plugins/lsp.nvim.md) (single
`init` commit, empty README, no `lua/`). Neither contributes guidelines.
</content>
