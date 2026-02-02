1. ToDo-COmments Patchless - also monkeypatch in nvim config lösbar ?
PR schreiben tr

-> Wenn mich nicht alles täucht ist es vorallme, wenn man keinen `:` nach einem keyword schreibt

   Error  14:23:58 msg_show.lua_error Error executing vim.schedule lua callback: .../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:94: Invalid 'end_col': out of range
stack traceback:
	[C]: in function 'nvim_buf_set_extmark'
	.../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:94: in function 'add_highlight'
	.../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:246: in function 'highlight'
	.../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:155: in function 'fn'
	vim/_editor.lua:366: in function <vim/_editor.lua:365>
   Error  14:23:59 msg_show.lua_error Error executing vim.schedule lua callback: .../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:94: Invalid 'end_col': out of range
stack traceback:
	[C]: in function 'nvim_buf_set_extmark'
	.../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:94: in function 'add_highlight'
	.../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:246: in function 'highlight'
	.../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:155: in function 'fn'
	vim/_editor.lua:366: in function <vim/_editor.lua:365>



