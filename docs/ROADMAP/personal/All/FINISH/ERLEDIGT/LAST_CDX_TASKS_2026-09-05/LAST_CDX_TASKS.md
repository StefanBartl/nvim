# LAST_CDX_TASKS — Docs, Kommentare, Wiederholungsläufe

**Stand: 2026-09-03.** Konzept und Arbeitsplan für den zusammengezogenen
Aufgabenblock: Doku-Audit über alle Plugin-Repos, Kommentar-Audit im Quelltext,
BINDINGS-Sanierung, und fünf Wiederholungsläufe früherer Durchgänge.

Begleitende Notizdatei während der Umsetzung:
[`docs/ROADMAP/handovers/HO_LAST_CDX_TASKS.md`](HO_LAST_CDX_TASKS.md).
Dort landet alles, was die Tasklist selbst unübersichtlich machen würde —
Zwischenstände, Einzelfallentscheidungen, Überraschungen.

---

## Table of content

- [0. Was das hier ist](#0-was-das-hier-ist)
- [1. Bestandsaufnahme](#1-bestandsaufnahme)
- [2. Die vier Leitprinzipien](#2-die-vier-leitprinzipien)
- [3. Der Doku-Standard](#3-der-doku-standard)
- [4. Die Docs-Checkliste](#4-die-docs-checkliste)
- [5. README-Konzept](#5-readme-konzept)
- [6. BINDINGS-Sanierung](#6-bindings-sanierung)
- [7. Source-Kommentare](#7-source-kommentare)
- [8. Die fünf Wiederholungsläufe](#8-die-fünf-wiederholungsläufe)
- [9. Vorgehen: vertikal, in Wellen](#9-vorgehen-vertikal-in-wellen)
- [10. Phasenplan](#10-phasenplan)
- [11. Offene Entscheidungen](#11-offene-entscheidungen)

---

## 0. Was das hier ist

Der Auftrag besteht aus zwei Hälften, die zusammengehören, weil beide dieselben
Dateien anfassen:

1. **Doku-Audit.** Jede Datei unter `docs/` in jedem `*.nvim`-Repo auf
   Aktualität, Korrektheit, Doppelung und Relevanz prüfen. Einheitliche
   Struktur finden. Zu tiefes oder rein internes Material auslagern.
2. **Wiederholungsläufe.** Fünf frühere Durchgänge (dedup, Diagnostics,
   Magic Numbers, Keymap-Parity, Konfigurierbarkeit) noch einmal fahren, weil
   seither viel neuer Code entstanden ist.

Sie gehören zusammen, weil ein Wiederholungslauf ohnehin jedes Repo öffnet.
Wer schon drin ist, prüft die Docs gleich mit — statt 31 Repos zweimal
anzufassen.

**Was dieses Dokument nicht ist:** die Umsetzung. Hier steht der Standard,
gegen den geprüft wird, und die Reihenfolge. Der Fortschritt selbst gehört in
die Handover-Datei.

---

## 1. Bestandsaufnahme

Gemessen am 2026-09-03 über alle 31 Repos unter `$REPOS_DIR\*.nvim`.

### 1.1 Größenordnung

| Größe | Wert |
|---|---|
| Plugin-Repos | 31 |
| Dateien unter `docs/` (Summe) | ~600 |
| `docs/`-Dateien pro Repo | 7 (spotlight) … 52 (lib.nvim) |
| README-Zeilen | 65 (recommender) … 1123 (hover) |
| BINDINGS-Cheatsheets (nvim-config) | 111 Dateien, 12.254 Zeilen |

Die Spannweite ist selbst schon ein Befund: `spotlight.nvim` hat sieben
Doku-Dateien, `lib.nvim` zweiundfünfzig. Ein Teil davon ist berechtigt
(lib.nvim ist die geteilte Basis), ein Teil ist Wildwuchs.

### 1.2 Was bereits einheitlich ist

Diese Bausteine sind **nicht** das Problem — sie sind schon fast überall da:

| Baustein | Abdeckung |
|---|---|
| `docs/BINDINGS.md` | 31/31 |
| `docs/WORKFLOW.md` | 30/31 (fehlt: hover.nvim) |
| `docs/map/` (index.html + module_map.json + overview.md) | 29/31 (fehlt: hover.nvim, lsp.nvim) |
| ASCII-Art im README | 30/31 (fehlt: mdview.nvim) |
| Badges im README | 31/31 (4–10 Stück) |
| Sibling-Plugin-Erwähnung im README | 31/31 |
| Reifegrad-Disclaimer als README-Zeile 1 | 31/31, **wortgleich** |
| `docs/FEATURES/README.md` als Overview | 21/23 (fehlt: cascade.nvim, debugging.nvim) |

**Konsequenz für den Plan:** Der Wunsch nach ASCII-Art, Badges,
Sibling-Hinweisen und Overview-Dateien ist zu ~95 % bereits erfüllt. Das ist
kein Bau-, sondern ein Lückenschluss- und Positionierungsthema. Der Aufwand
liegt woanders.

### 1.3 Was nicht einheitlich ist — die echten Befunde

**Befund A — der Disclaimer ist da, nur das Wort „Alpha" fehlt.**

> ⚠️ **Korrigiert 2026-09-03.** Die erste Fassung dieses Dokuments behauptete,
> nur 2 von 31 READMEs hätten einen Disclaimer. Das war falsch — ein Artefakt
> einer zu engen Wortsuche nach `alpha`. Breiter gemessen ergibt sich das
> Gegenteil.

**31 von 31** READMEs tragen als **allererste Zeile** denselben Block, exakt
wortgleich (eine einzige Variante über alle Repos):

> `> **Active development.** This repository is in its development phase —`
> `breaking changes are to be expected at any time. Pin a commit or tag if you`
> `depend on it.`

Inhaltlich leistet das bereits, was P3 verlangt: Reifegrad benannt, Breaking
Changes angekündigt, Handlungsempfehlung gegeben. Es fehlt allein das
ausdrücklich gewünschte Wort **„Alpha stage"**.

Zwei Repos haben zusätzlich einen eigenen, schärferen Hinweis weiter unten
(`lsp.nvim`: „**Status: alpha.**…", `mdview.nvim`: „Alpha stage: highly
experimental…"). Diese bleiben — sie sagen etwas Spezifisches über *dieses*
Plugin.

**Konsequenz:** Statt 31 Disclaimer zu schreiben, wird **eine Zeile 31×
ersetzt** — skriptbar, weil der Ausgangstext identisch ist. Das ist P4 in
Reinform. Siehe [E1](#11-offene-entscheidungen).

**Befund B — Groß-/Kleinschreibung divergiert, aber es gibt eine Mehrheit.**
Echte Schreibweisen, über alle Repos gezählt:

| Datei | lowercase | UPPERCASE |
|---|---|---|
| installation.md | **22** | 2 |
| configuration.md | **19** | 2 |
| commands.md | **16** | 5 |
| architecture.md | **12** | 1 |
| troubleshooting.md | **6** | 1 |
| keymaps.md | **5** | 1 |
| api.md | **8** | 0 |
| contributing.md | 1 | **3** |
| FEATURES.md | 0 | **11** |
| CHANGELOG.md | 0 | **2** |

Daraus lässt sich eine Regel *ableiten* statt erfinden:

> **Themen-Dokumente klein, Meta-Dokumente groß.**
> `installation.md`, `configuration.md`, `commands.md`, `api.md`,
> `architecture.md`, `keymaps.md`, `troubleshooting.md` — klein.
> `README.md`, `FEATURES.md`, `WORKFLOW.md`, `BINDINGS.md`, `CHANGELOG.md`,
> `CONTRIBUTING.md` — groß.

Das deckt sich mit der bestehenden Praxis in 88 % der Fälle. Umzubenennen
sind **12 Dateien** in ~8 Repos.

> ⚠️ **Windows-Falle:** Reine Case-Umbenennungen brauchen einen Zwischenschritt,
> sonst sieht Git keine Änderung:
> `git mv COMMANDS.md tmp.md && git mv tmp.md commands.md`.
> Beim Umbenennen müssen außerdem alle Links darauf mitgezogen werden —
> auf Windows funktionieren die falschen Links lokal weiter und brechen erst
> auf GitHub. Das ist der Grund, warum das überhaupt so lange unentdeckt blieb.

**Befund C — `FEATURES` ist mal Ordner, mal Datei, dreimal beides.**
23 Repos haben `docs/FEATURES/` (Ordner), 11 haben `docs/FEATURES.md` (Datei).
Drei haben **beides** und damit garantiert eine Doppelung:

- `debugging.nvim`
- `replacer.nvim`
- `reposcope.nvim`

`replacer.nvim` legt sogar noch `Feature-Matrix.md` daneben — dritte Fassung
derselben Frage.

**Befund D — Deutsche Dubletten ohne erkennbaren Anlass.**
Die Regel lautet: deutsche Docs nur, wenn eine englische Hauptversion besteht
*und* explizit eine deutsche Fassung verlangt wurde. Gefunden:

| Repo | Deutsche Datei | Englisches Original |
|---|---|---|
| color_my_ascii.nvim | `README-de.md` | ja |
| color_my_ascii.nvim | `QUICKSTART-de.md` | ja |
| gopath.nvim | `CACHE-DE.md` | ja |
| gopath.nvim | `LUA-SYMBOLS-DE.md` | ja |
| gopath.nvim | `RESOLUTION-DE.md` | ja |

Alle fünf haben ein englisches Gegenstück, erfüllen also die erste Hälfte der
Regel. Ob die zweite Hälfte („explizit verlangt") je erfüllt war, weiß nur
der Autor → [offene Entscheidung E4](#11-offene-entscheidungen).
Nebenbefund: die Namenskonvention ist selbst uneinheitlich (`-de` vs. `-DE`).

**Befund E — internes Material liegt in öffentlichen Repos.**
Kandidaten für die Auslagerung nach `wkdbook-myplugins`:

| Repo | Verdächtige Dateien |
|---|---|
| hover.nvim | `MANUAL-EVIDENCE.md`, `NAME-COLLISION.md`, `ROADMAP.md` |
| replacer.nvim | `AltEnter_Shot.md`, `DEBUG-GUIDE.md`, `TODO-Guidelines-Review.md`, `Materials/`, `Feature-Matrix.md` |
| documentation.nvim | `CHECKLIST/`, `FEATURE_LOG.md`, `ECOSYSTEM.md` |
| runtime-analysis.nvim | `IDEAS.md`, `FEATURE_LOG.md` |
| color_my_ascii.nvim | `FEATURE_LOG.md`, `dev/` |
| github_stats.nvim | `NOTES/`, `devs/` |
| gopath.nvim | `Developer-Notes/` |
| mdview.nvim | `testdoku/`, `CI/` |
| lsp.nvim | `CHECKLISTS/` |

„Verdächtig" heißt: einzeln prüfen, nicht blind verschieben. `CONTRIBUTING.md`
und `DEVELOPMENT.md` etwa gehören ins Repo — ein externer Beitragender braucht
sie. Ein `FEATURE_LOG.md` braucht er nicht.

**Befund F — `docs/README.md` gibt es zweimal.**
`documentation.nvim` und `gopath.nvim` haben eine `docs/README.md` neben dem
Repo-README. Ob das ein Doku-Index ist (sinnvoll, siehe
[§3](#3-der-doku-standard)) oder eine Kopie (Doppelung), ist beim Durchgang zu
klären.

**Befund G — hover.nvim ist der Ausreißer, und zwar aus gutem Grund.**
Erster Commit **2026-09-01** — zwei Tage alt. Es fehlt als einzigem Repo
`WORKFLOW.md` *und* `docs/map/`, es hat als einziges eine `ROADMAP.md` in
`docs/`, sein README ist mit **1123 Zeilen** das längste der Sammlung, und es
erwähnt **13** Sibling-Plugins (Median: 2–3). Es ist kein verrottetes Repo,
sondern ein noch nicht eingenordetes. Behandlung entsprechend: nicht
„reparieren", sondern erstmalig einnorden.

### 1.4 BINDINGS (nvim-config)

`docs/NOTES/PersonelPlugins/BINDINGS/` — 111 Dateien, 12.254 Zeilen, in drei
Unterordnern (`Autocmds/` 33, `Keymaps/` 34, `Usercmds/` 40).

Der Verdacht („da steht mehr drin als Bindings") **bestätigt sich, aber
anders als vermutet**:

- Eine Wortsuche nach `roadmap` trifft 45 Dateien — das ist jedoch **kein**
  Beleg. Die Treffer sind ganz überwiegend legitime Querverweise der Form
  *„see `docs/ROADMAP.md`"* oder *„added by a later roadmap feature"*. Ein
  Cheatsheet darf auf eine Roadmap zeigen.
- Der belastbare Befund ist ein anderer: **20+ Dateien enthalten
  Changelog-Abschnitte** — datierte Verlaufseinträge wie
  `- 2026-08-30 (2): lsp_nvim_supervisor aus Roadmap-M3 aufgenommen`.
  Das ist Entwicklungsgeschichte in einem Nachschlagewerk.
- Zweiter Indikator ist die Länge. Ein Cheatsheet-Eintrag sollte kurz sein;
  diese sind es nicht:
  `Usercmds/bindings_explorer.md` 411 Zeilen, `Usercmds/runtime-analysis.nvim.md`
  393, `Usercmds/lib.nvim.md` 381, `Usercmds/documentation.nvim.md` 372,
  `Usercmds/images.nvim.md` 360, `Usercmds/lsp.nvim.md` 356.

**Konsequenz:** Nach Wortsuche zu sanieren wäre falsch und würde gute
Querverweise zerstören. Sortierkriterium ist die Frage aus
[§2.1](#21-p1--das-relevanzprinzip), angewandt auf den Zweck der Sammlung:
*Beantwortet dieser Absatz die Frage „welche Taste/welches Kommando tut was"?*
Wenn nein — gehört er in die Repo-Docs oder nach `wkdbook-myplugins`, nicht
hierher.

### 1.5 Vorhandene Werkzeuge — der wichtigste Fund

Die Skripte der früheren Durchgänge wurden nach Abschluss gelöscht, ihr
Inhalt aber **in echte Kommandos überführt**. Das ist im Quelltext verifiziert,
nicht nur behauptet:

| Frühere Aufgabe | Kommando heute | Modul (verifiziert) |
|---|---|---|
| Keymap↔Usercmd-Parity | `:LibBindingsAudit`, `:LibBindingsAuditGaps` | `lib.nvim/lua/lib/nvim/bindings/audit.lua` |
| Duplikate → lib.nvim | `:LibDuplicateScan [path]` | `lib.nvim/lua/lib/nvim/dev/duplicates.lua` |
| Magic Numbers + Hardcoded Constants | `:Insights smells` | `insights.nvim/lua/insights/smells/init.lua` |
| Usercmd-Doku-Abgleich | `:LibUsercmdDocsCheck` | `lib.nvim/lua/lib/nvim/bindings/usercmd/docs.lua` |
| Autocmd-Doku-Abgleich | `:LibAutocmdDocsCheck` | `lib.nvim/lua/lib/nvim/bindings/autocmd/docs.lua` |

**Das verändert den Plan grundlegend.** Vier der fünf Wiederholungsläufe sind
keine Analysearbeit mehr, sondern *Kommandoläufe plus Bewertung der Treffer*.
Das spart den Löwenanteil an Tokens und ist der Grund, warum
[§8](#8-die-fünf-wiederholungsläufe) so kurz ausfällt.

`:LibUsercmdDocsCheck` und `:LibAutocmdDocsCheck` sind zusätzlich für den
**Doku-Audit selbst** brauchbar: sie prüfen maschinell, ob dokumentierte
Bindings dem Code entsprechen. Das ist genau die Frage „stimmt alles, was
behauptet wird" für den mechanisch prüfbaren Teil der Docs — und deckt
BINDINGS.md, commands.md und die BINDINGS-Cheatsheets in einem Zug ab.

---

## 2. Die vier Leitprinzipien

Alles Weitere ist Ableitung aus diesen vier Sätzen.

### 2.1 P1 — Das Relevanzprinzip

> Nicht „so viel wie möglich" in die Docs, sondern nur das, was für User und
> Devs tatsächlich interessant sein kann.

Operationalisiert als **Drei-Fragen-Test** pro Dokument oder Abschnitt:

1. **Braucht ein *User* das, um das Plugin zu benutzen?** → `docs/` im Repo.
2. **Braucht ein *Dev* das, um am Plugin zu arbeiten oder beizutragen?** →
   `docs/` im Repo.
3. **Weder noch, aber ich will es nicht verlieren?** → `wkdbook-myplugins`.

Zweimal Nein heißt auslagern, nicht löschen. Wenn keine der drei Fragen greift
und der Inhalt auch nicht bewahrenswert ist, heißt es löschen — `git log` hat
ihn.

**`wkdbook-myplugins` ist kein Downgrade.** Es ist die interne
Notizensammlung. Etwas dorthin zu verschieben ist eine Ablage-, keine
Qualitätsentscheidung.

### 2.2 P2 — Die Sprachregel

> Deutsche Docs nur, wenn eine englische Hauptversion besteht **und** explizit
> eine deutsche Fassung verlangt wurde.

Zwei Bedingungen, beide nötig. Repo-Inhalte (Code, Kommentare, Docs) sind
grundsätzlich Englisch. Notizen in der nvim-config und in WKDBooks sind
Deutsch — dieses Dokument selbst ist das Beispiel.

### 2.3 P3 — Ehrlichkeit über den Reifegrad

> Alle Plugins sind Alpha. Breaking Changes sind zu erwarten. Das steht im
> README, nicht im Kleingedruckten.

Bereits zu 31/31 erfüllt — bis auf das Wort „Alpha" selbst
([Befund A](#13-was-nicht-einheitlich-ist--die-echten-befunde)).

### 2.4 P4 — Der Standard wird abgeleitet, nicht erfunden

Wo es bereits eine Mehrheitspraxis gibt, wird sie zur Regel — auch wenn eine
andere Variante theoretisch schöner wäre. Das minimiert die Zahl der
Änderungen und damit das Risiko, beim Umbenennen Links zu brechen.
[Befund B](#13-was-nicht-einheitlich-ist--die-echten-befunde) ist genau so
entstanden.

---

## 3. Der Doku-Standard

Zielbild pro Plugin-Repo. **Pflicht** heißt: fehlt es, ist das ein Befund.
**Bedingt** heißt: nur wenn das Repo die Sache hat.

```
<repo>/
├── README.md                    [PFLICHT]  Schaufenster — siehe §5
└── docs/
    ├── README.md                [PFLICHT]  Doku-Index: was liegt hier, wofür
    ├── installation.md          [PFLICHT]
    ├── configuration.md         [PFLICHT]
    ├── commands.md              [PFLICHT]  falls Usercmds vorhanden
    ├── BINDINGS.md              [PFLICHT]  Keymaps + Usercmds, kompakt
    ├── WORKFLOW.md              [PFLICHT]
    ├── FEATURES/                [PFLICHT]  Ordner, nie Datei
    │   ├── README.md                       Overview: verweist auf alle, je 1 Satz
    │   └── <FEATURE>.md
    ├── USECASES/                [BEDINGT]  falls das Plugin eine API anbietet
    │   ├── README.md                       Overview
    │   └── <usecase>.md
    ├── api.md                   [BEDINGT]  falls öffentliche Lua-API
    ├── architecture.md          [BEDINGT]  falls nicht-offensichtlicher Aufbau
    ├── troubleshooting.md       [BEDINGT]
    ├── health.md                [BEDINGT]  falls checkhealth-Provider
    ├── CONTRIBUTING.md          [BEDINGT]
    ├── CHANGELOG.md             [BEDINGT]
    └── map/                     [PFLICHT]  generiert, nicht handgepflegt
        ├── index.html
        ├── module_map.json
        └── overview.md
```

### 3.1 Entscheidungen, die in diesem Baum stecken

**`FEATURES/` ist immer ein Ordner.** Auch bei zwei Features. Ein Ordner
skaliert, eine Datei muss irgendwann gesplittet werden, und der Split ist die
teure Operation. Die 11 Repos mit `FEATURES.md` werden umgestellt; die drei
mit beidem werden zusammengeführt.

**Jeder Sammelordner hat eine `README.md` als Overview.** Sie nennt jede Datei
des Ordners mit einem Satz. Damit verweist das Repo-README auf *eine* stabile
Adresse statt beispielhaft auf irgendeine Datei darin — das war der explizite
Wunsch. `README.md` statt `Overview.md`, weil GitHub sie beim Öffnen des
Ordners automatisch rendert und 21 von 23 Ordnern es bereits so machen (P4).

**`docs/README.md` ist der Doku-Index.** Zweite stabile Adresse: das
Repo-README verweist dorthin, nicht auf zwanzig Einzeldateien. Existiert
bisher in 2 von 31 Repos und ist die größte echte Neuerung dieses Standards.

**`USECASES/` ist neu und bedingt.** Der Wunsch war: „wenn eine API angeboten
wird, dann einen `docs/Usecases/**` dazu". Abgrenzung zu `api.md`:

> `api.md` beantwortet *„was kann ich aufrufen"* — Signaturen, Parameter,
> Rückgaben.
> `USECASES/` beantwortet *„wie löse ich damit Aufgabe X"* — durchgehende
> Beispiele.

Betroffen sind mindestens die 8 Repos mit `api.md`; welche darüber hinaus eine
öffentliche API haben, klärt der Durchgang.

**`map/` ist generiert.** Nicht von Hand prüfen. Wenn es veraltet ist, neu
erzeugen (`:DocMap`).

---

## 4. Die Docs-Checkliste

Der Prüfkatalog, der pro Repo abgearbeitet wird. IDs, damit die
Handover-Datei knapp darauf verweisen kann („`DOC-07` bei mdview offen").

### A — Struktur

| ID | Prüfung |
|---|---|
| `DOC-01` | Alle Pflicht-Dateien aus [§3](#3-der-doku-standard) vorhanden? |
| `DOC-02` | Groß-/Kleinschreibung nach P4-Regel? (Case-Rename über Zwischennamen!) |
| `DOC-03` | `FEATURES` ist Ordner, nicht Datei, und nicht beides? |
| `DOC-04` | Jeder Sammelordner hat `README.md` als Overview? |
| `DOC-05` | `docs/README.md` existiert und indiziert den Ordner? |
| `DOC-06` | Keine Datei ohne eingehenden Link (verwaist)? |

### B — Korrektheit

| ID | Prüfung |
|---|---|
| `DOC-07` | Alle internen Links auflösbar? (Windows verdeckt Case-Fehler — case-sensitiv prüfen) |
| `DOC-08` | Dokumentierte Commands existieren im Code? → `:LibUsercmdDocsCheck` |
| `DOC-09` | Dokumentierte Autocmds existieren im Code? → `:LibAutocmdDocsCheck` |
| `DOC-10` | Dokumentierte Keymaps stimmen mit der Registry? → `:LibBindingsAudit` |
| `DOC-11` | Dokumentierte Config-Keys existieren in `@types`/`DEFAULTS`? |
| `DOC-12` | Code-Beispiele im README syntaktisch gültig und lauffähig? |
| `DOC-13` | Genannte Abhängigkeiten stimmen mit der Install-Spec? |
| `DOC-14` | Keine Verweise auf entfernte Dinge (z. B. `migrate.nvim`, gelöschte Module)? |
| `DOC-28` | Stimmen die Zusagen über die **Umgebung**? Versionsangabe gegen die benutzten APIs (`vim.uv` → 0.10+), jeder `stdpath`-Pfad der Doku gegen den Code, Status-Badge gegen Zeile 1. Nachgetragen 2026-09-04 nach [Ü22]. |
| `DOC-29` | Haelt jede Tabelle als Tabelle? -> `scripts/docs_tablecheck.py`. Ein Prosa-Absatz zwischen zwei Zeilen beendet sie, und ein unescaptes `\|` in einer Zelle verwirft alles dahinter -- beides nur beim **Rendern** sichtbar. Nachgetragen 2026-09-05 nach U35/U36. |
| `DOC-30` | Laeuft jedes Doku-Beispiel ueberhaupt? Nicht ob es aktuell ist, sondern: den Aufruf gegen die echte Signatur halten. Ein Beispiel kann **kaputt** sein statt veraltet -- `cmdlog.nvim`s `ADD_PICKER.md` rief eine Factory wie ein Modul auf und warf beim ersten Versuch. Nachgetragen 2026-09-05 nach U40. |

### C — Relevanz (P1)

| ID | Prüfung |
|---|---|
| `DOC-15` | Jede Datei besteht den Drei-Fragen-Test aus [§2.1](#21-p1--das-relevanzprinzip)? |
| `DOC-16` | Kein Roadmap-/Handover-/Planungsmaterial in `docs/`? → auslagern. **Praezisiert 2026-09-05:** trifft „was noch kommt“, **nicht** „was nie kommt“. Ein Abschnitt, der aufzaehlt, was das Plugin bewusst *nicht* tut, ist eine Scope-Aussage und beantwortet eine echte User-Frage — er bleibt im Repo. Die *Entscheidung* dahinter (geprueft, verworfen, Grund) gehoert in die private Roadmap, damit sie nicht als offene Aufgabe wiederkommt. Beides ist kein Widerspruch: `spotlight.nvim` hat es so getrennt. |
| `DOC-17` | Kein Changelog-artiger Verlauf in Referenzdokumenten? |
| `DOC-18` | Keine inhaltliche Doppelung zwischen zwei Dateien? |
| `DOC-19` | Kein Inhalt, der dasselbe sagt wie das README? |

### D — Sprache (P2)

| ID | Prüfung |
|---|---|
| `DOC-20` | Alle Repo-Docs auf Englisch? |
| `DOC-21` | Deutsche Datei nur mit englischem Original **und** explizitem Wunsch? |
| `DOC-22` | Suffix-Konvention einheitlich (`-de`, klein)? |

### E — README (Details in [§5](#5-readme-konzept))

| ID | Prüfung |
|---|---|
| `DOC-23` | Alpha-Disclaimer vorhanden und weit oben? |
| `DOC-24` | ASCII-Art-Block + Badges? |
| `DOC-25` | 2–3 Sibling-Plugins einleitend erwähnt — nicht 13? |
| `DOC-26` | Verweis auf `docs/README.md`, `FEATURES/README.md`, `USECASES/README.md`? |
| `DOC-27` | Länge im Rahmen (Richtwert 100–250 Zeilen)? |

---

## 5. README-Konzept

Das README ist das, was Devs und User **zuerst** sehen und woraus sie ihre
Installationsentscheidung ableiten. Es bekommt daher ein eigenes,
ausformuliertes Konzept.

**Ablageort (explizit verlangt):**
`$REPOS_DIR\WKDBooks\Development\wkdbook-Neovim\MyNotes\docs\README-KONZEPT.md`

> Der Ordner `MyNotes\docs\` existiert bereits und ist **leer** — dieses
> Konzept ist sein erster Inhalt.

### 5.1 Vorgesehener Aufbau

Reihenfolge ist Absicht: Was die Installationsentscheidung trägt, steht oben.

1. **ASCII-Art-Titel** — visuelle Wiedererkennung der Sammlung
2. **Badge-Zeile** — Neovim-Version, Lizenz, Status, CI
3. **Ein-Satz-Beschreibung** — was das Plugin tut, ohne Marketing
4. **Alpha-Disclaimer** — als Blockquote, nicht überlesbar (P3)
5. **Einordnung in die Sammlung** — 2–3 verwandte Plugins mit je einem
   Halbsatz *warum*. Nicht als Liste aller 30.
6. **Screenshot/GIF** — wo sinnvoll
7. **Installation** — genau eine Spec (lazy.nvim), Rest verlinkt
8. **Quickstart** — der kürzeste Weg zum ersten Erfolgserlebnis
9. **Feature-Übersicht** — Stichpunkte, verlinkt auf `docs/FEATURES/README.md`
10. **Wegweiser in die Docs** — der Abschnitt, der zeigt *„die Doku ist gut
    ausgebaut"*: Verweis auf `docs/README.md`, `FEATURES/README.md`,
    `USECASES/README.md`, `api.md`
11. **Lizenz**

### 5.2 Was ausdrücklich *nicht* ins README gehört

Vollständige Config-Referenz, vollständige Command-Liste, Architektur,
Changelog, Roadmap. Das alles hat eine eigene Adresse unter `docs/` — das
README verweist darauf.

Genau hier liegt die Ursache der Ausreißer: `hover.nvim` (1123 Zeilen),
`documentation.nvim` (833), `replacer.nvim` (689), `spotlight.nvim` (652),
`runtime-analysis.nvim` (627), `cascade.nvim` (584), `images.nvim` (546) haben
Doku-Inhalt ins Schaufenster gezogen. Der Fix ist Verschieben, nicht Löschen.

### 5.3 Der Sibling-Abschnitt

Alle 31 Repos erwähnen bereits andere Plugins, aber Menge und Position
schwanken stark: `hover.nvim` nennt 13, `images.nvim` 9, die meisten 2–3.
`lib.nvim` ist fast überall dabei — das ist allerdings die geteilte Basis und
zählt eher als Dependency denn als Empfehlung.

Zielbild: **2–3 inhaltlich verwandte Plugins, einleitend, mit Begründung.**
`lib.nvim` gehört in den Dependency-Abschnitt, nicht in die Empfehlung.

---

## 6. BINDINGS-Sanierung

> **Neufassung 2026-09-04, auf Zuruf des Autors:** „PersonelPlugins/BINDINGS
> sollen auf die Plugin-Docs-Cheatsheets zeigen — keine Doppelung mehr."
> Die alte Fassung (Absatz für Absatz sortieren und verschieben) steht in der
> History; sie ist durch P4 überholt. Warum, steht in §6.1.

Betrifft `docs\NOTES\PersonelPlugins\BINDINGS\` (**107 Dateien, 12.566
Zeilen**, in `Autocmds/` 33, `Keymaps/` 34, `Usercmds/` 40) und
`docs\NOTES\ExternPlugins\Bindings\`.

### 6.1 Warum die alte Fassung überholt ist

Sie wurde geschrieben, als die Repo-Docs die Zielorte für verschobenes Wissen
noch nicht hatten. Inzwischen hat **jedes der 32 Repos eine
`docs/BINDINGS.md`** (gemessen 2026-09-04: 32/32), und P4 hat sie
vereinheitlicht. Damit ist die Sammlung unter `PersonelPlugins/BINDINGS/`
keine Ergänzung mehr, sondern eine **zweite Fassung derselben Sache** — genau
das, was `DOC-18` in den Repos verbietet.

### 6.2 Der Vorbehalt: „zeigen" darf nicht „verlinken" heißen

Ein Cheatsheet durch einen Link zu ersetzen wäre die naheliegende Lesart und
**würde `:Bindings` unbrauchbar machen**. Das Kommando ist kein Inhalts-
verzeichnis, sondern ein Werkzeug über dem Korpus:

| Route | Braucht vom Korpus |
|---|---|
| `:Bindings search` | Volltext (Live-Grep über `pickers.nvim`s Engine) |
| `:Bindings browse` | **geparste Tabellenzeilen** (`records.lua`) |
| `:Bindings check` / `report` | die **dokumentierte Seite** des Drift-Vergleichs gegen `nvim_get_keymap`/`nvim_get_commands` |
| `:Bindings status` | Korpus-Zahlen |

Alle vier lesen Text. Steht dort nur noch „siehe hover.nvim/docs/BINDINGS.md",
findet `search` nichts, hat `browse` keine Zeilen, und `check` verliert für 32
Plugins die Vergleichsseite — ausgerechnet für die, an denen am meisten
gearbeitet wird.

> **Die Doppelung verschwindet nicht dadurch, dass man auf die Wahrheit
> zeigt, sondern dadurch, dass man sie liest.**

### 6.3 Das Vorgehen: der Korpus bekommt eine zweite Wurzel

Statt einer Kopie im Config-Repo liest `:Bindings` die `docs/BINDINGS.md` des
Plugins **direkt aus dem installierten Plugin**:

```
stdpath("data")/lazy/<plugin>/docs/BINDINGS.md
```

Das ist maschinenunabhängig — die persönlichen Plugins werden in
`lua/plugins/personal/init.lua` als `"StefanBartl/<name>"` von GitHub geladen,
nicht per `dir=`. Kein `$REPOS_DIR`-Pfad im Config-Repo.

Danach:

| Wurzel | Danach |
|---|---|
| `PersonelPlugins/BINDINGS/` | **entfällt** — der Inhalt lebt im jeweiligen Plugin |
| `ExternPlugins/Bindings/` | **bleibt wie heute** — fremde Plugins haben keine `docs/BINDINGS.md` nach unserem Standard |

**Nebengewinn:** `:Bindings check` vergleicht die Live-Bindings dann gegen die
*autoritative* Doku des Plugins statt gegen eine Kopie. Eine Kopie kann
driften; das ist die Fehlerquelle, die der Drift-Report selbst finden soll.

### 6.4 Was dafür zu tun ist

| ID | Schritt |
|---|---|
| `BND-01` | `config.lua`: zweite Korpus-Wurzel auflösen (`stdpath("data")/lazy/<name>/docs/BINDINGS.md`), mit der Plugin-Liste aus der lazy-Spec statt einer gepflegten Namensliste |
| `BND-02` | `records.lua`: Abschnittsüberschriften normalisieren — der Korpus ist **art-zuerst** (`Autocmds/`, `Keymaps/`, `Usercmds/`), die Repos sind **plugin-zuerst** mit `##`-Abschnitten darin. Gemessene Varianten: `## Keymaps` (20), `## Autocommands` (19), `## User commands` (15), `## User Commands` (11), `## Autocmds` (10) |
| `BND-03` | `plugin_scope.lua`: Sheet-Stämme kommen jetzt aus der Plugin-Liste, nicht aus Dateinamen |
| `BND-04` | Pro Plugin: Sheet gegen `docs/BINDINGS.md` **diffen** (Ü20), Einzigartiges ins Repo nachtragen, dann Sheet löschen. Nicht umgekehrt |
| `BND-05` | `PersonelPlugins/BINDINGS/` entfernen, samt der drei Sammelseiten `autocmds-by-event.md`, `-by-filetype.md`, `-by-plugin.md` — prüfen, ob `:Bindings browse` sie ersetzt |
| `BND-06` | `:BindingsPath` **löschen** — siehe §6.5 |
| `BND-07` | `docs/FEATURES.md` des Explorers und `:help bindings_explorer` nachziehen |

**`BND-04` ist die eigentliche Arbeit** und der einzige Schritt, an dem Inhalt
verlorengehen kann. Die Sheets sind *älter* als die Repo-Docs und enthalten
teils Dinge, die nie ins Repo gewandert sind. Reihenfolge wie in
Ü14: erst diffen, dann das Einzigartige nachtragen, erst dann löschen.

### 6.5 Nebenbefund: `:BindingsPath` zeigt seit jeher ins Leere

```lua
-- lua/bindings/usrcmds/init.lua:47
local bindings_path = vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "NOTES", "BINDINGS")
```

`docs/NOTES/BINDINGS` **existiert nicht** (verifiziert 2026-09-04). Die
Wurzeln heißen `PersonelPlugins/BINDINGS` und `ExternPlugins/Bindings`. Das
Kommando kopiert also einen toten Pfad in die Zwischenablage, seine Keymap
`<leader>BI` ebenso, und es trägt selbst ein `--TEMP:`. `:Bindings path
[personal|extern]` macht dasselbe richtig und kennt beide Wurzeln — der
Modulkopf von `bindings_explorer` sagt das ausdrücklich.

→ `:BindingsPath` und `<leader>BI` entfernen, `<leader>BI` auf
`:Bindings path` legen. Dann auch
[`docs/NOTES/BINDINGS`](../../../../../../NOTES/) in der Keymap-Beschreibung nachziehen.

### 6.6 Kopplung und Priorität

Die alte Kopplung („läuft nach dem Repo-Durchgang, weil Zielorte fehlen") ist
**weitgehend aufgelöst**: die Zielorte existieren in 32/32 Repos. Was bleibt,
ist eine schwächere Abhängigkeit — `BND-04` diffed gegen `docs/BINDINGS.md`,
und wo P4 die noch nicht angefasst hat, diffed man gegen einen ungeprüften
Stand.

**Empfehlung:** `BND-01` bis `BND-03` und `BND-06` sind von P4 **unabhängig**
und können sofort laufen. `BND-04` pro Plugin dann, wenn dessen voller
Durchgang durch ist — oder gebündelt danach.

**Nebenbefund:** `PersonelPlugins/BINDINGS/rateltemtry.md` — Tippfehler für
„Telemetry". Klärt sich mit `BND-04`/`BND-05` von selbst.

---

## 7. Source-Kommentare

Dasselbe Prinzip (P1), angewandt auf den Quelltext. Läuft im selben
Repo-Durchgang, weil die Dateien ohnehin offen sind.

| ID | Prüfung |
|---|---|
| `CMT-01` | Kommentar erklärt **warum**, nicht **was** — „was" sagt der Code |
| `CMT-02` | Keine auskommentierten Code-Blöcke (`git log` hat sie) |
| `CMT-03` | Keine veralteten Kommentare, die dem Code widersprechen |
| `CMT-04` | Keine Verlaufs-/Changelog-Kommentare im Code |
| `CMT-05` | Keine verwaisten TODO/FIXME ohne Kontext → Roadmap oder weg |
| `CMT-06` | Alle Kommentare auf Englisch |
| `CMT-07` | LuaLS-Annotationen (`@param`, `@return`) korrekt und vollständig |
| `CMT-08` | Zu tiefe Herleitungen → `wkdbook-myplugins`, im Code bleibt der Verweis |

`CMT-07` überschneidet sich mit den Regeln aus
`$REPOS_DIR\WKDBooks\Development\wkdbook-Lua\Checklists\` — siehe
[§8.2](#82-diagnostics-erneut-anwenden). Nicht doppelt prüfen: Bei
`CMT-07` nur die Existenz, die inhaltliche Regel-Prüfung macht der
Diagnostics-Lauf.

---

## 8. Die fünf Wiederholungsläufe

Alle fünf sind Wiederholungen abgeschlossener Durchgänge. Der neue Code seit
dem letzten Lauf (ca. 2026-08-27) ist der Prüfgegenstand — **nicht** der alte
Bestand.

**Neuer Prüfgegenstand:** `hover.nvim` ist seit dem letzten Durchgang
komplett neu (erster Commit 2026-09-01) und war in keinem der Läufe dabei.
Es braucht überall den **Erstdurchlauf**, nicht den Delta-Check. Alle anderen
30 Repos haben zwischen 2026-08-27 und 2026-09-03 Commits — dort genügt das
Delta.

### 8.1 lib.nvim-Nutzung im neuen Code

Grundlage: `ERLEDIGT/Handover_ERLEDIGT/HANDOVER_dedup.md`.
Werkzeug: **`:LibDuplicateScan $REPOS_DIR`**.

Bewusst nicht angefasste Fälle aus dem letzten Lauf — bei Treffern nicht
erneut aufrollen: `config.M.get`, `try_require`, `notify.resolve`
(buffer-ctx/fileops), `M.augroup` (cascade/spotlight). Das sind
Soft-Dependency-Brücken, die *ohne* lib.nvim funktionieren müssen. Wenn der
Scan sie meldet, ist das erwartetes Verhalten und kein Befund.

### 8.2 Diagnostics erneut anwenden

Grundlage: `ERLEDIGT/DIAGNOSTICS/`.

Wichtig: Die Diagnostics-Dateien selbst sind **nur die Quittung**. Der Inhalt —
34 Regeln (`LLS-01`…`LLS-43`) und 11 Gate-Punkte (`NEW-36`…`NEW-46`) — steht in
`$REPOS_DIR\WKDBooks\Development\wkdbook-Lua\Checklists\`. Der Wiederholungslauf
prüft gegen **diese Regelsammlung**, nicht gegen die alten Reports.

„Mit dem, was gelernt wurde": Der letzte Durchgang brauchte 14 Runden, bis die
Regeln stabil waren. Diesmal stehen sie schon — der Lauf ist Anwendung, nicht
Ableitung. Neue Regeln nur, wenn ein Fall auftritt, den keine bestehende deckt,
und dann nach dem dortigen `WORKFLOW.md § F`: erst der Fall, dann die Regel.

### 8.3 Magic Numbers erneut prüfen

Grundlage: `ERLEDIGT/Handover_ERLEDIGT/zahlen-ohne-namen.md`.
Werkzeug: **`:Insights smells`**.

Filterregel aus dem letzten Lauf übernehmen: Defers/Waits **unter 50 ms** sind
kein Befund („raus aus dem aktuellen Tick", keine Einstellung).

Der letzte Lauf fand 43 Zahlen und 47 Plattform-Verzweigungen und löste den
Großteil über eine gemeinsame Hilfsfunktion für Float-Größen
(`vim.o.columns * 0.8`, 26 Fälle in 9 Plugins). **Erwartung für den neuen
Lauf:** Wo neuer Code diese Rechnung wieder von Hand macht, ist das der Befund
— nicht die Zahl selbst, sondern die Umgehung der bestehenden Lösung.

### 8.4 Keymap↔Usercmd-Parität

Grundlage: `ERLEDIGT/keymap-command-parity.md`.
Werkzeug: **`:LibBindingsAudit`** + **`:LibBindingsAuditGaps`**.

Letzter Stand: **keine Lücke** über 29 Plugins.

Die Automatik meldet **Kandidaten**, keine Befunde — jeder braucht eine
Handprüfung, weil eine ganze Klasse von Abdeckung maschinell unsichtbar ist:

> Eine Route mit typisiertem Argument deckt N Actions ab, ohne eine davon beim
> Namen zu nennen. (`:Open firefox` — eine Route mit `OPEN_TARGET`-Argument.)

Wer diese Warnung überliest, produziert Falschbefunde.

### 8.5 Konfigurierbarkeit

Grundlage: `ERLEDIGT/nicht-konfigurierbare-features.md`.
Werkzeug: **`:Insights smells`** (deckt `hardcoded_constants` mit ab).

Bekannter blinder Fleck, der eine Handprüfung braucht: Der Scan sieht
**Verzweigungen ohne Namen** nicht (`if vim.fn.has("win32") == 1`). Und er
zieht `DEFAULT_`-Präfixe ab, bevor er in der Config nachsieht — ein
`DEFAULT_MIN_LEVEL` hinter `toc.min_level` ist korrekt *kein* Befund.

---

## 9. Vorgehen: vertikal, in Wellen

Der Gedanke aus dem Auftrag — *„wahrscheinlich tokensparender, wenn man eine
Liste hat und die dann Repo für Repo einzeln durchgeht, also vertikal"* — ist
richtig, mit **einer Einschränkung**:

> Vertikal geht nur, wenn der Standard vorher steht. Sonst entscheidet Repo 1
> etwas, das Repo 17 anders entscheidet, und der dritte Durchgang korrigiert
> beide.

Daher: **einmal horizontal den Standard festlegen** (§3, §4, §5 — dieses
Dokument leistet den Großteil davon), **dann vertikal abarbeiten**.

### 9.1 Ablauf pro Repo

Ein Repo ist eine geschlossene Arbeitseinheit, die mit einem Commit endet:

1. `docs/`-Baum lesen, gegen [§4](#4-die-docs-checkliste) prüfen
2. Werkzeuge laufen lassen (`:LibUsercmdDocsCheck`, `:LibAutocmdDocsCheck`,
   `:LibBindingsAudit`, `:Insights smells`)
3. Struktur angleichen (Renames, `FEATURES/`-Konsolidierung, fehlende
   Overviews)
4. Inhalte prüfen: Doppelungen, Falschbehauptungen, tote Links
5. Auslagern nach `wkdbook-myplugins/<repo>/`
6. README nach [§5](#5-readme-konzept) überarbeiten
7. Source-Kommentare nach [§7](#7-source-kommentare)
8. Commit + Push auf `main`
9. Zeile in die Handover-Datei

### 9.2 Wellen

Maximal **3 Repos parallel** (feste Vorgabe). 31 Repos = 11 Wellen.

Die Zusammenstellung der Wellen ist nicht beliebig:

| Welle | Repos | Warum |
|---|---|---|
| 0 | `lib.nvim` | Referenz-Implementierung des Standards. Allein, nicht parallel — alle weiteren Wellen richten sich danach. |
| 1 | `hover.nvim`, `mdview.nvim`, `lsp.nvim` | Die Ausreißer ([Befund G](#13-was-nicht-einheitlich-ist--die-echten-befunde)). Fehlende Pflichtbausteine, größte README-Abweichung. Früh, weil sie den Standard am härtesten testen. |
| 2 | `debugging.nvim`, `replacer.nvim`, `reposcope.nvim` | Die drei mit `FEATURES`-Doppelung ([Befund C](#13-was-nicht-einheitlich-ist--die-echten-befunde)) |
| 3 | `color_my_ascii.nvim`, `gopath.nvim`, `documentation.nvim` | Deutsche Dubletten + `docs/README.md`-Frage ([Befund D](#13-was-nicht-einheitlich-ist--die-echten-befunde), [F](#13-was-nicht-einheitlich-ist--die-echten-befunde)) |
| 4–10 | Rest, alphabetisch | Routine — der Standard ist dann eingefahren |

**Warum die Ausreißer zuerst:** Wenn der Standard an `hover.nvim` scheitert,
ist es billiger, das nach einem Repo zu merken als nach fünfundzwanzig.

### 9.3 Auslagerung nach wkdbook-myplugins

`wkdbook-myplugins/<repo>/` existiert bereits für alle Plugins, enthält aber
bisher **ausschließlich** `ROADMAP/`. Für ausgelagerte Docs braucht es eine
zweite Kategorie → [offene Entscheidung E3](#11-offene-entscheidungen).

Vorschlag:

```
wkdbook-myplugins/<repo>/
├── ROADMAP/          (bestehend)
└── NOTES/            (neu — ausgelagerte Docs, Herleitungen, Verläufe)
```

Beim Verschieben: **Herkunft im Kopf der Datei notieren** (Originalpfad +
Datum). Sonst ist in drei Monaten unklar, warum eine Datei dort liegt. Die
Dateien in `ERLEDIGT/` machen das bereits vor (`roadmap-tools-analysis.md`
hat einen Nachtrag-Block, der genau das leistet) — dieselbe Form übernehmen.

---

## 10. Phasenplan

| Phase | Inhalt | Ergebnis | Blockiert durch |
|---|---|---|---|
| **P0** | Dieses Dokument + Handover-Gerüst | ✅ erledigt | — |
| **P1** | Entscheidungen E1–E6 klären | Standard ist verbindlich | **User** |
| **P2** | README-Konzept schreiben | `MyNotes\docs\README-KONZEPT.md` | P1 (E1, E2) |
| **P3** | Welle 0: `lib.nvim` als Referenz | Musterrepo, Standard validiert | P2 |
| **P4** | Wellen 1–10: 30 Repos vertikal | Alle Repos auf Standard | P3 |
| **P5** | Wiederholungsläufe ([§8](#8-die-fünf-wiederholungsläufe)) | 5 Reports | P4 (teilweise parallel) |
| **P6** | BINDINGS-Sanierung ([§6](#6-bindings-sanierung)) | Cheatsheet ist Cheatsheet | P4 (braucht Zielorte) |
| **P7** | Abschlussbericht | Ablage in `ERLEDIGT/` | P5, P6 |

**Zu P5:** Die Läufe 8.1, 8.3 und 8.5 sind Kommandoläufe über alle Repos
gleichzeitig und lassen sich **vor** P4 fahren — die Ergebnisse fließen dann in
die Repo-Durchgänge ein, statt eine eigene Runde zu brauchen. 8.2 und 8.4
brauchen Handprüfung und laufen besser danach.

**Zur Reihenfolge P4 → P6:** BINDINGS kann erst saniert werden, wenn die
Repo-Docs die Zielorte für verschobenes Wissen anbieten.

**Commits:** Pro Repo einer, direkt auf `main` gepusht (Vorgabe: Updates sollen
sofort nutzbar sein). Die Konzeptdateien in der nvim-config werden zunächst
**nicht** committet.

---

## 11. Offene Entscheidungen

**Alle sechs sind entschieden (2026-09-03).** E2, E4 und E6 vom Autor; E1, E3
und E5 delegiert und hier festgehalten.

**E1 — Alpha-Disclaimer: Wortlaut? → ✅ minimale Ergänzung, 31× skriptbar**

Da bereits ein wortgleicher Block in allen 31 READMEs steht
([Befund A](#13-was-nicht-einheitlich-ist--die-echten-befunde)), wird er nicht
ersetzt, sondern um das fehlende Wort ergänzt:

```
> **Alpha stage — active development.** This repository is in its development
> phase — breaking changes are to be expected at any time. Pin a commit or tag
> if you depend on it.
```

Geändert wird nur der fette Satzanfang. Die Eigenformulierungen von `lsp.nvim`
und `mdview.nvim` weiter unten im Dokument bleiben unangetastet.

**E2 — README-Länge: Richtwert 100–250 Zeilen? → ✅ ja**

Mit der ausdrücklichen Einschränkung des Autors:

> Nicht blind nach `docs/` wandern lassen — nur was Sinn macht.

Beim Kürzen gibt es daher **drei** Wege, nicht einen: verlinken, verschieben,
oder streichen. Ausformuliert im README-Konzept ([§5](#5-readme-konzept)),
Abschnitt „Die Kürzungsregel".

**E3 — `wkdbook-myplugins`: Ordnername? → ✅ `NOTES/`**

Neben dem bestehenden `ROADMAP/`. Gewählt, weil es die Sache benennt
(Notizen) statt eine Wertung zu transportieren (`DEEP/`, `INTERN/`) und weil
es sich nicht mit `docs/` im Repo verwechseln lässt (`DOCS/`).

**E4 — Die fünf deutschen Dateien? → ✅ entfernen**

> „Das war irgendwann mal eine Idee, die sich nicht bewährt hat, als das Repo
> gewachsen ist."

Betroffen: `color_my_ascii.nvim/docs/README-de.md`, `QUICKSTART-de.md`,
`gopath.nvim/docs/CACHE-DE.md`, `LUA-SYMBOLS-DE.md`, `RESOLUTION-DE.md`.

⚠️ **Nicht nur löschen.** `gopath.nvim` hat **10 eingehende Links**, darunter
eine ganze „German"-Spalte in `docs/README.md` und drei
„🇩🇪 Deutsche Version"-Blockquotes in den englischen Originalen. Die müssen
mit weg, sonst bleiben tote Links zurück. Bei `color_my_ascii.nvim` sind die
Dateien bereits verwaist (0 eingehende Links) — dort reicht das Löschen.

**E5 — `USECASES/`: für welche Repos? → ✅ nur wo es echte Usecases gibt**

Kein Flächen-Rollout. Ein `USECASES/`-Ordner entsteht, wenn beides zutrifft:

1. Das Plugin hat eine **öffentliche, für Fremdnutzung gedachte** Lua-API, und
2. es gibt eine Aufgabe, deren Lösung **mehr als einen API-Aufruf** braucht.

Bedingung 2 ist die entscheidende. `fileops.nvim`s `api.md` etwa ist eine
1:1-Abbildung der `:File`-Subcommands — jeder Aufruf steht für sich, es gibt
keinen mehrschrittigen Usecase. Dort wäre `USECASES/` eine leere Hülle.
`lib.nvim` dagegen ist der klare Fall: dort ist Fremdnutzung der Zweck.

Die Entscheidung fällt **pro Repo beim Durchgang** und wird in der
Handover-Datei begründet — nicht vorab per Liste.

**E6 — Pilot-Repo? → ✅ `fileops.nvim`, danach `lib.nvim`**

Vom Autor freigestellt. Gewählt, weil `fileops.nvim` mit nur 13 Doku-Dateien
zufällig **alle drei Problemklassen** auf einmal enthält:

- `FEATURES.md` als Datei (414 Zeilen) → Test der Ordner-Konsolidierung
- `api.md` (25 Zeilen) → Test der USECASES-Abgrenzung
- `BINDINGS.md` + `keymaps.md` + `commands.md` nebeneinander → Test der
  Doppelungsfrage

Damit validiert der Pilot den Standard, ohne 52 Dateien zu kosten. `lib.nvim`
folgt als Welle 0.5 — es ist die geteilte Basis und muss stimmen, bevor 29
weitere Repos darauf zeigen.

**Nachtrag: `fileops.nvim` ist bereits sehr nah am Zielbild.** 108
README-Zeilen, Disclaimer, ASCII, Badges, ein begründeter Sibling-Hinweis auf
`sessions.nvim`, Quickstart, Doku-Wegweiser. Es dient dem README-Konzept
([§5](#5-readme-konzept)) deshalb als **Musterbeispiel** — der Standard wird
an ihm abgelesen, nicht ihm auferlegt (P4).
