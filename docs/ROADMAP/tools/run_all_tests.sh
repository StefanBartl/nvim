#!/usr/bin/env bash
# Run every plugin's test suite, finding the runner instead of assuming one.
#
# The point is the "no runner found" case: during the keymap migration I called
# TESTS/run.lua in a repo whose runner is TESTS/pickers_spec.lua, got "cannot
# open", and read the missing output as success. A stale spec stayed red for
# hours. So: locate the runner, and say so loudly when there isn't one.
LIB=E:/repos/lib.nvim

run_one() {
  local repo="$1"
  cd "E:/repos/$repo" || return

  local runner="" cand
  for cand in TESTS/run.lua tests/run.lua TESTS/smoke.lua TESTS/smoke_spec.lua; do
    if [ -f "$cand" ]; then runner="$cand"; break; fi
  done

  # A single *.lua under TESTS/ that is itself the runner (pickers, ...).
  if [ -z "$runner" ]; then
    local n
    n=$(ls TESTS/*.lua 2>/dev/null | wc -l)
    if [ "$n" = "1" ]; then runner=$(ls TESTS/*.lua); fi
  fi

  if [ -z "$runner" ]; then
    printf '%-24s %-24s %s\n' "$repo" "-" "KEIN RUNNER GEFUNDEN"
    return
  fi

  local out verdict
  out=$(LIB_NVIM_PATH=$LIB LIB_NVIM_DIR=$LIB timeout 120 nvim --clean --headless -u NONE \
        -c "set rtp+=." -c "set rtp+=$LIB" -l "$runner" 2>&1 | tail -25)

  verdict=$(echo "$out" | grep -oiE '[0-9]+ (passed|failed)[a-z ]*' | tail -2 | tr '\n' ' ')
  if [ -z "$verdict" ]; then
    verdict=$(echo "$out" | grep -oE '[A-Z_]+_TESTS_OK|[0-9]+ spec\(s\) failed' | tail -1)
  fi
  if [ -z "$verdict" ]; then
    verdict="?? $(echo "$out" | tail -1 | cut -c1-44)"
  fi

  printf '%-24s %-24s %s\n' "$repo" "$runner" "$verdict"
}

cd E:/repos || exit 1
for repo in *.nvim; do
  [ -d "$repo/lua" ] || continue
  ( run_one "$repo" )
done
