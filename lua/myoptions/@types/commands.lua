---@meta
---@module 'myoptions.@types.commands'

---@class MyCommandsHLNames
---@field set  string @default: "MyHlSet"
---@field show string @default: "MyHlShow"
---@field list string @default: "MyHlList"

---@class MyCommandsHLSpec
---@field after_set  fun(key:string)                              @called when config was updated successfully
---@field show_table table                                        @table to show/inspect (usually C.cfg.highlight)
---@field names      MyCommandsHLNames|nil                        @optional custom command names

---@class MyCommandsOptNames
---@field set  string @default: "MyOptSet"
---@field show string @default: "MyOptShow"
---@field list string @default: "MyOptList"

---@class MyCommandsOptSpec
---@field after_set  fun(key:string)                              @called when config was updated successfully
---@field show_table table                                        @table to show/inspect (usually C.cfg.options)
---@field names      MyCommandsOptNames|nil                       @optional custom command names

---@class MyHighlightDebugNames
---@field debug string|nil

---@class MyBreadcrumbsCtxModule
---@field _ctx_lsp_func fun():string|nil                     -- LSP-based function name
---@field _ctx_ts_symbol fun():string|nil                    -- Tree-sitter semantic symbol
---@field _ctx_with_container fun(base_symbol:string|nil):string|nil  -- Container augment
---@field _ctx_lang_extra fun():string|nil                   -- Language-specific fallback/owner
---@field _ctx_word_fallback fun():string|nil                -- <cword> fallback (non-insert mode)
---@field _build_context fun():string|nil                    -- Full provider pipeline (final)

---@class MyHighlightDebugOpts
---@field names MyHighlightDebugNames|nil         -- Optional names table (command overrides)
---@field mod   MyBreadcrumbsCtxModule|nil        -- Optional module exposing providers
---@field sepfn fun():string|nil                  -- Optional separator resolver (returns string)
