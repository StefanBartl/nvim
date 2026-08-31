-- Ask lsp.nvim what workspace.library it injects, instead of modelling it.
--
-- Run headless with the normal config, so the runtimepath is the real one.
-- LUALS_SCAN_ROOTS is a ";"-separated list. An entry is either a plain root or
-- "<name>=<root>", where <name> is the file the dump is written to:
--   LUALS_SCAN_ROOTS="lsp.nvim=E:/repos/lsp.nvim;nvim-config=E:/wt/cfg" \
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

---@param path string
---@return string
local function normalize(path)
  return (vim.trim(path):gsub("\\", "/"):gsub("/+$", ""))
end

local config_root = normalize(vim.fn.stdpath("config"))

--- Split one LUALS_SCAN_ROOTS entry into the name its dump is filed under and
--- the root to dump.
---
--- The caller may name the file itself with a "<name>=" prefix, and for the
--- config it has to: this nvim runs with the real config, so a scan started
--- from a git worktree hands over a root that is not stdpath("config") but
--- still belongs in nvim-config.json. Without a prefix the name is the
--- basename, with the config spelled out so it does not collide with a plugin
--- called "nvim".
---@param entry string
---@return string name
---@return string root
local function split_entry(entry)
  local name, root = entry:match("^([^=]+)=(.+)$")
  if name then
    return vim.trim(name), normalize(root)
  end
  root = normalize(entry)
  if root == "" then
    return "", ""
  end
  if root == config_root then
    return "nvim-config", root
  end
  return root:match("[^/]+$"), root
end

local written = 0
for entry in vim.gsplit(roots_env, "[;\n]", { trimempty = true }) do
  local name, root = split_entry(entry)
  if root ~= "" and name ~= "" then
    local list = {}
    for path in pairs(build(root)) do
      list[#list + 1] = (path:gsub("\\", "/"))
    end
    table.sort(list)

    local path = out_dir .. "/" .. name .. ".json"
    local fh = assert(io.open(path, "w"))
    fh:write(vim.json.encode({ root = root, library = list }))
    fh:close()
    written = written + 1
    io.stderr:write(("DUMP %s %d entries\n"):format(name, #list))
  end
end

local meta = assert(io.open(out_dir .. "/_meta.json", "w"))
meta:write(vim.json.encode({
  vimruntime = (vim.env.VIMRUNTIME or ""):gsub("\\", "/"),
  nvim_config = config_root,
  written_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
}))
meta:close()

io.stderr:write("DUMP ok " .. written .. "\n")
vim.cmd("qa!")
