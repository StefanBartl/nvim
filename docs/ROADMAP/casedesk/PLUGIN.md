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

---

## Table of content

- [1. Ausgangslage](#1-ausgangslage)
- [2. Zielbild](#2-zielbild)
- [3. Entscheidungen](#3-entscheidungen)
- [4. Phasen](#4-phasen)
- [5. Risiken](#5-risiken)
- [6. Offene Fragen](#6-offene-fragen)
- [7. Bereiche — der Bestand ist nicht mehr nur SAP](#7-bereiche--der-bestand-ist-nicht-mehr-nur-sap)

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

Layout nach dem Muster von `open.nvim` (bewusst identisch, damit alle
personal-Plugins gleich aussehen):

```
casedesk.nvim/
  lua/casedesk/
    init.lua              -- setup(opts) + enable(); heutige case/init.lua
    config/
      init.lua            -- setup/get/rebuild_derived
      DEFAULTS.lua        -- heutige case/config.lua, unveraendert als Defaults
    @types/init.lua       -- die heute verstreuten ---@class-Bloecke
    apply.lua attachments.lua blocks.lua blueprint.lua commands.lua
    detect.lua doctor.lua export.lua ki.lua linkcheck.lua links.lua
    marks.lua meta.lua migrate.lua normalize.lua ocr.lua plan.lua
    query.lua registry.lua render.lua replygate.lua resolve.lua
    similar.lua solution.lua stream_format.lua templates.lua
    terminology.lua timeline.lua ui.lua
    extract/{doclinks,facts,stream,supportinfo}.lua
    sla/{init,clock,notify,stream}.lua
    templates/{KiPrompt,Notes,Reply,Research,Solution,Summary}.md
    health.lua            -- :checkhealth casedesk
  doc/casedesk.txt        -- vimdoc, Tags fuer :h casedesk
  docs/
    FEATURES.md CONCEPT.md ROADMAP.md EXTRACTION.md SLA.md
    SESSIONS.md HANDOVER.md PTO.md PLUGIN.md
    installation.md configuration.md commands.md
  TESTS/
    run.lua harness.lua *_spec.lua
  .github/workflows/ci.yml
  .gitattributes .gitignore .luacheckrc .luarc.json stylua.toml
  LICENSE README.md CHEATSHEET.md
```

Namespace: `bindings.usrcmds.case.*` → `casedesk.*`. Kein Zwischenpfad,
kein `casedesk.case.*`.

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

---

## 4. Phasen

Reihenfolge ist bindend: jede Phase lässt die Config in einem Zustand,
in dem `nvim` startet und `:Case` funktioniert.

### Phase 0 — Repo-Skelett (kein casedesk-Code)

Ziel: `casedesk.nvim` ist ein leeres, aber vollständig eingerichtetes
personal-Plugin.

1. `git clone https://github.com/StefanBartl/casedesk.nvim C:/repos/casedesk.nvim`
2. Aus `open.nvim` übernehmen und anpassen: `.gitattributes` (`* text=auto
   eol=lf`, plus die `*.lua`/`*.sh`-Regeln — Pflicht, siehe die
   Line-Ending-Strategie aller `C:/repos`-Repos), `.gitignore`,
   `.luacheckrc`, `.luarc.json`, `stylua.toml`, `LICENSE` (MIT).
3. `README.md` mit dem Standard-Kopf: Alpha-Hinweis, ASCII-Titel, die vier
   Kern-Badges (License / Neovim / Lua / Status), Platform-Badge.
   **Achtung:** casedesk ist heute faktisch Windows-only (Pfade,
   `cross.*`-Aufrufe, OCR über externe Binaries) — das Platform-Badge
   ehrlich setzen, nicht aus `lib.nvim` abschreiben.
4. Erster Commit, push.

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

### Phase 3 — Config umverdrahten

Erst jetzt verliert die Config ihre Kopie.

1. `lua/bindings/usrcmds/init.lua:7`: die `require(...case).enable()`-Zeile
   entfernt — das macht künftig die lazy-Spec.
2. `lua/bindings/mappings/custom.lua:28`:
   `pcall(require, "bindings.usrcmds.case.resolve")` → `"casedesk.resolve"`.
3. `lua/wkdnvchad/ui/statusline/modules/casedesk/init.lua`: vier requires
   umstellen, den `config`-Zugriff auf `pcall` heben (§3.4).
4. `lua/bindings/usrcmds/case/` löschen.
5. `docs/ROADMAP/casedesk/` und `docs/NOTES/casedesk/Workflow.md` gemäß
   §3.2/§3.3 durch Stubs ersetzen.

**Prüfpunkt:** `grep -rn "bindings.usrcmds.case" lua/` liefert nichts
mehr. `nvim` startet ohne Fehler, `:Case`, `:Cases` und `:Tricentis` sind
da, `:Cases doctor` läuft gegen den echten Bestand durch.

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

1. `TESTS/harness.lua` + `TESTS/run.lua` aus `open.nvim` übernehmen
   (framework-frei, headless).
2. Erste Specs dort, wo Regressionen am teuersten wären und der Test am
   billigsten ist — reine Funktionen ohne Dateisystem:
   - `render.lua`: `to_short` / `to_snow` / `is_plausible_case_number`
     (die Plausibilitätsgrenze existiert wegen eines echten Vorfalls —
     eine leere Case-Nummer, die Blueprint-Dateien direkt nach
     `Cases/Open/` geschrieben hätte; genau das gehört in einen Test)
   - `stream_format.lua`: Format-Erkennung SNOW vs. SAP Resolve
   - `extract/supportinfo.lua`: Kopf + Digest gegen ein Fixture
   - `sla/clock.lua`: Geschäftszeiten-Rechnung, inkl. der
     Awaiting-User-Info-Pause
3. `.github/workflows/ci.yml`: stylua + luacheck als Gate, danach die
   Suite mit `lib.nvim` als Sibling-Checkout. Direkt von `open.nvim`
   übernehmbar, nur Repo-Name tauschen.

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
3. Ein Arbeitstag im Alltag gegen den echten Bestand, ohne die alte Kopie
   als Rückfallnetz — erst danach ist der Umzug fertig.

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
4. **Windows-only offen aussprechen?** Wenn ja, gehört es ins README und
   ins Platform-Badge, nicht nur in einen Kommentar.
5. **Ist `CS` der endgültige Name des zweiten Bereichs, und kommen
   weitere?** (§7.2) — davon hängt ab, ob die Bereichsliste eine
   Config-Tabelle bleibt oder aus der Ordnerstruktur erkannt wird.

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

## Siehe auch

- [CONCEPT.md](CONCEPT.md) — Modul-Design und fertige Features
- [ROADMAP.md](ROADMAP.md) — offene Feature-Pakete
- [HANDOVER.md](HANDOVER.md) — Chronologie und Erkenntnisse
- [EXTRACTION.md](EXTRACTION.md) — Artefakt-Extraktion (anderes Thema, gleicher Wortstamm)
- `C:/repos/open.nvim` — Layout-Vorlage für Phase 0/4/5
- <https://github.com/StefanBartl/casedesk.nvim> — das Zielrepo
