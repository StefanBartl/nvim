# neotree- Roadmap & Ideas

## Table of content

- [neotree- Roadmap & Ideas](#neotree-roadmap-ideas)
  - [Critical](#critical)
  - [Important](#important)
  - [normal](#normal)
    - [open (m-f, m-l usw..)](#open-m-f-m-l-usw)
    - [marks / trash](#marks-trash)

---

## Critical

1. Failes to copy folder oder file list, mit [f ]f [F ]F warum ?

--

## Important


---

## normal

- @types muss reformiert werden
- alle ussercommands nach config/neotree/usercommands/init.lua sammeln

---

### Bei löffnen Fokus aus Neotree window setzen

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


---

### open (m-f, m-l usw..)

1. Neotree window muss schneller öffnen können, das dauert zu langsam nd wirkt nicht mehr flüssig:
2. sources einzeln mal deaktivieren, sources messen wir lange der unterschied ist wenn an einzeln wegnimmt
  - --> Im window alles sources deaktivieren bis auf filesyte, dann einen source selector mit zb.: "M-s" machen
3. open.windows: wenn man eine neotree window offen hat und dann ein anderes öfffnet, macht es erstmal das andere zu ohne das neue zu öffnen. dann muss man nochmal öffnen. also sagen wir neotree win links ist offen, ich drücke M-f dann macht es erstmal win left zu. jetzt muss ich nochmal M-f drücken um das float win zu bekommen. Es osllt eso sein, dass jedes window mapping mapping zuerst prüft ob ein neotree win offn ist., wenn ja, dann schlißeen und das neue öffnen in einem zug.

--

### marks / trash

--
