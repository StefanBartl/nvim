# `cascade.nvim`

1. Nach indent vcon mehreren zeilen verscwindet die markeirung des wortes das man indentet hat. wen man eins mehr indenten will, muss man neu markieren. Die markierung soll erhalten bleibenD
2. indent (mit text markiert aber nicht sicher ob das wichtig ist) und dann nahc unten geshcoben, in der letzten Zeile angekommen folgenden error:

  ```vim
     Error  11:46:16 AM msg_show.emsg E5108: Lua: vim/_core/editor.lua:355: nvim_exec2(), line 1: Vim(move):E16: Invalid range
  stack traceback:
  	[C]: in function 'nvim_exec2'
  	vim/_core/editor.lua:355: in function 'cmd'
   ...rtl/AppData/Local/nvim/lua/bindings/mappings/editing.lua:71: in function <...rtl/AppData/Local/nvim/lua/bindings/mappings/editing.lua:70>
```

Dieses Prtoblem kommt aber nicht immer vor, es geht wohl eher darum, Vorsorge daghegen zu treffen.

1. `autolist` features?
2. `O` im normal mode soll das machen, was auch `o` macht, aber in die zeile darüber


---

