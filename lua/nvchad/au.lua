---@module 'nvchad.au'
-- Override of NvChad's ui/lua/nvchad/au.lua.
--
-- The upstream version builds the "reload config on save" BufWritePost
-- autocmd by eagerly globbing every *.lua file under stdpath("config")/lua
-- and resolving each one with vim.uv.fs_realpath — ~450 files, ~450 sync
-- syscalls, ~600ms on every startup (measured via `nvim --startuptime`).
-- That cost is paid unconditionally, whether or not a session/file is even
-- opened, because it's wired via vim.schedule() from nvchad/init.lua.
--
-- This override keeps the same feature (auto-reload on save) but matches
-- lazily via a callback filter instead of precomputing the full path list,
-- so the cost only applies once you actually save a file, not on startup.

local autocmd = vim.api.nvim_create_autocmd
local config = require "nvconfig"

-- load nvdash only on empty file
if config.nvdash.load_on_startup then
  local opening_file = vim.api.nvim_buf_get_name(0)
  local is_dir = vim.fn.isdirectory(opening_file) == 1
  local bufmodifed = vim.api.nvim_get_option_value("modified", { buf = 0 })

  if not bufmodifed and (is_dir or opening_file == "") then
    local current_buffer = vim.api.nvim_get_current_buf()
    require("nvchad.nvdash").open()
    vim.api.nvim_buf_delete(current_buffer, { force = true, unload = false })
  end
end

if config.lsp.signature then
  autocmd("LspAttach", {
    callback = function(args)
      vim.schedule(function()
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client then
          local signatureProvider = client.server_capabilities.signatureHelpProvider
          if signatureProvider and signatureProvider.triggerCharacters then
            require("nvchad.lsp.signature").setup(client, args.buf)
          end
        end
      end)
    end,
  })
end

-- reload the plugin! (lazy match: no startup-time glob/realpath scan)
local config_lua_dir = vim.fs.normalize(vim.fn.stdpath "config" .. "/lua") .. "/"

autocmd("BufWritePost", {
  pattern = "*.lua",
  group = vim.api.nvim_create_augroup("ReloadNvChad", {}),

  callback = function(opts)
    local abs = vim.fs.normalize(vim.api.nvim_buf_get_name(opts.buf))
    if abs:sub(1, #config_lua_dir) ~= config_lua_dir then
      return
    end

    local fp = vim.fn.fnamemodify(abs, ":r") --[[@as string]]
    local app_name = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME or "nvim"
    local module = string.gsub(fp, "^.*/" .. app_name .. "/lua/", ""):gsub("/", ".")

    require("nvchad.utils").reload(module)
    -- vim.cmd("redraw!")
  end,
})

vim.api.nvim_create_user_command("MasonInstallAll", function()
  require("nvchad.mason").install_all()
end, {})

if config.colorify.enabled then
  require("nvchad.colorify").run()
end

local dir = vim.fn.stdpath "data" .. "/nvnotify1"

if not vim.uv.fs_stat(dir) then
  vim.fn.mkdir(dir, "p")
  require "nvchad.winmes" {
    { "* Blink.cmp plugin integration has been added, will be tested for 2 months" },
    { " " },
    { '* { import = "nvchad.blink.lazyspec" } in your plugins file' },
    { " " },
    { "* Discuss at https://github.com/NvChad/NvChad/discussions/3244" },
  }
end
