
  Info  08:58:00 notify.info [neo-tree] Action: open (pos: float, source: nil -> filesystem)
08:58:01 msg_show.lua_print [neo-tree.open.win.timing_rec] float nil float 44.607 ms
   Info  08:58:04 notify.info [neo-tree] Action: close (pos: float, source: filesystem -> filesystem)
   Info  08:58:04 notify.info [neo-tree] Closing position: float
08:58:04 msg_show.lua_print [neo-tree.open.win.timing_rec] nil nil float 17.113 ms
   Info  08:58:06 notify.info [neo-tree] Action: open (pos: float, source: filesystem -> filesystem)
08:58:06 msg_show.lua_print [neo-tree.open.win.timing_rec] float nil float 45.450 ms

<<< HIER KEINE NEOTREE AKTIONEN - andere Aufgaben in Nvim erledigt, files in buffer geöffnet, verändert, geschlossen, windows geäffnet und geschlossen usw...>>>

...4 Minuten vergehen mit Arbeit in NVIM...

<<< NÄCHSTE NEOTREE AKTION PROBLEMATISCH - NEUES ÖFNNEN NICHT VON FLOAT ABER LINKES NEOTREE WINDOW >>>>

  Info  09:02:47 notify.info [neo-tree] Action: switch (pos: left, source: filesystem -> filesystem)
  Info  09:02:47 notify.info [neo-tree] Switching from float to left (delay: 50ms)
  Info  09:02:47 notify.info [neo-tree] Closing position: float
09:02:47 msg_show.lua_print [neo-tree.open.win.timing_rec] nil nil left 57.665 ms
  Info  09:02:47 notify.info [neo-tree] Cleaned up 1 duplicate window(s)

<<<< JETZ TRITT DER FEHLER AUF >>>>
Anstatt dass sich das linke Neo-tree Window öffnet, öffnet sich float, schließ´t sich sofort wieer und dann erst öffnet sich links (manchmal öffnet sich da slinke auch nicht und ich muss es manuell nochmal öffnen)
Und dieser error wird ausgegeb;

  Error  09:02:47 msg_show.lua_error Error executing vim.schedule lua callback: ...im-data/lazy/neo-tree.nvim/lua/neo-tree/command/init.lua:196: Invalid window id: 1124
stack traceback:
	[C]: in function 'nvim_set_current_win'
	...im-data/lazy/neo-tree.nvim/lua/neo-tree/command/init.lua:196: in function <...im-data/lazy/neo-tree.nvim/lua/neo-tree/command/init.lua:194>
  Error  09:02:47 notify.error [Neo-tree ERROR] debounce  neo-tree-follow  error:  ...Data/Local/nvim-data/lazy/nui.nvim/lua/nui/tree/init.lua:261: Invalid 'window': Expected Lua number
  Info  09:02:48 notify.info [neo-tree] Action: close (pos: left, source: filesystem -> filesystem)
  Info  09:02:48 notify.info [neo-tree] Closing position: left
9:02:48 msg_show.lua_print [neo-tree.open.win.timing_rec] nil nil left 0.728 ms
  Info  09:02:53 notify.info [neo-tree] Action: open (pos: left, source: filesystem -> filesystem)
  Info  09:02:53 notify.info [neo-tree] Cleaned up 1 duplicate window(s)
9:02:53 msg_show.lua_print [neo-tree.open.win.timing_rec] left nil left 0.975 ms

ab nun funktnier es wieer, ich öffne es zweimal lnks. dann lasse ich es wieder iene zeit nicht neotre vewrenden. dann öffne ich wieder links mit M-l und es öfffnet und schlißt ganz schnell sich zuerst float und dann auch lionks, dann öfnfnet sich ein zweites mal links und blenbt dieses mal offen. in den notify sieht das so aus:

---------------------
   Info  09:10:04 notify.info [neo-tree] Action: switch (pos: left, source: filesystem -> filesystem)
   Info  09:10:04 notify.info [neo-tree] Switching from float to left (delay: 50ms)
   Info  09:10:04 notify.info [neo-tree] Closing position: float
09:10:04 msg_show.lua_print [neo-tree.open.win.timing_rec] nil nil left 75.734 ms
   Info  09:10:04 notify.info [neo-tree] Cleaned up 1 duplicate window(s)
   Error  09:10:04 msg_show.lua_error Error executing vim.schedule lua callback: ...im-data/lazy/neo-tree.nvim/lua/neo-tree/command/init.lua:196: Invalid window id: 1361
stack traceback:
	[C]: in function 'nvim_set_current_win'
	...im-data/lazy/neo-tree.nvim/lua/neo-tree/command/init.lua:196: in function <...im-data/lazy/neo-tree.nvim/lua/neo-tree/command/init.lua:194>
   Error  09:10:04 notify.error [Neo-tree ERROR] debounce  neo-tree-follow  error:  ...Data/Local/nvim-data/lazy/nui.nvim/lua/nui/tree/init.lua:261: Invalid 'window': Expected Lua number

DIeser gersamte abschnitt wurd nur von einmal M-l ausgelöst
