"""Identical function bodies across plugins -- actual duplication, not similar names."""
import hashlib
import io
import os
import re
from collections import defaultdict

REPOS = 'E:/repos'
MIN_LINES = 4   # a two-line wrapper is not worth extracting

bodies = defaultdict(list)

for repo in sorted(d for d in os.listdir(REPOS)
                   if d.endswith('.nvim') and os.path.isdir(os.path.join(REPOS, d, 'lua'))):
    if repo == 'lib.nvim':
        continue
    base = os.path.join(REPOS, repo, 'lua')
    for root, _dirs, files in os.walk(base):
        for f in files:
            if not f.endswith('.lua'):
                continue
            p = os.path.join(root, f)
            try:
                text = io.open(p, encoding='utf-8', errors='replace').read()
            except OSError:
                continue

            for m in re.finditer(
                    r'^(local function|function)\s+([\w.:]+)\s*\(([^)]*)\)\n(.*?)^end$',
                    text, re.S | re.M):
                name, body = m.group(2), m.group(4)
                lines = [ln.strip() for ln in body.splitlines() if ln.strip()
                         and not ln.strip().startswith('--')]
                if len(lines) < MIN_LINES:
                    continue
                norm = '\n'.join(lines)
                h = hashlib.sha1(norm.encode('utf-8')).hexdigest()[:12]
                rel = os.path.relpath(p, os.path.join(REPOS, repo)).replace('\\', '/')
                bodies[h].append((repo, rel, name, len(lines)))

found = 0
for h, hits in sorted(bodies.items(), key=lambda kv: -len(kv[1])):
    repos_involved = {r for r, _, _, _ in hits}
    if len(repos_involved) < 2:
        continue
    found += 1
    n_lines = hits[0][3]
    print('## %d Zeilen, %d Plugins: %s' % (n_lines, len(repos_involved),
                                            ', '.join(sorted(repos_involved))))
    for repo, rel, name, _ in hits:
        print('   %-22s %-46s %s' % (repo, rel, name))
    print()

print('identische Funktionskoerper in mehr als einem Plugin: %d' % found)
