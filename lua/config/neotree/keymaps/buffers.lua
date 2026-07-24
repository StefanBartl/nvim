---@module 'config.neotree.keymaps.buffers'
-- Buffer-Source-specific extra mappings (unchanged) =========

---@return table<string, any>
return {

  --====================== Commands ===================================

  ["dd"] = "buffer_delete",

  --====================== Add noop für filesystem-specific ===========

  -- single-char symbols
  ["+"] = "noop",
  ["-"] = "noop",

  -- single-char letters (lowercase → uppercase)
  ["a"] = "noop",
  ["A"] = "noop",
  ["c"] = "noop",
  ["D"] = "noop",
  ["I"] = "noop",
  ["L"] = "noop",
  ["M"] = "noop",
  ["m"] = "noop",
  ["O"] = "noop",
  ["p"] = "noop",
  ["r"] = "noop",
  ["U"] = "noop",
  ["x"] = "noop",
  ["Y"] = "noop",

  -- multi-char plain keys
  ["fm"] = "noop",
  ["gb"] = "noop",
  ["gr"] = "noop",
  ["rq"] = "noop",
  ["sm"] = "noop",

  -- bracket-prefixed motions
  ["[F"] = "noop",
  ["[f"] = "noop",
  ["[p"] = "noop",
  ["[r"] = "noop",
  ["[t"] = "noop",
  ["]p"] = "noop",
  ["]r"] = "noop",
  ["]t"] = "noop",

  -- control / modifier keys (grouped)
  ["<C-s>"] = "noop",
  ["<M-s>"] = "noop",
  ["<S-CR>"] = "noop",
}

