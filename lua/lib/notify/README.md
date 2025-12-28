# `lib.notify`

## Beispiel: Verwendung in einem Modul

```lua
---@module 'neotree_fs_refactor.core'

local notify = require("lib.notify").create("[neotree-fs-refactor]")

notify.info("Refactor started")
notify.warn("Some paths could not be updated")
notify.error("LSP rename failed")
```

---

## Beispiel: anderes Modul, anderer Prefix

```lua
---@module 'config.lsp.setup'

local notify = require("lib.notify").create("[lsp]")

notify.debug("Attaching server")
```

---

## Eigenschaften des Designs

* ein zentrales, generisches Notify-Modul
* Prefix wird **einmal pro Datei** festgelegt
* kein doppeltes Prefixing möglich
* API identisch zu `vim.notify`
* problemlos für jede Plugin- oder Config-Komponente wiederverwendbar

---
