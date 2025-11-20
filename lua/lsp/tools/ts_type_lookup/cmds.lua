---@module 'lsp.tools.ts_type_lookup.cmds'
--- Utilities and usercommands to lookup TypeScript type definitions by symbol string.
--- Commands accept an optional argument; when omitted the current word (`<cword>`) is used.
local api = vim.api
local lsp = vim.lsp
local fn = vim.fn
local M = {}

--- Helper: get workspace root via active LSP client or fallback to cwd
---@return string
local function get_root()
  local bufnr = api.nvim_get_current_buf()
  local clients = lsp.get_clients({ bufnr = bufnr })
  for _, c in ipairs(clients) do
    local cfg = c.config
    if cfg then
      if cfg.root_dir and type(cfg.root_dir) == "string" then
        return cfg.root_dir
      end
      if cfg.workspace_folders and cfg.workspace_folders[1] and cfg.workspace_folders[1].uri then
        return vim.uri_to_fname(cfg.workspace_folders[1].uri)
      end
    end
  end
  return fn.getcwd()
end

--- Request LSP workspace/symbol for given query
---@param bufnr number
---@param query string
---@param cb function
local function workspace_symbol(bufnr, query, cb)
  local params = { query = query }
  lsp.buf_request(bufnr, "workspace/symbol", params, function(err, result)
    if err then
      cb(nil, err)
      return
    end
    if not result or vim.tbl_isempty(result) then
      cb(nil, "no results")
      return
    end
    cb(result, nil)
  end)
end

--- Normalize Location or LocationLink -> fname, srow, scol, erow, ecol
---@param item table
---@return string, number, number, number, number
local function loc_to_path_range(item)
  local uri = item.uri or item.targetUri or (item.location and (item.location.uri or item.location.targetUri))
  local range = item.range or item.targetSelectionRange or item.targetRange or (item.location and item.location.range)
  local fname = uri and vim.uri_to_fname(uri) or nil
  local srow = (range and range.start and range.start.line or 0) + 1
  local scol = (range and range.start and range.start.character or 0) + 1
  local erow = (range and range["end"] and range["end"].line or 0) + 1
  local ecol = (range and range["end"] and range["end"].character or 0) + 1
  return fname, srow, scol, erow, ecol
end

--- Open a file in vertical split at given line
---@param fname string
---@param line number
local function open_in_vsplit(fname, line)
  if not fname then
    return
  end
  vim.cmd("vsplit " .. fn.fnameescape(fname))
  if line and line > 0 then
    vim.cmd(tostring(line))
  end
end

--- Public: try to go to a type definition for `symbol` using workspace/symbol then open found location
---@param symbol string
function M.go_to_type_definition_for(symbol)
  symbol = symbol ~= nil and symbol ~= "" and symbol or fn.expand("<cword>")
  local bufnr = api.nvim_get_current_buf()
  local clients = lsp.get_clients({ bufnr = bufnr })
  if not clients or vim.tbl_isempty(clients) then
    vim.notify("No active LSP client", vim.log.levels.WARN)
    return
  end

  workspace_symbol(bufnr, symbol, function(results, _)
    if not results then
      -- fallback: search in node_modules
      require("lsp.tools.ts_type_lookup.cmds").find_in_node_modules(symbol)
      return
    end
    -- Prefer the first result with a location
    for _, r in ipairs(results) do
      local loc = r.location or r
      if loc then
        local fname, srow = loc_to_path_range(loc)
        if fname then
          open_in_vsplit(fname, srow)
          return
        end
      end
    end
    -- fallback if nothing worked
    require("lsp.tools.ts_type_lookup.cmds").find_in_node_modules(symbol)
  end)
end

