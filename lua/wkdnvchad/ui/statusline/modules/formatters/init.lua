---@module 'wkdnvchad.ui.statusline.modules.formatters'
--- Statusline formatters with string pooling and lib.strings integration
--- Optimized: string operations, caching, proper error handling

---@type WkdNvC.UI.Stl.Modules.LSP.Cfg.Module
local config_module = require("lib.lazy").require("wkdnvchad.ui.statusline.modules.lsp.config")

-- String pool for common operations
local ellipsize_cache = require("lib.memo.lru").new(64)
local escape_cache = {}

-- Clear caches on colorscheme change
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("WkdNvChadFormattersCache", { clear = true }),
  callback = function()
    escape_cache = {}
    -- LRU cache is self-managing
  end,
  desc = "Clear formatters cache on colorscheme change",
})

local M = {}

---@nodiscard
---@param s string
---@return string
function M.stl_escape(s)
  if not s or s == "" then
    return ""
  end

  local cached = escape_cache[s]
  if cached then
    return cached
  end

  local result = s:gsub("%%", "%%%%")
  escape_cache[s] = result
  return result
end

---@nodiscard
---@param s string
---@param max integer
---@return string
function M.ellipsize_middle(s, max)
  if type(s) ~= "string" then
    return ""
  end

  if max <= 0 or #s <= max then
    return s
  end

  local cache_key = s .. ":" .. tostring(max)
  local cached = ellipsize_cache:get(cache_key)
  if cached then
    return cached
  end

  local head = math.floor((max - 1) / 2)
  local tail = max - head - 1
  local result = string.sub(s, 1, head) .. "…" .. string.sub(s, #s - tail + 1, #s)

  ellipsize_cache:put(cache_key, result)
  return result
end

---@nodiscard
---@param path string                -- path to display (absolute or relative)
---@param max integer                -- maximum number of characters to use
---@return string                    -- compacted path that fits into `max`
function M.ellipsize_path_components(path, max)
  -- Fast path
  if max <= 0 or #path <= max then
    return path
  end

  -- Normalize separators for splitting, but remember a prefix we always keep:
  --  - Windows drive root like "C:\"
  --  - POSIX root "/"
  --  - Tilde home "~"
  local p = path
  p = p:gsub("\\", "/")

  local prefix = ""
  local rest = p

  do
    -- Normalize backslashes first (this already happens earlier in your function)
    p = p:gsub("\\", "/")

    -- Windows drive root (normalized): "C:/"
    local drive = rest:match("^([A-Za-z]:)/")
    if drive then
      prefix = drive .. "/"
      -- drop the leading "C:/"
      rest = rest:sub(#drive + 2) -- 2 = length(":/") minus 1 due to 1-based indexing (+1 done by sub())
    elseif rest:sub(1, 2) == "~/" then
      prefix = "~"
      rest = rest:sub(3)
    elseif rest:sub(1, 1) == "/" then
      prefix = "/"
      rest = rest:sub(2)
    else
      prefix = "" -- relative path
    end
    if drive then
      prefix = drive .. "/"
      rest = rest:sub(#drive + 2) -- skip "C:" + separator
    elseif rest:sub(1, 2) == "~/" then
      prefix = "~"
      rest = rest:sub(3)
    elseif rest:sub(1, 1) == "/" then
      prefix = "/"
      rest = rest:sub(2)
    else
      prefix = "" -- relative path
    end
  end

  -- Split remaining into components (ignore empty)
  ---@type string[]
  local parts = {}
  for seg in rest:gmatch("[^/]+") do
    parts[#parts + 1] = seg
  end

  -- Reconstitute quickly if still fits
  local function join_all()
    if #parts == 0 then
      return prefix
    end
    return prefix .. table.concat(parts, "/")
  end
  local full = join_all()
  if #full <= max then
    return full
  end

  -- If there are fewer than 2 components, there is nothing to drop safely.
  -- Fall back to middle ellipsis (filename can be long; directories rule does not apply here).
  if #parts <= 1 then
    return M.ellipsize_middle(full, max)
  end

  -- Always try to keep: prefix + first-dir + "…/" + last
  local first = parts[1]
  local last = parts[#parts]

  local function build_min()
    return prefix .. first .. "/…/" .. last
  end

  local min_s = build_min()
  if #min_s > max then
    -- If even that doesn't fit, drop the first directory but keep the prefix if present.
    -- Example: "/…/filename" or "C:/…/filename".
    local alt = (prefix ~= "" and (prefix .. "…/" .. last)) or ("…/" .. last)
    if #alt <= max then
      return alt
    end
    -- As an absolute last resort, ellipsize the whole string.
    return M.ellipsize_middle(full, max)
  end

  -- Greedily add more components from the RIGHT (towards the beginning),
  -- while respecting the maximum length.
  -- Result shape: prefix + first + "/…/" + [extra_right_segments/] + last
  local right = {} ---@type string[]
  local cur = #min_s
  local i = #parts - 1
  while i >= 2 do
    local cand_len = cur + 1 + #parts[i] -- + "/" + segment length
    if cand_len > max then
      break
    end
    table.insert(right, 1, parts[i]) -- prepend so order stays natural
    cur = cand_len
    i = i - 1
  end

  if #right == 0 then
    return min_s
  end

  return prefix .. first .. "/…/" .. table.concat(right, "/") .. "/" .. last
end

--- Build the visible line with component-aware path compaction.
--- If `total_maxw` is nil, it derives from cfg.center_width_frac/center_width_min.
---@param rel string
---@param ctx string|nil
---@param sep string
---@param total_maxw integer|nil
---@return string line
function M.compact_breadcrumb_line(rel, ctx, sep, total_maxw)
  local options = config_module.get_cfg()

  local target = total_maxw
  if not target or target <= 0 then
    local frac = options.center_width_frac or 0.50
    local minw = options.center_width_min or 30
    target = math.max(minw, math.floor(vim.o.columns * frac))
  end

  if ctx and #ctx > 0 then
    local static_len = #sep + #ctx
    local room = target - static_len
    if options.path_max_chars then
      room = math.min(room, options.path_max_chars)
    else
      local pfrac = options.path_max_frac or 0.60
      room = math.min(room, math.floor(target * pfrac))
    end

    if room > (options.path_min_room or 8) then
      local rel_compact = M.ellipsize_path_components(rel, room)
      local candidate = rel_compact .. sep .. ctx
      if #candidate <= target then
        return candidate
      else
        return M.ellipsize_middle(candidate, target)
      end
    else
      return M.ellipsize_middle(rel .. sep .. ctx, target)
    end
  else
    -- Kein Kontext: nur Pfad kürzen
    local limit = options.path_max_chars or target
    local compact = M.ellipsize_path_components(rel, limit)
    if #compact > target then
      compact = M.ellipsize_middle(compact, target)
    end
    return compact
  end
end

return M
