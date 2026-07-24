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
  -- Deferred (not a module-top-level require): this module is itself
  -- required eagerly from plugins/fzf.lua's spec top level, before
  -- lazy=false plugins like pickers.nvim have been loaded onto the path.
  local entry_actions = require("pickers.entry_actions.adapters.fzf")

  return {
    -- Builtin keymaps
    keymap = keymaps.get(),

    -- fzf command-line options
    fzf_opts = fzf_opts.get(),

    -- Picker-specific configs FIX: Does not work
    grep = grep_cfg.get(fzf_actions),
    files = files_cfg.get(),

    -- Global actions (apply to all pickers)
    actions = vim.tbl_extend("force", {
      -- Default actions
      ["default"] = fzf_actions.file_edit,
      ["ctrl-s"] = fzf_actions.file_split,
      ["ctrl-v"] = fzf_actions.file_vsplit,
      ["ctrl-t"] = fzf_actions.file_tabedit,
    }, entry_actions.get_actions()),
  }
end

return M
