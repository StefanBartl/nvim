# Handover — filetree.nvim: outgoing-link rewrite on move + collapse-blink fix

Plan for two unrelated fixes in `filetree.nvim`, analyzed and approved
2026-09-28.

Both fixes are independent and should land as separate commits. Suggested
order: Feature 2 first (small, localized), then Feature 1 (larger surface).

## Status (updated 2026-09-28, both features done)

**DONE. Both features implemented, tested, documented, committed, and a PR
is open:** [`StefanBartl/filetree.nvim#1`](https://github.com/StefanBartl/filetree.nvim/pull/1)
(`claude/filetree-path-updates-icon-fix-dc6343` → `main`), pushed from
worktree `E:\repos\filetree.nvim\.claude\worktrees\filetree-rounded-skn-b36720`.
Nothing left on this handover unless the PR review turns something up.

- **Feature 2 (collapse-blink): DONE.** Committed as `04be623 fix(adapter):
  coalesce filetree's own redraw triggers around a collapse`, matches the
  plan below exactly (`redraw_soon`, `do_narrow_redraw` consolidation,
  `TESTS/neotree_collapse_redraw_coalesce.lua`, `docs/FEATURES/BACKENDS.md`
  updated, `TESTS/MANUAL.md`/`TESTS/README.md`/`TESTS/units.lua` updated).
  Only the manual real-Neovim+neo-tree check from the plan below was never
  run (headless-only session) — the automated regression test stands in for
  it.
- **Feature 1 (outgoing-link rewrite): DONE.** Committed as `bb65e90
  feat(refs): rewrite a moved file's own outgoing links`. Matches the design
  decisions below (verified by reading the diff, not just trusting the
  shape): `own_links.collect` calls `util/fs.lua`'s `collect_recursive` and
  `pathutil.remap_under` (decision 6), `pathutil.resolve_candidates`/
  `retarget` gained the `"env"` style (decision 3), `markdown.lua`'s
  `retarget_link` returns `nil` for wikilinks (decision 5), `copy_move`'s
  `do_paste_impl` tracks `copied_moves` separately and fires a second
  `handle_result` with an empty scan result (decision 7), `refs/init.lua`'s
  `handle_result` merges incoming + own-links edits into one confirmation/
  undo when both sides share an effective mode (decision 2).
  - New fixture tree `TESTS/refs/fixtures/markdown_own_links/` plus 4 new
    checks in `TESTS/refs/run.lua` (`run_own_links_move_check` — also proves
    the merged-undo behavior by combining an incoming ref and an own-links
    edit in one move and reverting both with a single `refs.undo()`;
    `run_own_links_dir_move_check`; `run_own_links_env_var_check` — a
    `$VAR`-rooted link whose own target moves in the same directory rename,
    re-folded back into `$VAR/...` form; `run_own_links_copy_check`).
  - `docs/FEATURES/FILEOPS.md` gained a "Rewriting a moved file's own
    outgoing links" section plus the `outgoing_links` config block.
  - Verified: `luacheck` clean repo-wide (138 files), `stylua --check` clean
    on every changed file, `TESTS/refs/run.lua` 195/195, `TESTS/config_schema.lua`
    241/241, `TESTS/units.lua` 443/443 (all run headless via
    `FILETREE_LIB_NVIM=E:/repos/lib.nvim FILETREE_UI_NVIM=E:/repos/ui.nvim
    nvim --clean --headless -u NONE -l TESTS/<file>.lua` — the sibling-repo
    lookup in `TESTS/refs/run.lua`'s `add_lib_nvim`/`add_ui_nvim` only finds
    `E:/repos/lib.nvim`/`ui.nvim` automatically from the *original* repo
    checkout, not from inside a `.claude/worktrees/...` path, so those two
    env vars are needed whenever running these suites from a worktree).
  - One curiosity, not a bug: the `run_own_links_env_var_check` smart_rename
    call logs `"2 skipped: line changed since the scan"` — the enabled
    `experimental.plaintext` bareword provider also matches the literal
    string "Notes" inside the `$TESTVAR/Notes/Asset.txt` line itself, races
    the same line own_links already rewrote, and the content-drift guard
    correctly skips it rather than double-editing. Benign (own_links'
    rewrite still lands, asserted), but only surfaces when both
    `experimental.plaintext.enabled` and `outgoing_links.enabled` are on at
    once with an env-var name that overlaps a real directory name nearby —
    worth a one-line docs/BACKLOG note if it ever comes up for real, not
    worth chasing further here.

## Bug reports (verbatim intent from Stefan)

1. Moving/pasting a file (`x` cut, or `c`+`p` copy-paste) to a different
   folder does not rewrite paths found *inside* the moved file's own content.
   Example: `Research/Research.md` links to `../assets/Screenshot.png`; after
   moving `Research.md` up one level, that link is now wrong. The existing
   "other files that reference this file get updated" feature does not cover
   this — the moved file's own outgoing links need the same treatment. Must
   handle absolute paths, relative paths, and paths rooted in env vars like
   `$REPOS_DIR` or `$NVIM_CONFIG_DIR`.
2. With two nested folders open in the tree, a file in the inner folder has
   unsaved changes and correctly shows the "modified" icon next to the file
   node. Closing the containing folder makes the icon "blink" a few times
   next to the now-collapsed folder node before it disappears.

## Feature 1 — Rewrite outgoing links inside a moved/renamed/copied file

### Existing architecture (verified by reading the code)

- Central engine: [`refs/init.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/refs/init.lua)
  — `refs.prefetch(paths, opts)` scans the project for *incoming* references,
  then `refs.handle_result(scan_result, moves, opts)` resolves + applies.
  `moves` is `{[old_path]=new_path}`.
- Callers of this pipeline:
  [`fileops/move`]($REPOS_DIR/filetree.nvim/lua/filetree/features/fileops/move/init.lua),
  [`fileops/copy_move`]($REPOS_DIR/filetree.nvim/lua/filetree/features/fileops/copy_move/init.lua),
  [`fileops/rename_batch`]($REPOS_DIR/filetree.nvim/lua/filetree/features/fileops/rename_batch/init.lua),
  [`fileops/smart_rename`]($REPOS_DIR/filetree.nvim/lua/filetree/features/fileops/smart_rename/init.lua).
- The mirror-image primitive already exists:
  [`refs/outgoing.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/refs/outgoing.lua)
  `M.scan(path, opts, cb)` reads a file's own lines and resolves every link
  target to an absolute path — but today it is used only by
  [`refs/assets.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/refs/assets.lua)
  (cascade-delete-assets concept) purely for classification, never for
  rewriting. Only the markdown provider implements `each_link_target`
  ([`providers/markdown.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/refs/providers/markdown.lua),
  lines ~189-196).
