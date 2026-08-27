import io
import os
import re
from collections import Counter

REPOS = 'E:/repos'
PLATFORM = re.compile(
    r'(vim\.fn\.has\(\s*"(win32|win64|macunix|mac|unix|wsl)"\s*\)'
    r'|jit\.os|package\.config:sub\(1,\s*1\)|os_uname)')

per_repo = Counter()
samples = {}

for repo in sorted(d for d in os.listdir(REPOS)
                   if d.endswith('.nvim') and os.path.isdir(os.path.join(REPOS, d, 'lua'))):
    base = os.path.join(REPOS, repo, 'lua')
    for root, dirs, files in os.walk(base):
        for f in files:
            if not f.endswith('.lua'):
                continue
            p = os.path.join(root, f)
            rel = os.path.relpath(p, os.path.join(REPOS, repo)).replace('\\', '/')
            for i, ln in enumerate(
                    io.open(p, encoding='utf-8', errors='replace').read().splitlines(), 1):
                if ln.strip().startswith('--'):
                    continue
                if PLATFORM.search(ln):
                    per_repo[repo] += 1
                    samples.setdefault(repo, []).append((rel, i, ln.strip()[:76]))

for repo, n in per_repo.most_common():
    print('## %s (%d)' % (repo, n))
    for rel, i, src in samples[repo][:4]:
        print('   %-46s %s' % (rel + ':' + str(i), src))
    print()
