---@module 'lsp.usercmds'
---

local nvim_create_user_command = vim.api.nvim_create_user_command
local lsp = vim.lsp

local M = {}

local desc_tag = "[lsp] "

-- =============

local function _active_servers()
  local ok, reg = pcall(require, "lsp.core.registry")
  if not ok or type(reg) ~= "table" then
    return {}
  end
  return { "lua_ls", "ts_ls", "gopls", "marksman" }
end

local function _buf_clients(bufnr)
  return lsp.get_clients({ bufnr = bufnr or 0 })
end

-- =============
-- Lsp Start

--- Get list of installed LSPs via Mason
---@return string[]
local function get_installed_lsps()
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return {}
  end
  local lsps = {}
  for _, pkg in ipairs(registry.get_installed_packages()) do
    if pkg:is_installed() and pkg:is_lsp() then
      table.insert(lsps, pkg.name)
    end
  end
  table.sort(lsps)
  return lsps
end

--- Start the LSP by name
---@param name string
local function start_lsp(name)
  if not name or name == "" then
    vim.notify("No LSP name provided", vim.log.levels.WARN)
    return
  end
  local clients = vim.lsp.get_clients({ name = name })
  if #clients > 0 then
    vim.notify("LSP '" .. name .. "' already running", vim.log.levels.INFO)
    return
  end

  -- Try to require lspconfig and start server
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then
    vim.notify("lspconfig not available", vim.log.levels.ERROR)
    return
  end

  if not lspconfig[name] then
    vim.notify("LSP '" .. name .. "' not configured in lspconfig", vim.log.levels.ERROR)
    return
  end

  lspconfig[name].launch()
  vim.notify("Starting LSP: " .. name, vim.log.levels.INFO)
end

-- Abhängigkeit auf Telescope prüfen
local has_telescope, telescope = pcall(require, "telescope.builtin")

--- UserCommand handler
---@param args table
function M.cmd(args)
  local lsp_name = args.args
  if lsp_name == "" and has_telescope then
    -- Show Mason LSP picker
    local lsps = get_installed_lsps()
    if #lsps == 0 then
      vim.notify("No Mason LSPs installed", vim.log.levels.WARN)
      return
    end
    telescope.pickers
      .new({}, {
        prompt_title = "Start LSP",
        finder = telescope.finders.new_table({ results = lsps }),
        sorter = telescope.config.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
          telescope.actions.select_default:replace(function()
            local selection = telescope.actions.get_selected_entry(prompt_bufnr)
            telescope.actions.close(prompt_bufnr)
            start_lsp(selection[1])
          end)
          return true
        end,
      })
      :find()
  else
    -- Direct start via string
    start_lsp(lsp_name)
  end
end

-- =============

---@return nil
function M.attach()
  vim.api.nvim_create_user_command("LspStart", function(args)
    M.cmd(args)
  end, {
    nargs = "?",
    complete = function()
      return get_installed_lsps()
    end,
    desc = "Start a Mason-installed LSP or via name",
  })

  pcall(nvim_create_user_command, "LspStartHere", function()
    for _, name in ipairs(_active_servers()) do
      pcall(lsp.enable, name) -- (neu) native API
    end
  end, { desc = desc_tag .. "Start/attach configured LSP servers for current buffer (vim.lsp)" })

  pcall(nvim_create_user_command, "LspStopHere", function()
    local ids = {}
    for _, c in ipairs(_buf_clients(0)) do
      ids[#ids + 1] = c.id
    end
    if #ids > 0 then
      lsp.stop_client(ids, true)
    end
  end, { desc = desc_tag .. "Stop LSP clients attached to current buffer" })

  pcall(nvim_create_user_command, "LspRestartHere", function()
    local ids = {}
    for _, c in ipairs(_buf_clients(0)) do
      ids[#ids + 1] = c.id
    end
    if #ids > 0 then
      lsp.stop_client(ids, true)
    end
    vim.defer_fn(function()
      for _, name in ipairs(_active_servers()) do
        pcall(vim.lsp.enable, name)
      end
    end, 50)
  end, { desc = desc_tag .. "Restart LSP for current buffer (vim.lsp)" })
end

return M
