vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function(args)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc, silent = true })
    end

    map("gf", function() require("utils.open_path.lua_require").gf_lua_smart() end,
        "Lua: go to required module or file")

    map("gF", function() require("utils.open_path.lua_require").open_in_vsplit() end,
        "Lua: open required module in vsplit")
    map("gT", function() require("utils.open_path.lua_require").open_in_tab() end,
        "Lua: open required module in new tab")
  end,
})

