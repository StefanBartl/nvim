# Testing docmap-desktop

How to manually test the desktop app. Same shape as the
`documentation*.md` files beside this one: one section per feature,
prerequisites, steps, what to expect.

Repo: `E:\repos\docmap-desktop`. Branch `main`, through `0896ddd`.

**Nothing in here has been seen by a human.** The Rust and JS halves are
covered by `cargo test` (12) and `node --test` (31), and a window is exactly
what neither can look at. Two of the items below are older debt from
`docs/HANDOVER.md` that has been waiting for eyes since long before this
batch.

## Setup

```
cd E:\repos\docmap-desktop
npm run tauri dev
```

The engine it will find is `C:\tools\docmap.exe`, on PATH.

**One thing to know before reading any language output**: that engine
**predates** the `languages` field in `--capabilities`. Everywhere below that
mentions per-language detail, today's answer is the *older-engine* path —
which is itself worth checking, and is marked as such. Full behaviour needs
an engine rebuilt from `documentation.nvim` (recipe in
`docmap-desktop/docs/HANDOVER.md`).

---

## 1. Language distribution before the first generate

**Steps**

**Add project…** → pick a repository that has never been mapped. Ideally one
the engine cannot read much of — a Python or Rust project.

**Expect**: before generation runs, the status line names what the tree is
written in, e.g. `68 % Python (412) · 20 % C (118)`. The point is placement:
that news costs nothing here and costs a 40-second scan and an empty map at
every later moment.

**Check the counting is sane** on a repo you know. It skips `node_modules`,
`target`, `.git` and friends — **and any subdirectory that is its own
checkout**. That rule came from measuring: this repo reported 448 Lua files
where `lua/` holds 98, because 306 of them were copies of itself under
`.claude/worktrees/`.

---

## 2. Language badges in the project list

**Steps**

Look at the sidebar with several projects added.

**Expect**: a third, quieter line under each project's name — `Lua · TS`, or
`JavaScript · Rust +2` when there are more.

**This is the one most likely to look wrong.** Specifically check:

- Does the third line break the row height or crowd the counts above it?
- Is the line readable at its reduced opacity, or too faint to bother with?
- Hovering it should show the **full** breakdown as a tooltip. Does that
  tooltip appear, and is it legible?

---

## 3. The "no map yet" placeholder

**Steps**

Select a project that has never been generated.

**Expect**: the usual "No map in this project yet" plus, underneath, the
language breakdown — the one screen whose entire subject is that there is
nothing to show.

---

## 4. The Engine panel's language list

**Older-engine path today.**

**Steps**

Expand the **Engine** panel in the sidebar.

**Expect** with the current engine: `This engine is older than the language
list — it cannot say which languages it reads.` That is correct and is the
degradation path; check it reads as an explanation rather than an error.

**After an engine rebuild**, expect instead a line like
`reads: lua · no grammar for js, ts, tsx — module tree only`. The caveat is
stated **once for the group** — an earlier version repeated it after each of
three backends and ran past the panel width.

---

## 5. The Engine panel's verdict

**Steps**

Look at the collapsed summary — the part that stays visible when the panel is
shut.

**Expect** three possible words: `ready`, `N of M grammars`, `no grammars`
(or `not found`).

**What this fixed**: it used to say `ready` whenever a grammars *directory*
resolved, so a directory holding one grammar out of four still read "ready" —
silent degradation in the indicator that exists to prevent silent
degradation. With an older engine it falls back to exactly that old
behaviour, deliberately; with a rebuilt one it should be able to say
`1 of 4 grammars`.

---

## 6. The map inside the app

**Steps**

Select a mapped project and look at the map in the window rather than in a
browser.

**Expect**: everything from `documentation3.md` §6–§11 works inside the
iframe — keyword hover, stdlib hover, the language legend, Copy link.

**Copy link is the one to watch here.** The app has no address bar, which is
half the reason the button exists; and the clipboard API behaves differently
inside a webview than in a browser. If it fails it should say
`Press Ctrl+C`, not fail silently.

---

## 7. Generate, and the report

**Steps**

**Generate map** on a selected project.

**Expect**: the engine's own report verbatim — counts, coverage, findings.
The window must keep repainting while it works; generation runs on a blocking
task specifically so it does not look frozen.

---

## Older debt, still unlooked-at

Both from `docs/HANDOVER.md`, built and never seen:

## 8. The collapsed Engine panel

Built as a `<details>` so keyboard operation and the open/closed state come
from the element rather than being reimplemented. **Never viewed.** Check it
opens, closes, is reachable by keyboard, and that the summary line is
readable while collapsed.

## 9. The edge popup in the Calls graph

In `documentation.nvim`'s generated page, Hierarchy → Calls: clicking an edge
should show a popup. Structurally verified, never looked at.

---

## What cannot be checked here, and why

- **Tab-navigation to the keyword spans.** The spans carry `tabindex="0"` and
  the handler works when the event arrives, but a non-compositing pane never
  takes window focus, so `focusin` never fires in any automated check. A real
  window is the only place this can be answered.
- **Typography scale and zebra striping** — 16 distinct `font-size` values
  were measured in the generated page, and deciding whether that is a problem
  needs eyes, not a script.
