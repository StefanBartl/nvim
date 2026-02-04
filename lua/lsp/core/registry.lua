---@module 'lsp.core.registry'

local notify = require("lib.notify").create("[lsp.core.registry]")

local M = {}

local desc_tag = "[lsp.registry] "

local ACTIVE = {
  "bashls",
  "lua_ls",
  "gopls",
  "marksman",
  -- "emmet_ls",

  -- Web Development
  "html",
  "ts_ls",
  "astro",
  "tailwindcss",
  "htmx_lsp",
  "wasm_language_tools",

  --"clangd",
  --"csharp",
  --"zig",

  -- Mobile development servers
  "mobiledev.jdtls", -- Java (Android)
  "mobiledev.kotlin_language_server", -- Kotlin (Android)
  "mobiledev.dartls", -- Dart/Flutter
}

---@param shared table
---@return string[]
function M.setup_all(shared)
  if type(shared) ~= "table" then
    return {}
  end

  -- iOS: sourcekit hinzufügen
  if require("lib.cross.platform.is_macos")() then
    ACTIVE[#ACTIVE + 1] = "mobiledev.sourcekit"
  end

  local enabled = {}

  for _, name in ipairs(ACTIVE) do
    -- Versuche beide Pfade: direkter Name und webdev-Präfix
    local paths = {
      "lsp.servers." .. name,
    }

    -- Falls Name kein Punkt enthält, auch webdev-Variante versuchen
    if not name:match("%.") then
      paths[#paths + 1] = "lsp.servers.webdev." .. name
    end

    if not name:match("%.") then
      paths[#paths + 1] = "lsp.servers.mobiledev." .. name
    end

    local loaded = false
    local last_error = nil

    for _, mod_path in ipairs(paths) do
      local ok, srv = pcall(require, mod_path)
      if ok and type(srv) == "table" and type(srv.setup) == "function" then
        local ok_setup, err = pcall(srv.setup, shared)
        if ok_setup then
          enabled[#enabled + 1] = name
          loaded = true
          break
        else
          last_error = err
        end
      end
    end

    if not loaded then
      if last_error then
        notify.warn((desc_tag .. "setup failed for '%s': %s"):format(name, last_error or "?"))
      else
        notify.info((desc_tag .. ("server module '%s' unavailable"):format()):format(name))
      end
    end
  end

  return enabled
end

return M
