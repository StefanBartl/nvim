---@module 'config.snacks.custom_dashboard.autocmds'
--- Defensive autocmds for the custom dashboard.
--- - VimEnter: ensure dashboard opens once at startup (guaranteed).
--- - BufWinEnter: defensive opener for truly empty buffers later in the session.

local api = vim.api
local desc_tag = "[snacks.custom_dashboard]: "

local ok_utils, utils = pcall(require, "config.snacks.custom_dashboard.utils")
if not ok_utils then
  vim.notify(desc_tag .. "utils not available; skipping autocmds", vim.log.levels.WARN)
  return {}
end

-- One-time discoverability hint (non-intrusive)
api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    -- Try to register and open the dashboard after a short delay to let startup finish.
    vim.defer_fn(function()
      local ok_dash, dash = pcall(require, "snacks.dashboard")
      if ok_dash and type(dash.open) == "function" then
        pcall(dash.open)
      end
    end, 50)
  end,
  desc = desc_tag .. "startup open",
})

--- Conservative check used for BufWinEnter (not used for VimEnter open)
local function safe_to_open_dashboard()
  local bufnr = api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  -- avoid obvious special buffers (help, checkhealth, terminal, etc.)
  if utils.is_special_buf(bufnr) then
    return false
  end

  -- allow if empty buffer OR unlisted buffer
  local listed = pcall(api.nvim_get_option_value, "buflisted", { buf = bufnr })
  if type(listed) == "table" then listed = listed[2] end
  if listed == nil then listed = true end

  local empty = utils.is_empty_buffer(bufnr)
  if not empty and listed then
    return false
  end

  -- prefer single-window situations
  if vim.fn.winnr('$') ~= 1 then
    return false
  end

  return true
end

api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    local ok_dash, dash = pcall(require, "snacks.dashboard")
    if not ok_dash or type(dash.open) ~= "function" then return end

    vim.defer_fn(function()
      if safe_to_open_dashboard() then
        pcall(dash.open)
      end
    end, 30)
  end,
  desc = desc_tag .. "defensive open on empty buffers",
})

return {}
