---@meta
---@module '@types.vim.uv.@types.streams'
---@brief Stream handles (TCP, pipes, TTY) and I/O operations

---@class uv.uv_stream_t : uv.uv_handle_t
---@field read_start fun(self: uv.uv_stream_t, callback: fun(err?: string, data?: string)): integer # Start reading from stream. Callback receives data chunks or error. Returns 0 on success.
---@field read_stop fun(self: uv.uv_stream_t): integer # Stop reading from stream. Returns 0 on success.
---@field write fun(self: uv.uv_stream_t, data: string|string[], callback?: fun(err?: string)): uv.uv_write_t # Write data to stream. Returns write request handle.
---@field try_write fun(self: uv.uv_stream_t, data: string|string[]): integer # Attempt synchronous write. Returns bytes written or negative error code.
---@field is_readable fun(self: uv.uv_stream_t): boolean # Returns true if stream is readable
---@field is_writable fun(self: uv.uv_stream_t): boolean # Returns true if stream is writable
---@field set_blocking fun(self: uv.uv_stream_t, blocking: boolean): integer # Set blocking mode. Returns 0 on success.
---@field listen fun(self: uv.uv_stream_t, backlog: integer, callback: fun(err?: string)): integer # Listen for connections with specified backlog. Returns 0 on success.
---@field accept fun(self: uv.uv_stream_t, client: uv.uv_stream_t): integer # Accept pending connection into client handle. Returns 0 on success.
---@field shutdown fun(self: uv.uv_stream_t, callback?: fun(err?: string)): uv.uv_shutdown_t # Shutdown write side of stream. Returns shutdown request handle.

---@class uv.uv_tcp_t : uv.uv_stream_t
---@field open fun(self: uv.uv_tcp_t, fd: integer): integer # Open existing file descriptor as TCP handle. Returns 0 on success.
---@field nodelay fun(self: uv.uv_tcp_t, enable: boolean): integer # Enable/disable Nagle's algorithm. Returns 0 on success.
---@field keepalive fun(self: uv.uv_tcp_t, enable: boolean, delay?: integer): integer # Enable/disable TCP keepalive with initial delay (seconds). Returns 0 on success.
---@field simultaneous_accepts fun(self: uv.uv_tcp_t, enable: boolean): integer # Enable/disable simultaneous accept on listening socket. Returns 0 on success.
---@field bind fun(self: uv.uv_tcp_t, host: string, port: integer, flags?: table): integer # Bind to address and port. Flags: {ipv6only = boolean}. Returns 0 on success.
---@field getsockname fun(self: uv.uv_tcp_t): table|nil, string|nil # Get local address as {ip, port, family} or nil, error
---@field getpeername fun(self: uv.uv_tcp_t): table|nil, string|nil # Get remote address as {ip, port, family} or nil, error
---@field connect fun(self: uv.uv_tcp_t, host: string, port: integer, callback: fun(err?: string)): nil # Connect to remote host and port. Callback on completion.
---@field write_queue_size fun(self: uv.uv_tcp_t): integer # Get size of write queue in bytes
---@field close_reset fun(self: uv.uv_tcp_t, callback?: fun()): integer # Close TCP connection with RST. Returns 0 on success.

---@class uv.uv_pipe_t : uv.uv_stream_t
---@field open fun(self: uv.uv_pipe_t, fd: integer): integer # Open existing file descriptor as pipe. Returns 0 on success.
---@field bind fun(self: uv.uv_pipe_t, name: string): integer # Bind pipe to filesystem path (Unix) or name (Windows). Returns 0 on success.
---@field connect fun(self: uv.uv_pipe_t, name: string, callback: fun(err?: string)): nil # Connect to named pipe. Callback on completion.
---@field getsockname fun(self: uv.uv_pipe_t): string|nil, string|nil # Get pipe name or nil, error
---@field getpeername fun(self: uv.uv_pipe_t): string|nil, string|nil # Get remote pipe name or nil, error
---@field pending_instances fun(self: uv.uv_pipe_t, count: integer): nil # Set number of pending pipe instances (Windows only)
---@field pending_count fun(self: uv.uv_pipe_t): integer # Get number of pending handles to be received via IPC
---@field pending_type fun(self: uv.uv_pipe_t): string # Get type of pending handle ("tcp", "pipe", "udp", "unknown")
---@field chmod fun(self: uv.uv_pipe_t, flags: string): integer # Change pipe permissions. Flags: "r", "w", "rw". Returns 0 on success.
---@field write2 fun(self: uv.uv_pipe_t, data: string|string[], send_handle: uv.uv_handle_t, callback?: fun(err?: string)): uv.uv_write_t # Write data with handle passing (IPC). Returns write request.

---@class uv.uv_tty_t : uv.uv_stream_t
---@field set_mode fun(self: uv.uv_tty_t, mode: integer): integer # Set TTY mode: 0 (normal), 1 (raw), 2 (IO). Returns 0 on success.
---@field reset_mode fun(): integer # Reset TTY mode to default. Returns 0 on success.
---@field get_winsize fun(self: uv.uv_tty_t): integer|nil, integer|nil, string|nil # Get terminal dimensions as width, height or nil, nil, error

return {}
