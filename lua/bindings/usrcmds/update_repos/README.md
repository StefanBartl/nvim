# bindings.usrcmds.update_repos

Config-internal, not a plugin's own command — alongside `:MyPlugins`
(`../plugin_repos/`) and `:WhoLocks` (`../who_locks/`).

| Command | Effect |
| --- | --- |
| `:MyReposUpdate [path]` | `git fetch --all --prune` + `git pull --ff-only` on every git repo directly under `path` (default `$REPOS_DIR`), sequentially |
| `:MyReposUpdate [path] --only=<name>` | The same, restricted to the one repo whose directory basename matches |

Non-git directories are skipped. Errors are collected and reported once every
repo has been attempted, so one hung or slow repo cannot silently block the
report on the others. Per-repo progress goes through `lib.nvim.progress`
(soft dependency, rendered by the statusline's `plugin_progress` module).

`<Tab>` completes `path` — `$REPOS_DIR` when that env var is set, plus real
directories — and `--only=`'s value.

## How this differs from `:MyPlugins update`

The two commands look interchangeable and are not:

|  | `:MyPlugins update` | `:MyReposUpdate` |
| --- | --- | --- |
| What it touches | only the repos named in `plugins.personal.list` | *every* git repo it finds under the directory |
| `dir`/`path` means | where to look for the listed repos | the folder to enumerate |
| `--only=<name>` | validated against the live plugin list | filters the scan's result by directory basename |

So `$REPOS_DIR`'s non-plugin checkouts (`Notes`, `WKDBooks`, ...) are updated
by this command and ignored by `:MyPlugins update`. That is also why `--only`
cannot share `:MyPlugins`'s `MYPLUGINS_NAME` argument type: there is no list
to validate against here, only whatever the scan happens to find.

## Examples

```vim
:MyReposUpdate                          " every repo under $REPOS_DIR
:MyReposUpdate $REPOS_DIR               " the same, spelled out
:MyReposUpdate C:/repos --only=Notes    " just one, by directory name
```
