# Quick Reference: the context menu

## Neo-tree right-click — moved out

The tree's context menu is filetree.nvim's now (`context_menu` feature, a
buffer-local `<RightMouse>` on the tree buffer). Its entries and keys are
documented there, not here — the table that used to sit in this spot was a
copy that drifted. This config's global right-click never fires inside the
tree, because a buffer-local mapping shadows it.

---

## Custom Menu (Alt-b / Right-Click)

### 📋 Copy Operations
| Entry | Shortcut | Description |
|-------|----------|-------------|
| **Copy All (Buffer)** | `<C-a>` | Copy entire buffer to clipboard |
| **Copy Marked/Selected** | `<C-c>` | Copy visual selection or entire buffer |
| **Paste Content** | `<C-v>` | Paste from system clipboard |

### 🗑️ Delete Operations
| Entry | Shortcut | Description |
|-------|----------|-------------|
| **Delete Marked/Selected** | `dm` | Delete visual selection |
| **Delete All** | `da` | Clear entire buffer (with confirmation) |
| **🗑️ Delete File** | `df` | Delete file from disk (with confirmation) |

### 🛠️ Tools
| Entry | Shortcut | Description |
|-------|----------|-------------|
| **Format Buffer** | `<leader>fm` | Format with conform/LSP |
| **Code Actions** | `<leader>ca` | Show LSP code actions |
| **Unicode Table** | `uni` | Open Unicode table (floating) |
| **Color Picker** | - | Open color picker (minty.huefy) |
| **Open Terminal** | - | Open terminal in current directory |

### 🎨 LSP & Git
| Entry | Shortcut | Description |
|-------|----------|-------------|
| **LSP** | - | Fly-out contributed by lsp.nvim (its resolved keymap catalogue) |
| **Git Actions** | - | Fly-out from `config/menu/git.lua`, gated on gitsigns.nvim |

Plugin fly-outs (Open, DAP, File, Spotlight, LSP, markdown, …) come from the
`CONTRIBUTORS` list in `config/menu/mappings.lua`, not from this table.

---

## Navigating the menu

`j`/`k`/arrows move (separators are stepped over), `<CR>` picks, `<Esc>`/`q`
closes. A `▸` entry opens a nested list **in place**; `<BS>` goes back up.
That drill-down is the kit renderer's shape — nvzone/menu opened nested
entries in a second window beside the parent.

---

## Visual Mode Workflows

### Copy Selected Text
1. Enter Visual Mode: `v`, `V`, or `<C-v>`
2. Select text
3. Right-click → "Copy Marked/Selected"
   - OR: `<C-c>`

### Delete Selected Text
1. Enter Visual Mode
2. Select text
3. Right-click → "Delete Marked/Selected"
   - OR: `dm`

---

## Configuration Toggle

Enable/Disable features in `init.lua` (the `UIReady` menu phase):

```lua
require("config.menu").setup({
  -- Copy/Paste
  enable_copy_all = true,
  enable_copy_marked = true,
  enable_paste = true,

  -- Delete
  enable_delete_marked = true,
  enable_delete_all = true,
  enable_delete_file = true,

  -- Tools
  enable_unicode_table = true,
  enable_color_picker = true,
  enable_open_terminal = true,

  -- Sections
  enable_git_section = true,

  -- Who draws the menu: "kit" (lib.nvim.ui.kit.menu, the default here),
  -- "nvzone" (nvzone/menu), or "auto".
  renderer = "kit",
})
```

---

## Unicode Table Usage

### Open
- Menu → "Unicode Table"
- OR: `:UnicodeTable`

### Navigation
- `j`/`k`: Navigate up/down
- `/`: Search
- `<CR>`: Insert character

### Close
- `q` or `<Esc>`

### Requirements
```lua
{
  "chrisbra/unicode.vim",
  cmd = { "UnicodeTable" },
}
```

---

## Common Workflows

### 1. Copy Entire File
```
<Alt-b> → Copy All (Buffer)
```

### 2. Copy Selected Lines
```
V (Visual Line) → Select → <C-c>
```

### 3. Delete File Safely
```
<Alt-b> → Delete File → Confirm
```

---

## Keyboard Shortcuts Summary

### Global
- `<Alt-b>`: Open custom menu
- `<RightMouse>`: Context menu at the pointer (inside the tree, filetree.nvim's own menu shadows it)

### Copy/Paste
- `<C-a>`: Copy all
- `<C-c>`: Copy selection/all
- `<C-v>`: Paste

### Delete
- `dm`: Delete marked/selected
- `da`: Delete all (buffer)
- `df`: Delete file

### Tools
- `uni`: Unicode table

---

## Tips & Tricks

### 1. Smart Copy
Menu's "Copy Marked/Selected" automatically detects:
- Visual selection → Copy only selected
- No selection → Copy entire buffer

### 2. Safe Delete File
Always shows confirmation with filename before deleting.

---

## Troubleshooting

### Unicode Table not opening
1. Check if plugin installed: `:PackerStatus` / `:Lazy`
2. Install: Add `chrisbra/unicode.vim` to plugins
3. Reload config: `:source %`

### Delete File fails
- Check file permissions
- File might be read-only
- Close all buffers with that file first

### Copy/Paste empty
- Check clipboard provider: `:checkhealth`
- System clipboard might not be available
- Try named registers: `"ay` (yank to register a)

---
