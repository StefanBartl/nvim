# Autocmds — by event

Same data as [autocmds-by-plugin.md](autocmds-by-plugin.md), re-grouped by
Vim event name — answers "what fires when X happens, across my whole
config?" Only events with autocmds are listed; events hit by only one
plugin are still included (for completeness) but flagged notes only appear
where 2+ plugins genuinely share the same trigger.

See also: [by plugin](autocmds-by-plugin.md), [by filetype/scope](autocmds-by-filetype.md).

## `VimEnter`

| Plugin | Augroup | Condition | Action |
| --- | --- | --- | --- |
| filetree.nvim | `filetree_cwd_sync` (once) | opt-in, off | Startup catch-up cwd sync |
| filetree.nvim | none (once) | neotree adapter | Defer neo-tree `?`-cheatsheet injection |
| github_stats.nvim | `GithubStatsAutoFetch` | — | Background fetch + auto-open dashboard |
| insights.nvim | `Insights_conflicts` | configurable (default trigger) | Quickfix git conflicts |
| pickers.nvim | `pickers.nvim`/none (once) | only if `setup()` never called | Register default keymaps/commands |
| sessions.nvim | `SessionsNvim` (once, nested) | `cfg.autoload` (default **off**) | Autoload contextual session |
| spotlight.nvim | `spotlight_persist` | `persist.enable` (default **on**) | Restore the persisted spotlights (also self-schedules when `setup()` runs after startup) |
| lib.nvim | `lib_telemetry_<namespace>` | only if `telemetry.new()` ran | Lifecycle-reminder check (fires at most twice ever, per namespace) |

**Worth knowing**: seven plugins hook Neovim startup. With `sessions.nvim`'s
autoload *and* `github_stats.nvim`'s dashboard auto-open both enabled, you'd
get a restored session layout immediately followed by a dashboard window
appearing on top of it (github_stats defers 1000ms, so it fires after
most session-restore work settles) — not a bug, just worth knowing if
startup ever looks like two things fighting for the screen.

## `VimLeavePre`

| Plugin | Augroup | Action |
| --- | --- | --- |
| diff.nvim | `diff_cleanup` | Wipe tracked scratch buffers |
| filetree.nvim | `filetree_session` | Save scroll/cursor/root state (opt-out) |
| language.nvim | none | Kill cspell sidecar job |
| insights.nvim | `Insights_devserver` | Kill tracked dev servers |
| sessions.nvim | `SessionsNvim` | Autosave session (default **on**) |
| lib.nvim | `lib_logger_<name>` | Flush logger ring buffer (per logger instance) |
| lib.nvim | `lib_telemetry_<namespace>` | Persist telemetry counters (per instance; re-reads and merges, so two Neovim instances sharing a namespace add up rather than clobber) |
| pickers.nvim | `pickers.nvim` | Flush `smart.frecency` store to disk (opt-in, off by default; added 2026-07-26) |
| spotlight.nvim | `spotlight_persist` | Flush a pending debounced spotlight-state save (default **on**) |

Nine independent cleanup/save routines on exit — none touch shared state, no
ordering dependency between them. The one that is not merely cheap is
lib.nvim's telemetry flush: it is a read-merge-write, not an append, which is
the price of two Neovim instances being able to share a namespace without
overwriting each other's counts.

## `BufWritePre`

| Plugin | Augroup | Condition | Action |
| --- | --- | --- | --- |
| cascade.nvim | `cascade_renumber_save` | list feature + `"save"` trigger configured | Renumber ordered lists |
| fileops.nvim | `fileops_auto_mkdir` | default on | Create parent dirs |
| markdown.nvim | `MarkdownNvimRefs` | mode == save (default) | Sync anchors + TOC |
| markdown.nvim | `MarkdownNvimLinksSanitize` | `sanitize_on_save` (default on) | Normalize inline-link targets (./, forward slashes) |
| language.nvim | `language_nvim` | opt-in, off | Abort write on spelling errors |

