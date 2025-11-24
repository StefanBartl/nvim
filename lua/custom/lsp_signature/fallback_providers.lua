---@module 'custom.lsp_signature.fallback_providers'
--- Query alternative LSP providers when signatureHelp and hover return nothing.
--- The module tries a sequence of LSP methods (typeDefinition, implementation, references)
--- and formats the first non-empty result into a list of lines suitable for
--- `open_floating_preview`.
---
--- Usage:
---   local fb = require("custom.lsp_signature.fallback_providers")
---   fb.try_providers(clients, params, { mode = mode, callback = cb })
---
--- Behavior:
--- 1. Iterate the configured provider-methods in order for *each* client until one returns results.
--- 2. Format locations or symbol info into compact textual lines:
---      "<relative-path>:<line>:<col>  –  <preview snippet or symbol-name>"
--- 3. Schedule opening of floating preview via open_floating_preview(lines).
--- 4. Notify user if no provider yields content.
---
--- Notes:
--- - This is an async, fire-and-forget helper. It invokes the provided callback(buf,win)
---   when a floating preview is created. It avoids blocking the caller.
--- - The formatting is conservative and avoids reading large files; a small snippet is attempted
---   by loading the target buffer line when possible.
--- - The module uses pcall around client.request to avoid exceptions when a client disconnects.
local M = {}

local open_floating_preview = require("custom.lsp_signature.open_floating_preview")
local state = require("custom.lsp_signature.state")
local helper = require("custom.lsp_signature.utils.helper") -- ensure this is required at top of file
local api = vim.api
local schedule = vim.schedule
local uri_to_fname = vim.uri_to_fname
local notify = vim.notify

--- Provider list in preferred order. Can be adjusted.
local DEFAULT_PROVIDERS = {
  "textDocument/typeDefinition",
  "textDocument/implementation",
  "textDocument/references",
}

-- Helper: obtain a short preview snippet from a file/uri at a 0-based line index.
---@param uri_or_fname string
---@param lnum0 integer
---@return string
local function get_line_preview(uri_or_fname, lnum0)
  local fname = uri_or_fname
  -- if it looks like a URI, convert
  if fname:match("^%a[%w+.-]*://") then
    fname = uri_to_fname(fname)
  end
  -- try to read the buffer for that file, or load file contents temporarily
  local ok, lines
  -- try to find buffer already loaded
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(bufnr) then
      local bufname = api.nvim_buf_get_name(bufnr)
      if bufname ~= "" and bufname == fname then
        ok = true
        lines = api.nvim_buf_get_lines(bufnr, lnum0, lnum0 + 1, false)
        break
      end
    end
  end
  if not ok then
    -- attempt to open file read-only to fetch line (safe pcall)
    local f_ok, f = pcall(io.open, fname, "r")
    if f_ok and f then
      local skip = 0
      local content_line
      for line in f:lines() do
        if skip == lnum0 then
          content_line = line
          break
        end
        skip = skip + 1
      end
      f:close()
      if content_line then
        lines = { content_line }
      end
    end
  end
  local snippet = ""
  if type(lines) == "table" and lines[1] then
    snippet = lines[1]:gsub("^%s+", ""):gsub("%s+$", "")
    if #snippet > 140 then
      snippet = snippet:sub(1, 137) .. "..."
    end
  end
  return snippet
end

-- Helper: normalize Location, LocationLink, or array into a flat list of {uri, lnum0, col0, name?}
---@param result any
---@return table[] list
local function flatten_locations(result)
  local out = {}
  if not result then
    return out
  end

  local function push_loc(uri, range, name)
    local s = range and range.start
    if s then
      table.insert(out, { uri = uri, lnum = (s.line or 0), col = (s.character or 0), name = name })
    end
  end

  local function handle_item(item)
    if item == nil then
      return
    end
    -- LocationLink has targetUri and targetRange / targetSelectionRange
    if item.targetUri and item.targetRange then
      push_loc(item.targetUri, item.targetRange, item.targetSelectionRange and item.targetSelectionRange or nil)
    elseif item.uri and item.range then
      push_loc(item.uri, item.range, nil)
    elseif type(item) == "string" then
      -- if server returned string (rare), just add as name-only
      table.insert(out, { uri = nil, lnum = 0, col = 0, name = item })
    end
  end

  if vim.islist(result) then
    for _, item in ipairs(result) do
      handle_item(item)
    end
  else
    handle_item(result)
  end

  return out
end

