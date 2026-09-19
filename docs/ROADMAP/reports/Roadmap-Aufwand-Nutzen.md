# Open roadmap items — cost/benefit review

**Date:** 2026-09-17
**Scope:** all 38 `ROADMAP/ROADMAP.md` files under
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`, plus the sibling
documents they hand their queue to (`ui.nvim/NOTES.md`,
`ui.nvim/PLAN-ui-kit-migration.md`, `ui.nvim/TASK-screenkey.md`,
`lib.nvim/ROADMAP/dependency-installer.md`, `filetree.nvim/ROADMAP/`).
**Goal:** one ranked view of what is actually left, what each item costs, and
what it buys.
**Hand-off prompts:** [`../personal/All/FINISH/ERLEDIGT/Tasks-offene-Punkte.md`](../personal/All/FINISH/ERLEDIGT/Tasks-offene-Punkte.md) — one
paste-ready task per open item, and a list of what had already been built
again by the time those were drafted.
**Regel-Audit follow-up:** [`Regel-Audit-Tasks.md`](Regel-Audit-Tasks.md) — hand-off prompts for what `Regel-Audit-Gesamtstatus.md`'s own four open construction sites still need (`ERR-50`/`ERR-22`, the 313 uncosted rules). `LUA-01` finished at 21/21 since that file was drafted; `ERR-50`/`ERR-22` is being run by a live parallel session ("Rewgel Audit") — **20 of 31 repos done as of 2026-09-19** (two rounds, adversarially verified, several follow-up crashes caught per round), remaining 11 repos (`pickers`, `recommender`, `replacer`, `reposcope`, `rules`, `runtime-analysis`, `sandbox`, `sessions`, `spotlight`, `emojis`, `ui`) still to come — check `ListAgents` before pasting either prompt.

---

## Table of content

  - [1. Method, and what this report is not](#1-method-and-what-this-report-is-not)
  - [2. The numbers](#2-the-numbers)
  - [4. Do these first — high benefit, ≤1 session](#4-do-these-first-high-benefit-1-session)
  - [5. Worth doing, but a real sitting](#5-worth-doing-but-a-real-sitting)
  - [6. Cheap, low stakes — take them when you are in the file anyway](#6-cheap-low-stakes-take-them-when-you-are-in-the-file-anyway)
  - [7. Do not do these](#7-do-not-do-these)
  - [8. What this leaves](#8-what-this-leaves)

---

## 1. Method, and what this report is not

Every roadmap was read in full. Then — and this is the part that changed the
result — **every item that would otherwise have been ranked "cheap and
valuable" was checked against the source tree in `$REPOS_DIR`** before it was
costed. That check is why §3 exists.

What was **not** done: no design work, no attempt to settle the open
*questions* (they are listed as questions, not as tasks), and no review of the
external queue that `documentation.nvim` and `runtime-analysis.nvim` both hand
to `docmap-desktop/docs/PLAN.md` — that plan lives outside this collection and
was deliberately left where it is.

Effort is in **working sessions** (one focused sitting, roughly a half day).
"Blocked" means the work is understood but cannot be finished on this machine
as it stands.

---

## 2. The numbers

Snapshot at review time (2026-09-17) — kept as written, not adjusted below,
so the method paragraph above stays checkable against what it actually
produced:

|                                                 |  Count  |
|-------------------------------------------------|---------|
|                  Roadmaps read                  | **38**  |
|      Empty by design — no open work at all      | **22**  |
|        Roadmaps carrying real open work         | **16**  |
| Items listed as open that are **already built** | **15**  |
|              Genuinely open items               | **≈48** |
|      Of those, high benefit at ≤1 session       | **11**  |

Twenty-two of thirty-eight plugins are genuinely finished: `recommender`,
`dap`, `sessions`, `cmdlog`, `diff`, `fileops`, `pickers`, `buffer-ctx`,
`language`, `emojis`, `pdfport`, `color_my_ascii`, `markdown`, `migrate`,
`insights`, `reposcope`, `sandbox`, `replacer`, `spotlight`, `github_stats`,
`runtime-analysis`, `cascade`. Several say so explicitly and give the date
they were last checked, which is what made this pass cheap for them.

**Since then, 2026-09-18:** every item this report actually ranked in
§4/§5/§6 — not the full ≈48 the table above counts, which also includes
items no lower-priority section below ever named individually — is now
done, was found already built, or was investigated and closed as a
decision. See
§8 for what is left and, more importantly, for the two much larger
fleet-wide findings (the `rules.nvim` audit, the `ui.nvim`/`my.nvim`
cross-feature check) that this report's own closing section flagged and
that have since actually run.

---

## 4. Do these first — high benefit, ≤1 session

**Status, 2026-09-19: all eleven rows are done, already-built, or the row's
own premise turned out wrong.** Verified against source, not against this
table — see each row.

| # | Plugin | Item | Effort | Why it ranks here |
|---|---|---|---|---|
| ~~1~~ | `ai.nvim` | ~~Migrate `pdfport.nvim`'s backends onto `ai.nvim`~~ — **withdrawn 2026-09-17, re-ranked as consolidation** | — | Ranked here on the entry's own security claim. That claim is stale: both defects are already fixed in `pdfport` itself. Re-ranked as consolidation, §5 — where its own status has since moved too |
| 2 | — | ~~Strike the fifteen done items from §3~~ — **done 2026-09-17**, `WKDBooks@15e77b3` | <1 | Every future reading of these files was wrong until this was done |
| ~~3~~ | `casedesk.nvim` | ~~Redaction gate in `ki.lua`~~ — **done 2026-09-18** | 0.5 | `lua/casedesk/redaction.lua` + a rewritten `ui/ki.lua`'s `M.ki`, `TESTS/redaction_spec.lua` (16 cases). The real leak path turned out to be `ocr.render`'s `{screenshots}` block, not a binary attachment — see `casedesk.nvim/FEATURES.md` |
| ~~4~~ | `filetree.nvim` | ~~Implement `get_node_at_line` for the neo-tree and nvim-tree adapters~~ — **already done by the time this row was drafted** | 1 | Built for both adapters, verified live against a real tree (19 checks). Corrects itself on the way: **four** features were unlocked, not five — `filter`'s dim fallback never reaches its gate on either adapter |
| ~~5~~ | `media.nvim` | ~~Segments → SRT/VTT serialisers~~ — **done 2026-09-17**, `media.nvim@f6a2ca8` | 0.5 | `output/srt.lua`, `output/vtt.lua`, `:Media transcribe out=srt\|vtt`. A silent fall-through was fixed on the way — any mode that wasn't `sidecar` used to open a buffer regardless of the requested format |
| ~~6~~ | `media.nvim` | ~~`lib.nvim.progress` handle during a transcription run~~ — **done 2026-09-17**, `media.nvim@feeb08a` | 0.5 | `opts.on_phase` + a `lib.nvim.progress` handle in `bindings/usrcmds.lua`. Larger find on the way: `:Media transcribe` was **not cancellable at all** — a cancel handle existed since it was written and the command dropped it |
| ~~7~~ | `casedesk.nvim` | ~~Decide what `:Case timeline` does about git-pull sessions~~ — **done 2026-09-19**, `casedesk.nvim@9ad5672` | 0.5 | Chose option 2 (detect + label), not option 3 (a duration journal) — `usage.lua` only keeps one throttled last-touched stamp, not the session/event log a forward-looking journal would need, so that would have been a new feature, not this 0.5-session fix. A bulk mtime stamp across multiple distinct files (the git-pull signature) now marks `session.artifact = true`; `:Case timeline` shows those as "not measurable (synced together, e.g. git pull)" and excludes them from the focused-time total. 3 new tests in `TESTS/timeline_spec.lua` |
| ~~8~~ | `mdview.nvim` | ~~Hand-test `any_file` in real Neovim~~ — **done, already built by the time this row was checked** | 0.5 | Verified 2026-09-18: was already tested against the roadmap's own checklist. Struck without further work |
| ~~9~~ | `media.nvim` | ~~Prefetch hint for frame stepping~~ — **done 2026-09-17**, `media.nvim@c72d8ba` | 0.25 | The ten-line estimate held — `cache.ensure` already joins an in-flight render, so `prefetch` is `frame` with nobody listening |
| ~~10~~ | `my.nvim` | ~~Breadcrumb `container` provider is a no-op~~ — **done 2026-09-17**, `my.nvim@fdeacd4` | 0.25 | Retired rather than wired: measured against a real Lua tree, the provider's own input unchanged all four times — `ts_symbol` already yields the qualified name, so it never had anything to add. Two bigger defects found underneath (a Tree-sitter node reaching no provider at all, a `memo.fn` crash on userdata keys) were fixed the same day too |
| ~~11~~ | `lib.nvim` | ~~`deps.health` migration for the two stragglers~~ — **the row's own premise was wrong** | 0.5 | `open.nvim`/`pdfport.nvim` (the row's actual targets) were already migrated — confirmed: `open.nvim/health.lua:216`, `pdfport.nvim/health.lua:435` (`pointer_for`). The real remaining stragglers are five OTHER plugins (`ai`, `debugging`, `emojis`, `fileops`, `sandbox`, confirmed still hand-rolling `vim.fn.executable` 2026-09-18) — and none of them declares an `install.json`, so `deps.health` doesn't apply to them yet. A different, larger task, not this row |


> **Correction, 2026-09-17, after the review shipped.** Row 1 above was wrong,
> and it was wrong in exactly the way §3 warns about — an item costed from its
> own description instead of from the source. Checked afterwards, while writing
> the hand-off task:
>
> - **JSON escaping** is fixed: both backends build the body with
>   `vim.json.encode` (`claude.lua:72-82`, `ollama.lua:131-137`), each with a
>   comment naming the old `gsub('"', '\\"')` and why it broke on any Windows
>   path in the prompt.
> - **The API key is out of the argv**: it goes into a `chmod`-protected curl
>   config file read with `-K` (`claude.lua:158-178`), with the threat model
>   written out in the comment.
>
> The migration is also **larger** than the entry implies. `pdfport` sends
> multimodal requests — a base64 PDF as a `document` block to Claude,
> `pdftoppm` PNGs to Ollama — and `Ai.Request` has no notion of an attachment
> (no `base64`, `image` or `document` anywhere in `ai.nvim/providers/`). So it
> needs an attachment capability in `ai.nvim` first; it is not a rewiring of
> call sites. It stays worth doing as **consolidation** — two hand-rolled
> curl/provider paths beside a plugin built for exactly that — at roughly
> 2 sessions, not 0.5.
>
> The corrected text is in `ai.nvim`'s own roadmap entry and `FEATURES.md`.
>
> **Second correction, 2026-09-18.** The precondition above no longer holds:
> `ai.nvim` HAS an attachment capability now (`base64`/`image`/`document`
> block types in `providers/{claude,ollama,openai}.lua`, `providers/transport.lua`).
> `pdfport.nvim` still carries its own `backends/{claude,gemini,ollama}.lua`
> unchanged, so the migration itself has not happened — but the thing that
> was blocking it is gone. Likely smaller than 2 sessions now; re-cost before
> starting.

---

## 5. Worth doing, but a real sitting

**Status, 2026-09-19: twelve of seventeen done outright, two superseded by a
much larger fleet-wide pass, two reclassified as decisions rather than open
work, one rejected after investigation — all seventeen rows now closed.**

| Plugin | Item | Effort | Benefit |
|---|---|---|---|
| ~~`media.nvim`~~ | ~~The hub — one dashboard across image/pdf/audio/video~~ — **done 2026-09-17**, `media.nvim@37db33b`+3 more | 3–4 | `hub/{kinds,scan,dashboard,actions}.lua`, `:Media dashboard`/`:Media text`. Found on the way: `ui.kit`'s picker is not the multi-select+preview one the roadmap described — the dashboard is a scratch float with its own keymaps instead |
| ~~`media.nvim`~~ | ~~First real whisper.cpp run~~ — **unblocked and done 2026-09-17**, `media.nvim@a2adf38` | 1 | Against a real build + `ggml-base.en.bin`. The JSON shape held; `-np` does not suppress everything, and `whisper-cli` exits 0 on some decode failures. The real find: caching a real transcription crashed — `vim.system`'s `on_exit` fast-event context, verified only once whisper.cpp stopped being a fake |
| ~~`casedesk.nvim`~~ | ~~Anonymisation before any AI hand-off~~ — **already built by the time this row was drafted** | 2 | `lua/casedesk/anonymize.lua` + `:Case anonymize`, `TESTS/anonymize_spec.lua` |
| ~~`casedesk.nvim`~~ | ~~Tests for the pure functions~~ — **already built by the time this row was drafted** | 1 | Suite went from 5 specs to 40, including the case-number guard with the real incident behind it |
| ~~`filetree.nvim`~~ | ~~`TESTS/refs/` — 52 of 54~~ — **already fixed weeks before this row was drafted (2026-08-27)** | 1–1.5 | The entry's own premise was the bug: a spec/fixture string mismatch, not the apply layer the "to_absolute" lead pointed at. `run.lua` now asserts fixtures contain what their spec expects, so the same drift names its own cause |
| ~~`lsp.nvim`~~ | ~~`:LspDoctor deep` — provoke errors~~ — **done 2026-09-17**, `lsp.nvim@60ba2c6` | 1 | `TESTS/lsp/probe_live_spec.lua` + a CI step installing a real server. Fails instead of skipping under CI — plenary's `Pending` tallies as `Success`, which would have hidden exactly the gap this check exists to catch |
| ~~`ui.nvim`~~ | ~~Run `rules.nvim` over `ui.nvim`~~ — **superseded, see below** | 1–2 | The per-plugin ask is now covered (and far exceeded) by the fleet-wide audit across all 38 repos, 2026-09-18 — see `Regel-Audit-Gesamtstatus.md` |
| ~~`media.nvim`~~ | ~~Run `rules.nvim` over `media.nvim`~~ — **superseded, see below** | 1–2 | Same fleet-wide audit covers it; its own roadmap's "after transcription and the hub settle" ordering turned out moot once the sweep ran over everything at once |
| ~~`data.nvim`~~ | ~~Phase 1 rest: `--reg=`/`--inplace`/`--split`~~ — **done, verified 2026-09-18** | 1 | All three flags typed and wired (`@types/init.lua`, `bindings/usrcmds.lua`); `scope/resolve.lua`'s own doc comment now explicitly hands the register/output half to `scope.source`/`scope.sink` |
| ~~`lib.nvim`~~ | ~~`autocmd-dispatcher` — one autocmd, many handlers~~ — **already shipped, 2026-09-19** | 1–2 | `lua/lib/nvim/bindings/autocmd/dispatcher/` implements the proposed generic factory, both recommended fixes included (sort-at-registration, per-registration id instead of `tostring(handler.load)`), honest performance framing in its own README. Migrating the nvim config's own `FileType` registry onto it (the doc's phase 2) never happened as such — the config no longer has a single bespoke dispatcher module to migrate — but `filetree.nvim` already consumes it in production, which is the actual validation phase 2 was after |
| ~~`lib.nvim`~~ | ~~Windows elevation in the dependency installer~~ — **not an open item, decided against** | 1 | Documented as a deliberate design choice (`deps/pm/init.lua`, `deps/README.md`): "no elevation logic beyond a `sudo` prefix" — Windows elevation is left to the package manager's own UAC prompt, on purpose, not unfinished |
| ~~`gopath.nvim`~~ | ~~Consolidate frecency~~ — **already correct, the entry's premise was wrong** | 1–2 | Verified: `gopath/alternate/frecency.lua:43` calls `require("lib.nvim.frecency").store` — the local file is the saturation curve on top of the shared implementation, not a second one |
| ~~`my.nvim`~~ | ~~Persisted highlight overrides~~ — **done 2026-09-18**, `my.nvim@3f8be49` | 1 | Opt-in `persist_overrides = true`; `lua/my/config/persist.lua`. A follow-up bug/security/performance re-check found and fixed a non-idempotent observer registration and N redundant disk writes on `:My hl reset` — both since fixed |
| ~~`hover.nvim`~~ | ~~The demo GIF~~ — **done, the screenkey HUD it needed shipped and the GIF followed** | 0.5–1 | Recorded once `ui.nvim`'s screenkey HUD existed |
| ~~`mdview.nvim`~~ | ~~Cooperative tab closing in `browser.mode = "default"`~~ — **investigated and rejected, 2026-09-18** | 1–2 | `window.close()` only closes a tab the script itself opened — checked against the actual mechanism, not assumed. Recorded as a decision, not left open |
| ~~`documentation.nvim`~~ | ~~A shim function that behaves differently~~ — **done 2026-09-17**, `documentation.nvim@c9e7ce2` | 1–2 | Fixed the shim so it matches the contract the static spec checks |
| ~~`ui.nvim` / `my.nvim`~~ | ~~Cross-feature check against the ~30 sibling plugins~~ — **done, in full — Tiers A–F all resolved by 2026-09-18** | 2–3 | `../personal/All/FINISH/ERLEDIGT/ui-my-Kreuzfeature-Analyse.md`. The S- and M-tier findings shipped 2026-09-17; F1 (diffopt profiles) and F2 (`gh` gitsigns peek) were decided (move to `diff.nvim`) and built 2026-09-18, `diff.nvim@03b6359`/`my.nvim@1c147de` |

**The `rules.nvim` sweep this section pointed at happened, and it is bigger
than either row above imagined.** `Regel-Audit-Gesamtstatus.md`
(2026-09-18/19) ran the full 421-rule catalogue over all 38 repos: 497
confirmed rule violations (from 541 raw findings after adversarial
verification), 52% of them error-handling (`ERR`), plus a fleet-wide
migration left half-finished (`lib.nvim.cross.fs.expand_path` replacing
`vim.fn.expand()` on 21 plugins' shell-command paths, `SEC-34`) and six
concrete defects in `rules.nvim`'s own automatic checks (producing 85%
false positives — `:Rules check` is not a usable gate until those are
fixed). **This report implements nothing** — it is the findings, not the
fix. See that document for the prioritised list; it now supersedes the two
struck `rules.nvim` rows above and is a body of work in its own right, not
a "take it when you're in the file anyway" item.

---

## 6. Cheap, low stakes — take them when you are in the file anyway

**Status, 2026-09-19: everything in this section is now closed.** Most
shipped as one bundle (`C.` in `Tasks-offene-Punkte.md`, sequential, one
repo at a time, 2026-09-18); the last remaining row (`casedesk.nvim`'s
sibling integrations) closed 2026-09-19. All of it went through the same
bug/security/performance re-check as everything else in this report.

~~`media.nvim`~~: resolution tied to the float / `levels` per material / a
larger default float for the playing view — **already done**, all three, in
`hover.nvim`/`images.nvim`, the same evening the note about them was
written; the note itself was just never struck.
~~`my.nvim`~~: `guicursor` presets (`my.nvim@c2f33ef`); `:My hl why` for
skip-rule tracing (`my.nvim@e253494`, and its own hot-path allocation fixed
in the re-check, `my.nvim@c17d9d3`) — **done**. The middle tier for
large-file behaviour — **checked 2026-09-19, already staged, no code
change needed**: `cursorline` is never size-gated at all, `cursorcolumn`
has its own `min_colored_file_kb` threshold, and `color_codes`/
`cword_occurrences` each carry a per-feature `large_file_kb` override —
`docs/PERFORMANCE.md` has documented this staged behaviour since the
plugin's extraction, before the roadmap note asking for it existed. Struck
from `my.nvim/ROADMAP.md`, recorded in `my.nvim/FEATURES.md`.
`filetree.nvim`: make the `cwd_mode` badge cheap before the statusline
framework is ever swapped — **done, 2026-09-19**, `filetree.nvim@49a0507`.
Confirmed the cost was real, not assumed: `badge_text()` does no I/O but
runs `lib.nvim`'s `gmatch`-based `path_shorten` on every pull, and
`component()`/`badge()` are exactly what lualine/heirline call on every
statusline redraw. Now memoized against `(mode, pinned root, tree-window
width)`, re-derived and compared on each call rather than relying on an
explicit invalidation call at every mutation site — so it can't drift out
of sync the way a forgotten invalidation would; the dead `CWD_MODES.md`
link — **done, 2026-09-19**, `filetree.nvim@2ad60ef` (the stack was
already documented under `CORE.md`; the reference was just a stale
filename in `WORKFLOW.md`'s intro list).
~~`lsp.nvim`~~: hover cache via `lib.lua.memo` — **already built** (record
only, nothing to build); the runtime half of the keymap collision check —
**done**, `lsp.nvim@49b4dfa`, plus a case-sensitivity gap in that same
check found and fixed in the re-check (`lsp.nvim@056639d`).
~~`data.nvim`~~: `diff.nvim` before/after for a `filter` run — **already
done by the time this row was checked**, `data.nvim@caa95af` (same day as
this report, `filter --preview` — a unified diff via `diff.nvim`'s
`require("diff").run(...)` API, Apply/Discard prompt before writing).
~~`ai.nvim`~~: a validated model registry per provider — **done 2026-09-19**,
`ai.nvim@b34f382` (`lua/ai/providers/models.lua`, wired into the existing
`:checkhealth ai`; `claude`/`gemini`/`openai` get a fixed catalogue,
`ollama`/`loomai` are marked open-ended since they run arbitrary local
models — reporting only, no request-time blocking). 16 new tests. A
same-session re-check found 2 real bugs and fixed both, `ai.nvim@319eda4`:
the default `provider = "auto"` bypassed the whole catalogue (the lookup
key was the literal string `"auto"`, absent from `M.KNOWN`, so a typo'd
`completion.model` was silently never flagged under default settings), and
`M.OPEN_ENDED` was declared but never actually consulted anywhere — see §8
~~`casedesk.nvim`~~: one routing-status field instead of filename *and*
`## Status` — **done**, `casedesk.nvim@718404f` (`routed_to` sidecar field,
`:Cases doctor` migration findings for legacy cases; a resulting data-loss
bug and a pattern-injection bug were both found and fixed in the re-check).
The eleven sibling-plugin integrations — **done, 2026-09-19**,
`casedesk.nvim@239ca13`/`d448341`/`d945e69`. Of the 8 the roadmap's own
"Sibling plugins" table left unverified beyond the 4 `around-it.md`
already documented: `language.nvim` and `markdown.nvim`/`cascade.nvim`
turned out to already work with no wiring needed (case files are plain
`.md` buffers `cascade` already treats as list-continuation-eligible);
`open.nvim` and `diff.nvim` were built now (`:Case diff stream|solution`,
7 new tests); `replacer.nvim`/`pickers.nvim`/`buffer-ctx.nvim` were left as
documented decisions rather than rushed — `replacer`'s generic find/replace
doesn't map onto `anonymize.lua`'s structural-anchor detection without an
over/under-redaction risk, `pickers` was already a deliberate deferral in
the existing code, and `buffer-ctx`'s flagged overlaps (`marks.lua`,
`:Case insert`) turned out to not actually overlap on inspection but also
have no clean integration point.

