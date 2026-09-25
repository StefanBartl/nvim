---@module 'config.fzf.grep'
---ripgrep configuration for fzf-lua

local M = {}

---@param actions table fzf-lua actions
---@return table
function M.get(actions)
  return {
    -- No `cmd`/`rg_opts` here: with a custom `cmd` fzf-lua ignores `rg_opts`,
    -- so the excludes could never apply. pickers.nvim patches its
    -- `find.exclude` into fzf-lua's default `rg_opts` instead.
    rg_glob = true,
    glob_flag = "--iglob",
    silent = true,
    actions = {
      ["ctrl-g"] = { actions.grep_lgrep },
      ["ctrl-r"] = { actions.toggle_ignore },
    },
  }
end

return M
