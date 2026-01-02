# Neo-tree Bug Index

## Table of content

  - [IMPORTANT Bugs](#important-bugs)
    - [1. EPERM Error friert [Neovim](./BUG-002.md) ein](#1-eperm-error-friert-neovimbug-002md-ein)
    - [2. Invalid window Error nach Renaming](#2-invalid-window-error-nach-renaming)
  - [NORMAL Bugs](#normal-bugs)
    - [1. Neo-tree fällt auf CWD root zurück](#1-neo-tree-fllt-auf-cwd-root-zurck)
    - [2. Linker Neo-tree schließt und öffnet rechts](#2-linker-neo-tree-schliet-und-ffnet-rechts)
  - [Long view](#long-view)
  - [Notes](#notes)
    - [Legende](#legende)
    - [Template](#template)

---

## IMPORTANT Bugs

- errorm meldung stimmt nicht:
  Error  22:40:54 notify.error [neotree.trash] Operation denied: path is open in buffer: C:\Users\bartl\AppData\Local\nvim\lua\config\neotree\sources\dynamic.lua

### 1. EPERM Error friert Neovim ein

Modul: neo-tree.nvim – filesystem, fs_watch
Kurzbeschreibung: Dateioperationen triggern File-Watcher in inkonsistentem Zustand, was zu EPERM-Fehlern, Hängern und Spam-Notifications führt.
Status: WIP
Reproduzierbar: häufig
Plattform: Windows
Detaildokument:  [BUG-001](./BUG-001.md), [Analyse](./BUG-001-Analyse.md)

---

### 2. Invalid window Error nach Renaming

Modul: neo-tree.nvim / nui.nvim – tree, debounce
Kurzbeschreibung: Ungültige Window-Handles werden nach Rename weiterverwendet und führen zu Runtime-Errors.
Status: FIXED
Reproduzierbar: häufig vor Fix
Plattform: Windows
Detaildokument: [BUG-002](./BUG-002.md)

---

## NORMAL Bugs

### 1. Neo-tree fällt auf CWD root zurück

Modul: neo-tree.nvim – filesystem follow / reveal
Kurzbeschreibung: Automatisches Follow überschreibt manuelle Navigation und setzt den Tree auf Root oder CWD zurück.
Status: AUDIT
Reproduzierbar: häufig
Plattform: alle
Detaildokument: [BUG-004](./BUG-004.md)

---

### 2. Linker Neo-tree schließt und öffnet rechts

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

