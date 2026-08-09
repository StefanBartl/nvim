local M = {}

function M.status()
  -- Nutze ipinfo.io, um Provider und Land zu ermitteln
  local handle = io.popen("curl -s ipinfo.io")
  if not handle then return "VPN?" end
  local data = handle:read("*a")
  handle:close()

  local org = data:match('"org":%s-"(.-)"') or ""
  local country = data:match('"country":%s-"(%a%a)"') or "??"

  if org:match("Proton") or org:match("Datacamp") then
    return "🔐WG(" .. country .. ")"
  end

  return ""
end

return M

