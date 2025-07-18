local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local Job = require("plenary.job")

local M = {}

function M.fd_multi_root()
  local search_dirs = { "C:/Users", "E:/MyGithub" }
  local all_results = {}
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
            }):find()
          end)
        end
      end,
    }):start()
  end
end

return M