**Worth knowing — the one real ordering dependency in this whole audit**:
four plugins hook `BufWritePre` on what can be the same buffer (a markdown
file with a Lua-ish name would only hit fileops+cascade+markdown, but any
`.md` file with all four features enabled hits all four). Neovim runs
`BufWritePre` autocmds in **registration order** (roughly: plugin
setup-call order in your config). If `language.nvim`'s
`block_write_on_error` is ever turned on and errors out, whichever of the
other three registered *after* it never runs for that write — right now
that's low-risk since none of the other three depend on one another's
side effects, but it's the one spot in this whole config where write-time
plugin order actually matters. `fileops.nvim`'s `auto_mkdir` in particular
would be worth keeping registered early (before anything that could abort)
since a missing parent directory should probably still get created even if
the write is later aborted for spelling.

## `BufWritePost`

| Plugin | Augroup | Condition | Action |
| --- | --- | --- | --- |
| insights.nvim | `Insights_unimported` | configurable filetypes | Warn on unimported components |
| gopath.nvim | `GopathPathCacheInvalidate` | always on | Drop directory-listing caches after a write |
| gopath.nvim | `GopathCacheAutoRebuild` | opt-in, off | Debounced cache rebuild |
| filetree.nvim | `filetree_current_hl` (opt-in, off), `filetree_opened_sync`, `filetree_git_status` (opt-in, off), `filetree_lsp_diagnostics` (opt-in, off) | various | Tree-buffer redecoration |
| markdown.nvim | `MarkdownNvimLinkDiagnostics` | `links.diagnostics.mode == "save"` (default off — opt-in, 2026-07-26) | Rerun dead-link/duplicate-anchor check via `vim.diagnostic` (also see `commands/preview.lua`'s `BufEnter` and Refs' `BufWritePre`, unrelated) |
| mdview.nvim | `MdviewAutocmds` | active session | Forced full resync push |
| color_my_ascii.nvim | `ColorMyAsciiFenceOpen_<tbuf>` | `:Fence open` scratch buf | Sync fence content back |
| lib.nvim | `lib.nvim.cache.memory` (opt-in), `LibDocmapWatch:<root>` (opt-in) | opt-in only | Cache invalidation / docmap rescan |

No overlap concerns — these all touch either the tree buffer specifically
(filetree.nvim) or distinct, unrelated concerns.

## `FileType`

By far the most-used event — nearly every plugin with buffer-local
keymaps/commands hooks it. See
[autocmds-by-filetype.md](autocmds-by-filetype.md) for the pattern-grouped
breakdown (markdown vs. tree-buffer vs. debug-view vs. generic).

## `ColorScheme`

| Plugin | Augroup | Condition | Action |
| --- | --- | --- | --- |
| color_my_ascii.nvim | `ColorMyAsciiFenceLineHl` | — | Re-resolve fence-line/content HL groups |
| color_my_ascii.nvim | `ColorMyAsciiHl` | — | Re-apply dynamically created (fixed-hex) ASCII-art HL groups, wiped by `:colorscheme`'s implicit `hi clear` |
| markdown.nvim | `MarkdownNvimHL` | feature `hl`/`link_hl` (default on) | Re-apply blockquote HL / re-strip link underline |
| markdown.nvim | `MarkdownNvimFencedFix` | feature `fenced_fix` (default on) | Re-apply fenced-code HL overrides |
| filetree.nvim | `filetree_current_hl` (opt-in, off) | — | Re-apply current-line HL |
| filetree.nvim | `filetree_window_style` (opt-in, off) | — | Re-link tree window HL groups |
| lib.nvim | `lib_ui_kit_theme` | `theme.setup()` called | Re-materialize `Kit*` HL groups |
| spotlight.nvim | `spotlight_highlights` | `palette.reapply_on_colorscheme` (default on) | Re-define `Spotlight1..8` (explicit bg+fg per slot), wiped by `:colorscheme` |

