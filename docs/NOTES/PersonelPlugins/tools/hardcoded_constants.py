"""Candidates for 'implemented but not configurable'.

Looks for named constants that describe *behaviour* -- timeouts, limits,
sizes, delays, counts -- and checks whether that name appears anywhere in the
plugin's config surface (DEFAULTS / @types / config module). A name that lives
only in the implementation is a candidate for a config key.

Candidates, not verdicts: plenty of constants should stay constants.
"""
import io
import os
import re
import sys

REPOS = 'E:/repos'

# Names that describe behaviour a user might reasonably want to change.
BEHAVIOUR = re.compile(
    r'(timeout|delay|debounce|interval|max|min|limit|cap|width|height|size|'
    r'count|threshold|retry|attempts|ms$|_ms|padding|depth|lines|chars|budget)',
    re.I)

# Module-level constants only -- column 0, so function-local accumulators
# (`local lines = {}` inside a loop) do not drown out the real ones. Either
# SCREAMING_CASE, or a value that is plainly a tuned number rather than a
# counter's starting point.
CONST = re.compile(r'^local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([0-9]+|"[^"]+"|\{[^}]+\})\s*(--.*)?$')


def is_constant(name, value):
    if name.isupper():
        return True
    if re.fullmatch(r'[0-9]+', value):
        return int(value) not in (0, 1)
    return False


def config_blob(repo):
    """Everything that looks like the plugin's config surface, as one string."""
    out = []
    for root, dirs, files in os.walk(os.path.join(REPOS, repo, 'lua')):
        dirs[:] = [d for d in dirs if d not in ('.git',)]
        low = root.replace('\\', '/').lower()
        for f in files:
            if not f.endswith('.lua'):
                continue
            p = os.path.join(root, f)
            if ('config' in low or '@types' in low or 'defaults' in f.lower()
                    or f.lower() in ('types.lua', 'init.lua') and 'config' in low):
                try:
                    out.append(io.open(p, encoding='utf-8', errors='replace').read())
                except OSError:
                    pass
    return '\n'.join(out).lower()


def scan(repo):
    cfg = config_blob(repo)
    if not cfg:
        return []
    hits = []
    base = os.path.join(REPOS, repo, 'lua')
    for root, dirs, files in os.walk(base):
        low = root.replace('\\', '/').lower()
        if 'config' in low or '@types' in low:
            continue
        for f in files:
            if not f.endswith('.lua'):
                continue
            p = os.path.join(root, f)
            try:
                lines = io.open(p, encoding='utf-8', errors='replace').read().splitlines()
            except OSError:
                continue
            for i, ln in enumerate(lines, 1):
                m = CONST.match(ln)
                if not m:
                    continue
                name, value = m.group(1), m.group(2)
                if not BEHAVIOUR.search(name):
                    continue
                if not is_constant(name, value):
                    continue
                # Already reachable from config? Then it is not a candidate.
                # `DEFAULT_MIN_LEVEL` is the fallback behind a `min_level`
                # config key, so the prefix has to come off before looking.
                key = name.lower().lstrip('_')
                variants = {key, re.sub(r'^default_', '', key)}
                if any(v in cfg for v in variants):
                    continue
                rel = os.path.relpath(p, os.path.join(REPOS, repo)).replace('\\', '/')
                hits.append((rel, i, name, value.strip()[:48]))
    return hits


repos = sys.argv[1:] or sorted(
    d for d in os.listdir(REPOS)
    if d.endswith('.nvim') and os.path.isdir(os.path.join(REPOS, d, 'lua')))

for repo in repos:
    hits = scan(repo)
    if hits:
        print('## %s  (%d Kandidaten)' % (repo, len(hits)))
        for rel, i, name, value in hits:
            print('   %-46s %-24s = %s' % (rel + ':' + str(i), name, value))
        print()
