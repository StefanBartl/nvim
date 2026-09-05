# Testing reposcope.nvim

How to manually test every implemented feature of `reposcope.nvim`.
One-time setup, then one section per feature: prerequisites, steps, what
to expect. Checkbox syntax (`- [ ]`) throughout.

Repo: `$REPOS_DIR\reposcope.nvim`. Spec: `lua/plugins/personal/init.lua` —
`name = "reposcope"`, `event = "VeryLazy"`, `dependencies = {
"StefanBartl/lib.nvim" }`, `opts = { progress_style = "statusline" }` (the
only override — `:Reposcope update`/`status` report into `lib.nvim`'s
shared progress registry, rendered by the statusline's `plugin_progress`
module; everything else below is the plugin's own default).

**Telemetry note**: only 2 accumulated sessions, 124 calls total, and none
of them are `bindings.`/`commands.`/`usrcmds`/`keymaps`/`handler.`-shaped
entry points — per the "only trust entry points" rule this gives no real
priority signal. What the raw numbers *do* hint at, informally: `utils.
repos.is_git_repo` (76), `ui.actions.status_view.render` (14), `utils.
repo_actions.push/pull/fetch` (3/2/1) and `utils.repo_status.status_all`
(2) suggest the maintenance dashboard (§3) got real use on this machine —
consistent with it being the second-listed capability in the README. Search
and clone show zero telemetry, likely because they were used in a session
that predates this instrumentation, not because they're untested territory.
Ordering below follows the README's own Capabilities table and
`docs/WORKFLOW.md`'s "core loop" framing instead of the call counts.

## Setup

```vim
:checkhealth reposcope
```

**Expect**: core modules loaded OK; at least one of `gh`/`curl`/`wget`
reported per-binary (all three checked individually, not just "any one");
the **configured** `request_tool` cross-checked against that list —
`gh` is the default here (`config/DEFAULTS.lua`, unchanged by this config's
`opts`), so this only passes clean if `gh` is actually installed; and
`GITHUB_TOKEN` presence (warn, not error, if absent — rate-limited, not
broken).

**The auth trap to check first, given this config's actual settings**: this
config never sets `request_tool` or `github_token` in `opts`, so it's
running with `request_tool = "gh"` and whatever `GITHUB_TOKEN` env var
happens to be in Neovim's environment. Per `docs/AUTHENTICATION.md`, a
`gh auth login` session is **not** visible to reposcope's child processes —
only an explicit token (env var forwarded, or `github_token` in `setup()`)
works. Confirm searches actually succeed before trusting anything else
below; if `gh`-based requests silently fail, that's this exact trap.

A good test target: search for something you know exists, e.g. `keywords =
neovim`, `owner = StefanBartl` — real, checkable results.

---

## 1. Core loop: search → preview → clone

The everyday shape the whole plugin is built around.

**Steps**

```vim
:Reposcope start
```

1. Type into the `keywords` field (e.g. `spotlight`), `<Tab>` to `owner`
   (e.g. `StefanBartl`), `<CR>` to search.
2. `<Up>`/`<Down>` through the results.
3. `<C-c>` on a real, small repo.

- [ ] Step 1 returns real results — check the count is sane, not empty or
      truncated oddly.
- [ ] Step 2: moving the selection auto-loads that repository's README
      into the preview window — confirm it's the **real** README content
      (spot-check one you know), not a placeholder.
- [ ] Step 3 clones into `clone.std_dir` (this config: `$REPOS_DIR` env var
      if set, else `~/temp` — check `:lua print(require("reposcope.config").
      get_option("clone").std_dir)` first) using the configured `clone.type`
      (default empty string → plain `git clone`). Confirm the directory
      actually appears on disk afterward.
- [ ] `<C-v>` opens the current README fullscreen (or in the system browser
      if it looks like HTML); `<C-b>` instead drops it into a hidden named
      scratch buffer — confirm both, and that `<C-b>`'s buffer is real text
      you can select/yank/script against.
- [ ] `?` shows the keymap cheatsheet — cross-check it against
      `docs/BINDINGS.md`'s own table; it's generated from the same
      `ACTION_ORDER` table that binds the keys, so it should never drift.
- [ ] `<Esc>` closes everything (list, prompt, preview, background) in one
      go — confirm no window is left behind.

---

## 2. README caching, pre-warming, and pre-caching

**Steps**

1. Run a search, scroll quickly through several results (don't pause on
   any), then scroll back slowly.
2. Restart Neovim, run the **same** search again.
3. `:Reposcope skipped-readmes` right after step 1's fast scroll.

- [ ] Step 1's fast pass should not fire a fetch per row — only the row you
      actually settle on (debounced). The slow pass back through should
      show instant previews for anything already fetched.
- [ ] Step 3 reports a nonzero skipped count after the fast scroll — the
      documented way to tell "debounce skipped this on purpose" from
      "something is broken" (per `docs/WORKFLOW.md`).
- [ ] Step 2: a repo's README from a **previous session** should load
      instantly from the file cache, no network round-trip needed (spot
      this via `:Reposcope toggle-dev` + `:Reposcope stats`, or just by how
      fast it appears).
- [ ] Right after any fresh search completes, without touching the list at
      all, wait a moment then scroll to result #3 or #4 — should already be
      warm (`readme_precache_count = 5` default: the top 5 results are
      fetched in the background immediately after search, regardless of
      whether you scroll to them).
- [ ] No `:Reposcope` subcommand force-refreshes a single cached README —
      confirm this is genuinely absent (only `cache.readme_cache.clear(owner,
      repo)`/`clear_all()` via Lua, per `docs/WORKFLOW.md`) rather than you
      having missed a command.

---

## 3. The status dashboard (`:Reposcope status`) — likely the most exercised feature here

**Prerequisites**: a directory with at least 2–3 real git clones — point at
`clone.std_dir` if it's already populated from §1, or pass an explicit
directory with real repos (e.g. `$REPOS_DIR` itself has plenty).

**Steps**

```vim
:Reposcope status $REPOS_DIR
```

- [ ] A popup table appears: `REPOSITORY / BRANCH / SYNC / STATE / LAST
      COMMIT`, one row per **immediate subdirectory** only — confirm a
      nested clone (a repo inside a repo, if you have one) is invisible.
- [ ] The `SYNC` column (`↑N ↓N`) appears **only** for repos that have
      actually diverged from upstream — confirm it's entirely absent from
      the table if nothing has, rather than showing `+0/-0` on every row.
- [ ] `s` cycles sort: discovery → name → **state** → age → discovery.
      Confirm `state` ranks **worst-first** (diverged, dirty, behind,
      ahead, clean) — not alphabetical.
- [ ] On a row: `p` (push), `P` (pull `--ff-only`), `f` (fetch `--prune`) —
      each shows a spinner (check the statusline's `plugin_progress`
      component too, since `progress_style = "statusline"` is this config's
      own override), then re-reads and redraws just that row in place, no
      full rescan.
- [ ] `S` on a row opens a nested popup with `git status --short` plus the
      last 5 commits — the way to tell a stray build artifact from real
      uncommitted work.
- [ ] `<CR>` on a row opens that repo's `README.md`; `q` inside it closes
      and returns to the **same row** in the overview (not a full
      re-scan) — this is the specific thing `docs/WORKFLOW.md` flags as
      recently fixed (used to tear the whole popup down with no way back).
- [ ] `r` re-reads just the current row; `R` re-scans the whole directory —
      confirm `R` re-reads the directory you actually passed
      (`$REPOS_DIR` here), not the configured `clone.std_dir` default.
- [ ] `y` yanks the repository's path — paste it somewhere to confirm.
- [ ] `?` lists every one of these keys — confirm it includes `r`/`R`/`y`,
      which are deliberately left out of the winbar's shortened legend to
      keep it on one line.
- [ ] `--out=split` / `--out=vsplit` / `--out=buffer` / `--out=clipboard` /
      `--out=path --to=<file>` — try at least two: confirm `clipboard`
      actually reaches the system clipboard (paste it), and `path` writes a
      real file at the given path (default `stdpath("cache")/reposcope/
      status.txt` if `--to` omitted).
- [ ] `<Tab>` on the `[dir]` argument — should offer `$REPOS_DIR` and `~`
      up front (if resolvable) plus real directory completion.

---

## 4. Bulk update (`:Reposcope update`)

**Steps** (same directory as §3, or a subset you don't mind actually
fetching/pulling)

```vim
:Reposcope update $REPOS_DIR
```

- [ ] Runs `git fetch --all --prune` then `git pull --ff-only` per repo,
      sequentially but asynchronously — confirm Neovim stays responsive
      (type something) while it runs.
- [ ] A repo shown as `diverged` in §3's status should **fail** here (an
      error in the summary), never silently rewrite local history —
      fast-forward-only refuses that by design.
