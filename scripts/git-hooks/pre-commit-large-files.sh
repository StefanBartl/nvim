#!/usr/bin/env bash
# pre-commit-large-files.sh -- warn about staged files above a size limit and let the
# committer decide, instead of rejecting them.
#
#   Limit:        LARGE_FILE_MB (default 5)
#   Skip prompt:  LARGE_FILE_OK=1 git commit ...   (or git commit --no-verify)
#
# Interactive (a terminal is attached): lists the files and asks y/N.
# Not interactive (GUI, editor plugin): lists the files and aborts with the hint above,
# since a hook without a terminal cannot ask.
#
# Installed per repo by scripts/git-hooks/install.sh, which writes a one-line
# .git/hooks/pre-commit that calls this file.

limit_mb="${LARGE_FILE_MB:-5}"
limit=$((limit_mb * 1024 * 1024))

big=()
while IFS= read -r -d '' path; do
  size=$(git cat-file -s ":$path" 2>/dev/null) || continue
  if [ "$size" -gt "$limit" ]; then
    big+=("$(awk -v s="$size" 'BEGIN { printf "%7.1f MB", s / 1048576 }')  $path")
  fi
done < <(git diff --cached --name-only -z --diff-filter=AM)

[ ${#big[@]} -eq 0 ] && exit 0

echo "pre-commit: ${#big[@]} staged file(s) larger than ${limit_mb} MB:" >&2
printf '  %s\n' "${big[@]}" >&2

[ "${LARGE_FILE_OK:-}" = "1" ] && exit 0

if [ -r /dev/tty ] && { exec 3</dev/tty; } 2>/dev/null; then
  printf 'Commit anyway? [y/N] ' >&2
  read -r answer <&3
  exec 3<&-
  case "$answer" in
    y | Y | yes | j | J | ja) exit 0 ;;
  esac
  echo "pre-commit: aborted, nothing committed." >&2
  exit 1
fi

echo "pre-commit: no terminal to ask. Commit anyway with LARGE_FILE_OK=1 git commit ..." >&2
exit 1
