---@module 'config.fzf.fzf_opts'
---Low-level fzf command-line options
---History is owned by pickers.nvim (history.fzf_scope = "patch" in its setup()),
---which patches fzf-lua's fzf_opts["--history"] itself — see StefanBartl/pickers.nvim.

local M = {}

---@return table
function M.get()
  return {
    ["--ansi"] = "",
    ["--cycle"] = "",
    ["--info"] = "inline",
    ["--multi"] = "",
  }
end

return M
