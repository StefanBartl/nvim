---@module 'custom.markdown.commands.markdown_links'
--- Generate markdown links from files or directories with filtering options.

local M = {}

local uv = vim.uv
local clipboard = require("custom.markdown.util.clipboard")

----------------------------------------------------------------------
-- Options
----------------------------------------------------------------------

---@class MarkdownLinkOptions
---@field recursive boolean
---@field noignore boolean
---@field root string?

----------------------------------------------------------------------
-- Ignore rules
----------------------------------------------------------------------

---@type table<string, boolean>
local default_ignore = require("lib.fs.ignore.list").as_set()

--- Check if directory should be ignored
---@param name string
---@param opts MarkdownLinkOptions
---@return boolean
local function is_ignored(name, opts)
  if opts.noignore then
    return false
  end

  return default_ignore[name] == true
end

----------------------------------------------------------------------
-- Path utilities
----------------------------------------------------------------------

--- Join path safely
---@param a string
---@param b string
---@return string
local function join_path(a, b)
  if vim.endswith(a, "/") then
    return a .. b
  end
  return a .. "/" .. b
end

--- Convert root option (supports env vars)
---@param root string?
---@return string?
local function resolve_root(root)
  if not root or root == "" then
    return nil
  end

  return vim.fn.expand(root)
end

----------------------------------------------------------------------
-- Markdown link builder
----------------------------------------------------------------------

--- Create markdown link
---@param title string
---@param path string
---@return string
local function make_link(title, path)
  return string.format("[%s](%s)", title, path)
end

---@param path string
---@return string
local function file_to_link(path)
  local title = vim.fn.fnamemodify(path, ":t")
  return make_link(title, path)
end

----------------------------------------------------------------------
-- File system traversal
----------------------------------------------------------------------

---@param dir string
---@param opts MarkdownLinkOptions
---@param out string[]
local function scan(dir, opts, out)
  local handle = uv.fs_scandir(dir)
  if not handle then
    return
  end

  while true do
    local name, type_ = uv.fs_scandir_next(handle)
    if not name then
      break
    end

    if is_ignored(name, opts) then
      goto continue
    end

    local full_path = join_path(dir, name)

    if type_ == "file" then
      out[#out + 1] = full_path
    elseif type_ == "directory" and opts.recursive then
      scan(full_path, opts, out)
    end

    ::continue::
  end
end

---@param directory string
---@param opts MarkdownLinkOptions
---@return string[]
local function collect_files(directory, opts)
  local result = {} ---@type string[]
  scan(directory, opts, result)
  table.sort(result)
  return result
end

----------------------------------------------------------------------
-- Argument parsing
----------------------------------------------------------------------

--- Parse CLI arguments
---@param args string[]
---@return MarkdownLinkOptions, string
local function parse_args(args)
  local opts = {
    recursive = false,
    noignore = false,
    root = nil,
  }

  local path

  local i = 1
  while i <= #args do
    local a = args[i]

    if a == "-r" or a == "--recursive" then
      opts.recursive = true

    elseif a == "--noignore" then
      opts.noignore = true

    elseif a == "--root" then
      opts.root = args[i + 1]
      i = i + 1

    else
      path = a
    end

    i = i + 1
  end

  return opts, path or ""
end

----------------------------------------------------------------------
-- Main command
----------------------------------------------------------------------

--- Generate markdown links
---@param args string[]
function M.run(args)
  local opts, path = parse_args(args)

  if not path or path == "" then
    vim.notify(
      "Usage: :Markdown links [-r] [--noignore] [--root <path|$ENV>] <path>",
      vim.log.levels.ERROR
    )
    return
  end

  path = vim.fn.expand(path)

  local root = resolve_root(opts.root)

  local lines = {} ---@type string[]

  if vim.fn.isdirectory(path) == 1 then
    local files = collect_files(path, opts)

    for i = 1, #files do
      local file_path = files[i]

      if root then
        file_path = join_path(root, file_path)
      end

      lines[#lines + 1] = file_to_link(file_path)
    end
  else
    local file_path = path

    if root then
      file_path = join_path(root, file_path)
    end

    lines[#lines + 1] = file_to_link(file_path)
  end

  local result = table.concat(lines, "\n")

  clipboard.copy(result)

  print(result)

  vim.notify("Markdown links copied to clipboard", vim.log.levels.INFO)
end

return M
