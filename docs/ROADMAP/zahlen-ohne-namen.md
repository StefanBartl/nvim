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

## A — Float-Größen (26 von 43) — **gelöst, aber nicht mit Config-Keys**

Neun Plugins, 26 Stellen, überall dieselbe Rechnung von Hand:

```lua
local width  = math.floor(vim.o.columns * 0.8)
local height = math.floor(vim.o.lines * 0.8)
```

26 Config-Keys wären die falsche Antwort gewesen. Die richtige stand schon in
der Bibliothek: `lib.nvim.ui.kit.layout` kennt seit jeher die Konvention
„Wert ≤ 1 ist ein Bruchteil, größer ist Zellen" — nur `make_scratch`, durch
das jeder dieser 26 Aufrufe am Ende geht, kannte sie nicht.

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

**Offen (mechanisch):** die 26 Aufrufstellen auf die kurze Form umstellen.
Nichts davon ist dringend — sie funktionieren unverändert weiter, es ist
Aufräumen. Betroffen: reposcope (11), pdfport (4), language (4), learn-cli
(3), lsp (2), markdown (2), filetree (2), images (1).

## B — Timeouts auf externe Prozesse (7)

| Plugin | Stelle | Wert | Einschätzung |
| --- | --- | --- | --- |
| documentation | `checklist.lua:50`, `churn.lua:52` | 120000 | Zwei Minuten für einen Git-Walk. Auf einem großen Repo knapp — derselbe Fall wie insights' rg-Timeout, den Durchgang eins konfigurierbar gemacht hat. **Kandidat.** |
| documentation | `mcp/tools.lua:395` | 120000 | Dito. |
| color_my_ascii | `cache_manager.lua:22`, `init.lua:47` | 5000 | Zwei Stellen, derselbe Wert, ohne gemeinsame Quelle — die driften. **Mindestens zusammenführen.** |
| pickers | `DEFAULTS.lua:177`, `smart/init.lua:17` | 3000 | Einer steht schon in DEFAULTS; der zweite ist eine Kopie daneben. **Zusammenführen.** |
| debugging | `views/display.lua:61` | 500 | UI-Timing, klein, unkritisch. |

## C — Defer- und Poll-Intervalle (5)

| Plugin | Stelle | Wert | Einschätzung |
| --- | --- | --- | --- |
| cmdlog | ~~`note_popup.lua:62`~~ | ~~4000~~ | **Hinfällig (2026-08-27):** das Favorite-Notes-Feature ist entfernt — es öffnete einen normalen Buffer, der mit reposcope kollidierte, und eine Notiz an einem CLI-Favoriten lohnt den Debug-Aufwand nicht. Damit ist auch das Popup weg. |
| github_stats | `background.lua:75` | 1000 | Verzögerung vor dem Hintergrundzyklus. Unkritisch. |
| language | `item_menu.lua:81` | 500 | UI-Timing. |
| pickers | `result_count/init.lua:37` | 150 | Tick der Trefferzählung. |
| reposcope | `prompt_reload.lua:32` | 80 | Grenzfall, faktisch ein Tick. |

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