- [ ] A non-git subdirectory is silently skipped, not reported as an error.
- [ ] The finishing summary names real repos/errors, not a generic "done".
- [ ] Progress shows in the statusline (`progress_style = "statusline"`,
      this config's setting) while the bulk run is in flight.

---

## 5. Filter and sort

**Steps**

With a real result list on screen (from §1):

```vim
:Reposcope filter <Tab>
```

then pick a real owner or name from the completion, `<CR>`.

- [ ] `<Tab>` completion offers only names/owners **actually in the current
      result set**, prefix-matched — not a guess against anything global.
- [ ] The filter narrows to a real, case-insensitive substring match over
      `owner/name: description` — confirm a match on the description alone
      (not just the name) actually works.
- [ ] `:Reposcope filter` with no argument clears the filter, restoring the
      full result set.
- [ ] `:Reposcope filter-prompt` — floating input, same matching behavior,
      empty input cancels rather than filtering to nothing.
- [ ] `:Reposcope sort` opens an interactive menu — pick a mode, confirm
      the list actually reorders.

---

## 6. Favorites

**Steps**

```vim
:Reposcope start
```

1. Search, move to a result, `<C-f>` to favorite it.
2. `:Reposcope favorites`.
3. `:Reposcope close`, then `:Reposcope start` again (fresh open, no
   session save/restore involved).

- [ ] Step 1: `<C-f>` toggles a favorite — confirm a visible indicator on
      the row (check `docs/BINDINGS.md`/the list highlight for what marks
      it).
- [ ] Step 2 lists it with real metadata (owner, name, description, URL,
      stars) in a scrollable popup.
- [ ] Step 3: **with any favorites saved**, `:Reposcope start` should show
      the favorited list **immediately** — no prompt, no network call, and
      the first entry's README preview already warm (pre-loaded from the
      favorite's own snapshot, not a live fetch). This is the behavior
      difference worth confirming specifically: it only kicks in because a
      favorite exists, unrelated to session save/restore (§7).
- [ ] `<C-f>` again on the same repo un-favorites it; `:Reposcope favorites
      clear` removes all of them — confirm a subsequent `:Reposcope start`
      goes back to the plain empty prompt.
- [ ] Restart Neovim entirely, `:Reposcope favorites` — favorites persist
      across restarts (JSON under the plugin's cache directory).

---

## 7. Session persistence

**Steps**

```vim
:Reposcope start
```

1. Search something specific, apply a filter and a non-default sort.
2. `:Reposcope session save`.
3. `:Reposcope close`, change the search to something else, `:Reposcope
   session restore`.
4. Switch `provider` (e.g. `:lua require("reposcope.config").set_option
   ("provider", "gitlab")` or via `setup()`), then `session restore` again.

- [ ] Step 3 restores the **exact** provider, prompt field values, last
      query, filter text, and sort mode from step 1 — not just re-running a
      generic search.
- [ ] Confirm `restore` re-runs the search **asynchronously** and applies
      the saved filter/sort only *after* results land — if you script
      something that assumes the list is already populated right after
      `restore`, it should visibly race (results appear a beat after the
      command returns).
- [ ] Step 4: restoring a session saved under a **different** provider than
      the one currently active should flip `provider` back to what was
      active at save time — confirm via `:Reposcope providers` right after.
- [ ] Session `save`/`restore`/`clear` never touch window **layout** —
      confirm by changing `layout` config or moving windows around, then
      restoring: the layout should reflect the *current* config, not
      whatever was on screen at save time.
- [ ] `:Reposcope session clear`, then `session restore` — should behave as
      if no session ever existed (falls through to favorites if any exist,
      per §6, or the empty prompt otherwise), not error.

---

## 8. Query-frequency tracking

**Steps**

Run 3–4 different real searches (varying keywords/owner), including one
repeated twice.

```vim
:Reposcope queries
```

- [ ] Lists up to 10 queries, **most-frequent first** — the repeated one
      should rank above the ones run once.
- [ ] No opt-in was needed — this recorded automatically from real `<CR>`
      searches in §1/§5 above, with no separate toggle.
- [ ] `:Reposcope queries clear` resets it — confirm a subsequent `queries
      list` is empty.

---

## 9. Providers

**Prerequisites**: to actually exercise GitLab/Codeberg, either set
`gitlab_token`/`codeberg_token` or accept the lower anonymous rate limit.

**Steps**

```vim
:Reposcope providers
```

then switch and search on each:

```lua
require("reposcope").setup({ provider = "gitlab" })
```

- [ ] Bare `:Reposcope providers` marks the currently active one with `*`
      and lists all three (`codeberg`, `github`, `gitlab`).
- [ ] After switching to `gitlab`, a real search returns real GitLab
      results (different shape/URLs from GitHub's), and `<C-c>` clones via
      GitLab's own clone path.
- [ ] Switching providers does **not** migrate prompt/session/cache state —
      confirm a search from the previous provider isn't still showing after
      the switch (should be a clean prompt or provider-appropriate state).
- [ ] README/favorite caches are keyed by `owner/repo_name` only, **not**
      by provider — if you have (or can construct) a same-named repo on two
      providers, confirm this is a real, documented collision risk rather
      than something silently handled.
- [ ] Switch to a provider whose token isn't set and try a search — should
      fail cleanly (rate-limited or an explicit auth error), not silently
      return GitHub results instead.

---

## 10. Diagnostics: dev mode, stats, skipped-readmes

**Steps**

```vim
:Reposcope toggle-dev
:Reposcope print-dev
:Reposcope stats
```

- [ ] `toggle-dev` flips developer mode — `print-dev` right after confirms
      the actual current state (not just "it ran").
- [ ] With dev mode on, run a search — check for extra debug output
      somewhere (`:messages`, or wherever `utils/debug.lua` routes it).
- [ ] `:Reposcope stats` shows real accumulated request/cache metrics after
      using the plugin a bit — confirm the numbers move between two calls
      separated by more searches (not static/fake).
- [ ] `:Reposcope skipped-readmes` — already exercised in §2; confirm it's
      reachable as its own command too, independent of the debounce test.

---

## What this checklist does not cover

The `curl`/`wget` clone paths (`.zip`-archive download instead of `git
clone`) need `clone.type` set explicitly away from this config's default
empty string — worth a one-off manual `setup()` override if you want to
verify the archive path specifically, not exercised by the steps above.
The exact wire format of each provider's search query
(`providers/*/query_builder.lua`) is a code-reading question, not something
a click-through usefully validates beyond "did real results come back."
