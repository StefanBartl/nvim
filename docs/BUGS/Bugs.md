# FIX: bugs

## Table of content

  - [Important Bugs](#important-bugs)
    - [LSP](#lsp)
  - [neotree-fs-refactor](#neotree-fs-refactor)
  - [MDTablewrap](#mdtablewrap)

---

## Important Bugs

- Neotree soll keine iegne statusline haben
- Makros funktionieren nicht

### LSP - AUDIT: Ist bereits implementiert.

 - Die @types und types dateien werden nicht gut erkannt.
    ---> Besser mal mit types.lua probeiren, aber das sollte eigentlich keinen Unterschied machen

--

## bugs

- `recommender -r`
    1. Preview funktioniert, aber zeigt falsche Zeilen an.
    2. Außerdem kein highlight.
    3. Da zuerst die nuee local variable eingefügt und dann replacer ausgeführt wird, taucht die neue local immer im replacer results auf. das kann man leicht verhindern, indem zuerst replacer ausgeführt wird und als abschluss - nur wenn auch wirklich ein replace durchgeführt wurde (wenn möglich) - dann erst die neue local einfügen.

---

## Eigene Plugins

### neotree-fs-refactor

05:32:36 msg_show [neotree-fs-refactor] Event handlers registered
[neotree-fs-refactor] [neotree-fs-refactor] Plugin loaded successfully
[LuaProjectFileStats] LuaFileStats commands registered
[github-stats] Fetch interval not elapsed (use 'force' to bypass)
E5108: Error executing lua: ...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:803: attempt to index local 'tree' (a nil value)
stack traceback:
...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:803: in function 'open_with_cmd'
...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:849: in function 'open'
...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:209: in function <...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:208>
05:32:41 msg_showcmd ^W^W

---

