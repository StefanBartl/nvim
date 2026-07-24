---@module 'wkdnvchad.ui.statusline.modules.neotest_module'

return function()
  local ok, neotest = pcall(require, "neotest")
  if not ok then return "" end

  local status = neotest.run.get_status()

  -- Nur anzeigen, wenn tatsächlich Tests laufen oder Ergebnisse vorliegen
  if not status or (status.passed == 0 and status.failed == 0 and status.running == 0) then
    return ""
  end

  local result = " "

  -- Laufende Tests (Blau)
  if status.running > 0 then
    result = result .. "%#St_LspProgress#󱎫 " .. status.running .. " "
  end
  -- Bestandene Tests (Grün)
  if status.passed > 0 then
    result = result .. "%#St_LspHints#󰄬 " .. status.passed .. " "
  end
  -- Fehlgeschlagene Tests (Rot)
  if status.failed > 0 then
    result = result .. "%#St_LspError#󰅖 " .. status.failed .. " "
  end

  return result
end
