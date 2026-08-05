# casedesk — Workflow & Use Cases

How to actually use `:Case`/`:Cases` day to day, now that the bestand is
migrated and cleaned up (0 `:Cases doctor` findings as of 2026-08-05, see
[`MIGRATION.md`](../../ROADMAP/casedesk/MIGRATION.md)). Command reference:
[`Usercmds.md`](./Usercmds.md).

## Mental model

Two verbs, everything else follows from which one you reach for:

- **`:Case`** — you're *in* a case. Every route resolves to exactly one
  case: explicit `[nr]` → the case owning your current buffer → a
  `kit.select` prompt. Almost always you can drop `[nr]` entirely and just
  work from wherever you already are.
- **`:Cases`** — you're looking *across* cases. Filters, search, reports,
  bulk maintenance.

## 1. A new ticket lands

```
:Case new
```

Prompts for case number (the short SNOW number, e.g. `1012345`), title,
company, name. Shows the dry-run plan, confirm, and it scaffolds:

```
Cases/Open/1012345/
  Summary.md
  Research/00_Research.md   (opened automatically)
  Replies/00_PSO.md
  Ressources/
  .case.json
```

If `config.company_blueprints` has an entry for the company you typed, that
blueprint is used instead of the default — today the table is empty, so
every case gets the same scaffold until you actually add a company-specific
one.

Already pasted the SNOW ticket URL and don't want to retype the number?
`:Case new` also accepts the number directly: `:Case new 1012345`.

## 2. Working a case

You're inside `Research/00_Research.md` (or any file under the case) — every
`[nr]`-taking command below just works with no argument, because your
buffer resolves it:

- `:Case snow` — copy (or open, once `snow_url_format` is set) the full
  ServiceNow ticket id, for pasting into SNOW itself.
- `:Case activity` — copied an Activity Stream out of SNOW? Paste-and-run:
  it lands as a new `Research/NN_ActivityStream.md`, numbered automatically.
  No retyping, no manual filename.
- `:Case add reply` — start a new reply draft (`Replies/NN_Reply.md`).
  Working two threads in parallel (e.g. one for a data request, one for the
  actual fix)? Name them: `:Case add reply AskForPDF` and
  `:Case add reply ProposeFix` instead of two generic `Reply.md`s.
- `:Case copy <path>` — pull a screenshot/log/attachment in; you pick the
  target folder (`Replies`/`Research`/`Ressources`/case root).
- `:Case add <name>` — anything that isn't a reply, e.g.
  `:Case add Terminologie` for a case-local glossary note (see §5 below for
  why that one's worth reconsidering).
- `:Case info` — the infocard. `e` to fill in Company/Priority/Tosca-Version/
  Name/Notes as they become known — nothing here is required up front,
  `:Case new`'s prompt chain only insists on a title.
- `:Case sync` — jumped straight into `Replies/` without ever running
  `:Case new` (e.g. a case that predates casedesk, or you deleted something
  by accident)? This adds back whatever blueprint pieces are missing,
  without touching what's already there.

The statusline shows `<case> · <company> · N replies` the whole time you're
inside a case buffer — a glance tells you which case you're in and how many
reply drafts already exist, no command needed.

## 3. Wrapping up

```
:Case close       " -> Cases/Closed/<nr>
:Case reassign     " -> Cases/Reassigned/<nr>, someone else picked it up
```

Both are plain folder moves — nothing else in `.case.json` needs updating,
the state IS the folder (`CONCEPT.md` §3).

## 4. Finding things across cases

| You want... | Run |
| --- | --- |
| "What am I working on?" | `:Cases list` (grouped by state) or `:Cases recent` (by last-touched) |
| "Which cases are Scania's?" | `:Cases company Scan` |
| "Scania cases from this year" | `:Cases find company=Scan year=2026` |
| "Did I ever write about that error message?" | `:Cases grep "NullReferenceException"` |
| "What's gone quiet?" | `:Cases stale` (7+ days idle, oldest first) — a Monday-morning check |
| "Where's that PNG/log I attached three weeks ago?" | `:Cases pickers` → Attachments |
| "That link I sent — did the docs page move?" | `:Cases linkcheck` (or `:Cases linkcheck <nr>` for just one case) |

`--exact`/`-e` and `--re`/`-r` narrow any of the field filters, `:Cases
find`, or `:Cases grep` beyond the substring default — reach for `--exact`
when a substring match is pulling in noise (`company Scan` also matching
some unrelated "Scanner" mention, say), `--re` for an actual pattern
(`:Cases grep "[Ee]rror" --re`).

## 5. Bestand hygiene

Not a per-case action — a periodic sweep, the same spirit as `:Cases stale`:

```
:Cases doctor       " report only, read-only
:Cases normalize     " dry-run + confirm, fixes what doctor found
```

Worth running **occasionally** (monthly, or whenever something feels
inconsistent), not after every single case — `doctor` catches: a case-note
file under one of five historical alias names instead of `Summary.md`,
`Research`/`Solution` as a flat file instead of a folder, two known
typo'd filenames, and any file directly in `Research/`/`Replies/` missing
its `NN_` prefix. `normalize` fixes everything unambiguous automatically;
anything genuinely ambiguous (two files that would both land on the same
target) is reported separately for a manual call — see `MIGRATION.md`'s
711373 writeup for a worked example of exactly that.

One wrinkle worth knowing: `normalize` can occasionally need **two passes**.
Its own `Research.md` (flat) → `Research/Research.md` fix, for instance,
produces a file that itself doesn't have an `NN_` prefix yet — `doctor`
correctly flags that as a new, separate finding on the next run. Just run
`:Cases doctor` again after a `normalize` pass; if it's not 0, `normalize`
again.

## 6. Where this could grow (not built — food for thought)

At the current scale (~20 cases) nothing here is performance-bound; every
`:Cases` command completes in well under a second. The interesting
question isn't "faster," it's "what new command becomes possible if the
bestand carried one more piece of structure." Three ideas that would each
unlock something concrete, roughly cheapest-first:

- **Consolidate scattered per-case `Terminologie.md` files into the
  existing shared `Terminologie/`** (already a sibling of `Cases/`, never
  part of the migration). Right now a term explained in one case's local
  `Terminologie.md` is invisible to every other case. Once shared,
  `:Cases grep` already searches it for free.
- **A `category`/`tags` field in `.case.json`** — one line in
  `config.infocard_fields`, gets `:Cases category X` as a filter for free.
  The actual payoff is downstream: ROADMAP.md v8's "ähnliche Cases
  vorschlagen" / "Company-Historie" ideas need *some* signal to group cases
  by, and there isn't one today beyond company and free-text.
- **A fixed `Ressources/` subfolder taxonomy** (`Logs/`, `Screenshots/`,
  rather than whatever a given case happened to create) — turns "Anhänge-
  Picker nach Typ" (ROADMAP.md v5) from guessing-by-extension into a
  straight folder read, and would be the precondition for any future
  automated log-scanning (the `spotlight.nvim` integration idea already
  noted in ROADMAP.md's plugin-check section).

The trade-off, in all three cases: every added field or convention is
something `:Cases doctor` has to police from then on, and something you
have to remember while working a case under deadline. The current
minimalism (four folders, six scalar fields) is itself the feature — fast
to start a case, nothing to get wrong. Worth adding one of the above only
once there's an actual command that needs it, not preemptively.
