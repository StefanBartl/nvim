# `filetree.nvim`

## Table of content

  - [Features](#features)
  - [Bug](#bug)
  - [Filetree Manager spezifische Features](#filetree-manager-spezifische-features)
      - [sources](#sources)

---

## Features

- Aktionen wie delete, das auf vele files angewendet weden kann -> lib.nvim progress modul einbauen (statusline integration wäre ideal)

---

## Bug

---

## Filetree Manager spezifische Features

> neotree, nvimtre, netrwq, oil, minifiles spezifische features sammeln (features, die diese plugins selbst anbieten)

---

#### sources

| **sources/ + icons/** | Lazy Source Registry, 3 Icon-Familien (nerd/codicons/common), responsive Größe |

`sources`-Feature von neotree nachbilden — 🔲 **Phase 4, niedrige Priorität.** Verifiziert: `lua/config/neotree/sources/registry.lua` ist aktuell ein simpler Lazy-Loader (register/load/is_loaded/list), kein Template-System — der Wunsch existiert im Code noch nicht. Statt eines vollen Template-Engines: erstmal eine kleine Recipe-/Copy-Paste-Config-Sammlung (2-3 gängige Source-Setups) im `filetree.nvim`-README oder `docs/` — deckt den eigentlichen Schmerzpunkt ("Einrichtung war Pain") günstiger ab als ein neues System.

Feedback: Es wäre aber super, wenn jemand filetree.nvim verwendet und neotreee als engine benutzt, dass man dann in der filetree.nvim user config (spec) die sources einfach enablen/disablen kann

---

