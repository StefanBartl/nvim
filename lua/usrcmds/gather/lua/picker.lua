---@module 'usrcmds.gather.lua.picker'
---@description Telescope picker for displaying CWD-wide gather results

local notify = require("lib.nvim.notify").create("[usrcmds.gather.lua.picker]")

require("usrcmds.gather.@types")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")

local M = {}

--- Format entry for display in picker
---@param match UsrCmds.Gather.Lua.Match
---@param gather_type UsrCmds.Gather.Lua.GatherType
---@return string display
---@diagnostic disable-next-line: unused-local
local function format_entry(match, gather_type)
  local filename = match.file and vim.fn.fnamemodify(match.file, ":t") or "current"
  local context = match.context and (" [" .. match.context .. "]") or ""

  return string.format(
    "%s:%d  %s%s",
    filename,
    match.line,
    match.name,
    context
  )
end

--- Build Telescope entries from matches
---@param file_matches UsrCmds.Gather.Lua.FileMatches[]
---@param gather_type UsrCmds.Gather.Lua.GatherType
---@return table[] entries
local function build_entries(file_matches, gather_type)
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 30 },        -- Location
      { remaining = true },  -- Symbol name
    },
  })

  local entries = {}

  for _, file_data in ipairs(file_matches) do
    for _, match in ipairs(file_data.matches) do
      local display_text = format_entry(match, gather_type)

      table.insert(entries, {
        value = match,
        ordinal = display_text,
        display = function()
          return displayer({
            { display_text:sub(1, 30), "Comment" },
            { display_text:sub(31), "Normal" }
          })
        end,
      })
    end
  end

  return entries
end

--- Create previewer for showing context
---@return table previewer
local function make_previewer()
  return previewers.new_buffer_previewer({
    title = "Context",
    define_preview = function(self, entry)
      local match = entry.value

      if not match.file then
        return
      end

      -- Load file content
      local lines = vim.fn.readfile(match.file)

      -- Context window: ±5 lines
      local start_line = math.max(1, match.line - 5)
      local end_line = math.min(#lines, match.line + 5)
      local context = vim.list_slice(lines, start_line, end_line)

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, context)

      -- Highlight target line
      local target_line = match.line - start_line + 1
      vim.api.nvim_buf_add_highlight(
        self.state.bufnr,
        -1,
        "TelescopePreviewMatch",
        target_line - 1,
        0,
        -1
      )

      -- Set filetype
      vim.api.nvim_set_option_value("filetype", "lua", { buf = self.state.bufnr })
    end,
  })
end

--- Show Telescope picker for gathered symbols
---@param file_matches UsrCmds.Gather.Lua.FileMatches[]
---@param gather_type UsrCmds.Gather.Lua.GatherType
function M.show_picker(file_matches, gather_type)
  if #file_matches == 0 then
    notify.warn("No " .. gather_type .. " found in cwd")
    return
  end

  local entries = build_entries(file_matches, gather_type)

  pickers.new({}, {
    prompt_title = "Gather: " .. gather_type,

    finder = finders.new_table({
      results = entries,
      entry_maker = function(e) return e end,
    }),

    sorter = conf.generic_sorter({}),
    previewer = make_previewer(),
    selection_caret = "* ",

    attach_mappings = function(prompt_bufnr)
      --- Open file at symbol location
      local function open_location()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local match = entry.value

        if match.file then
          vim.cmd("edit " .. vim.fn.fnameescape(match.file))
          vim.api.nvim_win_set_cursor(0, { match.line, match.col })
        end
      end

      vim.keymap.set({ "i", "n" }, "<CR>", open_location, { buffer = prompt_bufnr })

      return true
    end,
  }):find()
end

return M
