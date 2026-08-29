---@module 'bindings.usrcmds.case.blueprint'
--- Thin accessor over config.blueprints — the indirection exists so a
--- second blueprint (config.blueprints.escalation, ...) is a config change,
--- never a call-site change.

local config = require("bindings.usrcmds.case.config")

local M = {}

--- Enough of a node to locate one file inside a case: what `ui.open_node`
--- reads, and all it reads. A full blueprint node is one of these; so is the
--- ad-hoc `{ key = "summary", path = "Summary.md" }` that `open_summary`
--- passes, which is not a blueprint entry and has no `type` to give.
---@class Lib.Case.NodeRef
---@field path string  Relative to the case dir.
---@field key string|nil  Registers ":Case <key> [case]" to open this node.

---@class Lib.Case.BlueprintNode : Lib.Case.NodeRef
---@field type "dir"|"file"|"copy"
---@field open boolean|nil  Open this file after :Case new applies it.
---@field headline boolean|nil  Default true for type="file"; false suppresses the H1.
---@field overwrite boolean|nil  Default false: never clobber an existing file.
---@field template string|nil  A templates.lua tag (e.g. templates.SUMMARY) — checked before `body`.
---@field body? fun(tokens: table): string[]|nil  Inline body lines, used only when `template` is absent — a `dir` node has neither.
---@field from string|nil  Source path, for type="copy".

---@param name string|nil
---@return Lib.Case.BlueprintNode[]
function M.get(name)
  return config.blueprints[name or config.default_blueprint] or {}
end

--- Nodes that should surface as a generated ":Case <key> [case]" file-verb.
---@param nodes Lib.Case.BlueprintNode[]
---@return Lib.Case.BlueprintNode[]
function M.with_key(nodes)
  local out = {}
  for _, node in ipairs(nodes) do
    if node.key then
      out[#out + 1] = node
    end
  end
  return out
end

--- Every node with a `key`, across every registered blueprint, deduplicated
--- by key (first blueprint wins) — what init.lua loops over to generate
--- file-verb routes at startup.
---@return Lib.Case.BlueprintNode[]
function M.all_keyed_nodes()
  local seen, out = {}, {}
  for _, nodes in pairs(config.blueprints) do
    for _, node in ipairs(M.with_key(nodes)) do
      if not seen[node.key] then
        seen[node.key] = true
        out[#out + 1] = node
      end
    end
  end
  return out
end

return M
