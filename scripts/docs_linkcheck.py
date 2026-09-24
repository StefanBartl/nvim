#!/usr/bin/env python3
"""Relative-link checker for a repo's markdown files.

    python scripts/docs_linkcheck.py <repo-root> [...] [options]

    --fix    rewrite in place what can be corrected without guessing: every
             CASE mismatch, and every ANCHOR whose fragment fuzzy-matches
             exactly one real heading in the same file (see anchor_fix()).
             An unmatched ANCHOR is never auto-fixed -- printed only.
    --fix-dead
             also rewrite a DEAD link whose basename exists exactly once
             elsewhere in the repo (the SUGGEST hint). Separate from --fix
             on purpose: unlike CASE/ANCHOR, this asserts the same-named
             file elsewhere IS the moved target, not just that the string
             is close -- two files that happen to share a generic name
             (a stray "Overview.md") would be a wrong, silent rewrite.
             Implies --fix. Review the diff before trusting it at scale.
    --json   emit one JSON array of findings on stdout instead of the
             human-readable report -- for scripting / diffing runs / feeding
             another tool, not for reading in a terminal.

Reports every ](target) link whose file does not exist, and — the reason this
exists at all — every link whose spelling differs from the file's real name.
Each report line carries `file:line`, this project's own convention, so an
editor jump-to-location works on the report directly.

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

A DEAD link whose basename exists exactly once elsewhere in the repo (moved,
not deleted) gets a SUGGEST hint alongside it — the repo-wide basename index
is git-backed too, so it costs one extra `ls-files` per root, not a directory
walk. Ambiguous or absent basenames get no suggestion: a guess printed with no
signal it might be wrong is worse than no guess.

Multiple roots are scanned concurrently (I/O-bound: git subprocesses and file
reads release the GIL) but reported in the order given, so a diff between two
runs of the same command line is meaningful.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from difflib import SequenceMatcher
from urllib.parse import unquote

# Windows' default console/pipe encoding is cp1252, not UTF-8: a link whose
# TEXT (not path) contains an emoji or a non-Latin-1 character then blows up
# `print()` with UnicodeEncodeError deep inside a large multi-repo run,
# after most of the work is already done. reconfigure() is Python 3.7+;
# stdout/stderr are always text streams here (never redirected to a raw
# binary target by this script), so it is always safe to call.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

SKIP_DIRS = {".git", "node_modules", "dist", "build", "__pycache__"}
SKIP_PATHS = (os.path.join("docs", "map"),)

# [^)\n]: an unclosed "(" on a malformed line (escaped brackets, a stray
# paren in prose) must never let the match run on into the NEXT line's real
# link, swallowing it into one corrupted multi-line "target" -- found live
# in Notes/MyNotes/Notes.md:381 (`\[COM\](e:/...COM.md` with no closing
# paren) merging into line 382's actual `](../Learning/DOTnet_CSHARP.md)`.
LINK_RE = re.compile(r"\]\(([^)\n]+)\)")
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")
INLINE_CODE_RE = re.compile(r"`[^`]*`")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)")


@dataclass
class Finding:
    repo: str
    file: str  # relative to repo root
    line: int
    kind: str  # DEAD | CASE | IGNORED | ANCHOR
    target: str  # link text exactly as written
    detail: str = ""
    fix: str | None = None  # corrected target, CASE only

    def human(self) -> str:
        loc = f"{self.file}:{self.line}"
        extra = f"   ({self.detail})" if self.detail else ""
        return f"{self.kind:<7} {loc}  ->  {self.target}{extra}"


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
    """Blank out fenced blocks and inline code so quoted links are not links.

    Line count and line *content length* are not preserved (INLINE_CODE_RE
    removes the backtick span rather than blanking it in place) -- callers
    that need a line number look it up via `line_of()` on the ORIGINAL text
    instead of counting newlines in this output.
    """
    out = [""] * len(text.splitlines())
    for n, line in uncoded(text):
        out[n - 1] = INLINE_CODE_RE.sub("", line)
    return "\n".join(out)


def read_text(path: str) -> tuple[str, str] | None:
    """Read `path` as text without silently corrupting non-UTF-8 notes.

    `open(path, encoding="utf-8", errors="replace")` turns every byte an
    editor's cp1252 default produced for an umlaut into U+FFFD -- invisible
    right up until a computed ANCHOR fix contains a literal `�` and --fix
    would WRITE that into the file. utf-8 is tried first (the common case);
    cp1252 next (the realistic alternative on a Windows-authored note);
    latin-1 last, because it decodes any byte sequence and so is guaranteed
    to terminate the loop -- a non-corrupting last resort, not a claim that
    the bytes really are Latin-1. Returns (text, encoding) so a writer can
    round-trip in the same encoding it read, or None if the file cannot be
    read at all.
    """
    try:
        data = open(path, "rb").read()
    except OSError:
        return None
    for enc in ("utf-8", "cp1252", "latin-1"):
        try:
            return data.decode(enc), enc
        except UnicodeDecodeError:
            continue
    return None


def line_of(text: str, needle: str, start_hint: int = 0) -> int:
    """1-based line number of `needle`'s first occurrence at/after char start_hint."""
    idx = text.find(needle, start_hint)
    if idx < 0:
        idx = text.find(needle)
    if idx < 0:
        return 1
    return text.count("\n", 0, idx) + 1


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
            input=stdin, capture_output=True, timeout=30,
            # encoding=utf-8 explicitly: text=True alone decodes with
            # locale.getpreferredencoding(), which on Windows is the console's
            # ANSI codepage (cp1252), not UTF-8 -- silently mojibake-corrupting
            # any non-ASCII path git prints (a German umlaut in a filename,
            # common in this vault). git itself always writes UTF-8 paths.
            encoding="utf-8", errors="surrogateescape",
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


