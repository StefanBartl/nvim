# Testing documentation.nvim

How to manually test every implemented feature of `documentation.nvim`.
One-time setup, then one section per feature: prerequisites, steps, what to
expect.

Repo: `E:\repos\documentation.nvim`. Spec: `plugins/personal/init.lua`
(`cmd = { "DocMap", "DocBrowse" }`, no `root` — commands map the **current
working directory**, so which repo you `cd`/open Neovim from *is* the test
target).

## Setup

Already wired into this config — nothing extra to install.

```vim
:checkhealth documentation
```

**Expect**: dependencies OK, treesitter Lua parser OK, and a section
showing the resolved root/source for whatever directory you ran it from
(useful for confirming "which repo will `:DocMap` actually map" before
running it for real).

A good, harmless test target: **documentation.nvim's own repo**
(`E:\repos\documentation.nvim`) or `E:\repos\lib.nvim` — both are real,
sizeable, annotated Lua trees you already have. Open Neovim from inside
one of them for everything below unless noted otherwise.

---

## 1. `:DocMap` — generate

**Steps**

```vim
:DocMap
```

**Expect**: prints what it wrote (`docs/map/index.html`,
`overview.md`, `module_map.json`), node counts, test/doc coverage
percentages, then any drift findings. Check `docs/map/` in that repo now
has fresh timestamps.

**Also check** `:DocMap check` on the *same*, freshly-generated tree —
should report **no staleness** (byte-identical) and write nothing. Edit
one file's `---@module` comment, save, run `:DocMap check` again — now it
should report staleness (findings go to the **quickfix list**, `:copen` to
see them).

---

## 2. `:DocMap full` — LuaLS enrichment

**Steps**

```vim
:DocMap full
```

**Expect**: takes noticeably longer (several real seconds — LuaLS runs
over the whole tree). Open `:DocMap open` afterward and check the
Hierarchy tab's **Types** view now shows real `@class`/`@alias` detail
instead of the "needs `:DocMap full`" placeholder.

---

## 3. `:DocMap open` and the HTML page's tabs

**Steps**

```vim
:DocMap open
```