---

## 7. Do not do these

| Plugin | Item | Why not |
|---|---|---|
| `gopath.nvim` | Treesitter instead of line patterns in `symbol_locator`/`table_locator` | The roadmap costs it at **a week**, because all 8 fallback strategies in `table_locator.locate` must be preserved — and the current patterns were chosen deliberately, for tolerance of line breaks after `=`, bracket keys and tables inside calls. Fix concrete bugs as they appear instead |
| `lsp.nvim` | Shrink the signature-help module | Its own entry says "large (just observe for now)", and it has grown from ~800 to 1,322 LOC since. Nothing reports it as a problem |
| `mdview.nvim` | PDF page preview in the link hover | Costed honestly at ~1s of hover latency plus softening the `/asset` containment check. The clean road (pre-render at doc-push time) is written down; wait for a concrete case |
| `casedesk.nvim` | `area` in `.case.json` | The roadmap itself argues against it: an area is derived from where the case lies, and a stored copy that disagrees with the folder is wrong rather than helpful. Leave it as a question |
| `ui.nvim` | Own terminal implementation instead of `Snacks.terminal` | Raised in feedback, never commissioned. The actual complaint (no border) was fixed with one explicit option |
| `lib.nvim` | ui-kit migration step 4 (a `lib.nvim` shim) | Deliberately skipped — all 30/30 consumer repos went straight over. Not an open item, despite still being numbered as one |

