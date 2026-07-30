# spotlight.nvim — Autocmds Cheatsheet

Source: `lua/spotlight/bindings/autocmds.lua`, `M.setup(cfg)`
Bridge: `lua/spotlight/util/lib.lua`'s `lib.autocmd()` / `lib.augroup()` — prefers
`lib.nvim.autocmd` (which wraps every callback in a `pcall` and reports failures),
falls back to `nvim_create_autocmd` with its own `pcall`.

Cross-reference: `docs/BINDINGS.md` in the repo — verified current and accurate.

All three augroups are created with `clear = true` (idempotent re-setup).

**Registered unconditionally of `keymaps.preset`** — unlike cascade.nvim, where
some autocmds are preset-gated. These are not a keymap convenience: they are what
makes window-local `matchadd()` behave like a global marking system, so the plugin
is incorrect without them.

| Event(s) | Augroup | Pattern | Condition | Action |
| --- | --- | --- | --- | --- |
| `WinNew`, `BufWinEnter`, `TabNewEntered` | `spotlight_windows` | `*` | always | Applies every active spotlight to windows that have none yet |
| `WinClosed` | `spotlight_windows` | `*` | always | Drops the closed window's ledger entry |
| `ColorScheme` | `spotlight_highlights` | `*` | `palette.reapply_on_colorscheme` (default true) | Redefines `Spotlight1..8` |
| `OptionSet` | `spotlight_highlights` | `background` | always | Switches between `palette.colors` and `palette.colors_light` |
| `VimEnter` | `spotlight_persist` | `*` | `persist.enable` (default true) | Loads the persisted snapshot, once |
| `VimLeavePre` | `spotlight_persist` | `*` | `persist.enable` | Flushes a pending debounced save |

## What is deliberately absent

**No `TextChanged`. No `CursorMoved`. No `CursorHold`.** Not an oversight — the
core design property. `matchadd()` stores the *pattern*, not positions, so a text
edit needs no invalidation at all. Adding a change-triggered handler would
reintroduce exactly the O(file size) cost that choosing `matchadd()` over extmarks
exists to avoid.

The consequence is visible in the interface: match counts are computed only when
the list opens (`lua/spotlight/core/count.lua`), and the quickfix filter is an
explicit command rather than something continuous.

## Details

- **`WinNew`/`BufWinEnter`/`TabNewEntered`** — all three are needed, and each
  catches a case the others miss: `WinNew` a `:split`, `BufWinEnter` a buffer
  displayed in an existing window, `TabNewEntered` a tab created with its window
  already in place.

  The callback is **deferred one tick via `vim.schedule`**: on `WinNew` the new
  window is not yet current, and its id is not in the event args either. By the
  time the scheduled callback runs the window exists and is entered, so a plain
  "fill every eligible window" sweep is both correct and cheap — `core.match.add()`
  skips any window that already carries the match, so re-running it is a no-op.

  Floating windows are skipped (`core/match.lua`'s `eligible()`): they are
  transient UI, including this plugin's own list, and matches painted there outlive
  nothing. The **quickfix window is not skipped** — seeing the spotlight colors in
  the filtered view is the point of `:Spotlight qf`.

- **`WinClosed`** — forgets the ledger entry without touching Vim state. The
  matches died with the window, so `matchdelete()` on those ids would only fail.
  The window id arrives as a *string* in `args.match` and is `tonumber`'d.

- **`ColorScheme`** — a colorscheme clears highlight groups it does not know
  about, so the `SpotlightN` groups have to be re-defined afterwards. Definition
  is idempotent.

  Side effect worth knowing: this also overwrites a group the user redefined by
  hand after `setup()`. The supported way to change colors is `palette.colors` /
  `palette.colors_light` in `setup()`.

- **`OptionSet background`** — `'background'` is what selects between the dark and
  light palettes, so switching it has to re-run the definition. Registered
  unconditionally, even when `reapply_on_colorscheme` is false: that option is
  about colorscheme churn, not about the plugin's own two-palette model.

- **`VimEnter`** — the snapshot is **not** loaded directly from `setup()`. A plugin
  manager may run `setup()` before the project's cwd is final (a session plugin, a
  `:cd`-ing autocmd), and `lib.nvim.store.project` is keyed by project root —
  loading too early would read the wrong project's state.

  For the lazy-loaded case (`setup()` running well *after* `VimEnter`, so the event
  will never fire), `vim.v.vim_did_enter == 1` is checked and the load scheduled for
  the next tick instead.

- **`VimLeavePre`** — saves are debounced (`persist.debounce_ms`, default 500 ms),
  because a burst of toggles is one logical change. Without this flush the debounce
  timer would never fire on `:qa` and the last toggle before quitting would be
  exactly the one lost. `flush()` cancels the pending timer and writes synchronously.
