---@module 'custom.markdown.types.classes

---@class MarkdownConfig
---@field map_double_asterisk? boolean
---@field keep_inner_selection? boolean
---@field protect_h1? boolean
---@field use_zf_override boolean
---@field enable_autocmds? boolean
---@field enable_keymaps? boolean
---@field ft_only? boolean
---@field ensure_headline_spacing? boolean

---@class MarkdownPublicAPI
---@field setup fun(opts: MarkdownConfig|nil)
---@field foldexpr fun(lnum: integer): (string|integer)
---@field goto_prev_heading fun(): nil
---@field goto_next_heading fun(): nil
---@field shift_increase fun(): nil
---@field shift_decrease fun(): nil
---@field toggle_visual_bold fun(): nil

---@class handler_module
---@field handle_cursor_action fun(): nil

---@class custom.markdown.handler.file
---@field config table
---@field extract fun(line:string): string|nil
---@field resolve fun(target:string): string|nil
---@field is_file_line fun(line:string): boolean
---@field open fun(line?:string): boolean

---@class custom.markdown.handler.url
---@field config table
---@field extract fun(line:string): string|nil
---@field is_url_line fun(line:string): boolean
---@field open fun(line?:string): boolean
