---@module 'ui.stl_modules.lsp_based'
--- LSP-first breadcrumbs for NvChad statusline (async + cached), with Treesitter fallback.

---   local mod = require('ui.stl_modules.lsp_based')
---   local band = mod.mode_band_group()
---   return mod.hl_open(band) .. mod.render_breadcrumbs_inherit_lspfirst(band)

--- ROADMAP:
--- Table einbinden

local fn, api = vim.fn, vim.api

local M = {}

---@type UI.Stl_Modules.LSP_Based.LspCfg
M.cfg = {
  debounce_ms = 250,
  update_events = { "BufEnter", "CursorHold", "CursorHoldI", "InsertLeave", "TextChanged", "LspAttach" },
  center_width_frac = 0.50, -- Anteil der Editorbreite, der dem Mittelteil als Ziel dient
  center_width_min = 20, -- Mindestbreite für den Mittelteil
  path_max_frac = 0.60, -- maximaler Anteil des Mittelteil-Ziels, der für den Pfad reserviert wird
  path_max_chars = 45, -- optional harte Obergrenze (Zeichen) NUR für den Pfad; nil = deaktiviert
  path_min_room = 30, -- unterhalb dieses Platzes kein komponentenweises Kürzen, sondern Fallback
  path_mode = "absolute", -- "auto"|"repo"|"cwd"|"absolute"|"home"
  path_home_tilde = true, -- show "~" for $HOME in absolute/home modes
}
---@diagnostic enable

local Paths = require("ui.stl_modules.lsp_based.paths")

--------------------------------------------------------------------------------
-- Statusline helpers
--------------------------------------------------------------------------------

---@nodiscard
---@param s string
---@return string
function M.stl_escape(s)
  return (s:gsub("%%", "%%%%"))
end

