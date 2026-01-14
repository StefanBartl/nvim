---@module 'config.neotree.trash.validation.buffer_checker'
---@brief Detect and close buffers/previews referencing a path

local notify = require("lib.notify").create("[trash.buffer_checker]")

local M = {}

local api = vim.api
local fn = vim.fn
local resolve = fn.resolve

local config = {
  auto_close = false,
  debug = false,
}

---Set configuration
---@param cfg table
function M.set_config(cfg)
  config.auto_close = cfg.auto_close_buffers or false
  config.debug = cfg.debug or false
end

---Set debug mode
---@param enabled boolean
function M.set_debug(enabled)
  config.debug = enabled
end

---Debug notify
---@param msg string
local function debug(msg)
  if config.debug then
    notify.info(msg)
  end
end

---Force close all Neo-tree preview windows
---@return boolean success
local function force_close_preview()
  local closed = false

  -- Method 1: via Neo-tree preview module
  pcall(function()
    local preview = require("neo-tree.sources.common.preview")
    if preview then
      if preview.hide then
        preview.hide()
        closed = true
        debug("✓ Closed preview via hide()")
      end

      if preview.is_active and preview.is_active() then
        if preview.revert then
          pcall(preview.revert)
          closed = true
          debug("✓ Closed preview via revert()")
        end
      end
    end
  end)

  -- Method 2: Find float windows manually
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) then
      local ok, config = pcall(api.nvim_win_get_config, win)
      if ok and config.relative ~= "" then
        local buf = api.nvim_win_get_buf(win)
        local buftype = vim.bo[buf].buftype

        -- Close if looks like preview
        if buftype == "nofile" or buftype == "" then
          pcall(api.nvim_win_close, win, true)
          closed = true
          debug(string.format("✓ Closed float window %d", win))
        end
      end
    end
  end

  if closed then
    vim.wait(50)
  end

  return closed
end

---Find buffers referencing a path
---@param path string
---@return integer[] bufnrs
---@return string[] buf_names
local function find_buffers(path)
  local bufnrs = {}
  local buf_names = {}
  local normalized_path = resolve(path):gsub("\\", "/")

  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) and api.nvim_buf_is_loaded(buf) then
      local buf_name = api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local normalized_buf = resolve(buf_name):gsub("\\", "/")

        if normalized_buf == normalized_path or
           normalized_buf:sub(1, #normalized_path) == normalized_path then
          table.insert(bufnrs, buf)
          local display = fn.fnamemodify(buf_name, ":t")
          if display == "" then
            display = string.format("[Buffer %d]", buf)
          end
          table.insert(buf_names, display)
        end
      end
    end
  end

  return bufnrs, buf_names
end

---Check if preview is showing a path
---@param path string
---@return boolean is_open
---@return string|nil info
local function check_preview(path)
  local normalized_path = resolve(path):gsub("\\", "/")

  -- Check if preview is active
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

  -- Check windows
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) then
      local win_buf = api.nvim_win_get_buf(win)
      local buf_name = api.nvim_buf_get_name(win_buf)

      if buf_name ~= "" then
        local normalized_buf = resolve(buf_name):gsub("\\", "/")
        if normalized_buf == normalized_path or
           normalized_buf:sub(1, #normalized_path) == normalized_path then
          local win_config = api.nvim_win_get_config(win)
          if win_config.relative ~= "" then
            return true, string.format("Preview Window (Win %d)", win)
          end
        end
      end
    end
  end

  return false, nil
end

---Check if path has any open references
---@param path string
---@return boolean has_refs
---@return table ref_info {buffers: {bufnrs, names}, preview: {active, info}}
function M.check_references(path)
  local bufnrs, buf_names = find_buffers(path)
  local has_preview, preview_info = check_preview(path)

  local has_refs = #bufnrs > 0 or has_preview

  local ref_info = {
    buffers = {
      bufnrs = bufnrs,
      names = buf_names,
    },
    preview = {
      active = has_preview,
      info = preview_info,
    },
  }

  return has_refs, ref_info
end

---Format remaining references for error message
---@param ref_info table
---@return string
function M.format_remaining_references(ref_info)
  local lines = {}

  if #ref_info.buffers.bufnrs > 0 then
    table.insert(lines, string.format("- %d buffer(s)", #ref_info.buffers.bufnrs))
  end

  if ref_info.preview.active then
    table.insert(lines, "- Preview window")
  end

  return table.concat(lines, "\n")
end

---Close all references to a path
---@param path string
---@param filename string
---@param ref_info table
---@param ask_user boolean
---@return boolean success
---@return boolean user_cancelled
function M.close_references(path, filename, ref_info, ask_user)
  local bufnrs = ref_info.buffers.bufnrs
  local buf_names = ref_info.buffers.names
  local has_preview = ref_info.preview.active
  local preview_info = ref_info.preview.info

  -- Build message
  local details = {}

  if #bufnrs > 0 then
    table.insert(details, string.format(
      "📄 File '%s' is open in %d buffer%s:",
      filename,
      #bufnrs,
      #bufnrs > 1 and "s" or ""
    ))
    for i, name in ipairs(buf_names) do
      table.insert(details, string.format("   [%d] %s", bufnrs[i], name))
    end
  end

  if has_preview then
    table.insert(details, string.format("🔍 Preview: %s", preview_info or "active"))
  end

  debug(table.concat(details, "\n"))

  -- Ask user if needed
  if ask_user and not config.auto_close then
    table.insert(details, "")
    table.insert(details, "Close and continue? (y/N)")

    local prompt = table.concat(details, "\n") .. " "
    local ans = fn.input(prompt)
    api.nvim_command("redraw")

    if ans ~= "y" and ans ~= "Y" then
      debug("❌ User cancelled")
      return false, true
    end
  end

  debug("🔄 Closing references...")

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
        debug(string.format("✓ Closed buffer %d: %s", bufnr, buf_names[i]))
      else
        table.insert(failed, { bufnr = bufnr, name = buf_names[i] })
        debug(string.format("✗ Failed to close buffer %d: %s", bufnr, buf_names[i]))
      end
    end
  end

  if #failed > 0 then
    local error_lines = { "❌ Failed to close buffers:" }
    for _, fail in ipairs(failed) do
      table.insert(error_lines, string.format("   [%d] %s", fail.bufnr, fail.name))
    end
    table.insert(error_lines, "Please close manually")

    notify.error(table.concat(error_lines, "\n"))
    return false, false
  end

  vim.wait(100)
  return true, false
end

return M
