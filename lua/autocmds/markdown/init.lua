---@module 'autocmds.markdown'
--- Markdown-focused autocommands with feature flags.
--- Features:
---   1) Buffer-local keymap to wrap the <cword> as a Markdown link: [word]()
---   2) Smarter Markdown "gf": follow inline/reference links, resolve relative paths, open URLs via system opener
--- Each feature installs its own augroup and can be toggled independently via `require('autocmds.markdown').enable(cfg)`.

---@class MdAutoCmds
local M = {}

local api = vim.api

-- Helpers ---------------------------------------------------------------------

--- Create/clear a namespaced augroup.
---@param name string
---@return integer
local function augroup(name)
  return api.nvim_create_augroup("markdown_autocmds_" .. name, { clear = true })
end

--- Normalize a FileType autocmd pattern field.
---@param pat any
---@return string|string[]
local function norm_pattern(pat)
  if pat == nil then
    return "markdown"
  end
  return pat
end

--- Return text of a Treesitter node (safe).
---@param node TSNode
---@param bufnr integer
---@return string|nil
local function ts_text(node, bufnr)
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  return ok and text or nil
end

--- In-place "open URL" via system opener (macOS/Linux by default).
---@param url string
---@param cfg MdAutoCmdsGotoFileCfg
---@return boolean opened
local function open_url(url, cfg)
  local opener ---@type string[]|nil

  if vim.fn.has("macunix") == 1 then
    opener = cfg.open_cmd_mac or { "open", url }
  elseif vim.fn.has("unix") == 1 then
    opener = cfg.open_cmd_unix or { "xdg-open", url }
  elseif cfg.enable_windows_opener and vim.fn.has("win32") == 1 then
    opener = { "cmd.exe", "/c", "start", "", url }
  end

  if not opener then
    return false
  end
  -- Replace placeholder if custom arrays were provided like {"open", "<url>"}.
  for i, v in ipairs(opener) do
    if v == "<url>" then
      opener[i] = url
    end
  end
  vim.fn.jobstart(opener, { detach = true })
  return true
end

--- Quick predicate: looks like a web/URI target.
---@param s string
---@return boolean
local function is_url_like(s)
  if s:match("^https?://") or s:match("^file://") then
    return true
  end
  if s:match("^www%.") then
    return true
  end
  if s:match("^[A-Za-z0-9%-_]+%.[A-Za-z]+") then
    return true
  end
  return false
end

-- Defaults --------------------------------------------------------------------

---@type MdAutoCmdsCfg
local Defaults = {
  wrap_key = {
    enable = true,
    key = "<leader>[",
    description = "Wrap current word in Markdown link syntax",
    pattern = "markdown",
    only_modifiable = true,
  },
  goto_file = {
    enable = true,
    debug = false,
    pattern = "markdown",
    enable_windows_opener = false, -- keep Linux/macOS default per project policy
    open_cmd_mac = nil, -- e.g., { "open", "<url>" }
    open_cmd_unix = nil, -- e.g., { "xdg-open", "<url>" }
  },
}

--------------------------------------------------------------------------------
-- Case functions for modular "gf" resolution
--------------------------------------------------------------------------------

--- Case 0: gopath resolver (new first case)
--- Tries to resolve using gopath. If it succeeds, it should open the target itself.
--- Returns true on success, false on failure.
---@param cfg table
---@return boolean
---@diagnostic disable-next-line unused-param
local function resolve_gopath_case(cfg)
  local ok, _ = pcall(function()
    return require("gopath").commands.resolve_and_open("edit")
  end)
  if not ok then
    return false
  end
  -- Assume success if the function does not error.
  return true
end

--- Case 1: Inline link [text](destination)
---@param node TSNode
---@param bufnr integer
---@param ts_utils table
---@param log fun(msg:string,val?:any)
---@return boolean,string|nil
local function resolve_inline_link_case(node, bufnr, ts_utils, log)
  ts_utils = ts_utils
  local function find_parent(n, types)
    while n and not vim.tbl_contains(types, n:type()) do
      n = n:parent()
    end
    return n
  end

  local dest = find_parent(node, { "link_destination" })
  if dest and dest:type() == "link_destination" then
    local path = ts_text(dest, bufnr)
    log("Inline link: ", path)
    return true, path
  end
  return false, nil
end

--- Case 2: Reference link [label] with definition [label]: dest
---@param node TSNode
---@param bufnr integer
---@param ts_utils table
---@param log fun(msg:string,val?:any)
---@return boolean,string|nil
local function resolve_reference_link_case(node, bufnr, ts_utils, log)
    ts_utils = ts_utils
  local function find_parent(n, types)
    while n and not vim.tbl_contains(types, n:type()) do
      n = n:parent()
    end
    return n
  end

  local ref = find_parent(node, { "link_reference" })
  if not ref then
    return false, nil
  end

  local label = ts_text(ref, bufnr) or ""
  label = label:gsub("^%[", ""):gsub("%]$", "")
  log("Reference label: ", label)

  local total = api.nvim_buf_line_count(bufnr)
  for lnum = 1, total do
    local line = api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
    if line then
      local pat = "^%[" .. vim.pesc(label) .. "%]%s*:%s*(.+)$"
      local m = line:match(pat)
      if m then
        log("Reference target: ", m)
        return true, m
      end
    end
  end

  return false, nil
end

--- Case 3: URL-like target
---@param path string
---@param cfg table
---@param log fun(msg:string,val?:any)
---@return boolean
local function resolve_url_case(path, cfg, log)
  if not is_url_like(path) then
    return false
  end

  if path:match("^www%.") or (not path:match("^%w[%w+.-]*:") and path:match("^[A-Za-z0-9%-_]+%.[A-Za-z]+")) then
    path = "http://" .. path
    log("HTTP auto-prefix: ", path)
  end

  if open_url(path, cfg.goto_file) then
    return true
  end

  return false
