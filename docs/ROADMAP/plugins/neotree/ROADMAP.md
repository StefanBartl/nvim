# Roadmap für das `neotree`-Modul

## Bugs

1. neotree in Windows: M löst zweimal file explorer aus bzw funktionert meistens nicht FIXED: AUDIT:
- reveal reealed oftmals nur 1 ebene, wenn man wieder schließt und öffnet dann erst die nächste Ebene. Das ist aber nur manchmal.
- wenn man zuerst tab in neotree macht und dann mit enter in die file geht:

```vim
  Error  03:49:29 msg_show.lua_error Error detected while processing BufAdd Autocommands for "*":
Error executing lua callback: ...ocal/nvim-data/lazy/ui/lua/nvchad/tabufline/lazyload.lua:36: Invalid buffer id: 1
stack traceback:
	[C]: in function 'nvim_buf_get_name'
	...ocal/nvim-data/lazy/ui/lua/nvchad/tabufline/lazyload.lua:36: in function <...ocal/nvim-data/lazy/ui/lua/nvchad/tabufline/lazyload.lua:16>
	[C]: in function '__newindex'
	...nvim-data/lazy/neo-tree.nvim/lua/neo-tree/utils/init.lua:850: in function 'open_file'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:819: in function 'open'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:841: in function 'open_with_cmd'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:849: in function 'open'
	...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:209: in function 'open'
	...d/AppData/Local/nvim/lua/config/neotree/keymaps/init.lua:60: in function <...d/AppData/Local/nvim/lua/config/neotree/keymaps/init.lua:46>
```

---

## Allgemein

1. Modularisieren des `config/neotree`-Folders

## neue Mappings

--
