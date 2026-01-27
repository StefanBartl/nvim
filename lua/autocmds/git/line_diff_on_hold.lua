---@module 'autocmds.git.line_diff_on_hold'
--- Mode-aware line-diff preview on CursorHold/CursorHoldI with stable scrolling
--- and strict mode filtering (re-check on render + ModeChanged invalidation).

---@class AutoCmds.Git.LineDiffOnHold
local M = {}

local api, fn = vim.api, vim.fn
local uv = vim.uv or vim.loop

-- Optional helpers (truncate/parse_blame_sha) with safe fallbacks
local ok_helpers, H = pcall(require, "autocmds.git.helpers")

---@param s string
---@param max_len integer
---@return string
local function truncate(s, max_len)
  if ok_helpers and H and H.truncate then
    return H.truncate(s, max_len)
  end
  if type(s) ~= "string" then
    return ""
  end
  local n = math.max(0, tonumber(max_len or 0) or 0)
  if #s <= n then
    return s
  end
  if n <= 2 then
    return s:sub(1, n)
  end
  return s:sub(1, n - 2) .. " …"
end

---@param first string|nil
---@return string|nil
local function parse_blame_sha(first)
  if ok_helpers and H and H.parse_blame_sha then
    return H.parse_blame_sha(first)
  end
  if type(first) ~= "string" or first == "" then
    return nil
  end
  local sha = first:match("^([0-9a-f]+)")
  if not sha then
    return nil
  end
  return (#sha >= 7 and #sha <= 40) and sha or nil
end

---@return integer
local function get_lnum()
  local pos = api.nvim_win_get_cursor(0)
  return pos[1]
end

---Normalize Neovim's mode string to one of "n"|"v"|"i".
---@return "n"|"v"|"i"|nil
local function normalize_mode()
  -- Using fn.mode(1) because it reports operator-pending/visual variants.
  local m = fn.mode(1)
  if m == "i" then
    return "i"
  end
  if m == "n" or m == "no" then
    return "n"
  end
  if m == "v" or m == "V" or m == "\022" then
    return "v"
  end
  return nil
end

---Check if a (set of) modes allows rendering right now.
---@param modes string|string[]|nil
---@return boolean
local function mode_allowed(modes)
  if modes == nil then
    -- Default: treat as Normal+Visual allowed (since CursorHold fires in both)
    return normalize_mode() ~= "i"
  end
  local want = {}
  if type(modes) == "string" then
    for c in modes:gmatch(".") do
      want[c] = true
    end
  else
    for _, c in ipairs(modes) do
      want[c] = true
    end
  end
  local cur = normalize_mode()
  return cur ~= nil and want[cur] == true
end

---@param git_cmd string
---@param file string
---@return boolean
local function is_tracked(git_cmd, file)
  local _ = fn.system(string.format([[%s ls-files --error-unmatch -- %s 2>/dev/null]], git_cmd, fn.fnameescape(file)))
  return vim.v.shell_error == 0
end

---@param git_cmd string
---@param file string
---@param lnum integer
---@return string|nil
local function get_previous_line(git_cmd, file, lnum)
  local blame =
    fn.systemlist(string.format([[%s blame -L %d,%d --porcelain -- %s]], git_cmd, lnum, lnum, fn.fnameescape(file)))
  if type(blame) ~= "table" or #blame == 0 then
    return nil
  end
  local sha = parse_blame_sha(blame[1])
  if not sha then
    return nil
  end
  local blob = fn.systemlist(string.format([[%s show %s:%s]], git_cmd, sha, fn.fnameescape(file)))
  if type(blob) ~= "table" or #blob == 0 or lnum > #blob then
    return nil
  end
  return blob[lnum]
end

---@param modes string|string[]|nil
---@param events_override string[]|nil
---@return string[]
local function effective_events(modes, events_override)
  if type(events_override) == "table" and #events_override > 0 then
    return events_override
  end
  local has_n, has_v, has_i = false, false, false
  if modes == nil then
    has_n, has_v = true, true
  elseif type(modes) == "string" then
    has_n = modes:find("n", 1, true) ~= nil
    has_v = modes:find("v", 1, true) ~= nil
    has_i = modes:find("i", 1, true) ~= nil
  else
    for _, c in ipairs(modes) do
      if c == "n" then
        has_n = true
      elseif c == "v" then
        has_v = true
      elseif c == "i" then
        has_i = true
      end
    end
  end
  local ev = {}
  if has_n or has_v then
    ev[#ev + 1] = "CursorHold"
  end
  if has_i then
    ev[#ev + 1] = "CursorHoldI"
  end
  if #ev == 0 then
    ev = { "CursorHold" }
  end
  return ev
end

---@param cfg AutoCmds.Git.LineDiffOnHoldCfg
---@param shared table
---@return nil
function M.enable(cfg, shared)
  if not (cfg and cfg.enable) then
    return
  end

  local prefer_inline = (cfg.prefer_inline ~= false)
  local restore_view = (cfg.restore_view ~= false)
  local throttle_ms = tonumber(cfg.throttle_ms or 800) or 800

  -- Per-window throttle and generation (to invalidate delayed runs on mode changes)
  local last_fire_ms_by_win = {}
  local gen_by_win = {}

  local function bump_gen(win)
    gen_by_win[win] = (gen_by_win[win] or 0) + 1
    return gen_by_win[win]
  end

  local events = effective_events(cfg.modes, cfg.events_override)

  api.nvim_create_autocmd(events, {
    group = shared.augroup("line_diff_on_hold"),
    callback = function()
      -- Early, cheap gate at event time
      if not mode_allowed(cfg.modes) then
        return
      end

      local win = api.nvim_get_current_win()
      local now_ms = math.floor((uv.hrtime() or 0) / 1e6)
      local last_ms = last_fire_ms_by_win[win] or 0
      if (now_ms - last_ms) < throttle_ms then
        return
      end
      last_fire_ms_by_win[win] = now_ms

      local buf = api.nvim_get_current_buf()
      if not shared.normal_buf_allowed(cfg.ignore_buftypes) then
        return
      end
      if cfg.require_clean_buffer and vim.bo[buf].modified then
        return
      end

      local git = cfg.git_cmd or "git"
      if not shared.in_git_repo(git) then
        return
      end

      local file = api.nvim_buf_get_name(buf)
      if file == "" then
        return
      end
      if cfg.only_tracked and not is_tracked(git, file) then
        return
      end

      -- Snapshot a generation token for this schedule
      local my_gen = bump_gen(win)

      local function run()
        -- Re-check mode right before any rendering (fixes delayed runs in wrong mode)
        if not mode_allowed(cfg.modes) then
          return
        end
        -- Invalidate stale scheduled runs (mode changed since schedule)
        if gen_by_win[win] ~= my_gen then
          return
        end

        shared.clear_line_diff(buf)

        -- Prefer gitsigns inline preview (guarded + stable viewport)
        if prefer_inline then
          local ok_gs, gs = pcall(require, "gitsigns")
          if ok_gs and gs.preview_hunk_inline then
            local view = fn.winsaveview()
            local cur = api.nvim_win_get_cursor(0)
            local ok_inline = pcall(gs.preview_hunk_inline)
            if ok_inline then
              if restore_view then
                vim.schedule(function()
                  pcall(fn.winrestview, view)
                  pcall(api.nvim_win_set_cursor, 0, cur)
                end)
              end
              api.nvim_create_autocmd({ "CursorMoved", "BufHidden", "InsertEnter" }, {
                group = shared.augroup("line_diff_on_hold_cleanup"),
                buffer = buf,
                once = true,
                callback = function()
                  shared.clear_line_diff(buf)
                end,
                desc = "Git: clear inline diff preview on next move",
              })
              return
            end
          end
        end

        -- Fallback: previous committed content as EOL/right-aligned virtual text
        local lnum = get_lnum()
        local prev = get_previous_line(git, file, lnum)
        if not prev or prev == "" then
          return
        end

        local virt = truncate(prev, tonumber(cfg.max_len or 160) or 160)
        local pos = (cfg.right_align and "right_align") or "eol"
        local pref = (cfg.prefix ~= nil) and tostring(cfg.prefix) or "previous: "

        api.nvim_buf_set_extmark(buf, shared.NS_LINE_DIFF, lnum - 1, 0, {
          virt_text = { { pref .. virt, cfg.hl_prev or "Comment" } },
          virt_text_pos = pos,
          priority = tonumber(cfg.virt_priority or 1000) or 1000,
        })

        api.nvim_create_autocmd({ "CursorMoved", "BufHidden", "InsertEnter" }, {
          group = shared.augroup("line_diff_on_hold_cleanup"),
          buffer = buf,
          once = true,
          callback = function()
            shared.clear_line_diff(buf)
          end,
          desc = "Git: clear previous-line preview on next move",
        })
      end

      local extra = tonumber(cfg.delay or 0) or 0
      if extra > 0 then
        vim.defer_fn(run, extra)
      else
        run()
      end
    end,
    desc = "Git: show line diff/previous content on CursorHold/InsertHold (mode-aware, strict)",
  })

  -- Proaktiv räumen/invalidieren, sobald der Modus in einen nicht erlaubten wechselt
  api.nvim_create_autocmd("ModeChanged", {
    group = shared.augroup("line_diff_on_hold_modeclear"),
    callback = function()
      local win = api.nvim_get_current_win()
      local buf = api.nvim_get_current_buf()
      if not mode_allowed(cfg.modes) then
        shared.clear_line_diff(buf)
        bump_gen(win) -- invalidate any scheduled, not-yet-run callbacks
      end
    end,
    desc = "Git: clear/abort line diff when leaving allowed modes",
  })
end

return M
