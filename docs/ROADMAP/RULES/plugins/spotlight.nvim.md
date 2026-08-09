# spotlight.nvim

## Zweck
Highlightet beliebig viele Tokens (Request-IDs, PIDs, IPs, Fehlercodes) in Log-Dateien mit
bis zu acht unterscheidbaren Farben, über alle Fenster hinweg, persistent pro Git-Projekt
mit Datei-basiertem Opt-out. Baut bewusst auf `matchadd()` statt Extmarks, um auch auf
sehr großen Dateien (200 MB Logs) performant zu bleiben.

## Nicht-standard Patterns / Algorithmen

- `lua/spotlight/core/match.lua:1-24` und README.md "Why matchadd and not extmarks" — die
  zentrale Architekturentscheidung des Plugins: Extmarks speichern Positionen (O(Dateigröße)
  bei jedem Add und jeder Textänderung), `matchadd()` speichert nur das Pattern und lässt
  Vims C-Renderer nur die sichtbaren Zeilen auswerten (O(Fenstergröße)). Der Preis: Matches
  sind fensterlokal, deshalb führt `match.lua` ein Ledger `window -> {spotlight id -> match
  id}` (Zeile 30-32), um über drei Fenster-Autocmds hinweg den Eindruck von
  Session-Globalität zu erzeugen. Direkte Konsequenz: Match-Counts werden nur on-demand beim
  Öffnen der Liste berechnet (`core/count.lua`), nie live mitgeführt — sonst wäre genau der
  vermiedene Scan wieder da.
- `lua/spotlight/core/match.lua:34-53` (`eligible`) — Floating-Fenster werden bewusst
  übersprungen (eigene UI wie die Spotlight-Liste selbst, Completion-Popups), weil ein
  Highlight dort nichts überlebt und beim Schließen aufgeräumt werden müsste; Quickfix-Fenster
  bleiben dagegen bewusst eligible, weil dort die Farben der ganze Sinn von `:Spotlight qf`
  sind.
- `lua/spotlight/core/pattern.lua:19-43` — jedes an Vim übergebene Pattern wird als `\C\V` +
  escaped literal gebaut: `\V` (very nomagic) reduziert Sonderzeichen auf ein einziges
  (Backslash), wodurch Escaping eine einzige `gsub`-Substitution ist statt einer
  Zeichenklasse, die mit Vims Magic-Regeln synchron gehalten werden müsste. `\C` statt `\c`
  wird fest eingebrannt, damit ein Spotlight seine Bedeutung nicht ändert, wenn der Nutzer
  `'ignorecase'`/`'smartcase'` umschaltet. Wortgrenzen (`\<...\>`) werden nur für
  `word`-Token-Kind gesetzt — ein strukturiertes Token wie eine IP bekäme sonst NIE einen
  Treffer, weil `\<` einen Wortanfang voraussetzt und `.` kein Wortzeichen ist
  (Zeile 28-43). Explizit als Security-relevant dokumentiert: da nur `\V` + literal escaping
  verwendet wird, keine Quantifier/Gruppen/Alternation innerhalb eines Branches, kann kein
  Input pathologisches Backtracking auslösen (README.md "Security model").
- `lua/spotlight/core/palette.lua:60-88` (`next_slot`) — Farbvergabe ist Round-Robin, aber
  überspringt belegte Slots solange noch ein freier existiert (statt naives Round-Robin, das
  eine bereits sichtbare Farbe erneut vergeben könnte, während drei andere frei sind). Erst
  wenn alle Slots belegt sind, wird Wiederverwendung in Kauf genommen.
- `lua/spotlight/core/palette.lua:98-108` (`clamp`) — ein aus einem Snapshot restaurierter
  Palette-Slot wird per Modulo in den gültigen Bereich der AKTUELLEN Palettengröße geklemmt,
  weil eine alte Persistenz-Datei einen größeren Paletten-Index enthalten haben könnte, als
  die aktuell konfigurierte Palette bietet.
- `lua/spotlight/persist.lua:11-36` — das Persistenz-Exception-Modell trifft bewusst eine
  von zwei möglichen, nicht offensichtlichen Semantik-Entscheidungen: eine Datei-Exception
  unterdrückt NICHT "Spotlights, die in dieser Datei *vorkommen*" (nicht implementierbar
  ohne projektweiten O(alles)-Scan bei jedem Save), sondern "Spotlights, die *erstellt
  wurden, während* diese Datei aktiv war" (jedes Spotlight speichert einmalig seinen
  `origin`). Ein in `worker.log` erstelltes Spotlight bleibt persistiert, selbst wenn
  derselbe String auch in einem ausgeschlossenen `secrets.log` vorkommt.
