---@meta
---@module '@types.vim.uv.@types.network'
---@brief UDP sockets, DNS resolution, and network interfaces

---@class uv.uv_udp_t : uv.uv_handle_t
---@field open fun(self: uv.uv_udp_t, fd: integer): integer # Open existing socket as UDP handle. Returns 0 on success.
---@field bind fun(self: uv.uv_udp_t, host: string, port: integer, flags?: table): integer # Bind to address and port. Flags: {ipv6only, reuseaddr}. Returns 0 on success.
---@field getsockname fun(self: uv.uv_udp_t): table|nil, string|nil # Get local address as {ip, port, family} or nil, error
---@field set_membership fun(self: uv.uv_udp_t, multicast_addr: string, interface_addr: string, membership: string): integer # Join/leave multicast group. Membership: "join", "leave". Returns 0 on success.
---@field set_multicast_loop fun(self: uv.uv_udp_t, enable: boolean): integer # Enable/disable multicast loopback. Returns 0 on success.
---@field set_multicast_ttl fun(self: uv.uv_udp_t, ttl: integer): integer # Set multicast TTL (1-255). Returns 0 on success.
---@field set_multicast_interface fun(self: uv.uv_udp_t, interface_addr: string): integer # Set outgoing multicast interface. Returns 0 on success.
---@field set_broadcast fun(self: uv.uv_udp_t, enable: boolean): integer # Enable/disable broadcast. Returns 0 on success.
---@field set_ttl fun(self: uv.uv_udp_t, ttl: integer): integer # Set TTL (1-255). Returns 0 on success.
---@field send fun(self: uv.uv_udp_t, data: string|string[], host: string, port: integer, callback: fun(err?: string)): uv.uv_udp_send_t # Send datagram to destination. Returns send request.
---@field try_send fun(self: uv.uv_udp_t, data: string|string[], host: string, port: integer): integer # Attempt synchronous send. Returns bytes sent or negative error code.
---@field recv_start fun(self: uv.uv_udp_t, callback: fun(err?: string, data?: string, addr?: table, flags?: table)): integer # Start receiving datagrams. Callback receives data, source address, and flags. Returns 0 on success.
---@field recv_stop fun(self: uv.uv_udp_t): integer # Stop receiving datagrams. Returns 0 on success.
---@field get_send_queue_size fun(self: uv.uv_udp_t): integer # Get send queue size in bytes
---@field get_send_queue_count fun(self: uv.uv_udp_t): integer # Get number of queued send requests

---@class uv.dns_addr_info
---@field addr string # IP address
---@field family string # Address family: "inet" (IPv4) or "inet6" (IPv6)
---@field port integer|nil # Port number if applicable
---@field socktype string|nil # Socket type: "stream", "dgram"
---@field protocol string|nil # Protocol: "tcp", "udp"
---@field canonname string|nil # Canonical hostname

return {}