--- Public: peek type definition for symbol string (floating preview); default to <cword>
---@param symbol string|nil
function M.peek_type_definition_for(symbol)
  symbol = symbol ~= nil and symbol ~= "" and symbol or fn.expand("<cword>")
  local bufnr = api.nvim_get_current_buf()
  workspace_symbol(bufnr, symbol, function(results, _)
    if not results then
      vim.notify("No workspace symbol found for: " .. symbol, vim.log.levels.INFO)
      require("lsp.tools.ts_type_lookup.cmds").find_in_node_modules(symbol)
      return
    end
    local r = results[1]
    local loc = r.location or r
    if not loc then
      vim.notify("No location in workspace symbol result", vim.log.levels.WARN)
      return
    end
    local fname, srow, _, erow = loc_to_path_range(loc)
    if not fname then
      return
    end
    local ok, content = pcall(fn.readfile, fname)
    if not ok or not content then
      vim.notify("Could not read " .. fname, vim.log.levels.WARN)
      return
    end
    local start_line = math.max(1, srow - 2)
    local end_line = math.min(#content, erow + 2)
    local lines = {}
    table.insert(
      lines,
      ("[peek] %s:%d  — press 'o' to open in split, 'q' to close"):format(fn.fnamemodify(fname, ":."), srow)
    )
    for i = start_line, end_line do
      table.insert(lines, content[i])
    end
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local width = math.min(120, math.max(60, math.floor(vim.o.columns * 0.6)))
    local height = math.min(20, #lines)
    local opts = {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "rounded",
    }
    api.nvim_open_win(buf, true, opts)
    -- map 'o' in preview to open actual location in vsplit
    api.nvim_buf_set_keymap(
      buf,
      "n",
      "o",
      ("<cmd>lua require('tools.ts_type_lookup_cmds')._open_loc_in_split(%q,%d)<CR>"):format(fname, srow),
      { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { nowait = true, noremap = true, silent = true })
  end)
end

--- Internal helper used by preview mapping
---@param fname string
---@param line number
function M._open_loc_in_split(fname, line)
  open_in_vsplit(fname, line)
end

--- Fallback: ripgrep in node_modules; opens first match in vsplit
---@param symbol string|nil
function M.find_in_node_modules(symbol)
  symbol = symbol or fn.expand("<cword>")
  local cwd = get_root()
  local node_dir = cwd .. "/node_modules"
  if fn.isdirectory(node_dir) == 0 then
    vim.notify("No node_modules in project root: " .. cwd, vim.log.levels.WARN)
    return
  end
  if fn.executable("rg") == 1 then
    local cmd = { "rg", "--no-ignore", "-n", "--hidden", "-S", symbol, node_dir }
    local result = fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 or vim.tbl_isempty(result) then
      vim.notify("No results for '" .. symbol .. "' in node_modules", vim.log.levels.INFO)
      return
    end
    local first = result[1]
    local path, lnum = first:match("^([^:]+):(%d+):")
    if not path then
      vim.notify("Could not parse rg result", vim.log.levels.ERROR)
      return
    end
    local safe_lnum = tonumber(lnum)
    if safe_lnum ~= nil then
      open_in_vsplit(path, safe_lnum)
    end
  else
    vim.notify("ripgrep (rg) not found; install rg or rely on LSP", vim.log.levels.WARN)
  end
end

--- Setup convenience usercommands with optional argument (default: <cword>)
function M.attach()
  api.nvim_create_user_command("TypeDefGoTo", function(opts)
    local sym = opts.args ~= "" and opts.args or fn.expand("<cword>")
    M.go_to_type_definition_for(sym)
  end, { nargs = "?", desc = "Go to type definition for symbol string (vsplit). Defaults to <cword>." })

  api.nvim_create_user_command("TypeDefPeek", function(opts)
    local sym = opts.args ~= "" and opts.args or fn.expand("<cword>")
    M.peek_type_definition_for(sym)
  end, { nargs = "?", desc = "Peek type definition for symbol string (floating). Defaults to <cword>." })

  api.nvim_create_user_command("TypeDefFindInNodeModules", function(opts)
    local sym = opts.args ~= "" and opts.args or fn.expand("<cword>")
    M.find_in_node_modules(sym)
  end, { nargs = "?", desc = "Search symbol in node_modules (rg fallback). Defaults to <cword>." })
end

return M