--- Formats one location entry into a single human-readable line.
--- Uses helper.shorten_display_path() to show compact path (node_modules/... or ./relative or basename).
--- @param entry table
--- @return string
local function format_location_line(entry)
  if not entry then
    return ""
  end

  local uri = entry.uri or ""
  local fname = uri ~= "" and vim.uri_to_fname(uri) or "[unknown]"
  -- shorten the path for display
  local display_path = helper.shorten_display_path(fname)

  local lnum = (entry.lnum or 0) + 1
  local col = (entry.col or 0) + 1
  local snippet = get_line_preview(uri or fname, entry.lnum or 0)
  local name = entry.name and tostring(entry.name) or ""

  local parts = { string.format("%s:%d:%d", display_path, lnum, col) }

  if name ~= "" then
    table.insert(parts, "–")
    table.insert(parts, name)
  end

  if snippet ~= "" then
    table.insert(parts, ":")
    table.insert(parts, snippet)
  end

  return table.concat(parts, " ")
end

--- Try providers for a single client sequentially. On first non-empty result,
--- open floating preview and invoke callback(buf,win).
---@param client table
---@param params table
---@param providers string[] list of LSP method names
---@param opts table|nil
local function try_client_providers(client, params, providers, opts)
  opts = opts or {}
  local mode = opts.mode
  local callback = opts.callback

  local i = 1
  local function next_provider()
    local method = providers[i]
    if not method then
      -- exhausted providers for this client
      return
    end
    i = i + 1

    local handler = function(_, result)
      -- flatten and format result
      local locs = flatten_locations(result)
      if locs and #locs > 0 then
        local lines = {}
        for _, entry in ipairs(locs) do
          table.insert(lines, format_location_line(entry))
        end
        schedule(function()
          local buf, win = open_floating_preview(lines)
          state.set(buf, win)
          if mode == "n" and win and api.nvim_win_is_valid(win) then
            api.nvim_set_current_win(win)
          end
          if callback and buf and win then
            callback(buf, win)
          end
        end)
        return
      end
      -- nothing found for this provider — try next one
      next_provider()
    end

    -- protect request call
    pcall(function()
      -- For references, some servers expect params with context.includeDeclaration = true
      if method == "textDocument/references" then
        local rparams = vim.deepcopy(params)
        rparams.context = rparams.context or {}
        rparams.context.includeDeclaration = true
        pcall(client.request, client, method, rparams, handler, vim.api.nvim_get_current_buf())
      else
        pcall(client.request, client, method, params, handler, vim.api.nvim_get_current_buf())
      end
    end)
  end

  next_provider()
end

--- Public API: try a set of providers across clients.
--- Tries each client in order; for each client it tries providers sequentially until a result.
---@param clients table[] list of LSP client objects
---@param params table request params (position params)
---@param opts table|nil
function M.try_providers(clients, params, opts)
  opts = opts or {}
  local providers = opts.providers or DEFAULT_PROVIDERS
  local callback = opts.callback
  local mode = opts.mode

  if not clients or vim.tbl_isempty(clients) then
    schedule(function()
      notify("[signature_help] fallback: no clients available", vim.log.levels.INFO)
    end)
    return
  end

  -- iterate clients one by one; try providers on each until one produces output
  local ci = 1
  local function next_client()
    local client = clients[ci]
    ci = ci + 1
    if not client then
      -- exhausted all clients and providers
      schedule(function()
        notify("[signature_help] fallback: no provider returned results", vim.log.levels.INFO)
      end)
      return
    end

    -- attempt providers for this client; when providers are all exhausted for a client,
    -- continue with next client by arranging the provider callbacks to call next_client.
    -- We achieve that by wrapping try_client_providers and relying on it to call next_client
    -- only when it finds nothing. To detect that, we hack a timeout guard: if after
    -- X ms nothing called the floating preview, we move to the next client.
    local timer = vim.loop.new_timer()
    local timeout_ms = 800 -- reasonable wait per client for fallback methods
    ---@diagnostic disable-next-line lib.uv
    timer:start(
      timeout_ms,
      0,
      vim.schedule_wrap(function()
        -- stop trying this client and move on
        next_client()
      end)
    )

    -- We need to observe whether a preview was actually opened; wrap the provided callback
    -- so we can stop the timer and avoid advancing to next client.
    local wrapped_cb = function(buf, win)
      ---@diagnostic disable-next-line lib.uv
      if timer and not timer:is_closing() then
        ---@diagnostic disable-next-line lib.uv
        pcall(function()
          ---@diagnostic disable-next-line lib.uv
          timer:stop()
          ---@diagnostic disable-next-line lib.uv
          timer:close()
        end)
      end
      if callback then
        callback(buf, win)
      end
      -- not continuing to next client because we found something
    end

    -- Start trying providers for client
    try_client_providers(client, params, providers, { mode = mode, callback = wrapped_cb })

    -- If request chain completes without producing preview, timer will fire and next_client() runs.
  end

  next_client()
end

return M
