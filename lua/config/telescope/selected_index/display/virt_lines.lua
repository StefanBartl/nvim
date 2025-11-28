---@module 'config.telescope.selected_files.display.virt_lines'
--- Use virt_lines to render index above or below the selected entry, avoiding overlay issues.
-- Problem:
-- 'draw above == true', also Index über der aktuellen Zeile, funktioniert erst ab Zeile 2 (über Zeile 1 kann nichts gezeichnet werden)
-- 'draw above == false', also Index unter der aktuellen Zeile, funktioniert mur bis zur vorletzten Zeile (unter der letzten Zeile kann nichts gezeichnet werden)

---@param bufnr number
---@param ns number
---@param row number
---@param index number
---@param above boolean -- true to draw above, false to draw below
return function (bufnr, ns, row, index, above)
  local virt_line = { { tostring(index) .. ". ", "TelescopeResultsFunction" } }
  local opts = {
    virt_lines = { virt_line },
    virt_lines_above = above == true,
    hl_mode = "combine",
    -- optionally set ephemeral flags e.g. ephemeral = true (if supported)
  }
  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, 0, opts)
end

