# Quick Reference: the context menu

## Neo-tree right-click — moved out

The tree's context menu is filetree.nvim's now (`context_menu` feature, a
buffer-local `<RightMouse>` on the tree buffer). Its entries and keys are
documented there, not here — the table that used to sit in this spot was a
copy that drifted. This config's global right-click never fires inside the
tree, because a buffer-local mapping shadows it.

---

## Custom Menu (Alt-b / Right-Click)

The headings below are the menu's own: each is drawn as a titled frame, in
this order.

### Integrations
Every applicable plugin fly-out — Markdown, Open, DAP, Cascade, File, Images,
Spotlight, Color My ASCII, LSP. The list is `CONTRIBUTORS` in
`config/menu/mappings.lua`, and which of them appear depends on the buffer.

### Code
| Entry | Shortcut | Description |
|-------|----------|-------------|
| **Format Buffer** | `<leader>fm` | Format with conform/LSP |
| **Code Actions** | `<leader>ca` | Show LSP code actions |

### Clipboard
| Entry | Shortcut | Description |
|-------|----------|-------------|
| **Copy All (Buffer)** | `<C-a>` | Copy entire buffer to clipboard |
| **Copy Marked/Selected** | `<C-c>` | Copy visual selection or entire buffer |
| **Paste Content** | `<C-v>` | Paste from system clipboard |

### Delete
| Entry | Shortcut | Description |
|-------|----------|-------------|
| **Delete Marked/Selected** | `dm` | Delete visual selection |
| **Delete All (Clear Buffer)** | `da` | Clear entire buffer (with confirmation) |
| **Delete File** | `df` | Delete file from disk (with confirmation) |

### Tools
| Entry | Shortcut | Description |
|-------|----------|-------------|
| **Open in terminal** | - | Open terminal in current directory |
| **Color Picker** | - | Open color picker (minty.huefy) |
| **Unicode Table** | `uni` | Open Unicode table (floating) |
| **Git Actions** | - | Fly-out from `config/menu/git.lua` (Hunks / Blame / Diff), gated on gitsigns.nvim |

---

## Navigating the menu

`j`/`k`/arrows move (frame lines and section titles are stepped over), `<CR>`
picks, `<Esc>`/`q` closes. An entry marked `→` opens a nested list **in
place**; `<BS>`, or the `◂ Back` row at the top of a nested level, goes back
up. That marker sits just past the longest label rather than at the right
edge — the keymap-hint column keeps the edge. That drill-down is the kit renderer's shape — nvzone/menu
opened nested entries in a second window beside the parent.

Every row is a set of aligned columns: icon, label, fly-out marker, keymap
hint. The icon is a field on the entry, never part of its label — see
[`config/menu/icons.lua`](../icons.lua) and the note in
[`custom_menu/README.md`](../custom_menu/README.md).

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
