# Quick Reference: Updated Menu System

## Neo-tree Context Menu (Right-Click in Neo-tree)

### 🗂️ Navigation & View
| Key | Action | Description |
|-----|--------|-------------|
| `<CR>` | Open/Expand | Open file or expand directory |
| `+` | Navigate In | Set directory as root |
| `-` | Navigate Up | Go to parent directory |
| `w` | Resize | Cycle window size (small/normal/large) |
| `<Tab>` | Preview | Toggle preview window |

### 📋 Copy Operations
| Key | Action | Description |
|-----|--------|-------------|
| `c` | Copy | Copy marked/current to clipboard |
| `x` | Cut | Cut marked/current to clipboard |
| `p` | Paste | Paste from clipboard |
| `[a]` | Copy Path | Copy absolute path |
| `]a]` | Copy Dir | Copy base directory path |
| `[f]` | Copy Files | Copy file list (absolute) |
| `]f]` | Copy Files (Rel) | Copy file list (relative) |

### ✓ Marking
| Key | Action | Description |
|-----|--------|-------------|
| `m` | Mark | Toggle mark on file |
| `]m` | Mark All | Mark all in directory |
| `[m` | Unmark All | Unmark all in directory |
| `<C-m>` | Clear Marks | Clear all marks |

### 🗑️ Delete & Trash
| Key | Action | Description |
|-----|--------|-------------|
| `d` | Delete | Send to trash |
| `U` | Undo | Undo last trash |

### 🔍 Search & Filter
| Key | Action | Description |
|-----|--------|-------------|
| `f` | Filter | Filter on submit |
| `F` | Fuzzy | Fuzzy finder |
| `gr` | Grep | Live grep (auto-detect) |
| `tf` | Telescope Find | Find files via telescope |
| `tg` | Telescope Grep | Live grep via telescope |

### ℹ️ Info & System
| Key | Action | Description |
|-----|--------|-------------|
| `I` | Info | Show file/directory info |
| `<leader>fm` | File Manager | Open in system file manager |
| `<leader>sm` | System App | Open with system application |

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
| **Lsp Actions** | - | Nested LSP menu |
| **Git Actions** | - | Nested Git (gitsigns) menu |

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

Enable/Disable features in `init.lua`:

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
  enable_lsp_section = true,
  enable_git_section = true,
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

### 4. Mark & Copy Multiple Files (Neo-tree)
```
m (mark file 1)
j (move down)
m (mark file 2)
...
c (copy all marked)
```

### 5. Search in Directory
```
gr (in Neo-tree on folder)
→ Opens live grep in that directory
```

---

## Keyboard Shortcuts Summary

### Global
- `<Alt-b>`: Open custom menu
- `<RightMouse>`: Context menu (Neo-tree aware)

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

### 3. Neo-tree Path Operations
Use bracket prefixes for absolute/relative:
- `[` = Absolute
- `]` = Relative

Example:
- `[f]` = Absolute file list
- `]f]` = Relative file list

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
