---@meta

vim = vim or {}

---@class uv
local uv = {}

---@return integer nanoseconds
function uv.hrtime() end

---@return userdata pipe
function uv.new_pipe(flag) end

---@return userdata handle
function uv.spawn(...) end

vim.uv = uv
