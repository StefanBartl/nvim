#!/usr/bin/env bash
# test-commit-msg-no-claude-trailer.sh -- scenario test for commit-msg-no-claude-trailer.sh.
#
#   bash scripts/git-hooks/test-commit-msg-no-claude-trailer.sh
#
# Runs the hook on message files and through a real `git commit -F` in a temp repo.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$here/commit-msg-no-claude-trailer.sh"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
fails=0

check() { # check <description> <command...>
  local what="$1"
  shift
  if "$@"; then echo "ok   $what"; else echo "FAIL $what"; fails=$((fails + 1)); fi
}
same() { cmp -s "$1" "$2"; }

# run_hook <name> <message>: writes the message to $root/<name>, runs the hook on it.
run_hook() {
  printf '%s' "$2" >"$root/$1"
  bash "$hook" "$root/$1" 2>/dev/null
}

# (a) trailers are removed, in several spellings.
run_hook a1 $'subject\n\nbody\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n'
check "a: Claude trailer removed" same "$root/a1" <(printf 'subject\n\nbody\n')
run_hook a2 $'subject\n\nco-authored-by: claude <x@y.z>\nCO-AUTHORED-BY: Someone <noreply@anthropic.com>\n'
check "a: lower/upper case spellings removed" same "$root/a2" <(printf 'subject\n')
run_hook a3 $'subject\n\nCo-Authored-By: Bot <noreply@anthropic.com>\n'
check "a: anthropic address alone matches" same "$root/a3" <(printf 'subject\n')

# (b) a real person stays.
msg=$'subject\n\nCo-Authored-By: Jane Doe <jane@example.com>\n'
run_hook b1 "$msg"
check "b: real co-author kept" same "$root/b1" <(printf '%s' "$msg")
run_hook b2 $'subject\n\nCo-Authored-By: Jane Doe <jane@example.com>\nCo-Authored-By: Claude <noreply@anthropic.com>\n'
check "b: only the Claude line goes" same "$root/b2" <(printf 'subject\n\nCo-Authored-By: Jane Doe <jane@example.com>\n')

# (c) messages without a trailer are byte-identical (incl. odd whitespace, no final newline).
msg=$'subject\n\n\nbody  with  spaces\n\n\n# comment\nmentions Claude in prose'
run_hook c1 "$msg"
check "c: untouched message is byte-identical" same "$root/c1" <(printf '%s' "$msg")

# (d) a real commit leaves no trailer in the history.
repo="$root/repo"
mkdir -p "$repo" && cd "$repo" && git init -q && git config user.email t@t && git config user.name t
bash "$here/install.sh" . >/dev/null 2>&1
echo x >f && git add f
printf 'real commit\n\nbody\n\nCo-Authored-By: Claude Sonnet <noreply@anthropic.com>\n' >"$root/m"
git commit -q -F "$root/m" 2>/dev/null
check "d: commit succeeded" test "$(git rev-list --count HEAD 2>/dev/null)" = 1
check "d: no trailer in history" test -z "$(git log --format=%B | grep -i 'co-authored-by')"
check "d: body kept" test "$(git log -1 --format=%B | head -n1)" = "real commit"

# (e) a trailer-only message is refused.
printf 'Co-Authored-By: Claude <noreply@anthropic.com>\n' >"$root/e"
bash "$hook" "$root/e" 2>/dev/null
check "e: trailer-only message exits 1" test $? -eq 1
echo y >g && git add g
git commit -q -F "$root/e" 2>/dev/null
check "e: git commit with trailer-only message fails" test "$(git rev-list --count HEAD)" -eq 1

# install.sh: foreign commit-msg hook is not overwritten; --commit-msg-only skips pre-commit.
other="$root/other"
mkdir -p "$other" && git -C "$other" init -q
printf '#!/bin/sh\necho foreign\n' >"$other/.git/hooks/commit-msg"
bash "$here/install.sh" "$other" >/dev/null 2>&1
check "install: foreign commit-msg kept" grep -q foreign "$other/.git/hooks/commit-msg"
only="$root/only"
mkdir -p "$only" && git -C "$only" init -q
bash "$here/install.sh" --commit-msg-only "$only" >/dev/null 2>&1
check "install: --commit-msg-only writes commit-msg" test -f "$only/.git/hooks/commit-msg"
check "install: --commit-msg-only skips pre-commit" test ! -e "$only/.git/hooks/pre-commit"

echo
[ "$fails" -eq 0 ] && echo "all passed" || echo "$fails failed"
exit $((fails > 0))
