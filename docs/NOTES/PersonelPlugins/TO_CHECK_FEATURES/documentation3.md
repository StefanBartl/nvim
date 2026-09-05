# Testing documentation.nvim — the 2026-08-18 batch

Everything built on `main` between `751e5be` and `e421a64`. Same shape as
`documentation2.md`: one section per feature, prerequisites, steps, what to
expect.

**Every item here is verified structurally or in a browser DOM and has been
looked at by nobody.** That is the whole reason this file exists — the specs
say the data is right, they cannot say the thing is usable.

Repo: `$REPOS_DIR\documentation.nvim`. Open Neovim from inside the repo you
want mapped; `:DocMap` maps the current working directory.

## Prerequisites, and which ones actually bite

| Needed for | How to tell |
|---|---|
| **Tree-sitter grammars for JS/TS** — §6–§10, §14 | `:lua print(vim.treesitter.language.add("javascript"))`. Neovim resolves these from the runtimepath, **not** from `DOCMAP_TS_DIR` |
| **A rebuilt standalone engine** — §1 only | `C:\tools\docmap.exe --capabilities` must print a `languages` key. The installed one predates it |
| Nothing special | everything else |

A useful second target throughout: `$REPOS_DIR\documentation.nvim\TESTS\fixtures\polyglot`
— a checked-in tree with Lua beside JS/TS, two source roots, a file outside
every root and an extension no backend claims. Built precisely so these
things can be tried without inventing a tree first.

---

## 1. `--capabilities` reports the language backends

**Needs a rebuilt engine.** The one in `C:\tools` is older.

**Steps**

```
C:\tools\docmap.exe --capabilities
```

**Expect**: JSON with a `languages` array — one entry per backend
(`lua`, `js`, `ts`, `tsx`), each with `grammar` and `grammar_loaded`.

**The three-valued part is the point.** `grammar_loaded: false` means "wants
a grammar, could not load one" — degraded fidelity, module tree only. A
missing field would mean "needs no parser", which is not a degradation.
Run it once with `DOCMAP_TS_DIR` set and once without, and check the flags
actually flip.

---

## 2. A JavaScript project can be scanned at all

This is the failure that was live for months: `detect_source` returned `lua`
for every unrecognised tree, so a JS project died on
`source directory not found`.

**Steps**

Open Neovim from any JS/TS project with a `src/` (or make one: two `.js`
files under `src/`), then:

```vim
:DocMap
```

**Expect**: it scans, and the source root it reports is `src` — not an error
naming a `lua/` directory that does not exist.

---

## 3. A mixed tree maps both halves

**Steps**

```
cd $REPOS_DIR\documentation.nvim\TESTS\fixtures\polyglot
nvim
:DocMap
:DocMap open
```

**Expect**: `2 modules` worth of tree with **both** `lua/pgl` and `src`
under a single root node named after the directory. Before this, one half
was mapped and the other was never visited — no error, no mention, just
absent.

**Also check** the artifact: `docs/map/module_map.json` should carry
`meta.sources` listing both roots, and `meta.source` should be `"."`.

---

## 4. The report names what it did not look at

**Steps**

Make a Lua project with a `tools/` directory holding a `.ts` file, then
`:DocMap`.

**Expect**: a line reading
`N files of a language this map contains none of, outside every source root (ts N)`.

**Then check it stays quiet where it should.** Run `:DocMap` on
`documentation.nvim` itself: it has Lua in `scripts/` and `standalone/`
outside the source root, and must print **nothing** — that language is in
the map, so it is outside on purpose.

---

## 5. `language` per node, and the schema bump

**Steps**

```vim
:DocMap
:DocMap diff HEAD~20
```

**Expect**: `meta.schema` is `3`, every module/file node carries a
`language`, and namespaces carry none. The `diff` against an older revision
must still work — that artifact is schema 2, and the tolerance path is what
this checks.

---

## 6. Keyword hover in a source snippet

**Needs the Lua grammar (you have it).**

**Steps**

`:DocMap open`, go to the **Index** tab, hover the ⓘ next to any function to
open its card, then hover a keyword in the **Source** block — `local`,
`function`, `nil`, `end`.

**Expect**: after a short dwell (not instantly — crossing the word must not
open anything), a small card with one sentence, sometimes a second "note"
line, and a link to the **Lua 5.1** manual.

**Check specifically**:

- The function card underneath **stays open**. That is the entire reason the
  keyword card is a second layer.
- Escape closes the keyword card.
- Tab-navigation reaches the keywords. **This could not be verified at all**
  — a non-compositing browser pane never takes window focus, so `focusin`
  never fired. It is the one interaction with no evidence behind it.

---

## 7. Stdlib hover, and the `vim.*` distinction

**Steps**

In the same source block, hover `table.concat`, `table.sort`, `ipairs`, then
hover `vim.split` or `vim.trim`.

**Expect**:

- `table.concat` → a sentence **and** the Lua 5.1 manual link.
- `vim.split` → a sentence, the word **NEOVIM** underneath, and **no link**.
  Sending someone to lua.org for a Neovim function would be a link that looks
  right and answers nothing.
- `vim.treesitter.query.parse` decorates the **whole** dotted name, not just
  `vim.treesitter`.
- `vim.tbl_keys` (no entry) is **not** decorated at all.

---

## 8. Nothing is decorated inside strings or comments

**Steps**

Find a snippet containing a keyword inside a string or a comment.

**Expect**: undecorated. A definition shown for a word in the wrong context
is worse than no definition, which is why the tokenizer skips those spans.

---

## 9. The language legend — Tree tab

**Steps**

Open the **polyglot fixture's** map, Tree tab.

**Expect**: a row of chips above the tree — `lua`, `js`, `ts` with counts.
Click `ts`: only the TypeScript node and its ancestors stay; a "show all"
control appears.

