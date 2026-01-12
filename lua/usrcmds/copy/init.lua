---@module 'usercmds.copy'
---@description
--- Flexible path copy command for Neovim.
--- Supports relative/absolute paths, parent levels, custom bases and targets.

local M = {}

local api = vim.api
local fn = vim.fn
local uv = vim.uv or vim.loop


-- Hilfsfunktion: Parent-Verzeichnis um `levels` hoch
local function parent_dir(path, levels)
  local p = uv.fs_realpath(path) or path
  for _ = 1, levels do
    p = fn.fnamemodify(p, ":h")
  end
  return p
end

-- Normalisiert Pfade (optional, z.B. Backslashes unter Windows)
local function normalize(path)
  return path:gsub("\\", "/")
end

-- Kopiert Text in die Zwischenablage
local function copy(str)
  vim.fn.setreg("+", str)
  print("Copied: " .. str)

end

-- copy_path Funktion
-- usage:
-- :Copy path relative              -> relativ zu cwd
-- :Copy path relative 2            -> relativ zu 2 Ebenen parent
-- :Copy path relative /some/path   -> relativ zu explizitem Pfad
-- :Copy path absolute              -> absolute Datei/Ordner
local function copy_path(mode, base, target)
  target = target or fn.expand("%:p") -- Standard: aktueller Buffer
  local base_path

  if mode == "absolute" then
    copy(normalize(target))
    return
  end

  -- RELATIVE MODE
  if not base then
    -- default: relative zu cwd
    base_path = fn.getcwd()

  elseif type(base) == "string" and base:match("^%d+$") then
    -- numeric Parent-Level
    local levels = tonumber(base)
    if levels == 0 then
      -- Parent 0 = nur Datei, also dirname des direkten Files
      base_path = fn.fnamemodify(target, ":h")
    else
      base_path = parent_dir(target, levels)
    end

  else
    -- expliziter Base-Pfad
    base_path = uv.fs_realpath(base) or base
  end

  local rel = fn.fnamemodify(target, ":." .. base_path)
  copy(normalize(rel))
end

--- Setup user command
function M.enable()
  api.nvim_create_user_command("Copy", function(opts)
    local args = vim.split(opts.args, "%s+")
    if args[1] == "path" then
      table.remove(args, 1)
      copy_path(args)
    else
      vim.notify("Usage: :Copy path ...", vim.log.levels.ERROR)
    end
  end, {
    nargs = "*",
    complete = function(_, _)
      return {
        "path",
        "path relative",
        "path absolute",
      }
    end,
    desc = "[Copy] Copy paths to clipboard",
  })
end

return M

