# Wissensbasis durchsuchbar machen: KB-Artikel, SWAT-Tickets, Tosca-Notizen

Stand: 2026-10-14 · Anlass: Case 1268054 (License lost / ToscaConnect), bei dem KB- und SWAT-Artikel erstmals zentral abgelegt wurden.

## Table of content

  - [1. Ausgangslage](#1-ausgangslage)
  - [2. Befunde](#2-befunde)
  - [3. Zielbild](#3-zielbild)
  - [4. Baustein A: Ablage-Konvention (Frontmatter + Index)](#4-baustein-a-ablage-konvention-frontmatter--index)
  - [5. Baustein B: StartChat.md - neuer Abschnitt für Claude](#5-baustein-b-startchatmd---neuer-abschnitt-für-claude)
  - [6. Baustein C: Suche für dich in Neovim](#6-baustein-c-suche-für-dich-in-neovim)
  - [7. Baustein D: casedesk verbindet Case und Wissensbasis](#7-baustein-d-casedesk-verbindet-case-und-wissensbasis)
  - [8. Phasenplan](#8-phasenplan)
  - [9. Offene Fragen](#9-offene-fragen)

---

## 1. Ausgangslage

Workflow heute: Ein neuer Chat startet mit `Workflow/CDX/StartChat.md` + Activity Stream. Claude arbeitet dann im Case-Ordner und liest die CDX-Ressourcen. Im Case 1268054 kamen drei neue Wissensquellen dazu:

| Quelle | Ort | Umfang (heute) | Herkunft |
| --- | --- | --- | --- |
| KB-Artikel | `WKDBook-Tricentis/MyDomains/KB/License/` | 4 Dateien | Support Hub (öffentlich) + internes ServiceNow (`tricentiscsm`) |
| SWAT-Tickets | `WKDBook-Tricentis/MyDomains/SWAT/License/` | 5 Dateien | Jira `SWAT-*` |
| Tosca-Notizen (Onboarding) | `WKDBook-Tricentis/MyDomains/Tosca/` | 458 Dateien, davon 329 `.md` | eigene Notizen, Bootcamp, Fundamentals-Übungen |

Daneben gibt es schon: `Cases/Solutions/<Topic>/Solution.md` (casedesk `:Case promote`), `Terminologie/`, `Notes/`, `Workflow/`.

Zwei Nutzer brauchen dieselbe Wissensbasis:

1. Claude in einem neuen Chat - hat Dateizugriff auf das Repo, weiß aber nicht, dass und wo es suchen soll.
2. Du in Neovim - willst gezielt in KB/SWAT/Tosca suchen, ohne alle 458 Tosca-Dateien zu durchwühlen.

Zur Nachfrage nach cascade.nvim: cascade.nvim ist für Listen/Cycling in Markdown und Code zuständig und hat mit Suche nichts zu tun. Die passenden Plugins sind casedesk.nvim (Case-Kontext, `:Tricentis`), pickers.nvim (Collections = Suchbereiche) und lib.nvim (Frontmatter-Parser). Der Bericht geht davon aus, dass casedesk gemeint war.

---

## 2. Befunde

### 2.1 casedesk zeigt noch auf den alten Tosca-Pfad (Bug)

Commit `36a2bdd` ("my domains") im WKDBook-Tricentis-Repo hat `Tosca/` nach `MyDomains/Tosca/` verschoben. casedesk kennt den neuen Ort nicht:

| Stelle | Inhalt | Folge |
| --- | --- | --- |
| `casedesk.nvim/lua/casedesk/links.lua` (`AREAS`, fest verdrahtet) | `{ name = "tosca", dir = "Tosca" }` | `:Tricentis links tosca` findet nichts |
| `casedesk.nvim/lua/casedesk/config/DEFAULTS.lua` (`command_topics`) | `Tosca`, `Tosca/Notes/Tosca_Engines/...` | `:Tricentis commands/cheatsheet tosca|engines|mobile|api|excel` leer |
| `CHEATSHEET.md` / Doku | "`Tosca/` too" | Doku veraltet |

`MyDomains/` als Ganzes (KB, SWAT, AppStack, Horizon, VDI) kommt in keinem `:Tricentis`-Scope vor.

### 2.2 Es gibt schon fast alle Bausteine

| Baustein | Plugin | Was es schon kann |
| --- | --- | --- |
| Suchbereiche mit eigenen Tasten | pickers.nvim `collections` | Ein Eintrag = ein Verzeichnis, erzeugt `:Pickers <name> files/grep/smart` + Compat-Befehle + Keymaps. Pro Collection `find.exclude`. Konfiguriert in `nvim/lua/plugins/personal/specs/navigate.lua` (bisher `notes`, `notes_lua`, `notes_nvim`, `checklists`, `spickzettel`) |
| Live-Grep im Case-Kontext | casedesk `:Case grep`, `:Cases livegrep` | über pickers.nvim |
| Ähnlichkeit ohne KI | casedesk `similar.lua` (TF-IDF), `fingerprint.lua` (exakte Fehlerstrings) | bisher nur über Cases, nicht über KB/SWAT/Notizen |
| Fakten aus dem Stream | casedesk `jql.lua` | extrahiert schon KBA-Nummern und Fehlercodes |
| KI-Prompt | casedesk `ki.lua` (`:Case ki`) | bettet Policies ein, kennt `--inline`, anonymisiert |
| Frontmatter lesen | lib.nvim `lib.nvim.markdown.frontmatter` | flaches YAML inkl. Inline-Listen `[a, b]` |
| Token markieren | spotlight.nvim | `:Case spotlight` markiert KBA-Nummern im Stream |
| SWAT pro Case | casedesk `:Case swat` | öffnet `SWAT/Technicals.md` im Case - ein Case-lokaler Ort, kein zentraler |

Fazit: Es fehlt kein neues Plugin. Es fehlen (a) eine Ablage-Konvention, (b) Konfiguration und (c) zwei, drei casedesk-Routen, die die vorhandenen Teile verbinden.

### 2.3 Tosca-Notizen sind zu groß für "einfach alles lesen"

Verteilung (Dateien je Ordner, Auszug): `Onboarding/Tosca/Fundamentals/AE1/Excercises` 36, `.../AS1/Exercises` 33, `Onboarding/Processes/CaseRelated` 15, `Cheetsheets` 14 (viele PDFs), `Onboarding/TricentisPolicies` 13, `Notes/**` ~120.

Die Übungsordner sind für Case-Recherche fast immer Rauschen. Wertvoll für Cases sind vor allem `Notes/` (Engines, DEX/AOS, Tosca Server, XScan, SAP, Versionierung), `Onboarding/Bootcamp/PART2 - Licensing` (für 1268054 wäre das relevant gewesen), `Onboarding/Processes/CaseRelated`, `BestPractices/`.

### 2.4 Sicherheitsbefund: Credentials in MyDomains

`MyDomains/AppStack/Notes/Credentials.md` liegt im selben Baum. Wenn "durchsuche MyDomains" die Regel wird, kann diese Datei in einen Chat oder - schlimmer - über `:Case ki --send` an einen KI-Provider gelangen. Die Datei muss aus jedem Wissensbasis-Scope und jedem Prompt-Pfad ausgeschlossen werden (Details in Abschnitt 4.4). Inhalt wurde für diesen Bericht nicht gelesen.

### 2.5 Interne KB-Artikel sind ein Risiko für Kundentexte

Im Case 1268054 stand KB0016652 (intern, "Do not propose this solution directly to any user") zuerst als Link im Kundenentwurf. Die Sichtbarkeit muss maschinenlesbar am Artikel hängen, damit Claude und casedesk sie prüfen können.

---

## 3. Zielbild

```text
WKDBook-Tricentis/MyDomains/
├── KB/
│   ├── INDEX.md                  ← generiert: eine Zeile pro Artikel
│   ├── License/KB0011252_....md  ← Frontmatter + DE-Zusammenfassung + Original
│   └── <Topic>/...
├── SWAT/
│   ├── INDEX.md
│   └── <Topic>/SWAT-xxxx_....md
└── Tosca/
    ├── INDEX.md                  ← kuratierte Landkarte (Ordner → Thema), keine Dateiliste
    └── ...
```

- Ein Artikel = eine Datei mit Frontmatter (ID, Typ, Sichtbarkeit, Thema, Stichworte, Fehlertexte, Cases).
- Pro Bereich eine `INDEX.md`, die Claude zuerst liest (billig) und die du als Überblick nutzt.
- Themenordner (`License`, `DEX`, `XScan`, `SAP`, ...) parallel zu `Cases/Solutions/<Topic>`, damit KB, SWAT und Solutions dieselben Themen sprechen.
- Claude bekommt in `StartChat.md` eine feste Suchreihenfolge und Regeln.
- Du bekommst pickers-Collections + `:Tricentis`-Scopes, später `:Case knowledge`, das zu einem Case die passenden Artikel vorschlägt.

---

## 4. Baustein A: Ablage-Konvention (Frontmatter + Index)

### 4.1 Frontmatter-Schema

Flach, damit `lib.nvim.markdown.frontmatter` es ohne Erweiterung liest (Listen inline):

```yaml
---
id: KB0016652
type: kb                     # kb | swat | note
title: ToscaConnect Client License not Found - How to Disable
visibility: internal         # public | internal  (Pflichtfeld bei kb)
topic: License
product: Tosca
url: https://tricentiscsm.service-now.com/open?id=kb_article_view&number=KB0016652
tags: [ToscaConnect, TCProperty, ToscaConnectEnabled, Update All]
errors: ["ToscaConnect Client License not found"]
related: [SWAT-3630, SWAT-3448]
cases: [1268054]
updated: 2026-07-27
---
```

| Feld | Zweck |
| --- | --- |
| `visibility` | Claude/casedesk dürfen `internal` nie in `Replies/` verlinken (siehe 2.5) |
| `errors` | exakte Fehlertexte - Brücke zu `fingerprint.lua` und zum Activity Stream |
| `tags` | Synonyme/Fachbegriffe - Brücke zu `similar.lua` |
| `cases` | Rückverweis: in welchen Cases der Artikel geholfen hat |
| `related` | Querverweise KB ↔ SWAT ↔ Bug |

Die bisherige Kopf-Tabelle (Jira-Link, Case, Stichworte ...) wird dadurch zum großen Teil redundant. Vorschlag: Tabelle weglassen, Frontmatter ist die Quelle; der Rest der Datei bleibt (DE-Zusammenfassung, dann Original). markdown.nvim/Renderer zeigen Frontmatter ohnehin kompakt an. Falls du die Tabelle für die Lesbarkeit behalten willst: nur `url` als Markdown-Link darunter.

### 4.2 Dateiaufbau (bleibt wie heute)

1. Frontmatter
2. `# <ID> - <Titel>`
3. `## Zusammenfassung (DE)` - Problem, Ursache, Lösung/Workaround, Status, "Lessons learned"
4. Originaltext (aufgeräumt, Links als Markdown-Links)

Dateiname weiter `ID_Titel.md`, Windows-unzulässige Zeichen (`:` usw.) ersetzt, `(INTERNAL)` im Namen bei internen Artikeln beibehalten - doppelt hält besser.

### 4.3 INDEX.md

Eine Zeile pro Artikel, aus dem Frontmatter erzeugt:

```markdown
| ID | Titel | Sicht | Thema | Fehlertexte | Stichworte | Cases |
| --- | --- | --- | --- | --- | --- | --- |
| [KB0016652](License/KB0016652_....md) | ToscaConnect Client License not Found - How to Disable | internal | License | "ToscaConnect Client License not found" | ToscaConnect, TCProperty | 1268054 |
```

Bis es einen Generator gibt (Abschnitt 7.3), kann Claude den Index beim Ablegen eines Artikels mitpflegen - dafür steht eine Regel in StartChat.md.

Für `MyDomains/Tosca/INDEX.md` keine Dateiliste, sondern eine handgeschriebene Landkarte: Ordner → Thema → "wann relevant" (z. B. `Onboarding/Bootcamp/PART2 - Licensing` → Lizenzmodelle, License Server; relevant bei License-Cases). Plus eine Zeile "nicht für Case-Recherche": `Onboarding/Tosca/Fundamentals/**/Exercises`.

### 4.4 Ausschlüsse

Zentral an einer Stelle definieren und überall gleich verwenden (StartChat-Regel, pickers `find.exclude`, casedesk-Korpus):

```text
MyDomains/AppStack/Notes/Credentials.md
**/Credentials*.md
MyDomains/Tosca/Onboarding/Tosca/Fundamentals/**/Exercises/**
*.pdf, *.png (nur über OCR-/PDF-Sidecars, wie bei Cases)
```

Besser noch: `Credentials.md` aus dem WKDBook-Repo herausnehmen (Passwort-Manager) - das ist unabhängig von diesem Konzept sinnvoll.

---

## 5. Baustein B: StartChat.md - neuer Abschnitt für Claude

Claude hat in diesen Chats Dateizugriff. Es braucht also keinen Inhalt im Prompt, sondern Ort, Reihenfolge und Regeln. Vorschlag für einen neuen Abschnitt zwischen "3. Regeln & Vorgaben" und "4. Input-Daten":

```markdown
## 3a. Wissensbasis (für Claude)

Bevor du Lösungen, JQL oder Kundentexte schreibst, durchsuche die Wissensbasis in dieser Reihenfolge.
Lies zuerst die INDEX-Dateien, öffne nur passende Artikel:

1. `$REPOS_DIR/WKDBook-Tricentis/MyDomains/KB/INDEX.md` - KB-Artikel (öffentlich und intern)
2. `$REPOS_DIR/WKDBook-Tricentis/MyDomains/SWAT/INDEX.md` - SWAT-Tickets (intern)
3. `$REPOS_DIR/WKDBook-Tricentis/Cases/Solutions/` - bestätigte Lösungen aus früheren Cases
4. `$REPOS_DIR/WKDBook-Tricentis/MyDomains/Tosca/INDEX.md` - meine Tosca-Notizen (Landkarte)
5. Erst dann: Grep über diese Ordner mit den exakten Fehlertexten aus dem Activity Stream

Suchbegriffe: exakte Fehlermeldungen, KBA-/SWAT-Nummern aus dem Stream, Komponenten (z. B. "License Server", "DEX").

Regeln:
* Ausgeschlossen, nie öffnen: `**/Credentials*.md`, `MyDomains/Tosca/Onboarding/Tosca/Fundamentals/**/Exercises/**`.
* Artikel mit `visibility: internal` und alle SWAT-Tickets nie in `Replies/` oder `Summary.md` verlinken oder zitieren.
  Inhalt in eigenen Worten nur, wenn der Artikel das erlaubt (z. B. KB0016652: nur per Call umsetzen).
* Gefundene Artikel in `Research/` des Cases mit relativem Link auf die Datei nennen, mit einem Satz "warum relevant".
* Wenn ich KB-/SWAT-Texte in den Chat kopiere: nach dem Schema in `MyDomains/KB/README.md` ablegen
  (Frontmatter, DE-Zusammenfassung, aufgeräumter Originaltext, Themenordner), die INDEX.md ergänzen
  und die Case-Nummer in `cases:` eintragen. Bei bestehender Datei: aktualisieren statt duplizieren.
* Öffentliche KB-Links vor Verwendung im Kundentext prüfen; nicht prüfbare (Login) als "ungeprüft" kennzeichnen.
```

Ergänzend sinnvoll: eine `MyDomains/KB/README.md` (und analog `SWAT/README.md`) mit dem Schema aus Abschnitt 4 - dann bleibt StartChat.md kurz und das Schema hat genau einen Ort.

Ohne Dateizugriff (externer Chat): `:Case ki` würde die Treffer aus Abschnitt 7.2 als Block in den Prompt schreiben; `--inline` müsste dann auch die DE-Zusammenfassungen der Treffer einbetten (nur `visibility: public`, nur bei erlaubtem Provider).

---

## 6. Baustein C: Suche für dich in Neovim

### 6.1 pickers.nvim-Collections (nur Konfiguration, sofort möglich)

In `nvim/lua/plugins/personal/specs/navigate.lua`, Liste `collections`:

```lua
{
  name = "kb",
  dir = repos .. "/WKDBook-Tricentis/MyDomains/KB",
  keys = { files = "<leader>mkf", grep = "<leader>mkg", smart = "<leader>mks" },
},
{
  name = "swat",
  dir = repos .. "/WKDBook-Tricentis/MyDomains/SWAT",
  keys = { files = "<leader>mwf", grep = "<leader>mwg" },
},
{
  name = "tosca_notes",
  dir = repos .. "/WKDBook-Tricentis/MyDomains/Tosca",
  find = { exclude = { "Exercises", "Excercises", "*.pdf" } },
  keys = { files = "<leader>mtf", grep = "<leader>mtg", smart = "<leader>mts" },
},
{
  name = "mydomains",
  dir = repos .. "/WKDBook-Tricentis/MyDomains",
  find = { exclude = { "Credentials*.md", "Exercises", "Excercises" } },
},
```

Tasten sind Vorschläge - gegen `docs/NOTES/BINDINGS` prüfen. `find.exclude` gilt laut pickers-Doku auch für `grep`. Ergebnis: `:Pickers kb grep`, `:KbGrep`, `:SwatFiles`, `:ToscaNotesSmart` usw.

Grenze: Eine Collection hat genau ein `dir`. "KB + SWAT + Solutions in einem Rutsch" geht so nur über `mydomains` (ohne Solutions). Echte Mehrfach-Wurzeln wären eine pickers-Erweiterung (`dirs = {...}`), lohnt aber erst, wenn 7.1 nicht reicht.

### 6.2 casedesk `:Tricentis` reparieren und erweitern

1. Bug 2.1 beheben: `links.lua` `AREAS` und `DEFAULTS.lua` `command_topics` auf `MyDomains/Tosca` umstellen. `AREAS` dabei konfigurierbar machen (heute fest verdrahtet), Default aus `command_topics` ableiten statt doppelt pflegen.
2. Neue Scopes `kb`, `swat`, `mydomains` in dieselbe Liste - `:Tricentis links kb` listet dann alle Support-Hub-Links aus den KB-Artikeln.
3. Neue Route `:Tricentis grep [scope]`: Live-Grep über pickers mit dem Scope-Ordner als Wurzel (dasselbe Muster wie `:Cases livegrep`). Damit gibt es eine Suche, die auch aus einem Case-Buffer heraus ohne Tastenwissen funktioniert und `<Tab>`-Vervollständigung der Scopes hat.

---

## 7. Baustein D: casedesk verbindet Case und Wissensbasis

### 7.1 `:Case knowledge [nr]` - passende Artikel zu einem Case

Ziel: "Welche KB/SWAT/Notizen passen zu diesem Case?" ohne KI, nachvollziehbar wie `:Case similar`.

- Korpus: `config.knowledge_dirs` (Default `MyDomains/KB`, `MyDomains/SWAT`, `Cases/Solutions`, `MyDomains/Tosca/Notes`), Ausschlüsse aus 4.4 als `config.knowledge_exclude`.
- Zwei Signale, beide vorhanden:
  1. exakt: Fehlertexte/KBA-/SWAT-Nummern aus dem Stream (`jql.lua`-Faktenextraktion, `fingerprint.lua`) gegen `errors:`/`id:`/`related:` im Frontmatter und gegen den Volltext.
  2. lexikalisch: TF-IDF wie `similar.lua`, Query = Titel + Summary + Stream, Dokumente = Artikel (DE-Zusammenfassung + `tags`).
- Ausgabe: Picker mit Treffer, Score und "warum" (Begriffe), Markierung `internal`. Auswahl öffnet den Artikel.
- Optional `--write`: schreibt die Trefferliste als `Research/NN_Knowledge.md` mit relativen Links - das ist zugleich die Übergabe an Claude im Chat.
- `similar.lua` muss dafür ein austauschbares Korpus bekommen (heute fest auf Cases). Das ist die einzige echte Refaktorierung.

### 7.2 Treffer in `:Case ki`

`ki.lua` bekommt einen optionalen Block "Wissensbasis-Treffer" (Top 5 aus 7.1): ID, Titel, Sichtbarkeit, Pfad. Mit `--inline` zusätzlich die DE-Zusammenfassung, aber nur `visibility: public` und nie SWAT, wenn der Provider nicht auf der Allow-List ist (gleiche Logik wie die bestehende Anonymisierung).

### 7.3 Import und Index

- `:Tricentis kb add` / `:Tricentis swat add`: Zwischenablage (Support-Hub- bzw. Jira-Kopie) einlesen, UI-Reste entfernen (Avatare, "Add a comment", "Pro tip", Gravatar-Bilder - genau das, was heute von Hand gemacht wurde), ID und Titel erkennen, Thema per `kit.select`, Frontmatter vorbelegen, Dateiname bereinigen, Datei öffnen. Die DE-Zusammenfassung bleibt Handarbeit oder optional `casedesk.ai` (nur für `public`).
- `:Tricentis index [kb|swat]`: `INDEX.md` aus dem Frontmatter neu erzeugen (lib.nvim-Parser); `:Cases doctor` meldet Artikel ohne `visibility` oder ohne Eintrag im Index.
- `:Case kb link`: aktuelle KB-/SWAT-Datei mit dem Case verknüpfen → `cases:` im Artikel ergänzen (`frontmatter.patch`), Link in `Research/`.

### 7.4 Abgrenzung zu `:Case swat`

`:Case swat` öffnet heute `SWAT/Technicals.md` im Case. Vorschlag: bleibt für Case-spezifische Notizen zu einem SWAT-Task (z. B. eigener Swarm-Task des Cases), verlinkt aber auf die zentrale Datei unter `MyDomains/SWAT/`. Fremde SWAT-Tickets (Recherche) gehören zentral, nicht in den Case.

---

## 8. Phasenplan

| Phase | Inhalt | Aufwand | Code? |
| --- | --- | --- | --- |
| 0 - sofort | `KB/README.md` + `SWAT/README.md` mit Schema, Frontmatter in die 9 vorhandenen Dateien, `INDEX.md` für KB/SWAT, `Tosca/INDEX.md` (Landkarte), Abschnitt 3a in `StartChat.md`, Credentials-Datei ausschließen bzw. verschieben | ca. 1-2 h | nein |
| 1 - Konfiguration | pickers-Collections (6.1) | 15 min | nur Config |
| 2 - casedesk Fix | Tosca-Pfad-Bug (6.2 Punkt 1) + Scopes `kb`/`swat`/`mydomains` + `:Tricentis grep` | klein | ja, casedesk |
| 3 - Verknüpfung | `:Case knowledge` inkl. austauschbarem Korpus in `similar.lua` (7.1), `:Tricentis index`, doctor-Checks | mittel | ja, casedesk (+ ggf. lib.nvim) |
| 4 - Komfort | `:Tricentis kb/swat add` (7.3), Block in `:Case ki` (7.2), `:Case kb link` | mittel | ja, casedesk |

Phase 0 bringt Claude sofort den größten Nutzen, Phase 1 dir. Ab Phase 3 schließt sich der Kreis: casedesk findet die Artikel, schreibt sie in `Research/`, Claude liest sie dort.

Ablage der Umsetzungs-Tasks: laut Vorgaben nach `tasks-vault/casedesk.nvim/ROADMAP/` (Phasen 2-4) bzw. pickers-Config-Notiz in die nvim-Config.

---

## 9. Offene Fragen

1. Frontmatter statt Kopf-Tabelle in den KB/SWAT-Dateien - einverstanden, oder beides behalten?
2. Themenordner: gleiche Namen wie `Cases/Solutions/<Topic>` (heute `DEX_GPO_Autologon`, `Tosca_OSV`, `NOT_SAP`) erzwingen, oder grobere Themen (`License`, `DEX`, `XScan`, `SAP`, `Server`)?
3. Soll `MyDomains/Tosca` dauerhaft dort bleiben? Wenn ja, casedesk-Default auf `MyDomains/Tosca` umstellen; wenn noch Umzüge geplant sind, erst `AREAS` konfigurierbar machen und den Pfad in die Install-Spec legen.
4. `Credentials.md`: verschieben (empfohlen) oder nur ausschließen?
5. Sollen SWAT-Inhalte überhaupt in KI-Prompts an externe Provider (auch anonymisiert)? Vorschlag: nein, nur ID + Titel.
