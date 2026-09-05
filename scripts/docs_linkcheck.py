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
are not links, and are skipped. Anchors are stripped before the check, so a
wrong #heading is NOT caught; only missing files are.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys

SKIP_DIRS = {".git", "node_modules", "dist", "build", "__pycache__"}
SKIP_PATHS = (os.path.join("docs", "map"),)

LINK_RE = re.compile(r"\]\(([^)]+)\)")
FENCE_RE = re.compile(r"^\s*(```|~~~)")
INLINE_CODE_RE = re.compile(r"`[^`]*`")


def strip_code(text: str) -> str:
    """Blank out fenced blocks and inline code so quoted links are not links."""
    out, in_fence = [], False
    for line in text.splitlines():
        if FENCE_RE.match(line):
            in_fence = not in_fence
            out.append("")
            continue
        out.append("" if in_fence else INLINE_CODE_RE.sub("", line))
    return "\n".join(out)


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


def real_name_mismatch(root: str, path: str) -> str | None:
    """Return the real on-disk spelling if any segment of `path` differs in case.

    Every segment, not just the last one: a link to `features/COLORSCHEMES.md`
    under a directory actually named `FEATURES/` has a perfectly-cased file name
    and a mis-cased parent, and checking only `os.path.split(path)[1]` calls that
    green. It 404s on GitHub like any other case error -- found in
    color_my_ascii.nvim and sandbox.nvim, both after their full pass.

    Returns the corrected relative path, so the report names what to write.
    """
    try:
        rel = os.path.relpath(path, root)
    except ValueError:
        return None  # different drive on Windows -- an absolute personal-machine
        # path (some IDEAS/ notes link straight to `$REPOS_DIR\...`), not a repo-relative
        # link a case mismatch could even apply to
    if rel.startswith(".."):
        return None  # outside the repo; the caller only reports existence there

    here, fixed, wrong = root, [], False
    for segment in rel.replace("\\", "/").split("/"):
        if segment in (".", ""):
            continue
        try:
            entries = os.listdir(here or ".")
        except OSError:
            return None
        if segment in entries:
            real = segment
        else:
            real = next((e for e in entries if e.lower() == segment.lower()), None)
            if real is None:
                return None  # DEAD is the caller's business, not ours
            wrong = True
        fixed.append(real)
        here = os.path.join(here, real)

    return "/".join(fixed) if wrong else None


def check(root: str) -> tuple[int, int, int, int]:
    dead = case = files = 0
    live: list[tuple[str, str, str]] = []  # (source, target as written, rel path)

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
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            path = target.split("#", 1)[0].split('"', 1)[0].strip()
            if not path:
                continue
            resolved = os.path.normpath(os.path.join(base, path))
            if not os.path.exists(resolved):
                print(f"DEAD  {rel_md}  ->  {target}")
                dead += 1
                continue
            real = real_name_mismatch(root, resolved)
            if real:
                print(f"CASE  {rel_md}  ->  {target}   (in the repo: {real})")
                case += 1
                continue
            try:
                rel_target = os.path.relpath(resolved, root)
            except ValueError:
                continue  # different drive on Windows -- an absolute personal-machine
                # path, not a repo-relative reference to check for gitignore-hiding
            if not rel_target.startswith(".."):
                live.append((rel_md, target, rel_target.replace(os.sep, "/")))

    hidden = ignored(root, sorted({t for _, _, t in live}))
    gone = 0
    for rel_md, target, rel_target in live:
        if rel_target in hidden:
            print(f"IGNORED  {rel_md}  ->  {target}   (gitignored: 404 on the remote)")
            gone += 1
    return dead, case, gone, files


def main() -> int:
    roots = sys.argv[1:]
    if not roots:
        print(__doc__)
        return 2
    grand_dead = grand_case = grand_gone = 0
    for root in roots:
        if len(roots) > 1:
            print(f"##### {os.path.basename(os.path.normpath(root))}")
        d, c, g, f = check(root)
        grand_dead += d
        grand_case += c
        grand_gone += g
        print(f"--- {f} files, {d} dead, {c} case-mismatch, {g} gitignored ---")
    if len(roots) > 1:
        print(f"===== TOTAL: {grand_dead} dead, {grand_case} case-mismatch, "
              f"{grand_gone} gitignored =====")
    return 1 if (grand_dead or grand_case or grand_gone) else 0


if __name__ == "__main__":
    sys.exit(main())
