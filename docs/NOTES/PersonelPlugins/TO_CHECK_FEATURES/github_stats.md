# Testing github_stats.nvim

How to manually test github_stats.nvim's real feature surface. Telemetry
(Workstation dataset, 37 sessions) shows only `config.get` (37 calls) — no
entry-point signal at all, since the plugin's real behavior (dashboard
navigation, fetch cycles) doesn't run automatically without the user
opening it. Priority below follows the README's own ordering (dashboard
is the plugin's flagship, named first) and `docs/WORKFLOW.md`'s explicit
"do this before trusting any data" sequence, not usage counts.

Repo: `$REPOS_DIR\github_stats.nvim`. Spec: `lua/plugins/personal/init.lua`
(`event = "VimEnter"`, `dependencies = { "StefanBartl/lib.nvim" }`). This
config's `setup()` passes a curated `repos` list (~28 explicit
`StefanBartl/*` repos, not `watch_users` auto-discovery — deliberately, per
the config's own comment: discovery pulled in ~40 repos and froze the UI
45–90s on this machine spawning that many `curl` processes at once).
Also set here: `token_source = "env"` / `token_env_var = "GITHUB_TOKEN"`,
`fetch_interval_hours = 24`, `notification_level = "all"`, `progress_style
= "statusline"`, and **`background = { enabled = not machine.is
("workstation") }`** — if this machine resolves as the "workstation" in
`lib.nvim`'s machine detection (likely, since the primary telemetry
dataset referenced across this whole checklist folder is literally called
"Workstation"), **the silent background fetch cycle is disabled here**,
and only reads already-committed `data/` snapshots plus manual
`:GithubStats fetch`. Confirm which is actually true for this session
before testing §7.

## Setup

```vim
:checkhealth github_stats
```

**Expect**: config validity (repo format, at least one of `repos`/
`watch_users` set — this config has `repos` only), `GITHUB_TOKEN` env var
presence, `curl` availability, storage directory writability, dashboard
config shape, and a **synchronous live API call** (10s timeout) against
the first configured repo — a bad/expired token shows up here as a
specific `401`/`403`/`404`, not later as a silent "No Data" dashboard
entry. Run this **before** anything else in this checklist.

```vim
:GithubStats debug
```