- Rewrite/apply mechanism, reusable as-is:
  [`refs/apply.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/refs/apply.lua)
  `M.run(refs, opts, on_done)` — groups by file/line, content-verifies before
  writing, routes through the buffer if loaded else `readfile`/`writefile`,
  pushes one undo token (`:Filetree refs undo`).
- Path resolution: [`refs/pathutil.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/refs/pathutil.lua)
  `M.resolve_candidates` handles `~`, drive letters, leading `/` — **no**
  `$VAR` branch today. `M.match`/`M.retarget` support styles
  `"fs"|"root"|"relative"`. `M.abs()` deliberately does not expand env vars.
- Env-var fold utility (reverse direction of what's needed):
  [`util/path.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/util/path.lua)
  `M.env_rooted(p, names, extra)` (lines ~168-204) — folds an absolute path
  into `$VAR/rest` form, longest match, with an `extra` list for pseudo-vars
  like `$NVIM_CONFIG_DIR` (backed by `vim.fn.stdpath("config")`, not a real
  env var). Used today only by
  [`features/paths/path_copy`]($REPOS_DIR/filetree.nvim/lua/filetree/features/paths/path_copy/init.lua)'s
  clipboard-copy helper (one-way).
- Markdown link detection already covers inline links, images
  (`![alt](path)`), reference-style definitions, `src=`/`href=` attributes,
  and optional wikilinks — no changes needed there, only the resolve/retarget
  side is missing.
- Test conventions: [`TESTS/refs/run.lua`]($REPOS_DIR/filetree.nvim/TESTS/refs/run.lua),
  fixtures under `TESTS/refs/fixtures/<lang>/`, `on_move="auto"`/
  `on_rename="auto"` skips UI prompts, assertions on final file content plus
  negative controls (assert a string stayed *unchanged* to catch
  over-matching).

### Design decisions

1. New module `lua/filetree/refs/own_links.lua`, pure function
   `M.collect(moves, opts) -> FiletreeRef[]`. Only gathers edit records,
   mirrors the existing `refs.resolve()` (gather) vs. `refs.handle_result()`
   (orchestrate) split.
2. Hooked into `refs.handle_result`, not a parallel dialog: in the default
   case (same mode for incoming and outgoing fixes) both lists are merged
   into **one** `ui.apply_with_confirmation` call → one dialog, one undo
   token for the whole operation. Only an explicitly configured divergent
   `outgoing_links.mode` causes two separate applies/undo entries.
3. `pathutil.resolve_candidates` gets a `$VAR` branch via an optional `env`
   parameter (`{names, extra}`, mirroring `util/path.lua`'s `env_rooted`
   signature) — injected, not read via `require("filetree.refs")` from
   inside pathutil (load-order cycle risk: providers need pathutil,
   `refs/init.lua` needs providers). Backward compatible — no `env` param,
   unchanged behavior. Also returns the detected style
   (`"env"|"fs"|"root"|"relative"`) as a second value so `M.match` stops
   duplicating that logic. `M.retarget` gains a 4th style, `"env"`, via
   `ftpath.env_rooted(new_path, opts.env.names, opts.env.extra)`.
4. `outgoing.lua` resolves relative to a separately-passed base
   (`opts.base`, defaults to `path` as today): a link's raw text was
   authored relative to the file's *old* location, but scanning happens
   after the move, at the file's *new* path. `resolve_one` also returns the
   detected style; `FiletreeOutgoingLink` (in
   [`@types/refs.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/@types/refs.lua))
   gets a new `style` field. `assets.lua` (the only other caller) stays
   compatible since `base`/`env`/`style` are optional.
