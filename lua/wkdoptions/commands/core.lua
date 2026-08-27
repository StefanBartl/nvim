---@module 'wkdoptions.commands.core'
--- Core command utilities: definition, completion, path resolution.
--- Shared by all command registration functions.

local trim = require("lib.lua.strings.core").trim

local M = {}

--- (Re)define a user command.
---
--- Through `lib.nvim.bindings.usercmd`, which already does everything the
--- hand-rolled version here did and one thing it did not: it defaults to
--- `force = true`, so a redefinition needs no `nvim_del_user_command` dance
--- first, and it pcall-wraps the callback so a throwing command reports
--- through `lib.nvim.notify` instead of a raw stack trace.
---@param name string
---@param rhs fun(opts: {fargs: string[], bang: boolean}): nil
---@param opts table|nil
---@return nil
function M.define_cmd(name, rhs, opts)
  require("lib.nvim.bindings.usercmd").create(name, rhs, opts or {})
end

--- Resolve a dot-path on a table (read-only).
---@nodiscard
---@param root table
---@param path string
---@return any|nil
function M.get_by_path(root, path)
  if type(root) ~= "table" or type(path) ~= "string" or path == "" then
    return nil
  end

  local node = root
  for seg in string.gmatch(path, "[^%.]+") do
    if type(node) ~= "table" then
      return nil
    end
    node = node[seg]
  end

  return node
end

--- Build a completion function for a namespace.
---@nodiscard
---@param keys_fn fun(): string[]
---@return fun(ArgLead: string, CmdLine: string, CursorPos: integer): string[]
function M.make_complete(keys_fn)
  return function(ArgLead, _, _)
    if type(ArgLead) ~= "string" then
      ArgLead = ""
    end

    local ok, keys = pcall(keys_fn)
    if not ok or type(keys) ~= "table" then
      return {}
    end

    if ArgLead == "" then
      return keys
    end

    local pat = "^" .. vim.pesc(ArgLead)
    local matches = {}
    for i = 1, #keys do
      local k = keys[i]
      if type(k) == "string" and k:find(pat) then
        matches[#matches + 1] = k
      end
    end

    return matches
  end
end

--- Parse command arguments into key + value
---@nodiscard
---@param args string[]
---@return string|nil key
---@return string|nil value_str
function M.parse_args(args)
  if type(args) ~= "table" or #args == 0 then
    return nil, nil
  end

  local key = trim(args[1] or "")
  if key == "" then
    return nil, nil
  end

  -- Concatenate remaining args as value
  local value_parts = {}
  for i = 2, #args do
    value_parts[#value_parts + 1] = args[i]
  end

  local value_str = table.concat(value_parts, " ")
  value_str = trim(value_str)

  return key, value_str
end

return M
