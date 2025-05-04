local M = {}

M.system_find = function()
  local builtin = require("telescope.builtin")

  vim.ui.input({ prompt = "Search term (optional: name .ext): " }, function(input)
    if not input then return end

    local args = {}
    for word in input:gmatch("%S+") do
      table.insert(args, word)
    end

    local name = args[1] or ""
    local extension = ""

    -- If second argument starts with dot → use as extension (e.g. ".lua")
    if args[2] and args[2]:match("^%.[%w]+$") then
      extension = args[2]:sub(2) -- Remove leading dot for fd
    end

    -- Check for available fd binary
    local fd_executable = vim.fn.executable("fd") == 1 and "fd"
        or (vim.fn.executable("fdfind") == 1 and "fdfind" or nil)

    if not fd_executable then
      vim.notify("Neither 'fd' nor 'fdfind' found in PATH", vim.log.levels.ERROR)
      return
    end

    local fd_cmd = {
      fd_executable,
      name,
      "/etc", "/usr", "/home", "/media/steve",
    }

    if extension ~= "" then
      table.insert(fd_cmd, "--extension")
      table.insert(fd_cmd, extension)
    end

    builtin.find_files({
      prompt_title = "System-wide file search",
      find_command = fd_cmd,
    })
  end)
end

vim.api.nvim_create_user_command("FindOnSystem", function()
  require("custom.system_find").system_find()
end, {
  desc = "Search file on system.",
})

return M
