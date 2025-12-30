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
local conf = require("telescope.config").values
local notify = require("lib.notify").create("[migrate.lua.notify]")

local M = {}

local api = vim.api

-- Safe notify wrapper

--- Show generic migration picker
---@param matches MigrateCommon.Match[]
---@param opts MigrateCommon.PickerOpts
function M.show(matches, opts)
  if not matches or #matches == 0 then
    notify.info("No matches found")
    return
  end

  if #matches == 1 and opts.single_apply then
    opts.on_apply({ matches[1] })
    return
  end

  pickers.new({}, {
    prompt_title = opts.title,

    finder = finders.new_table({
      results = matches,
      entry_maker = function(match)
        local display_text = opts.format_entry(match)

        -- Split into location and content
        local location = display_text:match("^(.-)  ") or display_text:sub(1, 35)
        local content = display_text:match("  (.+)$") or ""

        -- Format as simple string (no entry_display for now)
        local display_str = string.format("%-35s │ %s", location, content)

        return {
          value = match,
          ordinal = display_text,
          display = display_str,  -- Return plain string, not function
          filename = match.fname,
          lnum = match.lnum,
        }
      end,
    }),

    previewer = previewers.new_buffer_previewer({
      title = "Migrated Preview",
      define_preview = function(self, entry)
        local lines = opts.format_preview(entry.value)

        -- Flatten: split any lines containing newlines
        local flattened = {}
        for _, line in ipairs(lines) do
          if type(line) == "string" then
            for subline in line:gmatch("[^\r\n]+") do
              table.insert(flattened, subline)
            end
            -- Handle empty lines (when line is just "\n")
            if line:match("^[\r\n]+$") then
              table.insert(flattened, "")
            end
          else
            table.insert(flattened, tostring(line))
          end
        end

        api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, flattened)
        api.nvim_set_option_value("filetype", "lua", { buf = self.state.bufnr })

        if #flattened > 0 then
          api.nvim_buf_add_highlight(self.state.bufnr, -1, "DiffAdd", 0, 0, -1)
        end
      end,
    }),

    sorter = conf.generic_sorter({}),
    selection_caret = "▶ ",

    attach_mappings = function(prompt_bufnr, map)
      -- Replace default <CR> action
      actions.select_default:replace(function()
        print("DEBUG: select_default triggered") -- DEBUG

        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()

        if vim.tbl_isempty(selections) then
          local current = action_state.get_selected_entry()
          print("DEBUG: No multi-selection, using current:", current and current.value.lnum or "nil") -- DEBUG
          selections = { current }
        else
          print("DEBUG: Multi-selection count:", #selections) -- DEBUG
        end

        actions.close(prompt_bufnr)

        local matches_to_apply = {}
        for _, entry in ipairs(selections) do
          if entry and entry.value then
            table.insert(matches_to_apply, entry.value)
          end
        end

        print("DEBUG: Calling on_apply with", #matches_to_apply, "matches") -- DEBUG
        local ok, err = pcall(opts.on_apply, matches_to_apply)
        if not ok then
          notify.error("Migration failed: " .. tostring(err))
          print("DEBUG: Error:", err) -- DEBUG
        end
      end)

      -- Add batch apply with Shift-A
      map({ "i", "n" }, "<S-A>", function()
        print("DEBUG: Batch apply triggered") -- DEBUG
        actions.close(prompt_bufnr)
        local ok, err = pcall(opts.on_apply, matches)
        if not ok then
          notify.error("Batch migration failed: " .. tostring(err))
          print("DEBUG: Batch error:", err) -- DEBUG
        end
      end)

      return true
    end,
  }):find()
end

return M
