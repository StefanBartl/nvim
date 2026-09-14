# Kreuzfeature-Check: `ui.nvim` gegen die ~30 Schwesterplugins

> **Zweck dieser Datei:** Bestandsaufnahme, wie `ui.nvim` und die anderen
> `StefanBartl/*.nvim`-Plugins unter `$REPOS_DIR\repos` bereits
> zusammenarbeiten (oder zusammenarbeiten könnten), Zeile für Zeile gegen den
> echten Code geprüft (Stand 2026-09-14), nicht gegen die Doku-Behauptungen
> allein. Zwei konkrete, risikoarme Lücken wurden im selben Durchgang auch
> geschlossen (siehe [Abschnitt 4](#4-umgesetzt-in-diesem-durchgang)); alles
> andere ist Befund/Empfehlung ohne Priorität oder Termin.

---

## Inhaltsverzeichnis

1. [Kernbefund](#1-kernbefund)
2. [Bestand: `ui.nvim` als UI-Toolkit-Provider (`ui.kit`/`ui.contextmenu`)](#2-bestand-uinvim-als-ui-toolkit-provider-uikituicontextmenu)
3. [Bestand: `ui.nvim` als Statusline-Consumer](#3-bestand-uinvim-als-statusline-consumer)
4. [Umgesetzt in diesem Durchgang](#4-umgesetzt-in-diesem-durchgang)
5. [Echte Lücken — geprüft und bewertet](#5-echte-lücken--geprüft-und-bewertet)
6. [Falsche Fährten (erst als Lücke erschienen, dann widerlegt)](#6-falsche-fährten-erst-als-lücke-erschienen-dann-widerlegt)
7. [Nebenbefund: README/health.lua-Drift](#7-nebenbefund-readmehealthlua-drift)
8. [Vollständige Matrix](#8-vollständige-matrix)

---

## 1. Kernbefund

Das Ökosystem ist bereits **deutlich enger cross-integriert, als die
`ui.nvim`-README bisher zeigte**. Zwei tragende Muster laufen seit längerem
produktiv:

1. **`ui.kit` + `ui.contextmenu` als gemeinsames UI-Toolkit.** Nicht nur
   die vier in der README genannten Partner (casedesk, filetree, my.nvim,
   lib.nvim) — **189 Fundstellen über ~20 Plugins** rufen `ui.kit.select`,
   `.input`, `.confirm`, `.viewer`, `.surface`, `.menu`, `.compare` oder
   `ui.contextmenu` auf, jede davon hinter einem `pcall`, sodass `ui.nvim`
   für alle ein weicher Dependency bleibt. Das ist der mit Abstand größte
   Integrationspunkt im ganzen Ökosystem und war in der README bisher gar
   nicht erwähnt.
2. **Statusline-Module als Consumer-Muster.** `ui.nvim` liest bereits
   Daten aus casedesk, filetree, github_stats, runtime-analysis und
   recommender und baut daraus fünf fertige Statusline-Segmente
   (`docs/modules.md`). Zwei weitere Plugins — sessions.nvim und
   sandbox.nvim — hatten ihre Hälfte davon schon erledigt (ein fertiges,
   gecachtes `component()`/`status()`) ohne dass `ui.nvim` je die
   Gegenseite gebaut hätte. Das wurde in diesem Durchgang nachgezogen
   (Abschnitt 4).

Echte, unadressierte Lücken sind selten und klein: von ~30 Plugins hatten
nach Bereinigung falscher Ersttreffer (Abschnitt 6) nur **drei** überhaupt
keine `ui.nvim`-Berührung — debugging.nvim, mdview.nvim, media.nvim — und
bei allen dreien ist "keine Integration" eher eine bewusste
Architekturentscheidung als eine Lücke (Abschnitt 5).

---

## 2. Bestand: `ui.nvim` als UI-Toolkit-Provider (`ui.kit`/`ui.contextmenu`)

Grep über `E:\repos\*.nvim\lua\**\*.lua` nach
`require\(['"]ui\.(kit|contextmenu|winbar|statusline|tabline)` (plus die
`pcall(require, "ui...")`-Variante, die einfache String-Suche verpasst) —
Plugins, die `ui.kit` und/oder `ui.contextmenu` bereits aktiv nutzen:

| Plugin | Nutzt |
| --- | --- |
| buffer-ctx.nvim | `ui.kit.select`, `.input` |
| cascade.nvim | `ui.kit.select`, `ui.contextmenu` |
| casedesk.nvim | `ui.kit` (ui.lua, resolve.lua) |
| cmdlog.nvim | `ui.kit.confirm` |
| color_my_ascii.nvim | `ui.contextmenu` (einfache statt doppelte Anführungszeichen — erster Grep-Durchlauf hat das verpasst, siehe Abschnitt 6) |
| dap.nvim | `ui.kit.select`, `.input`, `ui.contextmenu` |
| diff.nvim | `ui.kit.input`, `.select`, `.confirm` |
| documentation.nvim | `ui.kit.select`, `ui.contextmenu` |
| emojis.nvim | `ui.kit.select` |
| fileops.nvim | `ui.kit.input`, `.confirm`, `ui.contextmenu` |
| filetree.nvim | `ui.kit` durchgängig (13+ Stellen), `ui.contextmenu` |
| github_stats.nvim | `ui.kit.note`, `ui.contextmenu` |
| gopath.nvim | `ui.kit.select` |
| hover.nvim | `ui.kit.surface`, `.viewer` (Dashboard, `pcall`-Muster) |
| images.nvim | `ui.kit.compare`, `ui.contextmenu` |
| insights.nvim | `ui.kit` (scratch.lua, devserver) |
| language.nvim | `ui.kit.select`, `.surface` (fünf Stellen) |
| lsp.nvim | `ui.kit.viewer`, `ui.contextmenu` |
| markdown.nvim | `ui.kit.select` als Default-Picker-Backend (`util/picker.lua`, per `pcall(require, "ui.kit")`) |
| open.nvim | `ui.kit.select`, `ui.contextmenu` |
| pdfport.nvim | `ui.kit.input` |
| pickers.nvim | `ui.kit.input` |
| reposcope.nvim | `ui.kit` durchgängig — laut eigener `docs/requirements.md` ein **echter** (nicht weicher) Dependency, weil `ui.kit` Filter-/Sort-Prompts und Favoriten-/Hilfe-/Status-Views trägt |
| replacer.nvim | `ui.kit` (11 Dateien) — laut eigener README ebenfalls ein "echter" Dependency neben lib.nvim |
| sandbox.nvim | `ui.kit.confirm`, `ui.contextmenu` (8 Dateien) |
| sessions.nvim | `ui.kit.confirm` als Fallback für `autoload = "ask"` (`pcall`-Muster, `health.lua` meldet es explizit) |
| spotlight.nvim | `ui.kit`, `ui.contextmenu` |

**Bemerkenswert:** `reposcope.nvim` und `replacer.nvim` führen `ui.nvim`
in ihren eigenen `docs/requirements.md`/README als **echten** Dependency
(nicht "soft"), weil sie `ui.kit` für ihre komplette Prompt-/View-Schicht
brauchen. `ui.nvim` ist damit für zwei Plugins bereits Infrastruktur, nicht
nur "nice to have" — das war mir vorher nicht in dieser Deutlichkeit klar
und stand auch nirgends gesammelt.

---

## 3. Bestand: `ui.nvim` als Statusline-Consumer

`docs/modules.md`/`lua/ui/statusline/catalog.lua` listen bereits fünf
Segmente, die Daten aus anderen Plugins ziehen:

| Segment | Quelle | Was es zeigt |
| --- | --- | --- |
| `casedesk` | casedesk.nvim | Fall-Kurzinfo + SLA-Badge |
| `filetree_cwd_mode` | filetree.nvim | cwd-Modus-Badge (PROJECT/LOCK/MANUAL/…) |
| `github_stats_badge` | github_stats.nvim | Wochen-Views fürs aktuelle Repo |
| `runtime_analysis_ampel` | runtime-analysis.nvim | 🟢/🟡/🔴 Health-Ampel über alle instrumentierten Plugins |
| `recommender_badge` | recommender.nvim | Anzahl offener Alias-Vorschläge im Buffer |

Jedes davon ist ein `pcall`-geschützter Thin Wrapper, jedes degradiert auf
`""`, wenn das Partnerplugin fehlt — das etablierte Muster, an dem sich
alles Neue orientieren sollte.

---

## 4. Umgesetzt in diesem Durchgang

Zwei weitere Plugins hatten ihre Hälfte des exakt selben Musters schon
gebaut — ein statusline-plugin-agnostisches, selbst gecachtes
`component()`/`status()`, explizit als "sicher auf jedem Redraw aufrufbar"
dokumentiert — ohne dass `ui.nvim` je die Gegenseite (Catalog-Eintrag +
Wrapper-Modul) gezogen hätte:

- **sessions.nvim** (`docs/statusline.md`): `require("sessions.statusline").component()`
  liefert den aktiven Session-Namen plus Dirty-Marker (` *`), wenn sich das
  Fenster-/Buffer-Layout seit dem letzten Save/Load geändert hat.
- **sandbox.nvim** (`docs/statusline.md`): `require("sandbox.statusline").status()`
  liefert eine Ambient-Zusammenfassung wie `"docker (2/5)"`, intern
  stale-while-revalidate gecacht (Standard-TTL 3s), damit kein Redraw je
  synchron auf `docker ps` wartet.

Gebaut, nach exakt dem Muster von `recommender_badge`/`github_stats_badge`
(Thin-`pcall`-Wrapper, kein eigenes Caching, weil die Partnerseite das
schon erledigt):

- `E:\repos\ui.nvim\lua\ui\statusline\modules\session_status\init.lua`
- `E:\repos\ui.nvim\lua\ui\statusline\modules\sandbox_ambient\init.lua`
- Catalog-Einträge in `lua/ui/statusline/catalog.lua`
- Zwei neue Zeilen + ein Erklärabsatz in `docs/modules.md`
- `TESTS/session_status_spec.lua`, `TESTS/sandbox_ambient_spec.lua` (je 3 Tests: nicht installiert, leerer String, Text wird durchgereicht)
- README "Around it" erweitert (fehlte bisher: github_stats, runtime-analysis, recommender, sessions, sandbox als Statusline-Partner; `ui.kit`/`ui.contextmenu` als Toolkit-Provider für ~20 Plugins fehlte komplett)

Status: **luacheck clean, stylua clean, komplette Testsuite grün (0
Failures)**, committed und auf `main` gepusht — sofort nutzbar über
`order = { ..., "session_status", "sandbox_ambient" }` +
`modules = { session_status = require("ui.statusline.modules.session_status"), sandbox_ambient = require("ui.statusline.modules.sandbox_ambient") }`.

---

## 5. Echte Lücken — geprüft und bewertet

Nach Bereinigung der Fehltreffer (Abschnitt 6) bleiben drei Plugins ohne
jede `require("ui...")`-Referenz im eigenen Code:

### debugging.nvim

Nutzt durchgängig `lib.nvim.notify` für alles, auch für mehrzeilige
Diagnose-Dumps (`views/debug_helper.lua`s `report()` baut einen
60-Zeichen-Rahmen-Report und kippt ihn als einen `notify.info(...)`-Block
raus). **Konkrete, nicht umgesetzte Idee:** so ein Report ist genau der
Fall, für den `hover.nvim`s `show_keys()` bereits `ui.kit.viewer` statt
`vim.notify` verwendet — ein scrollbarer Read-only-Buffer statt einer
Notify-Wand. Geringes Risiko, geringer Nutzen (der Helfer ist laut
eigenem Kommentar "not wired into `:Debug`", also Dev-Tool, kein
User-Pfad) — deshalb nicht umgesetzt, nur notiert.

### mdview.nvim

Browser-basiertes Preview, rendert bewusst nichts im Terminal/Neovim
selbst ("renders nothing on the server"). Die In-Editor-Oberfläche ist
entsprechend minimal by design — `ui.kit` hätte hier wenig zu tun außer
vielleicht einen `ui.kit.confirm` vor einem Session-Neustart. Bewertung:
**kein Fehlen, sondern konsistent mit dem Architekturprinzip** des
Plugins.

### media.nvim

Nutzt `vim.notify` an drei Stellen für Probe-Ergebnisse/Fehler
(`lua/media/ui.lua`). Das Plugin ist laut eigener README bewusst
minimal gehalten ("it neither paints nor plays anything itself") und
hover.nvim ist bereits der dokumentierte Erstkonsument der erzeugten
PNGs. Ein `ui.kit.toast` statt `vim.notify` wäre eine kosmetische
Verbesserung, keine fehlende Fähigkeit. Nicht umgesetzt.

**Fazit zu allen dreien:** keiner ist ein Fall, wo Nutzer heute sichtbar
etwas vermissen — eher Kandidaten für "könnte man hübscher machen", falls
mal Zeit übrig ist. Kein Handlungsdruck.

---

## 6. Falsche Fährten (erst als Lücke erschienen, dann widerlegt)

Der erste Grep-Durchlauf (`require\("ui\....`, nur doppelte
Anführungszeichen) listete fälschlich folgende Plugins als "keine
Integration":

- **color_my_ascii.nvim** — nutzt `ui.contextmenu` tatsächlich, aber mit
  einfachen Anführungszeichen (`require('ui.contextmenu')`,
  `lua/color_my_ascii/integrations/menu.lua`).
- **hover.nvim** — nutzt `ui.kit.surface`/`.viewer` ausgiebig
  (`status_view.lua`, das komplette `:Hover dashboard`), aber über
  `pcall(require, "ui.kit")` (zwei Argumente statt eines
  String-Literal-Calls).
- **sessions.nvim** — nutzt `ui.kit.confirm` als Fallback für
  `autoload = "ask"`, ebenfalls über `pcall(require, ...)`, und
  `health.lua` prüft `ui.kit` explizit.
- **markdown.nvim** — `util/picker.lua`s `select_hover()` ist der
  **Default-Picker-Backend**, ebenfalls über `pcall(require, "ui.kit")`.

Lehre für zukünftige Greps in diesem Ökosystem: **immer sowohl
`require("ui...`/`require('ui...` als auch
`pcall(require, "ui...")`/`pcall(require, 'ui...')` suchen** — die zweite
Form ist der Standard-Soft-Dependency-Stil hier und wird von einer reinen
`require\(` -Suche verschluckt.

---

## 7. Nebenbefund: README/health.lua-Drift

`lua/ui/health.lua`s `check_segments()` (Zeilen ~276–294) listet als
"Statusline segments, die von etwas außerhalb abhängen" nur
`nvim-web-devicons`, `neotest` und `casedesk.meta` — **weder
filetree_cwd_mode, github_stats_badge, runtime_analysis_ampel,
recommender_badge noch die beiden neuen Module tauchen dort auf**, und
`neotest` referenziert offenbar ein Segment, das im aktuellen Catalog gar
nicht mehr existiert. Sieht nach eigenständigem Alt-Stand aus, der beim
Hinzufügen neuer Module nicht mitgepflegt wurde — nicht Teil dieses
Durchgangs (Scope war Cross-Feature-Check, nicht Health-Check-Pflege),
aber notiert, falls das mal aufgeräumt werden soll.

---

## 8. Vollständige Matrix

Alle ~34 Plugins unter `$REPOS_DIR\repos` (exkl. `ui.nvim` selbst), Stand
dieses Checks:

| Plugin | `ui.kit`/`ui.contextmenu` | Statusline-Segment in `ui.nvim` | `ui.nvim` in eigener README als Integrationspartner genannt |
| --- | :-: | :-: | :-: |
| buffer-ctx.nvim | ✅ | — | — |
| cascade.nvim | ✅ | — | — |
| casedesk.nvim | ✅ | ✅ (`casedesk`) | (n/a, keine eigene "Around it") |
| cmdlog.nvim | ✅ | — | — |
| color_my_ascii.nvim | ✅ | — | — |
| dap.nvim | ✅ | — | — |
| debugging.nvim | ❌ | — | — |
| diff.nvim | ✅ | — | — |
| documentation.nvim | ✅ | — | — |
| emojis.nvim | ✅ | — | — |
| fileops.nvim | ✅ | — | — |
| filetree.nvim | ✅ | ✅ (`filetree_cwd_mode`) | — |
| github_stats.nvim | ✅ | ✅ (`github_stats_badge`) | — |
| gopath.nvim | ✅ | — | — |
| hover.nvim | ✅ (pcall) | — | ✅ |
| images.nvim | ✅ | — | — |
| insights.nvim | ✅ | — | — |
| language.nvim | ✅ | — | — |
| lib.nvim | n/a (Basis, `ui.nvim` hängt davon ab, nicht umgekehrt) | | |
| lsp.nvim | ✅ | — | — |
| markdown.nvim | ✅ (pcall, Default-Backend) | — | — |
| mdview.nvim | ❌ (bewusst, browserbasiert) | — | — |
| media.nvim | ❌ (klein/bewusst minimal) | — | — |
| my.nvim | nur `ui.winbar.set()`, keine `ui.kit`-Nutzung | — | ✅ |
| open.nvim | ✅ | — | — |
| pdfport.nvim | ✅ | — | — |
| pickers.nvim | ✅ | — | — |
| recommender.nvim | — | ✅ (`recommender_badge`) | — |
| replacer.nvim | ✅ (echter Dependency) | — | ✅ (ui.nvim als "real dependency" gelistet) |
| reposcope.nvim | ✅ (echter Dependency) | — | ✅ (ui.nvim als "real dependency" gelistet) |
| runtime-analysis.nvim | — | ✅ (`runtime_analysis_ampel`) | — |
| sandbox.nvim | ✅ | ✅ neu (`sandbox_ambient`) | — |
| sessions.nvim | ✅ (pcall) | ✅ neu (`session_status`) | — |
| spotlight.nvim | ✅ | — | — |

**Legende:** ✅ = vorhanden und geprüft · ❌ = keine Integration gefunden
(bewertet in Abschnitt 5) · „—" = nicht zutreffend/nicht geprüft in dieser
Dimension.
