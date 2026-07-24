# mdview.nvim — `:MDView <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion).
Replaces the old 10 flat `:MDViewX` commands (fully removed, no alongside
period). This was the **first** composer migration — the pilot for the whole
`lib.nvim.usercmd.composer` module.

Source: `lua/mdview/bindings/usrcmds/init.lua` + one action module per
subcommand (`start/`, `stop.lua`, `open.lua`, `toggle.lua`, `detach.lua`,
`standalone.lua`, `show_weblogs.lua`, `preview_tab.lua`, `diagnose.lua`,
`theme.lua`, `log.lua`, `file_log.lua`, `cursor.lua`, `sync.lua`, `zoom.lua`,
`reveal.lua`, `blanklines.lua`, `overlay.lua`, `breadcrumbs.lua`)
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `docs/standalone.md`,
`README.md`, `doc/mdview.txt`

### Session lifecycle

| Command | Effect |
| --- | --- |
| `:MDView start [file] [cwd=...]` | Start the relay + open the preview |
| `:MDView stop` | Stop the relay, detach autocommands |
| `:MDView toggle [file] [cwd=...]` | Start if stopped, stop if running |
| `:MDView open` | Re-open a browser tab against the running session |
| `:MDView detach [file] [--no-browser]` | Preview in a **detached minimal nvim** that outlives this instance |
| `:MDView standalone [file] [--no-browser]` | Preview with **no nvim in the chain** (relay watches the file on disk) |
| `:MDView preview-tab` | In-nvim tab preview (Treesitter mirror; no relay/browser) |

### Live preview controls (push to the open tab, no reload)

