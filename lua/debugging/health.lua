---@module 'debugging.health'

local M = {}

function M.check()
  vim.health.start("Debug Views")

  -- Check clipboard providers
  local has_clipboard = false
  local providers = {"pbcopy", "wl-copy", "xclip", "xsel", "clip.exe"}

  for _, bin in ipairs(providers) do
    if vim.fn.executable(bin) == 1 then
      vim.health.ok(bin .. " available")
      has_clipboard = true
    end
  end

  if not has_clipboard then
    vim.health.warn("No clipboard provider found", {
      "Install: pbcopy (macOS) / wl-copy (Wayland) / xclip (X11) / clip.exe (WSL)"
    })
  end

  -- Check lib dependencies
  local ok_capture = pcall(require, "lib.nvim.buf_win_tab.capture")
  if ok_capture then
    vim.health.ok("lib.nvim.buf_win_tab.capture available")
  else
    vim.health.info("lib.nvim.buf_win_tab.capture not found (fallback mode active)")
  end

  local ok_buflib = pcall(require, "lib.nvim.buf_win_tab.windows_utils")
  if ok_buflib then
    vim.health.ok("lib.nvim.buf_win_tab.windows_utils available")
  else
    vim.health.warn("lib.nvim.buf_win_tab.windows_utils not found (BufReport unavailable)")
  end

  local ok_tablib = pcall(require, "lib.nvim.buf_win_tab.tabs_utils")
  if ok_tablib then
    vim.health.ok("lib.nvim.buf_win_tab.tabs_utils available")
  else
    vim.health.warn("lib.nvim.buf_win_tab.tabs_utils not found (TabReport unavailable)")
  end

  -- Check write permissions
  local state_dir = vim.fn.stdpath("state") .. "/debug_views"
  local ok_mkdir = pcall(vim.fn.mkdir, state_dir, "p")
  if ok_mkdir then
    vim.health.ok("Write permissions OK: " .. state_dir)
  else
    vim.health.error("Cannot write to: " .. state_dir)
  end
end

return M

