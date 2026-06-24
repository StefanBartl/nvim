---@module 'bindings.mappings.markdown'
--- Compatibility shim that wires the unified keymaps into FileType=markdown buffers.

local M = {}

---AUDIT: Das hier autocmds gsetzt werden, ist nicht korrekt. Da die Markdown keymaps alle an buffer attached werden (was wir uns performance technisch nochmal ansehen sollten), sollte diese file durch ene entsprechende in autocmds ersetzt werdn

function M.setup(opts)
  local md = require("markdown_nvim")
  md.setup(vim.tbl_deep_extend("force", {
    enable_autocmds = true,
    enable_keymaps = true,
    ft_only = true,
  }, opts or {}))
end

---@type Custom.MD.Config
return M
