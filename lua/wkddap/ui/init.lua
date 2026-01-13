---@module 'wkddap.ui'

local M = {}

function M.setup(opts)
  -- Setup signs
  local ok_signs, signs = pcall(require, "wkddap.ui.signs")
  if ok_signs then
    pcall(signs.setup)
  end

  -- Setup highlights
  local ok_hl, highlights = pcall(require, "wkddap.ui.highlights")
  if ok_hl then
    pcall(highlights.setup)
  end

  -- Setup DAP UI
  if opts.enable then
    local ok_dapui, dapui_mod = pcall(require, "wkddap.ui.dapui")
    if ok_dapui then
      pcall(dapui_mod.setup)
    end
  end

  -- Setup virtual text
  if opts.virtual_text then
    local ok_vt, virtual_text = pcall(require, "wkddap.ui.virtual_text")
    if ok_vt then
      pcall(virtual_text.setup)
    end
  end
end

return M
