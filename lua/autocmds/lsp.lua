vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local lspconfig = require("configs.lspconfig")

    -- Nur wenn lua_ls noch nicht läuft
    for _, client in ipairs(vim.lsp.get_active_clients()) do
      if client.name == "lua_ls" then
        print("✅ lua_ls already active")
        return
      end
    end

    -- Suche eine existierende Lua-Datei im Projekt
    local lua_files = vim.fn.globpath(vim.fn.getcwd(), "**/*.lua", true, { true })
    local first_file = lua_files[1]

    if not first_file then
      print("⚠️ Keine Lua-Datei im Projekt gefunden.")
      return
    end

    -- Erzeuge unsichtbaren echten Buffer mit der Datei
    local buf = vim.fn.bufadd(first_file)
    vim.fn.bufload(buf) -- Lade den Buffer ohne Öffnen
    vim.api.nvim_buf_set_option(buf, "filetype", "lua")

    -- Starte LSP für diesen Buffer
    local ok = lspconfig.lua_ls.manager.try_add(buf)
    if ok then
      print("🚀 lua_ls gestartet für Buffer: " .. first_file)
    else
      print("❌ Konnte lua_ls nicht starten.")
    end

    -- Unsichtbar und temporär lassen
  end,
})
