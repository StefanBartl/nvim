# Manual evidence

## Table of content

  - [Intro](#intro)
  - [How to read a row](#how-to-read-a-row)
  - [Before any row is worth reading: which code was actually loaded](#before-any-row-is-worth-reading-which-code-was-actually-loaded)
    - [How this config loads hover.nvim](#how-this-config-loads-hovernvim)
    - [The check to run first](#the-check-to-run-first)
  - [What no CI covers](#what-no-ci-covers)
    - [Images drawn into the float](#images-drawn-into-the-float)
    - [A hover resized](#a-hover-resized)
    - [A PDF page zoomed, which is a re-render rather than a crop](#a-pdf-page-zoomed-which-is-a-re-render-rather-than-a-crop)
    - [A picture zoomed, and panned around in](#a-picture-zoomed-and-panned-around-in)
    - [The resize wheel, where it points](#the-resize-wheel-where-it-points)
    - [A hover put full screen](#a-hover-put-full-screen)
    - [A PDF page rasterized](#a-pdf-page-rasterized)
    - [A page rendered by a headless browser](#a-page-rendered-by-a-headless-browser)
    - [A link that answers with a PDF](#a-link-that-answers-with-a-pdf)
    - [An office document converted](#an-office-document-converted)
    - [A contribution asked only on request](#a-contribution-asked-only-on-request)
  - [What is checked automatically, for contrast](#what-is-checked-automatically-for-contrast)
  - [Keeping this honest](#keeping-this-honest)
  - [Two findings from 2026-09-04 that are not rows](#two-findings-from-2026-09-04-that-are-not-rows)
    - [A bare path in prose that does not hover, while the picture beside it does](#a-bare-path-in-prose-that-does-not-hover-while-the-picture-beside-it-does)
    - [PageUp / PageDown on a keyboard that has neither](#pageup-pagedown-on-a-keyboard-that-has-neither)

---

## Intro

What is checked by hand, because no CI can check it — and **when it was last
checked**, which is the part that decays.

CI covers the specs, the formatter and the linter, on Ubuntu and on Windows.
It does not cover anything that needs a **terminal to draw into** — an image,
a rasterized PDF page, a converted office document — and it does not cover
anything that needs a **daemon to answer**, which is the container engine
behind a contribution marked `on_request`. Those are the most visible things
this plugin does, and nothing automated has ever exercised them.

This file exists so that gap is *legible* rather than invisible. **It is not
a test suite and must not be read as one.** A row here says one person saw
one thing work once, on one machine.

**It lives here rather than in the plugin, since 2026-09-04.** What one person
saw on one set of machines is that person's record, not documentation of the
plugin — it names hardware, install paths and a working directory, and a public
repository is the wrong home for it. hover.nvim keeps the two probe *scripts*,
which are repeatable and belong there; links below into the plugin's own docs
point at GitHub for the same reason.

---

## How to read a row

| Column | Means |
| --- | --- |
| Checked | The date. A row with no date has never been checked, only written down. |
| On | The machine, terminal and Neovim it was seen on. Everything here is terminal-dependent, so "it worked" without that is not a claim. |
| How | Enough to repeat it. If a row cannot be repeated from what it says, it is not evidence. |

---

## Before any row is worth reading: which code was actually loaded

**A row collected against code the session never loaded is worse than no row**,
because it reads as a statement about the plugin and is a statement about a
snapshot of it. This happened on 2026-09-04 and cost most of a test pass —
twice, because the first diagnosis was also wrong.

---

### How this config loads hover.nvim

`lua/plugins/personal/source.lua` sets `OVERRIDE = "dir"`, so every personal
repo is loaded **locally**: lazy gets `spec.dir = E:epos\<name>` and the
plugin runs straight out of the working checkout.

Two consequences, and the second is the one that bites:

- **The lazy clone under `~/AppData/Local/nvim-data/lazy/hover.nvim` is not
  loaded.** It is a leftover from an earlier `"remote"` phase and can sit
  dozens of commits behind for ever without meaning anything. On 2026-09-04 it
  stood at `b2b4b2c`, 54 behind — and that fact explained nothing at all, which
  did not stop it from looking like the answer for an hour. **Do not diagnose
  from it.** `:Lazy update` is not the fix and has nothing to fix.
- **A running session holds the code from the moment it started.** Lua modules
  are cached in `package.loaded`; editing or pulling the checkout changes
  nothing until the next start. So a feature committed *during* a session is
  absent from that session, and looks exactly like a broken feature.

That second one is what actually happened: zen (`c20191e`) and the page
screenshot (`4e2ebeb`) were written while the session under test was already
running. `F` did nothing and `:Hover links web shot` did not exist because that
Neovim had never seen either. A restart made both work.

---

### The check to run first

From inside the session you are about to collect evidence in:

```vim
:lua print(vim.api.nvim_get_runtime_file("lua/hover/init.lua", false)[1])
```

That names the directory that is actually loaded. Then, in that directory:

```bash
git log --oneline -1
```

and ask the only question that matters: **was this session started after that
commit?** If in any doubt, restart Neovim before writing a row. A restart costs
seconds; a row that cannot be placed on a version costs the next reader an
afternoon.

Cheaper still, from inside Neovim — each of these exists only from one commit
on, so a missing one dates the loaded code:

| Type this | Missing means the loaded code is |
| --- | --- |
| `:Hover resize` | older than `8ec5b40` — no resize, no `+`/`-`, no wheel |
| `:Hover zoom` | older than `9fba190` — no magnification, no `h`/`j`/`k`/`l` |
| `:Hover auto` | older than `e8cde0e` — no `auto_hover` axis at all |
| `:Hover zen` | older than `c20191e` — no zen |
| `:Hover links web shot` | older than `4e2ebeb` — no page screenshots |
| `:Hover links web fetch pdf` | older than `dbc2b87` — a PDF link shows its size only |

---

## What no CI covers

### Images drawn into the float

| | |
| --- | --- |
| **Checked** | 2026-09-04 — seen again, on a bare path in prose (`./htb-anomalies.jpg`). Previously 2026-09-01. |
| **On** | Windows 11, WezTerm, Neovim 0.12.2, images.nvim present |
| **How** | Rest the cursor on a `./assets/*.png` path. The picture appears inside the float, fitted, not beside it. |
| **Watch for** | The picture landing beside its own frame — that is the placement bug written up in [architecture.md](https://github.com/StefanBartl/hover.nvim/blob/main/docs/architecture.md#two-things-that-must-not-be-changed-casually), and it only shows with a sidebar open. Reproduce with a real image; a generated test card cannot reveal an aspect-ratio problem. |

---

### A hover resized

| | |
| --- | --- |
| **Checked** | 2026-09-04 — seen again, both halves, keys **and** `:Hover resize`. Previously 2026-09-03 (the text half) and 2026-09-02 (the picture half): more lines arrive, not a larger frame around the same ones. |
| **On** | Windows 11, Neovim 0.12.2, images.nvim present |
| **How** | Hover an image, then press `+` a few times and `-` back. The float grows and shrinks with it, and the picture fills it edge to edge at every size. Then hover a *text* file and run `:Hover resize` a few times: the float grows and more lines appear in it. **`+` and `-` are deliberately not bound over a text hover** — there they are the motions they always were, and pressing one moves the cursor a line, which takes the float away. That is not a failure of the resize; it is the reason the route exists. |
| **Watch for** | The **frame** growing while the picture inside it does not — that is the one failure a spec cannot see. `TESTS/resize_spec.lua` pins the geometry all the way to `nvim_win_get_config`, but the cell area is only a *request* to the terminal, and whether the drawing actually followed it is visible and nothing else. Also: letterboxing that drifts as the box grows (the picture no longer centred, or gaining a margin on one side only), which would mean the inset is being added at the wrong end of the scaling. |

**What was seen:** `+` several times and `-` back, over an image. The float
grows and shrinks with it and the picture fills it edge to edge at every size
— so the picture followed the cell area rather than the frame growing around a
picture that stayed put, which was the one failure no spec can reach.

**The text half, seen on 2026-09-03.** `:Hover resize` over a text file: the
float grows *and more lines appear in it*. That distinction is the whole reason
the feature was renamed, and it is the half a spec covers least convincingly —
the spec asserts the float's geometry, and "more lines are in it" is what a
reader actually looks for.

**The instruction that produced this row was wrong first, which is worth
keeping.** It said to press `+`. Over a text hover `+` is not borrowed — it is
the motion it always was, so it moves the cursor a line and the dismissal on
`CursorMoved` takes the float away. The row above said so already; a note
elsewhere said otherwise, and the note was what got followed.

Measured, not seen, on 2026-09-02: a 1200×675 image at the default `80×20`
grows through five steps on a 210×55 terminal (71×20 cells of picture up to
181×51) and through none at all on 80×24, where 20 rows is already
`lines - 4`. Those are float geometries read back from Neovim — they say the
frame is the right size, not that a picture arrived in it.

---

### A PDF page zoomed, which is a re-render rather than a crop

| | |
| --- | --- |
| **Checked** | 2026-09-04 — **the sharpness claim, by eye.** `>` narrowed the view and the result was genuinely *sharper*, not merely larger, which is the whole feature; `h`/`j`/`k`/`l` moved the view and `=` returned to the whole page. The scanned-PDF half of the row below — magnifies without sharpening — was not separately exercised. |
| **On** | Windows 11, WezTerm, Neovim 0.12.2, pdfport.nvim + `pdftoppm` on PATH |
| **How** | Hover a PDF with real text on the page, then press `>` two or three times. Each step shows a **smaller part of the page, larger and genuinely sharper** — letterforms that were grey mush at level 0 should have clean edges at level 2. Then `h` `j` `k` `l` to move around, `=` back to the whole page. Repeat on a **scanned** PDF, where there is no more detail to find: it should still magnify, just without getting sharper, because the page is an image inside the document and the re-render can only interpolate it. |
| **Watch for** | Each step taking noticeably *longer* than the one before — that means the crop window is not reaching pdftoppm and the whole page is being rendered at the higher DPI, which is exactly what an older pdfport does silently. Also: a magnified page that is blurry in the way a scaled bitmap is blurry, which is the same symptom from the other side. And the page number in the border changing, or the view jumping back to page 1, when the zoom re-renders. |

**What is covered without a person.** `TESTS/zoom_spec.lua` pins the
arithmetic — that the DPI rises by exactly the factor the view narrows by,
that the window comes out the size of the plain page at every level, that the
ceiling refuses before rendering. `scripts/pdfzoom_probe.lua` runs the whole
path against a real document and prints time, pixel size, hash and two
sharpness numbers per level; on 2026-09-03 it reported 207–752 ms a step at a
constant 1826×2312, and edge energy 2× to 15× that of the same window cropped
from the plain render.

**What that leaves.** The probe proves the file is produced and is sharper.
Whether it is *drawn* into the float — and whether a page reads as sharp to a
person rather than as a number — is what this row is for.

---

### A picture zoomed, and panned around in

| | |
| --- | --- |
| **Checked** | 2026-09-04 — seen again in full: `>` / `\|` / `=`, `h`/`j`/`k`/`l`, and all three of `:Hover zoom in\|out\|reset`. Also confirmed that moving the cursor off closes the float, which is the half that proves the keys are a borrow and not a permanent mapping. Previously 2026-09-03. Driven with `>` / `=` rather than the Alt chords, which never arrived — which is why those are the default since that day: see below. |
| **On** | Windows 11, Neovim 0.12.2, images.nvim + ImageMagick present, which-key installed |
| **How** | Hover an image, then press `>` two or three times. Each step takes about a quarter of a second and shows a **smaller part of the picture, larger** — not the same picture bigger. Then `h` `j` `k` `l` to move around in it; `\|` steps back, `=` returns to the whole picture. `:Hover zoom [in\|out\|reset]` does the same three from the command line. Finally press `h` with the hover **not** zoomed: the float should go away, because there the key is the cursor motion it always was. |
| **Watch for** | `>` doing nothing at all, which has two causes that look identical: the picture is not zoomable (no ImageMagick, or no images.nvim) — the float says so — or a key list configured back to Alt chords the terminal does not send, which `:nnoremap <M-z> :echo "da"<CR>` settles in one press. Then: the **whole picture getting larger** instead of a detail — that is resize's answer arriving where zoom's was asked for, and it looks almost right. Also: panning that jumps to a corner rather than moving a quarter of a view (a pixel centre instead of a fractional one would do that), and a centre that survives `reset` and makes the next zoom start somewhere nobody chose. |

**What is covered without a person.** `TESTS/zoom_spec.lua` pins the
arithmetic, and outside the suite the crops have been confirmed to be written
and to shrink as calculated — `800x533+200+133`, then `533x355+333+222`, then
`355x237+422+281`, with the centre clamped inside the source and `reset`
returning the whole image.

**What was seen on 2026-09-03, and what it cost to see it.** The magnified
detail arrives drawn, and panning it with `h/j/k/l` reads as one gesture rather
than as jumps — the half no spec can be asked about at all.

Getting there needed different keys, and that is the finding. **`<M-z>` never
reaches Neovim on this machine**: `:nnoremap <M-z> <Cmd>echo "…"<CR>` prints
nothing when the chord is pressed, so the terminal is not sending it — and
which-key opens instead, because what does arrive is `<Esc>` followed by `z`,
and `z` is a prefix. With `zoom_keys = { into = ">", out = "<", reset = "=" }`,
`>` and `=` work; **`<` makes which-key report "Recursion detected"**.

**That measurement changed the default on 2026-09-03**, and two of its details
are worth keeping because they were checked rather than reasoned:

- **which-key normalizes `<` to `<lt>`** while the mapping itself stays `<`
  (`Util.norm`, run against the installed copy on 2026-09-03). `|`, `_`, `>`
  and `=` all normalize to themselves. So `<` is not a coincidence of one
  configuration — anyone with which-key would meet it.
- **`-` cannot be the way out**, however natural it looks beside a `_`.
  `resize_keys.smaller` holds it, resize is bound before zoom, a key listed
  twice is taken once, and every hover a zoom key is bound for has a picture:
  it would resize on every press. That is a code reading rather than a
  keypress, and `:checkhealth hover` now reports the clash.

The default is `>` in, `|` out, `=` reset. The Alt chords stay right wherever
the terminal sends them, and this row is the evidence that "everywhere" was an
assumption.

**What that leaves.** Every one of those numbers is a rectangle handed to
ImageMagick. Whether the resulting file is *drawn* into the float, and whether
what appears is a magnified detail rather than a scaled whole, is visible and
nothing else — the same gap as the resize row above, one layer further along.
And whether `h/j/k/l` feel right while panning is not a question a spec can be
asked at all.

**What the suite covers since 2026-09-02.** The crop check used to report
*pending* on every machine, for two bootstrap defects rather than a missing
tool: `scripts/minimal_init.lua` never reached its images.nvim fallbacks, and a
single-file run got a different environment from a directory run. Both are
fixed, and the spec now writes a real cropped file with ImageMagick and
compares its pixel size against the rectangle the arithmetic asked for. What is
left for this row is the part after the file exists: whether it is *drawn*.

---

### The resize wheel, where it points

| | |
| --- | --- |
| **Checked** | 2026-09-04 — **both directions.** `<M-ScrollWheelUp>` and `<M-ScrollWheelDown>` over the float, growing and shrinking it. The pointer-elsewhere half of the row was not separately exercised. |
| **On** | Windows 11, WezTerm, Neovim 0.12.2, images.nvim present |
| **How** | Hover an image. With the pointer **on** the float, `<M-ScrollWheelUp>` a few times: it grows. Move the pointer well off the float and press it again: nothing happens. `<M-ScrollWheelDown>` on the float shrinks it back. |
| **Watch for** | Nothing happening *anywhere*, which is the interesting failure and has two causes that look identical: `'mouse'` not covering the mode (`:checkhealth hover` warns about exactly this), or the terminal not sending Alt+wheel as a distinct chord. `<M-ScrollWheelUp>` mapped to `:echo` tells the two apart in one press. Also worth watching: a step landing while the pointer is *beside* the float rather than on it — the gate is a rectangle test, and a wrong one would show up as a float that resizes from anywhere. |

**Why this cannot be a spec.** Mouse input needs a UI attached: measured on
2026-09-02, `nvim_input_mouse` fired **zero** mappings with
`#nvim_list_uis() == 0`, while `feedkeys` with the same termcode fired one. So
the specs drive the chord and stub the pointer position, which pins the
mapping and the rectangle test but says nothing about a real wheel reaching
Neovim.

The same measurement is why the gate does not use `getmousepos().winid`: the
float is `focusable = false`, and with the pointer squarely inside one, that
field named the window *underneath* it. Only the screen coordinates are
usable, so `hover.float.contains` does the rectangle test itself.

---

### A hover put full screen

| | |
| --- | --- |
| **Checked** | 2026-09-04 — **reported working after a restart.** The first attempt the same day found `F` doing nothing, and that was the session rather than the feature: zen was committed while that Neovim was already running, so it had never loaded the code (see the section at the top). Restarted, it works. What the reporter confirmed is the gesture — `F` opens and closes it; the individual claims in **How** below, in particular *more lines* on a text hover and the 📌 surviving a re-render, were not picked apart one by one. |
| **On** | Windows 11, WezTerm, Neovim 0.12.2, images.nvim present, hover.nvim loaded from `$REPOS_DIR\hover.nvim` |
| **How** | Hover a picture and press `F`. The float takes almost the whole editor, centred, and the picture fills it. `F` again returns it to where it was. Then hover a *text* file and press `F`: the float should show roughly fifty lines rather than twenty — **more lines**, not a larger frame around the same twenty. `-` inside zen shrinks it without leaving zen; `+` does nothing, because zen is already at the terminal's ceiling. |
| **Watch for** | The **frame** filling the screen while the picture inside it stays the size it was — the same failure the resize row watches for, and the one a spec structurally cannot see, since the cell area is only a request to the terminal. Also the 📌 marker: zen pins by default, and the marker is re-applied after every re-render because `float.open` replaces the window. A zen float with no 📌 in its border means that re-application was lost again. |

---

### A PDF page rasterized

| | |
| --- | --- |
| **Checked** | 2026-09-04 — the page, and paging through it with `<M-PageDown>` / `<M-PageUp>`. Previously 2026-09-01. |
| **On** | Windows 11, WezTerm, Neovim 0.12.2, pdfport.nvim + `pdftoppm` on PATH |
| **How** | Cursor on a `.pdf` path; page 1 appears. `<M-PageDown>` pages forward and stops at the last page. On a keyboard without PageUp/PageDown, `<C-Down>` / `<C-Up>` are the second pair and do the same — see the finding at the end of this file. |
| **Watch for** | "rendering…" that never resolves, and paging past the end — the page count is never known in advance, so the last page is discovered by asking for one too many. |

---

### A page rendered by a headless browser

| | |
| --- | --- |
| **Checked** | 2026-09-04 — **reported working after a restart.** The first attempt the same day found no `shot` route at all, which was the session and not the feature: the switch was committed while that Neovim was already running. Restarted, it works. Confirmed as a gesture; the three things the **Watch for** row calls out — the throwaway profile, one browser at a time while scrolling, and the fit factor — were not individually verified, and the first of those is worth a deliberate look. The browser start and one render against a `file://` page were measured (710–735 ms and 768 ms respectively, see [SHOT.md](https://github.com/StefanBartl/hover.nvim/blob/main/docs/FEATURES/SHOT.md)). |
| **On** | Windows 11, WezTerm, Neovim 0.12.2, images.nvim present, Chrome at `C:\Program Files\Google\Chrome\Application\chrome.exe` — installed, and on no PATH |
| **How** | `:Hover links web shot`, then `:Hover show` with the cursor on an `https://` link. A picture of the page appears in the float. Then `F` for the full-screen reading, `>` to magnify a detail, `h`/`j`/`k`/`l` to move it. For the trigger half: `:Hover links web shot eager` and `:Hover auto url`, then rest the cursor on a link and wait — nothing should start for the first second of stillness. |
| **Watch for** | Three things, in order of how badly they would fail. **The reader's own Chrome profile being used** — the picture would show them logged in, and their cookies would have gone to that host; the throwaway `--user-data-dir` is what prevents it and it is the one flag worth verifying by eye. **A browser per link while scrolling**, which would mean the start delay or the one-at-a-time kill is not working; the cheapest check is watching the process list while running the cursor down a page of links. And **an unreadable picture**, which is the fit factor rather than a bug — 1280×900 into a zen float is about 1.0, and a taller capture is meant to be read with the zoom. Since `28dc9e4`, a `>` that cannot produce a crop at all — an unreadable PNG, no `images.convert` — shows the **plain** picture rather than nothing; before that it returned nil two frames past the place that could have explained it. The date above is unmoved on purpose: what was checked is a crop that *works*, and that half is unchanged. |

---

### A link that answers with a PDF

| | |
| --- | --- |
| **Checked** | *never* — written down on 2026-09-04, the day it was built (`dbc2b87`), and not yet seen. The parts that are checked automatically are the four decisions around the download: what counts as a PDF, the refusal above the cap, a truncated file being discarded, and the switch implying `fetch`. What no spec can reach is the whole of what this row is for: a real server answering `application/pdf`, and a page drawn from it. |
| **On** | — |
| **How** | `:Hover links web fetch pdf` (it turns `links web fetch` on with it), then `:Hover show` with the cursor on a link that really serves a PDF — an arXiv `/pdf/` URL or a datasheet, not a `.pdf` in a path that redirects. The first page appears in the float. Then `<M-PageDown>` to page, `>` to magnify, `F` for the full-screen reading: all three should behave exactly as they do on a local `.pdf`, because past the download it *is* the local path. |
| **Watch for** | **A page that never arrives after "downloading the document…"** — the honest failure would name a reason instead. **`pdftoppm` erroring on a file that downloaded fine**, which would mean the bytes were mangled in transit rather than the renderer being broken; that is the `text = true` failure the second request exists to avoid, and seeing it would mean the second request is not being made. And **paging or zooming falling back to line-scrolling**, which would mean `_open.paged` was not recorded — the symptom is `<M-PageDown>` moving by lines on a web PDF while it turns pages on a local one. |

---

### An office document converted

| | |
| --- | --- |
| **Checked** | 2026-09-04 — seen again, conversion **and** sweep, both behaving as written. Previously 2026-09-03 (all three), the first two on 2026-09-02. |
| **On** | Windows 11, WezTerm, Neovim 0.12.2, pdfport.nvim + LibreOffice 25.x |
| **How** | `:Hover office on`, then hover a `.docx`. The first one costs a LibreOffice start, which is seconds. Then `:qa`, restart, `:Hover office on`, and hover the same document again. For the sweep: backdate the converted PDF in the cache directory past `office.cache_days`, restart, and hover a **different** office document — the sweep runs once per session and only on the first real conversion, so re-hovering a document that is already cached does not trigger it. |
| **Watch for** | The badge saying LibreOffice is missing rather than a failed conversion — `can_create("office")` is asked first, precisely so the answer is a sentence and not a hang. On Windows that badge is the *expected* first result even with LibreOffice installed, because its installer does not extend `PATH`; the fix is in [installation.md](https://github.com/StefanBartl/hover.nvim/blob/main/docs/installation.md#soffice-on-windows-installing-libreoffice-is-not-enough) and it is not a bug in this path. |

**What was seen**, in order: with office rendering off, the badge
`no text preview  ·  :Hover office on`. With it on, `converting to PDF…`,
then the rendered first page inside the float. After `:qa` and a restart, the
same document showed a badge for roughly a third of a second and then the
page — **no LibreOffice start**, which is the whole point of letting the cache
outlive the session. The flash is the PDF being rasterized again, not the
document being converted again; those are two different caches, and only the
outer one is this plugin's.

The cache directory afterwards held exactly one file:

```
<stdpath("cache")>/hover.nvim/office/Bewerbung_…-a62f1bc27aecd87f.pdf
```

To list it yourself — `nvim --headless -c 'echo …'` mixes the startup message
into its own output, so the path has to be written rather than echoed:

```powershell
ls "$(nvim -u NONE --headless -c 'lua io.write(vim.fn.stdpath("cache"))' -c 'q')/hover.nvim/office"
```

**The sweep, seen on 2026-09-03.** `office.cache_days` (default 7) is covered
by specs only where it is wiring; the sweep itself touches a real cache
directory, and that is in no test. What was done: one converted PDF in
`stdpath("cache")/hover.nvim/office` backdated thirty days, Neovim restarted,
a *different* office document hovered. The backdated file was gone and the new
one was there — the sweep ran, and it ran on the first conversion of the
session rather than at startup, which is where it is called from.

**Why a different document.** The sweep is called from the conversion path,
once per session. Re-hovering the same document answers out of the cache and
converts nothing, so nothing would have been swept and the check would have
read as a failure of the sweep rather than of the method.

---

### A contribution asked only on request

| | |
| --- | --- |
| **Checked** | 2026-09-02 |
| **On** | Windows 11, Neovim 0.12.2, sandbox.nvim beside this repo, Docker Engine 29.5.3 holding four images and two stopped containers |
| **How** | `nvim --clean --headless -l scripts/onrequest_probe.lua docker` from **hover.nvim's** repository root — `$REPOS_DIR\hover.nvim`, not the Neovim configuration directory. Run anywhere else it is `E5112: cannot open scripts/onrequest_probe.lua`, which names the path and not the mistake; hit on 2026-09-04, and the script now says which checkout in its own header. Four references in one buffer — a pulled image with no container, a pulled image with one, an image that is not pulled, and `init.lua:42` — each asked twice: once on the automatic trigger, once forced. |
| **Watch for** | Anything but `quiet` in the `auto` column. That column is the whole of what `on_request` buys, and losing it is silent: an engine start would then run after every keystroke followed by quiet, arriving as a stutter nobody would connect back to a container engine. Second: `(nothing shown)` on a row that should answer, which is the shape of `836a15a` — a preview correctly registered and reachable by no route at all. |

**Why no CI can do this.** A contribution marked `on_request` is skipped by
the automatic trigger and asked only for an explicit request; the only shipped
one is sandbox.nvim's container-image preview, and answering costs a container
engine. So the last step — a force-only contribution actually putting lines on
the screen — has no automated witness. The probe reads the float's first line
back rather than trusting the return value, because `836a15a` lived exactly in
the gap between "the pipeline returned true" and "something arrived".

Measured on the machine above, keypress to finished float:

| Reference | Answer | Forced | Engine calls |
| --- | --- | --- | --- |
| `alpine:edge` | pulled, no container | 566 ms | 2 |
| `lazyvim_starter:latest` | pulled, 1 container | 558 ms | 2 |
| `nginx:1.27-alpine` | not pulled | 294 ms | 1 |
| `init.lua:42` | declined | 0 ms | 0 |

All four stayed quiet on the automatic trigger. The 294 ms row is the evidence
for the second engine call happening only on a hit; the 0 ms row is evidence
that the `name:tag` collision with a file-and-line reference is refused
**before** any process starts.

**The run with no argument is the one that found something.** Without an
engine name the probe used sandbox.nvim's own detection, and on this machine
that picked `podman` — on PATH, but with its VM not running. Every row then
declined after ~370 ms, silently and for a reason that had nothing to do with
this plugin, while a working Docker engine sat beside it.

That was a sandbox.nvim bug and it is **fixed there** (sandbox.nvim `deb45bc`,
2026-09-02): detection now takes the first installed engine that actually
answers, and the same probe run picks `docker`. The row is kept because the
*shape* is worth recognising and will recur — an integration can be registered,
green in every spec, and silent on the machine, and the only thing that says so
is a run on a real one. When a container hover answers nothing, **check which
engine was chosen before suspecting the hover.**

---

## What is checked automatically, for contrast

Not evidence of the above, and listed only so the boundary is clear: the spec
suite, `stylua --check`, `luacheck`, and a LuaLS scan with the real injected
library — the last of those run from
`nvim/scripts/luals-scan/`, not from this repository. All four on Ubuntu and
Windows, per push.

---

## Keeping this honest

A row whose date is older than the code it describes is worse than no row,
because it reads as a check that happened. When one of the eleven paths above
changes, either check it again and move the date, or set the date back to
*never* and say why.

**And a row is only about the code that was loaded.** Check that first — the
section at the top says how, and 2026-09-04 is why it is there. Two features
read as broken that day for no better reason than having been written while the
session under test was already running.

The same day also produced the other half of that lesson, and it is worth
keeping because it was *my* mistake rather than the plugin's: the first
diagnosis blamed the lazy clone for being 54 commits behind. It is behind, it
is irrelevant, and it is never loaded — this config sets `OVERRIDE = "dir"` and
runs these plugins out of `E:epos`. A plausible cause that explains the
symptom is not the same thing as the cause, and the check that would have
settled it in one line is the `nvim_get_runtime_file` call at the top.

Both rows written down at *never* on 2026-09-04 — the full-screen hover and
the rendered page — were seen the same day, once the session had been
restarted. They were written before they were seen on purpose: a row that
exists and says "not yet" is the gap being legible, which is what this file is
for. A feature shipped with no row at all is the gap being invisible.

What is still genuinely unseen is narrower and named in those two rows: the
throwaway browser profile, verified by eye rather than by reading the flag
list, and one browser at a time while scrolling a page of links.

**A third row stands at *never* since 2026-09-04**, for the same reason and by
the same rule: a link that answers with a PDF (`dbc2b87`), built after that
day's test pass had ended. Nothing about it has been seen against a real
server.

---

## Two findings from 2026-09-04 that are not rows

Neither is about something CI cannot reach. Both are about a **correct**
behaviour that reads as a broken one, which is the other thing worth writing
down.

---

### A bare path in prose that does not hover, while the picture beside it does

Seen with three lines in one buffer:

```
Text:  .\image_hover.txt
Markdown file: ./ROADMAP/ROADMAP.md
Image: ./htb-anomalies.jpg
```

Only the image opened a float. `:Hover paths on` and `:Hover paths code on`
changed nothing — and could not, because they answer a different question.

**All three paths are found.** Checked against the current source on
2026-09-04: `.\image_hover.txt` (backslash included), `./image_hover.txt`,
`image_hover.txt` and `./ROADMAP/ROADMAP.md` all resolve and classify. What
stops two of them is `auto_hover`, whose default is `{ image, pdf }` — so
`file` and `markdown` are *found and waiting to be asked for*, exactly as
designed.

The fix is `:Hover auto file` / `:Hover auto markdown` for the session, or in
the spec:

```lua
auto_hover = { "image", "pdf", "file", "markdown" }
```

`:Hover show` answers for them regardless, and always did.

**Why this was undiagnosable at the time**: the three axes look identical from
the outside — `paths` decides whether a bare path is a target at all,
`auto_hover` decides whether its *type* opens unasked, and `mode` decides
whether anything opens unasked. hover.nvim `c20191e` is what makes the second
one say so: `:Hover why` now names it at the cursor, and a switch announces it
when thrown. That commit was not installed when this was seen — see the version
section.

One thing that *would* have been a defect and is not: the **backslash** path.
`.\image_hover.txt` resolves.

---

### PageUp / PageDown on a keyboard that has neither

The scroll keys are two pairs, not one, and this is why:
`<M-PageDown>` / `<M-PageUp>` **and** `<C-Down>` / `<C-Up>`. Laptop and 60%
layouts reach PageUp/PageDown only through an Fn chord, and nothing at runtime
can tell whether this keyboard has them — the arrows are on every keyboard
there is.

So nothing needs adding: **`<C-Down>` and `<C-Up>` page a PDF and scroll a file
already.** Confirmed present in `DEFAULTS.scroll_keys` on 2026-09-04. Ctrl
rather than Alt on the arrows, because `<M-Up>`/`<M-Down>` is a widespread
"move this line" binding.

---

