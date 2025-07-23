local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local Job = require("plenary.job")

local M = {}

--- Run `fd` in multiple roots and preview results using Telescope
---@async
function M.fd_multi_root()
  local search_dirs = {
    "C:/Users",     -- Erstes Verzeichnis
    "E:/MyGithub",  -- Zweites Verzeichnis
  }

  local all_results = {}        -- Sammlung aller Dateipfade
  local jobs_remaining = #search_dirs

  for _, dir in ipairs(search_dirs) do
    Job:new({
      command = "fd",
      args = { "--type", "f", "--hidden", "--exclude", ".git" },
      cwd = dir,
      on_exit = function(j)
        for _, line in ipairs(j:result()) do
          table.insert(all_results, dir .. "/" .. line)
        end

        jobs_remaining = jobs_remaining - 1
        if jobs_remaining == 0 then
          vim.schedule(function()
            pickers.new({}, {
              prompt_title = "Find files (multi root)",
              finder = finders.new_table({ results = all_results }),
              sorter = conf.generic_sorter({}),
              previewer = previewers.cat.new({}),  -- Vorschau hinzufügen
            }):find()
          end)
        end
      end,
    }):start()
  end
end

return M
