# Testing language.nvim

How to manually test language.nvim's real feature surface. Telemetry
(Workstation dataset, 50 sessions, 17 instrumented functions) shows
**zero recorded calls** — this plugin has been loaded 50 times and never
meaningfully exercised. Per this folder's own methodology, that is not
treated as "unimportant" — it means this checklist carries more weight
than usual, since nothing here has been validated by real use yet.
Priority below follows the README's own ordering (spelling/grammar is
named first, translate second, thesaurus third) and `docs/WORKFLOW.md`'s
description of which habit is worth building first.

Repo: `E:\repos\language.nvim`. Spec: `lua/plugins/personal/init.lua`
(`event = "VeryLazy"`, `dependencies = { "StefanBartl/lib.nvim",
"folke/trouble.nvim" }` — trouble.nvim optional, `pcall`-guarded, used for
a nicer issue list if present). This config's `setup()` sets:
`spell.ui = { view = "picker", preview = true }` (the panel UI, not the
classic quickfix+diagnostics flow), `spell.programming_dict = true`
(covers nvim/Lua plugin-dev vocabulary — `nvim`, `buffer`, `bindings`,
etc. — so `:Spellcheck de` stops flagging it in German prose about plugin
development), `spell.extra_wordlists = require("spell_wordlists")`
(Tricentis/TOSCA vocabulary, loaded unconditionally), and
`translate.keymaps = { operator = "<leader>lt", visual = "<leader>lt" }`
(same lhs bound in both normal-mode-operator and visual-mode contexts —
both are opt-in and off by default upstream; this config turns both on).
No `thesaurus.keymap`, no `translate.keymaps.to.<LANG>` per-language
force-keys, no `spell.live`, no `spell.highlights.enable`, no
`spell.guard.block_write_on_error` — all left at their off-by-default
upstream values.

## Setup

```vim
:checkhealth language
```

**Expect**: `lib.nvim` found, `curl` present (needed for the default
Google translate engine), grammar/spell CLI tools (`typos`/`cspell`/
`codespell`/`harper_ls`/`ltex`) reported present/missing — none of these
are configured in this session's `spell.providers`, so "missing, optional"
is the expected baseline, not a problem to fix before testing.

---

## 1. Spell session — the flagship feature, and the one to build a habit around first

**Steps**

Open a markdown or text buffer with a few real spelling mistakes, or type
some.

```
<leader>ss    " toggle session on
]s            " jump to next issue
<leader>z=    " fix picker on issue under cursor
<leader>z1    " apply first suggestion directly
<leader>ss    " toggle off again
```

**Expect**: `<leader>ss` starts a session, publishing issues via
`vim.spell` as diagnostics with a **Trouble panel** (since
`folke/trouble.nvim` is installed here) — confirm it's actually Trouble
and not the quickfix fallback, since `spell.ui.view = "picker"` in this
config governs the review panel specifically, not which list backend
diagnostics use. `]s` moves between issues. `<leader>z=` opens the
suggestion picker; `<leader>z1` applies the top suggestion and
auto-advances to the next issue. Ending the session (`<leader>ss` again)
restores the buffer's original `spelllang` and clears diagnostics —
confirm `:set spelllang?` really goes back to what it was before.

**The review panel itself** (opened by `<leader>ss`/`:Spellcheck` per
`spell.ui.view = "picker"`):

- [ ] `<CR>` on an issue — full action menu (suggestions, replace-all, add
  to dictionary, ignore, jump, LSP fix for grammar issues).
- [ ] `a` — add to dictionary directly, no menu round-trip.
- [ ] `i` / `I` — ignore (session-only vs. persistent) — confirm `I`
  survives ending and restarting the session, `i` doesn't.
- [ ] `gd`/`o` — jump to the word, closes the panel.
- [ ] `?` — cheatsheet of panel keys.
- [ ] Press `a` (dictionary-add) on a **grammar** issue specifically —
  should report that it's not applicable rather than silently doing
  nothing or erroring.
- [ ] Since `spell.ui.preview = true` here: confirm the panel actually
  shows a preview of surrounding context for the selected issue, not just
  the bare word.

---

## 2. Three sources feeding one panel — know which one answered

This config has no `spell.providers.buffer`/`.cwd` set, so **native
`vim.spell` is the only source for buffer scope**; grammar via LSP only
applies if `harper_ls`/`ltex` is actually attached to the buffer.

**Steps**

1. Confirm native detection is code-aware: type a CamelCase identifier
   with a real misspelling embedded (`getUsrDatta`) inside a comment —
   should split into sub-words and flag `Usr`/`Datta` individually, not
   the whole identifier as one token.
2. Type the same misspelling **outside** any comment/string (bare code) —
   should **not** be flagged at all (Treesitter `@spell` region
   restriction, `spell.regions.treesitter_spell` default `true`).
3. If `harper_ls`/`ltex` is attached to the buffer's filetype: introduce a
   grammar issue (subject-verb disagreement) and open the fix menu on it —
   should offer **"Apply LSP fix…"**, not a suggestion-list picker (no
   fixed word list exists for a grammar issue).

**Expect**: since `spell.programming_dict = true` here, common nvim/Lua
plugin-dev terms (`nvim`, `buffer`, `bindings`, `treesitter`) should
**not** be flagged even in German prose (`:Spellcheck de`) — this is the
exact scenario the config comment cites as the reason it's enabled. Also
confirm the custom `extra_wordlists` (Tricentis/TOSCA terms, e.g.
"Testfall", "Modultest" or similar domain vocabulary from
`lua/spell_wordlists.lua`) are genuinely recognized — pick a real term
from that wordlist file and confirm it's silently accepted.

