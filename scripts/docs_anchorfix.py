# -*- coding: utf-8 -*-
"""Repair links whose #anchor no longer matches the heading it names.

    python scripts/docs_anchorfix.py <file.md> [...]

The companion to docs_linkcheck.py's ANCHOR class: that one finds them, this
one fixes the two shapes that are a slug bug rather than a rename.

  1. **The link text still names the heading.** A table of contents entry
     whose anchor drifted while its text did not.
  2. **The anchor is the right slug with the hyphens wrong.** A heading with
     an em dash or a slash in it leaves *two* hyphens in GitHub's slug,
     because the punctuation is dropped and the spaces around it are not, and
     every table-of-contents generator seen in these repositories collapses
     them to one. Trailing punctuation does the same at the end.

Both are rewritten only when **exactly one** heading in the target document
qualifies. Anything ambiguous, and anything that matches no heading at all, is
left alone and reported: an anchor that matches nothing is usually a section
that was renamed or moved to another file, and guessing there would turn a
visible breakage into an invisible wrong answer.

Cross-file links (`../commands.md#some-heading`) are resolved and checked
against that file's headings, not this one's.
"""
import io, os, re, sys

HEAD = re.compile(r"^(#{1,6})\s+(.*)")
FENCE = re.compile(r"^\s*(`{3,}|~{3,})")
LINK = re.compile(r"\[([^\]]+)\]\(([^)\s]+)\)")


def uncoded(text):
    """The lines that are not inside a code fence, length-aware."""
    fence = 0
    for line in text.splitlines():
        m = FENCE.match(line)
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
            yield line


def slug(title):
    t = re.sub(r"[`*]", "", title.strip().rstrip("#").strip())
    return re.sub(r"[^\w\s-]", "", t).strip().lower().replace(" ", "-")


def loose(anchor):
    """An anchor with hyphen runs collapsed -- the shape both bugs blur."""
    return re.sub(r"-+", "-", anchor.lower()).strip("-")


def headings(path, cache={}):
    """(by link text, by loose slug) for one document."""
    if path in cache:
        return cache[path]
    try:
        text = io.open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        cache[path] = ({}, {})
        return cache[path]
    by_text, by_loose, seen = {}, {}, {}
    for line in uncoded(text):
        m = HEAD.match(line)
        if not m:
            continue
        title = re.sub(r"[`*]", "", m.group(2).strip().rstrip("#").strip())
        s = slug(m.group(2))
        n = seen.get(s, 0)
        seen[s] = n + 1
        real = s if n == 0 else "%s-%d" % (s, n)
        by_text.setdefault(title, []).append(real)
        by_loose.setdefault(loose(real), []).append(real)
    cache[path] = (by_text, by_loose)
    return cache[path]


def fix(path):
    text = io.open(path, encoding="utf-8").read()
    left = []

    def repl(m):
        label, target = m.group(1), m.group(2)
        if target.startswith(("http://", "https://", "mailto:")) or "#" not in target:
            return m.group(0)
        file_part, _, anchor = target.partition("#")
        if not anchor:
            return m.group(0)
        doc = path if not file_part else os.path.normpath(
            os.path.join(os.path.dirname(path), file_part))
        if not doc.lower().endswith((".md", ".markdown")) or not os.path.exists(doc):
            return m.group(0)
        by_text, by_loose = headings(doc)
        if anchor.lower() in {a for v in by_loose.values() for a in v}:
            return m.group(0)                       # already correct
        clean = re.sub(r"[`*]", "", label).strip()
        for candidates in (by_text.get(clean), by_loose.get(loose(anchor))):
            if candidates and len(candidates) == 1:
                return "[%s](%s#%s)" % (label, file_part, candidates[0])
        left.append(target)
        return m.group(0)

    out = LINK.sub(repl, text)
    if out != text:
        io.open(path, "w", encoding="utf-8", newline="").write(out)
        print("fixed    ", path)
    else:
        print("unchanged", path)
    for target in left:
        print("  left   ", target, "-- no single heading matches")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    for p in sys.argv[1:]:
        fix(p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
