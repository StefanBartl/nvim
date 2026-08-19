---@module 'bindings.usrcmds.case.templates'
--- Fixed template files, one per recurring case document. Each is
--- addressable by a tag from Lua source instead of a hardcoded path — a
--- blueprint node says `template = templates.SUMMARY`, and the actual
--- content lives in a real, easily-edited markdown file next to this
--- module (`templates/Summary.md`), not an inline string buried in
--- config.lua. Editing the wording is then a plain markdown edit, no Lua
--- required.
---
--- A template's own H1 is never written by this module — `plan.lua` always
--- prepends the mandated headline centrally (config.headline_format), so a
--- template file only ever holds the body.

local read = require("lib.nvim.fs.read")

local M = {}

--- Tags. The `$`-prefix is cosmetic (matches how they'd be typed/referenced
--- outside Lua too) but any string works as a tag — `M.register` accepts one.
M.SUMMARY = "$Summary"
M.NOTES = "$Notes"
M.RESEARCH = "$Research"
M.REPLY = "$Reply"
M.KI_PROMPT = "$KiPrompt"
M.SOLUTION = "$Solution"

local TEMPLATE_DIR = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "bindings", "usrcmds", "case", "templates")

---@type table<string, string>
local FILES = {
  [M.SUMMARY] = "Summary.md",
  [M.NOTES] = "Notes.md",
  [M.RESEARCH] = "Research.md",
  [M.REPLY] = "Reply.md",
  [M.KI_PROMPT] = "KiPrompt.md",
  [M.SOLUTION] = "Solution.md",
}

--- Point a tag at a file (absolute path, or a filename resolved under
--- templates/) — for a case-specific override or a new recurring document.
---@param tag string
---@param filename_or_path string
function M.register(tag, filename_or_path)
  FILES[tag] = filename_or_path
end

---@param tag string
---@return string|nil
function M.path(tag)
  local file = FILES[tag]
  if not file then
    return nil
  end
  if file:match("^%a:") or file:match("^/") then
    return file
  end
  return TEMPLATE_DIR .. "/" .. file
end

---@param text string
---@param tokens table
---@return string
local function substitute(text, tokens)
  return (text:gsub("%{(%w+)%}", function(key)
    local v = tokens[key]
    return v ~= nil and tostring(v) or ""
  end))
end

--- Render a tag's file against `tokens` (`{name}`, `{case}`, `{title}`, ...
--- placeholders) into body lines. Unknown tag or unreadable file -> `{}`,
--- not an error: a missing template degrades to "no body", the H1 above it
--- still gets written.
---@param tag string
---@param tokens table
---@return string[]
function M.render(tag, tokens)
  local path = M.path(tag)
  if not path then
    return {}
  end
  local content = read(path)
  if not content then
    return {}
  end
  content = substitute(content:gsub("\r", ""), tokens or {})

  local lines = vim.split(content, "\n", { plain = true })
  -- fs.write.to_file appends a trailing "\n" on write, so read() sees one
  -- trailing empty element here — drop it, apply.lua re-adds it on write.
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

return M
