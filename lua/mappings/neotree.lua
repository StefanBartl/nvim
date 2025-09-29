---@module 'mappings.neotree'
--- DRY keymap setup for Neo-tree positions (left/right/float/current) plus F1 disable across modes.
--- Ergänzt: feste AltGr-Aliasse für DE-Layout auf XKB:
---   AltGr+c → "¢", AltGr+f → "đ", AltGr+l → "ł"
--- Diese werden zusätzlich zu <A-c>/<A-f>/<A-l> gemappt.

---@class NeoTreeBaseOpts
---@field source string
---@field toggle boolean
---@field reveal boolean
---@field reveal_force_cwd boolean
---@field position NeoTreePosition

---@class NeoTreeMapSpec
---@field lhs string
---@field pos NeoTreePosition
---@field desc string

local M = {}

---@alias NeoTreePosition "left"|"right"|"float"|"current"

---@enum NeoTreePositionEnum
local NeoTreePositionEnum = {
  left = "left",
  right = "right",
  float = "float",
  current = "current",
}

---Convenience wrapper for vim.keymap.set with sane defaults.
---@param modes string|string[]
---@param lhs string
---@param rhs string|function
---@param opts table|nil
local function map(modes, lhs, rhs, opts)
  opts = opts or {}
  if opts.noremap == nil then opts.noremap = true end
  if opts.silent == nil then opts.silent = true end
  vim.keymap.set(modes, lhs, rhs, opts)
end

---@class NeoTreeCfg
---@field extra_lhs table<string,string[]>|nil  -- zusätzliche LHS je Hauptbinding, z. B. { ["<A-c>"] = {"¢"} }

---@type NeoTreeCfg
M.cfg = {
  extra_lhs = {
    ["<A-c>"] = { "¢" },
    ["<A-f>"] = { "đ" },
    ["<A-l>"] = { "ł" },
    ["<A-r>"] = { "¶" },
  },
}

local ok_nt, NeoCmd = pcall(require, "neo-tree.command")
if not ok_nt then
  return
end

---@type NeoTreeBaseOpts
local base_opts = {
  source = "filesystem",
  toggle = true,
  reveal = true,
  reveal_force_cwd = true,
  position = NeoTreePositionEnum.left,
}

---@type NeoTreeMapSpec[]
local specs = {
  { lhs = "<A-c>", pos = "current", desc = "[Neo-tree] Toggle & Reveal (current)" },
  { lhs = "<A-f>", pos = "float",   desc = "[Neo-tree] Toggle & Reveal (float)"   },
  { lhs = "<A-l>", pos = "left",    desc = "[Neo-tree] Toggle & Reveal (left)"    },
  { lhs = "<A-r>", pos = "right",    desc = "[Neo-tree] Toggle & Reveal (right)"    },
}

---@nodiscard
---@param position NeoTreePosition
---@return fun():nil
local function make_neotree_opener(position)
  if not NeoTreePositionEnum[position] then
    position = NeoTreePositionEnum.left
  end
  return function()
    local opts = vim.tbl_extend("force", base_opts, { position = position })
    NeoCmd.execute(opts)
  end
end

--- Registriert ein Binding für mehrere Varianten:
--- 1) Primär (z. B. <A-c>)
--- 2) <M-…>-Alias (falls Terminal Alt als Meta sendet)
--- 3) Benutzerdefinierte extra_lhs (für AltGr/Terminal-Sonderzeichen)
---@param lhs string
---@param pos NeoTreePosition
---@param desc string
local function register_aliases(lhs, pos, desc)
  local cb = make_neotree_opener(pos)

  -- 1) Primär
  map("n", lhs, cb, { desc = desc, silent = true })

  -- 2) Meta-Alias
  local m_lhs = lhs:gsub("^<A%-", "<M-")
  if m_lhs ~= lhs then
    pcall(map, "n", m_lhs, cb, { desc = desc .. " (Meta alias)", silent = true })
  end

  -- 3) Benutzerdefinierte Extra-LHS (AltGr/Terminals)
  if M.cfg.extra_lhs and M.cfg.extra_lhs[lhs] then
    for _, alt in ipairs(M.cfg.extra_lhs[lhs]) do
      pcall(map, "n", alt, cb, { desc = desc .. " (alias)", silent = true })
    end
  end
end

--- Einfache Hilfe zum Ermitteln, welcher Key in Neovim tatsächlich ankommt.
--- Aufruf: :lua require('mappings.neotree').capture_key()
--- Danach im Normal-Mode die gewünschte Taste drücken (z. B. AltGr+c).
function M.capture_key()
  vim.notify("[neotree] Press your key now (Normal mode). Capturing next key...", vim.log.levels.INFO)
  local ok, ch = pcall(vim.fn.getcharstr)
  if not ok then
    vim.notify("[neotree] Capture aborted.", vim.log.levels.WARN)
    return
  end
  vim.notify(string.format("[neotree] Received key: %q", ch), vim.log.levels.INFO)
end

---@param opts NeoTreeCfg|nil
function M.setup(opts)
  if type(opts) == "table" then
    -- Allow overriding/merging defaults
    if opts.extra_lhs then
      -- Deep-merge extra_lhs-Tabellen (Defaults ∪ User)
      M.cfg.extra_lhs = vim.tbl_deep_extend("force", M.cfg.extra_lhs or {}, opts.extra_lhs)
      opts.extra_lhs = nil
    end
    for k, v in pairs(opts) do M.cfg[k] = v end
  end

  for i = 1, #specs do
    local m = specs[i] ---@type NeoTreeMapSpec
    register_aliases(m.lhs, m.pos, m.desc)
  end

  local f1_modes = { "n", "i", "v", "t", "c" }
  for i = 1, #f1_modes do
    map(f1_modes[i], "<F1>", "<Nop>", { desc = "[General] Disable F1", silent = true })
  end
end

return M
