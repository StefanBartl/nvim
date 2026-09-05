# Testing mdview.nvim

How to manually test every implemented feature of `mdview.nvim`. One-time
setup, then one section per feature: prerequisites, steps, what to expect.
Checkbox syntax (`- [ ]`) throughout.

Repo: `$REPOS_DIR\mdview.nvim`. Spec: `plugins/personal/init.lua` — `ft =
{ "markdown" }`, `cmd = { "MDView" }`, `build = "npm ci && npm run build:go
&& npm run build"`, `dependencies = { "StefanBartl/lib.nvim" }`. The real
config passed:

```lua
require("mdview").setup({
  browser = {
    highlighter = "hljs",       -- shiki has a known bug, see the spec's own comment
    focus = "nvim",             -- focus stays in Neovim after opening the preview
    cursor_marker = "caret",    -- byte-accurate inline caret, not line/section
  },
  experimental = {
    line_diff = true,           -- versioned diff transport instead of full-buffer push
    click_navigate = true,      -- already the plugin default
    reverse_scroll = true,      -- opt-in: browser scroll moves the Neovim cursor
  },
})
```

Three settings here are deliberately non-default (`cursor_marker = "caret"`,
`focus = "nvim"`, `experimental.reverse_scroll = true`, `line_diff = true`) —
worth confirming each is actually in effect, not silently reverted to a
plugin default, since a config-shape mismatch would fail quietly the same
way it did for learn-cli.nvim's `exercises_dir`/`exercises_path` case.

