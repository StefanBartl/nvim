# casedesk — User Commands Cheatsheet

Two composer verbs, built via `lib.nvim.usercmd.composer` — `:Case` acts on
**one** case (always resolves to exactly one: explicit arg → buffer →
`kit.select`), `:Cases` acts on a **set**. `[case]`/`[nr]` everywhere below
is the same optional `CASE` arg type, `<Tab>`-completed from the on-disk
registry; typing the full SNOW ticket id works too, it's normalized down to
the short number.

Source: `lua/bindings/usrcmds/case/init.lua` (routes), `ui.lua` (handlers).
Concept: [`docs/ROADMAP/casedesk/CONCEPT.md`](../../ROADMAP/casedesk/CONCEPT.md).
Feature history: [`docs/ROADMAP/casedesk/ROADMAP.md`](../../ROADMAP/casedesk/ROADMAP.md).
Use cases / daily workflow: [`Workflow.md`](./Workflow.md).

## `:Case` — one case

| Command | Args | What |
| --- | --- | --- |
| `:Case new [nr]` | case number, prompts for the rest | Prompt chain (title/company/name) → dry-run plan → confirm → scaffold. Respects `config.company_blueprints` if the company entered maps to one. |
| `:Case info [nr]` | — | Infocard (`kit.viewer`) — `e` edit, `s` summary, `o` open folder, `q` close |
| `:Case summary [nr]` | — | Open `Summary.md` |
| `:Case research [nr]` | — | Open `Research/00_Research.md` |
| `:Case reply [nr]` | — | Open the newest file in `Replies/` |
| `:Case open [nr]` | — | Open the case folder (filetree reveal if `filetree.nvim` is loaded, else netrw) |
| `:Case add <name> [suffix]` | `name`, optional `suffix` | New `<name>.md` in the case root. `name == "reply"` is special: auto-numbers into `Replies/`, `[suffix]` overrides the stem (`:Case add reply AskForPDF` → `NN_AskForPDF.md`; omitted → `NN_Reply.md`) |
| `:Case activity [nr]` | — | Paste the system clipboard (a ServiceNow Activity Stream) into a new auto-numbered `Research/NN_ActivityStream.md` |
| `:Case similar [nr] [n]` | `n`, default 5 | Past cases whose title + `Summary.md` share the most distinctive vocabulary (TF-IDF cosine, no AI). Each hit shows the matched terms — the ranking is lexical, so seeing *why* it matched is how you judge it |
| `:Case copy [src]` | source path, prompts if omitted | Copy a file into the case; target folder (`Replies`/`Research`/`Ressources`/root) via `kit.select` |
| `:Case sync [nr]` | — | Add whatever blueprint pieces are still missing (never overwrites) |
| `:Case close [nr]` | — | Move to `Closed/` |
| `:Case reassign [nr]` | — | Move to `Reassigned/` |
| `:Case snow [nr]` | — | Open the ServiceNow ticket URL (if `config.snow_url_format` is set) or copy the ticket id |

Bare `:Case` (no subcommand) runs `:Case info` with no argument.

## `:Cases` — the cross-case querschnitt

| Command | Args | What |
| --- | --- | --- |
| `:Cases list` | — | Every case, grouped by state |
| `:Cases title/company/name/notes/priority/tosca_version [pattern] [--exact\|-e] [--re\|-r]` | one route per `config.infocard_fields` entry | Substring case-insensitive by default; `--exact`/`-e` = full-string equality; `--re`/`-r` = Lua pattern (case-**sensitive**, see Notes below). Empty pattern = "field is set at all". One hit opens its infocard directly, several go to `kit.select` |
| `:Cases find key=value ... [--exact\|-e] [--re\|-r]` | bare `key=value` pairs, no dashes | AND-combination across several `infocard_fields` at once, e.g. `:Cases find company=Scan year=2026` |
| `:Cases grep <pattern> [--re\|-r]` | — | Full-text search across every case's `.md` files (not `Ressources/` attachments). Report via `kit.viewer`, capped at 500 hits |
| `:Cases recent [n]` | `n`, default 10 | The `n` most recently touched cases, newest first |
| `:Cases stale [days]` | `days`, default 7 | Open cases idle for at least `days`, oldest first |
| `:Cases stats` | — | Counts by state / company / year |
| `:Cases doctor` | — | Bestand-consistency report (read-only) — summary-file aliases, `Research`/`Solution` as file vs. folder, known typos, missing `NN_` prefixes |
| `:Cases normalize` | — | Fixes exactly what `doctor` found — dry-run plan (`kit.viewer`) + confirm, then applies. Skips (reports separately) anything ambiguous: target already exists, or two findings in the same case would land on the same target |
| `:Cases linkcheck [nr]` | — | Checks `docs.tricentis.com` links (only that host) for dead pages, async bounded-concurrency HEAD requests |
| `:Cases pickers` | — | `kit.menu` discovery surface: Attachments (`Ressources/`, text opens in-buffer, everything else via the system default app), Links (opens externally, falls back to clipboard), Cases without `.case.json` |

Bare `:Cases` (no subcommand) runs `:Cases list`.

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
- **`:Case similar` is lexical, not semantic**: it matches *words*, not
  meaning — two cases describing the same problem in entirely different
  wording score 0. It also skips any case whose `Summary.md` is too thin
  (under 8 distinct terms after stopword removal), and needs at least 2
  shared terms before counting a hit at all — both thresholds exist because
  the first evaluation run produced an 87% "match" between two near-empty
  summaries sharing the single word "Research". See
  `docs/ROADMAP/casedesk/ROADMAP.md` v8 for the full evaluation and the
  open question of whether this suffices or an embedding model is needed.
- **`:Cases pickers` runs entirely on `kit.select`**, the same backend every
  other multi-result flow in `ui.lua` uses. The `pickers.nvim`/
  `snacks.picker` backend cascade `docs/ROADMAP/casedesk/ROADMAP.md` v5 also
  lists is deliberately deferred — `pickers.nvim`'s public API expects an
  internal `Source`+`engine_mod` object from its own config/engine
  resolution, not a trivial "picker over this list" entry point.
