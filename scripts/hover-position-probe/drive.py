"""Drive a real headless Neovim through a sequence of gestures and read the
probe's counters back after each one.

Each gesture is one keystroke (or a short pair) followed by enough quiet for
'updatetime' to fire CursorHold and for hover's own 250 ms debounce to run.
What the run establishes is which gestures re-ask the position pipeline with a
key it has already been asked -- not how often a human makes them.
"""
import os, subprocess, sys, time

ADDR = "127.0.0.1:47790"
PROBE_DIR = os.path.dirname(os.path.abspath(__file__))
SETTLE = 0.75  # 200 ms updatetime + 250 ms debounce + slack

# (label, keys to send, what it is meant to do)
GESTURES = [
    ("<Esc> (first key)", "<Esc>",   "the first CursorHold of the session"),
    ("j  (down a line)", "j",        "new row"),
    ("<Esc>",            "<Esc>",    "no move, no change"),
    ("<Esc> again",      "<Esc>",    "no move, no change"),
    ("l  (right)",       "l",        "new col, same row"),
    ("h  (back left)",   "h",        "back to a col already asked"),
    ("zz (centre)",      "zz",       "redraw, cursor stays put"),
    (": then <Esc>",     ":<Esc>",   "cmdline opened and abandoned"),
    ("0 then h at col 0","0h",       "a motion that cannot move"),
    ("G  (last line)",   "G",        "new row"),
    ("j at last line",   "j",        "a motion that cannot move"),
    ("x  (delete char)", "x",        "changedtick bumps"),
    ("u  (undo)",        "u",        "changedtick bumps again"),
    ("<C-e> (scroll)",   "<C-e>",    "view scrolls, cursor may or may not move"),
    ("w  (next word)",   "w",        "new col"),
    ("b  (back a word)", "b",        "back to a col already asked"),
]


def nvim(*args):
    return subprocess.run(["nvim", "--headless", "--server", ADDR, *args],
                          capture_output=True, text=True, timeout=20)


def expr(lua):
    r = nvim("--remote-expr", "luaeval('%s')" % lua)
    return (r.stdout or r.stderr).strip()


env = dict(os.environ, PROBE_DIR=PROBE_DIR)
server = subprocess.Popen(
    ["nvim", "--clean", "--headless", "--listen", ADDR, "-u",
     os.path.join(PROBE_DIR, "init.lua")],
    env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

# Wait for the socket to answer rather than sleeping a guess.
for _ in range(40):
    time.sleep(0.25)
    if expr('1 + 1') == "2":
        break
else:
    server.kill()
    print("nvim never answered on", ADDR, file=sys.stderr)
    print(server.stderr.read().decode(errors="replace"), file=sys.stderr)
    sys.exit(1)

print("%-20s %-34s %6s %6s %6s %6s" % ("gesture", "meant to", "asks", "+asks", "repeat", "cons"))
print("-" * 88)

prev_asks, prev_rep, prev_cons = 0, 0, 0
for label, keys, meaning in GESTURES:
    if keys:
        nvim("--remote-send", keys)
    time.sleep(SETTLE)
    asks = int(expr('require("position_probe").asks') or 0)
    rep = int(expr('require("position_probe").repeats') or 0)
    cons = int(expr('require("position_probe").consecutive') or 0)
    print("%-20s %-34s %6d %6d %6d %6d"
          % (label, meaning, asks, asks - prev_asks, rep - prev_rep, cons - prev_cons))
    prev_asks, prev_rep, prev_cons = asks, rep, cons

print("-" * 88)
print(expr('require("position_probe").line()').replace("\n", "\n"))
same_row = int(expr('require("position_probe").same_row') or 0)
print("same (bufnr,row,changedtick) as the previous ask, col ignored:", same_row)

nvim("--remote-send", "<Esc>:qa!<CR>")
time.sleep(0.5)
server.kill()
