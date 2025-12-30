---@module 'usrcmds.migrate.common.picker'
---@brief Generic Telescope picker for migration matches.
---@description
--- Provides a reusable picker implementation for all migration types.
--- Handles:
---   - Entry display with custom formatters
---   - Multi-select support (<Tab>)
---   - Preview with syntax highlighting
---   - Apply callback hooks
---   - Batch apply with <S-A>

require("usrcmds.migrate.common.@types")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values
local notify =require("lib.notify")

local M = {}

local api = vim.api

--- Show generic migration picker
---@param matches MigrateCommon.Match[]
---@param opts MigrateCommon.PickerOpts
function M.show(matches, opts)
  -- Validate matches
  if not matches or #matches == 0 then
    notify.info("No matches found")
    return
  end

  -- Single match: apply immediately if configured
  if #matches == 1 and opts.single_apply then
    opts.on_apply({ matches[1] })
    return
  end

  -- Build entry displayer
  local displayer = entry_display.create({
    separator = " │ ",
    items = {
      { width = 35 },        -- Location (file:line or buf:line)
      { remaining = true },  -- Content preview
    },
  })

  -- Build Telescope entries
  local entries = {}
  for _, match in ipairs(matches) do
    local display_text = opts.format_entry(match)

    -- Extract location and content parts
    local location = display_text:match("^(.-)  ") or display_text:sub(1, 35)
    local content = display_text:match("  (.+)$") or ""

    table.insert(entries, {
      value = match,
      ordinal = display_text,
      display = function()
        return displayer({
          { location, "Comment" },
          { content, "Normal" }
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
      title = "Migrated Preview",
      define_preview = function(self, entry)
        local lines = opts.format_preview(entry.value)
        api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

        -- Set filetype for syntax highlighting
        api.nvim_set_option_value("filetype", "lua", { buf = self.state.bufnr })

        -- Highlight the migrated line
        if #lines > 0 then
          api.nvim_buf_add_highlight(
            self.state.bufnr,
            -1,
            "DiffAdd",
            0,
            0,
            -1
          )
        end
      end,
    }),

    sorter = conf.generic_sorter({}),
    selection_caret = "▶ ",

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

        -- Call apply callback
        local ok, err = pcall(opts.on_apply, matches_to_apply)
        if not ok then
          notify.error("Migration failed: " .. tostring(err))
        end
      end

      --- Apply all matches (batch mode)
      local function apply_all()
        actions.close(prompt_bufnr)

        local ok, err = pcall(opts.on_apply, matches)
        if not ok then
          notify.error("Batch migration failed: " .. tostring(err))
        end
      end

      vim.keymap.set({ "i", "n" }, "<CR>", apply, { buffer = prompt_bufnr })
      vim.keymap.set({ "i", "n" }, "<S-A>", apply_all, { buffer = prompt_bufnr })

      return true
    end,
  }):find()
end

return M
