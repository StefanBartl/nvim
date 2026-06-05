-- =============================================================================
-- lua/custom/pdfport/renderers/system.lua
-- =============================================================================
---@module 'custom.pdfport.renderers.system'
---@brief Opens a PDF with the operating system's default application.

local sys_mod  = {}
local platform = require("custom.pdfport.platform")

---@param _ PdfPort.Result  (unused, path comes from opts)
---@param opts PdfPort.OpenOpts
---@return nil
function sys_mod.render(_, opts)
  local path = opts.path
  if not path or path == "" then
    vim.notify("pdfport system: no path provided", vim.log.levels.ERROR)
    return
  end

  local cmd = platform.open_cmd()
  if not cmd then
    vim.notify(
      "pdfport system: no system open command found (xdg-open / open)",
      vim.log.levels.ERROR
    )
    return
  end

  vim.fn.jobstart({ cmd, path }, {
    detach = true,
    on_exit = function(_, code, _)
      if code ~= 0 then
        vim.notify(
          string.format("pdfport system: %s exited with code %d", cmd, code),
          vim.log.levels.WARN
        )
      end
    end,
  })
end

return sys_mod
