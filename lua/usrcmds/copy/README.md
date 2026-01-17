# :Copy – Pfade flexibel kopieren

## Table of content

- [:Copy – Pfade flexibel kopieren](#copy-pfade-flexibel-kopieren)
  - [Ziel](#ziel)
  - [Überblick: :Copy path](#überblick-copy-path)
  - [Semantik im Detail](#semantik-im-detail)
    - [1. Modus](#1-modus)
    - [2. Basis (bei `relative`)](#2-basis-bei-relative)
    - [3. Zieltyp](#3-zieltyp)
    - [4. Zielpfad](#4-zielpfad)
    - [5. Separator](#5-separator)
    - [6. Spezielle Modi](#6-spezielle-modi)
  - [Beispiele](#beispiele)
    - [Basis-Verwendung](#basis-verwendung)
    - [Neovim-spezifisch](#neovim-spezifisch)
    - [Custom Separator](#custom-separator)
  - [Erweiterungsideen (bewusst vorbereitet)](#erweiterungsideen-bewusst-vorbereitet)
  - [Vollständige Argument-Referenz](#vollständige-argument-referenz)
  - [Fazit](#fazit)

---

## Ziel

`:Copy` ist ein modulares UserCommand, das Pfade aus dem aktuellen Buffer oder aus explizit angegebenen Dateien/Verzeichnissen berechnet und **in die Zwischenablage kopiert**.

Der Fokus liegt auf:

* reproduzierbaren relativen Pfaden
* klarer Semantik
* erweiterbarer Struktur (ähnlich wie `:Insert`)
* Neovim-spezifischen Workflows

---

## Überblick: :Copy path

Grundform:
```vim
:Copy path [relative|absolute] [<base>] [file|dir] [<target>] [sep <separator>]
```

Default-Verhalten bei:
```vim
:Copy path
```

* Modus: `relative`
* Basis: `cwd`
* Ziel: aktuelle Datei (`%`)
* Separator: `/`
* Ausgabe: relativer Dateipfad zum aktuellen Arbeitsverzeichnis

---

## Semantik im Detail

### 1. Modus

* `relative` (Default) – Relativer Pfad zur Basis
* `absolute` – Absoluter Pfad

---

### 2. Basis (bei `relative`)

Die Basis bestimmt, **wovon aus** der relative Pfad berechnet wird.

**Möglichkeiten:**

**a) `cwd` (Default, implizit)**
```vim
:Copy path relative
```

**b) Parent-Level (Zahl)**
```vim
:Copy path relative 2
```

→ relativ zum 2. Parent-Verzeichnis der Zieldatei

Beispiel:
```
C:/Users/bartl/AppData/Local/nvim/lua/ui/test.lua
```

`relative 2` → Basis = `.../Local/nvim`

**c) Expliziter Pfad**
```vim
:Copy path relative C:/Users/bartl/AppData/Local/
```

---

### 3. Zieltyp

* `file` (Default) – Datei
* `dir` – Verzeichnis der Datei

---

### 4. Zielpfad

* `%` oder leer → aktueller Buffer
* expliziter Pfad

Beispiel:
```vim
:Copy path relative C:/Users/bartl/AppData/Local/ file C:/Users/bartl/AppData/Local/nvim/lua/ui/moving/help.lua
```

→ relativer Pfad von `Local` zu `help.lua`

---

### 5. Separator

Standardmäßig wird `/` als Pfadtrenner verwendet. Dies kann geändert werden:
```vim
:Copy path sep .
:Copy path separator \
```

**Verwendung:**
```vim
:Copy path relative sep .
```

→ `lua.ui.test` (für Windows-Style)
```vim
:Copy path absolute sep \
```

→ `C:\Users\bartl\AppData\Local\nvim\lua\ui\test.lua`

---

### 6. Spezielle Modi

#### a) `nvim` – Relativ zu Neovim-Config
```vim
:Copy path nvim
```

* Prüft, ob Datei in `stdpath('config')` liegt
* Gibt relativen Pfad zu Config-Root zurück
* Warnung, wenn Datei außerhalb

**Beispiel:**
```
Datei: ~/.config/nvim/lua/plugins/lsp.lua
Ausgabe: lua/plugins/lsp.lua
```

#### b) `nvim_module` – Lua-Modulpfad
```vim
:Copy path nvim_module
```

* Konvertiert Dateipfad zu Lua-Modulpfad
* Separator: `.` (Punkt)
* Nur für Dateien in `lua/`-Verzeichnissen

**Beispiel:**
```
Datei: ~/.config/nvim/lua/plugins/lsp.lua
Ausgabe: plugins.lsp
```
```
Datei: ~/.config/nvim/lua/lib/notify/init.lua
Ausgabe: lib.notify
```

---

## Beispiele

### Basis-Verwendung
```vim
:Copy path
```

→ `lua/ui/test.lua`
```vim
:Copy path absolute
```

→ `C:/Users/bartl/AppData/Local/nvim/lua/ui/test.lua`
```vim
:Copy path relative 3 dir
```

→ relativer Pfad zum 3. Parent-Ordner (Verzeichnis)
```vim
:Copy path relative C:/Users/bartl/AppData/Local file
```

→ `nvim/lua/ui/test.lua`

### Neovim-spezifisch
```vim
:Copy path nvim
```

→ `lua/plugins/telescope.lua` (wenn in Config)
```vim
:Copy path nvim_module
```

→ `plugins.telescope`

### Custom Separator
```vim
:Copy path nvim sep .
```

→ `lua.plugins.telescope.lua`
```vim
:Copy path absolute sep \
```

→ `C:\Users\bartl\AppData\Local\nvim\lua\plugins\telescope.lua`
```vim
:Copy path nvim_module
```

→ `plugins.telescope` (immer `.` als Separator)

---

## Erweiterungsideen (bewusst vorbereitet)

* `:Copy path url` → `file://` URL
* `:Copy path win/unix` → Plattform-spezifisch
* `:Copy name` → nur Dateiname
* `:Copy tree` → Verzeichnisstruktur

Die Struktur ist absichtlich so gewählt, dass neue Subcommands einfach ergänzt werden können.

---

## Vollständige Argument-Referenz

| Argument       | Typ       | Bedeutung                                     |
|----------------|-----------|-----------------------------------------------|
| `relative`     | Modus     | Relativer Pfad (Default)                      |
| `absolute`     | Modus     | Absoluter Pfad                                |
| `nvim`         | Special   | Relativ zu `stdpath('config')`                |
| `nvim_module`  | Special   | Lua-Modulpfad (`.` als Separator)             |
| `0-5`          | Basis     | Parent-Level (Zahl)                           |
| `<path>`       | Basis     | Expliziter Basispfad                          |
| `file`         | Zieltyp   | Datei (Default)                               |
| `dir`          | Zieltyp   | Verzeichnis                                   |
| `sep <char>`   | Separator | Custom Pfadtrenner                            |
| `separator <char>` | Separator | Alias für `sep`                           |

---

## Fazit

`:Copy` ist:

* reload-sicher
* lua_ls-freundlich
* plattformübergreifend
* strikt deterministisch
* konsistent zu `:Insert`
* **Neovim-aware** (Config-Pfade, Lua-Module)

und eignet sich als zentrale Schnittstelle für alle „Pfad kopieren"-Workflows in Neovim.

---
