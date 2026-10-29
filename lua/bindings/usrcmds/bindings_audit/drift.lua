---@module 'bindings.usrcmds.bindings_audit.drift'
---@brief Compare a hand-edited `BINDINGS-RUNTIME-CHECKLIST.md` with the checklist the current
---session would generate: which entries are gone (a keymap or command route that no longer
---exists) and which are new (registered now, missing from the file).
---@description
--- `:BindingsRuntimeChecklist!` regenerates the file and resets every ticked box, so it cannot be
--- used to find out what changed. This module only reads: an entry is identified by its section
--- (`## Keymaps`, `## Usercmds`, ...), its group (`### ...`) and the code span of the box line
--- (the lhs or the `:Command route`). Ticks, notes and descriptions do not take part, so a ticked
--- box and a changed description are not drift. An identity can occur more than once in a group
--- (the generator writes a normal and an insert variant of the same lhs), so the diff counts
--- occurrences: a missing second variant is drift. Pure: no notify, no file access (ERR-04).

local M = {}

---@class Bindings.ChecklistEntry
---@field key string section, group and code span joined by NUL; the identity used for the diff
---@field section string the `## ` heading the box is under ("" before the first one)
---@field group string the `### ` heading the box is under ("" when none since the section)
---@field span string the code span of the box line, without the delimiting backticks
---@field lnum integer 1-based line of the box in the lines it was parsed from
---@field text string the box line as it stands

---@class Bindings.ChecklistDrift
---@field gone Bindings.ChecklistEntry[] in the file, not generated any more (with the file's lnum)
---@field new Bindings.ChecklistEntry[] generated now, not in the file (with the generated lnum)

---The span of a box line, or nil when the line is no box with one. The generator writes
---`` - [ ] `<lhs>` -- <desc> `` (`` `<lhs>` (<surface>) -- <desc> `` for the risky ones) and does not
---escape the lhs, so a lhs may itself contain backticks (`` ` ``, `` a` ``, `` `a ``). The span
---therefore ends at the first closing backtick that is followed by ` -- ` (or by a parenthesized
---surface and ` -- `), not at the first backtick. A box line without a description is read up to
---its first closing backtick.
---@param line string
---@return string|nil
local function box_span(line)
  local rest = line:match("^%s*%- %[.%]%s+`(.*)$")
  if not rest then
    return nil
  end
  local span = rest:match("^(.-)` %-%- ") or rest:match("^(.-)` %b() %-%- ")
  if span then
    return span
  end
  return rest:match("^([^`]+)`")
end

---The box entries of checklist `lines`, in order.
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

---How often each identity occurs.
---@param list Bindings.ChecklistEntry[]
---@return table<string, integer>
local function counts(list)
  local n = {}
  for _, e in ipairs(list) do
    n[e.key] = (n[e.key] or 0) + 1
  end
  return n
end

---The entries of `list` that exceed how often `limit` has their identity: the first occurrences
---are matched with `limit`, the later ones are the surplus.
---@param list Bindings.ChecklistEntry[]
---@param limit table<string, integer>
---@return Bindings.ChecklistEntry[]
local function surplus(list, limit)
  local seen, out = {}, {}
  for _, e in ipairs(list) do
    seen[e.key] = (seen[e.key] or 0) + 1
    if seen[e.key] > (limit[e.key] or 0) then
      out[#out + 1] = e
    end
  end
  return out
end

---What changed between the checklist in `file_lines` and a freshly generated one.
---@param file_lines string[] the checklist file as it is on disk
---@param generated_lines string[] what `lib.nvim.bindings.audit.checklist_lines()` returns now
---@return Bindings.ChecklistDrift
function M.diff(file_lines, generated_lines)
  local have = M.entries(file_lines)
  local want = M.entries(generated_lines)
  return { gone = surplus(have, counts(want)), new = surplus(want, counts(have)) }
end

return M
