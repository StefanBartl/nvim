---@module 'mappings.toggle_comment'
--- Provides comment toggling functionality with support for EmmyLua annotations.
--- Handles both regular comments and annotation comments (---@...) in normal and visual mode.

local M = {}

--- Toggle comment for a single line with annotation support
---
--- Detects whether the current line is an EmmyLua annotation or regular code.
--- For annotations: toggles between "---@..." and "-- ---@..."
--- For regular code: delegates to native gcc command
---@return nil
local function toggle_comment_with_annotations()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  -- Check if line is an annotation (starts with --- or -- ---)
  local is_annotation = line:match("^%s*%-%-%-") or line:match("^%s*%-%-%s+%-%-%-")

  if not is_annotation then
    -- Regular code: use native gcc command
    local keys = vim.api.nvim_replace_termcodes("gcc", true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)
    return
  end

  -- Toggle annotation comment
  local new_line
  if line:match("^%s*%-%-%s+%-%-%-") then
    -- Currently commented: "-- ---@module" -> "---@module"
    new_line = line:gsub("^(%s*)%-%-%s+(%-%-%-)", "%1%2")
  else
    -- Currently uncommented: "---@module" -> "-- ---@module"
    new_line = line:gsub("^(%s*)(%-%-%-)", "%1-- %2")
  end

  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
end

--- Toggle comments for a visual selection
---
--- Handles mixed content (regular code and annotations) by:
--- 1. Detecting if selection contains any annotations
--- 2. If no annotations: uses native gc command on visual selection
--- 3. If annotations present: toggles all lines individually
---@return nil
local function toggle_comment_visual()
  -- Capture visual selection range BEFORE exiting visual mode
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")

  -- Normalize order (handle backwards selection)
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- Check if selection contains any annotations BEFORE exiting visual mode
  local has_annotation = false
  for i = start_line, end_line do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    if line:match("^%s*%-%-%-") or line:match("^%s*%-%-%s+%-%-%-") then
      has_annotation = true
      break
    end
  end

  if not has_annotation then
    -- Pure regular code: use native gc command directly on visual selection
    -- Do NOT exit visual mode first - let gc handle it
    local keys = vim.api.nvim_replace_termcodes("gc", true, false, true)
    vim.api.nvim_feedkeys(keys, "x", false)
    return
  end

  -- Exit visual mode for annotation handling
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "x", false)

  -- Mixed or pure annotations: toggle each line individually
  for i = start_line, end_line do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    local new_line

    if line:match("^%s*%-%-%s+%-%-%-") then
      -- Commented annotation: "-- ---@..." -> "---@..."
      new_line = line:gsub("^(%s*)%-%-%s+(%-%-%-)", "%1%2")
    elseif line:match("^%s*%-%-%-") then
      -- Uncommented annotation: "---@..." -> "-- ---@..."
      new_line = line:gsub("^(%s*)(%-%-%-)", "%1-- %2")
    elseif line:match("^%s*%-%-%s+") then
      -- Commented regular code: "-- text" -> "text"
      new_line = line:gsub("^(%s*)%-%-%s+", "%1")
    elseif not line:match("^%s*$") then
      -- Uncommented regular code: "text" -> "-- text"
      new_line = line:gsub("^(%s*)", "%1-- ")
    else
      -- Empty line: leave unchanged
      new_line = line
    end

    if new_line ~= line then
      vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
    end
  end
end

--- Setup function to register keymaps
---@return nil
function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>/", toggle_comment_with_annotations, { desc = "[Text] Toggle comment" })
  map("v", "<leader>/", toggle_comment_visual, { desc = "[Text] Toggle comment" })
end

return M
