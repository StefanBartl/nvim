# filetree.nvim — User Commands Cheatsheet

`:Filetree`/`:Ft` rebuilt via `lib.nvim.bindings.usercmd.composer` (migrated
2026-07-19) — the best existing prior art in the whole migration series
(the hand-rolled `TREE` table + dispatch + completion + `command_paths()`
doc-walker was literally the design composer generalized). **No syntax
change**: same command names, same ~64 sub-command paths, same 3-level
nesting (`filelist files abs`), same configurable name/aliases.

Source: `lua/filetree/commands.lua`
Docs: `docs/BINDINGS/USERCOMMANDS.md`, `README.md`, `doc/filetree.txt`

32 top-level groups, ~65 total sub-command paths (`M.command_paths()` still
lists them all, unchanged). See `docs/BINDINGS/USERCOMMANDS.md` for the
full per-group table.

## Notes

- **2026-08-19**: new top-level `:Filetree link` (no sub-args) — new
  `fileops/link_create` feature. Prompts for a target path (`lib.nvim.ui.kit`
  input), then creates a symlink or hardlink to it inside the tree directory
  under the cursor, named after the target's basename. A directory target
  skips the chooser and always gets a symlink (neither Windows nor POSIX
  allows an unprivileged hard link to a directory); a file target asks
  Symlink/Hardlink via `kit.confirm`. Refuses to overwrite an existing path.
  The actual link/hardlink syscalls live in `lib.nvim.cross.fs.mutate`
  (`M.symlink`/`M.hardlink`, new alongside the existing
  copy/rename/delete/mkdir_p primitives) — same hard dependency copy_move and
  smart_rename already have on that module, not a new pattern. No default
  keymap (`features.link_create.keymap`, off by default) — usercmd-first,
  like `path_copy`'s format picker.
- **2026-08-01**: new top-level `:Filetree handles` (no sub-args) — lists
  neo-tree directory-watcher handles the new `handle_guard` feature is
  tracking, flagging any pointing at a path that no longer exists (the
  Windows watcher-leak signature). Bumps the ~64/31 counts below by one;
  `M.command_paths()` picks it up automatically (it walks `TREE` live), no
  registration-layer change needed. Also new: the `template` subcommand's
  flow reversed — filename prompted before the (now extension-filtered)
  template picker, `${module}` resolved against the real destination.
- **`TREE` stays the single source of truth**: composer routes are now
  *derived* from `TREE` via a small recursive `walk_tree()` converter
  (called fresh inside `build_routes()` on every `M.setup()`), not
  hand-transcribed into ~64 individual route table literals. `TREE` itself,
  `M.command_paths()` (the doc-walker), and every leaf function are
  completely unchanged — the migration only replaced the final
  registration step (`dispatch()`/`complete()`/`usercmd.create()` → the
  route-tree walk + `composer.verb()`).
- **The `[""]` default-key pattern falls out of composer's own dispatch for
  free**: groups like `filter`/`reveal`/`mdlink`/`search`/`info`/`require`
  mix a bare default action (`filter` with no args, or `filter foo bar`
  treated as a filter query) with proper sub-commands (`filter clear`).
  `walk_tree()` registers the `[""]` handler as a route at the *parent's own
  path* (e.g. `path = {"filter"}`); composer's `tree.walk` greedily
  consumes literal children and, on hitting an unmatched token, dispatches
  to whatever route exists at the deepest node reached — which is exactly
  this node — with the unmatched token(s) landing in `ctx.rest`. No special
  fallback logic needed; it's a natural consequence of composer's existing
  walk algorithm, confirmed by reading `tree.lua` before relying on it.
- **`find` is the one special-cased route**: the only slot where the
  original completion did anything beyond generic tree-key walking
  (`vim.fn.getcompletion(arglead, "dir")` for `find`'s optional directory
  arg) — carried over via a real `DIR`-typed composer arg on that one route
  (excluded from the generic `walk_tree()` pass, added by hand with a
  `ctx.args.dir` + `ctx.rest` reconstruction). Every other route just
  forwards `ctx.rest` straight into the original, unmodified leaf function.
- **Two names (`:Filetree`/`:Ft`) share one spec table**, same pattern
  established by replacer.nvim's `:Replace`/`:Replacer` — confirmed safe,
  `composer.verb()` only reads the spec to build a route tree.
- **Teardown-before-`setup()` preserved, and still needed**: `M.setup(cfg)`
  still calls `M.teardown()` first, since `cfg` can change the registered
  command *name* between calls (e.g. `setup({command="Foo"})` after an
  earlier default `setup()`) — without tearing down the previous name(s)
  first, a rename would leave the old name(s) registered and stale
  alongside the new one. Verified via a headless re-setup-with-different-
  name test: `:Filetree`/`:Ft` correctly disappear once renamed to `:MyFt`.
  `usercmd.del()` (a thin `vim.api.nvim_del_user_command` wrapper) still
  works fine on composer-registered commands, since they're regular Neovim
  user commands underneath.
- **`filetree/util/usercmd.lua`'s `M.create()` (the lib.nvim-with-fallback
  wrapper) is now unused** — `commands.lua` calls `composer.verb()`
  directly instead. Left in place (still exports `M.del`, which IS used for
  teardown, and removing a small, harmless soft-fallback helper wasn't
  worth the churn) rather than flagged as a cleanup task.
- Added a `lib.nvim.bindings.usercmd.composer` health check — the command layer is
  now a hard dependency (no pcall), whereas the plugin's README/vimdoc
  previously described lib.nvim as fully soft-fallback-able everywhere;
  fixed to note the command layer specifically requires it.
- No CI for this repo — pre-existing, not part of this migration's scope.

## Dry-run toggles (2026-08-24)

| command | purpose |
| --- | --- |
| `:Filetree copymove dry-run` | Toggle dry-run for copy/move |
| `:Filetree renamebatch dry-run` | Toggle dry-run for batch rename |

`trash` and `safety` already had a runtime toggle; these two had `dry_run`
as a config key only, so previewing meant editing the config and reloading.

**`renamebatch`, not `rename`:** `rename` is already a leaf command (it opens
the batch-rename buffer). A table declared under the same key in the same
table literal is silently overwritten by it — which is what happened on the
first attempt, and is worth knowing before adding any further namespace to
`commands.lua`.
