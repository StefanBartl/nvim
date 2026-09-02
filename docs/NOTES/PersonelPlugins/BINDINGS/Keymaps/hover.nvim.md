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
| `open_keys` | `gf` | every hover | open what the float is showing — routed through open.nvim when present, else `vim.ui.open` |
| `scroll_keys.down` | `<M-PageDown>`, `<C-Down>` | scrollable only | next screenful / next PDF page |
| `scroll_keys.up` | `<M-PageUp>`, `<C-Up>` | scrollable only | back |
| `zoom_keys.larger` | `+` | **hovers with a picture only** | die Bildfläche einen Schritt (×1,25) größer |
| `zoom_keys.smaller` | `-` | **hovers with a picture only** | einen Schritt kleiner |

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
- **`gf` is a Vim builtin, and this displaces it while a float is up.** That
  is the intent rather than an accident: with a hover open, the file `gf`
  would jump to and the file the float is showing are the same one, and the
  float already resolved it — including the cases `gf` cannot do, such as a
  truncated path or a `:line:col` suffix. With no float open, `gf` is
  untouched.
- **Zoom hängt an einer *anderen* Bedingung als Scroll**, und musste das.
  Scroll hängt an `content.scroll`, das ein Bild bewusst nicht deklariert —
  Zoom liest `content.canvas`. Hätte man Zoom an die Scroll-Bedingung gehängt,
  wäre es für jeden Fall außer dem eigenen gebunden gewesen. Praktisch heißt
  das: `+` und `-` sind auf einem Text-Hover **frei** und behalten dort, was
  sie sonst bedeuten (`+`/`-` als Zeilenbewegung).
- **The open key is taken *before* the scroll keys**, so a key configured as
  both opens rather than scrolls. Opening is what a reader means by pressing
  something; scrolling has two keys of its own either way.
- **A key listed in both lists is taken once, as a dismiss key** — the binding
  that always applies beats the one that only sometimes does. Without that, an
  unbind would "restore" one of our own mappings and it would outlive the
  float forever.

A configured list **replaces** the default rather than extending it; an empty
list binds nothing at all, which is how you take the scrolling over with your
own mappings (`require("hover").scroll(1)` / `(-1)`).

## Reserviert und ausgeschlossen — für den Zoom-Ausbau

Festgehalten am **2026-09-02**, bevor gebaut wird: welche Akkorde für Schritt 3
des Zooms (Mausrad) und für einen zweiten Tastensatz überhaupt zur Verfügung
stehen. Die Liste ist eine Aussage über **diese** Config, nicht über das
Plugin — hover.nvims Defaults bleiben `+` / `-`.

| Akkord | Status | Grund |
| --- | --- | --- |
| `<C-+>` / `<C-->` | **ausgeschlossen** | das allgemeine Fenster-Zoom, gehört nicht dem Plugin |
| `<C-ScrollWheel>` | **ausgeschlossen** | dieselbe Bedeutung wie oben; in WezTerm zoomt es hier zwar nicht, aber die Erwartung ist gesetzt |
| `<M-->` | **vergeben** | cascade.nvim, Bullet Points — bleibt, wo es ist |
| `<M-+>` | frei | aber ohne Partner: `<M-->` ist weg, ein Regler mit nur einer Richtung ist keiner |
| `<M-ScrollWheelUp/Down>` | **frei, und der Kandidat für Schritt 3** | kollidiert mit nichts, und Schritt 3 braucht ohnehin `getmousepos()` in einer globalen Map |
| `<S-+>` / `<S-->` | frei, **aber ungeprüft** | siehe unten |
| `<C-S-+>` / `<C-S-->` | frei, **aber ungeprüft** | dito |

**Die ungeprüfte Stelle, und sie ist keine Kleinigkeit.** Neovim *nimmt* diese
Schreibweisen an und hält sie von `+` / `-` getrennt (nachgemessen 2026-09-02
mit `maparg`). Ob das Terminal sie je **sendet**, ist eine andere Frage: auf
deutscher Tastatur ist Shift+`+` das Zeichen `*`, und ohne
Kitty-Keyboard-Protokoll kommt bei Neovim nie ein `<S-+>` an, sondern ein
`*`. WezTerm beherrscht das Protokoll, es ist also plausibel — aber zu prüfen,
bevor darauf gebaut wird. Der Test ist eine Minute:

```vim
:nnoremap <S-+> :echo "S-plus kommt an"<CR>
```

**Der Usercommand gibt es jetzt:** `:Hover zoom [in|out]`, ohne Argument
zoomt er hinein. Damit ist Zoom erreichbar, ohne dass eine Taste geliehen sein
muss — und ohne Akkord, was den offenen `<S-+>`-Test oben entschärft: er
entscheidet nur noch über Komfort, nicht mehr über Erreichbarkeit.

**Nebenbei korrigiert:** hier stand, es gebe eine `:Hover`-Route für `scroll`
und keine für Zoom. Eine für `scroll` gibt es **nicht** — nachgezählt gegen
`usrcmds.routes()`: sechzehn Routen, `scroll` ist keine davon. Gescrollt wird
ausschließlich über die geliehenen Tasten.

## Notes

- **Kein which-key** — geprüft und verneint: `lua/hover/` enthält kein
  `which_key`-Modul und keinen `which_key`-Config-Key. Es gibt auch nichts zu
  gruppieren: der einzige *besessene* Key ist `keymaps.show`, per Default
  ungebunden, und alle übrigen sind geliehen und existieren nur, solange ein
  Float offen ist — ein Präfix-Menü über Tasten, die es meistens nicht gibt,
  wäre irreführend.

## Changelog

- 2026-09-02: **`zoom_keys` fehlten hier ganz** — seit hover.nvim `204d083`
  geliehen (`+` / `-`, nur für Hovers mit Bild), in hover.nvims eigener
  `docs/BINDINGS.md` dokumentiert, in dieser Datei nicht. Dazu der Abschnitt
  über reservierte Akkorde für den Ausbau.
- 2026-09-02: `open_keys` (`gf`) fehlte hier ganz — seit hover.nvim `f2e0788`
  geliehen, wie die Dismiss- und Scroll-Tasten, und die einzige davon, die
  ein Vim-Builtin verdrängt. Kollisionsabschnitt entsprechend ergänzt.
- 2026-09-01: unverändert durch hover.nvim `b2b4b2c` (`:Hover paths code`) —
  der neue Schalter ist ein Usercommand ohne Taste, wie alle anderen auch.
