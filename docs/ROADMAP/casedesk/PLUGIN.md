# casedesk — Auslagerung in ein eigenes Plugin-Repo

Implementierungsplan für den Umzug von `lua/bindings/usrcmds/case/` in
`StefanBartl/casedesk.nvim`.

> **Repo steht** (2026-09-04): <https://github.com/StefanBartl/casedesk.nvim>
> — privat, leer, kein Auto-Init (kein README/LICENSE/gitignore von GitHub,
> damit die erste Struktur vollständig aus diesem Plan kommt und nicht mit
> einem generierten Initial-Commit kollidiert).

Nicht zu verwechseln mit [EXTRACTION.md](EXTRACTION.md) — das ist die
Artefakt-Extraktion (Support-Info/Activity-Stream-Parser), ein Feature.
Hier geht es um die Repo-Extraktion.

**Verbindliche Vorgaben** für alles, was hier gebaut wird:
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists` — `gates/NEW_PROJECT.md`
beim Anlegen, `gates/REVIEW.md` vor jedem Merge, `regeln/` beim Schreiben.
Wo dieser Plan davon abweicht, ist die Abweichung markiert und begründet.

**Laufender Arbeitsstand:**
`docs/ROADMAP/personal/All/FINISH/HANDOVER_casedesk-plugin.md` — was erledigt
ist, was als Nächstes ansteht, wo eine unterbrochene Sitzung wieder ansetzt.

**Messungen, Benchmarks, Werkzeuge**, die nicht ins Plugin-Repo gehören:
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/`.

---

## Table of content

