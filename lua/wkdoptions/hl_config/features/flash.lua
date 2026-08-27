---@module 'wkdoptions.hl_config.features.flash'
--- Yank and Put flash feedback with safe timer handling and range validation.

local lazy = require("lib.lua.lazy")
local State = lazy.require("wkdoptions.hl_config.core.state")
local Autocmd = lazy.require("lib.nvim.bindings.autocmd")
local map = require("lib.nvim.bindings.keymap")

local M = {}

--- Flash a region with timer cleanup (safe)
---@param group string
---@param ms integer
---@param bufnr integer
---@param srow integer
---@param scol integer
---@param erow integer
---@param ecol integer
---@return nil
local function flash_region(group, ms, bufnr, srow, scol, erow, ecol)
  local ns = State.get_namespace("Flash")

  -- Clear any previous flash
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)

  -- Normalize columns (marks can return -1)
  scol = math.max(scol, 0)
  ecol = math.max(ecol, 0)

  -- Try modern API first
  if vim.hl and type(vim.hl.range) == "function" then
    pcall(vim.hl.range, bufnr, ns, group, { srow, scol }, { erow, ecol }, { inclusive = true, priority = 90 })
  elseif vim.highlight and type(vim.highlight.range) == "function" then
    pcall(vim.highlight.range, bufnr, ns, group, { srow, scol }, { erow, ecol }, { inclusive = true, priority = 90 })
  else
    -- Fallback to extmark
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, srow, scol, {
      end_row = erow,
      end_col = ecol,
      hl_group = group,
      priority = 90,
    })
  end

  -- Timer cleanup
  local uv = vim.uv or vim.loop
  local timer = uv.new_timer()
  if not timer then
    return
  end

  timer:start(ms, 0, function()
    timer:stop()
    timer:close()
    vim.schedule(function()
      if vim.api.nvim_buf_is_loaded(bufnr) then
        pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
      end
    end)
  end)
end

--- Flash the changed region (uses marks '[' and ']')
---@param group string
---@param ms integer
---@return nil
function M.flash_changed(group, ms)
  local bufnr = vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local ok_s, smark = pcall(vim.api.nvim_buf_get_mark, bufnr, "[")
  local ok_e, emark = pcall(vim.api.nvim_buf_get_mark, bufnr, "]")

  if not ok_s or not ok_e then
    return
  end

  local srow, scol = smark[1], smark[2]
  local erow, ecol = emark[1], emark[2]

  if srow == 0 or erow == 0 then
    return
  end

  -- Convert to 0-based
  srow = srow - 1
  erow = erow - 1

  flash_region(group, ms, bufnr, srow, scol, erow, ecol)
end

--- Install yank flash autocmd
---@return nil
function M.enable_yank()
  local aug = State.get_augroup("Flash", true)

  Autocmd.create("TextYankPost", function()
    local on_yank = (vim.hl and vim.hl.on_yank) or vim.highlight.on_yank
    on_yank({ higroup = "YankFlash", timeout = 150, on_visual = true })
  end, {
    group = aug,
    desc = "Flash yanked text region",
  })
end

--- Install put flash mappings
---@return nil
function M.enable_put()
  -- Clear old mappings
  pcall(vim.keymap.del, "n", "p")
  pcall(vim.keymap.del, "n", "P")

  local function paste_and_flash(which)
    return function()
      vim.api.nvim_feedkeys(which, "n", false)
      vim.schedule(function()
        M.flash_changed("PutFlash", 160)
      end)
    end
  end

  map("n", "p", paste_and_flash("p"), { noremap = true, silent = true, desc = "Paste (flash)" })
  map("n", "P", paste_and_flash("P"), { noremap = true, silent = true, desc = "Paste before (flash)" })
end

--- Main entry point
---@param cfg WKDOptions.HL_CFG
---@return nil
function M.enable(cfg)
  if State.is_enabled("yank_flash") then
    M.enable_yank()
  end

  if State.is_enabled("put_flash") and cfg.map_put_flash then
    M.enable_put()
  end
end

return M
