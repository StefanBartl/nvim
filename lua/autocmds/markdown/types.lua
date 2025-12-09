---@meta
---@module 'autocmds.markdown.types'

---@class MdAutoCmdsWrapKeyCfg
---@field enable boolean                 -- Enable buffer-local mapping to wrap <cword> as [word]().
---@field key string                     -- Normal-mode key lhs (e.g., "<leader>[").
---@field description string             -- Mapping description.
---@field pattern string|string[]|nil    -- FileType pattern(s) to attach on; defaults to "markdown".
---@field only_modifiable boolean|nil    -- Skip mapping if buffer is not modifiable; default true.

---@class MdAutoCmdsCfg

