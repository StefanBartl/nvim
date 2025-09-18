---@module 'custom.last_file.last_session'
--- Manual last-session file saving and restoring system.
--- Saves and restores the last opened file including cursor position.
--- After restore, it ensures LSP attach without using the deprecated lspconfig manager.try_add().
--- Uses Neovim ≥ 0.11 native LSP APIs (vim.lsp.config / vim.lsp.start).

---@class LastSessionModule
local M = {}

---@type string
local session_file = vim.fn.stdpath("data") .. "/last_file.txt"

--- Save current buffer path and cursor position to the session file.
---@return nil
function M.save()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)

  -- Only persist real, listed file buffers
  if path == "" or vim.fn.filereadable(path) ~= 1 then
    return
  end
  local bt = vim.bo[buf].buftype
  if bt ~= "" or not vim.bo[buf].buflisted then
    return
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local line, col = pos[1], pos[2]

  local ok, f = pcall(io.open, session_file, "w")
  if not ok or not f then
    vim.notify("[last_session] Failed to write session file", vim.log.levels.ERROR)
    return
  end

  f:write(path .. "\n")
  f:write(line .. " " .. col .. "\n")
  f:close()
end

--- Internal: robustly ensure LSP is attached to bufnr using native APIs.
--- Strategy:
---   1) If a client is already attached -> return.
---   2) Re-fire FileType autocmds to let vim.lsp.enable()-based setups start normally.
---   3) If still no client:
---        * Derive target servers from filetype (Lua/TypeScript/Go focus).
---        * For each server name:
---            - Use vim.lsp.config[NAME] if present (preferred).
---            - Compute root_dir from cfg.root_dir() or via cfg.root_markers / ".git".
---            - Start/reuse client with vim.lsp.start(...).
---@param bufnr integer
---@return nil
local function ensure_lsp(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- 1) Already attached?
  if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
    return
  end

  -- 2) Nudge regular FileType-based LSP starters
  local ft = vim.bo[bufnr].filetype
  if type(ft) == "string" and ft ~= "" then
    pcall(vim.api.nvim_exec_autocmds, "FileType", { buffer = bufnr })
  end

  -- If that was enough, bail out
  if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
    return
  end

  -- 3) Manual attach per target language set (focus on Lua / TS / Go)
  ---@type table<string, string[]>
  local default_servers_for_ft = {
    lua = { "lua_ls" },
    typescript = { "ts_ls" }, javascript = { "ts_ls" },
    typescriptreact = { "ts_ls" }, javascriptreact = { "ts_ls" }, tsx = { "ts_ls" },
    go = { "gopls" }, gomod = { "gopls" }, gosum = { "gopls" },
  }

  -- Optional user override: a global mapping { [ft] = { "serverA", "serverB" } }
  -- If provided, it takes precedence over defaults.
  local user_map = rawget(vim.g, "last_session_lsp_servers")
  local server_names = (type(user_map) == "table" and user_map[ft])
    or default_servers_for_ft[ft]
    or {}

  if #server_names == 0 then
    return
  end

  -- Resolve root_dir via config or via root_markers/.git
  local function resolve_root(cfg)
    -- Prefer explicit root_dir(...) function if present (compatible with many configs)
    if type(cfg.root_dir) == "function" then
      local ok, root = pcall(cfg.root_dir, vim.api.nvim_buf_get_name(bufnr))
      if ok and type(root) == "string" and root ~= "" then
        return root
      end
    end
    -- Otherwise use root_markers if provided, else fallback to ".git"
    local markers = (type(cfg.root_markers) == "table" and cfg.root_markers) or { ".git" }
    local root = vim.fs.root(bufnr, markers)
    return root or vim.loop.cwd()
  end

  for _, name in ipairs(server_names) do
    -- Pull a configured server table if available (recommended with vim.lsp.config('name', {...}))
    local cfg = (type(vim.lsp.config) == "table") and vim.lsp.config[name] or nil

    -- If there is no config registered for this name, skip to avoid guessing cmd/opts.
    if type(cfg) == "table" then
      -- Guard filetypes if specified in the config
      if not cfg.filetypes or vim.tbl_contains(cfg.filetypes, ft) then
        local root_dir = resolve_root(cfg)
        local start_cfg = vim.tbl_deep_extend("force", {}, cfg, { name = name, root_dir = root_dir })
        -- Start or reuse client for this root/name; attaches current buffer on success
        pcall(vim.lsp.start, start_cfg)
      end
    end
  end
end

--- Restore the last saved file and cursor position and trigger LSP attach natively.
---@return nil
function M.restore()
  local ok, f = pcall(io.open, session_file, "r")
  if not ok or not f then
    vim.notify("[last_session] No saved file found", vim.log.levels.WARN)
    return
  end

  local path = f:read("*l")
  local pos_line = f:read("*l")
  f:close()

  if not path or vim.fn.filereadable(path) ~= 1 then
    vim.notify("[last_session] Saved file no longer exists: " .. (path or "<empty>"), vim.log.levels.WARN)
    return
  end

  local line, col = 1, 0
  if pos_line then
    local l, c = pos_line:match("^(%d+)%s+(%d+)$")
    line = tonumber(l) or 1
    col = tonumber(c) or 0
  end

  -- Open the file (triggers BufRead/BufWinEnter autocommands)
  vim.cmd("edit " .. vim.fn.fnameescape(path))

  -- Defer cursor placement and LSP attach to ensure the window is ready
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_win_set_cursor, 0, { line, col })

    -- Ensure filetype detection has run
    vim.cmd("filetype detect")

    -- Ensure LSP without lspconfig/manager.try_add
    ensure_lsp(bufnr)
  end)

  -- Optional: clear after successful restore to make it a one-shot
  M.clear()
end

--- Delete the session file if it exists.
---@return nil
function M.clear()
  if vim.fn.filereadable(session_file) == 1 then
    os.remove(session_file)
  end
end

--- Check whether a last session file exists and is valid.
---@return boolean
function M.has_saved_session()
  local f = io.open(session_file, "r")
  if not f then
    return false
  end
  local path = f:read("*l")
  f:close()
  return path and vim.fn.filereadable(path) == 1 or false
end

return M
