# lib.lazy – Wiederverwendbares Lazy-Loading für Neovim

Dieses Modul stellt einfache Hilfsfunktionen bereit, um Lua-Module in einer
Neovim-Config oder in eigenen Plugins kontrolliert und lazy zu laden.

Ziel ist es, unnötige `require()`-Aufrufe beim Startup zu vermeiden und Module
erst dann zu laden, wenn sie tatsächlich benötigt werden.

---

## Table of content

  - [Motivation](#motivation)
  - [API](#api)
    - [lazy.module(name)](#lazymodulename)
    - [lazy.fn(module, function_name)](#lazyfnmodule-function_name)
  - [Performance-Abschätzung](#performance-abschtzung)
    - [Startup](#startup)
    - [Laufzeit](#laufzeit)
  - [Sicherheit und Korrektheit](#sicherheit-und-korrektheit)
  - [Wann man es nicht einsetzen sollte](#wann-man-es-nicht-einsetzen-sollte)
  - [Typische Einsatzgebiete](#typische-einsatzgebiete)
  - [Fazit](#fazit)

---

## Motivation

In vielen Neovim-Konfigurationen werden Module direkt im Filescope geladen:

```
local mod = require("heavy.module")
```

Das bedeutet:

* das Modul wird immer beim Laden der Datei ausgeführt
* auch wenn die zugehörige Funktion nie benutzt wird
* Startup-Zeit und Speicherverbrauch steigen mit der Config-Größe

`lib.lazy` erlaubt es, dieses Verhalten explizit zu kontrollieren.

---

## API

### lazy.module(name)

Erzeugt einen Lazy-Wrapper für ein Modul.

```lua
local lazy = require("lib.lazy")
local mymod = lazy.module("mymodule")

mymod.get().do_work()
```

Eigenschaften:

* `require()` wird exakt einmal ausgeführt
* Ergebnis wird in einem Upvalue gecached
* nach dem ersten Zugriff minimaler Overhead (Nil-Check)

---

### lazy.fn(module, function_name)

Erzeugt einen lazy geladenen Funktions-Wrapper.

```lua
local lazy = require("lib.lazy")
local do_work = lazy.fn("mymodule", "do_work")

do_work(42)
```

Eigenschaften:

* `require()` läuft beim ersten Aufruf
* danach wird die Funktion neu gebunden
* kein weiterer Lazy-Check im Hot-Path

Diese Variante ist aggressiver und nur für Performance-kritische Pfade gedacht.

---

## Performance-Abschätzung

### Startup

* kein Laden des Moduls beim Start
* weniger Lua-Bytecode
* weniger Initialisierung von Nebenlogik (Autocommands, Caches)

### Laufzeit

* `lazy.module`:
  * ein einfacher Nil-Check pro Zugriff
  * vernachlässigbarer Overhead für die meisten Use-Cases
* `lazy.fn`:
  * nach dem ersten Aufruf keinerlei Zusatzkosten

Im Vergleich zu eager `require()` ist der Gesamteffekt in großen Configs
spürbar positiv, besonders bei vielen optionalen Features.

---

## Sicherheit und Korrektheit

* `require()` wird nicht umgangen, sondern nur verzögert
* Lua-Standard-Caching (`package.loaded`) bleibt vollständig erhalten
* Fehler im Modul treten beim ersten Zugriff auf, nicht stillschweigend
* keine globale Mutation, nur lokale Upvalues

Das Verhalten ist deterministisch und reproduzierbar.

---

## Wann man es nicht einsetzen sollte

* bei sehr kleinen Utility-Modulen
* bei Funktionen, die auf jedem Keypress laufen
* bei Code, der bewusst beim Startup Seiteneffekte erzeugen soll

Lazy-Loading ist ein Werkzeug, kein Dogma.

---

## Typische Einsatzgebiete

* Feature-spezifische Logik
* Event-Handler
* Neo-tree / LSP / Git-Integrationen
* eigene Plugins mit optionalen Komponenten

---

## Fazit

`lib.lazy` hilft dabei, Neovim-Konfigurationen:

* strukturierter
* performanter
* besser skalierbar

zu gestalten, ohne komplexe Infrastruktur oder externe Abhängigkeiten.

---
