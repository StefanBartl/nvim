---@module 'usrcmds.system_find'
---@description
--- Starts systemwide File-Search mit `fd` with optional filter (name, ext, path).
--- Uses `fd` or `fdfind` in combination with telescope.
---
--- Input could be:
---   `init.lua`
---   `/etc/init.lua`
---   `/home/*nvim.lua`
---   `log /var/log`
---   `rc .conf /etc`
---
--- The command will be translated to an `fd`-Command and showed with Telescope...

local M = {}

---Starts systemwide File-Search mit `fd`
---@return nil
local function System_find()
  local builtin = require("telescope.builtin")
  local input_opts = { prompt = "Suchbegriff(e) (Name .ext Pfad...): " }

  vim.ui.input(input_opts, function(input)
    if not input or input == "" then
      return
    end

    local fd_exec = vim.fn.executable("fd") == 1 and "fd" or (vim.fn.executable("fdfind") == 1 and "fdfind" or nil)
    if not fd_exec then
      vim.notify("Weder 'fd' noch 'fdfind' gefunden", vim.log.levels.ERROR)
      return
    end

    local args = {}
    for word in input:gmatch("%S+") do
      table.insert(args, word)
    end

    local name = nil
    local extension = nil
    local paths = {}

    for _, token in ipairs(args) do
      if token:match("^%.[%w]+$") then
        extension = token:sub(2)
      elseif token:match("^/") then
        table.insert(paths, token)
      elseif not name then
        name = token
      end
    end

    if #paths == 0 then
      paths = { "/etc", "/usr", "/home", "/media/steve" }
    end

    local fd_cmd = { fd_exec }
    if name then
      table.insert(fd_cmd, name)
    end
    vim.list_extend(fd_cmd, paths)

    if extension then
      table.insert(fd_cmd, "--extension")
      table.insert(fd_cmd, extension)
    end

    builtin.find_files({
      prompt_title = "Systemweite Dateisuche",
      find_command = fd_cmd,
    })
  end)
end

--- Setup 'system_find'-Usercommand
---@return nil
function M.enable_usercmds()
  vim.api.nvim_create_user_command("FindOnSystem", function()
    System_find()
  end, {
    desc = "Systemweite Dateisuche (fd + telescope)",
    nargs = "*",
  })
end

return M
