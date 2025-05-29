---@module 'custom.mygrep.core.picker'
---@class PickerManager
---@brief Creates interactive Telescope pickers with memory features.
---@description
--- This module builds a reusable picker UI with support for memory features
--- such as persistent history, favorites, entry deletion, session-local undo,
--- and result preview. It works per tool and accepts external state, making it
--- fully modular and reusable.
---
---@field open fun(tool: string, title: string, runner: fun(query: string), state: ToolState): nil
local M = {}

-- Telescope
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local sorters = require("telescope.sorters")

-- Memory systems
local preview = require("custom.mygrep.core.preview")
local history = require("custom.mygrep.core.history")
local undo = require("custom.mygrep.core.undo")

--- Opens a picker UI for the specified tool.
---@param tool string Tool name
---@param title string Picker title
---@param runner fun(query: string): nil Runner function to execute query
---@param state ToolState Per-tool memory state (history, favorites, undo)
---@return nil
function M.open(tool, title, runner, state)
  assert(type(tool) == "string" and tool ~= "", "tool must be a valid string")
  assert(type(title) == "string", "title must be a string")
  assert(type(runner) == "function", "runner must be a function")
  assert(type(state) == "table", "state must be table")

  -- Combine deduplicated history and favorites
  local seen = {}
  local entries = {}

  for _, entry in ipairs(state.history) do
    if entry and entry ~= "" and not seen[entry] then
      seen[entry] = true
      table.insert(entries, entry)
    end
  end

  for _, entry in ipairs(state.favorites) do
    if entry and entry ~= "" and not seen[entry] then
      seen[entry] = true
      table.insert(entries, entry)
    end
  end

  local picker = pickers.new({}, {
    prompt_title = title,
    finder = finders.new_table {
      results = entries,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local function refresh()
        history.save(tool, state)
        actions.close(prompt_bufnr)
        vim.defer_fn(function()
          M.open(tool, title, runner, state)
        end, 10)
      end

      map("i", "<CR>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end
        local query = selection[1]
        actions.close(prompt_bufnr)
        vim.defer_fn(function()
          runner(query)
        end, 10)
      end)

      map("i", "<Tab>", function()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local query = sel[1]

        local found = false
        for i, v in ipairs(state.favorites) do
          if v == query then
            table.remove(state.favorites, i)
            undo.push(state, "unfavorite", query)
            found = true
            break
          end
        end
        if not found then
          table.insert(state.favorites, query)
        end
        refresh()
      end)

      map("i", "<C-d>", function()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local query = sel[1]

        for i, v in ipairs(state.history) do
          if v == query then
            table.remove(state.history, i)
            undo.push(state, "delete", query)
            break
          end
        end

        for i, v in ipairs(state.favorites) do
          if v == query then
            table.remove(state.favorites, i)
            break
          end
        end

        refresh()
      end)

      map("i", "<C-z>", function()
        local ok = undo.apply(state)
        if ok then
          refresh()
        end
      end)

      map("i", "<C-h>", function()
        local sel = action_state.get_selected_entry()
        if sel then
          preview.show(sel[1])
        end
      end)

      return true
    end,
  })

  local ok, err = pcall(function()
    picker:find()
  end)

  if not ok then
    vim.notify("[mygrep] Picker failed: " .. err, vim.log.levels.ERROR)
  end
end

return M
