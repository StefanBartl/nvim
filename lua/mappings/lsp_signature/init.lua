---@module 'mappings.lsp_signature'
--- Provides a toggle mapping (<C-b>) that shows LSP signature help
--- or hover info in a floating window. The popup remains until <C-b> is pressed again.

local M = {}

local api = vim.api
local request_and_show = require("mappings.lsp_signature.request_and_show")

-- Keep track of currently open popup
M._popup_winid = nil
M._popup_bufnr = nil

--- Setup function: installs a toggle mapping for <C-b> in insert and normal mode.
function M.setup()
  local lhs = "<C-b>"

  vim.keymap.set({"i", "n"}, lhs, function()
    if M._popup_winid and api.nvim_win_is_valid(M._popup_winid) then
      -- Popup is open → close
      pcall(api.nvim_win_close, M._popup_winid, true)
      M._popup_winid = nil
      M._popup_bufnr = nil
    else
      -- Popup not open → show
      request_and_show(api.nvim_get_current_buf(), function(bufnr, winid)
        M._popup_bufnr = bufnr
        M._popup_winid = winid
      end)
    end
  end, { desc = "[LSP] Toggle signature/hover popup", silent = true, noremap = true })
end

return M