**Expect**: opens in your system browser. Click through all six tabs:
**Tree**, **Hierarchy**, **Notes**, **Index**, **History** (needs `:DocMap
serve` running — see §9 — otherwise it explains why it's empty),
**Analysis**.

**Analysis tab specifically** — click each of the nine panel buttons and
confirm each renders a real, sortable, filterable table:
`Test coverage · Documentation · Dependencies · Complexity · Duplicates ·
Plugins · Hooks · Docs · Endpoints`. `Plugins`/`Hooks`/`Endpoints` will be
empty on a pure-Lua repo like this one (no lazy.nvim specs / React hooks /
JS routes there) — that's the correct empty state, not a bug; see §8/§10
for how to actually populate them.

---

## 4. `:DocMap graph` / `why` / `dot` / `diff` / `impact` / `churn` / `plugins`

**Steps**

```vim
:DocMap graph deps
:DocMap graph calls documentation.core.check      " pick a real module name from your tree
:DocMap why documentation documentation.core.scan " pick two connected modules
:DocMap dot deps
:DocMap diff HEAD~5
:DocMap impact HEAD~1
:DocMap churn HEAD~200..
:DocMap plugins
```

**Expect**:
- `graph`: opens the HTML page already centered/filtered on that state (URL
  fragment, not a re-render).
- `why`: quickfix list, each entry a real require hop with a line number;
  jump through a couple to confirm they land on the actual `require(...)` line.
- `dot`: a new scratch buffer with Graphviz DOT text (`digraph {...}`).
- `diff`/`impact`: quickfix-list-style output naming real functions/modules
  that changed in that range — on this repo's own history, should list real
  entries, not "nothing changed" (unless you picked an empty range).
- `churn`: quickfix list sorted by `commits × complexity`, highest first,
  each row naming its single most complex function.
- `plugins`: on documentation.nvim/lib.nvim's own repo this will likely be
  **empty** (no lazy.nvim specs there) — test this one for real from
  `C:\Users\bartl\AppData\Local\nvim` instead (`:DocMap plugins` there
  should list every plugin from `plugins/personal/init.lua`, with its
  trigger and source file).

---

## 5. `:DocBrowse` — the in-editor navigator

**Steps**

```vim
:DocBrowse
```

Press `1`..`9` to cycle every mode (**structure · deps · calls · types ·
history · trail · endpoints · telemetry · loaded** — the last two are
their own §14/§15 below, since both need a live `runtime-analysis.nvim`
session to show anything interesting). In any mode:

- `j`/`k` move, `<CR>` descend, `-`/`<BS>` up.
- `gd` on a function/module — jumps to its real source line.
- `gq` — fills the quickfix list with the current list's contents.
- `f` then type a substring, `<CR>` — narrows the list in place; `f`
  again with nothing clears it. Try `-word` to *exclude* a substring.
- `?` — the key-hint overlay; confirm it matches what you just used and
  marks anything the current mode ignores.
- `p` on an entry, then `6` (Trail mode) — the pinned entry should appear;
  `<CR>` on it restores the exact view (mode + position) it was pinned
  from.
- Still in Trail mode: `S`, type a name, `<CR>` — saves the current trail.
  Pin something else, `p` it, then `L`, pick the saved name — the saved
  pins should be **added** to what's already pinned, not replace it.
  `X` on a saved name forgets it (confirm it's gone from a fresh `L`
  list). `d` on a pinned entry unpins just that one.
- `q` — closes.

**Also check trails persist across Neovim restarts**: pin something,
`:q` out of `:DocBrowse` (not just close the float — really quit and
reopen Neovim), `:DocBrowse` again, `6` — the pin should still be there.
Saved trails (via `S`) should too.

**History mode** needs `git log` (works even without `:DocMap serve`,
unlike the HTML page's own History tab) — `2` then a commit, `gD` shows
that commit's diff.

**Expect** throughout: nothing errors, `?` never shows a key that does
nothing when pressed (or explicitly marks it "(disabled)" if you've
rebound something in `opts.keys`).

---

## 6. The annotation popup (hover `ⓘ`)

**Steps**

1. `:DocMap open` (needs a real generated page — see §1).
2. Go to the **Index** or **Complexity** Analysis panel (or the Notes tab
   if anything here has `@todo`/`@bug`/`@deprecated` — check first).
3. Hover the small `ⓘ` beside any listed function. Try clicking one too.
4. Tab to one with the keyboard and press Enter.

**Expect**: a floating card with the full signature, params (with types),
returns, and — new in the same feature — the function's own **source
snippet** (§7) capped at 40 lines with a "+N more lines" note if it was
longer. Hovering away closes it after a short delay; clicking pins it
(stays open, click elsewhere or Escape closes it). Near the bottom of the
page, the card should flip to open *above* its trigger rather than running
off-screen. The footer link navigates to that function's module in the
Tree tab.

---

## 7. Bounded snippet previews

Covered inline by §6 — the popup already shows it. To see the boundary
case specifically:

**Steps**: find a long function in the popup (anything over ~40 lines —
`history.lua`'s own `M.analyze` is one, in this repo).

**Expect**: the snippet is truncated at exactly 40 lines, with a
"+N more lines" badge showing the real remaining count — not silently cut
off with no indication.

---

## 8. Docs corpus, doc-reference markers, and `doc-references-missing`

**Steps**

1. `:DocMap check` on this repo (documentation.nvim's own — it has real
   `.md` files that reference real code).
2. `:copen` — look for a `doc-references-missing` finding (should be at
   most one or two on a clean tree; check the exact wording).
3. `:DocMap open` → **Analysis** tab → **Docs** panel.
4. Back in **Index**/**Complexity**, look for the small doc-reference icon
   (rendered *only* where a `.md` file actually mentions that
   function/module — most rows will have none) and click one.

**Expect**: the **Docs** panel lists every `.md` file scanned, with a
title and a resolved-reference count, sortable/filterable like every other
panel — clicking a row does nothing (these aren't tree nodes, by design).
The doc-reference icon (where present) opens the same popup style as §6,
listing which `.md` file(s) mention this entity and the surrounding line.

---

## 9. `:DocMap serve` and the History tab

**Steps**

```vim
:DocMap serve
:DocMap open
```

Click the **History** tab, then click a commit.

**Expect**: `serve` prints the local port it bound (`127.0.0.1`, never
`0.0.0.0`). The History tab now actually loads commits and, clicking one,
computes and shows that commit's blast radius — where opening the page via
plain `:DocMap open` (no server) explicitly told you this tab needs
`serve`. `:DocMap serve stop` afterward, then confirm the tab explains
itself again instead of erroring.

---

## 10. API endpoint inventory (Analysis panel + `:DocMap endpoints`)

**Prerequisites**: needs real JS/TS Express-shaped route code — this
repo/lib.nvim has none, so use a scratch dir (same one from
`runtime-analysis.md` §2 works):

```js
const app = require("express")();
app.get("/users/:id", function getUser(req, res) {});
app.post("/users", function createUser(req, res) {});
```

**Steps**

```vim
:DocMap
:DocMap endpoints
```

Then `:DocMap open` → **Analysis** → **Endpoints** panel.

**Expect**: `:DocMap endpoints` → quickfix list, one entry per route,
sorted by path, summary line reporting how many are documented. The
**Endpoints** panel shows Method/Path/Handler/Framework/Declared-in
columns; `framework` should read `express` (from the real `require(...)`
in that file); clicking the `getUser` handler name opens the real
annotation popup for that function (§6), not a separate copy.

---

## 11. Endpoints mode in `:DocBrowse` + `gs` (send a request)

Same scratch JS repo as §10.

**Steps**

```vim
:DocBrowse
```

Press `7` (Endpoints mode). Move to a route, press `gs`.

**Expect**: a `runtime-analysis.nvim` request buffer opens, pre-filled
`METHOD /path` (no host — you complete it). See
[`runtime-analysis.md` §2](runtime-analysis.md) for the full round-trip
including the soft-dependency check.

---

## 12. Live handle (`install()`) instead of files

**Steps**

```lua
local handle = require("documentation").install({
  root = vim.fn.getcwd(),
  source = "lua/documentation",  -- adjust to whatever repo you're in
  watch = true,
})
print(#handle.ir().order, "nodes")
print(vim.inspect(handle.requires("documentation.core.scan")))

handle.on_change(function(ir, findings)
  print("rescanned:", #ir.order, "nodes,", #findings, "findings")
end)
```

Now edit and save a file under that `source` directory.

**Expect**: the initial prints show real numbers immediately (no
`:DocMap` needed first). After the save, the `on_change` callback fires
(debounced ~0.65s) with fresh counts. `handle.uninstall()` should stop
further callbacks — edit again and confirm nothing prints.

---

## 13. Drift checks, a few concretely

Most of the 14 checks (`missing-module-tag`, `module-path-mismatch`,
`missing-summary`, `dead-readme-link`, `dead-see-target`,
`doc-references-missing` (§8), `require-cycle`, `require-not-declared`,
`layer-violation`, `missing-readme`, `unreferenced-module`,
`undocumented-param`, `param-name-mismatch`, `dead-function`) are easiest
to see by breaking something on purpose in a scratch copy, running
`:DocMap check`, then reverting:

1. Delete a `---@module` comment from one file → `:DocMap check` →
   expect `missing-module-tag` (error severity — command should indicate
   failure).
2. Rename a `---@param` name so it no longer matches the function
   signature → expect `param-name-mismatch`.
3. Add `require("something.that.does.not.exist")` → expect
   `require-not-declared` or a require-graph-related finding.
4. Revert both changes, `:DocMap check` again → back to clean (or your
   original baseline).

**Expect** throughout: findings land in the quickfix list with a real
file:line, never just a message you have to search for by hand.

---

## 14. Telemetry mode in `:DocBrowse` (`ECOSYSTEM.md` step 8)

**Prerequisites**: a live `runtime-analysis.nvim` telemetry namespace —
your real config already has one for every personal plugin (see
[`runtime-analysis.md`](runtime-analysis.md) §5), so this works from any
of their repos once you've used the plugin a bit this session.

**Steps**

1. `cd` into a real plugin repo that has real telemetry data by now, e.g.
   `E:\repos\markdown.nvim`.
2. `:DocMap` (needs a real generated map first), `:DocBrowse`.
3. Press `8` (Telemetry mode).

**Expect**: one row per function, badge-prefixed: `✕` (no static caller,
never called — real dead-code candidate), `!` (called, but no static
caller found — a callback/dynamic-dispatch false positive), `○` (has a
caller, never called), blank (healthy). A function with genuinely no
telemetry data at all shows undecorated with a trailing note, not a
fabricated `✕`. Cross-check a `✕` row against `:DocMap check`'s own
`dead-function` findings — a function telemetry proves alive should
**not** also appear as `dead-function` there (the join suppresses it).

**Also check the soft-dependency path**: `cd` into a repo with **no**
telemetry data for that namespace (or temporarily rename
`E:\repos\runtime-analysis.nvim`), `8` again — expect a clear "no data"
message, never a graveyard of fabricated `✕` badges.

---

## 15. Endpoint coverage (`:DocBrowse` Endpoints mode, enriched — `docs/ROADMAP.md` §6.2 in runtime-analysis.nvim)

Builds on §10/§11's own scratch Express repo.

**Steps**

1. In that scratch repo, actually send one of the routes via `gs`
   (§11) — pick just one of the two, not both.
2. `:DocBrowse`, `7` (Endpoints mode).

**Expect**: the route you actually sent shows **no** leading badge; the
one you never sent shows a leading `○` and its detail pane says "never
sent" explicitly. Send the second route too, reopen Endpoints mode (`q`
then `:DocBrowse` again, or just re-enter the mode) — its `○` should be
gone now, detail pane shows "sent N time(s)" with a real timestamp.

**Also check**: `cd` somewhere with **no** `runtime-analysis.nvim`
request history at all for this project — Endpoints mode should still
work, just with no `○` badges and no coverage detail (the base feature
from §10 is unaffected by the join's own presence or absence).

---

## 16. Diff loaded-vs-declared (`:DocBrowse` Loaded mode — `docs/ROADMAP.md` §5.3 in runtime-analysis.nvim)

**Prerequisites**: this one only makes sense pointed at a plugin that is
itself genuinely loaded in *this* Neovim session — `documentation.nvim`
or `runtime-analysis.nvim` itself both qualify, since your config loads
both.

**Steps**

```vim
:DocBrowse
```

`cd` into `E:\repos\documentation.nvim` first (or `runtime-analysis.nvim`),
then press `9` (Loaded mode).

**Expect**: either "no discrepancies" (everything declared is loaded and
vice versa — a real, clean possibility) or real rows: `✕` a declared,
exported function not currently on `package.loaded`'s own table
(check whether it's genuinely dead or just a lazy-loaded submodule that
hasn't fired yet this session), `!` a function on the live table with no
matching source declaration (generated, wrapped, or a typo — read the
real code to find out which). `gd` on a `✕` row jumps to its real
declaration; a `!` row has no `gd` target (no static declaration exists)
— confirm the footer text says so instead of erroring when you try.

**Also check**: `cd` into a repo that is **not** currently loaded as a
live plugin in this session (any repo you have on disk but didn't
`require()` this session) — expect an honest "no data — install/enable
runtime-analysis.nvim" message, not a wall of false `✕` findings for
every declared function.

---

## 17. JS/TS/TSX as a real language backend (`core/lang/ecma.lua`)

**Prerequisites**: a real JS/TS/TSX repo — reuse the scratch Express dir
from §10, or point at any real `.ts`/`.tsx` project you have.

**Steps**

```vim
:DocMap
```

from inside that repo (`source` should auto-detect `src`/`.` — check
`:checkhealth documentation`'s resolved-config section if unsure).

**Expect**: real function/class/symbol extraction from `.js`/`.ts`/`.tsx`
files, not just an empty tree. `:DocBrowse`, Calls mode on a real
exported function — should show real call edges into/out of it, the
same as a Lua tree. Add a genuinely wrong import
(`import { X } from "./nowhere"`) — `:DocMap check` should flag it the
same way a bad Lua `require` would.

---

## 18. Analysis tab — Duplicates and Hooks panels

**Duplicates**: pick any repo with at least one obviously copy-pasted
function (or paste one deliberately into a scratch file for this test),
`:DocMap`, `:DocMap open` → **Analysis** → **Duplicates**.

**Expect**: a real pair (or group) of near-identical functions, each
with its own file:line, sortable/filterable like every other panel.
Revert the deliberate copy-paste, regenerate, confirm the pair is gone.

**Hooks** (React only — needs a real `.tsx` file using
`useState`/`useEffect`/etc., e.g. from §17's own scratch repo if it has
any, or a small one written for this test): `:DocMap open` → **Analysis**
→ **Hooks**.

**Expect**: real hook usages listed per component, not an empty panel on
a repo that genuinely has React hooks. On a pure-Lua repo, this panel
should be **empty** — the correct state, not a bug.
