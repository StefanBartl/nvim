---@module 'config.menu.neotree.entries'
--- Complete entries table for Neo-tree custom context menu.
--- Each key from config.neotree.keymaps.window() is represented here with
--- an optional icon, human-readable label, and toggle for enabling/disabling.

require("config.@types.menu")

---@type custom_neotree_entry[]
local entries = {
  -- basics
  { key = "<Tab>", enabled = true, label = "Toggle preview", icon = "", rtxt = "<Tab>" },
  { key = "<2-LeftMouse>", enabled = true, label = "Open node", icon = "", rtxt = "<2-LeftMouse>" },
  { key = "<CR>", enabled = true, label = "Open / Expand node", icon = "", rtxt = "<CR>" },
  { key = "<S-CR>", enabled = true, label = "Open in background", icon = "", rtxt = "<S-CR>" },

  -- splits / tabs
  { key = "SV", enabled = true, label = "Split window vertically", icon = "🠕", rtxt = "SV" },
  { key = "SG", enabled = true, label = "Split window horizontally", icon = "🠖", rtxt = "SG" },
  { key = "l", enabled = true, label = "Open or toggle node", icon = "", rtxt = "l" },
  { key = "h", enabled = true, label = "Close node", icon = "", rtxt = "h" },
  { key = "C", enabled = true, label = "Close node", icon = "", rtxt = "C" },
  { key = "z", enabled = true, label = "Close all nodes", icon = "", rtxt = "z" },
  { key = "<C-r>", enabled = true, label = "Refresh", icon = "", rtxt = "<C-r>" },
  { key = "sv", enabled = true, label = "Open split", icon = "🠕", rtxt = "sv" },
  { key = "sg", enabled = true, label = "Open vsplit", icon = "🠖", rtxt = "sg" },
  { key = "st", enabled = true, label = "Open new tab", icon = "", rtxt = "st" },

  -- copy paths
  { key = "[p", enabled = true, label = "Copy absolute path (+)", icon = "󰈙", rtxt = "[p]" },
  { key = "]p", enabled = true, label = "Copy base dir path (+)", icon = "󰈙", rtxt = "]p" },
  { key = "]r", enabled = true, label = "Copy relative path (+)", icon = "󰈙", rtxt = "]r" },
  { key = "[r", enabled = true, label = "Copy relative base dir (+)", icon = "󰈙", rtxt = "[r]" },
  { key = "[t", enabled = true, label = "Copy recursive file list (abs)", icon = "󰈙", rtxt = "[t]" },
  { key = "[T", enabled = true, label = "Copy recursive file list (rel)", icon = "󰈙", rtxt = "[T]" },

  -- resize
  { key = "w", enabled = true, label = "Resize window (toggle small/normal/large)", icon = "󰣇", rtxt = "w" },

  -- open / system operations
  { key = "Y", enabled = true, label = "Copy Path to Clipboard", icon = "", rtxt = "Y" },
  { key = "O", enabled = true, label = "Open with System Application", icon = "", rtxt = "O" },
  { key = "M", enabled = true, label = "Open in system file manager", icon = "", rtxt = "M" },
  { key = "+", enabled = true, label = "Set Neovim cwd to node and focus Neo-tree", icon = "", rtxt = "+" },
  { key = "-", enabled = true, label = "Up one level (adjust CWD)", icon = "", rtxt = "-" },

  -- grep
  { key = "grep", enabled = true, label = "Live grep in node directory", icon = "", rtxt = "grep" },
}

return entries
