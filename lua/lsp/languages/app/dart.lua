---@module 'lsp.languages.app.dart'

local M = {}

local api = vim.api

---@return nil
function M.enable()
  local grp = api.nvim_create_augroup("LangDart", { clear = true })

  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "dart" },
    callback = function(ev)
      local bufnr = ev.buf

      vim.bo[bufnr].shiftwidth = 2
      vim.bo[bufnr].tabstop = 2
      vim.bo[bufnr].expandtab = true

      -- Hot reload keybinding for Flutter
      pcall(vim.keymap.set, "n", "<leader>fr", function()
        vim.notify("Flutter: Hot Reload", vim.log.levels.INFO)
        vim.cmd("!flutter run --hot-reload")
      end, { buffer = bufnr, desc = "Flutter: Hot Reload" })
    end,
  })
end

---@type Lsp.Languages.ConfiguredLangs.Dart.Module
return M
