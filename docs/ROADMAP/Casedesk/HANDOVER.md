# casedesk — Handover

> **Seit 2026-10-02 ist diese Datei nur noch der „Erkenntnisse und
> Arbeitsweise“-Teil.** Wer eine Sitzung startet, liest zuerst
> [`../IMPLEMENTIERUNGSPLAN.md`](../IMPLEMENTIERUNGSPLAN.md) (Stand, Plan,
> Entscheidungen) und danach §2, §4 und §6 hier. §1 und §3 sind ausgelagert,
> weil alles darin erledigt war.

**Zweck**: Erkenntnisse, die man nicht noch einmal herausfinden muss
(Messungen, Fehlschläge), Testrezepte und Arbeitsweise in diesem Repo.

**Regel**: Sobald ein Punkt implementiert ist, in `ROADMAP/ROADMAP.md`
**ersatzlos** streichen — dort gibt es keine abgehakten Einträge, erledigte
Punkte verschwinden. Die ausführliche Begründung gehört in `FEATURES.md` und in
die Commit-Message; hier steht nur, was man beim Weiterarbeiten wissen muss.

**§2 ist der wertvollste Teil dieser Datei.** Er altert nicht: dort stehen
Messungen und Fehlschläge, die sonst jede Sitzung neu bezahlt. Wer etwas
misst, das die nächste Sitzung wissen sollte, trägt es dort ein.

**Wo diese Datei liegt und warum.** Hier, in
`wkdbook-myplugins/casedesk.nvim/handovers/` — nicht im Plugin-Repo. Das ist
DOC-16: Handover-Material ist Sitzungs-Werkstatt und gehört nicht in ein
öffentliches Plugin-Repo. Die Datei war am 2026-09-07 vorübergehend nach
`casedesk.nvim/docs/HANDOVER.md` zurückgeholt und ist noch am selben Tag wieder
hierher gewandert.

Zwei weitere Dateien tragen denselben Namen und sind **nicht** dieselbe Sache:

| Datei | Was sie ist |
|---|---|
| [`../Backlog/TASKS/HANDOVER_old.md`](../Backlog/TASKS/HANDOVER_old.md) | Stand der Sitzung 2026-08-19, nicht mehr fortgeschrieben. Sein §2 (Arbeits-Repo-Kontext) und §5 (Fallen auf diesem Rechner) stehen so nur dort |
| [`../Backlog/FEATURES/HANDOVER_casedesk-plugin.md`](../Backlog/FEATURES/HANDOVER_casedesk-plugin.md) | der Auslagerungs-Fortschritt (Phasen 0–7, abgeschlossen), nicht die Feature-Arbeit |

**Doku-Verweise** unten sind Pfade im Plugin-Repo `$REPOS_DIR/casedesk.nvim`,
nicht in diesem Repo — deshalb als Pfad geschrieben und nicht als Link, der von
hier aus ins Leere zeigen würde.

Stand: **2026-10-02** (Inhalt von §2/§4–§6: 2026-09-07)

---

## 1 — Was zuletzt fertig geworden ist

Ausgelagert am 2026-10-02 nach
[Backlog/FEATURES/HANDOVER_2026-09-07-erledigt.md](../Backlog/FEATURES/HANDOVER_2026-09-07-erledigt.md)
— alles dort ist erledigt. Den aktuellen Stand der Arbeit nennt
[IMPLEMENTIERUNGSPLAN.md](../IMPLEMENTIERUNGSPLAN.md) §1.

---

## 2 — Erkenntnisse, die man nicht noch einmal herausfinden muss

### 2.1 Bereiche: jedes globale `states` ist verdächtig

Zwei Fehler dieser Sitzung waren Folgeschäden derselben Annahme — dass
`config.states`/`config.default_state` die ganze Welt seien statt SAPs Antwort
unter einem globalen Namen:

