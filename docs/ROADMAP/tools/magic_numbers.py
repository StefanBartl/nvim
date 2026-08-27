"""Pass two: behaviour numbers that never got a name, and platform branches.

Pass one looked for named module constants. This looks for the two things it
structurally could not see:

  * a number written straight into the call -- `vim.defer_fn(fn, 60)`,
    `timer:start(250, 250, …)`, `vim.o.columns * 0.8` -- which has no name to
    match against a config key, and
  * a platform branch (`has("win32")`, `jit.os`) with no way to say
    "no, do the other thing".

Both are candidates only. A 10ms defer that exists to get off the current
tick is not a setting; a 3000ms one usually is.
"""
import io
import os
import re
import sys

REPOS = 'E:/repos'

PATTERNS = [
    # name, regex, what to report
    ('defer', re.compile(r'\bvim\.defer_fn\s*\([^,]*,\s*(\d+)\s*\)')),
    ('wait', re.compile(r'\bvim\.wait\s*\(\s*(\d+)')),
    ('timer', re.compile(r':start\s*\(\s*(\d+)\s*,\s*(\d+)')),
    ('timeout', re.compile(r'\btimeout\s*=\s*(\d+)')),
    ('frac_cols', re.compile(r'vim\.o\.columns\s*\*\s*(0?\.\d+)')),
    ('frac_lines', re.compile(r'vim\.o\.lines\s*\*\s*(0?\.\d+)')),
]

PLATFORM = re.compile(
    r'(vim\.fn\.has\(\s*"(win32|win64|macunix|mac|unix|wsl)"\s*\)'
    r'|jit\.os|package\.config:sub\(1,\s*1\)|vim\.uv\.os_uname)')

# A defer/wait this short is "get off the current tick", not a preference.
TICK_MAX = 50


def scan(repo):
    base = os.path.join(REPOS, repo, 'lua')
    if not os.path.isdir(base):
        return [], []
    magic, platform = [], []
    for root, dirs, files in os.walk(base):
        dirs[:] = [d for d in dirs if d not in ('.git',)]
        for f in files:
            if not f.endswith('.lua'):
                continue
            p = os.path.join(root, f)
            try:
                lines = io.open(p, encoding='utf-8', errors='replace').read().splitlines()
            except OSError:
                continue
            rel = os.path.relpath(p, os.path.join(REPOS, repo)).replace('\\', '/')
            for i, ln in enumerate(lines, 1):
                stripped = ln.strip()
                if stripped.startswith('--'):
                    continue
                for kind, rx in PATTERNS:
                    m = rx.search(ln)
                    if not m:
                        continue
                    val = m.group(1)
                    if kind in ('defer', 'wait', 'timer') and val.isdigit():
                        if int(val) <= TICK_MAX:
                            continue
                    magic.append((rel, i, kind, val, stripped[:70]))
                if PLATFORM.search(ln):
                    platform.append((rel, i, stripped[:78]))
    return magic, platform


repos = sys.argv[1:] or sorted(
    d for d in os.listdir(REPOS)
    if d.endswith('.nvim') and os.path.isdir(os.path.join(REPOS, d, 'lua')))

total_m = total_p = 0
for repo in repos:
    magic, platform = scan(repo)
    total_m += len(magic)
    total_p += len(platform)
    if magic:
        print('## %s — %d Zahlen ohne Namen' % (repo, len(magic)))
        for rel, i, kind, val, src in magic:
            print('   %-52s %-10s %-6s %s' % (rel + ':' + str(i), kind, val, src))
        print()

print('=' * 70)
print('Zahlen ohne Namen gesamt: %d' % total_m)
print('Plattform-Verzweigungen gesamt: %d' % total_p)
