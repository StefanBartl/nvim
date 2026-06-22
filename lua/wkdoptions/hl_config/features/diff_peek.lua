---@module 'wkdoptions.hl_config.features.diff_peek'
--- Git hunk preview via gitsigns.nvim integration.
--- Maps `gh` to inline/float hunk preview when gitsigns is available.

local lazy = require("lib.lua.lazy")
local State = lazy.require("wkdoptions.hl_config.core.state")
local notify = lazy.require("lib.nvim.notify").create("[DiffPeek]")

local M = {}

--- Clear existing `gh` mapping (safe)
---@return nil
local function clear_mapping()
  pcall(vim.keymap.del, "n", "gh")
end

--- Install keymap with gitsigns integration
---@return nil
local function install_keymap()
  local ok, gs = pcall(require, "gitsigns")

  if not ok then
    -- Gitsigns not available: install fallback keymap with notification
    vim.keymap.set("n", "gh", function()
      notify.info("Diff peek requires gitsigns.nvim")
    end, { desc = "Git hunk peek (install gitsigns)" })
    return
  end

  -- Gitsigns available: use preview_hunk_inline (preferred) or preview_hunk
  vim.keymap.set("n", "gh", function()
    if type(gs.preview_hunk_inline) == "function" then
      gs.preview_hunk_inline()
    elseif type(gs.preview_hunk) == "function" then
      gs.preview_hunk()
    else
      notify.warn("Gitsigns loaded but preview functions unavailable")
    end
  end, { desc = "Git hunk peek" })
end

--- Install or remove keymap based on feature state
---@param _cfg WKDOptions.HL_CFG
---@return nil
---@diagnostic disable-next-line: unused-local
function M.enable(_cfg)
  clear_mapping()

  if not State.is_enabled("diff_peek") then
    return
  end

  install_keymap()
end

return M
