# hover.nvim — User Commands Cheatsheet

New repository, 2026-09-01. Extracted from `lib.nvim.hover`, whose
`:Lib hover …` routes this replaces — those are switched off in the config
(`lib.nvim_usrcmds.setup({ hover = false })`) and can be deleted from lib.nvim
outright once its `lua/lib/nvim/hover/` goes.

Built on `lib.nvim.bindings.usercmd.composer`. Registered from
`plugin/hover.lua`, so `:Hover` exists before `setup()` runs and in a session
where nothing turned the hover on — which is the state someone typing
`:Hover mode auto` is most likely to be in.

Source: `lua/hover/bindings/usrcmds.lua` (routes generated from
`lua/hover/switches.lua`)
Docs: `docs/BINDINGS.md`, `doc/hover.txt`, `README.md`

| Command | Args | Notes |
| --- | --- | --- |
| `:Hover show` | — | one hover, here, now; ignores every volume switch |
| `:Hover status` | — | mode + all seven switches in one message |
| `:Hover mode [state]` | `auto\|manual\|off` | omitted: reports the current mode |
| `:Hover toggle` | — | off if on, back to `auto` if off |
| `:Hover links [state]` | `on\|off\|toggle` | whether link syntax hovers at all |
| `:Hover links web [state]` | `on\|off\|toggle` | http(s) links. Implies `links on` |
| `:Hover links web fetch [state]` | `on\|off\|toggle` | status code + title. Implies `links web on` |
| `:Hover paths [state]` | `on\|off\|toggle` | bare paths in prose |
| `:Hover paths missing [state]` | `on\|off\|toggle` | mark a path that resolves to nothing |
| `:Hover images [state]` | `on\|off\|toggle` | draw pictures, or describe them |
| `:Hover office [state]` | `on\|off\|toggle` | render office docs via PDF |

Every `state` argument is an `enum`, so it completes. **Omitting it toggles** —
`:Hover links` flips, `:Hover links off` is explicit.

## Notes

- **Routes are generated, not written.** `switch_route(name)` builds one route
  per entry in `hover.switches`; the same table feeds `:Hover status` and the
  `:checkhealth hover` section. An eighth switch is one table entry and
  nothing else, and dispatch/completion/docs cannot drift apart.

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
