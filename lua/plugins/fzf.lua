--@module 'plugins.fzf'
--- Fuzzy finding tools based on Telescope, fzf-lua, and optional tabbed UI (search.nvim)

local path_shorten = require("lib.filesystem.path_shorten")
local function adapt_max_len()
  return math.max(20, math.floor((vim.o.columns or 80) * 0.6))
end

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
    ".dist",
    "--exclude",
    ".git",
    "--exclude",
    ".github",
    "--exclude",
    "node_modules",
    "--exclude",
    "package.lock.json",
    "--exclude",
    "yarn.lock",
    "--exclude",
    "pnpm-lock.yaml",
    "--exclude",
    ".build",
    "--exclude",
    "out",
    "--exclude",
    "obj",
    "--exclude",
    ".tmp",
    "--exclude",
    ".vscode",
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
          -- enable ANSI colors (useful with bat/rg)
          ["--ansi"] = "",
          ["--cycle"] = "", -- enable wrap/cycle behaviour so up from first => goes to last
          ["--history"] = vim.fn.stdpath("data") .. "/fzf-history",
          -- use a compact inline info line
          ["--info"] = "inline",
          -- allow multi-select (useful with ctrl-a / ctrl-d bindings)
          ["--multi"] = "",
        },
        --  ("query -- *.md !**/node_modules/**")
        grep = {
          -- make flags explicit to avoid fzf-lua auto-adding them
          cmd = "rg --vimgrep --column --line-number --no-heading --color=always --smart-case --max-columns=4096",
          -- keep -e in rg_opts so queries werden korrekt angefügt
          rg_opts = "-e --glob '!.git/' --glob '!node_modules/' --glob '!.github/' --glob '!dist/' --glob '!package.lock.json'",
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
                    --- FIX: Funktioniert nicht
          entry_maker = function(entry)
            local max_len = adapt_max_len()
            entry.path = path_shorten(entry.path or entry, max_len)
            return entry
          end,
        },
      }
    end,
  },
}
