# Testing images.nvim

How to manually test every implemented feature of `images.nvim`. One-time
setup, then one section per feature: prerequisites, steps, what to expect.

Repo: `E:\repos\images.nvim`. Spec: `plugins/personal/init.lua`
(`cmd = { "Image" }`, `ft = { "markdown", "vimwiki", "norg", "text" }` — so
either typing `:Image` or opening a buffer of one of those filetypes loads
it; the buffer-local keymaps and the double-click only exist after the
`FileType` autocmd fires, i.e. after opening such a buffer, not after the
command).

## Setup

Already wired into this config — nothing extra to install.

```vim
:checkhealth images
```

**Expect**: `nvim_ui_send` available (API level 14), terminal detected as
supporting OSC 1337 (this config runs WezTerm — `checkhealth` should say so,
not warn), clipboard tool found (`powershell.exe` on Windows), and the
`lib.nvim.deps` section naming ImageMagick/chafa as optional with a reason
each, not required.

Open Neovim from inside a repo with real markdown + images to test against —
`E:\repos\images.nvim` itself has none checked in, so either this
nvim-config repo's own `docs/` (if it has image links) or any personal notes
folder with screenshots works. `:Image testcard`-style generation isn't a
command; `images/testcard.lua` is only used internally by calibration (§2).

---

## 1. `:Image` bare / `:Image show` / hover — the core path

**Steps**

1. Open a markdown buffer with at least one `![alt](path.png)` link, real
   file on disk.
2. Move the cursor onto the link line (no command) — the image should
   appear as soon as `hover_mode = "overlay"` draws over the text.
3. Move the cursor away (`CursorMoved`) — the image should clear.
4. `:Image` with the cursor back on the link — same result via the command
   path (`images.hover()` internally, per `lua/images/bindings/usrcmds.lua`'s
   `default` route).
5. `:Image show <path>` with an explicit path, cursor anywhere.
6. Double-click (`<2-LeftMouse>`) on a link — same show. Double-click on
   plain text — normal word selection (`viw`), not swallowed.

**Expect**: `overlay` mode draws directly over the text and disappears on
`CursorMoved`/`CursorMovedI`/`InsertEnter`/`BufLeave`/`WinScrolled`
(`display.clear_events`). If the terminal check fails (§7), a block-character
ASCII approximation should render instead of nothing, given
`display.ascii_fallback.enabled = true` (default) and ImageMagick present.

**Also check `hover_mode = "float"`** (`opts.display.hover_mode`): the same
hover now opens a small unfocused floating window instead of drawing over
text — but only for this single-image path. Set it, restart, confirm
`:Image gallery` (§3) still uses its own grid layout regardless — the
README calls this out explicitly as "a container swap for one specific
path, not a global display mode", worth confirming it doesn't leak.

---

## 2. Placement accuracy and `:Image calibrate`

This is the feature the README spends the most words justifying, and the
telemetry (however thin — `calibration.load` 4 calls, `calibration.save` 1,
across 57 sessions) shows it has actually been run and its result is being
loaded back in on later sessions, which is worth confirming still holds.

**Steps**

```vim
:Image calibrate
```

**Expect**: a framed window with a generated test card fills it exactly.
`h`/`j`/`k`/`l` (or arrows) nudge row/column, the title shows the live
`row N col N` values, `r` resets, `q` cancels without saving, `<CR>` accepts
and offers to save. The footer states the whole-cell caveat
(`whole cells only, any smaller offset needs display.draw_inset`) — confirm
it's actually visible, not truncated in a narrower terminal window (the
code explicitly drops it rather than half-showing it — worth checking that
degrades cleanly rather than looking like a rendering bug).

**After accepting and saving**: restart Neovim, hover an image again — the
correction should apply automatically (read from
`stdpath("data")/images.nvim`, not written into your config). An explicit
`display.terminal_padding` in `setup()` should override the stored value —
set one, confirm it wins over whatever calibration saved.

