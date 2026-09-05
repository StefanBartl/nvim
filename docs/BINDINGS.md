# nvim-config — Binding Cheatsheet

Every keymap, user command and autocommand this configuration registers in
its own Lua — owned by no plugin. Every personal plugin carries the same
kind of page as its own `docs/BINDINGS.md`; this is that page for the config
itself, read by `bindings_explorer` the same way (see
[`lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md`](../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md)).

This file exists because `:Bindings check`'s source axis
(`drift.source_check`, reading `docs/map/module_map.json`) had nothing to
compare `lua/bindings/mappings/*`, `lua/autocmds/**` and this config's own
user commands against — every one of them reported as "registered in
source, not documented" until this page existed.

## Table of contents

- [Keymaps](#keymaps)
- [User commands](#user-commands)
- [Autocommands](#autocommands)

---

## Keymaps

Source: `lua/bindings/mappings/*.lua`, each module's own `M.setup()`, all
called from [`lua/bindings/mappings/init.lua`](../lua/bindings/mappings/init.lua).

Every mapping goes through `lib.nvim.bindings.keymap` (aliased `map` in each
module), which takes `vim.keymap.set`'s argument order. The `desc` column
below is the exact string handed to it — `drift.lua`'s `is_live` compares
both sides' desc verbatim when a row carries one, so these are copied, not
paraphrased, and a drift report stays meaningful only while they match.

### Buffers and windows (`buf_win_tab.lua`)

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

### Tabs (`buf_win_tab.lua`)

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

### Buffer jump by position (`buffer_jump.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<leader>1` | n | Jump to the 1st listed buffer | `[Buffers] Go to buffer 1` | `buffer_jump.lua` |
| `<leader>2` … `<leader>9` | n | The same for the 2nd … 9th; the desc counts along, e.g. `[Buffers] Go to buffer 7` | — | `buffer_jump.lua` |
| `<leader>0` | n | Jump to the 10th listed buffer — `0` continues the row on the keyboard, it is not a zero index | `[Buffers] Go to buffer 10` | `buffer_jump.lua` |

### Window orientation (`window_orientation.lua`)

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

Only two of the five moves have a command counterpart (`:WinVertical`,
`:WinHorizontal` — see [User commands](#editor-and-window-layout)); the
right, bottom and rotate variants are keymap-only.

### Editor-wide, owned by no plugin (`general.lua`)

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

### Editing overrides (`editing.lua`)

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

### Screen-line movement (`screen_line.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<C-S-k>` | n, v | `gk` — up one *screen* row through soft-wrapped text | `Move up by screen line (through wrapped text)` | `screen_line.lua` |
| `<C-S-j>` | n, v | `gj` — down one screen row | `Move down by screen line (through wrapped text)` | `screen_line.lua` |

Requires a terminal that distinguishes Ctrl+Shift from plain Ctrl (Kitty
keyboard protocol or CSI-u). Where it does not, the terminal sends the plain
`<C-k>`/`<C-j>` keycode and the window-jump mapping above wins — this one
simply never fires. `<M-k>`/`<M-j>` is free and is the portable fallback.

### Structure movement (`treesitter_structure.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `[u` | n, x, o | Jump to the head of the structure the cursor is inside; repeat to climb a level further out | `Jump to the head of the enclosing structure (repeatable)` | `treesitter_structure.lua` |
| `]u` | n, x, o | The same downward, to the closing end | `Jump to the end of the enclosing structure (repeatable)` | `treesitter_structure.lua` |

Built as a Treesitter motion via `nvim-treesitter-textobjects` — the plugin
was installed (`plugins/treesitter.lua`, `lazy = false`) and used nowhere
until this. One query line per language in
`after/queries/<lang>/textobjects.scm`, extending the shipped `@block.outer`
capture (`(_ (block)) @block.outer`) rather than introducing a new one.
Covers lua, json, python, rust, toml, yaml — each node name read off the
real grammar; block languages (go, c, typescript, …) work for their blocks
without their own file.

**On key choice.** It was first `[b`/`]b`, based on a grep over `lua/` that
found nothing free — the wrong tool: `[b ]b [B ]B` are **Neovim's own 0.12
defaults** for buffer navigation (`vim/_core/defaults.lua`), so they never
show up in any config file and were never actually free. Found only by
asking the running editor (`maparg().desc` said `:bprevious`) rather than
the sources — a bare `maparg() ~= nil` test would not have shown it either,
since Neovim's default is itself a Lua callback. Confirmed taken (measured
live): `[a ]a [A ]A [b ]b [B ]B [t ]t [T ]T [L ]L [Q ]Q` (Neovim), `[d ]d [D ]D
[l ]l [q ]q [w ]w` (lsp.nvim), `[s ]s` (snacks.nvim's scope movement). `[u`/`]u`
was free — `u` for "up and out".

Two independent off switches: `["nvim-treesitter-textobjects"] = "disabled"`
in `plugins/treesitter.lua`'s `modes` table disables the whole plugin (binds
nothing, rather than binding keys that would complain when pressed);
`setup({ enable = false })` in `bindings/mappings/init.lua`, or
`setup({ keys = { up = …, down = … } })`, disables or moves just these keys.

### Smart Del (`smart_del_key.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<Del>` | n | On a blank line, delete the whole line through the buffer API with no register touched; otherwise delete one character into the black hole | `Smart delete (<Del>)` | `smart_del_key.lua` |

### Terminal mode (`terminal.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<Esc>` | t | Leave terminal mode | `[Terminal] Exit terminal mode` | `terminal.lua` |
| `<C-c>` | t | Leave terminal mode, second binding | `[Terminal] Exit terminal mode` | `terminal.lua` |
| `<C-h>` | t | Window left from inside a terminal buffer | `[Terminal] Left` | `terminal.lua` |
| `<C-l>` | t | Window right | `[Terminal] Right` | `terminal.lua` |
| `<C-j>` | t | Window down | `[Terminal] Down` | `terminal.lua` |
| `<C-k>` | t | Window up | `[Terminal] Up` | `terminal.lua` |
| `<A-h>` | n, t | Toggle NvChad's floating terminal (`floatTerm`); no-op when `nvchad.term` is absent | `[Term] Toggle floating` | `terminal.lua` |

`<C-l>` was once mapped twice in `terminal.lua` — window-right and a
`clear`/`cls` send — eleven lines apart, and the second silently won. Only
the window movement is left; the shell's own `clear` does the other job.

### Against NvChad's own features (`nvchad.lua`)

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

### Context open (`context_open.lua`)

| Key | Mode | Effect | desc | Source |
| --- | --- | --- | --- | --- |
| `<M-o>` | n | Open whatever is under the cursor (`bindings.usrcmds.context_open`) | `[Open] Open whatever is under the cursor` | `context_open.lua` |
| `<M-O>` | n | List every openable target in the buffer instead of acting on one | `[Open] List every openable target in the buffer` | `context_open.lua` |

Full implementation notes: [`lua/bindings/usrcmds/context_open/README.md`](../lua/bindings/usrcmds/context_open/README.md).

### fzf-lua pickers (`fzf.lua`)

The fzf-lua entry points this config binds directly. The `<leader>ff` /
`<leader>fb` family belongs to `pickers.nvim` and is documented on that
plugin's own `docs/BINDINGS.md` — those collisions are why two keys here
have the shape they do.

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

### which-key

**Checked, and there is none for these prefixes.** This config registers no
which-key group for its own `<leader>b` / `<leader>t` / `<leader>w` /
`<leader>f` prefixes — the only which-key references in `lua/` are
`<leader>wK` / `<leader>wk` above (which *open* which-key), `harpoon.lua`,
and `config/neotest/whichkey/`. Any group label appearing under these
prefixes therefore comes from whichever plugin registered it, not from here.

### Keymap notes

- **Scope.** Only `lua/bindings/mappings/*`, i.e. the modules
  `bindings/mappings/init.lua` calls. Keymaps registered inside
  `lua/config/<plugin>/` belong to that plugin and live on its own sheet.
- **Shadowed builtins**, listed so a surprise is findable: `x`, `dw`, `p`,
  `P`, `<CR>`, `<C-r>`, `<C-a>`, `<Del>` and `<F1>` all replace a Vim
  default. `<F1>` is the only one mapped to `<Nop>`; the rest change
  behaviour rather than removing it.
- **`<C-h/j/k/l>` is bound three times**, in three disjoint modes, and that
  is deliberate: normal-mode window jump (`buf_win_tab.lua`), terminal-mode
  window jump (`terminal.lua`), insert-mode cursor move (`nvchad.lua`).

See [`docs/NOTES/CrossPlugin/Keymaps-Collisions.md`](NOTES/CrossPlugin/Keymaps-Collisions.md)
for how these interact with every personal plugin's own keymaps.

---

## User commands

Sources: `lua/bindings/usrcmds/init.lua`,
`lua/bindings/mappings/window_orientation.lua`,
`lua/bindings/usrcmds/autocmd_docs/init.lua`,
`lua/bindings/usrcmds/telemetry_nvim_config/init.lua`,
`lua/startup/init.lua`, `lua/wkdoptions/commands/register.lua`, plus one
module per standalone command below. All of these go through
`lib.nvim.bindings.usercmd`'s `create`.

### Editor and window layout

| Command | Range | Effect |
| --- | --- | --- |
| `:WinVertical` | — | `:wincmd H` — move the current window into a vertical split, left side. Same action as `<leader>wl` |
| `:WinHorizontal` | — | `:wincmd K` — move it into a horizontal split, top. Same action as `<leader>wh` |
| `:ToggleInlineDiff` | — | Invert gitsigns' `word_diff` and `linehl` and preview the current hunk inline. Same action as `<leader>di` (`bindings/mappings/git.lua`) |

Only two of the five `window_orientation` moves have a command; the right,
bottom and rotate variants are keymap-only.

### Paths and the clipboard

| Command | Range | Effect |
| --- | --- | --- |
| `:CopyLocation` | — | Copy `<absolute path>:<line>:<column>` of the cursor to the `+` register. Warns instead of copying when the buffer has no file on disk. Column is reported 1-based |
| `:Bindings path` | — | Copy the BINDINGS root(s) to the `+` register — both, newline-separated, unless `personal`/`extern` narrows it. Also on `<leader>BI`. Replaced `:BindingsPath` on 2026-09-04 |
| `:CwdHere` | — | `:lcd` to the directory of the current buffer's file. Window-local, not global. Known gap: an open `neo-tree`/`nvim-tree`/`netrw` does not pick the new cwd up until it is reloaded |
| `:PowershellProfile` | — | Resolve `$PROFILE` through `powershell -NoProfile` and `:edit` it. Errors out when `powershell` is not executable |
| `:ContextOpen` / `:ContextOpen list` | — | Open whatever is under the cursor, through one verb instead of five plugin-specific keys: gopath, markdown, images, pdfport and open.nvim are tried in turn. `list` shows every openable target in the buffer and jumps to the one you pick |

`:BindingsPath` used to sit here and copied `docs/NOTES/BINDINGS`, a
directory that never existed — the two trees were
`docs/NOTES/PersonelPlugins/BINDINGS` (now this file plus
[`docs/NOTES/CrossPlugin/`](NOTES/CrossPlugin/), see `BND-05`) and
`docs/NOTES/ExternPlugins/Bindings`. Removed 2026-09-04; `<leader>BI` now
runs `:Bindings path`, which knows both roots.

### Startup instrumentation

| Command | Range | Effect |
| --- | --- | --- |
| `:StartupReport` | — | Open the startup phase timeline in a themed float (`startup.report.open`) |
| `:StartupCheck` | — | The same data reduced to policy violations only (`startup.report.check`) |

### Options

| Command | Range | Effect |
| --- | --- | --- |
| `:WKDDiffProfile {profile}` | — | Set `diffopt` from a named profile — `minimal`, `context`, `review` or `strict` (`wkdoptions/set_diff_profile/profiles.lua`). `nargs = 1` with completion over the four names |
| `:MyOptSet[!] {keypath} [value]` | — | Set one options-config key. `<Tab>` completes the key paths. With `!` and no value it toggles the key instead |
| `:MyOptShow [keypath]` | — | Print one key's value; without an argument, the whole options table |
| `:MyOptList` | — | List every options-config key path |
| `:WKDOptionsHLSet[!] {keypath} [value]` | — | The same three, for the highlight config. `!` without a value toggles |
| `:WKDOptionsHLShow [keypath]` | — | One highlight key, or the whole table |
| `:WKDOptionsHLList` | — | Every highlight-config key path |
| `:WKDOptionsHLDebugCtx` | — | Dump what the breadcrumb context resolver currently produces: LSP function, treesitter symbol, language extra, word fallback, and the separator it would use |

**Two subsystems, one registrar, and that is why the names look unrelated.**
`wkdoptions/commands/register.lua` defines all seven generically, with
default names `WKDOptSet`/`WKDHighlightSet`/… — and both callers override
them: `options_config/init.lua` asks for `MyOpt*`, `hl_config/init.lua` for
`WKDOptionsHL*`. Neither default name exists in a running session, so
grepping the registrar for the live names finds nothing.

**`:WKDDiffProfile` was registered late.** `wkdoptions/commands/register.lua`
had always defined it, but only from `M.register_all()` — and nothing called
`register_all()`; the other three registrars are each reached directly from
their own subsystem's `init.lua`. `wkdoptions/init.lua`'s `setup()` now calls
`register_diff_profile()` alongside the other standalone features (`qflist`,
`indent_per_ft`), since a diff profile is neither a highlight nor an option.
Found by `:Bindings check` reporting it on both axes at once: present in the
source map, absent from `nvim_get_commands`.

This config's default `diffopt` is byte-for-byte the `review` profile, so
`:WKDDiffProfile review` on a fresh session changes nothing visible — that is
the profile already being active, not a no-op. An unknown profile name
surfaces as a Vim error when driven from `vim.cmd` (how `nvim_exec2` reports
an error-level message); typed interactively it is just the notification.
One rough edge: the handler has a branch that lists the profiles when called
with no argument, but `nargs = 1` means Neovim rejects the bare call with
E471 first, so that branch is unreachable.

### Aliases for plugin commands

Registered here, not by the plugin — each one is a fixed argument list this
config types often enough to name.

| Command | Range | Effect |
| --- | --- | --- |
| `:LibAutocmdDocsAll [dir] [--dry-run]` | — | Run lib.nvim's autocmd-docs generator across every repository under `dir` (default `$REPOS_DIR`). The per-repo `:LibAutocmdDocs` / `:LibUsercmdDocs` pair comes from lib.nvim itself; only the `…All` sweep is config-local |
| `:RATelemetryNvimConfig` | — | `:RATelemetry setup nvim-config` |
| `:RATelemetryNvimConfigFull` | — | `:RATelemetry full nvim-config` |

`:LibUsercmdDocsAll` deliberately does not exist: lib.nvim has no `write_all`
for user commands. The autocmd sweep derives its repository set from records
carrying a source path, which the usercmd records now do too, so this is a
small addition if it is ever wanted — not a missing capability.

### `:MyPlugins` — config-internal plugin-repo management

Manages the checkouts of the personal `.nvim` plugins listed in
[`lua/plugins/personal/list.lua`](../lua/plugins/personal/list.lua). Full
implementation notes and safety rationale:
[`lua/bindings/usrcmds/plugin_repos/README.md`](../lua/bindings/usrcmds/plugin_repos/README.md).
Replaces the former flat `:MyPluginsClone [dir]` / `:MyPluginsRemove [dir]`.

| Command | Effect |
| --- | --- |
| `:MyPlugins clone [dir] [--only=<name>] [--dry-run]` | Clone every repo in `plugins.personal.list` not yet present in `dir` (default `$REPOS_DIR`); `--only` limits to one, `--dry-run` only reports what would be cloned |
| `:MyPlugins remove [dir] [--only=<name>]` | Remove clean (no uncommitted/unpushed work) listed repos from `dir`, after a confirmation naming exactly what will be deleted |
| `:MyPlugins fetch [dir] [--only=<name>]` | `git fetch --all --prune` on every present listed repo |
| `:MyPlugins pull [dir] [--only=<name>]` | `git pull --ff-only` on every present listed repo |
| `:MyPlugins update [dir] [--only=<name>]` | `fetch` + `pull` on every present listed repo — the two-machine sync command |
| `:MyPlugins dashboard [dir]` | Opens `reposcope.nvim`'s own `:Reposcope status [dir]` — a git-status overview of every repo in `dir`/`$REPOS_DIR` (not scoped to the plugin list). `:MyPluginsDashboard [dir]` is a flat shorthand |
| `:MyPlugins reclone [dir] [--only=<name>] [--dry-run]` | Delete-if-clean + fresh clone for present repos (same safety check as `remove`); plain clone for anything missing |
| `:MyPlugins mode [auto\|dir\|remote\|disabled]` | Show, or persistently switch, `plugins.personal.source`'s `OVERRIDE` — writes directly into `source.lua` |
| `:MyPlugins list [dir]` | Read-only: every listed plugin plus whether it's present in `dir` |
| `:MyPlugins picker [dir]` | Interactive: `<Tab>` assigns clone/update/pull/fetch/remove/reclone per plugin, `<CR>` runs the whole batch |

`dir` is where to look for the listed repos, never a folder to enumerate —
contrast with `:MyReposUpdate` below, which does scan. `mode` requires a
restart: `source.lua` is `require()`d once and already baked into the spec
list lazy-loaded at startup.

```vim
:MyPlugins update              " bring this machine level with what got pushed elsewhere
:MyPlugins reclone --only=filetree.nvim  " nuke and re-clone a checkout that's misbehaving
:MyPlugins picker               " assign different actions to different plugins, run as one batch
```

### `:MyReposUpdate` — update every git repo in a directory

Full docs: [`lua/bindings/usrcmds/update_repos/README.md`](../lua/bindings/usrcmds/update_repos/README.md).

| Command | Effect |
| --- | --- |
| `:MyReposUpdate [path]` | `git fetch --all --prune` + `git pull --ff-only` on every git repo directly under `path` (default `$REPOS_DIR`), sequentially |
| `:MyReposUpdate [path] --only=<name>` | The same, restricted to the one repo whose directory basename matches |

Unlike `:MyPlugins update`, `path` is a folder to *enumerate* — every git
repo found there is touched, not just the ones in the personal-plugin list.
That is why `$REPOS_DIR`'s non-plugin checkouts (`Notes`, `WKDBooks`, ...)
are updated by this command and ignored by `:MyPlugins update`.

### `:WhoLocks` — diagnose a Windows file lock

Full docs: [`lua/bindings/usrcmds/who_locks/README.md`](../lua/bindings/usrcmds/who_locks/README.md).

| Command | Effect |
| --- | --- |
| `:WhoLocks [path]` | Report who is holding `path` (default: the current buffer's file) open |
| `:WhoLocks [path] --json` | The same findings as one `vim.json.encode`d object |

Run right after a file operation fails with `EBUSY`/`EPERM`/`EACCES`. Measures
via a live `uv.fs_rename` probe, the Windows Restart Manager (processes
holding the file), and neo-tree's own `fs_event` watchers — the last one is
what makes this useful outside any one plugin.

### `:Bindings` — the picker over this very corpus

Full docs: [`lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md`](../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md),
`:help bindings_explorer`.

A verb over `lib.nvim.bindings.usercmd.composer`, like `:Case`/`:Image`. Bare
`:Bindings` is `:Bindings search`.

| Command | Effect |
| --- | --- |
| `:Bindings search [plugin] [query]` | Live-grep across the whole corpus (picker engine via `pickers.nvim`, else prompt+list) |
| `:Bindings search keymaps\|usercmds\|autocmds [plugin] [query]` | The same, scoped to one category |
| `:Bindings browse [plugin] [scope]` | Picker over parsed table rows (all three categories) instead of full text |
| `:Bindings path [personal\|extern]` | Copy the BINDINGS root(s) to the clipboard |
| `:Bindings check [plugin]` | Drift report: documented-but-not-live / live-but-undocumented |
| `:Bindings check extern\|all\|repo [plugin]` | The same report over the extern corpus, both corpora, or plus the checkout axis (documented bindings of unloaded plugins against their local source tree) |
| `:Bindings report [plugin]` | The same report written to a Markdown file |
| `:Bindings status` | Dashboard: corpus, live and plugin counts, last report, route list |

`plugin` is a cheatsheet stem — a plugin's short name (`hover.nvim`,
`nvim-config`) or a normalized/prefixed form of it — resolved the same way
for `search`, `browse`, `check` and `report`.

### `:DocMapAll` — superseded

`:DocMapAll` (and `:DocMap all`) used to live here
(`lua/bindings/usrcmds/docmap_all/`, now deleted) and is now
`documentation.nvim`'s own command, registered by its own `setup()` when
`opts.generate_all.projects` is configured. See that plugin's own
`docs/commands.md`/`docs/WORKFLOW.md` for the current design. What stayed
behind, config-local:

**`scripts/docmap_projects.lua`** prints the personal-plugin project list as
JSON, for callers outside this Neovim process —
[`docmap-desktop`](https://github.com/StefanBartl/docmap-desktop)'s own
"Import from Neovim…" button is the reason it exists:

```
nvim --headless -c "luafile scripts/docmap_projects.lua" -c "qa"
```

**Must be `-c "luafile ..."`, not `-l`.** Plain `nvim --headless -l
scripts/docmap_projects.lua` fails to even find `lib.nvim`, because `-l` is a
bare Lua-script runner that skips this config's own `init.lua` and
lazy.nvim's bootstrap entirely — the export needs the real, fully-resolved
plugin policy (`source.lua`'s mode table, machine detection), which only
exists after a real startup has run. `-c "luafile ..." -c "qa"` goes through
the normal startup sequence first.

stdout carries exactly one line of JSON, no pretty-printing; anything that
goes wrong is reported on stderr with a non-zero exit code, so a subprocess
caller can check `.code` without parsing stdout in the failure case. Built
on [`plugins.personal.export`](../lua/plugins/personal/export.lua), which wraps
[`plugins.personal.list`](../lua/plugins/personal/list.lua) plus each plugin's
resolved local directory; a remote-mode entry with no local checkout is
filtered out rather than passed through with a directory a caller would have
to remember to check for `nil`.

See [`docs/NOTES/CrossPlugin/Usercmds-Overview.md`](NOTES/CrossPlugin/Usercmds-Overview.md)
for how these command names interact with every personal plugin's own
commands — including the one real cross-plugin interaction found so far
(`:Lsp` silently suppressing nvim-lspconfig's own commands via an upstream
`exists(':lsp')` check).

---

## Autocommands

Sources: `lua/autocmds/**`, `lua/bindings/**`, `lua/config/harpoon/**`,
`lua/options.lua`, `lua/plugins/**`, `lua/startup/init.lua`,
`lua/wkdnvchad/ui/**`, `lua/wkdoptions/**`.

**Counted are call sites, not event registrations** — the same rule
[`lsp.nvim` uses for its own autocmds](https://github.com/StefanBartl/lsp.nvim/blob/main/docs/autocmds.md):
a handler on three events is one row; `nvim_get_autocmds` would count it
three times. Measured 2026-09-02: **58 call sites**, of which **43 sit in 28
augroups** and **15 have no augroup at all** (see
[Without an augroup](#without-an-augroup) below). All 58 go through
`lib.nvim.bindings.autocmd.create` — none on the raw API. The *augroups*
themselves are mixed (`Autocmd.group(name, true)` vs. raw
`nvim_create_augroup`), same as in lsp.nvim.

**Three call sites are easy to miss in a fresh session**: `NeotestCore`
(×2) and `NvChadLspSignature` (×1) register only once neotest or an LSP
client has actually loaded, so a `:Bindings check` run right after startup
reports them as `autocmd-not-live` — the same class as lsp.nvim's
`LspNvimSagaWinbarDepth` (hangs off `LspAttach`) and `LspFormatOnSave`
(hangs off a feature switch). Kept as real table rows rather than prose, so
a renamed augroup would still be caught.

### Filesystem explorer — `lua/autocmds/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `AutoCenterExplorerSetup` | `FileType` | — | Set up auto-centering for explorer buffers |
| `WkdExplorerSingleton` | `WinEnter` | — | Close whichever *other* explorer UI is open, when one opens |
| `WkdExplorerSingleton` | `WinClosed` | — | Reopen the just-displaced explorer UI exactly once, then forget it |

Read the `WkdExplorerSingleton` pair together: `WinEnter` displaces,
`WinClosed` restores. "Once, then forget" is why it is two call sites rather
than one handler on both events — the second holds state the first sets.
See [`docs/NOTES/CrossPlugin/Autocmds-Observations.md`](NOTES/CrossPlugin/Autocmds-Observations.md#winenterwinclosed-the-explorer-singleton-is-this-configs-own-code)
for why this exists (neo-tree and snacks.picker's `explorer` source have no
awareness of each other).

### Terminal, Git, Text — `lua/autocmds/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `general_autocmds_autocmds_general_kitty_spacing` | `VimEnter` | — | Kitty: shrink window padding for the current window |
| `general_autocmds_autocmds_general_kitty_spacing` | `VimLeavePre` | — | Kitty: restore padding on exit |
| `git_autocmds_commit_ft` | `FileType` | `gitcommit` | Buffer options for the commit-message buffer |
| `gitsigns_refresh` | `BufEnter`, `FocusGained` | — | Re-read gitsigns on focus/entry |
| `numbers` | `TermOpen` | — | Terminal: disable absolute and relative line numbers locally |
| `trim_trailing` | `BufWritePre` | `*` | Strip trailing whitespace on save |
| `trim_blank` | `BufWritePre` | `*` | Clean fully-blank lines, preserving cursor position |
| `last_loc` | `BufReadPost` | `*` | Restore the last cursor position after reading |

The Kitty augroup's doubled prefix
(`general_autocmds_autocmds_general_…`) is an artefact of the name-building
in `lua/autocmds/general/init.lua`, not a second mechanism — noted because a
grep for `general_kitty_spacing` alone would not find it.

### Keymaps and commands — `lua/bindings/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `NoiceBufferMaps` | `FileType` | `noice*` | Set buffer-local Noice keymaps |
| `CasedeskSlaNotify` | `FocusGained` | — | casedesk: re-check SLA clocks |

### Neotest — `lua/config/neotest/core/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `NeotestCore` | `BufEnter`, `BufNewFile` | — | Auto-attach to a test file (`neotest.run.attach`) when the buffer name matches a test-file pattern |
| `NeotestCore` | `User` | `NeotestRunComplete` | Open the output window once at least one test has failed (`enter = false`) |

Both hang off a switch (`auto_attach_on_test_file` / `show_output_on_fail`
in `config.neotest.core`) — the augroup exists regardless, only the
autocmd inside is conditional.

### LSP signature help — `lua/nvchad/au.lua`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `NvChadLspSignature` | `LspAttach` | — | For a newly attached client, set up `nvchad.lsp.signature` — only if its `signatureHelpProvider` reports trigger characters |

From the same local override copy of `nvchad/au.lua` as `ReloadNvChad` and
`:MasonInstallAll` (extern cheatsheet: `NvChadUI.md`). Registered only when
`config.lsp.signature` is true.

### Harpoon — `lua/config/harpoon/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `HarpoonHardening` | `BufLeave`, `FocusLost` | — | Debounced save |
| `HarpoonHardening` | `VimLeavePre` | — | Flush any pending save |
| `HarpoonPinMarks` | `FileType` | `harpoon` | Pin marks inside the Harpoon buffer |

`HarpoonPinMarks` also appears on the extern `Harpoon.md` cheatsheet, there
described as Harpoon-UI behavior; here as this config's registration of it.
Both are correct — the registration lives here.

### Options and plugin specs — `lua/options.lua`, `lua/plugins/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `MarkdownLocalFolds` | `FileType` | `markdown` | Lightweight markdown folding, markdown buffers only |
| `WebdevRestyLoader` | `FileType` | `http`, `resty` | Lazy-load `resty.nvim` on its own filetypes (`once`) |

### Statusline — `lua/wkdnvchad/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `WkdNvChadCwdModeBadgeHl` | `ColorScheme` | — | Rebuild the cwd-mode badge's highlights for the new palette |

### Highlights — `lua/wkdoptions/hl_config/`

The largest block on this page: this config's own highlight subsystem,
eleven augroups. Names are split between `myopt.X` (dot) and `myopt_X`
(underscore) — historical, no difference in meaning.

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `myopt.CWord` | `CursorMoved` | — | Underline the word under the cursor (window-local) |
| `myopt.CWord` | `InsertEnter`, `BufLeave`, `WinLeave` | — | Clear the underline again |
| `myopt_CwordOccur` | `CursorMoved` | — | Update cursor-word occurrences on movement |
| `myopt_CwordOccur` | `CursorMovedI` | — | Same, in insert mode |
| `myopt_CwordOccur` | `BufEnter`, `BufWinEnter`, `WinScrolled` | — | Update on view/window changes |
| `myopt_CwordOccur` | `TextChanged`, `TextChangedI` | — | Update on edits |
| `myopt_CwordOccur` | `BufLeave`, `WinLeave` | — | Clear on leaving |
| `myopt_CwordOccur` | `InsertEnter` | — | Clear on insert, if configured that way |
| `myopt.Flash` | `TextYankPost` | — | Briefly flash the yanked region |
| `myopt.ModeTint` | `ModeChanged` | — | Tint `CursorLine` by mode |
| `myopt.ModeTint` | `BufWinEnter` | — | Re-apply the tint on window entry |
| `myopt.ModeTint` | `WinClosed` | — | Clean up the mode-color cache |
| `myopt.SigncolTint` | `DiagnosticChanged`, `BufEnter` | — | Tint `SignColumn` by the worst diagnostic present |
| `myopt.TermPalette` | `TermOpen` | — | Apply the terminal-specific palette |
| `myopt.ColorPersist` | `ColorScheme` | — | Re-apply highlights after a theme change |
| `myopt.PerWindow` | `WinEnter`, `BufWinEnter` | — | Activate highlights in the active window |
| `myopt.PerWindow` | `WinLeave` | — | Dim them in the inactive window |
| `myopt.PerWindow` | `BufReadPost`, `TextChanged`, `TextChangedI` | — | Re-check the column highlight on size changes |
| `myopt_PathCache` | `BufEnter`, `BufFilePost` | — | Warm the per-buffer repo-path cache |
| `myopt_PathCache` | `DirChanged` | — | Refresh the cache on `:cd`/`:tcd` |

**Six call sites for `myopt_CwordOccur`** are not an oversight: each toggles
a different trigger, and three of them *clear* rather than set. Folded into
one handler, the "update" vs. "clear" distinction would only be visible in
the body.

### Options — `lua/wkdoptions/options_config/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `myopt_Options` | `ColorScheme` | — | Keep base options and `guicursor` stable across theme changes |

### Without an augroup

Fifteen call sites register with **no** group. Listed in full here because
`:Bindings check`'s autocmd axis structurally cannot see them — it needs an
augroup to connect a documented row to a live registration, and counts these
only as "not checkable".

| Augroup | Event(s) | Pattern | Source | Action |
| --- | --- | --- | --- | --- |
| **none** | `OptionSet` | `diff` | `lua/options.lua:180` | Reset `wrap`/`cursorbind` on entering diff mode |
| **none** | `FileType` | — | `lua/plugins/treesitter.lua:121` | Enable Treesitter highlighting, respecting the parser policy |
| **none** | `FileType` | — | `lua/plugins/treesitter.lua:144` | Set Treesitter folding |
| **none** | `FileType` | — | `lua/plugins/treesitter.lua:154` | Set Treesitter `indentexpr` (experimental) |
| **none** | `VimEnter` | — | `lua/startup/init.lua:105` | Catch up one pending `UIReady` phase (`once`, one per phase) |
| **none** | `FileType` | `*` | `lua/wkdoptions/indent_per_ft/init.lua:23` | Per-filetype indentation |
| **none** | `ColorScheme` | `*` | `lua/wkdoptions/init.lua:39` | Re-apply highlight config after a theme change |
| **none** | `FileType` | per language | `lua/wkdoptions/italic_keywords/init.lua:21` | Italicize keywords — one call site per language |
| **none** | `BufEnter`, `BufWinEnter`, `FileType` | — | `lua/wkdoptions/ui/line_numbers/init.lua:62` | Per-buffer line-number mode |

**Two rows are generators, not single cases.** `italic_keywords` iterates
`M.languages` and registers one call site per enabled language — currently
six (`typescript`, `go`, `rust`, `cpp`, `asm`, `lua`). `startup/init.lua:105`
registers one per pending `UIReady` phase — currently two (`usrcmds`,
`mappings`). Both numbers grow with configuration, not with code, which is
why the generator is listed here rather than the expanded list.

**Why this is not just cosmetic.** lsp.nvim's own autocmds page logged two
groupless autocmds as a real bug on 2026-08-25, with a measured consequence:
`setup()` had no idempotency guard and ran again on every config reload, and
a groupless autocmd **stacks** on that (1 → 2 → 3), while `usercmd.create`'s
`force = true` overwrites itself instead. Whether any of the fifteen above
takes the same path is **not measured** — it depends on whether their
registrar can run a second time.

### Open items

- **The fifteen without an augroup** — check for stacking behavior. Recipe
  is the same as lsp.nvim's: count `nvim_get_autocmds` before and after a
  reload, don't read the source and guess.
- **Two naming schemes in one subsystem** (`myopt.X` / `myopt_X`) — purely
  cosmetic, but it splits every grep in two.
- **The doubled Kitty-augroup prefix** (see above).

See [`docs/NOTES/CrossPlugin/Autocmds-Observations.md`](NOTES/CrossPlugin/Autocmds-Observations.md)
for how these interact with every personal plugin's own autocmds.