---

## 8. What this leaves

**Rewritten 2026-09-18, closed out 2026-09-19.** Every plugin-specific item
this report originally named in §4/§5/§6 has shipped, was already done, or
was investigated and either rejected (`mdview.nvim` cooperative tab
closing) or reclassified as a decision rather than work (`lib.nvim` Windows
elevation, `gopath.nvim` frecency). That closes the entire original scope
of this review.

**2026-09-19, the six items §8 originally still listed as open all
closed:** `filetree.nvim`'s dead `CWD_MODES.md` link
(`filetree.nvim@2ad60ef`) and its `cwd_mode` badge cost
(`filetree.nvim@49a0507`, memoized against mode/root/tree-window-width);
`casedesk.nvim`'s `:Case timeline` git-pull-session decision
(`casedesk.nvim@9ad5672`, §4 row 7 — sessions built from a bulk mtime stamp
across multiple files now labeled "not measurable" instead of counted as
fake zero-duration sessions); `data.nvim`'s `diff.nvim` before/after for
`filter`, which turned out to already be done (`data.nvim@caa95af`, same
day as this report — missed on the first pass); `ai.nvim`'s model registry
(`ai.nvim@b34f382`, wired into `:checkhealth ai`); and `lib.nvim`'s
`autocmd-dispatcher`, which also turned out to already be shipped
(`lua/lib/nvim/bindings/autocmd/dispatcher/`, with `filetree.nvim` already
consuming it in production — the actual validation the roadmap doc's
"migrate the config" phase 2 was after, even though that literal migration
never happened once the config was restructured away from having a single
dispatcher module to migrate).

