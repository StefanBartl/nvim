# `documentation.nvim`

## Long term (AN CLAUDE: NOCH NICHT IMPLEMENTIEREN: EINFACH IGNORIEREN!)

- Eine Desktop/Webapp-Version, in der auf dieses Konzept aufgesetzt wird,
  aber alles verfeinert wird, auch mit Profiler und besserer View/UI/Feature-
  Ausstattung.

---

## Taskliste — sortiert nach Aufwand, Quick Wins zuerst

Innerhalb einer Aufwandsstufe nach Nutzen absteigend sortiert.

### Quick Wins

- [x] **`@type`-vs-`@class`-Befund als Lint-Regel** — erledigt 2026-08-10:
      neuer Check `type-vs-class` (`warn`) in `core/check.lua`, liest den
      bereits vorhandenen Header-Scan (`scan.parse_header`), feuert nur,
      wenn dem Modul-Table tatsächlich Felder zugewiesen wurden. Eigene
      Testdatei `TESTS/check_type_vs_class_spec.lua`, in
      `docs/PIPELINE.md`, `README.md`, `doc/documentation.txt` und
      `docs/MULTILANG.md`s Check-Zählung dokumentiert. Commit `c2bec69`.

- [x] **Workflow-/Usecase-Doku für documentation.nvim selbst** — erledigt
      2026-08-10: neues `docs/WORKFLOW.md`, in README verlinkt. Konkret:
      Hierarchy-vs-Analysis, Churn+Impact vor Refactors, die
      Telemetry-Join-Badge-Tabelle (✕/!/○/blank) inkl. der Falle, die sie
      verhindert, Trail als Session-Tool vs. benannte gespeicherte Trails,
      `f` vs. `/` vs. `tag_files` über Repos hinweg. Commit `a4d8417`.

- [x] **Erweiterte Annotationen: `@see`, `@generic`, `@deprecated`** —
      geprüft 2026-08-10: alle drei sind bereits vollständig implementiert,
      nicht nur geparst. `@see` wird gegen den echten Modul-/Funktionsindex
      validiert (`dead-see-target`-Check, `check_see_targets`) und im
      Browser als klickbarer Link gerendert. `@deprecated` hat eine eigene
      Badge, einen eigenen Analysis-Index-Eintrag und wird im
      Annotation-Popup mit dem Migrationshinweis angezeigt. `@generic`
      wird geparst und in die Funktionssignatur übernommen. Die
      eigentlich offene Idee dahinter — `@see`-Verlinkung automatisch
      *generieren* lassen statt von Hand zu pflegen — ist ein anderes,
      deutlich größeres Feature (Ähnlichkeits-/Bezugs-Heuristik zwischen
      Funktionen) und kein Quick Win; nicht umgesetzt, aber als bewusst
      unterschiedene, offene Idee hier festgehalten.

- [ ] **Sichtbare Kennzeichnung von Fremd-Plugin-Modi** (Aufwand-Neubewertung
      2026-08-10: **nicht Quick Win** — Mittel, da neue UI-Infrastruktur
      nötig · Nutzen: niedrig-mittel)
      Geprüft: die Prämisse "Tabs" trifft die aktuelle Architektur nicht.
      Telemetry/Loaded sind **`:DocBrowse`-Modi** (Terminal-Float, `1`–`9`
      im Mode-Switcher), keine HTML-Tabs der generierten Seite — dort
      existieren aktuell überhaupt keine Fremd-Plugin-Tabs. Die
      Statuszeile, die `[telemetry]`/`[loaded]` anzeigt
      (`browse/view.lua`), ist reiner Text ohne jede
      Highlight-/Extmark-Infrastruktur — eine visuelle Abhebung bräuchte
      erst ein neues Highlighting-Konzept für die Statuszeile, kein
      CSS-Detail. Zurückgestellt zu Mittel, bis sich das lohnt.

