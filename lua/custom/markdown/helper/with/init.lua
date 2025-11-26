---@module 'custom.markdown.helper.with'

-- Stellt sicher, dass die Werte aus `extra` im `base` table enthalten sind
--  - wenn `extra` `nil` oder keine `table` ist, wird `base` unverändert zurückgegeben
--  - wenn `base` `nil` oder kein `table` ist, wird `extra` unverändert zurückgegeben
---@param base table|nil
---@param extra table|nil
---@return table
return function(base, extra)
  if not extra or type(extra) ~= "table" then
    return base or {}
  end
  if not base or type(base) ~= "table" then
    return extra
  end

  for k, v in pairs(extra) do
    base[k] = v
  end
  return base
end
