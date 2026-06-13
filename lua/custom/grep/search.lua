---@module 'usrcmds.live_grep.search'

local config = require("usrcmds.live_grep.config")

local M = {}

---@param term string
---@return string[]
local function rg_files(term)
  local opts = config.options

  local cmd = {
    opts.rg.binary,
    "--files-with-matches",
  }

  if opts.rg.hidden then
    table.insert(cmd, "--hidden")
  end

  if opts.rg.follow then
    table.insert(cmd, "--follow")
  end

  table.insert(cmd, term)

  local result = vim.system(
    cmd,
    {
      text = true,
      cwd = opts.cwd,
    }
  ):wait()

  if result.code ~= 0 and result.code ~= 1 then
    return {}
  end

  local files = {}

  for line in vim.gsplit(result.stdout or "", "\n", { plain = true }) do
    if line ~= "" then
      files[#files + 1] = line
    end
  end

  return files
end

---@param list string[]
---@return table<string, boolean>
local function to_set(list)
  local set = {}

  for _, value in ipairs(list) do
    set[value] = true
  end

  return set
end

---@param left string[]
---@param right string[]
---@return string[]
local function intersect(left, right)
  local result = {}

  local right_set = to_set(right)

  for _, file in ipairs(left) do
    if right_set[file] then
      result[#result + 1] = file
    end
  end

  return result
end

---@param left string[]
---@param right string[]
---@return string[]
local function union(left, right)
  local result = {}
  local seen = {}

  for _, file in ipairs(left) do
    seen[file] = true
    result[#result + 1] = file
  end

  for _, file in ipairs(right) do
    if not seen[file] then
      seen[file] = true
      result[#result + 1] = file
    end
  end

  return result
end

---@param left string[]
---@param right string[]
---@return string[]
local function difference(left, right)
  local result = {}

  local right_set = to_set(right)

  for _, file in ipairs(left) do
    if not right_set[file] then
      result[#result + 1] = file
    end
  end

  return result
end

---@param query string
---@return string[]
function M.search(query)
  query = vim.trim(query)

  if query == "" then
    return {}
  end

  local positive = {}
  local negative = {}

  for token in query:gmatch("[^;]+") do
    token = vim.trim(token)

    if token:sub(1, 1) == "!" then
      negative[#negative + 1] = token:sub(2)
    else
      positive[#positive + 1] = token
    end
  end

  local result

  for index, token in ipairs(positive) do
    local files = {}

    if token:find("|", 1, true) then
      local tmp = {}

      for or_term in token:gmatch("[^|]+") do
        tmp = union(tmp, rg_files(vim.trim(or_term)))
      end

      files = tmp
    else
      files = rg_files(token)
    end

    if index == 1 then
      result = files
    else
      result = intersect(result, files)
    end
  end

  result = result or {}

  for _, token in ipairs(negative) do
    result = difference(result, rg_files(token))
  end

  return result
end

return M
