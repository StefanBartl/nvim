#  __  __    _______
# |  \/  |  |__   __|
# | \  / |_   _| | ___ _ __ _ __ ___
# | |\/| | | | | |/ _ \ '__| '_ ` _ \
# | |  | | |_| | |  __/ |  | | | | | |
# |_|  |_|\__, |_|\___|_|  |_| |_| |_|
#          __/ |
#         |___/

<p align="center"><b>myterm.nvim</b> — Modular terminal manager for Neovim</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-0.1.0-blue.svg">
  <img src="https://img.shields.io/badge/status-beta-orange.svg">
  <img src="https://img.shields.io/badge/license-MIT-green.svg">
  <img src="https://img.shields.io/badge/Neovim-0.9+-success.svg">
  <img src="https://img.shields.io/badge/language-Lua-yellow.svg">
</p>

---

## Features

- 🔁 Toggle between **floating**, **horizontal**, and **vertical** terminals
- 🧠 Reuse or restore last focused terminal
- 🔒 Keep commands stored per terminal session
- 📦 Send background commands without UI focus
- 🚪 Close, focus, and inspect terminals by ID
- 🏷️ Terminal label overlays using virtual text
- ⌨️ Built-in keymaps and commands, no config required

---

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "StefanBartl/myterm.nvim",
  config = function()
    require("custom.myterm") -- or just require("myterm")
  end,
}
````

---

## Usage

### Commands

| Command        | Args                       | Description                                 |
| -------------- | -------------------------- | ------------------------------------------- |
| `:Myterm`      | `float`/`horizontal`/`...` | Toggle last terminal or open new one        |
| `:MytermNew`   | `float`, `horizontal`, ... | Open new terminal in given layout           |
| `:MytermRun`   | `[id]`                     | Run stored command in terminal ID or active |
| `:MytermSend`  | `{id} {command}`           | Send a command without focusing terminal    |
| `:MytermSet`   | –                          | Store a shell command                       |
| `:MytermClear` | –                          | Clear stored command                        |
| `:MytermFocus` | `{id}`                     | Switch focus to terminal ID                 |
| `:MytermInfo`  | –                          | Show active terminal info                   |
| `:MytermClose` | `{id}`                     | Close a terminal by its ID                  |

---

### Keybindings

Defined internally in `myterm.keymaps`:

| Mode | Key          | Action                                |
| ---- | ------------ | ------------------------------------- |
| `n`  | `<leader>tf` | Toggle floating terminal              |
| `n`  | `<leader>th` | Toggle horizontal terminal            |
| `n`  | `<leader>tv` | Toggle vertical terminal              |
| `n`  | `<leader>to` | Toggle most recently focused terminal |
| `n`  | `<leader>tt` | Set a new shell command               |
| `n`  | `<leader>tr` | Run stored command                    |
| `n`  | `<leader>tc` | Clear stored command                  |
| `n`  | `<leader>ti` | Show current terminal info            |
| `n`  | `<leader>tx` | Close active terminal                 |

---

## Documentation

> Full help is available via `:help myterm`

Make sure `doc/myterm.txt` is installed and `:helptags doc` has run (usually automatic).

---

## Roadmap

* [x] Terminal pool management
* [x] Floating + split modes
* [x] Command reuse
* [x] Command sending in background
* [x] Virtual terminal labeling
* [ ] Terminal tab line / UI picker
* [ ] Layout cycling
* [ ] Autostart terminal sessions

---

## License

MIT © [LICEŃSE](./LICENSE)
Pull requests welcome 🤝

---