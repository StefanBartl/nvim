---@meta
---@module 'vim.uv'
---
--- Comprehensive type definitions for libuv bindings in Neovim.
--- Covers handles, requests, filesystem operations, networking, processes, and timers.
--- Based on libuv 1.x API and Neovim's vim.uv/vim.loop exposure.

---@class uv
---@field constants uv.constants
local uv = {}

---@class uv.constants
---@field O_RDONLY integer
---@field O_WRONLY integer
---@field O_RDWR integer
---@field O_APPEND integer
---@field O_CREAT integer
---@field O_DSYNC integer
---@field O_EXCL integer
---@field O_NOCTTY integer
---@field O_NONBLOCK integer
---@field O_RSYNC integer
---@field O_SYNC integer
---@field O_TRUNC integer
---@field SOCK_STREAM integer
---@field SOCK_DGRAM integer
---@field SOCK_SEQPACKET integer
---@field SOCK_RAW integer
---@field SOCK_RDM integer
---@field AF_UNIX integer
---@field AF_INET integer
---@field AF_INET6 integer
---@field AF_IPX integer
---@field AF_NETLINK integer
---@field AF_X25 integer
---@field AF_AX25 integer
---@field AF_ATMPVC integer
---@field AF_APPLETALK integer
---@field AF_PACKET integer
---@field AI_ADDRCONFIG integer
---@field AI_V4MAPPED integer
---@field AI_ALL integer
---@field AI_NUMERICHOST integer
---@field AI_PASSIVE integer
---@field AI_NUMERICSERV integer
---@field SIGHUP integer
---@field SIGINT integer
---@field SIGQUIT integer
---@field SIGILL integer
---@field SIGTRAP integer
---@field SIGABRT integer
---@field SIGIOT integer
---@field SIGBUS integer
---@field SIGFPE integer
---@field SIGKILL integer
---@field SIGUSR1 integer
---@field SIGSEGV integer
---@field SIGUSR2 integer
---@field SIGPIPE integer
---@field SIGALRM integer
---@field SIGTERM integer
---@field SIGCHLD integer
---@field SIGSTKFLT integer
---@field SIGCONT integer
---@field SIGSTOP integer
---@field SIGTSTP integer
---@field SIGTTIN integer
---@field SIGWINCH integer
---@field SIGIO integer
---@field SIGPOLL integer
---@field SIGXFSZ integer
---@field SIGVTALRM integer
---@field SIGPROF integer
---@field UDP_RECVMMSG integer
---@field UDP_MMSG_CHUNK integer
---@field UDP_REUSEADDR integer
---@field UDP_PARTIAL integer
---@field UDP_IPV6ONLY integer
---@field TCP_IPV6ONLY integer
---@field UDP_MMSG_FREE integer
---@field SIGSYS integer
---@field SIGPWR integer
---@field SIGTTOU integer
---@field SIGURG integer
---@field SIGXCPU integer

-- ============================================================================
-- Base handle type (common interface for all handle types)
-- ============================================================================

---@class uv.uv_handle_t
---@field close fun(self: uv.uv_handle_t, callback?: fun())
---@field is_active fun(self: uv.uv_handle_t): boolean
---@field is_closing fun(self: uv.uv_handle_t): boolean
---@field ref fun(self: uv.uv_handle_t)
---@field unref fun(self: uv.uv_handle_t)
---@field has_ref fun(self: uv.uv_handle_t): boolean
---@field send_buffer_size fun(self: uv.uv_handle_t, size?: integer): integer
---@field recv_buffer_size fun(self: uv.uv_handle_t, size?: integer): integer
---@field fileno fun(self: uv.uv_handle_t): integer?
---@field get_type fun(self: uv.uv_handle_t): string

-- ============================================================================
-- Timer handle
-- ============================================================================

