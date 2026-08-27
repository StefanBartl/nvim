# Implementiert, aber nicht user-konfigurierbar

Stand: 2026-08-27. Beantwortet den MERGED.md-Punkt *"Featureliste: welche
bereits implementierten Features sind noch nicht user-seitig konfigurierbar?
Auflisten, strittige Fälle markieren für Rückfrage."*

## Methode, und was sie nicht sieht

Gescannt wurde nach **Modul-Konstanten mit Verhaltensbedeutung** — Timeouts,
Limits, Größen, Intervalle, Tiefen — deren Name in der Config-Fläche des
Plugins (`config/`, `@types/`, `DEFAULTS.lua`) nicht vorkommt. Skript:
`tools/hardcoded_constants.py` neben dieser Datei.

Zwei Dinge sieht der Scan **nicht**, sie fehlen also unten:

1. **Verzweigungen ohne Namen.** Ein `if vim.fn.has("win32") == 1 then` ist
   auch eine Entscheidung, die jemand überschreiben wollen könnte, hat aber
   keine Konstante, an der man sie fassen könnte.
2. **Zahlen direkt an der Verwendungsstelle.** `vim.defer_fn(fn, 60)` fällt
   durch, weil 60 nie einen Namen bekommt. Davon gibt es einige; sie sind
   einzeln kleiner, in Summe aber nicht.

Umgekehrt sind unten **keine** Fälle wie markdowns `DEFAULT_MIN_LEVEL`: das
ist der Fallback hinter `toc.min_level` und damit längst konfigurierbar. Der
Scan zieht `DEFAULT_`-Präfixe ab, bevor er in der Config nachsieht.

---

## A — Klar: sollte konfigurierbar werden — **erledigt 2026-08-27**

Verhalten, das ein User plausibel anders will, und wo "anders" nicht heißt,
dass das Plugin kaputtgeht. **Alle Einträge dieser Tabelle sind umgesetzt**,
mit unverändertem Default und LuaLS-Typ pro Key; die Spalte "Config-Key"
nennt, wie er jetzt heißt.

| Plugin | Konstante | Wert | Config-Key | Warum konfigurierbar |
| --- | --- | --- | --- | --- |
| insights | `TIMEOUT_MS` | 120000 | `symbols.indexing.timeout_ms` | rg-Timeout. Auf einem Monorepo zu knapp, auf einem kleinen Repo unnötig lang. |
| filetree | `MAX_HISTORY` | 50 | `features.trash.max_history` (0 = unbegrenzt) | Wie viele Trash-Vorgänge rückgängig gemacht werden können — reine Präferenz. |
| filetree | `UNDO_DEPTH` | 10 | `refs.undo_depth` | Dasselbe für `refs undo`. |
| filetree | `MAX_VISIBLE` | 5000 | `max_visible_nodes` | Ab wann neo-tree nicht mehr alles rendert. Hängt an der Maschine. |
| filetree | `MAX_CACHE_ENTRIES` | 1000 | `features.project_root.max_cache_entries` | Project-Root-Cache. Speicher vs. Trefferquote. |
| images | `MAX_ENTRIES` | 20000 | `display.browse_max_entries` | Obergrenze beim Browsen. Gleiche Klasse. |
| github_stats | `MAX_USER_REPO_PAGES` | 30 | `max_user_repo_pages` | **Kappt Daten.** Bei >3000 Repos fehlen welche, ohne dass es jemand merkt. |
| github_stats | `RENDER_DEBOUNCE_MS` | 50 | `dashboard.render_debounce_ms` | Dashboard-Redraw. |
| github_stats | `HEADER_CONTENT_WIDTH` | 72 | `dashboard.header_width` | Layoutbreite — auf einem breiten Monitor Verschenkung. |
| github_stats | `SPARKLINE_WIDTH` | 24 | `dashboard.sparkline_width` | Dito. |
| gopath | `RTP_INDEX_TTL_MS` | 30000 | `truncated.rtp_index_ttl_ms` | Wie lange der rtp-Index gilt. Wer viel installiert, will kürzer. |
| lsp | `CHUNK_SIZE` / `CHUNK_DELAY_MS` | 25 / 10 | `workspace_diagnostics.configure{ chunk_size, chunk_delay_ms }` | Durchsatz vs. Editor-Reaktivität beim Workspace-Diagnostics-Lauf. Genau der Regler, den man auf schwacher Hardware braucht. |
| sandbox | `STATUS_CACHE_TTL_MS` | 3000 | `status_cache_ttl_ms` | Wie frisch die Statusline ist vs. wie oft docker/podman befragt wird. |
| sandbox | `CACHE_TTL_MS` | 4000 | `completion_cache_ttl_ms` | Dito für die Completion. |
| replacer | `MAX_ENTRIES` | 50 | `history_max_entries` | Länge der Suchhistorie. |
| replacer | `PROGRESS_THROTTLE_MS` | 100 | `progress_throttle_ms` (0 = gar nicht drosseln) | Fortschrittsanzeige. |
| runtime-analysis | `MAX_ENTRIES` | 200 | `history_max_entries` | Länge der History. |
| documentation | `CONTEXT_MAX` | 120 | `context_max`, `refs_per_entity` | Wie viel Kontext um einen Treffer gezeigt wird. |
| documentation | `WRITE_MS` | 400 | `browse.trail_write_ms` | Debounce beim Persistieren des Browser-Trails. |
| mdview | `INTERVAL_MS`, `HEALTH_POLL_MS`, `HEALTH_TIMEOUT_MS`, `MAX_RETRIES`, `BASE_RETRY_MS` | 250 / 200 / 10000 / 5 / 150 | `transport = {}` | Netzwerk-Timing gegen einen externen Prozess. Auf einer langsamen Maschine oder über eine langsame Verbindung sind alle fünf zu knapp. Als **ein** Block umgesetzt, nicht als fünf Keys: die Retry-Zahl ohne das Timeout hochzudrehen heißt nur, innerhalb eines abgelaufenen Fensters zu wiederholen. |

