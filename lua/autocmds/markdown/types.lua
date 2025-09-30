---@meta
---@module 'autocmds.markdown.types'

---@class MdAutoCmdsWrapKeyCfg
---@field enable boolean                 -- Enable buffer-local mapping to wrap <cword> as [word]().
---@field key string                     -- Normal-mode key lhs (e.g., "<leader>[").
---@field description string             -- Mapping description.
---@field pattern string|string[]|nil    -- FileType pattern(s) to attach on; defaults to "markdown".
---@field only_modifiable boolean|nil    -- Skip mapping if buffer is not modifiable; default true.

---@class MdAutoCmdsGotoFileCfg
---@field enable boolean                 -- Enable Markdown-aware "gf" override for links/URLs.
---@field debug boolean                  -- Emit verbose debug via vim.notify while resolving links.
---@field pattern string|string[]|nil    -- FileType pattern(s) to attach on; defaults to "markdown".
---@field enable_windows_opener boolean  -- Allow Windows opener branch (default false; Linux/macOS preferred).
---@field open_cmd_mac string[]|nil      -- Override opener argv for macOS; default { "open", "<url>" }.
---@field open_cmd_unix string[]|nil     -- Override opener argv for Linux/Unix; default { "xdg-open", "<url>" }.

---@class MdAutoCmdsCfg
---@field wrap_key MdAutoCmdsWrapKeyCfg
---@field goto_file MdAutoCmdsGotoFileCfg
