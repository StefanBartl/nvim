---@module 'config.search'
--- Centralized configuration for search.nvim: Telescope integration and
--- tab/collection definitions. No side effects on load -- applied via
--- setup(), called from the plugin spec.

local M = {}

--- Initialize and configure search.nvim.
--- @return boolean success Indicates whether setup completed successfully
function M.setup()
  local ok_search, search = pcall(require, "search")
  if not ok_search then
    return false
  end

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
