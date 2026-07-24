---@module 'config.neotree.keymaps.document_symbols'
-- Document-Symbols-Source-specific mappings

---@return table<string, any>
return {

  --====================== Navigation ================================

  ["l"] = "jump_to_symbol",
  ["o"] = "jump_to_symbol",

  ["<CR>"]          = "jump_to_symbol",
  ["<2-LeftMouse>"] = "jump_to_symbol",

  --====================== Filter ====================================

  ["F"] = "filter",
  ["f"] = "filter_on_submit",

  --====================== Disable ALL filesystem operations ==========

  -- single-character symbols
  ["+"] = "noop",
  ["-"] = "noop",
  ["/"] = "noop",

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
  ["dd"] = "noop",
  ["gb"] = "noop",
  ["gr"] = "noop",
  ["rl"] = "noop",
  ["st"] = "noop",
  ["sv"] = "noop",

  -- bracket navigation
  ["[f"] = "noop",
  ["[F"] = "noop",
  ["[p"] = "noop",
  ["[r"] = "noop",
  ["[t"] = "noop",
  ["]p"] = "noop",
  ["]r"] = "noop",
  ["]t"] = "noop",

  -- control / modifier keys
  ["<S-CR>"] = "noop",
  ["<C-b>"] = "noop",
  ["<C-c>"] = "noop",
  ["<C-f>"] = "noop",
  ["<C-s>"] = "noop",
  ["<M-s>"] = "noop",
  ["<Tab>"] = "noop",

  -- leader keys
  ["<leader>mc"] = "noop",
  ["<leader>th"] = "noop",

  -- named special keys
  ["<PageDown>"] = "noop",
  ["<PageUp>"]   = "noop",
}
