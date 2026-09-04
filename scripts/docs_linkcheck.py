#!/usr/bin/env python3
"""Relative-link checker for a repo's markdown files.

    python scripts/docs_linkcheck.py <repo-root> [...]

Reports every ](target) link whose file does not exist, and — the reason this
exists at all — every link whose spelling differs from the file's real name.

On Windows the filesystem is case-insensitive: a link [x](COMMANDS.md) at a
file actually named commands.md resolves locally and 404s on GitHub. Python's
os.path.exists inherits that blindness, so this compares against the real
directory entries instead. Run it after every rename.

A target can be present and still 404: `docs/map/` is generated and gitignored
in every one of these repos, so a link to it resolves on the author's disk and
nowhere else. That is IGNORED — the same failure as CASE, from the other side.

Sources are the files git tracks plus the ones it does not ignore yet, so a
docs/README.md written a minute ago is checked rather than silently passed.

Links quoted as examples — inside a fenced code block or inline backticks —
are not links, and are skipped.

A link can name a file that exists and a heading in it that does not. That is
ANCHOR, and it is the failure a table of contents produces on its own: nothing
consumes it, so a renamed heading leaves it behind. Anchors are matched the way
GitHub builds them, including the -1/-2 suffix on repeated headings.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys

SKIP_DIRS = {".git", "node_modules", "dist", "build", "__pycache__"}
SKIP_PATHS = (os.path.join("docs", "map"),)

LINK_RE = re.compile(r"\]\(([^)]+)\)")
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")
INLINE_CODE_RE = re.compile(r"`[^`]*`")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)")


def uncoded(text: str):
    """Yield (lineno, line) for the lines that are not inside a code fence.

    The fence state is length-aware rather than a toggle, and that is not
    pedantry: a ````lua block whose body contains ``` flips a toggle back open
    halfway through, and every heading after it vanishes from the file. A line
    whose info string carries a backtick is not an opener at all (CommonMark
    forbids it) -- prose that names a fence inline reads as one otherwise, and
    inverted the rest of a real document here on 2026-09-04.
    """
    fence = 0
    for n, line in enumerate(text.splitlines(), 1):
        m = FENCE_RE.match(line)
        if m:
            width, rest = len(m.group(1)), line[m.end():]
            if fence:
                if width >= fence and not rest.strip():
                    fence = 0
                continue
            if "`" not in rest:
                fence = width
                continue
        if not fence:
            yield n, line


def strip_code(text: str) -> str:
    """Blank out fenced blocks and inline code so quoted links are not links."""
    out = [""] * len(text.splitlines())
    for n, line in uncoded(text):
        out[n - 1] = INLINE_CODE_RE.sub("", line)
    return "\n".join(out)


def slugs(text: str) -> set[str]:
    """The anchors GitHub generates for this document's headings.

    Lowercase, punctuation dropped, spaces to hyphens -- and a heading that
    repeats gets -1, -2, which is why the occurrences are counted rather than
    collected in a set.
    """
    out, seen = set(), {}
    for _, line in uncoded(text):
        m = HEADING_RE.match(line)
        if not m:
            continue
        title = re.sub(r"[`*]", "", m.group(2).strip().rstrip("#").strip())
        slug = re.sub(r"[^\w\s-]", "", title).strip().lower().replace(" ", "-")
        n = seen.get(slug, 0)
        seen[slug] = n + 1
        out.add(slug if n == 0 else f"{slug}-{n}")
    return out


