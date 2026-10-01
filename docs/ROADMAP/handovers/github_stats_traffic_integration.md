# GitHub traffic in docmap-desktop and documentation.nvim — implementation handover

Status: **all four steps built and pushed.** P0 (2026-09-28, `github_stats.nvim` `13fb0a2`), P1+P2
(2026-09-28, `docmap-desktop` `02b84fc`/`2a8d561`/`4774f11`), P3 (2026-10-01, `documentation.nvim`
`main` `b39c3be`). Designed 2026-09-25.

**This file is trimmed to what is still actually open** (2026-10-01) — the full build log (plan +
"as built" for every step, the data-flow diagram, settled open questions with their reasoning,
practical notes from building it) moved to the backlog, since none of that is needed for what is
left to do:

- Full build log:
  [`ALL/Backlog/FEATURES/github-stats-traffic-integration.md`]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/ALL/Backlog/FEATURES/github-stats-traffic-integration.md)
- Concept — the *why*, the alternatives, the risks, the decisions, the on-demand-fetch idea:
  [`GITHUB_STATS_CONCEPT.md`]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/github_stats.nvim/ROADMAP/IDEAS/GITHUB_STATS_CONCEPT.md)

**Keep this file current:** when the real end-to-end check below finally runs, or the on-demand
fetch idea gets decided one way or the other, update *this* file — and if nothing here is open any
more, move its remainder into the build log above and delete it, the same way its bulk already
moved there on 2026-10-01.

---

## What is actually left

1. **The real end-to-end check.** Nothing in this integration has been run against a genuine
   `:GithubStats fetch` — every step's own build log says so. Needs the author's own GitHub token
   and machine; not something a session can do unattended. See [*Verification, end to
   end*](#verification-end-to-end) below for the exact checklist.
2. **The on-demand live-fetch idea — not decided, not sized, not started.** Raised 2026-10-01
   alongside a cross-cutting principle for the planned rules.nvim/ai.nvim ("loomAI") agent
   integration: an external call and the credential it needs stay inside the one Neovim-side
   plugin that owns the integration; the app only triggers it via the existing "Ask Neovim"
   pattern and reads back an artifact, never holds the credential or makes the call itself. Full
   write-up, including why it is a *different* idea from the existing, unrelated, still-not-planned
   "P4 — traffic × churn": the concept's
   [*On-demand live fetch*]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/github_stats.nvim/ROADMAP/IDEAS/GITHUB_STATS_CONCEPT.md#on-demand-live-fetch-idea-not-built)
   section and its decision 5.

Everything else — all four steps' plans, what was actually built and where it differed, every
settled open question with its reasoning, the practical notes from building it — is in the build
log linked above, not repeated here.

---

## Verification, end to end

Still to run for real, against a genuine `:GithubStats fetch` (the one blocker in *What is
actually left* above). Fixture/unit coverage for each already exists per repo (see the build log);
what has never happened is a deliberate pass with real data across all three repos together.

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

---

## Where things are

| What | Where |
|---|---|
| Concept (canonical copy in the vault) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/github_stats.nvim/ROADMAP/IDEAS/GITHUB_STATS_CONCEPT.md` |
| Full build log (P0–P3 plan + as-built) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/ALL/Backlog/FEATURES/github-stats-traffic-integration.md` |
| The app's queue and roadmap (L11) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/docmap-desktop/ROADMAP/` |
| This handover (real file) | `$NVIM_CONFIG_DIR/docs/ROADMAP/handovers/github_stats_traffic_integration.md` |
| Vault entries pointing here | `wkdbook-myplugins/{github_stats.nvim,documentation.nvim,docmap-desktop}/ROADMAP/` |
| Collector (P0; contract in `docs/FEATURES/DIGEST.md`) | `$REPOS_DIR/github_stats.nvim` |
| Engine and Neovim side (P3) | `$REPOS_DIR/documentation.nvim` |
| The app (P1, P2) | `$REPOS_DIR/docmap-desktop` |
