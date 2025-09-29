---@module 'usrcmds.resize_window'
--- Small, focused module to resize the current window via a user command.
--- It provides an idempotent setup that registers :Size <dir> [amount].
--- Semantics:
---   - left  : decrease window width  by <amount> columns
---   - right : increase window width  by <amount> columns
---   - up    : increase window height by <amount> rows
---   - down  : decrease window height by <amount> rows
--- Notes:
---   - Amount defaults to `default_step` and must be a positive integer.
---   - The command only affects the current window and uses built-in :resize / :vertical resize.
---   - Linux/macOS focused; no platform-specific code is required.

local M = {
  opts = { default_step = 1 },
}

-- Local aliases (clarity over micro perf)
local api = vim.api

---@alias ResizeDirection '"left"'|'"right"'|'"up"'|'"down"'

--- Validate and normalize the step.
--- Ensures a positive integer; falls back to opts.default_step when invalid/missing.
---@param raw string|number|nil
---@param fallback integer
---@return integer step
local function normalize_step(raw, fallback)
  -- Accept numbers or numeric strings; coerce and clamp to >= 1
  local n = tonumber(raw or "")
  if not n or n < 1 or n ~= math.floor(n) then
    return math.max(1, math.floor(tonumber(fallback) or 1))
  end
  return n
end

--- Validate the direction token.
---@param dir any
---@return ResizeDirection|nil, string? errmsg
local function normalize_dir(dir)
  if dir == "left" or dir == "right" or dir == "up" or dir == "down" then
    return dir, nil
  end
  return nil,
    "Usage: :Size <left|right|up|down> [amount]\n" ..
    "Hint: amount must be a positive integer (defaults to configured step)."
end

--- Execute the actual resize based on direction and step.
---@param dir ResizeDirection
---@param step integer
---@return boolean ok
local function do_resize(dir, step)
  -- Defensive checks: ensure current window is valid
  local win = api.nvim_get_current_win()
  if not (win and api.nvim_win_is_valid(win)) then
    vim.notify("[Size] invalid current window", vim.log.levels.WARN)
    return false
  end

  -- Map direction to command; keep semantics transparent and documented.
  if dir == "left" then
    vim.cmd("vertical resize -" .. step)  -- decrease width
  elseif dir == "right" then
    vim.cmd("vertical resize +" .. step)  -- increase width
  elseif dir == "up" then
    vim.cmd("resize +" .. step)           -- increase height
  elseif dir == "down" then
    vim.cmd("resize -" .. step)           -- decrease height
  end
  return true
end

--- Register the :Size user command. Idempotent (redefines if it exists).
---@return nil
function M.enable_usercmd()
  -- Redefine safely if already present
  pcall(vim.api.nvim_del_user_command, "Size")

  api.nvim_create_user_command("Size", function(opts)
    ---@type string|nil
    local d = opts.fargs and opts.fargs[1] or nil
    ---@type ResizeDirection|nil, string|nil
    local dir, derr = normalize_dir(d)
    if not dir then
      vim.notify(derr or "[Size] invalid direction", vim.log.levels.ERROR)
      return
    end

    local step = normalize_step(opts.fargs and opts.fargs[2] or nil, M.opts.default_step)
    local ok = do_resize(dir, step)
    if not ok then
      vim.notify("[Size] resize failed", vim.log.levels.WARN)
    end
  end, {
    nargs = "+",  -- require at least the direction; amount is optional but we keep '+' to avoid ambiguity
    complete = function(arg_lead, cmd_line, _)
      -- Completion for the first argument; simple numeric hints for the second.
      local toks = vim.split(cmd_line, "%s+", { trimempty = true })
      if #toks <= 2 then
        -- First arg (after command name)
        local dirs = { "left", "right", "up", "down" }
        local out = {}
        for _, v in ipairs(dirs) do
          if v:find("^" .. vim.pesc(arg_lead)) then table.insert(out, v) end
        end
        return out
      else
        -- Second arg: suggest a few common steps
        local nums = { "1", "2", "3", "5", "10" }
        local out = {}
        for _, v in ipairs(nums) do
          if v:find("^" .. vim.pesc(arg_lead)) then table.insert(out, v) end
        end
        return out
      end
    end,
    desc = "Resize current window: :Size <left|right|up|down> [amount]",
  })
end

--- Configure defaults and (optionally) register the user command.
--- Idempotent; safe to call multiple times.
---@param cfg ResizeWindowConfig|nil
---@param register boolean|nil  -- when true (default), also register :Size
---@return nil
function M.setup(cfg, register)
  cfg = cfg or {}
  -- Validate config with conservative defaults
  local step = normalize_step(cfg.default_step, M.opts.default_step)
  ---@type ResizeWindowConfig
  M.opts = {
    default_step = step,
  }
  if register ~= false then
    M.enable_usercmd()
  end
end

return M ---@type ResizeWindow
