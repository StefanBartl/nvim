# `documentation.nvim`

## Long term (AN CLAUDE: NOCH NICHT IMPLEMENTIEREN: EINFACH IGNORIEREN!)

- [ ] Eine Desktop/Webapp-Version, in der auf dieses Konzept aufgesetzt wird,
  aber alles verfeinert wird, auch mit Profiler und besserer View/UI/Feature-
  Ausstattung.
- [ ] Root-Level Slider auch frü andere views als hirarchie intereesant?

---

## Taskliste — sortiert nach Aufwand, Quick Wins zuerst

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

    > Feedback: Es geht mir darum, dass wir zb. einen deps tab haben mit dependecys so haben wir auch einen tab für runtime anaylse.nvim feature(s) als auch für vl andere; diese soll en dann idealweriße in der tab design ein wenig hervorstehcen, weil es ja azch tabs /submenus sind, die nur sichtbar sind, wenn auch diese plugins isntalliert sind

### Mittel

### Hoch / größere Vorhaben

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
