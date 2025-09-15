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
          ["<PageUp>"]   = "preview-page-up",
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
          -- erzwingt rg auch für `grep` (nicht nur `live_grep`)
          cmd = "rg --vimgrep",

          -- GNU grep Fallback: .git ausschließen
          grep_opts = "--binary-files=without-match --line-number --recursive --color=auto --perl-regexp --exclude-dir=.git -e",

          -- ripgrep: .git explizit ausschließen (robust gegen RG-Config/--hidden)
          -- POSIX-Shell: single quotes, Windows/Pwsh: double quotes (siehe Hinweis unten)
          rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --glob '!**/.git/**' -e",

          -- Globs sind aktiv, Flag für Globs bleibt wie gehabt
          rg_glob = true,
          glob_flag = "--iglob", -- oder "--glob" wenn Groß/Kleinschreibung exakt sein soll

          hidden = false, -- keine versteckten Dateien durchsuchen
          follow = false,
          no_ignore = false, -- .gitignore respektieren
          -- …
          actions = {
            ["ctrl-g"] = { actions.grep_lgrep }, -- toggle grep <-> live_grep
            ["ctrl-r"] = { actions.toggle_ignore }, -- .gitignore respektieren/ignorieren
          },
        },
        -- Producer-side defaults for file pickers (fd). Prompt still filters client-side.
        files = {
          fd_opts = Build_fd_opts(),
        },
      }
    end,
  },
}