1. **`:Cases list` hätte Cases stumm verschluckt.** `query.by_state()` legte
   die Gruppen nach `config.states` an, `ui.list_all` rendert in derselben
   Reihenfolge — ein Zustand, den nur ein anderer Bereich hat, wäre im
   Gruppen-Table gelandet und nie gedruckt worden. Dieselbe stille Abwesenheit
   wie beim `T2`-Ordner, der monatelang unsichtbar war.
2. **`:Case t2` auf einem CS-Case hätte nicht gescheitert, sondern erfunden.**
   `do_move` legt sein Ziel mit `mkdirp` an, hätte also im CS-Baum ein `T2/`
   erzeugt und aus einem Vertipper einen Zustand gemacht.

**Regel daraus:** Renderndes iteriert über `config.all_states()`, „ist offen"
fragt `registry.is_open(e)`, ein Zielzustand gehört gegen
`config.area(e.area).states` geprüft. Und Guards gehören an die *Operation*
(`do_move`), nicht an die Befehle: es gibt drei Wege hinein, und nur einer
leitet sein Angebot aus dem Bereich ab.

### 2.2 Dateizeitstempel messen in diesem Bestand nichts

Gemessen, nicht vermutet — und der Reihe nach, weil jeder Schritt für sich
plausibel aussah:

1. **Eine Ordner-mtime bewegt sich beim Bearbeiten nicht.** Weder ein
   Shell-Append noch Neovims `:write` verschieben sie. Ein Verzeichnis
   protokolliert, dass Einträge *entstehen, verschwinden, umbenannt werden* —
   nicht, dass ihr Inhalt sich ändert. (Eine **neue** Datei bewegt sie sehr
   wohl.)
2. Also die jüngste Datei-mtime je Case. Kosten: 4 ms für 27 Cases über 65
   Dateien, einmal pro Sitzung — unkritisch.
3. **Und dann: 26 von 27 Cases trugen dieselbe mtime auf die Sekunde.** Der
   Case-Baum ist ein git-Arbeitsbaum, der von der anderen Maschine gezogen
   wird, und git stempelt jede Datei, die es schreibt. Das reflog von
   `WKDBook-Tricentis` belegt es: `pull --ff-only @ 2026-09-02 20:17:29` = die
   mtime von 26 Cases, `pull @ 2026-08-26 15:04:28` = die des 27.

Dateizeitstempel messen hier also, **wann git zuletzt geschrieben hat**, nicht
wann jemand gearbeitet hat. Nach jedem Pull behaupteten sie zusätzlich, der
ganze Bestand sei heute dran gewesen.

**Das betrifft mehr als die Completion:** `:Case timeline` rekonstruiert
Arbeitssitzungen aus genau diesen mtimes und zeigt deshalb die Pull-Historie —
pro Case eine „Sitzung" von null Dauer. Steht als Befund in der ROADMAP, samt
drei abwägbaren Optionen; eine offensichtliche Reparatur gibt es nicht, weil
das Journal zwar weiß *dass* gearbeitet wurde, aber nicht wie lange, und keine
Vergangenheit rekonstruieren kann. `detect.last_touched` steht auf derselben
Grundlage.

### 2.3 Deklariert ist nicht eingelöst

Dreimal an einem Tag dasselbe Muster. Es lohnt, bei jedem Modul zu fragen „wer
liest das eigentlich?", bevor man ein Feature obendrauf setzt:

| Deklariert | Eingelöst |
|---|---|
| `area.sla` — konfiguriert, typisiert, dokumentiert | von niemandem gelesen; ein CS-Case wurde an SAPs Fristen gemessen |
| `Casedesk.Meta.status` — im Typ deklariert | nie geschrieben, nie gelesen, in keinem `.case.json` des Bestands; ersatzlos entfernt |
| `templates.lua`s Docstring: „next to this module" | `TEMPLATE_DIR` zeigte auf `stdpath("config")/lua/bindings/usrcmds/case/templates`, den Ort **vor der Extraktion** |

