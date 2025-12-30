# FIX: bugs

## Important Bugs

- markdown-headlines: v-line increment/decrement funktioniert nicht (zuverlässig)

### LSP

- Die @types und types dateien werden nicht gut erkannt. Besser mal mit types.lua probeiren, aber das sollte eigentlich keinen Unterschied machen

## dbg_messages

- soll mit `q` und `<Esc>` geschlossen werden können

### neotree

#### EPERM

```vim
05:56:16 msg_show.echomsg    y Moving to Trash...
05:56:18 msg_show.echomsg ✓ Moved to Trash (1 items)
   Error  05:56:21 notify.error [Neo-tree ERROR] file_event_callback:  EPERM
   Error  05:56:21 notify.error [Neo-tree ERROR] file_event_callback:  EPERM
```

Nach einem renaming eines Folders:
```vim
   Error  06:08:10 notify.error [Neo-tree ERROR] debounce  neo-tree-follow  error:  ...Data/Local/nvim-data/lazy/nui.nvim/lua/nui/tree/init.lua:261: Invalid 'window': Expected Lua number
   Error  06:08:10 notify.error [Neo-tree ERROR] debounce  filesystem_navigate  error:  ...Data/Local/nvim-data/lazy/nui.nvim/lua/nui/tree/init.lua:261: Invalid 'window': Expected Lua number
```


#### situation, in der Neotree als buffer im tab ist...

.. und man dann ein preview ausführen möchte:

```vim
  Error  06:14:01 msg_show.emsg E5108: Error executing lua: ...zy/neo-tree.nvim/lua/neo-tree/sources/common/preview.lua:181: attempt to index field 'truth' (a nil value)
stack traceback:
	...zy/neo-tree.nvim/lua/neo-tree/sources/common/preview.lua:181: in function 'revert'
	...zy/neo-tree.nvim/lua/neo-tree/sources/common/preview.lua:482: in function 'hide'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:733: in function 'revert_preview'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:810: in function 'open'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:841: in function 'open_with_cmd'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:849: in function 'open'
	...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:209: in function 'open'
	...d/AppData/Local/nvim/lua/config/neotree/keymaps/init.lua:93: in function <...d/AppData/Local/nvim/lua/config/neotree/keymaps/init.lua:76>
```

1. Auch wenn man mit enter öffnen möchte wird der selbe Fehler ausgegeben!
2. Auch wenn man dann `:Neotree` ausführt, kann man keine node mehr damit öffnen, es wird immer der obige Fehler ausgegeben.


---

#### Neotree: beim öffnen fällt er oft auf das cwd root zurück...

...dann muss mian wieder nach vor "gehen" mit node opens um dort hinzukommen wo man ist. Spezielafall: wen man neotree schließ, dann wieder ffnet ist es wieder iene ebene näher am der richtigen ebene, dan nwieder schlißen und öffnen und er springt wieder eine eben näher zu dem file in der man ist.

- Weiteres beispiel: ich habe eine datei tief im cwd offen. ich gehe in neotree updir zum ordner meiner file, setze dies damit auf cwd. springe nun mit dem cursor in den buffer und neotree cwd fällt auf den projekt root zurück. Lösung eventuell -> cwd nur dann neu setzen bei reveal, wenn man updir ist. geht man downdir wird es cwd sowies neu gesetzt und wenn nicht, dann muss bei downdir maximal der parent ofolder als cwd gesetzt werden. als probieren mit: reveal nur mit updir

---

#### neotreee manchmal auch ohne usrcmd schließt sich der linke neotree und öffnet sich der rechte

---

## neotree-fs-refactor

05:32:36 msg_show [neotree-fs-refactor] Event handlers registered
[neotree-fs-refactor] [neotree-fs-refactor] Plugin loaded successfully
[LuaProjectFileStats] LuaFileStats commands registered
[github-stats] Fetch interval not elapsed (use 'force' to bypass)
E5108: Error executing lua: ...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:803: attempt to index local 'tree' (a nil value)
stack traceback:
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:803: in function 'open_with_cmd'
	...y/neo-tree.nvim/lua/neo-tree/sources/common/commands.lua:849: in function 'open'
	...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:209: in function <...o-tree.nvim/lua/neo-tree/sources/filesystem/commands.lua:208>
05:32:41 msg_showcmd ^W^W

---

## MDTablewrap

---
