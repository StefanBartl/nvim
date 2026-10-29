-- TESTS/plugins_nui_spec.lua -- nui.nvim must stay a pure dependency of noice and neo-tree.
-- A standalone entry anywhere under lua/plugins is redundant: it adds nothing the
-- dependencies do not already install, and it hides which plugins actually need nui.

return function(H)
  local NUI = "MunifTanjim/nui.nvim"
  -- Resolve the checkout from this spec file, not stdpath("config"), so worktrees and
  -- clones are validated against their own tree.
  local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
  local root = vim.fn.fnamemodify(here, ":h:h"):gsub("\\", "/")

  local standalone, owners = {}, {}
  local files = vim.fn.glob(root .. "/lua/plugins/**/*.lua", false, true)
  H.ok(#files > 0, "found plugin spec files under " .. root)
  for _, file in ipairs(files) do
    local ok, specs = pcall(dofile, file)
    if ok and type(specs) == "table" then
      -- A file may return one spec or a list of specs.
      local list = type(specs[1]) == "string" and { specs } or specs
      for _, spec in ipairs(list) do
        if type(spec) == "table" then
          if spec[1] == NUI then
            standalone[#standalone + 1] = file
          end
          for _, d in ipairs(type(spec.dependencies) == "table" and spec.dependencies or {}) do
            if d == NUI or (type(d) == "table" and d[1] == NUI) then
              owners[#owners + 1] = spec[1]
            end
          end
        end
      end
    end
  end

  H.ok(#standalone == 0, "no standalone nui.nvim entry: " .. table.concat(standalone, ", "))
  H.ok(vim.tbl_contains(owners, "folke/noice.nvim"), "noice.nvim depends on nui.nvim")
  H.ok(vim.tbl_contains(owners, "nvim-neo-tree/neo-tree.nvim"), "neo-tree depends on nui.nvim")
end