def git(root: str, *args: str, stdin: str | None = None) -> list[str] | None:
    """Run git in `root`, return its NUL-separated output, or None on failure.

    `check-ignore` exits 1 when nothing matched, which is an answer, not an
    error — both 0 and 1 count as success.
    """
    try:
        out = subprocess.run(
            ["git", "-C", root, *args],
            input=stdin, capture_output=True, text=True, timeout=30,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode not in (0, 1):
        return None
    if out.returncode == 1 and args[0] != "check-ignore":
        return None
    return [p for p in out.stdout.split("\0") if p]


def tracked_markdown(root: str) -> list[str] | None:
    """Markdown files that are in the repo or on their way in, or None.

    Preferred over walking the tree: it skips gitignored trees (.deps/,
    node_modules/, build output) without needing a list of their names, and
    documentation that is not in the repo is documentation nobody reads.

    `--others --exclude-standard` adds files that exist but are not staged
    yet. Without them a freshly written docs/README.md is invisible and the
    run reports a green that means nothing.
    """
    paths = git(root, "ls-files", "-z", "--cached", "--others",
                "--exclude-standard", "*.md", "*.MD", "*.markdown")
    if paths is None:
        return None
    return [os.path.join(root, p) for p in dict.fromkeys(paths)]


def ignored(root: str, targets: list[str]) -> set[str]:
    """Which of `targets` — paths relative to `root` — git ignores."""
    if not targets:
        return set()
    got = git(root, "check-ignore", "--stdin", "-z", stdin="\0".join(targets))
    return set(got or ())


def markdown_files(root: str):
    tracked = tracked_markdown(root)
    if tracked is not None:
        for path in tracked:
            rel = os.path.relpath(os.path.dirname(path), root)
            if any(rel == p or rel.startswith(p + os.sep) for p in SKIP_PATHS):
                continue
            yield path
        return

    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        rel = os.path.relpath(dirpath, root)
        if any(rel == p or rel.startswith(p + os.sep) for p in SKIP_PATHS):
            continue
        for fn in filenames:
            if fn.lower().endswith(".md"):
                yield os.path.join(dirpath, fn)


def real_name_mismatch(path: str) -> str | None:
    """Return the real on-disk name if `path`'s last segment differs in case."""
    parent, name = os.path.split(path)
    try:
        entries = os.listdir(parent or ".")
    except OSError:
        return None
    if name in entries:
        return None
    for e in entries:
        if e.lower() == name.lower():
            return e
    return None


def anchors_of(path: str, cache: dict) -> set[str]:
    """The heading anchors of `path`, read once per run."""
    if path not in cache:
        try:
            cache[path] = slugs(open(path, encoding="utf-8", errors="replace").read())
        except OSError:
            cache[path] = set()
    return cache[path]


def check(root: str) -> tuple[int, int, int, int, int]:
    dead = case = anchor = files = 0
    live: list[tuple[str, str, str]] = []  # (source, target as written, rel path)
    heads: dict[str, set[str]] = {}

    for md in sorted(markdown_files(root)):
        files += 1
        try:
            text = open(md, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        base = os.path.dirname(md)
        rel_md = os.path.relpath(md, root)
        seen = set()
        for target in LINK_RE.findall(strip_code(text)):
            target = target.strip()
            if not target or target in seen:
                continue
            seen.add(target)
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            path, _, frag = target.partition("#")
            path = path.split('"', 1)[0].strip()
            frag = frag.split('"', 1)[0].strip()
            # A bare "#heading" points into the document it is written in --
            # which is where a table of contents lives, and where a renamed
            # heading is least likely to be noticed.
            resolved = md if not path else os.path.normpath(os.path.join(base, path))
            if path:
                if not os.path.exists(resolved):
                    print(f"DEAD  {rel_md}  ->  {target}")
                    dead += 1
                    continue
                real = real_name_mismatch(resolved)
                if real:
                    print(f"CASE  {rel_md}  ->  {target}   (on disk: {real})")
                    case += 1
                    continue
            if frag and resolved.lower().endswith((".md", ".markdown")):
                if frag.lower() not in anchors_of(resolved, heads):
                    print(f"ANCHOR  {rel_md}  ->  {target}   (no such heading)")
                    anchor += 1
            if not path:
                continue
            rel_target = os.path.relpath(resolved, root)
            if not rel_target.startswith(".."):
                live.append((rel_md, target, rel_target.replace(os.sep, "/")))

    hidden = ignored(root, sorted({t for _, _, t in live}))
    gone = 0
    for rel_md, target, rel_target in live:
        if rel_target in hidden:
            print(f"IGNORED  {rel_md}  ->  {target}   (gitignored: 404 on the remote)")
            gone += 1
    return dead, case, gone, anchor, files


def main() -> int:
    roots = sys.argv[1:]
    if not roots:
        print(__doc__)
        return 2
    grand_dead = grand_case = grand_gone = grand_anchor = 0
    for root in roots:
        if len(roots) > 1:
            print(f"##### {os.path.basename(os.path.normpath(root))}")
        d, c, g, a, f = check(root)
        grand_dead += d
        grand_case += c
        grand_gone += g
        grand_anchor += a
        print(f"--- {f} files, {d} dead, {c} case-mismatch, {g} gitignored, "
              f"{a} dead anchors ---")
    if len(roots) > 1:
        print(f"===== TOTAL: {grand_dead} dead, {grand_case} case-mismatch, "
              f"{grand_gone} gitignored, {grand_anchor} dead anchors =====")
    return 1 if (grand_dead or grand_case or grand_gone or grand_anchor) else 0


if __name__ == "__main__":
    sys.exit(main())
