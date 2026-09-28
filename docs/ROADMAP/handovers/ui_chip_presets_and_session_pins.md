# UI chip/style preset unification + session-persisted tab pins — handover

Status: **P0-P3 built and pushed (2026-09-28). Next: P4 (pin persistence,
ui.nvim + sessions.nvim), then P5 (verify-only).** Designed 2026-09-28.

**Keep this file current:** update it whenever a step is finished or
something worth knowing turns up (status line above, the step's *As built*
block, *Open questions*, *Practical notes*).

**Prerequisite already shipped:** `sessions.nvim`'s corner chip used to mount
permanently top-right. It now defaults to bottom-left and auto-hides after
`chip.timeout_ms` (3000ms) on startup/save/load, with `timeout_ms = false`
for the old always-on behavior — `sessions.nvim` `6bda06f..c5a59ce`
(`fix(chip): default to a brief bottom-left flash, not a permanent top-right
indicator`). That work exposed that "chip shape" naming is inconsistent and
duplicated across the whole plugin family, which is what this file plans.

## Table of contents

  - [Read this first](#read-this-first)
  - [Inventory as found (2026-09-28)](#inventory-as-found-2026-09-28)
  - [P0 — naming module + ui.nvim adoption](#p0--naming-module--uinvim-adoption)
  - [P1 — lib.nvim frozen-copy sync](#p1--libnvim-frozen-copy-sync)
  - [P2 — sessions.nvim adoption](#p2--sessionsnvim-adoption)
  - [P3 — casedesk.nvim adoption](#p3--casedesknvim-adoption)
  - [P4 — pin persistence feature (ui.nvim + sessions.nvim)](#p4--pin-persistence-feature-uinvim--sessionsnvim)
  - [P5 — statusline plugin-count: verify only](#p5--statusline-plugin-count-verify-only)
  - [Verification, end to end](#verification-end-to-end)
  - [Open questions / assumptions made](#open-questions--assumptions-made)
  - [Practical notes](#practical-notes)
  - [Where things are](#where-things-are)

---

## Read this first

**What is being built.** Four pieces of work that surfaced together in one
conversation about the sessions.nvim chip, bundled here because they touch
the same files:

1. **Naming unification.** Every place across `ui.nvim` (and its frozen copy
   in `lib.nvim`) that offers a "box/chip shape" choice currently uses its
   own ad-hoc vocabulary. Replace all of them with three canonical presets:
   - **`classic`** — no box, plain colored text (currently called `"text"`
     in `ui.kit.chip`, not offered at all in `ui.context`).
   - **`chip`** — flat, square-cornered block (currently `"rect"` in
     `ui.kit.chip`/`sessions.nvim`/`ui.context`, `"square"` in
     `ui.tabline.styles`, `"block"` in the statusline separators).
   - **`rounded_chip`** — bordered capsule (currently `"rounded"`
     everywhere — the one name that was already consistent).
2. **Shared vocabulary module**, so the next consumer imports the preset
   list/aliasing instead of re-typing the same three strings a fifth time.
3. **New feature:** `sessions.nvim` persists `ui.nvim`'s tabline
   pinned-buffer state across a session save/load — currently pins do not
   survive a restart at all.
4. **Verification only:** confirm `ui.nvim`'s lazy.nvim plugin-count
   statusline module stays opt-in and is not shipped in any default preset,
   so other `ui.nvim` users never see it unasked.

**Decisions that are not reopened** (assumptions made while scoping this;
see [Open questions](#open-questions--assumptions-made) if you disagree):

1. `ui.tabline.styles`' `"divider"` (a plain separator, not a box shape) and
   the statusline's `"arrow"` separator stay as extra, non-standard options
   alongside the three canonical presets — they don't map cleanly onto
   "classic/chip/rounded_chip" and forcing them to would lose a distinct
   look each currently has.
2. Old string values (`"rounded"`, `"rect"`, `"text"`, `"square"`,
   `"block"`, `"default"`, `"round"`) stay valid forever through an alias
   layer in the new preset module — no hard break for existing configs
   (this user's own or anyone else's, since `ui.nvim`/`sessions.nvim` are
   public repos).
3. Pin persistence is its own opt-out flag in `sessions.nvim`
   (`restore_pinned_buffers`), not folded into the existing
   `restore_buffer_order` — they're related but independently toggleable.
4. The rendering internals of `ui.context` (sticky breadcrumb) and
   `ui.tabline` (tab chips) are **not** unified with `ui.kit.chip`'s
   implementation — they're structurally different (a row of chips in a
   bar vs. one floating corner box). Only the *naming* is shared.

## Inventory as found (2026-09-28)

Four independent shape vocabularies exist in `ui.nvim` alone, none sharing
code:

| Location | Option | Values | Default |
|---|---|---|---|
| [`ui/kit/chip.lua:495`](E:\repos\ui.nvim\lua\ui\kit\chip.lua) (the actual reusable primitive) | `shape` | `rounded`\|`rect`\|`text` | `rounded` |
| [`ui/context/init.lua:250`](E:\repos\ui.nvim\lua\ui\context\init.lua) (sticky-scope breadcrumb) | `chips.shape` | `rounded`\|`rect` (no `text`) | `rounded` |
| [`ui/tabline/styles.lua`](E:\repos\ui.nvim\lua\ui\tabline\styles.lua) (tab-chip boundaries, open registry via `M.register`/`M.resolve`) | style name | `square`\|`divider`\|`rounded` | `rounded` |
| [`ui/statusline/utils/primitives.lua:191-196`](E:\repos\ui.nvim\lua\ui\statusline\utils\primitives.lua) (statusline module separators) | `separator_style` | `default`\|`round`\|`block`\|`arrow` | varies per variant, read in [`ui/statusline/themes/default.lua:29-33`](E:\repos\ui.nvim\lua\ui\statusline\themes\default.lua) |

`ui.kit.chip.lua` and its dependency `ui/kit/surface.lua` are the only ones
frozen-copied into `lib.nvim` (`lib/nvim/ui/kit/chip.lua`,
`lib/nvim/ui/kit/surface.lua` — see the existing
`ui-kit-lib-nvim-drift-guard` memory and `kit_drift_spec.lua`). `surface.lua`
itself wraps `lib.nvim.window.make_scratch`/`set_title`
([doc lines 1-4](E:\repos\ui.nvim\lua\ui\kit\surface.lua)) and is not shape-aware;
`chip.lua`'s `preset_for_shape()` ([lines 227-232](E:\repos\ui.nvim\lua\ui\kit\chip.lua))
turns a shape into a `theme` name (`"rounded"`/`"minimal"`) that `surface.open()`
receives ([line 284](E:\repos\ui.nvim\lua\ui\kit\chip.lua)); `is_transparent_shape()`
([lines 234-239](E:\repos\ui.nvim\lua\ui\kit\chip.lua)) special-cases `"text"` as
having no background at all, ignoring any configured `color.bg`.

**Two third-party consumers of `ui.kit.chip`, already diverging on purpose:**

- `sessions.nvim` — [`chip.lua:108`](E:\repos\sessions.nvim\lua\sessions\chip.lua)
  forwards `cfg.chip.shape` straight through; default `"rounded"`
  ([`config/DEFAULTS.lua:124`](E:\repos\sessions.nvim\lua\sessions\config\DEFAULTS.lua)),
  anchor default `"bottom-left"` ([line 123](E:\repos\sessions.nvim\lua\sessions\config\DEFAULTS.lua)).
- `casedesk.nvim` — [`pin.lua`](E:\repos\casedesk.nvim\lua\casedesk\pin.lua)
  default `"rect"` (doc: *"the default, 'not rounded' as requested"*,
  doc lines 349-356), anchor default `"bottom-right"` — deliberately the
  opposite corner from `sessions.nvim` so the two chips never collide when
  both plugins are active at once (doc lines 341-347).
- `ai.nvim`'s [`ui/badge.lua`](E:\repos\ai.nvim\lua\ai\ui\badge.lua) is a
  different primitive (`kit.popup({type="note", timeout=...})`, a one-shot
  auto-dismissing toast, not `ui.kit.chip`) — out of scope for the preset
  rename, no shape option to rename.
- No other repo under `E:\repos\*.nvim` (36 repos total) uses
  `ui.kit.chip`/`require("ui.kit")` for a corner indicator beyond the four
  named above.

**Tabline pin state** — [`ui/bindings/keymaps/tabufline/state.lua`](E:\repos\ui.nvim\lua\ui\bindings\keymaps\tabufline\state.lua):

- Identity is by **bufnr**, stored in `vim.t.ui_pinned` — a tab-local **list**
  of bufnrs, deliberately not a `{[bufnr]=true}` dict (doc lines 69-78
  explain why: `vim.t` round-trips a sparse dict as a List padded with
  `vim.NIL`, which is truthy in Lua — a real bug this file's comment
  documents having hit).
- Public-ish accessors: `M.is_pinned(bufnr)` (lines 81-83),
  `M.pinned_bufs()` (lines 94-96, current tab only),
  `M.set_pinned(bufnr, pinned)` (lines 108-132, also re-sorts `vim.t.bufs`
  so pins sit first via `M.move_buf_to`, line 130),
  `M.toggle_pinned(bufnr)` (lines 137-139).
- Cleared on `BufDelete` (lines 214-224) and when a buffer moves to another
  tab via `M.forget_buffer` (lines 501-510).
- **Persistence: explicitly none** (doc line 78: *"not persisted across a
  restart"*). UI entry points: the tab context menu's Pin/Unpin toggle
  ([`ui/tabline/menu.lua:209-218`](E:\repos\ui.nvim\lua\ui\tabline\menu.lua)),
  clicking a pinned chip's own pin-glyph to unpin
  ([`ui/tabline/utils.lua:248-259`](E:\repos\ui.nvim\lua\ui\tabline\utils.lua)),
  render in `style_buf()` (lines 573-582, swaps the close button for a pin
  glyph), close-guard for pinned chips (lines 240-246).

**`sessions.nvim`'s existing sidecar pattern** (`restore_buffer_order`), the
template the pin feature should follow — [`sessions/buforder.lua`](E:\repos\sessions.nvim\lua\sessions\buforder.lua):

- Sidecar path `<session-dir>/.<session-basename>.bufs.json`
  ([`sidecar_path()`, lines 36-40](E:\repos\sessions.nvim\lua\sessions\buforder.lua)).
- Stores `{ tabs = { [tabpage-index] = { ordered absolute buffer paths } } }`,
  captured from `vim.t[tab].bufs` (`tab_buf_names()`, lines 47-66).
- `M.save()` (lines 73-94) / `M.restore()` (lines 104-155) via
  `lib.nvim.fs.json`; deletes the sidecar file entirely when no tabpage has
  an ordered buffer list (a no-op setup costs nothing).
- Wired into [`sessions/core.lua`](E:\repos\sessions.nvim\lua\sessions\core.lua):
  `M.save()` → `buforder.save()` (line 458, gated by `cfg.restore_buffer_order`
  at line 457); `M.load()` → `buforder.restore()` (line 561, gated line 560,
  run **after** `wipe_stale()` at lines 550-554 so a restore never tries to
  reorder an already-gone buffer); `M.delete()`/`M.rename()` move or drop the
  sidecar alongside the session file (core.lua lines 673, 701).
- `vim.t.ui_pinned` is currently read/written by **no** file in
  `sessions.nvim` — confirmed via grep.

**Statusline plugin-count module** — [`ui/statusline/modules/plugin_summary/init.lua`](E:\repos\ui.nvim\lua\ui\statusline\modules\plugin_summary\init.lua):

- `compute_text()` (lines 25-30) splits `require("lazy").stats().count` into
  own/external based on this host's own `plugins.personal.list` module
  (line 26, soft-required, falls back to `own = 0`) — written specifically
  for this host's convention, not a generic lazy.nvim wrapper.
- Catalog entry [`ui/statusline/catalog.lua:86-92`](E:\repos\ui.nvim\lua\ui\statusline\catalog.lua):
  `builtin = false`, **`used_by = {}`** — in no shipped preset's default
  `order`, unlike its sibling `plugin_progress` (catalog lines 79-85,
  `used_by = {"default"}`, a different, transient "lazy.nvim busy" module
  that *does* ship by default — don't conflate the two).
- Only wired in via this user's own
  [`config/ui_statusline/init.lua:134`](C:\Users\bartl\AppData\Local\nvim\lua\config\ui_statusline\init.lua)
  (`register("personal", ...)`); the actual `order` list referencing it
  lives in `config/ui_statusline/variant.lua` (not yet opened — open it if
  P5 needs to double check the exact wiring).
- **Conclusion: already correct.** No fresh `ui.nvim` install shows this
  module. P5 below is verification/documentation only.

## P0 — naming module + ui.nvim adoption — DONE (2026-09-28, `ui.nvim` `ae8119f`)

~1 session. Repo: `ui.nvim`.

**As built.** Matches the plan below with one deliberate deviation: no
`"classic"` entry was added to the statusline separators
(`ui/statusline/utils/primitives.lua`). `primitives_separators_spec.lua` has
an explicit regression test (`"every named style has a non-empty left and
right glyph"`) guarding against the exact historical bug an empty
`"classic"` separator would reproduce — a statusline module boundary always
needs *some* connecting glyph, unlike a standalone corner chip's box. Only
`chip`/`rounded_chip` were added there, as aliases of `block`/`round`. Every
other point below shipped as planned, verified with the full spec suite
(`ui_kit_chip_spec.lua` 27/27, `context_spec.lua` 117/117,
`tabline_styles_spec.lua` 14/14, `primitives_separators_spec.lua` 6/6, all
green including live deprecation warnings firing for the old names) plus
`stylua`/`luacheck` clean.

1. New `ui/kit/presets.lua`: exports the canonical list
   `{ "classic", "chip", "rounded_chip" }` plus `M.normalize(value)` that
   maps old names (`"text"→"classic"`, `"rect"→"chip"`, `"rounded"→"rounded_chip"`)
   to the new ones, warning once per session on a deprecated value via
   `vim.notify_once` (or whatever this codebase's convention is — check
   `lib.nvim`'s deprecation helpers first, there may already be one).
2. `ui/kit/chip.lua`: route `opts.shape` through `presets.normalize()`;
   `preset_for_shape()`/`is_transparent_shape()` switch on the new names;
   default stays `rounded_chip`.
3. `ui/context/init.lua`: extend `cfg.chips.shape` to all three presets
   (add `classic`, currently missing entirely), normalize through the same
   module; default stays `rounded_chip`.
4. `ui/tabline/styles.lua`: rename the registered `"square"` style to
   `"chip"`, keep `"rounded"` registered as `rounded_chip` (register the new
   name, keep the old as an alias pointing at the same function); `"divider"`
   stays as-is (assumption #1 above).
5. `ui/statusline/utils/primitives.lua`: add `chip`/`rounded_chip`/`classic`
   keys to `M.separators` alongside the existing `default`/`round`/`block`
   (kept as aliases); `arrow` stays as-is.
6. Update/add tests per module; update any docs (`ui/kit/README.md` already
   documents chip's shape option — update it).

## P1 — lib.nvim frozen-copy sync — DONE (2026-09-28, `lib.nvim` `3ce0926`)

~0.5 session. Repo: `lib.nvim`.

**As built.** `kit_drift_spec.lua` compares ui.nvim's source against
lib.nvim's copy after whitespace-flattening, but the `---` comment marker
itself is NOT whitespace — a doc comment that re-wraps differently between
the two files (which the `ui.kit`→`lib.nvim.ui.kit` rename's extra length
naturally causes) reads as real drift even when semantically identical.
Fixed by isolating the renamed token onto its own comment line in both
files' new doc blocks, so surrounding line breaks never depend on the
token's length. `kit_drift_spec.lua` (4/4) and lib.nvim's full suite both
green (one unrelated pre-existing failure, `git_sync_spec.lua`, an
async-timing test untouched by this work).

- Port P0 steps 1-2 into `lib/nvim/ui/kit/presets.lua` (new) and
  `lib/nvim/ui/kit/chip.lua` (frozen copy of ui.nvim's, per the existing
  drift-guard convention).
- Run `kit_drift_spec.lua` (or extend it to also diff the new `presets.lua`)
  to confirm the two copies stay identical.

## P2 — sessions.nvim adoption — DONE (2026-09-28, `sessions.nvim` `4cad07f`)

~0.5 session. Repo: `sessions.nvim`.

**As built.** No behavior-changing code needed in `chip.lua` itself: it
already just forwards `cfg.chip.shape` verbatim to `ui.kit.chip.mount()`,
which normalizes old/new names on its own. Only `config/DEFAULTS.lua`'s
default value, the `Sessions.Chip.Shape` alias (new, in `@types/init.lua`,
listing all six accepted names for completion) and docs changed. Full suite
green (`SESSIONS_TESTS_OK`), including `chip_spec.lua`'s default-value
assertion updated to `"rounded_chip"`.

- `config/DEFAULTS.lua`: `shape = "rounded_chip"` (was `"rounded"`), update
  the inline comment.
- `@types/init.lua`, `config/init.lua`'s `KNOWN.chip` table: extend the
  `shape` type/validation comment to mention all three canonical names (the
  `KNOWN` entry itself is just `true`, no change needed there — only docs
  and the `@alias`/`@field` comment).
- Old values (`"rounded"`/`"rect"`/`"text"`) keep working via `ui.kit`'s
  `presets.normalize()` (soft-required the same way `chip.lua` already
  soft-requires `ui.kit` — no new hard dependency).
- Update `docs/statusline.md`/`docs/configuration.md` (already touched by
  the previous chip fix — extend rather than re-litigate).
- Extend `TESTS/chip_spec.lua`'s forwarding test to also assert the new
  default name.

## P3 — casedesk.nvim adoption — DONE (2026-09-28, `casedesk.nvim` `a8f257d`)

~0.5 session. Repo: `casedesk.nvim`.

**As built.** Unlike sessions.nvim, casedesk.nvim has its own closed-enum
validation for `pin.shape` (`config/init.lua`'s `PIN_ENUM_VALUES.shape`) —
extended to accept all six names (three canonical + three old), not just
normalized downstream. Default changed `"rect"` → `"chip"`. Caught a real
test bug while updating `TESTS/pin_spec.lua`: its `install_pin_config()`
helper fakes `casedesk.config` entirely with its own hardcoded
`opts.shape or "rect"` fallback, independent of the real `DEFAULTS.lua` —
updating only the assertion (to `"chip"`) without also updating that
fallback would have left the test silently checking the OLD default forever
(the stub would keep emitting `"rect"` regardless of what the real config
now defaults to). Both the fallback and the assertion were updated. Full
suite green: `pin_spec.lua` 11/11, `config_spec.lua` 60/60.

- `pin.lua`: rename its default from `"rect"` to `"chip"` — same visual
  result, new name only. Keep the anchor-collision-avoidance comment
  (still accurate: `sessions.nvim` defaults `rounded_chip`/bottom-left,
  `casedesk.nvim` defaults `chip`/bottom-right).

## P4 — pin persistence feature (ui.nvim + sessions.nvim)

~1 session. Repos: `ui.nvim` then `sessions.nvim` (in that order — the new
API has to exist before sessions.nvim can call it).

1. **ui.nvim**, `ui/bindings/keymaps/tabufline/state.lua`: add two small,
   explicitly tab-parametrized functions —
   `M.pinned_bufs_for_tab(tab)` (read) and
   `M.set_pinned_list_for_tab(tab, bufnrs)` (write, replaces the whole list)
   — thin wrappers around the existing tab-implicit `vim.t` access. This
   gives `sessions.nvim` (or anyone) a documented, stable contract instead
   of reaching into `vim.t.ui_pinned` directly, so ui.nvim can change its
   internal representation later without silently breaking sessions.nvim.
2. **sessions.nvim**, new `lua/sessions/pins.lua`, built 1:1 on
   `buforder.lua`'s shape: sidecar `.{name}.pins.json`, `{ tabs = { [idx] =
   { paths... } } }`, bufnr↔path resolution the same way `buforder.lua`
   does, soft-dependent on `ui.tabline.keymaps.state` (no-op without
   ui.nvim installed, matching the chip feature's own soft dependency).
3. New config `restore_pinned_buffers` (default `true`), hooked into
   `sessions/core.lua`'s `save`/`load`/`delete`/`rename` right next to the
   existing `buforder` calls (same gating pattern, same ordering — restore
   pins *after* `wipe_stale()` and *after* `buforder.restore()`, since pin
   restore needs the final, stable bufnr↔path mapping).
4. New `TESTS/pins_spec.lua`, modeled on `buforder`'s own test file.
5. Docs: `docs/configuration.md` gets the new option; consider a short
   `docs/pins.md` or a section in `docs/statusline.md`'s sibling doc if one
   exists for buforder.

## P5 — statusline plugin-count: verify only

~0.25 session, likely doc-only. Repo: `ui.nvim`.

- Already correct (see inventory above). Optionally add a one-line comment
  in `ui/statusline/catalog.lua` next to `plugin_summary`'s entry noting it
  is intentionally host-specific (depends on a `plugins.personal.list`
  convention this user's config provides) and will never be `used_by`'d in
  a shipped preset. No functional change expected — if this step turns up
  something surprising, update this section before moving on.

## Verification, end to end

- Each repo's own test suite stays green after its phase (`stylua --check`,
  `luacheck`, headless test runner — see the sessions.nvim chip fix earlier
  in this conversation for the exact commands, they're the same pattern for
  every one of these repos).
- After P0-P3: open Neovim with both `sessions.nvim` and `casedesk.nvim`
  active, trigger a save/load and a case switch, confirm both chips render
  with their expected shape/corner and don't collide.
- After P4: pin a couple of buffers across two tabs, `:Session save`,
  restart Neovim, `:Session load`, confirm the same buffers are pinned in
  the same tabs.

## Open questions / assumptions made

Flagged already in "Decisions that are not reopened" above — repeated here
as the things most likely to need a second look before/while implementing:

1. Should `"divider"`/`"arrow"` eventually also get canonical-ish names, or
   do they stay permanently as each system's own extra option? Current plan:
   permanently extra.
2. Deprecation warning mechanism for old shape names — check whether
   `lib.nvim` already has a shared "warn once per deprecated option" helper
   before writing a new one in `ui/kit/presets.lua`.
3. Exact new-function names in `tabufline/state.lua`
   (`pinned_bufs_for_tab`/`set_pinned_list_for_tab`) are a first guess —
   check the file's existing naming conventions before adding them.

## Practical notes

- Workflow rule for this project: max **one** repo touched per work session/
  agent; go phase by phase in the order above (P0 → P1 → P2/P3 in either
  order → P4 → P5), commit + push to `main` after each phase, tests green
  before moving on.
- `ui.nvim`'s `ui/kit/*` is manually frozen-copied into `lib.nvim`'s
  `lib/nvim/ui/kit/*` — any change to `ui/kit/chip.lua` or the new
  `presets.lua` must be ported by hand, then checked with
  `kit_drift_spec.lua` (see the existing `ui-kit-lib-nvim-drift-guard`
  memory for why this is manual rather than a real shared package).
- Commit messages: English body, no Claude co-authorship line (per this
  user's global `CLAUDE.md`).

## Where things are

- `ui.nvim` — `E:\repos\ui.nvim`
- `lib.nvim` — `E:\repos\lib.nvim`
- `sessions.nvim` — `E:\repos\sessions.nvim`
- `casedesk.nvim` — `E:\repos\casedesk.nvim`
- `ai.nvim` — `E:\repos\ai.nvim` (referenced only to rule it out of scope)
- This nvim config — `C:\Users\bartl\AppData\Local\nvim`
  (statusline wiring: `lua/config/ui_statusline/init.lua`,
  `lua/config/ui_statusline/variant.lua`)
