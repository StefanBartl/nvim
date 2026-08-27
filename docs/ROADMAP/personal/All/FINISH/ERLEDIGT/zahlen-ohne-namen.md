# Zahlen ohne Namen, und Plattform-Verzweigungen

Stand: 2026-08-27. Durchgang **zwei** der Konfigurierbarkeits-Aufarbeitung.
Durchgang eins (`nicht-konfigurierbare-features.md`) suchte nach benannten
Modul-Konstanten; der konnte strukturell zwei Dinge nicht sehen:

- eine Zahl direkt im Aufruf — `vim.defer_fn(fn, 60)`, `timer:start(250, …)`,
  `vim.o.columns * 0.8` — die keinen Namen hat, gegen den man eine Config
  prüfen könnte, und
- eine Plattform-Verzweigung ohne Möglichkeit zu sagen „nein, mach das andere".

Skript: `tools/magic_numbers.py` neben dieser Datei. Defers/Waits **unter
50 ms** sind ausgefiltert — die sind „raus aus dem aktuellen Tick", keine
Einstellung.

**Gefunden: 43 Zahlen, 47 Plattform-Verzweigungen.**

---

## Das Ergebnis in einem Satz

Die 43 Zahlen sind nicht 43 Entscheidungen, sondern im Wesentlichen **eine**:
26 davon sind Float-Größen (`vim.o.columns * 0.8`) in neun Plugins. Und die
47 Plattform-Verzweigungen sind fast durchweg **Tatsachen über das
Betriebssystem**, keine Präferenzen — dafür steckte in ihnen ein echter Bug.

---

## A — Float-Größen (26 von 43) — **erledigt 2026-08-27**

Neun Plugins, 26 Stellen, überall dieselbe Rechnung von Hand:

```lua
local width  = math.floor(vim.o.columns * 0.8)
local height = math.floor(vim.o.lines * 0.8)
```

26 Config-Keys wären die falsche Antwort gewesen. Die richtige stand schon in
der Bibliothek: `lib.nvim.ui.kit.layout` kennt seit jeher die Konvention
„Wert ≤ 1 ist ein Bruchteil, größer ist Zellen" — nur `make_scratch` kannte sie
nicht — und, wie sich beim Abarbeiten zeigte, geht längst nicht jeder dieser
26 Aufrufe überhaupt dort hindurch (siehe Nachtrag unten).

**`make_scratch` nimmt jetzt Bruchteile.** `width = 0.8` genügt. Damit kann
jedes Plugin, das ohnehin eine Config-Tabelle hat, seinen Wert direkt
durchreichen — ohne Arithmetik am Aufrufort und ohne neuen Key pro Float.

**Ein Detail weicht bewusst von `kit.layout` ab**, und es war beinahe ein
stiller Regressionsbug: dort ist `1` „das Ganze", hier ist es *eine Zelle*.
Ein Pane von einer Zelle Höhe ist sinnlos, ein Float von einer Zeile ist
jeder Prompt dieser Bibliothek — `kit.input`, `kit.live_input`, beide
Progress-Styles und die Statusline übergeben `height = 1` und meinen es so.
Als 100 % gelesen hätte das jeden Prompt auf volle Höhe aufgerissen. Bruchteil
ist deshalb *strikt* zwischen 0 und 1.

### Nachtrag 2026-08-27: „26 mechanisch umstellbar" war falsch

Beim Abarbeiten habe ich alle 26 Stellen angesehen, statt sie zu ersetzen.
**Genau drei** sind reine Durchreichungen, bei denen der Wert unverändert in
`make_scratch` geht — die sind umgestellt (pdfport ×2, learn-cli ×1). Die
übrigen 23 zerfallen in zwei Gruppen, die die Konvention *nicht* ausdrücken
kann:

**Kappung gegen Inhaltsgröße** (`math.min(content_w + 2, 80%)`). Der Anteil
ist hier eine Obergrenze, nicht die Größe: das Fenster ist so breit wie sein
Inhalt, höchstens aber so breit wie der Anteil. `width = 0.8` würde daraus
„immer 80 %" machen — eine Verhaltensänderung, kein Refactoring. Betrifft
language (`translate/output`), filetree (Cheatsheet), lsp (beide) und
reposcope (favorites/help/status view).