Der Template-Fall war der gefährlichste, weil er **lautlos** war: `M.render`
macht aus einer unlesbaren Template-Datei einen leeren Body statt eines
Fehlers (Absicht — die H1 soll trotzdem geschrieben werden). Auf jeder anderen
Installation hätte `:Case new` also Dateien angelegt, die nichts als ihre
Überschrift enthalten, ohne ein Wort dazu. `TESTS/templates_spec.lua` prüft
jetzt jedes deklarierte Tag gegen eine lesbare Datei **innerhalb des Plugins**;
die Tag-Liste wird vom Modul reflektiert, nicht handgeschrieben, sonst geht sie
beim nächsten Template wieder auseinander.

### 2.4 Wohin ein Fakt gehört: Datei oder Sidecar

Die Frage kam bei „Kunde hat nie geantwortet" auf und ist aus dem Code
beantwortbar, nicht nach Geschmack. `solution_statuses` sind Werte des
`## Status`-Abschnitts **innerhalb einer Solution.md**. Ein Ergebnis dort
festzuhalten hieße, genau die inhaltsleere Datei anzulegen, die `DEFAULTS.lua`
vier Zeilen darüber als „schlimmer als keine" ablehnt — sie flutet die
Lösungssuche mit gehaltlosen Treffern.

Also Sidecar-Feld. Das ist nebenbei die billigere Abfrage: ein Feld in
`config.infocard_fields` erzeugt `:Cases <feld>` von selbst.

**Aber:** `infocard_fields` erzeugt **nur die Filterrouten**. Die Infocard
selbst (`ui.infocard_lines`) ist handgeschrieben — ein Feld dort einzutragen
gibt den Befehl gratis, aber *keine* Zeile in der Karte.

### 2.5 Einzelfall fragt, Massenpfad nicht

`:Cases close` über zwanzig markierte Cases zeigt genau **einen** Dialog; eine
Abfrage pro Case machte den Weg sinnlos. Deshalb sitzt der Schalter am
*Aufrufer* (`do_move`s `followup`), nicht am Zustand. Dieselbe Überlegung gilt
für jedes künftige „nach dem X noch fragen, ob Y".

Verwandt: **die Completion darf nie ins Nutzungsjournal schreiben.** In einem
Menü angeboten zu werden ist keine Nutzung; ein `usage.record` dort stempelte
beim ersten `<Tab>` den gesamten Bestand und ränge danach für immer alles
gleich. Ein Test hält das fest.

### 2.6 `resolve.pick`s Fallback-Liste ist „offene Cases", nicht „alle Cases"

Für jedes bisherige Verb richtig, für jedes künftige Verb, das mit *abgelegten*
Cases arbeitet, genau falsch herum. `opts.filter` ist der Weg; die Picker-Zeile
hängt den Zustand an, sobald er nicht der offene ist.

### 2.7 Der Windows Restart Manager registriert Dateien, keine Verzeichnisse

Gemessen: ein PowerShell-Prozess hält `Notes.md` exklusiv offen →
`lock.who(<datei>)` meldet `pid … powershell`, `lock.who(<ordner>)` meldet eine
**leere Liste**. Jede Diagnose, die einen Ordner befragt, ist ein stiller
No-op. `hint_lock_holder` fragt deshalb die Dateien im Case ab (neueste zuerst,
Abbruch beim ersten Treffer, max. 8 — jede Frage ist ein PowerShell-Prozess).
Ein Verzeichnis-Watcher auf dem Ordner selbst bleibt damit unauffindbar; das
ist ein ehrlicher Rest, kein Bug.

### 2.8 Der ROADMAP-Text ist nicht die Datenlage

Zweimal belegt. Einmal sagte ein Punkt „`SAP UI5` statt `none`" — im echten
Korpus steht `ControlFramework: SAPNW`. Einmal nannte ein Punkt die
Ordner-mtime als „billigstes Signal", das dann gar keines war (§2.2).

**Vor dem Bauen jedes Punktes:** die genannte Datei, den genannten Code, die
genannte Quelle wirklich ansehen und den Punkt danach zuschneiden. Die
ROADMAP-Texte altern still, der Code nicht.

---

## 3 — Implementierungsplan

