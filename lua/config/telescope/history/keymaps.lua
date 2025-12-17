---@module 'config.telescope.history.keymaps'
--- Provides key mappings for Telescope history navigation.
--- Automatically chooses mappings depending on whether the history backend is available.

local M = {}

local ok, _ = pcall(require, "telescope._extensions.smart_history")

--- Return mappings for insert and normal mode based on history availability
---@param actions table The actions table from telescope
---@return table
function M.get(actions)
  if ok then
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
