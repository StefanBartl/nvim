---@meta
---@module 'wkdoptions.@types.commands'

---@class WKDOptions.Commands.HLNames
---@field set  string @default: "MyHlSet"
---@field show string @default: "MyHlShow"
---@field list string @default: "MyHlList"

---@class WKDOptions.Commands.HLSpec
---@field after_set  fun(key:string)                              @called when config was updated successfully
---@field show_table table                                        @table to show/inspect (usually C.cfg.highlight)
---@field names      WKDOptions.Commands.HLNames|nil                        @optional custom command names

---@class WKDOptions.Commands.OptNames
---@field set  string @default: "MyOptSet"
---@field show string @default: "MyOptShow"
---@field list string @default: "MyOptList"

---@class WKDOptions.Commands.OptSpec
---@field after_set  fun(key:string)                              @called when config was updated successfully
---@field show_table table                                        @table to show/inspect (usually C.cfg.options)
---@field names      WKDOptions.Commands.OptNames|nil                       @optional custom command names

---@class WKDOptions.HL.DebugNames
---@field debug string|nil

---@class WKDOptions.Breadcrumbs.CtxModule
---@field _ctx_lsp_func fun():string|nil                     -- LSP-based function name
---@field _ctx_ts_symbol fun():string|nil                    -- Tree-sitter semantic symbol
---@field _ctx_with_container fun(base_symbol:string|nil):string|nil  -- Container augment
---@field _ctx_lang_extra fun():string|nil                   -- Language-specific fallback/owner
---@field _ctx_word_fallback fun():string|nil                -- <cword> fallback (non-insert mode)
---@field _build_context fun():string|nil                    -- Full provider pipeline (final)
---@field _ctx_base_token fun():string|nil

---@class WKDOptions.HL.DebugOpts
---@field names WKDOptions.HL.DebugNames|nil         -- Optional names table (command overrides)
---@field mod   WKDOptions.Breadcrumbs.CtxModule|nil        -- Optional module exposing providers
---@field sepfn fun():string|nil                  -- Optional separator resolver (returns string)

return {}
