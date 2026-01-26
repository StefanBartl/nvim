---@meta
---@module '@types.vim.uv.@types.requests'
---@brief Request handles for asynchronous operations

---@class uv.uv_req_t
---@field cancel fun(self: uv.uv_req_t): integer # Cancel pending request. Returns 0 on success or error code.

---@class uv.uv_fs_t : uv.uv_req_t
--- Filesystem operation request handle returned by async fs_* functions

---@class uv.uv_write_t : uv.uv_req_t
--- Write operation request handle returned by stream write operations

---@class uv.uv_shutdown_t : uv.uv_req_t
--- Shutdown operation request handle returned by stream shutdown

---@class uv.uv_udp_send_t : uv.uv_req_t
--- UDP send operation request handle returned by udp_send

---@class uv.uv_connect_t : uv.uv_req_t
--- Connection operation request handle returned by tcp_connect/pipe_connect

---@class uv.uv_getaddrinfo_t : uv.uv_req_t
--- DNS address resolution request handle returned by getaddrinfo

---@class uv.uv_getnameinfo_t : uv.uv_req_t
--- Reverse DNS resolution request handle returned by getnameinfo

---@class uv.uv_work_t : uv.uv_req_t
--- Thread pool work request handle returned by queue_work

return {}
