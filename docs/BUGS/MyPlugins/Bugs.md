# Eigene nvim PLugins - Bug Index

## Table of content

  - [CRITICAL Bugs](#critical-bugs)
  - [IMPORTANT Bugs](#important-bugs)
    - [neotree-fs-refactor](#neotree-fs-refactor)
  - [NORMAL Bugs](#normal-bugs)
  - [Long view](#long-view)
  - [Notes](#notes)
    - [Legende](#legende)
    - [__TITEL__ (Template)](#titel__-template)

---

## CRITICAL Bugs

- GithubStats

--

## IMPORTANT Bugs

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

## NORMAL Bugs

---


## Long view

---


## Notes

### Legende

Severity:
* CRITICAL – blockiert Editor oder führt zu Datenverlust
* IMPORTANT – stark störend, aber mit Workaround
* NORMAL – reproduzierbar, aber begrenzt
* LOW – kosmetisch oder selten

Status:
* OPEN – bekannt, ungelöst
* WIP – Analyse oder Fix in Arbeit
* AUDIT: Fix angewendet, in Beobachtung
* FIXED – gelöst, wartet auf Cleanup
* WONTFIX – bewusst nicht gelöst
* UPSTREAM – Bug liegt in externem Plugin

---

###  __TITEL__ (Template)

Modul:
Kurzbeschreibung:
Status:
Reproduzierbar:
Plattform:
Detaildokument:
Fehlermeldung?:

```vim

```

---
