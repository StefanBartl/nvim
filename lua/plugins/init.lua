---@module 'plugins.init'
--- Central entry point for lazy.nvim plugin registration.
--- Loads and merges all plugin lists from submodules in `plugins/`.

---@return LazyPluginSpec[]
local function load_all_plugins()
  ---@type string[]
  local modules = {
    "ai",
    "dap",
    "editing",
    "essentials",
    "file_nav",
    "fuzzy_finder",
    "git",
    "lsp",
    "markdown",
    "misc",
    "personal",
    "terminal",
    "test",
    "textobjects",
    "ui",
    "workflow",
    "neotree",
    "temp"
  }

  ---@type LazyPluginSpec[]
  local all_plugins = {}

  for _, name in ipairs(modules) do
    local ok, plugin_list = pcall(require, "plugins." .. name)
    if ok and type(plugin_list) == "table" then
      vim.list_extend(all_plugins, plugin_list)
    else
      vim.notify("[plugins/init.lua] Failed to load module: " .. name, vim.log.levels.WARN)
    end
  end

  return all_plugins
end

return load_all_plugins()
