# Keymaps — collision & prefix-wait analysis across all plugins

The cross-plugin check the per-plugin sheets in this folder cannot do on their
own: which `lhs` is claimed twice, which one shadows a Neovim builtin, and
which one makes Neovim sit and wait for `timeoutlen` before it acts.

Written 2026-08-25 against the sources in `C:/repos/*.nvim`, not against the
cheatsheets — the defaults were read out of each plugin's `keymaps.lua` /
`config/DEFAULTS.lua`, and the **scope** of every mapping was verified at its
`map(...)` call site.

## Table of content

  - [Why scope decides everything](#why-scope-decides-everything)
  - [The global set](#the-global-set)
  - [Exact duplicates](#exact-duplicates)
  - [Config vs. plugin](#config-vs-plugin-resolved-2026-08-30)
  - [Cross-scope shadowing](#cross-scope-shadowing)
  - [Builtins that get overridden](#builtins-that-get-overridden)
  - [Prefix waits](#prefix-waits)
  - [Shared which-key prefixes](#shared-which-key-prefixes)
  - [What is not a problem](#what-is-not-a-problem)

---

## Why scope decides everything

Two plugins binding the same `lhs` is only a conflict if both bindings can be
reachable at the same time. Four scopes exist here, and only the first is
global:

| Scope | Meaning | Plugins |
| --- | --- | --- |
| **global** | set once in `setup()`, live in every buffer | buffer-ctx, emojis, fileops, gopath, insights (3 keys), language (1 key), lsp, pickers, recommender, reposcope (2 keys), spotlight, cascade *(opt-in)* |
| **filetype** | buffer-local via a `FileType` autocommand | images (markdown), markdown, cascade's list keys |
| **tree** | buffer-local to a file-tree buffer | filetree, pdfport |
| **UI** | buffer-local to the plugin's own float/picker/dashboard | cmdlog, diff, documentation, github_stats, insights' scratch, language's spell session, migrate, pickers' picker, reposcope's UI, sandbox, sessions' picker, recommender's float, replacer, runtime-analysis |

A UI-scope key never collides with anything: the buffer it lives in exists for
one purpose and disappears again. That is why `q`, `<CR>`, `D`, `R` and friends
recur across a dozen plugins without a single real conflict.

## The global set

Everything that is live in an ordinary buffer, by owner:

| Plugin | Keys |
| --- | --- |
| buffer-ctx.nvim | `<leader>cnl` `<leader>cnm` `<leader>cnf` `<S-m>` `<C-p>` |
| emojis.nvim | `<C-e>` (n,i) `<leader>ee` `<leader>et` (n,x) `<leader>ec` `<leader>el` |
| fileops.nvim | `<leader>nf` `<leader>pf` `<leader>nfn` `<leader>pfn` `<leader>nF` `<leader>pF` `<leader>NF` `<leader>PF` `<leader>dcf` |
| gopath.nvim | `gP` `g\|` `g\` `g}` `gM` `gY` `g?` `gC` `<leader>pp` (n,v) |
| insights.nvim | `<leader>fi` `<leader>ps` `<leader>pS` |
| language.nvim | `<leader>ss` |
| lsp.nvim | 42 keys — the `ls*` family, `gr*`, `]d`/`[d`, `]q`/`[q`, `]l`/`[l`, `]w`/`[w`, `<leader>x*`, `<leader>f*`, `<leader>t*`, `<leader>d*`, `<leader>w*`, `<leader>rn`, `<leader>lb`, `<leader>lsp`, `<M-s>` (i) |
| pickers.nvim | `<leader>dp` `<leader>fb` `<leader>fc` `<leader>gc` `<leader>li` |
| recommender.nvim | `<leader>lr` `<leader>lR` `<leader>lrr` `<leader>lrt` `<leader>lrj` `<leader>lrp` `<leader>lrh` `<leader>lrc` |
| reposcope.nvim | `<leader>rs` `<leader>rc` |
| spotlight.nvim | `<leader>sk` (n,x) `<leader>sK` (n,x) `<leader>sL` `<leader>sC` `<leader>sq` `<leader>sW` `]k` `[k` |
| cascade.nvim *(only with `keymaps.preset = true`, default `false`)* | `<C-y>` `<C-x>` `+` `-` `<C-M-y>` `<C-M-x>` `<leader>cp` `<leader>cR` (x) `<A-Right>` `<A-Left>` `<A-Up>` `<A-Down>` `<leader><A-Right>` `<leader><A-Left>` `<leader><Right>` `<leader><Left>` `<leader><C-Right>` `<leader><C-Left>` |

**sessions.nvim binds nothing.** `keymaps = false` is the default; its README
suggests `<leader>ssa` / `<leader>slo` / `<leader>sli` as example values, which
matters below.

### Free `<leader>t…` keys

The complement of the table above for the one prefix that keeps coming up in
relocation questions. Checked against nvim-config, the NvChad defaults and
every repo under `$REPOS_DIR`, then verified a second time against a running
session:

```
free:   ta  td  ti  tj  tk  tm  tu  ty  tz
taken:  tB  tH  tb  tft th  tl  tq  tr  tt
```

`tb` went to lsp.nvim's lightbulb after the first pass, which is why the list
is worth re-checking rather than trusting: `:Bindings check` does not police
free keys, only documented ones.

## Exact duplicates

**None between plugins.** No two plugins claim the same `lhs` in the same
scope and mode. That axis is plugin-vs-plugin only — the keys this config
registers in its own Lua live in [nvim-config.md](./nvim-config.md) and are
covered one section down, where there *were* two.

That is a real result, not an absence of evidence: the global set above is 100
mappings across twelve plugins, and the per-plugin prefixes (`cn`, `e`, `n`/`p`,
`g`, `f`/`p`, `x`/`ls`, `d`/`f`/`g`/`l`, `lr`, `r`, `s`) were evidently chosen
against each other rather than in isolation.

## Config vs. plugin (resolved 2026-08-30)

The section above compares plugins with each other. This config's own 40 keys
are a third owner, and cascade.nvim's opt-in preset landed on two of them:

| lhs | Config owner | cascade owner | What actually happened |
| --- | --- | --- | --- |
| `<leader>cp` | `mappings/custom.lua:12` — copy the current file path (global) | `cycle_pick` (global preset) | Exact duplicate. `bindings.mappings` runs in the **UIReady** phase, i.e. *after* cascade's `VeryLazy` setup, so custom.lua's overwrote cascade's. The config's key worked; cascade's picker was silently unreachable |
| `<leader>cs` | `mappings/custom.lua:22` — save a casedesk session (global) | `sort`, list surface (buffer-local) | Cross-scope. cascade's buffer-local key wins inside `lists.filetypes` (markdown, markdown.mdx, text, tex, norg) — exactly where casedesk notes live, so it was *session save* that went missing, in the only buffers it mattered |

Both are resolved in the cascade spec in
[`lua/plugins/personal/init.lua`](../../../../../lua/plugins/personal/init.lua),
by moving cascade rather than the config — the two config keys are
long-standing muscle memory, and `keymaps.globals` / `keymaps.list` exist for
exactly this:

```lua
keymaps = {
  preset  = true,
  globals = { cycle_pick = "<leader>cP" },
  list    = { sort = "<leader>cS" },
},
```

The `<leader>cp` case is the same load-order trap as the `ctrl_cycle`
regression in the changelog of [cascade.nvim.md](./cascade.nvim.md): anything
registered in the UIReady mappings phase silently outranks a plugin that set
its keys at `VeryLazy`. Worth checking first whenever a plugin key "does
nothing".

## Cross-scope shadowing

Four cases where a buffer-local mapping covers a global one. None is a bug —
the local one is what you want in that buffer — but each is a surprise if you
hit it without knowing:

| lhs | Global owner | Local owner | Where the local one wins |
| --- | --- | --- | --- |
| `<leader>ps` | insights.nvim — symbol picker (telescope) | pdfport.nvim — open with system application | Inside a file-tree buffer (netrw / oil / nvim-tree / neo-tree), where pdfport installs its buffer-local keys |
| `gP` | gopath.nvim — resolve path under cursor, open here | filetree.nvim — create PDF(s) from the node via pdfport | Inside the tree window |
| `+` / `-` | cascade.nvim — increment/decrement *(opt-in preset)* | filetree.nvim — set node as root / go to parent | Inside the tree window |
| `<leader>th` | lsp.nvim — toggle inlay hints globally | filetree.nvim — show trash history | Inside the tree window, **`filesystem` source only** (since 2026-09-02) |

The pattern is the same for the first three: a plugin that operates on the
*thing under the cursor in a tree* takes a key a plugin that operates on the
*thing under the cursor in a file* already owns. In the tree there is no file
to act on, so nothing is lost.

`<leader>th` is the one row where that reading does not hold, and it is worth
the extra paragraph because it has now been investigated twice. lsp.nvim's is a
**global** toggle, not an action on the node under the cursor, so inside the
tree it is genuinely unreachable rather than merely pointless. Leave the tree,
or use `<leader>tH` for the current filetype.

Measured 2026-09-02, both directions: `nvim_get_keymap("n")` returns **exactly
one** `<leader>th` — lsp.nvim's, from
`lsp.nvim/lua/lsp/bindings/actions.lua:192` — and `nvim_buf_get_keymap` on an
open neo-tree buffer returns exactly one, `filetree: show trash history`.
filetree binds it through its own tree-attach dispatcher, not through
`window.mappings`, which is why the key is absent from
`require("neo-tree").config.filesystem.window.mappings`.

**Two further owners are commonly assumed and are not real:**

* **NvChad** does bind `<leader>th` to its theme picker
  (`NvChad/lua/nvchad/mappings.lua:67`, `require("nvchad.themes").open()`), but
  **this config never requires that module** — `package.loaded["nvchad.mappings"]`
  is `false` after a full start. `wkdnvchad.mappings.setup({ all = true })` is a
  different module and sets only `<Tab>`, `<S-Tab>`, `<leader>bc`,
  `<leader>tr`, `<leader>tl` and `<leader>tt`.
* **language.nvim**'s thesaurus ships `keymap = false`
  (`config/DEFAULTS.lua:117`, marked opt-in), so it binds nothing. The
  `3<leader>th` in `thesaurus/init.lua:145` is a comment describing how a count
  *would* act, not a registration.

**Resolved on the filetree side, 2026-09-02** (filetree.nvim `71eaa54`). Until
then the key was bound in every neo-tree source, because neo-tree draws all
five of them through one `neo-tree` filetype and filetree's tree-attach
dispatcher had no finer distinction available. It now consults
`lua/filetree/sources.lua`, which restricts `trash` (`d`, `U`, `<leader>th`) to
the `filesystem` source — so in a diagnostics list or a symbol outline the key
is not bound at all and lsp.nvim's global toggle comes through.

That list is read by both paths that put a key into a tree — the dispatcher
that binds it and the `window.mappings` injection that describes it in `?` — so
the two cannot come to disagree.

The config used to defend itself here with
`config/neotree/keymaps/{diagnostics,document_symbols}.lua` mapping the key to
`noop` alongside the other filesystem-mutating keys. Two things were wrong with
that, and both are gone with the noop:

* It did not work. `attach.inject` runs *after* `neo-tree.setup()` and writes
  into the already-merged config, so filetree's entry was the last word and the
  explicit "no filesystem operations in this tree" lost to load order.
* A `noop` is a buffer-local mapping to nothing, so even where it did win it
  swallowed lsp.nvim's global toggle rather than letting it through — the key
  did nothing at all in the tree built out of LSP data.

`<2-LeftMouse>` deserves a mention on its own: **images.nvim** and
**markdown.nvim** both bind it, both buffer-locally on markdown filetypes, and
whichever attaches last wins. images.nvim opens the image under the cursor;
markdown.nvim's `cursor_action_mouse` opens whatever is under the cursor —
anchor, image, URL or file — and falls back to a fold toggle on a heading.
markdown's is the superset, and it delegates image opening onward, so the
overlap is by design rather than a race worth fixing. Set
`keymaps.double_click = false` in images.nvim if you want it settled explicitly.

## Builtins that get overridden

Three global mappings take a key Neovim already uses. All three are
deliberate — they are noted here because "my `M` stopped working" is not
something anyone traces back to a copy-path plugin:

| lhs | Builtin it replaces | New owner |
| --- | --- | --- |
| `<S-m>` | `M` — move the cursor to the middle line of the window | buffer-ctx.nvim — toggle mark on the current line |
| `<C-e>` | scroll the window one line down | emojis.nvim — insert-picker (normal **and** insert mode) |
| `+` / `-` | move to the first non-blank of the next/previous line | cascade.nvim — increment/decrement *(opt-in; falls back to the native meaning when the token under the cursor is not cycleable)* |

cascade is the well-behaved one of the three: its `+`/`-` re-emit the native
behaviour when there is nothing to cycle, so the builtin is not lost, only
shared. `<S-m>` and `<C-e>` replace theirs outright.

lsp.nvim's `grn` / `grt` are a fourth case with a twist: Neovim 0.11 binds those
itself, buffer-locally, on `LspAttach` — and buffer-local beats global, so the
catalogue's version would be shadowed exactly in the buffers it is meant for.
`bindings/autocmds.lua` re-binds them buffer-locally on `LspAttach` for that
reason. Harmless while both call `vim.lsp.buf.rename`; load-bearing as soon as
`rename.provider` selects inc-rename.

## Bracket-pair motions (`[x` / `]x`)

Taken, as of Neovim 0.12 + this config's plugins — verified by asking the
running editor, not by grepping source (an unknown node name does not degrade,
it fails the whole query; a grep for a mapping misses buffer-local and
default ones):

| Owner | Pairs |
| --- | --- |
| Neovim (`vim/_core/defaults.lua`) | `[a ]a` `[A ]A` `[b ]b` `[B ]B` `[t ]t` `[T ]T` `[L ]L` `[Q ]Q` |
| lsp.nvim | `[d ]d` `[D ]D` `[l ]l` `[q ]q` `[w ]w` |
| snacks.nvim (scope motion) | `[s ]s` |
| this config (`bindings/mappings/treesitter_structure.lua`) | `[u ]u` — climb to head/end of the enclosing structure |

`[u ]u` was `[b ]b` for about an hour on the strength of a grep that found
nothing — but `[b ]b` is a Neovim 0.12 default (buffer nav), so the grep was
the wrong instrument. Free letters left in this space are scarce; check here
before taking a new pair.

## Prefix waits

A mapping that is also the prefix of a longer one makes Neovim wait
`timeoutlen` (default 1000 ms) before firing the short one. Four exist, three
of them inside a single plugin:

| Short map | Longer maps under it | Owner |
| --- | --- | --- |
| `<leader>lr` | `<leader>lrr` `<leader>lrt` `<leader>lrj` `<leader>lrp` `<leader>lrh` `<leader>lrc` | recommender.nvim (all its own) |
| `<leader>nf` | `<leader>nfn` | fileops.nvim (its own) |
| `<leader>pf` | `<leader>pfn` | fileops.nvim (its own) |
| `<leader>xl` | `<leader>xld` `<leader>xli` `<leader>xlr` `<leader>xls` `<leader>xlt` | lsp.nvim (its own) |

The fifth is **cross-plugin and latent**:

> **`<leader>ss`** is language.nvim's spell-session toggle, and sessions.nvim's
> README suggests `<leader>ssa` (save) and `<leader>sst` (save-timestamp) as
> example keymap values. Adopt those examples verbatim and `<leader>ss` starts
> waiting a full second before it toggles spell. sessions.nvim binds nothing by
> default, so this is dormant — but it is the one collision that arrives by
> following the documentation.

lsp.nvim's prefix-less three-character maps (`lsd`, `lsr`, `lsi`, `lss`, `lsD`,
`lst`, `lsa`) are the inverse case and are documented in its own
`docs/BINDINGS.md`: they do not wait themselves, but every normal-mode input
starting with `l` waits `timeoutlen` while Neovim looks for the continuation.
That is the price of the prefix-less family, and it is paid on the most common
motion key in the set.

## Shared which-key prefixes

Three leader prefixes have more than one owner, and each has exactly one plugin
that registers a group **label** for it. The label is therefore wrong for the
other owners' keys — cosmetic, but it makes which-key claim things it should
not:

| Prefix | Registers the label | Also owns keys there |
| --- | --- | --- |
| `<leader>s` | sessions.nvim ("Session") | spotlight.nvim (`sk` `sK` `sL` `sC` `sq` `sW`), language.nvim (`ss`), filetree.nvim (`sm`, tree-local) |
| `<leader>c` | cascade.nvim ("Cascade") | buffer-ctx.nvim (`cnl` `cnm` `cnf`) |
| `<leader>p` | fileops.nvim (`<leader>p` "prev file") | gopath.nvim (`pp`), insights.nvim (`ps` `pS`), pdfport.nvim (`po` `pt` `ps` `pi` `pb`, tree-local) |

sessions.nvim's own comment says the label is written so it "doesn't clobber
unrelated `<leader>s…` mappings" — worth keeping in mind if the other two ever
get tightened the same way.

## Commented-out slots that would collide if activated

`plugins/snacks.lua` carries a near-complete alphabet of commented-out
`snacks.picker.*` bindings under `<leader>s`. Not a live conflict — nothing
here fires today — but three land exactly on spotlight.nvim's letters:
`<leader>sk` (`snacks.picker.keymaps()`), `<leader>sq`
(`snacks.picker.qflist()`), `<leader>sC` (`snacks.picker.commands()`).
Uncommenting any of them later silently shadows the matching spotlight.nvim
action (last `vim.keymap.set` wins) — pick different letters for those three
if that block is ever finished, rather than reworking spotlight's scheme
again.

## What is not a problem

Recorded so the next audit does not re-derive it:

- **Repeated UI keys.** `q`, `<Esc>`, `<CR>`, `j`/`k`, `D`, `R`, `r`, `s`, `?`
  appear in cmdlog, documentation, github_stats, recommender, reposcope,
  sandbox and diff. Every one is buffer-local to a float that plugin opened.
- **`<C-p>` in four places.** buffer-ctx (global), markdown (markdown buffers),
  pickers (inside the picker), filetree (inside the tree). Only the first is
  global; the other three are each unreachable from the others' buffers.
- **`<C-c>` twice inside filetree.** `filter.keymap_clear` and
  `copy_move.keymaps.clear` both default to it; last registered wins. Known,
  documented in that repo, left as a config decision rather than silently
  renamed.
- **`gp` twice.** insights (scratch buffer) and filetree (tree window). Neither
  is global.
- **cascade's whole preset.** `keymaps.preset` defaults to `false`, so none of
  its sixteen global keys are live unless asked for.