- [1. Ausgangslage](#1-ausgangslage)
- [2. Zielbild](#2-zielbild)
- [3. Entscheidungen](#3-entscheidungen)
- [4. Phasen](#4-phasen)
- [5. Risiken](#5-risiken)
- [6. Offene Fragen](#6-offene-fragen)
- [7. Bereiche — der Bestand ist nicht mehr nur SAP](#7-bereiche--der-bestand-ist-nicht-mehr-nur-sap)
- [8. Schwesterplugins](#8-schwesterplugins)
- [9. Feature-Backlog](#9-feature-backlog)
- [Literatur und Referenzen](#literatur-und-referenzen)

---

## 1. Ausgangslage

Gemessen, nicht geschätzt (2026-09-04):

| Was | Umfang |
| --- | --- |
| Lua-Dateien unter `lua/bindings/usrcmds/case/` | 39 |
| Zeilen Lua | 11.295 |
| Größte Datei | `ui.lua` (3.502) |
| Danach | `init.lua` (603), `solution.lua` (520), `config.lua` (488), `doctor.lua` (437), `extract/stream.lua` (433) |
| Markdown-Templates (`templates/*.md`) | 5 |
| Modul-eigene Docs | `README.md`, `docs/FEATURES.md` |
| Konzept-Docs außerhalb (`docs/ROADMAP/casedesk/`) | 7 Dateien, ~166 KB |
| Bindings-Docs außerhalb (`docs/NOTES/casedesk/`) | 4 Dateien, ~57 KB |

### 1.1 Was das Modul von außen braucht

17 `lib.nvim`-Module, sonst nichts:

```
bindings.autocmd  bindings.keymap  bindings.usercmd.composer
cross.copy_to_clipboard  cross.fs.mutate  cross.open_default  cross.uv.spawn_capture
fs.collect_recursive  fs.is_valid_filename  fs.json  fs.mkdirp  fs.read
fs.write.append  fs.write.to_file
net.curl  notify  system.env  ui.kit
```

Keine Third-Party-Abhängigkeit, kein `pickers.nvim`, kein `images.nvim` im
Code (`:Image redact` ist laut ROADMAP.md ein *künftiger* Berührungspunkt,
heute existiert er nicht). Das ist die gute Nachricht: die Dependency-Lage
ist exakt die von `open.nvim`, und dessen Repo-Layout ist damit direkt als
Vorlage brauchbar.

### 1.2 Was das Modul von außen konsumiert wird

Genau drei Stellen — überschaubar:

| Datei | Zugriff |
| --- | --- |
| `lua/bindings/usrcmds/init.lua:7` | `require("bindings.usrcmds.case").enable()` |
| `lua/bindings/mappings/custom.lua:28` | `case.resolve` (pcall, session-aware Save-Keymap) |
| `lua/wkdnvchad/ui/statusline/modules/casedesk/init.lua` | `case.sla`, `case.config`, `case.meta`, `case.resolve` (4 Stellen, davon 2 pcall) |

Dazu vier reine Kommentar-Erwähnungen im `bindings_explorer` — keine
Kopplung, nur Querverweise im Fließtext.

### 1.3 Was struktureller Umbau ist, nicht Verschieben

`config.lua` ist heute eine **flache Modultabelle ohne `setup()`**: 30+
Konsumenten machen `local config = require(...case.config)` und lesen
`config.cases_root` direkt. Das funktioniert, solange die Werte
Config-Konstanten in einer privaten Config sind — als Plugin braucht es
einen Weg, sie von der Spec aus zu setzen. Das ist der einzige Punkt des
gesamten Umzugs, an dem echte Logik entsteht statt Pfade umzuschreiben.

Betroffen sind 30 `M.*`-Felder plus `M.state_dir()`, davon vier
**abgeleitete** Pfade, die nach einem `setup()` neu berechnet werden müssen:

```
repo_root  →  root  →  cases_root
           →  workflow_templates_dir
           →  sla_doc_path
```

### 1.4 Der Bestand ist bereits mehrbereichig — casedesk weiß es nur nicht

Beim Sichten der echten Datenlage (2026-09-04) aufgefallen, und wichtig
genug, um den Config-Umbau in Phase 2 zu formen: unter
`$REPOS_DIR/WKDBook-Tricentis/Cases/` liegen **zwei** Case-Bäume, nicht
einer.

```
Cases/
  SAP_Support/Cases/{Open,Closed,Solved,T2}/<Nr>/    28 Cases
  CS/{Open}/<Nr>/                                     2 Cases
  Solutions/{NOT_SAP,Tosca_OSV,Solution_TEMPLATE.md}
```

Vier Befunde daraus:

1. **`CS/` ist flacher als `SAP_Support/`** — ohne die
   `Cases/`-Zwischenebene. Die gibt es bei SAP, weil `SAP_Support/`
   Geschwister hat (`Notes/`, `Terminologie/`); `CS/` hat keine.
2. **Die CS-Cases sind echte casedesk-Cases** — `.case.json` mit
   demselben Schema (`blueprint`, `case`, `company`, `created`, `links`,
   `name`, `notes`, `title`, `year`), `assets/`, `Replies/`, `Research/`,
   `Notes.md`, `Summary.md`. Kein Fremdformat, keine Migration nötig.
3. **`registry.lua` findet sie trotzdem nicht.** Es scannt ausschließlich
   `config.state_dir(state)` = `cases_root/<state>`, und `cases_root` ist
   hart `Cases/SAP_Support/Cases`. Alles unter `CS/` ist für `:Case`,
   `:Cases`, `:Cases doctor` und den SLA-Wächter heute unsichtbar.
4. **`T2` ist ein State auf der Platte, aber nicht in `config.states`.**
   Derselbe Effekt im SAP-Baum selbst: der eine Case unter
   `SAP_Support/Cases/T2/996010` ist unsichtbar. Und `CS/` hat nur
   `Open` — die State-Menge ist also **pro Bereich verschieden**.

Konzept und Umsetzung: [§7](#7-bereiche--der-bestand-ist-nicht-mehr-nur-sap).

### 1.5 `EngineLab/` — Wissensquelle, kein Case-Bereich

`$REPOS_DIR/WKDBook-Tricentis/EngineLab/` ist eine Engine-Wissensbasis:
pro Tosca-Engine (API, Database, Excel, HTML_XBrowser, Image_OCR, Mail,
Mainframe, Mobile, PDF, SAP, TextStream, UIA_Desktop) ein
`00_Engine.md`-Steckbrief und teils `01_Rezepte.md`, dazu `Templates/`
(Engine-Steckbrief, Fehlerbild, TestCase-Rezept) und `Testobjekte/`
(lauffähige Fixtures: `api/server.js`, `db/*.sql`, `excel/*.xlsx`,
`html/*.html`).

Keine Cases, also **kein Bereich** im Sinne von §7. Für casedesk ist es
dieselbe Sorte Ding wie `Notes/` und `Terminologie/`: eine Quelle, die
`:Tricentis` bereits mit abdeckt, weil dessen Befehle auf `repo_root`
laufen, nicht auf `cases_root`. Zu prüfen ist nur, ob `command_topics`
und `terminology.lua` es explizit kennen sollten — und ob der
KI-Faktenblock aus `extract/facts.lua` den passenden Engine-Steckbrief
zum `sap_component`/Engine eines Cases mit anbieten kann. Das ist ein
Feature-Kandidat für ROADMAP.md, kein Umzugs-Thema.

---

## 2. Zielbild

Struktur nach `gates/NEW_PROJECT.md` §2 (NEW-07 bis NEW-10), aufgefüllt
mit dem, was `open.nvim` als bereits gelebte Fassung derselben Vorgaben
zeigt:

```
casedesk.nvim/
  lua/casedesk/
    init.lua              -- setup(opts); heutige case/init.lua
    config/
      init.lua            -- NEW-27: Einstieg (setup/get/rebuild_derived)
      DEFAULTS.lua        -- NEW-27: heutige case/config.lua als Defaults
    bindings/
      usrcmds.lua         -- NEW-08: die Composer-Verben aus init.lua
      keymaps.lua         -- NEW-08/21/22: heute keine, Datei trotzdem
      autocmds.lua        -- NEW-08: der FocusGained-Hook aus sla/notify.lua
    @types/init.lua       -- NEW-09, plus je Unterebene eine weitere
    health.lua            -- NEW-10: :checkhealth casedesk
    apply.lua attachments.lua blocks.lua blueprint.lua commands.lua
    detect.lua doctor.lua export.lua ki.lua linkcheck.lua links.lua
    marks.lua meta.lua migrate.lua normalize.lua ocr.lua plan.lua
    query.lua registry.lua render.lua replygate.lua resolve.lua
    similar.lua solution.lua stream_format.lua templates.lua
    terminology.lua timeline.lua ui.lua
    extract/{doclinks,facts,stream,supportinfo}.lua
    sla/{init,clock,notify,stream}.lua
    templates/{KiPrompt,Notes,Reply,Research,Solution,Summary}.md
  doc/casedesk.txt        -- NEW-13: vimdoc, englisch
  docs/
    ROADMAP.md            -- NEW-14: kuenftige Features
    BINDINGS.md           -- NEW-15: alle Usercmds/Keymaps/Autocmds
    FEATURES.md CONCEPT.md EXTRACTION.md SLA.md SESSIONS.md
    HANDOVER.md PTO.md PLUGIN.md
    installation.md configuration.md
  scripts/gen_map.lua     -- NEW-20: documentation.nvim
  TESTS/{run,harness}.lua *_spec.lua
  .github/workflows/ci.yml
  .gitattributes .gitignore .luacheckrc .luarc.json stylua.toml
  README.md               -- NEW-11/12: englisch, ASCII-Art, Badges, ToC
```

Namespace: `bindings.usrcmds.case.*` → `casedesk.*`. Kein Zwischenpfad,
kein `casedesk.case.*`.

### 2.1 Was die Checkliste gegenüber dem ersten Entwurf ändert

Punkte, an denen `gates/NEW_PROJECT.md` etwas anderes verlangt, als
naheliegend war — hier festgehalten, damit sie beim Bauen nicht wieder
verloren gehen:

- **Keine `LICENSE`, keine Lizenzverweise** (NEW-06). Der erste Entwurf
  dieses Plans sah MIT vor, wie `lib.nvim` es hat. Falsch für ein neues
  Repo — und damit fällt auch das License-Badge aus dem sonst üblichen
  README-Badge-Satz weg.
- **`docs/map/` wird nicht committet** (NEW-20), und `--check` läuft
  deshalb **nicht** in CI — auf einem frischen Checkout liegt nichts da,
  gegen das verglichen werden könnte. `scripts/gen_map.lua` kommt
  trotzdem rein, aus `documentation.nvim/docs/REUSE.md`.
- **`bindings/` als eigener Ordner** (NEW-08) mit drei Dateien, auch wo
  eine davon heute leer wäre. casedesk registriert seine Verben derzeit
  direkt in `init.lua` — das wandert nach `bindings/usrcmds.lua`, und
  `init.lua` wird der schmale `setup()`-Einstieg, der es laut Vorgabe
  sein soll.
- **Cross-Plattform von Anfang an** (NEW-30/31), statt Windows-only
  auszurufen. Siehe [§3.7](#37-windows-only-oder-cross-plattform).

### 2.2 Nachtrag: die Checkliste hat einen neuen Abschnitt 3

**Am 2026-09-04 während Phase 0 aufgefallen** (ein `git pull` im
Checklisten-Repo brachte sie): `gates/NEW_PROJECT.md` hat seit der
LuaLS-Erhebung vom 2026-09-02 einen Abschnitt „Diagnosen und Tests von
Anfang an", `NEW-36` bis `NEW-46`, mit eigener Regelschicht
(`regeln/LUA_NVIM.md § LuaLS-Diagnosen`, `LLS-01`…`LLS-43`) und einem
Dossier (`luals/`). Der erste Phase-0-Commit war davor geschrieben und
musste nachgebessert werden. Was daraus für casedesk gilt:

- **`.luarc.json`**: `workspace.library` bleibt ungesetzt (NEW-36,
  `LLS-01` — der Schlüssel *ersetzt* die Injektion des LSP-Setups statt
  sie zu ergänzen). `workspace.ignoreDir` **muss** gesetzt sein
  (NEW-37, `LLS-03`) — für casedesk besonders relevant, weil während des
  Parallelbetriebs (§3.8) tatsächlich eine zweite Kopie desselben Codes
  existiert, und genau solche Kopien haben in der Erhebung dreistellige
  Phantomzahlen erzeugt.
- **Tests laufen über plenary/busted**, nicht über einen selbstgebauten
  Harness: `TESTS/minimal_init.lua` plus `scripts/test.sh` (NEW-39),
  beide Abhängigkeiten über Env-Variable, `.deps/` oder Nachbar-Checkout
  auflösbar, und ein **lautes** Scheitern, das alle drei Wege nennt
  (NEW-40). Das ändert Phase 5 gegenüber dem ersten Entwurf, der
  `open.nvim`s framework-freien Runner übernehmen wollte.
- **Nullmessung vor dem ersten Push** (NEW-44), Werkzeug:
  `nvim/scripts/luals-scan/`. Bei einem Ergebnis von 0 **zweimal messen**
  (`LLS-07`) — ein Befund kann in einer unveränderten Datei erst
  auftauchen, wenn die anderen weg sind.
- **In Testdateien**: `need-check-nil` im Dateikopf unterdrücken, mit
  Begründung (NEW-41, `LLS-42`); Test-Doubles über `vim.*` erzeugen
  `duplicate-set-field` und werden pro Zeile unterdrückt (NEW-42); kein
  Testfall, der sich selbst überspringt (NEW-43).

Nicht Teil dieses Umzugs, aber beim ersten Merge fällig: `gates/REVIEW.md`
komplett, inklusive Range-Support (NEW-23), Count-Support (NEW-25) und
Completion-Pflicht (NEW-26) für jedes Kommando.

---

## 3. Entscheidungen

Jeweils mit Empfehlung; abweichen ist billig, solange es vor Phase 2
passiert.

### 3.1 Wie wird `config.lua` konfigurierbar?

- **(A) In-place-Merge, Modultabelle bleibt.** `config.setup(opts)`
  schreibt User-Werte in dieselbe Tabelle und ruft danach
  `rebuild_derived()`. Alle 30 Konsumenten bleiben Zeichen für Zeichen
  unverändert.
- (B) `config.get()` überall. Sauberer im Sinne von "kein globaler
  Zustand", aber ein Diff über alle 39 Dateien ohne funktionalen Gewinn.

**Empfehlung: (A).** Der einzige Grund für (B) wäre mehrfaches `setup()`
zur Laufzeit — das gibt es nicht, lazy ruft `setup` einmal. (A) hält den
Umzugs-Diff auf "Pfade umgeschrieben", und genau das will man beim Review
einer 11k-Zeilen-Verschiebung sehen können.

Ein Detail, das (A) nicht geschenkt bekommt: `vim.tbl_deep_extend("force",
…)` **ersetzt** Listen, statt sie zu mergen. Für `states`,
`solution_statuses`, `version_watch`, `sla_active_priorities` und
`blueprints` ist das genau richtig (wer `states` setzt, will seine Liste,
nicht die Vereinigung). Es muss nur in `docs/configuration.md` stehen,
sonst ist es beim ersten Überschreiben eine Überraschung.

### 3.2 Wandern die Konzept-Docs mit?

`docs/ROADMAP/casedesk/` (CONCEPT, ROADMAP, EXTRACTION, SLA, SESSIONS,
HANDOVER, PTO, und diese Datei) beschreibt ausschließlich casedesk.

**Empfehlung: alle sieben plus diese Datei mit ins Repo**, unter
`docs/`. In der Config bleibt an ihrer Stelle ein Stub mit Zeiger auf das
Repo — dieselbe Behandlung wie bei der `lib.nvim`-Auslagerung. Grund: ein
Konzept, das den Code beschreibt, gehört neben den Code, sonst driften
beide (und die Doc-Links *im* Lua-Code zeigen dann auf einen Pfad, den
ein Fremd-Checkout gar nicht hat — heute stehen genau 7 solcher Verweise
in `config.lua`, `init.lua`, `sla/clock.lua`, `sla/init.lua`).

### 3.3 Und `docs/NOTES/casedesk/`?

Anders gelagert: `Usercmds.md`, `Keymaps.md`, `Autocmds.md` sind Teil des
**Bindings-Doku-Korpus der Config**, den `:Bindings check` gegen die
Plugin-Checkouts prüft. Das ist deren Zweck, nicht Plugin-Doku.

**Empfehlung: bleiben, wo sie sind.** `Workflow.md` (die Worked Examples)
ist der Grenzfall — es ist inhaltlich Plugin-Doku. Vorschlag: mitnehmen
nach `docs/WORKFLOW.md` im Repo, so wie `open.nvim` es hält, und in
`docs/NOTES/casedesk/` einen Zeiger hinterlassen.

Nebenbefund beim Sichten: es gibt **zwei** Command-Dokus —
`docs/NOTES/casedesk/Usercmds.md` (33 KB) und
`docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/Case.md`. Welche davon
`:Bindings` als Quelle nimmt, ist vor Phase 4 zu klären; eine der beiden
sollte danach ein Zeiger auf die andere sein.

### 3.4 Bleibt das Statusline-Modul in der Config?

`lua/wkdnvchad/ui/statusline/modules/casedesk/` ist Teil des
Statusline-Frameworks `wkdnvchad`, das selbst noch in der Config lebt.

**Empfehlung: bleibt.** Es requiret nach dem Umzug `casedesk.sla`,
`casedesk.config`, `casedesk.meta`, `casedesk.resolve` — drei der vier
Zugriffe sind schon `pcall`, der vierte (`casedesk.config`) sollte einer
werden, damit die Statusline ohne casedesk-Checkout nicht wirft.

### 3.5 Deutsche Kommentare im Code

`config.lua` ab ca. Zeile 80, Teile von `solution.lua`, `sla/*` sind
deutschsprachig kommentiert — Verstoß gegen die eigene Regel
(Quellcode ausnahmslos Englisch).

**Empfehlung: eigener Commit *nach* dem Umzug**, nicht während. Ein
Umzugs-Commit, in dem `git log --follow` nur Pfade sieht, ist Gold wert;
ein Umzugs-Commit mit 200 übersetzten Kommentarzeilen darin ist nicht
mehr reviewbar.

### 3.6 Bereiche jetzt oder später?

Das Bereichs-Modell (§7) ist **kein** Umzugs-Thema — es ist ein Feature.
Trotzdem gehört es in diesen Plan, weil es dieselbe Datei umbaut, die
Phase 2 ohnehin anfasst: `config.state_dir()` und die vier Felder, die
`cases_root` ableiten.

**Empfehlung: das Datenmodell in Phase 2 mitnehmen, die Bedienoberfläche
danach.** Konkret heißt das: `config.areas` und die
`area`-Durchreichung in `registry`/`state_dir` entstehen zusammen mit
`config.setup()`, weil beides an derselben Stelle sitzt und ein zweiter
Eingriff dort ein zweites Mal alle Konsumenten berührt. Die
`:Case new`-Bereichsabfrage, der `:Cases area`-Filter und die
Migration von `T2` in die States kommen danach als eigene Pakete — mit
Tests, die es dann schon gibt.

Die billige Alternative wäre, in Phase 2 nur `cases_root` konfigurierbar
zu machen und Bereiche komplett zu vertagen. Dagegen spricht der
gemessene Befund: zwei der 30 Cases im Bestand sind **heute** unsichtbar
für jedes `:Case`-Kommando, plus der eine T2-Case. Das ist keine
Zukunftsfrage mehr.

### 3.7 Windows-only oder cross-plattform?

`NEW-30` verlangt cross-plattform von Anfang an, `NEW-31` eine
modul-interne Alternative, wo das nicht geht. Der erste Entwurf dieses
Plans wollte stattdessen Windows-only ins README schreiben — das war
bequem, aber es ist nicht, was die Regel sagt.

Realistisch ist casedesk in drei Punkten plattformgebunden, und alle drei
sind es über `lib.nvim`, nicht im eigenen Code: `cross.open_default`,
`cross.uv.spawn_capture` (OCR-Binaries) und `cross.fs.mutate`. Die
`cross.*`-Familie ist genau dafür da — sie **ist** die Alternative nach
NEW-31.

**Empfehlung: als cross-plattform behandeln, aber nur behaupten, was
geprüft ist.** Konkret: Platform-Badge auf Linux/macOS/Windows, im README
ein ehrlicher Satz "entwickelt und benutzt auf Windows, CI läuft auf
Linux, macOS ungetestet". Die CI-Suite auf Ubuntu (Phase 5) ist dabei
kein Feigenblatt: sie beweist, dass die reinen Parser (`render`,
`stream_format`, `extract/*`, `sla/clock`) plattformunabhängig laufen —
und das ist der Teil, der es sein muss. Was echte Pfade und Binaries
anfasst, ist ohnehin über `cross.*` abstrahiert.

Ein Punkt bleibt echt Windows-spezifisch und gehört dokumentiert statt
wegabstrahiert: die Standardpfade (`C:/repos`) sind Defaults, keine
Annahmen — sie kommen bereits aus `$REPOS_DIR`.

### 3.8 Parallelbetrieb: die Config-Kopie bleibt, bis das Plugin steht

Vorgabe aus dem Alltag: die casedesk-Dateien in der nvim-Config dürfen
nicht verschwinden, solange damit gearbeitet wird. Das ändert Phase 3
grundlegend — sie **löscht** nichts mehr, sie **schaltet um**.

Drei Wege, mit dem Konflikt umzugehen:

- (a) Beide Bäume aktiv lassen, im Plugin weiterentwickeln, Config-Kopie
  einfrieren. **Zwei Quellen, die driften** — genau die Fehlerquelle, die
  du an den Workflow-Doppelungen kritisierst.
- (b) Config-Kopie bleibt aktiv, Plugin wird blind daneben gebaut und
  erst am Ende scharfgeschaltet. Der Umschaltmoment ist dann ein großer
  ungetesteter Sprung.
- **(c) Das Plugin wird sofort die aktive Quelle, die Config-Kopie bleibt
  als Rückfallnetz liegen — inaktiv.**

**Empfehlung: (c).** Umgesetzt ist das eine einzige Zeile in
`lua/bindings/usrcmds/init.lua`:

```lua
-- Aktiv: das Plugin (lazy-Spec, lokaler Checkout unter $REPOS_DIR).
-- Rueckfall: diese Zeile einkommentieren, Spec-Eintrag auskommentieren.
-- require("bindings.usrcmds.case").enable()
```

Damit gilt: nur **eine** Quelle ist je aktiv (keine doppelten
`:Case`-Registrierungen, kein Rätselraten, welcher Code gerade lief), der
Alltag testet das Plugin ab Tag eins, und der Weg zurück ist ein
Kommentarzeichen — kein Checkout, kein Stash. Die alte Kopie wird
eingefroren: **ab Phase 3 wird nur noch im Plugin-Repo geändert.**

Das Löschen der Config-Kopie wird ein eigener, später Schritt
([Phase 7](#phase-7--aufraeumen-erst-wenn-das-plugin-traegt)), an dem
nichts mehr hängt.

---

## 4. Phasen

Reihenfolge ist bindend: jede Phase lässt die Config in einem Zustand,
in dem `nvim` startet und `:Case` funktioniert.

### Phase 0 — Repo-Skelett (kein casedesk-Code)

Ziel: `casedesk.nvim` ist ein leeres, aber vollständig eingerichtetes
personal-Plugin. Abzuhaken ist `gates/NEW_PROJECT.md` §1-§4.

1. Checkout unter `$REPOS_DIR/casedesk.nvim` (NEW-01 sagt `e:\repos` —
   auf dieser Maschine ist das `C:/repos`, dieselbe Rolle).
   Default-Branch `main` (NEW-02).
2. `gh repo edit --description … --homepage …` (NEW-04) und
   `--add-topic neovim,lua,plugin` plus fachliche Topics (NEW-05).
3. Aus `open.nvim` übernehmen und anpassen: `.gitattributes` (`* text=auto
   eol=lf`, plus die `*.lua`/`*.sh`-Regeln — Pflicht, siehe die
   Line-Ending-Strategie aller `C:/repos`-Repos), `.gitignore`
   (inklusive `docs/map/`, NEW-20), `.luacheckrc`, `.luarc.json`
   (NEW-03), `stylua.toml`.
   **Keine `LICENSE`** — NEW-06.
4. `README.md` (NEW-11): englisch, ASCII-Titel, Badges, Table of Content
   nur über Level-2-Headlines. Nach der ASCII-Art ein `>`-Absatz mit
   Verweis auf ein ergänzendes Schwesterplugin (NEW-12) — naheliegend
   `spotlight.nvim` oder `images.nvim`, siehe [§8](#8-schwesterplugins).
   Platform-Badge gemäß [§3.7](#37-windows-only-oder-cross-plattform).
5. Leere Gerüstdateien nach [§2](#2-zielbild): `lua/casedesk/init.lua`,
   `config/`, `bindings/`, `@types/init.lua`, `health.lua`,
   `doc/casedesk.txt`, `docs/ROADMAP.md`, `docs/BINDINGS.md`.
6. `scripts/gen_map.lua` aus `documentation.nvim/docs/REUSE.md` (NEW-20).
7. Erster Commit, push.

**Prüfpunkt:** `git ls-remote https://github.com/StefanBartl/casedesk.nvim`
ohne Passwort-Prompt. Wenn das fragt, ist der `remote`-Modus für dieses
Repo nicht benutzbar (siehe §5.1) — besser jetzt wissen als in Phase 6.

### Phase 1 — Code umziehen, Namespace umschreiben

Ein Commit, rein mechanisch.

1. `lua/bindings/usrcmds/case/*` → `casedesk.nvim/lua/casedesk/*`
   (inklusive `templates/`, `extract/`, `sla/`; `README.md` und
   `docs/FEATURES.md` gehen nach `docs/FEATURES.md`).
2. Globales Rewrite über alle `.lua` und `.md` im neuen Repo:
   - `bindings.usrcmds.case` → `casedesk`
   - `bindings/usrcmds/case` → `casedesk`
   Deckt in einem Rutsch die `require`-Aufrufe, die
   `---@module`-Annotationen und die Pfadangaben in den Doc-Kommentaren.
3. `config.lua` → `config/DEFAULTS.lua` verschieben, inhaltlich noch
   **unverändert** (die `M.*`-Felder bleiben stehen, `setup()` kommt erst
   in Phase 2). Ein Übergangs-`config/init.lua`, das DEFAULTS
   durchreicht, hält alle 30 Konsumenten am Leben.
4. Relative Doc-Links reparieren: `docs/FEATURES.md` verweist heute mit
   `../../../../../docs/NOTES/casedesk/…` — nach dem Umzug entweder auf
   die repo-eigenen Docs (Phase 4) oder als absolute GitHub-URL.
5. `stylua --check lua` und `luacheck lua` grün.

**Prüfpunkt:** In der Config `lua/bindings/usrcmds/case/` **noch nicht**
löschen. Beide Bäume existieren kurzzeitig parallel; die Config lädt
weiterhin ihren eigenen.

### Phase 2 — `config.setup(opts)`

Der einzige Schritt mit echter Logik.

1. `config/init.lua` bekommt:
   - `M.setup(opts)`: `vim.tbl_deep_extend("force", …)` der Skalare und
     Tabellen in die Modultabelle, danach `rebuild_derived()`.
   - `rebuild_derived()`: `root`, `cases_root`, `workflow_templates_dir`,
     `sla_doc_path` aus `repo_root` neu bauen — aber **nur die, die der
     User nicht explizit gesetzt hat** (sonst überschreibt ein
     abgeleiteter Pfad eine bewusste Einzelangabe).
   - `M.state_dir(state)` bleibt Funktion, funktioniert dadurch von selbst.
2. `lua/casedesk/init.lua` bekommt `M.setup(opts)`, das
   `config.setup(opts)` aufruft und danach `enable()` — oder `setup` und
   `enable` bleiben getrennt, siehe §6.1.
3. `@types/init.lua`: `---@class Casedesk.Config` mit allen 30 Feldern,
   plus `Casedesk.Config.Resolved`. Das ist die Datei, aus der später
   `docs/configuration.md` gefüllt wird.
3b. **Bereichs-Datenmodell mitnehmen** (§3.6): `config.areas`,
   `state_dir(area, state)`, `RegistryEntry.area`. Details und
   Migrationsweg: [§7](#7-bereiche--der-bestand-ist-nicht-mehr-nur-sap).
   Nur das Modell — die Bedienoberfläche kommt nach Phase 6.
4. `health.lua`: `:checkhealth casedesk` prüft, was `doctor.lua` heute
   schon weiß — existiert `repo_root`, ist `cases_root` da, sind die
   externen Binaries für OCR/curl auffindbar. `doctor.lua` selbst bleibt
   unangetastet (`:Cases doctor` ist eine Bestands-Prüfung, keine
   Installations-Prüfung — zwei verschiedene Dinge).

**Prüfpunkt:** `require("casedesk").setup({ repo_root = "…" })` in einem
Wegwerf-nvim, dann `:Case new` gegen einen Wegwerf-Ordner. Wenn die
abgeleiteten Pfade nicht mitziehen, fällt es hier auf und nicht im echten
Bestand.

### Phase 3 — Umschalten (die Config-Kopie bleibt liegen)

Nach [§3.8](#38-parallelbetrieb-die-config-kopie-bleibt-bis-das-plugin-steht):
Das Plugin wird die aktive Quelle, die alte Kopie bleibt als
auskommentiertes Rückfallnetz.

1. `lua/bindings/usrcmds/init.lua:7`: `require(...case).enable()`
   **auskommentieren**, mit dem Rückfall-Kommentar aus §3.8 daneben.
   Nicht löschen.
2. `lua/bindings/mappings/custom.lua:28`:
   `pcall(require, "bindings.usrcmds.case.resolve")` → `"casedesk.resolve"`.
3. `lua/wkdnvchad/ui/statusline/modules/casedesk/init.lua`: vier requires
   umstellen, den `config`-Zugriff auf `pcall` heben (§3.4).
4. Spec-Eintrag aktivieren (vorgezogen aus Phase 6, weil ohne ihn nach
   Schritt 1 gar kein `:Case` mehr da wäre).
5. `lua/bindings/usrcmds/case/README.md` bekommt oben einen Hinweis:
   eingefroren, aktive Quelle ist das Plugin, hier nichts mehr ändern.
6. Doc-Stubs (§3.2/§3.3) — **noch nicht**, erst in Phase 7. Solange die
   Config-Kopie liegt, sollen ihre Doc-Verweise weiter zeigen.

**Prüfpunkt:** `nvim` startet ohne Fehler, `:Case`, `:Cases` und
`:Tricentis` sind da und kommen aus dem Plugin (`:verbose command Case`
zeigt den Pfad), `:Cases doctor` liefert dieselbe Fundliste wie der
weggespeicherte Vorher-Lauf (§5.2).

### Phase 4 — Doku

1. `docs/installation.md`, `docs/configuration.md`, `docs/commands.md`,
   `docs/WORKFLOW.md` — Vorlage `open.nvim/docs/`.
2. `doc/casedesk.txt` (vimdoc, Tags: `:h casedesk`, `:h casedesk-config`,
   `:h :Case`).
3. `CHEATSHEET.md` aus `docs/NOTES/casedesk/Usercmds.md` ableiten.
4. `docs/install.json` — falls die Deps-Deklaration
   (`:Lib deps status` / `require_tool`) hier ebenfalls greifen soll:
   casedesk ruft externe Binaries auf (OCR, `curl`), das ist genau der
   Fall, für den die Deklaration gebaut wurde.
5. Bindings-Docs der Config auf die neuen Pfade ziehen
   (`docs/NOTES/BINDINGS`), §3.3-Doppelung auflösen.

### Phase 5 — Tests und CI

Heute gibt es **null Tests** für 11.295 Zeilen. Das nachzuholen ist nicht
Teil des Umzugs, aber die Gelegenheit, die Lücke wenigstens einzurahmen.

1. Infrastruktur steht seit Phase 0: `TESTS/minimal_init.lua`,
   `scripts/test.sh`, plenary/busted, drei CI-Jobs, plus
   `TESTS/smoke_spec.lua` (vier Zusicherungen, die belegen, dass der
   Runner überhaupt etwas lädt — eine davon prüft speziell, dass
   `require("casedesk")` **nicht** auf die eingefrorene Config-Kopie
   fällt). Nicht `open.nvim`s framework-freier Harness: NEW-39/40
   schreiben plenary vor, s. §2.2.
2. Erste echte Specs dort, wo Regressionen am teuersten wären und der
   Test am billigsten ist — reine Funktionen ohne Dateisystem:
   - `render.lua`: `to_short` / `to_snow` / `is_plausible_case_number`
     (die Plausibilitätsgrenze existiert wegen eines echten Vorfalls —
     eine leere Case-Nummer, die Blueprint-Dateien direkt nach
     `Cases/Open/` geschrieben hätte; genau das gehört in einen Test)
   - `stream_format.lua`: Format-Erkennung SNOW vs. SAP Resolve
   - `extract/supportinfo.lua`: Kopf + Digest gegen ein Fixture
   - `sla/clock.lua`: Geschäftszeiten-Rechnung, inkl. der
     Awaiting-User-Info-Pause
3. CI steht ebenfalls seit Phase 0 (drei Jobs, `lib.nvim` und
   `plenary.nvim` als `.deps/`-Checkouts). Hier nur noch nachziehen, was
   neue Specs an Fixtures brauchen.

**Fixtures:** Support-Infos und Activity-Streams aus echten Cases sind
Kundendaten. Ins Repo dürfen nur anonymisierte Fixtures — passt zum
Anonymisierungs-Punkt, der ohnehin auf der Liste steht.

### Phase 6 — Spec und Rollout

1. `lua/plugins/personal/init.lua`: neuer Eintrag.

   ```lua
   {
     -- Eager: enable() registriert die Composer-Verben (:Case, :Cases,
     -- :Tricentis) und den SLA-FocusGained-Autocmd. Lazy auf `cmd` waere
     -- moeglich, wuerde aber die SLA-Benachrichtigung erst beim ersten
     -- :Case scharfschalten -- also genau dann nicht, wenn sie zaehlt.
     "StefanBartl/casedesk.nvim",
     lazy = false,
     dependencies = { "StefanBartl/lib.nvim" },
     opts = {
       -- repo_root default: $REPOS_DIR/WKDBook-Tricentis
     },
   },
   ```

2. `lua/plugins/personal/source.lua`: `["casedesk.nvim"] = "dir"` in die
   MODE-Tabelle (der globale `OVERRIDE` steht ohnehin auf `"dir"`, aber
   der Eintrag dokumentiert die Absicht für den Fall, dass er auf
   `"auto"` zurückgeht).
3. `gates/REVIEW.md` einmal komplett durchgehen — insbesondere die drei
   Punkte, die casedesk heute vermutlich nicht erfüllt: Range-Support für
   die Kommandos, bei denen er sinnvoll ist (NEW-23), Count-Support
   (NEW-25), Completion für jedes Argument aus endlicher Menge (NEW-26).
4. Bindings in die zentrale Sammlung eintragen (NEW-35):
   `docs/NOTES/PersonelPlugins/BINDINGS`.
5. Mehrere Arbeitstage im Alltag gegen den echten Bestand — mit der alten
   Kopie noch als Rückfallnetz (§3.8).

### Phase 7 — Aufräumen (erst wenn das Plugin trägt)

Bewusst abgekoppelt, ohne Termin. Auslöser ist nicht "Phase 6 fertig",
sondern "seit N Arbeitstagen kein Griff zum Rückfallnetz".

1. `lua/bindings/usrcmds/case/` löschen.
2. Die auskommentierte `enable()`-Zeile in `usrcmds/init.lua` entfernen.
3. `docs/ROADMAP/casedesk/` und `docs/NOTES/casedesk/Workflow.md` durch
   Stubs mit Repo-Verweis ersetzen (§3.2/§3.3).
4. `grep -rn "bindings.usrcmds.case" lua/` muss leer sein.

---

## 5. Risiken

### 5.1 Privates Repo + lazy.nvim im `remote`-Modus

Der ernsteste Punkt. lazy.nvim klont über HTTPS; ein privates Repo
verlangt dabei Credentials. Auf dieser Workstation steht `OVERRIDE =
"dir"` (alles lokal), also fällt es hier zunächst nicht auf — auf einer
Maschine mit `SOURCE = "remote"` (und die Workstation-Rolle wäre per
`machine.is("workstation")` genau das, sobald `OVERRIDE` auf `"auto"`
zurückgeht) schlägt der Klon fehl und `:Case` ist weg.

Drei Auswege, in dieser Reihenfolge:

- **Git Credential Manager** hat den `gh`-Token meist schon gespeichert →
  Phase-0-Prüfpunkt beantwortet, ob das hier zutrifft. Billigste Lösung,
  wenn sie zutrifft.
- `url.…insteadOf`-Rewrite auf SSH in der globalen Git-Config.
- Repo öffentlich machen. Vorher zu klären, ob im Code oder in den Docs
  Kundendaten oder Interna stehen — bei 166 KB Konzept-Doku mit echten
  Case-Nummern, Firmennamen (die Achmea-DLL aus EXTRACTION.md §1) und
  einer SLA-Matrix aus einem internen Dokument ist die Antwort
  vermutlich ja. Deshalb steht diese Option hier zuletzt, nicht zuerst.

### 5.2 Der Umzug ist nicht testbar

Es gibt keine Tests, gegen die man "unverändertes Verhalten" beweisen
könnte. Das einzige verfügbare Netz ist `:Cases doctor` gegen den echten
Bestand vor und nach Phase 3 — ein Lauf mit identischer Fundliste ist ein
starkes Signal über sehr viele Module hinweg (Registry, Blueprint,
Normalisierung, Pfadauflösung).

**Also: `:Cases doctor` vor Phase 1 laufen lassen und die Ausgabe
wegspeichern.** Ohne diesen Vorher-Stand ist der Nachher-Lauf wertlos.

### 5.3 `ui.lua` mit 3.502 Zeilen

Ein Drittel des Moduls in einer Datei, und die Datei, die alle anderen
anfasst. Beim Umzug egal (Pfade sind Pfade), aber sie ist der Grund,
warum eine Aufteilung *nicht* in denselben Commit gehört: ein
fehlgeschlagenes Rewrite in dieser Datei wäre in einem gemischten Diff
nicht mehr zu finden. Kandidat für einen eigenen Schritt nach Phase 6.

### 5.4 On-disk-Zustand

Entwarnung, aber geprüft: `.case.json`, die Ordnerstruktur unter
`Cases/<State>/<Nr>/` und die Registry sind vom Umzug nicht betroffen —
kein Feld darin nennt einen Lua-Modulpfad. Es braucht **keine**
Datenmigration.

### 5.5 Zwei Kopien während des Parallelbetriebs

Die Config-Kopie bleibt bis Phase 7 liegen (§3.8) — und eine zweite
Kopie desselben Codes ist strukturell dieselbe Fehlerquelle wie die
Workflow-Doppelungen, gegen die dieser ganze Bestand sonst argumentiert.

Entschärft ist sie nur, solange die Regel eingehalten wird: **ab Phase 3
wird ausschließlich im Plugin-Repo geändert.** Der Hinweis oben in
`case/README.md` (Phase 3, Schritt 5) ist dafür da, dass man das auch
noch weiß, wenn man in drei Wochen aus Gewohnheit die alte Datei öffnet.

Zusätzliche Absicherung, falls es doch passiert: ein `diff -r` zwischen
beiden Bäumen vor Phase 7 zeigt jede Änderung, die versehentlich links
gelandet ist.

### 5.6 File-Locks beim Verschieben von Case-Ordnern

Bekanntes Windows-Problem in diesem Setup: nach `move`/`rename` kann ein
Handle den Ordner sperren. `:Case close`, `:Case solved` und jeder andere
State-Wechsel verschieben genau solche Ordner — mit offenen Buffern
darin, denn man schließt einen Case üblicherweise aus dem Case heraus.

Das ist kein Umzugs-Risiko (der Code bleibt derselbe), aber es gehört in
`health.lua` und in die Testliste: `lib.nvim.cross.fs.lock` und
`:WhoLocks` existieren bereits als Diagnose, und `move_state` sollte im
Fehlerfall darauf verweisen statt nur "konnte nicht verschieben" zu
melden. Kleiner Fix, hoher Alltagswert — Kandidat für NEW-32
("Sinnvolle Features, die dabei auffallen, gleich implementieren").

---

## 6. Offene Fragen

1. **`setup()` und `enable()` trennen oder verschmelzen?** Alle anderen
   personal-Plugins haben nur `setup()`. casedesk hat historisch
   `enable()`. Vorschlag: `setup(opts)` wird der öffentliche Einstieg und
   ruft `enable()` intern; `enable()` bleibt als No-op-sicherer
   Zweit-Einstieg für die Übergangszeit exportiert.
2. **Welche der beiden Command-Dokus ist die Quelle?** (§3.3)
3. **Kommt `:Tricentis` mit?** Es lebt im selben Modul, ist aber
   ausdrücklich *nicht* case-scoped, sondern arbeitet auf dem ganzen
   Wissens-Repo. Vorschlag: kommt mit (es teilt Config und
   Composer-Registrierung), aber in `docs/commands.md` klar als eigener
   Bereich geführt — und als Notiz für den Tag, an dem daraus ein
   `tricentis.nvim` werden soll.
4. **Ist `CS` der endgültige Name des zweiten Bereichs, und kommen
   weitere?** (§7.2) — davon hängt ab, ob die Bereichsliste eine
   Config-Tabelle bleibt oder aus der Ordnerstruktur erkannt wird.
5. **Wird `ui.lua` (3.502 Zeilen) vor oder nach Phase 7 aufgeteilt?**
   (§5.3) — der Umzug selbst braucht es nicht, `gates/REVIEW.md`s
   Modularitäts-Abschnitt vermutlich schon.

Zu Windows-only ist die Frage beantwortet, nicht mehr offen:
[§3.7](#37-windows-only-oder-cross-plattform).

---

## 7. Bereiche — der Bestand ist nicht mehr nur SAP

Befundlage: [§1.4](#14-der-bestand-ist-bereits-mehrbereichig--casedesk-weiß-es-nur-nicht).
Einordnung in den Umzug: [§3.6](#36-bereiche-jetzt-oder-später).

### 7.1 Das Problem in einem Satz

`config.cases_root` ist ein einzelner Pfad, und jede Frage nach "welche
Cases gibt es" wird über genau diesen einen Pfad beantwortet — deshalb
existieren die zwei CS-Cases und der eine T2-Case für casedesk nicht.

### 7.2 Modell: ein Bereich ist ein eigener Case-Baum

Ein **Bereich** (`area`) ist ein Ordner mit eigenen State-Unterordnern,
in denen Cases liegen. Er hat einen eigenen Wurzelpfad und eine eigene
State-Menge — beides, weil der Bestand beides bereits unterschiedlich
hat (§1.4, Befunde 1 und 4).

```lua
M.areas = {
  {
    name = "SAP",                                   -- Anzeige und :Cases-Filter
    dir = M.repo_root .. "/Cases/SAP_Support/Cases",
    states = { "Open", "Closed", "Solved", "T2", "Reassigned",
               "Assigned", "Unassigned", "OtherAgent" },
    default_state = "Open",
    snow_prefix = "SAP0000",                        -- heute global
    sla = true,                                     -- SLA-Uhr laeuft hier
  },
  {
    name = "CS",
    dir = M.repo_root .. "/Cases/CS",               -- flacher, ohne Cases/
    states = { "Open", "Closed", "Solved" },
    default_state = "Open",
    snow_prefix = nil,                              -- keine SNOW-Id
    sla = false,
  },
}
M.default_area = "SAP"
```

Der **eigene `dir` pro Bereich** ist die Stelle, an der der
Tiefenunterschied verschwindet: casedesk muss die Ebene nicht
herleiten, sie steht da. Die Alternative — `CS/` auf die SAP-Tiefe
umbauen (`Cases/CS/Cases/…`) — wäre ein Ordner namens `Cases` in einem
Ordner namens `CS` in einem Ordner namens `Cases`, nur damit ein
Formatstring passt. Nicht wert.

`snow_prefix` und `sla` pro Bereich, weil beides SAP-spezifisch ist: ein
CS-Case hat keine `SAP0000…`-Ticketnummer, und die SLA-Matrix aus
`Workflow/SLA_ServiceLevelAgreement.md` gilt für den SAP-Vertrag. Ein
CS-Case, der eine Frist reißt, die es für ihn gar nicht gibt, wäre genau
die Sorte Fehlalarm, die den ganzen SLA-Wächter unglaubwürdig macht.

### 7.3 Wie weit reicht das in den Code?

Erfreulich kurz. Gemessen: `config.state_dir()` hat **vier** echte
Aufrufer.

| Datei | Aufrufe | Was daraus wird |
| --- | --- | --- |
| `registry.lua` | 2 (`scan_state`, `new_dir`) | Schleife über `config.areas`, `RegistryEntry` bekommt `area` |
| `ui.lua` | 2 (`move_state`, Zeile 1882/1883) | Ziel wird im Bereich des Cases gesucht, nicht global |
| `migrate.lua` | 3 | historisch, SAP-only — bleibt auf den SAP-Bereich gepinnt |

Alle **12 anderen** Registry-Konsumenten (`doctor`, `query`, `resolve`,
`similar`, `solution`, `linkcheck`, `render`, `sla/notify`,
`sla/stream`, `init`, `ui`) lesen `e.dir` aus dem Registry-Eintrag und
funktionieren unverändert weiter. Das ist der Grund, warum das Modell
überhaupt billig ist: `registry.lua`s "flat by design"-Entscheidung hat
die Pfadauflösung schon vor langer Zeit an genau einer Stelle
zentralisiert.

Zwei Punkte, die trotzdem echte Arbeit sind:

- **Eindeutigkeit der Case-Nummer.** `registry.find(short)` gibt heute
  den ersten Treffer zurück. Über zwei Bereiche hinweg kann dieselbe
  Nummer zweimal existieren. Der `CASE`-Argumenttyp müsste dann
  `CS/049885` als qualifizierte Form akzeptieren und bei Mehrdeutigkeit
  nachfragen. Praktisch heute kein Konflikt (SAP: 6-7 Stellen, CS: 6
  Stellen mit führender Null) — aber `find` muss den Fall trotzdem
  erkennen, statt still den falschen Case zu öffnen.
- **`area` gehört in `.case.json`.** Ableitbar ist es aus dem Pfad, aber
  §1.4 zeigt, warum das nicht reicht: die vorhandenen CS-Cases wurden
  bereits ohne das Feld geschrieben. `doctor.lua` ergänzt es beim
  nächsten Lauf — dieselbe Naming-Drift-Mechanik wie bei jeder anderen
  Bestandsinkonsistenz, kein Einmalskript. Genau wie `Ressources/` →
  `assets/` es schon vorgemacht hat.

### 7.4 Bedienung

- **`:Case new`** fragt den Bereich ab — der Punkt, den der Bestand
  ausgelöst hat. Als erster Schritt, vor der Case-Nummer, per
  `kit.select` über `config.areas`. Bei genau einem konfigurierten
  Bereich entfällt die Abfrage. Ob der zuletzt benutzte Bereich
  vorausgewählt wird oder immer `default_area`, ist eine
  Alltagsfrage — Vorschlag: `default_area`, weil eine vorausgewählte
  Antwort, die von der letzten Sitzung abhängt, genau dann falsch ist,
  wenn man sie am wenigsten prüft.
- **`:Cases area [name]`** als Filter, nach dem Muster der bestehenden
  `config.infocard_fields`-Filterrouten. Ohne Argument: Verteilung
  anzeigen.
- **`:Cases`-Listen** zeigen den Bereich als Spalte, sobald mehr als
  einer konfiguriert ist.
- **`:Case close`**s Zielauswahl zeigt nur States des eigenen Bereichs.
  Ein CS-Case nach `T2` zu schieben ergibt keinen Sinn.
- **`:Cases doctor`** bekommt zwei neue Funde: ein Case in einem State,
  den sein Bereich nicht kennt, und ein Case ohne `area` in
  `.case.json`.

### 7.5 Was das nebenbei repariert

- **`T2` wird sichtbar** (§1.4, Befund 4) — heute ein Case, den niemand
  findet, obwohl der Ordner extra dafür angelegt wurde. Als State im
  SAP-Bereich braucht es dafür nur einen Listeneintrag. Die
  Semantik ("liegt bei Support Engineering, ich trage voraussichtlich
  nichts mehr bei, wird nicht mehr aktiv verfolgt") spricht dafür, ihn
  aus `sla_active_priorities`-Sicht wie einen geschlossenen Case zu
  behandeln — sonst tickt eine Uhr für etwas, das man bewusst abgegeben
  hat.
- **`Cases/Solutions/`** (mit `NOT_SAP/`, `Tosca_OSV/`,
  `Solution_TEMPLATE.md`) liegt parallel zu den Bereichen, nicht in
  einem. Sobald Bereiche existieren, ist beschreibbar, was dieser
  Ordner ist: die bereichsübergreifende Lösungssammlung. Das ist der
  fehlende Baustein für den ROADMAP-Punkt "wie kommen die Solutions aus
  den Cases dorthin".

### 7.6 Reihenfolge

1. Datenmodell in Phase 2 (`config.areas`, `state_dir(area, state)`,
   `RegistryEntry.area`) — der Bestand wird dadurch allein schon
   vollständig sichtbar, ohne dass ein einziges Kommando sich ändert.
2. `T2` in die SAP-States, `doctor`-Fund für unbekannte States.
3. `:Case new`-Bereichsabfrage.
4. `:Cases area`, Bereichsspalte in den Listen, `close`-Ziele
   bereichslokal.
5. `area` in `.case.json` inklusive `doctor`-Nachtrag.
6. SLA bereichsweise abschalten (`sla = false` für CS).

Schritt 1 ist die Substanz, 2 ist ein Einzeiler mit sofortigem Nutzen,
3-6 sind Komfort in abnehmender Dringlichkeit.

---

## 8. Schwesterplugins

Die 31 eigenen Plugins wurden gegen casedesks Aufgaben durchgesehen. Vier
Ergebnisklassen; die erste ist die interessante.

### 8.1 Starke Kandidaten — echter Gewinn, kleiner Aufwand

**`spotlight.nvim`** — *"spotlight any number of words, IDs, IPs or error
codes in distinguishable colors — matchadd-based, so cost is independent
of file size. Per-project persistence."*

Der beste Fund der ganzen Durchsicht. casedesks `extract/stream.lua`
zieht aus einem Activity Stream bereits genau die Tokens heraus, die
Spotlight hervorheben kann: Versionen, KBA-Nummern, Error-Codes,
Anhangsnamen, Stammdaten. Ein `:Case spotlight [nr]`, das den
Faktenblock aus `extract/facts.lua` als Spotlight-Token-Menge setzt, ist
fast geschenkt — die Extraktion existiert, das Hervorheben existiert,
es fehlt die Verbindung. Nutzen: ein 400-Zeilen-Activity-Stream wird
überfliegbar, weil das Wesentliche farbig ist. Die
Größenunabhängigkeit (matchadd) passt zu Streams und Logs.

**`replacer.nvim`** — *"Project-wide search-and-replace with ripgrep, an
interactive picker, live preview, and precise, bottom-up application of
changes."*

Das ist das fehlende Werkzeug für den **Anonymisierungs-Wunsch**
(Activity Streams für eine KI-Übergabe von Kundennamen, Kontaktdaten
und Firmennamen befreien). Die zu ersetzenden Werte stehen bereits
strukturiert in `.case.json` — `company`, `name`, und die
Stammdaten-Felder aus dem Stream. Daraus eine Ersetzungsliste zu bauen
und sie mit Live-Vorschau anzuwenden, ist genau das, was replacer.nvim
tut. Die Vorschau ist hier kein Komfort, sondern die Sicherheitsstufe:
niemand sollte eine Anonymisierung blind laufen lassen.

**`pickers.nvim`** — *"one :Pickers command over telescope.nvim or
fzf-lua, with scopes, collections and directory navigation."*

casedesk wählt heute über `lib.nvim.ui.kit`s `select` aus — brauchbar
für kurze Listen, schwach bei 28 Cases mit Titeln. Ausdrücklich
gewünscht für die Log-Auswahl im `assets/`-Ordner. Vorschlag: als
**optionale** Picker-Schicht, `kit.select` bleibt der Fallback, damit
casedesk seine Dependency-Armut behält.

**`images.nvim`** — *"Show images inside Neovim via the iTerm2 protocol
— hover, gallery, clipboard paste. Works on native Windows."*

Zwei Anwendungen: Screenshots aus `assets/` direkt ansehen statt extern
öffnen (Gallery über den Anhangsordner), und `:Image redact` als
Schwärzungs-Gate vor jeder KI-Übergabe von Bildern — steht bereits als
Datenschutz-Erfordernis in [ROADMAP.md](ROADMAP.md), das Werkzeug ist
fertig, es fehlt die Regel in `ki.lua`.

### 8.2 Naheliegend, kleinerer Hebel

| Plugin | Anwendung in casedesk |
| --- | --- |
| `open.nvim` | Ersetzt `lib.nvim.cross.open_default` für Anhänge. Bringt Handler pro Typ mit — Office-Dateien landen in der System-App statt als Buchstabensalat im Buffer. Kundenanhänge sind oft `.xlsx`/`.docx`. |
| `pdfport.nvim` | PDF-Anhänge lesbar machen (`pdftotext` und weitere Backends). Damit werden sie für `:Cases grep`, `:Case similar` und den Faktenblock überhaupt erst Text. |
| `language.nvim` | Rechtschreib- und Grammatikprüfung für Replies, plus Übersetzung. `replygate.lua` prüft Replies bereits — ein Sprach-Check ist derselbe Moment. Kunden schreiben deutsch und englisch. |
| `diff.nvim` | Zwei Activity-Stream-Stände vergleichen (jeder Copy-Paste ist eine neue Fassung), oder zwei Solutions gegeneinander. |
| `markdown.nvim` | Jede Case-Datei ist Markdown. TOC und Heading-Navigation in langen Streams, Link-/Anchor-Handling für die Doku-Links. |
| `hover.nvim` | Bereits global aktiv (`lazy = false`), also gratis: Hover über einen `assets/`-Link zeigt Bild oder Dateikopf, ohne den Case zu verlassen. Nur zu prüfen, ob die Markdown-Links aus casedesks Templates erkannt werden. |
| `cascade.nvim` | Checkboxen und Listen fortführen — relevant, sobald die geplante `TASK.md` mit Checklisten kommt (§9). |
| `buffer-ctx.nvim` | Überschneidet sich mit `:Case insert` und `marks.lua`. Vor einem Ausbau von `INSERT_FIELDS` prüfen, ob buffer-ctx das schon kann, statt eine zweite Fassung zu pflegen. |

### 8.3 Dev-Werkzeuge — Pflicht oder nahe dran

- **`documentation.nvim`** — Dev-Dependency, **Pflicht** nach NEW-19/20:
  `scripts/gen_map.lua`, `docs/map/` gitignored, `--check` nicht in CI.
- **`insights.nvim`** — `:Insights smells` (Magic Numbers, hartkodierte
  Konstanten) auf einen 11k-Zeilen-Baum ohne Tests ist eine billige
  erste Bestandsaufnahme. Auch die Metriken für die
  `ui.lua`-Aufteilungsfrage (§5.3, §6.5).
- **`runtime-analysis.nvim`** — falls sich beim Umzug ein
  Ladereihenfolge- oder `package.loaded`-Problem zeigt.

### 8.4 Bewusst nicht

`dap.nvim`, `debugging.nvim`, `lsp.nvim`, `gopath.nvim`, `sandbox.nvim`,
`reposcope.nvim`, `github_stats.nvim`, `cmdlog.nvim`, `recommender.nvim`,
`color_my_ascii.nvim`, `filetree.nvim`, `mdview.nvim`, `fileops.nvim`,
`emojis.nvim` — kein Bezug zur Case-Arbeit, oder das, was sie können,
kommt bereits über `lib.nvim`.

`sessions.nvim` steht nicht hier, weil es **schon** integriert ist
(Session pro Case, [SESSIONS.md](SESSIONS.md)).

### 8.5 Regel, die dabei einzuhalten ist

Jede dieser Integrationen ist eine **weiche** Abhängigkeit: `pcall` beim
Laden, funktionierender Fallback, wenn das Schwesterplugin nicht da ist.
casedesks heutige Dependency-Armut (nur `lib.nvim`, §1.1) ist ein Wert
an sich — sie ist der Grund, warum der Umzug überhaupt so klein ist. Was
für andere Plugins interessant ist, wandert stattdessen nach `lib.nvim`
(NEW-18).

---

## 9. Feature-Backlog

Gesammelt aus dem Wunschzettel und aus dem, was beim Sichten des Codes
und des Bestands aufgefallen ist. **Nicht** Teil des Umzugs — beim
Umzug gilt NEW-32 nur für Kleinigkeiten, die ohnehin angefasst werden.
Alles Größere wandert nach `docs/ROADMAP.md` im neuen Repo (NEW-33).

Sortiert nach Aufwand, billigstes zuerst.

### 9.1 Klein, sofort nützlich

- **`T2` als State sichtbar machen** (§7.5) — ein Listeneintrag, macht
  einen heute unsichtbaren Case auffindbar.
- **`:Case reopen`** — ein geschlossener oder gelöster Case muss zurück
  nach `Open`, ohne Copy-Paste im Explorer. Die Mechanik existiert
  vollständig (`ui.move_state`), es fehlt die Route. Fällt in dieselbe
  Kategorie wie die anderen State-Verben und ist damit fast ein
  Einzeiler.
- **File-Lock-Hinweis bei fehlgeschlagenem State-Wechsel** (§5.6).
- **`ControlFramework` aus den Tosca-Commander-Properties** — steht dort
  `SAP UI5` statt `none`, ist `ui5.sap.com` die relevante Doku-Quelle.
  Ein Erkennungsmuster in `detect.lua`, eine Zeile im Faktenblock.

### 9.2 Mittel

- **Completion sortiert nach Benutzung, nicht nach Ziffernfolge.**
  *(Wunsch, 2026-09-04.)* `:Case close <Tab>` bietet heute jede Nummer in
  `table.sort`-Reihenfolge an — eine Ordnung, die mit der Arbeit nichts zu
  tun hat. Wer gerade an einem Case sitzt, tippt dessen Nummer trotzdem
  aus dem Kopf, weil sie irgendwo in der Mitte einer Liste von dreißig
  steht. Ziel: **zuletzt benutzte und zuletzt veränderte Cases zuerst.**

  Der Eingriffspunkt ist genau eine Funktion — `registry.complete()`,
  deren letzte Zeile heute `table.sort(out)` ist. Alles andere bleibt.

  Vier mögliche Signale, keines davon allein ausreichend:

  | Signal | Woher | Stärke | Schwäche |
  | --- | --- | --- | --- |
  | Ordner-`mtime` | ein `fs_stat` je Case | kostenlos, überlebt Neustarts, zählt auch Änderungen, die nicht über `:Case` liefen | ein Sync-Werkzeug, das Dateien anfasst, sieht aus wie Arbeit; reines Lesen zählt gar nicht |
  | Benutzungsjournal | casedesk schreibt bei jedem aufgelösten Case eine Zeile | erfasst auch reines Lesen, kann nach Verb gewichten (`close` wiegt mehr als `info`) | neuer Zustand, muss beschnitten werden, auf einer frischen Maschine leer |
  | Aktueller Buffer | `resolve.sync(nil)` — gibt es schon | trivial und exakt | betrifft genau einen Case |
  | `git log --since` im Arbeitsrepo | Cases sind Ordner in einem Git-Repo | kein neuer Zustand, maschinenübergreifend | zählt nur, was committet ist |

  **Empfehlung: `mtime` als Basis, der Case des aktuellen Buffers als
  Fixstern obendrauf, Journal erst dann, wenn sich die Ordnung falsch
  anfühlt.** Damit braucht die erste Fassung **keinen neuen Zustand**: der
  Registry-Scan geht ohnehin über jeden Case-Ordner, ein `fs_stat` mehr
  pro Eintrag, Sortierschlüssel `mtime` absteigend.

  **Zwei Regeln, die dabei nicht verhandelbar sind:**

  1. **Sortieren, nie filtern.** Eine Completion, die Kandidaten
     *weglässt*, weil sie „alt" sind, ist schlimmer als eine, die falsch
     sortiert: der gesuchte Case ist dann gar nicht mehr erreichbar, und
     zwar ohne sichtbaren Hinweis darauf. Die 24-Stunden-Grenze aus dem
     Wunsch ist ein **Ranking**-Schwellwert, kein Sichtbarkeitsschwellwert.
  2. **Kein `stat`-Sturm pro Tastendruck.** `complete()` läuft bei jedem
     `<Tab>`. Die Zeitstempel gehören deshalb in den bestehenden
     Registry-Cache (`registry.list()`, geleert von
     `registry.invalidate()`), nicht in `complete()` selbst.

  Bewusst offen: ob die Ordnung **stabil** sein soll. Eine Liste, die sich
  zwischen zwei `<Tab>`s umsortiert, weil inzwischen eine Minute vergangen
  ist, bedient sich unangenehm. Die ruhigere Variante wäre ein grobes
  Zeitfenster als Sortierklasse (heute / diese Woche / älter) und
  innerhalb der Klasse weiter alphabetisch — was den Wunsch („die letzten
  24 Stunden zuerst") ohnehin wörtlicher trifft als eine
  sekundengenaue Reihung.

- **`:Case close` fragt nach der Solution.** Nach dem Schließen anbieten,
  gleich eine `Solution.md` anzulegen und zu öffnen — plus die Option
  „Kunde hat nicht mehr geantwortet", die genau festhält, dass es keine
  bestätigte Lösung gibt. Das ist der überwiegende reale Ablauf; ihn
  nicht anzubieten heißt, ihn manuell nachzuholen oder zu vergessen.
  Beim Bauen die anderen Verben mit durchsehen — dieselbe Frage („was
  folgt hierauf fast immer?") lohnt sich bei `solved` und `reassign`
  genauso.
- **Einheitliches Routing-Status-System.** Heute per Dateiname
  (`Solution_PAC.md`, `Solution_PSO.md`) und `## Status`-Abschnitt
  gemischt. Ziel: ein Feld, eine Wertemenge (PAC, PSO, License,
  Education, …), und `:Cases` kann danach filtern — „zeig mir alles, was
  je zu PAC ging" wird eine Abfrage statt einer Erinnerung. Fügt sich in
  `config.solution_statuses` und die bestehenden Filterrouten ein.
- **`TASK.md` als eigene Blueprint-Kategorie** — was der Kunde erreichen
  will, explizit festgehalten, samt dem, was er ausdrücklich *nicht*
  will. Ein Blueprint-Knoten mit `key`, damit `:Case task [nr]` gratis
  entsteht (die Verb-Generierung in `init.lua` macht das von selbst).
- **Anonymisierung** (§8.1, `replacer.nvim`) — Ersetzungsliste aus
  `.case.json` plus Stammdaten, Live-Vorschau, Ergebnis in eine
  `*.anon.md` neben das Original. Voraussetzung für jede KI-Übergabe.
- **Solutions in `Cases/Solutions/` überführen** — die
  bereichsübergreifende Sammlung existiert als Ordner, aber ohne Weg
  dorthin. Braucht §7 (Bereiche) als Grundlage, damit klar ist, was
  „bereichsübergreifend" heißt.
- **`Solution/Proposed.md`** — die letzte eigene Antwort vor dem
  Schließen ist *keine* bestätigte Lösung, aber oft die einzige Spur.
  Als eigene, klar benannte Kategorie führen, damit die Suche später
  weiß, wie belastbar ein Treffer ist.

### 9.3 Groß

- **Report-Extraktion** — `DEX_GPO_Report.html`, `gpresult.html` und
  Verwandte in den `assets/`-Ordnern maschinell auswerten. Dasselbe
  Vorgehen wie in [EXTRACTION.md](EXTRACTION.md): erst an echten
  Dateien analysieren, was überhaupt drinsteht, dann Parser bauen.
- **Log-Analyse mit KI** — Logdateien aus `assets/` auswählen (Picker),
  Analyse nach `Research/` schreiben. Hängt an der KI-Anbindung und an
  der Anonymisierung.
- **Doku-Referenzen belegen** — KI-Vorschläge mit echten
  `docs.tricentis.com`-Links auf der *richtigen* Version belegen. Die
  Versionsauflösung steht bereits (`extract/doclinks.lua`), es fehlt die
  Quellensuche.
- **JQL-Suchvorschläge** für die KB-Artikel-Suche in Jira — beim Anlegen
  eines Cases passende Suchstrings mit ausgeben.
- **Workflow-Doppelungen auflösen.** `Workflow/CDX/CDX_Ressourcen`
  spiegelt Dateien aus `Workflow/` — zwei Fassungen, die von Hand
  synchron gehalten werden müssen. Auf dieser Maschine sind **keine
  nativen Symlinks** möglich (Developer Mode aus, nicht elevated);
  Hardlinks (`mklink /H`) funktionieren, aber nur für Dateien, nicht für
  Ordner, und ein Editor, der beim Speichern neu anlegt statt zu
  überschreiben, bricht sie. Vor dem Bauen also erst prüfen, ob eine
  Verknüpfung hier überhaupt trägt — sonst ist ein
  `:Tricentis linkcheck`-artiger Abgleich („diese beiden Fassungen sind
  auseinandergelaufen") das ehrlichere Werkzeug.

---

## Literatur und Referenzen

- `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists` — die
  verbindliche Regelsammlung: `gates/NEW_PROJECT.md` (Phase 0),
  `gates/REVIEW.md` (Phase 6), `regeln/LUA_NVIM.md` (`@types`-Ordner,
  Importreihung, Konfigurierbarkeit, Count-Unterstützung),
  `regeln/PRINCIPLES.md`, `regeln/PERFORMANCE.md`
- `$REPOS_DIR/open.nvim` — Layout-Vorlage, gelebte Fassung derselben
  Vorgaben (Phase 0, 4, 5); besonders `TESTS/harness.lua` und
  `.github/workflows/ci.yml`
- `$REPOS_DIR/lib.nvim` — die einzige harte Abhängigkeit; `.gitattributes`
  als Vorlage für die Line-Ending-Strategie
- `documentation.nvim/docs/REUSE.md` — `scripts/gen_map.lua` (NEW-20)
- `docs/ROADMAP/personal/All/FINISH/ERLEDIGT/roadmap-tools-analysis.md` —
  wie frühere Werkzeugfragen entschieden wurden (welcher Scan wo landet
  und warum); Vorbild für die Ablage-Entscheidungen in §8
- `docs/ROADMAP/personal/All/FINISH/ERLEDIGT/checkhealt_conventions.md` —
  Konventionen für `health.lua` (NEW-10)
- `docs/NOTES/casedesk/` — Usercmds, Keymaps, Autocmds, Workflow;
  Grundlage für `docs/BINDINGS.md` (NEW-15) und `CHEATSHEET.md`
- `docs/NOTES/PersonelPlugins/BINDINGS` — zentrale Bindings-Sammlung,
  Eintragung ist NEW-35

---

## Siehe auch

- [CONCEPT.md](CONCEPT.md) — Modul-Design und fertige Features
- [ROADMAP.md](ROADMAP.md) — offene Feature-Pakete
- [HANDOVER.md](HANDOVER.md) — Chronologie und Erkenntnisse
- [EXTRACTION.md](EXTRACTION.md) — Artefakt-Extraktion (anderes Thema, gleicher Wortstamm)
- `C:/repos/open.nvim` — Layout-Vorlage für Phase 0/4/5
- <https://github.com/StefanBartl/casedesk.nvim> — das Zielrepo
