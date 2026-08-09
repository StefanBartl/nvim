# casedesk — Workflow & Use Cases

## Auto-detected fields (`detect.lua`)

Best-effort guesses from a case's own files, never written without going
through `:Case info`'s `e` edit form first (same "suggestion, not autopilot"
contract as `title`/`name`):

- **Tosca version** — `detect.tosca_version` scans for a
  `Ressources/ToscaSupportInfo*.txt` (SAP support attaches this) and pulls
  the `Tosca Testsuite Version: X.Y.Z` line. Pre-fills the `tosca_version`
  field in `e` when present.
- Title, contact name, links — see `detect.lua`'s existing doc comments.

## Mental model

Three verbs, everything else follows from which one you reach for:

- **`:Case`** — you're *in* a case. Every route resolves to exactly one
  case: explicit `[nr]` → the case owning your current buffer → a
  `kit.select` prompt. Almost always you can drop `[nr]` entirely and just
  work from wherever you already are.
- **`:Cases`** — you're looking *across* cases. Filters, search, reports,
  bulk maintenance.
- **`:Tricentis`** — you're looking across the **whole work repo**, not just
  SAP_Support cases (`Notes/`, `Workflow/`, `Terminologie/`, `Tosca/` too).
  Currently just the link picker, but scoped separately from `:Cases` on
  purpose — it answers a different question ("where did I see that link,
  anywhere") than `:Cases` does ("which of my cases…").

## 1. A new ticket lands

```
:Case new
```

Prompts for case number (the short SNOW number, e.g. `1012345` — the only
field that's actually validated, digits within `config.case_number_min_
digits`–`_max_digits`), then title, company, name, link — all four
optional, Enter on empty just leaves them blank. Shows the dry-run plan,
confirm, and it scaffolds:

```
Cases/Open/1012345/
  Summary.md                (SNOW-facing, no H1 — see §2)
  Notes.md                  (yours — see §2)
  Research/00_Research.md   (opened automatically, links to the reply draft)
  Replies/00_PSO.md
  Ressources/
  .case.json
```

`Research/00_Research.md` opens with a `[→ Reply draft](../Replies/00_PSO.md)`
link right under the headline — `gf` (or your file picker of choice) jumps
straight to the draft. Deliberately **one-directional**: `Replies/00_PSO.md`
stays free of any markdown, since its content is what actually goes out to
the customer and `:Case reply check` already flags a stray `##` for exactly
that reason — a permanent link back would be one more thing to remember to
strip before sending. `gopath.nvim`/your buffer list cover the reverse hop
for now (ROADMAP.md's plugin-check has a note to wire it in properly).

If `config.company_blueprints` has an entry for the company you typed, that
blueprint is used instead of the default — today the table is empty, so
every case gets the same scaffold until you actually add a company-specific
one.

Also saves a Neovim session under the case number right after scaffolding —
picking the case back up tomorrow is `<leader>cs`'s counterpart, `:Session
load 1012345` from inside Neovim, `case 1012345` from a fresh shell
(PowerShell-Funktion, `$PROFILE`), or just plain `nvim` (`autoload = true`
resumes whatever session you loaded last) — not re-opening the folder and
rebuilding whatever split layout you had. See
[Keymaps.md](./Keymaps.md) and
[docs/ROADMAP/casedesk/SESSIONS.md](../../ROADMAP/casedesk/SESSIONS.md).

Already pasted the SNOW ticket URL and don't want to retype the number?
`:Case new` also accepts the number directly: `:Case new 1012345`.

**Then, before you start digging:**

```
:Case similar
```

Ranks past cases by how much distinctive vocabulary they share with this
one's title + `Summary.md`, and shows the matching terms next to each hit.
The point is brainstorming: "have I solved something like this before?" —
a DEX setup problem surfacing the other DEX case, an SAP Fiori element
issue surfacing the other Fiori one.

Two things to know so the results aren't misleading:

- It matches **words, not meaning**. A past case about the same problem
  described in completely different wording won't show up. The displayed
  terms are there for exactly this reason — glance at them to judge whether
  a hit is real or just shared jargon (`customer`, `tosca` matching means
  nothing; `dex execution` matching means something).
- It only works as well as your summaries. Cases with a near-empty
  `Summary.md` are skipped entirely (currently 8 of 20), and thin ones on
  both sides produce weak scores. **This is the single biggest lever**: a
  few sentences of real problem description in `Summary.md` — the actual
  error message, the component, the symptom — makes every future
  `:Case similar` better. Writing it also costs nothing extra, since you'd
  summarize the case anyway.

**Got the SNOW Activity Stream copied and want a second opinion before you
dig in yourself?**

```
:Case activity     " optional: save the raw stream as a Research/ record first
:Case ki           " build the analysis prompt, copy it to the clipboard
```

Paste into whatever AI chat you have open (Gemini, Claude, …) and send it.
`:Case ki` reads the same clipboard `:Case activity` reads — running both is
"keep the raw record, then also analyze it," not two different sources.
The prompt it builds (`templates/KiPrompt.md`) bundles your role
description, the CDX policy/workflow docs, this case's title/company/
contact, the activity stream, and a fixed five-part answer format — the
same content you used to hand-copy from `StartChat.md` plus three resource
paths, every single case.

Once the AI answers, copy its full reply and:

```
:Case ki import
```

Splits it by the numbered sections and files each one:

| Section | Goes to |
| --- | --- |
| 1–3: analysis, difficulty, solution/next steps | `Research/NN_KiAnalysis.md` |
| 4: reply draft (English) | new `Replies/NN_Reply.md` |
| 5: internal notes (German) | appended to `Notes.md` |

**The reply draft is still just a draft** — it lands in `Replies/` like any
other, and goes through `:Case reply check` (§2) before anything is sent.
Nothing about this round trip talks to an AI on its own or sends anything
automatically; it only makes the copy-paste in both directions reliable.
If the pasted answer doesn't follow the numbered format (or you paste the
wrong thing), `:Case ki import` says so instead of silently filing garbage
— including the easy mistake of importing straight after `:Case ki`, with
the prompt still in the clipboard and no chat in between.

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
- `:Case template` — then fill that draft from the block library instead of
  retyping: `RequestMoreInfo`, `CloseCase`, `GermanSpeaker`,
  `Swarming/HandOverCase`, the whole `Wordings/` set. `<Tab>` completes the
  names, the block lands at your cursor with `{case}`/`{name}` already
  filled in. A new block is just a new `.md` under the work repo's
  `Workflow/Templates/` — it shows up in the picker with no code change.
- `:Case copy <path>` — pull a screenshot/log/attachment in; you pick the
  target folder (`Replies`/`Research`/`Ressources`/case root).
- `:Case ki` / `:Case ki import` — the AI-analysis round trip, covered in
  §1 above (usually the very first thing you run on a new ticket, but
  nothing stops you running it again mid-case with a fresh activity
  stream — a swarming request, an escalation reply, anything worth a
  second read).
- `:Case add <name>` — anything that isn't a reply, e.g.
  `:Case add Terminologie` for a case-local glossary note. Whatever you
  write there is automatically findable from every other case too, via
  `:Cases terminology` (§4) — no need to move it anywhere yourself.
- `:Case summary` / `:Case notes` — **two different documents, don't mix
  them up.** `Summary.md` is what you paste into the ServiceNow ticket:
  fixed four sections, plain text, no markdown (SNOW renders none of it, a
  `**bold**` lands verbatim in the ticket). `Notes.md` is yours — what you
  tried, what a coach said, tasks out of a meeting. Keeping them apart is
  what lets you paste the summary without editing it first.
- `:Case info` — the infocard. `e` to fill in Company/Priority/Tosca-Version/
  Name/Notes as they become known — nothing here is required up front.
  `:Case new`'s prompt chain doesn't insist on anything either besides the
  case number itself (title/company/name/link can all be left blank, Enter
  on empty) — the only value that has to be real is the one the folder gets
  named after.
- `:Case sync` — jumped straight into `Replies/` without ever running
  `:Case new` (e.g. a case that predates casedesk, or you deleted something
  by accident)? This adds back whatever blueprint pieces are missing,
  without touching what's already there.

**Before you send that reply:**

```
:Case reply check
```

Runs on whatever buffer you're looking at — normally the reply draft, no
reason it couldn't be `Notes.md` too. Reports emoji count (`c` removes
them), any stray `##` (a reply is plain text, SNOW/email doesn't render
markdown), and whether the links you're about to send are still alive.
`s` then launches `language.nvim`'s own spellcheck on the buffer — this
module doesn't reimplement grammar checking, it just gives you one place to
trigger it from alongside the other checks.

The statusline shows `<case> · <company> · N replies` the whole time you're
inside a case buffer — a glance tells you which case you're in and how many
reply drafts already exist, no command needed.

Lost track of when you actually touched this case, or writing a status
update and need "when did I last make progress here"?

```
:Case timeline
```

Groups every file touch into work sessions (a `:Case reply check` save five
minutes after a `Research/` edit is the same sitting; three days of silence
in between is a new one), oldest first, with a rough total. Read the total
as a **floor**, not a real hour count — it only knows about save points, not
how long you stared at the problem before the first one.

## 3. Wrapping up

```
:Case close       " -> Cases/Closed/<nr>
:Case reassign     " -> Cases/Reassigned/<nr>, someone else picked it up
```

Both are plain folder moves — nothing else in `.case.json` needs updating,
the state IS the folder (`CONCEPT.md` §3).

Handing a case off, or want one file to archive/attach elsewhere instead of
a folder of loose markdown?

```
:Cases export
```

Bundles `Summary.md`/`Notes.md`/`Research/`/`Replies/` into a single PDF
(`<case-dir>/Export.pdf`), opened automatically once it's done. Needs
`pandoc` and a Chrome/Edge install — see Usercmds.md if it complains about
either being missing.

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
| "Where did I see that link — in a case, my notes, anywhere?" | `:Tricentis links` (or `:Tricentis links notes`/`cases`/… to narrow) — see below |
| "What was that term again — didn't I explain it in some other case?" | `:Cases terminology` (or `:Cases pickers` → Terminology) |
| "What have we had with this company before?" | `:Cases history` (drops the company from your current case) or `:Cases history Scan` |

`--exact`/`-e` and `--re`/`-r` narrow any of the field filters, `:Cases
find`, or `:Cases grep` beyond the substring default — reach for `--exact`
when a substring match is pulling in noise (`company Scan` also matching
some unrelated "Scanner" mention, say), `--re` for an actual pattern
(`:Cases grep "[Ee]rror" --re`).

**`:Tricentis links` is the one command that isn't case-scoped at all.**
`:Cases grep`/`linkcheck`/`pickers` only ever look inside
`Cases/SAP_Support`; `:Tricentis links` reads the whole work repo — `Notes/`,
`Workflow/`, `Terminologie/`, `Tosca/` too, 617 links across all of it as
of this writing. Reach for it instead of `Notes/Links.md`, the old
hand-maintained collection: everything in there is already written
somewhere else, this just finds it instead of asking you to copy it twice.

## 5. Bestand hygiene

Not a per-case action — a periodic sweep, the same spirit as `:Cases stale`:

```
:Cases doctor       " report only, read-only
:Cases normalize     " dry-run + confirm, fixes what doctor found
```

Worth running **occasionally** (monthly, or whenever something feels
inconsistent), not after every single case — `doctor` catches: work notes
under one of four historical alias names instead of `Notes.md`,
`Research`/`Solution` as a flat file instead of a folder, two known
typo'd filenames, any file directly in `Research`/`Replies` missing its
`NN_` prefix, and a `Summary.md` that either isn't there, doesn't follow
the SNOW template's four sections, or uses markdown SNOW won't render.

The last two are **report-only** — no rename can produce text you have to
write yourself, so `normalize` deliberately leaves them alone and the
report says `[edit by hand]`. Treat them as a to-do list, not an error.
`normalize` fixes everything unambiguous automatically;
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
bestand carried one more piece of structure." Two ideas that would each
unlock something concrete, roughly cheapest-first:

- **A `category`/`tags` field in `.case.json`** — one line in
  `config.infocard_fields`, gets `:Cases category X` as a filter for free.
  `:Cases history` shipped without needing this (company + state + last-
  touched was enough), but a "which cases are network-config issues vs.
  data problems" grouping would need *some* signal beyond company and
  free-text, and there isn't one today.
- **A fixed `Ressources/` subfolder taxonomy** (`Logs/`, `Screenshots/`,
  rather than whatever a given case happened to create) — turns the
  Attachments picker (`:Cases pickers`) from guessing-by-extension into a
  straight folder read, and would be the precondition for any future
  automated log-scanning (the `spotlight.nvim` integration idea in
  ROADMAP.md's plugin-check section).

The trade-off, in all three cases: every added field or convention is
something `:Cases doctor` has to police from then on, and something you
have to remember while working a case under deadline. The current
minimalism (four folders, six scalar fields) is itself the feature — fast
to start a case, nothing to get wrong. Worth adding one of the above only
once there's an actual command that needs it, not preemptively.
