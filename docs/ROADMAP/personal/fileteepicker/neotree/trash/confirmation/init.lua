---@module 'config.neotree.trash.confirmation'
---@brief User confirmation dialogs for trash operations

local M = {}

local api, fn = vim.api, vim.fn
local tbl_insert, tbl_concat = table.insert, table.concat
local str_fmt = string.format
local min = math.min
local input = fn.input
local nvim_command = api.nvim_command
local km_set = vim.keymap.set

---Get unified confirmation for trash operation
---@param names string[]
---@param has_open_buffers boolean
---@return "all"|"individual"|"cancel"
---@nodiscard
function M.get_unified_confirmation(names, has_open_buffers)
  if #names == 1 then
    local buffer_info = has_open_buffers
      and "\n(Open buffers will be closed automatically)"
      or ""

    local prompt = ("Move to trash: %s?%s (y/N) "):format(names[1], buffer_info)
    local ans = input(prompt)
    nvim_command("redraw")

    return (ans == "y" or ans == "Y") and "all" or "cancel"
  end

  -- Multiple items
  local lines = {
    "=== Trash Confirmation ===",
    "",
    ("#items: %d"):format(#names),
  }

  -- Show first 10 items
  for i = 1, min(10, #names) do
    lines[#lines + 1] = ("  %d. %s"):format(i, names[i])
  end

  if #names > 10 then
    lines[#lines + 1] = ("  ... and %d more"):format(#names - 10)
  end

  lines[#lines + 1] = ""

  if has_open_buffers then
    lines[#lines + 1] = "⚠ Some files have open buffers"
    lines[#lines + 1] = "  (will be closed automatically)"
    lines[#lines + 1] = ""
  end

  lines[#lines + 1] = "Options:"
  lines[#lines + 1] = "  [a] Delete all at once"
  lines[#lines + 1] = "  [i] Confirm each individually"
  lines[#lines + 1] = "  [c] Cancel"
  lines[#lines + 1] = ""

  local prompt = tbl_concat(lines, "\n") .. "Choice (a/i/c): "
  local ans = input(prompt)
  nvim_command("redraw")

  if ans == "a" or ans == "A" then
    return "all"
  elseif ans == "i" or ans == "I" then
    return "individual"
  end

  return "cancel"
end

---Get confirmation mode for batch operations
---@param names string[]
---@return Cfg.NeoTree.DeleteMode|"cancel" # "all"|"individual"|"cancel"
function M.get_confirmation_mode(names)
  -- Single item: simple yes/no
  if #names == 1 then
    local prompt = str_fmt("Move to Trash: %s ? (y/N) ", names[1])
    local ans = input(prompt)
    nvim_command("redraw")

    if ans == "y" or ans == "Y" then
      return "all"
    else
      return "cancel"
    end
  end

  -- Multiple items: show list and options
  local lines = {
    "╭─────────────────────────────────────╮",
    "│     🗑️  Trash Confirmation        │",
    "╰─────────────────────────────────────╯",
    "",
    str_fmt("Items to delete (%d):", #names),
    "",
  }

  -- Show first 10 items
  local preview_count = min(10, #names)
  for i = 1, preview_count do
    tbl_insert(lines, str_fmt("  %2d. %s", i, names[i]))
  end

  -- Show "and more" if applicable
  if #names > 10 then
    tbl_insert(lines, "")
    tbl_insert(lines, str_fmt("  ... and %d more", #names - 10))
  end

  tbl_insert(lines, "")
  tbl_insert(lines, "╭─────────────────────────────────────╮")
  tbl_insert(lines, "│  Options:                          │")
  tbl_insert(lines, "│  [a] Delete all at once            │")
  tbl_insert(lines, "│  [i] Delete individually (confirm) │")
  tbl_insert(lines, "│  [c] Cancel                        │")
  tbl_insert(lines, "╰─────────────────────────────────────╯")
  tbl_insert(lines, "")

  local prompt = tbl_concat(lines, "\n") .. "Choice (a/i/c): "
  local ans = input(prompt)
  nvim_command("redraw")

  if ans == "a" or ans == "A" then
    return "all"
  elseif ans == "i" or ans == "I" then
    return "individual"
  else
    return "cancel"
  end
end

---Confirm individual item (only called in "individual" mode)
---@param name string
---@return boolean confirmed
function M.confirm_individual(name)
  local prompt = str_fmt("🗑️  Delete %s? (y/N) ", name)
  local ans = input(prompt)
  nvim_command("redraw")

  return ans == "y" or ans == "Y"
end

---Confirm buffer close before deletion
---@param filename string
---@param buffer_count integer
---@param preview_active boolean
---@return boolean confirmed
function M.confirm_close_buffers(filename, buffer_count, preview_active)
  local lines = {
    "╭─────────────────────────────────────╮",
    "│  ⚠️  Open References Detected      │",
    "╰─────────────────────────────────────╯",
    "",
  }

  tbl_insert(lines, str_fmt("File: %s", filename))
  tbl_insert(lines, "")

  if buffer_count > 0 then
    tbl_insert(lines, str_fmt("📄 Open in %d buffer%s",
      buffer_count,
      buffer_count > 1 and "s" or ""))
  end

  if preview_active then
    tbl_insert(lines, "🔍 Preview window active")
  end

  tbl_insert(lines, "")
  tbl_insert(lines, "Close and continue? (y/N) ")

  local prompt = tbl_concat(lines, "\n")
  local ans = input(prompt)
  nvim_command("redraw")

  return ans == "y" or ans == "Y"
end

---Show batch operation summary
---@param action string "copy"|"move"|"delete"
---@param count integer
---@return boolean confirmed
function M.confirm_batch_operation(action, count)
  local icon_map = {
    copy = "📋",
    move = "✂️",
    delete = "🗑️",
  }

  local icon = icon_map[action] or "⚡"
  local verb = action:sub(1, 1):upper() .. action:sub(2)

  local prompt = str_fmt(
    "%s  %s %d item%s? (y/N) ",
    icon,
    verb,
    count,
    count > 1 and "s" or ""
  )

  local ans = input(prompt)
  nvim_command("redraw")

  return ans == "y" or ans == "Y"
end

---Confirm dangerous operation (system directories, etc)
---@param path string
---@param reason string
---@return boolean confirmed
function M.confirm_dangerous_operation(path, reason)
  local lines = {
    "╭─────────────────────────────────────────╮",
    "│  ⚠️  DANGEROUS OPERATION WARNING      │",
    "╰─────────────────────────────────────────╯",
    "",
    str_fmt("Path: %s", path),
    "",
    str_fmt("Reason: %s", reason),
    "",
    "This operation could be destructive!",
    "",
    "Continue anyway? (yes/NO) ",
  }

  local prompt = tbl_concat(lines, "\n")
  local ans = input(prompt)
  nvim_command("redraw")

  -- Require explicit "yes" for dangerous ops
  return ans == "yes"
end

---Show operation result summary
---@param success integer
---@param failed integer
---@param skipped integer
---@param action string
---@return nil
---@diagnostic disable-next-line: unused-local
function M.show_result_summary(success, failed, skipped, action)
  local lines = {
    "╭─────────────────────────────────────╮",
    "│  Operation Complete                │",
    "╰─────────────────────────────────────╯",
    "",
  }

  if success > 0 then
    tbl_insert(lines, str_fmt("✓ Success: %d", success))
  end

  if failed > 0 then
    tbl_insert(lines, str_fmt("✗ Failed: %d", failed))
  end

  if skipped > 0 then
    tbl_insert(lines, str_fmt("⊘ Skipped: %d", skipped))
  end

  tbl_insert(lines, "")

  vim.notify(tbl_concat(lines, "\n"), vim.log.levels.INFO)
end

---Show error details in floating window
---@param errors table[] Array of {name: string, error: string}
---@return nil
function M.show_error_details(errors)
  if #errors == 0 then
    return
  end

  local lines = {
    "╭─────────────────────────────────────────╮",
    "│  ✗ Operation Errors                    │",
    "╰─────────────────────────────────────────╯",
    "",
  }

  for i, err in ipairs(errors) do
    tbl_insert(lines, str_fmt("%d. %s", i, err.name))
    tbl_insert(lines, str_fmt("   Error: %s", err.error))
    tbl_insert(lines, "")
  end

  -- Create floating window
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = 60
  local height = min(#lines + 2, 20)

  local ui = api.nvim_list_uis()[1]
  if not ui then
    return
  end

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - height) / 2),
    border = "rounded",
    style = "minimal",
    title = " Error Details ",
    title_pos = "center",
  }

  local win = api.nvim_open_win(buf, true, win_opts)

  -- Close keymaps
  local close = function()
    if api.nvim_win_is_valid(win) then
      api.nvim_win_close(win, true)
    end
  end

  km_set("n", "q", close, { buffer = buf, nowait = true })
  km_set("n", "<Esc>", close, { buffer = buf, nowait = true })
  km_set("n", "<CR>", close, { buffer = buf, nowait = true })

  -- Highlighting
  api.nvim_buf_add_highlight(buf, -1, "Title", 0, 0, -1)
  api.nvim_buf_add_highlight(buf, -1, "ErrorMsg", 1, 0, -1)
end

return M
