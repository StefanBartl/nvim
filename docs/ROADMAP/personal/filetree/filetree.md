# `filetree.nvim`
Folgendes: Wir gaheb ein fence featre, dass die fence  zeilen start und ende marker ``` dfie g anze zeiele higlighted. Nun, auf meinen pc (screenshot) funktinert das wie gewünscht, af meiner workstatiopn (dell laptop) aber wird ales im fence higlighted (screenshot)



Auf beiden systemen sind windows und powershell im einsatz, einziger unterschie ist, das ich auf meinen pc wezterm verwende, in der workstation das windows terminal powershell standard. Aber das hat denke ich dkeinen auswirkung, nur zur vollständigkeit. 

Auf beiden systemen ist die gleiche nvim config isntalliert und exakt gleich implemenitert..



Wie kann das sein? gibt es etwas, was ich misse? Soll cih etwas abfragen auf der workstation? oder kann es ein bug in der filetere fence iomplementierung sein?



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

## Bugs

## General

1. Alle keymaps prüfen
2. wen cwd_syn akltiv , der filetee offen iost undzwischen den buffern hin und her gewwechselt wird, dann soll der filetree immer das neue cwd_yyncen wen ein buffer ein anderes hat als der vorige^

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
3. Keymaps auch als usrcmds implementieren, die in neotree aber auch nvim tree usw funktioenren, zb könte man dann alle folder eines ordnnenr pfad kopieren, und den rekuuriscen kevek angeben
    1. neotere spezifische usrcmds -> `:FT neotree [options?]` (mit autocompletion)
4. [Keymaps](../../NOTES/neotree/Keymaps.md) && [Rest](./../../NOTES/neotree/Auto-Usrcmds-EventHandler.md): Gegenchecken, was noch fehlt
5. Features durchgehen
6. Alles aus der `nvim/config/lua/neotree/**` && `nvim/lua/plugins/neotree.lua` emtfernen, was bereits in `filetree.nvim` implementiert ist und eigentlich schon funkltioeren müsste, wenbn ich ews impleemntiere

---

## möglicherweise

1. "Wenn du neo-tree**s native** Visual-Markierung (`explicitly_marked_node_ids`) als Alternative zu filetrees eigenem Mark-System nutzen willst, wäre der saubere nächste Schritt eine Adapter-Methode `get_target_nodes()` auf Basis von `libnode.collect_nodes(state)`. Sag Bescheid, dann baue ich das."
2. `e:\repos\filetreepicker.nvim`
3. `e:\repos\neotree-fs-refactor.nvim`

---