---@class uv.uv_timer_t: uv.uv_handle_t
---@field start fun(self: uv.uv_timer_t, timeout: integer, repeat_: integer, callback: fun()): integer
---@field stop fun(self: uv.uv_timer_t): integer
---@field again fun(self: uv.uv_timer_t): integer
---@field set_repeat fun(self: uv.uv_timer_t, repeat_: integer)
---@field get_repeat fun(self: uv.uv_timer_t): integer
---@field get_due_in fun(self: uv.uv_timer_t): integer

--- Creates and initializes a new timer handle.
---@return uv.uv_timer_t timer
function uv.new_timer() end

-- ============================================================================
-- Pipe handle (IPC, named pipes, stdin/stdout/stderr)
-- ============================================================================

---@class uv.uv_pipe_t: uv.uv_handle_t
---@field open fun(self: uv.uv_pipe_t, fd: integer): integer
---@field bind fun(self: uv.uv_pipe_t, name: string): integer
---@field connect fun(self: uv.uv_pipe_t, name: string, callback: fun(err?: string))
---@field getsockname fun(self: uv.uv_pipe_t): string?, string?
---@field getpeername fun(self: uv.uv_pipe_t): string?, string?
---@field pending_instances fun(self: uv.uv_pipe_t, count: integer)
---@field pending_count fun(self: uv.uv_pipe_t): integer
---@field pending_type fun(self: uv.uv_pipe_t): string
---@field chmod fun(self: uv.uv_pipe_t, flags: string): integer
---@field read_start fun(self: uv.uv_pipe_t, callback: fun(err?: string, data?: string)): integer
---@field read_stop fun(self: uv.uv_pipe_t): integer
---@field write fun(self: uv.uv_pipe_t, data: string|string[], callback?: fun(err?: string)): uv.uv_write_t
---@field write2 fun(self: uv.uv_pipe_t, data: string|string[], send_handle: uv.uv_handle_t, callback?: fun(err?: string)): uv.uv_write_t
---@field try_write fun(self: uv.uv_pipe_t, data: string|string[]): integer
---@field is_readable fun(self: uv.uv_pipe_t): boolean
---@field is_writable fun(self: uv.uv_pipe_t): boolean
---@field set_blocking fun(self: uv.uv_pipe_t, blocking: boolean): integer
---@field listen fun(self: uv.uv_pipe_t, backlog: integer, callback: fun(err?: string)): integer
---@field accept fun(self: uv.uv_pipe_t, client: uv.uv_pipe_t): integer
---@field shutdown fun(self: uv.uv_pipe_t, callback?: fun(err?: string)): uv.uv_shutdown_t

--- Creates a new pipe handle for inter-process communication or stdio.
---@param ipc? boolean Enable IPC mode for handle passing
---@return uv.uv_pipe_t pipe
function uv.new_pipe(ipc) end

--- Opens an existing file descriptor or HANDLE as a pipe.
---@param pipe uv.uv_pipe_t
---@param fd integer
---@return integer status 0 on success, negative error code otherwise
function uv.pipe_open(pipe, fd) end

-- ============================================================================
-- TCP handle
-- ============================================================================

---@class uv.uv_tcp_t: uv.uv_handle_t
---@field open fun(self: uv.uv_tcp_t, fd: integer): integer
---@field nodelay fun(self: uv.uv_tcp_t, enable: boolean): integer
---@field keepalive fun(self: uv.uv_tcp_t, enable: boolean, delay?: integer): integer
---@field simultaneous_accepts fun(self: uv.uv_tcp_t, enable: boolean): integer
---@field bind fun(self: uv.uv_tcp_t, host: string, port: integer, flags?: table): integer
---@field getsockname fun(self: uv.uv_tcp_t): table?, string?
---@field getpeername fun(self: uv.uv_tcp_t): table?, string?
---@field connect fun(self: uv.uv_tcp_t, host: string, port: integer, callback: fun(err?: string))
---@field write_queue_size fun(self: uv.uv_tcp_t): integer
---@field read_start fun(self: uv.uv_tcp_t, callback: fun(err?: string, data?: string)): integer
---@field read_stop fun(self: uv.uv_tcp_t): integer
---@field write fun(self: uv.uv_tcp_t, data: string|string[], callback?: fun(err?: string)): uv.uv_write_t
---@field try_write fun(self: uv.uv_tcp_t, data: string|string[]): integer
---@field is_readable fun(self: uv.uv_tcp_t): boolean
---@field is_writable fun(self: uv.uv_tcp_t): boolean
---@field set_blocking fun(self: uv.uv_tcp_t, blocking: boolean): integer
---@field listen fun(self: uv.uv_tcp_t, backlog: integer, callback: fun(err?: string)): integer
---@field accept fun(self: uv.uv_tcp_t, client: uv.uv_tcp_t): integer
---@field shutdown fun(self: uv.uv_tcp_t, callback?: fun(err?: string)): uv.uv_shutdown_t
---@field close_reset fun(self: uv.uv_tcp_t, callback?: fun()): integer

