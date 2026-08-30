# nvim-config — Keymaps Cheatsheet

Source: `lua/bindings/mappings/*.lua`, each module's own `M.setup()`, all
called from [`lua/bindings/mappings/init.lua`](../../../../../lua/bindings/mappings/init.lua)

**Not a plugin.** Every other file in this folder documents a plugin — this
one documents the keymaps *this configuration itself* registers in its own
Lua, owned by no plugin at all. It exists because `:Bindings check`'s source
axis (`drift.source_check`, reading `docs/map/module_map.json`) had no
cheatsheet to compare `lua/bindings/mappings/*` against, so all 40 of these
keys reported as "registered in this config's source, not documented" — the
axis was right, and this file is the answer.

The commands half lives in [`Usercmds/nvim-config.md`](../Usercmds/nvim-config.md).

Every mapping goes through `lib.nvim.bindings.keymap` (aliased `map` in each
module), which takes `vim.keymap.set`'s argument order. The `desc` column
below is the exact string handed to it — `drift.lua`'s `is_live` compares
both sides' desc verbatim when a row carries one, so these are copied, not
paraphrased, and a drift report stays meaningful only while they match.

## Buffers and windows (`buf_win_tab.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<leader>bn` | n | `:enew` | `[Buffers] New` | `buf_win_tab.lua` |
| `<leader>bx` | n | Close the current buffer and go to the next; terminal buffers go through `lib.delete_terminal_buf` instead of `nvim_buf_delete` | `[Buffers] Close current, go to next` | `buf_win_tab.lua` |
| `<leader>Q` | n | `:qa!` | `[Windows] Force quit all` | `buf_win_tab.lua` |
| `<leader>q` | n, v | `:close!` | `[Windows] Close window` | `buf_win_tab.lua` |
| `<leader>q` | i | Leave insert for one command, then `:close` | `[Windows] Close window (insert)` | `buf_win_tab.lua` |
| `<leader>q` | t | Leave terminal mode, then `:close` | `[Windows] Close window (terminal)` | `buf_win_tab.lua` |
| `<C-h>` | n | `<C-w>h` | `[Window] Jump left` | `buf_win_tab.lua` |
| `<C-l>` | n | `<C-w>l` | `[Window] Jump right` | `buf_win_tab.lua` |
| `<C-j>` | n | `<C-w>j` | `[Window] Jump down` | `buf_win_tab.lua` |
| `<C-k>` | n | `<C-w>k` | `[Window] Jump up` | `buf_win_tab.lua` |
| `<S-h>` | n, t | Narrow the window by 5 columns; a count scales the step, so `3<S-h>` narrows by 15 in one redraw | `[Window] Resize narrower` | `buf_win_tab.lua` |
| `<S-l>` | n, t | Widen by 5 columns, same count rule | `[Window] Resize wider` | `buf_win_tab.lua` |
| `<S-k>` | n, t | Grow by 5 rows, same count rule | `[Window] Resize taller` | `buf_win_tab.lua` |
| `<S-j>` | n, t | Shrink by 5 rows, same count rule | `[Window] Resize shorter` | `buf_win_tab.lua` |
| `<leader>zm` | n | Toggle window zoom (`bindings.mappings.utils.window_zoom`) | `[Window] Zoom toggle.` | `buf_win_tab.lua` |

The four resize keys are guarded (`lib.nvim.buf_win_tab.resize_guarded`):
inside a picker prompt, `neo-tree`, `Trouble`, a quickfix window, a terminal
or anything matching `.*lazygit.*` they fall through to the plain key instead
of resizing.

## Tabs (`buf_win_tab.lua`)

