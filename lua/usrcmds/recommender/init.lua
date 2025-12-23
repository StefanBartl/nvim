---@module 'usrcmds.recommender'
---Suggest frequently used Lua chains for local aliases in the current buffer
---Hover / toggleable display

local M = {}

local api = vim.api
local tbl_insert = table.insert
local str_format = string.format

local float_buf = nil
local float_win = nil

--- Close hover if open
local function close_float()
  if float_win and api.nvim_win_is_valid(float_win) then
    pcall(api.nvim_win_close, float_win, true)
  end
  float_buf, float_win = nil, nil
end

local function is_float_open()
  return float_win and api.nvim_win_is_valid(float_win)
end

--- Extract "chains" from a line
---@param line string
---@return string[] chains
local function extract_chains(line)
  local chains = {}
  -- Match sequences like: api.nvim_buf_get_name
  for c in line:gmatch("([%w_]+%.[%w_]+%.[%w_]+)") do
    chains[#chains + 1] = c
  end
  -- Match sequences like api.xxx
  for c in line:gmatch("([%w_]+%.[%w_]+)") do
    chains[#chains + 1] = c
  end
  return chains
end

--- Build alias suggestion from chain
---@param chain string
---@return string alias
local function build_alias(chain)
  -- take last part of chain as variable name
  local last = chain:match("([%w_]+)$")
  if last then
    return str_format("local %s = %s", last, chain)
  else
    return str_format("local %s = %s", chain:gsub("%.", "_"), chain)
  end
end

--- Analyze buffer for frequently used chains
---@param threshold integer
---@return table suggestions
local function analyze_buffer(threshold)
  threshold = threshold or 3
  local counts = {}
  local lines = api.nvim_buf_get_lines(0, 0, -1, false)

  for _, line in ipairs(lines) do
    for _, chain in ipairs(extract_chains(line)) do
      counts[chain] = (counts[chain] or 0) + 1
    end
  end

  local suggestions = {}
  for chain, count in pairs(counts) do
    if count >= threshold then
      suggestions[#suggestions + 1] = {
        chain = chain,
        count = count,
        alias = build_alias(chain),
      }
    end
  end

  -- Sort by descending count
  table.sort(suggestions, function(a, b) return a.count > b.count end)
  return suggestions
end

--- Show hover with recommendations
---@param suggestions table
local function show_hover(suggestions)
  close_float()

  float_buf = api.nvim_create_buf(false, true)
  local content = {}

  if #suggestions == 0 then
    content = { "No repeated chains found (threshold not met)" }
  else
    tbl_insert(content, "Suggested aliases for repeated chains:")
    tbl_insert(content, "")
    for _, s in ipairs(suggestions) do
      tbl_insert(content, str_format("%s → %d hits", s.chain, s.count))
      tbl_insert(content, "  " .. s.alias)
      tbl_insert(content, "")
    end
  end

  api.nvim_buf_set_lines(float_buf, 0, -1, false, content)

  local width = 0
  for _, line in ipairs(content) do
    width = math.max(width, #line)
  end
  local height = #content

  local opts = {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width + 2,
    height = height,
    style = "minimal",
    border = "single",
  }

  float_win = api.nvim_open_win(float_buf, false, opts)
end

--- Main recommender function
---@param opts table {threshold=integer}
function M.recommender(opts)
  opts = opts or {}
  local threshold = opts.threshold or 3

  if is_float_open() then
    close_float()
    return
  end

  local suggestions = analyze_buffer(threshold)
  show_hover(suggestions)
end

--- Setup global close mappings (q / ESC)
local function setup_close_mappings()
  local key_opts = { noremap = true, silent = true }
  vim.keymap.set("n", "q", function()
    if is_float_open() then close_float() end
  end, key_opts)
  vim.keymap.set("n", "<ESC>", function()
    if is_float_open() then close_float() end
  end, key_opts)
end

--- Enable user command and close mappings
function M.enable()
  setup_close_mappings()

  api.nvim_create_user_command("Recommender", function(cmd)
    local t = cmd.args ~= "" and tonumber(cmd.args) or 3
    M.recommender({ threshold = t })
  end, { nargs = "?", desc = "Analyze buffer for repeated chains and suggest aliases" })
end

return M
