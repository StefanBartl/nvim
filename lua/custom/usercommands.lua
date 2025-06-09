--- @command NvimTreeSetRoot Set nvim-tree root to path or git root
vim.api.nvim_create_user_command("NvimTreeSetRoot", function(opts)
  local api = require("nvim-tree.api")
  local path = opts.args

  -- Use git root if no argument is passed
  if path == "" then
    local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("%s+$", "")
    if vim.v.shell_error ~= 0 or git_root == "" then
      vim.notify("No path provided and Git root not found", vim.log.levels.ERROR)
      return
    end
    path = git_root
  end

  -- Expand ~ and other shorthand
  path = vim.fn.expand(path)

  -- Set Neovim current working directory
  vim.cmd("cd " .. vim.fn.fnameescape(path))

  -- Ensure tree is open and visible
  if not api.tree.is_visible() then
    api.tree.open()
  end

  -- Actually change the root
  api.tree.change_root(path)

  -- Optionally: focus the new root
  api.tree.find_file({ open = false, focus = true })

  vim.notify("nvim-tree root changed to: " .. path, vim.log.levels.INFO)
end, {
  desc = "Set the nvim-tree root directory (explicit path or Git root)",
  nargs = "?",
  complete = "dir",
})


vim.api.nvim_create_user_command("BufferClear", function()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
end, {
  desc = "Clear all lines in the current buffer",
})
