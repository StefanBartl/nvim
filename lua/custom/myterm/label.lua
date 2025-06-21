---@module 'myterm.label'
---@brief Dynamic label rendering for terminals (float border or virttext)

local M = {}
local ns = vim.api.nvim_create_namespace("myterm_labels")

--- Applies a label to a terminal buffer, depending on its layout mode
---@param term TerminalInstance
function M.apply(term)
  assert(term and type(term) == "table", "Invalid terminal instance")
  assert(term.buf and vim.api.nvim_buf_is_valid(term.buf), "Invalid terminal buffer")

  -- Clear existing extmarks (in case of refresh)
  vim.api.nvim_buf_clear_namespace(term.buf, ns, 0, -1)

  if term.mode == "float" and vim.api.nvim_win_is_valid(term.win) then
    -- Use floating window title (Neovim 0.9+)
    local ok, err = pcall(vim.api.nvim_win_set_config, term.win, {
      title = " Terminal " .. term.id .. " ",
      title_pos = "center",
    })
    if not ok then
      vim.notify("[myterm] Failed to set float title: " .. tostring(err), vim.log.levels.WARN)
    end
  else
    -- Add virttext label to bottom right of terminal
    local last_line = vim.api.nvim_buf_line_count(term.buf) - 1
    vim.api.nvim_buf_set_extmark(term.buf, ns, last_line, 0, {
      virt_text = { { "Terminal " .. term.id, "Comment" } },
      virt_text_pos = "right_align",
    })
  end
end

return M
