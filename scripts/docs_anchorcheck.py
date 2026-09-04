#!/usr/bin/env python3
"""Anchor and orphan checker for a repo's markdown files.

    python scripts/docs_anchorcheck.py <repo-root> [...]

The companion to docs_linkcheck.py, which says so itself: it strips anchors
before checking, "so a wrong #heading is NOT caught; only missing files are."
This catches those, plus the documents nothing links to at all (DOC-06).

Two findings it reports, both seen in practice:

  ANCHOR    a ](#heading) or ](other.md#heading) with no such heading. The
            file exists, so the link checker calls it green.
  DOC-06    a tracked markdown file no other tracked file mentions by name.
            Good documentation nobody can reach.

WHAT IT CANNOT SEE, and this is the sharper half: an anchor that resolves to
the WRONG section. gopath.nvim's developer notes linked [Architecture]
(#architecture) at a heading further down under Configuration, because the one
the reader wanted carried an emoji and therefore a different anchor. That link
is green here and wrong on the page. Only reading finds it.

THE SLUG RULES ARE GITHUB'S, and five of them are non-obvious enough that
getting each wrong produced a wave of false findings while this was written:

  * Each whitespace character becomes one hyphen; runs are NOT collapsed. So
    "## A -- B", whose dash is dropped as punctuation, yields "#a--b".
  * An emoji is dropped but the space beside it is not, so "## <emoji> Config"
    is reachable only as "#-config" -- leading hyphen. Likewise a heading
    ending in punctuation: "## `:File[!] delete [%]`" is "#file-delete-".
    Both read off rendered GitHub pages on 2026-09-04, which give
    id="user-content--provider-system" and href="#file-delete-".
  * Only punctuation and symbols are dropped -- NOT everything outside \\w. An
    emoji like the warning sign is two codepoints, a pictograph and a variation
    selector, and GitHub drops the first and keeps the second: a heading ending
    in it renders as `href="#...-besetzt-<selector>"`. A `[^\\w\\s-]` rule eats
    the selector and calls every such link dead. See slug().
  * A repeated heading gets "-1", "-2" appended in order of appearance. That
    is how a CHANGELOG with three "## Added" sections is linkable at all.
  * Fenced code is tracked line by line, not matched with a ```.*?``` regex.
    Documentation about markdown nests fences, and a prose line that quotes
    one inline -- ```` ```lang ```` -- is not an opening fence: CommonMark
    forbids a backtick in a backtick fence's info string. Ignoring that read
    two headings of color_my_ascii.nvim as code and reported three live
    anchors as dead.

Sources are the files git tracks. Inline code and fenced blocks are stripped
before links are collected, because documentation about dead anchors quotes
dead anchors -- the same lesson docs_linkcheck.py learned for file links.

Exit code 1 when anything is reported.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
import unicodedata

FENCE = re.compile(r"^\s{0,3}(`{3,}|~{3,})(.*)$")
HEADING = re.compile(r"^#{1,6}\s+(.*)$", re.M)
SELF_LINK = re.compile(r"\]\(#([^)]+)\)")
CROSS_LINK = re.compile(r"\]\(([^)#\s]+\.md)#([^)\s]+)\)")


def slug(heading: str) -> str:
    """The anchor GitHub gives a heading.

    Punctuation and symbols go, letters/digits/marks stay, whitespace becomes
    hyphens. `[^\\w\\s-]` is *not* the same rule and gets one case wrong that
    matters: a variation selector (U+FE0F, the invisible half of an emoji like
    ⚠️) is a combining mark, and GitHub **keeps** it while dropping the
    pictograph in front of it. Measured — a heading ending in ⚠️ renders as
    `href="#…-besetzt-️"`, hyphen and selector both.
    """
    out = []
    for ch in heading.strip().lower().replace("`", ""):
        if ch.isspace():
            out.append("-")
        elif ch in "-_" or unicodedata.category(ch)[0] in "LNM":
            out.append(ch)
    return "".join(out)


def anchors_of(headings: list[str]) -> set[str]:
    """Every anchor a document offers, duplicates suffixed as GitHub does."""
    seen: dict[str, int] = {}
    out: set[str] = set()
    for h in headings:
        base = slug(h)
        n = seen.get(base, 0)
        out.add(base if n == 0 else f"{base}-{n}")
        seen[base] = n + 1
    return out


def prose_of(src: str) -> str:
    """The document with fenced code removed, fences tracked line by line."""
    out: list[str] = []
    closer: str | None = None
    for line in src.splitlines():
        m = FENCE.match(line)
        if closer is None:
            if m and not (m.group(1)[0] == "`" and "`" in m.group(2)):
                closer = m.group(1)
            else:
                out.append(line)
        elif (
            m
            and m.group(1)[0] == closer[0]
            and len(m.group(1)) >= len(closer)
            and not m.group(2).strip()
        ):
            closer = None
    return "\n".join(out)


def strip_inline_code(text: str) -> str:
    return re.sub(r"``.*?``|`[^`]*`", "", text)


def tracked_markdown(repo: str) -> list[str]:
    out = subprocess.run(
        ["git", "-C", repo, "ls-files", "*.md"],
        capture_output=True,
        text=True,
    ).stdout.split()
    return [p for p in out if os.path.isfile(os.path.join(repo, p))]


def check(repo: str) -> int:
    name = os.path.basename(repo.rstrip("/\\"))
    files = tracked_markdown(repo)
    bodies: dict[str, str] = {}
    prose: dict[str, str] = {}
    anchors: dict[str, set[str]] = {}

    for rel in files:
        with open(os.path.join(repo, rel), encoding="utf-8", errors="replace") as fh:
            bodies[rel] = fh.read()
        prose[rel] = prose_of(bodies[rel])
        anchors[rel] = anchors_of(HEADING.findall(prose[rel]))

    findings: list[tuple[str, str, str]] = []

    for rel in files:
        if rel == "README.md":
            continue
        base = os.path.basename(rel)
        if not any(base in bodies[o] for o in files if o != rel):
            findings.append(("DOC-06 orphan", rel, ""))

    for rel in files:
        clean = strip_inline_code(prose[rel])
        for a in SELF_LINK.findall(clean):
            if a in anchors[rel]:
                continue
            hint = ""
            if "-" + a in anchors[rel] or a + "-" in anchors[rel]:
                hint = "  (the heading's punctuation leaves its space behind)"
            findings.append(("ANCHOR dead", rel, "#" + a + hint))
        for target, a in CROSS_LINK.findall(clean):
            p = os.path.normpath(
                os.path.join(os.path.dirname(rel), target)
            ).replace("\\", "/")
            if p in anchors and a not in anchors[p]:
                findings.append(("ANCHOR dead cross-file", rel, f"{target}#{a}"))

    if findings:
        print("##### " + name)
        for kind, rel, detail in findings:
            print(f"  {kind:<24} {rel} {detail}")
    print(f"--- {name}: {len(files)} files, {len(findings)} findings ---")
    return len(findings)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__.strip().splitlines()[2].strip(), file=sys.stderr)
        return 2
    total = sum(check(r) for r in sys.argv[1:])
    print(f"===== TOTAL: {total} findings =====")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
