# Open roadmap items — cost/benefit review

**Reviewed:** 2026-09-17 · **Updated:** 2026-09-21 — everything the review
ranked as done, already built or rejected has been struck; this file now holds
the decisions that keep it closed. Nothing ranked by it is open any more.
**Scope:** all 38 `ROADMAP/ROADMAP.md` files under
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`, plus the sibling
documents they hand their queue to.
**Where the closed work is recorded:** each plugin's own `FEATURES.md` (and
`DONE.md` where it has one); the hand-off prompts for it are in
[`../personal/All/FINISH/ERLEDIGT/Tasks-offene-Punkte.md`](../personal/All/FINISH/ERLEDIGT/Tasks-offene-Punkte.md).
**Regel-Audit:** finished — `ERR-50`/`ERR-22` on all 31 repos, the 313-rule
breadth pass, and two review rounds over the campaign's own commits. The
consolidated record is [`Regel-Audit-Gesamtstatus.md`](Regel-Audit-Gesamtstatus.md);
its hand-off prompts moved to
[`../personal/All/FINISH/ERLEDIGT/Regel-Audit-Tasks.md`](../personal/All/FINISH/ERLEDIGT/Regel-Audit-Tasks.md).

---

## Table of content

  - [1. Method](#1-method)
  - [2. What is left](#2-what-is-left)
  - [3. Do not do these](#3-do-not-do-these)

---

## 1. Method

Every roadmap was read in full. Then every item that would otherwise have been
ranked "cheap and valuable" was checked against the source tree in
`$REPOS_DIR` before it was costed. That check earned its keep: the item ranked
first (migrate `pdfport.nvim` onto `ai.nvim` for a security reason) rested on
two defects that were already fixed, and 15 items listed as open were already
built.

Effort is in **working sessions** (one focused sitting, roughly a half day).

Two rules this review keeps paying for:

- **Cost an item from the source, not from its own description.** Entries go
  stale silently; the description of a roadmap item is a claim, not a
  measurement.
- **A green test suite is not evidence that an interactive path works.** The
  re-check of one round's own fixes found nine critical bugs in a UI split
  that every test had passed, because nothing had driven the callbacks that
  broke. Only running it, or a test that drives it, counts.

Not covered: the queue that `documentation.nvim` and `runtime-analysis.nvim`
hand to `docmap-desktop/docs/PLAN.md` — that plan lives outside this
collection.

---

## 2. What is left

Nothing. Checked against source on 2026-09-21; every item this review ranked is
shipped, was already built, or is a recorded decision (§3).

---

## 3. Do not do these

Decisions, each with the reason, so nobody re-opens them by accident.

| Plugin | Item | Why not |
|---|---|---|
| `gopath.nvim` | Treesitter instead of line patterns in `symbol_locator`/`table_locator` | The roadmap costs it at **a week**, because all 8 fallback strategies in `table_locator.locate` must be preserved — and the current patterns were chosen deliberately, for tolerance of line breaks after `=`, bracket keys and tables inside calls. Fix concrete bugs as they appear instead |
| `lsp.nvim` | Shrink the signature-help module | Its own entry says "large (just observe for now)", and it has grown from ~800 to 1,322 LOC since. Nothing reports it as a problem |
| `mdview.nvim` | PDF page preview in the link hover | Costed honestly at ~1s of hover latency plus softening the `/asset` containment check. The clean road (pre-render at doc-push time) is written down; wait for a concrete case |
| `mdview.nvim` | Cooperative tab closing in `browser.mode = "default"` | Investigated 2026-09-18 and rejected: `window.close()` only closes a tab the script itself opened. Reasoning in `mdview.nvim/ROADMAP/ROADMAP.md` |
| `casedesk.nvim` | `area` in `.case.json` | The roadmap itself argues against it: an area is derived from where the case lies, and a stored copy that disagrees with the folder is wrong rather than helpful. Leave it as a question |
| `ui.nvim` | Own terminal implementation instead of `Snacks.terminal` | Raised in feedback, never commissioned. The actual complaint (no border) was fixed with one explicit option |
| `lib.nvim` | Windows elevation in the dependency installer | A deliberate design choice, documented in `deps/pm/init.lua` and `deps/README.md`: nothing beyond a `sudo` prefix, Windows elevation is the package manager's own UAC prompt. Only worth a look if someone lands on a machine that really needs it |
| `debugging.nvim` | A `docs/install.json` | Its externals are per-platform (clipboard helpers, Windows PowerShell) and the install spec has no platform filter, so `:Lib deps status` would list the other platform's tools as missing everywhere. Revisit only if the spec grows a platform key |
| `sandbox.nvim` | A `docs/install.json` for `podman`/`docker`/`nerdctl` | The spec answers "is the binary on `PATH`"; sandbox needs an engine that *answers*. `:Lib deps install` could install a CLI with no running daemon and report success while nothing works. `:checkhealth sandbox` already tells the two apart |
