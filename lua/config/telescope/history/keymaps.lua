---@module 'config.telescope.history.keymaps'
--- Provides key mappings for Telescope history navigation.
--- Automatically chooses mappings depending on whether the history backend is available.

local M = {}

local ok, history = pcall(require, "telescope._extensions.smart_history")
local actions = require("telescope.actions")

--- Return mappings for insert and normal mode based on history availability
--- @return table
function M.get()
  if ok and history.is_available() then
    return {
      i = {
        ["<C-p>"] = actions.cycle_history_prev,
        ["<C-n>"] = actions.cycle_history_next,
        ["<PageUp>"] = actions.preview_scrolling_up,
        ["<PageDown>"] = actions.preview_scrolling_down,
      },
      n = {
        ["<PageUp>"] = actions.preview_scrolling_up,
        ["<PageDown>"] = actions.preview_scrolling_down,
      },
    }
  else
    return {
      -- Fallback mappings without history
      i = {
        ["<PageUp>"] = actions.preview_scrolling_up,
        ["<PageDown>"] = actions.preview_scrolling_down,
      },
      n = {
        ["<PageUp>"] = actions.preview_scrolling_up,
        ["<PageDown>"] = actions.preview_scrolling_down,
      },
    }
  end
end

return M
