---@module 'bindings.usrcmds.case.links'
--- A link index over the WHOLE work knowledge base
--- (`config.repo_root`: `Cases/`, `Notes/`, `Workflow/`, `Terminologie/`,
--- `Tosca/`, `ToDo-Collection/`) — deliberately wider than every other
--- module here, which stays scoped to `config.root` (`Cases/SAP_Support`
--- only). `Notes/Links.md` was a hand-maintained link collection; this
--- supersedes it by just reading what's already written everywhere else.

local config = require("bindings.usrcmds.case.config")
local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")

local M = {}

--- Top-level areas of the work repo, in the order a case worker would
--- reach for them — cases and own notes first. The key is the `scope`
--- argument `:Wkd links [scope]` accepts.
local AREAS = {
  { name = "cases", dir = "Cases" },
  { name = "notes", dir = "Notes" },
  { name = "workflow", dir = "Workflow" },
  { name = "terminologie", dir = "Terminologie" },
  { name = "tosca", dir = "Tosca" },
  { name = "todo", dir = "ToDo-Collection" },
}

local URL_PATTERN = "https?://[%w%-%._~:/?#%[%]@!%$&'%(%)%*%+,;=%%]+"

---@return string[]  "all" first, then every area name, sorted.
function M.scopes()
  local names = { "all" }
  for _, a in ipairs(AREAS) do
    names[#names + 1] = a.name
  end
  return names
end

---@class Lib.Case.LinkHit
---@field area string
---@field path string  Absolute path.
---@field line integer
---@field url string

--- Every link under `scope` (an `M.scopes()` name, or nil/"all" for the
--- whole repo), deduplicated per file (the same URL repeated 5 times in one
--- file is one hit, not five — a picker full of near-identical rows helps
--- no one). Cross-file duplicates ARE kept: the same link mentioned in two
--- different cases is two useful hits.
---@param scope string|nil
---@return Lib.Case.LinkHit[]
function M.find(scope)
  local areas = AREAS
  if scope and scope ~= "" and scope ~= "all" then
    areas = {}
    for _, a in ipairs(AREAS) do
      if a.name == scope then
        areas[1] = a
      end
    end
    if #areas == 0 then
      return {}
    end
  end

  local out = {}
  for _, area in ipairs(areas) do
    local root = config.repo_root .. "/" .. area.dir
    for _, path in ipairs(collect_recursive.files(root)) do
      if path:match("%.md$") then
        local content = read(path)
        if content then
          local seen_in_file = {}
          local lineno = 0
          for line in (content:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
            lineno = lineno + 1
            for url in line:gmatch(URL_PATTERN) do
              url = url:gsub("[%.,;:%)]+$", "") -- trailing prose punctuation
              if not seen_in_file[url] then
                seen_in_file[url] = true
                out[#out + 1] = { area = area.name, path = path, line = lineno, url = url }
              end
            end
          end
        end
      end
    end
  end
  return out
end

return M
