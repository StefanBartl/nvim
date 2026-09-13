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

local autocmd = require("lib.nvim.bindings.autocmd")
local config = require("nvconfig")

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

-- `nvchad.lsp.signature` used to attach here on `LspAttach`, gated by
-- nvconfig's own `config.lsp.signature` -- an automatic popup on the LSP's
-- own trigger characters. `lsp.nvim` already ships its own signature/hover
-- tool (lua/lsp/tools/lsp_signature/, `tools.lsp_signature.enable = true`
-- by default, which this host never overrides) -- a persistent floating
-- popup toggled manually on <C-b> in insert and normal mode, not an
-- automatic one, so this is a real UX change: signature help is now
-- summoned, not popped up while typing.

-- reload the plugin! (lazy match: no startup-time glob/realpath scan)
local config_lua_dir = vim.fs.normalize(vim.fn.stdpath("config") .. "/lua") .. "/"

autocmd.create("BufWritePost", function(opts)
  local abs = vim.fs.normalize(vim.api.nvim_buf_get_name(opts.buf))
  if abs:sub(1, #config_lua_dir) ~= config_lua_dir then
    return
  end

  local fp = vim.fn.fnamemodify(abs, ":r") --[[@as string]]
  local app_name = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME or "nvim"
  local module = string.gsub(fp, "^.*/" .. app_name .. "/lua/", ""):gsub("/", ".")

  require("nvchad.utils").reload(module)
end, {
  group = "ReloadNvChad",
  pattern = "*.lua",
  desc = "NvChad: reload a config module after saving it",
})

require("lib.nvim.bindings.usercmd").create("MasonInstallAll", function()
  require("nvchad.mason").install_all()
end, { desc = "NvChad: install every configured Mason package" })

-- `nvchad.colorify` used to run here, gated by nvconfig's own
-- `config.colorify.enabled`. Replaced by plugins/ui.lua's own
-- catgoose/nvim-colorizer.lua entry (nvim-highlight-colors as its opt-in
-- alternative), which never depended on NvChad in the first place -- only
-- on being declared somewhere. Running both would double-highlight every
-- match, so this call is gone rather than merely disabled.

local dir = vim.fn.stdpath("data") .. "/nvnotify1"

if not vim.uv.fs_stat(dir) then
  vim.fn.mkdir(dir, "p")
  require("nvchad.winmes")({
    { "* Blink.cmp plugin integration has been added, will be tested for 2 months" },
    { " " },
    { '* { import = "nvchad.blink.lazyspec" } in your plugins file' },
    { " " },
    { "* Discuss at https://github.com/NvChad/NvChad/discussions/3244" },
  })
end
