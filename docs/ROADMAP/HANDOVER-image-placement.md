# Handover — image placement offset (images.nvim / hover)

Running log for the "the image does not sit inside its frame" problem. Kept
because it has already outlived several sessions and will likely outlive
more: every measurement, every ruled-out cause, and what to try next.

**Status:** unresolved. The offset is *smaller* without a file tree, but not
zero. Neovim's arithmetic is verified correct; the remaining error is below
Neovim, in how WezTerm turns cell coordinates into pixels.

**Last updated:** 2026-08-28

---

## 1. The symptom

An image drawn into a floating window (hover preview, `:Image show`) lands
beside its own frame — shifted right and slightly down. `:Image calibrate`,
which draws into a centred `relative = "editor"` window, sits **correctly**
on the same machine at the same time. That contrast is the core puzzle.

Severity depends on horizontal position:

| Setup | Float at column | Visible offset |
| --- | --- | --- |
| No file tree | 33 | small (~1–2 cells), "much better but not perfect" |
| File tree open (50 cols) | 83 | large (~27 cells) |

---

## 2. Environment

| | |
| --- | --- |
| Machine | Personal PC (**not** the workstation where this last worked) |
| Terminal | WezTerm on Windows 11 |
| Neovim | 0.12.x, `columns=170 lines=37` |
| Font | JetBrainsMono Nerd Font |
| `cell_aspect` | `0.46` (set in `plugins/personal/init.lua`) |
| `draw_inset` | `1` (default) |
| `terminal_padding` | `{ row = 0, col = 0 }` — calibrated to zero on this machine |
| Protocol | OSC 1337 via `nvim_ui_send` |

**Changed vs. the workstation where placement was correct:**

1. Different physical machine (different DPI / font rendering).
2. Neovim's shell switched from PowerShell 5.1 to pwsh 7
   (`docs/ROADMAP/personal/All/FINISH/Merged_Finished.md`).
   **Assessed as a red herring:** image placement is pure OSC 1337 through
   `nvim_ui_send`; no shell is involved. The shell only matters for
   ImageMagick calls (SVG conversion, redact, export).
3. **WezTerm `window_padding` is `"1cell"` on all four sides**, with
   `tab_bar_at_bottom = true` —
   `E:/repos/Configs/Terminals/wezterm/config/experimental.lua:68`, loaded
   unconditionally from that repo's `init.lua:18`. **This is the prime
   suspect, see §6/H1.**

---

## 3. Ruled out, with evidence

### 3.1 Wrong `cell_aspect` — ruled out
`:Image calibrate` was extended (2026-08-28) to measure `cell_aspect` with
`+`/`-` alongside `terminal_padding`. The value in effect is `0.46` and the
calibration card fills its frame exactly (screenshot 1 of that session).
A wrong aspect shows as a letterbox strip, not a positional shift.

### 3.2 A float overhanging the screen edge — ruled out
This is the failure documented in `images.nvim/docs/ROADMAP/TERMINALS.md §4`:
Neovim silently moves an overhanging float back inside, but
`nvim_win_get_position` keeps reporting the requested position.
`images.anchor.placed_position` corrects for it.

**It is not this.** Every probe run reports `fits_h=true` — the float never
overhangs, so `placed_position` is never even engaged.

Verified separately that the correction still works when it *is* engaged
(headless, `columns=170`):

| requested col | extent | fits | sent col |
| --- | --- | --- | --- |
| 10 | 82 | yes | 13 |
| 130 | 82 | **no** | **91** (= 170−82+border+inset+1) |
| 160 | 82 | **no** | **91** (clamped identically) |

### 3.3 The hover bypassing `images.anchor` — ruled out
Hypothesis was that the hover drew through a lower-level path that never got
the `placed_position` fix. It does not:
`lib.nvim.hover.preview.media.draw_into` calls
`anchor.draw(win, "full", png, { defer = true })`.

