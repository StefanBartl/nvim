# docmodule

- Man soll sich durch die
  - hirarchie,
  - Abhängigkreiten der module zueiandner
  - Calls und gecallt werden von funktionen eines moduls visualisert

  durchklicken können, jedes ein einzelner menüpunkt bzw mit rechtscklick auf ein table oder funktionsobjekt auswählbar sein.
  und wenn man eines anklickt, dann verändet sich die Visualiseirung entsprechend für dieses Objekt, und zwar smooth also mit "bewegung".
  Doxygen --> Vorbield

---

# Implementierungs-Konzept: `lib.nvim.docmap` — Graph-Views & Browser-UI

> Modul: `lua/lib/nvim/docmap/` (heißt im Code `docmap`, nicht `docmodule`).
> Output: `docs/map/index.html`, `overview.md`, `module_map.json`.
> Vorbild: Doxygen (Collaboration / Include / Caller / Callee Graphs).

## 0. Ist-Stand (was schon da ist)

| Baustein | Datei | Status |
|---|---|---|
| Header-Scan (`@module`, Summary, README, Types) | `scan.lua` | ✅ |
| Funktions-Scan via treesitter (`@param`/`@return`/`@see`/…) | `functions.lua` | ✅ **Deklarationen**, keine Call-Sites |
| LuaLS-Enrichment: `@class`/`@alias` + Typ-Kanten | `luals.lua` | ✅ opt-in (`:LibMap full`) |
| Drift-Checks | `check.lua` | ✅ |
| HTML: Tab **Tree** (Baum + Detail-Pane) | `render/html.lua` | ✅ |
| HTML: Tab **Hierarchy**, Views **Modules** / **Types** | `render/html.lua` | ✅ |
| History-State `{tab, id, center, view}` | `render/html.lua` | ✅ |

**Fehlt gegenüber der Vision:**

1. **Keine Require-Kanten im IR.** `check_orphans` sammelt `require("…")`-Strings
   *transient* innerhalb des Checks und wirft sie weg. Es gibt also kein
   Abhängigkeits-Graph-Datum, das ein Renderer lesen könnte.
2. **Keine Call-Kanten.** `functions.lua` findet Funktions-*Definitionen*, nie
   Aufrufe. Damit gibt es weder Callee- noch Caller-Graph.
3. **Kein Kontextmenü.** Navigation nur über Linksklick / Doppelklick / den
   `Hierarchy ↳`-Link im Detail-Pane.
4. **Keine Bewegung.** `drawHierarchy()` macht `hgraph.innerHTML = ""` und baut
   alles neu — jeder Wechsel ist ein harter Schnitt.
5. **Funktionen sind keine navigierbaren Objekte.** Sie existieren nur als
   Text-Abschnitt im Detail-Pane; man kann nicht auf `M.scan_full` zentrieren.

Das Konzept unten schließt genau diese fünf Lücken, in dieser Reihenfolge —
Daten zuerst, UI danach, Animation zuletzt.

---

## 1. Datenmodell: Kanten bekommen eine `kind`

Heute ist `ir.edges` implizit „Typ-Referenzkanten". Das wird verallgemeinert;
**ein** Kanten-Array mit Diskriminator statt drei parallelen Feldern, damit
Layout/Filter/Zeichnen genau einmal existieren.

```lua
---@alias Lib.Docmap.EdgeKind
---| "type"    # Feld einer @class referenziert eine andere @class (heute: ir.edges)
---| "require" # Datei A enthält require("modul.b")
---| "call"    # Funktion A ruft Funktion B auf

---@class Lib.Docmap.Edge
---@field kind Lib.Docmap.EdgeKind
---@field from string          Node-Id (Quelle)
---@field to string            Node-Id (Ziel)
---@field from_class string?   nur kind="type"
---@field to_class string?     nur kind="type"
---@field via string?          kind="type": Feldname
---@field from_fn string?      nur kind="call": qualifizierter Name, z.B. "M.scan_full"
---@field to_fn string?        nur kind="call"
---@field to_module string?    nur kind="require": deklarierter require-String
---@field line integer?        Zeile der Call-Site / des require
---@field confidence ("exact"|"heuristic")?  nur kind="call", s. §3
```

**Migrationsregel:** bestehende Typ-Kanten bekommen `kind = "type"`, sonst
unverändert. `luals.lua` bleibt der einzige Produzent davon. Renderer, die heute
`IR.edges` roh iterieren (Types-View, `layoutTypes`), filtern künftig auf
`kind === "type"`. **IR-Schema-Version (`meta.schema`) hochzählen.**

