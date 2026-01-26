---@meta
---@module '@types.vim.uv.@types.filesystem'
---@brief File operations, directory iteration, and stat structures

---@class uv.fs_stat.time
---@field sec integer # Seconds since Unix epoch (UTC)
---@field nsec integer # Nanoseconds component (0-999999999)

---@class uv.fs_stat.result
---@field dev integer # Device ID containing file
---@field mode integer # File protection mode (permission bits)
---@field nlink integer # Number of hard links
---@field uid integer # User ID of owner
---@field gid integer # Group ID of owner
---@field rdev integer # Device ID (if special file)
---@field ino integer # Inode number
---@field size integer # Total size in bytes
---@field blksize integer # Preferred block size for I/O operations
---@field blocks integer # Number of 512-byte blocks allocated
---@field flags integer # User-defined flags (platform-specific)
---@field gen integer # File generation number (platform-specific)
---@field atime uv.fs_stat.time # Last access time
---@field mtime uv.fs_stat.time # Last modification time
---@field ctime uv.fs_stat.time # Last status change time (permissions, ownership)
---@field birthtime uv.fs_stat.time # File creation time
---@field type string # Entry type: "file" | "directory" | "link" | "fifo" | "socket" | "char" | "block" | "unknown"

---@class uv.fs_scandir_entry
---@field name string # Filename without directory path
---@field type string # Entry type: "file" | "directory" | "link" | "fifo" | "socket" | "char" | "block" | "unknown"

---@class uv.luv_dir_t : userdata
--- Opaque directory stream handle returned by fs_opendir.
--- Used with fs_readdir and fs_closedir.

return {}

