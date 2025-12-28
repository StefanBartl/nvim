---@module 'custom.recommender.regex'
---Regex-based chain analyzer

local blacklist_module = require("custom.recommender.blacklist")

local M = {}

---Extract chains from a line
---@param line string
---@return string[]
function M.extract_chains(line)
  local out = {}
  local seen = {}

  -- Match 3-part chains first (e.g., vim.api.nvim_*)
  for c in line:gmatch("([%w_]+%.[%w_]+%.[%w_]+)") do
    if not seen[c] then
      table.insert(out, c)
      seen[c] = true
    end
  end

  -- Then match 2-part chains (e.g., vim.api, table.insert)
  for c in line:gmatch("([%w_]+%.[%w_]+)") do
    if not seen[c] then
      table.insert(out, c)
      seen[c] = true
    end
  end

  return out
end

---Analyze buffer and return suggestions
---@param threshold integer
---@param custom_aliases? table<string, string>
---@param blacklist? string[]
---@return table[]
function M.analyze(threshold, custom_aliases, blacklist)
  local api = vim.api
  local counts = {}
  local lines = api.nvim_buf_get_lines(0, 0, -1, false)

  -- Count occurrences
  for _, line in ipairs(lines) do
    for _, chain in ipairs(M.extract_chains(line)) do
      -- Skip if blacklisted
      if not blacklist_module.is_blacklisted(chain, blacklist or {}) then
        counts[chain] = (counts[chain] or 0) + 1
      end
    end
  end

  -- Filter by threshold
  local res = {}
  for chain, count in pairs(counts) do
    if count >= threshold then
      local alias

      -- Check custom aliases first
      if custom_aliases and custom_aliases[chain] then
        alias = string.format("local %s = %s", custom_aliases[chain], chain)
      else
        -- Generate alias from last part of chain
        local last = chain:match("([%w_]+)$")
        local var_name = last or chain:gsub("%.", "_")
        alias = string.format("local %s = %s", var_name, chain)
      end

      table.insert(res, {
        chain = chain,
        count = count,
        alias = alias,
      })
    end
  end

  -- Sort by count (descending)
  table.sort(res, function(a, b)
    return a.count > b.count
  end)

  return res
end

return M
