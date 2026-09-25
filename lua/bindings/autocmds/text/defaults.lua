---@module 'bindings.autocmds.text.defaults'

---@type AutoCmds.Text.Cfg
local AUTOCMDS_TEXT_DEFAULTS = {
  trim_trailing = {
    enable = true,
    pattern = "*",
    preserve_cursor = true,
    ignore_filetypes = { "diff" },
    ignore_buftypes = { "nofile", "prompt" },
    only_modifiable = true,
    only_normal_bufs = true,
  },
  trim_blank = {
    enable = true,
    pattern = "*",
    preserve_cursor = true,
    ignore_filetypes = { "diff" },
    ignore_buftypes = { "nofile", "prompt" },
    only_modifiable = true,
    only_normal_bufs = true,
  },
  last_loc = {
    enable = true,
    pattern = "*",
    exclude = { "commit", "gitrebase", "xxd" },
    min_line = 1,
  },
  preserve_folds = {
    enable = true,
    pattern = "*",
    ignore_filetypes = { "diff" },
    ignore_buftypes = { "nofile", "prompt" },
    only_normal_bufs = true,
  },
}

local M = {}

---@return AutoCmds.Text.Cfg
function M.get_defaults()
  return AUTOCMDS_TEXT_DEFAULTS
end

return M
