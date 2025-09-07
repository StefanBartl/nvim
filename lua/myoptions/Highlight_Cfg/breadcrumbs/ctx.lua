---@module 'myoptions.Highlight_Cfg.breadcrumbs.ctx'
--- Breadcrumb-Kontext-Ermittlung für die Winbar.
--- Modular aufgebaute Provider-Pipeline:
---   1) LSP-Funktionsname (b:lsp_current_function)
---   2) Tree-sitter Symbolkette (Class → method())
---   3) Container/Owner-Kette als Präfix (z. B. obj.nested → obj)
---   4) Sprachspezifische Fallbacks (Owner in Literalen, Klassenname, …)
---   5) Wort-Fallback (<cword>)
--- Reihenfolge und Verhalten sind über cfg.breadcrumbs_ctx toggel-/konfigurierbar.

local C   = require("myoptions.config")
local cfg = C.cfg.highlight

--------------------------------------------------------------------------------
-- Generic TS helpers
--------------------------------------------------------------------------------

--- Safe text of TS node.
---@param n TSNode|nil
---@return string
local function _txt(n)
	if not n then return "" end
	local ok, s = pcall(vim.treesitter.get_node_text, n, 0)
	return ok and (s or "") or ""
end

--- Ancestor test by set of node types.
---@param node TSNode|nil
---@param set table<string, boolean>
---@return TSNode|nil
local function _ancestor_in(node, set)
	local u = node
	while u do
		if set[u:type()] then return u end
		local p = u:parent()
		if not p or p == u then break end
		u = p
	end
	return nil
end

--- Current TS node (nil-safe).
---@return TSNode|nil
local function _node_at_cursor()
	local ok_utils, tsu = pcall(require, "nvim-treesitter.ts_utils")
	if not ok_utils then return nil end
	return tsu.get_node_at_cursor()
end

--- Collapse consecutive duplicates in a string list.
---@param parts string[]
---@return string[]
local function _dedupe_consecutive(parts)
	local out, last = {}, nil
	for _, s in ipairs(parts) do
		if s ~= "" and s ~= last then
			out[#out + 1] = s; last = s
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- JS/TS literal helpers (owner aus Objekt-Literalen ermitteln)
--------------------------------------------------------------------------------

--- Detect literal-context (JS/TS object literal) around cursor.
---@param n TSNode|nil
---@return boolean
local function _is_js_literal_field(n)
	if not n then return false end
	local t = n:type()
	if t == "pair" or t == "property_identifier" or t == "shorthand_property_identifier" then
		return true
	end
	return _ancestor_in(n, { object = true }) ~= nil
end

--- Collect owner path inside JS/TS object literal:
--- builds "var.key1.key2" while ignoring the last key (current field) if present.
---@param n TSNode|nil
---@return string|nil
local function _collect_js_owner_from_literal(n)
	if not n then return nil end

	-- 1) Schlüsselkette nach oben durch 'pair'/'object' sammeln
	local keys = {}
	local u = n
	local last_key = nil
	for _ = 1, 20 do
		if not u then break end
		local t = u:type()
		if t == "pair" then
			local key = (u:field("key") or {})[1]
			if key then
				local k = _txt(key):gsub("^['\"]", ""):gsub("['\"]$", "")
				if k ~= "" then
					table.insert(keys, 1, k); last_key = last_key or k
				end
			end
		elseif t == "object" then
			-- weiter klettern
		end
		local p = u:parent()
		if not p or p == u then break end
		u = p
	end

	-- 2) Linke Variable der umgebenden Deklaration/Zuweisung finden
	local owner = nil
	local v = n
	for _ = 1, 20 do
		if not v then break end
		local t = v:type()
		if t == "variable_declarator" then
			local name = (v:field("name") or {})[1]
			if name then owner = _txt(name) end
			break
		elseif t == "assignment_expression" then
			local left = (v:field("left") or {})[1]
			if left then owner = _txt(left):gsub("%s+", ""):gsub("%=.*", "") end
			break
		end
		local p = v:parent(); if not p or p == v then break end; v = p
	end

	if not owner or owner == "" then return nil end
	if #keys == 0 then return owner end

	-- 3) Innersten Schlüssel (Cursor-Feld) verwerfen → Container
	local container = {}
	for i = 1, #keys - 1 do container[i] = keys[i] end
	if #container == 0 then return owner end
	return owner .. "." .. table.concat(container, ".")
end

