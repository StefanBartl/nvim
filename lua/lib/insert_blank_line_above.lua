---@module 'lib.text'
--- Single-function module: safely insert a blank line above the cursor.
--- Exported value is the function itself (not a table), so it can be
--- re-exported by an aggregator (e.g., `require("lib").insert_blank_line_above`).
--- Linux/macOS only; no Windows-specific branches. TODO:

return function(opts)
  opts = opts or {}
  local keep_on_text = (opts.keep_cursor_on_text ~= false)
  local do_notify = (opts.notify ~= false)

  -- Current buffer and its flags
  local buf = vim.api.nvim_get_current_buf()
  local bo = vim.bo[buf]

  -- Refuse read-only / unmodifiable buffers early
  if (not bo.modifiable) or bo.readonly then
    if do_notify then
      vim.notify("[lib.text] Buffer is not modifiable/read-only.", vim.log.levels.WARN)
    end
    return false, "not_modifiable"
  end

  -- Disallow special buftypes where editing lines is unexpected
  ---@type table<string, boolean>
  local disallowed = { terminal = true, prompt = true, help = true, quickfix = true }
  if disallowed[bo.buftype] then
    if do_notify then
      vim.notify("[lib.text] Disallowed buftype: " .. tostring(bo.buftype), vim.log.levels.WARN)
    end
    return false, "bad_buftype"
  end

  -- 1-based row, 0-based col
  local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))

  -- Insert a blank line above the current row.
  local ok = pcall(vim.api.nvim_buf_set_lines, buf, row - 1, row - 1, false, { "" })
  if not ok then
    if do_notify then
      vim.notify("[lib.text] Failed to insert blank line.", vim.log.levels.ERROR)
    end
    return false, "insert_failed"
  end

  -- Decide the target row for the cursor after the insertion.
  local target_row = keep_on_text and (row + 1) or row

  -- Compute a safe column for the target line after insertion.
  local target_line = (vim.api.nvim_buf_get_lines(buf, target_row - 1, target_row, false)[1]) or ""
  local line_len = #target_line
  if col > line_len then col = line_len end

  -- Move cursor; protect against edge cases with pcall.
  pcall(vim.api.nvim_win_set_cursor, 0, { target_row, col })

  return true, nil
end

