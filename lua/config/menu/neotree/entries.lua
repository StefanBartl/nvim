---@module 'config.menu.neotree.entries'
--- Entries table for Neo-tree custom context menu.
--- Updated: 2026-02-02
--- Source: Consolidated from all config.neotree.keymaps.filesystem.* modules

require("config.@types.menu")

---@type custom_neotree_entry[]
local entries = {
  -- ============================================================================
  -- Base Keymaps (from init.lua)
  -- ============================================================================
  { key = "q", enabled = true, label = "Close window", icon = "", rtxt = "q" },
  { key = "?", enabled = true, label = "Show help", icon = "?", rtxt = "?" },
  { key = "<Esc>", enabled = true, label = "Clear search/filter/preview/quarantine", icon = "󰌑", rtxt = "<Esc>" },
  { key = '"', enabled = true, label = "Next source", icon = "", rtxt = '"' },
  { key = "!", enabled = true, label = "Previous source", icon = "", rtxt = "!" },
  { key = "R", enabled = true, label = "Refresh", icon = "", rtxt = "R" },
  { key = "C", enabled = true, label = "Close node", icon = "", rtxt = "C" },
  { key = "z", enabled = true, label = "Close all nodes", icon = "", rtxt = "z" },
  { key = "W", enabled = true, label = "Open with window picker", icon = "", rtxt = "W" },
  { key = "w", enabled = true, label = "Resize window (cycle small/normal/large)", icon = "󰣇", rtxt = "w" },

  -- ============================================================================
  -- Filter (from filter.lua)
  -- ============================================================================
  { key = "f", enabled = true, label = "Filter on submit", icon = "", rtxt = "f" },
  { key = "F", enabled = true, label = "Fuzzy finder", icon = "", rtxt = "F" },
  { key = "<C-c>", enabled = true, label = "Clear filter", icon = "", rtxt = "<C-c>" },

  -- ============================================================================
  -- Commands (from commands.lua)
  -- ============================================================================
  { key = "i", enabled = true, label = "Run command", icon = "", rtxt = "i" },
  { key = "tf", enabled = true, label = "Telescope: find files", icon = "", rtxt = "tf" },
  { key = "tg", enabled = true, label = "Telescope: live grep", icon = "", rtxt = "tg" },

  -- ============================================================================
  -- Files (from files.lua)
  -- ============================================================================
  { key = "<CR>", enabled = true, label = "Open / Expand node", icon = "", rtxt = "<CR>" },
  { key = "<2-LeftMouse>", enabled = true, label = "Open node", icon = "", rtxt = "<2-LeftMouse>" },
  { key = "<S-CR>", enabled = true, label = "Open in background (badd)", icon = "", rtxt = "<S-CR>" },
  { key = "gb", enabled = true, label = "Open in background (badd)", icon = "", rtxt = "gb" },
  { key = "sg", enabled = true, label = "Open vsplit", icon = "🠖", rtxt = "sg" },
  { key = "sv", enabled = true, label = "Open split", icon = "🠕", rtxt = "sv" },
  { key = "st", enabled = true, label = "Open new tab", icon = "", rtxt = "st" },

  -- ============================================================================
  -- Save (from save.lua)
  -- ============================================================================
  { key = "<C-s>", enabled = true, label = "Force-save last normal buffer", icon = "💾", rtxt = "<C-s>" },
  { key = "<M-s>", enabled = true, label = "Force-save node buffer", icon = "💾", rtxt = "<M-s>" },

  -- ============================================================================
  -- Preview (from preview.lua)
  -- ============================================================================
  { key = "<Tab>", enabled = true, label = "Toggle preview", icon = "", rtxt = "<Tab>" },
  { key = "<C-b>", enabled = true, label = "Scroll preview up", icon = "", rtxt = "<C-b>" },
  { key = "<C-f>", enabled = true, label = "Scroll preview down", icon = "", rtxt = "<C-f>" },
  { key = "<PageUp>", enabled = true, label = "Scroll preview up (page)", icon = "", rtxt = "<PageUp>" },
  { key = "<PageDown>", enabled = true, label = "Scroll preview down (page)", icon = "", rtxt = "<PageDown>" },

  -- ============================================================================
  -- Replace (from replace.lua)
  -- ============================================================================
  { key = "O", enabled = true, label = "Open and replace buffer", icon = "", rtxt = "O" },

  -- ============================================================================
  -- Clipboard (from clipboard.lua)
  -- ============================================================================
  { key = "c", enabled = true, label = "Copy marked/current to clipboard", icon = "󰈙", rtxt = "c" },
  { key = "x", enabled = true, label = "Cut marked/current to clipboard", icon = "✂️", rtxt = "x" },
  { key = "p", enabled = true, label = "Paste from clipboard", icon = "📋", rtxt = "p" },

  -- ============================================================================
  -- Create (from create.lua)
  -- ============================================================================
  { key = "a", enabled = true, label = "Add file/folder", icon = "", rtxt = "a" },
  { key = "D", enabled = true, label = "Diff files", icon = "", rtxt = "D" },
  { key = "r", enabled = true, label = "Rename", icon = "", rtxt = "r" },

  -- ============================================================================
  -- Trash (from trash.lua)
  -- ============================================================================
  { key = "d", enabled = true, label = "Delete (trash)", icon = "🗑️", rtxt = "d" },
  { key = "U", enabled = true, label = "Undo last trash", icon = "", rtxt = "U" },
  { key = "<leader>th", enabled = true, label = "Show trash history", icon = "", rtxt = "<leader>th" },

  -- ============================================================================
  -- Mark (from mark.lua)
  -- ============================================================================
  { key = "m", enabled = true, label = "Mark/Unmark file", icon = "✓", rtxt = "m" },
  { key = "]m", enabled = true, label = "Mark all in directory", icon = "✓", rtxt = "]m" },
  { key = "[m", enabled = true, label = "Unmark all in directory", icon = "✗", rtxt = "[m" },
  { key = "<C-m>", enabled = true, label = "Clear all marks", icon = "󰌑", rtxt = "<C-m>" },
  { key = "<leader>ms", enabled = true, label = "Show marked nodes", icon = "", rtxt = "<leader>ms" },

  -- ============================================================================
  -- Navigation (from navigation.lua)
  -- ============================================================================
  { key = "+", enabled = true, label = "Navigate into directory (set root)", icon = "", rtxt = "+" },
  { key = "-", enabled = true, label = "Navigate up one level", icon = "", rtxt = "-" },

  -- ============================================================================
  -- Path (from path.lua)
  -- ============================================================================
  { key = "[a", enabled = true, label = "Copy absolute path", icon = "󰈙", rtxt = "[a]" },
  { key = "]a", enabled = true, label = "Copy base dir path", icon = "󰈙", rtxt = "]a]" },
  { key = "[f", enabled = true, label = "Copy file list (absolute)", icon = "󰈙", rtxt = "[f]" },
  { key = "]f", enabled = true, label = "Copy file list (relative)", icon = "󰈙", rtxt = "]f]" },
  { key = "[F", enabled = true, label = "Copy folder list (absolute)", icon = "󰈙", rtxt = "[F]" },
  { key = "]F", enabled = true, label = "Copy folder list (relative)", icon = "󰈙", rtxt = "]F]" },

  -- ============================================================================
  -- Info (from info.lua)
  -- ============================================================================
  { key = "I", enabled = true, label = "Show file/directory info", icon = "", rtxt = "I" },
  { key = "<leader>fm", enabled = true, label = "Open in file manager", icon = "", rtxt = "<leader>fm" },
  { key = "<leader>sm", enabled = true, label = "Open with system app", icon = "", rtxt = "<leader>sm" },
  { key = "rq", enabled = true, label = "Copy require() string", icon = "", rtxt = "rq" },

  -- ============================================================================
  -- Search (from search.lua)
  -- ============================================================================
  { key = "gr", enabled = true, label = "Live grep (auto)", icon = "", rtxt = "gr" },
  { key = "<leader>gt", enabled = true, label = "Live grep (telescope)", icon = "", rtxt = "<leader>gt" },
  { key = "<leader>gf", enabled = true, label = "Live grep (fzf-lua)", icon = "", rtxt = "<leader>gf" },
}

return entries
