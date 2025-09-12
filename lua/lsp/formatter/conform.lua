---@module 'lsp.formatter.conform'
---@class ConformPolicy

local M = {}

---@return nil
function M.setup()
  local ok, conform = pcall(require, "conform")
  if not ok then return end

  -- Resolve mdformat path robustly (pipx, pyenv, Windows/Linux)
  local uv = vim.uv or vim.loop
  local function resolve(cmd)
    local exepath = vim.fn.exepath(cmd)
    if exepath and exepath ~= "" then return exepath end
    local home = (uv.os_homedir and uv.os_homedir()) or os.getenv("HOME") or os.getenv("USERPROFILE") or ""
    local candidates = {
      home .. "/.local/bin/" .. cmd,                      -- Linux pipx/pip user base
      home .. "/.pyenv/shims/" .. cmd,                    -- pyenv
      home .. "/AppData/Roaming/Python/Scripts/" .. cmd .. ".exe", -- Windows pip user base
    }
    for _, p in ipairs(candidates) do
      if type(p) == "string" and p ~= "" and uv.fs_stat(p) then return p end
    end
    return cmd -- fallback to plain name; Conform prüft selbst noch einmal
  end

  conform.setup({
    -- Wichtig: MD bekommt mdformat (falls vorhanden) mit Fallback auf prettier;
    -- MDX direkt zu prettier (mdformat kann kein MDX).
    formatters_by_ft = {
      lua = { "stylua" },
      go = { "goimports", "gofmt" },
      javascript = { "prettierd", "prettier" },
      typescript = { "prettierd", "prettier" },
      typescriptreact = { "prettierd", "prettier" },
      javascriptreact = { "prettierd", "prettier" },
      json = { "jq" },
      css = { "prettierd", "prettier" },
      html = { "prettierd", "prettier" },
      zig = { "zigfmt" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      cs = { "csharpier" },

      markdown = { "mdformat", "prettierd", "prettier" },
      ["markdown.mdx"] = { "prettierd", "prettier" },
    },

    -- mdformat liest aus STDIN nur mit "-" zuverlässig
    formatters = {
      mdformat = {
        command = resolve("mdformat"),
        args = { "-" },
        stdin = true,
      },
      -- (Optional) stelle sicher, dass prettier zur Not stdin liest:
      prettier = {
        prepend_args = { "--stdin-filepath", "$FILENAME" },
      },
    },

    notify_on_error = true,
  })
end

return M
