---@module 'config.search'
--- Centralized configuration for search.nvim.
---
--- This module encapsulates all setup logic for the search plugin,
--- including Telescope integration and tab/collection definitions.
---
--- Responsibilities:
--- - Safe requiring of dependencies
--- - search.nvim setup
--- - Telescope builtin wiring
---
--- This module performs no side effects on load.
--- Configuration is applied explicitly via `setup()`.

local M = {}

--- Initialize and configure search.nvim.
--- This function is intended to be called from the plugin spec.
--- @return boolean success Indicates whether setup completed successfully
function M.setup()
  -- Safely require search.nvim
  local ok_search, search = pcall(require, "search")
  if not ok_search then
    return false
  end

  -- Safely require telescope builtins
  local ok_builtin, builtin = pcall(require, "telescope.builtin")
  if not ok_builtin then
    return false
  end

  search.setup({
    mappings = {
      next = "<Tab>",
      prev = "<S-Tab>",
    },

    tabs = {
      {
        "Files",
        function(tab_opts)
          tab_opts = tab_opts or {}

          -- Prefer git_files when inside a Git repository
          if vim.fn.isdirectory(".git") == 1 then
            builtin.git_files(tab_opts)
          else
            builtin.find_files(tab_opts)
          end
        end,
      },

      {
        name = "All Files",
        tele_func = builtin.find_files,
        tele_opts = {
          no_ignore = true,
          hidden = true,
        },
      },

      {
        name = "Grep",
        tele_func = builtin.live_grep,
      },

      {
        name = "Buffers",
        tele_func = builtin.buffers,
      },
    },

    collections = {
      git = {
        initial_tab = 1,
        tabs = {
          {
            name = "Branches",
            tele_func = builtin.git_branches,
          },
          {
            name = "Commits",
            tele_func = builtin.git_commits,
          },
          {
            name = "Stashes",
            tele_func = builtin.git_stash,
          },
        },
      },
    },
  })

  return true
end

return M
