---@module 'autocmds.general'
--- Centralized, toggleable autocmd suite with safe defaults and idempotent setup.
--- Each feature can be enabled/disabled via the `enable(cfg)` entry point.
--- Guards are included to avoid side effects in unsupported contexts.
local M = {}

-- Compatibility shim for libuv
local uv = vim.uv or vim.loop

-- Internal: create an augroup with `clear=true` to keep things idempotent.
---@param name string
---@return integer
local function augroup(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

-- Internal: detect whether we are inside Kitty (Linux/macOS).
-- The presence of KITTY_LISTEN_ON or TERM="xterm-kitty" is a strong signal.
---@return boolean
local function in_kitty()
  local env = vim.env
  return (env.KITTY_LISTEN_ON and #env.KITTY_LISTEN_ON > 0) or (env.TERM == "xterm-kitty")
end

-- Internal: run a Kitty remote control command safely and silently.
---@param padding integer
---@param margin integer
local function kitty_set_spacing(padding, margin)
  -- The `kitty @` RC client is part of Kitty installs; only run if we are in Kitty.
  if not in_kitty() then
    return
  end
  -- `silent !kitty @ set-spacing padding=<n> margin=<n>` will adjust spacing for the current OS window.
  -- Using `vim.cmd` to avoid job control complexity; it’s synchronous but negligible here.
  local cmd = string.format(":silent !kitty @ set-spacing padding=%d margin=%d", padding, margin)
  pcall(function() vim.cmd(cmd) end)
end

-- Defaults --------------------------------------------------------------------

---@type GeneralAutoCmdConfig
local Defaults = {
  group_name = "custom_autocmds",

  auto_mkdir = {
    enable = true,
    skip_remote = true,
    -- Matches e.g. "xx://", "ssh://", "http://", "file://", on both slash styles
    detect_remote_pattern = "^%w%w+:[\\/][\\/]",
  },

  kitty = {
    enable = false,         -- Disabled by default; only meaningful inside Kitty
    enter_padding = 0,
    enter_margin  = 0,
    leave_padding = 20,
    leave_margin  = 10,
  },

  nvdash = {
    enable = true,
    cmd = "Nvdash",
    is_listed_only = true,  -- Consider only listed buffers when deciding "last buffer"
  },

  cursorline = {
    enable = true,
    show_events = { "InsertLeave", "WinEnter" },
    hide_events = { "InsertEnter", "WinLeave" },
  },

  last_loc = {
    enable = true,
    exclude = { "gitcommit", "commit", "gitrebase" },
    mark = '"',
  },
}

-- Public API ------------------------------------------------------------------

--- Enable the configured set of autocmds. Safe to call multiple times; augroups are recreated.
--- One can disable individual features by setting `enable=false` in the corresponding section.
--- Example:
---   require("custom.autocmds").enable({
---     kitty = { enable = true, enter_padding = 0, enter_margin = 0, leave_padding = 16, leave_margin = 8 },
---     auto_mkdir = { enable = true },
---     nvdash = { enable = false },
---   })
---@param cfg GeneralAutoCmdConfig|nil
---@return nil
function M.enable(cfg)
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), cfg or {})

  -- 1) Auto-create directory on save (BufWritePre)
  if cfg.auto_mkdir.enable then
    local grp = augroup((cfg.group_name or "custom_autocmds") .. "_auto_mkdir")
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = grp,
      callback = function(event)
        -- Optional: skip URL-like or remote buffers (e.g., "ssh://host/path", "http://…")
        if cfg.auto_mkdir.skip_remote and event.match:match(cfg.auto_mkdir.detect_remote_pattern) then
          return
        end
        -- Resolve to a real path if possible; falls back to the raw buffer path.
        local file = (uv.fs_realpath and uv.fs_realpath(event.match)) or event.match
        -- Create the parent directory recursively ("p" flag).
        -- Uses Vim’s robust `mkdir()` which handles both Linux and macOS gracefully.
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
      end,
      desc = "Auto-create the parent directory before writing a file",
    })
  end

  -- 2) Kitty spacing tweaks on enter/leave (VimEnter, VimLeavePre)
  if cfg.kitty.enable then
    local grp = augroup((cfg.group_name or "custom_autocmds") .. "_kitty_spacing")
    vim.api.nvim_create_autocmd("VimEnter", {
      group = grp,
      callback = function()
        kitty_set_spacing(cfg.kitty.enter_padding, cfg.kitty.enter_margin)
      end,
      desc = "Kitty: reduce spacing for the current window on VimEnter",
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = grp,
      callback = function()
        kitty_set_spacing(cfg.kitty.leave_padding, cfg.kitty.leave_margin)
      end,
      desc = "Kitty: restore spacing for the current window on VimLeavePre",
    })
  end

  -- 3) Show dashboard when the last buffer is closed (BufDelete)
  if cfg.nvdash.enable then
    local grp = augroup((cfg.group_name or "custom_autocmds") .. "_nvdash")
    vim.api.nvim_create_autocmd("BufDelete", {
      group = grp,
      callback = function()
        -- Strategy:
        --   a) Determine the set of "tracked" buffers in the current tab (vim.t.bufs if available).
        --   b) Fall back to scanning all buffers and filtering by 'buflisted' if needed.
        local function listed_bufs()
          local ids = {}
          local function push(id)
            if vim.api.nvim_buf_is_valid(id) and vim.bo[id].buflisted then
              ids[#ids + 1] = id
            end
          end
          -- Prefer tab-local tracking if present (used by some UIs); otherwise scan all bufs.
          if type(vim.t.bufs) == "table" then
            for _, id in ipairs(vim.t.bufs) do push(id) end
          else
            for _, id in ipairs(vim.api.nvim_list_bufs()) do push(id) end
          end
          return ids
        end

        local ids = cfg.nvdash.is_listed_only and listed_bufs() or vim.api.nvim_list_bufs()
        -- Consider "last buffer" as: exactly one remaining and it is unnamed (no file).
        if #ids == 1 then
          local name = vim.api.nvim_buf_get_name(ids[1])
          if name == "" then
            -- Open the dashboard command silently; ignore errors if the command is absent.
            pcall(vim.cmd, cfg.nvdash.cmd)
          end
        end
      end,
      desc = "Open dashboard when the last listed buffer is closed",
    })
  end

  -- 4) Cursorline only in the active window
  if cfg.cursorline.enable then
    local grp_show = augroup((cfg.group_name or "custom_autocmds") .. "_cursorline_show")
    vim.api.nvim_create_autocmd(cfg.cursorline.show_events, {
      group = grp_show,
      callback = function(event)
        -- Only enable cursorline for "normal" buffers (empty buftype).
        if vim.bo[event.buf].buftype == "" then
          vim.opt_local.cursorline = true
        end
      end,
      desc = "Enable cursorline in the active window on relevant events",
    })

    local grp_hide = augroup((cfg.group_name or "custom_autocmds") .. "_cursorline_hide")
    vim.api.nvim_create_autocmd(cfg.cursorline.hide_events, {
      group = grp_hide,
      callback = function()
        vim.opt_local.cursorline = false
      end,
      desc = "Disable cursorline in inactive windows or insert mode",
    })
  end

  -- 5) Jump to last location when reopening a file (BufReadPost)
  if cfg.last_loc.enable then
    local grp = augroup((cfg.group_name or "custom_autocmds") .. "_last_loc")
    vim.api.nvim_create_autocmd("BufReadPost", {
      group = grp,
      callback = function(event)
        local buf = event.buf
        -- Skip specific filetypes (commit messages, rebase plans, etc.)
        if vim.tbl_contains(cfg.last_loc.exclude, vim.bo[buf].filetype) then
          return
        end
        -- Guard against running twice per buffer
        if vim.b[buf].__custom_last_loc_done then
          return
        end
        vim.b[buf].__custom_last_loc_done = true

        -- Retrieve the last-position mark (default: `"`).
        local mark = vim.api.nvim_buf_get_mark(buf, cfg.last_loc.mark)
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
          -- pcall to avoid throwing if the window is in a nonstandard state.
          pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
      end,
      desc = "Jump to the last cursor position on file open",
    })
  end
end

return M
