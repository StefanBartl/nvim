---@module 'usercmds.fd_multi_roots'

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local Job = require("plenary.job")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

-- Hilfsfunktion: macht aus einem String-Pfad einen Telescope-Entry
local function make_entry(path)
  return {
    value = path,
    display = path,
    ordinal = path,
    path = path,
  }
end

--- Run `fd` in multiple roots and preview results using Telescope
---@async
function M.fd_multi_root()
  local search_dirs = {
    "C:/Users",
    "E:/MyGithub",
  }

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
              finder = finders.new_table {
                results = all_results,
                entry_maker = make_entry,
              },
              sorter = conf.generic_sorter({}),
              previewer = previewers.cat.new({}),
              attach_mappings = function(prompt_bufnr, map)
                local function open_file()
                  local entry = action_state.get_selected_entry()
                  actions.close(prompt_bufnr)
                  vim.cmd("edit " .. vim.fn.fnameescape(entry.path or entry.value))
                end

                map("i", "<CR>", open_file)
                map("n", "<CR>", open_file)
                return true
              end,
            }):find()
          end)
        end
      end,
    }):start()
  end
end

-- Custom user command for multi-root file finding
vim.api.nvim_create_user_command("TelescopeFdMultiRoot", function()
  M.fd_multi_root()
end, {})

return M