Ersetzt am 2026-10-02: die damaligen Stufen 1 und 2 sind erledigt (Archiv:
[Backlog/FEATURES/HANDOVER_2026-09-07-erledigt.md](../Backlog/FEATURES/HANDOVER_2026-09-07-erledigt.md)),
die Arbeitsliste ist jetzt [IMPLEMENTIERUNGSPLAN.md](../IMPLEMENTIERUNGSPLAN.md),
die offenen Punkte stehen in [ROADMAP/ROADMAP.md](../ROADMAP/ROADMAP.md).

---
## 4 — Testrezepte (headless, ohne die laufende Sitzung zu stören)

Die Gates einmal komplett:

```bash
stylua --check . && luacheck . && LIB_NVIM_DIR=../lib.nvim scripts/gen_docs.sh --check
```

```bash
LIB_NVIM_DIR=../lib.nvim PLENARY_DIR=<nvim-data>/lazy/plenary.nvim scripts/test.sh
```

`plenary.nvim` liegt auf diesem Rechner unter
`C:/Users/<user>/AppData/Local/nvim-data/lazy/plenary.nvim`; `lib.nvim` als
Schwester-Checkout neben dem Repo, deshalb reicht `../lib.nvim`.

**Gates auf dieser Maschine (Git Bash, Stand 2026-10-02).** `stylua` (WinGet) und
`luacheck` (`~/.luarocks`) sind installiert, aber keines von beiden steht im
Standard-`PATH`, und `luacheck` findet seine Module nicht von selbst. Das hier
läuft aus dem Plugin-Repo und gibt alle vier Gates aus:

```bash
R=C:/Users/StefanBartl/.luarocks
export PATH="$PATH:/c/Users/StefanBartl/AppData/Local/Microsoft/WinGet/Packages/JohnnyMorganz.StyLua_Microsoft.Winget.Source_8wekyb3d8bbwe"
export LUA_PATH="$R/share/lua/5.4/?.lua;$R/share/lua/5.4/?/init.lua;;" LUA_CPATH="$R/lib/lua/5.4/?.dll;;"
export LIB_NVIM_DIR=../lib.nvim PLENARY_DIR=/c/Users/StefanBartl/AppData/Local/nvim-data/lazy/plenary.nvim
stylua --check . && lua $R/bin/luacheck . && scripts/test.sh && scripts/gen_docs.sh --check
```

`scripts/test.sh` druckt je Spec-Datei eine eigene `Success/Failed/Errors`-Summe;
über alle Dateien addieren, nicht die letzte lesen. Der Fehlerfall steht als
`Fail || <Spec> <Test>`. `stylua` formatiert beim Schreiben (`stylua lua TESTS`),
nicht erst beim Prüfen. Dieselben Schritte für `hover.nvim` (`scripts/test.sh`,
`HOVER_ALLOW_PENDING=1`) und `pdfport.nvim` (`nvim --headless -u NONE -c "set
rtp+=." -c "set rtp+=../lib.nvim" -c "luafile TESTS/run.lua" -c "qa!"`;
`bindings_spec.lua:293` schlägt unter Windows schon vor jeder Änderung fehl).

**Ein Skript, das Dateien schreibt, mit absolutem Pfad lesen/schreiben:**
`[IO.File]::ReadAllText` löst relative Pfade gegen das Prozess-Arbeitsverzeichnis
auf, nicht gegen das der PowerShell-Sitzung — ein fehlgeschlagenes Lesen mit
anschließendem Schreiben legt sonst leere Dateien im falschen Ordner an.
**Einen Flow gegen einen Wegwerf-Case-Baum fahren** — so sind `:Case reopen`,
der Lock-Hinweis, die Bereichs-Arbeit und `:Case close`s Lösungsabfrage
verifiziert worden:

```lua
local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/Cases/SAP_Support/Cases/Open", "p")
require("casedesk.config").setup({ repo_root = root, usage_path = root .. "/usage.json" })
local kit = require("lib.nvim.ui.kit")
kit.confirm = function(o) o.on_answer(true) end
kit.select = function(o) o.on_select(o.selection[1]) end
```

