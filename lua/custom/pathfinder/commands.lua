---@module 'custom.pathfinder.commands'
--- Wiring module that provides the user-facing mapping and coordinates extraction,
--- resolution and opening files. Every step uses notifier to emit debug messages.

local M = {}
local finder = require("custom.pathfinder.finder")
local notifier = require("custom.pathfinder.notifier")
local util = require("custom.pathfinder.util")
local extractor = require("custom.pathfinder.extractor")

--- Main action invoked by the mapping.
---@param opts table runtime options (from setup)
local function action(opts)
  opts = opts or {}
  notifier.notify("action: started", "info")

  -- 1) get full logical line where cursor is (works across wrapped lines)
  local line = vim.api.nvim_get_current_line()
  notifier.notify(("action: current_line -> %s"):format(line or ""), "debug")

  -- 2) extract candidates
  ---@type candidates
  local candidates = extractor(line or "")
  if not candidates or #candidates == 0 then
    notifier.notify("action: no path-like candidates found in line", "warn")
    return
  end

  -- 3) try to resolve candidates one by one
  ---@type string|nil
  local found_path = nil
  ---@type candidate|nil
  local found_candidate = nil

  -- Use indexed loop so we can add an explicit typed local for each element,
  -- which helps Lua language servers understand the shape of `cand`.
  for i = 1, #candidates do
    ---@type candidate
    local cand = candidates[i]

    -- defensive checks: ensure expected fields exist before formatting
    local raw_for_log = (cand and cand.raw) and cand.raw or "(no raw)"
    local path_for_log = (cand and cand.path) and cand.path or "(no path)"
    notifier.notify(("action: trying candidate raw='%s' path='%s'"):format(raw_for_log, path_for_log), "debug")

    -- guard candidate.path presence before passing to resolver
    if cand and cand.path and cand.path ~= "" then
      local resolved = finder.resolve_candidate(cand, { search_commands = opts.search_commands, max_results = opts.max_results })
      if resolved then
        found_path = resolved
        found_candidate = cand
        break
      end
    else
      notifier.notify("action: candidate has no path field; skipping", "debug")
    end
  end

  -- 4) if not found, attempt to find nearest folder
  if not found_path then
    notifier.notify("action: no file found; attempting to find nearest folder", "info")
    for i = 1, #candidates do
      ---@type candidate
      local cand = candidates[i]
      if cand then
        local folder = finder.find_nearest_folder(cand)
        if folder then
          found_path = folder
          found_candidate = cand
          break
        end
      end
    end
  end

  -- 5) report result via notify and open if it's a file
  if not found_path then
    notifier.notify("action: nothing found for any candidate", "warn")
    return
  end

  -- safe access to found_candidate.raw for logging
  local candidate_raw_for_log = (found_candidate and found_candidate.raw) and found_candidate.raw or "(unknown)"
  notifier.notify(("action: found -> %s (candidate raw=%s)"):format(found_path, candidate_raw_for_log), "info")

  -- if resolved path is directory, notify and do not open file (caller may extend)
  local stat = vim.loop.fs_stat(found_path)
  if stat and stat.type == "file" then
    notifier.notify(("action: opening file %s"):format(found_path), "info")

        -- open in current window (as requested)
    util.open_file(found_path)

    -- optionally jump to line/col if available and valid
    if found_candidate and type(found_candidate.lineno) == "number" and found_candidate.lineno > 0 then
      -- ensure column is a number (default to 0)
      local col = (type(found_candidate.col) == "number") and found_candidate.col or 0

      -- ensure lineno is integer
      local target_row = math.floor(found_candidate.lineno)

      -- get the current buffer (should be the just-opened file)
      local cur_buf = vim.api.nvim_get_current_buf()
      -- defensive: check buffer validity
      if not vim.api.nvim_buf_is_valid(cur_buf) then
        notifier.notify(("action: buffer not valid after opening file %s"):format(found_path), "warn")
      else
        -- clamp row to buffer line count
        local line_count = vim.api.nvim_buf_line_count(cur_buf) or 0
        if line_count == 0 then
          notifier.notify(("action: opened buffer has 0 lines for %s"):format(found_path), "warn")
          target_row = 1
        elseif target_row > line_count then
          notifier.notify(("action: requested lineno %d > line_count %d; clamping to %d"):format(target_row, line_count, line_count), "info")
          target_row = line_count
        elseif target_row < 1 then
          notifier.notify(("action: requested lineno %d < 1; clamping to 1"):format(target_row), "info")
          target_row = 1
        end

        -- clamp column to target line length (nvim expects 0-based col)
        local target_line_text = vim.api.nvim_buf_get_lines(cur_buf, target_row - 1, target_row, false)[1] or ""
        local max_col = math.max(0, #target_line_text)
        local target_col = math.floor(col)
        if target_col < 0 then target_col = 0 end
        if target_col > max_col then
          notifier.notify(("action: requested col %d > max_col %d; clamping to %d"):format(target_col, max_col, max_col), "debug")
          target_col = max_col
        end

        -- finally set cursor in current window
        local cur_win = vim.api.nvim_get_current_win()
        notifier.notify(("action: setting cursor to row=%d col=%d in buf=%d win=%d"):format(target_row, target_col, cur_buf, cur_win), "debug")
        pcall(vim.api.nvim_win_set_cursor, cur_win, { target_row, target_col })
      end
    else
      notifier.notify("action: no valid line/col information available to jump to", "debug")
    end
    end
end

--- Setup mapping and expose the command
---@param opts table
function M.setup(opts)
  opts = opts or {}
  local map = opts.map or "mp"

  -- register user command for manual invocation
  vim.api.nvim_create_user_command("PathfinderFind", function()
    action(opts)
  end, { desc = "Pathfinder: find and open path under cursor line" })

  -- mapping in normal mode using lua callback
  vim.keymap.set("n", map, function()
    notifier.notify(("mapping '%s' triggered"):format(map), "debug")
    action(opts)
  end, { noremap = true, silent = true, desc = "Pathfinder: search paths from current line" })

  -- notifier.notify(("commands: mapping %s installed and :PathfinderFind created"):format(map), "info")
end

return M
