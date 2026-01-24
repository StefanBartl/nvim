---@meta
---@module 'wkdoptions.hl_config.path_cache.@types'
---
--- Type definitions for buffer-local path caching system.
--- Reduces repeated upward .git searches on every CursorMoved/WinScrolled event.

---@class WKDOptions.HL_CFG.PathCache
--- Buffer-local cache for repo root and repo-relative path.
--- Stores computed values in buffer-local variables (vim.b) for fast access.
--- Cache is invalidated/refreshed on BufEnter, BufFilePost, and DirChanged events.
---@field refresh_buffer_cache fun(bufnr: integer): nil # Prime cache for specific buffer (0 = current). Sets: b.myopt_repo_root, b.myopt_repo_rel, b.myopt_repo_rel_path, b.myopt_repo_rel_cwd
---@field repo_relative_cached fun(path: string, bufnr: integer|nil): string # Get repo-relative path from cache (recomputes lazily on path/cwd change). Returns cached b.myopt_repo_rel or computes fresh if mismatch
---@field ensure_autocmds fun(): nil # Install autocmds that keep cache fresh (BufEnter/BufFilePost/DirChanged). Call once during init

---@class BufferPathCache
--- Buffer-local variables set by PathCache module (for reference only, not directly used in code).
---@field myopt_repo_root string|nil # Absolute path to repo root (parent of .git), nil if no repo
---@field myopt_repo_rel string # Repo-relative or "~"-shortened path (never nil, "[No Name]" for unnamed buffers)
---@field myopt_repo_rel_path string # Absolute path that was used to compute myopt_repo_rel (for cache invalidation)
---@field myopt_repo_rel_cwd string # CWD at time of cache computation (for cache invalidation on :cd/:tcd)

return {}
