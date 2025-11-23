---@module 'config.neotree.open'
-- Keymap setup for Neo-tree positions (left/right/float/current)
-- Fixed AltGr-Aliassse for DE-Layout

local map = require("lib.map")

local M = {}

---@enum NeoTreePositionEnum
local NeoTreePositionEnum = {
  left = "left",
  right = "right",
  float = "float",
  current = "current",
}

---@type NeoTreeCfg
M.cfg = {
  extra_lhs = {
    ["<A-c>"] = { "¢" },
    ["<A-f>"] = { "đ" },
    ["<A-l>"] = { "ł" },
    ["<A-r>"] = { "¶" },
  },
}

---@type NeoTreeBaseOpts
local base_opts = {
  source = "filesystem",
  toggle = true,
  reveal = true,
  reveal_force_cwd = true,
  position = NeoTreePositionEnum.float,
}

---@type NeoTreeMapSpec[]
local specs = {
  { lhs = "<A-c>", pos = "current", desc = "[Neo-tree] Toggle & Reveal (current)" },
  { lhs = "<A-f>", pos = "float", desc = "[Neo-tree] Toggle & Reveal (float)" },
  { lhs = "<A-l>", pos = "left", desc = "[Neo-tree] Toggle & Reveal (left)" },
  { lhs = "<A-r>", pos = "right", desc = "[Neo-tree] Toggle & Reveal (right)" },
}

---@nodiscard
---@param position NeoTreePosition
---@return fun()|nil
local function make_neotree_opener(position)
  local ok_nt, NeoCmd = pcall(require, "neo-tree.command")
  if not ok_nt then
    vim.notify("[neotree.open] neo-tree.command not available", 2)
    return
  end
  if not NeoTreePositionEnum[position] then
    position = NeoTreePositionEnum.left
  end
  return function()
    local opts = vim.tbl_extend("force", base_opts, { position = position })
    NeoCmd.execute(opts)
  end
end

--- Registriert ein Binding für mehrere Varianten:
--   1) Primär (z. B. <A-c>)
--   2) <M-…>-Alias (falls Terminal Alt als Meta sendet)
--   3) Benutzerdefinierte extra_lhs (für AltGr/Terminal-Sonderzeichen)
---@param lhs string
---@param pos NeoTreePosition
---@param desc string
local function register_aliases(lhs, pos, desc)
  local cb = make_neotree_opener(pos)
  if not cb then return end

  -- 1) Primär
  map("n", lhs, cb, { desc = desc, silent = true })

  -- 2) Meta-Alias
  local m_lhs = lhs:gsub("^<A%-", "<M-")
  if m_lhs ~= lhs then
    pcall(map, "n", m_lhs, cb, { desc = desc .. " (Meta alias)", silent = true })
  end

  -- 3) Userdefined Extra-LHS (AltGr/Terminals)
  if M.cfg.extra_lhs and M.cfg.extra_lhs[lhs] then
    for _, alt in ipairs(M.cfg.extra_lhs[lhs]) do
      pcall(map, "n", alt, cb, { desc = desc .. " (alias)", silent = true })
    end
  end
end

---@param opts NeoTreeCfg|nil
function M.attach_opener_mappings(opts)
  if type(opts) == "table" then
    -- Allow overriding/merging defaults
    if opts.extra_lhs then
      -- Deep-merge extra_lhs-Tabellen (Defaults ∪ User)
      M.cfg.extra_lhs = vim.tbl_deep_extend("force", M.cfg.extra_lhs or {}, opts.extra_lhs)
      opts.extra_lhs = nil
    end
    for k, v in pairs(opts) do
      M.cfg[k] = v
    end
  end

  for i = 1, #specs do
    local m = specs[i] ---@type NeoTreeMapSpec
    register_aliases(m.lhs, m.pos, m.desc)
  end
end

return M