---

## 3. `:Spellcheck cwd` — native fallback, since no CLI provider is configured

**Steps**

```vim
:Spellcheck en cwd
```

from a moderate-sized real directory (this nvim config's own `docs/`
works).

**Expect**: since no `typos`/`cspell`/`codespell` is in
`spell.providers.cwd` in this config, this should run the **native
recursive walk** — async, 20 files/tick, shows `lib.nvim.progress`,
cancellable, skipping `.git`/`node_modules`/`.venv`/etc. and files over
5MB or `max_file_lines`. Confirm it checks **closed** files too, read
fresh from disk — not just already-open buffers (that used to be a real
gap).

- [ ] Cancel it mid-scan (however the progress UI exposes that) — should
  stop cleanly, not leave a runaway background job.

---

## 4. Translate: `:Translate` (popup) vs `:TranslateReplace` (mutating)

**Steps**

```vim
:'<,'>Translate DE
:'<,'>TranslateReplace DE
:Translate FR --output=vsplit
```

**Expect**: `:Translate` defaults to a **read-only popup** — the buffer
must be untouched afterward, confirm by checking the selection is
unchanged. `:TranslateReplace` is the mutating counterpart — the
selection should actually change in place. `--output=vsplit` should open
a vertical split with the translation instead of a popup, buffer
untouched either way (`--output=` never mutates except `replace`/
`buffer`).

- [ ] `--nocode` on a markdown selection containing inline `` `code` ``
  spans, via `:TranslateReplace` — confirm the code spans survive
  untouched while the surrounding prose translates.
- [ ] Translate a multi-line indented list (markdown `- item` with
  leading whitespace) via `:TranslateReplace` — leading whitespace should
  be preserved per line (indent-preserving round trip), unless the
  translation came back with a different line count than the input, in
  which case confirm it gracefully skips re-indenting rather than
  corrupting anything.

---

## 5. Motion/visual translate keymap — `<leader>lt`, configured for both modes here

This config is one of the few settings that deviates from upstream
defaults (both off by default; both on here, same lhs).

**Steps**

```
<leader>ltiw     " normal mode: operator + inner-word motion
```

then, in visual mode, select some text and press `<leader>lt`.

**Expect**: both **always replace in place**, regardless of `:Translate`'s
own popup default — this is a deliberate, documented split (the
motion/visual maps hardcode `replace`). Since no `default_target` is
configured, both should **prompt** for a target language every time — if
that prompt doesn't appear, something is misconfigured. Since no
`translate.keymaps.to.<LANG>` force-keys are set, there's no one-shot
target override to test here.

- [ ] Confirm char-wise selections translate the **exact byte span**
  (multibyte-safe), not the whole line — select a few words mid-sentence
  and check only those words changed.

---

## 6. Interactive translate window (`:Translate!`)

**Steps**

```vim
:'<,'>Translate! DE
```

**Expect**: a two-pane float, editable input on one side, live output on
the other, updating as you type.

- [ ] `<C-l>` — retarget the language without closing the window.
- [ ] `<C-r>` — promotes the current output back into the input and picks
  a new target; chain DE → EN → FR to sanity-check a round trip.
- [ ] `<C-h>` — history picker; confirm a prior query from this session
  (or a persisted one, if JSON persistence is on) is recallable.
- [ ] `<C-y>` — copies the current result without touching the buffer.
- [ ] `q`/`<Esc>`/`<C-c>` — closes cleanly.

---

## 7. Multi-file translate

**Steps**

```vim
:Translate DE cwd
```

from a small directory with a couple of markdown files.

**Expect**: a multi-select picker (`<Tab>` to toggle files). Default
behavior writes a new sibling file per selection (`notes.md` →
`notes.DE.md`) — **non-destructive**, confirm the originals are untouched.

- [ ] `:Translate DE cwd --files=buffers` — opens scratch buffers instead
  of touching disk at all.
- [ ] `:TranslateReplace DE cwd` — skips the choice, overwrites originals
  directly, and should ask for confirmation first.

---

## 8. Thesaurus — no keymap configured here, so test via the API

**Steps**

```vim
:lua require("language").synonyms()
```

with the cursor on a real word.

**Expect**: replaces the word under cursor in place with a synonym from
Datamuse (async, keyless) — no picker between candidates by default, it
takes the top result directly. Since no keymap is bound in this config,
this Lua call is the only way to exercise it here; if the user wants
`3{keymap}`-style Nth-synonym behavior (documented for when a keymap
*is* set), that specifically needs `opts.thesaurus.keymap` configured —
not testable as-is without a temporary config change.

---

## 9. Silencing without ending the session

**Steps**

Add a comment `-- language:disable-line` on a line with a deliberate
misspelling, save, re-run `:Spellcheck`.

**Expect**: that specific line is suppressed from issues without touching
`highlights.enable` or ending the session — confirm it survives a
re-scan, not just the current one. Try `-next-line` and `-file` variants
too.

- [ ] `spell.guard.block_write_on_error` is **off** by default in this
  config — confirm `:w` on a buffer with known spelling errors succeeds
  normally (no abort). This is worth confirming precisely because it's
  the one guard-rail feature that would be surprising if silently active.

---

## What this checklist does not cover

`spell.live` (off by default here, not overridden — no background
scan-while-typing to test). `spell.highlights.enable` (off — no in-buffer
underline/undercurl to check). The `cspell_server` sidecar (not
configured in `spell.providers.buffer` here — would need `node` + `cspell`
installed and an explicit config change to exercise). DeepL/
translate-shell/custom translate engines (this config uses the default
`google` engine only, no `fallback`/`deepl.api_key` override).
