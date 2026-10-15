#!/usr/bin/env bash
# Run every personal plugin's test suite and print one table (pass/fail/error/skip/... per repo).
#
# The loop itself is scripts/run_all_tests.lua: for each repo it calls `scripts/test.sh --json <ir>`
# and reads the IR back (testing.nvim). Until 2026-10-15 this file searched for a runner by file
# name and read the verdict from sentinels with grep; that was wrong for every migrated repo.
#
#   scripts/run_all_tests.sh                       all repos
#   scripts/run_all_tests.sh --only=media.nvim,lsp.nvim
#   scripts/run_all_tests.sh --timeout=1200        seconds per repo (default 900)
#
# Exit code: 0 all green, 1 at least one repo red, 3 infrastructure error (a repo without a runner or
# without testing.nvim, a missing IR, a timeout): the verdict cannot be trusted and is never "green".
# It assumes THIS machine's checkout layout, so it stays here and does not ship with a plugin.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v nvim >/dev/null 2>&1 || {
  echo "run_all_tests: nvim is not on PATH" >&2
  exit 3
}

# Not from inside a :terminal with the editor's socket: the child must not reach back into the session.
exec env -u NVIM -u NVIM_LISTEN_ADDRESS nvim -n --clean --headless -u NONE -l "$here/run_all_tests.lua" "$@"
