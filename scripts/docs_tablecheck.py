#!/usr/bin/env python3
"""Find markdown tables that stopped being tables.

    python scripts/docs_tablecheck.py <repo-root> [...]

A markdown table is a header row, a separator row (`| --- | --- |`), and then
its body. Put a paragraph in the middle of one and the rows below it are no
longer part of any table: GitHub renders them as a single run-on line of text
with pipes in it. The file still reads fine in an editor, every link in it
still resolves, and every checker stays green -- which is exactly why this
went unnoticed in two repositories until someone read them end to end.

Reported as FRAGMENT: a run of `|`-rows whose second line is not a separator,
i.e. rows with no header above them.

Also reported as OVERFLOW: a body row with MORE cells than its header declares,
which is almost always an unescaped `|` inside a cell. GitHub splits the row on
it before parsing inline code -- backticks do not protect it -- and drops every
cell past the header's count. The text is in the file and not on the page.

A row with FEWER cells is counted separately as SHORT and does not fail the
run: markdown pads the missing cells and nothing is lost. Reporting both at the
same weight would bury the class that costs content under the one that does not.

Both are structural, so neither `docs_linkcheck.py` nor `docs_anchorcheck.py`
can see them: nothing is missing, the shape is wrong.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys

FENCE_RE = re.compile(r"^\s*(```|~~~)")
ROW_RE = re.compile(r"^\s*\|.*\|\s*$")
SEP_RE = re.compile(r"^\s*\|[\s\-:|]+\|\s*$")


def git(root: str, *args: str) -> list[str] | None:
    """Run git in `root`, split NUL-separated output, None when it fails."""
    try:
        out = subprocess.run(
            ["git", "-C", root, *args], capture_output=True, text=True, timeout=30
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    return [p for p in out.stdout.split("\0") if p]


def markdown_files(root: str) -> list[str]:
    """Tracked and not-yet-staged markdown, the same source set the link checker uses."""
    paths = git(root, "ls-files", "-z", "--cached", "--others",
                "--exclude-standard", "*.md", "*.MD", "*.markdown")
    if paths is None:
        return [
            os.path.join(dirpath, fn)
            for dirpath, _, filenames in os.walk(root)
            for fn in filenames
            if fn.lower().endswith(".md")
        ]
    return [os.path.join(root, p) for p in dict.fromkeys(paths)]


def cells(line: str) -> int:
    """How many columns this row declares. Escaped pipes are not separators."""
    body = line.strip()
    body = body[1:] if body.startswith("|") else body
    if body.endswith("|") and not body.endswith("\\|"):
        body = body[:-1]
    n, i = 1, 0
    while i < len(body):
        if body[i] == "\\":
            i += 2
            continue
        if body[i] == "|":
            n += 1
        i += 1
    return n


def blocks(lines: list[str]):
    """Yield (start_index, [rows]) for every run of consecutive table rows.

    Fenced code is skipped whole: a `|` inside a shell example or an ASCII
    diagram is not a table row, and treating it as one was the first version's
    entire false-positive budget.
    """
    i, in_fence = 0, False
    while i < len(lines):
        if FENCE_RE.match(lines[i]):
            in_fence = not in_fence
            i += 1
            continue
        if in_fence or not ROW_RE.match(lines[i]):
            i += 1
            continue
        start = i
        run = []
        while i < len(lines) and ROW_RE.match(lines[i]) and not FENCE_RE.match(lines[i]):
            run.append(lines[i])
            i += 1
        yield start, run


def check(root: str) -> tuple[int, int, int, int]:
    fragments = overflow = short = files = 0
    for path in sorted(markdown_files(root)):
        try:
            text = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        files += 1
        rel = os.path.relpath(path, root)
        lines = text.replace("\r", "").split("\n")

        for start, run in blocks(lines):
            has_header = len(run) >= 2 and SEP_RE.match(run[1]) is not None
            if not has_header:
                # A lone row is usually a one-line pipe construct in prose, not
                # a broken table. Two or more rows with no separator is the
                # real thing: a table body cut off from its head.
                if len(run) >= 2:
                    print(f"FRAGMENT  {rel}:{start + 1}  "
                          f"{len(run)} rows with no header separator")
                    fragments += 1
                continue
            want = cells(run[0])
            for offset, row in enumerate(run[2:], start=2):
                got = cells(row)
                if got > want:
                    print(f"OVERFLOW  {rel}:{start + offset + 1}  "
                          f"{got} cells, header declares {want} "
                          f"-- {got - want} dropped when rendered")
                    overflow += 1
                elif got < want:
                    print(f"SHORT     {rel}:{start + offset + 1}  "
                          f"{got} cells, header declares {want} (padded, nothing lost)")
                    short += 1
    return fragments, overflow, short, files


def main() -> int:
    roots = sys.argv[1:]
    if not roots:
        print(__doc__)
        return 2
    total_f = total_o = total_s = 0
    for root in roots:
        if len(roots) > 1:
            print(f"##### {os.path.basename(os.path.normpath(root))}")
        f, o, s, n = check(root)
        total_f += f
        total_o += o
        total_s += s
        print(f"--- {n} files, {f} fragments, {o} overflow, {s} short ---")
    if len(roots) > 1:
        print(f"===== TOTAL: {total_f} fragments, {total_o} overflow, "
              f"{total_s} short =====")
    # `short` is reported but does not fail: nothing is lost when markdown pads
    # a row, and a checker that fails on cosmetics stops being run.
    return 1 if (total_f or total_o) else 0


if __name__ == "__main__":
    sys.exit(main())