**Der Wert speist eigene Geometrie.** `col = (columns - width) / 2` oder
`col = columns - width` braucht die Zahl in Zellen, nicht als Anteil, und das
Fenster wird per `nvim_open_win` geöffnet, nicht über `make_scratch`.
Betrifft language (`translate/window`), markdown (`image_preview`), learn-cli
(`exercise_view`), images (Gallery-Layout).

Die Lehre für die Liste selbst: „dieselbe Zahl an 26 Stellen" hat *nicht*
bedeutet „dieselbe Entscheidung an 26 Stellen". Das Muster war echt, die
daraus abgeleitete Aufgabe war es nicht.

### Und ein Bug, der genau dabei auffiel

reposcopes Layout-Module — `ui/config`, `list_config`, `preview_config`,
`prompt_config`, `background_config` — berechneten ihre Geometrie **auf
Modulebene**, also einmal, beim ersten `require`. Wer danach das Terminal
vergrößerte, bekam die Picker für den Rest der Session in der alten Größe.
`update_layout()` hätte das geheilt, wurde aber von nichts aufgerufen, und
einen `VimResized`-Handler gibt es in dem Plugin nirgends.

Jede der fünf hat jetzt ein `recompute()`, das `open_ui()` in
Abhängigkeitsreihenfolge aufruft. Beim Öffnen statt bei `VimResized`, weil
die Werte ohnehin nur beim Öffnen gelesen werden. `update_layout(width)`
pinnt seinen Wert seither: er überlebt spätere Recomputes, alles
Nicht-Gepinnte fällt weiter aus der Editorgröße.

## B — Timeouts auf externe Prozesse (7) — **erledigt 2026-08-27**

| Plugin | Stelle | Wert | Ergebnis |
| --- | --- | --- | --- |
| documentation | `checklist.lua`, `churn.lua`, `mcp/tools.lua` | 120000 | **`git_log_timeout_ms`** — ein Key statt drei ausgeschriebener Kopien, samt drei Fehlermeldungen, die „within 120s" als Text führten. Die formatieren die Zahl jetzt aus dem echten Wert. |
| color_my_ascii | `cache_manager.lua`, `init.lua` | 5000 | **Kopie entfernt.** `init.lua` reichte eine Fallback-Tabelle durch, die die Modul-Defaults Wort für Wort wiederholte (cache: 3 Werte, debounce: 5). Beide `configure` mergen ohnehin feldweise — jetzt `or {}`. |
| pickers | `DEFAULTS.lua`, `smart/init.lua` | 3000 | **Kopie entfernt.** `smart.defaults()` führte dieselben sechs Werte ein zweites Mal und wäre bei Drift die Verliererin gewesen (`M.config()` merged die Config darüber). Liest jetzt `config.DEFAULTS`. |
| debugging | `views/display.lua` | 500 | **`timings.capture_timeout_ms`** — der Subsystem hat einen `timings`-Block, in dem jedes andere Zeitmaß schon stand. |

**Dabei aufgefallen und mitbehoben:** `commit_dates` in documentation bekam
die aufgelöste Config gar nicht, konnte den User-Wert also nicht sehen; und
`Documentation.Handle` hatte kein `cfg`, obwohl die Registry `entry.opts`
direkt daneben hält — das MCP-Tool hätte den Default raten müssen.

## C — Defer- und Poll-Intervalle (5) — **erledigt 2026-08-27**

Drei konfigurierbar, zwei bewusst nicht — die Trennlinie ist, *wessen*
Latenz die Zahl schätzt.

