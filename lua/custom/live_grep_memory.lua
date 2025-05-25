---@module 'custom.live_grep_memory'
---@class LiveGrepMemory
---@brief Adds in-session memory to Telescope live_grep
---@description
--- This module wraps `telescope.builtin.live_grep` with memory features.
--- It remembers previous search inputs and allows navigation, selection,
--- reset, and reuse directly from the prompt. It also provides a floating
--- window with selectable history entries.
---
--- | Keybinding | Description                                       |
--- |------------|---------------------------------------------------|
--- | `<C-p>`    | Jump backward in saved search history             |
--- | `<C-n>`    | Jump forward in saved search history              |
--- | `<CR>`     | Select current result and save query to history   |
--- | `<C-r>`    | Reset history (clear all saved queries)           |
--- | `<C-o>`    | Open floating history menu (picker)               |
---
---@field history string[] Stored live_grep queries
---@field index integer Index pointing to the current history position
---@field store_history fun(input: string): nil Stores a new query into the history list, if it's not a duplicate
---@field shift_history fun(prompt_bufnr: number, direction: integer): nil Navigates through the history and restarts live_grep with the selected entry
---@field open_history_picker fun(parent_bufnr: integer): nil Opens a floating Telescope picker showing the history list
---@field reset_history fun(): nil Resets the live grep with memory history
---@field open fun(opts?: table): nil Starts Telescope live_grep with memory support and custom mappings
local M = {}

-- Required Telescope components
local telescope_builtin = require("telescope.builtin")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local action_set = require("telescope.actions.set")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

-- History store
M.history = {}
M.index = 0

---Stores a new query into the history list, if it's not a duplicate
---@param input string Input string from the Telescope prompt
---@return nil
local function store_history(input)
  if not input or input == "" then return end
  if #M.history == 0 or M.history[#M.history] ~= input then
    table.insert(M.history, input)
    M.index = #M.history + 1
  end
end


---Navigates through the history and restarts live_grep with the selected entry
---@param prompt_bufnr number The buffer number of the Telescope prompt
---@param direction integer +1 for forward, -1 for backward
---@return nil
local function shift_history(prompt_bufnr, direction)
  if #M.history == 0 then return end

  M.index = M.index + direction
  if M.index < 1 then M.index = 1 end
  if M.index > #M.history then M.index = #M.history end

  local entry = M.history[M.index] or ""
  actions.close(prompt_bufnr)

  vim.defer_fn(function()
    M.open({ default_text = entry })
  end, 10)
end

---Opens a floating Telescope picker showing the history list
---Selecting an entry restarts the live_grep with that entry prefilled
---@param parent_bufnr number The buffer number of the current live_grep prompt
---@return nil
function M.open_history_picker(parent_bufnr)
  if #M.history == 0 then
    vim.notify("No previous queries found", vim.log.levels.WARN)
    return
  end

  -- Erzeuge umgekehrte Liste für Anzeige (neuester oben)
  local function get_reversed_history()
    local reversed = {}
    for i = #M.history, 1, -1 do
      table.insert(reversed, M.history[i])
    end
    return reversed
  end

  -- Picker-Instanz
  pickers.new({}, {
    prompt_title = "Live Grep History",
    finder = finders.new_table {
      results = get_reversed_history(),
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local picker = action_state.get_current_picker(prompt_bufnr)

      -- Auswahl per <CR>
      actions.select_default:replace(function(inner_bufnr)
        local selection = action_state.get_selected_entry()
        pcall(actions.close, inner_bufnr)
        vim.defer_fn(function()
          M.open({ default_text = selection[1] })
        end, 20)
      end)

      -- <C-d>: Löscht Eintrag aus History
      map("i", "<C-d>", function()
        local selection = action_state.get_selected_entry()

        if not selection then
          vim.notify("No selection to delete", vim.log.levels.WARN)
          return
        end

        for i = #M.history, 1, -1 do
          if M.history[i] == selection[1] then
            table.remove(M.history, i)
            break
          end
        end

        local function get_reversed_history()
          local reversed = {}
          for i = #M.history, 1, -1 do
            table.insert(reversed, M.history[i])
          end
          return reversed
        end

        picker:refresh(
          finders.new_table({ results = get_reversed_history() }),
          { reset_prompt = true }
        )
      end)

      return true
    end

  }):find()
end

---Resets the live grep with memory history
---@return nil
function M.reset_history()
  M.history = {}
  M.index = 0
  vim.schedule(function()
    vim.notify("History reset", vim.log.levels.INFO)
  end)
end

---Starts Telescope live_grep with memory support and custom mappings
---Supports browsing history, opening a history menu, and resetting it
---@param opts table|nil Optional Telescope options
---@return nil
function M.open(opts)
  opts = opts or {}
  opts.default_text = opts.default_text or ""

  opts.attach_mappings = function(prompt_bufnr, map)
    -- History navigation
    map("i", "<C-p>", function() shift_history(prompt_bufnr, -1) end)
    map("i", "<C-n>", function() shift_history(prompt_bufnr, 1) end)

    -- Open floating history picker
    map("i", "<C-o>", function()
      M.open_history_picker(prompt_bufnr)
    end)

    -- Reset history from prompt
    map("i", "<C-r>", function()
      M.reset_history()
    end)

    -- Save current prompt and then call original select
    action_set.select:replace(function(prompt_bufnr)
      local input = action_state.get_current_line()
      store_history(input)

      local selection = action_state.get_selected_entry()
      actions.close(prompt_bufnr)

      if selection and selection.filename then
        -- Open the file and jump to the line
        vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
        vim.fn.cursor(selection.lnum, 1)
      end
    end)

    return true
  end

  telescope_builtin.live_grep(opts)
end

return M