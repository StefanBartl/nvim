---@module 'wkdnvchad.ui.statusline.modules.lsp.symbols.document_symbols'

local M = {}

-- Lazy-load config to avoid circular dependency
local options

local function get_options()
  if not options then
    options = require("wkdnvchad.ui.statusline.modules.lsp.config").get_cfg()
  end
  return options
end

local api = vim.api

--------------------------------------------------------------------------------
-- LSP documentSymbol context (async cache)
--------------------------------------------------------------------------------

---@enum WkdNvC.UI.Status.Modules.Lsp.Symbols.Kind
local LspKind = {
  File = 1,
  Module = 2,
  Namespace = 3,
  Package = 4,
  Class = 5,
  Method = 6,
  Property = 7,
  Field = 8,
  Constructor = 9,
  Enum = 10,
  Interface = 11,
  Function = 12,
  Variable = 13,
  Constant = 14,
  String = 15,
  Number = 16,
  Boolean = 17,
  Array = 18,
  Object = 19,
  Key = 20,
  Null = 21,
  EnumMember = 22,
  Struct = 23,
  Event = 24,
  Operator = 25,
  TypeParameter = 26,
}

---@type integer[]
local DEFAULT_KEEP_KINDS = {
  LspKind.Namespace,
  LspKind.Module,
  LspKind.Class,
  LspKind.Struct,
  LspKind.Interface,
  LspKind.Enum,
  LspKind.Function,
  LspKind.Method,
  LspKind.Constructor,
  LspKind.Property,
  LspKind.Field,
  LspKind.EnumMember,
}

---@type table<integer, WkdNvC.UI.Status.Modules.Lsp.Symbols.Doc.SymCache>
M.__lsp_doc_cache = M.__lsp_doc_cache or {}

---@nodiscard
---@param bufnr integer
---@return integer
local function current_tick(bufnr)
  return (vim.b[bufnr] and vim.b[bufnr].changedtick) or vim.b.changedtick or 0
end

---@nodiscard
---@param range table
---@param l integer
---@param c integer
---@return boolean
local function range_contains(range, l, c)
  if not range or not range.start or not range["end"] then
    return false
  end
  local sL, sC = range.start.line, range.start.character
  local eL, eC = range["end"].line, range["end"].character
  if l < sL or (l == sL and c < sC) then
    return false
  end
  if l > eL or (l == eL and c > eC) then
    return false
  end
  return true
end

---@nodiscard
---@param sym table
---@return string
local function symbol_display_name(sym)
  local name = sym.name or ""
  if sym.detail and #sym.detail > 0 then
    local short = sym.detail:match("([%w_%.:]+)%s*%(") or sym.detail:match("([%w_%.:]+)$")
    if short and #short > 0 and #short < (#name + 3) then
      name = short
    end
  end
  return name
end

---@nodiscard
---@param kind integer
---@param name string
---@return string
local function maybe_callish(kind, name)
  if (kind == LspKind.Function) or (kind == LspKind.Method) or (kind == LspKind.Constructor) then
    if not name:find("%)$") then
      return name .. "()"
    end
  end
  return name
end

---@param bufnr integer
local function request_doc_symbols_async(bufnr)
  if not api.nvim_buf_is_loaded(bufnr) then
    return
  end

  local lsp = vim.lsp
  local params = vim.lsp.util.make_text_document_params(bufnr)
  local cache = M.__lsp_doc_cache[bufnr]
    or { version = -1, items = nil, hierarchical = false, client_id = nil, last_req = 0, pending = false }

  if cache.pending then
    return
  end

  cache.pending = true
  M.__lsp_doc_cache[bufnr] = cache

  local function on_result(err, result, ctx)
    cache.pending = false
    cache.last_req = vim.uv.now()
    if err or not result then
      return
    end
    local hierarchical = (result[1] and result[1].range ~= nil)
    cache.items = result
    cache.hierarchical = hierarchical
    cache.client_id = ctx and ctx.client_id or nil
    cache.version = current_tick(bufnr)

    local function redraw()
      pcall(function()
        vim.cmd("redrawstatus")
      end)
    end

    if vim.in_fast_event() then
      vim.schedule(redraw)
    else
      redraw()
    end
  end

  local requested = false
  for _, client in ipairs(lsp.get_clients({ bufnr = bufnr })) do
    local caps = client.server_capabilities or {}
    if caps.documentSymbolProvider then
      requested = true
      lsp.buf_request(bufnr, "textDocument/documentSymbol", params, on_result)
      break
    end
  end

  if not requested then
    cache.items, cache.hierarchical, cache.client_id = nil, false, nil
  end
