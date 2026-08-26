# lib.nvim — Autocmds Cheatsheet

lib.nvim is a **library** — almost nothing registers eagerly. No
`docs/BINDINGS.md` exists (there's nothing default-active to document).

## Helper module

- `lua/lib/nvim/bindings/autocmd/init.lua` + `augroup.lua` — the `lib.nvim.bindings.autocmd` helper other plugins bridge to: `M.create()` wraps `nvim_create_autocmd` with a pcall-guarded callback (notifies on error) and augroup name→id caching (`M.group`/`M.get_augroup`).
- `lua/lib/nvim/bindings/autocmd/dispatcher/init.lua` + `filetype.lua` — `lib.nvim.bindings.autocmd.dispatcher`: a generic, event-agnostic dispatcher factory (one real autocmd, many lazy-loaded/prioritized/per-buffer-once handlers, keyed by a caller function of the event table), plus a `FileType`-keyed convenience wrapper on top. Shipped 2026-08-14, replacing the roadmap concept doc (deleted per lib.nvim's own doc-lifecycle convention; see its README.md for the current reference). Not yet adopted by this config's own `autocmds/events/utils/filetype.lua` prototype — that migration is a separate, future call, not part of shipping the module itself.

## Dynamic registrations — fire only when a consuming plugin invokes the enclosing function

| Module | Trigger | Registers |
| --- | --- | --- |
| `lua/lib/nvim/window/close_on_focus_lost.lua` | any float-owning code with a `winid` | augroup `LibNvimWindowFocusClose_<winid>`; `{WinLeave,BufLeave}` (configurable), buffer-local, once → deferred-close the window |
| `lua/lib/nvim/ui/kit/picker.lua` | every `kit.select`-style picker | `{TextChangedI,TextChanged}` on the prompt buffer → debounced query-change |
| `lua/lib/nvim/ui/kit/surface.lua` | every kit float (backs select/menu/input/note/toast/confirm) | augroup `lib_ui_kit_surface_<winid>`; `WinClosed` (pattern=winid, once) → fires the surface's `on_close` callbacks |
| `lua/lib/nvim/ui/kit/theme.lua` | first call to `theme.setup()` | augroup `lib_ui_kit_theme` (created once); `ColorScheme` → re-materializes `Kit*` highlight groups |
| `lua/lib/nvim/ui/kit/preview.lua` | `:KitPreview` | augroup `lib_kit_preview_<config_buf>`; `{TextChanged,TextChangedI}` re-render |
| `lua/lib/nvim/cache/memory.lua` | **opt-in**: consumer calls `M.setup_auto_invalidation()` | augroup (default `"lib.nvim.cache.memory"`); `{TextChanged,TextChangedI}` prune stale entries, `BufWritePost` clears every namespace |
| `lua/lib/nvim/logger/init.lua` | automatic, once per `logger.new()` call with a file sink (`opts.capture ~= false`, default true) | augroup `lib_logger_<name>`; `VimLeavePre` → flushes that logger's ring buffer |
| `lua/lib/nvim/telemetry/init.lua` | automatic, once per `telemetry.new()` call | augroup `lib_telemetry_<namespace>`; `VimLeavePre` → merge-and-persist the counters collected this session, `VimEnter` → the lifecycle reminder check ("you've been collecting for 7 days, go read it") |
| `lua/lib/nvim/docmap/registry.lua` | **opt-in**: `docmap.install({watch=true, ...})` | augroup `LibDocmapWatch:<root>`; `BufWritePost` pattern `*.lua` → debounced IR rescan when the written file is under the watched source dir (checked via `is_subpath`, not the autocmd glob — avoids a Windows backslash-path mismatch bug) |
| `lua/lib/nvim/debounce/buffer/init.lua` | automatic, first `.call(bufnr)` for a new buffer | per-buffer cleanup autocmd (default `{BufDelete,BufWipeout}`) cancels that buffer's debounce timer |
| `lua/lib/nvim_usrcmds/init.lua` | **opt-in**: consumer calls `require("lib.nvim_usrcmds").setup({helptags=true})` | `User` event, pattern `LazyDone`, once → `:helptags ALL` |
| `lua/lib/nvim/bindings/autocmd/dispatcher/init.lua` | **opt-in**: consumer calls `dispatcher.new(opts):attach()` (or `dispatcher.filetype.new(opts):attach()`) | one autocmd for `opts.event` (pattern `opts.pattern` or `"*"`, group `opts.group`) → resolves the event's key against the registry and runs every matching handler; plus one global `BufWipeout` cleanup autocmd that clears that dispatcher's per-buffer `once` tracking |

## Notes

- The `cache.memory` auto-invalidation and `docmap.install(watch=true)` opt-in rows are still never called by lib.nvim's own dependents — they're features a *user's own config* would opt into. `nvim_usrcmds.setup({helptags=true})` breaks that pattern: it IS called, from this config's own `plugins/personal/init.lua` (the `StefanBartl/lib.nvim` spec's `config()`).
- The two "automatic" rows (`logger.new()`, `telemetry.new()`) are automatic *given the constructor ran* — neither module registers anything at require time. As of 2026-08-01, `telemetry.new()` runs for real: `lua/config/telemetry.lua` calls it once for `lib.nvim` itself (`wrap_lib()`, counting only) and once per personal plugin, generically, right after each one loads — each of those via `wrap_loaded()` over the plugin's whole loaded module subtree and with argument profiling on, so the numbers reflect the code that actually runs rather than the entry module's façade. See [Usercmds/lib.nvim.md](../Usercmds/lib.nvim.md#what-this-config-actually-collects) for what is collected and the verified first-buffer blind spot, and `lua/config/telemetry.lua`'s own doc-comment for why it must register before `lazy.setup()` runs.
- `telemetry`'s `VimLeavePre` deliberately only flushes, it does not `stop()`. The invariant `stop()` protects is "no wrapper outlives the decision to collect", and at exit the process outlives nothing.
- See [lib.nvim's Keymaps cheatsheet](../Keymaps/lib.nvim.md) for the keymap-side counterparts of these same UI components.
