---@module 'mappings.neotree'
--- DRY keymap setup for Neo-tree positions (left/right/float/current) plus F1 disable across modes.
--- The mappings share one base option set and differ only by 'position'.
--- This snippet is self-contained; it caches the require() and validates inputs.

local M = {}

-- Aliases and enums for better tooling
---@alias NeoTreePosition "left"|"right"|"float"|"current"

---@enum NeoTreePositionEnum
local NeoTreePositionEnum = {
  left = "left",
  right = "right",
  float = "float",
  current = "current",
}

---@class NeoTreeBaseOpts
---@field source string                -- e.g. "filesystem"
---@field toggle boolean               -- open if closed, close if open
---@field reveal boolean               -- reveal current file
---@field reveal_force_cwd boolean     -- jump CWD if file is outside current CWD
---@field position NeoTreePosition     -- left|right|float|current

---@class NeoTreeMapSpec
---@field lhs string
---@field pos NeoTreePosition
---@field desc string

-- Cache the module require to avoid repeated lookups.
local ok_nt, NeoCmd = pcall(require, "neo-tree.command")
if not ok_nt then
  -- If Neo-tree is unavailable, abort early to avoid runtime errors.
  return
end

-- Shared base options used by all mappings.
---@type NeoTreeBaseOpts
local base_opts = {
  source = "filesystem",
  toggle = true,
  reveal = true,
  reveal_force_cwd = true, -- requires Neo-tree v3+; harmless if ignored by older versions
  position = NeoTreePositionEnum.left, -- default; will be overridden per map
}

-- Table-driven specs: one entry per keymap.
---@type NeoTreeMapSpec[]
local specs = {
  { lhs = "<A-c>", pos = "current", desc = "[Neo-tree] Toggle & Reveal (current)" },
  { lhs = "<A-f>", pos = "float", desc = "[Neo-tree] Toggle & Reveal (float)" },
  { lhs = "<A-l>", pos = "left", desc = "[Neo-tree] Toggle & Reveal (left)" },
}

-- Small factory to build the mapping callback with the desired position.
---@nodiscard
---@param position NeoTreePosition
---@return fun():nil
local function make_neotree_opener(position)
  -- Validate enum to catch typos at runtime (cheap guard).
  if not NeoTreePositionEnum[position] then
    -- Fallback to a safe default if someone passes an invalid position.
    position = NeoTreePositionEnum.left
  end

  return function()
    -- Merge (force) base options with the per-call position.
    local opts = vim.tbl_extend("force", base_opts, { position = position })
    -- Execute the Neo-tree command using the cached module.
    NeoCmd.execute(opts)
  end
end

-- Optional: if using which-key, one can add a group name for <C-t>:
-- require("which-key").add({ { "<C-t>", group = "Neo-tree" } })

function M.setup()
  local map = vim.g.__map_helper

  -- Toggle Neotree & focus current buffer's file when opening
  -- map("n", "<C-t>", function()
  --   require("neo-tree.command").execute {
  --     source = "filesystem", -- ensure filesystem source
  --     toggle = true, -- open if closed, close if open
  --     reveal = true, -- focus current buffer's file on open
  --     reveal_force_cwd = true, -- if the file is outside the current cwd, jump cwd without prompt
  --     position = "current", -- "left", "right", "float", "current"
  --   }
  -- end, { desc = "[Neo-tree] Toggle & Reveal" })

  -- Register all position-specific mappings in normal mode.
  for i = 1, #specs do
    local m = specs[i] ---@type NeoTreeMapSpec
    map("n", m.lhs, make_neotree_opener(m.pos), { desc = m.desc, silent = true })
  end

  -- Disable F1 across multiple modes with one compact loop.
  ---@type string[]
  local f1_modes = { "n", "i", "v", "t", "c" }
  for i = 1, #f1_modes do
    map(f1_modes[i], "<F1>", "<Nop>", { desc = "[General] Disable F1", silent = true })
  end
end

return M