Eight independent "re-apply my custom highlights after a colorscheme
change" routines (two of them from color_my_ascii.nvim alone — one for
fence-line/content HL, one for the ASCII-art character-group HL groups).
All idempotent, no shared state — this is just what it costs to switch
colorschemes with this many plugins installed; not a correctness issue, only
relevant if you ever notice a colorscheme switch feels slow (it's plausible
several of these plus your colorscheme's own setup are what you're feeling,
not any single one).

## `BufReadPost`

| Plugin | Augroup | Condition | Action |
| --- | --- | --- | --- |
| pickers.nvim | `pickers.nvim` | `smart.frecency.enabled` (opt-in, off by default; added 2026-07-26), real listed file buffers only | Record a visit for the smart action's recency/frequency ranking boost |

First (and currently only) plugin in this config hooking `BufReadPost`.
Cheap (in-memory table update, no disk I/O per visit — the store is only
flushed to disk on `VimLeavePre` or an explicit `M.flush()` call).

## `BufEnter`

Hit by: filetree.nvim (auto_reveal, cwd_sync opt-in, breadcrumbs, cursor_hide,
size_info opt-in, copy_move, marks), mdview.nvim (snapshot, browser.behavior,
tab-preview sync/close), markdown.nvim (blockquote HL, preview refresh),
insights — no, insights doesn't use BufEnter (uses
BufWritePost/VimEnter/TermOpen/TermRequest/VimLeavePre only). No shared
concern beyond "several plugins re-check state when you switch buffers" —
all cheap, debounced where it matters (auto_reveal, current_hl equivalents).

## `BufDelete` / `BufWipeout` (+ `BufAdd`)

Universal cleanup event — used by buffer-ctx.nvim, color_my_ascii.nvim (×2),
markdown.nvim, filetree.nvim (layout_guard, buffer cache), language.nvim,
lib.nvim (debounce buffer cleanup). Every single one of these is "drop my
own per-buffer state table entry for the buffer that just went away" —
textbook correct usage, zero overlap risk (each plugin only touches its own
namespaced state).

filetree.nvim's `no_name_guard` also hooks `BufAdd`/`BufDelete`/`BufWipeout`
together (distinct from layout_guard's own use above — no overlap, different
purpose): a tab-wide sweep for a stray [No Name] buffer sitting in a window
that never itself refires `BufWinEnter` (its other, narrower trigger), so it
doesn't persist indefinitely alongside real, usable buffers. Deferred one
tick + re-validated per window, same as its BufWinEnter path, since these
events fire mid-transition before Neovim settles a window's replacement
buffer.

## `TextChanged` / `TextChangedI`

Hit by: color_my_ascii.nvim (re-highlight), markdown.nvim (×2: refs live
sync, table_mode realign), mdview.nvim (live_push to relay), language.nvim
(live spell rescan, opt-in), filetree.nvim (filter/live-search input,
buffer-local to those input popups only), lib.nvim (kit picker query, cache
opt-in), reposcope.nvim (prompt field capture), pickers.nvim
(selected_index overlay). All either buffer-local-to-a-specific-buffer or
independently debounced — no interaction between them even on a shared
buffer type (e.g. a markdown file triggers color_my_ascii's re-highlight
*and* markdown.nvim's refs-live-sync *and*, if configured, language.nvim's
live spell rescan — three independent debounced timers, not a race, just
three things quietly running on every keystroke if you have all three
features turned on).

## `CursorMoved` / `CursorHold` (+ `I` variants)

Hit by: filetree.nvim (breadcrumbs, preview live-update, size_info opt-in,
git_status opt-in), fileops.nvim (on_hold preview, opt-in), color_my_ascii.nvim
(Telescope scheme-preview), reposcope.nvim (cursor-line-2 guard),
pickers.nvim (selected_index overlay). All buffer/plugin-scoped, no overlap.

