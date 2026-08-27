---@module 'wkdoptions.hl_config.features.flash'
--- Yank and Put flash feedback with safe timer handling and range validation.

local lazy = require("lib.lua.lazy")
local State = lazy.require("wkdoptions.hl_config.core.state")
local Autocmd = lazy.require("lib.nvim.bindings.autocmd")

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
    pcall(
      vim.hl.range,
      bufnr,
      ns,
      group,
      { srow, scol },
      { erow, ecol },
      { inclusive = true, priority = 90 }
    )
  elseif vim.highlight and type(vim.highlight.range) == "function" then
    pcall(
      vim.highlight.range,
      bufnr,
      ns,
      group,
      { srow, scol },
      { erow, ecol },
      { inclusive = true, priority = 90 }
    )
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

--- Whether the put flash is switched on.
---
--- Set by `enable()`, so it is false until wkdoptions has been set up at all.
---@type boolean
local put_flash_on = false

--- Whether a paste should flash the region it wrote.
---
--- Asked by whoever owns `p`/`P` -- see `M.flash_put`.
---@return boolean
function M.put_flash_enabled()
  return put_flash_on
end

--- Flash the region a put just wrote.
---
--- This used to install its own `p`/`P` mappings, which put it in a fight with
--- `bindings.mappings.editing`'s trimming paste over the same two keys. It
--- lost that fight: the trimming paste is registered on `UIReady` and
--- therefore later, so the flash was configured on and did **nothing**.
---
--- The two were never in conflict about behaviour, only about the key. One
--- decides *what* gets pasted, the other adds feedback *afterwards*. So the
--- paste owner calls this and both happen on one keypress.
---
--- No `feedkeys` replay is needed: `nvim_put` sets the `[` and `]` marks this
--- reads, exactly as a native `p` does.
---@return nil
function M.flash_put()
  if not put_flash_on then
    return
  end
  M.flash_changed("PutFlash", 160)
end

--- Main entry point
---@param cfg WKDOptions.HL_CFG
---@return nil
function M.enable(cfg)
  if State.is_enabled("yank_flash") then
    M.enable_yank()
  end

  -- `map_put_flash` no longer installs anything -- nothing here maps `p`/`P`
  -- any more. It is still honoured as the switch it effectively was: someone
  -- who set it to `false` did so to stop the put flash, and that is what it
  -- still means.
  put_flash_on = State.is_enabled("put_flash") and cfg.map_put_flash ~= false
end

return M