| Command | Effect |
| --- | --- |
| `:MDView theme [name]` | Switch preview theme (tab-completed) |
| `:MDView cursor [line\|caret\|section\|off]` | Cursor marker mode in the preview |
| `:MDView sync [action]` | Pause/resume nvim→browser scroll sync (paused ⇒ "⏸ paused" pill in the tab) |
| `:MDView zoom [+\|-\|reset\|<factor>]` | Preview font-size zoom |
| `:MDView reveal [action]` | Reveal/hide ```private blocks |
| `:MDView blanklines [on\|off\|toggle]` | Toggle rendering ≥2 consecutive blank lines as vertical space (`browser.preserve_blank_lines`); re-renders the tab live |
| `:MDView overlay [name] [on\|off\|toggle]` | Toggle a preview overlay (floating TOC, …) |
| `:MDView overlay list` | List known overlays + their state |

> ⚠️ **These "live control" commands (overlay / zoom / cursor-mode) do nothing
> against the pinned `install.version` release**, because they POST to the
> relay's `/control` route which only exists *after* `v0.2.0` (overlays came
> even later). The POST is fire-and-forget, so you get **no error and no
> effect** while scroll sync (an older `/scroll`-based feature) keeps working —
> exactly the "overlay/zoom/cursor tun nichts" symptom. Run the **local build**
> to get them. In my `setup()`:
> ```lua
> dev = {
>   binary_path = "E:/repos/mdview.nvim/native/server/mdview-server.exe",
>   web_root    = "E:/repos/mdview.nvim/dist/client",
> }
> ```
> Build first: `npm run build` (wasm+client) **and** `npm run build:go` (relay).
> Falls back to `$MDVIEW_DEV_BINARY` / `$MDVIEW_DEV_WEB_ROOT`. This is the normal
> `:MDView start` path — separate from `standalone.binary_path` (standalone only).
>
> **Update: this `dev.binary_path`/`dev.web_root` config did not actually exist
> in the code** until a Claude Code session implemented it (`server_args.lua`
> now checks `dev.binary_path`/`dev.web_root` → `$MDVIEW_DEV_BINARY`/
> `$MDVIEW_DEV_WEB_ROOT` → `install.ensure_binary()`/`ensure_client_bundle()`,
> in that order). Verified end-to-end: local relay started via `:MDView start`
> with the config above, then `zoom`/`overlay`/`cursor` control payloads POSTed
> directly to `/control` → all `204`. The snippet above now genuinely works —
> just needed a real local build + a restarted Neovim to pick it up.

### Diagnostics

| Command | Effect |
| --- | --- |
| `:MDView weblogs` | Show the relay's captured stdout (incl. `[client]` lines) |
| `:MDView log [level]` | Show internal log ring, optional level filter |
| `:MDView log export [path]` | Export the internal log ring to a file |
| `:MDView file-log` | Toggle persistent file logging, report state |
| `:MDView file-log on [path]` | Enable persistent file logging |
| `:MDView file-log off` | Disable persistent file logging |
| `:MDView file-log status` | Report file logging state |
| `:MDView file-log path [value]` | Set/report the file log path |
| `:MDView diagnose [path]` | Write a full diagnostics report and open it |
| `:MDView breadcrumbs [export\|clear]` | :Session breadcrumbs (doc + heading over time) |

## detach vs. standalone — which one

|              | Survives `:qa` |  Unsaved buffer  | Scroll sync / cursor |
| ------------ | -------------- | ---------------- | -------------------- |
|   `start`    |       ✗        |        ✓         |          ✓           |
|   `detach`   |       ✓        |        ✓         |          ✓           |
| `standalone` |       ✓        | ✗ (file on disk) |          ✗           |

- **`detach`** = second headless nvim loading *only* mdview + lib.nvim via
  `scripts/minimal_init.lua`. Full feature set, isolated from my config —
  which also makes it the fastest way to answer "mdview bug or my config?".
- **`standalone`** = relay's own `--watch` mode, no nvim at all. Runs on
  `server_port + 100` (43319) so it can sit next to a normal session.
  Previews the file **as saved**.
- Terminal entry points: `scripts/mdview-bg.sh` / `.ps1`
  (`nvim +MDView --background file.md` is NOT valid nvim syntax — `+cmd` takes
  no trailing flags; the wrappers are the supported spelling).
- ⚠️ `standalone` needs a relay with `--watch` (**v0.3.0+**). The installed
  v0.2.0 release binary does **not** have it. Until a release ships, set:
  ```lua
  standalone = { binary_path = "E:/repos/mdview.nvim/native/server/mdview-server.exe" }
  ```
  mdview probes the binary and errors clearly if it's too old (it used to fail
  completely silently, since a detached process has no pipes).

### `detach` caveats found while testing (still open, see Roadmap.md BUGS #8-10)

- **Browser tab can open with a multi-minute delay, or not at all** (`mdview-bg.ps1`
  too). Cause not fully isolated: `standalone`'s browser-open is one direct Go-side
  `rundll32` call; `detach`/`mdview-bg.ps1` route health-poll AND browser-open
  through Neovim's own `jobstart` from a headless, fully stdio-less, detached
  instance — three chained child-process spawns instead of one. Reproduced
  working end-to-end in one test, unreliable timing in another — looks
  environment/Neovim-job-control-specific, not a plain logic bug.
- **Editing the file from a separate/new Neovim instance does NOT reach the
  detached preview** — verified: no live-push, no scroll-sync. The detached
  instance keeps its own buffer from spawn time; there's no file-watcher
  (`checktime`/`autoread`/`fs_event` — none exist) and `detach.lua` doesn't pass
  `--listen`, so there's no way to reattach to it either. In practice `detach`'s
  advertised "live buffer push because a real Neovim drives it" only works if
  something edits inside that exact instance — not achievable today.
- **Closing the preview tab does NOT stop the detached instance**, despite the
  start notification saying so. `User MDViewSessionEnded` only fires from
  `:MDViewStop` — nothing observes a tab close, and the default (non-isolated)
  `browser.open_mode` gives no process handle to detect it with anyway. The
  *only* reliable way to end a `:MDView detach` session right now is
  `Stop-Process`/`taskkill` on the pid from the start notification.

## Notes

- `start [file] [cwd=...]` and `toggle` use `ctx.rest` (composer's "leftover
  tokens" escape hatch) rather than a fixed positional schema, since `cwd=`
  can appear before or after the file arg — this is the pattern for any route
  whose grammar doesn't fit strict positional args (later formalized as
  Phase 6 flag support, motivated partly by this case and by `replacer.nvim`).
- `detach`/`standalone` **do** use the Phase 6 schema (`args` + `flags`), i.e.
  the thing `start` predates: `{name="file",type="PATH",optional=true}` plus
  `flags={{name="no-browser",bool=true}}` → `ctx.args.file` / `ctx.flags`.
  Gotcha hit while building these: once a route declares `args`, `ctx.rest`
  holds only *leftovers beyond the schema* — reading `ctx.rest` there silently
  gets you nothing. Declare a schema **or** use `rest`, never mix.
- `toggle` now calls `start`/`stop`'s functions **directly** (no more
  `vim.cmd("MDViewStart ...")` string round-trip).
- Found + fixed a pre-existing bug during verification: `:MDView log`
  (`show_in_scratch`) crashed with E95 on a second invocation in the same
  session (hardcoded scratch buffer name, no reuse/wipe guard). Flagged as a
  background task, fixed with a regression spec
  (`tests/nvim/log_scratch_spec.lua`) shortly after.
- Implemented `dev.binary_path`/`dev.web_root` (`lua/mdview/adapter/server_args.lua`):
  this config never actually existed before, despite the warning note above
  describing it as if it did — `server_args.resolve()` always called
  `install.ensure_binary()`/`ensure_client_bundle()` with no override, which is
  why overlay/zoom/cursor live-control silently did nothing against the normal
  `:MDView start` path. Mirrors `standalone.binary_path`'s pattern, plus a
  `$MDVIEW_DEV_BINARY`/`$MDVIEW_DEV_WEB_ROOT` env-var fallback for detached
  instances (which don't load this Lua config at all).
- Implemented `:MDView blanklines` (`blanklines.lua`, `browser.preserve_blank_lines`):
  no Rust/comrak change needed — `data-sourcepos` (start+end line) is already
  emitted unconditionally on every top-level block. `src/client/render/
  blankLines.ts` diffs consecutive blocks' sourcepos gap and inserts a plain
  spacer `<div>` (additive — never touches the theme's own margins) sized to
  the extra blank lines. Wired like `zoom`/`cursor`/`overlay`: config default +
  `?blanklines=1` URL param + live `/control` push. The `/control` wire key
  stayed `blankLines` (camelCase) even though the config field is
  `preserve_blank_lines` — matches the existing `cursor_marker` → `cursor`
  pattern (config name and wire key aren't required to match).
