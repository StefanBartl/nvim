# Handover — LAST_CDX_TASKS

Begleitdatei zur Umsetzung von
[`docs/ROADMAP/personal/All/FINISH/LAST_CDX_TASKS.md`](../personal/All/FINISH/LAST_CDX_TASKS.md).

**Angelegt 2026-09-03. Stand: P0–P3.5 erledigt, P4 läuft — E1 flächendeckend,
24 Repos gepusht.**

---

## Wofür diese Datei da ist

Zwischenstände pro Repo, Einzelfallentscheidungen mit Begründung,
Überraschungen, abgeleitete Regeln, Verschobenes.

**Nicht hierher:** der Standard selbst (in `LAST_CDX_TASKS.md`), der
Abschlussbericht (nach `ERLEDIGT/`).

---

## Fortschritt

| Phase | Status | Datum | Notiz |
|---|---|---|---|
| P0 — Konzept + Gerüst | ✅ | 2026-09-03 | — |
| P1 — Entscheidungen E1–E6 | ✅ | 2026-09-03 | siehe unten |
| P2 — README-Konzept | ✅ | 2026-09-03 | `MyNotes\docs\README-KONZEPT.md` |
| P3 — Pilot `fileops.nvim` | ✅ | 2026-09-03 | `da20a87` |
| P3.5 — Referenz `lib.nvim` | ✅ | 2026-09-03 | `1dae2fc` |
| P4 — Wellen 1–10 | 🟨 läuft | 2026-09-03 | E1 flächendeckend erledigt; Welle 1 in Arbeit |
| P5 — Wiederholungsläufe | ⬜ offen | — | 8.1/8.3/8.5 vorziehbar |
| P6 — BINDINGS-Sanierung | ⬜ offen | — | braucht P4 |
| P7 — Abschlussbericht | ⬜ offen | — | → `ERLEDIGT/` |

### Repo-Ledger

| Repo | Welle | Was gemacht | Commit |
|---|---|---|---|
| gopath.nvim | E4 | 3 de-Dateien + 10 eingehende Links | `67e3a5e` |
| color_my_ascii.nvim | E4 | 5 de-Dateien (inkl. `guides/de/`) | `892a388`, `c1b1e8c` |
| fileops.nvim | Pilot | FEATURES-Split, docs/README.md, keymaps-Doppelung, stale which_key-Verweis, README | `da20a87` |
| lib.nvim | Referenz | docs/README.md (Ebenen-Index), 9 tote Links, README | `1dae2fc` |

| *(20 Repos)* | E1 | Alpha-Disclaimer, Zeile 1 — ein Commit je Repo | `a3d4bdd`…`90b9730` |
| mdview.nvim | 1 | docs/README.md, FEATURES/FEATURES.md → MACHINERY.md, 6 Dateien ausgelagert, 2 tote Links, DOC-08/11-Korrekturen | `575cc0b` |
| lsp.nvim | 1 | FEATURES.md → FEATURES/ (9 Seiten), docs/README.md, README 390 → 157, 5 Dateien ausgelagert | `d38ec6e` |
| debugging.nvim | 2 (vorgezogen) | FEATURES-Doppelung aufgelöst, docs/README.md + FEATURES/README.md, `which_key`-Leichen | `7b828ae`, `0d42445` |
| fileops.nvim | Nachtrag | `map/`-Link entfernt (404 auf GitHub) | `b2c18d1` |
| lib.nvim | Nachtrag | dito | `2b7f744` |

