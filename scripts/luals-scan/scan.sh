#!/usr/bin/env bash
# Run lua-language-server over the Lua workspaces on this machine and file the
# results under a named pass, so two passes can be compared.
#
#   scan.sh before                 # every workspace
#   scan.sh before lsp.nvim        # just one -- the usual case
#   scan.sh after lsp.nvim dap.nvim
#
# Env:
#   REPOS_DIR            where the *.nvim repos live (required)
#   LUALS_SCAN_DIR       working dir  (default: $LOCALAPPDATA/nvim-data/luals-scan)
#   LUALS_SCAN_REFRESH=1 re-dump the injected library even if it is cached
#   LUALS_SCAN_JOBS      parallel lua-language-server instances (default 3)
set -u

# `pwd` in Git Bash answers /c/Users/... , which the Windows nvim and
# lua-language-server do not understand -- and a bad path makes headless nvim
# wait forever instead of failing. `pwd -W` gives C:/Users/... ; elsewhere it
# does not exist and plain pwd is already right.
abspath() { (cd "$1" && { pwd -W 2>/dev/null || pwd; }); }

here="$(abspath "$(dirname "${BASH_SOURCE[0]}")")"
nvim_config="$(abspath "$here/../..")"

if [ $# -lt 1 ]; then
  echo "usage: scan.sh <pass-name> [repo ...]" >&2
  exit 2
fi
pass="$1"
shift

repos_dir="${REPOS_DIR:-}"
if [ -z "$repos_dir" ]; then
  echo "REPOS_DIR is not set" >&2
  exit 2
fi
repos_dir="${repos_dir//\\//}"

work="${LUALS_SCAN_DIR:-${LOCALAPPDATA:-$HOME}/nvim-data/luals-scan}"
work="${work//\\//}"
jobs="${LUALS_SCAN_JOBS:-3}"
libdir="$work/library"
cfgdir="$work/cfg/$pass"
outdir="$work/out/$pass"
index="$work/index-$pass.tsv"
mkdir -p "$libdir" "$cfgdir" "$outdir"

# ---------------------------------------------------------------- the index --
# name<TAB>root for every workspace to scan. A workspace is a directory with a
# .luarc.json; the nvim config is one too and is filed under its own name.
: > "$index"
add() { printf '%s\t%s\n' "$1" "$2" >> "$index"; }

if [ $# -gt 0 ]; then
  for name in "$@"; do
    if [ "$name" = "nvim-config" ]; then
      add nvim-config "$nvim_config"
    elif [ -d "$repos_dir/$name" ]; then
      add "$name" "$repos_dir/$name"
    else
      echo "unknown workspace: $name" >&2
      exit 2
    fi
  done
else
  for luarc in "$repos_dir"/*/.luarc.json; do
    [ -e "$luarc" ] || continue
    root="$(dirname "$luarc")"
    add "$(basename "$root")" "$root"
  done
  add nvim-config "$nvim_config"
fi
echo "$(wc -l < "$index") workspace(s)"

# ------------------------------------------------- the injected library dump --
# What lsp.nvim hands lua_ls, straight from build_library() in a running nvim
# rather than modelled here. One root takes roughly half a minute, so it is
# cached per workspace.
missing=""
while IFS=$'\t' read -r name root; do
  name="${name%$'\r'}"; root="${root%$'\r'}"
  [ -z "$name" ] && continue
  if [ ! -f "$libdir/$name.json" ] || [ -n "${LUALS_SCAN_REFRESH:-}" ]; then
    missing="${missing}${root};"
  fi
done < "$index"

if [ -n "$missing" ]; then
  echo "dumping the injected library..."
  # Not piped through a filter: a Lua error here would otherwise be swallowed
  # and the run would look like it was merely slow.
  # The trailing -c is insurance: if the luafile fails, nvim would otherwise
  # sit in headless mode with nothing to do and never return.
  LUALS_SCAN_ROOTS="$missing" LUALS_SCAN_OUT="$libdir" \
    nvim --headless -c "luafile $here/dump_library.lua" -c "qa!" </dev/null 2>&1 |
    tr -d '\r' | grep -vE "^Config loaded in"

  while IFS=$'\t' read -r name root; do
    name="${name%$'\r'}"
    [ -z "$name" ] && continue
    if [ ! -f "$libdir/$name.json" ]; then
      echo "the library dump produced nothing for $name -- aborting" >&2
      exit 1
    fi
  done < "$index"
fi

# ------------------------------------------------------------------ configs --
python "$here/mkcfg.py" --index "$index" --library "$libdir" --out "$cfgdir" || exit 1

# ------------------------------------------------------------------- checks --
# Three things bite here, all of them silent:
#   - a CR from a CRLF index line sticks to the path and the run fails
#   - parallel instances clobber each other's meta cache without --metapath
#   - the child inherits stdin and eats the rest of the index file
slot=0
while IFS=$'\t' read -r name root; do
  name="${name%$'\r'}"; root="${root%$'\r'}"
  [ -z "$name" ] && continue
  rm -f "$outdir/$name.json"
  slot=$(( (slot % jobs) + 1 ))
  (
    lua-language-server --check "$root" --checklevel=Warning \
      --configpath="$cfgdir/$name.json" \
      --logpath="$work/log/$pass/$name" \
      --metapath="$work/meta/slot$slot" \
      --check_out_path="$outdir/$name.json" </dev/null >/dev/null 2>&1
    # LuaLS writes nothing when a workspace is clean; an empty object keeps the
    # comparison honest instead of looking like a failed run.
    [ -f "$outdir/$name.json" ] || echo '{}' > "$outdir/$name.json"
    echo "  checked $name"
  ) &
  [ "$slot" -eq "$jobs" ] && wait
done < "$index"
wait

echo "pass '$pass' -> $outdir"