Zusätzlich pro Node, als bequemer Index (aus den Kanten abgeleitet, nicht
zusätzliche Wahrheit):

```lua
---@field requires string[]     Node-Ids, die dieser Node requiret
---@field required_by string[]  Node-Ids, die diesen Node requiren
```

---

## 2. Phase A — Require-Graph (`deps.lua`)

Neue Stage zwischen `scan` und `check`, unconditional (kein LuaLS nötig, kostet
nur das Lesen von Dateien, die `scan` sowieso schon anfasst).

- **Extraktion:** dasselbe Pattern wie heute in `check_orphans`
  (`require%s*%(?%s*['\"]([%w%._%-]+)['\"]`), aber *pro Datei attribuiert*
  statt in ein globales Set geworfen. Zeilennummer mitnehmen.
- **Auflösung:** `module`-String → Node-Id über eine `module → id`-Map aus
  `ir.order`. Nicht auflösbare Requires (`vim.*`, externe Plugins) werden
  **verworfen**, nicht als Fremd-Node erfunden — der Graph bleibt „was in diesem
  Baum liegt". (Optional später: Toolbar-Schalter „externe Requires zeigen",
  dann als eigene Box-Klasse `k-external`.)
- **Dedupe:** mehrfaches `require` desselben Moduls in einer Datei = eine Kante.
- **`check_orphans` baut auf `ir.edges` auf** statt selbst zu scannen — die
  Datei-I/O passiert danach genau einmal.

**Neue Checks, die dadurch fast gratis werden:**

| Check | Severity | Fängt |
|---|---|---|
| `require-cycle` | warn | Zyklus im Require-Graph (Tarjan SCC > 1). |
| `require-not-declared` | info | Kante existiert, aber Ziel-Modul hat kein `@module`. |
| `layer-violation` | warn | opt-in via `opts.layers`: `lib.vim.*` darf nicht `lib.nvim.*` requiren o.ä. |

`layer-violation` ist optional und repo-spezifisch (`extra_checks`), nicht
generisch — aber das Datum dafür liegt ab hier bereit.

**Acceptance:** `module_map.json` enthält `kind:"require"`-Kanten; Anzahl
deckt sich mit einem manuellen `grep -c require` über `lua/` (± unaufgelöste);
`--check` bleibt byte-deterministisch (Kanten **sortiert** ausgeben:
`from, to, from_fn, to_fn, line`).

---

## 3. Phase B — Call-Graph (`calls.lua`)

Der ehrlich schwierigste Teil. Kein LuaLS (siehe README: `--doc` sieht die
meisten Funktionen dieses Repos gar nicht), also **treesitter**, wie schon in
`functions.lua`.

### Vorgehen pro Datei

1. **Alias-Tabelle bauen:** `local fs = require("lib.nvim.fs")` →
   `fs → lib.nvim.fs`. Auch `local x = require("…").sub` und
   `local M = require("…")` erfassen. Das ist der Schlüssel: ohne Alias-Auflösung
   ist ein Call-Graph in Lua Kaffeesatz.
2. **Enclosing-Function bestimmen:** über die schon in `functions.lua`
   ermittelten Definitions-Ranges — welche Top-Level-Funktion enthält die
   Call-Site (Zeilenintervall)? Damit hat die Kante ein `from_fn`.
3. **Call-Sites finden:** treesitter-Query auf `function_call` mit
   `method_index_expression` / `dot_index_expression`. Drei Formen:
   - `fs.read(x)` → Alias `fs` auflöst → Node + `to_fn = "M.read"` (`confidence: "exact"`)
   - `M.helper(x)` / `helper(x)` → modul-intern, Ziel im selben Node
     (`confidence: "exact"`)
   - `obj:method()` auf einem nicht auflösbaren Empfänger → **verwerfen**,
     nicht raten.
4. **Fallback-Heuristik (opt-in, `opts.calls_heuristic`):** unaufgelöster
   Bezeichner, dessen Name genau einer Funktion im Baum eindeutig entspricht →
   Kante mit `confidence: "heuristic"`, im UI gestrichelt/blasser gezeichnet.
   Default: **aus**. Ein falscher Call-Graph ist schlimmer als ein
   unvollständiger.

### Grenzen — explizit dokumentieren, nicht kaschieren

- Dynamik (`M[name]()`, Callbacks über Tabellen, `vim.schedule(fn)`) wird nicht
  erfasst. Doxygen kann das für C++ auch nicht.
