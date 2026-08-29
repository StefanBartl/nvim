# lib.nvim — Keymaps Cheatsheet

lib.nvim is a **library**, not an end-user plugin — `require("lib")` only
resolves an aggregator strategy; there are no side effects at load time and
no keymaps registered eagerly. No `docs/BINDINGS.md`/`commands.md` exists
here (reasonable — there's nothing default-active to document).

## `lastcmd` — repeat the last real command ("Super-Keymap")

Source: `lua/lib/nvim/lastcmd/init.lua`
Docs: `lua/lib/nvim/lastcmd/README.md`

This is the "Super-Keymap" from the config roadmap: one keymap that reaches
across *every* other mapping without any of them being wrapped or cooperating.

`lib.nvim.lastcmd` closes the one gap native `.` has: it cannot repeat a
Lua-callback mapping (it replays recorded keystrokes, so it silently repeats
an older, unrelated change instead). The tracker reads the typed keys off
`vim.on_key` and resolves them against `maparg`/`mapcheck`; native changes are
delegated to `.` via a `changedtick` comparison; whichever ran more recently
wins on repeat. Motions fall out for free (they never move `changedtick`,
unmapped keys never match `maparg`).

**Experimental and opt-in.** The module installs nothing on its own — the
tracker sees every keypress in the session, so `setup()` without
`experimental` does nothing at all. With it, the module binds the trigger
*itself*, through `lib.nvim.bindings.keymap`, so it lands in the keymap
registry like any other binding:

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `<M-.>` | n, x | Re-run the last real command (mapping or native change), skipping pure motions | Default trigger. Only bound after `setup({ experimental = true })`. |
| *(your lhs)* | n, x | same | `setup({ experimental = "<M-r>" })` binds that key instead. |
| — | — | feature off | `setup({ experimental = false })` unbinds and tears the tracker down. |

**Why `<M-.>` and not `<C-#>`** (which was the wish): outside the kitty
keyboard protocol a terminal cannot encode Ctrl with a non-alphabetic key —
legacy encoding only covers `Ctrl` + `@ A-Z [ \ ] ^ _ ?`. WezTerm here has
`enable_kitty_keyboard = false` set deliberately (`Configs/terminals/wezterm/config/terminal_safety.lua`,
against escape-sequence leaks on Alt-Tab), so `Ctrl+#` arrives as a plain `#`
and a `<C-#>` mapping would never fire — while *looking* bound, because
Neovim can represent the key internally. `<M-.>` survives the ESC-prefix
encoding every terminal implements.

Visual-mode replay reselects by the recorded selection *shape* via
`lib.nvim.selection` and anchors it at the cursor (`{count}v` forces charwise
and cannot reproduce a linewise/multi-line selection).

Not the same tool as `lib.nvim.dotrepeat` — that wires one specific buffer
change through Vim's `operatorfunc` so native `.` itself repeats it; `lastcmd`
is a separate keymap that repeats whatever ran last. A third member of the
family is still only a concept: the `\`/`?` result modifiers, see
[modifier-keymaps.md](../../../../ROADMAP/personal/modifier-keymaps.md).

**Known limits** (from the README): native non-change commands (`zz`, `:w`)
are invisible to `changedtick`; undo/redo count as a native change; an lhs
that is both an exact mapping and the prefix of a longer one is recorded
immediately instead of waiting for `timeoutlen`; operator-pending is
indistinguishable from normal mode inside `on_key`.

## Helper modules (no registration until a consumer calls them)

- `lua/lib/nvim/bindings/keymap/init.lua` — the `lib.nvim.bindings.keymap` keymap helper other plugins bridge to: validates args, notifies the caller's call-site on bad types, defaults `desc=""`, `noremap=true`, `silent=true`, normalizes `buffer=true→0`, then calls `vim.keymap.set`.

## Dynamic registrations — only fire when a consuming plugin invokes the enclosing function at runtime

| Module | Trigger | Registers |
| --- | --- | --- |
| `lua/lib/nvim/window/nice_quit.lua` | any float-owning code with a `winid` | n, `q`/`<Esc>` (configurable), buffer-local → closes the window (refuses to close the last window in a tabpage) |
| `lua/lib/nvim/ui/kit/picker.lua` | every `kit.select`-style picker | `<CR>` submit, `<C-n>`/`<Down>` next, `<C-p>`/`<Up>` prev, `<Esc>` close — on the prompt buffer |
| `lua/lib/nvim/ui/kit/input.lua` | `kit.input` (a `vim.ui.input` replacement) | `<CR>` submit, `<Esc>` cancel, buffer-local |
| `lua/lib/nvim/ui/kit/preview.lua` | `:KitPreview` (lib.nvim's own dev-tool theme playground) | `<Tab>` cycle presets, `<S-Tab>` cycle colorschemes, `q` close (both buffers) |
| `lua/lib/nvim/progress/styles/float.lua` | the "float" progress style is used | n, `<Esc>`, buffer-local → confirms and requests cancellation of the running op |

## Notes

- None of these are active until a consuming plugin (or your own config) actually calls the enclosing function — they're building blocks, not standing keymaps.
- No which-key integration — confirmed against source: zero `which_key`/`which-key` references in the whole tree. Makes sense for a library: which-key group labeling is each *consumer's* job (see `debugging.nvim.md`/`language.nvim.md`/`markdown.nvim.md`/`filetree.nvim.md`/`pickers.nvim.md` for real examples built on top of `lib.nvim.bindings.keymap`), not something lib.nvim itself would register.
- See [lib.nvim's Autocmds cheatsheet](../Autocmds/lib.nvim.md) for the autocmd-driven counterparts (surface lifecycle, theme re-materialization, etc.) that back these same UI components.
- `lastcmd` has no which-key surface either — it is a single user-bound trigger, not a group.

## Changelog

- 2026-08-29: added the `lastcmd` section as the first documented keymap for the lib (source `lua/lib/nvim/lastcmd/`, commit `db68ff5`).
- 2026-08-29 (2): `lastcmd` moved behind the `experimental` opt-in and now binds its own trigger; default `<M-.>`, not the wished-for `<C-#>` (unreachable with `enable_kitty_keyboard = false`). Two bugs found and fixed while verifying: the self-reference guard did not hold for any wrapped binding (the README's own example ran away into a hang), and only the *first* repeat ever worked because the replay was fed without `"t"` and so was invisible to the tracker.
