---@module 'custom.last_file.last_session'
---@brief Manual last-session file saving and restoring system
---@description
--- This module allows explicitly saving and restoring the last opened file
--- including the cursor position. Saving is only triggered manually via
--- `:LastFileSave` or `<leader><Esc>` (which force-quits Neovim and saves
--- the session). Restoration can be done manually with `:LastFileRestore`
--- or automatically on startup if a session is available. The saved session
--- can also be cleared after usage or manually via `:LastFileClear`.

---@class LastSessionModule
local M = {}

-- Session file location (e.g. ~/.local/share/nvim/last_file.txt)
---@type string
local session_file = vim.fn.stdpath("data") .. "/last_file.txt"

---Saves the currently active file and cursor position
---Saves current file path and cursor position to session file
function M.save()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)

  -- Skip if no file path
  if path == "" or vim.fn.filereadable(path) ~= 1 then
    return
  end

  -- Skip invalid or special buffers
  local buftype = vim.bo[buf].buftype
  if buftype ~= "" or not vim.bo[buf].buflisted then
    return
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local line, col = pos[1], pos[2]

  local ok, f = pcall(io.open, session_file, "w")
  if not ok or not f then
    vim.notify("[last_session] Failed to write session file", vim.log.levels.ERROR)
    return
  end

  f:write(path .. "\n")
  f:write(line .. " " .. col .. "\n")
  f:close()
end

---Restores the last saved file and cursor position
---@return nil
function M.restore()
  local ok, f = pcall(io.open, session_file, "r")
  if not ok or not f then
    vim.notify("[last_session] No saved file found", vim.log.levels.WARN)
    return
  end

  local path = f:read("*l")
  local pos_line = f:read("*l")
  f:close()

  if not path or vim.fn.filereadable(path) ~= 1 then
    vim.notify("[last_session] Saved file no longer exists: " .. (path or "<empty>"), vim.log.levels.WARN)
    return
  end

  local line, col = 1, 0
  if pos_line then
    local l, c = pos_line:match("^(%d+)%s+(%d+)$")
    line = tonumber(l) or 1
    col = tonumber(c) or 0
  end

  vim.cmd("edit " .. vim.fn.fnameescape(path))
  vim.schedule(function()
    pcall(vim.api.nvim_win_set_cursor, 0, { line, col })

    -- Trigger filetype + syntax detection
    vim.cmd("filetype detect")
    vim.cmd("syntax enable")

    local ft = vim.bo.filetype
    if ft ~= "" then
      vim.cmd("doautocmd FileType " .. ft)

      -- Attach LSP if none is running
      if #vim.lsp.get_clients({ bufnr = 0 }) == 0 and ft == "lua" then
        local ok_config, config = pcall(require, "lsp.languageservers.lua_ls")
        if ok_config then
          vim.lsp.start(config)
          vim.notify("[last_session] Attached lua_ls to restored buffer", vim.log.levels.INFO)
        end
      end
    end
  end)

  M.clear()
end

---Deletes the session file if it exists
---@return nil
function M.clear()
  if vim.fn.filereadable(session_file) == 1 then
    os.remove(session_file)
  end
end

---Checks whether a last session file exists and is valid
---@return boolean
function M.has_saved_session()
  local f = io.open(session_file, "r")
  if not f then return false end
  local path = f:read("*l")
  f:close()
  return path and vim.fn.filereadable(path) == 1
end

return M
