---@module 'custom.last_file'
--- Manual last-file session: save path+cursor and restore on demand or on startup.
--- One-file version that also registers user commands and auto-restore.
--- Migration note: no usage of `require('lspconfig')` anymore.
--- LSP attach is ensured using Neovim ≥ 0.11 native APIs (vim.lsp.config / vim.lsp.enable / vim.lsp.start).

---@class LastSessionModule
---@field save fun():nil                -- save current file + cursor to a small file
---@field restore fun():nil             -- restore file + cursor, re-attach LSP
---@field clear fun():nil               -- delete the small session file
---@field has_saved_session fun():boolean
---@version 1.1.0

local M = {}

-- Keep your user-facing command/keymap wiring (unchanged)
require("custom.last_file.commands")
require("custom.last_file.keymaps")

-- Path to small session file, e.g. ~/.local/share/nvim/last_file.txt
---@type string
local session_file = vim.fn.stdpath("data") .. "/last_file.txt"

--- Internal: compute a reasonable root_dir for a buffer using an LSP config table.
--- Priority:
---   1) cfg.root_dir(filename) if provided and returns a non-empty string
---   2) vim.fs.root(bufnr, cfg.root_markers or {".git"})
---   3) current working directory (last resort)
---@param bufnr integer
---@param cfg table
---@return string
local function _resolve_root(bufnr, cfg)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if type(cfg.root_dir) == "function" and filename ~= "" then
    local ok, root = pcall(cfg.root_dir, filename)
    if ok and type(root) == "string" and root ~= "" then
      return root
    end
  end
  local markers = (type(cfg.root_markers) == "table" and cfg.root_markers) or { ".git" }
  local root = vim.fs.root(bufnr, markers)
  if type(root) == "string" and root ~= "" then
    return root
  end
  return vim.loop.cwd()
end

--- Internal: return list of server names expected for a given filetype.
--- Focus on Lua / TypeScript / Go. Allow user override via `vim.g.last_session_lsp_servers[ft]`.
---@param ft string
---@return string[]
local function _servers_for_filetype(ft)
  ---@type table<string, string[]>
  local defaults = {
    lua = { "lua_ls" },
    typescript = { "ts_ls" },
    javascript = { "ts_ls" },
    typescriptreact = { "ts_ls" },
    javascriptreact = { "ts_ls" },
    tsx = { "ts_ls" },
    go = { "gopls" },
    gomod = { "gopls" },
    gosum = { "gopls" },
  }
  local override = rawget(vim.g, "last_session_lsp_servers")
  if type(override) == "table" and type(override[ft]) == "table" then
    return override[ft]
  end
  return defaults[ft] or {}
end

--- Save current buffer path and cursor position to the session file.
--- Skips special/unlisted/unnamed buffers for robustness.
---@return nil
function M.save()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or vim.fn.filereadable(path) ~= 1 then
    return
  end
  if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].buflisted then
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

--- Internal: (re)attach LSP using native Neovim APIs (no lspconfig managers).
--- Strategy:
---   1) If a client is already attached for bufnr → return.
---   2) Re-fire FileType autocmds (lets vim.lsp.enable()-based setups start).
---   3) If still no client → manually start expected servers for the filetype using vim.lsp.start().
---      The per-server config is taken from vim.lsp.config[NAME] if available.
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

  -- 2) Nudge normal FileType-based starters (if user used vim.lsp.enable(...) in setup)
  local ft = vim.bo[bufnr].filetype
  if type(ft) == "string" and ft ~= "" then
    pcall(vim.api.nvim_exec_autocmds, "FileType", { buffer = bufnr })
  end

  if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
    return
  end

  -- 3) Manual start for expected servers of this filetype
  local names = _servers_for_filetype(ft)
  if #names == 0 then
    return
  end

  -- `vim.lsp.config` stores named server configurations if the user set them up
  local registry = (type(vim.lsp.config) == "table") and vim.lsp.config or {}

  for i = 1, #names do
    local name = names[i]
    local cfg = registry[name]
    if type(cfg) == "table" then
      -- Honor cfg.filetypes if specified
      if (not cfg.filetypes) or vim.tbl_contains(cfg.filetypes, ft) then
        local start_cfg = vim.tbl_deep_extend("force", {}, cfg, {
          name = name,
          root_dir = _resolve_root(bufnr, cfg),
        })
        -- Start or reuse a client for (name, root_dir); this attaches current buffer on success
        pcall(vim.lsp.start, start_cfg)
      end
    end
  end
end

--- Restore the last saved file and cursor position, then ensure LSP attach.
--- Uses a scheduled callback so the target window exists when restoring the cursor.
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

  -- Open the file (triggers BufRead/BufWinEnter autocommands).
  vim.cmd("edit " .. vim.fn.fnameescape(path))

  -- After the window exists, set cursor and ensure LSP.
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_win_set_cursor, 0, { line, col })
    -- Make sure filetype detection has happened (usually :edit did this already).
    vim.cmd("filetype detect")
    ensure_lsp(bufnr)
  end)

  -- Optional: clear after successful restore so it's one-shot
  M.clear()
end

--- Delete the small session file.
---@return nil
function M.clear()
  if vim.fn.filereadable(session_file) == 1 then
    os.remove(session_file)
  end
end

--- Check whether the small session file exists and points to a readable file.
---@return boolean
function M.has_saved_session()
  local f = io.open(session_file, "r")
  if not f then
    return false
  end
  local path = f:read("*l")
  f:close()
  return path ~= nil and vim.fn.filereadable(path) == 1
end

return M
