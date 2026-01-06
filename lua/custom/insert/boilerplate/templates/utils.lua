---@module 'custom.insert.boilerplate.templates.utils'
---@brief Common utilities for template generation

local M = {}

local api = vim.api

---Insert lines at current cursor position
---@param lines string[]
---@return nil
function M.insert_lines_at_cursor(lines)
  local win = api.nvim_get_current_win()
  local cursor = api.nvim_win_get_cursor(win)
  local row = cursor[1] - 1

  api.nvim_buf_set_lines(0, row, row, false, lines)
  api.nvim_win_set_cursor(win, { row + #lines + 1, 0 })
end

---Get Lua module path for current buffer
---@return string|nil module_path
function M.get_module_path()
  local filepath = api.nvim_buf_get_name(0)
  local normalized = filepath:gsub("\\", "/")
  local lua_idx = normalized:find("/lua/")
  if not lua_idx then
    return nil
  end

  local after_lua = normalized:sub(lua_idx + 5)
  local without_ext = after_lua:gsub("%.lua$", "")
  without_ext = without_ext:gsub("/init$", "")
  return without_ext:gsub("/", ".")
end

---Prompt user for input with optional default
---@param prompt_text string
---@param default string|nil
---@param required boolean
---@return string|nil value
function M.prompt_user(prompt_text, default, required)
  local input = vim.fn.input(prompt_text)

  if input == "" then
    if default then
      return default
    end
    if required then
      vim.notify(
        "[custom.insert.boilerplate] Required input was empty",
        vim.log.levels.ERROR
      )
      return nil
    end
  end

  return input
end

---Process multiple prompts for template
---@param prompts Custom.Insert.Boilerplate.PromptSpec[]
---@return table<string, string>|nil values
function M.process_prompts(prompts)
  local values = {}

  for _, spec in ipairs(prompts) do
    local value = M.prompt_user(
      spec.prompt .. ": ",
      spec.default,
      spec.required
    )

    if not value and spec.required then
      return nil
    end

    values[spec.name] = value or spec.default or ""
  end

  return values
end

return M
