# lib.nvim Modul-Audit (docs / @types / Aggregatoren / Feature-Ideen) — 2026-09-07

**Status: läuft, ca. 1/3 der kleinen/mittleren Module durch, die vier großen
Subsysteme (bindings/cross/fs/ui) und `lib.lua.*` noch nicht angefasst.**

Auslöser (Chat, Repo `lib.nvim` in einem Worktree, nicht nvim-config selbst):

> lib.nvim - alle module durcgehen und checken, ob docs, @types, als auch
> aggregatoren noch korrekt sind. Die lib.nvim ist für mich umso mehr wert,
> umso besser die docs sind. Dabei auch gleich feature ideen einbringen,
> sprich bei jedem modul am ende auch checken "fehlt etwass sinnvolles?"

Tracking-Datei **im lib.nvim-Repo selbst** (nicht hier), lebt fort über
Sessions hinweg: [`E:/repos/lib.nvim/docs/MODULE_AUDIT.md`](file:///E:/repos/lib.nvim/docs/MODULE_AUDIT.md) —
dort steht die vollständige Inventar-Tabelle aller Top-Level-Module
(init/README/@types-Vorhandensein) plus das Pro-Modul-Log mit jedem Fund.
Diese Handover-Datei hier ist nur die Kurzfassung + Aufwandsschätzung.

---

## Table of contents

- [Methode](#methode)
- [Bisheriger Fortschritt](#bisheriger-fortschritt)
- [Bisherige Funde](#bisherige-funde)
- [Was noch aussteht](#was-noch-aussteht)
- [Aufwandsschätzung](#aufwandsschätzung)
- [Wie weitermachen](#wie-weitermachen)

---

## Methode

Pro Modul (Granularität: die Namespace-Tabellen in
[`docs/modules.md`](file:///E:/repos/lib.nvim/docs/modules.md)):

1. `init.lua` (echte API) gegen `README.md` (dokumentierte API) gegenlesen —
   fehlende/überzählige/falsch beschriebene Funktionen.
2. `@types/*.lua` gegen die tatsächlichen Parameter/Rückgaben gegenlesen;
   prüfen ob die Modul-Oberfläche selbst eine `@class` hat und ob `return M`
   ein `---@type` trägt (Konvention laut
   [`docs/conventions.md`](file:///E:/repos/lib.nvim/docs/conventions.md)).
3. Wiring prüfen: Zeile in `docs/modules.md`s Namespace-Tabelle + Per-Module-
   Doc-Bullet; bei `:help`-würdigen Modulen auch `doc/lib.nvim-<modul>.txt` +
   Hub-Zeile in `doc/lib.nvim.txt`.
4. Feature-Idee-Check: "fehlt etwas Sinnvolles?" — notiert, nicht automatisch
   gebaut (das ist eine Design-Entscheidung, keine Audit-Aufgabe).

Gefundene Bugs/Lücken werden direkt gefixt, committet und auf `main`
gepusht (kein Co-Author), in Batches von ca. 4-6 Modulen.

## Bisheriger Fortschritt

**13 von ~37 Top-Level-Modulen unter `lib.nvim.*` durch** (alles kleine bis
mittlere, 2-8 Dateien): `core`, `async`, `contextmenu`, `count`, `debounce`,
`dotrepeat`, `git`, `json`, `lastcmd`, `notify`, `require`, `safe_api`,
`selection`. Ein Commit gepusht (`cc08fad`) mit 4 echten Fixes.

`lib.nvim_usrcmds` (eigener Namespace neben `lib.nvim`, nicht in dessen
Baum) stichprobenartig geprüft — sauber dokumentiert (README, root-README,
`docs/BINDINGS.md`), bewusst nicht in `modules.md` gelistet, da andere
Kategorie (Opt-in-Usercmds für Nutzer der Library, nicht Library-API für
andere Plugins).

## Bisherige Funde

Details im Pro-Modul-Log der Tracking-Datei. Kurzfassung, alles bereits
gefixt und gepusht:

- **`lib/nvim/init.lua`**: Docstring behauptete einen Shortcut
  (`Nvim.map == require("lib.nvim.bindings.keymap")`), der auf diesem
  Aggregator technisch gar nicht existiert (der ist 1:1, keine
  Kurznamen-Flatten-Logik — die gibt's nur auf dem *anderen*, obersten
  `require("lib")`-Aggregator). Doc korrigiert.
- **`core`**: `@types`-Datei hatte falschen `@module`-Pfad und eine
  Klasse namens `Lib.Nvim` statt `Lib.Nvim.Core` (Namenskollisionsrisiko
  mit dem echten Top-Namespace-Typ). Umbenannt — dabei eine bereits
  bekannte, im Code selbst als "stale, pending check" markierte Altlast in
  `lua/lib/@types/init.lua` (`Lib.Modules`-Klasse) sichtbar gemacht, aber
  bewusst nicht angefasst (schon dokumentiert, außerhalb des Scopes).
- **`debounce`**: `init.lua` und `buffer/init.lua` gaben `M` ohne
  `---@type`-Annotation zurück (jedes Schwestermodul tut das) — LuaLS bekam
  keine Typisierung für `require(...)`. Modul-Oberflächen-Klassen fehlten
  komplett, nachgebaut.
- **`git`**: gleicher Bug wie debounce (fehlende `---@type Lib.Git`), obwohl
  der Typ selbst schon korrekt und vollständig war.
- **`notify`**: `resolve_log_level` existierte als echtes, aktiv genutztes
  Submodul (`lib.nvim.logger` hängt dran), war aber nirgends aggregiert,
  nirgends dokumentiert und ohne eigene Typannotation — obwohl
  `modules.md`s Einzeiler für `notify` genau das schon verspricht
  ("notify wrapper + log-level resolution"). Alle vier Lücken geschlossen.

Muster bisher: die meisten Module sind **sehr sauber** (README/@types/Code
decken sich exakt); die Bugs, die auftauchen, sind mechanisch (fehlende
`---@type` auf `return M`) oder "vergessenes Submodul beim Aggregieren" —
kein einziger Fall von grob falscher/veralteter Dokumentation bisher.

## Was noch aussteht

Unter `lib.nvim.*`, noch offen (aus der Inventar-Tabelle in
`MODULE_AUDIT.md`):

- **Klein/mittel** (ähnliches Tempo wie bisher erwartbar): `store`,
  `terminal`, `token`, `health`, `harvest`, `cache`, `deps`, `logger`,
  `progress`, `window`, `normalize`, `system`, `dev`, `image_preview`,
  `lua_ls`, `markdown`, `neotree`, `net`, `treesitter` — ca. 19 Module.
- **Groß, eigene Unter-Ökosysteme mit vielen Leaf-Modulen** (je eigene
  READMEs/@types pro Untermodul, laut `modules.md` teils ein Dutzend+):
  `bindings` (34 Lua-Dateien), `cross` (42), `fs` (52), `ui` (29),
  `buf_win_tab` (23), `buffer` (7, aber Sonderfall ohne `init.lua` laut
  `modules.md:34` — verifizieren, dass das noch stimmt). Diese fünf sind
  de facto eigene Teilprojekte.
- **`lib.lua.*`-Namespace** (Lua-nur, kein Neovim-Bezug): `tables`,
  `strings`, `functions`, `time`, `json`, `memo`, `lazy`, `class`,
  `context_manager` — noch **gar nicht** inventarisiert, geschweige denn
  geprüft.
- **Glue-Layer**: `lib/config`, `lib/strategies/*` (4 Aggregator-Strategien:
  metatable/lazy/eager/control), `lib/@types/*` — inkl. der bereits
  gefundenen `Lib.Modules`-Altlast, die dort explizit als offen markiert ist.

## Aufwandsschätzung

Ehrlich eingeordnet, basierend auf dem bisherigen Tempo (13 kleine Module
inkl. Fixes, Commit, Push in einer Session):

| Block | Umfang | Geschätzter Aufwand |
|---|---|---|
| Restliche kleine/mittlere `lib.nvim.*`-Module (~19) | 2-15 Dateien je Modul | **1-2 weitere Sessions** |
| `bindings`, `cross`, `fs`, `ui`, `buf_win_tab` | je 20-52 Dateien, viele Unter-READMEs/@types | **je eine halbe bis ganze eigene Session — macht zusammen 3-5 Sessions** |
| `lib.lua.*` (9 Module) | vermutlich klein wie die meisten `lib.nvim`-Module, aber noch ungeprüft | **~1 Session** |
| Glue-Layer (`config`, `strategies`, Top-`@types`) | klein an Dateizahl, aber hoher Prüfaufwand (Aggregator-Logik, Verweise) | **~0.5 Session** |

**Summe: grob 6-9 weitere Arbeits-Sessions** bei der aktuellen Prüftiefe
(Code + README + @types zeilenweise gegenlesen, Aggregator-Wiring prüfen,
Feature-Idee je Modul). Das ist der ehrliche Rahmen für "wirklich jedes
Modul gründlich" — nicht Tage, aber auch nicht "heute Nachmittag fertig".

Zwei Stellschrauben, falls das zu lang ist:
- **Tiefe reduzieren** für die fünf großen Subsysteme (nur Top-Level-README
  + Stichproben bei den Leaf-Modulen statt jedes einzelne Leaf-Modul mit
  derselben Sorgfalt) — spart wahrscheinlich 2-3 der 3-5 Sessions dort.
- **Priorisieren**: zuerst die Module, die andere Plugins tatsächlich als
  Dependency nutzen (`lib.nvim.window`, `.ui.kit`, `.fs.*`, `.cross.*`,
  `.progress`, `.deps` — laut [[lib-nvim-dependency]]), Rest später.

## Wie weitermachen

1. `E:/repos/lib.nvim/docs/MODULE_AUDIT.md` öffnen — die Inventar-Tabelle
   zeigt, welche Module noch kein ✅ im Pro-Modul-Log haben.
2. Nächster Batch: die restlichen kleinen Module (`store` bis `treesitter`
   aus der Liste oben), dann Entscheidung zu den fünf großen Subsystemen
   treffen (volle Tiefe vs. reduzierte Tiefe, siehe oben).
3. Jeder Batch: Fixes direkt im Code, Tracking-Datei nachführen, ein Commit
   pro Batch, sofort auf `main` gepusht.
