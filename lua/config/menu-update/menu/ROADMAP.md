# nvchad.menu roadmap

# neotree

1. Manche entries machen nur sinn auf folders anzuwenden, manche nur auf file nodes...
2. Leere contextmenud
  1. Wenn man contextmenu aufruft, dann einen linksklick außerhalb macht, bekommt man ein leeres contextmenu. Wnen mann dann wieder einen rechtsklick macht, dann hat man ein leeres und ein volles KOMISCHERWEI?E nicht immer ein Problem, nur manchmal
  2. Wenn eine auswahl einen error aufruft, auch dann gibt es ein eleeres contextmenu window, das man extra schließen muss
  LÖSUNG: Beim click event als erstes sofort das menu schließen, noch bevor die eigentlich entry logik ausgeführt wird
3. Bei click auf entry:

```lua
   Error  19:20:42 msg_show.lua_error Error executing vim.schedule lua callback: ...artl/AppData/Local/nvim-data/lazy/menu/lua/menu/init.lua:91: attempt to index field 'old_data' (a nil value)
stack traceback:
	...artl/AppData/Local/nvim-data/lazy/menu/lua/menu/init.lua:91: in function <...artl/AppData/Local/nvim-data/lazy/menu/lua/menu/init.lua:90>
```

Vorgeschlagene Lösung in nvim-data:

In deinem `close_post` Callback wird auf `state.old_data.win` und `state.old_data.cursor` zugegriffen, **ohne vorher zu prüfen, ob `state.old_data` überhaupt existiert**. Das löst den `attempt to index field 'old_data' (a nil value)` Fehler aus, wenn `state.old_data` aus irgendeinem Grund `nil` ist.

Du hast aktuell:

```lua
if api.nvim_win_is_valid(state.old_data.win) then
  api.nvim_set_current_win(state.old_data.win)
  vim.schedule(function()
    local cursor_line = math.max(1, state.old_data.cursor[1])
    local cursor_col = math.max(0, state.old_data.cursor[2])
    pcall(api.nvim_win_set_cursor, state.old_data.win, { cursor_line, cursor_col })
  end)
end
```

Hier muss man zuerst prüfen, ob `state.old_data` existiert **und** die Felder nicht nil sind. Robust sähe das so aus:

```lua
if state.old_data and state.old_data.win and api.nvim_win_is_valid(state.old_data.win) then
  api.nvim_set_current_win(state.old_data.win)
  vim.schedule(function()
    local cursor_line = 1
    local cursor_col = 0

    if state.old_data.cursor then
      cursor_line = math.max(1, state.old_data.cursor[1] or 1)
      cursor_col = math.max(0, state.old_data.cursor[2] or 0)
    end

    pcall(api.nvim_win_set_cursor, state.old_data.win, { cursor_line, cursor_col })
  end)
end
```

Damit wird der Fehler komplett vermieden, selbst wenn `state.old_data` `nil` ist oder keine Cursor-Infos vorhanden sind.

---
