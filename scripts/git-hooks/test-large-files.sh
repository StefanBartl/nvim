#!/usr/bin/env bash
# test-large-files.sh -- scenario test for pre-commit-large-files.sh.
#
#   bash scripts/git-hooks/test-large-files.sh
#
# Builds throwaway repos under a temp dir, installs the hook and checks what lands in
# the commit. The interactive prompt is fed from a file via LARGE_FILE_TTY.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$here/pre-commit-large-files.sh"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
fails=0

check() { # check <description> <command...>
  local what="$1"
  shift
  if "$@"; then echo "ok   $what"; else echo "FAIL $what"; fails=$((fails + 1)); fi
}
not() { ! "$@"; }
export LARGE_FILE_MB=1
new_repo() {
  repo="$root/$1"
  mkdir -p "$repo" && cd "$repo" && git init -q && git config user.email t@t && git config user.name t
  bash "$here/install.sh" . >/dev/null
}

big_text() { yes "repeated log line 0123456789" | head -c "${2:-1500000}" >"$1"; }
in_head() { git ls-tree -r --name-only HEAD 2>/dev/null | grep -qxF -- "$1"; }
no_commit() { ! git rev-parse -q --verify HEAD >/dev/null; }

# No terminal: abort, nothing committed.
new_repo plain
big_text "a b.evtx"
git add -A
git commit -qm t </dev/null 2>/dev/null
check "no terminal aborts" no_commit

# LARGE_FILE_ACTION=compress: the zip is committed, the original stays untracked.
LARGE_FILE_ACTION=compress git commit -qm t </dev/null 2>/dev/null
check "action=compress commits the zip" in_head "a b.evtx.zip"
check "action=compress leaves the original out" not in_head "a b.evtx"
check "action=compress keeps the original on disk" test -f "a b.evtx"

# Interactive: c, then y deletes the originals.
new_repo interactive
mkdir sub && big_text sub/App.evtx && big_text Sys.evtx 1800000
git add -A
printf 'c\ny\n' >"$root/answers"
LARGE_FILE_TTY="$root/answers" git commit -qm t 2>/dev/null
check "interactive c commits both zips" in_head sub/App.evtx.zip
check "interactive c commits the second zip" in_head Sys.evtx.zip
check "interactive y deletes the originals" test ! -e sub/App.evtx

# Interactive: N aborts.
new_repo declined
big_text x.log
git add -A
printf 'n\n' >"$root/answers"
LARGE_FILE_TTY="$root/answers" git commit -qm t 2>/dev/null
check "interactive N aborts" no_commit

# Partial commit (`git commit <paths>`): compressing is refused.
new_repo partial
echo seed >seed.txt && git add seed.txt && git commit -qm seed
big_text p.log
git add p.log
LARGE_FILE_ACTION=compress git commit -qm p -- p.log </dev/null 2>/dev/null
check "partial commit is refused" not in_head p.log
check "partial commit writes no zip" test ! -e p.log.zip

# --compress outside a commit, with LARGE_FILE_DELETE=1.
new_repo standalone
big_text s.log
git add -A
LARGE_FILE_DELETE=1 bash "$hook" --compress 2>/dev/null
check "--compress stages the zip" test "$(git diff --cached --name-only)" = s.log.zip
check "--compress deletes the original" test ! -e s.log

# Still too large after compressing: asked again.
new_repo incompressible
head -c 1500000 /dev/urandom >r.bin
git add -A
printf 'c\nn\nn\n' >"$root/answers"
LARGE_FILE_TTY="$root/answers" git commit -qm t 2>/dev/null
check "still-large zip is asked about again" no_commit

echo
[ "$fails" -eq 0 ] && echo "all passed" || echo "$fails failed"
exit $((fails > 0))
