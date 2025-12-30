---@module 'usrcmds.gather.lua.strings'
---@description Collects all Lua string literals using Tree-sitter

local api = vim.api
local ts = vim.treesitter

local M = {}

---@return string[]
local function collect()
  ---@type string[]
  local result = {}

  local parser = ts.get_parser(0, "lua")
  local tree = parser:parse()[1]
  local root = tree:root()

  local query = ts.query.parse(
    "lua",
    [[
      (string) @str
    ]]
  )

  for _, node in query:iter_captures(root, 0) do
    result[#result + 1] = ts.get_node_text(node, 0)
  end

  table.sort(result)
  return result
end

---@param lines string[]
local function open_scratch(lines)
  local buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_buf_set_option(buf, "buftype", "nofile")
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "modifiable", false)
  api.nvim_buf_set_option(buf, "filetype", "lua")

  api.nvim_set_current_buf(buf)

  api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>bd!<cr>", { noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>bd!<cr>", { noremap = true, silent = true })
end

function M.run()
  open_scratch(collect())
end

return M

