---@meta
---@module 'mynotes.@types'

---@alias _PickerTitle string
---@alias _AbsDir string

---@class WkdNvimCfg
---@field title _PickerTitle        -- Shown as picker title/prompt
---@field dir   _AbsDir             -- Absolute or "~/"-expanded directory for this book
---@field notify? boolean           -- If true (default), use vim.notify for issues

---@class WkdNvimApi
---@field fzf_files fun()
---@field fzf_grep  fun()
---@field tel_files fun()
---@field tel_grep  fun()
