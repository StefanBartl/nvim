---@module 'custom.markdown.anchor.jump'
-- Jump to the header linked under cursor

---AUDIT: Apply performance guidelines

local M = {}

---@nodiscard
---@return nil
function M.jump_to_anchor()
  local line = vim.api.nvim_get_current_line()
  -- extract Markdown-Link
  local anchor = line:match("%(#([%w%-]+)%)")
  if not anchor then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  for i = 0, total_lines-1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, i, i+1, false)[1]

    -- only respect Markdown-Headers
    local header_text = l:match("^#+%s+(.*)")
    if header_text then
      -- create GitHub-Style anchors
      local h_anchor = header_text:lower()
      h_anchor = h_anchor:gsub("[^%w%s-]", "")   -- remove special chars
      h_anchor = h_anchor:gsub("%s+", "-")       -- empty space to -
      if h_anchor == anchor then
        vim.api.nvim_win_set_cursor(0, {i+1, 0})
        return
      end
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("n", "gh", M.jump_to_anchor, {buffer=true})
  end
})
