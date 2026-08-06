# Doing `:MyPlugins`' job with `reposcope.nvim` instead

`:MyPlugins` (see [`lua/bindings/usrcmds/plugin_repos/`](../../lua/bindings/usrcmds/plugin_repos/README.md))
and [`reposcope.nvim`](https://github.com/StefanBartl/reposcope.nvim) solve
overlapping problems — both clone, both bulk-update — but from opposite
directions: `:MyPlugins` starts from a **fixed named list**
(`plugins.personal.list`) and asks "is each of these 29 repos present, in
sync, clean?"; reposcope starts from an **arbitrary directory** and asks
"what git repos live directly inside this folder?". This note is about
what it would take to lean on reposcope for the two-machine `dir`-mode sync
workflow instead of the custom `ops.lua`/`picker.lua` just added — what
already fits, and what's actually missing.

## What reposcope already does today

- **`:Reposcope update [dir]`** — `git fetch --all --prune` + `git pull
  --ff-only` on every immediate subdirectory of `dir` (default
  `clone.std_dir`), sequential and async, errors collected into one summary.
  This is *exactly* the same two git calls `ops.update_one` runs — reposcope
  already has the sync half of the workflow, directory-scan style.
- **`:Reposcope status [dir] [--out] [--to]`** — richer than `:MyPlugins
  list`'s `+`/`-` presence marker: per repo it reports branch,
  ahead/behind counts and a dirty-file count, rolled up into
  `clean`/`dirty`/`ahead`/`behind`/`diverged`. `--out=popup|buffer|split
  |vsplit|clipboard|path` covers "just let me read this somewhere sane"
  in a way `:MyPlugins list`'s single `vim.notify` doesn't.
- **Discovery + single clone** — `:Reposcope start` opens a search UI
  (GitHub/GitLab/Codeberg, filterable by keywords/owner/language/topic/
  stars), `<C-c>` clones whatever's under the cursor. Good for finding new
  repos, not built for "clone these 29 specific ones I already know the
  names of."

## Why `:Reposcope update $REPOS_DIR` is actually fine (unlike `remove`)

`:MyPlugins`' README spends a whole section on why `clone`/`remove` never
scan `dir` — the risk is asymmetric: an unrelated repo picked up by a scan
gets an unwanted `git pull` (harmless) if it's `update`, but gets
`vim.fn.delete(path, "rf")` (permanent data loss) if it's `remove`. That
asymmetry means the scan-safety argument only bites for **deletion**
(`remove`/`reclone`'s delete half). `:Reposcope update $REPOS_DIR` never
deletes anything — worst case it fetches and fast-forward-pulls `Notes` or
`WKDBooks` along with the plugins, which is just wasted network+CPU, not a
risk. So for the fetch/pull/update third of the workflow, reposcope's
existing directory-scan command is a legitimate drop-in replacement for
`:MyPlugins update` — point it at `$REPOS_DIR` and it does the same two git
calls on the same plugin checkouts, plus a few harmless extra ones on
non-plugin folders.

```vim
:Reposcope update $REPOS_DIR   " same fetch+pull as :MyPlugins update, on everything under $REPOS_DIR
:Reposcope status $REPOS_DIR   " richer read-only overview than :MyPlugins list
```

## What's genuinely missing

1. **No named-list scoping.** Reposcope has no concept of "these specific
   29 repos, regardless of what else lives in this folder." Every command
   is directory-scan-based by design (that's its whole value proposition
   for discovery). `:MyPlugins`'s `--only=<name>` flag and its
   `plugins.personal.list` grounding have no reposcope equivalent — adding
   one would mean reposcope growing a "managed set" concept (e.g. a
   `watch_list` config table or a `:Reposcope track <name>` command),
   which is scope creep for a repo-*discovery* tool.

2. **No delete/remove/reclone command at all.** Reposcope clones and
   updates; it has nothing that deletes a checkout, safety-checked or
   not. `:MyPlugins remove`'s `git status --porcelain --branch` gate
   (nothing uncommitted, nothing unpushed) and its `reclone` (delete-then-
   clone-fresh) would both need to be built from scratch in reposcope —
   plausible (the git-status plumbing `:Reposcope status` already has
   gets you most of the way to the "is this safe to delete" check), but
   it doesn't exist today.

3. **No batch multi-action picker.** Reposcope's UI is a search-results
   list with single-item actions (`<C-c>` clone, `<C-v>`/`<C-b>` view/edit
   README) — there's no per-item state you cycle through and commit as a
   batch. `:MyPlugins picker`'s "`<Tab>` cycles this one row through
   update/pull/fetch/remove/reclone, `<CR>` runs everything assigned at
   once" would be a new UI mode, not an extension of the existing one
   (the existing list is API search results, not a fixed local checkout
   list with per-repo lifecycle state).

4. **No batch clone of a known list.** Cloning all 29 personal plugins
   via reposcope's UI means either 29 individual `<C-c>` presses off a
   filtered search, or scripting `:Reposcope prompt` + repeated searches —
   nothing like `:MyPlugins clone`'s "clone everything in the list that's
   missing, one command."

## Sketch: what reposcope would need to fully absorb this

Not a plan to actually build — just what the gap looks like, for whenever
this is worth revisiting:

- A `watch_list` (or `tracked`) option: an explicit array of `owner/repo`
  strings, analogous to `plugins.personal.list`. `:Reposcope update
  --tracked-only` / `:Reposcope status --tracked-only` would then scope to
  exactly that set instead of scanning `dir`, closing gap #1.
- `:Reposcope prune [dir]`: reuse `:Reposcope status`'s existing git-status
  plumbing to compute the same "clean" gate `:MyPlugins remove` uses, list
  the safe-to-delete set, confirm, delete. Closes gap #2 (`remove`);
  `reclone` falls out of `prune` + `clone` on the same name.
- `:Reposcope clone-all [--tracked-only]`: iterate the watch list (or the
  last search results) and clone everything not yet present, mirroring
  `:MyPlugins clone`'s batch/skip-existing behavior. Closes gap #4.
- A management-mode UI distinct from the search UI: rows = watch-list
  entries instead of API search results, `<Tab>` cycles a per-row pending
  action the way `:MyPlugins picker` does now, `<CR>` runs the batch through
  whatever `update`/`prune`/`clone-all` ends up being. Closes gap #3.

Until (if ever) that lands, `:MyPlugins` stays the tool for anything
involving the fixed plugin list (`clone`/`remove`/`reclone`/`--only`/the
picker), and `:Reposcope update`/`status $REPOS_DIR` remain a perfectly
reasonable — if slightly noisier — alternative for just the fetch/pull/
update third of the two-machine sync workflow.

## See also

- [`lua/bindings/usrcmds/plugin_repos/README.md`](../../lua/bindings/usrcmds/plugin_repos/README.md) — `:MyPlugins` implementation notes, including the two-machine sync case
- [`docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/MyPlugins.md`](PersonelPlugins/BINDINGS/Usercmds/MyPlugins.md) — user-facing `:MyPlugins` cheatsheet
- [`docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/reposcope.nvim.md`](PersonelPlugins/BINDINGS/Usercmds/reposcope.nvim.md) — user-facing `:Reposcope` cheatsheet
- `reposcope.nvim`'s own [`docs/COMMANDS.md`](https://github.com/StefanBartl/reposcope.nvim/blob/main/docs/COMMANDS.md) and [`docs/FEATURES.md`](https://github.com/StefanBartl/reposcope.nvim/blob/main/docs/FEATURES.md)