**Telemetry note**: 56 accumulated sessions (the plugin loaded 56 times via
`ft = "markdown"`), 128 instrumented functions, but **zero** recorded calls
in either dataset — the strongest "no evidence of real command-level use"
signal among these four plugins, stronger even than learn-cli.nvim's "never
loaded" (this one *does* load routinely, just apparently without `:MDView
start` ever firing a wrapped entry point). Note the caveat this implies
nothing about the Go relay / TypeScript client / Rust WASM renderer, which
are entirely outside what Lua-side telemetry can see — real preview sessions
could have run and simply not shown up here if the Lua-side dispatch
functions weren't the ones wrapped. Priority below is therefore entirely
from README/WORKFLOW/FEATURES reading — treat this whole file as first
real eyes on the plugin, same spirit as `docmap-desktop.md`.

## Setup

```vim
:checkhealth mdview
```

Per `docs/WORKFLOW.md`, this distinguishes the three most common failure
modes in one pass: (1) `curl`/`tar` missing → the first-run binary/client
download in `:MDView start` never completed — check the "installed assets"
section reports both the relay binary and a **complete** client bundle
(`index.html` + a `.wasm` file, not just a directory that exists); (2)
`lib.nvim` missing/half-installed → reported as an error, not a warning; (3)
a session claiming to run but `GET /health` not returning `ok` → a wedged
relay, distinct from "no session running" (itself reported as fine).

**Expect**: all three sections clean on a working machine, plus `curl`
confirmed on PATH (`docs/install.json`'s only real dependency).

---

## 1. `:MDView start` / `stop` / `toggle` / `open` — the core session lifecycle

**Steps**

1. Open a real `.md` file (this repo's own `README.md` works — it has
   headings, links, a task-list-shaped feature table).
2. `:MDView start`.

**Expect**: a `[mdview] preview: <url>` notification (per WORKFLOW.md,
always printed — the fastest way to tell an open-failure from a
content/room-key problem before reaching for `:checkhealth`). A browser tab
opens showing the rendered document. Given `focus = "nvim"`, **confirm focus
stays in Neovim** after the tab opens (not switched to the browser) — this
is the one non-default setting most likely to be visibly wrong if broken.

- [ ] `:MDView stop` tears down the relay process, detaches autocommands,
      and (in isolated browser mode) closes the tab.
- [ ] `:MDView toggle` starts if stopped, stops if running — confirm both
      directions from a single command.
- [ ] `:MDView open` (session already running) opens a **second** tab
      against the same session without spawning a second relay process —
      check no second port/process appears, just another browser tab.
- [ ] `:MDView start port=43000` overrides `server_port` for that spawn
      only — start again with a plain `:MDView start` afterward and confirm
      it does **not** inherit the override (restored right after the spawn,
      per the docs).

---

## 2. Live push and scroll sync — the actual live-mirror behavior

**Steps**

1. With a session running (§1), edit the buffer — add a line, don't save.
2. Save (`:w`).
3. Move the cursor to different headings/lines in the buffer.

**Expect**: step 1's edit appears in the browser tab within
`live_push_throttle_ms` (150ms default) — confirm it updates **before**
saving, not only on save. Step 2's save-triggered push should be
**immediate**, never throttled (per FEATURES/PREVIEW.md's explicit claim —
worth actually timing informally: does save feel instant vs. a typing-pause
push which has a small, perceptible delay). Step 3: the browser scroll
follows the cursor, **line-accurate** (via `data-sourcepos`) rather than a
percentage-of-file estimate — jump to the very last heading and confirm the
browser doesn't overshoot/undershoot proportionally.

---

## 3. Cursor marker — `caret` mode (this config's non-default choice)

**Steps**

```vim
:MDView cursor
```
(no argument — reports the current mode) then move the cursor around inside
a line, not just between lines.

**Expect**: reports `caret` (confirming the config value actually took
effect — see the intro's caveat about this). Unlike `line` (whole-line
highlight) or `section` (heading-spotlight), `caret` should show an **exact
inline** marker at the cursor's byte position, tracking horizontal cursor
movement within a line, not just which line you're on. Try `:MDView cursor
line` and `:MDView cursor section` too, to see the contrast directly, then
switch back to `:MDView cursor caret`. `:MDView cursor toggle` should flip
between the current mode and `off` — confirm it's genuinely a two-state
toggle, not cycling through all four.

---

## 3b. Visual selection mirror — the presenting switch (new 2026-08-31)

**Off by default.** This is the one to reach for when showing a document to
someone rather than editing it.

**Steps**

```vim
:MDView selection
```
then, in the buffer, `v` + some motion, `V` over three lines, and `CTRL-V`
over a column block. Then `:MDView selection` again to switch it back off.

**Expect**: with it **off**, selecting text changes nothing in the browser —
that is the point, an audience should not watch you select things you are only
operating on. Switching it **on** re-renders the tab once (invisible, but it is
why the first thing you point at appears without a hitch) and immediately draws
a selection that is already active. Then:

- `v` → the highlight follows the selection as it grows, across line ends.
- `V` → one bar per line, each hugging that line's text.
- `CTRL-V` → a column band, one rectangle per line.
- `<Esc>` → the highlight disappears at once.
- Switching it off again clears a highlight that is currently drawn, rather
  than leaving it stranded in the tab.

Also select **inside a fenced code block** — that path is resolved differently
(code blocks carry no inline source spans, so the block's own line structure is
used) and is exactly the case a README walkthrough hits.

*Known limit*: source columns include markup characters the browser does not
render (`**bold**` is four characters wider in the source), so at markup
boundaries the highlight can be a character or two off. Inside code blocks and
plain text it is exact.

---

## 3c. `highlighter = "nvim"` — the buffer's own colors (new 2026-08-31)

**Not this config's current value** (`hljs` is). Worth switching to once to see
it, since it is the whole point of the color_my_ascii pairing.

**Prerequisite**: `color_my_ascii.nvim` updated to the commit that added
`color_my_ascii.highlight` (2026-08-31), and mdview rebuilt — **including
`npm run build:go`**, since the relay grew a `/spans` route.

**Steps**: set `highlighter = "nvim"` in the mdview spec, restart, open a
markdown file with a ```lua or ```bash block *and* a ```yaml one, `:MDView`.

**Expect**: the lua/bash blocks are colored **exactly like the buffer next to
them** — same colorscheme, same groups. Change `:colorscheme` in Neovim, edit
one character to trigger a push, and the browser follows. The yaml block is
colored differently: it goes to highlight.js, because color_my_ascii's fence
map does not cover yaml. That mixture on one page is correct, not a bug — 31
fence tags against highlight.js's ~190 languages.

Reload the browser tab: the blocks must come back colored **immediately**, not
only after the next edit (the relay stores the last spans per room for exactly
this).

---

## 4. Reverse scroll and click-to-navigate (both enabled in this config)

**`experimental.reverse_scroll = true`** — non-default, deliberately turned
on here.

**Steps**

1. With a session running, scroll the **browser tab** (not Neovim).
2. Click a relative Markdown link in the preview (e.g. a link to another
   `.md` file in this repo, or an in-page anchor).
3. Click an **external** link (a real `http://` URL) and a link with a
   modifier held (e.g. Ctrl/Cmd-click for "open in new tab").

