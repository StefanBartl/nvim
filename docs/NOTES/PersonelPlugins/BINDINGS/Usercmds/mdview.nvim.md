# mdview.nvim — `:MDView <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion).
Replaces the old 10 flat `:MDViewX` commands (fully removed, no alongside
period). This was the **first** composer migration — the pilot for the whole
`lib.nvim.usercmd.composer` module.

Source: `lua/mdview/bindings/usrcmds/init.lua` + one action module per
subcommand (`start/`, `stop.lua`, `open.lua`, `toggle.lua`,
`standalone.lua`, `show_weblogs.lua`, `preview_tab.lua`, `diagnose.lua`,
`theme.lua`, `log.lua`, `file_log.lua`, `cursor.lua`, `sync.lua`, `zoom.lua`,
`reveal.lua`, `blanklines.lua`, `overlay.lua`, `breadcrumbs.lua`)
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `docs/standalone.md`,
`README.md`, `doc/mdview.txt`

### Session lifecycle

| Command | Effect |
| --- | --- |
| `:MDView start [file] [cwd=...] [port=N]` | Start the relay + open the preview. `port=N` **added 2026-08-24** |
| `:MDView stop` | Stop the relay, detach autocommands |
| `:MDView toggle [file] [cwd=...]` | Start if stopped, stop if running |
| `:MDView open` | Re-open a browser tab against the running session |
| `:MDView standalone [file] [--no-browser]` | Preview with **no nvim in the chain** (relay watches the file on disk); outlives `:qa` |
| `:MDView preview-tab` | In-nvim tab preview (Treesitter mirror; no relay/browser) |

### Live preview controls (push to the open tab, no reload)

| Command | Effect |
| --- | --- |
| `:MDView theme [name]` | Switch preview theme (tab-completed) |
| `:MDView cursor [line\|caret\|section\|off\|toggle]` | Cursor marker mode in the preview; `toggle` flips section on/off specifically |
| `:MDView sync [action]` | Pause/resume nvim→browser scroll sync (paused ⇒ "⏸ paused" pill in the tab) |
| `:MDView zoom [+\|-\|reset\|<factor>]` | Preview font-size zoom. An out-of-range number is clamped **and reported** since 2026-08-24 |
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

## background preview = `standalone` only (`detach` removed)

|              | Survives `:qa` |  Unsaved buffer  | Scroll sync / cursor |
| ------------ | -------------- | ---------------- | -------------------- |
|   `start`    |       ✗        |        ✓         |          ✓           |
| `standalone` |       ✓        | ✗ (file on disk) |          ✗           |

- **`standalone`** = relay's own `--watch` mode, no nvim at all. Runs on
  `server_port + 100` (43319) so it can sit next to a normal session.
  Previews the file **as saved**. Reliable in every test (open, live-update on
  save, no interference with a normal session).
- Terminal entry points: `scripts/mdview-bg.sh` / `.ps1` — now run a throwaway
  headless nvim that fires `:MDView standalone` then quits (verified: launcher
  exits in ~240ms, relay survives detached). `nvim +MDView --background file.md`
  is NOT valid nvim syntax (`+cmd` takes no trailing flags); the wrappers are
  the supported spelling.
- ⚠️ `standalone` needs a relay with `--watch` (**v0.3.0+**). The installed
  v0.2.0 release binary does **not** have it. Until a release ships, set:
  ```lua
  standalone = { binary_path = "E:/repos/mdview.nvim/native/server/mdview-server.exe" }
  ```
  Env override for the wrappers: `$MDVIEW_STANDALONE_BIN`. mdview probes the
  binary and errors clearly if it's too old (it used to fail completely
  silently, since a detached process has no pipes).

### Why `detach` was cut (my test findings, confirmed by Claude's own analysis)

The first commit shipped `:MDView detach` (a second headless nvim). Testing
killed it — it was strictly dominated by `standalone`:

- **Browser tab opened after 10–15 min, or never** (`mdview-bg.ps1` too). The
  headless nvim's main loop is input-poll-driven; idle with no stdin, it
  services pending libuv job/pipe events on very coarse wakeups. `standalone`'s
  browser-open is one direct Go-side `rundll32` call — no headless nvim in the
  path, so none of this.
