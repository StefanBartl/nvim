---@module 'custom.pathfinder'
--- Main entrypoint for the pathfinder plugin.
--- Exposes setup(opts) which installs mappings and wires modules together.
--- This module is intentionally small and delegates logic to submodules.
local M = {}

-- require submodules
-- local notifier = require("custom.pathfinder.notifier")
local commands = require("custom.pathfinder.commands")

--- Default configuration. Users may override via setup(opts).
---@type table
local DEFAULTS = {
  -- mapping to trigger the pathfinder (normal mode)
  map = "mp",
  -- allow changing the external search priority (fd, rg, find)
  search_commands = { "fd --hidden --follow --type f --strip-cwd-prefix", "rg --files", "find . -type f" },
  -- whether to open first match in current window
  open_in_current_window = true,
  -- notify level (as string) passed to notifier
  verbosity = "info",
  -- maximum number of results to consider from external search
  max_results = 20,
}

---@param opts table|nil
function M.setup(opts)
  opts = opts or {}
  M.opts = vim.tbl_deep_extend("force", DEFAULTS, opts)

  vim.g.PATHFINDER_LOG = false

  -- notifier.notify(("pathfinder: setup with map=%s"):format(M.opts.map), "info")
  commands.setup(M.opts)
end

return M
