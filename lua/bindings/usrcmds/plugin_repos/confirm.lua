---@module 'bindings.usrcmds.plugin_repos.confirm'
---@brief Yes/no prompt for `:MyPlugins`' destructive confirmations.
---@description
--- `vim.fn.confirm()` only takes `<CR>` as "pick the `default` choice" and
--- has no `<BS>` handling at all, so it can't give `<CR>` and `<BS>` fixed
--- yes/no meanings independent of which choice is the default. This reads
--- keys directly instead: `<CR>`/`y`/`Y` accepts, `<BS>`/`n`/`N`/`<Esc>`/
--- `<C-c>` declines — `<BS>` sits directly above `<CR>` on this keyboard, so
--- the two keys read as a natural yes/no pair.

local M = {}

local fn = vim.fn
local CR = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
local BS = vim.api.nvim_replace_termcodes("<BS>", true, false, true)
local ESC = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)

---@param msg string
---@param yes_label string|nil e.g. "delete" — shown as "Yes, delete"
---@return boolean accepted
function M.yesno(msg, yes_label)
  local yes_hint = yes_label and ("Yes, " .. yes_label) or "Yes"
  vim.cmd("redraw")
  print(("%s\n\n[<CR>/y] %s    [<BS>/n] No"):format(msg, yes_hint))
  while true do
    local ok, char = pcall(fn.getcharstr)
    if not ok or char == ESC or char == "\3" then
      return false
    elseif char == CR or char == "y" or char == "Y" then
      return true
    elseif char == BS or char == "n" or char == "N" then
      return false
    end
  end
end

return M
