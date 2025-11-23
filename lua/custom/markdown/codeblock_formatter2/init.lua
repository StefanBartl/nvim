---@module 'custom.markdown.codeblock_formatter'
--- Module for formatting code blocks within markdown files.
--- Supports both visual range selection and automatic detection of multiple code blocks.
--- Uses CLI formatters (stylua, prettier, etc.) to format code without requiring LSP attachment.

local M = {}

local api = vim.api
local fn = vim.fn
local uv = vim.loop

--- Default formatter configurations for supported languages
---@type table<string, {cmd: string, args: string[]}>
local default_formatters = {
  lua = {
    cmd = "stylua",
    args = { "-" }, -- stdin/stdout mode
  },
  javascript = {
    cmd = "prettier",
    args = { "--stdin-filepath", "file.js" },
  },
  typescript = {
    cmd = "prettier",
    args = { "--stdin-filepath", "file.ts" },
  },
  javascriptreact = {
    cmd = "prettier",
    args = { "--stdin-filepath", "file.jsx" },
  },
  typescriptreact = {
    cmd = "prettier",
    args = { "--stdin-filepath", "file.tsx" },
  },
  json = {
    cmd = "prettier",
    args = { "--stdin-filepath", "file.json" },
  },
  python = {
    cmd = "black",
    args = { "--quiet", "-" },
  },
  go = {
    cmd = "gofmt",
    args = {},
  },
  rust = {
    cmd = "rustfmt",
    args = {},
  },
  css = {
    cmd = "prettier",
    args = { "--stdin-filepath", "file.css" },
  },
  html = {
    cmd = "prettier",
    args = { "--stdin-filepath", "file.html" },
  },
}

--- Module configuration
---@class CodeblockFormatterConfig
---@field formatters table<string, {cmd: string, args: string[]}> Formatter configurations per language
---@field notify_level integer Notification level for messages
---@field prefer_treesitter boolean Whether to prefer treesitter for code block detection
---@field ts_block_node string Treesitter node type for fenced code blocks
---@field supported_langs string[]|nil List of supported languages (nil = all in formatters table)
M._config = {
  formatters = default_formatters,
  notify_level = vim.log.levels.INFO,
  prefer_treesitter = true,
  ts_block_node = "fenced_code_block",
  supported_langs = nil,
}

--- Setup the module with custom configuration
---@param opts CodeblockFormatterConfig|nil Configuration options
function M.setup(opts)
  M._config = vim.tbl_deep_extend("force", M._config, opts or {})
end

--- Notify user with a message
---@param msg string Message to display
---@param level integer|nil Log level (default: INFO)
local function notify(msg, level)
  vim.notify("[CodeblockFormatter] " .. msg, level or M._config.notify_level)
end

--- Resolve formatter command path (check Mason first, then PATH)
---@param cmd string Command name to resolve
---@return string|nil path Full path to command or nil if not found
local function resolve_formatter_path(cmd)
  -- Try Mason registry first
  local mason_ok, mason_registry = pcall(require, "mason-registry")
  if mason_ok and mason_registry.is_installed(cmd) then
    local pkg = mason_registry.get_package(cmd)
    local install_path = pkg:get_install_path()

    -- Common Mason binary locations
    local possible_paths = {
      install_path .. "/bin/" .. cmd,
      install_path .. "/" .. cmd,
      install_path .. "/node_modules/.bin/" .. cmd, -- for npm packages
    }

    for _, path in ipairs(possible_paths) do
      if fn.executable(path) == 1 then
        return path
      end
    end
  end

  -- Fallback to PATH
  if fn.executable(cmd) == 1 then
    return cmd
  end

  return nil
end

--- Extract language from fence line (e.g., "```lua" -> "lua")
---@param line string The fence line containing language identifier
---@return string|nil language Language identifier or nil if not found
local function extract_language(line)
  local lang = line:match("^```%s*(%S+)")
  return lang
end