A count moves that many tab pages and wraps in both directions. The offset is
computed in Lua rather than handed to the Ex command, because every count
form of `:tabnext` is absolute — `:tabnext 2` is `2gt`, and `:tabnext +2` is
E475.

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<leader>tn` | n | Next tab page, wrapping | `[Tabs] Next tab` | `buf_win_tab.lua` |
| `<leader>tp` | n | Previous tab page, wrapping | `[Tabs] Previous tab` | `buf_win_tab.lua` |
| `<leader>tc` | n | `:tabnew` | `[Tabs] New tab` | `buf_win_tab.lua` |
| `<leader>tx` | n | `:tabclose` | `[Tabs] Close tab` | `buf_win_tab.lua` |

## Buffer jump by position (`buffer_jump.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<leader>1` | n | Jump to the 1st listed buffer | `[Buffers] Go to buffer 1` | `buffer_jump.lua` |
| `<leader>2` … `<leader>9` | n | The same for the 2nd … 9th; the desc counts along, e.g. `[Buffers] Go to buffer 7` | — | `buffer_jump.lua` |
| `<leader>0` | n | Jump to the 10th listed buffer — `0` continues the row on the keyboard, it is not a zero index | `[Buffers] Go to buffer 10` | `buffer_jump.lua` |

## Window orientation (`window_orientation.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<leader>wl` | n | `:wincmd H` — move this window to the left of a vertical split | `Move window to vertical split (left)` | `window_orientation.lua` |
| `<leader>wr` | n | `:wincmd L` — move it to the right | `Move window to vertical split (right)` | `window_orientation.lua` |
| `<leader>wh` | n | `:wincmd K` — move it to the top of a horizontal split | `Move window to horizontal split (top)` | `window_orientation.lua` |
| `<leader>wj` | n | `:wincmd J` — move it to the bottom | `Move window to horizontal split (bottom)` | `window_orientation.lua` |
| `<leader>wR` | n | `:wincmd R` — rotate the whole layout | `Rotate window layout` | `window_orientation.lua` |

`<leader>wR` is capital deliberately: `<leader>wr` four lines above is the
vertical-split-right move. It used to be `<leader>wo`, which `lsp.nvim`
claims for its workspace-diagnostics picker.

## Editor-wide, owned by no plugin (`general.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<C-a>` | n | `gg<S-v>G` — select the whole buffer | `[General] Select all` | `general.lua` |
| `<C-s>` | n, v, t | `:write`, restoring the cursor when formatting shortened the file | `[General] Save file` | `general.lua` |
| `<C-s>` | i | Same, bound separately and `noremap` because of `vim.lsp.buf.signature_help()` | `[General] Save file` | `general.lua` |
| `jk` | i, v, t | `<Esc>` | `[General] Exit to normal mode` | `general.lua` |
| `x` | n | Delete a character without touching a register | `[Edit] Delete char without yanking` | `general.lua` |
| `dw` | n | Delete the word *backwards*, no yank. Shadows builtin `dw`, which deletes forward | `[Edit] Delete word backwards without yanking` | `general.lua` |
| `<F1>` | n, i, v, t, c | `<Nop>` — disabled outright, so a mis-hit next to `<Esc>` does not open help | `[General] Disable F1` | `general.lua` |
| `<leader>date` | n | Insert today's date as `dd.mm.yyyy` at the cursor | `Datum einfügen` | `general.lua` |

## Editing overrides (`editing.lua`)

`p`/`P` are redefined config-wide: a paste trims leading and trailing blank
lines and edge whitespace off the register's content first (`put_trimmed`).
A count prefix is not special-cased and performs a single trimmed paste.

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<C-r>` | n | `g+` — redo along the undo *branch*, so a plugin's auto-change cannot strand a redo | `Redo (branch-aware)` | `editing.lua` |
| `<leader><CR>` | n | Open a blank line below, cursor stays put | `Insert blank line below` | `editing.lua` |
| `<CR>` | n | Split at column 0, i.e. push this line down | `Insert blank line` | `editing.lua` |
| `p` | n | Paste after the cursor, trimmed | `Paste after cursor (leading/trailing blank lines trimmed)` | `editing.lua` |
| `P` | n | Paste before the cursor, trimmed | `Paste before cursor (leading/trailing blank lines trimmed)` | `editing.lua` |
| `p` | x | Replace the selection, trimmed, without the selection landing in the yank register | `Paste over selection, trimmed, without yanking it` | `editing.lua` |
| `<C-A-S-p>` | i | Insert the system clipboard literally, no auto-indent doubling | `Aus System-Zwischenablage im Insert-Modus einfügen` | `editing.lua` |