- `lua/spotlight/persist.lua:106-126` (`save_now`) — bei leerem Snapshot (nichts zu
  behalten UND keine Exceptions) wird die Store-Datei aktiv gelöscht statt eine leere Liste
  zu schreiben, damit eine spätere Session nicht versehentlich eine leere Liste über
  zwischenzeitlich neu erstellte Spotlights restauriert.
- `lua/spotlight/persist.lua:180-192` (`load`) — beim Laden wird der Snapshot ERNEUT gegen
  `persist.default` gefiltert (nicht nur beim Save), weil der Nutzer die Konfiguration
  zwischen Save und einem späteren Load geändert haben könnte — die aktuelle Einstellung
  soll entscheiden, nicht die Einstellung zum Speicherzeitpunkt.
- README.md "Security model" (Zeile 508-553) — dediziertes Security-Modell-Kapitel mit
  konkreten Bounded-Input-Guards: `match.max_text_len` (512, gegen `v$` auf einer minified
  Zeile), `cursor.max_line_len` (8192, Resolver-Scan ist O(Zeile) pro Pattern und
  nutzerdefinierte Lua-Patterns könnten backtracken), `quickfix.max_entries` (10000, weil
  Filtern im Gegensatz zu Zählen tatsächlich Speicher alloziert — pro Treffer eine ganze
  Zeile). Snapshot-Daten werden beim Laden vollständig re-validiert (Typ, Länge, Dedup,
  Count-Cap, Paletten-Slot-Clamp) — das Regex wird IMMER aus `text` neu gebaut, nie aus der
  Datei gelesen, damit ein manipulierter Snapshot kein Pattern injizieren kann.
- `lua/spotlight/util/path.lua` (laut README.md Zeile 593-596) — Pfad-Keys werden auf
  Forward-Slashes normalisiert und unter Windows case-insensitive verglichen, weil
  `C:\Repos\x` und `c:\repos\x` sonst zwei unterschiedliche Exception-Keys ergäben.

## Abgeleitete Guidelines

1. Bei potenziell riesigen Dateien/Puffern: Kostenmodell zuerst festlegen (O(Fenster) vs.
   O(Datei)) und die Primitive danach wählen — `matchadd()` statt Extmarks ist ein
   konkretes Beispiel für "Rendering-API nutzen, die nur das Sichtbare kostet".
2. Wenn eine "billige" Primitive (fensterlokale Matches) global wirken soll, das
   Ledger/Bookkeeping als eigenes, kleines Modul auslagern statt es in die
   Kernlogik zu verweben — macht die Kosten-Nutzen-Abwägung explizit sichtbar und testbar.
3. Jedes an eine Regex-Engine übergebene, aus Nutzereingabe gebaute Pattern MUSS literal
   escaped werden (very-nomagic/`\V`-äquivalent), nie als Regex direkt übernommen —
   verhindert sowohl falsche Treffer als auch pathologisches Backtracking.
4. Case-Sensitivity von Highlights/Suchmustern explizit fest einbrennen (`\C`/`\c`), statt
   sich auf globale Optionen wie `'ignorecase'` zu verlassen, wenn die Bedeutung über
   Sessions/Optionsänderungen stabil bleiben soll.
5. Round-Robin-Zuteilung von begrenzten Ressourcen (Farben, Slots) sollte belegte Optionen
   überspringen, solange freie existieren — vermeidet unnötige Kollisionen bei knapper,
   aber nicht erschöpfter Kapazität.
6. Persistierte Slot-/Index-Werte aus einem Snapshot immer gegen die AKTUELLE Konfiguration
   klemmen (nicht gegen die zum Speicherzeitpunkt gültige), da sich Konfiguration zwischen
   Save und Load ändern kann.
