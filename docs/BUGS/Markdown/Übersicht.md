# Custom Markdown Bug Index

## CRITICAL Bugs

Titel:
Modul:
Kurzbeschreibung: `<leader>[` löst folgenen Fehler aus:
Status:
Reproduzierbar:
Plattform:
Detaildokument:
Fehlermeldung:

```vim
  Error  17:55:34 msg_show.emsg E5108: [Error]() executing lua: ...a/Local/nvim/lua/custom/markdown/core/wrap_link/init.lua:123: Invalid 'end_col': out of range
stack traceback:
[C]: in function 'nvim_buf_set_text'
...a/Local/nvim/lua/custom/markdown/core/wrap_link/init.lua:123: in function <...a/Local/nvim/lua/custom/markdown/core/wrap_link/init.lua:98>
```


---

## IMPORTANT Bugs


---

## NORMAL Bugs

---


## Long view

---


## Notes

### Module Metadaten

Projekt: ________
Stand: YYYY-MM-DD



### Legende

Severity:
* CRITICAL – blockiert Editor oder führt zu Datenverlust
* IMPORTANT – stark störend, aber mit Workaround
* NORMAL – reproduzierbar, aber begrenzt
* LOW – kosmetisch oder selten

Status:
* OPEN – bekannt, ungelöst
* WIP – Analyse oder Fix in Arbeit
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
Fehlermeldung?:

```vim

```
---
