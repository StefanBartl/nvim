---@module 'custom.recommender.treesitter'
---Safe Treesitter-based analyzer for Lua

local ts = vim.treesitter
local blacklist_module = require("custom.recommender.blacklist")

local M = {}

---Get text from node
---@param node TSNode
---@param src string
---@return string|nil
local function text(node, src)
  local ok, result = pcall(ts.get_node_text, node, src)
  return ok and result or nil
end

---Collect all chains from buffer using treesitter
---@param bufnr integer
---@param blacklist? string[]
---@return string[]
local function collect_chains(bufnr, blacklist)
  local ok, parser = pcall(ts.get_parser, bufnr, "lua")
  if not ok or not parser then
    return {}
  end

  local parse_ok, trees = pcall(parser.parse, parser)
  if not parse_ok or not trees or #trees == 0 then
    return {}
  end

  local tree = trees[1]
  local root = tree:root()

  local src = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

  local chains = {}

  -- Query for field expressions and method calls
  local query_ok, query = pcall(
    ts.query.parse,
    "lua",
    [[
    (field_expression) @field
    (call_expression
      function: (field_expression) @call)
  ]]
  )

  if not query_ok then
    return {}
  end

  for _, match in query:iter_matches(root, bufnr) do
    for _, node in pairs(match) do
      ---@cast node TSNode
      local value = text(node, src)
      if value and value:match("^[%w_]+%.[%w_]+") then
        -- Skip if blacklisted
        if not blacklist_module.is_blacklisted(value, blacklist or {}) then
          table.insert(chains, value)
        end
      end
    end
  end

  return chains
end

---Find common prefix of chains
---@param chains string[]
---@return string|nil
local function common_prefix(chains)
  if #chains == 0 then
    return nil
  end

  local parts = vim.split(chains[1], ".", { plain = true })
  local max = #parts

  for i = 2, #chains do
    local p = vim.split(chains[i], ".", { plain = true })
    max = math.min(max, #p)
    for j = 1, max do
      if parts[j] ~= p[j] then
        max = j - 1
        break
      end
    end
  end

  if max < 2 then
    return nil
  end

  return table.concat(parts, ".", 1, max)
end

---Analyze buffer and return suggestions
---@param threshold integer
---@param custom_aliases? table<string, string>
---@param blacklist? string[]
---@return table[]
function M.analyze(threshold, custom_aliases, blacklist)
  threshold = threshold or 3

  local bufnr = vim.api.nvim_get_current_buf()
  local counts = {}

  -- Count occurrences (blacklist is already checked in collect_chains)
  for _, chain in ipairs(collect_chains(bufnr, blacklist)) do
    counts[chain] = (counts[chain] or 0) + 1
  end

  -- Filter by threshold
  local filtered = {}
  for chain, count in pairs(counts) do
    if count >= threshold then
      table.insert(filtered, { chain = chain, count = count })
    end
  end

  if #filtered == 0 then
    return {}
  end

  -- Extract chain list for prefix detection
  local chains = {}
  for _, v in ipairs(filtered) do
    table.insert(chains, v.chain)
  end

  local prefix = common_prefix(chains)

  -- Generate aliases
  local out = {}
  for _, item in ipairs(filtered) do
    local alias

    -- Check custom aliases first
    if custom_aliases and custom_aliases[item.chain] then
      alias = string.format("local %s = %s", custom_aliases[item.chain], item.chain)
    elseif prefix and item.chain:sub(1, #prefix) == prefix then
      -- Use common prefix
      local name = prefix:match("([%w_]+)$")
      alias = string.format("local %s = %s", name, prefix)
    else
      -- Use last part of chain
      local last = item.chain:match("([%w_]+)$")
      alias = string.format("local %s = %s", last, item.chain)
    end

    table.insert(out, {
      chain = item.chain,
      count = item.count,
      alias = alias,
    })
  end

  -- Sort by count (descending)
  table.sort(out, function(a, b)
    return a.count > b.count
  end)

  return out
end

return M
