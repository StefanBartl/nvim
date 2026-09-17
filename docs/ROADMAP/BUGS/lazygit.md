Wenn ich mit `leader lg` lazygit ui starrte und dann sofort einen anderren key eingebe crashed lazygit mit:

```vim
  Error  17:12:01 msg_show.lua_error vim.schedule callback: Vim:jobstart(...,{term=true}) requires unmodified buffer
stack traceback:
	[C]: in function 'jobstart'
	...ppData/Local/nvim-data/lazy/lazygit.nvim/lua/lazygit.lua:65: in function <...ppData/Local/nvim-data/lazy/lazygit.nvim/lua/lazygit.lua:64>
```

und der lazygiut buffer öffnet dann zwar, bleibt aber leer. Kann man das mit einen handle abfangen ?
