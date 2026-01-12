# :Copy – Pfade flexibel kopieren
-

## Table of content

- [:Copy – Pfade flexibel kopieren](#copy-pfade-flexibel-kopieren)
  - [Ziel](#ziel)
  - [Überblick: :Copy path](#berblick-copy-path)
  - [Semantik im Detail](#semantik-im-detail)
    - [1. Modus](#1-modus)
    - [2. Basis (`relative`)](#2-basis-relative)
    - [3. Zieltyp](#3-zieltyp)
    - [4. Zielpfad](#4-zielpfad)
  - [Beispiele](#beispiele)
  - [Erweiterungsideen (bewusst vorbereitet)](#erweiterungsideen-bewusst-vorbereitet)
  - [Fazit](#fazit)

---

## Ziel

`:Copy` ist ein modulares UserCommand, das Pfade aus dem aktuellen Buffer oder aus explizit angegebenen Dateien/Verzeichnissen berechnet und **in die Zwischenablage kopiert**.
Der Fokus liegt auf:

* reproduzierbaren relativen Pfaden
* klarer Semantik
* erweiterbarer Struktur (ähnlich wie `:Insert`)

---

## Überblick: :Copy path

Grundform:

```
:Copy path [relative|absolute] [<base>] [file|dir] [<target>]
```

Default-Verhalten bei:

```
:Copy path
```

* Modus: `relative`
* Basis: `cwd`
* Ziel: aktuelle Datei (`%`)
* Ausgabe: relativer Dateipfad zum aktuellen Arbeitsverzeichnis

---

## Semantik im Detail

### 1. Modus

* `relative` (Default)
* `absolute`

---

### 2. Basis (`relative`)

Die Basis bestimmt, **wovon aus** der relative Pfad berechnet wird.

Möglichkeiten:

a) `cwd` (Default, implizit)

```
:Copy path relative
```

b) Parent-Level (Zahl)

```
:Copy path relative 2
```

→ relativ zum 2. Parent-Verzeichnis der Zieldatei

Beispiel:

```
C:/Users/bartl/AppData/Local/nvim/lua/ui/test.lua
```

`relative 2` → Basis = `.../Local/nvim`

c) Expliziter Pfad

```
:Copy path relative C:/Users/bartl/AppData/Local/
```

---

### 3. Zieltyp

* `file` (Default)
* `dir` → Verzeichnis der Datei

---

### 4. Zielpfad

* `%` oder leer → aktueller Buffer
* expliziter Pfad

Beispiel:

```
:Copy path relative C:/Users/bartl/AppData/Local/ file C:/Users/bartl/AppData/Local/nvim/lua/ui/moving/help.lua
```

→ relativer Pfad von `Local` zu `help.lua`

---

## Beispiele

```
:Copy path
```

→ `lua/ui/test.lua`

```
:Copy path absolute
```

→ `C:/Users/bartl/AppData/Local/nvim/lua/ui/test.lua`

```
:Copy path relative 3 dir
```

→ relativer Pfad zum 3. Parent-Ordner (Verzeichnis)

```
:Copy path relative C:/Users/bartl/AppData/Local file
```

→ `nvim/lua/ui/test.lua`

```
:Copy path relative 2 file C:/other/file.lua
```

→ relativer Pfad von Parent-Level-2 zu externer Datei

---

## Erweiterungsideen (bewusst vorbereitet)

* `:Copy path lua` → Lua-Modulpfad
* `:Copy path url` → file:// URL
* `:Copy path win/unix`
* `:Copy name` → nur Dateiname
* `:Copy tree` → Verzeichnisstruktur

die Struktur ist absichtlich so gewählt, dass neue Subcommands einfach ergänzt werden können.

---

## Fazit

`:Copy` ist:

* reload-sicher
* lua_ls-freundlich
* plattformübergreifend
* strikt deterministisch
* konsistent zu `:Insert`

und eignet sich als zentrale Schnittstelle für alle „Pfad kopieren“-Workflows in Neovim.

---
