---@module 'bindings.usrcmds.bindings_explorer.source'
--- The third drift axis: what this config's **source** actually registers,
--- as extracted by documentation.nvim's `core/bindings.lua` and already
--- baked into `docs/map/module_map.json`.
---
--- `drift.lua` compared two axes: *documented* (the BINDINGS cheatsheets,
--- via `records.lua`) against *live* (`nvim_get_keymap`/`nvim_get_commands`).
--- This adds the third, and it is specifically what makes the missing
--- direction possible.
---
--- **Why "live-but-undocumented" was never built, and why source fixes it.**
--- `drift.lua`'s own limitation 1 says the reverse check would mean diffing
--- against EVERY global keymap — vim's own defaults, matchit, every
--- plugin's own bindings — flooding the report with things this corpus was
--- never meant to document. That objection is entirely about the *live*
--- axis. The source axis has no such problem by construction: it only ever
--- contains registrations written in **this repository's own Lua**, which
--- is exactly the set the Personal cheatsheets are supposed to cover. So
--- "in the source, not in the docs" is a clean, bounded question that
--- "live, not in the docs" could never be.
---
--- **Reads the artifact, does not scan.** `docs/map/module_map.json` is
--- already generated and committed, and documentation.nvim's whole posture
--- is that its artifacts are cold-readable without a live session. A scan
--- here would re-parse ~500 files to re-derive data sitting on disk.
---
--- The cost of that choice, stated rather than hidden: the artifact is only
--- as fresh as the last `:DocMap`. A binding added since then is missing
--- from this axis, which reads as "documented but not in source" — the
--- opposite of the truth. Hence `M.generated_at`, and hence every finding
--- from this axis naming the artifact rather than claiming to have read the
--- source itself.
---
--- Nothing here requires documentation.nvim to be loaded, or installed: it
--- reads a JSON file. If the file is absent, or predates the bindings
--- extractor, that is reported as a reason, never as "no bindings found".

local M = {}

---Where the map artifact lives for this config.
---@return string
local function map_path()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "map", "module_map.json")
end

---@class Bindings.SourceEntry
---@field lhs string?        # keymap left-hand side, raw as written in the source
---@field name string?       # user command name
---@field kind string        # "keymap"|"usercmd"|"autocmd"
---@field modes string[]
---@field desc string?
---@field module string      # the node's module id, e.g. "bindings.mappings.git"
---@field path string        # the node's source path, for a jump target
---@field line integer

---Read every binding documentation.nvim recorded for this config.
---
---Returns `nil` plus a human-readable reason rather than an empty table for
---every failure mode, because "no bindings" and "the map cannot answer
---that" are different claims and a drift report must not present the
---second as the first.
---@return Bindings.SourceEntry[]|nil
---@return string|nil reason
---@return integer|nil generated_at  # mtime of the artifact, for staleness notes
function M.load()
  local path = map_path()
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil, ("no map artifact at %s — run :DocMap in this config first"):format(path), nil
  end

  local fd = io.open(path, "rb")
  if not fd then
    return nil, ("cannot read %s"):format(path), nil
  end
  local raw = fd:read("*a")
  fd:close()

  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" or type(decoded.nodes) ~= "table" then
    return nil, ("%s is not a readable module map"):format(path), nil
  end

  local out = {}
  local saw_field = false
  for _, node in ipairs(decoded.nodes) do
    if node.bindings ~= nil then
      saw_field = true
      for _, b in ipairs(node.bindings) do
        out[#out + 1] = {
          lhs = b.lhs,
          name = b.name,
          kind = b.kind,
          modes = b.modes or {},
          desc = b.desc,
          module = node.module or node.id,
          path = node.source or node.path,
          line = b.line or 1,
        }
      end
    end
  end

  -- No node carrying the field at all is a *stale artifact*, not an empty
  -- result: this config really does register hundreds of bindings, so
  -- reporting zero would send the reader hunting for a bug in their own
  -- config instead of regenerating the map.
  if not saw_field then
    return nil,
      ("%s predates documentation.nvim's bindings extraction — run :DocMap to regenerate"):format(
        path
      ),
      stat.mtime and stat.mtime.sec or nil
  end

  return out, nil, stat.mtime and stat.mtime.sec or nil
end

return M
