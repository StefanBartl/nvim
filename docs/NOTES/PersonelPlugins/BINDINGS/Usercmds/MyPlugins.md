# `:MyPlugins` — config-internal plugin-repo management

Not a plugin's own command — `:MyPlugins` lives in this config itself
(`lua/bindings/usrcmds/plugin_repos/`, alongside `:MyReposUpdate` and `:WhoLocks` under
`lua/bindings/usrcmds/`), managing the checkouts of the ~28 personal `.nvim` plugins
listed on this page. Listed here rather than under a per-plugin file because
it's about the personal-plugin *list itself*, not any one plugin. Built with
[`lib.nvim.bindings.usercmd.composer`](https://github.com/StefanBartl/lib.nvim/blob/main/lua/lib/nvim/bindings/usercmd/composer/README.md)
— full implementation notes and safety rationale:
[`lua/bindings/usrcmds/plugin_repos/README.md`](../../../../../lua/bindings/usrcmds/plugin_repos/README.md).

Replaces the former flat `:MyPluginsClone [dir]` / `:MyPluginsRemove [dir]`.

| Command | Effect |
| --- | --- |
| `:MyPlugins clone [dir] [--only=<name>] [--dry-run]` | Clone every repo in `plugins.personal.list` not yet present in `dir` (default `$REPOS_DIR`); `--only` limits to one, `--dry-run` only reports what would be cloned |
| `:MyPlugins remove [dir] [--only=<name>]` | Remove clean (no uncommitted/unpushed work) listed repos from `dir`, after a confirmation naming exactly what will be deleted |
| `:MyPlugins fetch [dir] [--only=<name>]` | `git fetch --all --prune` on every present listed repo |
| `:MyPlugins pull [dir] [--only=<name>]` | `git pull --ff-only` on every present listed repo |
| `:MyPlugins update [dir] [--only=<name>]` | `fetch` + `pull` on every present listed repo — the two-machine sync command, see below |
| `:MyPlugins dashboard [dir]` | Opens `reposcope.nvim`'s own `:Reposcope status [dir]` — a git-status overview of every repo in `dir`/`$REPOS_DIR` (not scoped to the plugin list). `:MyPluginsDashboard [dir]` is a flat shorthand for the bare form |
| `:MyPlugins reclone [dir] [--only=<name>] [--dry-run]` | Delete-if-clean + fresh clone for present repos (same safety check as `remove`); plain clone for anything missing. `--dry-run` prints the safe/unsafe/missing split and stops there |
| `:MyPlugins mode [auto\|dir\|remote\|disabled]` | Show, or persistently switch, `plugins.personal.source`'s `OVERRIDE` — writes directly into `source.lua` |
| `:MyPlugins list [dir]` | Read-only: every listed plugin plus whether it's present in `dir` |
| `:MyPlugins picker [dir]` | Interactive: `<Tab>` assigns clone/update/pull/fetch/remove/reclone per plugin, `<CR>` runs the whole batch |

`<Tab>` completes the subcommand, `dir` (real directories, plus a
`$REPOS_DIR` keyword when that env var is set), `--only`'s value (every name
in the live personal-plugin list), and `mode`'s value. A bare `--<Tab>`
lists the flags the current subcommand accepts. Bare `:MyPlugins` prints
this subcommand list.

## `--dry-run` — what it previews, and why it is free

`--dry-run` is not a second code path that could drift out of sync with the
real one: for `reclone`, the safe / unsafe / missing split *is* the preview,
and it was always computed before the confirmation prompt. `--dry-run` only
decides whether the command stops after reporting that split instead of going
on to confirm and act. For `clone`, it does not even need the check phase — it
reuses `ops.clone_one`'s own "already exists" predicate (a `loop.fs_stat`, no
git subprocess), so a dry run touches neither disk nor network beyond a stat.

```vim
:MyPlugins clone --dry-run     " what would be cloned
:MyPlugins reclone --dry-run   " which checkouts are clean enough to be replaced
```

## Keeping two machines in sync (`dir`-mode checkouts)

Every personal plugin is a real git checkout under `$REPOS_DIR` in `dir`
mode, present on more than one machine. Work happens on whichever machine
you're sitting at; the other one is left behind at an older commit. Before
relying on a plugin there, bring it level:

```vim
:MyPlugins update              " fetch + ff-only pull every present listed plugin
:MyPlugins update --only=x     " just one
```

If a checkout ever gets into a state a plain `pull` can't fix (diverged
history, corrupted `.git`, ...), `:MyPlugins reclone --only=<name>` deletes
it (after the same safety check `remove` uses) and clones it fresh. For
handling several plugins at once with different actions each — say, `update`
most of them but `reclone` one that's acting up — `:MyPlugins picker` opens
an interactive list: `<Tab>` on a plugin cycles it through
update/pull/fetch/remove/reclone (or just `clone` for one that's missing
entirely), `<CR>` runs everything assigned in a single batch.

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
:MyPlugins update                        " bring this machine level with what got pushed elsewhere
:MyPlugins dashboard                     " open reposcope.nvim's git-status dashboard for $REPOS_DIR
:MyPluginsDashboard                      " shorthand for the above
:MyPlugins reclone --only=filetree.nvim  " nuke and re-clone a checkout that's misbehaving
:MyPlugins picker                        " assign different actions to different plugins, run as one batch
:MyPlugins mode                          " show current OVERRIDE
:MyPlugins mode remote                   " switch all personal plugins to GitHub, then restart
```