--- Creates a new TCP handle.
---@param flags? table Address family flags (e.g., {family = "inet"})
---@return uv.uv_tcp_t tcp
function uv.new_tcp(flags) end

-- ============================================================================
-- UDP handle
-- ============================================================================

---@class uv.uv_udp_t: uv.uv_handle_t
---@field open fun(self: uv.uv_udp_t, fd: integer): integer
---@field bind fun(self: uv.uv_udp_t, host: string, port: integer, flags?: table): integer
---@field getsockname fun(self: uv.uv_udp_t): table?, string?
---@field set_membership fun(self: uv.uv_udp_t, multicast_addr: string, interface_addr: string, membership: string): integer
---@field set_multicast_loop fun(self: uv.uv_udp_t, enable: boolean): integer
---@field set_multicast_ttl fun(self: uv.uv_udp_t, ttl: integer): integer
---@field set_multicast_interface fun(self: uv.uv_udp_t, interface_addr: string): integer
---@field set_broadcast fun(self: uv.uv_udp_t, enable: boolean): integer
---@field set_ttl fun(self: uv.uv_udp_t, ttl: integer): integer
---@field send fun(self: uv.uv_udp_t, data: string|string[], host: string, port: integer, callback: fun(err?: string)): uv.uv_udp_send_t
---@field try_send fun(self: uv.uv_udp_t, data: string|string[], host: string, port: integer): integer
---@field recv_start fun(self: uv.uv_udp_t, callback: fun(err?: string, data?: string, addr?: table, flags?: table)): integer
---@field recv_stop fun(self: uv.uv_udp_t): integer
---@field get_send_queue_size fun(self: uv.uv_udp_t): integer
---@field get_send_queue_count fun(self: uv.uv_udp_t): integer

--- Creates a new UDP handle.
---@param flags? table Address family flags
---@return uv.uv_udp_t udp
function uv.new_udp(flags) end

-- ============================================================================
-- Process handle
-- ============================================================================

---@class uv.uv_process_t: uv.uv_handle_t
---@field kill fun(self: uv.uv_process_t, signum: integer): integer
---@field get_pid fun(self: uv.uv_process_t): integer

---@class uv.spawn_options
---@field args? string[] Command arguments
---@field stdio? (uv.uv_pipe_t|integer|nil)[] Array of stdio handles (stdin, stdout, stderr)
---@field env? table<string, string> Environment variables
---@field cwd? string Working directory
---@field uid? integer User ID (POSIX)
---@field gid? integer Group ID (POSIX)
---@field verbatim? boolean Don't escape arguments on Windows
---@field detached? boolean Spawn detached process
---@field hide? boolean Hide window on Windows

--- Spawns a new process.
---@param path string Executable path
---@param options uv.spawn_options Spawn options
---@param on_exit fun(code: integer, signal: integer) Exit callback
---@return uv.uv_process_t? userdata, integer
function uv.spawn(path, options, on_exit) end

--- Sends a signal to the process.
---@param process uv.uv_process_t
---@param signum integer Signal number
---@return integer status 0 on success
function uv.process_kill(process, signum) end

--- Disables or enables the inheritance of file descriptors.
---@param fd integer File descriptor
---@param enable boolean
---@return integer status
function uv.disable_stdio_inheritance(fd, enable) end

