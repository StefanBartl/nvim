---@module 'autocmds.git.defaults'

-- AUDIT: Optionen beschreiben

---@type AutoCmds.Git.Cfg
local AUTOCMDS_GIT_DEFAULTS = {
  conflicts_qf = {
    enable = true,
    events = { "VimEnter" },
    diff_filter = "U",
    open_qf = true,
    notify = true,
    git_cmd = "git",
  },
  commit_ft = {
    enable = true,
    spell = true,
    textwidth = 72,
    colorcolumn = "73",
    formatoptions = "tcqj",
    start_in_insert = false,
  },
  gitsigns_refresh = {
    enable = true,
    events = { "BufEnter", "FocusGained" },
  },
  blame_on_hold = {
    enable = false,
    delay = 0,
    virt = true,
    ignore_buftypes = { "nofile", "prompt" },
  },
}

local M = {}

---@return AutoCmds.Git.Cfg
function M.get_defaults()
  return AUTOCMDS_GIT_DEFAULTS
end

return M

