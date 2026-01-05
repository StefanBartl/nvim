---@module 'config.fzf.keymaps'
---Keymaps for fzf-lua (builtin + fzf prompt)

local M = {}

---@return table
function M.get()
  return {
    builtin = {
      true,
      ["<PageDown>"] = "preview-page-down",
      ["<PageUp>"] = "preview-page-up",
    },
    fzf = {
      ["ctrl-n"] = "next-history",
      ["ctrl-p"] = "prev-history",
    },
  }
end

return M
