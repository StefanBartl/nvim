# `filetree.nvim`

## Table of content

  - [General](#general)
  - [neotree spezifisch](#neotree-spezifisch)
    - [sources](#sources)
  - [hooks](#hooks)
    - [state/windows.lua & state/tree.lua](#statewindowslua-statetreelua)
  - [Später](#spter)
  - [möglicherweise](#mglicherweise)

---

## Neue Features

- [ ] Userconfig schalter, mit dmm man angeben kann, wo man confirmations nach aktion haben will, also zb.:
  - Beim pasten mit `p`
  - Beim entfernen mit `d`
  - Beim .... also alle aktionen, die dementsprechend confiramtion verlangen könnten

  In der user config sol dan so in etwa:

  ```lua
  {
    "StefanBartl/filetree.nvim",
    event = "VeryLazy", -- must load AFTER the tree plugin's config function runs
    dependencies = {
      "StefanBartl/lib.nvim", -- shared helpers (neo-tree node utils, etc.)
      -- only ONE tree plugin is needed:
      "nvim-neo-tree/neo-tree.nvim",
      -- or: "nvim-tree/nvim-tree.lua",
    },
    config = function()
      -- That's it — every feature is on by default.
      require("filetree").setup({
        adapter = "neotree",
        confirmation = true, -- Alle confiramtoins an
        --oder
        confirmations = {
          delete = true,
          create = false,
          --....
        }
      })
    end,
  },
  ```

  Wobei de genaue bezeichnung und umsetzung du etewas vorschlagen kanns!

- [ ] Beim createn mit `a` soll die erstellte file gleich als buffer geöffnet und fokusiiert werden.

## Bugs

- [ ] `U`: Trash Undo scheint nicht zufunkltnioeren
- [ ] `Tab` preview hat keine lsp highlghtiung, das wäre suer, soll auch vom suer einstellbar sein ob er das will oder nicht
- [ ] `cwd_sync`
  - [ ] BUG: Wenn ich ein cwd sync auslöse, zb ffne ich über das harpoon menu eine file in einem andern projekt während der filetree offen ist, dann pasiert momentan folgerndes: Es wird eine prompt ausgeben "File not in cwd. Change to new cwd?" oder so auf die art. Das sollte nicht sein, wenn ich cwd_sync als feature aktiviert habe, dann soll er immer das cqwd syncen ium filetere - sobald im fokusierten buffer ein anderes cwd ist, dann der sync
  - [ ] Eine neue option - für die user config & default - mit der man cwd_sync so steuern kann, dass es versucht bei einem cwd_sync immer den nächstgelegene Folder mit .git hinsynced. DAmit kann verhindert werden, dass cwd_sync immer den übergeorndeten folder der files nimmt und man sehr häufoige cwd spprünge/syncs hat. Es wäre natürlich super wenn
    - [ ] es eine `lib.nvim` modul schreiben würd, das immer das nächstgelgende .git folder findet - bzw. einen bestimmten Folder findet und den korrekte fad zurückgibt, so könnte man eine liste an möglichen flder die au fein projekt hinweisen übergeben, wie .gi oder node_modules usw... Und diesen verwenden wir dann in filetree.nvim
    - [ ] Dies option soll der user daeaktviern können, default ist es aktiv, optional kann er auch eine liste an ordnern übergeben zu denen geachtet wierden soll
    - [ ] Irgendein system brauchen wir, dass möglichst gute performancer sicherstellt, vielleicht ein cache oder eine art hot path, indem zu jheder in der session aufgemachten file das püassende cwd einmal errechnet und dann temporär für die sessiongespeichert wird, vielleicht mit  einen ringbuffer, oder vielelicht gibt es eine bessere option...

## General

1. Alle keymaps prüfen

---

## Filetree Manager spezifische Features

1. neotree, nvimtre, netrwq, oil, minifiles spezifische features sammeln (features, die diese plugins selbst anbieten)

### neotree spezifisch

| Datei | Was drin | Für filetree.nvim? |
| ----- | -------- | ------------------ |
| `utils/selective_callback_guard.lua` | Monkey-patcht `neo-tree.events._handlers` für Event-Transitionen | **NEIN** — neotree-intern, aber inspiriert `watcher_quarantine` neotree-Adapter-Integration |
| `utils/event_patch.lua` | Patcht `neo-tree.sources.filesystem.lib.fs_watch` für EPERM-Suppression | **NEIN** — komplett neotree-intern |

---

#### sources

| **sources/ + icons/** | Lazy Source Registry, 3 Icon-Familien (nerd/codicons/common), responsive Größe |

1. `sources` feature von neotree, kann wr das implementieren? Filetree spezifische features z uunterstützen ist auf dauewr sicherlich ein key zum Erfolg - es mus aber nicht 1:1 jedes feature sein, denn man kann als user ja auch in dedr seiner neotree config features aktiviren neben filetree.nvim... aber trotzdem wenn feaatures gut unterstützt werdden können wäre das super. Da wäre es toll, wenn wir Templates anbieten könnten, also zb: für das source feature in neotree verschiedenne source konfiguartionen,. anrodungen usw... ich weiß noch,. das war ein pain in the *peips* daie sources manuell einzurichten...
2. Explizit userkonfigurationen füür dasd filetree.nvim sammeln: Auf eigener developer seite kawnn ich einen Endppoint/Webppage bauen, bei der man konfigurationen posten und scrreenshots teilen kann. Diese Seite kan ich dann ihn der filetree.nvim README auf GIthub auch hinterlgen

---

## hooks

---

### state/windows.lua & state/tree.lua

- `state/windows.lua` — Window-State-Registry (open/position/source, Listener-Pattern, Snapshot-Cache). Das deckt `adapter.is_open()` / `adapter.get_winid()` in filetree.nvim bereits ab. Das Listener-Pattern wäre interessant, gehört aber in einen zentralen Event-Bus (filetree hat `hooks_api` dafür geplant).

lua\config\neotree\state\tree.lua

- `state/tree.lua` — Cursor-Position + expanded-Nodes speichern/restoren. Nutzt neotree-interne APIs (`tree.expand_batch`, `tree.set_selection`) — nicht übertragbar. Inspiration für `session`-Feature (adapter-spezifisch implementieren).

lua\config\neotree\state\tree.lua

---

## Später

1. in `?` Cheetsheet sollen alle Keymaps angezeigt werdenV
  - in neotree FIXED;
  - in nvim
  - in netrw
  - in oil
  - in minifiles
  - wenn es nicht klappt, als letzten ausweg: eigenes cheatsheet schreiben, das `?` ersetzt
2. Noch ein check: Alles Cross-Plattform? Cross-Filetree-Plugins?
3. Neotree: Keymaps auch als usrcmds implementieren, die in neotree aber auch nvim tree usw funktioenren, zb könte man dann alle folder eines ordnnenr pfad kopieren, und den rekuuriscen kevek angeben
    1. neotere spezifische usrcmds -> `:FT neotree [options?]` (mit autocompletion)
5. [Keymaps](../../NOTES/neotree/Keymaps.md) && [Rest](./../../NOTES/neotree/Auto-Usrcmds-EventHandler.md): Gegenchecken, was noch fehlt
6. Features durchgehen
7. Alles aus der `nvim/config/lua/neotree/**` && `nvim/lua/plugins/neotree.lua` emtfernen, was bereits in `filetree.nvim` implementiert ist und eigentlich schon funkltioeren müsste, wenbn ich ews impleemntiere

---

## möglicherweise

1. "Wenn du neo-tree**s native** Visual-Markierung (`explicitly_marked_node_ids`) als Alternative zu filetrees eigenem Mark-System nutzen willst, wäre der saubere nächste Schritt eine Adapter-Methode `get_target_nodes()` auf Basis von `libnode.collect_nodes(state)`. Sag Bescheid, dann baue ich das."
2. `e:\repos\filetreepicker.nvim`
3. `e:\repos\neotree-fs-refactor.nvim`

---

## TEMP

rotzdem passt da einiges nicht. ich übergeb dir nun die liste der keymaos so wie sie super funkltionert hjabe als ich noch alles in der nvim config hatte, als neotree user config. Genaui so von den keymaps her sol es auch jetzt sein. daher:

Gehe ddie liste mit den aktuell zughwiesenen keymPs kexmap für kexymapo durch und checke>:



* ist das mapping kgenasu auf der gelichen taste?

* Gib es das mapping überhaupt`?

* Ist es ein neus mapping ? (die gehen wir dann separat durech, ob wir jede neer neuen wirlich benötigen)



gib die lsite danach bitte mal aus und ich werded dann feebak geben. heir mal die liste der keymaos so wie sie sein sollten:



<!-- # Neo-tree Keymaps Übersicht