5. Retargeting delegated to a new optional provider method
   `retarget_link(link, new_target_abs, ctx)`, implemented in
   `providers/markdown.lua` via `pathutil.retarget(...)` plus the existing
   local `url_encode`. Wikilinks (`kind=="wiki"`) return `nil` in v1 — no
   rewrite — since `wiki_links` already defaults off and their retarget
   logic has no equivalent in the generic scan path; documented scope cut,
   not a silent wrong rewrite.
6. `own_links.collect` expands directory moves into per-file work via
   [`util/fs.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/util/fs.lua)
   `M.collect_recursive(root, "files", ignore_fn)`, and remaps a link target
   that was itself moved in the same batch (e.g. a folder containing both
   `Research.md` and `assets/Screenshot.png`) via `pathutil.remap_under`/the
   `moves` table before rendering the new link text.
7. Copy handling wired separately from `_cfg.copy` (which only gates
   incoming refs and is effectively dead for copy today). In
   [`copy_move/init.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/features/fileops/copy_move/init.lua)
   `do_paste_impl`, track a second table `copied_moves` (old source → new
   pasted path) and call `refs.handle_result` a second time with an empty
   scan result so only `own_links.collect` contributes. Critical negative
   control: the original file at its old location must never be touched by
   this.

### Config (`refs/DEFAULTS.lua`)

