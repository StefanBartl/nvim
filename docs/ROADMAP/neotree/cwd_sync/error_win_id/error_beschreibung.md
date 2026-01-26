## config/neotree/cwd_sync optimierung und bugfix

### error (Hohe priorität)

Folgendes setup habe iuch um cwd_sync zu aktivieren im neotree plugin setup:
        cwd_sync = {
          debounce_ms = 150,
          keep_focus = true,
          also_set_nvim_cwd = false,
          open_if_closed = false,
          use_project_root = true,
          project_root_fallback_to_bufdir = true,
        },```

Wenn ich nun in nvim bin, einen file ffen habe, dann eine andere file, in einem anderen cwd, in einem buffer öffne und dann wieder neotree öffne, bekom ich den error:

```vim
  Error  12:20:29 notify.error [Neo-tree ERROR] debounce  neo-tree-follow  error:  ...Data/Local/nvim-data/lazy/nui.nvim/lua/nui/tree/init.lua:261: Invalid 'window': Expected Lua number
   Error  12:20:29 notify.error [Neo-tree ERROR] debounce  filesystem_navigate  error:  ...Data/Local/nvim-data/lazy/nui.nvim/lua/nui/tree/init.lua:261: Invalid 'window': Expected Lua number
   Error  12:20:44 notify.error [Neo-tree ERROR] debounce  neo-tree-follow  error:  ...Data/Local/nvim-data/lazy/nui.nvim/lua/nui/tree/init.lua:261: Invalid 'window': Expected Lua number
```

Es  schie0t sich dann das neotree window sofort nach dem lffnen und ein neues window auf der default poition öffnet sich. das cwd wurde dann aber erfoplgrecih auf die neue file gesetzt.


Kannst du herausfindern,  wo dias problem leigt?
Für meinen teil bin ich n mienre gesamten nvim config neotree beretis alle

`vim.api.nvim_set_current_win`

calls in pcall gepackt. Da der bug aber in der neotree builtin source code auftauchen zu scheint, weoiß ich nicht ganz, wie ich dem ansonten noch vorbeugen kann bzw. wo ich etwas falsch mache.

