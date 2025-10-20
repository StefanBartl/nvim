---@module 'config.menu.patch_neotree

local function load_neo_tree_menu()
  local ok, menu = pcall(require, "menus.neo-tree")
  if not ok then return {} end

  local ok_custom, custom = pcall(require, "config.neotree.keymaps")
  if ok_custom then
    for _, entry in ipairs(custom) do
      table.insert(menu, entry)
    end
  end

  return menu
end

return {
  load = load_neo_tree_menu
}
