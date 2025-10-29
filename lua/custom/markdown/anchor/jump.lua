---@module 'custom.markdown.anchor.jump'
-- Jump to the header linked under cursor
---AUDIT: Apply performance guidelines

---Jump to the anchor referenced in a Markdown TOC link
---@return nil
return function()
  local line = vim.api.nvim_get_current_line()
  -- Extract Markdown link anchor
  local anchor = line:match("%(#([%w%-]+)%)")
  if not anchor then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  -- Search through all lines for matching header
  for i = 0, total_lines-1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, i, i+1, false)[1]

    -- Only respect Markdown-Headers
    local header_text = l:match("^#+%s+(.*)")
    if header_text then
      -- Create GitHub-Style anchors
      local h_anchor = header_text:lower()
      h_anchor = h_anchor:gsub("[^%w%s-]", "")   -- Remove special chars
      h_anchor = h_anchor:gsub("%s+", "-")       -- Replace spaces with hyphens
      if h_anchor == anchor then
        vim.api.nvim_win_set_cursor(0, {i+1, 0})
        return
      end
    end
  end
end

