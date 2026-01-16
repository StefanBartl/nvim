---@module 'config.neotree.current_hl'
--- Highlight the current buffer's file (red) and its parent directory (dark red) in Neo-tree.
--- Minimal invasive: plug into setup(opts) and refresh on buffer/window/tab changes.

local M = {}

local S = { current_file = nil, current_parent = nil, timer = nil }

-- tiny name->hex fallback for convenience; prefer hex or link
local NAMED = {
  red = "#ff0000",
  blue = "#0000ff",
  green = "#00ff00",
  yellow = "#ffff00",
  magenta = "#ff00ff",
  cyan = "#00ffff",
  white = "#ffffff",
  black = "#000000",
  gray = "#808080",
  grey = "#808080",
  darkred = "#8b0000",
  darkblue = "#00008b",
  darkgreen = "#006400",
}

--- Resolve a user color spec into a valid nvim_set_hl opts table
--- Accepts:
---   "#rrggbb" → { fg = "#rrggbb" }
---   "red"     → { fg = "#ff0000" } via NAMED
---   "link:ErrorMsg" → { link = "ErrorMsg" }
---   existing group name → { link = "<that group>" }
---   { fg=..., bg=..., bold=..., ... } → passed through
---@param spec any
---@param fallback table
local function resolve_spec(spec, fallback)
  if type(spec) == "table" then
    return vim.tbl_deep_extend("force", {}, spec)
  end
  if type(spec) ~= "string" or spec == "" then
    return vim.tbl_deep_extend("force", {}, fallback)
  end
  -- explicit link:GroupName
  local link = spec:match("^link:(.+)$")
  if link then
    return { link = link }
  end
  -- hex
  if spec:match("^#%x%x%x%x%x%x$") then
    return { fg = spec }
  end
  -- existing hl group name? then link
  if vim.fn.hlexists(spec) == 1 then
    return { link = spec }
  end
  -- named fallback
  local hex = NAMED[spec:lower()]
  if hex then
    return { fg = hex }
  end
  return vim.tbl_deep_extend("force", {}, fallback)
end

-- Normalize to an absolute path (best-effort)
---@param p string|nil
---@return string
local function norm(p)
  local s = tostring(p or "")
  if s == "" then
    return ""
  end
  local ok, out = pcall(vim.fs.normalize, s)
  return ok and out or s
end

---@return string|nil
local function current_file()
  if vim.bo.buftype ~= "" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(0)
  if not name or name == "" then
    return nil
  end
  return norm(name)
end

---@param path string|nil
---@return string|nil
local function parent_dir(path)
  if not path or path == "" then
    return nil
  end
  local d = vim.fs.dirname(path)
  if not d or d == "" then
    return nil
  end
  return norm(d)
end

---@return boolean
local function neotree_visible_in_tab()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      return true
    end
  end
  return false
end

---@param cfg Cfg.NeoTree.CurrentHl.Config
local function refresh(cfg)
  if not cfg.enable or not neotree_visible_in_tab() then
    return
  end
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if ok then
    pcall(manager.refresh, "filesystem", nil, true)
  else
    pcall(function()
      vim.cmd("silent! Neotree refresh")
    end)
  end
end

---@param fn fun()
---@param ms integer
---@return fun()
local function debounce(fn, ms)
  return function()
    if S.timer then
      pcall(vim.uv.timer_stop, S.timer)
      ---@diagnostic disable-next-line close exists in uv library
      pcall(vim.uv.close, S.timer)
      S.timer = nil
    end

    ---@type uv
    local uv = vim.uv or vim.loop
    local t = uv.new_timer()
    S.timer = t
    ---@cast t uv.uv_timer_t
    ---@diagnostic disable-next-line start exists in uv library
    t:start(ms, 0, function()
      vim.schedule(function()
        if S.timer == t then
          S.timer = nil
        end
        pcall(fn)
      end)
      ---@diagnostic disable-next-line
      t:stop()
      t:close()
    end)
  end
end

