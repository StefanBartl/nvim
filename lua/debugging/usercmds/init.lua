---@module 'debugging.usercmds'

local buflib = require("lib.buf_win_tab.windows_utils")
local tablib = require("lib.buf_win_tab.tabs_utils")

local M = {}

---Collect window report for current or specified window
---@param winid integer|nil
---@return { textual: string[], raw: table }
local function collect_win_report(winid)
  winid = winid or vim.api.nvim_get_current_win()
  local api = vim.api

  if not api.nvim_win_is_valid(winid) then
    return {
      textual = { string.format("Window %d is invalid", winid) },
      raw = { valid = false, winid = winid }
    }
  end

  local report = { textual = {}, raw = {} }

  -- Basic window info
  local ok_buf, bufnr = pcall(api.nvim_win_get_buf, winid)
  local ok_cursor, cursor = pcall(api.nvim_win_get_cursor, winid)
  local ok_config, config = pcall(api.nvim_win_get_config, winid)

  report.raw.winid = winid
  report.raw.bufnr = ok_buf and bufnr or nil
  report.raw.cursor = ok_cursor and cursor or nil
  report.raw.config = ok_config and config or nil

  table.insert(report.textual, string.format("=== Window Report: %d ===", winid))
  table.insert(report.textual, string.format("Valid: %s", "true"))
  table.insert(report.textual, string.format("Buffer: %s", ok_buf and bufnr or "ERROR"))

  if ok_buf and bufnr then
    local ok_name, name = pcall(api.nvim_buf_get_name, bufnr)
    local ok_ft, ft = pcall(function() return vim.bo[bufnr].filetype end)
    local ok_bt, bt = pcall(function() return vim.bo[bufnr].buftype end)

    report.raw.buf_name = ok_name and name or nil
    report.raw.filetype = ok_ft and ft or nil
    report.raw.buftype = ok_bt and bt or nil

    table.insert(report.textual, string.format("  Name: %s", ok_name and name or "ERROR"))
    table.insert(report.textual, string.format("  Filetype: %s", ok_ft and ft or "ERROR"))
    table.insert(report.textual, string.format("  Buftype: %s", ok_bt and bt or "ERROR"))
  end

  if ok_cursor then
    table.insert(report.textual, string.format("Cursor: [%d, %d]", cursor[1], cursor[2]))
  end

  -- Window options
  local win_opts = {
    "number", "relativenumber", "wrap", "cursorline",
    "winbar", "statusline", "signcolumn", "foldcolumn"
  }

  table.insert(report.textual, "Window Options:")
  for _, opt in ipairs(win_opts) do
    local ok, val = pcall(function() return vim.wo[winid][opt] end)
    if ok then
      report.raw[opt] = val
      table.insert(report.textual, string.format("  %s: %s", opt, tostring(val)))
    end
  end

  -- Window variables
  local win_vars = vim.w[winid] or {}
  if next(win_vars) then
    table.insert(report.textual, "Window Variables:")
    for k, v in pairs(win_vars) do
      report.raw.vars = report.raw.vars or {}
      report.raw.vars[k] = v
      table.insert(report.textual, string.format("  %s: %s", k, tostring(v)))
    end
  end

  -- Window configuration
  if ok_config then
    table.insert(report.textual, "Window Config:")
    table.insert(report.textual, string.format("  Relative: %s", config.relative or "editor"))
    table.insert(report.textual, string.format("  Width: %s", config.width or "full"))
    table.insert(report.textual, string.format("  Height: %s", config.height or "full"))
    table.insert(report.textual, string.format("  Focusable: %s", tostring(config.focusable)))
    if config.zindex then
      table.insert(report.textual, string.format("  Z-Index: %d", config.zindex))
    end
  end

  return report
end

---@return nil
function M.attach()
  vim.api.nvim_create_user_command("BufReport", function()
    local r = buflib.collect_report()
    for _, l in ipairs(r.textual) do
      vim.notify(l, vim.log.levels.INFO)
    end
  end, { desc = "[debugging] Prints a Buffer-Report to :messages" })

  vim.api.nvim_create_user_command("TabReport", function()
    local r = tablib.collect_report()
    for _, l in ipairs(r.textual) do
      vim.notify(l, vim.log.levels.INFO)
    end
  end, { desc = "[debugging] Prints a Tab-Report to :messages" })

  vim.api.nvim_create_user_command("WinReport", function(opts)
    local winid = nil
    if opts.args ~= "" then
      winid = tonumber(opts.args)
      if not winid or not vim.api.nvim_win_is_valid(winid) then
        vim.notify("Invalid window ID: " .. opts.args, vim.log.levels.ERROR)
        return
      end
    end

    local r = collect_win_report(winid)
    for _, l in ipairs(r.textual) do
      vim.notify(l, vim.log.levels.INFO)
    end
  end, {
    nargs = "?",
    desc = "[debugging] Prints a Window-Report to :messages (optional: specify window ID)"
  })
end

return M
