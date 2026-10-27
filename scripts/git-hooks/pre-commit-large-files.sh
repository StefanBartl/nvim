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
# Bash arithmetic reads "5MB" or "" as 0, and every file would be "large".
case "$limit_mb" in
  '' | *[!0-9]*)
    echo "pre-commit: LARGE_FILE_MB='$limit_mb' is not a whole number, using 5" >&2
    limit_mb=5
    ;;
esac
limit=$((limit_mb * 1024 * 1024))

# Every staged blob that is new in content: added, copied, modified, renamed or
# changed in type (a large file moved to a new path is a rename, not an add).
# --raw gives the staged blob's id; one `git cat-file --batch-check` sizes them
# all, instead of one process per file.
paths=()
ids=()
while IFS= read -r -d '' meta && IFS= read -r -d '' path; do
  case "$meta" in *' R'* | *' C'*) IFS= read -r -d '' path ;; esac # R/C: old path, then new
  set -- $meta
  [ "$1" = ":160000" ] || [ "$2" = "160000" ] && continue # a submodule commit, no blob
  paths+=("$path")
  ids+=("$4")
done < <(git diff --cached --raw -z --diff-filter=ACMRT)

big=()
if [ ${#ids[@]} -gt 0 ]; then
  i=0
  while read -r size; do
    if [ "$size" -eq "$size" ] 2>/dev/null && [ "$size" -gt "$limit" ]; then
      big+=("$(awk -v s="$size" 'BEGIN { printf "%7.1f MB", s / 1048576 }')  ${paths[$i]}")
    fi
    i=$((i + 1))
  done < <(printf '%s\n' "${ids[@]}" | git cat-file --batch-check='%(objectsize)')
fi

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
