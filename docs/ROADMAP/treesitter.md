# `treeesitter`-Roadmap

## Neotree fokussiert, dann `CR` auf file node: `.luarc.json`:

```vim
   Error  15:53:24 notify.error [Neo-tree ERROR] Error opening file: vim/_core/editor.lua:355: nvim_exec2()[1]..BufReadPost Autocommands for "*": Vim(append):Lua callback: C:/Program Files/Neovim/share/nvim/runtime/filetype.lua:28: nvim_exec2()[1]..BufReadPost Autocommands for "*"..FileType Autocommands for "*": Vim(append):Lua callback: ...m Files/Neovim/share/nvim/runtime/lua/vim/treesitter.lua:471: Parser could not be created for buffer 111 and language "json"
stack traceback:
	[C]: in function 'assert'
	...m Files/Neovim/share/nvim/runtime/lua/vim/treesitter.lua:471: in function 'start'
	...sers/bartl/AppData/Local/nvim/lua/plugins/treesitter.lua:27: in function <...sers/bartl/AppData/Local/nvim/lua/plugins/treesitter.lua:25>
	[C]: in function 'nvim_cmd'
	C:/Program Files/Neovim/share/nvim/runtime/filetype.lua:28: in function <C:/Program Files/Neovim/share/nvim/runtime/filetype.lua:27>
	[C]: in function 'pcall'
	vim/_core/shared.lua:1648: in function <vim/_core/shared.lua:1628>
	[C]: in function '_with'
	C:/Program Files/Neovim/share/nvim/runtime/filetype.lua:27: in function <C:/Program Files/Neovim/share/nvim/runtime/filetype.lua:10>
	[C]: in function 'nvim_exec2'
	vim/_core/editor.lua:355: in function <vim/_core/editor.lua:351>
	[C]: in function 'pcall'
	...nvim-data/lazy/neo-tree.nvim/lua/neo-tree/utils/init.lua:857: in function 'open_file'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:843: in function 'open'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:865: in function 'open_with_cmd'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:873: in function 'open'
	...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:214: in function <...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:213>
stack traceback:
	[C]: in function '_with'
	C:/Program Files/Neovim/share/nvim/runtime/filetype.lua:27: in function <C:/Program Files/Neovim/share/nvim/runtime/filetype.lua:10>
	[C]: in function 'nvim_exec2'
	vim/_core/editor.lua:355: in function <vim/_core/editor.lua:351>
	[C]: in function 'pcall'
	...nvim-data/lazy/neo-tree.nvim/lua/neo-tree/utils/init.lua:857: in function 'open_file'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:843: in function 'open'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:865: in function 'open_with_cmd'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:873: in function 'open'
	...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:214: in function <...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:213>
```

---
