# neotree-current-hl

Highlight the current buffer’s file and its parent directory in Neo-tree, without changing focus and without extra keymaps. Minimal integration: wrap Neo-tree’s built-in `name` component and refresh the tree when the active buffer changes.

## Features

* Highlights the current file node (e.g., bright red) and its parent directory node (e.g., dark red)
* No focus stealing, no new keymaps
* Works with the filesystem source; keeps your icons, git badges, and renderer setup intact
* Color configuration via hex, group links, or full highlight specs
* Debounced refresh for smooth performance
* Survives colorscheme changes

## Requirements

* Neovim 0.9+ (uses `vim.fs.*` and `vim.uv`)
* Neo-tree v3.x

## How it works

* A tiny wrapper around the filesystem `name` component returns the original render item, then swaps its `highlight` when:

  * `node.type == "file"` and `node.path == <current buffer path>`
  * `node.type == "directory"` and `node.path == <parent of current buffer path>`
* A debounced autocmd set (`BufEnter`, `WinEnter`, `TabEnter`, `BufWritePost`) updates the tracked paths and triggers a lightweight `manager.refresh("filesystem")`
* Two highlight groups are defined (and re-applied on `ColorScheme`):

  * `NeoTreeCurrentFile` (file color/style)
  * `NeoTreeCurrentParent` (parent directory color/style)

## Installation

Place the module at `lua/config/neotree/current_hl.lua` (adjust the path to your taste). The module exposes two entry points:

* `attach(opts)` to inject the component wrapper before `require("neo-tree").setup(opts)`
* `setup({ ... })` to define highlights and register autocmds after Neo-tree is configured

## Minimal lazy.nvim integration

```lua
-- English comments

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
  lazy = false,

  opts = function(_, opts)
    opts = opts or {}

    -- Inject the component wrapper before Neo-tree initializes
    require("config.neotree.current_hl").attach(opts)

    -- Keep your existing options here as-is
    opts.default_component_config = opts.default_component_config or {}
    opts.default_component_config.name = vim.tbl_deep_extend("force",
      opts.default_component_config.name or {},
      {
        highlight_opened_files = true,
        -- Keep git status colors off by default so our custom color takes precedence.
        use_git_status_colors = false,
      }
    )

    opts.filesystem = vim.tbl_deep_extend("force", opts.filesystem or {}, {
      follow_current_file = { enabled = true },
    })

    return opts
  end,

  config = function(_, opts)
    -- Your existing hooks before setup (if any)
    -- require("config.neotree.usr_picker").attach(opts)

    require("neo-tree").setup(opts)

    -- Register highlights + autocmds after Neo-tree is configured
    require("config.neotree.current_hl").setup({
      -- colors are optional; see Configuration section for details
      colors = {
        -- Hex string
        file = "#ff6b6b",
        -- Link to an existing group from your colorscheme
        parent = { link = "Directory" },
        -- Or full table: parent = { fg = "#b30000", underline = true },
        -- Or a pragmatic name (mapped internally): file = "red",
      },
      debounce = 50,               -- ms; raise on huge repos, lower on small ones
      use_git_status_colors = false, -- keep our color dominant
      enable = true,
    })
  end,
}
```

> cwd syncing is handled by filetree.nvim's `cwd_sync` feature (see
> `plugins/personal/init.lua`'s filetree.nvim setup), not by any config here.

## Configuration

Options accepted by `setup({ ... })`:

| Key                     | Type            | Default            | Description                                                                                                                |
| ----------------------- | --------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `colors.file`           | string or table | `"#ff5f5f"` (bold) | Current file color. Hex (`"#rrggbb"`), `{ link = "Group" }`, full table, or simple names like `"red"` (mapped internally). |
| `colors.parent`         | string or table | `"#af0000"`        | Parent directory color. Same accepted forms as `colors.file`.                                                              |
| `debounce`              | integer (ms)    | `50`               | Debounce for refresh after buffer/window/tab changes.                                                                      |
| `use_git_status_colors` | boolean         | `false`            | If `true`, name component may be recolored by git status; your custom color might be overridden.                           |
| `enable`                | boolean         | `true`             | Master switch.                                                                                                             |

Accepted color forms:

* Hex: `"#ff6b6b"`
* Link to group: `{ link = "Directory" }` or `"link:Directory"`
* Full spec: `{ fg = "#ff6b6b", bold = true, underline = false }`
* Pragmatic names: `"red"`, `"darkred"`, `"blue"`, etc. (mapped to hex internally; prefer hex or links for portability)

Notes on highlight precedence:

* If `use_git_status_colors = false` (default), your custom colors dominate the file and directory name text
* If enabled, git status may recolor filename text depending on your theme and git state

## Usage

* Open Neo-tree as usual
* Switch buffers or open new files; the current file node is highlighted, and its parent directory node is highlighted differently
* No keymaps or focus changes are introduced

## Interaction with follow/reveal

* Works best with `filesystem.follow_current_file.enabled = true`
* If your workflow uses an external “reveal” action (e.g., project root jumps), the highlight follows the current buffer path on the next debounced refresh
* If the file lies outside the current tree root, highlight appears after the tree root reveals/updates it (normal Neo-tree behavior)

## Performance notes

* `debounce = 50` is a good default; for very large trees increase to `80–150`
* Refresh uses Neo-tree’s internal manager and only re-renders the filesystem source
* No Tree-sitter or heavy scans; path comparisons are absolute and normalized

## Troubleshooting

| Symptom                                             | Check / Fix                                                                              |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| No highlight appears                                | Ensure at least one Neo-tree window is open in the current tab                           |
| Git colors override custom color                    | Set `use_git_status_colors = false` (default)                                            |
| Colors lost after switching theme                   | The module re-applies on `ColorScheme`; verify the autocommand group isn’t overwritten   |
| Highlight doesn’t follow buffer changes immediately | Decrease `debounce` or verify your buffer isn’t a special `buftype`                      |
| File is not visible under current tree root         | Use Neo-tree’s reveal/follow to bring the node under the root; highlight will apply then |

## Example: plain setup with hex colors

```lua
-- English comments

require("config.neotree.current_hl").setup({
  colors = {
    file   = "#ff4d4f",
    parent = "#a8071a",
  },
  debounce = 80,
})
```

## Example: link to theme groups

```lua
-- English comments

require("config.neotree.current_hl").setup({
  colors = {
    file   = { link = "ErrorMsg" },
    parent = { link = "Directory" },
  },
})
```

## API surface

* `require("config.neotree.current_hl").attach(opts)`

  * Wraps `filesystem.components.name` before `neo-tree`.setup
* `require("config.neotree.current_hl").setup(cfg)`

  * Defines highlight groups, registers autocmds, kicks initial refresh

## Limitations

* Only affects the filesystem source’s `name` text; icons and other components remain controlled by your theme and git settings
* If Neo-tree is closed or not present in the current tab, no refresh is performed

## Rationale

* Component wrapping is the least invasive way to affect per-node styling while preserving all of Neo-tree’s features (icons, git, symlinks, diagnostics)
* Debounced autocmds avoid performance pitfalls and keep the UX seamless
* Explicit highlight groups plus `ColorScheme` hook make the behavior robust across theme switches

## License

