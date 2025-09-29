# help_sync

Aggregates scattered Vim help files found in recursively discovered `docs/` folders within your Neovim config into a single `doc/` directory on the `'runtimepath'`, then runs `:helptags` so `:help` can see all topics. Linux/macOS, symlink-first with copy fallback.

## Features

* Recursive scan of one or more roots (defaults to `stdpath("config")` and its `lua` subdir)
* Detects any directory named `docs` (configurable)
* Collects all `*.txt` help files and mirrors them into a single aggregator
* Uses symlinks by default; falls back to copying if symlinks are not allowed
* Automatically ensures the aggregator is on the `'runtimepath'`
* Runs `:helptags` once so `:help` works immediately
* Very low runtime overhead, mostly I/O-bound

## Requirements

* Neovim ≥ 0.9 (uses `vim.fs.walk`; ≥ 0.10 recommended)
* POSIX system (Linux/macOS) with symlink support
* Valid Vim help files (`*.txt` with `*tags*` inside)

## Installation (Lazy.nvim)

```lua
{
  -- Adjust to your local tree:
  dir = vim.fn.stdpath("config") .. "/nvim/usrcmds/help_sync",
  name = "help_sync",
  lazy = false,  -- load early so :help works right after startup
  config = function()
    require("usrcmds.help_sync").setup({
      -- sensible defaults; tweak as needed
      search_roots = {
        vim.fn.stdpath("config"),                -- ~/.config/nvim
        vim.fn.stdpath("config") .. "/lua",      -- ~/.config/nvim/lua
      },
      docs_dirnames = { "docs" },                -- e.g. { "docs", "doc" }
      aggregator_ns = "local",                   -- namespace under STATE: ~/.local/state/nvim/help-sync/local/doc
      prefer_symlink = true,                     -- symlink first, fallback to copy
      clear_before_build = true,                 -- wipe aggregator before each rebuild
      rebuild_on_start = true,                   -- build once on startup
      notify_prefix = "[HelpSync] ",
    })
  end,
  cmd = { "HelpSyncRebuild" },
}
```

## Quickstart

* `:HelpSyncRebuild` builds the aggregator manually (scan → mirror → `:helptags`).
* With `rebuild_on_start = true`, this happens once on startup.
* After that, topics are reachable via `:h <tag>`, for example `:h project_tree`.

## API

```lua
-- load and configure once at startup
require("usrcmds.help_sync").setup({
  search_roots = { vim.fn.stdpath("config"), vim.fn.stdpath("config") .. "/lua" },
  docs_dirnames = { "docs" },
  prefer_symlink = true,
  rebuild_on_start = false,
})

-- programmatic rebuild (same as :HelpSyncRebuild)
local ok, msg, count = require("usrcmds.help_sync").rebuild()
vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.ERROR)
```

## How it works

* Neovim only discovers help tags under `<rtp>/doc/`.
* Help files buried deeper in your config (for example `lua/**/docs/*.txt`) are not found by `:help` unless mirrored into a `doc/` folder that sits on the `'runtimepath'`.
* `help_sync`:

  * recursively scans all `search_roots` for directories named in `docs_dirnames`
  * collects every `*.txt` help file found under those directories
  * mirrors each file into `~/.local/state/nvim/help-sync/<namespace>/doc` via symlink (or copy)
  * ensures the aggregator base is present in `'runtimepath'`
  * runs `:helptags <aggregator/doc>` to generate `tags`

## Performance

* Recursive scanning uses `vim.fs.walk` (streaming), which is efficient.
* One symlink/copy operation per file, then a single `:helptags` run.
* Even with hundreds of files the process is typically sub-second on SSDs and remains I/O-bound.

## Configuration

## Name                 Type        Default                                              Description

search_roots         string[]    { stdpath("config"), stdpath("config").."/lua" }    recursive roots to scan
docs_dirnames        string[]    { "docs" }                                           directory names containing help
aggregator_ns        string      "local"                                              namespace under the state path
prefer_symlink       boolean     true                                                 prefer symlinks, otherwise copy
clear_before_build   boolean     true                                                 wipe aggregator before rebuild
rebuild_on_start     boolean     false                                                rebuild once on startup
notify_prefix        string      "[HelpSync] "                                        prefix for notifications

## Notes and limitations

* Name collisions: files are flattened in the aggregator by replacing path separators with `__`, keeping `.txt`. This avoids collisions; if an edge case occurs, adjust the namespace or flattening scheme.
* Windows is not supported.
* If symlinks are restricted on your system, set `prefer_symlink = false` to copy files instead.
* Help files must contain valid Vim help tags (for example `*mytopic*`) to be discoverable.

## Troubleshooting

## Problem                             Cause/Resolution

`:help` cannot find a topic         aggregator not built yet → run `:HelpSyncRebuild`
no new tags after edits             run a rebuild to regenerate `tags`
symlink errors                      filesystem policy prevents symlinks → set `prefer_symlink=false`
multiple files with same name       flattening avoids collisions; adjust namespace if needed
slow rebuilds                       many files on slow disks → expected I/O; set `rebuild_on_start=false` and rebuild on demand

## Security

* Only mirrors text files from configured roots.
* No shell execution; file system operations and a single `:helptags` call.
* Aggregator location follows XDG state dir by default: `~/.local/state/nvim/help-sync/<ns>/doc`.

---