--- Detect code block boundaries using treesitter
---@param bufnr integer Buffer number
---@param start_line integer Starting line number (1-indexed)
---@param end_line integer Ending line number (1-indexed)
---@return table|nil block Code block info or nil if not found
local function detect_codeblock_ts(bufnr, start_line, end_line)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown")
  if not ok or not parser then
    return nil
  end

  local tree = parser:parse()[1]
  if not tree then
    return nil
  end

  local root = tree:root()
  local query = vim.treesitter.query.parse(
    "markdown",
    string.format("(%s) @block", M._config.ts_block_node)
  )

  -- Convert to 0-indexed for treesitter
  local start_row = start_line - 1
  local end_row = end_line - 1

  for _, node in query:iter_captures(root, bufnr, start_row, end_row + 1) do
    local node_start, _, node_end, _ = node:range()

    -- Check if selection overlaps with this code block
    if node_start <= end_row and node_end >= start_row then
      local lines = api.nvim_buf_get_lines(bufnr, node_start, node_end + 1, false)

      -- First line should be the fence with language
      local lang = extract_language(lines[1])
      if not lang then
        goto continue
      end

      -- Extract code content (skip fence lines)
      local code_lines = {}
      for i = 2, #lines - 1 do
        table.insert(code_lines, lines[i])
      end

      return {
        lang = lang,
        start_line = node_start + 2, -- Skip opening fence (1-indexed)
        end_line = node_end, -- Before closing fence (1-indexed)
        lines = code_lines,
      }
    end

    ::continue::
  end

  return nil
end

--- Detect code block boundaries using pattern matching
---@param bufnr integer Buffer number
---@param start_line integer Starting line number (1-indexed)
---@param end_line integer Ending line number (1-indexed)
---@return table|nil block Code block info or nil if not found
local function detect_codeblock_pattern(bufnr, start_line, end_line)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local in_block = false
  local block_start = nil
  local block_lang = nil
  local code_lines = {}

  for i = 1, #lines do
    local line = lines[i]

    -- Check for opening fence
    if line:match("^```") and not in_block then
      local lang = extract_language(line)
      if lang and i <= start_line then
        in_block = true
        block_start = i
        block_lang = lang
        code_lines = {}
      end
    -- Check for closing fence
    elseif line:match("^```") and in_block then
      -- Check if selection is within this block
      if start_line >= block_start and end_line <= i then
        return {
          lang = block_lang,
          start_line = block_start + 1,
          end_line = i - 1,
          lines = code_lines,
        }
      end
      in_block = false
      block_start = nil
      block_lang = nil
      code_lines = {}
    elseif in_block then
      table.insert(code_lines, line)
    end
  end

  return nil
end

--- Detect code block containing the given range
---@param bufnr integer Buffer number
---@param start_line integer Starting line number (1-indexed)
---@param end_line integer Ending line number (1-indexed)
---@return table|nil block Code block info or nil if not found
local function detect_codeblock(bufnr, start_line, end_line)
  if M._config.prefer_treesitter then
    local block = detect_codeblock_ts(bufnr, start_line, end_line)
    if block then
      return block
    end
  end

  return detect_codeblock_pattern(bufnr, start_line, end_line)
end

