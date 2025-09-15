--@module 'plugins.fzf'
--- Fuzzy finding tools based on Telescope, fzf-lua, and optional tabbed UI (search.nvim)

--- Build fd options string.
---@return string  -- fd options ready for fzf-lua
---@private
function Build_fd_opts()
  -- local custom_nvim_doc = vim.fn.stdpath("config") .. '/doc'

  -- Base options: files only, include dotfiles, ignore .git
  local parts = {
    "--type",
    "f",
    "--hidden",
    "--exclude",
    ".git",
  }
  return table.concat(parts, " ")
end

---@type LazyPluginSpec[]
return {

  -- fzf-lua: Alternative fuzzy finder based on fzf
  {
    "ibhagwan/fzf-lua",
    lazy = true,
    opts = function()
      local actions = require("fzf-lua").actions

      return {
        keymap = {
          builtin = {
            true,
            ["<PageDown>"] = "preview-page-down",
            ["<PageUp>"] = "preview-page-up",
          },
          fzf = {
            ["ctrl-n"] = "next-history",
            ["ctrl-p"] = "prev-history",
          },
        },
        fzf_opts = {
          ["--history"] = vim.fn.stdpath "data" .. "/fzf-history",
        },
        --  ("query -- *.md !**/node_modules/**")
        grep = {
          -- make flags explicit to avoid fzf-lua auto-adding them
          cmd = "rg --vimgrep --column --line-number --no-heading --color=always --smart-case --max-columns=4096",
          -- keep -e in rg_opts so queries werden korrekt angefügt
          rg_opts = "-e",
          rg_glob = true,
          glob_flag = "--iglob",
          actions = {
            ["ctrl-g"] = { actions.grep_lgrep },
            ["ctrl-r"] = { actions.toggle_ignore },
          },
          -- optional: also hide info lines entirely
          silent = true,
        },
        -- Producer-side defaults for file pickers (fd). Prompt still filters client-side.
        files = {
          fd_opts = Build_fd_opts(),
        },
      }
    end,
  },
}
