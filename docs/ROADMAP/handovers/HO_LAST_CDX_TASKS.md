# Handover — LAST_CDX_TASKS

Begleitdatei zur Umsetzung von
[`docs/ROADMAP/personal/All/FINISH/LAST_CDX_TASKS.md`](../personal/All/FINISH/LAST_CDX_TASKS.md).

**Angelegt 2026-09-03. Stand: P0–P3.5 erledigt, P4 läuft — E1 ist 31/31,
Wellen 1–3 vollständig (11 Repos), alle toten Anker der Sammlung behoben.**

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
| P4 — Wellen 1–10 | 🟨 läuft | 2026-09-04 | E1 **31/31**; **Wellen 1–3 vollständig** — 11 Repos, vier davon still erledigt (siehe Ü25). Offen: Wellen 4–10, 21 Repos |
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
| gopath.nvim | Nachtrag | `LICENSE`-Link aus `Developer-Notes/` zeigte neben sich statt ins Root | `cbdd322` |
| insights.nvim | Nachtrag | README verwies auf ein nie geschriebenes `docs/features.md` | `62928cb` |
| pickers.nvim | Nachtrag | `DOC-14`: which-key-Abschnitt beschrieb ein gelöschtes Modul | `95866f6` |
| github_stats.nvim | Nachtrag | 7× `configurations/`, 1× `usercommands.md` (Case) | `acb9857` |
| reposcope.nvim | 2 | FEATURES-Doppelung, 6 Case-Renames, `docs/README.md`, `health.md`, README 93 → 138, 3 tote Anker, DOC-11 (5 Keys) | `b35b795` |
| *(5 Repos)* | E1 (Nachtrag) | `diff`, `documentation`, `language`, `markdown`, `open` — nach Ü9-Freigabe | `a2a5ee5`…`a269b2b` |
| hover.nvim | 1 | Voller Durchgang. **Ein** inhaltlicher Befund: `FEATURES/README.md` beschrieb das Quiet-Modell als zwei Achsen, wo die Seite drei hat. Struktur war bereits vollständig; E1 war es auch | `1588f2c` |
| replacer.nvim | 2 | **Im Repo selbst gelaufen, hier nicht eingetragen** (Ü25). FEATURES-Katalog zusammengeführt, `docs/README.md`, README 689 → 125. Nachgeprüft 2026-09-04: 0 Befunde | `8c3fb0e` |
| color_my_ascii.nvim | 3 | dito. Wegweiser, Fixture zu den Specs, Planungsmaterial raus, README → 120. **Die 8 „Known issue"-Links sind weg**; nachgeprüft: 0 tote Links, 0 tote Anker | `bfb74da` |
| gopath.nvim | 3 | dito (`4c1f17c`). Danach **19 Emoji-Überschriften** korrigiert, deren Anker niemand treffen konnte — zwei davon lösten auf den *falschen* Abschnitt auf. Siehe Ü27 | `4c1f17c`, `502272d` |
| documentation.nvim | 3 | dito. README auf eine Bildschirmseite, Themenseiten kleingeschrieben, vier fehlende ergänzt. Offen: `docs/hover.md` ist verwaist | `5d74e96` |
| lsp.nvim | Nachtrag | vier ToC-Anker in `markdown_words/README.md`, alle tot aus demselben Emoji-Grund | `2a59f91` |
| fileops.nvim | Nachtrag | `commands.md#file-delete` → `#file-delete-`; die Klammern der Signatur lassen ihr Leerzeichen zurück | `373026b` |

