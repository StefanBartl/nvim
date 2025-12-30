---@meta
---@module 'lib.notify.@types'

---@class Lib.Notify.Notifier
---@field notify fun(msg: string, level?: integer, opts?: table)
---@field info fun(msg: string, opts?: table)
---@field warn fun(msg: string, opts?: table)
---@field error fun(msg: string, opts?: table)
---@field debug fun(msg: string, opts?: table)

---@alias Lib.Notify.CreateFN fun(prefix: string): Lib.Notify.Notifier

---@class Lib.Notify.Module
---@field create Lib.Notify.CreateFN

return {}