end

--- Case 4: Local filesystem path
---@param path string
---@param log fun(msg:string,val?:any)
---@return boolean
local function resolve_local_file_case(path, log)
  local cwd = vim.fn.expand("%:p:h")
  log("CWD: ", cwd)

  -- If relative path
  if not path:match("^/") and not path:match("^[A-Za-z]:[\\/]") then
    path = cwd .. "/" .. path
    log("Combined relative: ", path)
  end

  local target = vim.fn.fnamemodify(path, ":p")
  log("Absolute: ", target)

  vim.cmd("edit " .. vim.fn.fnameescape(target))
  return true
end

--------------------------------------------------------------------------------
-- Case dispatcher
--------------------------------------------------------------------------------

--- Try all gf-cases in sequence.
--- Returns true if any case succeeded; false otherwise.
---@param node TSNode|nil
---@param bufnr integer
---@param ts_utils table
---@param cfg table
---@return boolean
local function resolve_markdown_gf_cases(node, bufnr, ts_utils, cfg)
  local function log(msg, val)
    if cfg.goto_file.debug then
      vim.notify(msg .. (val ~= nil and tostring(val) or ""), vim.log.levels.INFO, { title = "markdown-gf" })
    end
  end

  -- Case 0: gopath
  if resolve_gopath_case(cfg) then
    return true
  end

  -- No node? Fallback immediately
  if not node then
    return false
  end

  -- Case 1: Inline link
  local ok_inline, path = resolve_inline_link_case(node, bufnr, ts_utils, log)
  if ok_inline and path then
    -- module conversion
    path = path:gsub("\\", "/")
    if path:match("^[%a_][%w_]*%.") then
      path = path:gsub("%.", "/") .. ".lua"
    end
    -- try URL case
    if resolve_url_case(path, cfg, log) then
      return true
    end
    -- fallback to file
    return resolve_local_file_case(path, log)
  end

  -- Case 2: Reference link
  local ok_ref, ref_path = resolve_reference_link_case(node, bufnr, ts_utils, log)
  if ok_ref and ref_path then
    local path2 = ref_path:gsub("\\", "/")
    if path2:match("^[%a_][%w_]*%.") then
      path2 = path2:gsub("%.", "/") .. ".lua"
    end
    if resolve_url_case(path2, cfg, log) then
      return true
    end
    return resolve_local_file_case(path2, log)
  end

  return false
end

-- Public API ------------------------------------------------------------------

--- Enable Markdown-related autocommands per feature.
---@param cfg MdAutoCmdsCfg|nil
---@return nil
function M.enable(cfg)
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), cfg or {})

  -- 1) Buffer-local wrap mapping ---------------------------------------------
  -- Description: Registers a buffer-local normal-mode mapping to wrap <cword> as [word]()
  if cfg.wrap_key.enable then
    api.nvim_create_autocmd("FileType", {
      group = augroup("wrap_key"),
      pattern = norm_pattern(cfg.wrap_key.pattern),
      callback = function()
        ---@type integer
        local buf = api.nvim_get_current_buf()
        if cfg.wrap_key.only_modifiable ~= false and not vim.bo[buf].modifiable then
          vim.notify("Markdown wrap: buffer is not modifiable", vim.log.levels.WARN)
          return
        end

        ---@type string
        local key = cfg.wrap_key.key
        ---@type string
        local description = cfg.wrap_key.description

        ---@type fun(): nil
        local handler = function()
          -- Guard: still in markdown?
          if vim.bo.filetype ~= "markdown" then
            return
          end
          ---@type string
          local word = vim.fn.expand("<cword>")
          if not word or word == "" then
            return
          end
          ---@type integer, integer
          local row, col = unpack(api.nvim_win_get_cursor(0))

          -- Atomic textual change via change-inner-word motion.
          vim.cmd("normal! ciw[" .. word .. "]()")

          -- Place cursor inside parentheses: [word](|)
          local new_col = col + 2 + #word + 1
          api.nvim_win_set_cursor(0, { row, new_col })
        end

        vim.keymap.set("n", key, handler, {
          desc = description,
          buffer = buf,
          noremap = true,
          silent = true,
        })
      end,
      desc = "Markdown: buffer-local keymap to wrap <cword> as [word]()",
    })
  end

  -- 2) Markdown-aware gf override --------------------------------------------
  -- Description: Overrides "gf" to call "gopath", than follow inline/reference links or open URLs; falls back to default "gf" when unresolved.
  if cfg.goto_file.enable then
    api.nvim_create_autocmd("FileType", {
      group = augroup("goto_file"),
      pattern = norm_pattern(cfg.goto_file.pattern),
      callback = function()
        -- require TS only once
        local ok_ts = pcall(require, "nvim-treesitter.ts_utils")
        if not ok_ts then
          return
        end
        local ts_utils = require("nvim-treesitter.ts_utils")

        vim.keymap.set("n", "gf", function()
          local node = ts_utils.get_node_at_cursor()
          local bufnr = api.nvim_get_current_buf()

          -- Try all cases
          local success = resolve_markdown_gf_cases(node, bufnr, ts_utils, cfg)

          -- If nothing matched → fallback to builtin gf
          if not success then
            vim.cmd("normal! gf")
          end
        end, { buffer = true, desc = "Markdown-aware gf with modular resolver" })
      end,
    })
  end
end

return M
