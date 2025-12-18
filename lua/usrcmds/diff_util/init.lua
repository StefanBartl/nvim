---@module 'usrcmds.diff_util'
--- Advanced diff command for Neovim
--- Allows flexible diffing of files or buffers with optional flags and custom output.
--- Uses cross-platform diff wrapper to automatically select diff.exe on Windows.
-- FIX


local diff_wrapper = require("usrcmds.diff_util.wrapper")

local M = {}

local bo = vim.bo
local api = vim.api
local notify = vim.notify
local levels = vim.log.levels

local function escape_path(path)
  -- Escape spaces and special characters for shell
  return path:gsub("([%s%$`\\])", "\\%1")
end

local function parse_args(fargs)
  local opts = {
    context = false,
    unified = false,
    recursive = false,
    show = false,
    source = nil,
    target = nil,
    output = nil,
  }

  local i = 1
  while i <= #fargs do
    local arg = fargs[i]
    if arg == "-c" or arg == "--context" then opts.context = true
    elseif arg == "-u" or arg == "--unified" then opts.unified = true
    elseif arg == "-r" or arg == "--recursive" then opts.recursive = true
    elseif arg == "-s" or arg == "--show" then opts.show = true
    elseif arg == "-S" or arg == "--source" then
      i = i + 1
      opts.source = fargs[i]
    elseif arg == "-T" or arg == "--target" then
      i = i + 1
      opts.target = fargs[i]
    elseif arg == "-O" or arg == "--output" then
      i = i + 1
      opts.output = fargs[i]
    else
      -- positional args if not prefixed
      if not opts.source then opts.source = arg
      elseif not opts.target then opts.target = arg
      elseif not opts.output then opts.output = arg
      end
    end
    i = i + 1
  end

  -- If source is % then use current buffer
  if opts.source == "%" then
    opts.source = api.nvim_buf_get_name(0)
  elseif not opts.source then
    -- Default to current buffer if source not specified
    opts.source = api.nvim_buf_get_name(0)
  end

  return opts
end

local function diff_file_handler(args)
  local opts = parse_args(args.fargs)

  if not opts.source or opts.source == "" then
    notify("No source file specified and current buffer is unsaved", levels.ERROR)
    return
  end

  local cmd = diff_wrapper.build_diff_command(opts.source, opts.target, opts)

  if opts.output then
    -- Write to output file
    cmd = cmd .. " > " .. escape_path(opts.output)
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      notify("Diff command failed: " .. result, levels.ERROR)
      return
    end
    notify("Diff written to " .. opts.output, levels.INFO)
    if opts.show then
      vim.cmd("edit " .. opts.output)
    end
  else
    -- Open diff in a new scratch buffer
    local output = vim.fn.systemlist(cmd)
    local buf = api.nvim_create_buf(false, true) -- unlisted, scratch
    api.nvim_buf_set_lines(buf, 0, -1, false, output)
    api.nvim_set_current_buf(buf)
    bo[buf].bufhidden = "wipe"
    bo[buf].filetype = "diff"
  end
end

-- Completion function for user command arguments
local function diff_complete(arglead, _, _)
  local options = {
    "-c", "--context",
    "-u", "--unified",
    "-r", "--recursive",
    "-s", "--show",
    "-S", "--source",
    "-T", "--target",
    "-O", "--output",
    "%"
  }
  local matches = {}
  for _, opt in ipairs(options) do
    if vim.startswith(opt, arglead) then
      table.insert(matches, opt)
    end
  end
  return matches
end

---@return nil
function M.enable()
  api.nvim_create_user_command("DiffFile", diff_file_handler, {
    nargs = "+",
    complete = diff_complete,
    desc = "[usrcmds.diff_util] Advanced diff: DiffFile [source] [target] [output] with flags -c/-u/-r/-s and prefixed options -S/-T/-O",
  })
end

return M
