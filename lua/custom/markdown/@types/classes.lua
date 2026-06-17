---@meta
---@module 'custom.markdown.types.classes

---@class Custom.MD.BlockquoteHL
---@field marker_fg string|nil     Foreground of the `>` marker. Default: "#6A9955"
---@field marker_bold boolean|nil  Bold marker. Default: false
---@field marker_italic boolean|nil Italic marker. Default: false
---@field text_bg string|nil       Background of the text after `>`. Default: auto-derived (20% of marker_fg)
---@field text_fg string|nil       Foreground of the text after `>`. Default: nil (inherits Normal fg)
---@field text_italic boolean|nil  Italic text. Default: false
---@field text_bold boolean|nil    Bold text. Default: false
---@field link string|nil          Link both groups to an existing hl group (overrides all above).
---@field fg string|nil            Shorthand alias for marker_fg (kept for compatibility).

---@class Custom.MD.Config
---@field map_double_asterisk boolean     Visual "**" mapping (default: true)
---@field keep_inner_selection boolean    Reselect inner text after wrapping (default: true)
---@field protect_h1 boolean              Never demote below H1 (default: false)
---@field use_zf_override boolean         Map 'zf' to fold toggle (default: true)
---@field enable_autocmds boolean         For your own UI/FileType hooks (default: true)
---@field enable_keymaps boolean          Install unified keymaps (default: true)
---@field ft_only boolean                 Buffer-local keymaps on FileType=markdown (default: true)
---@field ensure_headline_spacing boolean Ensure whitespace + separator before H2+ headlines (default: true)
---@field blockquote_hl Custom.MD.BlockquoteHL|nil  Blockquote highlight options (default: green italic)

---@class Custom.MD.PublicAPI
---@field setup fun(opts: Custom.MD.Config|nil)
---@field foldexpr fun(lnum: integer): (string|integer)
---@field goto_prev_heading fun(): nil
---@field goto_next_heading fun(): nil
---@field shift_increase fun(): nil
---@field shift_decrease fun(): nil
---@field toggle_visual_bold fun(): nil

---@class Custom.MD.HandlerFile
---@field config table
---@field extract fun(line:string): string|nil
---@field resolve fun(target:string): string|nil
---@field is_file_line fun(line:string): boolean
---@field open fun(line?:string): boolean

---@class Custom.MD.HandlerUrl
---@field config table
---@field extract fun(line:string): string|nil
---@field is_url_line fun(line:string): boolean
---@field open fun(line?:string): boolean

return {}
