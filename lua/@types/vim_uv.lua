---@meta

vim = vim or {}

---@class uv
local uv = {}

-- Time and performance
---@return integer nanoseconds
function uv.hrtime() end

---@return integer milliseconds
function uv.now() end

-- Filesystem
---@param path string
---@return table|nil stat Returns a stat table or nil on failure
function uv.fs_stat(path) end

---@param path string
---@return table|nil stat Returns link stat
function uv.fs_lstat(path) end

---@param path string
---@return boolean success
function uv.fs_unlink(path) end

---@param path string
---@param mode? number
---@return boolean success
function uv.fs_mkdir(path, mode) end

---@param path string
---@return string[]|nil entries Returns array of filenames or nil
function uv.fs_scandir(path) end

---@param path string
---@param flags? string
---@return integer|nil fd File descriptor or nil
function uv.fs_open(path, flags, mode) end

---@param fd integer
---@return string? data
function uv.fs_read(fd, offset, length) end

---@param fd integer
---@return boolean success
function uv.fs_close(fd) end

-- File watching
---@return userdata fs_event
function uv.new_fs_event() end

---@param handle userdata
---@param path string
---@param options table
---@param callback fun(err: string?, filename: string?)
function uv.fs_event_start(handle, path, options, callback) end

-- Pipes
---@return userdata pipe
function uv.new_pipe(flag) end

---@param handle userdata
---@param fd integer
function uv.pipe_open(handle, fd) end

-- Processes
---@param path string
---@param options table
---@param on_exit fun(code: integer, signal: integer)
---@return userdata process_handle
function uv.spawn(path, options, on_exit) end

-- Child process signal control
---@param handle userdata
---@return boolean success
function uv.process_kill(handle, signal) end

-- TCP
---@return userdata tcp
function uv.new_tcp() end

-- Timers
---@return userdata timer
function uv.new_timer() end

---@param timer userdata
---@param timeout number
---@param _repeat number
---@param callback fun()
function uv.timer_start(timer, timeout, _repeat, callback) end

---@param timer userdata
function uv.timer_stop(timer) end

---@param timer userdata
function uv.timer_close(timer) end

-- Misc
---@return table uname Returns system information
function uv.os_uname() end

---@return integer pid
function uv.os_getpid() end

---@return string cwd
function uv.cwd() end

vim.uv = uv

return {}
