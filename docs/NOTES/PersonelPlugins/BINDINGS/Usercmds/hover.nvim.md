# hover.nvim — User Commands Cheatsheet

New repository, 2026-09-01. Extracted from `lib.nvim.hover`, whose
`:Lib hover …` routes this replaces. Those are **gone** as of 2026-09-01
(lib.nvim `5450dd4`): the module, the routes, the `hover` field on
`Lib.NvimUsrCmds.Options` and the `hover = false` line in this config all went
together, so `:Lib hover …` no longer exists in any form.

Built on `lib.nvim.bindings.usercmd.composer`. Registered from
`plugin/hover.lua`, so `:Hover` exists before `setup()` runs and in a session
where nothing turned the hover on — which is the state someone typing
`:Hover mode auto` is most likely to be in.

Source: `lua/hover/bindings/usrcmds.lua` (routes generated from
`lua/hover/switches.lua`)
Docs: `docs/BINDINGS.md`, `doc/hover.txt`, `README.md`

## Routes

| Command | Args | Notes |
| --- | --- | --- |
| `:Hover show` | — | one hover, here, now; ignores every volume switch |
| `:Hover status` | — | mode + all nine switches, as a selectable list |
| `:Hover why` | — | why nothing hovered here — names which gate declined |
| `:Hover next` | — | step to the next plugin with something to say about this place; wraps past the last |
| `:Hover pin` | — | keep this float on screen while the cursor moves away |
| `:Hover resize [direction]` | `bigger\|smaller` | make the hover on screen bigger or smaller. Omitted: **bigger**. **Any** hover — a picture is drawn larger, a text preview shows more lines |
| `:Hover zoom [direction]` | `in\|out\|reset` | magnify a *detail* of the picture on screen. Omitted: **in**. Bilder **und** PDF-Seiten seit hover.nvim `7fdfc09` — eine Seite wird dabei bei hoeherem DPI neu gerastert statt beschnitten. Ein Schritt kostet ~258 ms (Bild) bzw. 207–752 ms (Seite), also zu langsam zum Gedrueckthalten. Tasten seit `21c4932`: `>` / `\|` / `=`, blank statt Alt-Akkord, weil dieses Terminal keinen sendet |
| `:Hover nav {direction}` | `left\|right\|up\|down` | move the magnified view. Required argument. The keyboard counterpart to the borrowed `h/j/k/l`, which only exist while zoomed and are therefore undiscoverable |
| `:Hover mode [state]` | `auto\|manual\|off` | omitted: reports the current mode |
| `:Hover toggle` | — | off if on, back to `auto` if off |
| `:Hover links [state]` | `on\|off\|toggle` | whether link syntax hovers at all |
| `:Hover links web [state]` | `on\|off\|toggle` | http(s) links. Implies `links on` |
| `:Hover links web fetch [state]` | `on\|off\|toggle` | status code + title. Implies `links web on` |
| `:Hover paths [state]` | `on\|off\|toggle` | bare paths in prose |
| `:Hover paths missing [state]` | `on\|off\|toggle` | mark a path that resolves to nothing |
| `:Hover paths code [state]` | `on\|off\|toggle` | hover a path inside executable code, not just comments and strings. **Default off.** Implies `paths on` |
| `:Hover images [state]` | `on\|off\|toggle` | draw pictures, or describe them |
| `:Hover positions [state]` | `on\|off\|toggle` | whether a plugin may speak about a cursor position that points at nothing |
| `:Hover office [state]` | `on\|off\|toggle` | render office docs via PDF |

Every `state` argument is an `enum`, so it completes. **Omitting it toggles** —
`:Hover links` flips, `:Hover links off` is explicit.

## Notes

- **Routes are generated, not written.** `switch_route(name)` builds one route
  per entry in `hover.switches`; the same table feeds `:Hover status` and the
  `:checkhealth hover` section. A tenth switch is one table entry and nothing
  else, and dispatch/completion/docs cannot drift apart. `paths code` was the
  eighth and cost exactly that — one entry plus one name in `ORDER`.

  **This has been the repository's recurring bug, three times.** Every place
  that kept its own list of switches by hand eventually fell behind the table
  without anything failing: `route_path` filed a new switch at top level
  instead of under its parent, `switches.effective` reported one as off while
  it was on (so `:Hover status` *and* `:checkhealth` both lied), and a preview
  badge advertised a command that no longer existed. All three are derived
  now. **The same applies to this file** — but see the next entry for what
  can and cannot check it.

