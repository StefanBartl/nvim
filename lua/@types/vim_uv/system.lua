---@meta
---@module '@types.vim.uv.@types.system'
---@brief OS information, environment, memory, and CPU metrics

---@class uv.uname_result
---@field sysname string # Operating system name (e.g., "Linux", "Darwin", "Windows_NT")
---@field release string # OS release version
---@field version string # OS version string
---@field machine string # Hardware architecture (e.g., "x86_64", "arm64")

---@class uv.cpu_info_entry
---@field model string # CPU model name
---@field speed integer # CPU speed in MHz
---@field times table<string, integer> # CPU time breakdown: {user, nice, sys, idle, irq}

---@class uv.interface_address
---@field name string # Interface name (e.g., "eth0", "wlan0")
---@field phys string # Physical address (MAC) as hex string
---@field is_internal boolean # True if loopback interface
---@field family string # Address family: "inet" or "inet6"
---@field address string # IP address
---@field netmask string # Network mask
---@field mac string # MAC address (same as phys)

---@class uv.passwd_result
---@field username string # User login name
---@field uid integer # User ID
---@field gid integer # Primary group ID
---@field shell string # Default shell path
---@field homedir string # Home directory path

---@class uv.rusage_result
---@field utime table<string, integer> # User CPU time: {sec, usec}
---@field stime table<string, integer> # System CPU time: {sec, usec}
---@field maxrss integer # Maximum resident set size (KB)
---@field ixrss integer # Integral shared memory size
---@field idrss integer # Integral unshared data size
---@field isrss integer # Integral unshared stack size
---@field minflt integer # Page reclaims (soft page faults)
---@field majflt integer # Page faults (hard page faults)
---@field nswap integer # Swaps
---@field inblock integer # Block input operations
---@field oublock integer # Block output operations
---@field msgsnd integer # IPC messages sent
---@field msgrcv integer # IPC messages received
---@field nsignals integer # Signals received
---@field nvcsw integer # Voluntary context switches
---@field nivcsw integer # Involuntary context switches

return {}
