---@module 'autocmds.git'
---@brief Automatically detects git conflicts on startup and populates the quickfix list.
---@description
--- This module sets up an autocmd on VimEnter that:
--- - Checks if the current working directory is a Git repository
--- - Looks for merge conflicts (`diff-filter=U`)
--- - Populates the quickfix list with conflicting files
--- - Opens the quickfix window and notifies the user

vim.api.nvim_create_augroup("mygit", { clear = true })

-- Create an autocommand that triggers on VimEnter
vim.api.nvim_create_autocmd("VimEnter", {
  group = "mygit",
  callback = function()
    -- Check if current directory is inside a Git repository
    ---@type string
    local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")

    -- Exit early if not a Git repository
    if not is_git_repo or not is_git_repo:match("^true") then
      return
    end

    -- Get list of files with unresolved conflicts (diff-filter=U)
    ---@type string[]
    local conflicts = vim.fn.systemlist("git diff --name-only --diff-filter=U")

    -- Exit if no conflicts found
    if #conflicts == 0 then
      return
    end

    -- Build quickfix entries
    ---@type table[]
    local qf_entries = {}
    for _, file in ipairs(conflicts) do
      table.insert(qf_entries, {
        filename = file,       -- conflicting file path
        lnum = 1,              -- default to line 1
        col = 1,               -- default to column 1
        text = "Git conflict", -- message for quickfix entry
      })
    end

    -- Set quickfix list and open it
    vim.fn.setqflist(qf_entries, 'r')
    vim.cmd("copen")

    -- Show notification with list of conflicts
    vim.notify(
      "Git conflicts detected in:\n" .. table.concat(conflicts, "\n"),
      vim.log.levels.WARN
    )
  end,
})
