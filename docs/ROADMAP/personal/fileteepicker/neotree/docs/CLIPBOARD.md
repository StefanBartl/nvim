# Neo-tree Mark & Clipboard Fixes

## Table of content

- [Neo-tree Mark & Clipboard Fixes](#neo-tree-mark-clipboard-fixes)
  - [Configuration Changes](#configuration-changes)
    - [Neo-tree Setup (in your config)](#neo-tree-setup-in-your-config)
  - [Keymaps Summary](#keymaps-summary)
  - [Additional Keymaps (Add to filesystem keymaps)](#additional-keymaps-add-to-filesystem-keymaps)
  - [Features](#features)
    - [🎨 Visual Indicators](#visual-indicators)
    - [📋 Clipboard Workflow](#clipboard-workflow)
  - [Known Limitations](#known-limitations)
  - [Troubleshooting](#troubleshooting)
    - [Issue: No marks visible](#issue-no-marks-visible)
    - [Issue: Paste doesn't work](#issue-paste-doesnt-work)
  - [Future Enhancements](#future-enhancements)

---

## Configuration Changes

### Neo-tree Setup (in your config)

```lua
require("neo-tree").setup({
  -- ... existing config ...

  -- Add mark component to filesystem renderers
  filesystem = {
    components = {
      -- Add mark indicator component
      mark_indicator = function(config, node, state)
        return require("config.neotree.components.marks").mark_indicator(config, node, state)
      end,
    },

    -- Update renderers to include mark indicator
    renderers = {
      file = {
        { "indent" },
        { "icon" },
        { "mark_indicator" }, -- ADD THIS
        { "name", use_git_status_colors = true },
        { "git_status" },
      },
      directory = {
        { "indent" },
        { "icon" },
        { "mark_indicator" }, -- ADD THIS
        { "current_filter" },
        { "name" },
        { "git_status" },
      },
    },
  },
})
```

---

## Keymaps Summary

| Key | Action | Description |
|-----|--------|-------------|
| `m` | Toggle mark | Mark/unmark single file |
| `]m` | Mark all in dir | Mark all files in directory |
| `[m` | Unmark all in dir | Unmark all files in directory |
| `<C-m>` | Clear all marks | Clear all marks (global) |
| `<leader>ms` | Show marks | Show marked nodes in float |
| `c` | Copy | Copy marked/current to clipboard |
| `x` | Cut | Cut marked/current to clipboard |
| `p` | Paste | Paste clipboard to current dir |
| `<C-c>` | Clear clipboard | Clear clipboard |
| `d` | Delete/Trash | Delete marked/current nodes |

---

## Additional Keymaps (Add to filesystem keymaps)

```lua
-- In lua/config/neotree/keymaps/filesystem/mark.lua
return {
  ["m"] = {
    function(state)
      require("config.neotree.commands").mark.toggle_mark(state, false)
    end,
    desc = "Mark/Unmark single file",
  },

  ["]m"] = {
    function(state)
      require("config.neotree.commands").mark.mark_all_in_directory(state)
    end,
    desc = "Mark all files in directory",
  },

  ["[m"] = {
    function(state)
      require("config.neotree.commands").mark.unmark_all_in_directory(state)
    end,
    desc = "Unmark all files in directory",
  },

  ["<C-m>"] = {
    function(state)
      require("config.neotree.commands").mark.clear_all_marks(state)
    end,
    desc = "Clear all marks",
  },

  ["<leader>ms"] = {
    function(state)
      require("config.neotree.commands").mark.show_marked_nodes(state)
    end,
    desc = "Show marked nodes",
  },
}
```

---

## Features

### 🎨 Visual Indicators

- Marked nodes show `✓` icon (or `*` in non-GUI)
- Gold/yellow highlight for marked items
- Float window shows all marked nodes

### 📋 Clipboard Workflow

```
1. Mark files with 'm'
2. Navigate to target directory
3. Press 'p' to paste

OR

1. Mark files with 'm'
2. Press 'c' to copy (or 'x' to cut)
3. Navigate to target
4. Press 'p' to paste
```

---

## Known Limitations

1. **Directory Copy**: Recursive copy uses `cp -r` (Linux/Mac only)
   - Windows fallback needed
2. **Paste Conflicts**: Existing files are skipped (no overwrite prompt yet)
3. **Undo**: No undo for copy/move operations (use trash for delete)

---

## Troubleshooting

### Issue: No marks visible
```lua
-- Check highlight setup
:lua vim.print(vim.g.neotree_mark_highlights_setup)
-- Should be true

-- Check component registration
:lua vim.print(require("neo-tree.sources.filesystem").setup)
```

### Issue: Paste doesn't work
```lua
-- Check clipboard
:lua vim.print(vim.g.neo_tree_clipboard)
-- Should show action and nodes

-- Check target directory
:lua vim.print(vim.fn.getcwd())
```

---

## Future Enhancements

- [ ] Windows-compatible directory copy
- [ ] Overwrite confirmation for paste
- [ ] Visual clipboard preview
- [ ] Undo for copy/move
- [ ] Multi-window mark sync

--
