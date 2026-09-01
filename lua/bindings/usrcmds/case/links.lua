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
--- argument `:Tricentis links [scope]` accepts.
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
            for match in line:gmatch(URL_PATTERN) do
              local url = match:gsub("[%.,;:%)]+$", "") -- trailing prose punctuation
              -- Prose writes placeholders that look like URLs: "ändern Sie
              -- den Wert von `http://...` auf ...". Stripping the trailing
              -- dots above leaves a bare scheme, i.e. a row with nothing on
              -- it. A host is the minimum for something to be a link at all
              -- (deliberately not "a host with a dot in it" — `http://localhost:4723`
              -- is a real and frequently written one here).
              local host = url:match("^https?://([^/]*)")
              if host and host ~= "" and not seen_in_file[url] then
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

--- Collapse repeats for the picker. `M.find`'s per-file dedup keeps
--- cross-file duplicates deliberately (see its comment), and for a *report*
--- that is right — but as a *picker* it produced 810 rows for this bestand,
--- the same `docs.tricentis.com/.../xscan_window_settings.htm` a dozen times
--- over, which is unreadable. One row per URL per area, carrying `count`
--- and the first place it was written down; picking still opens the URL,
--- which is all the picker ever did with the other occurrences anyway.
---
--- Sorted by URL within an area rather than by file: pages of the same
--- manual section then land next to each other, which is how you actually
--- scan a link list ("was there something about xscan_window_settings?").
---@param hits Lib.Case.LinkHit[]
---@return Lib.Case.LinkHit[]  Each with an added `count` field.
function M.dedupe(hits)
  local out, index = {}, {}
  for _, h in ipairs(hits) do
    local key = h.area .. "\0" .. h.url
    local seen = index[key]
    if seen then
      seen.count = seen.count + 1
    else
      local copy = vim.tbl_extend("force", {}, h)
      copy.count = 1
      index[key] = copy
      out[#out + 1] = copy
    end
  end
  table.sort(out, function(a, b)
    if a.area ~= b.area then
      return a.area < b.area
    end
    return a.url < b.url
  end)
  return out
end

return M
