# Bug: Neo-tree "Error setting nodes" (nui `_child_ids` läuft aus dem Tritt)

Beobachtet 2026-08-26 ab 18:44:36, in Serie. Status: **nicht gefixt, unter Beobachtung.**
Beide beteiligten Plugins sind Fremd-Repos (`MunifTanjim/nui.nvim`,
`nvim-neo-tree/neo-tree.nvim`), beide auf dem jeweils neuesten Stand — es gibt
dort keinen Commit, der die Stelle behebt.

## Symptom

```
[Neo-tree ERROR] Error setting nodes:  .../nui.nvim/lua/nui/tree/init.lua:494:
attempt to index local 'node' (a nil value)
```

Danach jedes Mal ein Dump des **kompletten** Baums in die Meldungen — das ist
`renderer.lua:1421`, `log.error(vim.inspect(state.tree:get_nodes()))`. Daher die
riesigen Ausgaben.

Der Fehler wiederholt sich, bis Neo-tree geschlossen und neu geöffnet wird:
`set_nodes` stirbt, **bevor** es `parent_node._child_ids = nil` setzt, der Baum
bleibt also für den Rest der Session inkonsistent.

## Mechanik

1. **Absturzstelle** ist nuis internes `remove_node`:
   `local node = tree.nodes.by_id[node_id]` → `node:has_children()` mit `node = nil`.
   Es wird rekursiv über `_child_ids` gelöscht und dabei eine ID getroffen, die
   nicht mehr in `by_id` steht.

2. **Ursache in nui**, `initialize_nodes` (`lua/nui/tree/init.lua`):
   - Zeile 70: `node.__children = nil` — die Kinder werden beim ersten Init
     **verbraucht**.
   - Zeile ~51: `if not node._child_ids then node._child_ids = {} end`, danach
     `table.insert(node._child_ids, ...)` — bei einem schon initialisierten
     Knoten wird also **angehängt statt ersetzt**.

   Ein zweiter `set_nodes` mit denselben Knoten-Objekten erzeugt damit still
   einen kaputten Baum: die Kinder fehlen in `by_id`, `_child_ids` bleibt stehen.
   Reproduziert (siehe unten), deterministisch.

3. **Auslöser in neo-tree**: genau *eine* Stelle gibt lebende, bereits
   initialisierte Knoten an `set_nodes` zurück — der `group_empty_dirs`-Zweig
   beim Nachladen eines Einzel-Unterordners, `ui/renderer.lua` ~1522:

   ```lua
   local siblings = state.tree:get_nodes(parentId)   -- lebende Knoten
   ...
   state.tree:set_nodes(siblings, parentId)
   ```

   Der Kommentar dort sagt es selbst: "To avoid digging into private internals
   of Nui, we will just export the entire level and replace the one node."
   Alle anderen `set_nodes`-Aufrufe bekommen frische Knoten aus `create_nodes`
   (`renderer.lua:1552`).

4. **Passt zur Config**: `group_empty_dirs = true` (zweimal in
   `lua/plugins/neotree.lua`), `scan_mode` nicht gesetzt → Default `"shallow"`,
   und genau bei `"shallow"` wird der problematische Zweig genommen. Die Fehler
   beginnen 18:44:36, unmittelbar nachdem `docs/Telemetry/Workstation` — eine
   Ein-Kind-Kette, exakt der Gruppierungsfall — um 18:44 entstand.

5. **Passt zum Dump**: `docs._child_ids` listet sechs Kinder
   (`ARCHITECTURE, map, NOTES, ROADMAP, Telemetry\Workstation, TESTING`),
   `by_id` kennt nur noch drei davon. Die Render-Cache-Tabelle
   `linenr_by_node_id` kennt dagegen alle sechs — sie waren also gerendert und
   sind danach aus `by_id` verschwunden.

**Ehrlich zur Beweislage:** das End-to-End-Repro mit echtem Neo-tree ist *nicht*
gelungen — die exakte Sequenz liess sich synthetisch nicht nachstellen (Toggle
des gruppierten Ordners, Datei-Watcher, neue Verzeichnisse: alles blieb
konsistent). Punkt 1, 2 und 5 sind belegt, Punkt 3 und 4 sind starke Indizien,
kein Beweis.

## Minimal-Repro (nur nui, ohne Neo-tree)

```lua
local NuiTree = require("nui.tree")
local function mk(id, kids) return NuiTree.Node({ id = id, text = id }, kids) end

local kids = { mk("a"), mk("b"), mk("c") }
local docs = mk("docs", kids)
local root = mk("root", { docs })
local tree = NuiTree({
  bufnr = vim.api.nvim_create_buf(false, true),
  nodes = { root },
  get_node_id = function(n) return n.id end,
})

-- Dieselben Objekte ein zweites Mal hineingeben:
tree:set_nodes({ root })

-- by_id enthält jetzt nur noch "root"; docs._child_ids listet a, b, c weiter.
-- Der nächste set_nodes läuft über diese IDs und wirft
-- "attempt to index local 'node' (a nil value)".
```

## Sofort-Hilfe, wenn es auftritt

Neo-tree schliessen und neu öffnen (`:Neotree close` / wieder auf). Ein frischer
Baum ist wieder konsistent; ohne das bleibt der Fehler bis zum Session-Ende.

## Mögliche Fixes — bewusst *nicht* umgesetzt

Beide sind Einzeiler in `lua/plugins/neotree.lua`, beide haben einen Nachteil,
deshalb erst mal beobachten statt ändern:

| Option | Wirkung | Nachteil |
| --- | --- | --- |
| `group_empty_dirs = false` | der problematische Zweig wird nie betreten | die kompakte Darstellung (`Telemetry/Workstation` als eine Zeile) entfällt |
| `scan_mode = "deep"` | Gruppierung bleibt, neo-tree nimmt den Zweig mit frischen Knoten | scannt Verzeichnisse tiefer, in grossen Repos spürbar langsamer |

Der saubere Fix gehört nach oben: nui müsste `_child_ids` beim Re-Init
zurücksetzen statt anzuhängen (oder das Re-Init eines initialisierten Knotens
ablehnen), oder neo-tree dürfte an dieser Stelle keine lebenden Knoten
zurückreichen.
