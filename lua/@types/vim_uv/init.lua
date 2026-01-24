---@meta
---@module '@types.vim.uv.@types'
---@brief Central type aggregator for libuv bindings in Neovim
---@description
--- Aggregates all libuv type definitions from submodules organized by domain.
--- Provides comprehensive type coverage for vim.uv (and legacy vim.loop) API.
---
--- Module structure:
---   - constants.lua  : Platform constants (O_*, SOCK_*, SIG_*, etc.)
---   - handles.lua    : Base handle types and lifecycle methods
---   - timers.lua     : Timer, idle, prepare, check, async handles
---   - streams.lua    : TCP, pipe, TTY handles and streaming I/O
---   - network.lua    : UDP, DNS resolution, network interfaces
---   - filesystem.lua : File operations, stat structures, directory iteration
---   - process.lua    : Process spawning, signals, priority management
---   - system.lua     : OS information, environment, memory, CPU metrics
---   - loop.lua       : Event loop control and metrics

return {}
