---@module 'wkdnvchad.ui.statusline.modules.replacer_progress'

return function()
  local ok, sl = pcall(require, "lib.nvim.progress.styles.statusline")
  if not ok then return "" end

  local active = sl.active() -- string[], oldest first, shared across all lib.nvim.progress users
  if #active == 0 then return "" end

  -- Same highlight convention as neotest_module: blue while running.
  return " %#St_LspProgress#󰥩 " .. active[1] .. " "
end

