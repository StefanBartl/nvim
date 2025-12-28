-- Beispiel-Konfiguration für lua/custom/recommender/blacklist.lua

---@module 'custom.recommender.blacklist'
---Chains that should never be suggested

local M = {}

---Default blacklist entries
M.default = {
  -- === VIM API CHAINS ===
  -- Uncomment wenn du vim.fn.* chains nicht aliased haben willst
  -- "vim.fn",

  -- Uncomment wenn du vim.api.* chains lieber ausschreibst
  -- "vim.api",

  -- === STANDARD LUA FUNCTIONS ===
  -- Wenn du diese Funktionen lieber direkt nutzt:
  -- "table.insert",
  -- "table.concat",
  -- "table.remove",
  -- "string.format",
  -- "string.match",
  -- "string.gsub",
  -- "math.floor",
  -- "math.ceil",

  -- === SPEZIFISCHE CHAINS ===
  -- Nur bestimmte Chains blockieren:
  -- "vim.keymap.set",  -- Blockiert nur diese eine Chain
  -- "vim.schedule",    -- Blockiert nur diese eine Chain

  -- === PRÄFIX-BEISPIELE ===
  -- "string",  -- Würde ALLE string.* Funktionen blockieren
  -- "math",    -- Würde ALLE math.* Funktionen blockieren
}

---Check if a chain is blacklisted (prefix matching)
---@param chain string The chain to check
---@param blacklist string[] List of blacklisted prefixes
---@return boolean
function M.is_blacklisted(chain, blacklist)
  if not blacklist or #blacklist == 0 then
    return false
  end

  for _, prefix in ipairs(blacklist) do
    -- Check if chain starts with the blacklist entry
    if chain:sub(1, #prefix) == prefix then
      return true
    end
  end

  return false
end

return M


-- === BEISPIEL SETUP IN init.lua ===
--[[

require("custom.recommender").setup({
  analyzer = "regex",
  threshold = 3,

  -- Custom Aliases: Definiere bevorzugte Namen
  custom_aliases = {
    ["vim.api"] = "api",
    ["table.insert"] = "tbl_insert",
  },

  -- Blacklist: Was soll NIE vorgeschlagen werden?
  blacklist = {
    "vim.fn",        -- Blockiert alle vim.fn.* chains
    "string.format", -- Blockiert nur string.format
  },
})

]]
