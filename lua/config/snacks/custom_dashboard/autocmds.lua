---@module 'config.snacks.custom_dashboard.autocmds'
--- Autocmd registrations for the custom dashboard.
--- Uses utils for safety checks and avoids opening dashboard over special/read-only buffers.
--- Defensive: failures are notified but non-fatal.

local api = vim.api
local nvim_create_autocmd = api.nvim_create_autocmd
local desc_tag = "[snacks.custom_dashboard]: "

local utils_ok, utils = pcall(require, "config.snacks.custom_dashboard.utils")
if not utils_ok then
  vim.notify("[custom_dashboard] utils not available; skipping autocmds", vim.log.levels.WARN)
  return {}
end

-- One-time discoverability hint (non-intrusive)
nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local ok_dash, dash = pcall(require, "snacks.dashboard")
    if ok_dash and type(dash.open) == "function" then
      vim.defer_fn(function()
        pcall(dash.open)
      end, 50)
    end
  end,
})


--- Decide whether it's safe to open the dashboard in the current window.
--- The heuristics intentionally conservative to avoid hijacking transient buffers.
local function safe_to_open_dashboard()
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end

  -- allow empty or unlisted buffers
  local name = vim.api.nvim_buf_get_name(bufnr) or ""
  local listed = vim.api.nvim_buf_get_option(bufnr, "buflisted")
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype") or ""
  local bt = vim.api.nvim_buf_get_option(bufnr, "buftype") or ""

  local forbidden = { help=true, qf=true, checkhealth=true, terminal=true, packer=true, TelescopePrompt=true }
  if forbidden[ft] or forbidden[bt] then return false end

  -- relax: open on empty OR unlisted buffer
  local empty = vim.api.nvim_buf_line_count(bufnr) == 1 and vim.api.nvim_buf_get_lines(bufnr,0,1,true)[1] == ""
  if not empty and listed then return false end

  -- optional: only if single window
  if vim.fn.winnr('$') ~= 1 then return false end

  return true
end

nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    local ok_dash, dash = pcall(require, "snacks.dashboard")
    if not ok_dash or type(dash.open) ~= "function" then
      return
    end

    -- Defer to let transient buffers finish initialization, then re-check handles.
    vim.defer_fn(function()
      -- re-validate safe condition (handles may have changed)
      if safe_to_open_dashboard() then
        pcall(dash.open)
      end
    end, 30)
  end,
  desc = desc_tag .. "open dashboard defensively on truly empty startup buffers",
})

return {}