---@nodiscard
---@param s string
---@param max integer
---@return string
function M.ellipsize_middle(s, max)
  if #s <= max then
    return s
  end
  local head = math.floor((max - 1) / 2)
  local tail = max - head - 1
  return string.sub(s, 1, head) .. "…" .. string.sub(s, #s - tail + 1, #s)
end

---@nodiscard
---@param s string
---@return string
function M.stl_strip_hl(s)
  return (s:gsub("%%#.-#", ""):gsub("%%%*", ""))
end

---@nodiscard
---@param group string
---@return string
function M.hl_open(group)
  return "%#" .. group .. "#"
end

---@nodiscard
---@param group string
---@param s string
---@return string
function M.hl_wrap(group, s)
  if not s or s == "" then
    return ""
  end
  return "%#" .. group .. "#" .. s .. "%*"
end

---@nodiscard
---@return string
function M.mode_band_group()
  local utils = require("nvchad.stl.utils")
  local m = api.nvim_get_mode().mode
  local name = (utils.modes[m] and utils.modes[m][2]) or "Normal"
  return "St_" .. name .. "mode"
end

local function _display_path_for_buf(bufnr)
  return Paths.display_path({ path_mode = M.cfg.path_mode, path_home_tilde = M.cfg.path_home_tilde }, bufnr)
end

--------------------------------------------------------------------------------
-- Separators
--------------------------------------------------------------------------------

---@nodiscard
---@param hex string
---@return string
local function cp(hex)
  local n = tonumber(hex, 16)
  if not n then
    return ""
  end
  return fn.nr2char(n)
end

-- ---@nodiscard
-- ---@param hex string
-- ---@return string
-- local function nerd_sep_or_fallback(hex)
--   local g = cp(hex)
--   if g ~= "" and fn.strdisplaywidth(g) == 1 then
--     return " " .. g .. " "
--   end
--   return (vim.o.columns >= 100) and " ⟶ " or " › "
-- end

--------------------------------------------------------------------------------
-- Paths & devicons
--------------------------------------------------------------------------------

---@nodiscard
---@param path string
---@return string
function M.repo_relative(path)
  if path == "" then
    return "[No Name]"
  end
  local dir = fn.fnamemodify(path, ":h")
  local gitdir = (vim.fs.find(".git", { upward = true, path = dir }) or {})[1]
  if gitdir then
    local root = fn.fnamemodify(gitdir, ":h")
    local rel = fn.fnamemodify(path, (":~:%s"):format(root))
    if rel == path then
      return fn.fnamemodify(path, ":t")
    end
    rel = rel:gsub("^%./", ""):gsub("^/", "")
    return rel
  end
  return fn.fnamemodify(path, ":~:.")
end

---@nodiscard
---@param n integer|nil
---@return string|nil
local function int_to_hex(n)
  if type(n) ~= "number" then
    return nil
  end
  return string.format("#%06x", n)
end

---@nodiscard
---@return string|nil
local function mode_band_bg_hex()
  local group = M.mode_band_group()
  local hl = api.nvim_get_hl(0, { name = group, link = false }) or {}
  ---@diagnostic disable-next-line undefined-field
  return int_to_hex(hl.bg)
end

---@nodiscard
---@param fg string|nil
---@param band_bg string|nil
---@return string
local function ensure_icon_hl(fg, band_bg)
  ---@type WkdNvC.UI.Stl.Modules.Custom.FileIcon.HLCache
  M.__icon_hl = M.__icon_hl or { name = "St_FileIcon", fg = nil, bg = nil }
  if M.__icon_hl.fg ~= fg or M.__icon_hl.bg ~= band_bg then
    api.nvim_set_hl(0, M.__icon_hl.name, { fg = fg, bg = band_bg })
    M.__icon_hl.fg = fg
    M.__icon_hl.bg = band_bg
  end
  return M.__icon_hl.name
end

---@nodiscard
---@param path string
---@return string icon, string|nil color
local function devicon_for_path(path)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  local filename = (path == "" or path == nil) and "[No Name]" or fn.fnamemodify(path, ":t")
  local ext = filename:match("^.+%.(.+)$") or ""
  if not ok then
    return "󰈙", nil
  end
  local icon, color
  local ok_color = pcall(function()
    icon, color = devicons.get_icon_color(filename, ext, { default = true })
  end)
  if not ok_color or not icon then
    icon = devicons.get_icon(filename, ext, { default = true })
    if devicons.get_color then
      pcall(function()
        color = devicons.get_color(filename, ext, { default = true })
      end)
    end
  end
  if not icon or icon == "" then
    icon = "󰈙"
  end
  return icon, color
end

---@nodiscard
---@return string
function M.file_icon_segment()
  local utils = require("nvchad.stl.utils")
  local bufnr = utils.stbufnr()
  local path = api.nvim_buf_get_name(bufnr) or ""
  local icon, fg = devicon_for_path(path)
  local bg = mode_band_bg_hex()
  local group = ensure_icon_hl(fg, bg)
  return "%#" .. group .. "#" .. icon .. "%*"
end

---@nodiscard
---@param band_group string
---@return string
function M.file_icon_segment_inherit(band_group)
  local utils = require("nvchad.stl.utils")
  local bufnr = utils.stbufnr()
  local path = api.nvim_buf_get_name(bufnr) or ""
  local icon, fg = devicon_for_path(path)
  local bg = mode_band_bg_hex()
  local group = ensure_icon_hl(fg, bg)
  return "%#" .. group .. "#" .. icon .. "%#" .. band_group .. "#"
end

---@nodiscard
---@param path string                -- path to display (absolute or relative)
---@param max integer                -- maximum number of characters to use
---@return string                    -- compacted path that fits into `max`
function M.ellipsize_path_components(path, max)
  -- Fast path
  if max <= 0 or #path <= max then
    return path
  end

  -- Normalize separators for splitting, but remember a prefix we always keep:
  --  - Windows drive root like "C:\"
  --  - POSIX root "/"
  --  - Tilde home "~"
  local p = path
  p = p:gsub("\\", "/")

  local prefix = ""
  local rest = p

  do
    -- Normalize backslashes first (this already happens earlier in your function)
    p = p:gsub("\\", "/")

    -- Windows drive root (normalized): "C:/"
    local drive = rest:match("^([A-Za-z]:)/")
    if drive then
      prefix = drive .. "/"
      -- drop the leading "C:/"
      rest = rest:sub(#drive + 2) -- 2 = length(":/") minus 1 due to 1-based indexing (+1 done by sub())
    elseif rest:sub(1, 2) == "~/" then
      prefix = "~"
      rest = rest:sub(3)
    elseif rest:sub(1, 1) == "/" then
      prefix = "/"
      rest = rest:sub(2)
    else
      prefix = "" -- relative path
    end
    if drive then
      prefix = drive .. "/"
      rest = rest:sub(#drive + 2) -- skip "C:" + separator
    elseif rest:sub(1, 2) == "~/" then
      prefix = "~"
      rest = rest:sub(3)
    elseif rest:sub(1, 1) == "/" then
      prefix = "/"
      rest = rest:sub(2)
    else
      prefix = "" -- relative path
    end
  end

  -- Split remaining into components (ignore empty)
  ---@type string[]
  local parts = {}
  for seg in rest:gmatch("[^/]+") do
    parts[#parts + 1] = seg
  end

  -- Reconstitute quickly if still fits
  local function join_all()
    if #parts == 0 then
      return prefix
    end
    return prefix .. table.concat(parts, "/")
  end
  local full = join_all()
  if #full <= max then
    return full
  end

  -- If there are fewer than 2 components, there is nothing to drop safely.
  -- Fall back to middle ellipsis (filename can be long; directories rule does not apply here).
  if #parts <= 1 then
    return M.ellipsize_middle(full, max)
  end

  -- Always try to keep: prefix + first-dir + "…/" + last
  local first = parts[1]
  local last = parts[#parts]

  local function build_min()
    return prefix .. first .. "/…/" .. last
  end

  local min_s = build_min()
  if #min_s > max then
    -- If even that doesn't fit, drop the first directory but keep the prefix if present.
    -- Example: "/…/filename" or "C:/…/filename".
    local alt = (prefix ~= "" and (prefix .. "…/" .. last)) or ("…/" .. last)
    if #alt <= max then
      return alt
    end
    -- As an absolute last resort, ellipsize the whole string.
    return M.ellipsize_middle(full, max)
  end

  -- Greedily add more components from the RIGHT (towards the beginning),
  -- while respecting the maximum length.
  -- Result shape: prefix + first + "/…/" + [extra_right_segments/] + last
  local right = {} ---@type string[]
  local cur = #min_s
  local i = #parts - 1
  while i >= 2 do
    local cand_len = cur + 1 + #parts[i] -- + "/" + segment length
    if cand_len > max then
      break
    end
    table.insert(right, 1, parts[i]) -- prepend so order stays natural
    cur = cand_len
    i = i - 1
  end

  if #right == 0 then
    return min_s
  end

  return prefix .. first .. "/…/" .. table.concat(right, "/") .. "/" .. last
end

--- Build the visible line with component-aware path compaction.
--- If `total_maxw` is nil, it derives from cfg.center_width_frac/center_width_min.
---@param rel string
---@param ctx string|nil
---@param sep string
---@param total_maxw integer|nil
---@return string line
function M.compact_breadcrumb_line(rel, ctx, sep, total_maxw)
  local target = total_maxw
  if not target or target <= 0 then
    local frac = M.cfg.center_width_frac or 0.50
    local minw = M.cfg.center_width_min or 30
    target = math.max(minw, math.floor(vim.o.columns * frac))
  end

  if ctx and #ctx > 0 then
    local static_len = #sep + #ctx
    local room = target - static_len
    if M.cfg.path_max_chars then
      room = math.min(room, M.cfg.path_max_chars)
    else
      local pfrac = M.cfg.path_max_frac or 0.60
      room = math.min(room, math.floor(target * pfrac))
    end

    if room > (M.cfg.path_min_room or 8) then
      local rel_compact = M.ellipsize_path_components(rel, room)
      local candidate = rel_compact .. sep .. ctx
      if #candidate <= target then
        return candidate
      else
        return M.ellipsize_middle(candidate, target)
      end
    else
      return M.ellipsize_middle(rel .. sep .. ctx, target)
    end
  else
    -- Kein Kontext: nur Pfad kürzen
    local limit = M.cfg.path_max_chars or target
    local compact = M.ellipsize_path_components(rel, limit)
    if #compact > target then
      compact = M.ellipsize_middle(compact, target)
    end
    return compact
  end
end

--------------------------------------------------------------------------------
-- Treesitter context (robuster Fallback)
--------------------------------------------------------------------------------

---@nodiscard
---@return string|nil
function M.symbol_context_ts()
  -- Guard: Treesitter & ts_utils müssen verfügbar sein
  local ok_ts = pcall(require, "vim.treesitter")
  local ok_utils, tsu = pcall(require, "nvim-treesitter.ts_utils")
  if not ok_ts or not ok_utils or not tsu then
    return nil
  end

  -- Cursor-Knoten holen
  local node = tsu.get_node_at_cursor()
  if not node then
    return nil
  end

  -- Knoten-Typen, die man als "semantische Anker" behalten möchte (breiter gefasst)
  local keep = {
    -- Funktionen/Methoden/Klassen/Namespaces (bisher)
    function_declaration = true,
    function_definition = true,
    method_declaration = true,
    method_definition = true,
    class_declaration = true,
    class_specifier = true,
    struct_specifier = true,
    interface_declaration = true,
    module_declaration = true,
    namespace_definition = true,
    impl_item = true,

    -- Neu: häufige Container/Member/Calls in diversen Grammatiken
    variable_declaration = true, -- JS/TS/C-ähnlich
    lexical_declaration = true, -- JS/TS (let/const)
    local_declaration = true, -- Lua (local ...)
    variable_declarator = true, -- JS/TS/C-ähnlich
    init_declarator = true, -- C/C++
    assignment_statement = true, -- Lua/C-ähnlich
    declaration = true, -- generisch

    member_expression = true, -- JS/TS
    field_expression = true, -- Lua (a.b)
    dot_index_expression = true, -- Lua (a.b)
    method_index_expression = true, -- Lua (a:b)
    index_expression = true, -- Lua/JS (a[b])

    property_declaration = true, -- TS/Java/C#
    field_declaration = true, -- C/C++/Rust
    property_signature = true, -- TS interface

    call_expression = true, -- viele Sprachen
    function_call = true, -- Lua
  }

  --- Extract a useful identifier from a node:
  --- 1) Feld "name", 2) flache Suche nach Identifier-Knoten,
  --- 3) Zeilenbasierte Heuristik (inkl. Member-Ketten a.b.c[:method]())
  ---@param n TSNode
  ---@return string|nil
  local function ts_identifier_of(n)
    -- 1) Direktes, benanntes Feld
    local named = n:field("name")
    if named and named[1] then
      local t = vim.treesitter.get_node_text(named[1], 0)
      if t and #t > 0 then
        return t
      end
    end

    -- 2) Flache Suche nach gängigen Identifier-Knotentypen
    local want = {
      "identifier",
      "property_identifier",
      "field_identifier",
      "type_identifier",
      "name",
      "shorthand_property_identifier",
      "variable_name",
    }
    local function in_list(x)
      for _, w in ipairs(want) do
        if x == w then
          return true
        end
      end
      return false
    end
    local function first_ident(m, depth)
      depth = depth or 0
      if depth > 2 or not m then
        return nil
      end
      if in_list(m:type()) then
        local t = vim.treesitter.get_node_text(m, 0)
        if t and #t > 0 then
          return t
        end
      end
      for i = 0, m:child_count() - 1 do
        local r = first_ident(m:child(i), depth + 1)
        if r then
          return r
        end
      end
      return nil
    end
    local t2 = first_ident(n, 0)
    if t2 and #t2 > 0 then
      return t2
    end

    -- 3) Zeilen-/Text-Heuristik (Member-Ketten und Call-Signaturen)
    local raw = vim.treesitter.get_node_text(n, 0) or ""
    -- Whitespace entfernen, auf die letzte Kette nahe Cursor zielen
    local s = raw:gsub("%s+", "")
    -- Kandidaten: foo.bar.baz  |  obj:method  |  foo["bar"].baz
    local chain = s:match("([%w_%.:]+)%s*$") or s:match("([%w_]+%b[][%w_%.%[%]]*)%s*$")
    if chain and #chain > 0 then
      -- Klammern am Ende entfernen, damit "method()" → "method" (später optional "()" anfügen)
      chain = chain:gsub("%(%s*%)$", "")
      return chain
    end

    -- Generische Fallbacks
    local guess = raw:match("^%w+%s+([%w_]+)%s*%(")
      or raw:match("^%w+%s+([%w_]+)%s*[={:]")
      or raw:match("^([%w_%.:]+)%s*%(")
      or raw:match("^([%w_%.:]+)")
    return guess
  end

  -- Namen sammeln (von außen nach innen prependen)
  ---@type string[]
  local names = {}
  local u = node
  while u do
    local t = u:type()

    if keep[t] then
      local ident = ts_identifier_of(u)

      -- Bei Member-Ausdrücken lieber nur den rechten Teil der Kette zeigen (z. B. "enable_line")
      -- Optional: gesamten Pfad zeigen, wenn gewünscht:
      -- ident = ident and ident:gsub("^.+[%.:]", "") or ident
      if ident and #ident > 0 then
        -- Funktions-/Methoden-Knoten optisch als Aufruf darstellen
        if t:find("function") or t:find("method") or t:find("call") then
          if not ident:find("%)$") then
            ident = ident .. "()"
          end
        end
        table.insert(names, 1, ident)
      end
    end

    local p = u:parent()
    if not p or p == u then
      break
    end
    u = p
  end

  if #names == 0 then
    return nil
  end
  return table.concat(names, " → ")
