# `lib.nvim`

1. Personal Plugins auf `utils`-Folder durchsuchen -> Eventuell Funktionen für die lib dabei?
2. [ ] Overlay/Fenster müssem sich oft im Normal-Mode intuitiv über `q` oder `Escape` schließen lassen. Dies könnte man in einer `lib.nvim`-Funktion anbieten: `function close_window_with_keymap(win_id){ ... }` Somit müsste man das nicht in jedem Plugin extra implementieren. Derartige weitere Features möglich? Beispiele:
    - Telescope / fzf-lua picker
    - `lib.nvim` -> `hover_select`
    - `debugging.nvim` -> Debugging windows
    - `pickers.nvim` -> Alle UI ickers
    - usw...

  Ich denke, dass es ein Vorteil wäre, wenn man eine `lib.nvim` Funklion hat, die man in sein plugin callen kann, die window id übergibt und sich dan nsicher sein kann, dass man das Fenster ab jetzt mit `q` oder `Escape` im nomral modus schließen kann, ohne wieder die übliche implementierung anzugehen.

  Gerner auch, wenn wir schon dabei sind, können wir das ein oder andere feature in diese richtung mehr implementieren, wenn dier gute "einfallen" :-)

  Wichtig: Wen möglich sollten die `lib.nvim` funkltiione pure functions sein, walso wenn ötiog mehrere kleine funkltien die alle nurt eine aufgabe ahebn anstatt eine große funktion.

  Cool wäre, dass wierr dann in etwa so arbeiten können:

  ```lua
  local winid = `...{get the window id}...`
  local win_tools = require("lib.nvim.win_tools") -- Das ist beisoielhaft hier, der pfasd wird dann wrsch adners sein
  win_tools.nice_quit(winid)                    -- Auch hier, bezeichnung nur bespielhaft""
  win_tools.Set_title(winid, "New Title")
  ```
  Ich würde es auch cool findne, wenn man sowas wie einen Aggeregator hat (was ist dafrü die korrekte bezeicvhnung???):

    ```lua
  local winid = `...{get the window id}...`
  local win_tools = require("lib.nvim.win_tools")(winid) -- Also hier ein init über enen  konstruktor anbeitete optional (konstruktor ist glaubich der korrekte name)
  win_tools.nice_quit()
  win_tools.Set_title("New Title")
  ```

  Das wäre auch cool!

Was dnekst du, ist es das wert diese imlemntierung zu tun, oder eher vorsicht?

---
