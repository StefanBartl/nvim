---@module 'config.harpoon.utils.normkey'
--- Cross-platform path normalization for stable cache/dedup keys.

local M = {}
local uv = vim.uv or vim.loop

--- Normalize path to a canonical cache/dedup key.
--- - Expands "~"
--- - Optionally realpath() to resolve symlinks (default true)
--- - Normalizes slashes to "/"
--- - Uppercases Windows drive letter ("C:/...")
--- - Collapses duplicate slashes (except UNC prefix)
---@param p string
---@param opts Cfg.Harpoon.NormKeyOpts|nil
---@return string
function M.normkey(p, opts)
  if type(p) ~= "string" or p == "" then
    return ""
  end
  opts = opts or {}
  local use_real = (opts.realpath ~= false) -- default true

  -- Expand tilde if present
  local home = (uv.os_homedir and uv.os_homedir()) or os.getenv("HOME")
  if home then
    p = p:gsub("^~", home)
  end

  local out = p

  if use_real and uv.fs_realpath then
    local rp = uv.fs_realpath(p)
    if rp then
      out = rp
    end
  else
    -- normalize keeps relative parts tidy; not as strong as realpath
    out = vim.fs.normalize(p)
  end

  -- Normalize slashes
  out = out:gsub("\\", "/")

  -- Uppercase drive letter on Windows
  out = out:gsub("^([A-Za-z]):", function(d)
    return string.upper(d) .. ":"
  end)

  -- Collapse duplicate slashes, but keep UNC prefix (//server/share)
  if not out:match("^//") then
    out = out:gsub("//+", "/")
  end

  return out
end

return M
