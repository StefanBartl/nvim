--- @module 'lib.map'
-- =========================================================
-- Keymap helper utilities.
--
-- Standardized wrapper around vim.keymap.set with sane
-- defaults and optional buffer scoping.
-- =========================================================

--FIX: type of opts einfügen. ist das vim.kemaps.set.Opts?



---Convenience wrapper for vim.keymap.set with sane defaults.
---@param modes string|string[]
---@param lhs string
---@param rhs string|function
---@param opts table|nil
---@param desc string?
return function(modes, lhs, rhs, opts, desc)
  opts = opts or {}

  if type(desc) == "string" then
    opts.desc = desc
  end

  if opts.desc == nil then
    opts.desc = ""
  end

  if opts.noremap == nil then
    opts.noremap = true
  end
  if opts.silent == nil then
    opts.silent = true
  end
  vim.keymap.set(modes, lhs, rhs, opts)
end
