# Handover — casedesk als eigenes Plugin (`casedesk.nvim`)

**Stand: 2026-09-04, Phasen 0-4 abgeschlossen, dazu der Typ-Rename. Das
Plugin ist seit Phase 3 die aktive Quelle; ab jetzt wird nur noch im
Plugin-Repo geändert. Als Nächstes: Phase 5 (Tests) oder Phase 6
(Rollout) — Phase 7 (Löschen der Kopie) bewusst später.**

Auftrag: `lua/bindings/usrcmds/case/` aus der nvim-Config nach
`StefanBartl/casedesk.nvim` auslagern (privat), dabei naheliegende Features
ergänzen und passende Schwesterplugins einbinden.

**Der Plan ist die Quelle, nicht diese Datei:**
[`docs/ROADMAP/casedesk/PLUGIN.md`](../../casedesk/PLUGIN.md) — Ausgangslage
mit Messwerten, Zielstruktur, sieben Phasen, Entscheidungen mit Begründung,
Bereichs-Konzept (§7), Schwesterplugins (§8), Feature-Backlog (§9).
Diese Datei sagt nur: **wo stehen wir gerade, was kommt als Nächstes.**

---

## Orte

| Was | Wo |
| --- | --- |
| Zielrepo (GitHub, privat) | <https://github.com/StefanBartl/casedesk.nvim> |
| Checkout | `$REPOS_DIR/casedesk.nvim` |
| Alte Kopie (eingefroren, inaktiv) | `nvim/lua/bindings/usrcmds/case/` |
| Plan | `nvim/docs/ROADMAP/casedesk/PLUGIN.md` |
| Konzept-Docs | **`casedesk.nvim/docs/`** (seit Phase 4; in der Config nur noch Zeiger) |
| Bindings-Korpus der Config | `nvim/docs/NOTES/PersonelPlugins/BINDINGS/` — was `:Bindings` liest |
| Verbindliche Regeln | `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists` |
| Notizen/Messungen | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/` |
| Echte Case-Daten | `$REPOS_DIR/WKDBook-Tricentis/Cases/{SAP_Support,CS,Solutions}` |

---

## Erledigt

- [x] **GitHub-Repo angelegt** (2026-09-04) — privat, ohne Auto-Init.
- [x] **Bestandsaufnahme, gemessen** — 39 Lua-Dateien, 11.295 Zeilen,
      17 `lib.nvim`-Module als einzige Abhängigkeit, exakt 3 externe
      Konsumenten in der Config. Details: PLUGIN.md §1.
- [x] **Plan geschrieben** — PLUGIN.md, sieben Phasen.
- [x] **Datenlage gesichtet** — dabei drei für casedesk unsichtbare Cases
      gefunden (s. „Befunde" unten).
- [x] **Vorgaben eingearbeitet** — `gates/NEW_PROJECT.md` in Phase 0/2,
      Parallelbetrieb statt Löschen (§3.8), Schwesterplugins (§8),
      Feature-Backlog (§9).
- [x] **`wkdbook-casedesk` angelegt** — `wkdbook-myplugins/casedesk.nvim/`
      mit `README.md`, `ROADMAP/`, `Messungen/`. Committet und gepusht.
- [x] **`:Cases doctor`-Baseline aufgenommen** (2026-09-04, **vor**
      Phase 1) — 20 Funde, gesichert unter
      `wkdbook-myplugins/casedesk.nvim/Messungen/doctor-baseline-2026-09-04.md`
      samt Kommandozeile zum Wiederholen. Das ist das Regressionsnetz für
      den Umzug.
- [x] **Phase 0 — Repo-Skelett steht** (Commits `da2a7fe`, `dc168a4`,
      gepusht). Details unten.

## Phase 0 im Einzelnen — was steht

- Struktur nach NEW-07/08/09/10: `config/{init,DEFAULTS}.lua`,
  `bindings/{usrcmds,keymaps,autocmds}.lua`, `@types/init.lua`,
  `health.lua`. Alles Gerüste mit `TODO(phase N)` — Phase 1 zieht die 39
  echten Module hinein.
- Keine `LICENSE` (NEW-06), `docs/map/` gitignored und kein
  `gen_map --check` in CI (NEW-20), `scripts/gen_map.lua` übernommen und
  auf casedesk angepasst (inklusive zweier Layer-Regeln: `extract/*` und
  `config` dürfen nicht auf `ui` zugreifen).
- `README.md` englisch mit ASCII-Art, Badges, Schwesterplugin-Absatz
  (NEW-11/12). `doc/casedesk.txt`, `docs/{ROADMAP,BINDINGS,installation,
  configuration}.md` als Gerüste; `docs/ROADMAP.md` ist bereits echt und
  trägt den Feature-Backlog.
- `gh repo edit` mit Beschreibung und Topics (NEW-04/05).
- Tests: `TESTS/minimal_init.lua` + `scripts/test.sh` (plenary/busted,
  NEW-39/40), `TESTS/smoke_spec.lua` mit vier grünen Zusicherungen. CI:
  drei Jobs (stylua, luacheck, tests mit `lib.nvim` und `plenary.nvim`
  als `.deps/`-Checkouts).
- **Nullmessung: 0 Befunde** (NEW-44), dreimal gemessen, `worse: nothing`
  über alle Läufe.

## Phase 1 im Einzelnen — was steht

Commits `b91ac49` (Umzug), `160f7ed` (Lint + ein echter Bug), `9f8...`
(busted-Globals).

- 39 Module, 11.295 Zeilen umgezogen. Namespace-Rewrite
  `bindings.usrcmds.case` → `casedesk` und `bindings/usrcmds/case` →
  `casedesk` über `.lua` **und** `.md` in einem Durchgang — deckt
  requires, `---@module`-Annotationen und Pfade in Doc-Kommentaren
  zugleich. 0 Reste.
- Zwei Dateien wechseln die Rolle, nicht nur den Ort:
  `case/init.lua` → `bindings/usrcmds.lua` (es **ist** der Kommandobaum;
  `M.enable` → `M.setup`), `case/config.lua` → `config/DEFAULTS.lua`
  (es **ist** die Defaults-Tabelle). Das Gerüst-`init.lua` bleibt der
  `setup()`-Einstieg und treibt beide.
- `bindings/autocmds.lua` bleibt bewusst leer: den einen Autocmd
  (`FocusGained` für die SLA-Uhr) erzeugt `sla/notify.lua` neben dem
  Zustand, der entscheidet, ob er feuert. Die Datei sagt das jetzt,
  statt ein TODO zu tragen.
- `docs/FEATURES.md` mitgezogen, relative Links repariert.
- Verifiziert: alle 45 Module laden headless, Smoke-Suite grün, stylua
  und luacheck sauber.
- **Die Config-Kopie ist unangetastet und weiterhin die aktive.**

## Phase 2 im Einzelnen — was steht

Commit `57f5d66`.

- **`config.setup(opts)`** — Deep-Merge, danach `rebuild_derived()` für
  `root`, `cases_root`, `workflow_templates_dir`, `sla_doc_path`, aber
  **nur** für Schlüssel, die der User nicht selbst gesetzt hat.
  Listen-Optionen ersetzen, namensgeschlüsselte Tabellen mergen.
- **Bereiche** — `config.areas` mit SAP und CS, `config.area(name)`,
  `config.state_dir(state, area)` (zweites Argument optional, damit die
  vier Altaufrufer korrekt bleiben, nicht bloß kompilieren).
  `DERIVED_AREA_DIRS` sorgt dafür, dass auch CS `repo_root` folgt.
- **`T2` ist jetzt ein SAP-State** — der Case dort ist zum ersten Mal
  auffindbar.
- **`registry`** scannt alle Bereiche, jeder Eintrag trägt `area`.
  Mehrdeutige Nummern: `find` meldet die Mehrdeutigkeit statt zu raten,
  `exists` sagt „gibt es nicht", der CASE-Argumenttyp nennt im Fehler die
  Bereiche, Completion bietet solche Nummern nur als `AREA/number`.
- **`:Case close`** bietet die Schnittmenge der States aller markierten
  Cases — ein CS-Case kann nicht nach `T2`.
- **`@types/init.lua`** — `Casedesk.Config.Opts` (alles optional, was
  `setup` nimmt) getrennt von `Casedesk.Config` (alles vorhanden, was die
  Module lesen), plus `Casedesk.Area` und `Casedesk.SlaLevel.Opts`.
- **`health.lua`** — `:checkhealth casedesk` prüft lib.nvim, jede
  Bereichs-Wurzel, die Reply-Block-Bibliothek, das SLA-Dokument und die
  drei optionalen Binaries.
- **28 neue Zusicherungen** (`config_spec`, `registry_spec`), Letztere
  gegen einen echten temporären Baum mit absichtlich doppelter Nummer.
  Gesamt 32 Specs, alle grün.

**Zwei echte Defekte kamen dabei ans Licht, beide selbst gebaut:**

1. `ui.lua` übergab `apply` an `pick_asset_value`, nachdem die lokale
   Funktion dieses Namens einen Commit zuvor zu `emit` umbenannt worden
   war — das Argument war damit still das gleichnamige **Modul**. Ein
   Callback, der eine Tabelle ist, wäre erst zur Aufrufzeit gescheitert,
   in einem Zweig, den nur `:Case insert asset` erreicht. Genau der
   „Fix, der eine Warnung nur verschiebt" aus `LLS-08` — gefunden von
   der Messung, die dem Fix folgte.
2. `:Case new` baute einen Registry-Eintrag ohne `area`.

**Und zwei, die die Tests beim Schreiben fanden:** die CS-Area folgte
`repo_root` nicht, und `split()` wies das `"CS/"` zurück, das die
Completion genau dann bekommt, wenn jemand den Bereich tippt und Tab
drückt.

**Messung:** 29 Befunde, davon 27 aus einem einzigen Typfehler
(`Casedesk.Config` erbte die optionalen Felder statt eigene Pflichtfelder
zu haben). Nach der Trennung: **0**.

## Phase 3 im Einzelnen — was steht

Commit `00a45b77` in der **nvim-Config** (im Plugin-Repo hat sich für
diese Phase nichts geändert). **Ab hier ist das Plugin die aktive
Quelle.**

- `lua/bindings/usrcmds/init.lua:7` auskommentiert, mit dem
  Rückfall-Text aus §3.8 daneben: Zeile einkommentieren, Spec
  auskommentieren, und die alte Kopie ist wieder da. **Nie beide** — das
  registrierte `:Case` zweimal.
- Spec in `plugins/personal/init.lua` (Ende von Abschnitt 3),
  `["casedesk.nvim"] = "dir"` in `source.lua`. `lazy = false` mit
  Begründung im Kommentar: `setup()` startet neben dem Kommandobaum den
  SLA-Wächter (Timer + `FocusGained`). Ein `cmd = "Case"`-Trigger gäbe
  die Kommandos zurück, aber die Fristwarnung erst nach dem ersten
  `:Case` der Sitzung — verkehrt herum für ein Feature, dessen ganzer
  Zweck die vergessene Uhr ist.
- `mappings/custom.lua` (`<leader>cs`) und die fünf Stellen im
  Statusline-Segment auf `casedesk.*`. Der `config`-Zugriff dort ist
  jetzt ein `pcall` wie sein `sla`-Nachbar (§3.4); der `meta`-Require in
  `compute` bleibt hart, mit Begründung: dorthin kommt man nur nach
  einem erfolgreichen `resolve.sync`, der casedesk bereits bewiesen hat.
- `case/README.md` trägt oben den Einfrier-Hinweis.

**Verifiziert, nicht behauptet:**

- `nvim` startet fehlerfrei (0 Fehlerzeilen in `:messages`, ~0,8-1,9 s).
- `:Case`, `:Cases`, `:Tricentis` sind da; `nvim_get_runtime_file` löst
  `lua/casedesk/*` auf **genau einen** Pfad auf
  (`C:epos\casedesk.nvim`) — keine Verdeckung durch die alte Kopie.
- `package.loaded["bindings.usrcmds.case"] == nil` nach dem Start.
- Das Statusline-Segment liefert in einem Case-Buffer sein Label
  (`1135620 BARMER · 1 reply`), außerhalb den leeren String.
- luacheck über die fünf geänderten Dateien: keine neue Warnung (die
  fünf gemeldeten Langzeilen standen vorher schon da, an Stellen, die
  diese Phase nicht anfasst).

**Der Prüfpunkt, mit Zahl:** `:Cases doctor` meldet **21 Funde statt 20**
— die 20 der Baseline **zeichengleich und in derselben Reihenfolge**,
dazu `996010 summary-markdown` aus `SAP_Support/Cases/T2/`. Genau die
vorhergesagte Verbesserung, keine Regression.

**Nebenbefund:** die Registry sieht jetzt **31 Cases (28 SAP, 3 CS)** —
in `Cases/CS/Open/` liegen **drei**, nicht zwei wie in der
Bestandsaufnahme geschätzt. Und alle drei sind **sauber**: Notes.md,
Summary.md, Replies/, Research/, assets/ — deshalb bringen sie keinen
einzigen Fund mit. Der Zuwachs von 20 auf 21 ist also vollständig der
T2-Case.

**Doku nebenbei korrigiert:** `docs/NOTES/casedesk/Autocmds.md` sagte
„None. Confirmed by a repo-wide grep …". Der Grep war echt, lief aber
**vor** dem SLA-Notifier — seither installiert casedesk sehr wohl einen
`FocusGained`-Autocmd (`CasedeskSlaNotify`). Die Seite behauptete ein
Negativum und veraltete, ohne dass irgendetwas fehlschlug. Steht jetzt
richtig drin, samt dieser Notiz.

## Typ-Rename `Lib.Case.*` → `Casedesk.*` — und was er nebenbei repariert

Commits `d8be673` (Plugin, 261 Fundstellen in 35 Dateien, 53 Typnamen)
und `e8121dfb` (Config, zwei Annotationen im Statusline-Segment).

**Eine Kollision musste aufgelöst statt ersetzt werden.**
`Casedesk.SlaWindow` gab es bereits — als Union
`Lib.Case.SlaWindow|"24x7"`. Ein blindes `sed` hätte daraus
`---@alias Casedesk.SlaWindow Casedesk.SlaWindow` gemacht, einen Alias
auf sich selbst. Die Tabellenhälfte heißt jetzt
`Casedesk.BusinessHours` (das ist, was sie beschreibt: `from`/`to`/
`days`), der Alias behält die Union, und die Stellen, die die Union
ausgeschrieben hatten, benutzen jetzt den Alias, statt ihn zu
wiederholen. Die `---@cast`-Verengungen zeigen weiterhin auf die
Tabelle, nicht auf die Union — das war der Punkt, an dem ein
Suchen-und-Ersetzen still falsch geworden wäre.

**Der eigentliche Gewinn stand nicht im Plan.** Das Messartefakt aus
Phase 1 — der reguläre LuaLS-Scan meldete 231 `duplicate-doc-field`/
`-alias` gegen die eingefrorene Zwillingskopie, die er als injizierte
Library mitliest — **ist weg.** Die Kollision waren die **Namen**, nicht
die Dateien: das Plugin deklariert jetzt `Casedesk.*`, die eingefrorene
Kopie weiter `Lib.Case.*`, und damit sieht der Scan jede Klasse wieder
nur einmal. Mit **einer** Konfiguration vorher und nachher gemessen:

| Lauf | Befunde |
| --- | --- |
| vorher, Config in `workspace.library` | **232** |
| vorher, Kontroll-Config ohne sie | 1 |
| nachher, Config in `workspace.library` | **1** |
| nachher, Kontroll-Config ohne sie | 1 |

Der eine Rest ist `assert.are_not` in einem Spec — luassert deklariert
diesen Alias in seinen eigenen Typen nicht. Kein Befund an diesem Code.

**Folge für die Arbeitsweise:** „Befund 7" weiter unten sagte, der
reguläre Scan sei bis Phase 7 unbrauchbar. Das gilt **nicht mehr** — die
Kontroll-Config wird nicht länger gebraucht, der normale Scan ist wieder
die gültige Zahl, drei Phasen früher als geplant. Befund 7 ist unten
entsprechend korrigiert.

## Phase 4 im Einzelnen — was steht

Commits `ba5bc21` (Plugin) und `9fc01127` (Config).

**Die Konzept-Docs sind umgezogen** — `CONCEPT.md`, `SLA.md`,
`EXTRACTION.md`, `SESSIONS.md`, `PTO.md`, `HANDOVER.md`, dazu
`Workflow.md` → `docs/WORKFLOW.md` und die Wunschliste →
`docs/REQUESTS.md`. In der Config stehen Zeiger. Das war kein Aufräumen um
seiner selbst willen: **158 Doc-Verweise im Quelltext des Plugins** zeigten
auf `docs/ROADMAP/casedesk/…`, also auf Pfade, die ein fremder Checkout
gar nicht hat. Jetzt lösen alle auf.

**Die Wunschliste heißt jetzt `REQUESTS.md`**, nicht `ROADMAP.md`. Im
Plugin gab es bereits eine `docs/ROADMAP.md` (die kuratierte), und der
Quelltext zitiert die andere ~30-mal als „ROADMAP.md v4/v6/v7". Zwei
Dateien gleichen Namens, von denen der Code die eine meint und ein Leser
die andere aufschlägt, war die Verwechslung, die der neue Name beendet.

**`MIGRATION.md` gibt es nicht.** Sechsmal aus dem Quelltext zitiert,
zweimal aus `CONCEPT.md`, teils mit Abschnittsnummern — und in **keinem**
Repo auffindbar (repo-weit gesucht). Die Verweise zeigen jetzt auf
`CONCEPT.md` §3 und §10, wo die Begründungen tatsächlich stehen, und
`CONCEPT.md` sagt einmal, dass die Datei weg ist, statt so zu tun als
nicht.

**`docs/commands.md` ist generiert**, über
`lib.nvim.bindings.usercmd.composer.document()` — aus demselben
Routen-Baum, den Dispatch und `<Tab>`-Completion benutzen. Damit kann die
Referenz nicht veralten. `scripts/gen_docs.sh` schreibt sie,
`--check` vergleicht, und ein vierter CI-Job schlägt fehl, wenn die
committete Fassung alt ist. Die handgeschriebene `CHEATSHEET.md` daneben
sagt *warum*; die generierte sagt *was*.

**Neu geschrieben:** `docs/configuration.md` (jede Option mit Typ und
echtem Default, aus `DEFAULTS.lua` **ausgelesen** statt abgetippt),
`docs/BINDINGS.md`, `docs/installation.md`, `docs/install.json`,
`doc/casedesk.txt` (zehn Abschnitte mit Tags), README-Doku-Tabelle.

### Zwei Defekte, beim Schreiben der Doku gefunden

1. **`health.lua` prüfte nie, was `:Cases export` wirklich braucht.**
   `pandoc` und ein Chromium fehlten in der Liste — man hätte
   `:checkhealth casedesk` grün bekommen und `:Cases export` wäre trotzdem
   gescheitert. Jetzt beides drin, und der Browser über
   `export.find_browser()` statt über eine zweite Kopie der
   Installationspfad-Liste: ein reiner `PATH`-Test meldet auf Windows
   einen Fehlalarm, weil niemand einen Browser bewusst in den `PATH` legt.
2. **Zwei Listen derselben Werkzeuge.** `health.lua` hatte seine eigene,
   `docs/install.json` (neu) hätte die zweite werden sollen. Stattdessen
   liest `health.lua` jetzt `install.json` über `lib.nvim.deps` — was
   `:Lib deps status` installiert und was `:checkhealth` meldet, ist ab
   jetzt **eine** Liste.

### Eine Annahme des Plans ist gefallen

PLUGIN.md §3.3 sagte, `docs/NOTES/casedesk/` sei Teil des Bindings-Korpus,
den `:Bindings` prüft, und müsse deshalb in der Config bleiben.
Nachgeprüft statt geglaubt: `bindings_explorer/config.lua`s `M.roots()`
liest ausschließlich `PersonelPlugins/BINDINGS/` und
`ExternPlugins/Bindings/`. Der Ordner kam dort nie vor — er war ein
eigenständiger Cheatsheet-Satz, also Plugin-Doku. §3.3 ist mit dem Beleg
korrigiert, und `Usercmds/Case.md` heißt jetzt
`Usercmds/casedesk.nvim.md`, weil `:Bindings drift` über den Dateistamm
mit dem Checkout paart und `Case` zu keinem Repo passte.

**Gates:** stylua sauber, luacheck 0/0 über 45 Dateien, 32 Specs grün,
`gen_docs.sh --check` grün, LuaLS 1 Befund (`assert.are_not` — eine
Typlücke in luassert, kein Befund an diesem Code).

## Als Nächstes

- [x] ~~**Phase 3 — Umschalten.** In der nvim-Config:
      `lua/bindings/usrcmds/init.lua:7` auskommentieren (mit
      Rückfall-Kommentar), `mappings/custom.lua:28` und die vier requires
      in `wkdnvchad/ui/statusline/modules/casedesk/init.lua` auf
      `casedesk.*` umstellen, Spec-Eintrag in `plugins/personal/init.lua`
      **und** `source.lua` anlegen, Hinweis in `case/README.md`, dass die
      Kopie eingefroren ist. **Nicht löschen.**
      Prüfpunkt: `:Cases doctor` muss dieselben 20 Funde liefern wie die
      Baseline — plus jetzt möglicherweise neue aus CS und T2, die vorher
      unsichtbar waren; das ist erwartete Verbesserung, keine Regression.~~
      **Erledigt, `00a45b77`.**
- [x] ~~Phase 4 — Doku.~~ **Erledigt, `ba5bc21` / `9fc01127`.**
- [ ] Phase 5 — Tests und CI (heute 32 Specs für 11.295 Zeilen; die
      Infrastruktur steht seit Phase 0).
- [ ] Phase 6 — Spec und Rollout (der Spec-Eintrag ist in Phase 3
      vorgezogen worden, es bleibt der Rest).
- [ ] Phase 7 — die eingefrorene Kopie löschen. **Erst wenn das Plugin im
      Alltag getragen hat.**
- [ ] Danach: `:Case new` fragt den Bereich (§7.6 Schritt 3),
      `:Cases area`-Filter, `area` in `.case.json` samt doctor-Nachtrag.
- [x] ~~**Aufgeschoben:** im Plugin heißen 53 Typen weiterhin
      `Lib.Case.*`.~~ **Erledigt, `d8be673` (Plugin) und `e8121dfb`
      (Config).** Siehe unten.

---

## Befunde, die den Plan geformt haben

**1. Drei Cases sind heute für jedes `:Case`-Kommando unsichtbar.**
`registry.lua` scannt nur `config.cases_root` = `Cases/SAP_Support/Cases`.
Nicht gefunden werden: die zwei Cases unter `Cases/CS/Open/` und der eine
unter `SAP_Support/Cases/T2/` (`T2` steht nicht in `config.states`). Kein
Umzugsproblem — ein bestehender Zustand. Konzept: PLUGIN.md §7.

**2. `Cases/CS/` ist flacher als `Cases/SAP_Support/`** — ohne die
`Cases/`-Zwischenebene. Deshalb bekommt jeder Bereich einen eigenen `dir`
statt eines abgeleiteten Pfadmusters.

**3. Die Kopplung ist klein.** `config.state_dir()` hat vier echte
Aufrufer; die anderen zwölf Registry-Konsumenten lesen `e.dir` aus dem
Eintrag und laufen unverändert weiter.

**4. `gates/NEW_PROJECT.md` widerspricht dem ersten Entwurf an vier
Stellen** — keine `LICENSE` (NEW-06), `docs/map/` nicht committen und
kein `--check` in CI (NEW-20), `bindings/`-Ordner (NEW-08),
cross-plattform statt Windows-only (NEW-30/31). PLUGIN.md §2.1.

**4b. Die Checkliste hat einen neuen Abschnitt 3** (NEW-36..NEW-46,
seit der LuaLS-Erhebung vom 2026-09-02), der beim ersten Phase-0-Commit
noch nicht vorlag — ein `git pull` im Checklisten-Repo brachte ihn
mitten in der Arbeit. Nachgebessert in `dc168a4`: `workspace.ignoreDir`
in `.luarc.json`, Tests auf plenary statt eigenem Harness, Nullmessung.
PLUGIN.md §2.2. **Vor dem nächsten größeren Schritt lohnt ein Blick, ob
sich dort wieder etwas geändert hat.**

**5. `spotlight.nvim` und `replacer.nvim` sind die stärksten
Integrationskandidaten** — Ersteres für hervorgehobene Fakten in
Activity Streams (die Extraktion existiert bereits), Letzteres als das
fehlende Werkzeug für die Anonymisierung vor KI-Übergaben. PLUGIN.md §8.1.

**6. Ein echter Bug, den luacheck beim Umzug gefunden hat** (Phase 1):
`similar.lua` deklariert `MIN_SHARED_TERMS = 2` mit einem Kommentar, der
ein am echten Bestand beobachtetes Problem beschreibt — und hat die
Konstante **nie angewendet**. Die Bedingung war ein blankes `dot > 0`,
das genau den Ein-Term-Treffer zulässt, den der Kommentar ausschließen
will. `:Case similar` hat also die ganze Zeit dünne Summaries mit einem
geteilten Allerweltswort nahe 1.0 gerankt. Gefixt in `160f7ed`.
Bemerkenswert ist, warum es nicht auffiel: ohne Tests scheitert ein
Ähnlichkeitsranker mit plausiblen, aber falschen Treffern nicht sichtbar.

**7. Der reguläre LuaLS-Scan war unbrauchbar — seit dem Typ-Rename ist
er es nicht mehr.** *(Ursprünglicher Befund, mit Nachtrag am Ende.)*
Er meldet
nach dem Umzug 231 Befunde, davon 230 in einer Regel — alle
`duplicate-doc-field` gegen die eingefrorene Zwillingskopie in der
Config, die der Scan als injizierte Library mitliest (`LLS-03`/`LLS-04`).
Eine Kontrollmessung ohne die Config in `workspace.library` ergibt **0**.
Weg und Beleg:
`wkdbook-myplugins/casedesk.nvim/Messungen/luals-phase1-messartefakt-2026-09-04.md`.
**Nachtrag, 2026-09-04:** erledigt durch den Typ-Rename (`d8be673`),
nicht erst durch Phase 7. Die Doppelung entstand aus gleichen
**Klassennamen**, nicht aus gleichen Dateien — das Plugin deklariert
jetzt `Casedesk.*`, die eingefrorene Kopie weiter `Lib.Case.*`. Der
reguläre Scan fällt damit von 232 auf 1, gleichauf mit der
Kontrollmessung. Ab hier gilt wieder die normale Zahl.

---

## Arbeitsregeln für diesen Auftrag

- **Die Config-Kopie bleibt aktiv nutzbar, bis das Plugin trägt.** Ab
  Phase 3 ist das Plugin die aktive Quelle und die alte Kopie ein
  auskommentiertes Rückfallnetz — **ab dann wird nur noch im Plugin-Repo
  geändert** (PLUGIN.md §3.8, Risiko §5.5).
- Verbindlich: `gates/NEW_PROJECT.md` beim Anlegen, `gates/REVIEW.md` vor
  jedem Merge, `regeln/` beim Schreiben.
- Commit/Push **immer auf `main`**, pro Repo einzeln, **ohne**
  `Co-Authored-By: Claude`.
- Code, Kommentare und Repo-Doku **englisch**; Konversation und
  Roadmap-/Handover-Dateien **deutsch**.
- Vor jedem Commit im Plugin-Repo: `stylua lua && luacheck lua`, dann der
  Test-Runner. **`stylua` nie über die nvim-Config laufen lassen** — sie
  ist nicht stylua-formatiert; dort nur geänderte Dateien einzeln.
- In der nvim-Config **nicht** `git add -A` — es arbeiten mehrere
  Sitzungen parallel daran. Nur explizit stagen.
- Keine Emojis, in Code wie in Doku.
