#!/usr/bin/env bash
# install.sh -- install the large-file pre-commit warning into one or more repos.
#
#   bash scripts/git-hooks/install.sh <repo> [<repo> ...]
#
# Writes .git/hooks/pre-commit as a one-liner that calls pre-commit-large-files.sh
# from this checkout, so later changes to the script need no reinstall. An existing
# pre-commit hook that is not ours is left alone (reported, exit 1).

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/pre-commit-large-files.sh"
marker="# large-files-hook"
status=0

for repo in "$@"; do
  hooks="$(git -C "$repo" rev-parse --git-path hooks 2>/dev/null)" || {
    echo "skip: $repo is not a git repository" >&2
    status=1
    continue
  }
  case "$hooks" in /* | [A-Za-z]:*) ;; *) hooks="$repo/$hooks" ;; esac
  target="$hooks/pre-commit"
  if [ -f "$target" ] && ! grep -q "$marker" "$target"; then
    echo "skip: $target exists and is not ours" >&2
    status=1
    continue
  fi
  mkdir -p "$hooks"
  printf '#!/usr/bin/env bash\n%s\nexec bash "%s" "$@"\n' "$marker" "$script" >"$target"
  chmod +x "$target"
  echo "installed: $target"
done

exit $status
