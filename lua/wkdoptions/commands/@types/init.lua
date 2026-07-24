---@meta
---@module 'wkdoptions.commands.@types'
---
--- Type definitions for user command registration system.

---@class WKDOptions.Commands.HL_Names
---@field set string # Default: "WKDHighlightSet"
---@field show string # Default: "WKDHighlightShow"
---@field list string # Default: "WKDHighlightList"

---@class WKDOptions.Commands.HL_Spec
---@field after_set fun(key: string): nil # Called when config was updated successfully
---@field show_table table # Table to show/inspect (usually cfg.highlight)
---@field names WKDOptions.Commands.HL_Names|nil # Optional custom command names

---@class WKDOptions.Commands.Opt_Names
---@field set string # Default: "WKDOptSet"
---@field show string # Default: "WKDOptShow"
---@field list string # Default: "WKDOptList"

---@class WKDOptions.Commands.Opt_Spec
---@field after_set fun(key: string): nil # Called when config was updated successfully
---@field show_table table # Table to show/inspect (usually cfg.options)
---@field names WKDOptions.Commands.Opt_Names|nil # Optional custom command names

---@class WKDOptions.Commands.Debug_Names
---@field debug string|nil # Default: "WKDHighlightDebugCtx"

---@class WKDOptions.Commands.Breadcrumbs_Ctx_Module
---@field _ctx_lsp_func fun(): string|nil
---@field _ctx_ts_symbol fun(): string|nil
---@field _ctx_with_container fun(base_symbol: string|nil): string|nil
---@field _ctx_lang_extra fun(): string|nil
---@field _ctx_word_fallback fun(): string|nil
---@field _build_context fun(): string|nil
---@field _ctx_base_token fun(): string|nil

---@class WKDOptions.Commands.Debug_Opts
---@field names WKDOptions.Commands.Debug_Names|nil
---@field mod WKDOptions.Commands.Breadcrumbs_Ctx_Module|nil
---@field sepfn fun(): string|nil # Separator resolver

---@class WKDOptions.Commands
--- User command registration module.
---@field register_highlight_commands fun(spec: WKDOptions.Commands.HL_Spec): nil
---@field register_options_commands fun(spec: WKDOptions.Commands.Opt_Spec): nil
---@field register_highlight_debug_command fun(opts: WKDOptions.Commands.Debug_Opts|nil): nil

return {}
