---@module 'usrcmds.templates.html.aside'
--- HTML Aside Template for Sidebar Content
---
--- This module provides a user command to insert an HTML aside template
--- at the current cursor position in Neovim.

local api = vim.api

--- Insert HTML aside template at cursor position
---
--- Creates a complete HTML5 aside element for sidebar or supplementary content.
--- The cursor is positioned at the id attribute for quick editing.
local function insert_html_aside_template()
  -- Get current buffer and cursor position
  local bufnr = api.nvim_get_current_buf()
  local cursor = api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-indexed

  -- Define the template lines
  local template = {
    '<aside id="#aside-" style="border-left: 3px solid #ddd; padding-left: 1em; margin: 1em 0;">',
    '  <strong>Note:</strong> ',
    '</aside>',
  }

  -- Insert the template at cursor position
  api.nvim_buf_set_lines(bufnr, row, row, false, template)

  -- Position cursor at the id attribute (after "aside-")
  -- Row is current line, column is position after "aside-"
  local id_col = string.find(template[1], 'id="aside%-', 1, true) + 10 -- Position after 'aside-'
  api.nvim_win_set_cursor(0, { row + 1, id_col })

  -- Enter insert mode for immediate editing
  vim.cmd('startinsert')
end

--- Register the user command
api.nvim_create_user_command('HTMLAsideTemplate', insert_html_aside_template, {
  desc = 'Insert HTML aside template at cursor position',
})