- **Editing the file from another nvim did NOT reach the detached preview** —
  no live-push, no scroll-sync. The detached instance keeps its spawn-time
  buffer; no `checktime`/`autoread`/`fs_event`, and no `--listen` to reattach.
  So detach's advertised "live buffer because a real nvim drives it" never
  materialised — nothing edits inside a headless instance.
- **Closing the tab did NOT stop it** — nothing observed a tab close; only
  `taskkill` on the pid worked.

Net: static snapshot + flaky vs. `standalone`'s live-file-following + robust.
Decision (2026-07-26): remove `detach`, `detach.lua`, the `User
MDViewSessionEnded` event (was only there to auto-quit the detached instance),
and repoint the wrappers at `standalone`. `detached.lua` stays — `standalone`
uses its `spawn`/`resolve_target`. Rationale preserved in
`docs/Roadmap/KONZEPT_headless_und_standalone.md`.

## Notes

- `start [file] [cwd=...]` and `toggle` use `ctx.rest` (composer's "leftover
  tokens" escape hatch) rather than a fixed positional schema, since `cwd=`
  can appear before or after the file arg — this is the pattern for any route
  whose grammar doesn't fit strict positional args (later formalized as
  Phase 6 flag support, motivated partly by this case and by `replacer.nvim`).
