---@module 'config.neotree.keymaps.document_symbols'
-- Document-Symbols-Source-specific mappings

---@return table<string, any>
return {

  --====================== Navigation (document_symbols specific) =====

  ["<CR>"] = "jump_to_symbol",
  ["<2-LeftMouse>"] = "jump_to_symbol",
  ["l"] = "jump_to_symbol",
  ["o"] = "jump_to_symbol",

  --====================== Filter =======================================

  ["F"] = "filter",
  ["f"] = "filter_on_submit",

  --====================== Disable ALL filesystem operations ==========

  ["/"] = "noop",
  ["<C-c>"] = "noop",
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
  ["<Tab>"] = "noop", -- No preview
  ["<PageDown>"] = "noop",
  ["<PageUp>"] = "noop",
  ["<C-f>"] = "noop",
  ["<C-b>"] = "noop",
  ["sv"] = "noop",
  ["sg"] = "noop",
  ["st"] = "noop",
}
