---@module 'custom.mygrep.keymaps'
---@class KeymapManager
---@brief Sets up key mappings for the LiveGrepMemory system.
---@description
--- This module configures user key mappings to invoke registered grep tools via the
--- LiveGrepMemory API. It demonstrates how to safely bind keys in Neovim using pcall,
--- type guards, and proper error handling. The mappings provided include a default
--- live grep and multigrep invocation.
---
--- Example key mappings (using <leader> prefix):
--- - `<leader>lg` : Launch live_grep tool (memory-enabled)
--- - `<leader>mg` : Launch multigrep tool (memory-enabled)
---
--- The functions check for environment validity and use secure pcall wrappers to
--- prevent runtime errors from affecting user workflow.
local M = {}

--- Sets up key mappings for LiveGrepMemory tools.
--- @return nil
function M.setup()
  -- Ensure Neovim API is available
  if type(vim) ~= "table" or type(vim.keymap) ~= "table" then
    error("Neovim API is not available")
  end

  -- Use pcall to safely set key mappings
  local status, err = pcall(function()
    -- Map <leader>lg to open the "live_grep" tool
    vim.keymap.set("n", "<leader>lg", function()
      local ok = pcall(function()
        local lg = require("custom.mygrep")
        -- call the open function with "live_grep" as tool name and no additional options
        lg.open("live_grep", {})
      end)
      if not ok then
        vim.notify("[MyGrep] Failed to open live_grep", vim.log.levels.ERROR)
      end
    end, { noremap = true, silent = true, desc = "LiveGrepMemory: Launch live_grep" })

    -- Map <leader>mg to open the "multigrep" tool
    vim.keymap.set("n", "<leader>mg", function()
      local ok = pcall(function()
        local lg = require("custom.mygrep")
        -- call the open function with "multigrep" as tool name and no additional options
        lg.open("multigrep", {})
      end)
      if not ok then
        vim.notify("[MyGrep] Failed to open multigrep", vim.log.levels.ERROR)
      end
    end, { noremap = true, silent = true, desc = "MyGrep: Launch multigrep" })
  end)

  if not status then
    vim.notify("[MyGrep] Error setting key mappings: " .. tostring(err), vim.log.levels.ERROR)
  end
end

return M
