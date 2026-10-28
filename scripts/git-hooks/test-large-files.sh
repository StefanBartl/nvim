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
# Nobody to ask unless a case says so: no real terminal, no real Neovim (a run from a
# Neovim terminal would otherwise put dialogs into it).
export LARGE_FILE_TTY=/nonexistent
unset NVIM NVIM_ASK LARGE_FILE_NVIM_ASK LARGE_FILE_ACTION LARGE_FILE_DELETE LARGE_FILE_OK
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

# git config largefiles.action decides without anybody to ask.
new_repo cfg_compress
big_text g.log
git add -A
git config largefiles.action compress
git config largefiles.deleteOriginals true
git commit -qm t </dev/null 2>/dev/null
check "config compress: the zip is committed" in_head g.log.zip
check "config deleteOriginals: the original is gone" test ! -e g.log

new_repo cfg_commit
big_text h.log
git add -A
git config largefiles.action commit
git commit -qm t </dev/null 2>/dev/null
check "config commit: the large file is committed" in_head h.log

new_repo cfg_abort
big_text i.log
git add -A
git config largefiles.action abort
LARGE_FILE_NVIM_ASK=/nonexistent NVIM=x git commit -qm t </dev/null 2>/dev/null
check "config abort: nothing committed, nobody asked" no_commit

new_repo cfg_env_wins
big_text j.log
git add -A
git config largefiles.action abort
LARGE_FILE_ACTION=compress git commit -qm t </dev/null 2>/dev/null
check "LARGE_FILE_ACTION wins over git config" in_head j.log.zip

# Neovim is asked (no terminal, $NVIM set): a stub nvim-ask answers and logs its arguments.
stub="$root/nvim-ask-stub"
cat >"$stub" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"$STUB_LOG"
case "$*" in
  *"Delete the originals"*) [ -n "$STUB_DELETE" ] && echo "$STUB_DELETE" ;;
  *) [ -n "$STUB_MAIN" ] && echo "$STUB_MAIN" ;;
esac
exit "${STUB_EXIT:-0}"
STUB
export STUB_LOG="$root/stub.log"

new_repo nvim_compress
big_text k.log
git add -A
NVIM=fake LARGE_FILE_NVIM_ASK="$stub" STUB_MAIN="Compress to .zip" STUB_DELETE="Delete originals" \
  git commit -qm t </dev/null 2>/dev/null
check "nvim: Compress commits the zip" in_head k.log.zip
check "nvim: Delete originals deletes them" test ! -e k.log
check "nvim: the question names the file" grep -q "k.log" "$STUB_LOG"
check "nvim: the dialog gets a title" grep -qx -- "--title" "$STUB_LOG"

new_repo nvim_commit
big_text l.log
git add -A
NVIM=fake LARGE_FILE_NVIM_ASK="$stub" STUB_MAIN="Commit anyway" git commit -qm t </dev/null 2>/dev/null
check "nvim: Commit anyway commits the large file" in_head l.log

new_repo nvim_abort
big_text m.log
git add -A
NVIM=fake LARGE_FILE_NVIM_ASK="$stub" STUB_MAIN="Abort" git commit -qm t </dev/null 2>/dev/null
check "nvim: Abort commits nothing" no_commit
NVIM=fake LARGE_FILE_NVIM_ASK="$stub" STUB_EXIT=3 git commit -qm t </dev/null 2>/dev/null
check "nvim: no answer (nvim-ask fails) commits nothing" no_commit

# $NVIM_ASK (what terminal.nvim's native terminals actually set) must be used directly,
# not just the LARGE_FILE_NVIM_ASK test override above.
new_repo nvim_ask_env
big_text n.log
git add -A
NVIM=fake NVIM_ASK="$stub" STUB_MAIN="Compress to .zip" STUB_DELETE="Delete originals" \
  git commit -qm t </dev/null 2>/dev/null
check "\$NVIM_ASK alone (terminal.nvim's own bridge) is used" in_head n.log.zip

echo
[ "$fails" -eq 0 ] && echo "all passed" || echo "$fails failed"
exit $((fails > 0))
