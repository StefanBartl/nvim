---@module 'usrcmds.migrate.notify.telescope'
---@brief Telescope picker for interactive match selection.
---@description
--- Features:
---   - Multi-select with <Tab>
---   - Refactor all with <S-A>
---   - Preview with context lines
---   - File grouping with match count

require("usrcmds.migrate.notify.@types")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local M = {}

local api = vim.api

--- Format entry for display
---@param file_match MigrateNotify.FileMatches
---@param match MigrateNotify.Match
---@return string display
local function format_entry(file_match, match)
  local filename = vim.fn.fnamemodify(file_match.path, ":t")
  local level = match.log_level:lower()

  return string.format(
    "%s:%d  [%s]  %s",
    filename,
    match.line,
    level,
    match.original:sub(1, 50)
  )
end

--- Build flat entry list from file matches
---@param file_matches MigrateNotify.FileMatches[]
---@return table[] entries
local function build_entries(file_matches)
  local entries = {}

  for _, file_match in ipairs(file_matches) do
    for _, match in ipairs(file_match.matches) do
      table.insert(entries, {
        display = format_entry(file_match, match),
        ordinal = file_match.path .. ":" .. match.line,
        value = {
          path = file_match.path,
          match = match,
        },
      })
    end
  end

  return entries
end

--- Create previewer with context
---@return table previewer
local function make_previewer()
  return previewers.new_buffer_previewer({
    title = "Match Preview",
    define_preview = function(self, entry)
      local bufnr = self.state.bufnr
      local path = entry.value.path
      local match = entry.value.match

      -- Load file content
      local lines = vim.fn.readfile(path)

      -- Context window: ±5 lines
      local start_line = math.max(1, match.line - 5)
      local end_line = math.min(#lines, match.line + 5)
      local context = vim.list_slice(lines, start_line, end_line)

      api.nvim_buf_set_lines(bufnr, 0, -1, false, context)

      -- Highlight target line
      local target_line = match.line - start_line + 1
      vim.api.nvim_buf_add_highlight(
        bufnr,
        -1,
        "TelescopePreviewMatch",
        target_line - 1,
        0,
        -1
      )

      -- Set filetype for syntax
      vim.bo[bufnr].filetype = "lua"
    end,
  })
end

--- Show picker
---@param file_matches MigrateNotify.FileMatches[]
function M.show_picker(file_matches)
  if #file_matches == 0 then
    vim.notify("No vim.notify patterns found", vim.log.levels.WARN)
    return
  end

  local entries = build_entries(file_matches)

  pickers.new({}, {
    prompt_title = "Migrate vim.notify → lib.notify",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return entry
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = make_previewer(),
    attach_mappings = function(prompt_bufnr, map)
      --- Refactor selected entries
      local function refactor_selected()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()

        if #selections == 0 then
          selections = { picker:get_selection() }
        end

        actions.close(prompt_bufnr)

        -- Group by file
        local files = {}
        for _, entry in ipairs(selections) do
          local path = entry.value.path
          if not files[path] then
            files[path] = {
              path = path,
              matches = {},
            }
          end
          table.insert(files[path].matches, entry.value.match)
        end

        -- Convert to list
        local file_list = {}
        for _, file_data in pairs(files) do
          table.insert(file_list, file_data)
        end

        local refactor = require("usrcmds.migrate.notify.refactor")
        local results = refactor.refactor_selections(file_list)

        -- Summary
        local total_modified = 0
        for _, result in pairs(results) do
          total_modified = total_modified + result.modified_lines
        end

        vim.notify(
          string.format("Refactored %d matches across %d files", total_modified, #file_list),
          vim.log.levels.INFO
        )
      end

      --- Refactor all visible
      local function refactor_all()
        actions.close(prompt_bufnr)

        local refactor = require("usrcmds.migrate.notify.refactor")
        local results = refactor.refactor_selections(file_matches)

        local total = 0
        for _, result in pairs(results) do
          total = total + result.modified_lines
        end

        vim.notify(
          string.format("Refactored %d matches across %d files", total, #file_matches),
          vim.log.levels.INFO
        )
      end

      map("i", "<CR>", refactor_selected)
      map("n", "<CR>", refactor_selected)
      map("i", "<S-A>", refactor_all)
      map("n", "<S-A>", refactor_all)

      return true
    end,
  }):find()
end

return M
