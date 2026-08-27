-- Keymap-vs-command audit for one plugin.
--
-- Loads the plugin against lib.nvim, runs setup(), then asks two questions the
-- registry can now answer mechanically:
--   1. which keymap actions exist, and
--   2. which :Command routes exist.
-- Prints both as data; the pairing is a judgement call made afterwards.
--
--   nvim --clean -l audit.lua <repo-dir> <module>

local repo = vim.v.argv[#vim.v.argv - 1]
local mod = vim.v.argv[#vim.v.argv]

vim.opt.rtp:append("E:/repos/lib.nvim")
vim.opt.rtp:append(repo)
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Quiet: a plugin's own startup notifications are not what is being audited.
vim.notify = function() end

-- Which :commands existed before the plugin was loaded, so netrw's and
-- Neovim's own do not show up as if the plugin had defined them.
local builtin = {}
for _, c in pairs(vim.api.nvim_get_commands({})) do
  builtin[c.name] = true
end

local ok, plugin = pcall(require, mod)
if not ok then
  print("LOADFAIL " .. tostring(plugin):sub(1, 120))
  return
end

if type(plugin) == "table" and type(plugin.setup) == "function" then
  local ok_setup, err = pcall(plugin.setup, {})
  if not ok_setup then
    print("SETUPFAIL " .. tostring(err):sub(1, 160))
  end
end

-- Some plugins only bind on a filetype; give those a chance to attach.
vim.wait(150, function()
  return false
end)

local keymap = require("lib.nvim.bindings.keymap")

---@type table<string, boolean>
local seen = {}
local actions = {}
for surface, entries in pairs(keymap.registered()) do
  for _, e in ipairs(entries) do
    local id = surface .. "." .. e.name
    if not seen[id] then
      seen[id] = true
      actions[#actions + 1] = {
        surface = surface,
        name = e.name,
        lhs = e.lhs,
        bound = e.bound,
        desc = e.desc,
      }
    end
  end
end
table.sort(actions, function(a, b)
  if a.surface ~= b.surface then
    return a.surface < b.surface
  end
  return a.name < b.name
end)

print("### KEYMAP ACTIONS: " .. #actions)
for _, a in ipairs(actions) do
  print(
    ("KEY\t%s\t%s\t%s\t%s"):format(
      a.surface,
      a.name,
      a.lhs or "-",
      (a.desc or ""):gsub("\t", " ")
    )
  )
end

-- Command routes: the composer's registry knows every verb it built.
local ok_c, composer = pcall(require, "lib.nvim.bindings.usercmd.composer")
local routes = {}
local composer_names = {}
if ok_c then
  for name, handle in pairs(composer.registry()) do
    composer_names[name] = true
    local ok_spec, spec = pcall(function()
      return handle:spec()
    end)
    if ok_spec and type(spec) == "table" then
      if spec.default then
        routes[#routes + 1] = name .. "	(bare)	" .. (spec.desc or "")
      end
      for _, r in ipairs(spec.routes or {}) do
        local path = table.concat(r.path or {}, " ")
        routes[#routes + 1] = name .. "	" .. (path ~= "" and path or "(root)") .. "	" .. (r.desc or "")
      end
    else
      routes[#routes + 1] = name .. "	?	(spec not readable)"
    end
  end
end

-- Plain :command definitions, for plugins that do not use the composer.
for _, c in pairs(vim.api.nvim_get_commands({})) do
  if not builtin[c.name] and not composer_names[c.name] then
    routes[#routes + 1] = c.name .. "	(plain)	" .. (c.definition or ""):sub(1, 60)
  end
end
table.sort(routes)

print("### COMMAND ROUTES: " .. #routes)
for _, r in ipairs(routes) do
  print("CMD\t" .. r)
end
