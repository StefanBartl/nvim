---@module 'bindings.usrcmds.case.detect'
--- Best-effort field guesses from a case's existing content, so the
--- infocard form (§7 of the concept) arrives pre-filled instead of blank.
--- Every guess is a *suggestion* — the caller decides whether to keep it;
--- nothing here writes to `.case.json`.

local read = require("lib.nvim.fs.read")
local collect_recursive = require("lib.nvim.fs.collect_recursive")

local M = {}

local MAX_FILES = 40   -- a case folder has a handful of files, this is a safety cap
local MAX_LINES = 400  -- per file, while scanning for the H1/greeting

---@param case_dir string
---@return string[] paths markdown/text files under case_dir, most-recently-modified first
local function case_files(case_dir)
  local uv = vim.uv or vim.loop
  local files = collect_recursive.files(case_dir, {
    ignore = function(p) return p:match("%.json$") ~= nil end,
  })

  table.sort(files, function(a, b)
    local sa = uv.fs_stat(a)
    local sb = uv.fs_stat(b)
    local ma = sa and sa.mtime and sa.mtime.sec or 0
    local mb = sb and sb.mtime and sb.mtime.sec or 0
    return ma > mb
  end)

  if #files > MAX_FILES then
    local capped = {}
    for i = 1, MAX_FILES do
      capped[i] = files[i]
    end
    files = capped
  end
  return files
end

---@param case_dir string
---@return string|nil title  first level-1 heading found across the case's files
function M.title(case_dir)
  for _, path in ipairs(case_files(case_dir)) do
    local content = read(path)
    if content then
      -- Strip CR up front: files in this bestand are CRLF, and leaving a
      -- trailing \r in a match moves the terminal cursor rather than
      -- ending the string, corrupting anything printed right after it.
      for line in (content:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
        local h1 = line:match("^#%s+(.+)$")
        if h1 then
          -- Strip our own headline scaffolding ("<case> - `<title>` - <file>")
          -- back down to just the title, if this file already has one.
          local inner = h1:match("^%S+%s*%-%s*`(.-)`%s*%-")
          return inner or h1
        end
      end
    end
  end
  return nil
end

---@param case_dir string
---@return string|nil name  the addressee from the newest "Dear X," in Replies/
function M.name(case_dir)
  local newest, newest_mtime = nil, -1
  local uv = vim.uv or vim.loop
  for _, path in ipairs(case_files(case_dir)) do
    if path:match("/Replies/") then
      local st = uv.fs_stat(path)
      local mtime = st and st.mtime and st.mtime.sec or 0
      if mtime > newest_mtime then
        newest, newest_mtime = path, mtime
      end
    end
  end
  if not newest then
    return nil
  end
  local content = read(newest)
  if not content then
    return nil
  end
  return content:match("[Dd]ear%s+([%w%s]-)[,:]")
end

---@param case_dir string
---@return string[] links  deduplicated URLs found across the case's files
function M.links(case_dir)
  local seen, out = {}, {}
  local count = 0
  for _, path in ipairs(case_files(case_dir)) do
    local content = read(path)
    if content then
      local n = 0
      for url in content:gmatch("https?://[%w%-%._~:/?#%[%]@!%$&'%(%)%*%+,;=%%]+") do
        url = url:gsub("[%.,;:%)]+$", "") -- trailing punctuation from prose
        if not seen[url] then
          seen[url] = true
          out[#out + 1] = url
          count = count + 1
        end
        n = n + 1
        if n > MAX_LINES then
          break
        end
      end
    end
    if count >= 50 then
      break
    end
  end
  return out
end

--- Everything at once — what the infocard's edit form pre-fills with.
---@param case_dir string
---@return { title: string|nil, name: string|nil, links: string[] }
function M.guess(case_dir)
  return {
    title = M.title(case_dir),
    name = M.name(case_dir),
    links = M.links(case_dir),
  }
end

return M
