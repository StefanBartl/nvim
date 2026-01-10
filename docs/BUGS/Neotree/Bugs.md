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

 Eine file, die offen war, im neotree zu löschen löst machmal aus:

```vim
   Error  16:07:11 notify.error [neotree.trash] Operation denied: path is open in buffer: C:\Users\bartl\AppData\Local\nvim\lua\usrcmds\migrate\notify\refactor.lua
```

In Neotree sources finde ich diesen buffer aber nicht. Es wäre gut, wenn es möglch wäre, diesen buffer zu finden und das dieser dnn automatisch beim delete vorgang gesclossen wird, damit das delete durchgeführt werden kann.

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