--------------------------------------------------------------------------------
-- Lua table helpers (owner aus Tabellen-Konstruktoren ermitteln)
--------------------------------------------------------------------------------

--- Detect literal-context (Lua table constructor) around cursor.
---@param n TSNode|nil
---@return boolean
local function _is_lua_table_field(n)
	if not n then return false end
	local t = n:type()
	if t == "field" or t == "pair" then return true end
	return _ancestor_in(n, { table_constructor = true }) ~= nil
end

--- Collect owner from Lua table constructor:
--- builds "Var.key1.key2" while dropping the last key.
---@param n TSNode|nil
---@return string|nil
local function _collect_lua_owner_from_table(n)
	if not n then return nil end

	-- 1) Keys innerhalb verschachtelter table_constructor sammeln
	local keys = {}
	local u = n
	local found_field = false
	for _ = 1, 20 do
		if not u then break end
		local t = u:type()
		if t == "field" or t == "pair" then
			found_field = true
			local raw = _txt(u)
			local k = raw:match("^%s*([%a_][%w_]*)%s*=")      -- identifier =
					or raw:match("^%s*%[(['\"]?)(.-)%1%]%s*=")    -- ["key"] =
			if k and #k > 0 then table.insert(keys, 1, k) end
		elseif t == "table_constructor" then
			-- weiter klettern
		end
		local p = u:parent(); if not p or p == u then break end; u = p
	end

	-- 2) Linke Variable eines local/assignment finden
	local owner = nil
	local v = n
	for _ = 1, 20 do
		if not v then break end
		local t = v:type()
		if t == "local_statement" or t == "local_declaration" or t == "assignment" then
			local left = (v:field("left") or v:field("variables") or {})[1]
			if left then owner = _txt(left):gsub("%s+", "") end
			break
		end
		local p = v:parent(); if not p or p == v then break end; v = p
	end

	if not owner or owner == "" then return nil end
	if not found_field or #keys == 0 then return owner end

	local container = {}
	for i = 1, #keys - 1 do container[i] = keys[i] end
	if #container == 0 then return owner end
	return owner .. "." .. table.concat(container, ".")
end

--------------------------------------------------------------------------------
-- Provider Base Symbo
--------------------------------------------------------------------------------

