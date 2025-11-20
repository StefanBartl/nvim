---@module 'usrcmds.templates.html.accordion'
--- HTML Accordion Item Template
---
--- This module provides a user command to insert an HTML accordion template
--- at the current cursor position in Neovim.

local api = vim.api

--- Insert HTML accordion template at cursor position
---
--- Creates a complete HTML5 details/summary element for collapsible content.
--- The cursor is positioned at the id attribute for quick editing.
local function insert_html_accordion_template()
  -- Get current buffer and cursor position
  local bufnr = api.nvim_get_current_buf()
  local cursor = api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-indexed

  -- Define the template lines
  local template = {
    '<details id="#accordion-" style="border: 1px solid #ddd; border-radius: 4px; padding: 0.5em 1em; margin: 0.5em 0;">',
    '  <summary style="cursor: pointer; font-weight: bold; user-select: none;">',
    "    ",
    "  </summary>",
    '  <div style="margin-top: 1em;">',
    "    ",
    "  </div>",
    "</details>",
  }

  -- Insert the template at cursor position
  api.nvim_buf_set_lines(bufnr, row, row, false, template)

  -- Position cursor at the id attribute (after "accordion-")
  -- Row is current line, column is position after "accordion-"
  local id_col = string.find(template[1], 'id="accordion%-', 1, true) + 14 -- Position after 'accordion-'
  api.nvim_win_set_cursor(0, { row + 1, id_col })

  -- Enter insert mode for immediate editing
  vim.cmd("startinsert")
end

--- Register the user command
api.nvim_create_user_command("HTMLAccordionTemplate", insert_html_accordion_template, {
  desc = "Insert HTML accordion item template at cursor position",
})
