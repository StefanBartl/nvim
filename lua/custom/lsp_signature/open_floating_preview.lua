---@module 'custom.lsp_signature.open_floating_preview'
local api = vim.api
local lsp_util = vim.lsp.util
local state = require("custom.lsp_signature.state")

---@param lines string[]
return function(lines)
  if not lines or vim.tbl_isempty(lines) then
    return nil
  end

  -- Trim leading/trailing empty lines
  while #lines > 0 and lines[1] == "" do
    table.remove(lines, 1)
  end
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines, #lines)
  end
  if #lines == 0 then
    return nil
  end

  -- Filetype für LSP-Syntax / Highlights
  local filetype = "markdown"

  -- Optionen für das Floating Window
  local opts = {
    focusable = true, -- Fokus erlaubt Scroll/Copy
    border = "rounded", -- gerundeter Rahmen
    max_width = math.floor(vim.o.columns * 0.6),
  }

  -- Öffne das Floating Window über LSP util (korrekt modifiable)
  local bufnr, winid = lsp_util.open_floating_preview(lines, filetype, opts)
  api.nvim_set_option_value("modifiable", true, { buf = bufnr })

  -- Buffer-local mappings to close the popup and clear state.
  -- They call the state.close() function to ensure module state is consistent.
  local map_opts = { nowait = true, noremap = true, silent = true }
  api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", "<Cmd>lua require('custom.lsp_signature.state').close()<CR>", map_opts)
  api.nvim_buf_set_keymap(bufnr, "n", "q", "<Cmd>lua require('custom.lsp_signature.state').close()<CR>", map_opts)

  -- Additionally, support 'q' in visual mode inside popup for convenience
  api.nvim_buf_set_keymap(bufnr, "v", "q", "<Cmd>lua require('custom.lsp_signature.state').close()<CR>", map_opts)

  -- Create an augroup to ensure cleanup if window is closed externally
  local group_name = "LspSignaturePopup_" .. tostring(winid)
  local aug_id = api.nvim_create_augroup(group_name, { clear = true })
  api.nvim_create_autocmd({ "BufWipeout", "BufHidden", "BufLeave" }, {
    group = aug_id,
    once = true,
    buffer = bufnr,
    callback = function()
      -- ensure state cleared if popup buffer goes away
      pcall(state.close)
      pcall(api.nvim_del_augroup_by_id, aug_id)
    end,
  })

  return bufnr, winid
end
