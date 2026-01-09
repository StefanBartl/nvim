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

---@type Cfg.NeoTree.Cfg
M.cfg = {
  extra_lhs = {
    ["<A-c>"] = { "¢" },
    ["<A-f>"] = { "đ" },
    ["<A-l>"] = { "ł" },
    ["<A-r>"] = { "¶" },
  },
}

---@param position Cfg.NeoTree.Position
---@return fun()|nil
local function make_neotree_opener(position)
  local ok_nt, NeoCmd = pcall(require, "neo-tree.command")
  if not ok_nt then
    vim.notify("[neotree.open.window] neo-tree.command not available", vim.log.levels.WARN)
    return
  end

  if not PositionEnum[position] then
    position = PositionEnum.left
  end

  return function()
    local ctx = buffer_utils.get_buffer_context()
    local reveal_file = nil
    local dir = nil

    if ctx then
      reveal_file = ctx.file
      dir = ctx.dir
    end

    local opts = {
      source = "filesystem",
      toggle = true,
      reveal = true,
      reveal_file = reveal_file,
      reveal_force_cwd = false,
      position = position,
      dir = dir,
    }

    NeoCmd.execute(opts)

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

---@param opts Cfg.NeoTree.Cfg|nil
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