-- ============================================================================
-- Filesystem operations (synchronous and asynchronous)
-- ============================================================================

---@class uv.fs_stat.result
---@diagnostic disable
---@field dev integer Device ID
---@field mode integer Protection mode
---@field nlink integer Number of hard links
---@field uid integer User ID
---@field gid integer Group ID
---@field rdev integer Device ID (if special file)
---@field ino integer Inode number
---@field size integer Total size in bytes
---@field blksize integer Block size for I/O
---@field blocks integer Number of 512B blocks allocated
---@field flags integer Flags (platform-specific)
---@field gen integer Generation number (platform-specific)
---@field atime uv.fs_stat.time Access time
---@field mtime uv.fs_stat.time Modification time
---@field ctime uv.fs_stat.time Status change time
---@field birthtime uv.fs_stat.time Creation time
---@field type string File type: "file", "directory", "link", "fifo", "socket", "char", "block", or "unknown"
---@diagnostic enable

---@class uv.fs_stat.time
---@field sec integer Seconds since epoch
---@field nsec integer Nanoseconds

--- Equivalent to stat(2).
---@param path string
---@return uv.fs_stat.result? stat
---@return string? err
---@return string? err_name
---@overload fun(path: string, callback: fun(err?: string, stat?: uv.fs_stat.result)): uv.uv_fs_t
function uv.fs_stat(path) end

--- Equivalent to lstat(2).
---@param path string
---@return uv.fs_stat.result? stat
---@return string? err
---@return string? err_name
---@overload fun(path: string, callback: fun(err?: string, stat?: uv.fs_stat.result)): uv.uv_fs_t
function uv.fs_lstat(path) end

--- Equivalent to fstat(2).
---@param fd integer File descriptor
---@return uv.fs_stat.result? stat
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, callback: fun(err?: string, stat?: uv.fs_stat.result)): uv.uv_fs_t
function uv.fs_fstat(fd) end

--- Equivalent to rename(2).
---@param path string Old path
---@param new_path string New path
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, new_path: string, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_rename(path, new_path) end

--- Equivalent to unlink(2).
---@param path string
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_unlink(path) end

--- Equivalent to mkdir(2).
---@param path string
---@param mode integer Permission mode (e.g., 0755)
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, mode: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_mkdir(path, mode) end

--- Equivalent to mkdtemp(3).
---@param template string Template path ending with "XXXXXX"
---@return string? path
---@return string? err
---@return string? err_name
---@overload fun(template: string, callback: fun(err?: string, path?: string)): uv.uv_fs_t
function uv.fs_mkdtemp(template) end

--- Equivalent to mkstemp(3).
---@param template string Template path ending with "XXXXXX"
---@return integer? fd
---@return string? path
---@return string? err
---@overload fun(template: string, callback: fun(err?: string, fd?: integer, path?: string)): uv.uv_fs_t
function uv.fs_mkstemp(template) end

--- Equivalent to rmdir(2).
---@param path string
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_rmdir(path) end

--- Equivalent to scandir(3).
---@param path string
---@param callback? fun(err?: string, entries?: uv.fs_scandir_entry[])
---@return uv.uv_fs_t? req
---@return string? err
---@return string? err_name
function uv.fs_scandir(path, callback) end

---@class uv.fs_scandir_entry
---@field name string Filename
---@field type string Entry type: "file", "directory", "link", "fifo", "socket", "char", "block", or "unknown"

--- Iterator for scandir results (sync mode).
---@param req uv.uv_fs_t Request handle from fs_scandir
---@return string? name
---@return string? type
function uv.fs_scandir_next(req) end

--- Opens path as a directory stream. Returns a handle that the user can pass to
--- `uv.fs_readdir()`. The `entries` parameter defines the maximum number of entries
--- that should be returned by each call to `uv.fs_readdir()`.
--- @param path string
--- @param callback nil (async if provided, sync if `nil`)
--- @param entries integer?
--- @return uv.luv_dir_t? dir
--- @return string? err
--- @return string? err_name
--- @overload fun(path: string, callback: fun(err: string?, dir: uv.luv_dir_t?), entries: integer?): uv.uv_fs_t
function uv.fs_opendir(path, callback, entries) end

