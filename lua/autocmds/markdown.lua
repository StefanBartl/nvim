---@module 'autocmds.markdown'

-- Create (or clear) an augroup for Markdown-specific autocmds
vim.api.nvim_create_augroup("markdown_autocmds", { clear = true })

--- Set up a FileType-based autocmd for Markdown buffers
--- Registers a buffer-local keymap that wraps the current word as a Markdown link: [word]()
vim.api.nvim_create_autocmd("FileType", {
  group = "markdown_autocmds",
  pattern = "markdown",
  callback = function()
    ---@diagnostic disable: undefined-global

    -- Get current buffer handle and validate buffer is modifiable
    ---@type integer
    local buf = vim.api.nvim_get_current_buf()
    if not vim.bo[buf].modifiable then
      vim.notify("Buffer is not modifiable", vim.log.levels.WARN)
      return
    end

    -- Key and description for the mapping
    ---@type string
    local key = "<leader>["
    ---@type string
    local description = "Wrap current word in Markdown link syntax"

    -- Handler: wrap <cword> as [word]() and place cursor inside the parentheses
    ---@type fun(): nil
    local handler = function()
      -- Defensive: ensure we're still in a markdown buffer
      if vim.bo.filetype ~= "markdown" then
        return
      end

      -- Get the word under cursor
      ---@type string
      local word = vim.fn.expand("<cword>")
      if not word or word == "" then
        return
      end

      -- Save current cursor position (row: 1-based, col: 0-based)
      ---@type integer, integer
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))

      -- Replace the word with [word]() using a change-inner-word motion
      -- This keeps the action atomic and undo-friendly.
      vim.cmd("normal! ciw[" .. word .. "]()")

      -- Compute new column to place cursor inside the parentheses: [word](|)
      ---@type integer
      local new_col = col + 2 + #word + 1

      -- Restore cursor to the calculated position
      vim.api.nvim_win_set_cursor(0, { row, new_col })
    end

    -- Buffer-local normal-mode mapping
    vim.keymap.set("n", key, handler, {
      desc = description,
      buffer = buf,
      noremap = true,
      silent = true,
    })
  end,
})
