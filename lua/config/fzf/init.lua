---@module 'config.fzf'
---fzf-lua configuration. Only what is genuinely personal lives here; the rest
---is owned by pickers.nvim and patched onto fzf-lua once it loads:
---  - excludes for files/grep         -> `find.ignore_list` / `find.exclude`
---  - entry actions (create_file, …)  -> pickers.entry_actions.patch
---  - preview scroll, history         -> pickers.keys (fzf's own ctrl-n/ctrl-p
---                                       history keys are native with --history)
---  - --cycle, --layout, preview wrap -> `display.*`
---(ctrl-s/ctrl-v/ctrl-t split/vsplit/tab and grep's ctrl-g are fzf-lua defaults;
---a top-level `actions = { default = … }` is not read by fzf-lua, which keys
---global actions per provider, so none is set here.)

local M = {}

---@return table
function M.get()
  local fzf_actions = require("fzf-lua").actions

  return {
    fzf_opts = {
      ["--info"] = "inline",
    },

    files = {
      fd_opts = "--type f --hidden",
    },

    grep = {
      rg_glob = true,
      glob_flag = "--iglob",
      silent = true,
      actions = {
        ["ctrl-r"] = { fzf_actions.toggle_ignore },
      },
    },
  }
end

return M