## `WinEnter` / `WinLeave` (+ `Win*` family)

Hit by: debugging.nvim (auto-refresh tagged view), filetree.nvim
(auto_reveal pause, cursor_hide, breadcrumbs float close, window_style),
language.nvim (translate window teardown), lib.nvim (window focus-close,
kit surface lifecycle), reposcope.nvim (implicitly via `QuitPre`, not
`WinLeave`). No overlap — each owns a distinct window/float.

spotlight.nvim is the one plugin here that hooks the Win* family *globally*
rather than for a window it owns:

| Plugin | Event(s) | Augroup | Action |
| --- | --- | --- | --- |
| spotlight.nvim | `WinNew`, `BufWinEnter`, `TabNewEntered` | `spotlight_windows` | Apply every active spotlight to windows that have none yet, deferred one tick |
| spotlight.nvim | `WinClosed` | `spotlight_windows` | Drop the closed window's match-ledger entry |
| autocmds.explorer-singleton | `WinEnter` | `WkdExplorerSingleton` | Close neo-tree/snacks' `explorer` picker, whichever is the OTHER one, when either opens |
| autocmds.explorer-singleton | `WinClosed` | `WkdExplorerSingleton` | Reopen the just-displaced one exactly once |

That is unavoidable rather than greedy: `matchadd()` is window-local, so a
`:split` would otherwise show the same buffer with no highlights. The callback
skips windows that already carry the match, so the sweep is a no-op in the
common case. Floating windows are excluded; the quickfix window is not.

`autocmds.explorer-singleton` (this repo's own `lua/autocmds/explorer-
singleton.lua`, wired from `autocmds/init.lua`) is the other genuinely global
Win* hook here: neo-tree (`<A-l>`) and snacks.picker's `explorer` source
(`<leader>.`, via pickers.nvim) have zero awareness of each other by
default, so opening one leaves the other open alongside it unless something
external coordinates them. Both handlers defer a tick before reading
current win/buf — a newly created window (a floating picker especially) can
still briefly report the PREVIOUS window's buffer at the instant `WinEnter`
fires. See the module's own doc comment + its smoke test
(`explorer-singleton.smoke.lua`, not wired into any CI — this repo has none)
for the exact cascade contract and its known one-directional imprecision.

## `OptionSet`

| Plugin | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| spotlight.nvim | `spotlight_highlights` | `background` | Switch between `palette.colors` and `palette.colors_light` |

Only plugin here that watches an option change. Registered unconditionally, even
when `palette.reapply_on_colorscheme` is false — that option is about colorscheme
churn, not about the plugin's own two-palette (dark/light) model.

## `User` (custom events)

| Plugin | Pattern | Action |
| --- | --- | --- |
| dap.nvim | `DapUIWindowOpen`/`DapUIWindowClose` | Toggle `cursorline` |
| lib.nvim | `LazyDone` (opt-in) | Regenerate helptags |

No overlap — distinct custom event names, no plugin here emits either of
these itself (dap.nvim's pair comes from nvim-dap-ui, an external plugin).

## Events used by exactly one plugin (listed for completeness)

`VimResized` (filetree, opt-in), `WinScrolled` (language, opt-in),
`OptionSet` (diff, opt-in), `DiagnosticChanged` (filetree, opt-in),
`DirChanged` (filetree, opt-in), `TermOpen`/`TermRequest` (insights),
`ModeChanged` (fileops), `BufWinEnter`/`BufWinLeave` (debugging, filetree,
mdview — different purposes, no overlap), `BufHidden` (filetree, sessions —
different purposes), `QuitPre` (reposcope only — and the one autocmd in
this whole audit that skips `nvim_create_augroup` entirely, see
[reposcope.nvim's cheatsheet](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/reposcope.nvim.md)).
