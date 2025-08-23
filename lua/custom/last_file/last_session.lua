---@module 'custom.last_file.last_session'
--- Manual last-session file saving and restoring system.
--- Saves and restores the last opened file including cursor position.
--- On restore, re-triggers LSP via lspconfig managers instead of calling vim.lsp.start() directly.

---@class LastSessionModule
local M = {}

---@type string
local session_file = vim.fn.stdpath("data") .. "/last_file.txt"

--- Save current buffer path and cursor position to the session file.
---@return nil
function M.save()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)

  if path == "" or vim.fn.filereadable(path) ~= 1 then
    return
  end

  local bt = vim.bo[buf].buftype
  if bt ~= "" or not vim.bo[buf].buflisted then
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

--- Internal: robustly (re)attach LSP using lspconfig managers, if configured.
--- This avoids calling vim.lsp.start() with incomplete config.
---@param bufnr integer
local function ensure_lsp(bufnr)
  -- If any client is already attached, nothing to do.
  if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
    return
  end

  -- Try lspconfig managers: for every configured server that has a manager,
  -- ask it to try_add() for this buffer. Managers will no-op if filetype/root_dir doesn't match.
  local ok_lsp, lspconfig = pcall(require, "lspconfig")
  if ok_lsp then
    for name, cfg in pairs(lspconfig) do
      if type(cfg) == "table" and cfg.manager and type(cfg.manager.try_add) == "function" then
        pcall(cfg.manager.try_add, bufnr)
      end
    end
  end

  -- As an additional nudge, re-fire the FileType autocommands once lspconfig is loaded.
  -- lspconfig registers its startup on FileType; refire to be safe.
  local ft = vim.bo[bufnr].filetype
  if ft and ft ~= "" then
    pcall(vim.api.nvim_exec_autocmds, "FileType", { buffer = bufnr })
  end
end

--- Restore the last saved file and cursor position and trigger LSP attach via lspconfig.
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

  -- Open the file (triggers BufRead autocommands if they are already registered).
  vim.cmd("edit " .. vim.fn.fnameescape(path))

  -- Defer cursor placement and LSP attach to the main loop to ensure window exists.
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_win_set_cursor, 0, { line, col })

    -- Make sure filetype detection has happened
    -- (usually :edit does this automatically; keep as a safe guard).
    vim.cmd("filetype detect")

    -- Ensure LSP via lspconfig managers instead of vim.lsp.start()
    ensure_lsp(bufnr)
  end)

  -- Optionally clear after successful restore to make it a one-shot
  M.clear()
end

--- Delete the session file if it exists.
---@return nil
function M.clear()
  if vim.fn.filereadable(session_file) == 1 then
    os.remove(session_file)
  end
end

--- Check whether a last session file exists and is valid.
---@return boolean
function M.has_saved_session()
  local f = io.open(session_file, "r")
  if not f then
    return false
  end
  local path = f:read("*l")
  f:close()
  return path and vim.fn.filereadable(path) == 1 or false
end

return M
