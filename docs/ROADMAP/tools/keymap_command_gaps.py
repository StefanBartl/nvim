"""Candidate gaps: keymap actions with no obvious command counterpart.

A candidate, not a verdict. The pairing is by name and by description words,
and a route with a typed argument (`:Open <handler>`) covers many actions
without naming any of them -- so every candidate still needs a look.
"""
import io
import os
import re

OUT = ('C:/Users/bartl/AppData/Local/Temp/claude/'
       'C--Users-bartl-AppData-Local-nvim--claude-worktrees-nvim-rules-checklists-merge-6656cc/'
       'fb223ac8-966d-4014-8901-d47bd55aa27d/scratchpad/audit_out')

STOP = {'the', 'a', 'an', 'to', 'in', 'of', 'and', 'or', 'for', 'this', 'that',
        'with', 'on', 'at', 'by', 'it', 'as', 'from', 'toggle', 'open', 'show'}


def words(text):
    return {w for w in re.split(r'[^a-z0-9]+', text.lower()) if len(w) > 2 and w not in STOP}


for fn in sorted(os.listdir(OUT)):
    plugin = fn[:-4]
    lines = io.open(os.path.join(OUT, fn), encoding='utf-8').read().splitlines()
    keys, cmds = [], []
    for ln in lines:
        parts = ln.split('\t')
        if ln.startswith('KEY') and len(parts) >= 5:
            keys.append((parts[2], parts[4]))
        elif ln.startswith('CMD') and len(parts) >= 3:
            cmds.append(' '.join(parts[1:]))

    if not keys:
        continue

    cmd_blob = ' '.join(cmds).lower()
    cmd_words = words(cmd_blob)

    gaps = []
    for name, desc in keys:
        # Name match: the action's own name, or its parts, in a route path.
        name_parts = [p for p in name.split('_') if len(p) > 2]
        if name.lower() in cmd_blob:
            continue
        if name_parts and all(p in cmd_blob for p in name_parts):
            continue
        # Description overlap: at least half the meaningful words covered.
        dw = words(desc)
        if dw and len(dw & cmd_words) >= max(1, len(dw) // 2):
            continue
        gaps.append((name, desc))

    if gaps:
        print('## %s  (%d/%d ohne offensichtliches Kommando)' % (plugin, len(gaps), len(keys)))
        for name, desc in gaps:
            print('   %-22s %s' % (name, desc))
        print()
