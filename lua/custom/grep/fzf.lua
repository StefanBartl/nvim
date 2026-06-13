---@module 'usrcmds.live_grep.fzf'

local M = {}

---@param files string[]
---@param title string
function M.open(files, title)
  require("fzf-lua").fzf_exec(files, {
    prompt = title .. "> ",
  })
end

return M
