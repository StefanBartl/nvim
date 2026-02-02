---@module 'config.neotree.keymaps.filesystem.preview'
--- Preview window control and scrolling.

---@type table<string, any>
return {
  ["<Tab>"] = {
    "toggle_preview",
    config = {
      use_float = true,
      use_snacks_image = true,
      use_image_nvim = true,
    },
  },

  ["<C-b>"] = { "scroll_preview", config = { direction = 1 } },
  ["<C-f>"] = { "scroll_preview", config = { direction = -1 } },
  ["<PageUp>"] = { "scroll_preview", config = { direction = 10 } },
  ["<PageDown>"] = { "scroll_preview", config = { direction = -10 } },
}