```lua
outgoing_links = {
  enabled = false,  -- opt-in, same posture as outgoing_assets/experimental.plaintext
  mode = nil,       -- "ask"|"auto"|"off"|nil; nil => inherits on_move/on_rename
  env_vars = {},    -- e.g. {"REPOS_DIR"} -- names without "$"
  -- $NVIM_CONFIG_DIR is always available as a pseudo-var (stdpath("config")),
  -- mirroring util.path.env_rooted's "extra" convention.
},
```

Plus `@field outgoing_links?` in `@types/refs.lua` and a status line in
`refs.status()` mirroring the existing `outgoing_assets` line.

### Tests

New fixture dir `TESTS/refs/fixtures/markdown_own_links/` (kept separate
from the shared `fixtures/markdown/` tree so the directory-move case doesn't
perturb existing checks):

- `run_own_links_move_check()` — move a file with a relative, an absolute,
  and (when `env_vars` configured) a `$VAR`-rooted link; assert the relative
  link is correctly re-derived (negative control against the naively-wrong
  resolution), the absolute link is unchanged, and a single `refs.undo()`
  reverts both rewrite kinds together.
- `run_own_links_dir_move_check()` — move a whole directory with a nested
  file, assert `collect_recursive` expansion covers every file under it.
- `run_own_links_env_var_check()` — set `outgoing_links.env_vars`, assert
  pre-move resolution via `refs.outgoing()` and post-move re-render in the
  same `$VAR` form.
- A fourth check exercises the copy path in `copy_move`: the pasted copy's
  link is rewritten, the original file is byte-identical to before.

Every new check calls `check_fixtures_match_spec` first (existing
convention against fixture/spec drift).

### Files touched

- `lua/filetree/refs/own_links.lua` (new)
- `lua/filetree/refs/outgoing.lua`
- `lua/filetree/refs/pathutil.lua`
- `lua/filetree/refs/init.lua`
- `lua/filetree/refs/providers/markdown.lua`
- `lua/filetree/refs/DEFAULTS.lua`
- `lua/filetree/@types/refs.lua`
- `lua/filetree/features/fileops/copy_move/init.lua`
- `TESTS/refs/run.lua` (+ new fixtures)

## Feature 2 — Modified-icon blink on folder collapse

### Existing architecture (verified)

- [`adapter/neotree.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/adapter/neotree.lua):
  `M.collapse_node` (~731-783) calls `target:collapse()`, then synchronously
  `pcall(renderer.redraw, state)` (~774) and `renderer.focus_node` (~776),
  which moves the cursor and fires `CursorMoved`. `M.expand_node` (~636-649)
  has a third, uncoordinated inline copy of the same redraw call (~646).
  `M.redraw()` (~935-941) is the existing named public entry point.
- [`features/ui/opened_sync/init.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/features/ui/opened_sync/init.lua)
  independently triggers on `BufAdd/BufDelete/BufWipeout/BufWinEnter/
  BufWinLeave`, debounced 60ms, and calls `adapter.redraw()` — per its own
  doc comment, to keep neo-tree's `highlight_opened_files`-style decoration
  in sync, which is a *different* thing from `enable_opened_markers`/
  `enable_modified_markers` (the native icon). Not redundant — must not be
  removed outright.
- There is already a global monkeypatch on `renderer.redraw` itself
  (`install_redraw_hook`, ~line 1200) that notifies subscribers *after*
  every redraw call, from any caller including neo-tree's own internals.
  It exists today only to redraw filetree's own extmark decorations (marks
  checkmarks, symlink signs) after a "narrow redraw" wipes them — not to
  coalesce/delay redraw calls. Adding debounce there would affect every
  caller including neo-tree-internal, timing-sensitive ones — too invasive,
  and out of step with this codebase's conservative style (it already
  documents its own "residual limitation, clearly disclosed" cases). **Not
  touched.**
- `git_status`, `link_marker`, `current_hl` draw their own decorations
  directly via extmarks (`nvim_buf_set_extmark`) and do **not** call
  `renderer.redraw`/`adapter.redraw()` — they don't contribute to the actual
  blink (a full tree re-render) and are left alone.

### Plan

