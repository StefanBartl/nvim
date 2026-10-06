`:Case clipboard [options?]` und als options sowas wie casenumber, titel, summary, usw... alles was es dieshzeüglich den case aktuellen gibt, man kann aber auch einen case number explizit angeebn, mit case number oder wie in anderen usrcmds auhc title suw... Die idee ist, alles was man sinnvoll in die clipboard kopieren kann, an einer stelle zu haben vie usrcmd

> **Status 2026-10-06: umgesetzt** in casedesk.nvim (`1394d3a`, BOM-Fix `4958979`, Docs `373487d`).
> `:Case clipboard [was] [case] [--labels|-l] [--sep=...]`: Felder `number`, `header`, `title`,
> `oneline`, `subject`, `snow`, `link`, `path`, `status`, `area`, alle Sidecar-Felder
> (`company`, `name`, `notes`, `priority`, `tosca_version`, `outcome`, `routed_to`), `server`,
> `component`, `tags`, `links`, `summary`, `solution`, `all`; mehrere Felder per Komma oder
> Leerzeichen; Case wie bei den anderen Cmds (Nummer, `AREA/Nummer`, `.`, volle SNOW-ID, sonst
> Case des Puffers bzw. Picker). Ohne Argument eine Mehrfachauswahl. Nur lokale Zwischenablage.
> Beleg: `wkdbook-myplugins/casedesk.nvim/FEATURES.md`. Offen: Tab-Completion ab dem dritten Token
> (`casedesk.nvim/clipboard-variadic-completion`, geparkt), echter TUI-Durchlauf
> (`casedesk.nvim/clipboard-spotlight-live-check`).


spotlight: eine möglichlkeit, wie ich in casedesk.nvim mit spotlight verbinde, also markiereungen werden sozusagen persistent pro case gesetzt, die ide ist dann, ine inen case sagen z können "dies emakrierungen ghaebi chin cased x gesetz, diese incase y usw..."

> **Status 2026-10-06: umgesetzt** in casedesk.nvim (`529d4cb`, Review-Fixes `d54fe22`, Docs `bc0e125`)
> mit einer kleinen Erweiterung in spotlight.nvim (`export()`/`import(items)`, `74680c9`, Docs `3901bdd`).
> Die Markierungen eines Cases liegen als `.spotlight.json` im Case-Ordner; `:Case spotlight
> save|load|clear|show [nr]` und `:Case spotlight list`. Die aktiven Spotlights folgen dem Case
> (beim Wechsel wird der alte gesichert, der neue exklusiv geladen); freie Markierungen werden nie
> von selbst ersetzt. Config `spotlight = { enabled, follow, filename, debounce_ms }`, Abschnitt in
> `:checkhealth`. Beleg: `wkdbook-myplugins/casedesk.nvim/FEATURES.md`.
> **Entscheidung offen (Task `casedesk.nvim/spotlight-per-case-gitignore-and-follow-default`):**
> `.spotlight.json` in die `.gitignore` von WKDBook-Tricentis (kann Kundendaten enthalten) und ob
> `follow = true` Default bleibt. Weitere Randpunkte: `casedesk.nvim/spotlight-per-case-open-edges`.

---

## Task: spotlight.nvim ↔ mdview.nvim — Spotlight-Markierungen im Browser spiegeln

> **Status 2026-10-06: umgesetzt, alle Abnahmekriterien im Browser-Pane einmal skriptgesteuert
> belegt; offen ist ein Release des Relays und ein menschlicher Dauerbetrieb-Test.**
> - spotlight.nvim (`2b5ad9a`, Fix `76ac11b`, Docs `ba09f51`): Lese-API `spotlights({whole_file})` mit
>   `hl_group`, `line_mode`, `whole_file`, `scope`, `kind`, `ignore_case`; `colors()` aus den echten
>   Gruppen `Spotlight1..8`; gebuendeltes `User SpotlightChanged` (Payload `reasons`, `count`,
>   `whole_file_count`, `whole_file_changed`; Set-Switch = ein Event).
> - mdview.nvim (`83c2086` Relay-Route `POST /spotlight`, `e648f35` Browser-Rendering, `3dfd41a`
>   Lua-Seite, Docs `fc2267f`; spotlight-Seite `76bf333`): Transport ueber die neue Relay-Route statt
>   `/control` (1 KiB, kein Seeding); CSS Custom Highlight API mit `<mark>`-Fallback; Farben als
>   CSS-Variablen; Re-Apply nach jedem Re-Render; Trefferobergrenze `browser.spotlight_max_matches`
>   (500); Abschalter `browser.spotlight_sync` und `:MDView spotlight [on|off|toggle]`; nur
>   Ganz-Datei-Spotlights.
> - Antworten auf die offenen Fragen: Transport = neue Relay-Route; Persistenz = Spiegelung ist
>   unabhaengig von `persist off`, abschaltbar per Option (Default an, in den Docs benannt);
>   Substring vs. Wort = `kind` wird mitgesendet; Performance = Cap pro Spotlight.
> - Beleg: `wkdbook-myplugins/mdview.nvim/FEATURES.md` und `spotlight.nvim/FEATURES.md`.
> - **Offen:** Release des Relays (`mdview.nvim/release-relay-spotlight-route`; bis dahin
>   `dev.binary_path` + `dev.web_root`), Live-Judgement (`mdview.nvim/spotlight-mirror-live-check`),
>   Hardening (`mdview.nvim/spotlight-mirror-hardening`), Kanten der API
>   (`spotlight.nvim/read-api-kind-and-event-edges`).

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

