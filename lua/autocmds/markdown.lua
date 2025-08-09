vim.api.nvim_create_augroup("mymarkdown", { clear = true })

--- Setup a FileType-based autocommand for Markdown buffers
vim.api.nvim_create_autocmd("FileType", {
  group = "mymarkdown",
  pattern = "markdown",
  callback = function()
    ---@diagnostic disable: undefined-global

    --- Set a normal-mode keymap that wraps the current word as a markdown link: [word]()
    ---
    --- This is useful when editing markdown documents to quickly insert a link wrapper
    --- around any word under the cursor.
    ---
    --- Example:
    ---   Before:   example
    ---   Pressed:  <leader>[
    ---   After:    [example]()
    ---
    --- The cursor will be placed between the parentheses: [example](|)

    local buf = vim.api.nvim_get_current_buf()
    if not vim.bo[buf].modifiable then
      vim.notify("Buffer is not modifiable", vim.log.levels.WARN)
      return
    end

    ---@type string
    local key = "<leader>["

    ---@type string
    local description = "Wrap current word in Markdown link syntax"

    ---@type fun(): nil
    local handler = function()
      -- Ensure this is still a markdown buffer (defensive check)
      local filetype = vim.bo.filetype
      if filetype ~= "markdown" then
        return
      end

      -- Get the word under the cursor using the <cword> expansion
      ---@type string
      local word = vim.fn.expand("<cword>")
      if not word or word == "" then
        return
      end

      -- Save current cursor position (1-based row, 0-based col)
      ---@type integer, integer
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))

      -- Replace the word with [word]() via normal mode command
      vim.cmd("normal! ciw[" .. word .. "]()")

      -- Calculate new column position to place cursor inside the ()
      ---@type integer
      local new_col = col + 2 + #word + 1 -- [ ] adds 2 chars, then '(' is one more

      -- Restore cursor to the calculated position
      vim.api.nvim_win_set_cursor(0, { row, new_col })
    end

    -- Register the buffer-local keymap
    vim.keymap.set("n", key, handler, {
      desc = description,
      buffer = true, -- keymap only applies to the current markdown buffer
    })
  end,
})