end

--------------------------------------------------------------------------------
-- LSP documentSymbol context (async cache)
--------------------------------------------------------------------------------

---@enum LspSymbolKind
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

---@class LspDocSymCache
---@field version integer
---@field items table[]|nil
---@field hierarchical boolean
---@field client_id integer|nil
---@field last_req number
---@field pending boolean

---@type table<integer, LspDocSymCache>
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
    -- Statusline neu zeichnen, außerhalb fast-event
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

  -- Anfrage an alle passenden Clients; erste erfolgreiche Antwort genügt.
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
  local now = vim.uv.now()
  local cache = M.__lsp_doc_cache[bufnr]
  local tick = current_tick(bufnr)
  if cache and cache.version == tick then
    return
  end
  if cache and cache.pending then
    return
  end
  if cache and (now - (cache.last_req or 0) < (M.cfg.debounce_ms or 250)) then
    return
  end
  request_doc_symbols_async(bufnr)
end

do
  if not rawget(M, "__au_lsp_breadcrumbs") then
    local aug = api.nvim_create_augroup("LspBreadcrumbsAsync", { clear = true })
    for _, ev in ipairs(M.cfg.update_events) do
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
  -- Niemals im Renderpfad synchron anfragen: nur Cache lesen.
  local items, hierarchical = get_cached_doc_symbols(bufnr)
  if not items then
    -- Hintergrundwärmung auslösen und sofort zurück (TS/fallback übernimmt)
    ensure_doc_symbols_in_bg(bufnr)
    return nil
  end

  local cur = api.nvim_win_get_cursor(0) -- 1-based
  local l0, c0 = cur[1] - 1, cur[2]
  local keep_kinds = DEFAULT_KEEP_KINDS

  local path_syms ---@type table[]
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
  local names = {} ---@type string[]
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
  local ok2, ctx2 = pcall(M.symbol_context_ts)
  if ok2 and ctx2 and #ctx2 > 0 then
    return ctx2
  end
  return nil
