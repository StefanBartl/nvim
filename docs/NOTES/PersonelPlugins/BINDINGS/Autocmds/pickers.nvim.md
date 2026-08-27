# pickers.nvim — Autocmds Cheatsheet

Sources: `lua/pickers/bindings/autocmds.lua`, `plugin/pickers.lua`, `selected_index/init.lua`, `smart/frecency.lua`
Cross-reference: **2026-08-07 checklist pass** — `docs/BINDINGS.md` now documents all three autocmd groups (`VimEnter` fallback, the `selected_index` overlay's 3 autocmds, `smart.frecency`'s 2 autocmds); previously it only had the `VimEnter` fallback.

**2026-07-26 roadmap pass**: `selected_index` moved config from top-level
`cfg.selected_index` to `cfg.experimental.selected_index` (opt-in namespace,
signals not-yet-stable) — same gating condition, just nested now. New
opt-in `smart.frecency` autocmds added (see below).

## `VimEnter` fallback

Called from `plugin/pickers.lua` at plugin load time:

```lua
vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = callback })
```

`once = true`. Checks `vim.g.pickers_nvim_setup_called`; if the user never
called `require("pickers").setup()`, registers default keymaps/usercmds
using default config — covers the case where the user's config has no
`config = function() ... end` block, or the plugin loaded after `VimEnter`.
When `lib.nvim.bindings.autocmd` is available, the augroup is named `"pickers.nvim"`;
the raw-API fallback path doesn't set an explicit group.

## `selected_index` overlay — Telescope-only, per-picker-instance

Only created when `cfg.experimental.selected_index.enabled == true` or
`cfg.experimental.selected_index.toggle_key` is set (moved under
`experimental` 2026-07-26 — same gate as its keymaps, just nested now — see
[Keymaps cheatsheet](../Keymaps/pickers.nvim.md)); only for the Telescope
engine. Augroup `"PickersSelectedIndexAUG_" .. results_bufnr` (unique per
picker instance, `clear = true`).

| Event(s) | Buffer (pattern) | Action |
| --- | --- | --- |
| `CursorMoved` | results buffer | Debounced (30ms) recompute + redraw of the selected-index overlay |
| `TextChangedI`, `TextChanged` | prompt buffer | Same debounced recompute — needed because typing in the prompt re-sorts results (changing the selected entry's rank) without firing `CursorMoved`; the debounce lets Telescope's async sort settle first |
| `BufDelete` (once, no explicit group) | results buffer | Cleans up the extmark namespace and cancels the debounce timer |

**2026-07-26: indexing bug root-caused and fixed.** The overlay used to show
the wrong number on *every* render (not just intermittently) — it fell back
to a plain `row + 1`, which is only correct under Telescope's non-default
`sorting_strategy = "ascending"`. Under the default `"descending"` strategy
(best match closest to the prompt), `row + 1` is off by an amount depending
on `row`/`max_results`. Confirmed by reading Telescope's own source
(`telescope/pickers.lua`): `entry.index` (the code's primary lookup) is
never actually set by Telescope's builtins or this plugin's own
entry_makers, and the fallback's `picker.results`/`picker.manager.results`/
`picker._results` checks don't exist on a modern Telescope
`Picker`/`EntryManager` (results live in a linked list, not a flat array) —
so both old paths silently fell through to `row + 1` every time. Now uses
`picker:get_index(row)`, Telescope's own authoritative row↔index mapping
(already accounts for `sorting_strategy`) — no caching or timing involved.

## `smart.frecency` — opt-in, real file buffers only

Only registered when `cfg.smart.frecency.enabled == true` (opt-in, off by
default — added 2026-07-26 with the smart action's frecency ranking boost).
Augroup `"pickers.nvim"` (shared with the `VimEnter` fallback above).

| Event(s) | Buffer (pattern) | Action |
| --- | --- | --- |
| `BufReadPost` | any real, listed file buffer (`buftype == ""`, readable path) | Records a visit (`pickers.smart.frecency.record`) — increments count + updates last-visited timestamp for that abspath |
| `VimLeavePre` | none | Flushes the in-memory frecency store to `stdpath("data")/pickers.nvim/frecency.json` (best-effort snapshot, not written on every single visit) |