**Expect**: repo counts (explicit vs. discovered — should show 0
discovered here, since `watch_users` isn't configured), token
source/length, `fetcher.last_fetch_summary` (empty until a fetch has run
once), its own live API test. Reach for this one *after* a real fetch has
happened, as the companion to `:checkhealth`.

---

## 1. Manual fetch — get real data before anything else is worth testing

**Steps**

```vim
:GithubStats fetch force
```

**Expect**: `force` bypasses `fetch_interval_hours` entirely — should hit
the API regardless of when data was last pulled. 4 API calls per repo
(clones, views, referrers, paths) run in parallel; with ~28 repos
configured, watch `progress_style = "statusline"` show live progress
(this config's own setting) rather than nothing on screen for a while.

- [ ] After it finishes, `:GithubStats debug` should show real
  `last_fetch_summary` data, including any per-repo/metric errors (a repo
  you don't have push access to reports a specific failure here, not a
  silent gap).

---

## 2. The dashboard — the flagship feature

**Steps**

```vim
:GithubStats dashboard
```

**Expect**: a full-buffer listing, one entry per configured repo (clones,
views, trend arrow, a 24-character clone sparkline on the `Period:` line).
The header (6 lines) shows totals across every repo over the active range
and names the top-clones repo — costs no extra query, computed from data
already fetched for the render.

- [ ] `j`/`k` (and `<Down>`/`<Up>`) navigate; `<CR>` opens the detail view
  for the selected repo.
- [ ] `s` cycles sort: `clones → views → name → trend`. `3s` should
  advance 3 positions (mod 4, so `4s` is a deliberate no-op — confirm it
  really does nothing on the 4th press).
- [ ] `t` cycles time range `7d → 30d → 90d → max`; `m` jumps straight to
  `max` and the header names the concrete resolved span, e.g.
  `Range:max (2025-03-04 -> 2026-08-22, 172d)`. Changing the range is
  purely local re-aggregation — confirm it triggers **no** network
  activity (watch `:GithubStats debug`'s fetch summary — it shouldn't
  change).
- [ ] `T` — prompts pre-filled with the current range; type `3m` and
  confirm it lands calendar-accurate (one month back from a 31st lands on
  28th–30th, not a fixed 90-day block) rather than a fixed day count.
  Type garbage — expect a rejection notification, previous range kept
  (retry immediately, no need to reopen).

**`r` vs `f` vs `R` — the one worth getting right**:

- [ ] `r` on a repo showing stale-looking data — **does nothing** if
  nothing new has actually been fetched (it only re-renders from the
  on-disk cache, never touches the network). Confirm pressing it
  repeatedly changes nothing.
- [ ] `f` — force-fetches just the selected repo, bypassing the interval;
  confirm the entry updates after.
- [ ] `R` — force-fetches **every** configured repo; only worth it
  deliberately, given the rate-limit cost scales with repo count (~28
  here).

- [ ] `?` — key-hint overlay; confirm it lists the *effective* bindings
  (a remapped or disabled key shown/omitted correctly, not hardcoded
  defaults).
- [ ] `<RightMouse>` — context menu mirroring the same actions (if
  `nvzone/menu` installed; otherwise silently inert).
- [ ] `:GithubStats! dashboard` (bang on the verb, not the subcommand) —
  forces a refresh from the API before opening, instead of rendering
  straight from cache.
- [ ] `q`/`<Esc>` — closes cleanly; reopen and confirm no leftover timer
  (check nothing errors on a second `q` right after opening, which used
  to crash via a divergent teardown path).

---

## 3. `show` / `summary` / `referrers` / `paths`

**Steps**

```vim
:GithubStats show StefanBartl/lib.nvim clones
:GithubStats summary clones
:GithubStats referrers StefanBartl/lib.nvim
:GithubStats paths StefanBartl/lib.nvim
```

**Expect**: `show` — total count, uniques, daily breakdown for one
repo/metric, defaulting to all available data. `summary` — one metric
aggregated across every configured repo. `referrers`/`paths` — top 10 from
GitHub's own latest snapshot (GitHub itself only retains 14 days of this
data, so don't expect a long history here regardless of local retention
settings).

- [ ] Tab-completion on the repo argument — should complete from the live
  configured list (28 explicit repos), not require typing the full name.

---

## 4. ASCII charts

**Steps**

```vim
:GithubStats chart StefanBartl/lib.nvim both
```

**Expect**: two stacked sparklines (count + uniques), 8-level Unicode
blocks, normalized to the data's own min/max, with max/avg/min/total
alongside. Try `clones` alone (single sparkline) too.

---

## 5. Period-over-period diff

**Steps**

```vim
:GithubStats diff StefanBartl/lib.nvim clones 2026-07 2026-08
```

**Expect**: total count/uniques, days with data, per-day averages
(deliberately per-day, so a 31-day month is still fairly compared against
a 28-day one), and percentage change. Pick a repo/period combination with
genuinely zero traffic in `period1` — expect `+∞`, not a divide-by-zero
error.

---

## 6. Export — check the format matrix before trying `all`

**Steps**

```vim
:GithubStats export all both C:/Users/bartl/Desktop/report.md
:GithubStats export StefanBartl/lib.nvim clones C:/Users/bartl/Desktop/lib-clones.csv
```

**Expect**: the `all` target only ever supports Markdown — try
`:GithubStats export all clones report.csv` deliberately and confirm it
errors (`'all' target only supports Markdown format`) rather than
silently downgrading. A missing extension defaults to `.md` for `all`,
`.csv` otherwise; an extension that's present but wrong (e.g. `.txt`) is
left alone and still errors, not silently rewritten.

- [ ] The `.md` export should include a **Highlights** section (most
  cloned/viewed repo, best month, best single day).
- [ ] If `pdfport.nvim` is installed (it is, in this config): export the
  same report as `.pdf` — should route through `pdfport.create()`
  directly with no intermediate `.md` file on disk, and read identically
  to the `.md` version content-wise.

---

## 7. Background fetch cycle — confirm whether it's even running here

**This is the one setting where this config's value depends on runtime
state (`machine.is("workstation")`), not a fixed opt.**

**Steps**

```vim
:lua print(vim.inspect(require("github_stats.config").get().background))
```

**Expect**: if `enabled == false` here (this machine resolved as
"workstation"), confirm the dashboard and all read commands above still
work purely from the last manual/committed fetch — that's the deliberate
design (`background` only gates the *silent* automatic cycle, nothing
else). If `enabled == true` instead, leave Neovim open past the poll
period (`min(60, fetch_interval_hours * 60)` = 60 minutes at this config's
`fetch_interval_hours = 24`) and confirm a due fetch lands within the
hour without any notification on success (errors still notify, subject to
`notification_level = "all"` here).

---

## 8. Retention (`compact`)

**Steps**

```vim
:GithubStats compact dry-run
:GithubStats compact
```

**Expect**: `dry-run` reports would-be archived/deleted counts and freed
bytes without touching disk. Real run archives `clones`/`views` data older
than `cutoff_days` into a per-repo `_archive.json`, prunes
`referrers`/`paths` snapshots older than `prune_days` (default config
here — both default `15`, but `cutoff_days` has a **hard floor of 14**
enforced in code regardless of a lower configured value — this config
doesn't override either, so the floor is moot here, just worth knowing if
you ever lower it).

- [ ] This runs automatically at most once per 24h anyway
  (`retention.enabled = true`, this config's default) — the manual command
  is mainly for seeing the effect immediately after a config change,
  which doesn't apply here since retention settings are untouched.

---

## What this checklist does not cover

`watch_users` auto-discovery — this config deliberately uses an explicit
`repos` list instead (see the spec comment about the 45–90s UI freeze it
caused), so there's nothing meaningful to test here without temporarily
reconfiguring it. Custom date presets beyond the built-ins (this config
doesn't define any). The right-click menu's exact entry list beyond "does
it mirror the keymaps" (covered structurally in §2).
