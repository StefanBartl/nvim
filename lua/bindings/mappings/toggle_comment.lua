---@module 'bindings.mappings.toggle_comment'
--- Comment toggling with EmmyLua-annotation awareness (`---@...` toggles to
--- `-- ---@...`), in normal and visual mode.

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

--- Is this line an EmmyLua annotation (`---@...`), commented or not?
---@param line string
---@return boolean
local function is_annotation(line)
  return line:match("^%s*%-%-%-") ~= nil or line:match("^%s*%-%-%s+%-%-%-") ~= nil
end

--- Comment or uncomment one line, annotation-aware. Empty lines pass through.
---@param line string
---@param comment_str string
---@param uncomment boolean  true = strip a comment leader, false = add one
---@return string
local function transform_line(line, comment_str, uncomment)
  if line:match("^%s*$") then
    return line
  end
  if is_annotation(line) then
    if uncomment then
      -- "-- ---@module" -> "---@module"
      return (line:gsub("^(%s*)%-%-%s+(%-%-%-)", "%1%2"))
    end
    -- "---@module" -> "-- ---@module"
    return (line:gsub("^(%s*)(%-%-%-)", "%1-- %2"))
  end
  if uncomment then
    return (line:gsub("^(%s*)" .. vim.pesc(comment_str) .. "%s+", "%1"))
  end
  return (line:gsub("^(%s*)", "%1" .. comment_str .. " "))
end

--- Is this line currently commented (annotation or regular)?
---@param line string
---@param comment_str string
---@return boolean
local function line_is_commented(line, comment_str)
  if is_annotation(line) then
    return line:match("^%s*%-%-%s+%-%-%-") ~= nil
  end
  return is_commented(line, comment_str)
end

--- Toggle the comment state of the current line (annotation-aware).
---@return nil
local function toggle_comment_with_annotations()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local comment_str = get_comment_string()
  local new_line = transform_line(line, comment_str, line_is_commented(line, comment_str))
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
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

  -- Uncomment only if every non-empty line is already commented; otherwise
  -- comment the whole block.
  local all_commented = true
  for _, line in ipairs(lines) do
    if not line:match("^%s*$") and not line_is_commented(line, comment_str) then
      all_commented = false
      break
    end
  end

  local new_lines = {}
  for i, line in ipairs(lines) do
    new_lines[i] = transform_line(line, comment_str, all_commented)
  end

  -- Apply changes
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
end

--- Setup function to register keymaps
---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  map("n", "<leader>/", toggle_comment_with_annotations, { desc = "[Text] Toggle comment" })
  map("v", "<leader>/", toggle_comment_visual, { desc = "[Text] Toggle comment" })
end

return M
