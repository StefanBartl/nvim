---@module 'config.fzf.grep'
---ripgrep configuration for fzf-lua

local M = {}

---@param actions table fzf-lua actions
---@return table
function M.get(actions)
  return {
    cmd = "rg --vimgrep --column --line-number --no-heading --color=always --smart-case --max-columns=4096",
    rg_opts = "-e --glob '!.git/' --glob '!node_modules/' --glob '!.github/' --glob '!dist/' --glob '!package.lock.json'",
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
