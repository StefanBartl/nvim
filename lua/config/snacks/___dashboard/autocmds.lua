---@module 'config.snacks.dashboard.autocmds'
--- Autocmds for snacks dashboard with safer guards to avoid hijacking special buffers.
--- This file contains defensive checks to prevent the dashboard opening while other
--- tools (like :checkhealth) are writing to their buffers.

local nvim_create_autocmd = vim.api.nvim_create_autocmd
local desc_tag = "[snacks.dashboard]: "

-- Small discoverability hint (non-intrusive, once).
nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      vim.notify("Snacks ready · dashboard with Sessions loaded", vim.log.levels.DEBUG)
    end, 50)
  end,
  desc = desc_tag .. "Snacks init hint",
})

-- Helper: decide whether it's safe to open the dashboard in the current window.
local function safe_to_open_dashboard()
  -- English comments inside code by requirement.

  -- current buffer/window info
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr) or ""
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr }) or ""
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr }) or ""
  local modifiable = vim.api.nvim_get_option_value("modifiable", { buf = bufnr })
  local buflisted = vim.api.nvim_get_option_value("buflisted", { buf = bufnr })

  -- Exclude special buftypes and filetypes that are typically not user-edit buffers.
  local forbidden_filetypes = {
    help = true,
    qf = true,
    checkhealth = true,
    terminal = true,
    packer = true,
    ["TelescopePrompt"] = true,
  }
  if forbidden_filetypes[filetype] or forbidden_filetypes[buftype] then
    return false
  end

  -- If buffer has a name (file or special) -> do not open over it.
  if bufname ~= "" then
    return false
  end

  -- Only open when the buffer is modifiable (avoid interfering with read-only output buffers).
  if not modifiable then
    return false
  end

  -- Require that we are in the single-window startup scenario to avoid mid-session hijack.
  if vim.fn.winnr("$") ~= 1 then
    return false
  end

  -- If the buffer is not listed, still allow only if it's a plain empty buffer.
  if not buflisted and vim.api.nvim_buf_line_count(bufnr) > 1 then
    return false
  end

  return true
end

nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    local ok_dash, dash = pcall(require, "snacks.dashboard")
    if not ok_dash or type(dash.open) ~= "function" then
      return
    end

    -- Defer a tick to let transient buffers finish initialization, then re-check.
    vim.defer_fn(function()
      if safe_to_open_dashboard() then
        -- final protection: pcall to avoid crashing if dash.open errors
        pcall(dash.open)
      end
    end, 30)
  end,
  desc = desc_tag .. "Open custom Snacks dashboard on startup or truly empty buffer (defensive)",
})
