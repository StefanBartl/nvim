# hover.nvim — Keymaps Cheatsheet

New repository, 2026-09-01, extracted from `lib.nvim.hover`.

**Almost nothing here is owned.** The keys below are *borrowed*: bound
globally while one float is on screen, handed back the moment it closes, and
the mapping they displaced is **restored** (via `maparg(…, true)` + `mapset`),
not deleted. The float is `focusable = false`, so it never receives a
keystroke and can never hold a mapping of its own; a buffer-local mapping on
the document would leak into buffers with no hover open.

Source: `lua/hover/bindings/keymaps.lua`
Docs: `docs/BINDINGS.md`, `doc/hover.txt`

## Owned (bound at setup, kept)

| Config key | Default | Action |
| --- | --- | --- |
| `keymaps.show` | **`false`** | `hover.show({ force = true })` |

No key is claimed by default — a plugin other plugins depend on has no
business taking one on their behalf, and `:Hover show` covers it. Worth
setting in `mode = "manual"`; `:checkhealth hover` warns about that
combination when no key is bound. **Not set in this config today.**

## Borrowed (only while a float is up)

| Config key | Default | Bound for | Action |
| --- | --- | --- | --- |
| `dismiss_keys` | `q`, `<Esc>` | every hover | dismiss until the cursor reaches another target |
| `scroll_keys.down` | `<M-PageDown>`, `<C-Down>` | scrollable only | next screenful / next PDF page |
| `scroll_keys.up` | `<M-PageUp>`, `<C-Up>` | scrollable only | back |

## Collisions to know about

- **`q` records no macro while a float is up.** That is the deliberate price
  of a dismissal that works without focusing the float. It comes back the
  moment the float closes.
- **`<Esc>`** is borrowed for the same window. Anything mapped to it is
  restored, not lost.
- **`<C-Down>` / `<C-Up>`** were chosen over `<M-Down>` / `<M-Up>` precisely
  because the latter is a widespread "move this line" binding. Both pairs are
  bound because PageUp/PageDown is an Fn chord on laptop and 60% layouts, and
  nothing at runtime can tell which keyboard this is.
- **A key listed in both lists is taken once, as a dismiss key** — the binding
  that always applies beats the one that only sometimes does. Without that, an
  unbind would "restore" one of our own mappings and it would outlive the
  float forever.

A configured list **replaces** the default rather than extending it; an empty
list binds nothing at all, which is how you take the scrolling over with your
own mappings (`require("hover").scroll(1)` / `(-1)`).