### 3.4 `relative = "cursor"` reporting window-relative coordinates — ruled out
Hypothesis: with a file tree on the left, a cursor-relative float might
report a position relative to its parent window rather than the editor,
which would explain an offset the width of the tree.

Headless test — 50-column split on the left, cursor in the right window at
column 5:

```
active window starts at col=51
float relative=cursor: nvim_win_get_position reports row=1 col=56   (= 51 + 5)
  -> sent: row=4 col=59 cols=58 rows=10
```

Reported correctly and absolutely.

### 3.5 Neovim-side arithmetic in general — ruled out
Seven live measurements through `hover_probe.lua` (§5), with and without the
file tree. In **every** case:

```
SENT col == (reported col + border + 1) + draw_inset
SENT row == (reported row + border + 1) + draw_inset
```

which is exactly the intended formula. Full data in §4.

---

## 4. Measurements (2026-08-28, live, WezTerm)

`screen: columns=170 lines=37`, `draw_inset=1`,
`terminal_padding={row=0,col=0}`, `cell_aspect=0.46` throughout.

### Without file tree

| file | SENT row/col | float reported row/col | content | expected origin | Δ |
| --- | --- | --- | --- | --- | --- |
| pdf_inline_hover.png | 8 / 36 | 5 / 33 | 80×18 | 7 / 35 | +1 / +1 |
| image_inline_hover.png | 7 / 36 | 4 / 33 | 80×19 | 6 / 35 | +1 / +1 |
| pdf_inline_hover.png | 10 / 36 | 7 / 33 | 80×18 | 9 / 35 | +1 / +1 |
| pdf_inline_hover.png | 10 / 28 | 7 / 25 | 80×18 | 9 / 27 | +1 / +1 |

### With file tree (50 columns)

| file | SENT row/col | float reported row/col | content | expected origin | Δ |
| --- | --- | --- | --- | --- | --- |
| image_inline_hover.png | 7 / 86 | 4 / 83 | 80×19 | 6 / 85 | +1 / +1 |
| pdf_inline_hover.png | 8 / 86 | 5 / 83 | 80×18 | 7 / 85 | +1 / +1 |
| pdf_inline_hover.png | 10 / 86 | 7 / 83 | 80×18 | 9 / 85 | +1 / +1 |

`fits_h=true` in all seven. The file tree shifts the float by exactly 50
columns (33 → 83), which is its width — consistent and correct.

### The contradiction to explain

Identical, provably correct cell coordinates produce a **small** offset at
column 33 and a **large** one at column 83. A constant pixel error
(e.g. window padding) cannot do that. Something that scales with the column
index can.

### Stale floats seen in the data

Two runs list extra floats (`1007`, `1008`) at `row=28 col=94` / `row=35
col=104` while only one hover was open. Probably notification windows
(nvim-notify) rather than leftovers, but worth remembering: **OSC images
persist**, so a float that vanishes without `images.terminal.clear()` leaves
its picture on screen and can be mistaken for a misplaced one.

---

## 5. Tooling

`docs/TESTING/hover_probe.lua` — wraps `images.terminal.draw` and reports,
per draw: screen size, the cell coordinates sent, every open float's
reported geometry and expected content origin, plus the effective config.
It only observes; the image still draws.

```vim
:luafile docs/TESTING/hover_probe.lua
" hover an image, then:
:messages
```

Idempotent: loading it twice wraps the original, not the previous wrapper.

Fixtures: `docs/TESTING/image_hover.md` (markdown links + bare paths),
`docs/TESTING/image_hover.txt` (same, non-markdown filetype).

### `column_scale_probe.lua` — the constant-vs-proportional test

`docs/TESTING/column_scale_probe.lua` draws the *same* generated test card at
four columns spread across the screen (on a 172-column screen: 8, 51, 94,
137), each on its own row, with a text marker `|<- col N` on the line above
marking where that image's left edge belongs.

```vim
:luafile docs/TESTING/column_scale_probe.lua
```

Read it off the screen, no pixel measuring needed:

