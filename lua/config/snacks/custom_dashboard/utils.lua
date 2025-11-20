---@module 'config.snacks.custom_dashboard.utils'
--- Small utility helpers used by the custom dashboard modules.
--- Keep functions tiny, pure where possible, and return explicit success values.

local uv = vim.uv or vim.loop
local api = vim.api

local M = {}

--- Check whether a buffer is "empty" (no name, single empty line).
--- @param bufnr integer?
--- @return boolean
function M.is_empty_buffer(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local name = api.nvim_buf_get_name(bufnr) or ""
  if name ~= "" then
    return false
  end
  local line_count = api.nvim_buf_line_count(bufnr)
  if line_count == 1 then
    local line = api.nvim_buf_get_lines(bufnr, 0, 1, true)[1] or ""
    return line == ""
  end
  return false
end

--- Heuristic: is buffer a "special" buffer (help, qf, terminal, checkhealth, etc.)
--- @param bufnr integer?
--- @return boolean
function M.is_special_buf(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(bufnr) then
    return true
  end
  -- buffer-local option accessor (stable API)
  local ok, ft = pcall(api.nvim_get_option_value, "filetype", { buf = bufnr })
  if not ok then
    ft = ""
  end
  local ok2, bt = pcall(api.nvim_get_option_value, "buftype", { buf = bufnr })
  if not ok2 then
    bt = ""
  end

  local blacklist = {
    help = true,
    qf = true,
    checkhealth = true,
    terminal = true,
    packer = true,
    TelescopePrompt = true,
  }
  if blacklist[ft] or blacklist[bt] then
    return true
  end
  return false
end

--- Check if buffer is modifiable
--- @param bufnr integer?
--- @return boolean
function M.is_modifiable(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local ok, val = pcall(api.nvim_get_option_value, "modifiable", { buf = bufnr })
  if not ok then
    return false
  end
  return val
end

--- Safe call wrapper: pcall + optional notify on error.
--- Returns boolean ok, ... (same as pcall)
--- @param fn function
--- @param on_err_level integer? (vim.log.levels.*)
--- @return boolean, any, any?
function M.safe_call(fn, on_err_level)
  if type(fn) ~= "function" then
    return false, "not a function"
  end
  local ok, res1, res2 = pcall(fn)
  if not ok then
    local lvl = on_err_level or vim.log.levels.ERROR
    vim.notify("[custom_dashboard] error: " .. tostring(res1), lvl)
  end
  return ok, res1, res2
end

--- Small filesystem helper: safe fs_stat
--- @param path string
--- @return table|nil
function M.fs_stat(path)
  if type(path) ~= "string" then
    return nil
  end
  local stat_ok, st = pcall(uv.fs_stat, path)
  if not stat_ok then
    return nil
  end
  return st
end

return M
