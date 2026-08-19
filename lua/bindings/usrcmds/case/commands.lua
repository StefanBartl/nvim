---@module 'bindings.usrcmds.case.commands'
--- A shell-command index over the WHOLE work knowledge base
--- (`config.repo_root`), built by harvesting fenced code blocks out of every
--- markdown file — the same "read what's already written, don't maintain a
--- second copy" approach `terminology.lua` takes for `## Term` headings and
--- `links.lua` takes for URLs.
---
--- The need: working a Mobile-Engine case means reaching for `adb devices`,
--- `uiautomator dump`, `sdkmanager`, `pm clear` — all of them already
--- written down, but scattered across
--- `Tosca/Notes/Tosca_Engines/Mobile_Engine/Testumgebung/*.md` and only
--- findable by remembering WHICH note. This turns the whole bestand into
--- one cheat sheet, filterable per topic.
---
--- Deliberately NOT a curated list of "important commands": a hand-kept
--- list is a third place to update and rots the moment a note gains a
--- command. Everything in a shell fence anywhere in the repo is in the
--- index, and the way to add a command to the cheat sheet is to write it
--- down in the note where it belongs.

local config = require("bindings.usrcmds.case.config")
local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")

local M = {}

--- Fence languages that mean "this is something you type into a shell".
--- `text`/`markdown`/`lua`/`json` fences are deliberately absent — a JSON
--- capability block or a Lua snippet is documentation, not a command, and
--- letting them in would bury the real hits.
local SHELL_LANGUAGES = {
  bash = true,
  sh = true,
  shell = true,
  zsh = true,
  console = true,
  powershell = true,
  ps1 = true,
  pwsh = true,
  cmd = true,
  bat = true,
  batch = true,
  dos = true,
}

--- A fenced block that runs on for pages is a script, not a command worth
--- offering as a one-line cheat-sheet row. Blocks longer than this are
--- still indexed (they may well be the thing you want) but get their own
--- "… +N Zeilen" marker in the picker rather than pretending to be a
--- one-liner.
local PREVIEW_LINE_LIMIT = 1

