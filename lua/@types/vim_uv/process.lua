---@meta
---@module '@types.vim.uv.@types.process'
---@brief Process spawning, signals, and priority management

---@class uv.uv_process_t : uv.uv_handle_t
---@field kill fun(self: uv.uv_process_t, signum: integer): integer # Send signal to process. Returns 0 on success.
---@field get_pid fun(self: uv.uv_process_t): integer # Get process ID

---@class uv.spawn_options
---@field args string[]|nil # Command-line arguments (excluding program name)
---@field stdio (uv.uv_pipe_t|integer|nil)[]|nil # Array of stdio handles: [stdin, stdout, stderr]. Use integer fd or pipe handle or nil to ignore.
---@field env table<string, string>|nil # Environment variables as key-value pairs. If nil, inherits parent environment.
---@field cwd string|nil # Working directory for child process
---@field uid integer|nil # User ID (POSIX only)
---@field gid integer|nil # Group ID (POSIX only)
---@field verbatim boolean|nil # If true, don't escape arguments on Windows
---@field detached boolean|nil # Spawn detached process (runs independently of parent)
---@field hide boolean|nil # Hide console window on Windows

---@class uv.uv_signal_t : uv.uv_handle_t
---@field start fun(self: uv.uv_signal_t, signum: integer, callback: fun(signum: integer)): integer # Start signal handler. Callback receives signal number. Returns 0 on success.
---@field start_oneshot fun(self: uv.uv_signal_t, signum: integer, callback: fun(signum: integer)): integer # Start one-shot signal handler (auto-stops after first signal). Returns 0 on success.
---@field stop fun(self: uv.uv_signal_t): integer # Stop signal handler. Returns 0 on success.

return {}
