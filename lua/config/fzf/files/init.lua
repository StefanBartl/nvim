---@module 'config.fzf.files'
---File picker (fd) configuration and entry formatting

local path_shorten = require("lib.nvim.fs.path_shorten")

local M = {}

---@return string
local function build_fd_opts()
  local parts = {
    "--type", "f",
    "--hidden",
    "--exclude", ".dist",
    "--exclude", ".git",
    "--exclude", ".github",
    "--exclude", "node_modules",
    "--exclude", "package.lock.json",
    "--exclude", "yarn.lock",
    "--exclude", "pnpm-lock.yaml",
    "--exclude", ".build",
    "--exclude", "out",
    "--exclude", "obj",
    "--exclude", ".tmp",
    "--exclude", ".vscode",
  }
  return table.concat(parts, " ")
end

---@return integer
local function adapt_max_len()
  return math.max(20, math.floor((vim.o.columns or 80) * 0.6))
end

---@return table
function M.get()
  return {
    fd_opts = build_fd_opts(),
    entry_maker = function(entry)
      local max_len = adapt_max_len()
      entry.path = path_shorten(entry.path or entry, max_len)
      return entry
    end,
  }
end

return M

