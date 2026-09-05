# Testing gopath.nvim

How to manually test gopath.nvim's real feature surface. Telemetry
(Workstation dataset, 50 sessions) shows real but thin entry-point signal
— `commands.resolve_and_open` (1 call), `open.open` (1),
`resolve.resolve_at_cursor` (1), `providers.builtin.expand_cfile` (1),
`resolvers.common.filetoken.resolve` (1), `resolvers.common.help.resolve`
(1) — meaning the core "resolve and jump" path has been used for real at
least once and worked. The much larger counts (`config.get` 510,
`truncated.cache.needs_refresh` 486, `truncated.cache.build_async` 252,
`_finalize_build`/`_save_to_disk` 251 each) are the filesystem-cache
subsystem rebuilding repeatedly in the background — infrastructure, not a
feature a user chose, so it doesn't reorder priority here, but its sheer
activity is worth confirming isn't runaway (see §2).

Repo: `$REPOS_DIR\gopath.nvim`. Spec: `lua/plugins/personal/init.lua`
(`event = "VeryLazy"` — required; without a lazy-load trigger the plugin
never sources and every keymap silently does nothing, which the plugin's
own docs call out as the most common "it's not working" report).
`dependencies = { "nvim-treesitter/nvim-treesitter" }` (optional, only
used by `pcall`-guarded Treesitter fallback paths).

**The one thing to know before testing anything else**: this config
**remaps the primary open keymaps away from the README's own defaults**:

```lua
mappings = {
  open_here = "gF",       -- README/docs default is gP
  open_split = "g|",
  open_vsplit = "g\\",
  open_tab = "g}",
  copy_location = "gY",
  debug = "g?",
},
```

Every doc in `$REPOS_DIR\gopath.nvim\docs\` refers to `gP` throughout — in
this actual session, `gP` does **nothing** and `gF` is the real "resolve
and open here" key. `gC` (check/create), `<leader>pp` (probe), and `gM`
(reveal in file manager) are **not** remapped and keep their documented
defaults. Also configured: `mode = "hybrid"`, `alternate.enable = true`
with `similarity_threshold = 75` (same as upstream default, just made
explicit), `external.enable = true`.

## Setup

```vim
:checkhealth gopath
```

**Expect**: `lib.nvim` found, `nvim-treesitter` optional (present here),
`fd`/`rg` reported present/missing with a reason (speeds up truncated-path
suffix search), which-key detected if installed.

---

## 1. `gF` — the core resolve-and-open pipeline (remapped from `gP`)

**Steps**

Put the cursor on a real `require("a.b")` in a Lua file in this config
(`lua/`), press `gF`.

**Expect**: jumps straight to `lua/a/b.lua`. Try each shape the LSP →
Treesitter → builtin pipeline is documented to handle:

- [ ] Bare identifier — `local resolver = require("gopath.resolve")`,
  cursor on `resolver` alone → opens `resolve.lua` directly (Treesitter's
  `identifier_locator` pass).
- [ ] Table-chain call — `config.get()`, cursor on `get` → opens the
  `get` definition inside `config.lua`, not just the file.
- [ ] Value origin — a config table's leaf key traced back to its source
  module (`cfg.highlight.enable_x` → opens `config.lua` at the
  `enable_x = ...` line, however nested).
- [ ] A plain relative file path in a comment or string.
- [ ] A `:help` tag (`vim.api.nvim_win_set_cursor`) — opens real help.
- [ ] `g?` — prints the full resolution chain to `:messages`. Use this any
  time `gF` opens the "wrong" file; it should name which phase (LSP,
  Treesitter, builtin) produced the hit, not just say "resolved."

**Also check the other open variants** (also remapped here): `g|` split,
`` g\ `` vsplit, `g}` tab, `gY` copies `path:line:col` to the clipboard —
paste it somewhere and confirm it's real, not just a notification.

---

## 2. Truncated-path suffix search and the filesystem cache

The subsystem telemetry shows is the most active part of this plugin on
this machine — worth confirming it's actually working, not just busy.

**Steps**

```vim
:Gopath cache info
```

**Expect**: real stats (paths indexed, last build time) — confirms a
background build has actually completed (deferred ~2s after `setup()`).

- [ ] Find or fabricate a truncated stack-trace-style line, e.g. paste
  `...nvim-data/lazy/gopath.nvim/lua/gopath/init.lua:42` into a scratch
  buffer, cursor on it, `gF`. Should resolve via suffix search against the
  cache — if the cache is cold (very first jump after a fresh restart), it
  may fall back to an async live search first ("search running" message,
  never blocks).
- [ ] `:Gopath cache build` — forces an immediate rebuild; should visibly
  take a moment (real filesystem walk), not be instant.
- [ ] `:Gopath cache add-root <dir>` with `<Tab>` completion — confirm
  `<Tab>` only offers real directories and a non-directory argument is
  rejected before the handler runs.

---

## 3. Create-on-missing and "Open in filetree"

**Steps**

Put the cursor on a plausible-but-nonexistent path, e.g. type
`docs/NOTES/scratch-test-file.md` in a scratch buffer, `gF`.

**Expect**: no exact file, no fuzzy alternate close enough → a button
dialog offering **Create file**. Since `filetree.nvim` is installed and
configured in this session, and the path's ancestor directory
(`docs/NOTES/`) exists, the dialog should also offer **Open in filetree**
as a second button — pick it and confirm the tree roots/focuses on that
directory rather than creating anything.

- [ ] Pick **Create file** instead on a fresh path — confirm parent
  directories get created (`mkdir -p` semantics) and the new file opens in
  the originally-requested window mode.
- [ ] `gC` (`:GopathCheck`) on the same kind of nonexistent path — should
  **always** offer creation, even if you've set
  `create_on_missing.enable = false` for a test (this config leaves it at
  its default `true`, so this mainly matters if you're deliberately
  testing the opt-out).

---

## 4. Fuzzy alternate resolution

**Steps**

Rename a real file slightly (fix a typo, change extension) in a scratch
copy, then put the cursor on a reference to the **old** name and press
`gF`.

**Expect**: since the exact path is now missing, the fuzzy matcher should
suggest the renamed file (Levenshtein distance + prefix bonus,
`similarity_threshold = 75` — this config's explicit value, matching
upstream default) **before** offering to create anything — confirm the
picker shows candidates with `(NN%) — size, modified Xm ago`, not a bare
create-file prompt.

- [ ] Deliberately test the threshold boundary is real: a barely-similar
  filename should **not** appear as a suggestion (falls through to
  create-on-missing instead).

---

## 5. `gM` — reveal in file manager (distinct from opening)

**Steps**

Cursor on a resolvable file reference, `gM`.

**Expect**: Windows Explorer opens with the file **selected inside its
parent directory** — no buffer opened in Neovim. On a directory reference,
Explorer navigates straight into it instead. `gM` takes priority over the
external-app heuristic — try it on an image reference and confirm it
reveals in Explorer rather than launching an image viewer.

- [ ] `gM` on an unresolvable/missing path — should **warn**, not offer
  the create-on-missing dialog (there's nothing to reveal yet, and `gM`
  never opens a buffer to begin with).

---

## 6. Universal resolvers: URLs and environment variables

**Steps**

1. Put the cursor on a URL with a query string, e.g.
   `https://github.com/search?q=test&type=code`, `gF`.
