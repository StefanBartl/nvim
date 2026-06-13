# Markdown Links Module (Neovim)

Erzeugt Markdown-Links aus Dateien und Verzeichnissen direkt aus Neovim heraus. Unterstützt rekursive Traversierung, Filterung, Root-Prefixing und automatische Zwischenablage-Integration.

---

## Table of content

- [Markdown Links Module (Neovim)](#markdown-links-module-neovim)
  - [Features](#features)
  - [Usage](#usage)
    - [Basic](#basic)
    - [Directory](#directory)
    - [Recursive](#recursive)
    - [Ignore deaktivieren](#ignore-deaktivieren)
    - [Root Prefix](#root-prefix)
    - [Kombination](#kombination)
  - [Neo-tree Integration](#neo-tree-integration)
  - [Architektur](#architektur)
    - [Command Layer](#command-layer)
    - [Module Struktur](#module-struktur)
  - [Behavior Notes](#behavior-notes)
    - [Default Ignore](#default-ignore)
    - [Clipboard Behavior](#clipboard-behavior)

---

## Features

- Einzelne Dateien → Markdown-Link
- Verzeichnisse → Batch-Link-Generierung
- Rekursive Traversierung (`-r`, `--recursive`)
- Default Ignore (`.git`, `node_modules`, `.DS_Store`)
- Ignore deaktivierbar (`--noignore`)
- Root-Prefixing (`--root <path|$ENV>`)
- Ausgabe + automatische Clipboard-Kopie
- Neo-tree Integration möglich (`ml`)

---

## Usage

### Basic

```vim
:Markdown links <path>
````

Beispiel:

```vim
:Markdown links ~/notes/file.md
```

---

### Directory

```vim
:Markdown links ~/notes
```

Erzeugt Links für alle Dateien im Ordner (nicht rekursiv).

---

### Recursive

```vim
:Markdown links -r ~/notes
```

Durchläuft alle Unterordner rekursiv.

---

### Ignore deaktivieren

```vim
:Markdown links --noignore ~/notes
```

Inklusive `.git`, `node_modules` und weiterer systemtypischer Ordner.

---

### Root Prefix

```vim
:Markdown links --root $HOME/vault ~/notes/file.md
```

Der Root-Pfad wird vor dem Zielpfad eingefügt.

---

### Kombination

```vim
:Markdown links -r --noignore --root $HOME/vault ~/notes
```

---

## Neo-tree Integration

Wenn im Neo-tree ein Node aktiv ist:

```text
ml
```

Erzeugt Markdown-Links aus dem aktuellen Node (Datei oder Ordner).

---

## Architektur

### Command Layer

```text
:Markdown
  └── links
```

Dispatcher-Pattern:

* Neue Features = neue Module
* Kein Umbau bestehender Commands nötig

---

### Module Struktur

```text
custom/markdown/
├── commands/
│   ├── markdown_links.lua
│   ├── init.lua
│   └── ...
├── util/
│   └── clipboard.lua
└── setup/
    └── usercmds.lua
```

---

## Behavior Notes

### Default Ignore

Folgende Ordner werden standardmäßig ignoriert:

* `.git`
* `node_modules`
* `.DS_Store`

---

### Clipboard Behavior

Nach Ausführung:

* Ausgabe im Command Output
* Kopie in `+` und `*` Register

---