**E1 ist bei 31/31** — siehe [Ü23](#ü23--drei-behauptungen-des-standards-über-hovernvim-waren-am-tag-der-welle-nicht-mehr-wahr), das die letzte offene Zeile aufgelöst hat, ohne dass sie eine war. Der deps-Durchgang aus
[Ü9](#ü9--ein-zweiter-durchgang-läuft-parallel-und-hält-sechs-repos-besetzt-️) hat
am 2026-09-04 committet und damit alle sechs blockierten Repos freigegeben.
Fünf davon haben die Zeile nachgetragen bekommen (`diff.nvim`,
`documentation.nvim`, `language.nvim`, `markdown.nvim`, `open.nvim`); offen ist
nur noch `hover.nvim` — und das war es bereits, ohne dass die Ledger-Zeile es
wusste. Siehe [Ü23](#ü23--drei-behauptungen-des-standards-über-hovernvim-waren-am-tag-der-welle-nicht-mehr-wahr).

> Die Schranke aus Ü9 ist damit gefallen, die **Regel** dahinter nicht:
> `git status` bleibt der erste Blick vor der Repo-Auswahl, nicht der letzte
> vor dem Commit.

**~~Offen bei bereits angefassten Repos:~~ erledigt.** `color_my_ascii.nvim`
hatte **8 tote Links** aus einem alten Doku-Layout, im Repo selbst als „Known
issue" dokumentiert und bewusst dem vollen Durchgang überlassen. Der ist
gelaufen (`bfb74da`), und sie sind weg — nachgemessen 2026-09-04: 0 tote
Links, 0 tote Anker. Siehe [Ü25](#ü25--vier-weitere-repos-waren-fertig-ohne-dass-es-hier-stand).

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
[Werkzeug-Notizen](#scriptsdocs_linkcheckpy-neu)). Die alte Handregel
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
  **Zwei Sonderfälle, in `reposcope.nvim` beide aufgetreten:** eine *nummerierte*
  Überschrift `## 1. Keymaps` erzeugt `#1-keymaps`, nicht `#keymaps` — und ein
  Anker auf eine **fett gesetzte Zeile** statt eine Überschrift zeigt ins Leere,
  weil eine fette Zeile keinen Anker hat. Der Fix für den zweiten Fall ist,
  die fette Zeile zu einer echten `###` zu machen, nicht den Link zu löschen.
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

### Ü21 — Die vier „Restmeldungen“ waren vier verschiedene Fehlerklassen

Die Liste sah nach Aufräumarbeit aus: neun tote Links über vier Repos, alle
klein. Tatsächlich war kein einziger ein Tippfehler, und keine zwei hatten
dieselbe Ursache:

| Repo | Link | Ursache |
|---|---|---|
| gopath.nvim | `[LICENSE](LICENSE)` aus `docs/Developer-Notes/` | Pfad gedacht wie im Repo-Root, geschrieben zwei Ebenen tiefer |
| insights.nvim | `docs/features.md` | **Nie geschrieben.** Das README versprach eine Adresse, die niemand angelegt hat |
| pickers.nvim | `bindings/whichkey.lua` | Modul **bewusst** gelöscht (`9b3247d`) |
| github_stats.nvim | `configuration/` (7×), `USERCOMMANDS.md` (1×) | Ordner heißt `configurations/`; Windows verdeckt beides |

Der `pickers.nvim`-Fall ist der teuerste und der einzige, den ein Linkchecker
nur zufällig findet. Der tote Link war das Symptom; der Befund war ein
**Abschnitt, der ein entferntes Feature weiterhin als vorhanden beschreibt**
(`DOC-14`). `whichkey.lua` wurde entfernt, weil which-key die Mappings ohnehin
selbst liest und jedes aus dessen eigenem `desc` beschriftet — das Modul gab
einer Zeichenkette einen zweiten Ort zum Auseinanderdriften. Der Abschnitt ist
deshalb **umgeschrieben**, nicht umgebogen.

> **Lehre:** Einen toten Link nie nur umbiegen. Erst fragen, **warum** das Ziel
> weg ist. In einem von vier Fällen war die Antwort „weil das beschriebene
> Feature weg ist“ — dann ist Umbiegen die falsche Reparatur, und der
> Linkchecker hat einen `DOC-14`-Befund gefunden, nach dem er gar nicht sucht.

Nebenbei bestätigt: [Ü10](#ü10--docsmap-ist-in-29-von-31-repos-gar-nicht-im-repo-️)s
korrigierte Zahl stimmt. Über alle 31 Repos mit `git ls-files docs/map`
gemessen, trackt sie **genau zwei**: `documentation.nvim` und
`runtime-analysis.nvim`, je drei Dateien.

### Ü22 — Was die Doku über die *Umgebung* behauptet, prüft niemand ⚠️

`DOC-11` fragt nach Config-Keys, und dafür gibt es mit `@types`/`DEFAULTS` eine
Gegenprobe. Für drei andere Sorten von Behauptungen gibt es keine — und in
`reposcope.nvim` war jede einzelne davon falsch:

| Behauptung | Wirklichkeit |
|---|---|
| README + Badge: **Neovim 0.9+** | `vim.uv` ungeguarded an **sechs** Stellen → braucht 0.10+ |
| Doku: Cache liegt unter `stdpath("data")/reposcope` | `config/init.lua:29` schreibt nach `stdpath("cache")/reposcope`. Der genannte Ordner war **nie** belegt |
| Badge: `beta` | Disclaimer und Commit `8dc533c` sagen `alpha` |

Keine dieser drei hätte ein Test gefangen: die CI testet nur `stable`, prüft die
0.9-Zusage also nie; ein Pfad in Prosa hat ohnehin keinen Test; und ein Badge ist
ein Bild.

> **Lehre — `DOC-28`:** `DOC-11` endet nicht bei Config-Keys. Version, Pfade und
> Badges sind genauso Behauptungen über die Wirklichkeit, nur ohne Gegenprobe.
> Pro Repo drei Greps: die Versionszusage gegen `vim.uv`/neuere APIs, jeden
> `stdpath`-Pfad der Doku gegen den Code, und das Status-Badge gegen Zeile 1.

**Der Versionsfall ist nicht abgeschlossen.** Der Agent hat die *Doku an den
Code* angeglichen (0.10+), weil eine Doku-Session keinen Code ändert — richtig
entschieden, aber die Frage bleibt offen: `readme_cache.lua`, `wget.lua`,
`repos.lua`, `repo_status.lua` und `repo_updater.lua` schreiben bereits
`(vim.uv or vim.loop)`. Die Inkonsistenz sitzt also **im Code, nicht in der
Absicht** — jemand wollte 0.9 unterstützen und hat es an sechs Stellen
vergessen. Entweder sechs Zeilen nachziehen oder die 0.9-Absicht bewusst
aufgeben. → Entscheidung des Autors.

### Ü23 — Drei Behauptungen des Standards über `hover.nvim` waren am Tag der Welle nicht mehr wahr

`hover.nvim` ist im Standard das Paradebeispiel des Ausreißers: §5.2 nennt es
mit **1123 Zeilen** README als Ursache von Befund G, §5.3 mit **13** genannten
Geschwister-Plugins, und die Ledger-Zeile führte es als das letzte Repo mit
offenem E1. Gemessen am 2026-09-04, vor der Arbeit:

| Behauptung | Bestandsaufnahme (2026-09-03) | Gemessen (2026-09-04) |
|---|---|---|
| README-Länge | 1123 Zeilen | **191** — mitten im E2-Korridor |
| Genannte Geschwister | 13 | **3**, plus `lib.nvim` im Dependency-Absatz |
| E1 offen | ja | **nein** — die Zeile stand wortgleich da |

Alle drei gehen auf **einen** Commit zurück: `40153a7` („a README that fits on
one screen"), am 2026-09-04 im Repo selbst entstanden, ohne Bezug auf diesen
Durchgang. Er hat 1124 auf 188 Zeilen gekürzt, die Geschwisterliste auf drei
zusammengestrichen — und dabei E1s Wortlaut mitgenommen: davor las Zeile 1
`> **Active development.**`, danach `> **Alpha stage — active development.**`,
buchstabengleich mit den anderen 30.

**E1 ist damit 31/31, und die offene Ledger-Zeile war ein Buchhaltungsartefakt.**
Was E1 *änderte*, war der Wortlaut, nicht die Position — und der Wortlaut war
da.

**Das ist Ü1/Ü7/Ü10 zum vierten Mal, in einer neuen Variante.** Die ersten drei
Male war die Frage falsch gestellt (nach dem Wort statt der Sache, ohne
Code-Block-Filter, gegen die Platte statt gegen Git). Hier war die Frage
richtig gestellt und die **Antwort abgelaufen**: eine Bestandsaufnahme ist eine
Messung mit Datum, und zwischen ihr und der Welle liegt in einem aktiven Repo
ein Tag Arbeit.

> **Regel:** Am Anfang der eigenen Welle neu messen, nicht die Zahl aus der
> Bestandsaufnahme übernehmen. Es kostet ein `wc -l README.md` und einen Grep,
> und es hätte hier einen ganzen geplanten Umbau eingespart.

**Was der Durchgang tatsächlich gefunden hat: genau einen inhaltlichen
Befund** — `docs/FEATURES/README.md` beschrieb das Quiet-Modell als **zwei**
Achsen, während `QUIET.md` eine Überschrift „The third axis, added when the
first two could not express it" trägt und das README-Einzeiler bereits „three
axes" sagte. Gefunden mit [Ü20](#ü20--doppelt-gepflegte-referenzen-sind-ein-fundbüro-kein-befund)s
Methode: jeder Index ist für sich plausibel, erst das Paar ist widersprüchlich.

**Nebenbefund, für den Autor und nicht für dieses Repo:** die Position des
Disclaimers ist repoübergreifend uneinheitlich. 29 Repos haben ihn auf Zeile 1
(über dem Titel), drei nicht — `hover.nvim` (32), `replacer.nvim` (21),
`reposcope.nvim` (24) —, und `mdview.nvim` hat ihn **zweimal**. Zeile 1 ist die
Mehrheitspraxis (P4), Position 4 ist das, was §5.1 vorschreibt. Beide Regeln
gelten, und sie widersprechen sich. → Entscheidung des Autors; bis dahin folgt
`hover.nvim` §5.1.

**Und ein Muster, das andere Repos übernehmen könnten:** die B-Sektion der
Checkliste ist in `hover.nvim` nicht einmalig geprüft, sondern **in der eigenen
Suite verdrahtet**. `TESTS/docs_spec.lua` lässt CI rot werden, wenn eine Route
undokumentiert ist (`DOC-08`), ein Augroup fehlt (`DOC-09`), eine geliehene
Taste in keiner Tabelle steht (`DOC-10`), ein Config-Key in
`docs/configuration.md` nicht in `DEFAULTS` existiert (`DOC-11`) oder
`doc/hover.txt` die Schalter in anderer Reihenfolge listet als
`hover.set()` (`DOC-14`). Das ist der einzige Weg, auf dem diese Befunde nicht
wiederkommen — ein Durchgang prüft einmal, eine Spec bei jedem Commit.

### Ü24 — Zwei blinde Flecken aus Ü18 sind mit je 15 Zeilen prüfbar

`docs_linkcheck.py` sieht keine Anker. Für `hover.nvim` wurden beide fehlenden
Prüfungen ad hoc nachgezogen und liefen sauber (0 Befunde bei 21 Dateien):

- **Datei-interne Anker** — jeden `](#…)` gegen die Überschriften der eigenen
  Datei, slugifiziert.
- **Datei-übergreifende Anker** — jeden `](andere.md#…)` gegen die
  Überschriften *jener* Datei. Das ist der Fall, den Ü18 an `lsp.nvim`s ToC
  nur zur Hälfte beschreibt, und der mit `docs/README.md` als Wegweiser
  häufiger wird.

Beides gehört ins Werkzeug, nicht in 31 Einzelläufe. **Am 2026-09-04 gebaut**,
als `scripts/docs_anchorcheck.py` — als *Nachbar* von `docs_linkcheck.py` statt
als Änderung daran, weil das bewährte Skript nicht für eine Erweiterung
angefasst werden muss. Es hat auf Anhieb 21 tote Anker in drei Repos gefunden
(siehe [Ü27](#ü27--emoji-im-titel-der-anker-behält-das-leerzeichen-gemessen)),
und drei eigene Fehler produziert, bevor es das konnte
([Ü28](#ü28--der-prüfer-hatte-drei-fehler-und-jeder-erzeugte-eine-welle-falschbefunde)).

**Drei Fallen stecken in der Slug-Regel, und die ersten beiden haben in dieser
Prüfung zugeschlagen** — wer sie ins Werkzeug einbaut, spart sie sich:

1. **Leerzeichen werden nicht kollabiert.** GitHub ersetzt *jedes* durch einen
   Bindestrich. `## Ü9 — Ein zweiter` wird `ü9--ein-zweiter`, mit zwei
   Bindestrichen, weil der Gedankenstrich zwischen zwei Leerzeichen wegfällt.
   Ein `\s+` statt `\s` meldet jeden solchen Anker als tot — die erste Fassung
   dieser Prüfung meldete so 14 Befunde, von denen keiner einer war.
2. **Inline-Code enthält Beispiel-Anker.** Ü18 selbst zitiert
   `` `[Roadmap](#roadmap)` `` als Beispiel eines toten Ankers. Ohne
   Code-Filter zählt der Prüfer das als Befund — [Ü7](#ü7--naive-link-checks-bestehen-zu-80--aus-rauschen)
   noch einmal, eine Ebene tiefer.
3. **Emoji in Überschriften sind ungeklärt.** `### Ü9 … besetzt ⚠️` und
   `### Ü10 … im Repo ⚠️` erzeugen einen Slug, dessen Ende von GitHubs
   Emoji-Behandlung abhängt, und die ist nicht nachgebaut. Die Links auf beide
   sind hier **ungeprüft** stehen geblieben statt auf Verdacht umgeschrieben.
   Wer den Prüfer baut, klärt diesen Fall an einer gerenderten Seite, nicht am
   Regex.

Ein Befund war echt und ist behoben: der Verweis auf die Werkzeug-Notizen zeigte
auf `#scriptsdocs_linkcheckpy`, während die Überschrift `(neu)` trägt und damit
auf `-neu` endet.

### Ü25 — Vier weitere Repos waren fertig, ohne dass es hier stand

[Ü23](#ü23--drei-behauptungen-des-standards-über-hovernvim-waren-am-tag-der-welle-nicht-mehr-wahr)
war kein Einzelfall. Vor der Auswahl von Welle 2/3 einmal alle 32 Repos gegen
den Standard gemessen statt gegen dieses Ledger:

| Behauptung | Bestandsaufnahme | Gemessen 2026-09-04 |
|---|---|---|
| `docs/README.md` vorhanden | „2 von 31" | **11 von 32** |
| `replacer.nvim` README | 689 Zeilen, drei FEATURES-Fassungen (Ü14) | **125**, ein Ordner, ein Katalog |
| `color_my_ascii.nvim` | 8 tote Links, „Known issue" | **0** |
| Welle 2/3 offen | `replacer`, `color_my_ascii`, `gopath`, `documentation` | alle vier **gelaufen** |

Die vier Durchgänge stehen als Commits in den Repos selbst, alle vom
2026-09-04 und alle in der Form dieses Projekts: `8c3fb0e`, `bfb74da`,
`4c1f17c`, `5d74e96`. Sie sind hier nur nie eingetragen worden.

**Die elf Repos mit `docs/README.md` sind exakt die elf mit Durchgang** —
Pilot, Referenz und die Wellen 1–3. Damit ist P4 zu einem Drittel fertig, und
was bleibt, sind die 21 Repos der Wellen 4–10.

> **Regel, verschärft:** die Repos sind kein stehendes Ziel. Vor jeder Welle
> einmal breit messen — das kostet einen Durchlauf über 32 Verzeichnisse und
> hätte hier vier geplante Durchgänge eingespart, von denen keiner nötig war.

### Ü26 — `WORKFLOW.md` ist in 16 Repos verwaist, und das ist ein Befund

Über alle 32 Repos gemessen: `docs/WORKFLOW.md` ist eine **Pflichtdatei**
nach §3, und in 16 Repos zeigt nichts darauf. Der Zufall daran ist keiner:

> Es sind **genau** die Repos ohne `docs/README.md` — und **kein einziges**
> der elf mit Index hat das Problem.

Das ist [Ü15](#ü15--doc-04-und-doc-06-sind-derselbe-befund-von-zwei-seiten)
eine Ebene höher. Dort war es der Sammelordner ohne Overview, hier ist es das
`docs/`-Verzeichnis ohne Wegweiser: eine Pflichtdatei, die von keiner Seite aus
erreichbar ist, weil es die Seite nicht gibt, von der aus man sie erreichen
würde. `WORKFLOW.md` trifft es zuerst, weil es die einzige Pflichtdatei ist,
auf die ein README typischerweise *nicht* von sich aus verweist —
`installation.md`, `configuration.md` und `commands.md` sind im README
ohnehin verlinkt.

**Damit ist der Satz des Standards belegt**, `docs/README.md` sei „die größte
echte Neuerung dieses Standards": es ist nicht eine Datei mehr, es ist die
Datei, die den Rest überhaupt auffindbar macht. Wer in Welle 4–10 nur eine
Sache pro Repo tun kann, tut diese.

### Ü27 — Emoji im Titel: der Anker behält das Leerzeichen. Gemessen.

[Ü24](#ü24--zwei-blinde-flecken-aus-ü18-sind-mit-je-15-zeilen-prüfbar)s dritte
Falle ist geklärt, und zwar so, wie sie es verlangt hat — an einer gerenderten
Seite, nicht am Regex. GitHub liefert für `## 🧩 Provider System`:

```
id="user-content--provider-system"     href="#-provider-system"
```

Das Emoji fällt als Interpunktion weg, **sein Leerzeichen nicht** — es wird
zum führenden Bindestrich. Dasselbe am anderen Ende: `` ## `:File[!] delete [%]` ``
ist `#file-delete-`, mit hinterem Bindestrich, gemessen an fileops' gerenderter
`commands.md` neben `#file-move--dest` für den Nachbarn, der auf ein Argument
endet.

Jede von Hand oder von einem Generator geschriebene ToC schreibt die
naheliegende Form. **21 tote Anker in drei Repos**, alle aus diesem einen
Grund: gopath 17, lsp 4 — dazu fileops' einer aus der Interpunktion.

**Zwei davon waren schlimmer als tot.** In gopaths Developer-Notes lösten
`#architecture` und `#resolution-flow` sauber auf — nur auf ein `#### Architecture`
weiter unten unter *Configuration*. Ein Link, der still am falschen Abschnitt
landet, ist für jeden Prüfer grün und für den Leser falsch. **Das findet kein
Werkzeug**, nur Lesen.

Repariert wurde am **Ziel**, nicht am Link: das Emoji fliegt aus der
Überschrift, damit der Anker der ist, den jede ToC ohnehin schreibt — dieselbe
Entscheidung wie in [Ü18](#ü18--zwei-blinde-flecken-die-das-werkzeug-nicht-schließen-wird)s
Fall der fetten Zeile. Nur bei fileops andersherum: dort sind die drei
Kommando-Überschriften eine konsistente Signaturform, und eine davon für einen
Link zu verbiegen tauscht einen kaputten Link gegen eine inkonsistente
Referenzseite.

Nicht angefasst: vier weitere Dateien in `lsp.nvim` mit Emoji-Überschriften,
auf die **nichts** zeigt. Da ist kein Defekt, nur ein Stil — die Falle liegt
dort latent, jede später geschriebene ToC ist bei Geburt tot.

### Ü28 — Der Prüfer hatte drei Fehler, und jeder erzeugte eine Welle Falschbefunde

[Ü7](#ü7--naive-link-checks-bestehen-zu-80--aus-rauschen) zum dritten Mal, in
einem Werkzeug, das ich selbst geschrieben habe, um Ü7s Lehre umzusetzen. Der
Reihe nach gefunden — jeder Fehler dadurch, dass ein Befund gegen die
Wirklichkeit geprüft wurde statt geglaubt:

1. **`\s+` statt `\s`.** GitHub kollabiert Leerzeichenfolgen nicht. 14 gemeldete
   Anker in dieser Datei, keiner davon tot.
2. **Keine Duplikat-Suffixe.** Drei `## Added` in einem Changelog sind
   `#added`, `#added-1`, `#added-2`. Ohne die Regel ist jede Wiederholung tot.
3. **`` ```.*?``` `` als Fence-Erkennung.** Eine Prosa-Zeile, die einen Fence
   **zitiert** — ```` ```` ```ascii-mylang ```` ```` — öffnet damit einen, und
   alles bis zum nächsten Fence gilt als Code. In `color_my_ascii.nvim` hat das
   zwei Überschriften verschluckt und **36 Befunde** erzeugt, von denen genau
   null einer war. CommonMark verbietet einen Backtick im Info-String eines
   Backtick-Fences; genau diese Regel fehlte.

Nach allen dreien: **0 tote Anker** in der ganzen Sammlung, bis auf vier in
`mdview.nvim/TESTS/testfile.md` — eine Fixture mit absichtlich kaputten Links,
also kein Befund.

> **Lehre:** ein Befundzähler ist erst dann ein Werkzeug, wenn seine Zahl
> einmal gegen die Wirklichkeit gehalten wurde. Bis dahin ist er eine Meinung
> mit Nachkommastellen. Die drei Fehler oben haben zusammen 53 Falschbefunde
> produziert und keinen einzigen echten verdeckt — die Richtung ist gnädig,
> die Kosten sind es nicht.

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
| reposcope.nvim | `DEVELOPMENT.md` → `troubleshooting.md`, nicht `development.md` | Der Inhalt war Symptome plus Dateipfade — also genau der Standard-Slot. Ein drittes, im Standard nicht vorgesehenes Dokument zu erfinden wäre schlechter gewesen. |
| reposcope.nvim | `docs/health.md` angelegt, obwohl [BEDINGT] | Es *gibt* einen checkhealth-Provider, und „was bedeutet diese WARN-Zeile“ hatte keine Adresse. |
| reposcope.nvim | Datierte Messwerte in `configuration.md` und `FEATURES/UI.md` bleiben | Ein datierter Messwert ist **Evidenz**, kein Changelog. `DOC-17` trifft „now/used to“-Formulierungen, nicht Messungen mit Stichtag. |
| hover.nvim | Alpha-Disclaimer auf Position 4 statt Zeile 1 | §5.1 schreibt genau diese Reihenfolge vor (ASCII → Badges → Ein-Satz → Disclaimer), und `40153a7` folgt ihr. Die Mehrheitspraxis (P4) ist Zeile 1. Beides sind Regeln dieses Durchgangs — siehe [Ü23](#ü23--drei-behauptungen-des-standards-über-hovernvim-waren-am-tag-der-welle-nicht-mehr-wahr). |
| hover.nvim | Kein `USECASES/`, obwohl E5s beide Bedingungen erfüllt sind | Es *gibt* eine API und eine mehrschrittige Aufgabe (eine Contribution registrieren). Sie hat aber schon zwei Adressen und ein lauffähiges Beispiel: `api.md` trägt die Signaturen und den Vertrag, `FEATURES/CONTRIBUTIONS.md` das Warum, `scripts/onrequest_probe.lua` den Durchlauf. Eine dritte Adresse für denselben Weg wäre `DOC-18`, keine Ebene. |
| hover.nvim | Kein `troubleshooting.md` [BEDINGT] | Das Symptom-Material hat zwei Adressen, die *verschiedene* Fragen beantworten: `WORKFLOW.md` „When nothing hovers, ask before you guess" nennt die Werkzeuge und ihre Reihenfolge (`:Hover why` vor `:checkhealth`), `integrations.md` „Reading a symptom back to its owner" liest jedes Symptom auf das Plugin zurück, dem es gehört. Beide sind in `docs/README.md` **nach Symptom** benannt. Der `reposcope`-Präzedenzfall legte eine Datei an, weil es *keine* Adresse gab; hier gäbe es eine dritte. |
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

### `scripts/docs_anchorcheck.py` (neu, 2026-09-04)

```bash
python scripts/docs_anchorcheck.py E:/repos/<repo>          # eines
python scripts/docs_anchorcheck.py E:/repos/*.nvim          # alle
```

Der Nachbar von `docs_linkcheck.py`, dessen eigener Kopf die Lücke benennt:
Anker werden dort abgeschnitten, „so a wrong #heading is NOT caught". Hier
werden sie geprüft, dazu `DOC-06`:

| Klasse | Bedeutung |
|---|---|
| `ANCHOR dead` | `](#ueberschrift)` ohne diese Überschrift — die Datei existiert, der Linkchecker meldet grün |
| `ANCHOR dead cross-file` | dasselbe über Dateigrenzen, `](andere.md#ueberschrift)` |
| `DOC-06 orphan` | eine getrackte Markdown-Datei, die keine andere beim Namen nennt |

**Was es nicht sieht, und das ist die schärfere Hälfte:** einen Anker, der auf
den **falschen** Abschnitt auflöst. Genau das stand in gopaths Developer-Notes
und ist hier grün. Nur Lesen findet das.

Die vier Slug-Regeln stehen im Kopf des Skripts, jede mit dem Falschbefund
daneben, den ihr Fehlen erzeugt hat — siehe
[Ü28](#ü28--der-prüfer-hatte-drei-fehler-und-jeder-erzeugte-eine-welle-falschbefunde).
Zwei davon sind an gerenderten GitHub-Seiten gemessen, nicht hergeleitet.

### Bestandsprüfer: `:DocMap` kann das teilweise auch

`color_my_ascii.nvim/docs/guides/README.md` verweist auf `:DocMap`, das tote
Links als `dead-readme-link` flaggt. Überschneidung ist gewollt: `docs_linkcheck.py`
läuft ohne nvim, prüft case-sensitiv und eignet sich für den Flächenlauf;
`:DocMap` ist das Werkzeug in der Sitzung.

### Offene Befundliste (Stand 2026-09-04, nach dem Anker-Durchgang)

**Tote Links: einer in der ganzen Sammlung.**

| Repo | Befund |
|---|---|
| casedesk.nvim | `lua/casedesk/templates/Research.md` → `../Replies/00_PSO.md` — in einem Template unter `lua/`, also [Ü13](#ü13--der-doku-bestand-endet-nicht-bei-docs)-Gebiet |

Die 8 in `color_my_ascii.nvim` sind **weg**, mit dessen vollem Durchgang
(`bfb74da`, siehe [Ü25](#ü25--vier-weitere-repos-waren-fertig-ohne-dass-es-hier-stand)).
Früher am 2026-09-04 erledigt: `gopath.nvim`, `insights.nvim`, `pickers.nvim`
(je 1 `dead`) und `github_stats.nvim` (6 `dead` + 1 `CASE`) — siehe
[Ü21](#ü21--die-vier-restmeldungen-waren-vier-verschiedene-fehlerklassen).

**Tote Anker: keiner.** 21 in drei Repos gefunden und behoben
([Ü27](#ü27--emoji-im-titel-der-anker-behält-das-leerzeichen-gemessen)); die
vier verbleibenden Meldungen liegen in `mdview.nvim/TESTS/testfile.md`, einer
Fixture mit absichtlich kaputten Links.

**Verwaiste Dokumente (`DOC-06`): 48**, und sie sind kein Sammelsurium:

| Was | Zahl | Einordnung |
|---|---|---|
| `docs/WORKFLOW.md` | **16** | Pflichtdatei ohne eingehenden Link — siehe [Ü26](#ü26--workflowmd-ist-in-16-repos-verwaist-und-das-ist-ein-befund). Löst sich mit `docs/README.md` |
| Modul-`README.md` unter `lua/` | ~12 | Von [Ü6](#ü6--mehr-doku-ebenen-können-richtig-sein-libnvim) ausdrücklich gesegnet. **Kein Befund**, solange der Modulbaum sie trägt |
| Fixtures unter `TESTS/` | ~6 | Testdaten, keine Doku. Kein Befund |
| Echte Waisen in `docs/` | ~14 | Der Rest, pro Repo zu prüfen — z. B. `documentation.nvim/docs/hover.md`, `language.nvim/docs/FEATURES/*.md` (vier Stück, die die eigene `FEATURES/README.md` nicht nennt), `cmdlog.nvim/docs/FEATURES/README.md` |

> Der Prüfer kennt den Unterschied zwischen diesen vier Sorten nicht und soll
> ihn nicht kennen. Er meldet „niemand nennt diese Datei"; welche Sorte das ist,
> entscheidet der Durchgang.

### Bekannte blinde Flecken der Bestands-Werkzeuge

Stehen in `LAST_CDX_TASKS.md` §8. Hier nur Neues.

- **Ein Anker, der auf den falschen Abschnitt auflöst**, ist für jedes Werkzeug
  grün. In `gopath.nvim` sind zwei ToC-Einträge auf ein gleichnamiges
  `####` weiter unten gefallen, weil die gemeinte Überschrift ein Emoji trug
  und damit einen anderen Anker hatte. Gefunden beim Lesen, nicht beim Prüfen —
  siehe [Ü27](#ü27--emoji-im-titel-der-anker-behält-das-leerzeichen-gemessen).
