# `documentation.nvim`

## Long term (AN CLAUDE: NOCH NICHT IMPLEMENTIEREN: EINFACH IGNORIEREN!)

- Eine Desktop/Webapp-Version, in der auf dieses Konzept aufgesetzt wird,
  aber alles verfeinert wird, auch mit Profiler und besserer View/UI/Feature-
  Ausstattung.

---

## Taskliste — sortiert nach Aufwand, Quick Wins zuerst

Innerhalb einer Aufwandsstufe nach Nutzen absteigend sortiert. Erledigte
Punkte werden ersatzlos entfernt, sobald sie umgesetzt sind — der
Entscheidungsrecord lebt in `documentation.nvim`s eigenem
`docs/ROADMAP/FEATURES.md`, echte Features zusätzlich in dessen
`docs/FEATURES/`.

### Quick Wins

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

### Mittel

### Hoch / größere Vorhaben

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