- [x] **README-Hinweis auf die generierte Map, pro Plugin** — erledigt
      2026-08-10, Prämisse dabei korrigiert: die Annahme "Nutzen: niedrig,
      solange Pages fehlt" galt nur für `index.html` (echtes HTML, GitHub
      rendert das als Quelltext, nicht als Seite). `docs/map/overview.md`
      dagegen rendert schon heute direkt im GitHub-Repo-View — kein Pages
      nötig, kein Warten auf `publish_map.sh`. Konvention jetzt in
      `documentation.nvim`s `docs/REUSE.md` ("Linking to your own map from
      your README") dokumentiert und in beiden aktiven Repos umgesetzt:
      documentation.nvim ([`da4b351`](https://github.com/StefanBartl/documentation.nvim/commit/da4b351))
      und runtime-analysis.nvim ([`e5768b4`](https://github.com/StefanBartl/runtime-analysis.nvim/commit/e5768b4))
      verlinken jeweils ihre eigene `overview.md`. Auf die übrigen ~30
      Repos noch nicht ausgerollt — die Konvention steht jetzt, das
      Nachziehen pro Repo ist mechanisch und kein eigener Punkt hier wert.

- [x] **Persistente Laufzeitdaten eines Plugins einsehbar machen — Triage,
      nicht Umsetzung hier** — erledigt 2026-08-10: als Kandidat in
      `runtime-analysis.nvim`s eigenes `docs/IDEAS.md` §3.2 (Runtime-Tab)
      verschoben, mit Notiz, dass ein eigener Tab dafür trotzdem hier
      denkbar bleibt, sobald der Runtime-Tab existiert.

### Mittel

- [x] **`:DocMap annotate` — Modul-Header generieren statt nur
      bemängeln** — erledigt 2026-08-10, Prämisse an einer Stelle
      korrigiert: `@brief`/`@desc` sind laut `docs/ANNOTATION_TAGS.md`
      selbst nur ein Fallback ("prefer plain prose"), also generiert der
      Header stattdessen eine `TODO`-Prosa-Zeile, keine erfundenen Tags.
      `@field`-Referenzierung eines bereits vorhandenen `@class`-Blocks
      funktioniert wie gedacht (`---@field rate_limits t.x.RateLimits`
      statt `table`), ebenso `fun(...)`-Rekonstruktion aus bereits
      geparsten `@param`/`@return` für Funktionsfelder. Neu:
      `core/annotate.lua` (Kernlogik), `bindings/usrcmds/annotate.lua`
      (`:DocMap annotate [--write|--sidecar]`, Default reine Vorschau in
      einem Scratch-Buffer, nichts wird ungefragt geschrieben), Tests mit
      echten Fixture-Dateien (`TESTS/annotate_spec.lua`), Doku in
      `docs/COMMANDS.md`/README/vimdoc. Commit
      [`67fd074`](https://github.com/StefanBartl/documentation.nvim/commit/67fd074),
      CI grün.

- [x] **Hierarchie-Ansicht: einzelne Module ein-/ausblenden** — erledigt
      2026-08-10: Rechtsklick auf eine Hierarchie-Box → "Dim this box" /
      "Show this box", dazu eine "Hidden (N) — show all"-Pille in der
      Toolbar, die alle auf einmal wieder einblendet. Bewusst nur
      Abdunkeln (`opacity:.08` + `pointer-events:none`, dasselbe
      Mechanismus wie der bestehende Hover-Fokus, nur persistent und pro
      Box statt transient), kein echtes Entfernen aus dem Layout — ein
      entfernter Knoten müsste seine Kinder reparentieren oder eine Lücke
      lassen, unnötige Komplexität für das eigentliche Ziel ("großen Baum
      weniger unübersichtlich machen"). Die strukturelle Variante bleibt
      bewusst der separate, größere Punkt weiter unten (Root-Level
      aus-/einblenden mit Zoom-Slider). State-Design 1:1 von den
      bestehenden Compare-Marks übernommen (`state.hidden`, eigener
      `localStorage`-Key, Hash gewinnt beim Laden gegen `localStorage`),
      aber Hierarchy-scoped statt global. Reiner Client-JS-Change in
      `core/render/html.lua`, keine IR-/Pipeline-Änderung. Verifiziert im
      echten Browser gegen das generierte `docs/map/index.html`. Commit
      [`41db728`](https://github.com/StefanBartl/documentation.nvim/commit/41db728).

### Hoch / größere Vorhaben

- [x] **FEATURES-/BINDINGS-Ordner-Konvention + eigener Tab** — erledigt
      2026-08-10. Vorab geprüft statt angenommen: eine Bestandsaufnahme
      über ~30 eigene Repos zeigte, dass `docs/BINDINGS.md` bereits
      durchgängig konsistent ist (documentation.nvims eigener Generator),
      "FEATURES" aber tatsächlich drei unabhängig entstandene,
      inkompatible Formen hatte (lib.nvim: Essay-Write-ups; markdown.nvim:
      kompakte Pro-Feature-Metadatenblöcke; color_my_ascii.nvim: volle
      User-Manuals) — keine der drei war die im Punkt angenommene
      thematische `UI.md`/`PERFORMANCE.md`-Aufteilung. Format- und
      Speicherort-Entscheidung dem Nutzer vorgelegt (kompakt-strukturiert
      nach markdown.nvim-Vorbild, `docs/FEATURES/`-Ordner thematisch
      aufgeteilt), bevor Parser/Tab gebaut wurden — genau die im Punkt
      selbst geforderte Reihenfolge. Neu: `core/features.lua` (Parser,
      gegen markdown.nvims echte `docs/FEATURES/headings.md` verifiziert —
      ein mehrzeilig umgebrochenes Bullet-Value deckte einen echten
      Parser-Bug auf, keinen synthetischen), `ir.features`, ein neunter
      Tab in `core/render/html.lua`, `docs/FEATURES_FORMAT.md` (die
      Spezifikation selbst — kein festes Metadaten-Vokabular, da
      markdown.nvims eigene Datei bereits bekannte und Ad-hoc-Keys mischt).
      Dogfooding: documentation.nvims eigenes `docs/FEATURES/` (4 echte
      Einträge), Ende-zu-Ende im echten Browser verifiziert.
      Cross-Linking zu Bindings über normale Markdown-Links in den
      Metadata-Bullets (`Keymaps:`/`Usercmds:` → `../BINDINGS.md#...`),
      keine Pro-Zeile-Anchors — GitHub-Markdown ankert nur Überschriften,
      nicht Tabellenzeilen. Bewusst nicht umgesetzt, wie im Punkt selbst
      als spekulativ markiert: eigener Leitlinien-Tab, Hover-Icon
      "welches Feature nutzt diesen Code". Die Fremd-Plugin-Tab-Markierung
      selbst bleibt weiterhin zurückgestellt (siehe Quick-Win-Punkt oben)
      — es existiert nach wie vor kein Fremd-Plugin-Tab in der generierten
      Seite, den man markieren könnte; documentation.nvims eigenes
      `docs/FEATURES/` ist kein Fremd-Plugin-Inhalt, sondern der
      analysierte Repo selbst.
      **Nebenbei gefunden und behoben, betrifft auch den `:DocMap
      tools`-Punkt oben:** `core/render/html.lua`s `M.render` baut das in
      die Seite eingebettete IR-JSON unabhängig von
      `documentation.to_json` (`module_map.json`s Writer) — ein
      Kommentar-Thread genau in dieser Funktion dokumentierte das bereits,
      zweimal zuvor an `duplicates`/`docs` passiert. `ir.tools` und
      `ir.features` waren im gescannten IR und in `module_map.json`
      vorhanden, fehlten aber in der Seite selbst — das Tools-Analysis-Panel
      zeigte seit dem Ship "kein Manifest gefunden" unabhängig davon, ob
      eines existierte. Beim Prüfen von `module_map.json`s tatsächlichen
      Keys gegen ein echtes Repo aufgefallen, nicht beim bloßen Vertrauen
      auf `scan_full`. Commit
      [`3eeb6a8`](https://github.com/StefanBartl/documentation.nvim/commit/3eeb6a8).

- [ ] **Leitlinien-Tab (Architektur-/Prinzipien-Dokumente)** (Aufwand: Mittel
      — dieselbe Infrastruktur wie der Features-Tab, nur mit anderem
      Quellordner · Nutzen: mittel, projektspezifisch)
      Aus dem ursprünglichen FEATURES-Punkt herausgelöst, wo es nur als
      "denkbare Erweiterung derselben Infrastruktur" erwähnt, aber nie als
      eigene Aufgabe festgehalten war. Ein eigener Tab, der
      Architektur-/Design-Leitliniendokumente einliest — nicht "was macht
      das Plugin" (das ist der Features-Tab), sondern "wie/warum ist es so
      gebaut". Für dieses Repo z. B. genau die Dokumente unter
      `docs/ROADMAP/{ARCH_AND_CODING,Zentral-Prinzipien}.md`, wie sie
      mehrere eigene Plugins bereits führen (siehe `All/Checklists.md`).
      Technisch dieselbe Parser-/Tab-Infrastruktur wie `core/features.lua`/
      der Features-Tab, nur auf einen anderen Quellordner (z. B.
      `docs/PRINCIPLES/`) angewendet — `docs/FEATURES_FORMAT.md`s Schema
      ist wahrscheinlich unverändert wiederverwendbar. Aufwand entsprechend
      niedriger als beim ursprünglichen FEATURES-Punkt, da Format- und
      Parser-Fragen bereits beantwortet sind.

- [ ] **Einzelnes Feature bekommt eigenen Tab statt nur Karte im
      Features-Tab** (Aufwand: Mittel — eine Aufwertungsregel plus
      dynamisches Tab-Registrieren · Nutzen: niedrig-mittel, für sehr
      wenige, besonders wichtige Features gedacht)
      Ursprüngliche Idee aus dem FEATURES-Punkt, dort bewusst nicht
      umgesetzt: wenn eine `docs/FEATURES/`-Datei ein Feature besonders
      ausführlich beschreibt ("bewirbt"), bekommt genau dieses Feature
      einen eigenen Tab statt nur einen Eintrag in der Features-Liste. Der
      gebaute Features-Tab ist bewusst ein einheitlicher Katalog (alle
      Features gleich behandelt, kein Promotion-Mechanismus) — diese Idee
      bräuchte eine explizite Markierung im Format (z. B. ein
      `- **Tab:** true`-Bullet) und dynamisches Tab-Registrieren in
      `core/render/html.lua`, was heute nirgends existiert (die neun Tabs
      sind aktuell alle statisch im Markup). Erst sinnvoll zu bewerten,
      wenn `docs/FEATURES/` in echten Repos genutzt wird und sich zeigt,
      ob der Bedarf real ist.

- [ ] **Externe Calls/Plugins gezielt sichtbar machen** (Aufwand: Hoch —
      Call-Site-zu-externem-Symbol-Auflösung + GitHub-Fetch-Integration ·
      Nutzen: hoch — „warum ist diese Dependency überhaupt drin" auf
      einen Blick)
      In der Dependency-Ansicht einen Unterpunkt, der zeigt, *welche*
      Funktionen aus einer externen Dependency tatsächlich aufgerufen
      werden — nicht nur „plenary ist eingebunden", sondern "wegen
      `plenary.async.run` (2×) und `plenary.job.new` (1×)". Da der externe
      Source lokal nicht vorliegt: bei Klick auf ein Icon den Code von
      GitHub nachladen und anzeigen, oder direkt auf die passende
      GitHub-Seite weiterleiten.

- [ ] **Gewichtete Alternativ-Ansicht des Call-Graphen, eigener Tab**
      (Aufwand: Hoch — neue Rendering-Logik ohne externe Graph-Bibliothek
      · Nutzen: hoch — echtes Analysewerkzeug, kein Spielerei-Feature)
      Wie die Hierarchie, aber mit wählbaren Datenfiltern auf der
      Modul-Ansicht: z. B. welche Calls macht dieses Modul — alle
      Module, die diese Calls empfangen, werden ringsherum eingeblendet
      und mit gewichteten Pfeilen verbunden (mehr Calls = dickerer
      Strich). Mehrere Varianten denkbar, verdient einen eigenen Tab statt
      eine Erweiterung des bestehenden Hierarchy-Tabs.

- [ ] **Hierarchie: Root-Level aus-/einblenden mit Zoom-Slider**
      (Aufwand: Hoch — neues UI-Widget + Re-Rooting-Logik im bestehenden
      Renderer · Nutzen: mittel — Navigationshilfe bei sehr tiefen Bäumen)
      Root-Level ausblenden können, sodass Level-2-Ordner als neue
      Root-Ebene erscheinen — als Idee mit einem seitlichen, vertikalen
      Maßstab-Slider (wie der Zoom-Regler bei Google Maps, `+` oben,
      `-` unten).

- [ ] **LuaLS' fehlendes „in/outgoing calls"-Feature mitbedienen**
      (Aufwand: Hoch — unklar, ob/wie LuaLS überhaupt eine passende
      Erweiterungsschnittstelle anbietet · Nutzen: spekulativ, potenziell
      hoch)
      Prüfen, ob documentation.nvims eigene, bereits vorhandene
      Call-Graph-Daten genutzt werden könnten, um LuaLS' fehlendes
      Incoming/Outgoing-Calls-Feature zu ergänzen (z. B. über CodeLens
      oder Hover). Erster Schritt wäre reine Recherche: gibt es dafür
      überhaupt einen sinnvollen Erweiterungspunkt in LuaLS oder im LSP
      selbst.

- [ ] **Eigene Findings als `vim.diagnostic` statt nur Quickfix** (Aufwand:
      unklar, erst Recherche nötig · Nutzen: spekulativ, potenziell hoch)
      Die "Linting/LSP-Diagnostic"-Hälfte des allerersten, ganz frühen
      "Generell"-Punktes zu diesem Repo — bisher nirgends als eigene
      Aufgabe festgehalten, verwandt mit dem LuaLS-in/outgoing-calls-Punkt
      oben, aber eigenständig. Könnten documentation.nvims eigene, bereits
      berechnete Daten — Drift-Findings (`check.lua`), der Call-/
      Require-Graph, Coverage — nicht nur als |quickfix| dienen, sondern
      direkt als native `vim.diagnostic`-Einträge im Buffer erscheinen
      (z. B. `missing-summary`/`dead-see-target` als echte Diagnostic statt
      nur im `:DocMap check`-Quickfix)? Erster Schritt auch hier reine
      Recherche: wo würde ein `vim.diagnostic.set()`-Aufruf aus den
      bestehenden `Documentation.Finding[]`-Daten am saubersten sitzen —
      vermutlich ein neuer, optionaler Baustein in `bindings/`, nicht
      `core/`, damit die Kernregel "Pipeline läuft ohne Editor" (siehe
      `docs/PORTABILITY.md`) nicht verletzt wird.

### Fragwürdig — eher nicht umsetzen

- [ ] **Compiler-Explorer-(godbolt.org)-Tab** (Aufwand: Mittel — iframe/
      Link-Einbindung ist technisch nicht schwer · Nutzen: sehr niedrig,
      Prämisse fraglich)
      Idee war ein Tab, der den Projekt-Source in godbolt.org lädt, mit
      einem Icon an Modulen/Funktionen/Tables, das ein Popup mit dem dort
      geladenen Code öffnet. Compiler Explorer ist für **kompilierte**
      Sprachen gedacht — sein Wert liegt im Vergleich von Quelltext gegen
      erzeugten Assembler-Code. Für Lua (interpretiert, kein
      Assembler-Output, den man sinnvoll inspizieren würde) fehlt der
      eigentliche Nutzen der Seite fast komplett. Nur wieder aufgreifen,
      falls sich ein konkreter, anderer Anwendungsfall für die Integration
      findet, der nicht auf „Assembler ansehen" beruht.
