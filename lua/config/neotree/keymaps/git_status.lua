---@module 'config.neotree.keymaps.git_status'
-- Git-Status-Source-specific extra mappings

---@return table<string, any>
return {

  --====================== Commands ==================================

  ["dd"] = "delete",

  --====================== Disable filesystem operations =============

  -- single-character symbols
  ["+"] = "noop",
  ["-"] = "noop",

  -- single-character letters
  ["a"] = "noop",
  ["c"] = "noop",
  ["d"] = "noop",
  ["m"] = "noop",
  ["p"] = "noop",
  ["r"] = "noop",
  ["x"] = "noop",

  -- single-character uppercase letters
  ["A"] = "noop",
  ["D"] = "noop",
  ["I"] = "noop",
  ["L"] = "noop",
  ["M"] = "noop",
  ["O"] = "noop",
  ["U"] = "noop",
  ["Y"] = "noop",

  -- multi-character plain tokens
  ["gb"] = "noop",
  ["gr"] = "noop",
  ["rq"] = "noop",

  -- bracket navigation
  ["[f"] = "noop",
  ["[F"] = "noop",
  ["[p"] = "noop",
  ["[r"] = "noop",
  ["[t"] = "noop",
  ["]p"] = "noop",
  ["]r"] = "noop",
  ["]t"] = "noop",

  -- control / modifier keys (grouped)
  ["<CR>"]   = "noop",
  ["<S-CR>"] = "noop",
  ["<C-s>"] = "noop",
  ["<M-s>"] = "noop",
}