`<C-A-S-p>` needs a terminal that can encode the chord. If it never fires,
the terminal or GUI is swallowing it — the mapping itself is unconditional.

## Screen-line movement (`screen_line.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<C-S-k>` | n, v | `gk` — up one *screen* row through soft-wrapped text | `Move up by screen line (through wrapped text)` | `screen_line.lua` |
| `<C-S-j>` | n, v | `gj` — down one screen row | `Move down by screen line (through wrapped text)` | `screen_line.lua` |

Requires a terminal that distinguishes Ctrl+Shift from plain Ctrl (Kitty
keyboard protocol or CSI-u). Where it does not, the terminal sends the plain
`<C-k>`/`<C-j>` keycode and the window-jump mapping above wins — this one
simply never fires. `<M-k>`/`<M-j>` is free and is the portable fallback.

## Smart Del (`smart_del_key.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<Del>` | n | On a blank line, delete the whole line through the buffer API with no register touched; otherwise delete one character into the black hole | `Smart delete (<Del>)` | `smart_del_key.lua` |

## Terminal mode (`terminal.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<Esc>` | t | Leave terminal mode | `[Terminal] Exit terminal mode` | `terminal.lua` |
| `<C-c>` | t | Leave terminal mode, second binding | `[Terminal] Exit terminal mode` | `terminal.lua` |
| `<C-h>` | t | Window left from inside a terminal buffer | `[Terminal] Left` | `terminal.lua` |
| `<C-l>` | t | Window right | `[Terminal] Right` | `terminal.lua` |
| `<C-j>` | t | Window down | `[Terminal] Down` | `terminal.lua` |
| `<C-k>` | t | Window up | `[Terminal] Up` | `terminal.lua` |
| `<A-h>` | n, t | Toggle NvChad's floating terminal (`floatTerm`); no-op when `nvchad.term` is absent | `[Term] Toggle floating` | `terminal.lua` |

The `<C-j>` desc used to read `[Terminal Down`, with the bracket left open.
It was reproduced verbatim here at first, because `is_live` compares this
column against the live string and a "fixed" copy would have reported the key
as missing. `terminal.lua` is corrected as of 2026-08-30, so both sides now
say `[Terminal] Down`.

## Against NvChad's own features (`nvchad.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<Esc>` | n | Clear a Copilot NES overlay if one is up, else `:noh` | `Clear copilot NES overlays or nohl` | `nvchad.lua` |
| `<C-c>` | n | Whole file to the system clipboard | `[General] Copy whole file` | `nvchad.lua` |
| `<leader>nvt` | n | NvChad theme switcher (`nvchad.themes`, compact, borderless) | `[nvchad] Themes switcher` | `nvchad.lua` |
| `<leader>fm` | n, x | Format via `conform`, `lsp_fallback`, 3 s timeout | `[General] Format file` | `nvchad.lua` |
| `<leader>wK` | n | `:WhichKey` with no argument — the full table | `[General] WhichKey (all)` | `nvchad.lua` |
| `<leader>wk` | n | Prompt (`lib.nvim.ui.kit.input`) for a prefix, then `:WhichKey <prefix>` | `[General] WhichKey query` | `nvchad.lua` |
| `<C-h>` | i | `<Left>` | `[Text] Left` | `nvchad.lua` |
| `<C-l>` | i | `<Right>` | `[Text] Right` | `nvchad.lua` |
| `<C-j>` | i | `<Down>` | `[Text] Down` | `nvchad.lua` |
| `<C-k>` | i | `<Up>` | `[Text] Up` | `nvchad.lua` |

## Context open (`context_open.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<M-o>` | n | Open whatever is under the cursor (`bindings.usrcmds.context_open`) | `[Open] Open whatever is under the cursor` | `context_open.lua` |
| `<M-O>` | n | List every openable target in the buffer instead of acting on one | `[Open] List every openable target in the buffer` | `context_open.lua` |