- `standalone` uses the Phase 6 schema (`args` + `flags`), i.e. the thing
  `start` predates: `{name="file",type="PATH",optional=true}` plus
  `flags={{name="no-browser",bool=true}}` → `ctx.args.file` / `ctx.flags`.
  Gotcha hit while building it: once a route declares `args`, `ctx.rest` holds
  only *leftovers beyond the schema* — reading `ctx.rest` there silently gets
  you nothing. Declare a schema **or** use `rest`, never mix.
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
- **Bug found + fixed: cursor marker stopped updating after switching
  buffers a few times, even after `:MDView cursor off` + `on` again.**
  `scroll_sync.lua` always sent the outgoing scroll/cursor ping to the
  *buffer's own path*, but `live_push`/`buffer_switch`/`control.lua` all
  route to `state.preview_key` (the room the open tab actually watches) in
  `browser.behavior = "reuse"` (the default). After a buffer switch the ping
  landed in a room nobody was listening to, so the marker (which "rides the
  scroll-sync ping") silently went stale — toggling the mode didn't help
  because `control.lua` routed correctly, the mode DID change, it just never
  got a position ping to draw. Extracted the shared routing rule into
  `lua/mdview/helper/target_key.lua` (this was the third independent inline
  copy of the same logic — exactly why it drifted) and pointed `scroll_sync`,
  `live_push`, and `control.lua` at it. Repro'd and verified with a script
  that stubs `ws_client.send_scroll`/`send_control` and asserts the room key
  before/after a buffer switch; regression test added
  (`tests/nvim/scroll_sync_routing_spec.lua`, mirrors `buffer_switch_spec.lua`).
  Also added `:MDView cursor toggle` (flips `section` on/off specifically) per
  request.
- **`:MDView start` "browser doesn't open" on Windows — NOT yet root-caused;
  my first hypothesis was WRONG.** I first guessed `normalize.path_for_url` left
  a bare `C:` in the URL that `rundll32 FileProtocolHandler` chokes on, and
  changed it to `vim.uri_encode(..., "rfc2396")` (commit `3d62ddf`). Then I
  tested it empirically and **disproved it**: with fresh ports (to avoid a
  leftover tab reconnecting and faking the result), real `rundll32` opens a
  working tab with **both** the encoded AND the unencoded URL, and the Lua
  `fn.jobstart({rundll32...})` path connects fine too. Worse/better: I
  reproduced the **full real `:MDView start`** flow headless with a local build
  (`dev.binary_path`/`web_root`, fresh port) and it **works** — `file_log`
  showed `[client] boot: connecting → websocket connected → first render ok`. So
  the code path is intact on my machine. The `rfc2396` change is harmless/
  slightly cleaner (matches the Go side's QueryEscape) but is **not** the fix for
  whatever the user hit. Real cause is **environmental** — leading suspicion:
  `standalone` uses the user's local build (`standalone.binary_path`), while
  `start` may be running the downloaded v0.2.0 assets unless `dev.binary_path`/
  `dev.web_root` are set; or a `browser.open_mode="isolated"`/`focus="nvim"`
  config path. **Next step: get `:MDView weblogs` output right after `:MDView
  start` (does `[client] boot: connecting` appear? → bisects open vs render) and
  the user's `browser.*` + whether `dev.*` is set.** Diagnostic method note:
  ALWAYS use a fresh port per rundll32/browser test — a still-open tab from a
  previous test reconnects to the new relay on the same port and fakes a
  "connected" result (burned 20 min on exactly that).
- **Feature: task-list checkbox sync (`sync_checkboxes`, default true).** Tick a
  `- [ ]` in the preview → written back to the source, so it persists across
  re-render. comrak already puts `data-sourcepos` on the task `<li>`, so no Rust
  change (same trick as blanklines). `src/client/render/taskToggle.ts` enables
  the (comrak-`disabled`) checkbox, reads the source line, POSTs `<line>:<0|1>`
  to a new `/toggle` relay route. **Standalone** = relay owns the file, flips
  the marker in place (`native/server/internal/source/toggle.go`), watcher
  re-broadcasts — self-contained, verified e2e. **`:MDView start`** = buffer may
  have unsaved edits, so the relay queues (`relay/toggle.go`) and `inbound_poll`
  drains + edits the buffer (same poller as click-nav; now runs whenever
  `sync_checkboxes` is on, not just for the experimental flags). `?sync=0`
  renders checkboxes read-only. Commit `791e29b`. **Needs a v0.3.0 relay+client
  or the local `dev.*`/`standalone.binary_path` build to actually work.**
- **Feature: text-field sync (`sync_fields`, default true).** Commit `0ede98a`.
  Write `<input type="text" name="x">` / `<textarea name="y">` in the source →
  editable in the preview; commit on **`change`** (blur/Enter, NOT per keystroke
  — a per-keystroke write-back would re-render and yank the focused field) →
  value written back. **Key difference from checkboxes:** raw HTML has **no
  `data-sourcepos`** (verified: comrak only annotates real markdown blocks), so
  there's no line to target — matched by the **`name` attribute** instead
  (`source/field.go` / `inbound_poll.handle_field` scan for `name="…"` and
  rewrite the `value` attr or `<textarea>` body). Value is HTML-escaped both
  sides (byte-identical Lua/Go) so `</textarea><script>` stays inert. Sanitizer
  (`lib.rs`) now allows `<textarea>` + `<input>` name/value/placeholder, never
  `formaction`/`form`/`on*`. `?fields=0` = read-only. `name` must be unique +
  double-quoted. New `/field` route + `relay/field.go` queue (start mode). Same
  "needs v0.3.0 or local build" caveat. Verified e2e: input value insert +
  multi-line textarea rewrite + escape round-trip + XSS-inert, no console errors.
  - **Deferred:** which other tags? Only `<input>`/`<textarea>` for now.
    `<select>`, radio groups, etc. would each need their own value-encoding +
    write-back; not done.

## `port=` and the zoom report (2026-08-24)

**`:MDView start port=N`** overrides `server_port` for that spawn only — for
a firewall rule or port-forward that has to match exactly on one machine,
without editing a config everyone else shares. `port=` rather than `--port`,
because `cwd=` is already this command's convention.

It is set on the live config and **restored right after the spawn**:
`adapter/server_args` reads `config.defaults.server_port` at spawn time and
sits several layers down. Restoring is what keeps it a one-run override —
otherwise the next plain `:MDView start` would silently inherit it. Out of
range (1–65535) is refused; with a server already running it is ignored with
a warning, exactly as `cwd=` is.

**Zoom clamping was never missing** — the completion audit's entry described
where the check sits (in the handler, not the route), not its absence. The
real gap was that `zoom 500` applied 300% silently, so the value used
differed from the one asked for with nothing said. It now reports the
requested value, the allowed range, and what it used.