end

--------------------------------------------------------------------------------
-- Renderers (LSP-first, async-safe)
--------------------------------------------------------------------------------

local SEP_HEX = "f0058"

function M.render_breadcrumbs_lspfirst()
  local utils = require("nvchad.stl.utils")
  local bufnr = utils.stbufnr()
  local rel = _display_path_for_buf(bufnr)
  local ctx = M.symbol_context_smart()
  local icon = M.file_icon_segment()
  local sep = (function()
    return (
      " "
      .. (cp(SEP_HEX) ~= "" and fn.strdisplaywidth(cp(SEP_HEX)) == 1 and cp(SEP_HEX) or ((vim.o.columns >= 100) and "⟶" or "›"))
      .. " "
    )
  end)()

  local line = M.compact_breadcrumb_line(rel, ctx, sep, nil)
  line = M.stl_escape(line)
  return icon .. " " .. line .. "%*"
end

function M.render_breadcrumbs_inherit_lspfirst(band_group)
  local utils = require("nvchad.stl.utils")
  local bufnr = utils.stbufnr()
  local rel = _display_path_for_buf(bufnr)
  local ctx = M.symbol_context_smart()
  local icon = M.file_icon_segment_inherit(band_group)
  local sep = (function()
    return (
      " "
      .. (cp(SEP_HEX) ~= "" and fn.strdisplaywidth(cp(SEP_HEX)) == 1 and cp(SEP_HEX) or ((vim.o.columns >= 100) and "⟶" or "›"))
      .. " "
    )
  end)()

  local line = M.compact_breadcrumb_line(rel, ctx, sep, nil)
  line = M.stl_escape(line)
  return icon .. " " .. line -- wichtig: keine %* hier (inherit)
end

return M