**Then open documentation.nvim's own map**: the bar must be **completely
absent** — one language means nothing to choose between, and a legend there
would be permanent chrome on every map anyone ever generates.

---

## 10. The language legend — Hierarchy views

**Steps**

Same map, Hierarchy tab, Modules view. Click a chip.

**Expect**: non-matching boxes **dim** rather than disappear. Removing boxes
would re-flow the graph and can disconnect the picture, so the reader would
lose the shape they were looking at in order to ask about part of it.

**Check**: switch to Deps and back — the filter must survive the redraw. And
clear the filter from the **Tree** tab's bar; the graph must follow. One
state, two bars.

---

## 11. Copy link

**Steps**

Navigate somewhere specific — Hierarchy, a centred module, a depth — then
press **Copy link**.

**Expect**: the button flashes "Copied", and the clipboard holds the full URL
including the fragment (`#tab=hierarchy&center=…&view=deps&dir=out&depth=2`).

**Worth trying from `file://` too**, opening `docs/map/index.html` directly:
`navigator.clipboard` does not exist on an insecure origin, and the fallback
should either copy anyway or say "Press Ctrl+C" rather than doing nothing.

---

## 12. `binding-conflict` — the config check

**This one is about your own config, and is the most likely to find
something real.**

**Steps**

```
cd C:\Users\bartl\AppData\Local\nvim
nvim
:DocMap
:copen
```

**Expect**: `binding-conflict` findings wherever two places register the same
keymap (same `lhs`, same mode) or the same user command — the later one wins
silently, and `:map <leader>x` shows the winner without hinting there was a
loser.

**Check the exclusions hold**: a `{ buffer = true }` map shadowing a global
one must **not** be reported (that is the mechanism, not a mistake), and one
`vim.keymap.set({ "n", "v" }, …)` call is one registration, not two.

---

## 13. `unused-require`

**Steps**

`:DocMap` on any repo, `:copen`.

**Expect**: `info`-level findings for a `local x = require("y")` never
mentioned again. On `documentation.nvim` itself expect **none** — 144
aliased requires, all used.

**Note the deliberate coarseness**: a mention in a *comment* counts as a use.
Over-counting errs toward keeping a live line, which is the safe direction.

---

## 14. `.jsx`, class methods and `module.exports`

**Needs the JS grammar.**

**Steps**

Point `:DocMap` at a JS project with a class, a `.jsx` file, and a
`module.exports = { … }` module.

**Expect**:

- Class methods listed as `ClassName.method`.
- A `get x()` accessor **not** listed — its signature would read as callable
  and it is not.
- `.jsx` files scanned (they are JavaScript; the `javascript` grammar parses
  JSX with no errors).
- Every function in `module.exports = { … }` listed, in all three forms
  (shorthand, `function` value, arrow) — and `notAFunction: 42` not listed.

---

## 15. Cross-file calls in JS

**Needs the JS grammar.**

**Steps**

Open the polyglot fixture's map, Hierarchy → **Calls**.

**Expect**: an edge from `polyglotFixtureSplit` to `polyglotFixtureJoin`,
crossing from `src/parse.ts` into `src/util.js`. Before this, a relative
import was recorded as an *external* module and no JS call ever crossed a
file boundary.

**Also check** in the Deps view that `./util.js` is a real node-to-node edge
rather than a grey external box.

---

## 16. `:DocMap mermaid [tree|deps]`

**Steps**

```vim
:DocMap mermaid
:DocMap mermaid deps
```

**Expect**: a scratch buffer of Mermaid source in a fenced block, `markdown`
filetype. Asking twice must **reuse** the buffer rather than producing an
unnamed one. Paste into a README and confirm GitHub draws it.

---

## 17. `:DocMap consumers` — the reverse index

**The interesting one to run against `lib.nvim`.**

**Steps**

```
cd $REPOS_DIR\lib.nvim
nvim
:DocMap consumers $REPOS_DIR
```

**Expect**: a markdown buffer reporting roughly **107** modules required by
at least one consumer, **108** required only by lib.nvim itself, **33** by
nobody, read from ~29 sibling maps — then the per-module list, most-used
first (`lib.nvim.bindings.usercmd.composer` at 28 consumers, `lib.nvim.notify` at 27).

**Read the caveat in the output and check it is there**: `unreferenced` does
not mean dead. It means no consumer among the maps supplied.

---

## 18. `consumer-require-missing`

**Steps**

Add to lib.nvim's docmap opts: `consumers = "E:/repos"`, then `:DocMap`.

**Expect**: **nothing** today — 29 maps, zero broken references. To see it
fire, rename a module in lib.nvim without regenerating its consumers, then
re-run: it should name the module and every consumer still pointing at it.

---

## 19. SARIF output

**Steps**

```
nvim --headless -l scripts/gen_map.lua --check --sarif=drift.sarif
```

**Expect**: `wrote drift.sarif`, valid SARIF 2.1.0, one rule per check that
actually fired.

**Every result points at line 1**, and `invocation.properties.lineNumbers`
says so — findings carry no line, and a fabricated one would be trusted.
Check that sentence is in the file.

---

## 20. `example-does-not-parse`

**Expect nothing, anywhere.** No tree in this ecosystem uses `@example` —
zero blocks here, none in the thirty-odd sibling plugins. To see it work at
all you have to write one, and then break it. Recorded so the silence is not
mistaken for the check being broken.

---

## Still outstanding from before this batch

Carried over from `docmap-desktop/docs/HANDOVER.md`, still unlooked-at:

- The **collapsed engine panel** in docmap-desktop.
- The **edge popup** in the Calls graph.
- Typography scale (16 distinct `font-size` values were measured) and zebra
  striping — both need eyes, neither has had them.
