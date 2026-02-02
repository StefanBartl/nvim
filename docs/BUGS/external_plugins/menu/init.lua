1. kontrollieren, ob alles funktioniert
2. Delete funktienrt nicht
```vim
   Error  12:59:06 msg_show.lua_error Error executing vim.schedule lua callback: ...AppData/Local/nvim-data/lazy/menu/lua/menus/neo-tree.lua:17: attempt to call local 'cb' (a nil value)
stack traceback:
	...AppData/Local/nvim-data/lazy/menu/lua/menus/neo-tree.lua:17: in function 'fn'
	vim/_editor.lua:366: in function <vim/_editor.lua:365>
   Error  12:58:27 notify.error [gopath] File not found: C:\Users\bartl\AppData\Local\nvim\lua\lsp\usercmds/commands.debug().execute
   Error  12:57:20 msg_show.emsg E5108: Error executing lua: ...cal/nvim/lua/config/neotree/keymaps/filesystem/files.lua:37: invalid key: reveal_force_cwd
stack traceback:
	[C]: in function 'Neotree'
	...cal/nvim/lua/config/neotree/keymaps/filesystem/files.lua:37: in function <...cal/nvim/lua/config/neotree/keymaps/filesystem/files.lua:14>
   Error  12:58:07 msg_show.lua_error   LspDebug Error executing Lua callback: C:/Users/bartl/AppData/Local/nvim/lua/lsp/usercmds/init.lua:123: attempt to call field 'debug' (a nil value)
stack traceback:
	C:/Users/bartl/AppData/Local/nvim/lua/lsp/usercmds/init.lua:123: in function <C:/Users/bartl/AppData/Local/nvim/lua/lsp/usercmds/init.lua:122>
```

3. Wenn möglich, implementieren, dass das neotree window gefunden wird, wenn man es nicht bereits schon fokusiert hat
