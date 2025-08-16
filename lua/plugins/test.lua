---@module 'plugins.test'
--- Plugins curently in test phase

---@type LazyPluginSpec[]
return {

 -- C:/Users/bartl/AppData/Local/nvim/lua/plugins/test.lua
  {
  -- Pfad auf den Plugin-Root, in dem lua/ und plugin/ liegen
  dir = vim.fs.normalize(vim.fn.stdpath("config") .. "/lua/plugins/test/klingons"),
  name = "klingon_notify",
  dev = true,
  event = "VeryLazy",
  -- rtp = "." -- Default, kann entfallen

  config = function()
    local ok, klingon = pcall(require, "klingon_notify")
    if not ok then
      vim.notify("klingon_notify not on runtimepath (check dir / layout)", vim.log.levels.ERROR)
      return
    end
    klingon.setup({
      mode = "float",
      title = "tlhIngan",
    })
  end,
}



}
