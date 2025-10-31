---@module 'usrcmds.templates.html.quote'
--- HTML Quote with Citation Template
---
--- This module provides a user command to insert an HTML quote template
--- with citation at the current cursor position in Neovim.

local api = vim.api

--- Insert HTML quote template at cursor position
---
--- Creates a complete HTML5 figure element with blockquote and citation.
--- The cursor is positioned at the id attribute for quick editing.
local function insert_html_quote_template()
  -- Get current buffer and cursor position
  local bufnr = api.nvim_get_current_buf()
  local cursor = api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-indexed

  -- Define the template lines
  local template = {
    '<figure id="quote-">',
    '  <blockquote style="border-left: 4px solid #ddd; padding-left: 1em; margin: 1em 0; font-style: italic;">',
    '    ',
    '  </blockquote>',
    '  <figcaption style="text-align: right;">— </figcaption>',
    '</figure>',
  }

  -- Insert the template at cursor position
  api.nvim_buf_set_lines(bufnr, row, row, false, template)

  -- Position cursor at the id attribute (after "quote-")
  -- Row is current line, column is position after "quote-"
  local id_col = string.find(template[1], 'id="quote%-', 1, true) + 10 -- Position after 'quote-'
  api.nvim_win_set_cursor(0, { row + 1, id_col })

  -- Enter insert mode for immediate editing
  vim.cmd('startinsert')
end

--- Register the user command
api.nvim_create_user_command('HTMLQuoteTemplate', insert_html_quote_template, {
  desc = 'Insert HTML quote with citation template at cursor position',
})
