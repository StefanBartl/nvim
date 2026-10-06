`:Case clipboard [options?]` und als options sowas wie casenumber, titel, summary, usw... alles was es dieshzeüglich den case aktuellen gibt, man kann aber auch einen case number explizit angeebn, mit case number oder wie in anderen usrcmds auhc title suw... Die idee ist, alles was man sinnvoll in die clipboard kopieren kann, an einer stelle zu haben vie usrcmd


spotlight: eine möglichlkeit, wie ich in casedesk.nvim mit spotlight verbinde, also markiereungen werden sozusagen persistent pro case gesetzt, die ide ist dann, ine inen case sagen z können "dies emakrierungen ghaebi chin cased x gesetz, diese incase y usw..."

---

## Task: spotlight.nvim ↔ mdview.nvim — Spotlight-Markierungen im Browser spiegeln

**Ziel:** Die Spotlights, die in Neovim aktiv sind, sollen in der von mdview.nvim gerenderten Vorschau im Browser ebenfalls hervorgehoben sein, in derselben Farbe und mit Live-Update.

**Motivation:** Wer Logs oder Analysen als Markdown schreibt (z. B. eine Log-Analyse mit Code-Blöcken voller `SYSsystosca`, `400 (Bad Request)`), markiert in Neovim Tokens. Im Browser-Preview, das man teilt oder gegenliest, fehlen diese Markierungen.

### Anforderungen

1. **Datenquelle:** spotlight.nvim stellt eine Lese-API bereit, z. B. `require("spotlight").spotlights()` mit `{ text, slot, hl_group, line_mode, origin }`. Das Facade existiert vermutlich schon, das muss geprüft werden. Falls nicht, wird eine stabile, dokumentierte Funktion ergänzt.
2. **Änderungs-Event:** Bei jedem Toggle, Clear, Set-Switch oder Restore sendet spotlight.nvim ein `User`-Autocmd (z. B. `SpotlightChanged`). mdview.nvim hört darauf und schickt den neuen Zustand an den Browser (Debounce einplanen).
3. **Transport:** Der Zustand geht über den bestehenden Kanal von mdview.nvim zum Browser (WebSocket/SSE, je nach Implementierung) als JSON, etwa `{ type: "spotlight", items: [{ text, slot, line }] }`.
4. **Rendering im Browser:**
   - Wörtliche, **case-sensitive** Textsuche im gerenderten DOM (Text-Knoten, inklusive `<code>`/`<pre>`), um Spotlight-Semantik (`\C`) zu erhalten.
   - Treffer in `<mark class="spotlight spotlight-N">` einhüllen (oder CSS Custom Highlight API, falls verfügbar, damit das DOM unverändert bleibt).
   - Farben: die 8 Slots von spotlight.nvim als CSS-Variablen, abgeleitet aus den Highlight-Gruppen `Spotlight1..8` (inklusive Colorscheme-Wechsel).
   - `line_mode`: ganze Zeile bzw. ganzen Block hervorheben.
5. **Nach jedem Re-Render erneut anwenden**, da mdview.nvim bei Pufferänderungen neu rendert.
6. **Einschränkungen:** Nur ganz-Datei-Spotlights (`toggle`), nicht "diese Stelle" (`toggle_here`), da die Position im Browser keine Entsprechung hat.

### Offene Fragen

- Welchen Transportkanal nutzt mdview.nvim heute, und lässt sich ein weiterer Nachrichtentyp einfach einhängen?
- Persistenz: Soll das Browser-Highlight dem Spotlight-Persist-Status folgen (z. B. keine Kundendaten, wenn `persist off` für die Datei gilt)? Vorschlag: Browser-Spiegelung ist unabhängig von Persistenz, aber eine Option `mdview.mirror = false` verhindert das Senden.
- Wörter vs. Teilstrings: Spotlights ohne Wortgrenzen (Visual-Auswahl) treffen auch Teilstrings, das Verhalten im Browser muss identisch sein.
- Performance bei großen Dokumenten (Obergrenze für Treffer pro Spotlight, wie `map.max_entries`).

### Abnahmekriterien

- Token in Neovim markieren → Treffer erscheinen im Browser innerhalb ~1 s in derselben Farbe.
- Entfernen, `clear` und `sets switch` aktualisieren die Ansicht.
- Colorscheme-Wechsel aktualisiert die Farben.
- Option zum Abschalten, Hinweis in beiden READMEs, Tests auf beiden Seiten (Lua-Spec für das Event, Browser-seitig für das Highlighting).

---

