---@module 'config.telescope.selected_files.display.virt_text'
--- Use virt_text with 'overlay', 'eol' or 'right_align'
-- Problem:
-- 'overlay' zeichnet die Nummerierung über die ersten chars der aktuellen Zeile

---@param results_bufnr number
---@param ns number
---@param row number
---@param index number
---@param text_align "overlay"|"right_align"|"eol"
return function (results_bufnr, ns, row, index, text_align)
  local virt_text = { { tostring(index) .. ". ", "TelescopeResultsFunction" } }
  local opts = {
    virt_text = virt_text,
    hl_mode = "combine",
    virt_text_pos = text_align,
  }
  pcall(vim.api.nvim_buf_set_extmark, results_bufnr, ns, row, 0, opts)
end

