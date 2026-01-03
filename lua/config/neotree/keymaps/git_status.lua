---@module 'config.neotree.keymaps.git_status'
-- Git-Status-Source-specific extra mappings (unchanged) =========

---@return table<string, any>
return {

  --====================== Commands ===================================

   ["dd"] = "delete",

  --====================== Add noop für filesystem-specific ===========

  ["d"] = "noop",
  ["a"] = "noop",
  ["A"] = "noop",
  ["r"] = "noop",
  ["c"] = "noop",
  ["x"] = "noop",
  ["p"] = "noop",
  ["m"] = "noop",
  ["<S-m>"] = "noop",
  ["U"] = "noop",
  ["+"] = "noop",
  ["-"] = "noop",
  ["I"] = "noop",
  ["O"] = "noop",
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