- **Every image displaced by the same amount** → constant offset.
  `display.terminal_padding` can compensate it; calibrate and done.
- **Displacement grows from top to bottom** → proportional error.
  `terminal_padding` **cannot** fix it — it adds a fixed number of cells,
  and what is needed is a scale correction.

**Already run (2026-08-28) — see §6/H2.** Cards landed at identical pixel
positions with and without the file tree, which ruled out a proportional
error and proved `images.terminal.draw` correct. Note the caveat in H2 about
its markers sitting at buffer rather than screen columns.

### `float_position_probe.lua` — is a float where it says it is?

`docs/TESTING/float_position_probe.lua`. **Open the file tree first**, then:

```vim
:luafile docs/TESTING/float_position_probe.lua
```

Opens a bordered float the way the hover does (`relative = "cursor"`) and
draws a test card into it through `images.anchor.draw` — the same call the
hover makes. Frame and card both come from the same reported position, so
they either agree or they do not.

- card **inside** the frame → reported position correct; look elsewhere.
- card **beside** the frame → `nvim_win_get_position` is the bug.

Press `q` to clear.

---

## 6. Open hypotheses, most promising first

### H1 — WezTerm `window_padding` — **TESTED, RULED OUT** (2026-08-28)

Padding was set to `{ left = 0, right = 0, top = 0, bottom = 0 }` and WezTerm
restarted. Confirmed in effect: the screen grew from `170×37` to **`172×39`**,
exactly the 2 columns and 2 rows the padding had been consuming.

**The offset survives.** With the file tree open the image is still displaced
by roughly the same amount.

What *did* change: **without** the file tree the placement now looks correct
(screenshots 1–3 of that run), where before it was "much better but not
perfect". So padding was one contributing term — but not the cause.

| | before (`1cell`) | after (`0`) |
| --- | --- | --- |
| screen | 170×37 | 172×39 |
| no file tree, float at col | 33 | 31 |
| no file tree, visual | small offset | **looks correct** |
| file tree, float at col | 83 | 79 |
| file tree, visual | large offset | **still large** |

The arithmetic remained provably correct throughout (Δ = +1 = `draw_inset`
in all six new measurements, `fits_h=true` everywhere).

That the error is small at column 31 and large at column 79 — with padding
now zero — is the strongest evidence yet for a **proportional** error
(H2), and against anything that adds a constant.

### H1-old — the original padding reasoning (kept for the record)

**Confirmed present:**
`E:/repos/Configs/Terminals/wezterm/config/experimental.lua:68`

```lua
Config.window_padding = { left = "1cell", right = "1cell", top = "1cell", bottom = "1cell" }
```

Its own comment says cell units are chosen so the padding is "by definition
a whole multiple of the cell size". **That is only half true, and
`TERMINALS.md §5` says so explicitly:**

> Careful: by our own measurement `"1cell"` refers to the cell **width**, for
> `top`/`bottom` as well; vertically that is therefore not a multiple of the
> cell height and the offset remains.

So the vertical padding is already known to be wrong-by-construction on this
setup. The wezterm config comment and the images.nvim measurement log
contradict each other — the measurement log wins, it was measured.

**Why this can produce a *proportional* error, not just a constant one.**
With `left`/`right` padding, WezTerm's text grid gets `W − 2×pad` pixels for
its 170 columns, so a grid cell is `(W − 2×pad)/170`. If image placement
computes its origin from a cell width derived from the *full* window width
instead (`W/170`), the pixel error is:

```
error(col) = col × ( W/170 − (W − 2·pad)/170 ) = col × 2·pad/170
```

— zero at the left edge and growing linearly rightwards. That is exactly the
observed shape:

| Float at column | Observed offset |
| --- | --- |
| 33 (no file tree) | small |
| 83 (file tree open) | large |

And it explains the calibration paradox: `:Image calibrate` opens a centred
`relative = "editor"` window at roughly **column 34** on a 170-column screen
— the same low column where the error is small enough to look correct. The
tool is not more accurate than the hover; it just happens to sit where the
error is smallest.

