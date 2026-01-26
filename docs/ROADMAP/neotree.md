# neotree- Roadmap & Ideas

## Table of content

- [neotree- Roadmap & Ideas](#neotree-roadmap-ideas)
  - [Watch](#watch)
  - [Important](#important)
    - [neotree/open/](#neotreeopen)
  - [normal](#normal)
    - [Bei öffnen Fokus auf Neotree window setzen](#bei-ffnen-fokus-auf-neotree-window-setzen)
      - [funktionert, aber mit kleinen bug](#funktionert-aber-mit-kleinen-bug)
      - [Bereits geteste, hat nicht funktionert](#bereits-geteste-hat-nicht-funktionert)
    - [open (m-f, m-l usw..)](#open-m-f-m-l-usw)
  - [config/neotree/cwd_sync optimierung und bugfix](#configneotreecwd_sync-optimierung-und-bugfix)
    - [error (Hohe priorität)](#error-hohe-prioritt)
    - [Optimierungen ausarbeiten](#optimierungen-ausarbeiten)
      - [Mögliche umfangreiche  Optimierungen für künftige updates: Analyse und Machbarkeits-Einschätzung](#mgliche-umfangreiche-optimierungen-fr-knftige-updates-analyse-und-machbarkeits-einschtzung)

---

1. Wenn sources switch dann soll der fokus im neotree bleiben

 Jede Löschung aus dem neotree heraus muss doppelt bestätigt werden, das ist nicht notwenidg:

Erste prompt:

```vim
Move to trash: nil ?  (y(N)
```

zweite prompt:

```vim
             Input
delete: C:\.....ABSOLUTER-PFAD.md ? (y/(N)
```

3. mark:
    - nicht nur für löschen sondern auch für files kopieren, verschieben usw...
    - soll ene markierung im lnken rand (sign column / sign gutter) erzeugen wenn markiert.
    - delete all muste ich dann erst wieer alle ienzeln bestätigen das löschen

---

## Watch

1. Ersetztn die `[f]`-Mappings in der Praxis tatsächlich die `[r]`-Mappings?

---

## Important

1. Neotree keymaps werden relativ oft verwendet. imports hier belassen, in die funktionen refactoren oder mit `lib.lazy`?
2. checkhealt: modular machen, dafoür brauche ich ein system + doc
3. CWD sync muss:
    - performanter gemacht werden, asynchron sc hon bever man neotree öffnet
    - löst die reopenings aus
    - ist es async?
    - wie funktniert es genau? wäre es nicht besser, anstatt bei jeden neotree openeing das im hintergrund zu machen bei bufferwechsel?

---

### neotree/open/

1. Der zustabnd ist unschön
2. early float return?
3. `config/neotree/open/window` sollte eigentlich `config/neotree/window/open` sein und nicht eumgekehrt, denn es geht um ein windcow, das geäfnet wird. aes müsste dann aber close und sowitch auch heraud refactored werden, wenn wir wirlich "open" verwenden

---

## normal

1. in commands, usrcmds, kleymaps einen  oprdner /sources machen
2. Plugin Varianten systemaitsch pperformance testen mit `plugins/neotree_variants`
3. Lazy opt opimierung machen
4. watcheruarantien ist ja eigentlich ein rash / filesystem modul, sollte auch dorthin moved werden

---

### Bei öffnen Fokus auf Neotree window setzen

---

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

---

#### Bereits geteste, hat nicht funktionert

---

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

---

