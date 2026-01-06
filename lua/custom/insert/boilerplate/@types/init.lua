---@module 'custom.insert.boilerplate.@types'

---@alias Custom.Insert.Boilerplate.Category
---| "lua"       -- Lua code templates
---| "nvim"      -- Neovim-specific templates
---| "html"      -- HTML templates
---| "guard"     -- Guard clause patterns

---@alias Custom.Insert.Boilerplate.Template
---| "lua-module"
---| "lua-class"
---| "lua-function"
---| "nvim-autocmd"
---| "nvim-keymap"
---| "guard-clause"
---| "html-figure"
---| "html-code"
---| "html-quote"
---| "html-formula-table"
---| "html-aside"
---| "html-pagination"
---| "html-accordion"

---@class Custom.Insert.Boilerplate.TemplateMetadata
---@field category Custom.Insert.Boilerplate.Category
---@field description string
---@field prompts Custom.Insert.Boilerplate.PromptSpec[]|nil

---@class Custom.Insert.Boilerplate.PromptSpec
---@field name string Internal variable name
---@field prompt string User-facing prompt text
---@field default string|nil Default value if user enters nothing
---@field required boolean Whether this prompt is mandatory

---@class Custom.Insert.Boilerplate.TemplateRegistry
---@field [Custom.Insert.Boilerplate.Template] Custom.Insert.Boilerplate.TemplateMetadata

return {}
