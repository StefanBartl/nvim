# casedesk — User Commands Cheatsheet

Three composer verbs, built via `lib.nvim.usercmd.composer` — `:Case` acts
on **one** case (always resolves to exactly one: explicit arg → buffer →
`kit.select`), `:Cases` acts on a **set**, both scoped to `config.root`
(`Cases/SAP_Support`). `:Tricentis` is the odd one out: it reaches across the
**whole work repo** (`config.repo_root` — `Notes/`, `Workflow/`,
`Terminologie/`, `Tosca/` too), which is exactly why it isn't a `:Cases`
route. `[case]`/`[nr]` everywhere below is the same optional `CASE` arg
type, `<Tab>`-completed from the on-disk registry; typing the full SNOW
ticket id works too, it's normalized down to the short number.

Source: `lua/bindings/usrcmds/case/init.lua` (routes), `ui.lua` (handlers).
Concept: [`docs/ROADMAP/casedesk/CONCEPT.md`](../../ROADMAP/casedesk/CONCEPT.md).
Feature history: [`docs/ROADMAP/casedesk/ROADMAP.md`](../../ROADMAP/casedesk/ROADMAP.md).
Use cases / daily workflow: [`Workflow.md`](./Workflow.md).

## `:Case` — one case

| Command | Args | What |
| --- | --- | --- |
| `:Case new [nr]` | case number, prompts for the rest | Prompt chain (title/company/name/link) → dry-run plan → confirm → scaffold. Respects `config.company_blueprints` if the company entered maps to one. Only the case number is actually required (`config.case_number_min_digits`–`_max_digits` plausible digits) — every other field can be left blank (Enter on empty) without crashing or half-creating anything |
| `:Case info [nr]` | — | Infocard (`kit.viewer`) — `e` edit, `s` summary, `o` open folder, `q` close |
| `:Case summary [nr]` | — | Open `Summary.md` — the **ServiceNow-facing** document (fixed four-section template, no markdown; see Notes below) |
| `:Case notes [nr]` | — | Open `Notes.md` — your **private** work notes (what was tried, coach input, meeting tasks) |
| `:Case template [name]` | block name, `<Tab>`-completed; prompts if omitted | Insert a reply block from the work repo's `Workflow/Templates/` at the cursor, with `{case}`/`{name}`/`{title}`/`{today}` filled from the current buffer's case |
| `:Case research [nr]` | — | Open `Research/00_Research.md` |
| `:Case reply [nr]` | — | Open the newest file in `Replies/` |
| `:Case open [nr]` | — | Open the case folder (filetree reveal if `filetree.nvim` is loaded, else netrw) |
| `:Case add <name> [suffix]` | `name`, optional `suffix` | New `<name>.md` in the case root. `name == "reply"` is special: auto-numbers into `Replies/`, `[suffix]` overrides the stem (`:Case add reply AskForPDF` → `NN_AskForPDF.md`; omitted → `NN_Reply.md`) |
| `:Case activity [nr]` | — | Paste the system clipboard (a ServiceNow Activity Stream) into a new auto-numbered `Research/NN_ActivityStream.md` |
| `:Case reply check` | — | Pre-send gate on the **current buffer**: emoji count (`c` removes), stray markdown headlines, dead links, `s` launches `language.nvim`'s spellcheck on the buffer |
| `:Case similar [nr] [n]` | `n`, default 5 | Past cases whose title + `Summary.md` share the most distinctive vocabulary (TF-IDF cosine, no AI). Each hit shows the matched terms — the ranking is lexical, so seeing *why* it matched is how you judge it |
| `:Case timeline [nr]` | — | Work sessions reconstructed from file mtimes, oldest first — touches within `config.timeline_session_gap_minutes` (default 120) of each other count as one sitting. Each session's duration is a **lower bound** (a save marks when editing stopped, not started) |
| `:Case ki [nr]` | — | Build the AI-analysis prompt (role + policies + this case's activity stream, from the clipboard) and copy it back to the clipboard, ready to paste into an AI chat. Also saved as `Research/NN_KiPrompt.md` |
| `:Case ki import [nr]` | — | Paste an AI answer (in the format `:Case ki` asked for) from the clipboard and file it: analysis/difficulty/next-steps → `Research/NN_KiAnalysis.md`, English reply draft → new `Replies/NN_Reply.md` (still goes through `:Case reply check`, never auto-sent), internal German notes → appended to `Notes.md` |
| `:Case copy [src]` | source path, prompts if omitted | Copy a file into the case; target folder (`Replies`/`Research`/`Ressources`/root) via `kit.select` |
| `:Case sync [nr]` | — | Add whatever blueprint pieces are still missing (never overwrites) |
| `:Case close [nr]` | — | Move to `Closed/`, delete its saved session if it had one (SESSIONS.md §6) |
| `:Case reassign [nr]` | — | Move to `Reassigned/`, delete its saved session if it had one (SESSIONS.md §6) |
| `:Case snow [nr]` | — | Open the ServiceNow ticket URL (if `config.snow_url_format` is set) or copy the ticket id |
| `:Case sla [nr] [--doc]` | — | SAP-SLA status (see [SLA.md](../../ROADMAP/casedesk/SLA.md)): Erstreaktion/Rückmeldung/Korrekturmaßnahme, each as an absolute deadline + remaining time. Rückmeldung shows "wartet auf Kunden" instead of a countdown while the case sits in SNOW's own "Awaiting User Info" — it resets to a full fresh budget once they reply, not resumed from wherever it stood. `nil`/no line when the case has no parseable priority yet. `--doc` opens the source `SLA_ServiceLevelAgreement.md` instead, no case needed |
| `:Case insert [field] [nr]` | `field` `<Tab>`-completed: `case\|snow\|link\|title\|company\|name\|priority\|summary\|mail-subject`; prompts via `kit.select` (showing live values) if omitted | Insert that token at the cursor AND copy it to the clipboard, one action. `link` is the SNOW ticket URL (falls back to the plain id if `config.snow_url_format` isn't set), `mail-subject` is `[case] title`. With a Visual range (`:'<,'>Case insert [field]`) replaces the selection instead of inserting at the cursor — handy on a `<CASE>` placeholder |

Bare `:Case` (no subcommand) runs `:Case info` with no argument.

## `:Cases` — the cross-case querschnitt

| Command | Args | What |
| --- | --- | --- |
| `:Cases list` | — | Every case, grouped by state |
| `:Cases title/company/name/notes/priority/tosca_version [pattern] [--exact\|-e] [--re\|-r]` | one route per `config.infocard_fields` entry | Substring case-insensitive by default; `--exact`/`-e` = full-string equality; `--re`/`-r` = Lua pattern (case-**sensitive**, see Notes below). Empty pattern = "field is set at all". One hit opens its infocard directly, several go to `kit.select` |
| `:Cases find key=value ... [--exact\|-e] [--re\|-r]` | bare `key=value` pairs, no dashes | AND-combination across several `infocard_fields` at once, e.g. `:Cases find company=Scan year=2026` |
| `:Cases grep <pattern> [--re\|-r]` | — | Full-text search across every case's `.md` files (not `Ressources/` attachments). Report via `kit.viewer`, capped at 500 hits |
| `:Cases recent [n]` | `n`, default 10 | The `n` most recently touched cases, newest first |
| `:Cases stale [days]` | `days` optional | Open cases idle at least that long, oldest first. Omitted: each case uses its own priority-derived threshold (`config.sla_stale_days` — a P2 gets 2 days, a P4 gets 10; a case with no priority falls back to the old flat 7) instead of one number for everyone |
| `:Cases sla` | — | SLA dashboard: every open case with a parseable priority, sorted by remaining time on its most urgent clock — "what breaches next", not grouped by priority label. `!!`/`!` mark overdue / under warning threshold. Selecting a row opens that case's `:Case sla` |
| `:Cases history [company]` | `company`, defaults to the current buffer's case's company | Every matching case in one screen, grouped by state, most-recently-touched first within each group (`kit.viewer`, not a picker) |
| `:Cases stats` | — | Counts by state / company / year |
| `:Cases doctor` | — | Bestand-consistency report (read-only) — work-note aliases, `Research`/`Solution` as file vs. folder, known typos, missing `NN_` prefixes, and whether each `Summary.md` follows the SNOW template without markdown |
| `:Cases normalize` | — | Fixes exactly what `doctor` found — dry-run plan (`kit.viewer`) + confirm, then applies. Skips (reports separately) anything ambiguous: target already exists, or two findings in the same case would land on the same target |
| `:Cases linkcheck [nr]` | — | Checks `docs.tricentis.com` links (only that host) for dead pages, async bounded-concurrency HEAD requests |
| `:Cases pickers` | — | `kit.menu` discovery surface: Attachments (`Ressources/`, text opens in-buffer, everything else via the system default app), Links (opens externally, falls back to clipboard), Cases without `.case.json`, Terminology |
| `:Cases export [nr]` | — | Bundles `Summary.md`/`Notes.md`/`Research/`/`Replies/` into one PDF at `<case-dir>/Export.pdf` (`pandoc` → HTML, then a headless Chrome/Edge → PDF), opened automatically on success |
| `:Cases terminology` | — | Every `## `/`### ` term collected from every `Terminologie.md` across the whole work repo (`terminology.lua`), `kit.select`-picked; selecting one jumps to it in its source file. Same entry point as `:Cases pickers` → Terminology |
| `:Cases insert [pattern]` | substring over number/title/company/name | Same as `:Case insert` but for a case OTHER than the one you're in — e.g. referencing "see also case 977123" from a different case's reply. 0 matches warns, 1 skips straight to the field picker, several go through a case picker first. Same Visual-range replace as `:Case insert` |

Bare `:Cases` (no subcommand) runs `:Cases list`.

## `:Tricentis` — the whole work repo, not just SAP_Support

| Command | Args | What |
| --- | --- | --- |
| `:Tricentis links [scope]` | `scope`, `<Tab>`-completed: `all\|cases\|notes\|workflow\|terminologie\|tosca\|todo` | Every link found under that area of the work repo, `kit.select`-picked, opened externally (falls back to clipboard). Supersedes hand-maintaining `Notes/Links.md` |

Bare `:Tricentis` (no subcommand) runs `:Tricentis links` with no scope (everything).

## The `CASE` argument type

Registered once in `init.lua` (`register_case_type`), used by every `[case]`/
`[nr]` argument above:

- **validate**: runs the raw input through `render.to_short` (strips a pasted
  full `SAP0000<nr><year>` SNOW id down to the short number), then checks it
  against the registry — an unknown number is a hard error, not a silent
  fallback.
- **complete**: `<Tab>` lists every case number currently in the registry
  (`Open`/`Closed`/`Reassigned` alike), prefix-filtered.

## Notes

- **`Summary.md` and `Notes.md` are different documents, not variants.**
  `Summary.md` is what gets pasted into the ServiceNow ticket: the fixed
  four-section template (`Problem statement` / `Case notes` / `Links` /
  `Solution or workaround`) from
  `WKDBook-Tricentis/Workflow/Templates/SummaryTemplate.md`, and **no
  markdown** — SNOW renders none of it, so a `##` or `**bold**` shows up
  verbatim in the ticket. `Notes.md` is yours: what you tried, what a coach
  said, tasks out of a meeting. `:Cases doctor` reports on both
  (`summary-not-snow`, `summary-markdown`) but never auto-fixes them —
  no rename can write text a human has to write. Full rationale, including
  the earlier rule that wrongly conflated the two:
  `docs/ROADMAP/casedesk/CONCEPT.md` §8a.
- **`:Case template` reads a different library than `templates/`.** The
  blocks come from the *work repo* (`Workflow/Templates/`, 34 of them,
  discovered recursively) and get inserted into text you're writing;
  `lua/bindings/usrcmds/case/templates/` is casedesk's own scaffolding for
  `:Case new`. Adding a block is dropping a `.md` file into the work repo —
  no Lua edit, and `<Tab>` picks it up immediately. On a machine without
  that repo checked out the command degrades to "no reply blocks found"
  rather than erroring.
- **File-verb routes are generated, not hand-written**: `init.lua`'s
  `file_verb_routes()` loops `blueprint.all_keyed_nodes()` (every blueprint
  node with a `key`) and emits one `:Case <key> [case]` route per node — the
  three rows above (`summary`/`research`/`reply`) come from the `default`
  blueprint's three keyed nodes. A blueprint node with a new `key` is a new
  command for free, no `init.lua` edit.
- **State-verb routes are generated too**: `state_verb_routes()` loops
  `config.states` (`{ "Open", "Closed", "Reassigned" }`) and emits one
  `:Case <verb> [case]` per non-default state, named from
  `config.state_verbs` (falls back to the lowercased state name). A fourth
  state is a config line, not a new code path.
- **`--re` is case-sensitive on purpose**: lowercasing an arbitrary Lua
  pattern before matching would corrupt case-meaningful class specifiers
  (`%A`/`%D`/`%S`/... mean something different from their lowercase
  counterparts) — `query.lua`'s `matches()` documents this trade-off inline.
- **`:Cases linkcheck` only checks `docs.tricentis.com`** — deliberately, not
  every link a case happens to mention (SNOW tickets, support-hub links,
  screenshots hosted elsewhere would just be noise). 401/403/405 responses
  are reported as "uncertain"/"alive", not "dead" — an auth wall or a
  HEAD-unfriendly server doesn't mean the page is gone.
- **`:Cases terminology` parses both `## ` and `### ` as term boundaries**,
  not just `## `: most `Terminologie.md` files are flat (H1 title, H2 =
  term), but at least one (a Tosca onboarding doc) groups terms under a
  numbered H2 with the actual terms one level down as H3 — a bare group
  heading has no prose before its first H3 child, so it's dropped
  automatically (empty body), no separate "is this a group" check needed.
  Headings written as a markdown link (`## [Term](url)`, throughout the OSV
  glossary) have the link stripped to just the term text.
- **`:Case similar` is lexical, not semantic**: it matches *words*, not
  meaning — two cases describing the same problem in entirely different
  wording score 0. It also skips any case whose `Summary.md` is too thin
  (under 8 distinct terms after stopword removal), and needs at least 2
  shared terms before counting a hit at all — both thresholds exist because
  the first evaluation run produced an 87% "match" between two near-empty
  summaries sharing the single word "Research". Full evaluation:
  `docs/ROADMAP/casedesk/CONCEPT.md` §8e; the open question of whether this
  suffices or an embedding model is needed: `docs/ROADMAP/casedesk/ROADMAP.md`.
- **`:Cases pickers` runs entirely on `kit.select`**, the same backend every
  other multi-result flow in `ui.lua` uses. The `pickers.nvim`/
  `snacks.picker` backend cascade `docs/ROADMAP/casedesk/ROADMAP.md` also
  lists is deliberately deferred — `pickers.nvim`'s public API expects an
  internal `Source`+`engine_mod` object from its own config/engine
  resolution, not a trivial "picker over this list" entry point.
- **Renames go through `lib.nvim.cross.fs.mutate.rename_file`, not a bare
  `uv.fs_rename`** (`normalize.lua`, `:Case close`/`reassign`) — retries a
  few times with backoff on Windows when a directory watcher or AV/indexer
  scan holds a transient lock on the file/folder being renamed. Looked at
  `fileops.nvim` for this first; its `rename`/`move` API turned out to
  operate on "the current buffer's file" only, not an arbitrary path, so it
  doesn't fit a bulk rename across the bestand — `mutate.rename_file` is
  the layer underneath that `fileops.nvim` itself uses.
- **`:Case reply check` doesn't reimplement spelling/grammar.** `s` in its
  report just launches `language.nvim`'s own `:Spellcheck` on the buffer —
  that plugin already owns the domain, and its result (buffer highlighting)
  isn't data this module could usefully return anyway. Emoji count/removal
  goes through `emojis.nvim`'s pure `ops().count()`/`ops().clear()`, not
  the interactive `:Emojis` command, so it composes into one combined
  report instead of opening a second UI. Both integrations are optional
  (`pcall`-guarded) — missing either degrades that one line of the report,
  the rest still runs.
- **`:Case timeline`'s session durations are a lower bound, stated
  deliberately**: it groups file mtimes into sessions (gap ≤
  `config.timeline_session_gap_minutes`, default 120), but an mtime is a
  save point, not "editing started here" — a session with one touch shows
  `touched` (0 duration) even though real work preceded that save. Good
  enough for "when/how often was I in this case"; a trustworthy time-spent
  number would need real focus tracking (buffer enter/leave over the
  case's lifetime), which is exactly the separate logbook this approach
  avoids — see `docs/ROADMAP/casedesk/CONCEPT.md` §8h.
- **`:Case ki import` matches sections by their leading digit, not exact
  wording.** The prompt `:Case ki` builds asks for five `## N. …` headings
  in a fixed order (see `templates/KiPrompt.md`), but the parser
  (`ki.lua`'s `M.parse_response`) only looks at the `N.` — an LLM is far
  more reliable at keeping a numbered list's numbers straight than at
  reproducing an exact heading string. A missing section is silently
  skipped, not an error; "no numbered section found at all" and "sections
  1-3 all empty" are. The second case exists because `KiPrompt.md` spells
  the requested format out verbatim, so **the prompt itself parses as a
  well-formed, entirely empty answer** — pasting it back (clipboard still
  holds what `:Case ki` put there) used to file three headline-only files
  and append the whole activity stream to `Notes.md`. Now it says
  "that's the prompt, not the answer". Note
  the token spelling in the template: `{activitystream}`, no underscore —
  `templates.lua`'s substitution pattern (`%{(%w+)%}`) doesn't match one,
  the same first-run bug documented in `docs/ROADMAP/casedesk/CONCEPT.md`
  §8i.
- **`:Cases export` needs `pandoc` and a Chrome/Edge on PATH/in a known
  install location** — neither ships with Neovim. `pandoc` isn't
  reimplemented (markdown → HTML) and neither is a PDF engine (a headless
  browser's own `--print-to-pdf` is used instead of pulling in `pdflatex`,
  which is a multi-GB LaTeX install for this one use). If `pandoc` was just
  installed, restart Neovim — `vim.fn.executable()` only sees `$PATH` as of
  process start, not a PATH change made after.
