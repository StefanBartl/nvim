---@module 'lib.crosss.windows.has_win_sep.init.lua'

---@param s string
---@return boolean
return function (s)
  -- "E:/path/.." or "C:\path\.."
  return s:match("^[A-Za-z]:[\\/]")
end
