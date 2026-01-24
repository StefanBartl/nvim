---@meta
---@module '@types.vim.uv.@types.handles'
---@brief Base handle types and lifecycle management

---@class uv.uv_handle_t
---@field close fun(self: uv.uv_handle_t, callback?: fun()): nil # Close handle and execute callback when done. Handle becomes invalid after close.
---@field is_active fun(self: uv.uv_handle_t): boolean # Returns true if handle is active (has pending operations or references)
---@field is_closing fun(self: uv.uv_handle_t): boolean # Returns true if handle is closing or already closed
---@field ref fun(self: uv.uv_handle_t): nil # Reference handle (prevents event loop from exiting while active)
---@field unref fun(self: uv.uv_handle_t): nil # Unreference handle (allows event loop to exit even if active)
---@field has_ref fun(self: uv.uv_handle_t): boolean # Returns true if handle is referenced
---@field send_buffer_size fun(self: uv.uv_handle_t, size?: integer): integer # Get/set send buffer size in bytes. Returns current size.
---@field recv_buffer_size fun(self: uv.uv_handle_t, size?: integer): integer # Get/set receive buffer size in bytes. Returns current size.
---@field fileno fun(self: uv.uv_handle_t): integer|nil # Returns underlying file descriptor or nil if not applicable
---@field get_type fun(self: uv.uv_handle_t): string # Returns handle type name (e.g., "tcp", "pipe", "timer")

return {}