**The test — cheap, decisive, do this first:**

1. In `experimental.lua`, set `Config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }`.
2. Restart WezTerm **completely** (not just a new tab — `TERMINALS.md`
   warns that terminal state persists).
3. Re-run `hover_probe.lua` and hover with **and** without the file tree.

- Offset gone in both → confirmed; decide whether zero padding is acceptable
  or whether a pixel value that is a true multiple of the *cell height*
  vertically and *cell width* horizontally also works.
- Offset unchanged → H1 is wrong, move to H2.

### H2 — proportional / cell-width error — **RULED OUT** (2026-08-28)

`column_scale_probe.lua` drew the same card at columns 8, 51, 94, 137.

**Result, and it is unambiguous:** with the file tree open *and* closed, the
four cards land at **identical pixel positions** on screen. Every card sits
exactly where its screen column says it should. No growth from top to
bottom, no scaling — `images.terminal.draw` places correctly at every
column tested.

So the error is **not** proportional, and `images.terminal.draw` is not the
culprit. Both are now excluded.

> **Caveat on that probe's design.** Its text markers sit at *buffer*
> columns while the cards are drawn at *screen* columns — with a file tree
> those differ by the tree's width, so the markers appear shifted while the
> cards are correct. The probe therefore cannot answer "does the card line
> up with the marker"; what it does prove is the stronger fact above: card
> positions are identical with and without the tree, i.e. drawing is
> screen-absolute and correct. Do not read its marker alignment as an error.

### H2-old — cell-width disagreement independent of padding (superseded)
Same arithmetic as H1's proportional term, but caused by something other
than padding (DPI rounding, fractional scaling). Distinguished from H1 only
by H1's test coming back negative.

**Measurement that quantifies either:** draw the same image at several known
columns and measure each left edge in pixels.

```lua
-- needs a real terminal; screenshot after each draw
for _, c in ipairs({ 5, 40, 80, 120, 160 }) do
  require("images.terminal").draw(png, 5, c, 20, 10)
end
```

- Offset **constant** across columns → a fixed offset; `terminal_padding`
  can compensate it.
- Offset **grows linearly** → a scale error; `terminal_padding` **cannot**
  fix it, because it is a fixed cell offset, not a scale factor. Only
  removing the cause (padding/scaling) helps.

### H4 — `nvim_win_get_position` misreports a float when a file tree is open (CURRENT LEAD)

By elimination this is what is left. Everything downstream is now verified:

- `images.terminal.draw` places correctly at any screen column (H2).
- `images.anchor`'s arithmetic on top of the reported position is correct
  (§3.5, seven measurements, Δ = +1 = `draw_inset` every time).
- No overhang is involved (`fits_h=true` everywhere), so `placed_position`
  is not even engaged.

If the *input* to that chain — the float's reported position — is wrong, the
whole chain produces a wrong result while every individual step checks out.
That matches every observation, including the one that looked strangest:
**the error appears only with a file tree open**, i.e. only when the editor
window does not start at column 0.

Counter-evidence to weigh: a headless test with a 50-column `vsplit` on the
left reported correctly (§3.4). But neo-tree is not a plain `vsplit` — it
may use a different window layout, and headless has no real UI grid.

**Test:** `docs/TESTING/float_position_probe.lua`, with the file tree open.
It opens a bordered float exactly like the hover (`relative = "cursor"`) and
draws a card into it via `images.anchor.draw` — the same call the hover
makes. Frame and card both derive from the *same* reported number, so:

- card **inside** the frame → the reported position is right, and the real
  hover's offset comes from something else about those floats (size,
  timing, a second float) rather than position arithmetic;
- card **beside** the frame → confirmed, and the fix belongs in
  `images.anchor`: derive the float's true origin from its parent window
  rather than trusting `nvim_win_get_position`.

### H3 — DPI / fractional scaling on this machine
The workstation placed correctly; this PC does not. If Windows display
scaling is not 100%, WezTerm's logical vs. physical pixel handling could
produce exactly the proportional error of H2. Worth noting the scaling
factor when testing H2.