**Also check** `:Image check` separately — it's the *other* diagnostic
(terminal support, not placement); the README is explicit these are
different failures ("images don't appear at all" vs. "images appear
offset"), so confirm `:Image check`'s output doesn't conflate the two.

---

## 3. `:Image paste` and `:Image screenshot` — the documentation workflow

**Steps**

1. Copy an image to the clipboard (screenshot tool, or copy a `.png` from a
   file manager).
2. In a markdown buffer, `:Image paste` (or `<leader>iv`).
3. Check the written file: `assets/<document-stem>-<timestamp>.png` next to
   the document, and a `![](assets/…)` link inserted at the cursor.
4. Now `<leader>is` (`:Image screenshot`) — should invoke the OS screenshot
   tool directly (Snipping Tool on Windows via `ms-screenclip:`), then
   continue exactly like paste once a new clipboard image appears.

**Expect on Windows specifically** (this machine): screenshot polls the
clipboard rather than reading a file directly — `windows_poll_interval_ms`
(600ms default) up to `windows_timeout_ms` (60s). **This is the one path
most likely to look broken when it isn't** — if it seems to hang, that's
still polling; give it the full minute. Try deliberately cancelling the
Snipping Tool (Esc) and confirm it times out with a clear message rather
than hanging forever.

**Also check**:
- A `Resources`/`Ressourcen` folder already present next to the document —
  paste/screenshot should reuse it silently instead of creating `assets/`
  alongside it (`paste.existing_dir_names`). `:Image info` on the newly
  inserted link is the fast way to confirm where it actually landed.
- No image on the clipboard at all — `:Image paste` should leave no folder
  created and report clearly, not silently create an empty `assets/`.
- A count before paste (`1<leader>iv`) prompts for a filename instead of
  using the template — confirm the prompt appears and any path component
  typed is stripped, extension forced to `.png`.
- `:Image replace <path>` overwrites an existing image file with the
  clipboard contents while keeping the same link — confirm the link text
  in the buffer is genuinely unchanged (only the file's bytes should
  differ).

---

## 4. `:Image gallery` / `:Image list` / `next` / `prev`

**Steps**

1. A buffer with 3+ image links. `:Image gallery` — all shown side by side.
2. `:'<,'>Image gallery` on a visual selection covering only 2 of them —
   only those 2 shown.
3. `:Image list` — a picker of every link in the buffer; pick one, it
   shows.
4. `<leader>in` / `<leader>ip` (or `:Image next`/`prev`) — steps through
   images in buffer order, wrapping at the ends.
5. `3<leader>in` — should land 3 images forward in one step (multiplies the
   step, not repeats it 3 times through 3 redraws).

**Expect**: gallery tiles are genuinely side by side with `display.
gallery_gap` cells between them, not overlapping. `next`/`prev` wrap
(stepping past the last image goes to the first). Remote (`http(s)`) links
should **not** appear resolved in the gallery even with
`display.remote.enabled = true` — the README states gallery/compare/
pickers/zen deliberately don't resolve remote images, only the single-show
path does; worth confirming that gap is real, not accidentally fixed since
the doc was written.

---

## 5. `:Image pickers` and `:Image compare`

**Prerequisites**: [snacks.nvim](https://github.com/folke/snacks.nvim) for
live thumbnail preview (soft dependency — without it, a plain list).

**Steps**

```vim
:Image pickers cwd
:Image pickers cfile
:Image compare cwd
```

**Expect**: `pickers cwd` browses every image under the working directory
with a live thumbnail per entry if snacks.picker is installed; `<Tab>`
multi-selects, confirming more than one shows a gallery instead of just the
first. `pickers cfile` narrows to the directory of the file under the
cursor. Without snacks installed, confirm it falls back to a plain
`vim.ui.select`-style list rather than erroring.

`compare cwd` should let you pick exactly two images and show them side by
side — with ImageMagick installed, scaled to true relative size (a 2x
larger export should visibly look larger, not identical); without it, side
by side at equal size with no size signal.

**Also check the exclusion/limit config**: `display.browse_exclude`
(`.deps`, `node_modules` by default, `.git` always) and
`display.browse_max_entries` (20000) — not easy to verify exhaustively, but
worth at least confirming a `node_modules` folder in the scan path doesn't
show up in the picker results if you have one handy.

---

## 6. `:Image zen`

**Steps**

```vim
:Image zen
```

with the cursor on an image link, or `:Image zen <path>` explicitly.

**Expect**: a real, resizable, focusable window (not an overlay) sized to
`display.zen.width`/`height` fractions of the editor, but — per the
README's `preserveAspectRatio` explanation — actually fit to the image's own
aspect ratio via `images.scale.fit_cells`, not just a fixed box (resize the
Neovim window and re-run; the zen window's aspect should still match the
image, not stretch). Resize the Neovim window while zen is open
(`WinResized`/`VimResized` autocmds) — the image should redraw to follow.
Closing the window (`:q` inside it) should clear the image
(`images.zen` `WinClosed` autocmd, `once`).

---

## 7. Terminal detection and the ASCII fallback

**Steps**

```vim
:Image check
```

**Expect**: reports whether the current terminal (WezTerm, in this config)
is recognized as supporting OSC 1337. On a first run in a genuinely
unsupported terminal (SSH session, tmux without passthrough — harder to
simulate on this machine, but worth knowing the shape of the check), the
warning should appear **once per session**, not repeatedly, and the image
should still draw via the ASCII fallback (`display.ascii_fallback.enabled`,
needs ImageMagick) rather than failing silently.

**If you want to force the fallback path** to actually see it: temporarily
set `display.assume_supported = false` and spoof an unrecognized
`$TERM`/`$WEZTERM_*` env var for a fresh Neovim instance — a real, if
slightly artificial, way to exercise a path this session's real terminal
won't naturally hit.

---

## 8. `:Image redact`

**Prerequisites**: ImageMagick installed.

**Steps**

1. `:Image redact <path-to-a-screenshot>`.
2. `v` or `<C-v>`, move to the opposite corner of something to black out,
   `<CR>` marks it. Repeat for a second box.
3. `u` — undo the last box. `3u` — remove up to 3, clamped to what exists
   (try it with only 1 box left, confirm it doesn't error).
4. `w` — burns the boxes in, writes `<name>.redacted.png` next to the
   original.

**Expect**: the **original file is never modified** — check its mtime/hash
before and after. The redacted boxes should be visibly padded beyond what
you selected (`display.redact.padding_cells`, default 1 cell) — the README
frames over-redacting as the deliberately safe failure mode, worth actually
seeing that margin rather than assuming it. Without ImageMagick, `:Image
redact` should report a clear error, not silently do nothing.

---

## 9. `:Image orphans`

**Steps**

1. Have at least one file in `paste.dir` (`assets/` by default) that no
   markdown link in the project currently references — delete a link line
   but leave the file, or copy a stray file in.
2. `:Image orphans`.

**Expect**: lists exactly the unreferenced files (not ones still linked
somewhere), offers to delete them one at a time — confirm a "keep this one"
choice actually leaves that specific file alone while still offering the
next. Run it again immediately after deleting one — the deleted file should
no longer appear.

---

## 10. `:Image export`

**Prerequisites**: either ImageMagick, or
[pdfport.nvim](https://github.com/StefanBartl/pdfport.nvim) (installed in
this config).

**Steps**

```vim
:Image export
```

with the cursor on an image link.

**Expect**: since pdfport.nvim is installed here, this should route through
its async `create()` API rather than a synchronous `magick` call — worth
confirming the command returns control immediately (doesn't block the UI)
if that's actually wired up, since the soft-dependency path is `pcall`'d
and could silently fall through to the old synchronous path if something's
misconfigured. Either way, a real PDF should land next to the source image.

---

## 11. Remote images (opt-in)

**Steps**

1. With `display.remote.enabled` at its default (`false`), hover a
   `![alt](https://example.com/image.png)` link — should do **nothing**
   (no network request, no image, ideally a clear message rather than dead
   silence).
2. Set `display.remote.enabled = true`, restart, hover the same link again.

**Expect**: step 2 downloads and displays the image, cached by URL
thereafter (hover it again — should not re-download; hard to observe
directly, but a slow/offline network shouldn't cause a second hover to
hang if the first succeeded). `display.remote.max_bytes`/`timeout_ms` are
harder to trigger deliberately — not essential to force, but good to know
they exist if a remote hover ever hangs unexpectedly long.

---

## 12. Integrations — markdown.nvim, filetree.nvim, open.nvim, context menu

**Steps**

1. With `markdown.nvim` installed (it is, in this config): a `<figure>`
   block with an `<img>` and a `<figcaption>` — put the cursor on the
   `<figcaption>` line specifically (not the `<img>` line) and hover/show.
2. `filetree.nvim`'s preview feature on an image file (if filetree exposes
   a preview keymap) — should use images.nvim as its first backend.
3. `:Open image` (open.nvim), or check `open.nvim`'s registry routes image
   files here.
4. Right-click an image link, if `nvzone/menu` is installed — otherwise
   this is structurally-verified-only (no dependency on `menu` itself is
   required, but nothing shows without it).

**Expect**: step 1 is the one worth actually confirming — the README states
`under_cursor` asks `figure_at()` when the line itself carries no target,
so a `<figcaption>` line (which has no `img src=` on it) should still
resolve to the figure's image. Without markdown.nvim, only the fallback
`![alt](target)` pattern is recognized (no HTML `<img>`/`<figure>` at all)
— worth knowing that as the degraded baseline if markdown.nvim is ever
disabled.

---

## What cannot fully be checked here, and why

- **The Windows Snipping Tool poll path in §3** is inherently timing- and
  UI-dependent — the plugin has no documented way to have the Snipping Tool
  write directly to a file, so it's polling the clipboard as a workaround.
  A slow or interrupted screenshot is the one place this plugin's behavior
  depends on external, non-deterministic OS UI rather than its own code.
- **Placement accuracy in §2** is inherently a per-terminal, per-font-size
  measurement — the README is explicit that no number written into any
  documentation would be correct for your setup, so "does calibration
  produce the right result" can only be judged by eye, not asserted here.