- **`:Bindings check` does not cover this table, and it looks like it does.**
  Measured on 2026-09-02: a row was deleted from the table above and both
  `:Bindings check hover.nvim` and the full `:Bindings check` reported *no
  drift*. hover.nvim was loaded and checked — it does not appear under
  "not loaded this session, skipped" — so this is not a gap in coverage but
  in resolution.

  The reason: the checker compares documented commands against
  `nvim_get_commands({})`, which lists **top-level Vim commands only**. This
  plugin registers exactly one, `Hover`; every route above is a composer
  sub-route and is invisible there. All fifteen rows collapse onto the same
  live name, it exists, and both directions pass trivially.

  So the authority for this table is **`composer.document("Hover")`**, which
  is the mechanical dump of the route tree. Note that it *writes a file* named
  after the command and returns `true` — it does not return the text.

  This is worth a bindings-explorer task: every plugin built on
  `usercmd.composer` has the same blind spot, and a passing check on a rotten
  table is worse than no check.

- **`web` and `fetch` nest under `links` in the command tree** even though
  they are flat entries in the switch table (`route_path()` maps them). The
  tree reads like the implication chain rather than like seven booleans.

- **Implication is upward only.** `fetch` → `web` → `links` on the write side.
  Downward is answered on the *read* side (`config.web_enabled()` is
  `links_enabled() and links.web`), so `:Hover links off` silences web links
  without clearing their flag — turn `links` back on and `web` is as you left
  it.

- **No range, deliberately.** Every route acts on the cursor position or on a
  session-wide switch; neither has a reading over a line range, and a route
  that accepted a range and ignored it would be worse than one that does not.

- **No count.** Nothing here is a motion. The two that are (`scroll(1)` /
  `scroll(-1)`) are keys, not commands, and borrowed ones at that — a count
  prefix typed at a borrowed key is indistinguishable from one meant for the
  mapping it displaced. Noted in the plugin's `docs/ROADMAP.md`.

- **`:Hover why` is the one route that answers about an *absence*.**
  Everything else acts or reports state; this one explains why nothing
  happened, by naming which of the gates declined — mode, a switch, the
  scope gate, no source, no preview, nothing under the cursor. It exists
  because "no float appeared" is the plugin's most common failure mode and
  was, until then, indistinguishable from "the plugin is broken".

- **`:Hover resize` exists for two reasons, and the second one grew.** First,
  the keys are a *borrow*: `+` and `-` are bound only while a hover with a
  picture is on screen, so someone who has never had one open has no way to
  find the feature — and `:Hover` completion is where the rest of this plugin
  is found. Second, since the rename (hover.nvim `8ec5b40`) `+` and `-` are
  deliberately **not** bound for a text hover at all, because they are motions
  there. For text this route *is* the keyboard way in; the wheel is the other.
  It also needs no chord, which matters for the reserved combinations listed
  in the keymaps file.

  It works at all because **entering the command line moves no cursor**: the
  float's dismissal hangs on `CursorMoved`, `InsertEnter`, `BufLeave` and
  `WinScrolled`, and typing `:` fires none of them. That is pinned by a spec
  rather than assumed — if it were false the route would be a command that
  closes the thing it acts on.

  Omitting the direction makes it **bigger**, not "toggle" like the switches:
  a step has no reverse reading, and `smaller` undoes a wrong guess in one
  keypress.

- **`:Hover pin` has no `unpin`.** A pinned float is dismissed the same way
  any float is; a second verb for the reverse would have to be typed *into*
  a window that is deliberately not focused.

- **`positions` guards a different trust boundary than the other switches.**
  The others decide which kind of *target* may hover. This one decides
  whether a registered plugin may speak about a position that points at
  nothing — which is the only class where the content is authored entirely
  elsewhere. With nothing registered it costs nothing: the trigger is not
  installed at all.

