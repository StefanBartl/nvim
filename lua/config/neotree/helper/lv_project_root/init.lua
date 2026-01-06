---@module 'config.neotree.helper.lv_project_root'
--- Resolve a "project root" similarly to LazyVim, but without depending on it.
--- Priority:
---   1) LSP client root_dir for the current buffer (closest/longest path wins)
---   2) Git toplevel (via vim.fs.find(".git", upward) or `git rev-parse`)
---   3) Current buffer's directory
---   4) Current working directory (uv.cwd())
---
--- Neovim: 0.9+ (vim.fs APIs); uses modern LSP API when available (0.10+).

local M = {}

-- Backward-compatible uv handle
local uv = vim.uv or vim.loop

--- Normalize a path for reliable cross-platform comparisons.
---@param p Path|nil
---@return Path
local function norm(p)
  return vim.fs.normalize(p or "")
end

--- Typed wrapper around `uv.cwd()` with fallback to `vim.fn.getcwd()`.
--- Some analyzers do not infer `uv.cwd()` as string → keep it explicit.
---@return Path
local function get_cwd()
  return (uv.cwd() or vim.fn.getcwd()) --[[@as Path]]
end

--- Return the directory of the given buffer (or cwd if unnamed).
---@param bufnr? integer  -- 0 = current buffer
---@return Path           -- always a normalized string path
local function buffer_dir(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  if not name or name == "" then
    return get_cwd()
  end
  -- `vim.fs.dirname` may return nil → coalesce and cast for LuaLS
  local dir = vim.fs.dirname(name) or get_cwd()
  ---@cast dir Path
  return vim.fs.normalize(dir)
end

--- Iterate LSP clients attached to `bufnr`, preferring the modern API.
---@param bufnr? integer
local function get_buf_clients(bufnr)
  bufnr = bufnr or 0
  if type(vim.lsp.get_clients) == "function" then
    -- Neovim ≥ 0.10 (non-deprecated)
    return vim.lsp.get_clients({ bufnr = bufnr })
  end
  -- Neovim < 0.10: fallback via deprecated API, filtered manually
  local clients = {}
  ---@diagnostic disable-next-line: deprecated
  local all = vim.lsp.get_active_clients and vim.lsp.get_active_clients() or {}
  for _, c in ipairs(all) do
    if c.attached_buffers and c.attached_buffers[bufnr] then
      clients[#clients + 1] = c
    end
  end
  return clients
end

--- Collect unique LSP root dirs for the buffer and sort by "closest" (longest path first).
---@param bufnr? integer
---@return Path[] roots
local function lsp_roots(bufnr)
  bufnr = bufnr or 0

  ---@type table<Path, true>
  local acc = {}

  for _, client in ipairs(get_buf_clients(bufnr)) do
    -- Conventional root hint
    local root = client and client.config and client.config.root_dir or nil
    if type(root) == "string" and root ~= "" and vim.fn.isdirectory(root) == 1 then
      acc[norm(root)] = true
    end
  end

  ---@type Path[]  -- de-duplicate
  local roots = {}
  for r, _ in pairs(acc) do
    roots[#roots + 1] = r
  end

  table.sort(roots, function(a, b)
    return #a > #b
  end) -- longest first
  return roots
end

--- Try to find the Git toplevel directory upward from `start`.
---@param start Path
---@return Path|nil
local function git_root(start)
  -- Fast path: use Neovim's filesystem search (no external process)
  local hit = vim.fs.find(".git", { upward = true, type = "directory", path = start })[1]
  if hit then
    return norm(vim.fs.dirname(hit))
  end
  -- Fallback: shell out to git (handles submodules/worktrees robustly)
  local out = vim.fn.system({ "git", "-C", start, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and type(out) == "string" and #out > 0 then
    return norm((out:gsub("%s+$", "")))
  end
  return nil
end

--- Check whether `child` lies within (or equals) `root`.
---@param child Path
---@param root Path
---@return boolean
local function is_within(child, root)
  child = norm(child)
  root = norm(root)
  if child == root then
    return true
  end
  if not root:match("[/\\]$") then
    root = root .. "/"
  end
  return child:sub(1, #root) == root
end

--- Compute the project root for `bufnr`.
---@param bufnr? integer
---@return Path
function M.get(bufnr)
  bufnr = bufnr or 0
  local bdir = buffer_dir(bufnr)

  -- 1) LSP roots (closest match wins)
  for _, r in ipairs(lsp_roots(bufnr)) do
    if is_within(bdir, r) then
      return r
    end
  end

  -- 2) Git toplevel
  local gr = git_root(bdir)
  if gr then
    return gr
  end

  -- 3) Buffer directory
  if bdir ~= "" then
    return norm(bdir)
  end

  -- 4) CWD
  return norm(get_cwd())
end

---@cast M ProjectRoot
return M
