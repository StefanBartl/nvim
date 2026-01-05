# Diff-Konfiguration in `options.lua`: saubere Implementierung mit Profilen

## Table of content

  - [Zielsetzung](#zielsetzung)
  - [Grundprinzip](#grundprinzip)
  - [Empfohlene Struktur in `options.lua`](#empfohlene-struktur-in-optionslua)
    - [1. Diff-Profile definieren](#1-diff-profile-definieren)
  - [2. Zentrale Setter-Funktion](#2-zentrale-setter-funktion)
  - [3. Default-Profil setzen](#3-default-profil-setzen)
  - [4. Optional: Umschaltung zur Laufzeit](#4-optional-umschaltung-zur-laufzeit)
    - [Variante A: Manuell in Lua](#variante-a-manuell-in-lua)
    - [Variante B: Exponieren über `vim.g`](#variante-b-exponieren-ber-vimg)
    - [Variante C: User Commands (optional, aber praktisch)](#variante-c-user-commands-optional-aber-praktisch)
  - [5. Empfohlene begleitende Fensteroptionen (optional)](#5-empfohlene-begleitende-fensteroptionen-optional)
  - [Typische Fehler, die diese Lösung vermeidet](#typische-fehler-die-diese-lsung-vermeidet)
  - [Ergebnis](#ergebnis)
  - [Literatur](#literatur)

---

## Zielsetzung

* zentrale, saubere Diff-Vorkonfiguration
* mehrere **vordefinierte Profile** (minimal, context, review, strict …)
* Umschaltung über **lokale Variable oder Funktionsaufruf**
* vollständig Lua-basiert, ohne `:set`-Strings
* kompatibel mit `diffthis`, `diffsplit`, Fugitive, Diffview

---

## Grundprinzip

`diffthis` setzt lediglich `:setlocal diff`.
Das Verhalten wird ausschließlich über die **globale Option** `vim.o.diffopt` bestimmt.

Daher:

* Diff-Profile → schreiben nach `vim.o.diffopt`
* Umschalten → explizite Funktion
* Default-Profil → beim Laden der Options-Datei setzen

---

## Empfohlene Struktur in `options.lua`

### 1. Diff-Profile definieren

```lua
-----------------------------------------------------------
-- Diff profiles
-----------------------------------------------------------

---@alias DiffProfile
---| '"minimal"'
---| '"context"'
---| '"review"'
---| '"strict"'

---@type table<DiffProfile, string[]>
local diff_profiles = {

  -- Minimal, schnell, alltagstauglich
  minimal = {
    "internal",
    "filler",
    "closeoff",
    "vertical",
    "linematch:60",
    "algorithm:histogram",
    "indent-heuristic",
    "iwhite",
  },

  -- Reduzierter Kontext für fokussierte Reviews
  context = {
    "internal",
    "filler",
    "closeoff",
    "vertical",
    "context:3",
    "linematch:60",
    "algorithm:patience",
    "indent-heuristic",
    "iwhite",
  },

  -- Ausführlicher Review mit mehr Kontext
  review = {
    "internal",
    "filler",
    "closeoff",
    "vertical",
    "context:8",
    "linematch:80",
    "algorithm:histogram",
    "indent-heuristic",
    "iwhite",
  },

  -- Streng: alles anzeigen, nichts ignorieren
  strict = {
    "internal",
    "filler",
    "closeoff",
    "vertical",
    "linematch:80",
    "algorithm:myers",
    "indent-heuristic",
  },
}
```

---

## 2. Zentrale Setter-Funktion

Diese Funktion ist **bewusst lokal** zur Datei gehalten, kann aber problemlos exportiert werden.

```lua
-----------------------------------------------------------
-- Diff profile selector
-----------------------------------------------------------

---@param profile DiffProfile
local function set_diff_profile(profile)
  local opts = diff_profiles[profile]

  if not opts then
    error(("Unknown diff profile: %s"):format(profile))
  end

  -- Join list into a valid diffopt string
  vim.o.diffopt = table.concat(opts, ",")
end
```

Warum so?

* kein mehrfaches `+=`
* kein Altbestand in `diffopt`
* deterministisches Verhalten
* leicht erweiterbar

---

## 3. Default-Profil setzen

Am Ende des Diff-Blocks oder der Datei:

```lua
-- Default diff profile
set_diff_profile("minimal")
```

Damit ist sichergestellt:

* jeder `diffthis`
* jeder `diffsplit`
* jedes Git-Diff

verwendet sofort konsistente Optionen.

---

## 4. Optional: Umschaltung zur Laufzeit

### Variante A: Manuell in Lua

```lua
set_diff_profile("context")
```

### Variante B: Exponieren über `vim.g`

```lua
vim.g.set_diff_profile = set_diff_profile
```

Dann nutzbar via:

```vim
:lua vim.g.set_diff_profile("review")
```

---

### Variante C: User Commands (optional, aber praktisch)

```lua
vim.api.nvim_create_user_command("DiffProfile", function(opts)
  set_diff_profile(opts.args)
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(diff_profiles)
  end,
})
```

Verwendung:

```vim
:DiffProfile minimal
:DiffProfile context
:DiffProfile review
```

---

## 5. Empfohlene begleitende Fensteroptionen (optional)

Diese sind **nicht Teil von `diffopt`**, aber oft sinnvoll:

```lua
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "diff",
  callback = function()
    if vim.wo.diff then
      vim.wo.wrap = false
      vim.wo.cursorbind = false
    end
  end,
})
```

---

## Typische Fehler, die diese Lösung vermeidet

* Vermischung von alten und neuen `diffopt`-Werten
* `set diffopt+=...` in Lua (fehleranfällig)
* Inline-Strings ohne Validierung
* Profilwechsel ohne Reset

---

## Ergebnis

* klar strukturierte Diff-Konfiguration
* reproduzierbares Verhalten
* einfache Erweiterbarkeit
* perfekte Grundlage für `diffthis`, Fugitive, Diffview
* vollständig Lua-idiomatisch

---

## Literatur

* `:h diffthis`
* `:h diffopt`
* `:h linematch`
* `:h algorithm`
* `:h indent-heuristic`

---
