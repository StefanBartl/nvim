---@module 'autocmds.markdown'
--- Markdown-focused autocommands with feature flags.
--- Features:
---   1) Buffer-local keymap to wrap the <cword> as a Markdown link: [word]()
---   2) Smarter Markdown "gf": follow inline/reference links, resolve relative paths, open URLs via system opener
--- Each feature installs its own augroup and can be toggled independently via `require('autocmds.markdown').enable(cfg)`.

---@class MdAutoCmds
local M = {}

-- Helpers ---------------------------------------------------------------------

--- Create/clear a namespaced augroup.
---@param name string
---@return integer
local function augroup(name)
  return vim.api.nvim_create_augroup("markdown_autocmds_" .. name, { clear = true })
end

--- Normalize a FileType autocmd pattern field.
---@param pat any
---@return string|string[]
local function norm_pattern(pat)
  if pat == nil then return "markdown" end
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
  if s:match("^https?://") or s:match("^file://") then return true end
  if s:match("^www%.") then return true end
  if s:match("^[A-Za-z0-9%-_]+%.[A-Za-z]+") then return true end
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
    open_cmd_mac = nil,            -- e.g., { "open", "<url>" }
    open_cmd_unix = nil,           -- e.g., { "xdg-open", "<url>" }
  },
}

-- Public API ------------------------------------------------------------------

--- Enable Markdown-related autocommands per feature.
---@param cfg MdAutoCmdsCfg|nil
---@return nil
function M.enable(cfg)
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), cfg or {})

  -- 1) Buffer-local wrap mapping ---------------------------------------------
  -- Description: Registers a buffer-local normal-mode mapping to wrap <cword> as [word]()
  if cfg.wrap_key.enable then
    vim.api.nvim_create_autocmd("FileType", {
      group = augroup("wrap_key"),
      pattern = norm_pattern(cfg.wrap_key.pattern),
      callback = function()
        ---@type integer
        local buf = vim.api.nvim_get_current_buf()
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
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))

          -- Atomic textual change via change-inner-word motion.
          vim.cmd("normal! ciw[" .. word .. "]()")

          -- Place cursor inside parentheses: [word](|)
          local new_col = col + 2 + #word + 1
          vim.api.nvim_win_set_cursor(0, { row, new_col })
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
  -- Description: Overrides "gf" to follow inline/reference links or open URLs; falls back to default "gf" when unresolved.
  if cfg.goto_file.enable then
    vim.api.nvim_create_autocmd("FileType", {
      group = augroup("goto_file"),
      pattern = norm_pattern(cfg.goto_file.pattern),
      callback = function()
        -- Validate Treesitter availability; otherwise, keep default behavior.
        local ok_ts = pcall(require, "nvim-treesitter.ts_utils")
        if not ok_ts then
          return
        end
        local ts_utils = require("nvim-treesitter.ts_utils")

        vim.keymap.set("n", "gf", function()
          local node = ts_utils.get_node_at_cursor()
          if not node then
            return vim.cmd("normal! gf")
          end

          local bufnr = vim.api.nvim_get_current_buf()
          local path ---@type string|nil

          local function log(msg, val)
            if cfg.goto_file.debug then
              local text = msg .. (val ~= nil and tostring(val) or "")
              vim.notify(text, vim.log.levels.INFO, { title = "markdown-gf" })
            end
          end

          -- Walk up to a parent node of given types.
          ---@param n TSNode|nil
          ---@param types string[]
          ---@return TSNode|nil
          local function find_parent(n, types)
            while n and not vim.tbl_contains(types, n:type()) do
              n = n:parent()
            end
            return n
          end

          -- Case 1: Inline link [text](dest)
          do
            local dest = find_parent(node, { "link_destination" })
            if dest and dest:type() == "link_destination" then
              path = ts_text(dest, bufnr)
              log("Inline link: ", path)
            end
          end

          -- Case 2: Reference link [label] with definition [label]: dest
          if not path then
            local ref = find_parent(node, { "link_reference" })
            if ref then
              local label = ts_text(ref, bufnr) or ""
              label = label:gsub("^%[", ""):gsub("%]$", "")
              log("Reference label: ", label)
              local line_count = vim.api.nvim_buf_line_count(bufnr)
              for lnum = 1, line_count do
                local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
                local pat = "^%[" .. vim.pesc(label) .. "%]%s*:%s*(.+)$"
                local m = line and line:match(pat) or nil
                if m then
                  path = m
                  log("Reference target: ", path)
                  break
                end
              end
            end
          end

          if not path or path == "" then
            return vim.cmd("normal! gf")
          end

          -- Normalize slashes (portable)
          path = path:gsub("\\", "/")
          log("Normalized: ", path)

          -- Case 3: URL-like target
          if is_url_like(path) then
            if path:match("^www%.") or (not path:match("^%w[%w+.-]*:") and path:match("^[A-Za-z0-9%-_]+%.[A-Za-z]+")) then
              path = "http://" .. path
              log("HTTP auto-prefix: ", path)
            end
            if open_url(path, cfg.goto_file) then
              return
            end
          end

          -- Case 4: Local file (relative to current buffer)
          local cwd = vim.fn.expand("%:p:h")
          log("CWD: ", cwd)

          if not path:match("^/") and not path:match("^[A-Za-z]:[\\/]") then
            path = cwd .. "/" .. path
            log("Combined relative: ", path)
          end

          local target = vim.fn.fnamemodify(path, ":p")
          log("Absolute: ", target)

          vim.cmd("edit " .. vim.fn.fnameescape(target))
        end, { buffer = true, desc = "Markdown-aware gf (TS+URLs+fallback)" })
      end,
      desc = "Markdown: override gf to follow links/URLs with fallback",
    })
  end
end

return M