--- Not every shell fence holds a command. `Cases/.../Research/01_Logfiles.md`
--- pastes a Tosca stack trace into an ```sh fence — correct enough as
--- markdown (it IS console output), useless as a cheat-sheet row, and it
--- sorted to the very top of the picker because `[cases]` beats `[mobile]`
--- alphabetically. Rejection rather than a whitelist of known executables:
--- the whole point is to index tools nobody has thought of yet, so the
--- filter names the shapes that are definitely NOT a command and lets
--- everything else through.
---@param line string  First non-empty line of the block.
---@return boolean
local function looks_like_command(line)
  local first = vim.trim(line)
  if first == "" then
    return false
  end
  -- `System.NullReferenceException: Object reference not set ...`
  if first:match("Exception:") or first:match("^%u[%w%.]*Exception") then
    return false
  end
  -- ` at Tricentis.Automation.XScan.Tasks.ScanTask.OnTaskFinished()` — a
  -- .NET stack frame. Anchored on the dotted PascalCase namespace so a real
  -- `at`-prefixed shell line (there is no such thing in practice) wouldn't
  -- be the thing deciding this.
  if first:match("^at%s+%u[%w_]*%.") then
    return false
  end
  -- A dotted PascalCase token as the executable is a type name, not a
  -- program: `Tricentis.Automation.Rescan.Result.Controller...`.
  local head = first:match("^([%w%._%-]+)")
  if head and head:match("^%u[%w_]*%.%u") then
    return false
  end
  return true
end

---@class Lib.Case.CommandHit
---@field command string   The full block text (may be multi-line).
---@field first_line string  First non-empty line — what the picker shows.
---@field extra_lines integer  Lines beyond the first.
---@field context string   Nearest preceding markdown heading ("" if none).
---@field topic string     Name of the matched `config.command_topics` entry, or the repo-relative directory.
---@field path string      Absolute path.
---@field line integer     1-based line of the fence opener.

--- Resolve a `topic` argument to the roots that are searched.
---
--- Three cases, in order:
---  * nil/""/"all" — the whole repo.
---  * a name from `config.command_topics` — that entry's directory.
---  * anything else — the whole repo, and the raw string is handed back as
---    a path filter. That fallback is what makes the feature usable for
---    topics nobody has added a config entry for yet: `:Tricentis commands
---    excel` still works the day someone writes an Excel-Engine note,
---    because "excel" matches the path.
---@param topic string|nil
---@return string[] roots, string|nil path_filter
local function resolve_topic(topic)
  if not topic or topic == "" or topic == "all" then
    return { config.repo_root }, nil
  end
  local wanted = topic:lower()
  for _, t in ipairs(config.command_topics) do
    if t.name == wanted then
      return { config.repo_root .. "/" .. t.dir }, nil
    end
  end
  return { config.repo_root }, wanted
end

--- Topic names for `<Tab>`-completion. Static (straight out of config)
--- rather than scanned off disk: completion has to answer instantly, and a
--- full repo walk per keystroke to discover folder names would not. A topic
--- missing here is a missing convenience, never a missing capability — the
--- free-form fallback in `resolve_topic` covers everything else.
---@return string[]
function M.topics()
  local names = { "all" }
  for _, t in ipairs(config.command_topics) do
    names[#names + 1] = t.name
  end
  return names
end

--- Which configured topic a file belongs to, for the label in the picker.
--- Falls back to the repo-relative directory, which is still a useful
--- grouping key — just longer.
---@param path string
---@return string
local function topic_of(path)
  local rel = path:sub(#config.repo_root + 2)
  for _, t in ipairs(config.command_topics) do
    if rel:sub(1, #t.dir) == t.dir then
      return t.name
    end
  end
  return vim.fn.fnamemodify(rel, ":h")
end

---@param path string
---@param path_filter string|nil
---@return Lib.Case.CommandHit[]
local function parse_file(path, path_filter)
  if path_filter then
    local rel = path:sub(#config.repo_root + 2):lower()
    if not rel:find(path_filter, 1, true) then
      return {}
    end
  end

  local content = read(path)
  if not content then
    return {}
  end

  local lines = vim.split(content:gsub("\r", ""), "\n", { plain = true })
  local topic = topic_of(path)

  local out = {}
  local seen = {} -- same command twice in one file is one hit (see links.lua)
  local heading = ""
  local in_fence, fence_line, body = false, 0, {}

  for i, line in ipairs(lines) do
    if in_fence then
      if line:match("^%s*```") or line:match("^%s*~~~") then
        local text = vim.trim(table.concat(body, "\n"))
        if text ~= "" and not seen[text] and looks_like_command(text:match("^[^\n]*")) then
          seen[text] = true
          local block_lines = vim.split(text, "\n", { plain = true })
          out[#out + 1] = {
            command = text,
            first_line = block_lines[1],
            extra_lines = math.max(0, #block_lines - PREVIEW_LINE_LIMIT),
            context = heading,
            topic = topic,
            path = path,
            line = fence_line,
          }
        end
        in_fence, body = false, {}
      else
        body[#body + 1] = line
      end
    else
      local h = line:match("^#+%s+(.+)$")
      if h then
        -- Strip a markdown link around the heading text, same reason as
        -- terminology.lua: the URL is noise in a one-line label.
        heading = vim.trim((h:gsub("%[([^%]]+)%]%([^%)]+%)", "%1")))
      else
        local lang = line:match("^%s*```%s*([%w%+%-]+)") or line:match("^%s*~~~%s*([%w%+%-]+)")
        if lang and SHELL_LANGUAGES[lang:lower()] then
          in_fence, fence_line, body = true, i, {}
        end
      end
    end
  end

  return out
end

--- Every shell command in the knowledge base, optionally narrowed to one
--- topic. Sorted by topic, then by the file it came from, then by position
--- in that file — so the result reads in the order the notes were written,
--- which for a walkthrough note like `Emulator_AVD.md` IS the correct order
--- to run them in.
---@param topic string|nil  A `M.topics()` name, a free-form path substring, or nil for everything.
---@return Lib.Case.CommandHit[]
function M.find(topic)
  local roots, path_filter = resolve_topic(topic)

  local out = {}
  for _, root in ipairs(roots) do
    for _, path in ipairs(collect_recursive.files(root)) do
      if path:match("%.md$") then
        vim.list_extend(out, parse_file(path, path_filter))
      end
    end
  end

  table.sort(out, function(a, b)
    if a.topic ~= b.topic then
      return a.topic < b.topic
    end
    if a.path ~= b.path then
      return a.path < b.path
    end
    return a.line < b.line
  end)
  return out
end

--- Collapse repeats for the picker: the same command written down in three
--- notes is one row carrying `count = 3`, not three near-identical rows
--- (`adb devices -l` legitimately appears in the setup walkthrough, the
--- quick reference AND two use cases — all correct, all noise when you are
--- scanning a list).
---
--- Keyed per TOPIC, not globally: the topic is on the row, so folding a
--- `mobile` command into a `workflow` one would mislabel it. Keeps the
--- first occurrence, so the surviving row points at the note that
--- introduces the command rather than a random later mention.
---
--- Only the picker uses this — `M.find`'s own result stays complete, and
--- the cheat sheet renders every occurrence in place (there a repeat is
--- context, not duplication).
---@param hits Lib.Case.CommandHit[]
---@return Lib.Case.CommandHit[]  Each with an added `count` field.
function M.dedupe(hits)
  local out, index = {}, {}
  for _, h in ipairs(hits) do
    local key = h.topic .. "\0" .. h.command
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
  return out
end

--- The same hits, grouped for the rendered cheat sheet: an ordered list of
--- `{ file = <repo-relative path>, hits = {...} }`. Grouping by FILE rather
--- than by topic keeps a walkthrough note's commands together and in order;
--- the topic is already the thing you filtered by to get here.
---@param hits Lib.Case.CommandHit[]
---@return { file: string, hits: Lib.Case.CommandHit[] }[]
function M.group_by_file(hits)
  local order, groups = {}, {}
  for _, h in ipairs(hits) do
    local rel = h.path:sub(#config.repo_root + 2)
    if not groups[rel] then
      groups[rel] = {}
      order[#order + 1] = rel
    end
    table.insert(groups[rel], h)
  end

  local out = {}
  for _, rel in ipairs(order) do
    out[#out + 1] = { file = rel, hits = groups[rel] }
  end
  return out
end

return M