---

## 7. Recommendation: flag inline images as experimental

The hover itself is solid — detection, file heads, directory listings, URL
previews, the missing-target marker all behave. **Only drawing the picture
inline is unreliable**, and only on setups where the terminal disagrees with
Neovim about pixels.

Asking a user to run `:Image calibrate` once per machine is reasonable.
Asking them to re-run it after window resizes, or to accept an image that
lands beside its frame, is not.

Proposed shape (not yet implemented):

- Keep the hover on by default; keep the **metadata** preview for images
  (format, dimensions, size) as the default answer.
- Move inline drawing behind an explicit opt-in, e.g.
  `hover = { experimental = { inline_images = true } }` in
  `lib.nvim.hover`, and say plainly in the docs that placement depends on
  the terminal and may be off.
- Keep `:Image calibrate` as the tool that makes it usable where it can be.

Honest framing beats a feature that looks broken by default.

---

## 8. Chronology

| Date | What happened |
| --- | --- |
| earlier | Placement correct on the workstation (PowerShell 5.1 era) |
| 2026-08-28 | Moved to personal PC; offset reappears |
| 2026-08-28 | `:Image calibrate` extended to also measure `cell_aspect` (`+`/`-`); stored per machine (images.nvim `f29bd14`) |
| 2026-08-28 | Calibration confirms `terminal_padding={0,0}`, `cell_aspect=0.46`, card sits correctly |
| 2026-08-28 | Hover offset persists → `placed_position`, `relative="cursor"`, and the anchor bypass all ruled out |
| 2026-08-28 | `hover_probe.lua` written; seven live measurements prove the Neovim-side arithmetic correct |
| 2026-08-28 | Found `window_padding = "1cell"` all round in the wezterm repo config — and that its own comment contradicts `TERMINALS.md §5`, which measured that `"1cell"` is the cell *width* even vertically |
| 2026-08-28 | Padding set to `0`, WezTerm restarted (screen 170×37 → **172×39**, confirming it took effect). **Offset survives with a file tree; without one it now looks correct.** H1 ruled out as *the* cause, confirmed as *a* contributing term |
| 2026-08-28 | Fixed an unrelated crash surfacing in the same runs: `float.lua` passed previewer strings containing `\n` straight to `nvim_buf_set_lines`, which rejects them — async previews died with a bare stack trace (lib.nvim `f473ad9`) |
| 2026-08-28 | `column_scale_probe.lua`: cards land at **identical pixel positions with and without the file tree**, at all four columns. **H2 (proportional) ruled out**, and `images.terminal.draw` proven correct |
| **next** | Run `float_position_probe.lua` **with the file tree open** (§6/H4) — the last unverified link is whether a float's *reported* position is where it is actually drawn |

### Where the search stands

Everything from the terminal call upwards is now verified correct:

```
images.terminal.draw          ✓ correct at every screen column (H2 probe)
images.anchor arithmetic      ✓ Δ = +1 = draw_inset, 7 measurements
placed_position               ✓ correct when engaged; never engaged here
window_padding                ✓ ruled out (offset survives padding = 0)
cell_aspect                   ✓ 0.46, calibration card fills its frame
  ↑
nvim_win_get_position         ← ONLY UNVERIFIED LINK (H4)
```

The offset appears **only with a file tree open** — the one condition under
which the editor window does not start at screen column 0. That is what H4
tests.

### Note on `terminal_padding` history

`TERMINALS.md §5` records that on a setup with `window_padding = "1cell"`
and `tab_bar_at_bottom = true`, the correct value was
`terminal_padding = { row = -2, col = 0 }`. This machine calibrates to
`{ row = 0, col = 0 }` with the *same* wezterm settings — which is itself
evidence that the error is not a stable whole-cell offset here, and
therefore not something `terminal_padding` can express. Consistent with a
proportional error (H1/H2).
