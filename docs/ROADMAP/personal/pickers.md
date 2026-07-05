# `pickers.nvim`

   Error  13:24:52 notify.error [lib.nvim.usercmd] UserCommand 'WkdBookFiles' failed:

E:/repos/pickers.nvim/lua/pickers/selected_index/init.lua:187: attempt to index local 'cfg' (a nil value)

   Error  13:23:51 notify.error [lib.nvim.usercmd] UserCommand 'RepoFiles' failed:

E:/repos/pickers.nvim/lua/pickers/selected_index/init.lua:187: attempt to index local 'cfg' (a nil value)





   Error  13:25:29 msg_show.emsg E5108: Lua: E:/repos/pickers.nvim/lua/pickers/selected_index/init.lua:187: attempt to index local 'cfg' (a nil value)

stack traceback:

	E:/repos/pickers.nvim/lua/pickers/selected_index/init.lua:187: in function 'wrap_attach_mappings'

	E:/repos/pickers.nvim/lua/pickers/engines/telescope.lua:72: in function 'pick_files'

	E:/repos/pickers.nvim/lua/pickers/actions/files.lua:9: in function 'run'

	E:/repos/pickers.nvim/lua/pickers/command/init.lua:73: in function 'dispatch_action'

	E:/repos/pickers.nvim/lua/pickers/command/init.lua:83: in function 'after_source'

	E:/repos/pickers.nvim/lua/pickers/command/init.lua:111: in function 'callback'

	E:/repos/pickers.nvim/lua/pickers/sources/config.lua:10: in function 'get'

	E:/repos/pickers.nvim/lua/pickers/command/init.lua:110: in function 'run_standard_scope'

	E:/repos/pickers.nvim/lua/pickers/command/init.lua:181: in function 'handle'

	E:/repos/pickers.nvim/lua/pickers/bindings/keymaps.lua:26: in function <E:/repos/pickers.nvim/lua/pickers/bindings/keymaps.lua:25>


---
