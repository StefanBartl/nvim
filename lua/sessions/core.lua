---@module 'sessions/core'
---@brief Core save/load/list logic built on :mksession and :source with safety filters.
---@description
--- Implements the low-level functions to create, restore, and enumerate session files.
--- Guards all Neovim API calls (per safety checklist) and avoids serializing ephemeral state
--- via blacklists. Returns explicit booleans plus result/error strings to keep UI layers clean.

local fn, bo = vim.fn, vim.bo

---@class SessionsCore
local M = {}

local uv = vim.uv or vim.loop

---@param p string
---@return boolean
local function is_dir(p)
  local st = uv.fs_stat(p)
  return (st and st.type == "directory") or false
end

---@param dir string
---@return nil
local function ensure_dir(dir)
  if not is_dir(dir) then
    fn.mkdir(dir, "p")
  end
end

---@param s string
---@param list string[]
---@return boolean
local function starts_with_any(s, list)
  -- Fast prefix check; avoids patterns on hot path
  for i = 1, #list do
    local pref = list[i]
    if pref ~= nil and s:sub(1, #pref) == pref then return true end
  end
  return false
end

---@return nil
local function apply_sessionoptions()
  local cfg = require("sessions.config").cfg
  vim.opt.sessionoptions = cfg.sessionoptions
end

---@param name string|nil
---@return SessionInfo
local function resolve_session(name)
  local cfg = require("sessions.config").cfg
  local n = (type(name) == "string" and name ~= "" and name) or cfg.default_name
  local path = ("%s/%s.vim"):format(cfg.root, n)
  return { name = n, path = path }
end

---@return nil
local function wipe_blacklisted_buffers()
  -- Safety: do not serialize noisy or host-specific buffers (per rules/checklist).
  -- This intentionally errs on the safe side.
  local list = vim.api.nvim_list_bufs()
  for i = 1, #list do
    local b = list[i]
    if vim.api.nvim_buf_is_loaded(b) then
      local bt = bo[b].buftype
      local ft = bo[b].filetype
      local name = vim.api.nvim_buf_get_name(b)
      local bl = require("sessions.config").cfg.blacklist
      local bad = (bt ~= "" and vim.tbl_contains(bl.buftypes, bt))
        or (ft ~= "" and vim.tbl_contains(bl.filetypes, ft))
        or (name ~= "" and starts_with_any(name, bl.paths))
      if bad then
        pcall(vim.api.nvim_buf_delete, b, { force = true })
      end
    end
  end
end

---@param name string|nil
---@return boolean, string|nil
function M.save(name)
  -- Explicit returns, no UI side-effects in low level (per rules).
  local cfg = require("sessions.config").cfg
  apply_sessionoptions()
  ensure_dir(cfg.root)
  wipe_blacklisted_buffers()
  local si = resolve_session(name)
  local ok, err = pcall(vim.cmd.mksession, { args = { si.path }, bang = true })
  if not ok then return false, err end
  return true, si.path
end

---@param name string|nil
---@return boolean, string|nil
function M.load(name)
  local si = resolve_session(name)
  if fn.filereadable(si.path) == 0 then
    return false, "no such session: " .. si.path
  end
  apply_sessionoptions()
  local ok, err = pcall(vim.cmd.source, si.path)
  if not ok then return false, err end
  return true, si.path
end

---@return string[]
function M.list()
  local cfg = require("sessions.config").cfg
  if not is_dir(cfg.root) then return {} end
  local files = fn.globpath(cfg.root, "*.vim", false, true)
  table.sort(files)
  return files
end

return M

