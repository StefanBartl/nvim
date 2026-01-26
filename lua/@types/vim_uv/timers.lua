---@meta
---@module '@types.vim.uv.@types.timers'
---@brief Timer and event loop phase handles

---@class uv.uv_timer_t : uv.uv_handle_t
---@field start fun(self: uv.uv_timer_t, timeout: integer, repeat_: integer, callback: fun()): integer # Start timer with initial timeout (ms) and repeat interval. Returns 0 on success.
---@field stop fun(self: uv.uv_timer_t): integer # Stop timer. Returns 0 on success.
---@field again fun(self: uv.uv_timer_t): integer # Restart timer with current repeat value. Requires non-zero repeat. Returns 0 on success.
---@field set_repeat fun(self: uv.uv_timer_t, repeat_: integer): nil # Set repeat interval in milliseconds for future restarts
---@field get_repeat fun(self: uv.uv_timer_t): integer # Get current repeat interval in milliseconds
---@field get_due_in fun(self: uv.uv_timer_t): integer # Get milliseconds until next timeout. Returns 0 if not started.

---@class uv.uv_idle_t : uv.uv_handle_t
---@field start fun(self: uv.uv_idle_t, callback: fun()): integer # Start idle handle. Callback runs once per event loop iteration. Returns 0 on success.
---@field stop fun(self: uv.uv_idle_t): integer # Stop idle handle. Returns 0 on success.

---@class uv.uv_prepare_t : uv.uv_handle_t
---@field start fun(self: uv.uv_prepare_t, callback: fun()): integer # Start prepare handle. Callback runs before blocking for I/O. Returns 0 on success.
---@field stop fun(self: uv.uv_prepare_t): integer # Stop prepare handle. Returns 0 on success.

---@class uv.uv_check_t : uv.uv_handle_t
---@field start fun(self: uv.uv_check_t, callback: fun()): integer # Start check handle. Callback runs after blocking for I/O. Returns 0 on success.
---@field stop fun(self: uv.uv_check_t): integer # Stop check handle. Returns 0 on success.

---@class uv.uv_async_t : uv.uv_handle_t
---@field send fun(self: uv.uv_async_t): integer # Wake up event loop from another thread. Thread-safe. Returns 0 on success.

return {}
