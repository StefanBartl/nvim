---@module 'autocmds.events.utils.filetype'
---@brief Central FileType event dispatcher with lazy handler loading

local M = {}

local api = vim.api
local buffer_ctx = require("autocmds.benchmarks.context.buffer")

---@class FiletypeHandler
---@field load fun(): table|nil Lazy loader function
---@field priority? integer Handler priority (lower = earlier, default: 100)
---@field once? boolean Run only once per buffer (default: false)

---@type table<string, FiletypeHandler[]>
local handlers = {
  -- Git commit messages
  gitcommit = {
    {
      load = function()
        return (require("autocmds.git.commit_ft"))
      end,
      priority = 10,
      once = true,
    },
  },

  -- Noice buffers
  ["noice*"] = {
    {
      load = function()
        return (require("mappings.noice"))
      end,
      priority = 10,
    },
  },

  -- LSP-specific filetypes
  lua = {
    {
      load = function()
        return (require("lsp.languages.scripting.lua"))
      end,
      priority = 10,
      once = true,
    },
  },

  c = {
    {
      load = function()
        return (require("lsp.languages.systems.c"))
      end,
      priority = 10,
      once = true,
    },
  },

  cpp = {
    {
      load = function()
        return (require("lsp.languages.systems.c"))
      end,
      priority = 10,
      once = true,
    },
  },

  cs = {
    {
      load = function()
        return (require("lsp.languages.app.csharp"))
      end,
      priority = 10,
      once = true,
    },
  },

  go = {
    {
      load = function()
        return (require("lsp.languages.systems.go"))
      end,
      priority = 10,
      once = true,
    },
  },

  html = {
    {
      load = function()
        return (require("lsp.languages.webdev.html"))
      end,
      priority = 10,
      once = true,
    },
  },

  zig = {
    {
      load = function()
        return (require("lsp.languages.systems.zig"))
      end,
      priority = 10,
      once = true,
    },
  },

  -- Messages/debug filetypes
  messages = {
    {
      load = function()
        return (require("debugging.views.autocmds"))
      end,
      priority = 10,
    },
  },
}

--- Track which handlers have run (for once=true)
---@type table<integer, table<string, boolean>>
local run_once_tracker = setmetatable({}, { __mode = "k" })

--- Match filetype against pattern (supports wildcards)
---@param filetype string
---@param pattern string
---@return boolean
local function matches_pattern(filetype, pattern)
  if pattern == filetype then
    return true
  end

  -- Support wildcard patterns (e.g., "noice*")
  if pattern:match("%*") then
    local lua_pattern = "^" .. pattern:gsub("%*", ".*") .. "$"
    return filetype:match(lua_pattern) ~= nil
  end

  return false
end

--- Get handlers for a filetype
---@param filetype string
---@return FiletypeHandler[]
local function get_handlers(filetype)
  local matched = {}

  for pattern, handler_list in pairs(handlers) do
    if matches_pattern(filetype, pattern) then
      for _, handler in ipairs(handler_list) do
        table.insert(matched, handler)
      end
    end
  end

  -- Sort by priority
  table.sort(matched, function(a, b)
    local pa = a.priority or 100
    local pb = b.priority or 100
    return pa < pb
  end)

  return matched
end

--- Run a single handler
---@param handler FiletypeHandler
---@param ctx table Buffer context
---@param bufnr integer
---@return boolean success
local function run_handler(handler, ctx, bufnr)
  -- Check if already run (for once=true)
  if handler.once then
    run_once_tracker[bufnr] = run_once_tracker[bufnr] or {}
    local key = tostring(handler.load)
    if run_once_tracker[bufnr][key] then
      return true -- Already run, skip
    end
    run_once_tracker[bufnr][key] = true
  end

  local ok, module = pcall(handler.load)
  if not ok then
    vim.notify(
      string.format("[FileType] Failed to load handler: %s", tostring(module)),
      vim.log.levels.ERROR
    )
    return false
  end

  -- Call handler's apply/setup function
  if type(module) == "table" then
    if module.apply then
      ok = pcall(module.apply, ctx, bufnr)
    elseif module.setup then
      ok = pcall(module.setup, ctx, bufnr)
    else
      -- Module loaded but no entry point
      return true
    end
  elseif type(module) == "function" then
    ok = pcall(module, ctx, bufnr)
  end

  if not ok then
    vim.notify(
      string.format("[FileType] Handler execution failed for %s", ctx.filetype),
      vim.log.levels.WARN
    )
    return false
  end

  return true
end

--- Main dispatcher callback
---@param ev table Autocmd event args
function M.dispatch(ev)
  local bufnr = ev.buf
  local filetype = ev.match

  -- Get buffer context (cached)
  local ctx = buffer_ctx.get(bufnr)

  -- Early exit for invalid buffers
  if not ctx.is_valid then
    return
  end

  -- Get handlers for this filetype
  local handler_list = get_handlers(filetype)
  if #handler_list == 0 then
    return -- No handlers registered
  end

  -- Run handlers in priority order
  for _, handler in ipairs(handler_list) do
    run_handler(handler, ctx, bufnr)
  end
end

--- Register the dispatcher (call once in init)
function M.setup()
  local aug = api.nvim_create_augroup("FiletypeDispatcher", { clear = true })

  api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = "*",
    callback = M.dispatch,
    desc = "Central filetype dispatcher with lazy handlers",
  })
end

--- Register a new handler (for external use)
---@param filetype string|string[]
---@param handler FiletypeHandler
function M.register(filetype, handler)
  local filetypes = type(filetype) == "table" and filetype or { filetype }

  for _, ft in ipairs(filetypes) do
    handlers[ft] = handlers[ft] or {}
    table.insert(handlers[ft], handler)
  end
end

--- Get statistics about registered handlers
---@return table
function M.get_stats()
  local total_handlers = 0
  local filetypes = {}

  for ft, handler_list in pairs(handlers) do
    table.insert(filetypes, ft)
    total_handlers = total_handlers + #handler_list
  end

  table.sort(filetypes)

  return {
    total_filetypes = #filetypes,
    total_handlers = total_handlers,
    filetypes = filetypes,
    handlers = handlers,
  }
end

--- Print handler registry (for debugging)
function M.print_registry()
  local stats = M.get_stats()

  print(
    string.format(
      "FileType Handler Registry (%d handlers, %d filetypes)",
      stats.total_handlers,
      stats.total_filetypes
    )
  )
  print(string.rep("─", 60))

  for _, ft in ipairs(stats.filetypes) do
    local handler_list = handlers[ft]
    print(string.format("%-20s → %d handler(s)", ft, #handler_list))
    for i, h in ipairs(handler_list) do
      local prio = h.priority or 100
      local once = h.once and " [once]" or ""
      print(string.format("  %d. Priority %3d%s", i, prio, once))
    end
  end
end

return M
