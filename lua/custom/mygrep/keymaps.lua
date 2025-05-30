---@module 'custom.mygrep.keymaps'
---@class KeymapManager
---@brief Sets up key mappings for the LiveGrepMemory system.
---@description
--- This module configures user key mappings to invoke registered grep tools via the
--- LiveGrepMemory API. It ensures lazy-compatibility and runtime safety.
---
---@param open fun(tool: string, opts?: table): boolean|nil

local M = {}

--- Sets up key mappings for LiveGrepMemory tools.
---@param open fun(tool: string, opts?: table): boolean|nil
---@return nil
function M.setup(open)
  if not vim or type(vim.keymap) ~= "table" then return end
  if type(open) ~= "function" then
    vim.notify("[mygrep.keymaps] Invalid .open function provided", vim.log.levels.ERROR)
    return
  end

  local map = vim.keymap.set
  local opts = { noremap = true, silent = true }

  map("n", "<leader>lg", function()
    local success = pcall(open, "live_grep", {})
    if not success then
      vim.notify("[MyGrep] Failed to open live_grep", vim.log.levels.ERROR)
    end
  end, vim.tbl_extend("force", opts, { desc = "LiveGrepMemory: Launch live_grep" }))

  map("n", "<leader>mg", function()
    local success = pcall(open, "multigrep", {})
    if not success then
      vim.notify("[MyGrep] Failed to open multigrep", vim.log.levels.ERROR)
    end
  end, vim.tbl_extend("force", opts, { desc = "MyGrep: Launch multigrep" }))
end

return M