---@param cfg Cfg.NeoTree.CurrentHl.Config
local function define_highlights(cfg)
  local file_default = { fg = "#ff5f5f", bold = true }
  local dir_default = { fg = "#af0000", bold = false }

  local file_spec = file_default
  local dir_spec = dir_default
  if cfg.colors then
    file_spec = resolve_spec(cfg.colors.file, file_default)
    dir_spec = resolve_spec(cfg.colors.parent, dir_default)
  end

  local function apply()
    -- if 'link' is present, it's mutually exclusive with local attrs (Neovim rule)
    if file_spec.link then
      vim.api.nvim_set_hl(0, cfg.file_hl, { link = file_spec.link })
    else
      vim.api.nvim_set_hl(0, cfg.file_hl, file_spec)
    end
    if dir_spec.link then
      vim.api.nvim_set_hl(0, cfg.dir_hl, { link = dir_spec.link })
    else
      vim.api.nvim_set_hl(0, cfg.dir_hl, dir_spec)
    end
  end

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("NeoTreeCurrentHL", { clear = true }),
    callback = apply,
  })
  apply()
end

-- Wrap the stock "name" component to inject our highlight
---@param cfg Cfg.NeoTree.CurrentHl.Config
---@param opts table
local function attach_component(cfg, opts)
  local components = require("neo-tree.sources.common.components")

  opts.filesystem = opts.filesystem or {}
  opts.filesystem.components = opts.filesystem.components or {}

  opts.default_component_config = opts.default_component_config or {}
  opts.default_component_config.name = vim.tbl_extend(
    "force",
    opts.default_component_config.name or {},
    { use_git_status_colors = cfg.use_git_status_colors == true }
  )

  opts.filesystem.components.name = function(config, node, state)
    -- Call the original component to keep icons, git, symlink arrows, etc.
    local item = components.name(config, node, state)
    local cf, cp = S.current_file or "", S.current_parent or ""
    if cf ~= "" and node.type == "file" and norm(node.path) == cf then
      item.highlight = cfg.file_hl
    elseif cp ~= "" and node.type == "directory" and norm(node.path) == cp then
      item.highlight = cfg.dir_hl
    end
    return item
  end
end

---@param user_cfg Cfg.NeoTree.CurrentHl.Config|boolean|nil
function M.setup(user_cfg)
  local cfg = vim.tbl_deep_extend("force", {
    file_hl = "NeoTreeCurrentFile",
    dir_hl = "NeoTreeCurrentParent",
    debounce = 50,
    use_git_status_colors = false,
    enable = true,
    colors = nil,
  }, user_cfg or {})

  define_highlights(cfg)

  local function update_and_refresh()
    local f = current_file()

    -- If there is no real file buffer (dashboard, nofile, empty name, etc.),
    -- clear previous highlights and refresh Neo-tree once.
    if not f then
      local had_state = (S.current_file ~= nil) or (S.current_parent ~= nil)
      if had_state then
        S.current_file = nil
        S.current_parent = nil
        refresh(cfg) -- re-render to drop highlights
      end
      return
    end

    -- Normal path: track current file and its parent
    local p = parent_dir(f)
    if S.current_file == f and S.current_parent == p then
      return
    end
    S.current_file, S.current_parent = f, p
    refresh(cfg)
  end

  local deb = debounce(update_and_refresh, cfg.debounce)
  local grp = vim.api.nvim_create_augroup("NeoTreeCurrentHL_Auto", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TabEnter", "BufWritePost" }, {
    group = grp,
    callback = deb,
  })

  -- Initialize immediately
  vim.schedule(function()
    local f = current_file()
    if f then
      S.current_file = f
      S.current_parent = parent_dir(f or "")
    else
      S.current_file = nil
      S.current_parent = nil
    end
    refresh(cfg)
  end)
end

---@param opts table
function M.attach(opts)
  attach_component({
    file_hl = "NeoTreeCurrentFile",
    dir_hl = "NeoTreeCurrentParent",
    debounce = 50,
    use_git_status_colors = false,
    enable = true,
  }, opts or {})
end

return M