**Expect**: step 1 moves the Neovim cursor to follow, with a small
noticeable lag (documented as polling-based, not instant — confirm it's
"small lag", not several seconds or completely unresponsive). Step 2: the
browser does **not** navigate on its own (there's no web server behind those
relative paths) — instead Neovim opens the target document, which flows back
into the preview through the normal push path, i.e. the browser tab now
shows the *new* file. Step 3: external links and modifier-clicks are left
untouched — browser handles them natively (opens in a real new tab / follows
the real URL), confirming the click interceptor is scoped correctly rather
than swallowing every click.

---

## 5. Task-list checkbox sync and text-field sync

**Steps**

1. Write a GFM task list in the source: `- [ ] test item`. Start the
   preview.
2. Click the checkbox **in the browser**.
3. Add a raw-HTML field: `Title: <input type="text" name="title">`, restart
   the preview (or let it re-render), edit the field's value in the browser
   and click elsewhere (blur).

**Expect**: step 2 — the source buffer's `- [ ]` becomes `- [x]`
**immediately** in Neovim (check `:e!`-free, i.e. the live buffer itself
changed, not just the file on disk) — confirm bullet style/indentation/line
ending are preserved, only the marker character changed. Step 3 — the typed
value should **not** write back per-keystroke (type a few characters,
check the source hasn't changed yet), only on blur/Enter; after blur, the
source's `<input value="...">` should contain the typed text, HTML-escaped
(try typing `</textarea><script>` deliberately into a `<textarea name="notes">`
field and confirm it round-trips as inert escaped text, not live markup).

**Also check the disable paths**: `require("mdview").setup({ sync_checkboxes
= false })` — checkboxes should render but clicking should do nothing to the
source (read-only). Same for `sync_fields = false` on the text-field case.

---

## 6. Zoom, overlay (TOC), and breadcrumbs

**Steps**

```vim
:MDView zoom +
:MDView zoom +
:MDView zoom
:MDView zoom 500
:MDView zoom reset
:MDView overlay toc on
:MDView overlay list
:MDView breadcrumbs
```

**Expect**: `zoom +` steps by 0.1 (10%) each press; bare `zoom` reports the
current factor. `zoom 500` — **should clamp to 300% and say so explicitly**
(the requested value, the allowed range, and what was actually used) rather
than silently applying 300% with no explanation — this was a specifically
fixed behavior (2026-08-24 per FEATURES/PREVIEW.md), worth confirming it
still reports rather than silently clamps. `zoom reset` returns to 100%.

`overlay toc on` mounts a floating TOC on top of the preview **without
disabling** scroll sync or the cursor marker — move around the buffer with
the overlay on and confirm both still work simultaneously (additive, not
exclusive, per WORKFLOW.md). `overlay list` should show `toc: on`.
`breadcrumbs` opens a scratch buffer with a session outline of visited
sections — visit a few different headings/files first (via §4's
click-navigate) and confirm they're all recorded in order.

---

## 7. Theme switching and `highlighter = "hljs"`

**Steps**

```vim
:MDView theme
:MDView theme dark-dimmed
:MDView theme github-light
```

**Expect**: bare `theme` reports the current theme. Switching applies live
to the open tab (no reload) and persists into the shared config (a
subsequently reopened tab starts on the new theme). Since this config
deliberately forces `highlighter = "hljs"` (not the default, due to a known
Shiki bug per the spec's own comment), open a code fence with a real
language (e.g. \`\`\`lua) in the preview and confirm syntax highlighting
renders correctly under whichever theme is active — this is the concrete
thing to watch for regressions on, since it's the explicit workaround for a
known bug in the alternative highlighter.

---

## 8. Reveal private blocks, and blank-line handling

**Steps**

Write a fenced block using whatever "private" syntax this plugin defines
(check `docs/FEATURES/RENDERING.md#private-blocks` for the exact marker),
start the preview.

```vim
:MDView reveal
:MDView reveal on
:MDView blanklines
```

**Expect**: private blocks are hidden from the rendered preview by default;
`reveal`/`reveal on` shows them; toggling back off hides them again without
a reload. `:MDView blanklines` toggles how blank lines affect rendered
spacing — compare a document with intentional blank-line paragraph breaks
before and after toggling to see a visible difference.

---

## 9. In-editor preview tab — `:MDView preview-tab`

**Steps**

```vim
:MDView preview-tab
```

**Expect**: opens a **read-only**, Treesitter-highlighted mirror of the
buffer in a new Neovim tab — no browser, no relay process spawned (confirm
via `:MDView weblogs`/process check that nothing new started). Edit the
source buffer and confirm the preview tab updates via its own
`TextChanged`/`BufWritePost` autocommands. Confirm this is genuinely
**decoupled** from §1's browser session: with a `:MDView start` session
already running, none of §2-§8's live-preview controls (`cursor`, `zoom`,
`overlay`, ...) should have any visible effect on this tab.

**Also check** `open_preview_tab = true` in a scratch `setup()` call, then
`:MDView start` — should open this tab **instead of** the browser, while the
relay/WASM pipeline keeps running underneath (confirm `:MDView open`
afterward still successfully brings up the browser tab, without restarting
anything).

---

## 10. Standalone mode — outlives Neovim

**Prerequisites**: needs a relay binary built with `--watch` support
(v0.3.0+, per docs — check `:MDView standalone` refuses fast with a clear
message rather than spawning a broken process if the cached binary predates
this).

**Steps**

```vim
:MDView standalone
```
then close Neovim entirely (`:qa`) and check the browser tab.

**Expect**: the preview **keeps working** after Neovim exits — the relay
polls the file on disk directly (~4×/s). Edit the file with an external
editor (not Neovim) while Neovim is closed and confirm the browser preview
picks up the change within ~250ms. Confirm what's explicitly **not**
available in this mode: no scroll sync, no cursor marker (since there's no
Neovim cursor to track), and unsaved edits are irrelevant (it previews the
file as saved, never a live buffer).

---

## 11. Diagnostics — `log` / `weblogs` / `file-log` / `diagnose`

**Steps**

```vim
:MDView log
:MDView weblogs
:MDView file-log on
:MDView file-log status
:MDView diagnose
```

**Expect**: `log` shows the plugin's own Lua-side ring (launcher, live-push,
`ws_client`) — per WORKFLOW.md, this is the layer for "why didn't my
keystroke reach the relay". `weblogs` shows the relay process's own stdout,
including `[client]`-tagged lines forwarded from the browser — the layer for
"the relay started but the tab shows nothing". `file-log on` should switch
persistent disk logging on (confirm nothing was written to disk before this,
per "opt-in, off by default") and `status` reports the state without
changing it. `diagnose` writes **one file** covering config, install status,
and session state together, and opens it immediately — confirm it's a single
self-contained report, not a pointer to check the other three separately.

---

## 12. `experimental.line_diff` — versioned diff transport (enabled in this config)

**Steps**

With a session running and `line_diff = true` active (this config's
setting), make a **small, single-line edit** far into a large document, then
check `:MDView weblogs` or network activity for evidence of what was sent.

**Expect**: per `docs/configuration.md`, only the changed lines are sent per
edit rather than the whole document — hard to observe directly without
instrumentation, so the practical check is the **self-healing** claim
instead: after making several small edits, save the file (or make 25+ edits)
and confirm the preview is still byte-correct afterward (a full snapshot is
sent on save / every 25 edits specifically to correct any drift) — introduce
a edit rapidly enough to plausibly desync (many quick small edits in a row)
and confirm the eventual full-snapshot resync catches up rather than the
preview staying permanently wrong.

---

## What cannot be checked here, and why

- **Link hover previews in the browser tab itself** (`docs/FEATURES/PREVIEW.md`'s
  own hover feature, the browser counterpart to markdown.nvim's in-editor
  hover) — genuinely testable (hover a link in the rendered tab, confirm a
  popup appears with image/text/URL/anchor preview per target type, and that
  a PDF link shows name-only per the documented limitation) but omitted from
  the numbered list above only for space; worth a pass alongside §1 using the
  same document.
- **The security posture** (loopback-only bind, per-session token, Origin
  allowlist, comrak→ammonia sanitization of untrusted Markdown/HTML) is
  real and documented in `docs/FEATURES/SECURITY.md`, but verifying it needs
  deliberately hostile input and/or a second machine on the network
  attempting to reach the relay — a security-review pass, not a feature
  click-through, and out of scope for this checklist.
- **`experimental.any_file`** (off by default, and explicitly documented as
  "not yet exercised through real Neovim use" by the plugin's own
  WORKFLOW.md) is not part of this config and not covered here — if it's
  ever turned on, treat any surprise as reportable rather than a known
  caveat, per the plugin's own framing.
