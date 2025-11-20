---@module 'lib._trim'
--- Trim ASCII whitespace (space, tab, CR, LF)

---@param s string
---@return string
return function(s)
  -- Use a single pattern capture to return the trimmed string.
  return (s or ""):match("^%s*(.-)%s*$")
end