--- Reads a single directory entry.
---@param dir uv.luv_dir_t
---@return uv.fs_scandir_entry[]? entries
---@return string? err
---@return string? err_name
---@overload fun(dir: uv.luv_dir_t, callback: fun(err?: string, entries?: uv.fs_scandir_entry[])): uv.uv_fs_t
function uv.fs_readdir(dir) end

--- Closes a directory stream.
---@param dir uv.luv_dir_t
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(dir: uv.luv_dir_t, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_closedir(dir) end

--- Equivalent to open(2).
---@param path string
---@param flags string|integer Flags (e.g., "r", "w", "a", or O_RDONLY)
---@param mode integer Permission mode
---@return integer? fd
---@return string? err
---@return string? err_name
---@overload fun(path: string, flags: string|integer, mode: integer, callback: fun(err?: string, fd?: integer)): uv.uv_fs_t
function uv.fs_open(path, flags, mode) end

--- Equivalent to close(2).
---@param fd integer File descriptor
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_close(fd) end

--- Equivalent to read(2).
---@param fd integer File descriptor
---@param size integer Number of bytes to read
---@param offset? integer File offset (-1 for current position)
---@return string? data
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, size: integer, offset: integer?, callback: fun(err?: string, data?: string)): uv.uv_fs_t
function uv.fs_read(fd, size, offset) end

--- Equivalent to write(2).
---@param fd integer File descriptor
---@param data string|string[] Data to write
---@param offset? integer File offset (-1 for current position)
---@return integer? bytes_written
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, data: string|string[], offset: integer?, callback: fun(err?: string, bytes?: integer)): uv.uv_fs_t
function uv.fs_write(fd, data, offset) end

--- Equivalent to fsync(2).
---@param fd integer
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_fsync(fd) end

--- Equivalent to fdatasync(2).
---@param fd integer
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_fdatasync(fd) end

--- Equivalent to ftruncate(2).
---@param fd integer
---@param offset integer New file size
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, offset: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_ftruncate(fd, offset) end

--- Equivalent to sendfile(2).
---@param out_fd integer Destination file descriptor
---@param in_fd integer Source file descriptor
---@param in_offset integer Offset in source file
---@param size integer Number of bytes to transfer
---@return integer? bytes_sent
---@return string? err
---@return string? err_name
---@overload fun(out_fd: integer, in_fd: integer, in_offset: integer, size: integer, callback: fun(err?: string, bytes?: integer)): uv.uv_fs_t
function uv.fs_sendfile(out_fd, in_fd, in_offset, size) end

--- Equivalent to access(2).
---@param path string
---@param mode integer|string Access mode (e.g., "R", "W", "X", or F_OK)
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, mode: integer|string, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_access(path, mode) end

--- Equivalent to chmod(2).
---@param path string
---@param mode integer Permission mode
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, mode: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_chmod(path, mode) end

--- Equivalent to fchmod(2).
---@param fd integer
---@param mode integer Permission mode
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, mode: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_fchmod(fd, mode) end

--- Equivalent to utime(2).
---@param path string
---@param atime number Access time
---@param mtime number Modification time
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, atime: number, mtime: number, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_utime(path, atime, mtime) end

--- Equivalent to futime(2).
---@param fd integer
---@param atime number Access time
---@param mtime number Modification time
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, atime: number, mtime: number, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_futime(fd, atime, mtime) end

--- Equivalent to lutime(2).
---@param path string
---@param atime number Access time
---@param mtime number Modification time
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, atime: number, mtime: number, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_lutime(path, atime, mtime) end

--- Equivalent to link(2).
---@param path string Existing path
---@param new_path string New link path
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, new_path: string, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_link(path, new_path) end

