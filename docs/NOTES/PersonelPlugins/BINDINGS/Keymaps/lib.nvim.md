# lib.nvim — Keymaps Cheatsheet

lib.nvim is a **library**, not an end-user plugin — `require("lib")` only
resolves an aggregator strategy; there are no side effects at load time and
no keymaps registered eagerly. No `docs/BINDINGS.md`/`commands.md` exists
here (reasonable — there's nothing default-active to document).

## Helper modules (no registration until a consumer calls them)

- `lua/lib/nvim/map/init.lua` — the `lib.nvim.map` keymap helper other plugins bridge to: validates args, notifies the caller's call-site on bad types, defaults `desc=""`, `noremap=true`, `silent=true`, normalizes `buffer=true→0`, then calls `vim.keymap.set`.

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
- No which-key integration — confirmed against source: zero `which_key`/`which-key` references in the whole tree. Makes sense for a library: which-key group labeling is each *consumer's* job (see `debugging.nvim.md`/`language.nvim.md`/`markdown.nvim.md`/`filetree.nvim.md`/`pickers.nvim.md` for real examples built on top of `lib.nvim.map`), not something lib.nvim itself would register.
- See [lib.nvim's Autocmds cheatsheet](../Autocmds/lib.nvim.md) for the autocmd-driven counterparts (surface lifecycle, theme re-materialization, etc.) that back these same UI components.
