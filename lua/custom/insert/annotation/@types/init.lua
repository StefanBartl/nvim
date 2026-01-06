---@module 'custom.insert.annotation.@types'

---@alias Custom.Insert.Annotation.Type
---| "module"      -- @module annotation with path
---| "class"       -- @class annotation
---| "field"       -- @field annotation
---| "param"       -- @param annotation
---| "return"      -- @return annotation
---| "alias"       -- @alias annotation

---@class Custom.Insert.Annotation.API
---@field insert_module_annotation fun(): boolean Insert @module annotation at cursor
---@field insert_class_annotation fun(name: string|nil): boolean Insert @class annotation
---@field insert_function_annotation fun(): boolean Insert full function annotation block

return {}
