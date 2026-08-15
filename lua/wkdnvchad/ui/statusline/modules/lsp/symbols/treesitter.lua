---@module 'wkdnvchad.ui.statusline.modules.lsp.symbols.treesitter'
--- Breadcrumb of the treesitter node context around the cursor (function/
--- class/block names), the fallback the statusline's symbol module reaches
--- for when no LSP is attached to supply the same thing.

local M = {}

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

return M
