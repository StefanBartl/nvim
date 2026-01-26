---@module 'config.neotree.trash.validation.buffer_checker'
---@brief Detect and auto-close buffers/previews (no user prompts)

local notify = require("lib.notify").create("[trash.buffer_checker]")

local M = {}

local api = vim.api
local fn = vim.fn

local config = {
  debug = false,
}

---Set configuration
---@param cfg table
---@return nil
function M.set_config(cfg)
  config.debug = cfg.debug or false
end

---Debug notify
---@param msg string
---@return nil
local function debug(msg)
  if config.debug then
    notify.info(msg)
  end
end

---Force close preview windows
---@return boolean closed
---@nodiscard
local function force_close_preview()
  local closed = false

  -- Method 1: Neo-tree preview module
  pcall(function()
    local preview = require("neo-tree.sources.common.preview")
    if preview and preview.hide then
      preview.hide()
      closed = true
      debug("✓ Closed preview via hide()")
    end

    if preview and preview.is_active and preview.is_active() then
      if preview.revert then
        pcall(preview.revert)
        closed = true
        debug("✓ Closed preview via revert()")
      end
    end
  end)

  -- Method 2: Find float windows
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) then
      local ok, win_config = pcall(api.nvim_win_get_config, win)
      if ok and win_config.relative ~= "" then
        local buf = api.nvim_win_get_buf(win)
        local buftype = vim.bo[buf].buftype

        if buftype == "nofile" or buftype == "" then
          pcall(api.nvim_win_close, win, true)
          closed = true
          debug(("✓ Closed float window %d"):format(win))
        end
      end
    end
  end

  if closed then
    vim.wait(50)
  end

  return closed
end

---Find buffers referencing path
---@param path string
---@return integer[] bufnrs
---@return string[] names
---@nodiscard
local function find_buffers(path)
  local bufnrs = {}
  local names = {}
  local normalized = fn.resolve(path):gsub("\\", "/")

  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) and api.nvim_buf_is_loaded(buf) then
      local buf_name = api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local buf_norm = fn.resolve(buf_name):gsub("\\", "/")

        if buf_norm == normalized or buf_norm:sub(1, #normalized) == normalized then
          bufnrs[#bufnrs + 1] = buf
          local display = fn.fnamemodify(buf_name, ":t")
          names[#names + 1] = (display ~= "" and display or ("[Buffer %d]"):format(buf))
        end
      end
    end
  end

  return bufnrs, names
end

---Check if preview showing path
---@param path string
---@return boolean active
---@return string|nil info
---@nodiscard
local function check_preview(path)
  local normalized = fn.resolve(path):gsub("\\", "/")

  local preview_active = false
  pcall(function()
    local preview = require("neo-tree.sources.common.preview")
    if preview and preview.is_active then
      preview_active = preview.is_active()
    end
  end)

  if not preview_active then
    return false, nil
  end

  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) then
      local buf = api.nvim_win_get_buf(win)
      local buf_name = api.nvim_buf_get_name(buf)

      if buf_name ~= "" then
        local buf_norm = fn.resolve(buf_name):gsub("\\", "/")
        if buf_norm == normalized or buf_norm:sub(1, #normalized) == normalized then
          local win_config = api.nvim_win_get_config(win)
          if win_config.relative ~= "" then
            return true, ("Preview Window (Win %d)"):format(win)
          end
        end
      end
    end
  end

  return false, nil
end

---Check for references (buffers + preview)
---@param path string
---@return boolean has_refs
---@return table info
---@nodiscard
function M.check_references(path)
  local bufnrs, names = find_buffers(path)
  local has_preview, preview_info = check_preview(path)

  return (#bufnrs > 0 or has_preview), {
    buffers = { bufnrs = bufnrs, names = names },
    preview = { active = has_preview, info = preview_info },
  }
end

---Auto-close all references (no user prompt)
---@param path string
---@param filename string
---@param ref_info table
---@return boolean success
---@nodiscard
---@diagnostic disable-next-line: unused-local
function M.auto_close_references(path, filename, ref_info)
  local bufnrs = ref_info.buffers.bufnrs
  local buf_names = ref_info.buffers.names
  local has_preview = ref_info.preview.active

  debug(("🔄 Auto-closing references for: %s"):format(filename))

  -- Close preview first
  if has_preview then
    local closed = force_close_preview()
    if closed then
      debug("✓ Closed preview")
    else
      debug("⚠ Could not close preview")
    end
  end

  -- Close buffers
  local failed = {}
  for i, bufnr in ipairs(bufnrs) do
    if api.nvim_buf_is_valid(bufnr) then
      local ok = pcall(api.nvim_buf_delete, bufnr, { force = true })
      if ok then
        debug(("✓ Closed buffer %d: %s"):format(bufnr, buf_names[i]))
      else
        failed[#failed + 1] = { bufnr = bufnr, name = buf_names[i] }
        debug(("✗ Failed buffer %d: %s"):format(bufnr, buf_names[i]))
      end
    end
  end

  if #failed > 0 then
    local lines = { "❌ Failed to close buffers:" }
    for _, f in ipairs(failed) do
      lines[#lines + 1] = ("   [%d] %s"):format(f.bufnr, f.name)
    end
    lines[#lines + 1] = "Please close manually"
    notify.error(table.concat(lines, "\n"))
    return false
  end

  vim.wait(100)
  return true
end

return M
