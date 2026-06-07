---@module 'config.neotree.layout_guard'
---@brief Keeps Neo-tree from becoming the only normal window in a tab.

local autocmd = require("lib.autocmd")

local M = {}

local api = vim.api

---@class Cfg.NeoTree.LayoutGuard.Config
---@field enabled? boolean
---@field delay_ms? integer
---@field restore_focus? boolean

---@type Cfg.NeoTree.LayoutGuard.Config
local config = {
  enabled = true,
  delay_ms = 20,
  restore_focus = true,
}

local attached = false
local scheduled = false

---@param win integer
---@return boolean
local function is_normal_window(win)
  if type(win) ~= "number" or not api.nvim_win_is_valid(win) then
    return false
  end

  local ok, win_config = pcall(api.nvim_win_get_config, win)
  return ok and win_config.relative == ""
end

---@param bufnr integer
---@return boolean
local function is_neotree_buffer(bufnr)
  if type(bufnr) ~= "number" or not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  return vim.bo[bufnr].filetype == "neo-tree"
end

---@param bufnr integer
---@return boolean
local function is_editor_buffer(bufnr)
  if type(bufnr) ~= "number" or not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if not api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  return vim.bo[bufnr].buftype == "" and not is_neotree_buffer(bufnr)
end

---@return integer[] wins
local function list_tab_wins()
  local ok, wins = pcall(api.nvim_tabpage_list_wins, 0)
  if not ok or type(wins) ~= "table" then
    return {}
  end
  return wins
end

---@return integer|nil win
local function find_neotree_window()
  local wins = list_tab_wins()

  for i = 1, #wins do
    local win = wins[i]
    if is_normal_window(win) then
      local ok, buf = pcall(api.nvim_win_get_buf, win)
      if ok and is_neotree_buffer(buf) then
        return win
      end
    end
  end

  return nil
end

---@return boolean
local function has_editor_window()
  local wins = list_tab_wins()

  for i = 1, #wins do
    local win = wins[i]
    if is_normal_window(win) then
      local ok, buf = pcall(api.nvim_win_get_buf, win)
      if ok and is_editor_buffer(buf) then
        return true
      end
    end
  end

  return false
end

---@return Cfg.NeoTree.Position|"left"
local function get_position()
  local ok, neotree_config = pcall(require, "config.neotree")
  if ok and neotree_config and type(neotree_config.get_default_position) == "function" then
    return neotree_config.get_default_position()
  end

  return "left"
end

---@return string command
local function get_create_window_command()
  local position = get_position()

  if position == "right" then
    return "leftabove vnew"
  end

  if position == "top" then
    return "belowright new"
  end

  if position == "bottom" then
    return "aboveleft new"
  end

  return "rightbelow vnew"
end

---@return boolean created
local function create_editor_window()
  local neo_win = find_neotree_window()
  if neo_win == nil or not api.nvim_win_is_valid(neo_win) then
    return false
  end

  local previous_win = api.nvim_get_current_win()
  local ok = pcall(api.nvim_set_current_win, neo_win)
  if not ok then
    return false
  end

  ok = pcall(vim.cmd, get_create_window_command())
  if not ok then
    if api.nvim_win_is_valid(previous_win) then
      pcall(api.nvim_set_current_win, previous_win)
    end
    return false
  end

  local editor_win = api.nvim_get_current_win()
  local editor_buf = api.nvim_win_get_buf(editor_win)
  if api.nvim_buf_is_valid(editor_buf) then
    vim.bo[editor_buf].buflisted = true
  end

  if config.restore_focus and api.nvim_win_is_valid(previous_win) then
    pcall(api.nvim_set_current_win, previous_win)
  end

  return true
end

---Ensure the current tab has an editor window when Neo-tree is visible.
---@return boolean created
function M.ensure_editor_window()
  if not config.enabled then
    return false
  end

  if vim.v.exiting ~= vim.NIL and vim.v.exiting ~= 0 then
    return false
  end

  if has_editor_window() then
    return false
  end

  if find_neotree_window() == nil then
    return false
  end

  return create_editor_window()
end

---Schedule a guarded layout check after potentially destructive UI changes.
---@param opts Cfg.NeoTree.LayoutGuard.Config|nil
---@return nil
function M.ensure_editor_window_deferred(opts)
  if not config.enabled or scheduled then
    return
  end

  opts = opts or {}
  scheduled = true

  vim.defer_fn(function()
    scheduled = false
    M.ensure_editor_window()
  end, opts.delay_ms or config.delay_ms or 20)
end

---Attach autocmd-based protection for unknown buffer/window deletion paths.
---@param opts Cfg.NeoTree.LayoutGuard.Config|boolean|nil
---@return nil
function M.setup(opts)
  if opts == false then
    config.enabled = false
    return
  end

  if type(opts) == "table" then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  if attached or not config.enabled then
    return
  end

  attached = true

  autocmd.create({ "BufDelete", "BufWipeout", "WinClosed" }, function()
    M.ensure_editor_window_deferred()
  end, {
    group = "NeoTreeLayoutGuard",
    desc = "Keep an editor window beside Neo-tree",
  })
end

return M
