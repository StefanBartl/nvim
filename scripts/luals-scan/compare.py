"""Summarise one scan pass, or compare two.

    python compare.py after                 # totals per workspace and per rule
    python compare.py before after          # deltas, and what got worse

Reads the JSON that `lua-language-server --check --check_out_path` writes:
a map of file URI -> list of findings, each carrying a `code` (the rule name).

A note on trust: repeated runs over an unchanged workspace differ by a few
counts, `param-type-mismatch` being the restless one. Deltas below NOISE in a
single workspace are marked rather than reported as fact.
"""

import argparse
import collections
import json
import os
import sys

NOISE = 10


def pass_dir(name):
    work = os.environ.get("LUALS_SCAN_DIR") or os.path.join(
        os.environ.get("LOCALAPPDATA") or os.path.expanduser("~"),
        "nvim-data",
        "luals-scan",
    )
    direct = os.path.join(work.replace("\\", "/"), "out", name)
    return direct if os.path.isdir(direct) else name


def read(directory):
    """-> ({workspace: total}, {workspace: Counter(rule)})"""
    totals, rules = {}, {}
    if not os.path.isdir(directory):
        sys.exit("no such pass: %s" % directory)
    for entry in sorted(os.listdir(directory)):
        if not entry.endswith(".json"):
            continue
        with open(os.path.join(directory, entry), encoding="utf-8") as fh:
            data = json.load(fh)
        counter = collections.Counter()
        # LuaLS writes {} for a clean workspace and a list in some versions.
        if isinstance(data, dict):
            for findings in data.values():
                for finding in findings:
                    counter[finding.get("code")] += 1
        name = entry[:-5]
        totals[name] = sum(counter.values())
        rules[name] = counter
    return totals, rules


def summarise(name):
    totals, rules = read(pass_dir(name))
    for workspace in sorted(totals, key=lambda k: -totals[k]):
        if totals[workspace]:
            print("%-26s%6d" % (workspace, totals[workspace]))
    print("%-26s%6d" % ("TOTAL", sum(totals.values())))
    print()
    overall = collections.Counter()
    for counter in rules.values():
        overall.update(counter)
    for rule, count in overall.most_common():
        print("  %-28s%6d" % (rule, count))


def compare(before_name, after_name):
    before, before_rules = read(pass_dir(before_name))
    after, after_rules = read(pass_dir(after_name))

    print("%-26s%9s%9s%9s" % ("workspace", "before", "after", "delta"))
    worse, noisy = [], []
    for workspace in sorted(set(before) | set(after)):
        was, now = before.get(workspace, 0), after.get(workspace, 0)
        if was == now:
            continue
        delta = now - was
        mark = ""
        if abs(delta) < NOISE:
            # Small moves happen between two runs over an unchanged workspace,
            # in both directions. Flagging only regressions would let a
            # meaningless improvement be read as a result.
            noisy.append(workspace)
            mark = "  <-- within noise"
        elif delta > 0:
            worse.append(workspace)
            mark = "  <-- worse"
        print("%-26s%9d%9d%+9d%s" % (workspace, was, now, delta, mark))
    print(
        "%-26s%9d%9d%+9d"
        % ("TOTAL", sum(before.values()), sum(after.values()), sum(after.values()) - sum(before.values()))
    )

    overall_before, overall_after = collections.Counter(), collections.Counter()
    for counter in before_rules.values():
        overall_before.update(counter)
    for counter in after_rules.values():
        overall_after.update(counter)

    changed = [r for r in set(overall_before) | set(overall_after) if overall_before.get(r, 0) != overall_after.get(r, 0)]
    if changed:
        print("\nper rule:")
        for rule in sorted(changed, key=lambda r: -abs(overall_after.get(r, 0) - overall_before.get(r, 0))):
            was, now = overall_before.get(rule, 0), overall_after.get(rule, 0)
            print("  %-28s%9d%9d%+9d" % (rule, was, now, now - was))

    print("\nworse: %s" % (", ".join(worse) if worse else "nothing"))
    if noisy:
        print(
            "within noise (|delta| < %d -- run-to-run variance, in either "
            "direction; no result without a second run): %s" % (NOISE, ", ".join(noisy))
        )


ap = argparse.ArgumentParser()
ap.add_argument("passes", nargs="+", metavar="PASS", help="one pass to summarise, two to compare")
args = ap.parse_args()

if len(args.passes) == 1:
    summarise(args.passes[0])
elif len(args.passes) == 2:
    compare(args.passes[0], args.passes[1])
else:
    sys.exit("give one pass to summarise, or two to compare")