## B — Klar: sollte Konstante bleiben

| Plugin | Konstante | Warum nicht |
| --- | --- | --- |
| lib.nvim, documentation, runtime-analysis | `MIN_NVIM` | Eine Tatsache über den Code, keine Präferenz. Wer sie herunterdreht, bekommt kein funktionierendes Plugin, sondern einen späteren Fehler. |
| lib.nvim | `B64_CHARS`, `HEX_CHARS`, `VARIANT_CHARS` | Base64-, Hex- und UUID-Alphabete sind Spezifikation. Konfigurierbar wäre "kaputt konfigurierbar". |
| color_my_ascii | `HTML_ESCAPE` | HTML-Escaping ist ebenfalls Spezifikation. |
| documentation | `MODULE_CHARS` | Lua-Modulnamen-Zeichenklasse — folgt der Sprache, nicht dem Geschmack. |
| markdown | `MAX_SUBARGS` | Parser-Grenze der Subcommand-Grammatik, keine Verhaltenseinstellung. |
| runtime-analysis | `MAX_STRING`, `MAX_ARGS` | Fingerprint-Normalisierung. Ändert man sie, sind alte und neue Telemetrie nicht mehr vergleichbar — das ist ein Datenformat, kein Regler. |

## C — Strittig, Rückfrage

Hier ist die Antwort eine Geschmacks- oder Zielgruppenfrage, keine technische.

1. **`github_stats.SPARKLINE_CHARS`** (`▁▂▃▄▅▆▇█`) — konfigurierbar machen?
   *Dafür:* in einem Terminal ohne die Blockzeichen ist die Sparkline Müll,
   und ein ASCII-Fallback (`.:-=+*#`) wäre ein Einzeiler. *Dagegen:* es ist
   das einzige Feature, dessen Aussehen dann von zwei Stellen abhängt, und
   wir haben mit `lib.nvim.ui.nerd_font` bereits einen Mechanismus für
   "Zeichen nur, wenn der Font sie kann" — vielleicht gehört es dorthin statt
   in die Plugin-Config.

2. **`reposcope.MAX_NAME_W` / `MAX_BRANCH_W`** (28 / 22) — Spaltenbreiten der
   Status-View. Konfigurierbar, oder besser **automatisch** aus der
   Fensterbreite? Zwei Config-Keys sind billig, aber die richtige Lösung ist
   vermutlich, gar nicht zu fragen und zu rechnen.

3. **`sandbox.MAX_LEN = 200`** — Kürzung von Fehlermeldungen. Konfigurierbar
   wirkt übertrieben; andererseits ist eine abgeschnittene Docker-Fehlermeldung
   genau dann ärgerlich, wenn man sie braucht. Alternative: nicht kürzen,
   sondern die volle Meldung in `:messages` und die gekürzte in die
   Notification.

4. **`lib.nvim.logger.MAX_ITEMS = 200`** — wie viele Items beim Serialisieren
   eines Tables mitgehen. Das ist eine Bibliothek: gehört es in die
   Logger-Options (per Aufruf), in eine `lib.setup()`-Konfiguration (die es
   bisher nicht gibt), oder bleibt es Konstante?

5. **`documentation.TELEMETRY_TTL_MS = 2000`** — Cache-Dauer der
   Call-Hierarchy-Telemetrie. Konfigurierbar nur sinnvoll, wenn jemand die
   Zahl je bemerkt; ich sehe kein Szenario, in dem sie stört. Erwähnt, weil
   sie technisch in Kategorie A gehört und ich sie trotzdem nicht anfassen
   würde.

6. **`markdown.PLACEHOLDER_GRACE_MS = 250`** — wie lange der Hover-Platzhalter
   steht, bevor das Bild da ist. Gleiche Klasse: technisch ein Regler,
   praktisch ein Detail, das nur auffällt, wenn es falsch ist.

## Nicht erfasst, aber bekannt

- **Zahlen ohne Namen.** `vim.defer_fn(fn, 60)` in language.nvims Spell-Fix,
  `vim.wait(300)`-Muster, Float-Größen als Prozentsätze von `vim.o.columns`.
  Ein zweiter Durchgang müsste nach `defer_fn`/`wait`/`0%.%d+ %*` suchen; das
  wäre eine eigene Liste.
- **Plattform-Verzweigungen** (`has("win32")`), die kein Opt-out haben.
- **Reihenfolgen**: Fallback-Ketten wie translates `engine`-Kette sind
  konfigurierbar, andere (z. B. welche Picker-Engine zuerst probiert wird)
  nicht überall.

---

## Was beim Umsetzen noch auffiel

`github_stats.setup()` verwarf **jede** Option außer `repos` still, sobald
eine `config.json` existierte — und die schreibt das Plugin beim ersten Lauf
selbst. `setup({ dashboard = { … } })` tat also nichts, ohne dass irgendwo
stand warum. Die Reihenfolge ist jetzt: Datei (oder Default) als Basis,
`setup()` gewinnt darüber. Ohne diesen Fix wären die vier neuen Keys dort
unerreichbar geblieben.

`runtime-analysis.history.MAX_ENTRIES` war exportiert und wurde von Spec und
zwei Doc-Stellen gelesen. Aus der Konstante wurde `history.max_entries()` —
zwei Namen für dieselbe Zahl wären genau die Drift, gegen die die Konstante
ursprünglich exportiert wurde.