## fzf-lua pickers (`fzf.lua`)

The fzf-lua entry points this config binds directly. The `<leader>ff` /
`<leader>fb` family belongs to `pickers.nvim` and is documented on that
plugin's own sheet — those collisions are why two keys here have the shape
they do.

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<leader>fth` | n | `:FzfLua colorschemes` | `[FzfLua] Colorschemes` | `fzf.lua` |
| `<leader>fK` | n | `:FzfLua keymaps` | `[FzfLua] Keymaps` | `fzf.lua` |
| `<leader>fgs` | n | `:FzfLua git_status` | `[FzfLua] Git Status` | `fzf.lua` |
| `<leader>fq` | n | `:FzfLua quickfix` | `[Quickfix] Quickfix` | `fzf.lua` |
| `<leader>man` | n | `:FzfLua man_pages` | `[FzfLua] Man Pages` | `fzf.lua` |
| `<leader>fg` | n | `:FzfLua live_grep` | `[FzfLua] Live Grep` | `fzf.lua` |
| `<leader>fB` | n | `:FzfLua grep_curbuf` | `[FzfLua] Grep current buffer` | `fzf.lua` |
| `<leader>fzf` | n | `:FzfLua files` | `[FzfLua] Files` | `fzf.lua` |
| `<leader>ftf` | n | `:FzfLua treesitter` | `[FzfLua] Search Tree-sitter symbols` | `fzf.lua` |
| `<leader>fws` | n | `fzf-lua.lsp_workspace_symbols()` | `[FzfLua] Search workspace symbols (LSP)` | `fzf.lua` |

Two were renamed away from collisions and the old names are gone:
`<leader>fK` was `<leader>ffk`, a prefix of `pickers.nvim`'s `<leader>ff`,
which made every `<leader>ff` press wait out `timeoutlen`; `<leader>fB` was
`<leader>fb`, which `pickers.nvim`'s `keymaps.folder_files` owns now. The
LSP-flavoured entries that used to live here (`<leader>do`, `<leader>dos`,
`<leader>wo`, `<leader>wos`) moved into `lsp.nvim`'s keymap catalogue.

## which-key

**Checked, and there is none for these prefixes.** This config registers no
which-key group for its own `<leader>b` / `<leader>t` / `<leader>w` /
`<leader>f` prefixes — the only which-key references in `lua/` are
`<leader>wK` / `<leader>wk` above (which *open* which-key), `harpoon.lua`,
and `config/neotest/whichkey/`. Any group label appearing under these
prefixes therefore comes from whichever plugin registered it, not from here.

## Notes

- **Scope.** Only `lua/bindings/mappings/*`, i.e. the modules
  `bindings/mappings/init.lua` calls. Keymaps registered inside
  `lua/config/<plugin>/` belong to that plugin and live on its own sheet,
  Personal or Extern.
- **Shadowed builtins**, listed so a surprise is findable: `x`, `dw`, `p`,
  `P`, `<CR>`, `<C-r>`, `<C-a>`, `<Del>` and `<F1>` all replace a Vim
  default. `<F1>` is the only one mapped to `<Nop>`; the rest change
  behaviour rather than removing it.
- **`<C-h/j/k/l>` is bound three times**, in three disjoint modes, and that
  is deliberate: normal-mode window jump (`buf_win_tab.lua`), terminal-mode
  window jump (`terminal.lua`), insert-mode cursor move (`nvchad.lua`).
- `<C-l>` was once mapped twice in `terminal.lua` — window-right and a
  `clear`/`cls` send — eleven lines apart, and the second silently won. Only
  the window movement is left; the shell's own `clear` does the other job.

## Changelog

- 2026-08-30 (2): `terminal.lua`'s `<C-j>` desc lost its closing bracket
  (`[Terminal Down`); fixed at the source, and this sheet follows it.
- 2026-08-30: created. Closes the `keymap-undocumented` findings that
  `:Bindings check`'s source axis raised for `lua/bindings/mappings/*`, which
  had never had a cheatsheet to be compared against.
