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
| `:Case new [nr]` | case number, prompts for the rest | Prompt chain (title/company/name/SNOW link/SAP Resolve link) → dry-run plan → confirm → scaffold. Both links, if given, land together in `.case.json`'s `links`. Respects `config.company_blueprints` if the company entered maps to one. Only the case number is actually required (`config.case_number_min_digits`–`_max_digits` plausible digits) — every other field can be left blank (Enter on empty) without crashing or half-creating anything |
| `:Case info [nr]` | — | Infocard (`kit.viewer`) — `e` edit, `s` summary, `o` open folder, `q` close |
| `:Case summary [nr]` | — | Open `Summary.md` — the **ServiceNow-facing** document (fixed four-section template, no markdown; see Notes below) |
| `:Case notes [nr]` | — | Open `Notes.md` — your **private** work notes (what was tried, coach input, meeting tasks) |
| `:Case template [name]` | block name, `<Tab>`-completed; prompts if omitted | Insert a reply block from the work repo's `Workflow/Templates/` at the cursor, with `{case}`/`{name}`/`{title}`/`{today}` filled from the current buffer's case |
| `:Case research [nr]` | — | Open `Research/00_Research.md` |
| `:Case reply [nr]` | — | Open the newest file in `Replies/` |
| `:Case open [nr]` | — | Open the case folder (filetree reveal if `filetree.nvim` is loaded, else netrw) |
| `:Case add <name> [suffix]` | `name`, optional `suffix` | New `<name>.md` in the case root. `name == "reply"` is special: auto-numbers into `Replies/`, `[suffix]` overrides the stem (`:Case add reply AskForPDF` → `NN_AskForPDF.md`; omitted → `NN_Reply.md`) |
| `:Case activity [nr]` | — | Paste the system clipboard (a ServiceNow Activity Stream) into a new auto-numbered `Research/NN_ActivityStream.md`. Also auto-detects Priority (SLA.md §6A), `sap_component`, `versions.server`/`versions.commander` (EXTRACTION.md §8), and `last_reply_sent` from a "Send to Customer" memo (EXTRACTION.md §5, never regresses a newer manual stamp) straight into `.case.json` — no manual step |
| `:Case reply check` | — | Pre-send gate on the **current buffer**: emoji count (`c` removes), stray markdown headlines, dead links, doc links on a different Tosca version than the customer's own (EXTRACTION.md §6), `s` launches `language.nvim`'s spellcheck on the buffer |
| `:Case similar [nr] [n]` | `n`, default 5 | Past cases whose title + `Summary.md` share the most distinctive vocabulary (TF-IDF cosine, no AI). Each hit shows the matched terms — the ranking is lexical, so seeing *why* it matched is how you judge it |
| `:Case timeline [nr]` | — | Work sessions reconstructed from file mtimes, oldest first — touches within `config.timeline_session_gap_minutes` (default 120) of each other count as one sitting. Each session's duration is a **lower bound** (a save marks when editing stopped, not started) |
| `:Case ki [nr]` | — | Build the AI-analysis prompt (role + policies + this case's activity stream, from the clipboard, one line of SLA urgency context — SLA.md §6E — PLUS a full "Ermittelte Fakten" block: priority/impact, SAP Component, Commander/Server versions, TBox-Build/Api-Core, custom DLLs, current SNOW state, SLA clocks, and a doc-link version tally — EXTRACTION.md §7) and copy it back to the clipboard, ready to paste into an AI chat. Also saved as `Research/NN_KiPrompt.md` |
| `:Case ki import [nr]` | — | Paste an AI answer (in the format `:Case ki` asked for) from the clipboard and file it: analysis/difficulty/next-steps → `Research/NN_KiAnalysis.md`, English reply draft → new `Replies/NN_Reply.md` (still goes through `:Case reply check`, never auto-sent), internal German notes → appended to `Notes.md`. Also checks the solution/reply text for a `docs.tricentis.com` link on a different Tosca version than the customer's own and warns immediately if found (EXTRACTION.md §7 Richtung 2) |
| `:Case copy [src]` | source path, prompts if omitted | Copy a file into the case; target folder (`Replies`/`Research`/`assets`/root) via `kit.select` |
| `:Case doclinks [nr]` | — | Every `docs.tricentis.com/tosca-<version>/` link in the case (Activity Streams + Replies) pointing at a version other than the customer's own. Customer version resolved most-reliable-first: `.case.json` → support-info (`detect.tosca_version`) → newest Activity Stream's Commander version. Also folded into `:Case reply check` (EXTRACTION.md §6) |
| `:Case sync [nr]` | — | Add whatever blueprint pieces are still missing (never overwrites) |
| `:Case solution [nr] [--edit|-e]` | — | The case's documented solution (`Solution/Solution.md`). Exists: shown read-only (`e` edit, `y` copies just the `## Lösung` section, `q` close). Doesn't exist: asks whether to create it from the template (`## Status`/`Problem`/`Ursache`/`Lösung`/`Verifikation`/`Schlagworte`/`Referenzen`) and drops you into `## Problem`. `--edit` skips the viewer. Reads legacy layouts too (flat `Solution.md`, `Solutions/`) so a not-yet-normalized case never looks solution-less |
| `:Case versions [component] [nr] [--all] [--raw]` | `component` — a `config.version_components` name, `server`, or any substring of any filename in the report | No args: curated digest (Testsuite/TBox build/Api Core/Install-Root + the "Auffällig" custom-DLL section) from `assets/ToscaSupportInfo*.txt`. A `component` copies its version to the clipboard (several matches → `kit.select`). `component = server` falls back to the newest Activity Stream's "Tosca Server - v…" prose — the support-info never has it, EXTRACTION.md §4.1 — and works even with no support-info file at all. `--all` lists every entry, grouped by directory. `--raw` opens the file itself |
| `:Case close [nr]` | — | Pick a destination (`kit.select`): any other state, or "Delete permanently" (types the case number back to confirm — irreversible, not a bare y/n). Moving deletes the case's saved session too, if it had one (SESSIONS.md §6) |
| `:Case reassign [nr]` | — | Move to `Reassigned/`, delete its saved session if it had one (SESSIONS.md §6) |
| `:Case solved [nr]` | — | Move to `Solved/`, same session cleanup as every other state-move verb |
| `:Case assigned [nr]` | — | Move to `Assigned/` |
| `:Case unassigned [nr]` | — | Move to `Unassigned/` |
| `:Case otheragent [nr]` | — | Move to `OtherAgent/` |
| `:Case delete [nr]` | — | Permanently delete the case — types the case number back to confirm, same irreversible gate as `:Case close`'s "Delete permanently" target, just reachable directly |
| `:Case attachments [nr]` | — | List this case's `assets/` files (`kit.select`, including nested `assets/initial/`), open the picked one — text opens in-buffer, everything else via the system default app. Same picker `:Cases pickers` → Attachments uses |
| `:Case snow [nr]` | — | Open the ServiceNow ticket URL (if `config.snow_url_format` is set) or copy the ticket id |
| `:Case sla [nr] [--doc]` | — | SAP-SLA status (see [SLA.md](../../ROADMAP/casedesk/SLA.md)): Erstreaktion/Rückmeldung/Korrekturmaßnahme, each as an absolute deadline + remaining time. Rückmeldung shows "wartet auf Kunden" instead of a countdown while the case sits in SNOW's own "Awaiting User Info" — it resets to a full fresh budget once they reply, not resumed from wherever it stood. `nil`/no line when the case has no parseable priority yet. `--doc` opens the source `SLA_ServiceLevelAgreement.md` instead, no case needed |
| `:Case insert [field] [nr]` | `field` `<Tab>`-completed: `case\|snow\|link\|title\|company\|name\|priority\|summary\|mail-subject`; prompts via `kit.select` (showing live values) if omitted | Insert that token at the cursor AND copy it to the clipboard, one action. `link` is the SNOW ticket URL (falls back to the plain id if `config.snow_url_format` isn't set), `mail-subject` is `[case] title`. With a Visual range (`:'<,'>Case insert [field]`) replaces the selection instead of inserting at the cursor — handy on a `<CASE>` placeholder |

Bare `:Case` (no subcommand) runs `:Case info` with no argument.

## `:Cases` — the cross-case querschnitt

| Command | Args | What |
| --- | --- | --- |
| `:Cases list` | — | Every case, grouped by state. Also the mark view: `m` toggles the case under the cursor, a Visual-line range + `m` toggles every case in it, `c` runs `:Cases close` on whatever's marked |
| `:Cases close` | — | Close several cases at once. Uses existing marks (`:Cases list`'s `m`) if any; otherwise opens `kit.select({multi=true})` — `<Tab>` toggles cases, `<CR>` confirms the set. Either way, asks ONCE where they all go (same destination picker as `:Case close`, incl. delete — bulk delete types `DELETE` to confirm) |
| `:Cases title/company/name/notes/priority/tosca_version [pattern] [--exact\|-e] [--re\|-r]` | one route per `config.infocard_fields` entry | Substring case-insensitive by default; `--exact`/`-e` = full-string equality; `--re`/`-r` = Lua pattern (case-**sensitive**, see Notes below). Empty pattern = "field is set at all". One hit opens its infocard directly, several go to `kit.select` |
| `:Cases find key=value ... [--exact\|-e] [--re\|-r]` | bare `key=value` pairs, no dashes | AND-combination across several `infocard_fields` at once, e.g. `:Cases find company=Scan year=2026` |
| `:Cases grep <pattern> [--re\|-r]` | — | Full-text search across every case's `.md` files (not `assets/` attachments). Report via `kit.viewer`, capped at 500 hits |
| `:Cases recent [n]` | `n`, default 10 | The `n` most recently touched cases, newest first |
| `:Cases stale [days]` | `days` optional | Open cases idle at least that long, oldest first. Omitted: each case uses its own priority-derived threshold (`config.sla_stale_days` — a P2 gets 2 days, a P4 gets 10; a case with no priority falls back to the old flat 7) instead of one number for everyone |
| `:Cases sla` | — | SLA dashboard: every OPEN case with a parseable priority, sorted by remaining time on its most urgent clock — "what breaches next", not grouped by priority label. `!!`/`!` mark overdue / under warning threshold. Selecting a row opens that case's `:Case sla` |
| `:Cases sla report [--year N]` | — | Retrospective, EVERY state (not just open — SLA.md §9 Q5): ratio of first-response deadlines met per priority, both anchors ("ab Ticket-Eingang"/"ab Zuweisung", SLA.md §9.1). Outliers listed with how late. A case with no `last_reply_sent` stamp yet is excluded from the ratio, not counted as missed, and reported as its own "ohne last_reply_sent" count. States up front it's "meine Sicht, keine SNOW-Wahrheit" (SLA.md §6D's honesty clause) |
| `:Cases history [company]` | `company`, defaults to the current buffer's case's company | Every matching case in one screen, grouped by state, most-recently-touched first within each group (`kit.viewer`, not a picker) |
| `:Cases stats` | — | Counts by state / company / year |
| `:Cases doctor` | — | Bestand-consistency report (read-only) — work-note aliases, `Research`/`Solution` as file vs. folder, known typos, missing `NN_` prefixes, whether each `Summary.md` follows the SNOW template without markdown, a saved session for a case that's no longer open (`stale-session`, SESSIONS.md §6), and an Activity Stream whose block count doesn't match its own declared total (`stream-incomplete`, EXTRACTION.md §4 — the SNOW view wasn't fully expanded before copying) |
| `:Cases normalize` | — | Fixes exactly what `doctor` found — dry-run plan (`kit.viewer`) + confirm, then applies. Skips (reports separately) anything ambiguous: target already exists, or two findings in the same case would land on the same target. `stale-session` findings delete the session instead of renaming anything |
| `:Cases linkcheck [nr]` | — | Checks `docs.tricentis.com` links (only that host) for dead pages, async bounded-concurrency HEAD requests |
| `:Cases pickers` | — | `kit.menu` discovery surface: Attachments (`assets/`, text opens in-buffer, everything else via the system default app), Links (opens externally, falls back to clipboard), Cases without `.case.json`, Terminology, CLI commands, Solutions |
| `:Cases export [nr]` | — | Bundles `Summary.md`/`Notes.md`/`Research/`/`Replies/` into one PDF at `<case-dir>/Export.pdf` (`pandoc` → HTML, then a headless Chrome/Edge → PDF), opened automatically on success |
| `:Cases solutions [begriff]` | free text, optional | Search every documented solution in the bestand — the payoff for `:Case solution`'s fixed format. Weighted TF-IDF over the solution files only: a term in `## Schlagworte` counts triple, in the case title double, and the query matching as a literal phrase multiplies the score. No pattern lists every solution. Rows show `matched/wanted` + the terms that hit, never a percentage (see Notes) |
| `:Cases terminology` | — | Every `## `/`### ` term collected from every `Terminologie.md` across the whole work repo (`terminology.lua`), `kit.select`-picked; selecting one jumps to it in its source file. Same entry point as `:Cases pickers` → Terminology |
| `:Cases insert [pattern]` | substring over number/title/company/name | Same as `:Case insert` but for a case OTHER than the one you're in — e.g. referencing "see also case 977123" from a different case's reply. 0 matches warns, 1 skips straight to the field picker, several go through a case picker first. Same Visual-range replace as `:Case insert` |

Bare `:Cases` (no subcommand) runs `:Cases list`.

## `:Tricentis` — the whole work repo, not just SAP_Support

| Command | Args | What |
| --- | --- | --- |
| `:Tricentis links [scope]` | `scope`, `<Tab>`-completed: `all\|cases\|notes\|workflow\|terminologie\|tosca\|todo` | Every link found under that area of the work repo, `kit.select`-picked, opened externally (falls back to clipboard). Supersedes hand-maintaining `Notes/Links.md`. Rows are one-per-URL-per-area with a `×N` repeat count, sorted by URL; the label drops scheme/`www.`/query string and collapses the MIDDLE of long URLs so host, version segment and page name survive |
| `:Tricentis commands [topic]` | `topic`, `<Tab>`-completed: `all\|enginelab\|mobile\|api\|excel\|engines\|tosca\|workflow\|notes\|terminologie\|cases\|todo` — any other string works too, matched as a substring of the file's repo-relative path | Every shell command written down anywhere in the work repo (harvested from `bash`/`powershell`/`cmd` code fences), `kit.select`-picked, selection copied to the clipboard. The row carries the nearest heading as context and a `×N` count when the same command is written down in several notes. Blocks that are console OUTPUT rather than input (stack traces, exception lines) are filtered out |
| `:Tricentis cheatsheet [topic]` | same `topic` as above | The same index rendered into one throwaway markdown buffer in a new tab, grouped by source file and in the order the notes write them — for a walkthrough note that file order IS the run order |

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
- **`:Case solution` writes one place, reads several.** New solutions always
  land at `Solution/Solution.md` — the convention `:Cases doctor` has been
  enforcing all along (it renames `Solutions/` and moves a flat
  `Solution.md` there). Reading also accepts those legacy spots, so a case
  that hasn't been normalized yet still shows its solution instead of being
  offered a second, empty one. Deliberately **not** a blueprint node: a
  solution comes into being when there is one, not when the case is
  scaffolded — an empty `Solution.md` in every fresh case would flood
  `:Cases solutions` with contentless hits, which is exactly what would make
  the search useless. `:Case solved` (and any state in
  `config.solution_reminder_states`) warns once when a case is filed away
  without one — a hint, never an automatic file.
- **`:Cases solutions` reports `matched/wanted`, not a percentage.**
  `:Case similar` compares two documents of the same kind, so its cosine is
  a real 0–1 figure; here a three-word query stands against a document, and
  any normalization of that would be invented precision. The section
  weighting (`## Schlagworte` ×3, title ×2, literal phrase ×1.5) shares
  `similar.lua`'s tokenizer — one vocabulary (stopwords, umlaut folding,
  markdown noise) for both searches, so they can't drift apart on what
  counts as a word. Same lexical limit as `:Case similar` too: the same
  problem in entirely different words scores 0 — `## Schlagworte` is the
  place where you loosen that by hand.
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
  `uv.fs_rename`** (`normalize.lua`, `:Case(s) close`/`reassign`) — retries
  a few times with backoff on Windows when a directory watcher or AV/indexer
  scan holds a transient lock on the file/folder being renamed. Looked at
  `fileops.nvim` for this first; its `rename`/`move` API turned out to
  operate on "the current buffer's file" only, not an arbitrary path, so it
  doesn't fit a bulk rename across the bestand — `mutate.rename_file` is
  the layer underneath that `fileops.nvim` itself uses. `:Case(s) close`'s
  "Delete permanently" destination goes through the same `mutate.retry`
  (wrapping `vim.fn.delete(dir, "rf")`, the same Windows-lock risk as a
  rename) — deliberately behind a stronger confirm than every other
  mutation here, since it's the one action in this module with no undo:
  typing the case number back for one case, `DELETE` for a batch, never a
  plain y/n.
- **`extract/stream.lua`'s attachment names are separated by blank
  lines, not terminated by the first one** — a real stream had
  `FileServices Properties.png`, a blank line, then `ToscaSupportInfo.txt`
  as a SECOND attachment on the same "New attachment(s) added" block; an
  earlier version of this parser stopped at the first blank line and
  silently dropped the second file. Now scans until the block's own
  `Show less` line instead.
- **`extract/stream.lua`'s error-code pattern requires two underscores
  (3+ segments), not one** — one underscore caught `HEC_ABAP` (a real SAP
  `Cloud System Type` value, not an error code) and a truncated `SE_A`
  fragment cut out of a mixed-case filename mid-match. Both were real
  false positives against real data, not hypothetical.
- **`:Case versions` never parses a version number, only compares
  strings.** Real formats seen across four support-info files:
  `34.8.0.280 (280)`, `2, 8, 0`, `3.3.0`, `2026.1` next to `25.1.7` on the
  same header — EXTRACTION.md §2. `report_created` is the same story:
  two locale-dependent formats (12h vs. 24h) with no field telling you
  which, so it's shown verbatim and never fed to a date parser.
- **`extract/facts.lua` is a pure aggregator, not a new parser.** Every
  line of the "Ermittelte Fakten" block reads from an extractor that
  already existed (`supportinfo`/`stream`/`sla`/`doclinks`/`meta`) — the
  module's only job is assembling and formatting. A missing signal
  degrades that one line to "unbekannt" (or the line is skipped
  entirely for TBox-Build/Api-Core/Custom-Controls when there's no
  support-info at all) rather than erroring.
- **`:Case doclinks` normalizes both Tosca version shapes to the doc-link's
  own form before comparing** — a doc URL only ever carries
  `<4-digit-year>.<minor>` (`tosca-2025.1`, never a patch digit), while the
  Testsuite version itself can be `25.1.7` (2-digit year) or `2026.1`
  (4-digit year, no patch, EXTRACTION.md §2). Comparing raw strings would
  flag every single case as a false mismatch. Real find: case 1041708 runs
  `25.1.2` per its support-info, one reply links `tosca-2026.1`.
- **A curated `version_components` entry (e.g. `tbox`) can genuinely exist
  in the support-info under two different paths with two different
  versions** — `Tricentis.AutomationBase.dll` ships its own copy under
  `ToscaCommander\` in addition to the `TBox\` root, real and confirmed,
  not a hypothetical. `extract/supportinfo.lua`'s lookup always prefers
  the TBox-root occurrence for a curated component; an uncurated substring
  search returns every match instead, since there's no single "main"
  answer to prefer there.
- **`config.known_vendor_prefixes` (the "Auffällig" filter) was built by
  extracting every real filename from a real TBox root, not guessed** —
  and it's expected to need occasional additions as Tosca versions add new
  dependencies, same "config as data, extend without touching the parser"
  shape as `version_components` itself. A legitimate library missing from
  the list shows up once as a false "Auffällig" hit; add its prefix and
  it's gone.
- **Active SLA notifications aren't a command — they run in the
  background.** For `config.sla_active_priorities` (P1/P2 by default), a
  15-min timer plus a `FocusGained` check (`sla/notify.lua`) warn once per
  clock breach (first response, cadence, or the fix window) — on top of
  the passive statusline badge, which only helps while that case's buffer
  is actually focused. Never repeats for the same breach, but re-arms once
  a clock resets to a fresh period (e.g. cadence after a customer reply
  moves the deadline). Set `config.sla_notifications_enabled = false` to
  turn the whole thing off.
- **A `doctor.lua` finding carries either `to` (a rename target) or
  `action` (a `fun(): ok, err` closure for a fix that isn't a rename),
  never both.** `stale-session` is the first `action` finding — it calls
  `sessions.delete(name)` instead of `mutate.rename_file`. `normalize.lua`
  treats both as equally "safe to auto-apply"; only `to`-findings go
  through the target-collision check (two findings landing on the same
  path), since an `action` finding has no path to collide on.
- **Marks (`marks.lua`) are a flat, session-global set of case numbers, not
  tied to any buffer or window.** Mark a few cases in `:Cases list`, close
  that view, run `:Cases close` five minutes (or five other commands)
  later — the marks are still there. `:Cases close` clears them after a
  successful apply, not before (a cancelled destination picker or bulk
  delete leaves the marks exactly as they were, so nothing is lost to a
  changed mind).
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
- **A trailing "Best regards, …" sign-off is stripped automatically**
  (`replygate.strip_signature`), both when `:Case template` inserts a
  block and when `:Case ki import` files the AI's reply draft — not a
  manual cleanup step, the line just never appears. Only the last 5 lines
  of the text are scanned, so a quoted "Best regards" deep in a pasted
  earlier email is left alone.
