#!/usr/bin/env bash
# install.sh -- install the git hooks of this directory into one or more repos.
#
#   bash scripts/git-hooks/install.sh [--commit-msg-only] <repo> [<repo> ...]
#
# Installs two hooks, each as a one-liner that calls the script from this checkout
# (later changes to the scripts need no reinstall):
#   pre-commit  -> pre-commit-large-files.sh        (marker: large-files-hook)
#   commit-msg  -> commit-msg-no-claude-trailer.sh  (marker: no-claude-trailer-hook)
# --commit-msg-only installs just the commit-msg hook. An existing hook that is not
# ours is left alone (reported, exit 1).

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0
only_commit_msg=0
if [ "$1" = "--commit-msg-only" ]; then
  only_commit_msg=1
  shift
fi

# install_hook <hooks-dir> <hook-name> <script> <marker>
install_hook() {
  local target="$1/$2"
  if [ -f "$target" ] && ! grep -q "$4" "$target"; then
    echo "skip: $target exists and is not ours" >&2
    status=1
    return
  fi
  printf '#!/usr/bin/env bash\n%s\nexec bash "%s" "$@"\n' "$4" "$3" >"$target"
  chmod +x "$target"
  echo "installed: $target"
}

for repo in "$@"; do
  hooks="$(git -C "$repo" rev-parse --git-path hooks 2>/dev/null)" || {
    echo "skip: $repo is not a git repository" >&2
    status=1
    continue
  }
  case "$hooks" in /* | [A-Za-z]:*) ;; *) hooks="$repo/$hooks" ;; esac
  mkdir -p "$hooks"
  if [ "$only_commit_msg" -eq 0 ]; then
    install_hook "$hooks" pre-commit "$here/pre-commit-large-files.sh" "# large-files-hook"
  fi
  install_hook "$hooks" commit-msg "$here/commit-msg-no-claude-trailer.sh" "# no-claude-trailer-hook"
done

exit $status
