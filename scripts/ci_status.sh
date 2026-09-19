#!/usr/bin/env bash
# Per-platform CI verdict for every plugin, in one table.
#
# Sibling of run_all_tests.sh and here for the same reason: it assumes THIS
# machine's checkout layout (every *.nvim repo under $REPOS_DIR) and needs the
# `gh` CLI authenticated as this user, which is exactly what no published
# plugin should ship. So it stays a script, in the folder for scripts.
#
# Written after the 2026-09-18/19 cross-platform rollout, which put a
# ubuntu+windows+macos matrix on all 38 repos. Before that a per-platform view
# did not exist because there was only one platform. Now "is the fleet green"
# is a question with three answers per repo, and clicking through 38 Actions
# tabs is not a workflow.
#
# Two things it does deliberately, both of which cost hours to learn:
#
#   1. It keys on the HEAD SHA of origin/main, not on `--branch main`. A
#      fast-forward push of a commit that already ran on a feature branch does
#      not always produce a second, main-branded run, and `gh run list --branch
#      main` then reports an OLDER run as the newest one -- a green verdict for
#      code that was never built.
#
#   2. It reports a run with ZERO jobs as a rejected workflow file, not as a
#      pass. GitHub creates the run, finds the YAML invalid, and fails it
#      without starting anything; every per-job query then comes back empty,
#      which reads like "no failures" if you only count red jobs.
#
#   3. It filters to the CI workflow specifically (name == "CI", every repo's
#      convention) before picking the newest run for a SHA. Several repos also
#      have a path-filtered workflow (e.g. documentation.nvim's pages.yml on
#      docs/map/**, release-engine.yml on standalone/**) that can trigger on
#      the same push and be CREATED after the CI run -- without this filter,
#      "newest run for this SHA" picks whichever workflow happened to finish
#      last, not the one this script's columns are actually about.
#
# Usage:
#   scripts/ci_status.sh              # every repo
#   scripts/ci_status.sh markdown     # only repos whose name matches
#   scripts/ci_status.sh --red        # only repos that are not fully green
set -u

REPOS_ROOT="${REPOS_DIR:-E:/repos}"
OWNER="StefanBartl"

only_red=0
filter=""
for arg in "$@"; do
  case "$arg" in
    --red) only_red=1 ;;
    -h | --help)
      sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) filter="$arg" ;;
  esac
done

command -v gh >/dev/null 2>&1 || {
  echo "gh CLI not found -- this script reads GitHub Actions results." >&2
  exit 1
}

green=0
total=0
printf '%-24s %-9s %-9s %-9s %s\n' PLUGIN UBUNTU WINDOWS MACOS NOTE

for dir in "$REPOS_ROOT"/*.nvim; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  [ -n "$filter" ] && case "$name" in *"$filter"*) ;; *) continue ;; esac

  sha=$(git -C "$dir" rev-parse origin/main 2>/dev/null)
  if [ -z "$sha" ]; then
    printf '%-24s %s\n' "$name" "no origin/main"
    continue
  fi

  if ! runs=$(gh api "repos/$OWNER/$name/actions/runs?head_sha=$sha&per_page=20" 2>/tmp/ci_status_gh_err); then
    total=$((total + 1))
    printf '%-24s %-9s %-9s %-9s %s\n' "$name" '?' '?' '?' "gh api call failed: $(head -c 80 /tmp/ci_status_gh_err)"
    continue
  fi
  read -r run_id run_status <<EOF
$(printf '%s' "$runs" | python -c "
import sys, json
try:
    rs = json.load(sys.stdin)['workflow_runs']
except Exception:
    print('PARSE_ERROR'); raise SystemExit
# Filter to the CI workflow specifically -- a path-filtered sibling workflow
# (pages.yml, release-engine.yml, ...) can trigger on the same push and be
# created after the CI run, and 'newest run for this SHA' with no filter
# would silently pick that one instead.
rs = [r for r in rs if r.get('name') == 'CI']
if not rs:
    print('NONE'); raise SystemExit
r = sorted(rs, key=lambda x: x['created_at'])[-1]
print(r['id'], r['status'])
" 2>/dev/null)
EOF

  total=$((total + 1))

  if [ "$run_id" = "PARSE_ERROR" ]; then
    printf '%-24s %-9s %-9s %-9s %s\n' "$name" '?' '?' '?' "gh api returned unparseable JSON"
    continue
  fi
  if [ "$run_id" = "NONE" ] || [ -z "${run_id// /}" ]; then
    printf '%-24s %-9s %-9s %-9s %s\n' "$name" - - - "no CI run for this commit"
    continue
  fi
  if [ "$run_status" != "completed" ]; then
    printf '%-24s %-9s %-9s %-9s %s\n' "$name" . . . "$run_status"
    continue
  fi

  line=$(gh api "repos/$OWNER/$name/actions/runs/$run_id/jobs?per_page=100" 2>/dev/null |
    python -c "
import sys, json, re
try:
    js = json.load(sys.stdin)['jobs']
except Exception:
    print('? ? ? api-error'); raise SystemExit
if not js:
    # A run with no jobs at all did not fail its tests -- GitHub rejected the
    # workflow file before starting any. Saying so is the whole point.
    print('! ! ! WORKFLOW REJECTED (0 jobs)'); raise SystemExit
plat, other = {}, []
for j in js:
    c = j.get('conclusion') or j.get('status')
    # buffer-ctx.nvim's matrix (and any future repo shaped like it) runs an
    # extra nightly-Neovim leg on ubuntu ALONGSIDE the stable one -- both job
    # names match 'ubuntu'. Nightly is deliberately non-gating (it catches
    # Neovim API drift, not the platform assumptions this table is about),
    # so it must not share a cell with -- and silently overwrite -- the
    # stable leg's verdict.
    if 'nightly' in j['name'].lower():
        if c not in ('success', 'skipped', None):
            other.append(j['name'])
        continue
    m = re.search(r'(ubuntu|windows|macos)', j['name'])
    if m:
        k = m.group(1)
        if plat.get(k) != 'failure':     # any red leg wins over a green one
            plat[k] = c
    elif c not in ('success', 'skipped', None):
        other.append(j['name'])
cells = []
for k in ('ubuntu', 'windows', 'macos'):
    v = plat.get(k)
    cells.append('ok' if v == 'success' else ('-' if v is None else v))
note = ('also red: ' + ', '.join(other[:2])) if other else ''
print(cells[0], cells[1], cells[2], note)
" 2>/dev/null)

  set -- $line
  u=${1:-?} w=${2:-?} m=${3:-?}
  shift 3 2>/dev/null || true
  note="$*"

  if [ "$u" = "ok" ] && [ "$w" = "ok" ] && [ "$m" = "ok" ] && [ -z "$note" ]; then
    green=$((green + 1))
    [ "$only_red" -eq 1 ] && continue
  fi
  printf '%-24s %-9s %-9s %-9s %s\n' "$name" "$u" "$w" "$m" "$note"
done

echo
echo "fully green: $green / $total"
