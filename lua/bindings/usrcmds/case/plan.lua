---@module 'bindings.usrcmds.case.plan'
--- Blueprint + tokens + on-disk state -> a flat action list. Pure: the only
--- filesystem read is `uv.fs_stat` to decide "does this already exist"
--- (needed to honor "never overwrite" and to make :Case sync a no-op on
--- what's already there) — no writes happen here. apply.lua executes what
--- this returns; :Case new's dry-run viewer renders it unexecuted.

local render = require("bindings.usrcmds.case.render")
local templates = require("bindings.usrcmds.case.templates")

local M = {}

---@class Lib.Case.Action
---@field kind "mkdir"|"write"|"copy"|"skip"
---@field path string  Absolute target path.
---@field lines string[]|nil  For kind="write".
---@field from string|nil  For kind="copy".
---@field open boolean|nil
---@field reason string|nil  For kind="skip".

local uv = vim.uv or vim.loop

---@param path string
---@return boolean
local function exists(path)
  return uv.fs_stat(path) ~= nil
end

---@param case_dir string
---@param nodes Lib.Case.BlueprintNode[]
---@param tokens table  { case, title, company, name, year, snow, ... }
---@return Lib.Case.Action[]
function M.build(case_dir, nodes, tokens)
  local actions = {}

  for _, node in ipairs(nodes) do
    local full = case_dir .. "/" .. node.path

    if node.type == "dir" then
      if exists(full) then
        actions[#actions + 1] = { kind = "skip", path = full, reason = "directory exists" }
      else
        actions[#actions + 1] = { kind = "mkdir", path = full }
      end
    elseif node.type == "file" then
      if exists(full) and node.overwrite ~= true then
        actions[#actions + 1] = { kind = "skip", path = full, reason = "file exists" }
      else
        local lines = {}
        if node.headline ~= false then
          lines[#lines + 1] = render.headline(tokens.case, tokens.title, render.filename_token(node.path))
          lines[#lines + 1] = ""
        end
        if node.template then
          vim.list_extend(lines, templates.render(node.template, tokens))
        elseif node.body then
          vim.list_extend(lines, node.body(tokens) or {})
        end
        actions[#actions + 1] = { kind = "write", path = full, lines = lines, open = node.open }
      end
    elseif node.type == "copy" then
      if exists(full) and node.overwrite ~= true then
        actions[#actions + 1] = { kind = "skip", path = full, reason = "file exists" }
      else
        actions[#actions + 1] = { kind = "copy", path = full, from = node.from, open = node.open }
      end
    end
  end

  return actions
end

--- Render a plan as human-readable lines for the dry-run viewer.
---@param actions Lib.Case.Action[]
---@return string[]
function M.describe(actions)
  local lines = {}
  for _, a in ipairs(actions) do
    if a.kind == "mkdir" then
      lines[#lines + 1] = ("mkdir  %s"):format(a.path)
    elseif a.kind == "write" then
      lines[#lines + 1] = ("write  %s"):format(a.path)
    elseif a.kind == "copy" then
      lines[#lines + 1] = ("copy   %s -> %s"):format(a.from, a.path)
    elseif a.kind == "skip" then
      lines[#lines + 1] = ("skip   %s (%s)"):format(a.path, a.reason or "exists")
    end
  end
  return lines
end

return M
