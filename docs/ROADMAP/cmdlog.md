:Cmdlog nvim
dann Tab um ein favoirte auszuwählen:

  Error  11:23:15 AM msg_show.lua_error vim.schedule callback: C:/repos/cmdlog.nvim/lua/cmdlog/ui/picker_utils.lua:258: Invalid buffer id: 134
stack traceback:
	[C]: in function 'nvim_buf_attach'
	C:/repos/cmdlog.nvim/lua/cmdlog/ui/picker_utils.lua:258: in function 'attach_mappings'
	...nvim-data/lazy/telescope.nvim/lua/telescope/mappings.lua:324: in function 'apply_keymap'
	.../nvim-data/lazy/telescope.nvim/lua/telescope/pickers.lua:740: in function 'find'
	C:/repos/cmdlog.nvim/lua/cmdlog/ui/picker_utils.lua:282: in function 'open_picker'
	...epos/cmdlog.nvim/lua/cmdlog/ui/history_unique_picker.lua:27: in function <...epos/cmdlog.nvim/lua/cmdlog/ui/history_unique_picker.lua:19>
