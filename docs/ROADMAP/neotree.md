# neotree- Roadmap & Ideas

## Table of content

- [neotree- Roadmap & Ideas](#neotree-roadmap-ideas)
  - [Critical](#critical)
  - [Important](#important)
  - [normal](#normal)
    - [open (m-f, m-l usw..)](#open-m-f-m-l-usw)
    - [marks / trash](#marks-trash)

---

## Watch

1. Ersetztn die `[f]`-Mappings in der Praxis tatsächlich die `[r]`-Mappings?

---

## Important


---

## normal

1 @types muss reformiert werden
1. commands und aktionen sammeln
    - alle usercommands nach config/neotree/usercommands/init.lua sammeln
    - alle keymaps die mit vim.keymap.set oder einem direkten äqivalent wie nvim_create_keympa oder map (aus lib.map) nach config/neotree/keympaps/init.lua sammeln (es geht in ordnung hier eine neues modul zu schreiben, das aktuelle config/neotree/keymaps eigentlich keympas in sources sind und daher nach confiog/neotree/sources verschoieben werden.
    - alle autocmds nach config/neotree/automcmds/init.lua sammeln
    - Für all diese Files im Ordner eine enstprechende README.md auf deustch schreiben

1. commands und actions nach keymaps, keymaps nach sources verschieben

--

### Bei öffnen Fokus auf Neotree window setzen

#### funktionert, aber mit kleinen bug

Folgende Variante funktiert bei allen 4 window positionen. Ein Bug ist aber, wenn man aus dem float window direkt in ein rechtes oder linkes neotree window wechselt, dann geht der fokus nicht mit. Man muss dann erstmal das window wieder schlie0en und neu öffnen um den fokus automaitsch hineon zu bekommen oder mit wincmd hineinwechseln, aber dnan wäre es ja kein auto fokus mehr. In allen anderen Szenarien klappt es. Spannend: wenn m,an in ein float window wechselt und dann direkt in ein current neotrew window, dann kann amn von dort direkt wieder in ein links oder rechtes mit auto fokus wechseln, das scheint es zuirückzusetzen.

```lua
  -- Nach dem Öffnen Fokus zurück auf vorheriges Fenster setzen (außer bei Float)
  {
    event = "neo_tree_window_after_open",
    handler = function(args)
      local function is_float(winid)
        if not vim.api.nvim_win_is_valid(winid) then
          return false
        end
        local cfg = vim.api.nvim_win_get_config(winid)
        return cfg.relative ~= "" and cfg.relative ~= nil
      end

      if not args.winid or not vim.api.nvim_win_is_valid(args.winid) then
        return
      end
      if is_float(args.winid) then
        return
      end
      if M._prev_win and vim.api.nvim_win_is_valid(M._prev_win) then
        vim.schedule(function()
          vim.api.nvim_set_current_win(M._prev_win)
        end)
      end
    end,
  },
```

#### Bereits geteste, hat nicht funktionert

##### `plugins/neotree.lua`

```lua
-- focus_on_open gibt es nicht mehr:
require("neo-tree").setup({
  filesystem = {
    -- Focus the Neo-tree window immediately after opening
    focus_on_open = true,
  },
})


event_handlers = {
-- VARIANTE 1:
{
    event = "neo_tree_buffer_enter",
    handler = function()
      -- Wird ausgelöst, sobald der Cursor ein Neo-tree-Buffer-Fenster betritt.
      -- Das Highlight der Cursor-Gruppe wird so verändert, dass der Cursor
      -- vollständig transparent ist (blend=100).
      -- Effekt: der Cursor ist im Neo-tree-Fenster unsichtbar, obwohl das Fenster fokussiert ist.
      vim.cmd("highlight! Cursor blend=100")
    end,
  },
  {
    event = "neo_tree_buffer_leave",
    handler = function()
      -- Wird ausgelöst, sobald der Cursor den Neo-tree-Buffer wieder verlässt.
      -- Das Highlight der Cursor-Gruppe wird auf eine sichtbare Hintergrundfarbe
      -- mit deaktivierter Transparenz zurückgesetzt (blend=0).
      -- Effekt: der Cursor erscheint in normalen Buffern wieder wie gewohnt.
      vim.cmd("highlight! Cursor guibg=#5f87af blend=0")
    end,
  },

-- VARIANTE 2:

    {
        event = "neo_tree_buffer_enter",
        handler = function(args)
            -- Ensures that the Neo-tree window always receives focus when its buffer is entered.
            -- This is more reliable than window-based events because it runs after buffer activation.
            if args.winid and vim.api.nvim_win_is_valid(args.winid) then
                vim.api.nvim_set_current_win(args.winid)
            end
        end,
    },
}


```

##### Autocommands

1. Funktioniert zawr für  Neotree window links, rechts und current, aber es hat die Auswirkung, dass sich das flaot window sofort wieder schließt.

```lua
  if opts.auto_fokus and opts.auto_fokus == true then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "neo-tree",
      callback = function()
        vim.schedule(function()
          -- This runs after the buffer and window are fully initialized.
          vim.cmd("wincmd p")
          vim.cmd("wincmd w")
        end)
      end,
    })
  end
```

Ist also in dieser Versionm so keine Option.

---

### open (m-f, m-l usw..)

1. Neotree window muss schneller öffnen können, das dauert zu langsam und wirkt nicht mehr flüssig:
2. sources einzeln mal deaktivieren, sources messen wir lange der unterschied ist wenn an einzeln wegnimmt
  - --> Im window alles sources deaktivieren bis auf filesyte, dann einen source selector mit zb.: "M-s" machen

-

### marks / trash

--
