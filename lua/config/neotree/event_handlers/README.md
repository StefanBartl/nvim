# Neo-tree Event Handler Modul

Dieses Modul enthält zentrale Event-Handler für Neo-tree in Neovim.
Es ermöglicht ein konsistentes Verhalten des Cursors, Fensterfokus und weitere Anpassungen beim Arbeiten mit Neo-tree.

## Table of content

- [Neo-tree Event Handler Modul](#neo-tree-event-handler-modul)
  - [Installation](#installation)
  - [Event Handler Übersicht](#event-handler-bersicht)
    - [1. `neo_tree_buffer_enter`](#1-neo_tree_buffer_enter)
    - [2. `neo_tree_buffer_leave`](#2-neo_tree_buffer_leave)
    - [3. `neo_tree_window_before_open`](#3-neo_tree_window_before_open)
    - [4. `neo_tree_window_after_open`](#4-neo_tree_window_after_open)
  - [Interne Hilfsfunktionen](#interne-hilfsfunktionen)
    - [`is_float(winid)`](#is_floatwinid)
  - [Anpassungen](#anpassungen)

---

## Installation

In der `plugins/neotree.lua` kann das Modul eingebunden werden:

```lua
require("neo-tree").setup({
  event_handlers = require("config.neotree.event_handlers"),
})
````

---

## Event Handler Übersicht

### 1. `neo_tree_buffer_enter`

* **Beschreibung:** Wird ausgelöst, wenn ein Neo-tree-Puffer betreten wird.
* **Effekt:** Der Cursor wird unsichtbar, um den Fokus auf den Baum selbst zu legen.
* **Implementierung:**

```lua
vim.cmd("highlight! Cursor blend=100")
```

---

### 2. `neo_tree_buffer_leave`

* **Beschreibung:** Wird ausgelöst, wenn ein Neo-tree-Puffer verlassen wird.
* **Effekt:** Der Cursor wird in normalen Buffern wieder sichtbar.
* **Implementierung:**

```lua
vim.cmd("highlight! Cursor guibg=#5f87af blend=0")
```

---

### 3. `neo_tree_window_before_open`

* **Beschreibung:** Wird ausgelöst, bevor ein Neo-tree-Fenster geöffnet wird.
* **Effekt:** Speichert das aktuell fokussierte Fenster (`_prev_win`), um nach dem Öffnen ggf. den Fokus zurückzusetzen.
* **Verwendung:** Ermöglicht Auto-Fokus-Management.
* **Implementierung:**

```lua
M._prev_win = vim.api.nvim_get_current_win()
```

---

### 4. `neo_tree_window_after_open`

 **Beschreibung:** Wird ausgelöst, nachdem ein Neo-tree-Fenster geöffnet wurde.
 **Effekt:** Setzt den Fokus auf das vorherige Fenster zurück, falls das Neo-tree-Fenster kein Floating-Fenster ist.
 **Details:**

  * Ignoriert Floating-Fenster, da der Fokus dort nicht verändert werden soll.
  * Nutzt `vim.schedule`, um sicherzustellen, dass der Fokus nach dem Öffnen korrekt gesetzt wird.
* **Implementierung:**

```lua
if not is_float(args.winid) and M._prev_win and vim.api.nvim_win_is_valid(M._prev_win) then
  vim.schedule(function()
    vim.api.nvim_set_current_win(M._prev_win)
  end)
end
```

---

## Interne Hilfsfunktionen

### `is_float(winid)`

* **Beschreibung:** Prüft, ob ein Fenster ein Floating-Fenster ist.
* **Rückgabewert:** `true`, wenn es ein Float ist, sonst `false`.
* **Implementierung:**

```lua
local cfg = vim.api.nvim_win_get_config(winid)
return cfg.relative ~= "" and cfg.relative ~= nil
```

---

## Anpassungen

* Das Modul kann beliebig erweitert werden, indem neue Event-Handler in der `handlers`-Tabelle ergänzt werden.
* `_prev_win` ist intern und sollte nur innerhalb des Moduls verwendet werden.
* Cursor-Farben und Blend-Einstellungen können nach Geschmack angepasst werden.

---

