---@module 'bindings.mappings.toggle_comment'
--- Provides comment toggling functionality with support for EmmyLua annotations.
--- Handles both regular comments and annotation comments (---@...) in normal and visual mode.

local M = {}

--- Get comment string for current buffer
---@return string
local function get_comment_string()
  local commentstring = vim.bo.commentstring
  if commentstring == "" then
    commentstring = "# %s" -- Fallback
  end
  -- Extract comment leader (e.g., "--" from "-- %s")
  local leader = commentstring:match("^(.-)%%s") or commentstring:match("^(.+)$") or "--"
  return vim.trim(leader)
end

--- Check if a line is commented (regular comment, not annotation)
---@param line string
---@param comment_str string
---@return boolean
local function is_commented(line, comment_str)
  local pattern = "^%s*" .. vim.pesc(comment_str) .. "%s"
  return line:match(pattern) ~= nil
end

--- Toggle comment for a regular line
---@param line string
---@param comment_str string
---@return string
local function toggle_regular_comment(line, comment_str)
  if is_commented(line, comment_str) then
    -- Remove comment
    local pattern = "^(%s*)" .. vim.pesc(comment_str) .. "%s+"
    return (line:gsub(pattern, "%1"))
  else
    -- Add comment (preserve leading whitespace)
    if line:match("^%s*$") then
      -- Empty line: leave unchanged
      return line
    end
    return (line:gsub("^(%s*)", "%1" .. comment_str .. " "))
  end
end

--- Toggle comment for a single line with annotation support
---
--- Detects whether the current line is an EmmyLua annotation or regular code.
--- For annotations: toggles between "---@..." and "-- ---@..."
--- For regular code: toggles regular Lua comments
---@return nil
local function toggle_comment_with_annotations()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  -- Check if line is an annotation (starts with --- or -- ---)
  local is_annotation = line:match("^%s*%-%-%-") or line:match("^%s*%-%-%s+%-%-%-")

  if is_annotation then
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
  else
    -- Regular code: toggle regular comment
    local comment_str = get_comment_string()
    local new_line = toggle_regular_comment(line, comment_str)
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
  end
end

--- Toggle comments for a visual selection
---
--- Handles mixed content (regular code and annotations) by:
--- 1. Detecting if all selected lines are commented
--- 2. If all commented: uncomments all lines
--- 3. If any uncommented: comments all lines
--- 4. Handles annotations and regular code separately
---@return nil
local function toggle_comment_visual()
  -- Capture visual selection range BEFORE exiting visual mode
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")

  -- Normalize order (handle backwards selection)
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- Exit visual mode
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "x", false)

  -- Get all lines
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local comment_str = get_comment_string()

  -- Determine if we should comment or uncomment
  -- Check if ALL non-empty lines are commented
  local all_commented = true
  for _, line in ipairs(lines) do
    if not line:match("^%s*$") then -- Ignore empty lines
      local is_annotation = line:match("^%s*%-%-%-") or line:match("^%s*%-%-%s+%-%-%-")
      if is_annotation then
        -- For annotations: check if commented (starts with "-- ---")
        if not line:match("^%s*%-%-%s+%-%-%-") then
          all_commented = false
          break
        end
      else
        -- For regular code: check if commented
        if not is_commented(line, comment_str) then
          all_commented = false
          break
        end
      end
    end
  end

  -- Toggle all lines based on detected state
  local new_lines = {}
  for i, line in ipairs(lines) do
    if line:match("^%s*$") then
      -- Empty line: leave unchanged
      new_lines[i] = line
    else
      local is_annotation = line:match("^%s*%-%-%-") or line:match("^%s*%-%-%s+%-%-%-")

      if is_annotation then
        -- Handle annotation
        if all_commented then
          -- Uncomment: "-- ---@..." -> "---@..."
          new_lines[i] = line:gsub("^(%s*)%-%-%s+(%-%-%-)", "%1%2")
        else
          -- Comment: "---@..." -> "-- ---@..."
          new_lines[i] = line:gsub("^(%s*)(%-%-%-)", "%1-- %2")
        end
      else
        -- Handle regular code
        if all_commented then
          -- Uncomment
          local pattern = "^(%s*)" .. vim.pesc(comment_str) .. "%s+"
          new_lines[i] = line:gsub(pattern, "%1")
        else
          -- Comment
          new_lines[i] = line:gsub("^(%s*)", "%1" .. comment_str .. " ")
        end
      end
    end
  end

  -- Apply changes
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
end

--- Setup function to register keymaps
---@return nil
function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>/", toggle_comment_with_annotations, { desc = "[Text] Toggle comment" })
  map("v", "<leader>/", toggle_comment_visual, { desc = "[Text] Toggle comment" })
end

return M
