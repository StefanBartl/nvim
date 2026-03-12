---@module 'config.snacks.picker'
---@brief Snacks picker configuration with custom actions and keymaps
---@description
--- Provides a complete configuration for snacks.nvim picker with:
--- - Custom actions (create_file, open_background)
--- - Enhanced keymaps (PageUp/Down, Ctrl+Left/Right for preview)
--- - Shared history with Telescope (SQLite or file-based)
---
--- Usage:
---   local picker_config = require("config.snacks.picker")
---   local snacks_opts = picker_config.get_config()
---
---   -- In your snacks.nvim setup:
---   require("snacks").setup({
---     picker = vim.tbl_deep_extend("force", { enabled = true }, snacks_opts)
---   })

local actions = require("config.snacks.picker.actions")
local keymaps = require("config.snacks.picker.keymaps")

local M = {}

---Get complete picker configuration
---@return table config Snacks picker configuration
function M.get_config()

  -- Get custom actions
  local custom_actions = actions.get_actions()

  -- Get keymaps
  local list_keys = keymaps.get_list_keys()
  local preview_keys = keymaps.get_preview_keys()

  return {
    -- Enable picker
    enabled = true,

    -- Custom actions
    actions = custom_actions,

    -- Window configuration with keymaps
    win = {
      -- List window keymaps
      list = {
        keys = list_keys,
      },

      -- Preview window keymaps
      preview = {
        keys = preview_keys,
      },
    },

    -- Preview configuration
    preview = {
      -- Disable line wrapping by default (like Telescope)
      wrap = false,
    },
  }
end

---Setup and merge with existing opts
---@param opts? table Existing snacks picker options
---@return table config Merged configuration
function M.setup(opts)
  opts = opts or {}

  local config = M.get_config()

  -- Merge with existing opts
  return vim.tbl_deep_extend("force", config, opts)
end

---Get only actions (for manual integration)
---@return table<string, function> actions
function M.get_actions()
  return actions.get_actions()
end

---Get only keymaps (for manual integration)
---@return {input: table, list: table, preview: table} keymaps
function M.get_keymaps()
  return {
    list = keymaps.get_list_keys(),
    preview = keymaps.get_preview_keys(),
  }
end


return M
