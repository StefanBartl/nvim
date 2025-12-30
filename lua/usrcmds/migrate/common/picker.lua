---@module 'usrcmds.migrate.common.picker'
---@brief Generic Telescope picker for migration matches.
---@description
--- Provides a reusable picker implementation for all migration types.
--- Handles:
---   - Entry display with custom formatters
---   - Multi-select support
---   - Preview with syntax highlighting
---   - Apply callback hooks

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values

local M = {}

---@class MigrateCommon.PickerOpts
---@field title string                       # Picker prompt title
---@field format_entry fun(match: table): string # Format match for display
---@field format_preview fun(match: table): string[] # Generate preview lines
---@field on_apply fun(selections: table[]) # Callback for applying migrations
---@field single_apply boolean|nil          # Apply single match immediately

--- Show generic migration picker
---@param matches table[] List of matches (any structure)
---@param opts MigrateCommon.PickerOpts
function M.show(matches, opts)
  -- Handle empty matches
  if #matches == 0 then
    vim.notify("No matches found", vim.log.levels.INFO)
    return
  end

  -- Single match: apply immediately if configured
  if #matches == 1 and opts.single_apply then
    opts.on_apply({ matches[1] })
    return
  end

  -- Build entry displayer
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 40 },        -- Location
      { remaining = true },  -- Content
    },
  })

  -- Build Telescope entries
  local entries = {}
  for _, match in ipairs(matches) do
    local display_text = opts.format_entry(match)

    table.insert(entries, {
      value = match,
      ordinal = display_text,
      display = function()
        return displayer({
          { display_text:sub(1, 40), "Comment" },
          { display_text:sub(41), "Normal" }
        })
      end,
    })
  end

  -- Create picker
  pickers.new({}, {
    prompt_title = opts.title,

    finder = finders.new_table({
      results = entries,
      entry_maker = function(e) return e end,
    }),

    previewer = previewers.new_buffer_previewer({
      title = "Preview",
      define_preview = function(self, entry)
        local lines = opts.format_preview(entry.value)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.api.nvim_set_option_value("filetype", "lua", { buf = self.state.bufnr })
      end,
    }),

    sorter = conf.generic_sorter({}),
    selection_caret = "* ",

    attach_mappings = function(prompt_bufnr)
      --- Apply to selected or multi-selected entries
      local function apply()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()

        if vim.tbl_isempty(selections) then
          selections = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)

        -- Extract values
        local matches_to_apply = {}
        for _, entry in ipairs(selections) do
          table.insert(matches_to_apply, entry.value)
        end

        opts.on_apply(matches_to_apply)
      end

      vim.keymap.set({ "i", "n" }, "<CR>", apply, { buffer = prompt_bufnr })
      vim.keymap.set({ "i", "n" }, "<S-A>", function()
        actions.close(prompt_bufnr)
        opts.on_apply(matches)
      end, { buffer = prompt_bufnr })

      return true
    end,
  }):find()
end

return M
