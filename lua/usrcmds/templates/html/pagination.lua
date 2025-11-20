---@module 'usrcmds.templates.html.pagination'
--- HTML Pagination Template
---
--- This module provides a user command to insert an HTML pagination template
--- at the current cursor position in Neovim.

local api = vim.api

--- Insert HTML pagination template at cursor position
---
--- Creates a complete HTML5 nav element for pagination controls.
--- The cursor is positioned at the id attribute for quick editing.
local function insert_html_pagination_template()
  -- Get current buffer and cursor position
  local bufnr = api.nvim_get_current_buf()
  local cursor = api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-indexed

  -- Define the template lines
  local template = {
    '<nav id="#pagination-" style="text-align: center; margin: 2em 0;">',
    '  <a href="#" style="padding: 0.5em 1em; margin: 0 0.2em; border: 1px solid #ddd; text-decoration: none;">← Previous</a>',
    '  <a href="#" style="padding: 0.5em 1em; margin: 0 0.2em; border: 1px solid #ddd; text-decoration: none;">Next →</a>',
    "</nav>",
  }

  -- Insert the template at cursor position
  api.nvim_buf_set_lines(bufnr, row, row, false, template)

  -- Position cursor at the id attribute (after "pagination-")
  -- Row is current line, column is position after "pagination-"
  local id_col = string.find(template[1], 'id="pagination%-', 1, true) + 15 -- Position after 'pagination-'
  api.nvim_win_set_cursor(0, { row + 1, id_col })

  -- Enter insert mode for immediate editing
  vim.cmd("startinsert")
end

--- Register the user command
api.nvim_create_user_command("HTMLPaginationTemplate", insert_html_pagination_template, {
  desc = "Insert HTML pagination template at cursor position",
})
