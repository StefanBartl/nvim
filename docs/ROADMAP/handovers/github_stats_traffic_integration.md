# GitHub traffic in docmap-desktop and documentation.nvim — implementation handover

Status: **designed, nothing built.** Recorded 2026-09-25.

The *why*, the alternatives and the risks are in the concept, which this file
does not repeat:
[`GITHUB_STATS_CONCEPT.md`]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/github_stats.nvim/ROADMAP/IDEAS/GITHUB_STATS_CONCEPT.md)
(a copy also sits in `docmap-desktop/docs/`, where that repo's README links it).
This file is the *how*: order, files, tests, gates, and what to check at the end.

## Read this first

**What is being built.** `github_stats.nvim` already collects GitHub's traffic
data (clones, views, referrers, top pages) and keeps it past GitHub's 14 days.
`docmap-desktop` and `documentation.nvim` should show it when the plugin is
installed, and only then. Read-only. Nothing else fetches from GitHub, and no
token ever enters the app.

**Decisions that are not reopened** (all in the concept, dated 2026-09-25):

1. The plugin publishes a small per-repo **digest**; both readers read that, not
   the raw history and not the live Lua API.
2. The raw history stays in the **synced** Neovim config (one dataset for the PC
   and the workstation). The digest is derived, so it goes to a **local,
   per-machine** directory, default `stdpath("data")/github_stats.nvim`,
   overridable with `digest_dir`.
3. Readers find it through one **discovery chain**: explicit setting →
   `root.json` at the default place → ask Neovim → (app only, no digest yet)
   raw history under the app's configured Neovim config dir.
4. Repo-level data only. `paths` is GitHub's **top 10**; not being in it means
   *unknown*, never *zero*. No heat map over the module tree.
5. `gitsuite.nvim` is **not** involved.
6. A per-project **opt-out** lives in the app, not in the plugins.

**Traps, each verified against the code on 2026-09-25:**

- `require("github_stats")` loads the dashboard at module load, and the dashboard
  needs `ui.nvim` (`lua/github_stats/init.lua`, last lines). A probe on the
  top-level module reports "not installed" for someone who has the plugin but not
  its UI dependency. Probe **`github_stats.digest`**, a small module of its own.
  `config`, `storage` and `analytics` need only `lib.nvim` and each other, so the
  digest module can stay UI-free — **write a spec that proves it**
  (`package.loaded["ui.kit"]` stays `nil`).
- **The word "summary" is taken.** `:GithubStats summary {metric}`
  (`bindings/usrcmds/summary.lua`) aggregates across repos and is unrelated.
  Hence *digest* everywhere: module, option, folder, command.
- **Never write derived files into the synced config dir** (`stdpath("config")/lua/plugins/github-stats/`).
  A file rewritten by two machines is a sync conflict. New timestamp-named
  history files do not conflict; `last_fetch.json` and `_archive.json` are single
  files both machines rewrite (see P0 step 8).
- **Do not parse the user's installation spec.** It is code (`opts` may be a
  function). Ask the loaded plugin instead.
- `last_fetch.json` lives in the synced config: a fetch on machine A makes
  machine B skip its own for the interval. B's local digest is then **stale
  although the history is new** — P0 step 5 exists because of that.
- `lib.nvim.fs.json` `write` is atomic (`path .. ".tmp"`, then rename; on Windows
  `fs_rename` is best-effort). Readers must ignore a stray `*.tmp`.
- The app's shell has **no tab bar**. Telemetry lives in the sidebar
  (`renderTelemetry`, `src/main.js`), the map's tabs live inside the generated
  page. The concept therefore says *Traffic section* (sidebar) plus a *detail
  dialog* (pattern: the dependency matrix).
- `github_stats.nvim`'s test suite needs `lib.nvim`, `ui.nvim` and `plenary.nvim`
  checked out (`TESTS/README.md`, `scripts/minimal_init.lua`).

**House rules for this work** (from the task brief):

