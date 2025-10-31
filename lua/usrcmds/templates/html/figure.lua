---@module 'usrcmds.templates.html.figure_template'
--- HTML Figure Template Command
---
--- This module provides a user command to insert an HTML figure template
--- at the current cursor position in Neovim.

local api = vim.api

--- Insert HTML figure template at cursor position
---
--- Creates a complete HTML5 figure element with image and figcaption.
--- The cursor is positioned at the id attribute for quick editing.
local function insert_html_figure_template()
  -- Get current buffer and cursor position
  local bufnr = api.nvim_get_current_buf()
  local cursor = api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-indexed

  -- Define the template lines
  local template = {
    '<figure style="text-align:center;" id="#fig-tbl-">',
    '  <img src="" alt="">',
    '  <figcaption></figcaption>',
    '</figure>',
  }

  -- Insert the template at cursor position
  api.nvim_buf_set_lines(bufnr, row, row, false, template)

  -- Position cursor at the id attribute (after "fig-tbl-")
  -- Row is current line, column is position after "fig-tbl-"
  local id_col = string.find(template[1], 'id="fig%-tbl%-') + 13 -- Position after 'fig-tbl-'
  api.nvim_win_set_cursor(0, { row + 1, id_col })

  -- Enter insert mode for immediate editing
  vim.cmd('startinsert')
end

--- Register the user command
api.nvim_create_user_command('HTMLFigureTemplate', insert_html_figure_template, {
  desc = 'Insert HTML figure template at cursor position',
})