**E1 ist damit bei 22/31.** Offen bleiben neun: die drei aus Welle 1 (erledigen
es im eigenen Durchgang) und sechs mit fremder uncommitteter README-Arbeit —
siehe [Ü9](#ü9--ein-zweiter-durchgang-läuft-parallel-und-hält-sechs-repos-besetzt).

**Offen bei bereits angefassten Repos:**
`color_my_ascii.nvim` hat noch **8 tote Links** aus einem alten Doku-Layout
(`./language-detection.md`, `../groups/operators.md` u. a.). Sie sind im Repo
selbst als „Known issue" dokumentiert. Bewusst liegen gelassen — gehören in
den vollen Durchgang (Welle 3), nicht in einen Sprach-Cleanup.

---

## Entscheidungen (E1–E6)

| ID | Frage | Antwort | Von |
|---|---|---|---|
| E1 | Alpha-Disclaimer | Zeile 1 um `Alpha stage — ` ergänzen, 31× skriptbar | delegiert |
| E2 | README-Länge | 100–250 Zeilen; **nicht blind nach `docs/` wandern** | Autor |
| E3 | `wkdbook-myplugins` | `NOTES/` neben `ROADMAP/` | delegiert |
| E4 | Deutsche Dateien | **Entfernen** | Autor |
| E5 | `USECASES/` | Nur bei API **und** mehrschrittiger Aufgabe; pro Repo | delegiert |
| E6 | Pilot | `fileops.nvim`, dann `lib.nvim` | delegiert |

---

## Überraschungen

### Ü1 — Der Alpha-Disclaimer war nie das Problem

Konzept behauptete „2 von 31". Falsch — Artefakt einer Wortsuche nach `alpha`.
Tatsächlich **31/31**, wortgleich, als Zeile 1. Befund A ist korrigiert.

**Lehre:** Nach der *Sache* suchen, nicht nach dem *Wort*.

### Ü2 — BINDINGS: der `roadmap`-Grep überzeichnet

45 Treffer, aber fast alle **legitime Querverweise**. Belastbar sind
stattdessen Changelog-Blöcke (20+ Dateien) und Dateilänge (6 über 350 Zeilen).

### Ü3 — Verwaiste Dokumente sind ein eigener Befundtyp

`fileops.nvim/docs/FEATURES.md`: 414 Zeilen, **null eingehende Links**. Gute
Doku, die niemand findet. `DOC-06` deshalb **früh** prüfen — ein verwaistes
Dokument ändert den Aufwand für alles andere (verlinken statt umschreiben).

### Ü4 — `docs/map/module_map.json` ist flächendeckend veraltet

Nennt Dateien, die es nicht mehr gibt. Kein Doku-Befund (generiert), aber pro
Repo nach dem Umbau mit `:DocMap` neu zu erzeugen.

> **Offen:** Sammel-Regenerierung am Ende (P7) statt 31 Einzelläufe?

### Ü5 — Deutsche Dubletten waren mehr als die fünf gefundenen

`color_my_ascii.nvim/docs/guides/de/` mit drei weiteren, alle verwaist. Die
Bestandsaufnahme suchte nach Datei*namen* mit `-de`/`-DE`; ein Ordner `de/`
fiel durch. **Bei den restlichen Repos auch Verzeichnisnamen prüfen.**

### Ü6 — Mehr Doku-Ebenen können richtig sein *(lib.nvim)*

Der Verdacht „vier Sammelorte = Doppelung" war **falsch**. `API/`, `FEATURES/`,
`guides/`, `EXAMPLES/` sind sauber gegeneinander abgegrenzt, und jede
`README.md` erklärt die Abgrenzung explizit:

- `modules.md` — Namespace-Index, eine Zeile pro Modul (*was existiert*)
- `FEATURES/` — Narrativ pro Thema (*warum, wann greife ich danach*)
- `API/` — Signaturen pro Thema (*wie heißt die Funktion*)
- Modul-`README.md` — autoritative Nutzung (*Details*)
- `EXAMPLES/` — lauffähige Szenarien · `guides/` — Problem→Lösung-Essays

**Lehre für den Standard:** Eine *Bibliothek* braucht mehr Ebenen als ein
Feature-Plugin. Der Standard aus §3 ist das **Minimum**, keine Obergrenze.
Zusätzliche Ebenen sind in Ordnung, wenn jede ihre Abgrenzung selbst erklärt.
Was `lib.nvim` fehlte, war nicht weniger Struktur, sondern der **Wegweiser**
(`docs/README.md`) — der jetzt existiert und die Ebenen benennt.

Ebenso **kein** Befund: `docs/BINDINGS/Usercmds.md` neben `BINDINGS.md`. Die
Ordner-Datei ist **generiert** („Do not edit by hand", vom Composer), und
`BINDINGS.md` verweist korrekt darauf.

### Ü7 — Naive Link-Checks bestehen zu 80 % aus Rauschen

Die gemessene Zahl toter Links über alle Repos wanderte:

| Werkzeugstand | Gemeldet |
|---|---|
| bash, jeder `](…)`-Treffer | 169 |
| + Code-Blöcke und Inline-Code ausgenommen | 118 |
| + nur **git-getrackte** Dateien | **28** |

141 der ursprünglichen 169 waren Artefakte: als Beispiel zitierte Links
(`` `[report](docs/report.pdf)` ``, `replace_format = "[%s](%s)"`) und
gitignorierte Bäume (`lib.nvim/.deps/` allein: 84 Treffer).

**Lehre:** Ein Befundzähler, dem man nicht trauen kann, kostet mehr Zeit als
er spart. Vor dem Flächeneinsatz an einem bekannten Repo eichen.

### Ü8 — Fremde uncommittete Arbeit in `lib.nvim` ⚠️

Beim Commit lagen dort uncommittete Änderungen an einem `deps`-Modul, die
**nicht** aus diesem Durchgang stammten: `lua/lib/nvim/deps/init.lua`,
`@types/init.lua`, `README.md`, `TESTS/deps_spec.lua`,
`doc/lib.nvim-deps.txt`, plus zwei neue Dateien (`require_tool.lua`,
`status.lua`). Sie sind unangetastet im Working Tree geblieben; committet
wurden nur die sechs Doku-Dateien.

> **Regel für alle weiteren Repos:** Vor jedem Commit `git status` lesen und
> **selektiv stagen**. Kein `git add -A` — in diesen Repos wird auch außerhalb
> dieses Durchgangs gearbeitet.

### Ü9 — Ein zweiter Durchgang läuft parallel und hält sechs Repos besetzt ⚠️

Ü8 war kein Einzelfall, sondern die Regel. Ein **deps-installer-Durchgang**
(neues `lib.nvim.deps`-Modul, `:Lib deps show`) rollt gerade
`docs/install.json` plus je eine README-Zeile und eine `health.lua`-Prüfung
über mehrere Repos aus. Betroffen mit **uncommitteter** Arbeit:

`hover.nvim`, `diff.nvim`, `documentation.nvim`, `markdown.nvim`, `open.nvim`,
`language.nvim`, `lib.nvim`, `insights.nvim`.

Das ist kein Fehler — aber für diesen Durchgang eine harte Schranke:

> **Wo das README uncommittet verändert ist, wird es nicht überarbeitet.**
> Ein Commit würde die fremde Zeile mitnehmen, während die von ihr verlinkte
> `docs/install.json` noch untracked ist — also genau den toten Link
> produzieren, den `DOC-07` verhindern soll.

**Folge für die Wellenplanung:** `hover.nvim` ist aus Welle 1 herausgenommen
und wartet, bis sein Working Tree sauber ist. Nachgerückt ist
`debugging.nvim` aus Welle 2. Bei `insights.nvim` reichte selektives Stagen
(nur `README.md`), weil dort das README selbst unberührt war.

**Regel:** `git status` **vor** der Repo-Auswahl lesen, nicht erst vor dem
Commit. Ein besetztes Repo kostet einen ganzen Durchgang, wenn man es erst
nach der Arbeit merkt.

### Ü10 — `docs/map/` ist in 29 von 31 Repos gar nicht im Repo ⚠️

Der Standard führt `docs/map/` als **Pflicht**, und die Bestandsaufnahme
mass 29/31 als vorhanden. Beides beruht auf einem Blick **auf die Platte**.
In Git sieht es anders aus:

| | Repos |
|---|---|
| `docs/map/` getrackt | **2** — `documentation.nvim`, `runtime-analysis.nvim` |
| gitignoriert, mit ausgeschriebener Begründung in `.gitignore` | **29** |

Die `.gitignore`-Begründung ist gut: generiert, in Sekunden aus dem aktuellen
Baum neu baubar, sofort stale, ~40 MB Artefakte. Die Datei gehört nicht ins
Repo. **Aber:** wer sie aus `docs/README.md` verlinkt, produziert einen Link,
der lokal grün ist und auf GitHub 404 liefert. Genau das war in beiden
Referenz-Implementierungen passiert (`fileops.nvim`, `lib.nvim`) — also in den
zwei Repos, an denen sich die übrigen 29 ausrichten sollen.

**Zwei Korrekturen am Standard:**

1. `docs/map/` ist **kein Pflichtbaustein**. Sein Fehlen ist kein `DOC-01`.
2. Ein Repo, das die Map nicht trackt, **verlinkt sie nicht**. Es beschreibt
   sie in Prosa: `:DocMap` baut sie, deshalb liegt sie nicht hier.

**Ü4 ist damit weitgehend erledigt.** Die Frage „Sammel-Regenerierung am Ende
oder 31 Einzelläufe?" stellt sich für 29 Repos nicht — dort gibt es nichts
zu regenerieren, das committet würde. Offen bleibt sie nur für die zwei
Repos, die ihre Map tatsächlich ausliefern.

> **Lehre — die dritte Auflage von Ü1/Ü7:** Auch „existiert die Datei?" ist
> eine Wortsuche, wenn man die falsche Instanz fragt. Erst log Windows über
> die Schreibweise, dann log die Platte über die Auslieferbarkeit. Maßgeblich
> ist, was `git ls-files` sagt — nicht, was der Explorer zeigt.

### Ü11 — Der Linkchecker meldete Grün für Dateien, die er nie gelesen hat

Er liest nur **git-getrackte** Quelldateien (das war Ü7s Fix gegen 141
Falschbefunde). Frisch angelegte Dokumente sind aber noch nicht getrackt.
Nach dem Anlegen von `docs/README.md` meldete er in `debugging.nvim`
unverändert „13 files, 0 dead" — grün, und wertlos.

Beide Fehlerklassen sind jetzt im Werkzeug behoben (siehe
[Werkzeug-Notizen](#scriptsdocs_linkcheckpy)). Die alte Handregel
„**erst `git add`, dann prüfen**" ist damit nicht mehr nötig, schadet aber
nicht.

### Ü12 — ASCII-Art ist 31/31, DOC-24 ist erledigt

`mdview.nvim` galt als das eine Repo ohne ASCII-Block. Es hat einen — nur im
Fence ` ```sh ` statt im nackten ` ``` `. Die Bestandsaufnahme suchte den
nackten Fence.

**Das ist Ü1 zum zweiten Mal**, und beide Male hat dieselbe Vorgehensweise den
Fehler erzeugt: nach der *Schreibweise* gesucht statt nach der *Sache*.
`DOC-24` braucht in keinem Repo mehr geprüft zu werden.

### Ü13 — Der Doku-Bestand endet nicht bei `docs/`

`lsp.nvim` hat **26 Markdown-Dateien unter `lua/`** — 25 legitime
Modul-READMEs (die Ü6 für `lib.nvim` ausdrücklich gesegnet hat), aber
darunter auch zwei `ROADMAP.md`, ein 367-Zeilen-`POC.md` und ein
Installations-Fragment, das bei Punkt „2)" beginnt. `DOC-16` in Reinform, an
einem Ort, an den die Bestandsaufnahme („Dateien unter `docs/`") nie
geschaut hat.

> **Einstieg pro Repo ist ab sofort `git ls-files "*.md"`, nicht
> `find docs/`.**

### Ü14 — Die FEATURES-Doppelung ist nicht symmetrisch

Bei `debugging.nvim` hatte `FEATURES.md` zwei eingehende Links und der Ordner
keinen — aber die **Datei** war die aktuelle und der **Ordner** stammte aus
einem Feature-Log. Der Link-Zähler sagt also, was auffindbar ist, **nicht**,
was stimmt. Das Vorgehen, das funktioniert hat, in dieser Reihenfolge:

1. `grep -rn "FEATURES" --include=*.md .` — die verlinkte Seite ist die
   **inhaltliche Autorität**.
2. Die verwaiste Seite trotzdem ganz lesen, aber nur auf **additive Substanz**
   — was sagt sie, das die andere nicht sagt. *Dieser Schritt ist der einzige,
   an dem echter Inhalt verlorengehen kann.*
3. Alles mit Datum, „moved into lib.nvim", „merged in from the former X"
   fällt weg — Entwicklungsgeschichte, steht im `git log`.
4. Erst danach die Ordner-Aufteilung wählen, entlang der Kategorien der
   autoritativen Seite, unter Wiederverwendung vorhandener Dateinamen.
5. `git rm` der Datei, dann **jeden** eingehenden Link auf
   `FEATURES/README.md` umbiegen.

Bei `replacer.nvim` kommt mit `Feature-Matrix.md` eine dritte Fassung dazu —
dort erst die drei gegeneinander stellen, dann Schritt 1.

### Ü15 — `DOC-04` und `DOC-06` sind derselbe Befund von zwei Seiten

Bei `debugging.nvim` war nicht eine Datei verwaist (Ü3), sondern der **ganze
Sammelordner** — aus einem strukturellen Grund: kein `FEATURES/README.md`
→ nichts kann auf den Ordner zeigen → jede Einzeldatei darin bleibt
unverlinkt.

**Wo `DOC-04` offen ist, ist `DOC-06` mit hoher Wahrscheinlichkeit auch
offen.** Bei `cascade.nvim` (dem zweiten Repo ohne `FEATURES/README.md`)
gleich mitprüfen.

### Ü16 — Wo die private Spec von der README-Spec abweicht, steckt ein Grund dahinter

`debugging.nvim`s README empfiehlt `cmd = "Debug"`. In
`lua/plugins/personal/init.lua` ist genau diese Zeile auskommentiert,
zugunsten von `event = "VeryLazy"` — weil `cmd` `setup()` und damit die sieben
View-Keymaps bis zum ersten `:Debug` verzögert.

**Regel:** Bei jedem Repo die eigene Install-Spec danebenlegen und
Abweichungen als *Frage* behandeln, nicht als Tippfehler (`DOC-13`).

### Ü17 — Gelöschte Module überleben in `doc/*.txt`

`bindings/which_key.lua` war seit zwei Commits weg und stand noch in
`docs/architecture.md`, `docs/FEATURES/CORE.md` **und** `doc/debugging.txt`.
Letzteres ist handgepflegtes Vimdoc, kein Generat — und fällt aus
`docs_linkcheck.py` wie aus jedem `--include=*.md`-Grep heraus.

> **Bei `DOC-14` immer auch über `doc/` greppen.**

### Ü18 — Zwei blinde Flecken, die das Werkzeug nicht schließen wird

- **Anker.** Die README-ToC von `lsp.nvim` enthielt `[Roadmap](#roadmap)` ohne
  zugehörige Überschrift. 0 dead, 0 case — und trotzdem tot. Nach jedem
  README-Umbau die ToC gegen `grep '^## '` gegenprüfen.
- **HTML.** `<img src="./ressources/…">` in `mdview.nvim`s Test-Fixture zeigte
  seit je ins Leere — das Fixture für das Local-Images-Feature testete also
  nichts. `LINK_RE` sieht nur `](…)`.

### Ü19 — Beim Kürzen brechen Zirkelverweise

`lsp.nvim/docs/installation.md` sagte „Other managers … are in the README",
während das README nach dem Kürzen genau dorthin verweisen sollte. Beim
Kürzen also nicht nur prüfen, ob der Inhalt *woanders steht*, sondern auch,
ob das Ziel nicht zurückzeigt. Bei den verbleibenden Ausreißern
(`replacer.nvim` 689, `spotlight.nvim` 652, `runtime-analysis.nvim` 627,
`cascade.nvim` 584, `images.nvim` 546) mit zu erwarten.

### Ü20 — Doppelt gepflegte Referenzen sind ein Fundbüro, kein Befund

`mdview.nvim` hat `BINDINGS.md` (lang, vollständig) neben `commands.md`
(kurz) — gegenüber §3 vertauscht, das `BINDINGS.md` als *kompakt* führt.
Der Agent hat die Rollen gelassen und beide korrigiert, und das war richtig:
**gerade weil sie getrennt gepflegt wurden, hatte jede andere Fehler.** Der
Diff der beiden gegeneinander war der ergiebigste `DOC-08`/`DOC-11`-Fund des
ganzen Durchgangs.

> Doppelt gepflegte Referenzdokumente also erst **gegeneinander diffen**, dann
> über das Zusammenlegen entscheiden.

---

## Abweichungen vom Standard

| Repo | Abweichung | Begründung |
|---|---|---|
| fileops.nvim | Volle `:File`-Tabelle bleibt im README | Das Plugin *ist* ein Kommando — die Tabelle ist der Quickstart, keine Referenz daneben (E2: „nicht blind wandern"). |
| fileops.nvim | Kein `USECASES/` | `api.md` bildet die Subcommands 1:1 ab; kein mehrschrittiger Usecase → E5-Bedingung 2 nicht erfüllt. |
| lib.nvim | Fünf Doku-Ebenen statt der Standard-Struktur | Siehe [Ü6](#ü6--mehr-doku-ebenen-können-richtig-sein-libnvim). Bibliothek, nicht Feature-Plugin. |
| lib.nvim | `GUIDE-ui-kit.md` bleibt in `docs/`, nicht in `guides/` | `guides/` ist laut eigener README für ökosystemweite Problem→Lösung-Essays reserviert. Ein User Guide ist etwas anderes; ein Verschieben würde die Semantik verwässern und zwei Links brechen. |
| mdview.nvim | 22-zeilige Capabilities-Tabelle bleibt im README | Dieselbe Ausnahme wie `fileops.nvim`s `:File`-Tabelle: das Plugin *ist* ein Kommando. |
| mdview.nvim | `FEATURES/` hat 5 statt 4 Themenfiles | `MACHINERY.md` fängt auf, was kein eigenes Kommando hat — in der Overview benannt. |
| lsp.nvim | Nur *ein* Sibling statt 2–3 | `dap.nvim` ist der einzige echte Verwandte (dasselbe Muster, anderes Protokoll). Ein zweiter Name wäre erfunden. Lieber einer mit Begründung. |
| lsp.nvim | Kein `api.md`, kein `USECASES/` | Drei öffentliche Funktionen, jede ein Einzelaufruf → E5-Bedingung 2 nicht erfüllt. Eine Signaturseite für drei Signaturen ist eine Datei mehr, kein Wissen mehr. |
| debugging.nvim | Status-Badge bleibt `active development` (blau) | `bae4dec` hat das Badge-Set repoübergreifend vereinheitlicht. Eines davon zu ändern wäre eine Abweichung, keine Angleichung. |
| debugging.nvim | Eine Code-Änderung im Doku-Durchgang (`DEFAULTS.lua`) | `capture_timeout_ms` war dokumentiert, getypt und wirksam, fehlte aber in der Datei, die sich selbst „single source of truth“ nennt. Alternative wäre gewesen, korrekte Doku zu löschen. |
| alle | `docs/map/` nicht verlinkt und nicht als Pflicht geführt | Siehe [Ü10](#ü10--docsmap-ist-in-29-von-31-repos-gar-nicht-im-repo-️). |

---

## Verschoben nach wkdbook-myplugins

| Datei (Original) | Ziel | Warum |
|---|---|---|
| `mdview.nvim/docs/CI/V_1.0.md` | `mdview.nvim/NOTES/CI-V1.0.md` | 493 Zeilen Node-Ära-CI, selbst als „OUTDATED … History only" markiert, 0 eingehende Links |
| `mdview.nvim/docs/CI/ci.yml` | `…/NOTES/ci.yml` | Stale Kopie, **nicht** identisch mit `.github/workflows/ci.yml` |
| `mdview.nvim/docs/CI/test-report.yml` | `…/NOTES/test-report.yml` | Workflow, den es nicht mehr gibt |
| `mdview.nvim/docs/templates/{autocmds,usercmds}.lua` | `…/NOTES/template-*.lua` | Verwaistes Scaffolding von vor der lib.nvim-Registry bzw. dem Composer-Route-Tree |
| `mdview.nvim/docs/testdoku/mdview/util/diff.md` | `…/NOTES/line-diff-evaluation-plan.md` | Evaluationsmethodik vor dem Ausliefern; nannte Module, die nie so hießen |
| `lsp.nvim/docs/CHECKLISTS/NEW_PROJECT.md` | `lsp.nvim/NOTES/NEW_PROJECT.md` | Quittung eines einmaligen Gate-Durchlaufs, datierte Verlaufseinträge, einzige deutsche Datei unter `docs/` |
| `lsp.nvim/lua/lsp/tools/**/{ROADMAP,POC,InstallationNotes}.md` | `lsp.nvim/NOTES/*` | Roadmap- und Entwurfsmaterial im **Quellbaum** — siehe [Ü13](#ü13--der-doku-bestand-endet-nicht-bei-docs) |

**Gelöscht statt verschoben:** `mdview.nvim/docs/testdoku/commands.md` (zu ~80 %
wortgleiche Doppelung dreier anderer Dateien, die zwei einzigartigen Rezepte
sind gefaltet) und fünf Verlaufsabsätze aus `debugging.nvim/docs/FEATURES/`
(„moved into lib.nvim", „merged in from the former …") — Drei-Fragen-Test
dreimal Nein, und `git log` hat sie vollständig.

> ⚠️ **`E:\repos\WKDBooks` ist nicht committet.** Die 11 verschobenen Dateien
> liegen dort **untracked**, ebenso `MyNotes\docs\README-KONZEPT.md` aus P2.
> Das folgt dem Plan („Konzeptdateien zunächst nicht committen"), muss aber
> vor P7 nachgeholt werden — und dort gilt Ü8/Ü9 genauso: selektiv stagen.

---

## Werkzeug-Notizen

### `scripts/docs_linkcheck.py` (neu)

```bash
python scripts/docs_linkcheck.py E:/repos/<repo>          # eines
python scripts/docs_linkcheck.py E:/repos/*.nvim          # alle
```

Meldet drei Befundklassen. Exit 1 bei Befunden, Laufzeit über alle 31 Repos
**< 1 s**:

| Klasse | Bedeutung |
|---|---|
| `DEAD` | Ziel existiert nicht |
| `CASE` | Ziel existiert, Schreibweise weicht ab — lokal grün, auf GitHub 404 |
| `IGNORED` | Ziel existiert und ist **gitignoriert** — lokal grün, auf GitHub 404 |

`IGNORED` kam am 2026-09-03 dazu (siehe Ü10). Es ist dieselbe Fehlerklasse wie
`CASE`, eine Ebene tiefer: dort log Windows über die Schreibweise, hier log die
Platte über die Auslieferbarkeit. Maßgeblich ist `git check-ignore`, nicht
`os.path.exists`.

Ebenfalls am 2026-09-03 korrigiert: das Skript las als *Quellen* nur
git-getrackte Dateien (Ü7s Fix gegen 141 Falschbefunde) und übersah damit jedes
frisch angelegte Dokument — es meldete Grün für Dateien, die es nie geöffnet
hatte (Ü11). Es liest jetzt `--cached --others --exclude-standard`: alles, was
im Repo ist **oder auf dem Weg hinein**, aber nichts Ignoriertes.

**Warum `CASE` der eigentliche Grund ist:** Windows ist case-insensitiv, und
Pythons `os.path.exists` erbt das. Ein Link `[x](COMMANDS.md)` auf eine Datei
`commands.md` ist lokal grün und auf GitHub ein 404. Das Skript vergleicht
deshalb gegen die echten Verzeichniseinträge. **Pflichtlauf nach jedem Rename**
(`DOC-02` produziert genau diesen Fehler).

Bereits gefunden: `github_stats.nvim/docs/configurations/USER-DEFINED-DATE-PRESETS.md`
→ `../USERCOMMANDS.md`, auf der Platte `usercommands.md`.

**Grenzen** (alle drei in der Praxis aufgetreten, siehe Ü18):

- **Kein `#anchor`.** Ein Verweis auf eine umbenannte Überschrift fällt durch —
  `lsp.nvim`s README-ToC hatte `[Roadmap](#roadmap)` ohne die Überschrift.
- **Kein HTML.** `<img src="…">` wird nicht gesehen; `mdview.nvim`s
  Bild-Fixture zeigte deshalb seit je ins Leere.
- **Nur Markdown.** Handgepflegtes Vimdoc unter `doc/*.txt` fällt heraus, und
  genau dort überlebte in `debugging.nvim` ein seit zwei Commits gelöschtes
  Modul (Ü17).

**Vorgänger:** Ein bash-Skript gleichen Zwecks ist gelöscht — zu langsam
(> 2 min statt < 1 s), case-blind, und ohne Code-Block-Filter (siehe Ü7).

### Bestandsprüfer: `:DocMap` kann das teilweise auch

`color_my_ascii.nvim/docs/guides/README.md` verweist auf `:DocMap`, das tote
Links als `dead-readme-link` flaggt. Überschneidung ist gewollt: `docs_linkcheck.py`
läuft ohne nvim, prüft case-sensitiv und eignet sich für den Flächenlauf;
`:DocMap` ist das Werkzeug in der Sitzung.

### Offene Befundliste (Stand 2026-09-04, nach dem Werkzeug-Fix)

| Repo | dead | case | ignored |
|---|---|---|---|
| color_my_ascii.nvim | 8 | 0 | 0 |
| github_stats.nvim | 6 | **1** | 0 |
| gopath.nvim | 1 | 0 | 0 |
| insights.nvim | 1 | 0 | 0 |
| pickers.nvim | 1 | 0 | 0 |

Die übrigen 26 Repos sind link-sauber. Erledigt seit der letzten Zählung:
`mdview.nvim` (2), `documentation.nvim` (4), `fileops.nvim` und `lib.nvim`
(je 1 `IGNORED`).

Die 8 in `color_my_ascii.nvim` stammen aus einem alten Doku-Layout und sind im
Repo selbst als „Known issue“ dokumentiert — sie gehören in dessen vollen
Durchgang (Welle 3). `gopath.nvim`s Restmeldung ist ein `LICENSE`-Verweis aus
`docs/Developer-Notes/`, der ins Repo-Root zeigen müsste. `insights.nvim`
verweist im README auf ein `docs/features.md`, das es nicht gibt.


### Bekannte blinde Flecken der Bestands-Werkzeuge

Stehen in `LAST_CDX_TASKS.md` §8. Hier nur Neues.

*(bisher nichts)*