- **ROADMAP entries live in WKDBooks, never in a plugin repo.** Roadmap text for
  the three targets is under `wkdbook-myplugins/{github_stats.nvim,documentation.nvim,docmap-desktop}/ROADMAP/`.
  Open: `docmap-desktop/docs/PLAN.md` already carries an **L11** row and
  `ROADMAP.md`/`HANDOVER.md` mention it; that repo keeps its queue in-repo by
  its own convention, so decide whether to move it (see *Open questions*).
- Code and comments in English. No `Co-Authored-By` trailer. `luacheck` and
  `stylua` green before every commit (`nvim --headless -l scripts/ci.lua` where a
  repo has it). Commit and push to `main` as soon as a step is done.
- Large or escape-heavy text goes through the file tools, not a shell heredoc
  (`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md`).
- Docs and `README.md` are part of each step, not a follow-up. If a binding
  changes, `$NVIM_CONFIG_DIR/docs/NOTES/BINDINGS` too (none is planned).
- Personal plugin install specs: `$NVIM_CONFIG_DIR/lua/plugins/personal/init.lua`.
  Plugin checkouts: `$REPOS_DIR`.

## Data flow

```
GitHub traffic API ──► github_stats.nvim (fetcher, retention)
                              │  raw history, SYNCED between machines
                              ▼
          <config>/lua/plugins/github-stats/data/<owner_repo>/<metric>/*.json
                              │  digest.write()   after each fetch, and at start
                              ▼  if the history is newer than the digest
   LOCAL, per machine:  <digest_dir>/digest/<owner_repo>.json
                        stdpath("data")/github_stats.nvim/root.json  (pointer + index)
                              │
              ┌───────────────┴────────────────┐
              ▼                                ▼
   docmap-desktop (Rust: traffic.rs)   documentation.nvim (core/traffic_join.lua)
   sidebar section · list column ·     `traffic` browse mode, next to `rules`
   detail dialog
```

## Order and sizes

| Step | Repo | What | Size |
|---|---|---|---|
| **P0** | `github_stats.nvim` | Write the digest and `root.json`; `github_stats.digest` module | ~0.5 session |
| **P1** | `docmap-desktop` | `traffic.rs`, discovery chain, folder button, header line, list column, opt-out | ~1 session |
| **P2** | `docmap-desktop` | Detail dialog: sparkline, referrers, pages, pages linked to files | ~1 session |
| **P3** | `documentation.nvim` | `core/traffic_join.lua`, `traffic` browse mode | ~0.5–1 session |
| P1b | `docmap-desktop` | Raw-history fallback, **only if P0 slips** | ~0.5 session, optional |

P0 first. P1 and P3 are independent of each other afterwards; P2 needs P1.
P0–P2 is useful without touching `documentation.nvim`.

---

## P0 — github_stats.nvim (~0.5 session)

Goal: after a fetch, and whenever the synced history is newer than the local
digest, the digest exists and is correct; the plugin can say where it is.

1. **`lua/github_stats/digest.lua`** — UI-free. Requires only `github_stats.config`,
   `.storage`, `.analytics`, `lib.nvim.fs.json` and `lib.nvim.fs.mkdirp`. Public:
   `default_dir()`, `digest_dir()` (works **before `setup()`** and returns the
   default then), `build(repo)`, `write(repos)`, `write_all()`, `write_root()`.
2. **Config.** `digest_dir` (string|nil) and `digest_daily_days` (default 400) in
   `config/DEFAULTS.lua`, the `GHStats.Config` type (`@types/`), the validation
   in `config/init.lua`, and `docs/configurations/`. Expand `~`/env like the
   other paths (`fn.expand`, as `resolve_data_dir` does).
3. **Build the content** from what already exists, so the semantics stay the
   plugin's own: `analytics.query_metric({repo, metric})` gives
   `daily_breakdown` (dedupe-by-day and *today excluded* come for free);
   `d7/d30/d90` are sums of it with uniques; `trend` is
   `analytics.trend_over(daily, 7)`; `analytics.get_top_referrers/get_top_paths`;
   the span from `analytics.get_history_span`. Schema `1`; fields as in the
   concept's D1 example, `daily` capped to `digest_daily_days`.