--- Equivalent to symlink(2).
---@param path string Target path
---@param new_path string Link path
---@param flags? table Platform-specific flags
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, new_path: string, flags: table?, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_symlink(path, new_path, flags) end

--- Equivalent to readlink(2).
---@param path string
---@return string? target
---@return string? err
---@return string? err_name
---@overload fun(path: string, callback: fun(err?: string, target?: string)): uv.uv_fs_t
function uv.fs_readlink(path) end

--- Equivalent to realpath(3).
---@param path string
---@return string? resolved_path
---@return string? err
---@return string? err_name
---@overload fun(path: string, callback: fun(err?: string, path?: string)): uv.uv_fs_t
function uv.fs_realpath(path) end

--- Equivalent to chown(2).
---@param path string
---@param uid integer User ID
---@param gid integer Group ID
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, uid: integer, gid: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_chown(path, uid, gid) end

--- Equivalent to fchown(2).
---@param fd integer
---@param uid integer User ID
---@param gid integer Group ID
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(fd: integer, uid: integer, gid: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_fchown(fd, uid, gid) end

--- Equivalent to lchown(2).
---@param path string
---@param uid integer User ID
---@param gid integer Group ID
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, uid: integer, gid: integer, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_lchown(path, uid, gid) end

--- Copies a file (source to destination).
---@param path string Source path
---@param new_path string Destination path
---@param flags? table Copy flags (e.g., {excl = true, ficlone = true})
---@return boolean? success
---@return string? err
---@return string? err_name
---@overload fun(path: string, new_path: string, flags: table?, callback: fun(err?: string, success?: boolean)): uv.uv_fs_t
function uv.fs_copyfile(path, new_path, flags) end

--- Equivalent to statfs(2).
---@param path string
---@return table? statfs
---@return string? err
---@return string? err_name
---@overload fun(path: string, callback: fun(err?: string, statfs?: table)): uv.uv_fs_t
function uv.fs_statfs(path) end

-- ============================================================================
-- Filesystem event watching
-- ============================================================================

---@class uv.uv_fs_event_t: uv.uv_handle_t
---@field start fun(self: uv.uv_fs_event_t, path: string, flags: table, callback: fun(err?: string, filename?: string, events?: table)): integer
---@field stop fun(self: uv.uv_fs_event_t): integer
---@field getpath fun(self: uv.uv_fs_event_t): string?, string?

--- Creates a new filesystem event handle.
---@return uv.uv_fs_event_t fs_event
function uv.new_fs_event() end

-- ============================================================================
-- Filesystem polling (portable file change detection)
-- ============================================================================

---@class uv.uv_fs_poll_t: uv.uv_handle_t
---@field start fun(self: uv.uv_fs_poll_t, path: string, interval: integer, callback: fun(err?: string, prev?: uv.fs_stat.result, curr?: uv.fs_stat.result)): integer
---@field stop fun(self: uv.uv_fs_poll_t): integer
---@field getpath fun(self: uv.uv_fs_poll_t): string?, string?

--- Creates a new filesystem polling handle.
---@return uv.uv_fs_poll_t fs_poll
function uv.new_fs_poll() end

-- ============================================================================
-- Signal handling
-- ============================================================================

---@class uv.uv_signal_t: uv.uv_handle_t
---@field start fun(self: uv.uv_signal_t, signum: integer, callback: fun(signum: integer)): integer
---@field start_oneshot fun(self: uv.uv_signal_t, signum: integer, callback: fun(signum: integer)): integer
---@field stop fun(self: uv.uv_signal_t): integer

--- Creates a new signal handle.
---@return uv.uv_signal_t signal
function uv.new_signal() end

-- ============================================================================
-- Idle, Prepare, Check handles (event loop phases)
-- ============================================================================

---@class uv.uv_idle_t: uv.uv_handle_t
---@field start fun(self: uv.uv_idle_t, callback: fun()): integer
---@field stop fun(self: uv.uv_idle_t): integer

--- Creates a new idle handle (runs callback on every loop iteration).
---@return uv.uv_idle_t idle
function uv.new_idle() end

---@class uv.uv_prepare_t: uv.uv_handle_t
---@field start fun(self: uv.uv_prepare_t, callback: fun()): integer
---@field stop fun(self: uv.uv_prepare_t): integer

--- Creates a new prepare handle (runs before blocking for I/O).
---@return uv.uv_prepare_t prepare
function uv.new_prepare() end

---@class uv.uv_check_t: uv.uv_handle_t
---@field start fun(self: uv.uv_check_t, callback: fun()): integer
---@field stop fun(self: uv.uv_check_t): integer

--- Creates a new check handle (runs after blocking for I/O).
---@return uv.uv_check_t check
function uv.new_check() end

-- ============================================================================
-- Async handle (thread-safe event triggering)
-- ============================================================================

---@class uv.uv_async_t: uv.uv_handle_t
---@field send fun(self: uv.uv_async_t): integer

--- Creates a new async handle for waking up the event loop from other threads.
---@param callback fun() Callback executed in main thread
---@return uv.uv_async_t async
function uv.new_async(callback) end

-- ============================================================================
-- TTY (terminal) handle
-- ============================================================================

---@class uv.uv_tty_t: uv.uv_handle_t
---@field set_mode fun(self: uv.uv_tty_t, mode: integer): integer
---@field reset_mode fun(): integer
---@field get_winsize fun(self: uv.uv_tty_t): integer?, integer?, string?

--- Creates a new TTY handle.
---@param fd integer File descriptor (e.g., 0 for stdin, 1 for stdout)
---@param readable boolean True if handle is readable
---@return uv.uv_tty_t tty
function uv.new_tty(fd, readable) end

-- ============================================================================
-- Thread pool / Work scheduling
-- ============================================================================

---@class uv.uv_work_t

--- Queues a work request to run in a thread pool.
---@param work_callback fun() Executed in thread pool
---@param after_work_callback fun() Executed in main loop after work
---@return uv.uv_work_t? work
---@return string? err
function uv.queue_work(work_callback, after_work_callback) end

-- ============================================================================
-- Request types (returned by async operations)
-- ============================================================================

---@class uv.uv_req_t
---@field cancel fun(self: uv.uv_req_t): integer

---@class uv.uv_fs_t: uv.uv_req_t
---@class uv.uv_write_t: uv.uv_req_t
---@class uv.uv_shutdown_t: uv.uv_req_t
---@class uv.uv_udp_send_t: uv.uv_req_t
---@class uv.uv_connect_t: uv.uv_req_t
---@class uv.uv_getaddrinfo_t: uv.uv_req_t
---@class uv.uv_getnameinfo_t: uv.uv_req_t

-- ============================================================================
-- Directory handle (for fs_opendir/readdir/closedir)
-- ============================================================================

---@class uv.luv_dir_t: userdata

-- ============================================================================
-- Miscellaneous system functions
-- ============================================================================

--- Returns high-resolution real time in nanoseconds.
---@return integer nanoseconds
function uv.hrtime() end

--- Returns the current timestamp in milliseconds (monotonic).
---@return integer milliseconds
function uv.now() end

--- Pauses the current thread for a given number of milliseconds.
---@param ms integer Milliseconds to sleep
function uv.sleep(ms) end

--- Returns the current working directory.
---@return string? cwd
---@return string? err
function uv.cwd() end

--- Changes the current working directory.
---@param cwd string New working directory
---@return boolean? success
---@return string? err
function uv.chdir(cwd) end

--- Returns system name information.
---@return table? uname {sysname, release, version, machine}
---@return string? err
function uv.os_uname() end

--- Returns environment variable value.
---@param name string Variable name
---@return string? value
function uv.os_getenv(name) end

--- Sets an environment variable.
---@param name string Variable name
---@param value string Variable value
---@return boolean? success
---@return string? err
function uv.os_setenv(name, value) end

--- Unsets an environment variable.
---@param name string Variable name
---@return boolean? success
---@return string? err
function uv.os_unsetenv(name) end

--- Returns all environment variables.
---@return table<string, string>? env
---@return string? err
function uv.os_environ() end

--- Returns the hostname.
---@return string? hostname
---@return string? err
function uv.os_gethostname() end

--- Returns the system uptime in seconds.
---@return number? uptime
---@return string? err
function uv.uptime() end

--- Returns load average (1, 5, 15 minutes).
---@return number[]? loadavg
function uv.loadavg() end

--- Returns the amount of free system memory in bytes.
---@return number? bytes
function uv.get_free_memory() end

--- Returns the total system memory in bytes.
---@return number? bytes
function uv.get_total_memory() end

--- Returns the amount of memory available to the process in bytes.
---@return number? bytes
function uv.get_constrained_memory() end

--- Returns resource usage information.
---@return table? rusage
---@return string? err
function uv.getrusage() end

--- Returns the current process ID.
---@return integer pid
function uv.os_getpid() end

--- Returns the parent process ID.
---@return integer ppid
function uv.os_getppid() end

--- Returns the priority of a process.
---@param pid integer Process ID
---@return integer? priority
---@return string? err
function uv.os_getpriority(pid) end

--- Sets the priority of a process.
---@param pid integer Process ID
---@param priority integer Priority value
---@return boolean? success
---@return string? err
function uv.os_setpriority(pid, priority) end

--- Returns password file entry for the current user.
---@return table? passwd
---@return string? err
function uv.os_get_passwd() end

--- Returns system CPU information.
---@return table[]? cpus Array of {model, speed, times}
---@return string? err
function uv.cpu_info() end

--- Returns network interface addresses.
---@return table[]? addresses
---@return string? err
function uv.interface_addresses() end

--- Performs DNS resolution (getaddrinfo).
---@param node string Hostname or IP
---@param service? string|integer Service name or port
---@param hints? table Hints for resolution
---@param callback? fun(err?: string, addresses?: table[])
---@return uv.uv_getaddrinfo_t? req
---@return string? err
function uv.getaddrinfo(node, service, hints, callback) end

--- Performs reverse DNS lookup (getnameinfo).
---@param address table Address table {ip, port, family}
---@param callback? fun(err?: string, hostname?: string, service?: string)
---@return uv.uv_getnameinfo_t? req
---@return string? err
function uv.getnameinfo(address, callback) end

--- Returns the executable path.
---@return string? path
---@return string? err
function uv.exepath() end

--- Returns the resident set size (memory usage) in bytes.
---@return integer? bytes
---@return string? err
function uv.resident_set_memory() end

--- Returns handle statistics (event loop metrics).
---@return table? metrics
function uv.metrics_info() end

--- Returns idle time for the event loop.
---@return integer? idle_time
function uv.metrics_idle_time() end

--- Returns the libuv version as an integer.
---@return integer version
function uv.version() end

--- Returns the libuv version as a string.
---@return string version
function uv.version_string() end

-- ============================================================================
-- Event loop control
-- ============================================================================

--- Runs the event loop until no active handles remain.
---@param mode? string Run mode: "default", "once", or "nowait"
---@return boolean success
function uv.run(mode) end

--- Stops the event loop.
function uv.stop() end

--- Returns true if there are active handles or requests.
---@return boolean alive
function uv.loop_alive() end

--- Closes the event loop and releases all resources.
---@return boolean success
function uv.loop_close() end

--- Returns the backend file descriptor for the event loop (Unix).
---@return integer? fd
function uv.backend_fd() end

--- Returns the backend timeout value in milliseconds.
---@return integer? timeout
function uv.backend_timeout() end

--- Walks all active handles and executes a callback for each.
---@param callback fun(handle: uv.uv_handle_t)
function uv.walk(callback) end

---@param timer uv.uv_timer_t
---@return integer|nil
function uv.timer_stop(timer) end

---@return string|nil
function uv.os_homedir() end

---@param self uv.uv_handle_t
---@return boolean
function uv.is_closing(self) end

-- Expose as vim.uv (and vim.loop as legacy alias)
vim.uv = uv
vim.loop = uv

return {}