def tracked_all(root: str) -> list[str] | None:
    """Every tracked/untracked-but-not-ignored path — the basename index's source.

    Deliberately not scoped to *.md: a DEAD link just as often names an image,
    a script or a sibling doc's asset, and the suggestion is only worth giving
    when it is exactly this same search the rest of the tool already trusts
    (git-backed, gitignore-aware) rather than a second, divergent os.walk.
    """
    paths = git(root, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
    if paths is None:
        return None
    return list(dict.fromkeys(paths))


def basename_index(root: str) -> dict[str, list[str]]:
    """basename.lower() -> [repo-relative paths], for DEAD-link SUGGEST hints."""
    index: dict[str, list[str]] = {}
    for rel in tracked_all(root) or ():
        base = os.path.basename(rel).lower()
        index.setdefault(base, []).append(rel.replace("\\", "/"))
    return index


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


def suggest(index: dict[str, list[str]], target_path: str) -> tuple[str, str | None]:
    """(SUGGEST detail, single unambiguous candidate or None) for a DEAD link.

    The candidate is only returned when exactly one file anywhere in the repo
    has this basename -- a generic name (`Overview.md`, `README.md`) will
    almost always have several, which correctly yields no candidate rather
    than a guess among them.
    """
    base = os.path.basename(target_path).lower()
    if not base:
        return "", None
    candidates = index.get(base, [])
    if len(candidates) == 1:
        return f"moved to {candidates[0]}?", candidates[0]
    if 1 < len(candidates) <= 3:
        return (f"{len(candidates)} files named {os.path.basename(target_path)}: "
                + ", ".join(candidates)), None
    return "", None


def anchors_of(path: str, cache: dict) -> set[str]:
    """The heading anchors of `path`, read once per run."""
    if path not in cache:
        got = read_text(path)
        cache[path] = slugs(got[0]) if got else set()
    return cache[path]


def anchor_fix(frag: str, real_slugs: set[str]) -> str | None:
    """The one real heading slug `frag` almost certainly meant, or None.

    Written against a concrete, recurring cause: a table-of-contents
    generator that drops a heading's leading diacritic (`Öffentliche API`
    -> `#ffentliche-api` instead of `#öffentliche-api`) -- same failure
    shape every time, across hundreds of files, so a close-but-not-exact
    match is corrected rather than just reported. difflib's ratio is a
    stdlib similarity measure (no Levenshtein dependency needed); the
    threshold and margin are deliberately strict -- an unrelated heading
    that happens to share a few words must never win a silent rewrite.
    """
    if len(frag) < 3 or not real_slugs or "�" in frag:
        return None
    real_slugs = {s for s in real_slugs if "�" not in s}
    if not real_slugs:
        return None
    scored = sorted(
        ((SequenceMatcher(None, frag, s).ratio(), s) for s in real_slugs),
        reverse=True,
    )
    best_ratio, best_slug = scored[0]
    if best_ratio < 0.82:
        return None
    if len(scored) > 1 and (best_ratio - scored[1][0]) < 0.06:
        return None  # too close to a second candidate to guess safely
    return best_slug


def check(root: str) -> tuple[list[Finding], int]:
    """Scan one repo root. Returns (findings, files-scanned)."""
    findings: list[Finding] = []
    files = 0
    live: list[tuple[str, str, str, int]] = []  # (rel_md, target, rel_target, line)
    heads: dict[str, set[str]] = {}
    index: dict[str, list[str]] | None = None  # built lazily, only if a DEAD link needs it

    for md in sorted(markdown_files(root)):
        files += 1
        got = read_text(md)
        if got is None:
            continue
        raw, _ = got
        stripped = strip_code(raw)
        base = os.path.dirname(md)
        rel_md = os.path.relpath(md, root).replace(os.sep, "/")
        seen = set()
        for m in LINK_RE.finditer(stripped):
            target = m.group(1).strip()
            if not target or target in seen:
                continue
            seen.add(target)
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            lineno = line_of(raw, f"]({m.group(1)})", 0)
            path, _, raw_frag_full = target.partition("#")
            path = path.split('"', 1)[0].strip()
            raw_frag = raw_frag_full.split('"', 1)[0]  # unstripped: needed verbatim for --fix
            frag = raw_frag.strip()
            # A bare "#heading" points into the document it is written in --
            # which is where a table of contents lives, and where a renamed
            # heading is least likely to be noticed.
            #
            # unquote(path): a link's PATH component may be percent-encoded
            # (a filename with spaces, "+", a comma -- "%20"/"%2B"/"%2C"),
            # and every real link-follower (browser, GitHub, vim.ui.open)
            # decodes it before touching the filesystem. Comparing the raw
            # "%2B%2B" against a real on-disk "++" would call an actually
            # working link DEAD. `path` itself stays encoded -- it is the
            # literal substring `target`'s own text is built from, needed
            # verbatim for the CASE/DEAD --fix string replace below.
            resolved = md if not path else os.path.normpath(os.path.join(base, unquote(path)))
            if path:
                if not os.path.exists(resolved):
                    if index is None:
                        index = basename_index(root)
                    detail, candidate = suggest(index, unquote(path))
                    dead_fix = None
                    if candidate and target.startswith(path):
                        new_rel = os.path.relpath(
                            os.path.join(root, candidate), base
                        ).replace(os.sep, "/")
                        dead_fix = target.replace(path, new_rel, 1)
                    findings.append(Finding(
                        repo=root, file=rel_md, line=lineno, kind="DEAD",
                        target=target, detail=detail, fix=dead_fix,
                    ))
                    continue
                real = real_name_mismatch(root, resolved)
                if real:
                    corrected = target.replace(path, real, 1) if target.startswith(path) else None
                    findings.append(Finding(
                        repo=root, file=rel_md, line=lineno, kind="CASE",
                        target=target, detail=f"on disk: {real}", fix=corrected,
                    ))
                    continue
            if frag and resolved.lower().endswith((".md", ".markdown")):
                real_slugs = anchors_of(resolved, heads)
                if frag.lower() not in real_slugs:
                    fixed_slug = anchor_fix(frag.lower(), real_slugs)
                    corrected = (
                        target.replace(f"#{raw_frag}", f"#{fixed_slug}", 1)
                        if fixed_slug else None
                    )
                    detail = f"no such heading -- fix: #{fixed_slug}" if fixed_slug else "no such heading"
                    findings.append(Finding(
                        repo=root, file=rel_md, line=lineno, kind="ANCHOR",
                        target=target, detail=detail, fix=corrected,
                    ))
            if not path:
                continue
            try:
                rel_target = os.path.relpath(resolved, root)
            except ValueError:
                continue  # different drive on Windows -- an absolute personal-machine
                # path, not a repo-relative reference to check for gitignore-hiding
            if not rel_target.startswith(".."):
                live.append((rel_md, target, rel_target.replace(os.sep, "/"), lineno))

    hidden = ignored(root, sorted({t for _, _, t, _ in live}))
    for rel_md, target, rel_target, lineno in live:
        if rel_target in hidden:
            findings.append(Finding(
                repo=root, file=rel_md, line=lineno, kind="IGNORED",
                target=target, detail="gitignored: 404 on the remote",
            ))
    return findings, files


def apply_fixes(root: str, findings: list[Finding], fix_dead: bool = False) -> int:
    """Rewrite CASE/ANCHOR (and, if `fix_dead`, DEAD) findings with a computed
    `fix` in place. Returns count fixed."""
    kinds = ("CASE", "ANCHOR", "DEAD") if fix_dead else ("CASE", "ANCHOR")
    by_file: dict[str, list[Finding]] = {}
    for f in findings:
        # "�" is defense in depth, not the primary guard (read_text's
        # cp1252/latin-1 fallback is): a fix computed from a lossily-decoded
        # heading must never be written back, whatever produced it.
        if f.kind in kinds and f.fix and "�" not in f.fix:
            by_file.setdefault(f.file, []).append(f)

    fixed = 0
    for rel_file, items in by_file.items():
        path = os.path.join(root, rel_file)
        got = read_text(path)
        if got is None:
            continue
        text, enc = got
        changed = text
        for f in items:
            old, new = f"]({f.target})", f"]({f.fix})"
            if old in changed:
                changed = changed.replace(old, new)
                fixed += 1
        if changed != text:
            # Round-trip in the encoding it was read with: rewriting a
            # cp1252 note as UTF-8 would touch every non-ASCII byte in the
            # file, not just the link this tool actually means to fix.
            with open(path, "w", encoding=enc, newline="") as fh:
                fh.write(changed)
    return fixed


def summary_counts(findings: list[Finding]) -> dict[str, int]:
    counts = {"DEAD": 0, "CASE": 0, "IGNORED": 0, "ANCHOR": 0}
    for f in findings:
        counts[f.kind] = counts.get(f.kind, 0) + 1
    return counts


def run_root(root: str, do_fix: bool, fix_dead: bool = False) -> tuple[str, list[Finding], int, int]:
    """One root's full pipeline: scan, optionally fix, return (root, findings, files, fixed)."""
    findings, files = check(root)
    fixed = apply_fixes(root, findings, fix_dead) if do_fix else 0
    if fixed:
        # Re-scan so the report reflects what is actually on disk now, rather
        # than claiming a CASE mismatch the fix pass just corrected.
        findings, files = check(root)
    return root, findings, files, fixed


def main() -> int:
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("roots", nargs="*")
    ap.add_argument("--fix", action="store_true")
    ap.add_argument("--fix-dead", action="store_true")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("-h", "--help", action="store_true")
    args = ap.parse_args()

    if args.help or not args.roots:
        print(__doc__)
        return 0 if args.help else 2

    do_fix = args.fix or args.fix_dead  # --fix-dead implies --fix
    roots = args.roots
    results: dict[str, tuple[list[Finding], int, int]] = {}
    workers = min(8, len(roots)) or 1
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(run_root, r, do_fix, args.fix_dead): r for r in roots}
        done = 0
        for fut in futures:
            root, findings, files, fixed = fut.result()
            results[root] = (findings, files, fixed)
            done += 1
            if len(roots) > 1 and not args.json:
                print(f"# scanned {os.path.basename(os.path.normpath(root))} "
                      f"({done}/{len(roots)})", file=sys.stderr)

    if args.json:
        payload = []
        for root in roots:
            findings, files, fixed = results[root]
            payload.append({
                "repo": os.path.basename(os.path.normpath(root)),
                "root": root,
                "files_scanned": files,
                "fixed": fixed,
                "findings": [
                    {"file": f.file, "line": f.line, "kind": f.kind,
                     "target": f.target, "detail": f.detail}
                    for f in findings
                ],
            })
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return 1 if any(p["findings"] for p in payload) else 0

    grand = {"DEAD": 0, "CASE": 0, "IGNORED": 0, "ANCHOR": 0}
    grand_fixed = 0
    for root in roots:
        findings, files, fixed = results[root]
        if len(roots) > 1:
            print(f"##### {os.path.basename(os.path.normpath(root))}")
        for f in sorted(findings, key=lambda f: (f.file, f.line)):
            print(f.human())
        counts = summary_counts(findings)
        for k in grand:
            grand[k] += counts[k]
        grand_fixed += fixed
        fixed_note = f", {fixed} fixed" if fixed else ""
        print(f"--- {files} files, {counts['DEAD']} dead, {counts['CASE']} case-mismatch, "
              f"{counts['IGNORED']} gitignored, {counts['ANCHOR']} dead anchors{fixed_note} ---")

    if len(roots) > 1:
        fixed_note = f", {grand_fixed} fixed" if grand_fixed else ""
        print(f"===== TOTAL: {grand['DEAD']} dead, {grand['CASE']} case-mismatch, "
              f"{grand['IGNORED']} gitignored, {grand['ANCHOR']} dead anchors{fixed_note} =====")
    return 1 if any(grand.values()) else 0


if __name__ == "__main__":
    sys.exit(main())
