---@module 'config.telescope.selected_files.place_index'
--- Use virt_text with eol or right_align to avoid overlaying start of line.

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

