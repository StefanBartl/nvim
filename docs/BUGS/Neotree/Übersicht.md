# Neo-tree Bug Index

## Table of content

  - [CRITICAL Bugs](#critical-bugs)
  - [IMPORTANT Bugs](#important-bugs)
  - [NORMAL Bugs](#normal-bugs)
  - [Long view](#long-view)
  - [Notes](#notes)
    - [Module Metadaten](#module-metadaten)
    - [Legende](#legende)
    - [Template](#template)

---

## CRITICAL Bugs

Titel: Preview Error (truth field nil)
Modul: neo-tree.nvim – sources/common/preview.lua
Kurzbeschreibung: Preview- und Open-Operationen brechen vollständig ab, wenn Neo-tree das einzige oder letzte valide Window ist.
Status: WIP
Reproduzierbar: ja, unter bestimmten Window-Layouts
Plattform: alle
Detaildokument: [BUG-003](./BUG-003.md)

---

## IMPORTANT Bugs

Titel: EPERM Error friert [Neovim](./BUG-002.md) ein
Modul: neo-tree.nvim – filesystem, fs_watch
Kurzbeschreibung: Dateioperationen triggern File-Watcher in inkonsistentem Zustand, was zu EPERM-Fehlern, Hängern und Spam-Notifications führt.
Status: WIP
Reproduzierbar: häufig
Plattform: Windows
Detaildokument: BUG-001](./BUG-002.md)

---

Titel: Invalid window Error nach Renaming
Modul: neo-tree.nvim / nui.nvim – tree, debounce
Kurzbeschreibung: Ungültige Window-Handles werden nach Rename weiterverwendet und führen zu Runtime-Errors.
Status: FIXED
Reproduzierbar: häufig vor Fix
Plattform: Windows
Detaildokument: [BUG-002](./BUG-002.md)

---

## NORMAL Bugs

Titel: Neo-tree fällt auf CWD root zurück
Modul: neo-tree.nvim – filesystem follow / reveal
Kurzbeschreibung: Automatisches Follow überschreibt manuelle Navigation und setzt den Tree auf Root oder CWD zurück.
Status: OPEN
Reproduzierbar: häufig
Plattform: alle
Detaildokument: [BUG-004](./BUG-004.md)

---

Titel: Linker Neo-tree schließt und öffnet rechts
Modul: neo-tree.nvim – UI / window placement
Kurzbeschreibung: Neo-tree verliert seine linke Dock-Position und wird rechts neu geöffnet.
Status: OPEN
Reproduzierbar: sporadisch
Plattform: alle
Detaildokument: [BUG-005](./BUG-005.md)

---

## Long view

* Mehrere Bugs haben gemeinsame Ursachen in Race-Conditions zwischen UI-State, Window-Lifecycle und asynchronen Operationen.
* File-Watcher und Debounce-Mechanismen reagieren zu früh auf transienten Zustand.
* Mehrere Codepfade setzen implizit gültige Window-Handles oder Preview-Targets voraus.
* Windows-spezifisches Filesystem-Verhalten (Locking, Delays) verstärkt die Probleme deutlich.

---

## Notes

### Module Metadaten

Projekt: neo-tree.nvim
Stand: 2025-12-31

---

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

---

