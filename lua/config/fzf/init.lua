---@module 'config.fzf'
---Composed fzf-lua configuration

local keymaps = require("config.fzf.keymaps")
local fzf_opts = require("config.fzf.fzf_opts")
local grep_cfg = require("config.fzf.grep")
local files_cfg = require("config.fzf.files")

local M = {}

---@return table
function M.get()
  local actions = require("fzf-lua").actions

  return {
    keymap = keymaps.get(),
    fzf_opts = fzf_opts.get(),
    grep = grep_cfg.get(actions),
    files = files_cfg.get(),
  }
end

return M

