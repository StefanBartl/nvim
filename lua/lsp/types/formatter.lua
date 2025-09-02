---@meta
---@module 'lsp.types.lsp_core'

---@alias Bufnr integer

---@class FormatterOptions
---@field format_on_save boolean        -- default off in our setup; can be enabled at build time
---@field timeout_ms integer            -- formatting timeout in ms

---@class FormatterApi
---@field format fun(bufnr?:Bufnr):boolean          -- run a one-shot format for the given buffer (or current)
---@field enable fun():boolean                      -- enable format-on-save (creates autocmd)
---@field disable fun():boolean                     -- disable format-on-save (clears autocmd)
---@field toggle fun():boolean                      -- toggle format-on-save and return new state (true = enabled)
---@field is_enabled fun():boolean                  -- current on-save state

---@class FormatterOptions
---@field format_on_save_? boolean  -- Enable format on save initially (default: false)
---@field timeout_ms_? integer      -- Timeout for formatting operations (default: 1500)

---@class FormatterApi
---@field format fun(bufnr?: Bufnr): boolean   -- One-shot format; returns true on success
---@field enable fun(): boolean                -- Enable on-save formatting
---@field disable fun(): boolean               -- Disable on-save formatting
---@field toggle fun(): boolean                -- Toggle on-save formatting; returns new state
---@field is_enabled fun(): boolean            -- Query on-save formatting state
