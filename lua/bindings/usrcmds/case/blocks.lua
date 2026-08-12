---@module 'bindings.usrcmds.case.blocks'
--- The reply-block library: the hand-written snippets under the work repo's
--- `Workflow/Templates/` (RequestMoreInfo, CloseCase, GermanSpeaker,
--- HandOverCase, the Wordings/ and CDX/ sets, …), discovered from disk so
--- adding one is dropping in a markdown file — never a Lua edit.
---
--- Distinct from `templates.lua` despite the similar word: that module holds
--- casedesk's OWN scaffolding (what `:Case new` writes into a fresh case,
--- shipped inside the config). This one reads snippets that live in the work
--- repo, are authored and maintained there, and get pasted into a reply
--- being written.

local config = require("bindings.usrcmds.case.config")
local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")
local replygate = require("bindings.usrcmds.case.replygate")

local M = {}

local EXCLUDED = {}
for _, name in ipairs(config.workflow_template_excludes) do
  EXCLUDED[name] = true
end

---@class Lib.Case.Block
---@field name string  Path relative to the library root, without ".md" — e.g. "Wordings/Noemi".
---@field path string  Absolute path.

--- Every reply block on disk, sorted by name. Empty (not an error) when the
--- library directory is missing — a machine without the work repo checked
--- out should degrade to "no blocks", not blow up on an unrelated command.
---@return Lib.Case.Block[]
function M.list()
  local root = config.workflow_templates_dir
  local uv = vim.uv or vim.loop
  local st = uv.fs_stat(root)
  if not (st and st.type == "directory") then
    return {}
  end

  local out = {}
  for _, path in ipairs(collect_recursive.files(root)) do
    local basename = vim.fn.fnamemodify(path, ":t")
    if path:match("%.md$") and not EXCLUDED[basename] then
      out[#out + 1] = {
        name = path:sub(#root + 2):gsub("%.md$", ""),
        path = path,
      }
    end
  end

  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out
end

--- A block's body, with `{case}`/`{name}`/`{title}`/`{today}`/… substituted.
--- The trailing "Best regards, ..." sign-off several blocks end with is
--- stripped too (`replygate.strip_signature`, 2026-08-11 feedback) — every
--- insertion point, not a per-block edit of the source library.
---
--- Today's blocks are plain prose with `_____` blanks rather than tokens, so
--- substitution is usually a no-op — it runs anyway so a block CAN use the
--- same placeholders every other casedesk template does, without needing
--- code changes first.
---@param block Lib.Case.Block
---@param tokens table|nil
---@return string[]|nil lines
---@return string|nil err
function M.render(block, tokens)
  local content, err = read(block.path)
  if not content then
    return nil, err
  end
  content = content:gsub("\r", "")
  content = (content:gsub("%{(%w+)%}", function(key)
    local v = (tokens or {})[key]
    return v ~= nil and tostring(v) or ("{" .. key .. "}")
  end))
  content = replygate.strip_signature(content)

  local lines = vim.split(content, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines, nil
end

return M
