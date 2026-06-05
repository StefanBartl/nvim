---@module 'custom.pdfport.health'
---@brief :checkhealth provider for pdfport.
---@description
--- Reports on the availability of all extraction backends, renderers,
--- and optional dependencies. Accessible via :checkhealth pdfport.

local M = {}

--- vim.health compatibility shim (api changed in nvim 0.10)
local health = vim.health or require("health")

local ok    = health.ok    or health.report_ok
local warn  = health.warn  or health.report_warn
local err   = health.error or health.report_error
local start = health.start or health.report_start
local info  = health.info  or health.report_info

local platform = require("custom.pdfport.platform")
local registry = require("custom.pdfport.core.registry")

-- #############################################################################
-- Helpers
-- #############################################################################

---@param name string
---@param required boolean
---@return boolean available
local function check_exe(name, required)
  if platform.has(name) then
    ok(name .. " found on PATH")
    return true
  end

  if required then
    err(name .. " NOT found on PATH (required)")
  else
    warn(name .. " NOT found on PATH (optional)")
  end

  return false
end

-- #############################################################################
-- Health sections
-- #############################################################################

local function check_core()
  start("pdfport: core")

  local ok_init, _ = pcall(require, "custom.pdfport")
  if ok_init then
    ok("custom.pdfport module loads without error")
  else
    err("custom.pdfport module failed to load")
  end

  local ok_reg, _ = pcall(require, "custom.pdfport.core.registry")
  if ok_reg then
    ok("core.registry loads")
  else
    err("core.registry failed to load")
  end

  local ok_res, _ = pcall(require, "custom.pdfport.core.resolver")
  if ok_res then
    ok("core.resolver loads")
  else
    err("core.resolver failed to load")
  end

  local ok_dis, _ = pcall(require, "custom.pdfport.core.dispatcher")
  if ok_dis then
    ok("core.dispatcher loads")
  else
    err("core.dispatcher failed to load")
  end
end

local function check_backends()
  start("pdfport: extraction backends")

  -- pdftotext (recommended baseline)
  if check_exe("pdftotext", false) then
    ok("pdftotext backend: ready (install poppler-utils for full support)")
  else
    warn("pdftotext backend: unavailable – install poppler-utils")
  end

  -- pdfplumber
  if platform.has("python3") then
    ok("python3 found")
    if platform.has_python_module("pdfplumber") then
      ok("pdfplumber Python module: available")
    else
      warn("pdfplumber Python module: not installed (pip install pdfplumber)")
    end
  else
    warn("python3 NOT found – pdfplumber and marker backends unavailable")
  end

  -- marker
  if check_exe("marker_single", false) then
    ok("marker backend: ready")
  else
    warn("marker backend: marker_single not on PATH (pip install marker-pdf)")
  end

  -- docling
  if platform.has("python3") then
    if platform.has_python_module("docling") then
      ok("docling Python module: available")
    else
      warn("docling Python module: not installed (pip install docling)")
    end
  end

  -- ollama
  if check_exe("ollama", false) then
    ok("ollama binary found")
    -- Check if daemon is running by probing the API
    local result = vim.fn.system("curl -s -o /dev/null -w '%{http_code}' http://localhost:11434/api/tags 2>/dev/null")
    if result and result:match("^200") then
      ok("ollama daemon is running on localhost:11434")
    else
      warn("ollama daemon does not appear to be running (start with: ollama serve)")
    end
  else
    warn("ollama not installed (optional AI backend)")
  end

  -- claude
  if check_exe("curl", true) then
    local key = vim.env.ANTHROPIC_API_KEY
    if key and key ~= "" then
      ok("ANTHROPIC_API_KEY is set (" .. #key .. " chars)")
    else
      warn("ANTHROPIC_API_KEY not set – claude backend unavailable")
      info("Set it via: export ANTHROPIC_API_KEY=sk-ant-...")
    end
  end
end

local function check_renderers()
  start("pdfport: renderers")

  -- buffer / float: always available (pure Lua)
  ok("buffer renderer: built-in (always available)")
  ok("float renderer: built-in (always available)")

  -- system open
  local sys = platform.open_cmd()
  if sys then
    ok("system renderer: " .. sys .. " found")
  else
    err("system renderer: no open command found (xdg-open / open)")
  end

  -- terminal image rendering
  start("pdfport: terminal image renderer")

  check_exe("pdftoppm", false)  -- needed to rasterize pages

  local tool = platform.best_terminal_renderer()
  if tool then
    ok("best terminal renderer: " .. tool)
  else
    warn("no terminal image renderer found")
    info("Install one of: ueberzugpp, chafa, kitten, imgcat")
  end

  check_exe("ueberzugpp", false)
  check_exe("chafa",      false)
end

local function check_integrations()
  start("pdfport: integrations")

  local ok_neo, _ = pcall(require, "neo-tree")
  if ok_neo then
    ok("neo-tree.nvim found – integration available")
  else
    info("neo-tree.nvim not loaded – neotree integration inactive")
  end

  local ok_tel, _ = pcall(require, "telescope")
  if ok_tel then
    ok("telescope.nvim found – integration available")
  else
    info("telescope.nvim not loaded – telescope integration inactive")
  end

  local ok_fzf, _ = pcall(require, "fzf-lua")
  if ok_fzf then
    ok("fzf-lua found – integration available")
  else
    info("fzf-lua not loaded – fzf integration inactive")
  end

  local ok_hover, _ = pcall(require, "lib.ui.hover_select")
  if ok_hover then
    ok("lib.ui.hover_select found – mode picker available")
  else
    warn("lib.ui.hover_select not found – mode picker will fallback to vim.ui.select")
  end
end

local function check_registry_state()
  start("pdfport: registered backends")

  local backends = registry.all_backends()
  if #backends == 0 then
    warn("No backends registered – call require('custom.pdfport').setup() first")
    return
  end

  for _, b in ipairs(backends) do
    local avail_ok, avail = pcall(b.available)
    local status = (avail_ok and avail) and "available" or "unavailable"
    if avail_ok and avail then
      ok(string.format("%-14s  %s", b.id, status))
    else
      warn(string.format("%-14s  %s", b.id, status))
    end
  end
end

-- #############################################################################
-- Entry point
-- #############################################################################

--- Called by :checkhealth pdfport
function M.check()
  check_core()
  check_backends()
  check_renderers()
  check_integrations()
  check_registry_state()
end

return M
