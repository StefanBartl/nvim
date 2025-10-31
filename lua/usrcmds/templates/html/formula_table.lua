---@module 'usrcmds.templates.html.formula_table'
--- HTML Formula Table Template
---
--- This module provides a user command to insert an HTML formula table template
--- at the current cursor position in Neovim.

local api = vim.api

--- Insert HTML formula table template at cursor position
---
--- Creates a complete HTML5 figure element with table for mathematical formulas.
--- The cursor is positioned at the id attribute for quick editing.
local function insert_html_formula_table_template()
  -- Get current buffer and cursor position
  local bufnr = api.nvim_get_current_buf()
  local cursor = api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-indexed

  -- Define the template lines
  local template = {
    '<figure id="tbl-formula-">',
    '  <table style="border-collapse: collapse; width: 100%;">',
    '    <caption><strong>Formeln:</strong> </caption>',
    '    <thead>',
    '      <tr>',
    '        <th style="border: 1px solid #ddd; padding: 8px;">Name</th>',
    '        <th style="border: 1px solid #ddd; padding: 8px;">Formula</th>',
    '        <th style="border: 1px solid #ddd; padding: 8px;">Variables</th>',
    '      </tr>',
    '    </thead>',
    '    <tbody>',
    '      <tr>',
    '        <td style="border: 1px solid #ddd; padding: 8px;"></td>',
    '        <td style="border: 1px solid #ddd; padding: 8px;">$  $</td>',
    '        <td style="border: 1px solid #ddd; padding: 8px;"></td>',
    '      </tr>',
    '    </tbody>',
    '  </table>',
    '</figure>',
  }

  -- Insert the template at cursor position
  api.nvim_buf_set_lines(bufnr, row, row, false, template)

  -- Position cursor at the id attribute (after "tbl-formula-")
  -- Row is current line, column is position after "tbl-formula-"
  local id_col = string.find(template[1], 'id="tbl%-formula%-', 1, true) + 17 -- Position after 'tbl-formula-'
  api.nvim_win_set_cursor(0, { row + 1, id_col })

  -- Enter insert mode for immediate editing
  vim.cmd('startinsert')
end

--- Register the user command
api.nvim_create_user_command('HTMLFormulaTableTemplate', insert_html_formula_table_template, {
  desc = 'Insert HTML formula table template at cursor position',
})
