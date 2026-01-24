---@module 'wkdoptions.hl_config.features.signcolumn_tint'
--- SignColumn tinting based on worst diagnostic severity.
--- Uses winhighlight to dynamically change SignColumn background per buffer/window.

local State = require("wkdoptions.hl_config.core.state")
local Winhl = require("wkdoptions.hl_config.utils.winhighlight")
local is_ui = require("wkdoptions.hl_config.utils.skip").std_skip

local M = {}

--- Resolve SignColumn group based on worst diagnostic severity
---@nodiscard
---@param bufnr integer
---@return string -- HL group name
local function resolve_signcolumn_group(bufnr)
  local ok, diags = pcall(vim.diagnostic.get, bufnr)
  if not ok or not diags or #diags == 0 then
    return "SignColNeutral"
  end

  local worst = nil
  for i = 1, #diags do
    local sev = diags[i].severity
    if not worst or sev < worst then
      worst = sev
    end
  end

  if not worst then
    return "SignColNeutral"
  end

  local sev = vim.diagnostic.severity
  if worst == sev.ERROR then
    return "SignColError"
  elseif worst == sev.WARN then
    return "SignColWarn"
  elseif worst == sev.INFO then
    return "SignColInfo"
  elseif worst == sev.HINT then
    return "SignColHint"
  end

  return "SignColNeutral"
end

--- Apply tint to current window
---@return nil
function M.apply()
  if not State.is_enabled("signcolumn_tint") then
    return
  end

  if is_ui(0) then
    return
  end

  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local bufnr = vim.api.nvim_win_get_buf(win)
  local group = resolve_signcolumn_group(bufnr)

  local wh = Winhl.set_pair(vim.wo[win].winhighlight, "SignColumn", group)
  Winhl.apply_to_window(win, wh)
end

--- Remove tint (reset to neutral)
---@return nil
function M.clear()
  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local wh = Winhl.set_pair(vim.wo[win].winhighlight, "SignColumn", "SignColNeutral")
  Winhl.apply_to_window(win, wh)
end

--- Install autocmds
---@param _cfg WKDOptions.HL_CFG
---@return nil
function M.enable(_cfg)
  local aug = State.get_augroup("SigncolTint", true)

  if not State.is_enabled("signcolumn_tint") then
    -- Feature disabled: clear all tints
    vim.api.nvim_create_autocmd("BufEnter", {
      group = aug,
      callback = M.clear,
      desc = "Clear SignColumn tint (feature disabled)",
    })
    return
  end

  vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
    group = aug,
    callback = M.apply,
    desc = "Tint SignColumn based on worst diagnostic",
  })

  -- Initial apply
  M.apply()
end

return M
