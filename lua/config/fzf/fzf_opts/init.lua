---@module 'config.fzf.fzf_opts'
---Low-level fzf command-line options

local M = {}

---@return table
function M.get()
  return {
    ["--ansi"] = "",
    ["--cycle"] = "",
    ["--history"] = vim.fn.stdpath("data") .. "/fzf-history",
    ["--info"] = "inline",
    ["--multi"] = "",
  }
end

return M

