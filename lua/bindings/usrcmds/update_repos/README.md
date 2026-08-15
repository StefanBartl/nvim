# bindings.usrcmds.update_repos

Registers `:MyReposUpdate [path]`. Scans `path` (or `$REPOS_DIR` when no
argument is given) for git repositories and runs `git fetch --all --prune`
+ `git pull --ff-only` on each, sequentially; non-git directories are
skipped.
