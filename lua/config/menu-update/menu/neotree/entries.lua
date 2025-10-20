---@module 'config.menu.neotree.entries'
--- Entries table für Neo-tree context menu mit node_type Filter ("any", "file", "folder").

---@type custom_neotree_entry[]
local entries = {
  -- Basic navigation
  {
    name = "  Basic",
    hl = "ExYellow",
    items = {
      { key = "<Tab>", enabled = true, label = "Toggle preview", icon = "", rtxt = "<Tab>", node_type = "file" },
      { key = "<2-LeftMouse>", enabled = true, label = "Open node", icon = "", rtxt = "<2-LeftMouse>", node_type = "folder" },
      { key = "<CR>", enabled = true, label = "Open / Expand node", icon = "", rtxt = "<CR>", node_type = "folder" },
      { key = "<S-CR>", enabled = true, label = "Open in background", icon = "", rtxt = "<S-CR>", node_type = "file" },
    },
  },

  -- Window / Tab management (nur Dateien)
  {
    name = "󰕱  Splits & Tabs",
    hl = "ExGreen",
    items = {
      { key = "SV", enabled = true, label = "Split window vertically", icon = "🠕", rtxt = "SV", node_type = "file" },
      { key = "SG", enabled = true, label = "Split window horizontally", icon = "🠖", rtxt = "SG", node_type = "file" },
      { key = "sv", enabled = true, label = "Open split", icon = "🠕", rtxt = "sv", node_type = "file" },
      { key = "sg", enabled = true, label = "Open vsplit", icon = "🠖", rtxt = "sg", node_type = "file" },
      { key = "st", enabled = true, label = "Open new tab", icon = "", rtxt = "st", node_type = "file" },
    },
  },

  -- Node operations (nur Ordner)
  {
    name = "󰉋  Node Actions",
    hl = "ExCyan",
    items = {
      { key = "l", enabled = true, label = "Open or toggle node", icon = "", rtxt = "l", node_type = "folder" },
      { key = "h", enabled = true, label = "Close node", icon = "", rtxt = "h", node_type = "folder" },
      { key = "C", enabled = true, label = "Close node", icon = "", rtxt = "C", node_type = "folder" },
      { key = "z", enabled = true, label = "Close all nodes", icon = "", rtxt = "z", node_type = "folder" },
      { key = "<C-r>", enabled = true, label = "Refresh", icon = "", rtxt = "<C-r>", node_type = "any" },
    },
  },

  -- Copy / Path operations
  {
    name = "󰈙  Copy & Path",
    hl = "ExBlue",
    items = {
      { key = "[p", enabled = true, label = "Copy absolute path (+)", icon = "󰈙", rtxt = "[p]", node_type = "any" },
      { key = "]p", enabled = true, label = "Copy base dir path (+)", icon = "󰈙", rtxt = "]p", node_type = "folder" },
      { key = "]r", enabled = true, label = "Copy relative path (+)", icon = "󰈙", rtxt = "]r", node_type = "any" },
      { key = "[r", enabled = true, label = "Copy relative base dir (+)", icon = "󰈙", rtxt = "[r]", node_type = "any" },
      { key = "[t", enabled = true, label = "Copy recursive file list (abs)", icon = "󰈙", rtxt = "[t]", node_type = "any" },
      { key = "[T", enabled = true, label = "Copy recursive file list (rel)", icon = "󰈙", rtxt = "[T]", node_type = "any" },
      { key = "Y", enabled = true, label = "Copy Path to Clipboard", icon = "", rtxt = "Y", node_type = "any" },
    },
  },

  -- Resize (immer sichtbar)
  {
    name = "󰣇  Resize",
    hl = "ExMagenta",
    items = {
      { key = "w", enabled = true, label = "Resize window (toggle small/normal/large)", icon = "󰣇", rtxt = "w", node_type = "any" },
    },
  },

  -- System / Clipboard (immer sichtbar)
  {
    name = "󰈙  System & Clipboard",
    hl = "ExBlue",
    items = {
      { key = "O", enabled = true, label = "Open with System Application", icon = "", rtxt = "O", node_type = "any" },
      { key = "M", enabled = true, label = "Open in system file manager", icon = "", rtxt = "M", node_type = "any" },
      { key = "+", enabled = true, label = "Set Neovim cwd to node and focus Neo-tree", icon = "", rtxt = "+", node_type = "any" },
      { key = "-", enabled = true, label = "Up one level (adjust CWD)", icon = "", rtxt = "-", node_type = "folder" },
    },
  },

  -- Grep (nur Ordner)
  {
    name = "  Search",
    hl = "ExOrange",
    items = {
      { key = "grep", enabled = true, label = "Live grep in node directory", icon = "", rtxt = "grep", node_type = "folder" },
    },
  },
}

return entries
