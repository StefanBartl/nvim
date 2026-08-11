# `:DocMapAll` — generate documentation.nvim's map for every personal plugin

Not a plugin's own command — `:DocMapAll` lives in this config itself
(`lua/bindings/usrcmds/docmap_all/`, alongside `:MyPlugins`, `:MyReposUpdate`
and `:WhoLocks` under `lua/bindings/usrcmds/`), not under any one plugin's
own file. Listed here for the same reason [`MyPlugins.md`](MyPlugins.md) is:
it is about the personal-plugin *list itself*, not any one plugin.

| Command | Effect |
| --- | --- |
| `:DocMapAll` | Run `documentation.nvim`'s `generate()` for every enabled personal plugin that has a local checkout on this machine |

Bare, no arguments — it always means "every enabled, locally-checked-out
plugin," the same set [`plugins.personal.export.projects()`](../../../../../lua/plugins/personal/export.lua)
returns.

## What it reads

Built on `plugins.personal.export.projects()`, which itself wraps
[`plugins.personal.list`](../../../../../lua/plugins/personal/list.lua) —
the same drift-proof, fully-resolved entry list `:MyPlugins` and the
statusline's own/external badge already read, plus one thing `list.lua`
deliberately does not carry: each plugin's resolved local directory (via
`personal_utils.local_dev()`). A remote-mode entry with no local checkout
has nothing to scan and is filtered out rather than passed through with a
directory a caller would have to remember to check for `nil`.

`title` is set to each plugin's own short name on purpose, not left to
`documentation.nvim`'s default — that name is also the exact
`runtime-analysis.nvim` telemetry namespace `config/telemetry.lua` already
writes to for every one of these plugins (deep instrumentation, on by
default, reading this same entry list), so a generated map's Telemetry
panel is joined to real, already-collected data with no extra wiring on
either side.

## Headless export, for callers outside this Neovim process

`scripts/docmap_projects.lua` prints the same project list as JSON, for
anything that needs it without a live editor session —
[`docmap-desktop`](https://github.com/StefanBartl/docmap-desktop)'s own
"Import from Neovim…" button is the reason this exists:

```
nvim --headless -c "luafile scripts/docmap_projects.lua" -c "qa"
```

**Must be `-c "luafile ..."`, not `-l`.** Measured, not assumed: plain
`nvim --headless -l scripts/docmap_projects.lua` fails to even find
`lib.nvim`, because `-l` is a bare Lua-script runner that skips this
config's own `init.lua` and lazy.nvim's bootstrap entirely — the export
needs the real, fully-resolved plugin policy (`source.lua`'s mode table,
machine detection), which only exists after a real startup has run.
`-c "luafile ..." -c "qa"` goes through the normal startup sequence first.

stdout carries exactly one line of JSON, no pretty-printing; anything that
goes wrong is reported on stderr with a non-zero exit code, so a subprocess
caller can check `.code` without parsing stdout in the failure case.

## Notes

- Sequential, not parallel — same reasoning `:MyReposUpdate` and
  `docmap-desktop`'s own "Generate all" button both use: each run is a real
  CPU-bound process (`documentation.nvim`'s own LuaLS enrichment pass,
  `full` mode), and running a dozen at once would not finish sooner while
  making the editor genuinely unresponsive rather than just slow.
- One project failing (a scan error, a LuaLS timeout) does not abort the
  rest; the closing report names every one that failed once the whole batch
  finishes.
- **Never fires on its own.** Generation writes into `docs/map` *inside*
  each project's own repository — running that unasked on every plugin
  update or config reload would be exactly the kind of uninvited,
  hard-to-notice git-diff-producing side effect
  `docmap-desktop`'s own auto-generate logic was built to avoid (fires only
  when a project has no map yet, never re-fires on one that does).
  `:DocMapAll` is the explicit request that path deliberately declines to
  infer.

## Changelog

- 2026-08-11 — added, alongside `plugins.personal.export` and
  `scripts/docmap_projects.lua`, to back `docmap-desktop`'s spec-import
  feature.
