# Open roadmap items — cost/benefit review

**Date:** 2026-09-17
**Scope:** all 38 `ROADMAP/ROADMAP.md` files under
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`, plus the sibling
documents they hand their queue to (`ui.nvim/NOTES.md`,
`ui.nvim/PLAN-ui-kit-migration.md`, `ui.nvim/TASK-screenkey.md`,
`lib.nvim/ROADMAP/dependency-installer.md`, `filetree.nvim/ROADMAP/`).
**Goal:** one ranked view of what is actually left, what each item costs, and
what it buys.

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

| | Count |
|---|---|
| Roadmaps read | **38** |
| Empty by design — no open work at all | **22** |
| Roadmaps carrying real open work | **16** |
| Items listed as open that are **already built** | **15** |
| Genuinely open items | **≈48** |
| Of those, high benefit at ≤1 session | **11** |

Twenty-two of thirty-eight plugins are genuinely finished: `recommender`,
`dap`, `sessions`, `cmdlog`, `diff`, `fileops`, `pickers`, `buffer-ctx`,
`language`, `emojis`, `pdfport`, `color_my_ascii`, `markdown`, `migrate`,
`insights`, `reposcope`, `sandbox`, `replacer`, `spotlight`, `github_stats`,
`runtime-analysis`, `cascade`. Several say so explicitly and give the date
they were last checked, which is what made this pass cheap for them.

---

## 3. The largest finding: fifteen items are done and still listed

> **Acted on the same day** (`WKDBooks@15e77b3`). Every item in the table
> below is struck from its roadmap and recorded in a new `FEATURES.md` in
> that plugin's folder, naming the module that answers it. `lsp.nvim` §14
> carries five rows now instead of fifteen; `ui.nvim/TASK-screenkey.md` is
> deleted; `filetree.nvim`'s "Live — open work" table is gone, it had one
> row and that row was closed. The two stale-but-not-done entries at the
> end of this section are corrected in place. The table stays here as the
> evidence for §8's closing argument.

This is not a nitpick about tidiness. These entries are what a reader plans
against, and four of them are in the *cheapest* tier — exactly the ones most
likely to be picked up next, and every one of them would have been picked up
only to find the work already in the tree.

| Listed as open in | Item | Actually in the tree as |
|---|---|---|
| `lsp.nvim` §14 | Inlay-hints toggle | `lua/lsp/core/inlay_hints.lua` |
| `lsp.nvim` §14 | Code-action indicator | `lua/lsp/core/lightbulb.lua` |
| `lsp.nvim` §14 | Auto-restart with backoff | `lua/lsp/core/supervisor.lua` — and it solves the hard half (crash vs. deliberate stop, via a declared `expect_stop`) |
| `lsp.nvim` §14 | Per-project override (`.nvim-lsp.json`) | `lua/lsp/config/project.lua`, `DEFAULTS.lua:34` |
| `lsp.nvim` §14 | Profile presets (`lean`/`default`/`full`) | `DEFAULTS.lua:27` — `preset = "default"` |
| `lsp.nvim` §14 | Diagnostics debounce on `publishDiagnostics` | `core/handlers.lua` — leading-edge, `debounce_ms` |
| `lsp.nvim` §14 | Multi-root/monorepo workspace switcher | `lua/lsp/core/workspace_picker.lua` |
| `lsp.nvim` §14 | Formatter-priority audit ("unclear whether enforced") | Answered: `lspdoctor/@types.lua:13` states it is report-only and says why |
| `lsp.nvim` LSPDoctor §1 | `installed: N, attached: M` in `:checkhealth` | `health.lua:274` ff., including the heavy-server warning |
| `ui.nvim` `TASK-screenkey.md` | Screenkey HUD, whole task file with acceptance list | `lua/ui/screenkey/init.lua`, wired in `bindings/usrcmds/init.lua` |
| `my.nvim` | Highlight profiles (`:My hl profile {name}`) | `bindings/usrcmds/init.lua:327` — with the enum over profile names |
| `open.nvim` | Windows file-manager window opens without focus | `lib.nvim/cross/reveal_in_fm/win_reveal.ps1` — the `SetForegroundWindow` route this entry proposed as the first candidate |
| `ai.nvim` | Phase-8 wiring, `<leader>a*` collision to decide | Wired in `lua/plugins/personal/init.lua:1232` ff.; the colliding `lua/config/ai/` no longer exists |
| `ai.nvim` | `loomai` provider, "once loomAI has an endpoint" | `ai.nvim/lua/ai/providers/loomai.lua`, 159 lines, real `available()` |
| `filetree.nvim` | `ROADMAP/CWD_MODES.md`, "still open: its Open section" | The file moved to `FINISHED/CWD_MODES.md`; the roadmap's link is dead |

Two more entries are stale rather than done: `lsp.nvim` costs the signature
module at "~800 LOC", it is **1,322** today; and `mdview.nvim` still calls the
flag `experimental.any_file`, which moved to the top level on 2026-08-30.

**Cost to fix all of this: well under one session** — confirmed, it took
about that — and it was the single highest-leverage item in this report. `lsp.nvim`'s §14 table is the worst
offender — eight of its fifteen rows are stale — and it is 1,368 lines, the
longest roadmap in the collection.

---

## 4. Do these first — high benefit, ≤1 session

| # | Plugin | Item | Effort | Why it ranks here |
|---|---|---|---|---|
| ~~1~~ | `ai.nvim` | ~~Migrate `pdfport.nvim`'s backends onto `ai.nvim`~~ — **withdrawn 2026-09-17, see below** | — | Ranked here on the entry's own security claim. That claim is stale: both defects are already fixed in `pdfport` itself. Re-ranked as consolidation, §5 |
| 2 | — | ~~Strike the fifteen done items from §3~~ — **done 2026-09-17**, `WKDBooks@15e77b3` | <1 | Every future reading of these files was wrong until this was done |
| 3 | `casedesk.nvim` | Redaction gate in `ki.lua` — refuse to attach a file without a redacted counterpart | 0.5 | Customer screenshots and logs reaching an AI unredacted. `:Image redact` already does the work; what is missing is the *refusal*. Verified: no `redact` reference in `ki.lua` today |
| 4 | `filetree.nvim` | Implement `get_node_at_line` for the neo-tree and nvim-tree adapters | 1 | Unlocks **five** silently-disabled features at once: `git_status`, `lsp_diagnostics`, `size_info`, `copy_move`'s clipboard marker, `filter`'s dim fallback. Both adapters already carry the other line-mapping methods. Verified: `@types/adapter.lua:60` still says "Implemented by no backend yet" |
| 5 | `media.nvim` | Segments → SRT/VTT serialisers (transcription phase 1) | 0.5 | The data model (`Media.Segment`/`Media.Transcript`) is built and every engine already has to produce it. Only the serialisers are missing — verified: `lua/media/output/` holds `init.lua` and `sidecar.lua`, nothing else |
| 6 | `media.nvim` | `lib.nvim.progress` handle during a transcription run | 0.5 | The roadmap calls this non-negotiable in its own design section and then shipped without it. An hour of audio is minutes of work behind a single "transcribing…" |
| 7 | `casedesk.nvim` | Decide what `:Case timeline` does about git-pull sessions | 0.5 | **It currently reports wrong numbers**, measured, not suspected: every "session" is a `git pull` collapsing to zero duration. Three options are already weighed in the entry; the cheapest (label a one-second session "not measurable") is an afternoon. `detect.last_touched` rests on the same mtimes |
| 8 | `mdview.nvim` | Hand-test `any_file` in real Neovim | 0.5 | Shipped 2026-08-24, tested through the Lua harness, vitest and a browser check — but never through real Neovim. The test list is already written out in the roadmap |
| 9 | `media.nvim` | Prefetch hint for frame stepping | 0.25 | "Roughly ten lines", and the playback path already does exactly this one level up |
| 10 | `my.nvim` | Breadcrumb `container` provider is a no-op | 0.25 | A real defect, not a feature: nothing sets `cfg._base_symbol`, so `container.extract()` never fires outside a debug path. Either wire a source or drop it from `providers_order` |
| 11 | `lib.nvim` | `deps.health` migration for the two stragglers | 0.5 | Only `open.nvim` and `pdfport.nvim` still hand-roll their executable checks — verified by grep across the fleet. Smaller than the entry implies |


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

---

## 5. Worth doing, but a real sitting

| Plugin | Item | Effort | Benefit |
|---|---|---|---|
| `media.nvim` | The hub — one dashboard across image/pdf/audio/video (`:Media`, `:Media text`) | 3–4 | High. Fully specified down to the module layout, the row format and the scope vocabulary; this is the plugin's reason for its name. Nothing blocks it |
| `media.nvim` | First real whisper.cpp run: verify the JSON shape and `-np` | 1 | High, **blocked** — needs a binary and a GGML model on the machine. The parser was written from whisper.cpp's source, not from observed output, and only `result.code ~= 0` is read for errors |
| `casedesk.nvim` | Anonymisation before any AI hand-off (via `replacer.nvim`) | 2 | High. Customer names and contacts in prompts. The values are already structured in `.case.json`; the live preview is the safety step |
| `casedesk.nvim` | Tests for the pure functions (case-number normalisation first) | 1 | High. There is a real incident behind that guard — an empty case number once wrote a blueprint into the parent folder of every case. Fixtures must be anonymised |
| `filetree.nvim` | `TESTS/refs/` — 52 of 54, one file skipped on rename | 1–1.5 | High (data correctness). The lead is already narrowed to the apply layer, with a concrete suspect: `to_absolute` returns a path with a literal `\.\` segment and mixed separators |
| `lsp.nvim` | `:LspDoctor deep` — provoke errors in a scratch buffer, check diagnostics arrive | 1 | High. The only check that verifies the chain end to end rather than querying states; separates "no errors" from "diagnostics never arrive" |
| `ui.nvim` | Run `rules.nvim` over `ui.nvim` | 1–2 | Medium-high, with evidence: the same pass over `my.nvim` on 2026-09-15 found a shell-injection-shaped clipboard call, missing `pcall`s around external processes, a `PERF` finding on a hot path and about a dozen more. `my.nvim` was the more-exercised of the two |
| `media.nvim` | Run `rules.nvim` over `media.nvim` | 1–2 | Medium. Its own roadmap puts this last, after transcription and the hub settle — that ordering is right, keep it |
| `data.nvim` | Phase 1 rest: `--reg=`/`--inplace`/`--split` target flags | 1 | Medium. `filter` landed; this is the remaining half. Verified still open (`scope/resolve.lua:12`) |
| `lib.nvim` | `autocmd-dispatcher` — one autocmd, many handlers | 1–2 | Medium. Already verified against 17 real `FileType` registrations across the fleet, with two fixes found in the prototype. The recommendation is to ship it |
| `lib.nvim` | Windows elevation in the dependency installer | 1 | Medium. Thought through, never run on a machine that actually demands elevation |
| `gopath.nvim` | Consolidate frecency | 1–2 | Medium. There are now **three** implementations: `pickers.nvim/smart`, `lib.nvim/frecency`, and `gopath/alternate/frecency.lua` — which was built locally despite the entry saying it belonged in `lib.nvim` |
| `my.nvim` | Persisted highlight overrides under `stdpath("data")` | 1 | Medium. `modified(ns)` is exactly the key set such a file needs, so the expensive half already exists |
| `hover.nvim` | The demo GIF (`REL-09`) | 0.5–1 | Medium. The last 🟢 open in the release gate — **and `ui.nvim`'s screenkey HUD now exists** (§3), which is the tool this recording wants |
| `mdview.nvim` | Cooperative tab closing in `browser.mode = "default"` | 1–2 | Medium. Makes `browser_autoclose` and `stop_on_browser_exit` stop being silent no-ops there |
| `documentation.nvim` | A shim function that exists and behaves differently | 1–2 | Medium. The static contract spec cannot see it; the honest gate message is already in |
| `ui.nvim` / `my.nvim` | Cross-feature check against the ~30 sibling plugins | 2–3 | Medium. Requested in both roadmaps, explicitly as **one** written pass for both, not two spot-checks |

---

## 6. Cheap, low stakes — take them when you are in the file anyway

`media.nvim`: resolution tied to the float rather than a fixed pixel width;
`levels` per material; a larger default float for the playing view.
`my.nvim`: `guicursor` presets; `:My hl why` for skip-rule tracing; a middle
tier for large-file behaviour instead of the binary switch.
`filetree.nvim`: make the `cwd_mode` badge cheap before the statusline
framework is ever swapped; fix the dead `CWD_MODES.md` link.
`lsp.nvim`: hover cache via `lib.lua.memo`; the runtime half of the keymap
collision check (build-time half is done in `keymaps_spec.lua`).
`data.nvim`: `diff.nvim` before/after for a `filter` run — now possible,
since `filter` shipped.
`ai.nvim`: a validated model registry per provider.
`casedesk.nvim`: one routing-status field instead of filename *and* `## Status`;
the eleven sibling-plugin integrations, each small and each soft-dependency only.

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

Three plugins carry nearly all of the remaining work: **`media.nvim`**
(transcription phase 1 plus the hub — the largest single block in the
collection), **`casedesk.nvim`** (privacy and one feature reporting measurably
wrong numbers), and **`filetree.nvim`** (five features disabled behind one
unimplemented adapter method, plus a rename bug with a narrowed lead).

`lsp.nvim` looks like the fourth only because its roadmap is stale; after §3
it has four genuinely open items, all of them small or explicitly parked.

The cross-cutting item worth naming separately: **`rules.nvim` has been run
over exactly one plugin** (`my.nvim`, 2026-09-15) out of a fleet of 38, and
that single pass turned up a shell-injection-shaped call, missing `pcall`s
around external processes, and a hot-path performance defect. `ui.nvim` and
`media.nvim` both list the pass as their own last item. On that evidence the
question is less whether to run it and more whether the fleet-wide sweep
should be planned as its own campaign rather than as a footnote in each
roadmap.
