# documentation.nvim — Usercmds Cheatsheet

Source: `lua/documentation/bindings/usrcmds/` — `init.lua` dispatches, one file
per action.
Cross-reference: the repo's `docs/BINDINGS.md` (generated) and
`docs/COMMANDS.md` (prose reference).

Two commands, split along one line: **`:DocMap` writes or verifies artifacts,
`:DocBrowse` only ever reads.** The viewer is deliberately not a `:DocMap`
subcommand — folding a read-only viewer into a command whose bare form rewrites
files on disk is the kind of surprise that gets a command bound to a key and
then regretted.

Both names are configurable (`opts.command_name`, `opts.browse_command_name`),
which is what lets a *consuming* plugin generate its own map without
overwriting these.

## `:DocMap`

| Invocation | Does | Writes? |
| --- | --- | --- |
| `:DocMap` | Rescan and regenerate all artifacts | **yes** |
| `:DocMap full` | Same, with LuaLS enrichment (`@class`/`@alias` detail, type edges). Costs seconds. | **yes** |
| `:DocMap check` | Verify without writing; findings → quickfix. What the pre-commit hook runs. | no |
| `:DocMap open` | Open the generated HTML in the system browser | no |
| `:DocMap graph {deps\|calls} [module]` | Open the page on that graph, centered | no |
| `:DocMap dot [deps\|calls] [module]` | Graphviz DOT source in a scratch buffer (`:%!dot -Tsvg`) | no |
| `:DocMap why <a> <b>` | Shortest require path between two modules → quickfix, one entry per hop | no |
| `:DocMap diff [ref]` | What changed about the tree's *shape* since `ref` (default HEAD) | no |
| `:DocMap impact [ref]` | Where changed *lines* radiate to: functions → callers → quickfix | no |
| `:DocMap churn [range]` | Churn × complexity, hottest first → quickfix | no |
| `:DocMap serve [stop]` | Local map server on `127.0.0.1`, OS-assigned port. Enables the History tab. | no |
| `:DocMap helptags` | Regenerate this plugin's own `doc/tags` | writes `doc/tags` |

**Only a genuinely empty argument regenerates.** An unknown action reports what
it expected. (Until 2026-07-28 the old if-chain fell through to the default, so
`:DocMap graph` with a missing argument — or any typo — silently rewrote files.)

Completion is two-level: the action first, then real module paths once an
action that takes one is typed. It offers exactly what `find_node` resolves,
namespaces included.

## `:DocBrowse`

| Invocation | Opens on |
| --- | --- |
| `:DocBrowse` | the structure list, from the committed artifact (~10 ms) |
| `:DocBrowse live` | same, but installing a watching handle that rescans on write (~0.65 s once) |
| `:DocBrowse {module}` | centered on one module |
| `:DocBrowse history` | the commit list |
| `:DocBrowse trail` | the pinned positions |

`live` is a prefix a module name may follow; `history` and `trail` stand *where*
a module name would.

## Global-surface collision check (2026-07-28)

The command names are this plugin's only global surface. Checked against every
`Usercmds/*.md` in this folder: **`DocMap` and `DocBrowse` are unique** — no
other personal plugin registers either name or a `Doc`-prefixed command.

Note `:checkhealth documentation` is also registered, implicitly, by the
presence of `lua/documentation/editor/health.lua`.
