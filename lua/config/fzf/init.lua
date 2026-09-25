---@module 'config.fzf'
---Composed fzf-lua configuration with custom actions

local keymaps = require("config.fzf.keymaps")
local fzf_opts = require("config.fzf.fzf_opts")
local grep_cfg = require("config.fzf.grep")
local files_cfg = require("config.fzf.files")

local M = {}

---@return table
function M.get()
  local fzf_actions = require("fzf-lua").actions

  return {
    -- Builtin keymaps
    keymap = keymaps.get(),

    -- fzf command-line options
    fzf_opts = fzf_opts.get(),

    -- Per-picker config
    grep = grep_cfg.get(fzf_actions),
    files = files_cfg.get(),

    -- Global actions (apply to all pickers). pickers.nvim patches its own
    -- entry actions (create_file/open_background/cheatsheet/path_copy) in.
    actions = {
      ["default"] = fzf_actions.file_edit,
      ["ctrl-s"] = fzf_actions.file_split,
      ["ctrl-v"] = fzf_actions.file_vsplit,
      ["ctrl-t"] = fzf_actions.file_tabedit,
    },
  }
end

return M