4. **Hook the fetch.** In `fetcher.fetch_all`'s completion (`lua/github_stats/fetcher.lua`,
   just before `callback(summary)`, after the retention block): take the repos
   from `all_success` (its entries are `repo/metric` strings — split on the
   **last** `/`, repos contain one), then
   `vim.schedule(function() pcall(digest.write, repos) end)`. A digest failure
   must never fail or slow a fetch; report it at debug level only.
5. **Rebuild when stale.** In the background start path (`background.lua`, before
   the first cycle) call a cheap `digest.stale()` — newest history file mtime vs
   the digest's `generated` — and `write_all()` if so. This is the
   two-machine case above.
6. **Write rules.** Atomic (use `lib.nvim.fs.json` `write`), **only when the
   payload changed** (compare without `generated`, so mtimes stay quiet for the
   app's cache), only for the repos of this cycle, never on the fetch's own tick.
7. **`root.json`** at `stdpath("data")/github_stats.nvim/root.json` **always**,
   even when `digest_dir` is overridden:
   `{ "schema": 1, "digest_dir": "...", "data_dir": "...", "repos": { "owner/name": "owner_name" } }`.
8. **Two-machine review (write down, fix only if real).** Read `retention.lua`:
   can retention on machine A delete raw files machine B still needs? Both
   machines rewrite `_archive.json` and `last_fetch.json`. Record the finding in
   the plugin's wkdbook ROADMAP; do not widen this step's scope.
9. **Command and health.** `:GithubStats digest` (rebuild all now — the answer to
   "the local digest lags after a sync") in `bindings/usrcmds/` beside the
   others; a `:checkhealth github_stats` line for `digest_dir` writable,
   `root.json` present and consistent (`health.lua`, `docs/FEATURES/DIAGNOSTICS.md`).
10. **Docs.** New `docs/FEATURES/DIGEST.md` **as the stable contract** (schema,
    where it lives, the discovery chain, what it does not contain), linked from
    `docs/FEATURES/README.md` and the plugin README's documentation list; an
    entry in `docs/CHANGELOG.md`; `doc/github_stats.txt` help. State that the
    digest never contains the token.

**Tests** — `TESTS/digest_spec.lua` (plenary busted; `scripts/test.sh TESTS/digest_spec.lua`):
built from a fixture history; changed-only (second write leaves the mtime);
atomic (no `*.tmp` left); `daily` bounded; `digest_dir()` before `setup()`;
**UI-free** (`package.loaded["ui.kit"] == nil` after requiring it); a token in the
config never appears in the output; `root.json` written to the default place
when `digest_dir` is overridden; stale detection.

**Done when:** `:GithubStats fetch` on a real repo produces
`digest/<owner_repo>.json` and `root.json`; `:checkhealth github_stats` is green;
the suite, `luacheck` and `stylua` are green; the contract page is written.

---

## P1 — docmap-desktop core (~1 session)

Goal: the sidebar shows a project's traffic line, the project list can sort by it,
and the user can point the app at the digest folder.

Template for everything: **`src-tauri/src/telemetry.rs`** (reads another plugin's
on-disk data from Rust, reports "not known" rather than assuming).

1. **`src-tauri/src/traffic.rs`.** Typed structs with `#[serde(default)]`;
   `schema` newer than known → an explicit "newer than this app understands";
   **read cap 2 MiB**; numeric fields as integers with saturating arithmetic;
   unreadable file → status `unreadable`, never a panic. Cache by `(path, mtime)`.
2. **Repo resolution** per project: `ProjectSettings.repo_url` first (URL-imported
   projects already have it — no process), else `git remote get-url origin` with
   the three URL forms and host `github.com` only, spawned the way the nvim run
   does it (`CommandExt`/no console window on Windows). **Cache per project root
   in memory**; invalidate on project edit or explicit refresh. Never one spawn
   per list row.
3. **Outcomes**, each shown as what it is: `ok`, `not_tracked` (matched, but the
   plugin does not track it), `no_remote` (nothing shown, no error),
   `no_digest`, `unreadable`, `disabled` (opt-out).
4. **Discovery chain in Rust:** explicit setting `traffic_dir` (new
   `Option<String>` on `Workspace`, `#[serde(default)]`, beside `nvim_config_dir`)
   → `root.json` at the default `stdpath("data")` place → the stored answer of
   "Ask Neovim" → (later, P1b) raw history under `<nvim_config_dir>/lua/plugins/github-stats/data`.
   Never search the disk. The chosen folder is **read by Rust; do not add it to a
   Tauri fs scope** (`capabilities/default.json`).
5. **"Ask Neovim".** `spawn_blocking`, modelled on `import_from_nvim_config`
   (`nvim --headless -c "luafile <script>" -c "qa"`); the script prints
   `require("github_stats.digest").digest_dir()` between markers. One process,
   only on the button, answer stored like a chosen folder. No `nvim` path
   configured → say so.
6. **Commands** in `main.rs`, registered in the `generate_handler!` list (around
   the `set_nvim_config_dir` line): `traffic_info(id)`, `traffic_list(ids)` (one
   async read for the whole column), `traffic_set_dir(path)`,
   `traffic_ask_neovim()`; the opt-out as a field on `ProjectSettings`
   (`project_scope_get/_set`).
7. **Front end (`src/main.js`, `src/index.html`).** A Traffic section in the
   sidebar next to the telemetry block, modelled on `renderTelemetry`: line with
   7/30/90-day views and clones, trend arrow, uniques, `generated` and span
   (a stale digest must say so); the folder button with the native dialog
   (`open({ directory: true })`, as `pickNvimConfig` does) and what was found
   there. A fifth sort order **`traffic`** next to `name`/`stale`/`generated`/`added`
   (`sortedProjects()`, the `<select>` in `index.html`, the saved-choice
   validation). **Every user-derived string goes through `escapeHtml`/`textContent`
   — never `innerHTML`.** Any link is built from validated owner/repo and opened
   only for host `github.com`.
8. **i18n.** New keys in `src/lib/i18n.js` for **both** shipped locales (`en`, `de`)
   — the suite fails a locale with missing keys (`i18n.test.js`). Add stubs for the
   new commands to `tools/preview/stub.js` so the layout preview keeps working.
9. **Docs.** `README.md` (it says "four sort orders"), `docs/USAGE.md` (the
   section, the folder button, the opt-out), `docs/FEATURES/`; the concept status
   line; `docs/PLAN.md` L11 row (see *Open questions*).

**Tests:** `cargo test` (URL forms, `repo_url` first, the size cap, schema
refusal, saturating numbers, a malformed file, the outcome states) and
`node --test src/lib/*.test.js` (i18n keys complete, the sort order).
`cargo test` needs the placeholder sidecar first — see `docs/HANDOVER.md`,
*Gates*. Check the layout with `python tools/preview/preview.py`
(`http://localhost:8731/tools/preview/preview.html`).

**Done when:** with a real digest on disk, the section shows numbers and the list
sorts by traffic; with none, it says why and offers the button; a project without
a GitHub remote shows nothing and no error.

---

## P2 — detail dialog (~1 session)

1. Dialog after the pattern of the dependency matrix: an inline-SVG sparkline
   over the **whole stored span** (that is the point — not 14 days), referrers,
   top pages.
2. **Pages linked to files.** A `paths` entry becomes a project-relative path
   (`/owner/repo/blob/<branch>/…` stripped) in **Rust**, and is rejected on `..`,
   a backslash, a drive letter or a leading `/`; the joined path is
   canonicalized and must still lie under the project root before it gets a
   badge or a jump (reuse the files pane / open-in-editor). Anything else stays a
   plain, unlinked line. Label it "top 10 on GitHub", never "views".
3. Tests: traversal cases (`../..`, `C:\`, `%2e%2e`), a referrer named
   `<img onerror=…>` rendered as text, an entry that does not resolve.

---

## P3 — documentation.nvim (~0.5–1 session)

Model: **`lua/documentation/core/rules_join.lua`** and the `rules` mode.

1. **`core/traffic_join.lua`.** Discovery chain: `opts.traffic.digest_dir` →
   `root.json` at `stdpath("data")` → `soft_require.probe("github_stats.digest")`
   → `digest_dir()`. Reads the digest with `lib.nvim.fs.json.read`. Resolves the
   tree's repo with `lib.nvim.git.remote` directly (host `github.com`) — do not
   require `github_stats` for that. `nil` is "no data", never an error, never
   evidence.
2. **Browse mode `traffic`**, not centred on a node, like `rules`: add it to the
   mode list in `lua/documentation/editor/browse/init.lua` (the comment there
   numbers `rules` 10th), the mode/entry-kind docs and a `traffic_row` field in
   `editor/browse/@types/init.lua`, the `head == …` dispatch in
   `bindings/usrcmds/browse.lua`, the entry building and actions in
   `editor/browse/view.lua` (the places that handle `"rules"`), and the option in
   `config/init.lua` + `config/file.lua` (as `rules_gate` is).
3. **The standalone engine is untouched.** The join is a consumer concern, like
   telemetry.
4. Docs: `docs/FEATURES/`, `doc/documentation.txt`, `core/README.md`, the plugin
   README. Test: `TESTS/traffic_join_spec.lua` (no plugin → `nil`; fixture digest;
   malformed digest; unknown schema).

**Done when:** `:DocMap browse traffic` (or whatever the mode's entry point ends up
being) lists the digest for a tree whose remote is tracked, and says "no data" for
one that is not.

---

## Verification, end to end

- **Two machines.** Fetch on A, sync, open B: B's digest is rebuilt at start, not
  stale, and B did not refetch inside the interval.
- **Plugin absent.** The app and `documentation.nvim` behave as before; nothing
  errors, nothing renders empty.
- **`ui.nvim` absent, plugin present.** The probe still finds `github_stats.digest`.
- **Lazy-loaded plugin.** `soft_require.probe` loads it; no user command needed.
- **Overridden `digest_dir`.** `root.json` at the default place points to it;
  the app and the plugin find it without a setting.
- **Hostile digest.** A fixture with `<img onerror=…>` as a referrer,
  `../../etc/passwd` and `C:\Windows` as paths, a 3 MiB file, `schema: 99`:
  text is inert, nothing outside the project root gets a link, the file is
  refused with a message.
- **Private repo + opt-out.** Nothing shown for an opted-out project; nothing of
  it in any exported artifact.

## Open questions

1. **Where does L11 live?** `docmap-desktop/docs/PLAN.md` (L11), `ROADMAP.md` and
   `HANDOVER.md` already mention it, in-repo. The brief says roadmap entries
   belong in WKDBooks. Decide: move the L11 row out, or keep that repo's own
   convention (its `PLAN.md` is "the one queue for all three repositories").
2. **Is P1b needed?** Only if P0 slips or an older plugin version must be
   supported. It is a second implementation of the plugin's rules; skip it
   otherwise.
3. **Retention across two machines** — the finding of P0 step 8.
4. **`digest_daily_days`.** 400 is a guess; check the size of a real digest.
5. **Opt-out storage.** A field on `ProjectSettings` is the plan; confirm it does
   not change what `project_scope_get` returns to older front ends.

## Where things are

| What | Where |
|---|---|
| Concept (canonical copy in the vault) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/github_stats.nvim/ROADMAP/IDEAS/GITHUB_STATS_CONCEPT.md` |
| Concept (repo copy, linked from its README) | `$REPOS_DIR/docmap-desktop/docs/GITHUB_STATS_CONCEPT.md` |
| This handover (real file) | `$NVIM_CONFIG_DIR/docs/ROADMAP/handovers/github_stats_traffic_integration.md` |
| Vault entries pointing here | `wkdbook-myplugins/{github_stats.nvim,documentation.nvim,docmap-desktop}/ROADMAP/` |
| Collector | `$REPOS_DIR/github_stats.nvim` |
| Engine and Neovim side | `$REPOS_DIR/documentation.nvim` |
| The app | `$REPOS_DIR/docmap-desktop` |
