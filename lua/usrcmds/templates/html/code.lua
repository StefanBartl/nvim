---@module 'usrcmds.templates.html.code_template'
--- HTML Code Listing Template Command
---
--- This module provides a user command to insert an HTML code listing template
--- at the current cursor position in Neovim.

local api = vim.api

--- Insert HTML code listing template at cursor position
---
--- Creates a complete HTML5 figure element with pre/code block and figcaption.
--- The cursor is positioned at the id attribute for quick editing.
local function insert_html_code_template()
  -- Get current buffer and cursor position
  local bufnr = api.nvim_get_current_buf()
  local cursor = api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-indexed

  -- Define the template lines
  local template = {
    '<figure id="#code-">',
    '  <pre><code class="">',
    "",
    "  </code></pre>",
    "  <figcaption><strong>Listing:</strong> </figcaption>",
    "</figure>",
  }

  -- Insert the template at cursor position
  api.nvim_buf_set_lines(bufnr, row, row, false, template)

  -- Position cursor at the id attribute (after "code-")
  -- Row is current line, column is position after "code-"
  local id_col = string.find(template[1], 'id="code%-', 1, true) + 9 -- Position after 'code-'
  api.nvim_win_set_cursor(0, { row + 1, id_col })

  -- Enter insert mode for immediate editing
  vim.cmd("startinsert")
end

--- Register the user command
api.nvim_create_user_command("HTMLCodeTemplate", insert_html_code_template, {
  desc = "Insert HTML code listing template at cursor position",
})