- **`paths code` is about *where*, not *what*.** Every other switch decides
  which kind of target may hover. This one decides whether the cursor's
  *position* disqualifies it: off, a spot Treesitter identifies as executable
  code is skipped, so `vim.api.foo` and `a / b` stop opening floats while a
  path in a comment or a string still does. Prose is untouched — no parser, no
  captures, or an unfamiliar capture family all fall through to "look anyway".
  `:Hover show` ignores it entirely.

## Changelog

- 2026-09-03: **`:Hover next` added** (hover.nvim `ac0a372`), the
  borrow-free half of `<M-n>`. Seventeen routes now. It steps between the
  plugins that answer for one *place* — until then the first registered one
  won and the rest were invisible, which plugin load order decided. Stepped
  rather than merged: `Hover.Content` is shaped for one answer, so two would
  mean two titles for one border and two filetypes for one highlight, and a
  picture cannot be merged with text at all.

- 2026-09-02 (4): **`:Hover pan` heißt `:Hover nav`** (hover.nvim `efafb82`).
  Weiter achtzehn Routen. Umbenannt statt aliasiert: `pan` ist das präzisere
  Wort für die Operation und das falsche für ein Verb, das jemand tippt — und
  ein Alias für eine umbenannte Operation ist genau der Bug von `bd72836`. Der
  Name war einen Tag alt.

- 2026-09-02 (3): **`:Hover zoom` und `:Hover pan` fehlten hier ganz** — seit
  hover.nvim `9fba190`. Damit sind es **achtzehn** Routen, nicht sechzehn.
  `zoom` ist nicht die alte Route unter altem Namen, sondern ein anderes
  Feature auf dem freigewordenen Wort: gleiche Kiste, Ausschnitt aus der
  Quelle, nur für Bilder, ~258 ms je Schritt.

- 2026-09-02 (2): **`hover.zoom()` ist kein Alias mehr** (hover.nvim
  `bd72836`) — und war seit `9fba190` auch keiner. Dort entstand ein echtes
  `M.zoom` als zweite Definition desselben Namens, und Lua nimmt die zweite;
  der Alias war ab dem Tag tot, ohne dass etwas fehlschlug. Der Eintrag
  darunter behauptet ihn noch — er bleibt stehen, weil er beschreibt, was
  damals stimmte.

- 2026-09-02: **`:Hover zoom` heißt `:Hover resize`** (hover.nvim `8ec5b40`),
  und die Argumente `in|out` heißen `bigger|smaller`. Immer noch sechzehn
  Routen. Der Grund ist kein Namensgeschmack: `zoom` las genau *ein* Feld,
  und das multiplizierte `max_width`/`max_lines` für eine Vorschau — also
  „größere Kiste, ganzes Bild hineinskaliert", nie ein Ausschnitt. Damit hat
  die Operation auch für Text eine Antwort (mehr Zeilen), und die Route gilt
  jetzt für **jeden** Hover statt nur für gezeichnete. `zoom_keys` wird von
  `config.normalize()` gefaltet, `hover.zoom()` bleibt als Alias.

- 2026-09-02: **`:Hover zoom [in|out]` added** (hover.nvim `2493e1b`). Sixteen
  routes now. Zoom itself shipped with `204d083` as borrowed keys only; this
  is the reachable-without-a-float-open half. Also corrected in the keymaps
  file: that one said a route existed for `scroll` and not for zoom — there is
  **no** `:Hover scroll` either, and there never was.

- 2026-09-02: three routes were missing here entirely — `:Hover why`,
  `:Hover pin` and `:Hover positions`. The file documented 7 of 15
  invocations and called the switch count eight when it was nine. Rebuilt
  against `composer.document("Hover")`, which is the mechanical dump, rather
  than against the README.
- 2026-09-01: `:Hover paths code` added (hover.nvim `b2b4b2c`) — eighth
  switch, default off. `:Hover status` now lists eight.
- 2026-09-01: `:Lib hover …` is gone rather than merely switched off —
  lib.nvim `5450dd4` deleted the module the routes drove.
