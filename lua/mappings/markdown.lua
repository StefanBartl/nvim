---@module 'mappings.markdown'
--- Compatibility shim that wires the unified keymaps into FileType=markdown buffers.
--- It does not define its own mappings anymore.

local M = {}

function M.setup(opts)
  local md = require("custom.markdown")
  md.setup(vim.tbl_deep_extend("force", {
    enable_autocmds = true,
    enable_keymaps = true,
		ft_only = true,
  }, opts or {}))

end

---@type MarkdownConfig
return M
