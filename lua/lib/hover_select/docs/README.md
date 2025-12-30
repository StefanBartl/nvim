# hover-select

hover-select is a small, modular Neovim helper module for displaying and selecting items in a floating window relative to the cursor position. It is intentionally minimal and designed as a building block for custom plugins or internal tools.

--

## Table of content

  - [Motivation](#motivation)
  - [Features](#features)
  - [Architecture](#architecture)
  - [Type Definitions](#type-definitions)
  - [Configuration](#configuration)
  - [Interaction](#interaction)
  - [Intended Use Cases](#intended-use-cases)

---

## Motivation

Many plugins require a simple, focused selection UI without pulling in large frameworks such as Telescope, fzf, or even `vim.ui.select`. hover-select provides a lightweight, fully controllable alternative for these cases.

---

## Features

* floating window relative to cursor, window, or editor
* simple string-based item list
* callback executed on item selection
* strictly vertical navigation, horizontal movement disabled
* automatic window size calculation with minimum and maximum limits
* automatic cleanup of buffers and windows via autocommands
* dedicated highlight group for the active cursor line

---

## Architecture

The module is split into small, well-defined components:

* lib.hover_select.buffer
  Responsible for buffer creation, content updates, and buffer-local options

* lib.hover_select.window
  Calculates window dimensions, creates the floating window, and manages lifecycle cleanup

* lib.hover_select.navigation
  Defines keymaps for navigation, selection, and closing the UI

* lib.hover_select.highlight
  Manages highlight groups for the active cursor line

* lib.hover_select.config
  Central location for default buffer, window, and layout configuration

* lib.hover_select.@types
  EmmyLua type definitions for options and internal state

---

## Type Definitions

The module ships with EmmyLua annotations intended for LuaLS, including:

* HoverSelectOptions
  Configuration object for items, callbacks, buffer options, window options, and layout

* HoverSelectState
  Internal state holding buffer and window references as well as the active item list

These definitions significantly improve autocompletion and static analysis.

---

## Configuration

Reasonable defaults are provided for:

* buffer options (nofile buffer, wipe on close, no swapfile, custom filetype)
* window-local options (cursorline enabled, no line numbers, no wrapping)
* floating window layout (border, relative positioning, z-index)
* size constraints (minimum and maximum width and height)

All options can be overridden or extended by passing custom tables, which are merged using `vim.tbl_deep_extend`.

---

## Interaction

* vertical navigation using standard keys (j/k, arrow keys)
* selection via Enter or double mouse click
* closing the UI using Escape or q
* horizontal cursor movement is intentionally disabled to avoid accidental navigation

---

## Intended Use Cases

hover-select is aimed at plugin authors and advanced Neovim users who:

* build custom UI components
* need precise control over buffers and floating windows
* prefer minimal dependencies and clear internal structure

---