**2026-09-19, the last item closed too:** `casedesk.nvim`'s remaining seven
sibling integrations (§6), `casedesk.nvim@239ca13`/`d448341`/`d945e69`.
`language.nvim`/`markdown.nvim`/`cascade.nvim` needed no wiring (already
worked or applied automatically to plain `.md` case files); `open.nvim`
and `diff.nvim` (`:Case diff stream|solution`) were built; `replacer.nvim`,
`pickers.nvim`, and `buffer-ctx.nvim` were left as documented decisions
rather than rushed — see §6 for why each. **Every item this report has
ever named as open is now closed**, one way or another: shipped, found
already built, or resolved as a decision.

**The same-session bug/security/performance re-check of this round's own
fixes** (the pattern every prior bundle in this report went through) ran
over the three code-bearing commits from this round —
`casedesk.nvim@9ad5672`, `ai.nvim@b34f382`, `filetree.nvim@49a0507` —
each via an independent review agent followed by an adversarial verify
pass per finding. `casedesk.nvim` and `filetree.nvim` came back clean.
`ai.nvim` did not: **2 real correctness bugs**, both confirmed and fixed,
`ai.nvim@319eda4`. (1) `check_config()`'s `completion.model` check resolved
the provider via a raw `completion.provider or cfg.provider` fallback
instead of going through `provider_order` the way the real request path
(`ai/init.lua`'s `resolve()`) deliberately does — under the out-of-the-box
default (`provider = "auto"`), the lookup key passed to `is_known()` was
the literal string `"auto"`, which has no entry in `M.KNOWN` and is
therefore always treated as "no fixed catalogue", so a typo'd
`completion.model` under default settings was silently never flagged even
though the actually-resolved provider would reject it. Fixed by resolving
`"auto"` through `provider_order` first, mirroring `resolve()`. (2)
`M.OPEN_ENDED` was declared but never consulted anywhere, so a future
built-in provider added without a catalogue entry would fail silently
instead of the safety net it was documented to be — fixed with a
completeness test asserting every built-in provider id appears in either
`M.KNOWN` or `M.OPEN_ENDED`, matching the module's own "fails loudly in
review/tests" framing rather than changing runtime behavior. This is the
same lesson §5 already drew from the `casedesk.nvim` `ui.lua` re-check:
work that looked complete and tested still had a real gap until an
independent adversarial pass checked it against the actual code.

**The cross-cutting item this report closed out itself: the `ui.nvim`/
`my.nvim` cross-feature check ran in full**, six tiers (A–F), and found four
surfaces with no owner (`vim.wo.winbar`, `winhighlight`, the highlight-group
table after `:colorscheme`, `vim.t.bufs`) plus two features that had drifted
into the wrong plugin entirely (diffopt profiles and a gitsigns keymap,
both moved from `my.nvim` to `diff.nvim`). All resolved.

**The cross-cutting item this report flagged and got, at ten times the
scale it asked for: `rules.nvim` has now been run over all 38 plugins**,
not the one (`my.nvim`, 2026-09-15) this report knew about.
`Regel-Audit-Gesamtstatus.md` (2026-09-18/19) is the result:
**497 confirmed rule violations**
fleet-wide (52% error handling), a security-relevant migration
(`lib.nvim.cross.fs.expand_path` replacing raw `vim.fn.expand()` on shell-
command paths) started on 15 of 38 repos and not finished on the other 21,
and six defects in the automatic checks themselves that make `:Rules check`
produce 85% false positives as it stands. **This is now the largest body of
open, verified work in the whole fleet — bigger than anything this report
originally ranked** — and it implements nothing on its own; every fix is
still its own task. Read that report next, not this one, for what to do
next.

**Also worth naming: a fleet-wide bug/security/performance re-check ran
over this session's own fixes** (`Tasks-offene-Punkte.md`, §C plus the
cross-feature check's F1/F2) and found nine real, critical bugs in
`casedesk.nvim`'s `ui.lua` split alone — invisible to a fully green test
suite, because nothing had driven the interactive callbacks that broke.
Twenty-two of twenty-four findings fixed same-day; the other two documented
as a known limitation. The lesson, stated plainly: **a green test suite is
not evidence an interactive code path works** — only running it, or a test
that actually drives it, is.

---