--- Find all code blocks in buffer
---@param bufnr integer Buffer number
---@return table[] blocks List of code block info tables
local function find_all_codeblocks(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local blocks = {}
  local in_block = false
  local block_start = nil
  local block_lang = nil
  local code_lines = {}

  for i = 1, #lines do
    local line = lines[i]

    -- Check for opening fence
    if line:match("^```") and not in_block then
      local lang = extract_language(line)
      if lang then
        in_block = true
        block_start = i
        block_lang = lang
        code_lines = {}
      end
    -- Check for closing fence
    elseif line:match("^```") and in_block then
      table.insert(blocks, {
        lang = block_lang,
        start_line = block_start + 1,
        end_line = i - 1,
        lines = code_lines,
      })
      in_block = false
      block_start = nil
      block_lang = nil
      code_lines = {}
    elseif in_block then
      table.insert(code_lines, line)
    end
  end

  return blocks
end

--- Format code using the specified formatter
---@param code string Code content to format
---@param lang string Programming language
---@param callback fun(formatted: string|nil, err: string|nil) Callback with result
local function format_code_async(code, lang, callback)
  local formatter = M._config.formatters[lang]
  if not formatter then
    callback(nil, "No formatter configured for language: " .. lang)
    return
  end

  local cmd_path = resolve_formatter_path(formatter.cmd)
  if not cmd_path then
    callback(nil, string.format(
      "Formatter not available: %s (not in Mason or PATH)",
      formatter.cmd
    ))
    return
  end

  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local stdin = uv.new_pipe(false)

  local stdout_data = {}
  local stderr_data = {}

  local handle, pid
  handle, pid = uv.spawn(
    cmd_path,
    {
      args = formatter.args,
      stdio = { stdin, stdout, stderr },
    },
    vim.schedule_wrap(function(code_exit, _)
      stdout:close()
      stderr:close()
      stdin:close()
      handle:close()

      if code_exit ~= 0 then
        local err_msg = table.concat(stderr_data, "")
        callback(nil, string.format("Formatter failed (exit %d): %s", code_exit, err_msg))
      else
        local formatted = table.concat(stdout_data, "")
        callback(formatted, nil)
      end
    end)
  )

  if not handle then
    callback(nil, "Failed to spawn formatter: " .. tostring(pid))
    return
  end

  -- Read stdout
  stdout:read_start(function(err, data)
    assert(not err, err)
    if data then
      table.insert(stdout_data, data)
    end
  end)

  -- Read stderr
  stderr:read_start(function(err, data)
    assert(not err, err)
    if data then
      table.insert(stderr_data, data)
    end
  end)

  -- Write code to stdin
  stdin:write(code)
  stdin:shutdown(function()
    -- All input sent
  end)
end

--- Format a single code block
---@param bufnr integer Buffer number
---@param block table Code block info
---@param callback fun(success: boolean) Callback when done
local function format_block_async(bufnr, block, callback)
  local code = table.concat(block.lines, "\n")

  format_code_async(code, block.lang, function(formatted, err)
    if err then
      notify(err, vim.log.levels.ERROR)
      callback(false)
      return
    end

    if not formatted then
      notify("Formatting returned empty result", vim.log.levels.WARN)
      callback(false)
      return
    end

    -- Split formatted code back into lines
    local formatted_lines = vim.split(formatted, "\n", { plain = true })

    -- Remove trailing empty line if formatter added one
    if formatted_lines[#formatted_lines] == "" then
      table.remove(formatted_lines)
    end

    -- Replace lines in buffer
    api.nvim_buf_set_lines(
      bufnr,
      block.start_line - 1,
      block.end_line,
      false,
      formatted_lines
    )

    notify(string.format("Formatted %s code block", block.lang))
    callback(true)
  end)
end

--- Format code block in visual selection or at cursor
---@param start_line integer|nil Starting line (1-indexed), nil for auto-detect
---@param end_line integer|nil Ending line (1-indexed), nil for auto-detect
function M.format_range_async(start_line, end_line)
  local bufnr = api.nvim_get_current_buf()

  -- Auto-detect range if not provided
  if not start_line or not end_line then
    local mode = fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
      start_line = fn.line("'<")
      end_line = fn.line("'>")
    else
      start_line = fn.line(".")
      end_line = start_line
    end
  end

  -- Detect code block
  local block = detect_codeblock(bufnr, start_line, end_line)
  if not block then
    notify("No code block found in selection", vim.log.levels.WARN)
    return
  end

  -- Check if language is supported
  if M._config.supported_langs then
    local supported = false
    for _, lang in ipairs(M._config.supported_langs) do
      if lang == block.lang then
        supported = true
        break
      end
    end
    if not supported then
      notify("Language not supported: " .. block.lang, vim.log.levels.WARN)
      return
    end
  end

  format_block_async(bufnr, block, function(success)
    if success then
      vim.cmd("silent! write")
    end
  end)
end

--- Format all code blocks in buffer
function M.format_buffer_async()
  local bufnr = api.nvim_get_current_buf()
  local blocks = find_all_codeblocks(bufnr)

  if #blocks == 0 then
    notify("No code blocks found in buffer", vim.log.levels.WARN)
    return
  end

  -- Filter supported languages if configured
  if M._config.supported_langs then
    local filtered = {}
    for _, block in ipairs(blocks) do
      for _, lang in ipairs(M._config.supported_langs) do
        if lang == block.lang then
          table.insert(filtered, block)
          break
        end
      end
    end
    blocks = filtered
  end

  if #blocks == 0 then
    notify("No supported code blocks found", vim.log.levels.WARN)
    return
  end

  notify(string.format("Formatting %d code block(s)...", #blocks))

  local completed = 0
  local total = #blocks

  for _, block in ipairs(blocks) do
    format_block_async(bufnr, block, function(_)
      completed = completed + 1
      if completed == total then
        notify(string.format("Formatted %d/%d code blocks", total, total))
        vim.cmd("silent! write")
      end
    end)
  end
end

--- Format code block at cursor or in visual selection (synchronous wrapper)
function M.format_range()
  M.format_range_async()
end

--- Format all code blocks in buffer (synchronous wrapper)
function M.format_buffer()
  M.format_buffer_async()
end

return M