1. New small coalescing helper `M.redraw_soon()` in `adapter/neotree.lua`,
   next to `M.redraw()`, using `lib.nvim.debounce` (repo convention already
   used by `current_hl`/`opened_sync`/`git_status`/`link_marker`), fixed
   small window (~30ms), only to coalesce multiple **filetree-own** redraw
   requests landing close together:

   ```lua
   function M.redraw_soon()
     if not _redraw_soon then
       _redraw_soon = lib_debounce.new(function() M.redraw() end, 30)
     end
     _redraw_soon.call()
     return true
   end
   ```

   New optional capability field `redraw_soon?` in
   [`@types/adapter.lua`]($REPOS_DIR/filetree.nvim/lua/filetree/@types/adapter.lua)
   next to the existing `redraw?`.
2. `opened_sync.redraw_now()` uses `redraw_soon` when available, else falls
   back to `redraw` (capability-probed, backward compatible, no config
   change in `opened_sync` itself — its own `debounce_ms` still decides
   *when* to request a redraw at all).
3. `collapse_node`/`expand_node` stay synchronous, same ordering (do **not**
   defer, `focus_node` stays *after* the redraw): `renderer.focus_node`
   needs the already-rendered line state; deferring the redraw risks the
   cursor landing on a stale line — worse than the bug being fixed. Only
   change: the three separate inline `pcall(require(...)); pcall(renderer
   .redraw, state)` copies (lines ~646, ~774, ~940) get unified behind one
   internal helper `do_narrow_redraw(state)` — pure consolidation, no
   behavior change.
4. Deliberately not touched: `git_status`/`link_marker`/`current_hl` (no
   `renderer.redraw` call to begin with) and the global `renderer.redraw`
   monkeypatch.
5. Explicit, documented limitation (as a code comment on `collapse_node` and
   in this handover): this only reduces filetree's *own* contribution to
   the redraw burst around a collapse. It cannot affect neo-tree's own
   internal redraw timing (`opened_buffers_changed`'s debounce,
   watcher-driven redraws, the native icon recompute) — those live entirely
   in the external `neo-tree.nvim` dependency. A residual blink sourced
   purely from neo-tree's own internals may still be observable.

### Verification

Manual (primary — a visual "blink" isn't meaningfully assertable
automatically):
1. Open two nested folders `A/B/`, make a file in `A/B/` dirty (unsaved).
2. Collapse `A/` (not `B/` — this is the path that reproduces the bug).
3. Compare before/after: expect less flicker, not a guaranteed full fix.
4. Re-run with `features.opened_sync.enabled = false` to isolate its share
   from neo-tree's own internal timing.

Automated regression test (new,
`TESTS/neotree_collapse_redraw_coalesce.lua`, following
`TESTS/neotree_redraw_hook.lua`/`TESTS/nav_switch_toggle.lua`'s
counting-stub technique): stub `renderer.redraw` to count calls, open a real
neo-tree tree with two nested folders, mark a buffer under the inner one
modified, fire a Buf* event close to calling `adapter.collapse_node(node)`,
wait past the coalescing window, and assert the total `renderer.redraw`
call count is `2` (collapse_node's own call, plus one coalesced call) rather
than `3+`.

### Files touched

- `lua/filetree/adapter/neotree.lua`
- `lua/filetree/features/ui/opened_sync/init.lua`
- `lua/filetree/@types/adapter.lua`
- `TESTS/neotree_collapse_redraw_coalesce.lua` (new)
- `docs/FEATURES/BACKENDS.md` (render-event-bridge section: mention
  `redraw_soon` and the scope limitation)

## Overall verification

- `luacheck`/`stylua` green.
- `TESTS/refs/run.lua` including new checks green.
- New `TESTS/neotree_collapse_redraw_coalesce.lua` green.
- Manual check of both scenarios in real Neovim + neo-tree.
- Docs updated: `docs/FEATURES/BACKENDS.md` (redraw bridge) and
  `docs/FEATURES/`/README for the new `outgoing_links` option.
