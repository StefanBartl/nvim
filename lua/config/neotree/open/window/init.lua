---@module 'config.neotree.open.window'
---@brief Keymap-based Neo-tree window opener with reveal support

local map = require("lib.map")
local buffer_utils = require("config.neotree.utils.buffer")

local M = {}

---@enum Cfg.NeoTree.PositionEnum
local PositionEnum = {
  left = "left",
  right = "right",
  float = "float",
  current = "current",
}

---@type Cfg.NeoTree.Open.Win.xlhs
M.cfg = {
  extra_lhs = {
    ["<A-c>"] = { "¢" },
    ["<A-f>"] = { "đ" },
    ["<A-l>"] = { "ł" },
    ["<A-r>"] = { "¶" },
  },
}

---Check if Neo-tree is open and get its position
---@return string|nil position
local function get_neotree_position()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neo-tree" then
        local ok, state = pcall(require, "neo-tree.sources.manager")
        if ok and state.get_state then
          local fs_state = state.get_state("filesystem")
          if fs_state and fs_state.window then
            return fs_state.window.position
          end
        end
      end
    end
  end
  return nil
end

---@param target_position Cfg.NeoTree.Position
---@return fun()|nil
local function make_neotree_opener(target_position)
  local ok_nt, NeoCmd = pcall(require, "neo-tree.command")
  if not ok_nt then
    vim.notify("[neotree.open.window] neo-tree.command not available", vim.log.levels.WARN)
    return
  end

  if not PositionEnum[target_position] then
    target_position = PositionEnum.right
  end

  return function()
    local current_position = get_neotree_position()

    local ctx = buffer_utils.get_buffer_context()
    local reveal_file = ctx and ctx.file or nil
    local dir = ctx and ctx.dir or nil

    -- Smart switching logic
    if current_position then
      if current_position == target_position then
        -- Same position → toggle (close)
        NeoCmd.execute({
          source = "filesystem",
          toggle = true,
          position = target_position,
        })
      else
        -- Different position → close old, open new (atomic)
        NeoCmd.execute({
          source = "filesystem",
          action = "close",
        })

        vim.schedule(function()
          NeoCmd.execute({
            source = "filesystem",
            action = "show",
            reveal = true,
            reveal_file = reveal_file,
            reveal_force_cwd = false,
            position = target_position,
            dir = dir,
          })
        end)
      end
    else
      -- No Neo-tree open → open new
      NeoCmd.execute({
        source = "filesystem",
        action = "show",
        reveal = true,
        reveal_file = reveal_file,
        reveal_force_cwd = false,
        position = target_position,
        dir = dir,
      })
    end

    -- Pause CWD sync to avoid conflicts
    local ok_sync, sync = pcall(require, "config.neotree.cwd_sync")
    if ok_sync and sync.pause_sync then
      sync.pause_sync(2000)
    end
  end
end

local function register_aliases(lhs, pos, desc)
  local cb = make_neotree_opener(pos)
  if not cb then
    return
  end

  map("n", lhs, cb, { desc = desc, silent = true })

  local m_lhs = lhs:gsub("^<A%-", "<M-")
  if m_lhs ~= lhs then
    pcall(map, "n", m_lhs, cb, { desc = desc .. " (Meta alias)", silent = true })
  end

  if M.cfg.extra_lhs and M.cfg.extra_lhs[lhs] then
    for _, alt in ipairs(M.cfg.extra_lhs[lhs]) do
      pcall(map, "n", alt, cb, { desc = desc .. " (alias)", silent = true })
    end
  end
end

---@param opts Cfg.NeoTree.Open.Win.xlhs|nil
function M.attach_opener_mappings(opts)
  if type(opts) == "table" then
    if opts.extra_lhs then
      M.cfg.extra_lhs = vim.tbl_deep_extend("force", M.cfg.extra_lhs or {}, opts.extra_lhs)
      opts.extra_lhs = nil
    end
    for k, v in pairs(opts) do
      M.cfg[k] = v
    end
  end

  local specs = {
    { lhs = "<A-c>", pos = "current", desc = "[Neo-tree] Toggle & Reveal (current)" },
    { lhs = "<A-f>", pos = "float", desc = "[Neo-tree] Toggle & Reveal (float)" },
    { lhs = "<A-l>", pos = "left", desc = "[Neo-tree] Toggle & Reveal (left)" },
    { lhs = "<A-r>", pos = "right", desc = "[Neo-tree] Toggle & Reveal (right)" },
  }

  for i = 1, #specs do
    local m = specs[i]
    register_aliases(m.lhs, m.pos, m.desc)
  end
end

return M
