---@module 'config.neotree.keymaps.diagnostics'
--- Diagnostics-Source-specific mappings

---@return table<string, any>
return {
  --====================== Navigation =================================

  ["<CR>"] = "open",
  ["<2-LeftMouse>"] = "open",
  ["o"] = "open",

  --====================== Splits =====================================

  ["sv"] = "open_split",
  ["sg"] = "open_vsplit",
  ["st"] = "open_tabnew",

  --====================== Preview ====================================

["<Tab>"] = "toggle_preview",

  --====================== Refresh ====================================

  ["R"] = "refresh",

  --====================== Disable filesystem operations ==============

  ["a"] = "noop",
  ["A"] = "noop",
  ["d"] = "noop",
  ["dd"] = "noop",
  ["r"] = "noop",
  ["c"] = "noop",
  ["x"] = "noop",
  ["p"] = "noop",
  ["m"] = "noop",
  ["<S-m>"] = "noop",
  ["<leader>mc"] = "noop",
  ["U"] = "noop",
  ["<leader>th"] = "noop",
  ["+"] = "noop",
  ["-"] = "noop",
  ["I"] = "noop",
  ["L"] = "noop",
  ["[l"] = "noop",
  ["grep"] = "noop",
  ["D"] = "noop",
  ["[p"] = "noop",
  ["]p"] = "noop",
  ["]r"] = "noop",
  ["[r"] = "noop",
  ["[f"] = "noop",
  ["[F"] = "noop",
  ["[t"] = "noop",
  ["[T"] = "noop",
  ["Y"] = "noop",
  ["<S-o>"] = "noop",
  ["<S-CR>"] = "noop",
  ["gb"] = "noop",
  ["<C-s>"] = "noop",
  ["<M-s>"] = "noop",

}
