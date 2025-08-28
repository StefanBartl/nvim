---@module 'custom.last_file'
--- Manual last-file session: save path+cursor and restore on demand or on startup.
--- One-file version that also registers user commands and auto-restore.
--- LSP attach is triggered via lspconfig managers (no direct vim.lsp.start).

---@class LastSessionModule
---@field save fun():nil                -- save current file + cursor to a small file
---@field restore fun():nil             -- restore file + cursor, re-attach LSP
---@field clear fun():nil               -- delete the small session file
---@field has_saved_session fun():boolean
local M = {}

require("custom.last_file.commands")
require("custom.last_file.keymaps")

-- Path to small session file, e.g. ~/.local/share/nvim/last_file.txt
---@type string
local session_file = vim.fn.stdpath("data") .. "/last_file.txt"

--- Save current buffer path and cursor position to the session file.
---@return nil
function M.save()
  -- Skip unlisted/special buffers or unnamed buffers
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or vim.fn.filereadable(path) ~= 1 then
    return
  end
  local bt = vim.bo[bufnr].buftype
  if bt ~= "" or not vim.bo[bufnr].buflisted then
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

--- Internal: (re)attach LSP using lspconfig managers.
---@param bufnr integer
local function ensure_lsp(bufnr)
  -- If any client is already attached, we're done.
  if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
    return
  end

  -- Ask every configured lspconfig server manager to try_add() for this buffer.
  local ok_lsp, lspconfig = pcall(require, "lspconfig")
  if ok_lsp then
    for _, cfg in pairs(lspconfig) do
      -- cfg is a table for servers; util/etc. won't have a manager
      if type(cfg) == "table" and cfg.manager and type(cfg.manager.try_add) == "function" then
        pcall(cfg.manager.try_add, bufnr)
      end
    end
  end

  -- Nudge FileType autocommands (lspconfig hooks into FileType).
  local ft = vim.bo[bufnr].filetype
  if ft and ft ~= "" then
    pcall(vim.api.nvim_exec_autocmds, "FileType", { buffer = bufnr })
  end
end

--- Restore the last saved file and cursor position, then re-attach LSP.
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

  -- Open the file (triggers BufRead autocommands).
  vim.cmd("edit " .. vim.fn.fnameescape(path))

  -- After the window exists, set cursor and re-attach LSP.
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_win_set_cursor, 0, { line, col })
    -- Filetype detection (usually already done by :edit; keep as guard)
    vim.cmd("filetype detect")
    -- Attach LSP via lspconfig managers
    ensure_lsp(bufnr)
  end)

  -- Optional: clear after successful restore so it's one-shot
  M.clear()
end

--- Delete the small session file.
---@return nil
function M.clear()
  if vim.fn.filereadable(session_file) == 1 then
    os.remove(session_file)
  end
end

--- Check whether the small session file exists and points to a readable file.
---@return boolean
function M.has_saved_session()
  local f = io.open(session_file, "r")
  if not f then
    return false
  end
  local path = f:read("*l")
  f:close()
  return path ~= nil and vim.fn.filereadable(path) == 1
end

return M
