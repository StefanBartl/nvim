# Review: `docs/ROADMAP/IDEAS/*` (2026-09-14)

> **Zweck:** Einschätzung aller zwölf angefragten Konzept-/Notiz-Dateien unter
> `docs/ROADMAP/IDEAS/` nach Nutzen, Umsetzbarkeit und Aufwand — und, wo
> zutreffend, ob eine Idee eher als Feature in ein bereits bestehendes eigenes
> Plugin gehört statt ein neues Repo zu rechtfertigen. Gegen den echten Stand
> von `$REPOS_DIR/*.nvim` und `nvim/lua/**` geprüft, nicht nur gegen die
> IDEAS-Datei selbst — konkrete Fundstellen sind referenziert.
>
> Fünf der zwölf Dateien (`blueprint.nvim.md`, `spec.nvim.md`, `test.md`,
> `slots.nvim.md`, `typepilot.nvim.md`) sind bereits vollständige
> Selbstanalysen mit eigener Bewertung. Dort liefert dieser Report einen
> **Meta-Verdict** (stimme zu / widerspreche / ergänze) statt die Analyse zu
> wiederholen. Die übrigen sieben sind Rohnotizen ohne eigene Bewertung —
> dort steht hier die eigentliche Einschätzung erstmals.

---

## Table of content

  - [Legende](#legende)
  - [Übersicht](#übersicht)
  - [Arbeiotsspeicher.md — Speicher-Viewer](#arbeiotsspeichermd--speicher-viewer)
  - [Better_TODOComments.md — TODO-Kommentar-Ersatz](#better_todocommentsmd--todo-kommentar-ersatz)
  - [IDEAS.md — vier Einzelideen](#ideasmd--vier-einzelideen)
    - [#1 Externe Deps durch Eigenimplementierungen ersetzen](#1-externe-deps-durch-eigenimplementierungen-ersetzen)
    - [#2 Wezterm-Integration (Tabs steuern, Wezterm-Statusline durch nvim ersetzen)](#2-wezterm-integration-tabs-steuern-wezterm-statusline-durch-nvim-ersetzen)
    - [#3 Screenkey-Integration](#3-screenkey-integration)
    - [#4 `lazy.nvim` nachbauen ("moderner, performanter, sicherer")](#4-lazynvim-nachbauen-moderner-performanter-sicherer)
  - [TMUX_WEZTERM_USW.md — leer](#tmux_wezterm_uswmd--leer)
  - [blueprint.nvim.md — Template-Bibliothek (Meta-Review)](#blueprintnvimmd--template-bibliothek-meta-review)
  - [git_nvim.md — Git-Konsolidierung](#git_nvimmd--git-konsolidierung)
  - [health.md — `:checkhealth`-Erweiterung](#healthmd--checkhealth-erweiterung)
  - [slots.nvim.md — nummerierte Datei-Slots (Meta-Review)](#slotsnvimmd--nummerierte-datei-slots-meta-review)
  - [spec.nvim.md — Test-Runner-Engine (Meta-Review)](#specnvimmd--test-runner-engine-meta-review)
  - [test.md — neotest-Auslagerung (Meta-Review)](#testmd--neotest-auslagerung-meta-review)
  - [Priorisierungsvorschlag](#priorisierungsvorschlag)

---

## Legende

| Skala | Bedeutung |
|---|---|
| **Nutzen** | niedrig / mittel / hoch — für wie viele Situationen/wie oft zahlt sich das aus |
| **Umsetzbarkeit** | niedrig / mittel / hoch — technisches Risiko, vorhandene Bausteine |
| **Aufwand** | Quick&nbsp;Win / Klein / Mittel / Groß / Sehr groß |
| **Fit** | eigenständiges Plugin / Feature in bestehendem Plugin / config-lokal / verwerfen |

---

## Übersicht

| Datei | Nutzen | Umsetzbarkeit | Aufwand | Fit |
|---|---|---|---|---|
| Arbeiotsspeicher.md | mittel (Nische: Assembly/Embedded) | mittel | Mittel | Feature in **`dap.nvim`** |
| Better_TODOComments.md | hoch | hoch | Klein–Mittel | eigenständiges Plugin (`comments.nvim`) |
| IDEAS.md #1 Deps-Audit | mittel | hoch | Klein (Audit selbst) | wiederkehrende Aufgabe, kein Plugin |
| IDEAS.md #2 Wezterm-Integration | mittel | mittel | Mittel | Feature in **`ui.nvim`** (tabline) |
| IDEAS.md #3 Screenkey | → siehe Screenkey.md | | | |
| IDEAS.md #4 lazy.nvim-Ersatz | niedrig | niedrig | Sehr groß | **verwerfen** |
| Screenkey.md | mittel | hoch | Klein | Feature in **`ui.nvim`** |
| TMUX_WEZTERM_USW.md | — (leer) | — | — | Datei leeren/mergen oder löschen |
| blueprint.nvim.md | hoch (bedingt) | hoch | Klein (MVP) + laufend (Content) | eigenständiges Plugin — **bauen** |
| git_nvim.md | hoch | hoch | Mittel | eigenständiges Plugin (Konsolidierung, nicht Neubau) |
| health.md | mittel, aber Konzept zu dünn | ungeklärt | ungeklärt | Klärungsbedarf vor Einschätzung |
| slots.nvim.md | hoch, *falls* Nische frei | hoch | Quick Win (Entscheidung) / Groß (Neubau) | **kein neues Plugin** — Feature in bestehendem |
| spec.nvim.md | hoch | hoch | Groß, phasiert | eigenständiges Plugin — **bauen, phasiert** |
| test.md | hoch | hoch | Mittel | eigenständiges Plugin — **bauen** |
| typepilot.nvim.md | offen | mittel | Mittel–Groß | Klärung vor Bau (Scope-Frage) |

---

## Arbeiotsspeicher.md — Speicher-Viewer

**Idee:** Ein Fenster wie in Visual Studio, das Arbeitsspeicher ab einer
Adresse in Bits anzeigt, klickbar modifizierbar — als separate, per Terminal
gestartete nvim-Instanz, die an die Ursprungsinstanz „attached" wird.

**Einschätzung:**

- **Nutzen: mittel.** Echte Nische (Assembly-/Embedded-Debugging), aber eine
  reale und in der eigenen Plugin-Liste bereits angelegte Domäne — `dap.nvim`
  existiert für genau elf Debug-Adapter-Targets.
- **Umsetzbarkeit: mittel, aber der im Konzept skizzierte Mechanismus ist der
  falsche.** Eine zweite, per Terminal gestartete und „attachte" nvim-Instanz
  ist unnötig komplex (Prozessmanagement, IPC, zwei Zustände synchron halten)
  für ein Problem, das das Debug Adapter Protocol bereits löst: DAP kennt
  `readMemory`/`writeMemory`-Requests (`supportsReadMemoryRequest`), die
  GDB-/LLDB-/Cortex-Debug-basierte Adapter typischerweise unterstützen.
  `dap.nvim` registriert bereits Adapter für mehrere dieser Targets
  ([README.md]($REPOS_DIR/dap.nvim/README.md)) — ein Speicher-Viewer ist damit
  ein **Feature auf der bestehenden DAP-Session**, kein zweiter Prozess: ein
  Floating-Window (über `ui.kit`, falls als Cross-Plugin-Feature gebaut) mit
  Hex/Bit-Darstellung, das per Timer/`on_click` `readMemory` pollt und
  `writeMemory` für Edits nutzt.
- **Aufwand: Mittel.** Kein Machbarkeitskonzept nötig — die Bausteine
  (DAP-Session, Hex-Rendering, Klick-Edit) sind einzeln simpel, die Summe ist
  eine reale Baustelle (Endianness, Formatwahl, Undo-Semantik bei Edits).
- **Fit: Feature in `dap.nvim`**, nicht eigenständiges Plugin und nicht der
  Zwei-Prozess-Ansatz aus der Notiz. `debugging.nvim` (editor-seitige
  Inspektion ohne Adapter) ist explizit die falsche Seite laut eigener
  Abgrenzung im README der beiden Plugins.

---

## Better_TODOComments.md — TODO-Kommentar-Ersatz

**Idee:** `todo-comments.nvim` ersetzen. Konkreter Schmerzpunkt: Custom-Tags
wurden nicht nur in Kommentaren, sondern überall (auch Logfiles) und als
Teilstring hervorgehoben (`DEBUG:` triggerte auch in `debugging`).

**Einschätzung:**

- **Nutzen: hoch.** Kein Meinungsbild, sondern ein dokumentierter, echter
  Bug im Alltagswerkzeug, der laut Notiz nur mit Monkeypatches umgehbar war.
- **Umsetzbarkeit: hoch — die Bug-Ursache ist klar benennbar und behebbar:**
  1. **Kein Wortgrenzen-Check.** Ein Tag-Pattern ohne `%f[%w]TAG%f[%W]`
     (Lua-Frontier-Pattern) matcht `DEBUG` als Teilstring von `DEBUGGING`.
     Trivial zu fixen.
  2. **Keine Beschränkung auf Kommentar-Knoten.** Wer treesitter-Queries auf
     `comment`-Nodes statt Zeilen-Regex über den ganzen Buffer-Text matcht,
     bekommt „nur in echten Kommentaren" geschenkt — und Logfiles (eigenes
     Filetype, meist ohne Parser) fallen dann ohnehin nicht unter „Code",
     sondern bräuchten höchstens einen eigenen, expliziten Opt-in.
  Beides ist Standardtechnik, keine Forschung.
- **Aufwand: Klein–Mittel für ein MVP** (Scan + Highlight + Quickfix-Liste je
  Tag), **Mittel–Groß für volle Parität + Cross-Features** (Picker-Anbindung
  über `pickers.nvim`, Sprung über `lib.nvim`).
- **Fit: eigenständiges Plugin.** Weder `documentation.nvim` (scannt
  strukturierte Doc-Kommentare wie `@module`/`@brief`, nicht freie
  Ad-hoc-Tags) noch `markdown.nvim` (Markup, nicht Quellcode-Kommentare)
  decken diese Domäne ab — der Name `comments.nvim` aus der Notiz ist treffend
  und kollidiert nicht mit vorhandenen Repos.

---

## IDEAS.md — vier Einzelideen

### #1 Externe Deps durch Eigenimplementierungen ersetzen

Meta-Aufgabe, kein Plugin: „Auflistung aller externen Deps + Aufwandsschätzung"
ist eine wiederkehrende Bestandsaufnahme, kein Konzept. **Nutzen: mittel**
(verhindert Wildwuchs), **Aufwand: klein** für den Audit selbst — aber ohne
Ergebnis dieser Datei nicht bewertbar, welche Deps überhaupt gemeint sind.
Empfehlung: als eigene, kurze Bestandsaufnahme (Tabelle: Repo → externe Dep →
bereits ersetzt? → Aufwand) nachziehen, kein Plugin-Vorschlag.

---

### #2 Wezterm-Integration (Tabs steuern, Wezterm-Statusline durch nvim ersetzen)

**Deckt sich inhaltlich mit der leeren [`TMUX_WEZTERM_USW.md`](#tmux_wezterm_uswmd--leer)** —
sollte dorthin konsolidiert werden statt an zwei Stellen zu leben.

- **Nutzen: mittel** — sinnvoll nur, wenn Wezterm tatsächlich der primäre
  Terminalemulator ist (nicht verifiziert, aber plausibel angesichts des
  Dateinamens).
- **Umsetzbarkeit: mittel.** `wezterm cli` ist scriptbar (`list --format json`,
  `set-tab-title`, `spawn-tab`) und über `vim.system()` ansprechbar — kein
  Neuland, aber ein Enable-Gate über `vim.env.TERM_PROGRAM == "WezTerm"` ist
  Pflicht, sonst bricht das Feature auf jedem anderen Terminal.
- **Aufwand: Mittel.**
- **Fit: Feature in `ui.nvim`s `tabline`-Modul**
  ([`lua/ui/tabline`]($REPOS_DIR/ui.nvim/lua/ui/tabline)), nicht eigenständiges
  Plugin — `ui.nvim` besitzt bereits die Tabline-Rendering-Infrastruktur, ein
  Wezterm-Bridge-Adapter ist ein weiterer Renderer/Datenlieferant dort, kein
  neues UI-Subsystem.

---

### #3 Screenkey-Integration

→ siehe eigener Abschnitt [Screenkey.md](#3-screenkey-integration), dort
ausführlich behandelt. Kurzfassung: ja, aber als `ui.nvim`-Feature.

---

### #4 `lazy.nvim` nachbauen ("moderner, performanter, sicherer")

- **Nutzen: niedrig.** `lazy.nvim` ist aktiv maintained, extrem verbreitet,
  Performance ist längst auf State-of-the-Art-Niveau (Bytecode-Caching,
  Profiler eingebaut). Kein in der Notiz genannter konkreter Mangel, den ein
  Neubau beheben würde.
- **Umsetzbarkeit: niedrig relativ zum Nutzen.** Ein Plugin-Manager ist eine
  der riskantesten Kategorien überhaupt (lädt vor allem anderen, jeder Bug
  bricht den kompletten Start) — Reimplementierung „from scratch" für einen
  nicht belegten Zusatznutzen.
- **Aufwand: Sehr groß.**
- **Empfehlung: verwerfen.** Falls es einen konkreten Kritikpunkt gibt,
  gehört der als Issue/PR gegen `folke/lazy.nvim` selbst adressiert, nicht als
  Parallelentwicklung. Größtes Aufwand/Nutzen-Missverhältnis aller zwölf
  Dateien.

---

## TMUX_WEZTERM_USW.md — leer

Die Datei enthält nur eine Leerzeile. **Keine Idee bewertbar.** Der
Dateiname deckt sich inhaltlich mit
[`IDEAS.md` #2](#2-wezterm-integration-tabs-steuern-wezterm-statusline-durch-nvim-ersetzen) —
naheliegend, dass hier ursprünglich die ausführlichere Fassung (Tmux **und**
Wezterm, „usw.") entstehen sollte.

**Empfehlung:** entweder mit Inhalt aus `IDEAS.md` #2 befüllen und dort
löschen (eine Quelle der Wahrheit), oder die Datei entfernen, falls die Idee
komplett in `ui.nvim`s Tabline-Backlog aufgeht. Eine leere Roadmap-Datei ohne
Folgeaktion sollte nicht dauerhaft im `IDEAS/`-Ordner liegen bleiben.

---

## blueprint.nvim.md — Template-Bibliothek (Meta-Review)

Diese Datei ist bereits eine vollständige, 630 Zeilen lange Konzeptausarbeitung
mit eigener Bewertung, Architektur, Phasenplan und Risikotabelle — kein Rohkonzept.

**Meta-Verdict: Stimme der Selbsteinschätzung zu.**

- **Nutzen: hoch, mit der von der Notiz selbst genannten Einschränkung**
  (steht und fällt mit Trefferquote/Pflege der Bibliothek — korrekt erkannt).
- **Umsetzbarkeit: hoch.** Die referenzierten `lib.nvim`-/`pickers.nvim`-Bausteine
  existieren tatsächlich (Cache, Composer, Picker-Engine-Erkennung) — keine
  offene technische Frage im MVP.
- **Aufwand: klein fürs MVP** (die Notiz schätzt „ein Wochenend-Projekt" —
  plausibel angesichts der Wiederverwendung), **laufend für Content-Pflege**
  (korrekt als eigentlicher Kostenpunkt identifiziert, nicht Code).
- **Eine konkrete Ergänzung:** Die Notiz identifiziert selbst „Bibliothek
  bleibt leer" als **größtes Risiko** (`Risiken`-Tabelle), aber der
  Phasenplan platziert `:Blueprint new` (das Feature, das genau dieses
  Risiko mindert) erst in **Phase 1**, nicht Phase 0. Empfehlung: `:Blueprint
  new` in Phase 0 vorziehen, auch wenn das MVP dadurch minimal größer wird —
  sonst wächst die Bibliothek in der kritischen ersten Nutzungsphase nicht,
  und genau das ist laut eigener Risikoanalyse der Punkt, an dem solche
  Projekte sterben.
- **Fit: eigenständiges Plugin** — bereits korrekt begründet (maschinen-
  übergreifender Nutzen, eigenes `:checkhealth`-Bedürfnis, `pickers.nvim` als
  Engine-Dependency statt Config-zu-Plugin-Kopplung).

---

## git_nvim.md — Git-Konsolidierung

**Idee:** Prüfen, ob externe Git-Plugins durch ein eigenes, zentral
orchestrierendes `git.nvim` ersetzt/gebündelt werden sollten — nach dem
Muster von `filetree.nvim`/`dap.nvim`. Die Datei selbst ist nur eine
7-zeilige Arbeitsanweisung, kein Konzept.

**Einschätzung (eigene Recherche, da die Notiz selbst keine Analyse enthält):**

Ein Grep über die Config bestätigt den in der Notiz vermuteten Zustand: die
Git-Integration ist tatsächlich über mindestens fünf Orte verstreut —
[`nvim/lua/config/lazygit/`, now gitsuite.nvim]($REPOS_DIR/gitsuite.nvim),
[`nvim/lua/autocmds/git/`]($NVIM_CONFIG_DIR/lua/autocmds/git),
[`nvim/lua/bindings/mappings/git.lua`, now gitsuite.nvim]($REPOS_DIR/gitsuite.nvim),
[`nvim/lua/config/menu/git.lua`, now gitsuite.nvim]($REPOS_DIR/gitsuite.nvim),
[`nvim/lua/plugins/git.lua`]($NVIM_CONFIG_DIR/lua/plugins/git.lua) —
exakt das Muster „stateful Subsystem über den Host verstreut", das laut
`test.md`s eigener Begründung (§3 dort) bereits zweimal (`dap.nvim`,
geplant `test.nvim`) den Ausschlag für eine Auslagerung gegeben hat.

- **Nutzen: hoch** — entfernt reale, belegte Config-Streuung.
- **Umsetzbarkeit: hoch**, aber **nur wenn der Scope „Konsolidierung", nicht
  „Neubau" ist.** `gitsigns.nvim`, Lazygit-Terminal-Integration und ggf.
  Diffview sind ausgereifte externe Tools — sie nachzubauen wäre derselbe
  Fehler wie bei `IDEAS.md` #4 (`lazy.nvim`). Richtig dimensioniert bedeutet
  das: ein `git.nvim` nach dem `debugging.nvim`-Muster (`:Debug {category}
  {action}` als ein Dispatcher über mehrere fremde Tools) — hier also `:Git
  {category} {action}` als **ein Command über bestehende externe Plugins**,
  das die fünf oben genannten verstreuten Config-Orte bündelt, nicht deren
  Funktionalität reimplementiert.
- **Aufwand: Mittel** — Größenordnung vermutlich unter `test.nvim`s
  geschätzten ~2.500 Zeilen/27 Dateien, da weniger Adapter-Vielfalt, aber
  ohne eigenen Line-Count-Audit nicht seriös genauer zu beziffern.
- **Fit: eigenständiges Plugin**, aber die in der Notiz selbst geforderte
  ausführliche Analyse (nach `NEW_PROJECT.md`-Leitlinie, mit Ist-Zustand-
  Tabelle wie in `test.md`/`spec.nvim.md`) ist mit diesem Report **nicht**
  erledigt — dieser Abschnitt bestätigt nur, dass sich die Tiefenanalyse
  lohnt, ersetzt sie aber nicht. Empfehlung: als eigene Folgeaufgabe mit der
  gleichen Methodik wie `test.md` durchziehen.

---

## health.md — `:checkhealth`-Erweiterung

**Idee:** `:checkhealth` erweitern, evtl. etwas wie „das Info-Tag in
`nvim/after`" dorthin übertragen und ausbauen.

**Einschätzung:**

- **Klärungsbedarf zuerst:** Ein Scan von
  [`nvim/after/`]($NVIM_CONFIG_DIR/after) findet aktuell
  **keine** Datei, die zu „Info-Tag" passt (nur `after/queries/**` für
  Treesitter-Textobjects). Entweder ist das seither entfernt worden, oder
  gemeint ist etwas anderes (z. B. das `:h`-Tags-Dateiformat, oder
  `vim.health.info()`-Aufrufe innerhalb bestehender `health.lua`-Module). Ohne
  diese Klärung ist der Kern der Idee nicht bewertbar.
- **Ein Punkt lässt sich unabhängig davon einschätzen:** Natives `:checkhealth`
  ohne Argument aggregiert bereits **automatisch alle registrierten
  Health-Provider** in einem Report — und jedes eigene Plugin liefert laut
  `NEW_PROJECT`-Checkliste bereits ein eigenes `:checkhealth <name>` (belegt
  z. B. in `blueprint.nvim.md`s Checkliste, `test.md`s
  Dokumentationspflichten-Abschnitt). Ein „Fleet-weites Health-Dashboard" für
  die ~20 Geschwister-Plugins existiert damit in gewisser Form bereits
  kostenlos über die native `:checkhealth`-Aggregation — geprüft ist das
  nicht, es lässt sich aber ohne Zusatzcode verifizieren (`:checkhealth`
  einmal ohne Argument gegen die volle Config laufen lassen).
- **Falls der eigentliche Wunsch eine schönere/gefilterte Übersicht ist**
  (statt reinem Text-Report): das wäre ein `ui.kit`-Viewer über die
  `vim.health`-Reportdaten — wieder ein Fit für `ui.nvim`, kein neues Plugin.
  `insights.nvim` scheidet aus, weil dessen „automatische Checks" (Git-
  Konflikte, unused imports, verwaiste Dev-Server) auf **ein** Projekt
  bezogen sind, nicht auf die eigene Plugin-Flotte
  ([README.md]($REPOS_DIR/insights.nvim/README.md)).
- **Aufwand/Nutzen:** ohne Klärung der Grundfrage nicht seriös bezifferbar.

---

## slots.nvim.md — nummerierte Datei-Slots (Meta-Review)

Bereits eine vollständige Selbstanalyse mit klarer Handlungsempfehlung:
**kein neues Repo**, sondern Prüfung, ob die Funktion in ein bestehendes
Plugin wandert (`buffer-ctx.nvim`, `sessions.nvim`, `pickers.nvim`,
`filetree.nvim` als Kandidaten).

**Meta-Verdict: Stimme zu, mit einer Präzisierung zum stärksten Kandidaten.**

- Verifiziert: `buffer-ctx.nvim` hat tatsächlich ein extmark-basiertes
  `mark/`-Modul mit eigenem Feature-Dokument
  ([`docs/FEATURES/MARK.md`]($REPOS_DIR/buffer-ctx.nvim/docs/FEATURES/MARK.md))
  und sogar einen eigenen ROADMAP-Eintrag `anchor-stable-marks.md` — die
  Vermutung der Notiz ist also korrekt belegt.
- **Aber:** `buffer-ctx.nvim`s Marks sind **pro Buffer** (Zeilen markieren +
  gemeinsam yanken), nicht **projekt-/dateiübergreifend numeriert
  navigierbar** wie im Slots-Konzept gefordert (Slot 3 → Datei X, egal welcher
  Buffer gerade offen ist). Gleiche Technik (Extmarks), andere Funktions-
  ebene. Eine 1:1-Erweiterung ist also **nicht** der Nulllinie-Fall, den die
  Notiz suggeriert — es bräuchte trotzdem eine neue, kleine
  Cross-File-Registry obendrauf, nur eben nicht die Extmark-Technik neu
  erfunden.
  - Realistischste Landung bleibt daher eher **`pickers.nvim`** (Frecency-
    Liste ist konzeptionell bereits „Dateien, an denen ich gerade arbeite",
    fehlt nur die manuelle Fixierung auf eine Nummer) oder **`sessions.nvim`**
    (Persistenzmuster passt direkt) — wie von der Notiz selbst als
    Alternativen genannt.
- **Aufwand:** Quick Win für die Entscheidung selbst (wie von der Notiz
  taxiert), Groß nur im — nicht empfohlenen — Neubau-Fall.
- **Fit: kein eigenständiges Plugin.** Bestätigt.

---

## spec.nvim.md — Test-Runner-Engine (Meta-Review)

> **2026-09-20:** `spec.nvim.md` ist zusammen mit `test.md` in
> [testing.md](testing.md) aufgegangen (dort Teil A; Teil C/D ergänzen
> synthetische Feature-Tests und die überarbeitete Zielarchitektur samt
> Meilensteinplan). Dieser Meta-Review bezieht sich auf den Stand davor.

Umfangreichste der zwölf Dateien (15 Abschnitte, Ist-Zustand-Scan über 19
Repos, Dialekt-Analyse, Architektur, Migrationsplan). Eigenes Fazit: „Ja,
lohnt sich" — mit ausdrücklich benannten Risiken (NIH-Falle, Scope-Explosion,
`mini.test`-Alternative).

**Meta-Verdict: Stimme zu, mit Fokus auf die Reihenfolge.**

- Die Zahlen (16 handgerollte Harnesses in 4 Dialekten, ~550 Spec-Dateien)
  sind eine Bestandsaufnahme, keine Behauptung — überzeugend als Nutzen-
  Beleg, weil das Kernproblem (P1: erster Fehlschlag killt die Datei) ein
  objektiver Mangel ist, kein Geschmacksurteil.
- **Größtes reales Risiko ist korrekt benannt:** die zirkuläre Abhängigkeit
  `spec.nvim` ↔ `lib.nvim` (§15) — ein `lib.nvim`-Bug könnte seinen eigenen
  Test verstecken, wenn `spec.nvim` selbst auf `lib.nvim` aufbaut, um
  `lib.nvim` zu testen. Die vorgeschlagene Gegenmaßnahme (minimaler
  Bootstrap-Harness in `lib.nvim` für Kernmodule) ist notwendig, sollte aber
  **vor** Phase 0 tatsächlich entschieden und nicht nur als offene Frage
  stehen bleiben — sonst beginnt die Umsetzung mit einer ungelösten
  Grundsatzfrage.
- **Phase 0 als Falsifikationstest** (muss `lib.nvim`s 137 Specs unverändert
  grün fahren) ist der richtige Aufbau — ein Scope dieser Größe verdient
  einen harten Abbruchpunkt früh, nicht erst nach Investition in §9–§11.
- **Aufwand: Groß, aber korrekt phasiert** — Phase 0–5 sind das eigentliche
  Produkt, alles ab §9 (Cache/Affected-Selection) ist wertvoll, aber
  optional und darf laut eigener Aussage nie Bedingung für den Nutzen der
  frühen Phasen werden. Diese Selbstdisziplin ist der Grund, warum die
  Größe hier kein Ablehnungsgrund ist (anders als bei `IDEAS.md` #4).
- **Fit: eigenständiges Plugin.** Bestätigt — keine bestehende Alternative
  deckt „läuft alle 4 vorhandenen Dialekte weiter" ab, das ist der
  entscheidende Unterschied zu `mini.test`.

---

## test.md — neotest-Auslagerung (Meta-Review)

> **2026-09-20:** `test.md` ist in [testing.md](testing.md) aufgegangen
> (dort Teil B, inhaltlich unverändert).

Bereits eine vollständige Ist-Zustand-Analyse mit vier konkret benannten,
unabhängig vom Auslagerungsthema bestehenden Bugs im heutigen Code
(Adapter-Split-Brain, tote Adapter-Dateien, dreifache Keymap-Registrierung).
Eigenes Fazit: „Ja, es macht Sinn."

**Meta-Verdict: Stimme zu — das ist der am konkretesten belegte Fall der
gesamten Liste.**

- Anders als bei den meisten anderen Dateien ist hier nicht nur die
  Auslagerung selbst bewertet, sondern auch **aktive Fehlfunktion im
  Ist-Zustand** nachgewiesen: `neotest-python`, `neotest-rust`,
  `neotest-jest` sind installiert, aber nie aktiviert — Python-/Rust-/
  Jest-Projekte bekommen laut Analyse aktuell **keine** Testerkennung, obwohl
  die Abhängigkeiten dafür bereits geladen werden. Das ist ein eigenständiger
  Bugfix-Grund, unabhängig davon, ob die Auslagerung passiert.
- **Aufwand: Mittel** (~2.500 Zeilen/27 Dateien, vergleichbar mit `dap.nvim`s
  ursprünglichem Umfang) — realistisch geschätzt, kein Neubau, sondern
  Konsolidierung dreier paralleler Adapter-Implementierungen zu einer.
  Genau dieses Muster (Konsolidierung statt Neubau) ist auch die richtige
  Vorlage für [`git_nvim.md`](#git_nvimmd--git-konsolidierung) oben.
- **Fit: eigenständiges Plugin.** Bestätigt, gleiche Kategorie wie
  `dap.nvim`/`lsp.nvim` (stateful Subsystem, keine deklarativen Settings).

---

## Priorisierungsvorschlag

Absteigend nach Nutzen/Aufwand-Verhältnis, unter Berücksichtigung der
Fit-Empfehlungen oben:

2. **`comments.nvim`** (Better_TODOComments.md) — behebt einen dokumentierten
   Alltags-Bug, klar umrissener Scope.
3. **`test.nvim`-Auslagerung** — bereits vollständig geplant, deckt zusätzlich
   einen aktiven Bug auf (Python/Rust/Jest ohne Testerkennung).
4. **`blueprint.nvim`** — MVP klein, aber `:Blueprint new` in Phase 0
   vorziehen (s. o.), sonst greift das eigene Leer-Bibliothek-Risiko.
5. **`git.nvim`** — hoher belegter Nutzen (5 verstreute Config-Orte), aber
   erst nach einer echten Tiefenanalyse wie bei `test.md` beginnen, nicht
   direkt bauen.
6. **`slots`-Entscheidung** — Quick Win: einmal klären (`pickers.nvim` vs.
   `sessions.nvim`), kein Bau nötig.
7. **`spec.nvim`** — größter Nutzen der Liste, aber bewusst als Mehrjahres-
   projekt geplant; zirkuläre `lib.nvim`-Abhängigkeit vor Phase 0 entscheiden.
8. **Arbeitsspeicher-Viewer → `dap.nvim`-Feature** — Nische, aber sauber
   einordenbar, kein eigenes Konzept nötig.
9. **`health.md`** — erst klären, was „Info-Tag" meint, dann neu bewerten.
    zusammenführen, dann als `ui.nvim`-Tabline-Feature einplanen.

---

