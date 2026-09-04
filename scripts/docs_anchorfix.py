# -*- coding: utf-8 -*-
"""Repair a document's own table of contents against its real headings.

    python scripts/docs_anchorfix.py <file.md> [...]

The companion to docs_linkcheck.py's ANCHOR class: that one finds them, this
one fixes the shape they almost always have. A heading with an em dash or a
slash in it leaves *two* hyphens in GitHub's slug, because the punctuation is
dropped and the spaces around it are not -- and every table-of-contents
generator seen in these repositories collapses them to one.

Only rewrites an anchor when exactly one heading in the file has that link
text. Anything ambiguous, and anything whose text does not match a heading at
all, is left for a person: a link text that no heading matches is usually a
renamed section rather than a mis-slugged one, and guessing there would turn a
visible breakage into an invisible wrong answer.
"""
import io, re, sys

HEAD = re.compile(r"^(#{1,6})\s+(.*)")
FENCE = re.compile(r"^\s*(`{3,}|~{3,})")

def uncoded(text):
    fence = 0
    for n, line in enumerate(text.splitlines(), 1):
        m = FENCE.match(line)
        if m:
            w, rest = len(m.group(1)), line[m.end():]
            if fence:
                if w >= fence and not rest.strip():
                    fence = 0
                continue
            if "`" not in rest:
                fence = w
                continue
        if not fence:
            yield n, line

def slug(title):
    t = re.sub(r"[`*]", "", title.strip().rstrip("#").strip())
    return re.sub(r"[^\w\s-]", "", t).strip().lower().replace(" ", "-")

def fix(path):
    text = io.open(path, encoding="utf-8").read()
    by_title, seen = {}, {}
    for _, line in uncoded(text):
        m = HEAD.match(line)
        if not m:
            continue
        title = re.sub(r"[`*]", "", m.group(2).strip().rstrip("#").strip())
        s = slug(m.group(2))
        n = seen.get(s, 0); seen[s] = n + 1
        by_title.setdefault(title, []).append(s if n == 0 else "%s-%d" % (s, n))

    def repl(m):
        text_, anc = m.group(1), m.group(2)
        clean = re.sub(r"[`*]", "", text_).strip()
        cands = by_title.get(clean)
        if len(cands or ()) == 1 and cands[0] != anc:
            return "[%s](#%s)" % (text_, cands[0])
        return m.group(0)

    out = re.sub(r"\[([^\]]+)\]\(#([^)]+)\)", repl, text)
    if out != text:
        io.open(path, "w", encoding="utf-8", newline="").write(out)
        print("fixed", path)
    else:
        print("unchanged", path)

for p in sys.argv[1:]:
    fix(p)