| Plugin | Stelle | Wert | Ergebnis |
| --- | --- | --- | --- |
| github_stats | `background.lua` | 1000 | **`background.initial_delay_ms`.** Der wiederkehrende Zyklus leitete sein Intervall längst aus `fetch_interval_hours` ab — die Verzögerung vor dem *ersten* stand daneben als Literal. Dieselbe Entscheidung, eine Hälfte konfigurierbar, die andere nicht. Und ihr Zweck ist „nicht mit dem Startup konkurrieren", was von der Config des Users abhängt, nicht vom Plugin. |
| language | `spell/ui/item_menu.lua` | 500 | **`spell.ui.lsp_refresh_delay_ms`.** Nach einer LSP-Code-Action gibt es kein Fertig-Signal; der Refresh wartet eine plausible Weile und sieht nach. Die Zahl schätzt also die Latenz *eines fremden Servers* — genau das, was pro Setup variiert. |
| pickers | `result_count/init.lua` | 150 | **`result_count.interval_ms`.** Der Feature-Block existierte schon (das Feature ist opt-in), also kostet ein Intervall daneben nichts. Wird einmal beim Schleifenstart gelesen, nicht pro Tick. |
| cmdlog | `note_popup.lua` | 4000 | **Hinfällig** — Favorite-Notes sind entfernt. |
| reposcope | `prompt_reload.lua` | 80 | **Bleibt Literal, jetzt mit Begründung im Code.** Die 80ms lassen `close_ui`s Teardown vor dem Reopen fertig werden — sie kommen vom aktuellen Tick weg, sie werden nicht justiert. Ein Key lädt dazu ein, sie auf 0 zu setzen und einen Reopen zu bekommen, der mit dem Close rennt, auf den er wartet. |

## D — Plattform-Verzweigungen (47) — fast alle Tatsachen

Aufgeteilt nach Repo: lib.nvim 22, gopath 7, filetree 6, mdview 5, debugging
4, lsp 3, markdown 3, dap 2, open 2.

**Kein Opt-out nötig** bei der großen Mehrheit, und das ist keine Bequemlichkeit:

- **Pfadtrenner** (`package.config:sub(1,1)`) — eine Tatsache, keine Meinung.
- **`lib.nvim.cross.platform.*`** — das sind die Erkennungsfunktionen selbst.
- **Healthchecks**, die die Plattform *berichten*.
- **`sourcekit` verlangt Darwin**, **`mason_node` überspringt win32** — Tatsachen
  über die Werkzeuge, nicht über den Geschmack.
- **gopath's `minimal_fallback_open`** sieht nach einem Kandidaten aus, ist aber
  ausdrücklich nur aktiv, „wenn open.nvim *und* lib.nvim fehlen". Der normale
  Weg läuft über open.nvims Handler-Registry, die der User vollständig
  konfiguriert. Der Escape-Hatch existiert also — eine Ebene höher.

**Dabei gefunden und behoben — ein echter Bug, kein Konfigurierbarkeits-Thema:**

`filetree/features/ui/size_info` rief auf Unix `du -sb` auf. `-b` ist eine
GNU-Erweiterung; auf macOS und den BSDs lehnt `du` das Flag ab, der Prozess
endet mit Exit ≠ 0, und der Callback kehrt still zurück — keine Fehlermeldung,
nur eine Spalte, die dauerhaft leer bleibt. Jetzt `du -sk` (POSIX) mal 1024.
Der Genauigkeitsverlust ist nach der Formatierung unsichtbar.

---

## Was auch dieser Durchgang nicht sieht

- **Reihenfolgen.** Welche Picker-Engine zuerst probiert wird, in welcher
  Reihenfolge Marker für die Projektwurzel geprüft werden — das sind Listen im
  Code, keine Zahlen und keine Verzweigungen.
- **Schwellwerte in Bedingungen.** `if #files > 500 then` fällt durch beide
  Raster: die 500 hat keinen Namen *und* steht in keinem Aufruf, den das
  Muster kennt.
- **Hardcodierte Pfade und Kommandonamen**, sofern sie nicht in einer
  Plattform-Verzweigung stehen.

Ein dritter Durchgang müsste nach Vergleichsoperatoren mit Literalen suchen
(`> 500`, `>= 1024`). Der Ertrag pro Fund dürfte niedriger sein als hier —
die meisten solchen Zahlen sind Wachhunde, keine Regler.
