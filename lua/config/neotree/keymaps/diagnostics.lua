---@module 'config.neotree.keymaps.diagnostics'
--- Diagnostics-Source-specific mappings

---@return table<string, any>
return {

  --====================== Navigation ================================

  ["o"] = "open",

  ["<CR>"] = "open",
  ["<2-LeftMouse>"] = "open",

  --====================== Splits ====================================

  ["sg"] = "open_vsplit",
  ["st"] = "open_tabnew",
  ["sv"] = "open_split",

  --====================== Preview ===================================

  ["<Tab>"] = "toggle_preview",

  --====================== Refresh ===================================

  ["R"] = "refresh",

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
  ["U"] = "noop",
  ["Y"] = "noop",

  -- multi-character plain tokens
  ["dd"] = "noop",
  ["fm"] = "noop",
  ["gb"] = "noop",
  ["gr"] = "noop",
  ["rq"] = "noop",
  ["sm"] = "noop",

  -- bracket navigation
  ["[f"] = "noop",
  ["[F"] = "noop",
  ["[p"] = "noop",
  ["[r"] = "noop",
  ["[t"] = "noop",
  ["]p"] = "noop",
  ["]r"] = "noop",
  ["]t"] = "noop",

  -- control / modifier keys (grouped by base key)
  ["<S-CR>"] = "noop",
  ["<C-s>"] = "noop",
  ["<M-s>"] = "noop",
  ["<S-o>"] = "noop",

  -- leader keys
  ["<leader>mc"] = "noop",
  -- `<leader>th` used to be noop'd here too. It no longer has to be:
  -- filetree.nvim restricts its trash keymaps to the `filesystem` source
  -- (filetree.nvim 71eaa54, `lua/filetree/sources.lua`), so nothing claims it
  -- in this tree any more. And a `noop` is not free -- it is a buffer-local
  -- mapping to nothing, which also swallowed lsp.nvim's global inlay-hint
  -- toggle. Leaving the key unmapped lets that one through, which is the
  -- useful answer in a tree built out of LSP data.
}
