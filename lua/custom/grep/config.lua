---@module 'usrcmds.live_grep.config'

local M = {}

---@type LiveGrepConfig
M.defaults = {
  picker = nil,

  keymap = "<leader>li",

  separator = ";",

  cwd = nil,

  prompt = "LiveGrep",

  rg = {
    binary = "rg",
    hidden = true,
    follow = true,
    smart_case = true,
    glob = {},
  },

  telescope = {
    preview = true,
  },

  fzf = {
    preview = true,
  },
}

---@type LiveGrepConfig
M.options = vim.deepcopy(M.defaults)

---@param opts? LiveGrepConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend(
    "force",
    vim.deepcopy(M.defaults),
    opts or {}
  )
end

return M