end

---@param bufnr integer
local function ensure_doc_symbols_in_bg(bufnr)
  local opts = get_options()
  local now = vim.uv.now()
  local cache = M.__lsp_doc_cache[bufnr]
  local tick = current_tick(bufnr)

  if cache and cache.version == tick then
    return
  end
  if cache and cache.pending then
    return
  end
  if cache and (now - (cache.last_req or 0) < (opts.debounce_ms or 250)) then
    return
  end

  request_doc_symbols_async(bufnr)
end

-- Auto-update setup
do
  if not rawget(M, "__au_lsp_breadcrumbs") then
    local opts = get_options()
    local aug = api.nvim_create_augroup("LspBreadcrumbsAsync", { clear = true })
    for _, ev in ipairs(opts.update_events) do
      api.nvim_create_autocmd(ev, {
        group = aug,
        callback = function(args)
          local bufnr = args.buf or 0
          if bufnr <= 0 then
            bufnr = api.nvim_get_current_buf()
          end
          ensure_doc_symbols_in_bg(bufnr)
        end,
        desc = "Warm LSP documentSymbol cache for breadcrumbs",
      })
    end
    M.__au_lsp_breadcrumbs = true
  end
end

---@nodiscard
---@param bufnr integer
---@return table[]|nil items, boolean hierarchical
local function get_cached_doc_symbols(bufnr)
  local cache = M.__lsp_doc_cache[bufnr]
  if cache and cache.items and cache.version == current_tick(bufnr) then
    return cache.items, cache.hierarchical
  end
  return nil, false
end

---@nodiscard
---@return string|nil
function M.symbol_context_lsp()
  local utils = require("nvchad.stl.utils")
  local bufnr = utils.stbufnr()
  local items, hierarchical = get_cached_doc_symbols(bufnr)

  if not items then
    ensure_doc_symbols_in_bg(bufnr)
    return nil
  end

  local cur = api.nvim_win_get_cursor(0)
  local l0, c0 = cur[1] - 1, cur[2]
  local keep_kinds = DEFAULT_KEEP_KINDS

  local path_syms
  if hierarchical then
    local function locate_in_hierarchical(list, l, c)
      local best_path = {}
      local function walk(nodes, path)
        for _, sym in ipairs(nodes) do
          if sym.range and range_contains(sym.range, l, c) then
            local this = {}
            for i = 1, #path do
              this[i] = path[i]
            end
            table.insert(this, sym)
            if sym.children and #sym.children > 0 then
              walk(sym.children, this)
            else
              best_path = this
            end
          end
        end
      end
      walk(list, {})
      if #best_path == 0 then
        return {}
      end
      local filtered = {}
      for _, s in ipairs(best_path) do
        for _, k in ipairs(keep_kinds) do
          if (s.kind or 0) == k then
            table.insert(filtered, s)
            break
          end
        end
      end
      return filtered
    end
    path_syms = locate_in_hierarchical(items, l0, c0)
  else
    local function locate_in_flat(infos, l, c)
      local best, best_span
      for _, si in ipairs(infos) do
        local loc = si.location
        local range = loc and loc.range
        if range and range_contains(range, l, c) then
          local sL, sC = range.start.line, range.start.character
          local eL, eC = range["end"].line, range["end"].character
          local span = (eL - sL) * 10000 + (eC - sC)
          if not best or span < best_span then
            best, best_span = si, span
          end
        end
      end
      if not best then
        return {}
      end
      local ok = false
      for _, k in ipairs(keep_kinds) do
        if (best.kind or 0) == k then
          ok = true
          break
        end
      end
      if not ok then
        return {}
      end
      return { best }
    end
    path_syms = locate_in_flat(items, l0, c0)
  end

  if #path_syms == 0 then
    return nil
  end

  local names = {}
  for _, s in ipairs(path_syms) do
    local name = symbol_display_name(s)
    name = maybe_callish(s.kind or 0, name)
    table.insert(names, name)
  end

  return (#names > 0) and table.concat(names, " → ") or nil
end

---@nodiscard
---@return string|nil
function M.symbol_context_smart()
  local ok1, ctx1 = pcall(M.symbol_context_lsp)
  if ok1 and ctx1 and #ctx1 > 0 then
    return ctx1
  end

  local ts_ok, ts_module = pcall(require, "wkdnvchad.ui.statusline.modules.lsp.symbols.treesitter")
  if ts_ok then
    local ok2, ctx2 = pcall(ts_module.symbol_context_ts)
    if ok2 and ctx2 and #ctx2 > 0 then
      return ctx2
    end
  end

  return nil
end

return M
