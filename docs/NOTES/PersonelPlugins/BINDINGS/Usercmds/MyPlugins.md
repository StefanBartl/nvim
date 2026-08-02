# `:MyPlugins` — config-internal plugin-repo management

Not a plugin's own command — `:MyPlugins` lives in this config itself
(`lua/usrcmds/plugin_repos/`, alongside `:MyReposUpdate` and `:WhoLocks` under
`lua/usrcmds/`), managing the checkouts of the ~28 personal `.nvim` plugins
listed on this page. Listed here rather than under a per-plugin file because
it's about the personal-plugin *list itself*, not any one plugin. Built with
[`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim/blob/main/lua/lib/nvim/usercmd/composer/README.md)
— full implementation notes and safety rationale:
[`lua/usrcmds/plugin_repos/README.md`](../../../../../lua/usrcmds/plugin_repos/README.md).

Replaces the former flat `:MyPluginsClone [dir]` / `:MyPluginsRemove [dir]`.

| Command | Effect |
| --- | --- |
| `:MyPlugins clone [dir] [--only=<name>]` | Clone every repo in `plugins.personal.list` not yet present in `dir` (default `$REPOS_DIR`); `--only` limits to one |
| `:MyPlugins remove [dir] [--only=<name>]` | Remove clean (no uncommitted/unpushed work) listed repos from `dir`, after a confirmation naming exactly what will be deleted |
| `:MyPlugins mode [auto\|dir\|remote\|disabled]` | Show, or persistently switch, `plugins.personal.source`'s `OVERRIDE` — writes directly into `source.lua` |
| `:MyPlugins list [dir]` | Read-only: every listed plugin plus whether it's present in `dir` |

`<Tab>` completes the subcommand, `dir` (real directories, plus a
`$REPOS_DIR` keyword when that env var is set), `--only`'s value (every name
in the live personal-plugin list), and `mode`'s value. Bare `:MyPlugins`
prints this subcommand list.

## Why `dir` never means "scan this folder"

`clone`/`remove`/`list` only ever touch the repos named in
[`plugins.personal.list`](../../../../../lua/plugins/personal/list.lua) —
`dir` is where to look for them, never a folder to enumerate. This matters
because `$REPOS_DIR` also holds non-plugin checkouts (`Notes`, `WKDBooks`,
...); a directory scan there would be actively unsafe for `remove`. Contrast
with [`reposcope.nvim`](./reposcope.nvim.md)'s `:Reposcope update`/`status`,
which *do* scan every immediate subdirectory of a given path — correct for
that plugin's job (managing an arbitrary clone folder), wrong for this one.

## `mode` — the persistent dir/remote/auto switch

`:MyPlugins mode` reads the current `OVERRIDE` value straight out of
[`lua/plugins/personal/source.lua`](../../../../../lua/plugins/personal/source.lua#L42)
(no separate runtime copy to drift out of sync); `:MyPlugins mode <value>`
rewrites just that one line, leaving the surrounding comments/formatting
untouched.

| Value | Effect |
| --- | --- |
| `auto` | Machine role (`machine.is("workstation")`) + the per-repo mode table decide |
| `dir` | Every personal plugin loads from `$REPOS_DIR` locally |
| `remote` | Every personal plugin loads from GitHub |
| `disabled` | None of them load |

**Restart required.** `source.lua` is `require()`d once and its result is
already baked into the spec list lazy loaded at startup — `:Lazy reload`
re-runs a plugin's `config()`, not the spec files, so it will not pick up a
`mode` change.

## Examples

```vim
:MyPlugins list                          " overview: what's present where
:MyPlugins clone                         " clone everything missing from $REPOS_DIR
:MyPlugins clone --only=language.nvim    " clone just one
:MyPlugins clone $REPOS_DIR --only=cascade.nvim
:MyPlugins remove --only=learn-cli.nvim  " remove one, if clean
:MyPlugins mode                          " show current OVERRIDE
:MyPlugins mode remote                   " switch all personal plugins to GitHub, then restart
```
