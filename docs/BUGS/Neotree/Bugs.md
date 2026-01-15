# Neo-tree Bug Index

## Table of content

- [Neo-tree Bug Index](#neo-tree-bug-index)
  - [IMPORTANT Bugs](#important-bugs)
  - [NORMAL Bugs](#normal-bugs)
  - [Long view](#long-view)
  - [Notes](#notes)
    - [Legende](#legende)
    - [Template](#template)

---

## IMPORTANT Bugs

`]r`
   Error  22:37:48 msg_show.emsg E5108: Error executing lua: Vim:E117: Unknown function: cwd
stack traceback:
	[C]: in function 'cwd'
	...rtl/AppData/Local/nvim/lua/config/neotree/utils/path.lua:124: in function 'from_node'
	...ata/Local/nvim/lua/config/neotree/keymaps/filesystem.lua:373: in function <...ata/Local/nvim/lua/config/neotree/keymaps/filesystem.lua:366>

`[f` ist nicht korrekt

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

### Template

Titel:
Modul:
Kurzbeschreibung:
Status:
Reproduzierbar:
Plattform:
Detaildokument:

---

