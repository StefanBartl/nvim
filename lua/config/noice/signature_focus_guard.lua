---@module 'noice.signature_focus_guard'
--- Keep Noice LSP signature popups from stealing focus.
--- Non-invasive guard: only acts during Insert-mode and only for floating windows.

---@class SigFocusGuard
local M = {}

-- Reentrancy guard to avoid loops
local _busy_until = 0

-- Timestamp helper (ms)
local function now_ms()
  local uv = vim.uv or vim.loop
  return uv.now()
end

-- Did we very recently enter or type in Insert-mode?
local last_insert_ms = 0
local function mark_insert_activity()
  last_insert_ms = now_ms()
end

-- Return true if 'win' is a floating window
local function is_float(win)
  local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
  return ok and cfg and cfg.relative ~= "" and cfg.relative ~= nil
end

-- Decide if we should bounce focus back to the edit window
local function should_bounce(win)
  -- Only guard around recent Insert activity (e.g., signature auto-open)
  if not vim.api.nvim_get_mode().mode:match("^i") and (now_ms() - last_insert_ms) > 250 then
    return false
  end
  if not is_float(win) then
    return false
  end

  -- Heuristics to avoid false positives on TUI popups:
  local buf = vim.api.nvim_win_get_buf(win)
  -- Noice docs/signature floats are 'nofile' and unmodifizierbar; das passt auch auf andere Docs-Floats.
  if vim.bo[buf].buftype ~= "nofile" then
    return false
  end
  return true
end

-- Attempt to restore focus to the previous edit window and re-enter insert
local function bounce_back(from_win)
  local ms = now_ms()
  if ms < _busy_until then
    return
  end
  _busy_until = ms + 150

  -- Prefer the last Insert window if valid; fallback: alternate window (#)
  local target = nil

  -- Try "window we were inserting in": current win before WinEnter is typically '#'
  local alt = vim.fn.win_getid(vim.fn.winnr("#"))
  if alt ~= 0 and vim.api.nvim_win_is_valid(alt) and not is_float(alt) then
    target = alt
  end

  -- If that fails, fall back to the previously recorded insert window
  if not target or not vim.api.nvim_win_is_valid(target) then
    -- Note: we do not globally store a dedicated "edit" win; optional enhancement below.
  end

  -- Final fallback: do nothing if we have no safe target
  if not target or not vim.api.nvim_win_is_valid(target) then
    _busy_until = 0
    return
  end

  vim.schedule(function()
    pcall(vim.api.nvim_set_current_win, target)
    -- Re-enter insert; keep cursor exactly where it was
    pcall(vim.cmd, "startinsert")
    _busy_until = 0
  end)
end

function M.setup()
  -- Track Insert-mode activity with low overhead
  vim.api.nvim_create_autocmd({ "InsertEnter", "InsertCharPre", "TextChangedI" }, {
    group = vim.api.nvim_create_augroup("NoiceSigFocusGuardInsert", { clear = true }),
    callback = function() mark_insert_activity() end,
    desc = "Mark recent Insert activity for signature focus guard",
  })

  -- If we enter a float right after Insert activity, bounce back
  vim.api.nvim_create_autocmd("WinEnter", {
    group = vim.api.nvim_create_augroup("NoiceSigFocusGuard", { clear = true }),
    callback = function(args)
      local win = args.win or vim.api.nvim_get_current_win()
      if should_bounce(win) then
        bounce_back(win)
      end
    end,
    desc = "Prevent focus from sticking to signature/hover floats during Insert",
  })
end

return M
