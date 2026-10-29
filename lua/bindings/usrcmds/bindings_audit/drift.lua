---@module 'bindings.usrcmds.bindings_audit.drift'
---@brief Compare a hand-edited `BINDINGS-RUNTIME-CHECKLIST.md` with the checklist the current
---session would generate: which entries are gone (a keymap or command route that no longer
---exists) and which are new (registered now, missing from the file).
---@description
--- `:BindingsRuntimeChecklist!` regenerates the file and resets every ticked box, so it cannot be
--- used to find out what changed. This module only reads: an entry is identified by its section
--- (`## Keymaps`, `## Usercmds`, ...), its group (`### ...`) and the first code span of the box
--- line (the lhs or the `:Command route`). Ticks, notes and descriptions do not take part, so a
--- ticked box and a changed description are not drift. Pure: no notify, no file access (ERR-04).

local M = {}

---@class Bindings.ChecklistEntry
---@field key string section, group and code span joined by NUL; the identity used for the diff
---@field section string the `## ` heading the box is under ("" before the first one)
---@field group string the `### ` heading the box is under ("" when none since the section)
---@field span string the first code span of the box line, without the backticks
---@field lnum integer 1-based line of the box in the lines it was parsed from
---@field text string the box line as it stands

---@class Bindings.ChecklistDrift
---@field gone Bindings.ChecklistEntry[] in the file, not generated any more (with the file's lnum)
---@field new Bindings.ChecklistEntry[] generated now, not in the file (with the generated lnum)

---The box entries of checklist `lines`, in order.
---The code span at the start of a box line, or nil when the line is no box with one. Besides
---`` `x` `` it reads the Markdown form for spans that contain a backtick (``` `` x `` ```) and the
---generator's ```` ``` ```` for the backtick key itself.
---@param line string
---@return string|nil
local function box_span(line)
  local rest = line:match("^%s*%- %[.%]%s+(`.*)$")
  if not rest then
    return nil
  end
  return rest:match("^``%s(.-)%s``") or (rest:match("^```%s") and "`") or rest:match("^`([^`]+)`")
end

---@param lines string[]
---@return Bindings.ChecklistEntry[]
function M.entries(lines)
  local out = {}
  local section, group = "", ""
  for lnum, line in ipairs(lines) do
    local h2 = line:match("^##%s+(.-)%s*$")
    local h3 = line:match("^###%s+(.-)%s*$")
    if h3 then
      group = h3
    elseif h2 then
      section, group = h2, ""
    else
      local span = box_span(line)
      if span then
        out[#out + 1] = {
          key = section .. "\0" .. group .. "\0" .. span,
          section = section,
          group = group,
          span = span,
          lnum = lnum,
          text = line,
        }
      end
    end
  end
  return out
end

---@param list Bindings.ChecklistEntry[]
---@return table<string, true>
local function key_set(list)
  local set = {}
  for _, e in ipairs(list) do
    set[e.key] = true
  end
  return set
end

---What changed between the checklist in `file_lines` and a freshly generated one.
---@param file_lines string[] the checklist file as it is on disk
---@param generated_lines string[] what `lib.nvim.bindings.audit.checklist_lines()` returns now
---@return Bindings.ChecklistDrift
function M.diff(file_lines, generated_lines)
  local have = M.entries(file_lines)
  local want = M.entries(generated_lines)
  local have_keys, want_keys = key_set(have), key_set(want)

  local gone, new = {}, {}
  for _, e in ipairs(have) do
    if not want_keys[e.key] then
      gone[#gone + 1] = e
    end
  end
  for _, e in ipairs(want) do
    if not have_keys[e.key] then
      new[#new + 1] = e
    end
  end
  return { gone = gone, new = new }
end

return M