7. Bei datei-bezogenen Opt-out/Exception-Modellen die Semantikfrage ("bezieht sich die
   Exception auf Erstellungsort oder auf Vorkommen im Text?") explizit im Code-Kommentar
   beantworten und die praktisch billigere, wohldefinierte Variante wählen.
8. Snapshots/Cache-Dateien immer als externen, nicht vertrauenswürdigen Input behandeln:
   beim Laden jedes Feld re-validieren (Typ, Länge, Count-Cap), niemals ausführbare/
   pattern-bildende Daten direkt aus der Datei übernehmen — Pattern immer aus dem
   Rohtext neu bauen.
9. Explizite Bounded-Input-Limits (Text-Länge, Zeilen-Länge, Max-Entries) mit Begründung
   dokumentieren, welchen konkreten unbounded Input sie abdecken — macht Reviews und
   spätere Anpassungen nachvollziehbar.
10. Bei Cross-Platform-Pfad-Keys (Windows-Laufwerksbuchstaben, Backslashes) immer auf ein
    normalisiertes, case-insensitives Format vereinheitlichen, bevor sie als Map-Keys dienen.
11. Config-Validierung sollte fehlerhafte Einzelwerte auf Defaults degradieren statt die
    gesamte Plugin-Initialisierung abzubrechen — mit Report über `:checkhealth`, was verworfen
    wurde.

## Keybindings-Audit

Preset aktiv per Default (`keymaps.preset = true`), jede Aktion einzeln per Config-Key
deaktivierbar (README.md "Keymaps", `lua/spotlight/bindings/keymaps.lua`).

| lhs | mode | Aktion |
|---|---|---|
| `<leader>mk` | n | `toggle` — Spotlight auf Token unter Cursor |
| `<leader>mk` | x | `toggle_selection` — Spotlight auf exakte Selektion |
| `<leader>mK` | n | `list` — Spotlight-Liste öffnen |
| `<leader>m<C-k>` | n | `clear` — alle entfernen |
| `<leader>mq` | n | `quickfix` — Treffer in Quickfix |
| `]k` | n | `next` — nächstes Vorkommen |
| `[k` | n | `prev` — vorheriges Vorkommen |

- `count`-Unterstützung: NEIN für alle sieben Mappings — keins liest `v:count`. Für `]k`/`[k`
  wäre `N]k`/`N[k` ("N Vorkommen weiterspringen") eine naheliegende, sinnvolle Erweiterung
  (ähnlich wie `n`/`N` bei der Suche kein `count` nutzen, aber andere Motion-artige Mappings
  in Neovim wie `}`/`{` es tun) — aktuell nicht implementiert, aber plausibel nachrüstbar,
  da `nav.lua` die eigentliche Navigation kapselt.
- Ex-Command-Completion: `:Spotlight` ist ein `lib.nvim.usercmd.composer`-Verb mit
  vollständiger `<Tab>`-Completion aller Subcommands (`toggle/add/remove/clear/list/next/
  prev/qf/persist/refresh`, README.md "The :Spotlight command"); `persist` completed
  `on|off|default|status`. Gute Abdeckung, keine Lücke erkennbar.
- Fehlende Flags/Ideen: `:Spotlight list` unterstützt `jump`/`remove` als Modus-Arg, aber
  kein Filter-Arg (z.B. nur Spotlights einer bestimmten Farbe/eines bestimmten Ursprungs
  anzeigen) — bei vielen aktiven Spotlights könnte das nützlich sein. `next`/`prev` könnten
  ein `!`-Bang oder Flag für "auch über `nav.scope=all` hinaus explizit die ganze
  Session durchsuchen" gebrauchen, unabhängig vom konfigurierten `nav.scope`.

## Ideen für andere Plugins

- **Generisches fensterlokales-Match-Ledger-Modul** für lib.nvim: das
  `window -> {id -> match id}`-Bookkeeping aus `core/match.lua` ist ein wiederverwendbares
  Muster für jedes Plugin, das `matchadd()`/`matchdelete()` global wirken lassen will
  (z.B. ein generisches "Highlight-Persistenz"-Grundgerüst statt projektspezifisch für
  Spotlights).
- **Literal-Pattern-Builder** (`\V` + Escaping + `\C`/`\c` + optionale Wortgrenzen nach
  Token-Kind) als eigenständiges lib.nvim-Utility — jedes Plugin, das Nutzertext gegen
  Vim-Regex sicher matchen will (Suchen-Ersetzen-Plugins, Bookmark-Highlighter), müsste
  das sonst neu erfinden.
- **Origin-basiertes Exception-Modell** (Persistenz-Override pro "wo wurde es erstellt" statt
  "wo kommt es vor") als generisches Pattern für andere Plugins mit
  Datei-übergreifendem State und Datei-lokalem Opt-out (z.B. bookmarks.nvim, todo-highlighter).