--- Return a concise base token under the cursor (identifier/property/method name).
--- Falls back to <cword> if no structured node is recognized.
---@return string|nil
local function _ctx_base_token()
	local node = _node_at_cursor()
	if not node then
		local w = vim.fn.expand("<cword>")
		return (type(w) == "string" and #w >= 1) and w or nil
	end
	local ft = vim.bo.filetype
	local t  = node:type()

	-- Lua: table field keys, function names, identifier-like nodes
	if ft == "lua" then
		-- field = value   |  ["key"] = value
		if t == "field" or t == "pair" then
			local raw = _txt(node)
			local k = raw:match("^%s*([%a_][%w_]*)%s*=") or raw:match("^%s*%[(['\"]?)(.-)%1%]%s*=")
			if k and #k > 0 then return k end
		end
		if t == "function_declaration" or t == "function_definition" then
			local name = (node:field("name") or {})[1]
			if name then
				local full = _txt(name) -- e.g. "M.run" or "M:run"
				local base = full:match("[%.:](%w+)$") or full
				if base and #base > 0 then
					-- methods: add () so später klar ist, dass es callable ist
					return base .. "()"
				end
			end
		end
		-- plain identifiers
		if t == "identifier" or t == "name" then
			local s = _txt(node); if s ~= "" then return s end
		end
	end

	-- JS/TS: method/property identifiers, object-literal keys
	if ft == "javascript" or ft == "typescript" or ft == "javascriptreact" or ft == "typescriptreact" then
		if t == "method_definition" then
			local name = (node:field("name") or {})[1]
			local s = name and _txt(name) or nil
			if s and #s > 0 then return s .. "()" end
		end
		if t == "property_identifier" or t == "identifier" or t == "shorthand_property_identifier" then
			local s = _txt(node); if s ~= "" then return s end
		end
		if t == "pair" then
			local key = (node:field("key") or {})[1]
			if key then
				local k = _txt(key):gsub("^['\"]", ""):gsub("['\"]$", "")
				if k ~= "" then return k end
			end
		end
	end

	-- Python: def name, attribute tail, identifiers
	if ft == "python" then
		if t == "function_definition" then
			local name = (node:field("name") or {})[1]
			local s = name and _txt(name) or nil
			if s and #s > 0 then return s .. "()" end
		end
		if t == "attribute" then
			local full = _txt(node)
			local tail = full:match("%.([_%w]+)$")
			if tail and #tail > 0 then return tail end
		end
		if t == "identifier" then
			local s = _txt(node); if s ~= "" then return s end
		end
	end

	-- Go: method/function decl identifiers
	if ft == "go" then
		if t == "method_declaration" or t == "function_declaration" then
			local name = (node:field("name") or {})[1]
			local s = name and _txt(name) or nil
			if s and #s > 0 then return s .. "()" end
		end
		if t == "identifier" then
			local s = _txt(node); if s ~= "" then return s end
		end
	end

	-- Fallback
	local w = vim.fn.expand("<cword>")
	return (type(w) == "string" and #w >= 1) and w or nil
end

--------------------------------------------------------------------------------
-- Provider 1: LSP current function
--------------------------------------------------------------------------------

--- Provider: LSP current function (sehr günstig, wenn vorhanden).
---@return string|nil
local function _ctx_lsp_func()
	local bctx = cfg.breadcrumbs_ctx or {} ---@type MyOptionsBreadcrumbsCtx
	if not bctx.prefer_lsp_function then return nil end
	local s = vim.b.lsp_current_function
	if type(s) == "string" and #s > 0 then return s end
	return nil
end

--------------------------------------------------------------------------------
-- Provider 2: Tree-sitter Symbolpfad
--------------------------------------------------------------------------------

--- Extract a concise symbol path via TS (class → method()).
--- Returns nil if TS is not available or no meaningful symbol found.
---@return string|nil
local function _ctx_ts_symbol()
	local bctx = cfg.breadcrumbs_ctx or {} ---@type MyOptionsBreadcrumbsCtx
	if not bctx.use_treesitter_symbol then return nil end
	local ok_ts = pcall(require, "vim.treesitter"); if not ok_ts then return nil end
	local node = _node_at_cursor(); if not node then return nil end

	-- In Literalen/Memberzugriffen optional Owner statt Symbol bevorzugen
	if bctx.prefer_owner_in_literals then
		if _is_js_literal_field(node) or _is_lua_table_field(node) then
			return nil
		end
	end
	if bctx.prefer_owner_on_member_access then
		local t = node:type()
		if t == "member_expression" or t == "dot_index_expression" or t == "attribute" then
			return nil
		end
	end

	-- Semantische Container, die wir in der Kette behalten
	local keep = {
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
	}

	-- Bestmöglichen Identifier zu einem Node extrahieren
	local function ts_identifier_of(n)
		local named = n:field("name"); if named and named[1] then
			local t = _txt(named[1]); if t ~= "" then return t end
		end
		local want = { identifier = true, property_identifier = true, field_identifier = true, type_identifier = true, name = true }
		local function first_ident(m, depth)
			depth = depth or 0
			if depth > 2 then return nil end
			if want[m:type()] then
				local t = _txt(m); if t ~= "" then return t end
			end
			local cnt = m:child_count()
			for i = 0, cnt - 1 do
				local r = first_ident(m:child(i), depth + 1)
				if r then return r end
			end
			return nil
		end
		local t = first_ident(n, 0); if t and #t > 0 then return t end
		local raw = (_txt(n):gsub("^%s+", ""):gsub("\n.*", ""))
		local guess = raw:match("^%w+%s+([%w_]+)%s*%(")
				or raw:match("^%w+%s+([%w_]+)%s*[={:]")
				or raw:match("^([%w_%.:]+)%s*%(")
				or raw:match("^([%w_%.:]+)")
		return guess
	end

	local names = {}
	local u = node
	while u do
		local t = u:type()
		if keep[t] then
			local ident = ts_identifier_of(u)
			if ident and #ident > 0 then
				if t:find("function") or t:find("method") then
					if not ident:find("%)$") then ident = ident:gsub("%s+$", "") .. "()" end
				end
				table.insert(names, 1, ident)
			end
		end
		local p = u:parent(); if not p or p == u then break end
		u = p
	end
	if #names == 0 then return nil end
	return table.concat(names, " → ")
end

--------------------------------------------------------------------------------
-- Provider 3: Container/Owner-Kette als Präfix
--------------------------------------------------------------------------------

--- Try to derive a container/owner chain and prefix it to the symbol.
--- Honors cfg.breadcrumbs_ctx.container_max_depth and container_join.
---@param base_symbol string|nil
---@return string|nil
local function _ctx_with_container(base_symbol)
	-- AUDIT:
	-- Optional: Container-Provider auch ohne Symbol nutzbar machen (falls gewünscht), indem er – bei base_symbol == nil – auf _ctx_base_token() zurückfällt. Das ist nicht zwingend, weil (2) den häufigen Fall bereits sauber abdeckt; falls man es mag, so:
	local bctx = cfg.breadcrumbs_ctx or {} ---@type MyOptionsBreadcrumbsCtx
	if not bctx.use_container_chain then return base_symbol end
	base_symbol = base_symbol or _ctx_base_token()
-- anstelle von:
	-- if not base_symbol then return nil end
	-- local bctx = cfg.breadcrumbs_ctx or {} ---@type MyOptionsBreadcrumbsCtx
	-- if not bctx.use_container_chain then return base_symbol end
	--- End

	local ft   = vim.bo.filetype
	local join = bctx.container_join or "."
	local maxd = tonumber(bctx.container_max_depth or 2) or 2

	---@type TSNode|nil
	local node = _node_at_cursor()
	if not node then return base_symbol end

	local chain = {}
	local function push_front(s) if s and s ~= "" then table.insert(chain, 1, s) end end

	local steps = 0
	---@type TSNode|nil
	local u = node
	while u and steps < 12 and #chain < maxd do
		---@cast u TSNode
		local t = u:type()

		if ft == "lua" then
			if t == "function_declaration" or t == "function_definition" then
				local name = (u:field("name") or {})[1]
				if name then
					local full = _txt(name)                    -- "M.run"
					local c = full:match("^(.*)[%.:][^%.:]+$") -- "M"
					if c and #c > 0 then push_front(c) end
				end
			elseif t == "dot_index_expression" or t == "method_index_expression" or t == "index_expression" then
				local full = _txt(u) -- "obj.field" / "obj:method"
				local c = full:match("^(.*)[%.:][^%.:]+$")
				if c and #c > 0 then push_front(c) end
			elseif t == "field" or t == "pair" or t == "table_constructor" then
				local owner = _collect_lua_owner_from_table(u)
				if owner then push_front(owner) end
			end
		elseif ft == "javascript" or ft == "typescript" or ft == "javascriptreact" or ft == "typescriptreact" then
			if t == "class_declaration" then
				local name = (u:field("name") or {})[1]; if name then push_front(_txt(name)) end
			elseif t == "method_definition" or t == "public_field_definition" then
				local cls = _ancestor_in(u, { class_declaration = true })
				if cls then
					local name = (cls:field("name") or {})[1]; if name then push_front(_txt(name)) end
				end
			elseif t == "member_expression" or t == "object" or t == "pair" then
				local owner = _collect_js_owner_from_literal(u)
				if not owner and t == "member_expression" then
					local full = _txt(u)
					owner = full:match("^(.-)%.[_%w%$]+%s*$")
				end
				if owner and owner ~= "" then push_front(owner) end
			end
		elseif ft == "python" then
			if t == "class_definition" then
				local name = (u:field("name") or {})[1]; if name then push_front(_txt(name)) end
			elseif t == "function_definition" then
				local cls = _ancestor_in(u, { class_definition = true })
				if cls then
					local name = (cls:field("name") or {})[1]; if name then push_front(_txt(name)) end
				end
			elseif t == "attribute" then
				local full = _txt(u)
				local c = full:match("^(.-)%.[_%w]+$")
				if c and #c > 0 then push_front(c) end
			end
		elseif ft == "go" then
			if t == "method_declaration" then
				local recv = (u:field("receiver") or {})[1]
				local raw  = _txt(recv)
				local typ  = raw:match("%*?([A-Za-z_][A-Za-z0-9_]*)")
				if typ and #typ > 0 then push_front(typ) end
			end
		end

		local parent = u:parent()
		if not parent or parent == u then break end
		u = parent
		steps = steps + 1
	end

	if #chain == 0 then return base_symbol end
	if bctx.dedupe_containers then chain = _dedupe_consecutive(chain) end

	-- Wenn base_symbol bereits mit derselben Kette beginnt, nicht erneut voranstellen
	local prefix = table.concat(chain, join)
	local esc = vim.pesc(prefix .. join)
	if base_symbol and base_symbol:match("^" .. esc) then
		return base_symbol
	end

	return prefix .. join .. base_symbol
end

--------------------------------------------------------------------------------
-- Provider 4: Sprachspezifische Fallbacks
--------------------------------------------------------------------------------

--- Try to produce a context even if there is no proper symbol.
--- Useful fallback like "M" (Lua table), "api.client" (Owner), "Class" (um Methode).
---@return string|nil
local function _ctx_lang_extra()
	local bctx = cfg.breadcrumbs_ctx or {} ---@type MyOptionsBreadcrumbsCtx
	if not bctx.use_lang_specific then return nil end
	local node = _node_at_cursor(); if not node then return nil end
	local ft = vim.bo.filetype

	if ft == "lua" then
		local owner = _collect_lua_owner_from_table(node)
		if owner then return owner end
		local t = node:type()
		if t == "dot_index_expression" or t == "method_index_expression" or t == "index_expression" then
			local full = _txt(node)
			local o = full:match("^(.*)[%.:][^%.:]+$")
			if o and #o > 0 then return o end
		end
	elseif ft == "javascript" or ft == "typescript" or ft == "javascriptreact" or ft == "typescriptreact" then
		local owner = _collect_js_owner_from_literal(node)
		if owner then return owner end
		if node:type() == "member_expression" then
			local full = _txt(node)
			local o = full:match("^(.-)%.[_%w%$]+%s*$")
			if o and #o > 0 then return o end
		end
	elseif ft == "python" then
		if node:type() == "attribute" then
			local full = _txt(node)
			local o = full:match("^(.-)%.[_%w]+$")
			if o and #o > 0 then return o end
		end
		local cls = _ancestor_in(node, { class_definition = true })
		if cls then
			local name = (cls:field("name") or {})[1]
			if name then return _txt(name) end
		end
	elseif ft == "go" then
		if node:type() == "method_declaration" then
			local recv = (node:field("receiver") or {})[1]
			local raw  = _txt(recv)
			local typ  = raw:match("%*?([A-Za-z_][A-Za-z0-9_]*)")
			if typ and #typ > 0 then return typ end
		end
	end

	return nil
end

--------------------------------------------------------------------------------
-- Provider 5: Wort-Fallback
--------------------------------------------------------------------------------

---@return string|nil
local function _ctx_word_fallback()
	local bctx = cfg.breadcrumbs_ctx
	if not (bctx and bctx.fallback_word_when_empty) then return nil end
	if vim.fn.mode():find("i") then return nil end
	local w = vim.fn.expand("<cword>")
	if type(w) == "string" and #w >= 2 then return w end
	return nil
end

--------------------------------------------------------------------------------
-- Kontext orchestrieren
--------------------------------------------------------------------------------

--- Compose context robustly:
---  * Prefer a structured TS symbol (class → method()), optionally container-prefixed
---  * Else combine owner/container with a base token under cursor
---  * Else just owner, else <cword>
---@return string|nil
local function _build_context()
	local bctx     = cfg.breadcrumbs_ctx or {} ---@type MyOptionsBreadcrumbsCtx
	local join     = bctx.container_join or "."
	local have_sym = _ctx_ts_symbol()  -- e.g. "User → fullName()" or just "fullName()"
	local base     = _ctx_base_token() -- e.g. "fullName()" oder "version"
	local owner    = _ctx_lang_extra() -- e.g. "User" oder "M" oder "api.client"

	-- 1) Structured symbol vorhanden → Containerkette präfixen (falls sinnvoll)
	if have_sym and have_sym ~= "" then
		local with_cont = _ctx_with_container(have_sym) or have_sym
		return with_cont
	end

	-- 2) Kein Symbol: Owner + Basistoken, z. B. "User.fullName()" bzw. "M.version"
	if owner and owner ~= "" and base and base ~= "" then
		-- Schutz gegen Duplikate: wenn base bereits mit owner beginnt, nicht doppeln
		local esc = vim.pesc(owner .. join)
		if not base:match("^" .. esc) then
			return owner .. join .. base
		end
		return base
	end

	-- 3) Nur Owner (z. B. Cursor auf Container, kein klarer Basistoken)
	if owner and owner ~= "" then
		return owner
	end

	-- 4) Letzte Rettung
	return _ctx_word_fallback()
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

local M = {
	_ctx_base_token = _ctx_base_token,
	_ctx_lsp_func       = _ctx_lsp_func,
	_ctx_ts_symbol      = _ctx_ts_symbol,
	_ctx_lang_extra     = _ctx_lang_extra,
	_ctx_with_container = _ctx_with_container,
	_ctx_word_fallback  = _ctx_word_fallback,
	_build_context      = _build_context,
}

return M
