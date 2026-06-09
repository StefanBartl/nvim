# dir_picker

A lightweight, fully lazy-loaded Neovim module that opens a file picker
(Telescope or fzf-lua) rooted at any directory — addressed by numeric depth
above CWD or by a named alias such as `git`, `home`, or `root`.

## Table of content

- [dir_picker](#dir_picker)
  - [Directory structure](#directory-structure)
  - [Setup](#setup)
  - [User command](#user-command)
  - [Keymap](#keymap)
  - [Programmatic API](#programmatic-api)
  - [Depth aliases](#depth-aliases)
  - [Notes](#notes)

---

## Directory structure

```
nvim/lua/custom/dir_picker/
  ├── init.lua
  ├── config.lua
  ├── core.lua
  ├── bindings/
  │   ├── keymaps.lua
  │   └── usercmds.lua
  ├── types/
  │   └── init.lua
  ├── doc/
  │   └── dir_picker.txt
  └── README.md
```

## Setup

```lua
require("custom.dir_picker").setup({
  default_engine  = "telescope",   -- or "fzf"
  fallback_engine = "fzf",
  -- optional: add or override named depth aliases
  depth_aliases = {
    work = function() return "/home/user/work" end,
  },
})
```

The module has zero startup cost; all inner modules are loaded on first use.

## User command

```
:DirPicker [depth|alias|path=<dir>] [engine]
```

The three argument forms can appear in any order.

| Argument      | Accepted values                                     | Default   |
|---------------|-----------------------------------------------------|-----------|
| depth         | integer ≥ 0                                         | 0 (= cwd) |
| alias         | cwd  git  home  root  (+ custom)                    | —         |
| path=\<dir\>  | any absolute or relative path, ~ and $VAR expanded  | —         |
| engine        | telescope, fzf                                      | config    |

`path=` takes priority over a depth or alias if both are given.

Examples:

```vim
:DirPicker                          " CWD, default engine
:DirPicker 2                        " 2 levels above CWD
:DirPicker git                      " nearest Git root
:DirPicker home fzf                 " $HOME with fzf-lua
:DirPicker path=/srv/www            " explicit POSIX path
:DirPicker path=c:\tools            " explicit Windows path
:DirPicker path=~/projects          " tilde expansion
:DirPicker path=%USERPROFILE%\dev   " Windows env-var expansion
:DirPicker path=$XDG_DATA_HOME fzf  " POSIX env-var + engine
```

## Keymap

`<leader>fd` — interactive two-step prompt:

1. Enter depth, alias, or `path=<dir>` (empty → CWD).
2. Select engine.

Examples of valid first-prompt input:

```
2
git
path=c:\tools
path=~/work
path=/srv
```

## Programmatic API

```lua
local core = require("custom.dir_picker.core")

-- depth / alias forms (unchanged)
core.pick()
core.pick("git", "telescope")
core.pick(2, "fzf")

-- explicit path via raw_args
core.pick(nil, nil, { "path=/srv/www" })
core.pick(nil, "fzf", { "path=c:\\tools" })
```

## Depth aliases

| Alias  | Resolves to                                         |
|--------|-----------------------------------------------------|
| cwd    | Current working directory                           |
| home   | $HOME / uv.os_homedir()                             |
| root   | Filesystem root (upward walk until path = parent)   |
| git    | Nearest ancestor directory containing .git          |

Custom aliases can be added via `setup({ depth_aliases = { ... } })`.

## Notes

- Engine auto-detection: if the configured default is not installed,
  the module falls back to the other supported engine automatically.
- All state is module-local; no `_G` pollution.
- Cross-platform: tested on Linux, macOS, Windows (PowerShell), and WSL.