2. Put the cursor on `$USERPROFILE/some/path.md` (or `${VAR}\...`).

**Expect**: step 1 opens the URL in the system browser — confirm the full
URL including `?q=test&type=code` is preserved, not truncated at the `?`
(a historical bug: `isfname` used to stop there, silently opening a
truncated URL or offering to *create* a local path from it — should not
happen now). Step 2 expands the env var against a real path.

- [ ] A bare host with a known TLD but no scheme (`github.com/neovim/
  neovim`) — should still resolve as a URL (the "loose" match), but only
  after every local file resolver has already missed — a real local
  `github.com` directory on disk should still win if one exists.

---

## 7. Probe (`<leader>pp`) — for spans the automatic extractor misses

**Steps**

1. Normal mode: cursor on a bare filename embedded mid-sentence with no
   path separators around it (e.g. inside a log-style line pasted into a
   scratch buffer), `<leader>pp`.
2. Visual mode: select just the filename fragment, `<leader>pp`.

**Expect**: both run the same suffix-candidate search the cache-backed
resolver uses, opening in a vertical split. A tight selection (just the
filename) should produce better candidates than a loose one (extra words
included) — worth comparing both deliberately once.

---

## 8. Language-specific vs. universal resolver order

**Steps**

In a `.lua` file under this config's own `lua/` tree, temporarily set
(via `:lua`) `require("gopath").setup({ languages = { lua = { enable =
false } } })`, then `gF` on a `require(...)` line again.

**Expect**: falls through to the universal resolvers (plain file paths,
help tags) instead of erroring — confirms disabling a language's
resolvers doesn't disable navigation on that filetype entirely, just the
language-aware layer. Restore the setting afterward (`lua = { enable =
true }`, or just restart Neovim) before continuing other tests.

---

## What this checklist does not cover

Deep per-language resolver correctness beyond Lua (Python/JS/TS/Go/Rust/
C/C#/Zig/Java each get one resolver module — this session has no polyglot
repo handy to exercise them against; the Lua path in §1 is the
well-covered one, since Lua/Neovim configs are the plugin's stated primary
use case). `custom_resolvers`/`opts.external.extensions` extension points
(no custom resolver configured in this session). `auto_rebuild_on_save`
(off by default here, not overridden).
