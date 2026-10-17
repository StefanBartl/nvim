-- TESTS/bindings/insert_moves_spec.lua -- <C-h/j/k/l> move the cursor in insert mode
-- (left/down/up/right). The global maps live in bindings.mappings.general; blink.cmp's
-- insert presets bind <C-k> buffer-local to show_signature/hide_signature, which shadows
-- the global map, so plugins/completion.lua must take <C-k> out of blink's keymap
-- (`false`) and must not claim any of the other three keys either.

return function(H)
  local eq, ok = H.eq, H.ok

  require("bindings.mappings.general").setup()

  local expected =
    { ["<C-H>"] = "<Left>", ["<C-J>"] = "<Down>", ["<C-K>"] = "<Up>", ["<C-L>"] = "<Right>" }
  for lhs, rhs in pairs(expected) do
    local m = vim.fn.maparg(lhs, "i", false, true)
    eq(m.rhs, rhs, "global insert map " .. lhs)
    eq(m.noremap, 1, lhs .. " is non-recursive (blink's <Up>/<Down> select maps never see it)")
  end

  -- The blink.cmp fragment of plugins/completion.lua, fed a keymap shaped like blink's
  -- `default` preset entries that collide with the four keys.
  local blink
  for _, spec in ipairs(require("plugins.completion")) do
    if spec[1] == "saghen/blink.cmp" then
      blink = spec
    end
  end
  ok(blink and type(blink.opts) == "function", "plugins.completion has a blink.cmp opts function")

  local opts = { keymap = { ["<C-k>"] = { "show_signature", "hide_signature", "fallback" } } }
  blink.opts(nil, opts)
  eq(opts.keymap["<C-k>"], false, "<C-k> is removed from blink's keymap")
  for _, key in ipairs({ "<C-h>", "<C-j>", "<C-l>", "<C-H>", "<C-J>", "<C-K>", "<C-L>" }) do
    ok(opts.keymap[key] == nil or opts.keymap[key] == false, key .. " is not claimed by blink")
  end
end
