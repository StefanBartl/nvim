# Menu Integration (custom NVDash menu)

- Custom menu integration is added in `config/menu/`.

## Features

This module provides:
- A composed `custom` menu (based on `menus.default`) with:
  - Paste Content (system clipboard)
  - Nested *LSP Actions* (`menus.lsp`)
  - Nested *Git Actions* (`menus.gitsigns`)
- Keymaps for `<A-b>` and right mouse to open the appropriate menu for current window (NeoTree / NvimTree / custom).
- A small API to toggle top-level entries at setup time.

---

## Installation

1. Put `config/menu/*` and `plugins/nvdash.lua` in the repository as described.

--

## Usage

- `<A-b>` opens the custom menu if registered, otherwise the default.
- Right-click in Neo-Tree opens the Neo-Tree menu; in a normal buffer it opens `custom` (or `default`).

---
