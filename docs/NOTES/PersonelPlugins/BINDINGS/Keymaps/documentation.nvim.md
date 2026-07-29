# documentation.nvim — Keymaps Cheatsheet

Source: `lua/documentation/editor/browse/init.lua` (the `KEYS` table)
Override rule: `lua/documentation/bindings/keymaps.lua`
Cross-reference: the repo's own `docs/BINDINGS.md` — **generated** from the same
table, so it cannot drift from this.

## Scope — no global keymaps at all

`documentation.nvim` sets **zero** global keymaps. Every binding below is
buffer-local to the `:DocBrowse` scratch buffer and set with `nowait`. Nothing
is mapped until `:DocBrowse` mounts, and it goes away with the float.

That is what makes the collision table at the bottom a non-issue rather than a
problem: a key can only shadow something *inside* that buffer.

## Modes

`1`…`6` switch the list: `structure`, `deps`, `calls`, `types`, `history`,
`trail`. Positional and deliberately **not** rebindable — `3` means "the third
list", so renumbering them individually would desynchronise them from the
status line.

## Keys

| Keys | Action id | Modes | Does |
| --- | --- | --- | --- |
| `j` `k` | `move` | all | move; the detail pane follows. **Left native** — not bound, so counts and `scrolloff` behave. A `CursorMoved` autocmd drives the detail pane instead. |
| `<CR>` | `enter` | all | descend a level, or follow the edge |
| `-` `<BS>` | `up` | all | up a level |
| `<C-o>` | `back` | all | back through the visit history |
| `<C-i>` | `forward` | all | forward through the visit history |
| `h` | `dir_in` | deps, calls | direction: incoming edges |
| `l` | `dir_out` | deps, calls | direction: outgoing edges |
| `+` | `depth_inc` | deps | depth +1 |
| `_` | `depth_dec` | deps | depth −1 |
| `gd` | `goto_source` | all | open the source at the line (closes) |
| `gq` | `quickfix` | all | current list → quickfix (closes) |
| `gI` | `impact` | all | blast radius → quickfix (closes) |
| `gO` | `open_page` | all | open the generated HTML page |
| `gD` | `commit_diff` | history | the opened commit's diff |
| `p` | `pin` | all | pin / unpin the entry under the cursor |
| `d` | `unpin` | trail | unpin |
| `S` | `trail_save` | trail | save this trail under a name |
| `L` | `trail_load` | trail | load a saved trail (**adds** to the current one) |
| `X` | `trail_delete` | trail | forget a saved trail |
| `f` | `filter` | all | filter this list in place (`-negate`, `"phrase"`; empty clears) |
| `/` | `search` | all | fuzzy jump across modules and functions |
| `?` | `help` | all | the cheatsheet overlay |
| `q` `<Esc>` | `close` | all | close |

Keys the current mode ignores are **marked**, not hidden, in the `?` overlay —
"why did `+` do nothing" is precisely the question it is opened to answer.

## User-configurable

```lua
opts = {
  keys = {
    quickfix = "gQ",              -- string: one replacement key
    filter   = { "F", "<C-f>" },  -- list: several
    pin      = false,             -- false: off entirely
  },
  which_key = true,               -- default; no-op when which-key is absent
}
```

Keyed by **action id**, not by the default lhs, so a rebinding survives a change
of defaults. A disabled action still appears in the `?` overlay marked
`(disabled)`. An unknown action id is reported, not silently ignored.

## Collision check vs. the other personal plugins (2026-07-28)

Run against every `Keymaps/*.md` in this folder. Nominal overlaps exist and are
**all benign**, because both sides are buffer-local to their own scratch/float
buffers:

| Key | Also used by |
| --- | --- |
| `j` `k` `h` `l` | github_stats, pickers, recommender, sandbox, dap |
| `<CR>` | cascade, filetree, github_stats, language, lib, markdown, migrate, cmdlog, recommender, replacer, reposcope, sandbox |
| `q` `<Esc>` `?` `/` | most list/float UIs in this set |
| `-` `+` | cascade, filetree, language, pickers, recommender |
| `<BS>` | github_stats, recommender, reposcope |
| `<C-o>` | pickers |
| `gd` | insights |
| `p` `d` `f` | filetree, sandbox, github_stats |
| `L` `X` | dap, sandbox |

**No action needed.** documentation.nvim installs nothing globally, so none of
these can shadow anything outside `:DocBrowse`. The only genuinely global
surface this plugin has is its two command *names* — see the Usercmds sheet.
