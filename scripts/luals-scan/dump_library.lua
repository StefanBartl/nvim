-- Ask lsp.nvim what workspace.library it injects, instead of modelling it.
--
-- Run headless with the normal config, so the runtimepath is the real one:
--   LUALS_SCAN_ROOTS="E:/repos/lsp.nvim;E:/repos/dap.nvim" \
--   LUALS_SCAN_OUT="<cache dir>" \
--   nvim --headless -c "luafile scripts/luals-scan/dump_library.lua"
--
-- Writes <out>/<name>.json per root plus <out>/_meta.json. One root takes
-- roughly half a minute -- find_type_dirs walks the tree to depth 15 -- which
-- is why the caller caches per workspace rather than dumping all of them.

local roots_env = vim.env.LUALS_SCAN_ROOTS or ""
local out_dir = vim.env.LUALS_SCAN_OUT

local function die(msg)
  io.stderr:write("DUMP ERROR " .. msg .. "\n")
  vim.cmd("cq!")
end

if out_dir == nil or out_dir == "" then
  die("LUALS_SCAN_OUT is not set")
  return
end

local ok, build = pcall(require, "lsp.servers.lua_ls.build_library")
if not ok or type(build) ~= "function" then
  die("lsp.servers.lua_ls.build_library did not load: " .. tostring(build))
  return
end

vim.fn.mkdir(out_dir, "p")

--- The name a root is filed under -- its basename, with the config spelled out
--- so it does not collide with a plugin called "nvim".
---@param root string
---@return string
local function name_of(root)
  if root == vim.fn.stdpath("config"):gsub("\\", "/") then
    return "nvim-config"
  end
  return (root:gsub("/+$", ""):match("[^/]+$"))
end

local written = 0
for root in vim.gsplit(roots_env, "[;\n]", { trimempty = true }) do
  root = vim.trim(root):gsub("\\", "/"):gsub("/+$", "")
  if root ~= "" then
    local list = {}
    for path in pairs(build(root)) do
      list[#list + 1] = (path:gsub("\\", "/"))
    end
    table.sort(list)

    local path = out_dir .. "/" .. name_of(root) .. ".json"
    local fh = assert(io.open(path, "w"))
    fh:write(vim.json.encode({ root = root, library = list }))
    fh:close()
    written = written + 1
    io.stderr:write(("DUMP %s %d entries\n"):format(name_of(root), #list))
  end
end

local meta = assert(io.open(out_dir .. "/_meta.json", "w"))
meta:write(vim.json.encode({
  vimruntime = (vim.env.VIMRUNTIME or ""):gsub("\\", "/"),
  nvim_config = vim.fn.stdpath("config"):gsub("\\", "/"),
  written_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
}))
meta:close()

io.stderr:write("DUMP ok " .. written .. "\n")
vim.cmd("qa!")
