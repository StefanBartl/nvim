---@module 'custom.lsp_signature.open_floating_preview'
local api = vim.api
local lsp_util = vim.lsp.util

---@param lines string[]
return function(lines)
  if not lines or vim.tbl_isempty(lines) then
    return nil
  end

  -- Trim leading/trailing empty lines
  while #lines > 0 and lines[1] == "" do table.remove(lines, 1) end
  while #lines > 0 and lines[#lines] == "" do table.remove(lines, #lines) end
  if #lines == 0 then return nil end

  -- Filetype für LSP-Syntax / Highlights
  local filetype = "markdown"

  -- Optionen für das Floating Window
  local opts = {
    focusable = true,       -- Fokus erlaubt Scroll/Copy
    border = "rounded",     -- gerundeter Rahmen
    max_width = math.floor(vim.o.columns * 0.6),
  }

  -- Öffne das Floating Window über LSP util (korrekt modifiable)
  local bufnr, winid = lsp_util.open_floating_preview(lines, filetype, opts)
  api.nvim_set_option_value("modifiable", true, { buf = bufnr })

  if bufnr and api.nvim_buf_is_valid(bufnr) then
    -- Mapping für Esc: Popup schließen
    api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", "<Cmd>close<CR>", {
      nowait = true,
      noremap = true,
      silent = true,
    })

    -- Optional: Buffer readonly (nachdem Lines gesetzt sind)
    api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  end

  return bufnr, winid
end