- `lib.nvim.require`'s Lazy/Metatable-Strategien (`strategies/`) erzeugen
  Aufrufe, die syntaktisch nirgends stehen. Im UI als Hinweis-Badge am Node
  („dynamic dispatch — call graph incomplete").
- Deswegen: Call-Kanten sind **nie** Grundlage eines `error`-Checks.

**Performance:** treesitter-Parse pro Datei passiert in `functions.lua` bereits.
`calls.lua` muss denselben Tree wiederverwenden → `functions.lua` gibt den
geparsten Tree zurück bzw. beide Scans laufen in einem Durchgang
(`functions.scan_file` → `{ functions, calls }`). Sonst verdoppeln sich die
Scan-Kosten für nichts.

**Acceptance:** für `lib.nvim.docmap` selbst zeigt der Callee-Graph von
`init.generate` mindestens `scan`, `check`, `render.html`, `json.encode`;
Caller-Graph von `json.encode` zeigt `init.generate`. Manuell verifizierbar.

---

## 4. Phase C — Views: vier statt zwei

Die Hierarchy-Toolbar bekommt vier Buttons (`data-view`), Doxygen-Analogie in
Klammern:

| View | Boxen | Kanten | Doxygen-Pendant |
|---|---|---|---|
| **Modules** | IR-Nodes | `children` (solid) | Directory / Class Hierarchy |
| **Types** | `@class`/`@alias` | `kind="type"` | Collaboration Diagram |
| **Deps** *(neu)* | IR-Nodes | `kind="require"` | Include Dependency Graph |
| **Calls** *(neu)* | einzelne **Funktionen** | `kind="call"` | Caller / Callee Graph |

### Richtung als eigene Achse (`dir`)

Für **Deps** und **Calls** ist die Richtung eine zweite Dimension, kein weiterer
View. Toolbar: `[ ← Eingehend | ⇄ Beides | Ausgehend → ]`

- `out` — was das Objekt braucht / aufruft (Callee).
- `in` — wer es braucht / aufruft (Caller) → Kanten **umgedreht** durchlaufen.
- `both` — bidirektional, zentriertes Objekt in der Mittellage, Caller darüber,
  Callee darunter (das ist der Doxygen-Look).

### Tiefe (`depth`)

Slider / `[1] [2] [3] [∞]` in der Toolbar. Default **2**. `MAX_HNODES` (90)
bleibt als harte Obergrenze bestehen — bei Require-Graphen explodiert die
Nachbarschaft deutlich schneller als bei einem Baum. Bei Abschneidung: die
bestehende `.htrunc`-Notiz, plus „+N weitere" als klickbarer Rand-Chip am
letzten Layer.

### Layout bei Zyklen

`layoutModules` ist eine BFS über einen **Baum**. Require-/Call-Graphen sind
gerichtete Graphen **mit** Zyklen. Die vorhandene BFS ist dagegen bereits robust
(`included[id] !== undefined → continue`, erster Besuch gewinnt die Ebene) —
Rückwärtskanten landen also in einer schon gefüllten Ebene und werden als
„Backedge" gezeichnet. Konsequenz für `edgePath()`: Kanten, bei denen
`to.y <= from.y`, brauchen einen seitlich ausholenden Pfad statt der aktuellen
S-Kurve, sonst laufen sie durch die Boxen. Backedges bekommen eine eigene
CSS-Klasse (`.hedge.back`) und einen Pfeilkopf.

**Pfeilköpfe generell:** Modules/Types kommen heute ohne aus. Für gerichtete
Graphen sind sie zwingend — ein `<marker>` im SVG-`<defs>`, je Kantenart
eingefärbt.

### Legende

Fixe Ecke im `#hgraph-wrap`: Kantenart → Farbe/Strichart, Box-Kind → Farbe.
Ohne Legende ist ein vierfarbiger Graph geraten statt gelesen.

---

## 5. Phase D — Funktionen als navigierbare Objekte

Voraussetzung für die Calls-View. Heute hat nur ein Node eine Id.

- **Funktions-Id:** `"<node.id>#<fn.name>"`, z.B.
  `lua/lib/nvim/docmap/init.lua#M.generate`. Stabil, ableitbar, kollisionsfrei.
- **History-State erweitern:** `{tab, id, center, view, dir, depth, fn}`.
  `serializeState`/`parseState`/`applyState` entsprechend — das ist der Ort, an
  dem alle neuen Achsen zusammenlaufen; keine davon darf an `navigate()` vorbei
  gesetzt werden (siehe README-Warnung zu `replaceState`).
- **Detail-Pane:** jede Funktion in der Functions-Section bekommt eine
  Anker-Zeile mit `Calls ↳` / `Callers ↳`, analog zum bestehenden
  `Hierarchy ↳`-Link.
- **Tree-Tab:** Modul-Zeilen bekommen aufklappbare Funktions-Kinder (Twisty wie
  bisher), damit man Funktionen auch im Baum sieht und nicht nur über die
  Detail-Ansicht erreicht.

---

## 6. Phase E — Kontextmenü (Rechtsklick)

Ein einziges Menü-Widget, gefüttert von einem `describeTarget(el)`, das aus
einem angeklickten Element ermittelt: `{ kind: "node"|"class"|"function", id }`.
Registriert auf `contextmenu` an Tree-Zeilen, Hierarchy-Boxen, Funktions-Einträgen
und Typ-Einträgen im Detail-Pane.

**Einträge (kontextabhängig gefiltert):**

```
Zeige Hierarchie          → navigate({tab:"hierarchy", view:"modules", center:id})
Zeige Abhängigkeiten  ▸   → Ausgehend (requires) / Eingehend (required by) / Beides
Zeige Aufrufe         ▸   → Aufgerufene (callees) / Aufrufer (callers) / Beides
Zeige Typen               → view:"types"
──────────
Im Tree auswählen         → navigate({tab:"tree", id})
Quelle öffnen ↗           → srcUrl(node.source) (+ #Lnnn bei Funktionen)
README öffnen             → nur wenn node.readme
──────────
Als Zentrum fixieren      → Pin, s.u.
Pfad kopieren             → navigator.clipboard
Link kopieren             → location.origin+pathname+"#"+serializeState(state)
```

**Umsetzungsdetails:**
- `preventDefault()` nur, wenn das Ziel tatsächlich ein bekanntes Objekt ist —
  sonst normales Browser-Menü. (Text markieren + kopieren muss weiter gehen.)
- Positionierung an Cursor, Clamping an den Viewport-Rand.
- Schließen bei `click`/`Escape`/`scroll`/`resize`; Pfeiltasten + Enter für
  Tastaturbedienung, `aria-role="menu"`.
- Submenüs (`▸`) als einfache verschachtelte `<ul>`, kein Framework.
- **Deaktiviert statt versteckt**, wenn das Datum fehlt: „Zeige Aufrufe (keine
  Call-Daten — mit `:LibMap full` neu generieren)". Genau wie die Types-View
  heute schon eine erklärende Message zeigt statt leer zu bleiben.

---

## 7. Phase F — Bewegung (das „smooth")

Der Kern der Anforderung — und der Grund, warum `drawHierarchy()` umgebaut
werden muss, nicht nur erweitert.

### Prinzip: FLIP mit stabiler Identität

Heute: `hgraph.innerHTML = ""` → alles neu. Stattdessen ein **keyed reconcile**:

1. Boxen werden in einer `Map<key, HTMLElement>` gehalten (`key` = Node-Id /
   Klassenname / Funktions-Id).
2. Beim Neuzeichnen: neues Layout berechnen (unverändert analytisch, siehe
   README — nichts wird aus dem DOM gemessen, das bleibt so).
3. Dann drei Mengen:
   - **enter** — neue Boxen: eingefügt mit `opacity:0; transform:scale(.92)`,
     im nächsten Frame auf Zielwert.
   - **update** — Boxen, die es vorher schon gab: nur `left/top` ändern sich,
     CSS-`transition: left .32s cubic-bezier(.2,.7,.2,1), top .32s …` erledigt
     die Bewegung. **Das ist der Doxygen-Moment**: zentriert man auf ein
     Nachbarmodul, wandern die gemeinsamen Boxen sichtbar an ihre neue Stelle,
     statt dass das Bild springt.
   - **exit** — verschwundene Boxen: auf `opacity:0` fahren, nach `transitionend`
     entfernen.
4. **Kanten:** SVG-Pfade analog gekeyed (`from|to|kind`). Da `d` nicht
   CSS-animierbar ist: `requestAnimationFrame`-Interpolation zwischen altem und
   neuem `d` über dieselbe Dauer, oder — deutlich billiger und optisch fast
   gleichwertig — Kanten während der Bewegung ausblenden und am Ende mit
   `stroke-dashoffset`-Zeichnen einblenden. **Empfehlung: Variante 2** (kein
   Pfad-Interpolator, keine Framerate-Sorgen bei 90 Boxen).

### Weitere Bewegung

- **Auto-Scroll aufs Zentrum** existiert schon → auf `scrollTo({behavior:"smooth"})`
  umstellen, aber nur wenn `prefers-reduced-motion` nicht gesetzt ist.
- **Highlight-Puls** auf der neu zentrierten Box (kurzer Outline-Flash), damit
  klar ist, worauf sich der Graph gerade bezieht.
- **Hover-Fokus:** Maus über einer Box dimmt alle Boxen/Kanten, die nicht ihre
  direkten Nachbarn sind (`.hgraph.focusing .hnode:not(.near){opacity:.28}`) —
  reines CSS über Klassen, keine Neuberechnung. Bei dichten Require-Graphen ist
  das der Unterschied zwischen lesbar und Spinnennetz.
- **`prefers-reduced-motion: reduce`** ⇒ alle Transition-Dauern auf `0s`. Ein
  einziger Media-Query-Block, kein JS-Zweig.

### Nicht-Ziel

Kein Force-Directed-Layout, keine Physik. Layered/analytisch bleibt — es ist
deterministisch, testbar und funktioniert in einem `display:none`-Pane. Bewegung
entsteht durch Interpolation *zwischen* zwei deterministischen Layouts, nicht
durch eine Simulation.

---

## 8. Phase G — Ausbau drumherum

- **Command-Erweiterung:** `:LibMap graph {deps|calls} [modul]` öffnet den
  HTML-View direkt in der passenden View/Zentrierung (Hash mitgeben). Das
  spiegelt die README-Idee eines `:LibMap functions <module>`.
- **Mermaid-Renderer** (`render/mermaid.lua`) um `graph LR` für Deps erweitern,
  damit die Abhängigkeiten auch auf GitHub in `overview.md` sichtbar sind — dort
  gibt es kein JS.
- **Export**: „Als SVG speichern" — der Graph *ist* schon SVG + HTML-Boxen;
  Boxen als `<foreignObject>` serialisieren oder Boxen optional als native
  SVG-`<rect>+<text>` zeichnen.
- **`install()`-Handle**: `handle.callers(fn_id)` / `handle.callees(fn_id)` /
  `handle.requires(id)` als Live-API — dann kann ein Plugin (oder ein
  Telescope-Picker in nvim) den Graph ohne HTML nutzen.
- **Nvim-seitiger View** (später, eigener Scope): dieselben Daten in einem
  `lib.nvim.ui.kit`-Fenster, Tastatur-Navigation statt Maus.

---

## 9. Reihenfolge & Abhängigkeiten

```
A: deps.lua (require-Kanten)          ─┐
B: calls.lua (call-Kanten)            ─┤→ C: Views Deps/Calls ─┐
D: Funktions-Ids + State-Achsen       ─┘                       ├→ F: Animation
                                        E: Kontextmenü ────────┘
                                        G: Ausbau
```

- **A ist der günstigste erste Schritt** (kleiner Diff, sofort sichtbarer
  Mehrwert, macht `check_orphans` gleichzeitig sauberer).
- **F (Animation) bewusst zuletzt** — sie ist eine Umschreibung von
  `drawHierarchy()`; sie vorher zu machen heißt, sie zweimal zu machen.
- **B ist der einzige Schritt mit echtem Forschungsrisiko** (Alias-Auflösung).
  Wenn er sich zieht: C/E/F laufen mit A allein bereits vollständig, die
  Calls-View bleibt so lange die „keine Daten"-Message.

## 10. Risiken

| Risiko | Umgang |
|---|---|
| Call-Graph rät falsch | `confidence`-Feld, Heuristik default aus, nie `error`-Severity |
| Graph-Explosion bei `depth:∞` | `MAX_HNODES` bleibt, Default-Tiefe 2, Truncation sichtbar machen |
| Determinismus bricht (`--check` wird rot) | Kanten sortiert emittieren, keine Zeitstempel, JSON weiter über `json.lua` |
| Scan-Zeit verdoppelt sich | Ein treesitter-Parse pro Datei für `functions` **und** `calls` |
| `history` erneut subtil kaputt | Neue Achsen (`dir`, `depth`, `fn`) **nur** über `navigate()`; Live-Preview weiterhin ohne `replaceState` |
| Zyklen zerlegen das Layer-Layout | Backedge-Erkennung + eigener Pfad + eigene CSS-Klasse |