Das Überschreiben wirkt, weil `ui.lua` die Referenz auf dieselbe Tabelle hält.
`usage_path` mit in den Wegwerf-Baum zeigen lassen, sonst schreibt die Probe in
das echte `stdpath("data")`. Danach mit `fs_stat` prüfen, was wirklich auf der
Platte steht — nicht der Meldung glauben.

Ein Skript gegen den **echten** Bestand laufen lassen:

```bash
LIB_NVIM_DIR=../lib.nvim PLENARY_DIR=<plenary> nvim --clean --headless \
  -u TESTS/minimal_init.lua -c "luafile C:/…/probe.lua" -c "qa!"
```

**Fallen dabei:**

- `luafile` braucht einen **Windows-Pfad** (`C:/...`). Mit einem Git-Bash-Pfad
  (`/c/...`) schlägt es still fehl, und ohne abschließendes `-c "qa!"` bleibt
  der headless-Prozess für immer stehen.
- Solche Prozesse **immer über die konkrete PID** beenden
  (`Get-CimInstance Win32_Process -Filter "Name='nvim.exe'"` zum
  Identifizieren), nie über den Imagenamen — auf diesem Rechner laufen echte
  nvim-Sitzungen.

---

## 5 — Wo was steht

| Frage | Datei |
|---|---|
| Was ist offen? | `wkdbook-myplugins/casedesk.nvim/ROADMAP/ROADMAP.md` — Ideen, keine Zusagen; Reihenfolge in `IMPLEMENTIERUNGSPLAN.md` |
| Warum ist etwas so gebaut? | `docs/CONCEPT.md`, `docs/EXTRACTION.md`, `docs/SLA.md`, `docs/SESSIONS.md` |
| Was wurde nach dem Erstbau fertig? | `docs/FEATURES.md` |
| Welche Befehle gibt es? | `docs/commands.md` (generiert), `CHEATSHEET.md` |
| Wie ist das Repo aufgebaut, wie kommt eine Route dazu? | `docs/CONTRIBUTING.md` |
| Unfertige Konzepte, Analysen | `wkdbook-myplugins/casedesk.nvim/ROADMAP/` (`PTO.md`, `ANALYSEN/`) |
| Erledigtes, Audits, Messungen | `wkdbook-myplugins/casedesk.nvim/Backlog/` |

---

## 6 — Arbeitsweise in diesem Repo

`docs/CONTRIBUTING.md` beschreibt den Weg für Außenstehende: Fork,
`feature/<name>`, Pull Request. **Der Autor arbeitet anders** — direkt auf
`main`, ein Commit pro abgeschlossenem Punkt, sofort gepusht, damit die
Änderung gleich benutzbar ist. Kein Co-Author-Trailer. Das ist kein
Widerspruch zu CONTRIBUTING, sondern die andere Seite derselben Regeln: die
inhaltlichen Vorgaben dort (kein plattformspezifischer Code im Modul, keine
hartcodierten Pfade, Routen nur über den Composer) gelten unverändert.

- **Vier Gates, alle vier grün vor jedem Commit:** `stylua --check .`,
  `luacheck .`, `scripts/test.sh`, `scripts/gen_docs.sh --check`.
  `docs/commands.md` wird aus dem Routenbaum generiert — nach jeder neuen
  Route neu erzeugen, sonst bricht der `docs`-Job.
- **Kommentare und Code auf Englisch**, `docs/`-Prosa in der Sprache der Datei
  (die deutschen sind in `docs/README.md` mit **[de]** markiert).
- **Eine Reparatur, die einen Punkt blockiert, wird getrennt committet.** Beide
  Diffs bleiben so für sich lesbar — siehe den Template-Pfad-Fix vor `Task.md`.
- **Ein Punkt ist erst fertig, wenn er dokumentiert ist:** FEATURES.md
  (Begründung), ROADMAP.md (Eintrag entfernt), diese Datei (§1, und §2 wenn
  etwas gemessen wurde), dazu `CHEATSHEET.md`, `doc/casedesk.txt` und
  `docs/configuration.md`, soweit betroffen.
