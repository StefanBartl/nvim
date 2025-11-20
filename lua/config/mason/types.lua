---@meta
---@module 'config.mason.types'

---@class MasonEnsureCategory
---@alias MasonEnsureMap table<string, boolean>

---@class MasonEnsureCfg
---@field lsp boolean|nil            -- Enable LSP ensures (default: true)
---@field dap boolean|nil            -- Enable DAP ensures (default: true)
---@field linters boolean|nil        -- Enable linter tool ensures (default: true)
---@field formatters boolean|nil     -- Enable formatter tool ensures (default: true)
---@field overrides { lsp?: MasonEnsureMap, dap?: MasonEnsureMap, linters?: MasonEnsureMap, formatters?: MasonEnsureMap }|nil
---@field log_prefix string|nil      -- Optional log prefix (default: "mason.ensure")
