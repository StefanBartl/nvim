# FIX: bugs

## Important Bugs

- MDTablewrap

 dbg_messages: noice error: Error executing vim.schedule lua callback: ...tl/AppData/Local/nvim/lua/mappings/dbg_messages/init.lua:46: Invalid window id: 1007
stack traceback:
	[C]: in function 'nvim_win_get_buf'
	...tl/AppData/Local/nvim/lua/mappings/dbg_messages/init.lua:46: in function 'focus_and_bottom'
	...tl/AppData/Local/nvim/lua/mappings/dbg_messages/init.lua:111: in function 'cb'
	.../AppData/Local/nvim/lua/lib/buf_win_tab/capture/init.lua:127: in function 'fn'
	vim/_editor.lua:366: in function <vim/_editor.lua:365>
