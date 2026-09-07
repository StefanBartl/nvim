# Handover — README-Vereinheitlichung aller *.nvim-Plugins

**Stand:** 2026-09-07 · **Fortschritt:** **abgeschlossen.** 32 von 32 Plugins
fertig, committet und gepusht auf `main`.

---

## Table of content

- [Was die Aufgabe war](#was-die-aufgabe-war)
- [Wo der Standard liegt](#wo-der-standard-liegt)
- [Die feste Abschnittsreihenfolge](#die-feste-abschnittsreihenfolge)
- [Abschlussprüfung](#abschlussprüfung)
- [Was im zweiten Durchgang gefunden wurde](#was-im-zweiten-durchgang-gefunden-wurde)
- [Offene Punkte](#offene-punkte)
- [Befunde aus dem ersten Durchgang](#befunde-aus-dem-ersten-durchgang)
- [Die Prozedur pro Plugin](#die-prozedur-pro-plugin)
- [Regeln für die Sitzung](#regeln-für-die-sitzung)

---

## Was die Aufgabe war

Alle Root-`README.md` der `StefanBartl/*.nvim`-Plugins sollten **dieselbe
Struktur** haben: dieselben Abschnitte, in derselben Reihenfolge, mit denselben
Überschriften. Plugin-spezifische Abschnitte sind erlaubt und werden an einer
festen Stelle eingeschoben.

Dazu kam ein Flotten-weiter Statuswechsel: **Alpha → Beta**, Blockquote und
Badge immer gemeinsam.

Die Repos liegen unter `$REPOS_DIR` (= `E:\repos`). Die Installations-Specs
stehen in `vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua`.

---

## Wo der Standard liegt

Der Standard ist **geschrieben und committet**, nicht nur in einem Chat. Zwei
Dateien, beide im Repo `WKDBooks` (gepusht):

| Datei | Inhalt |
| --- | --- |
| `E:/repos/WKDBooks/Development/wkdbook-myplugins/TEMPLATES/README-NVIM-PLUGIN/README.template.md` | Die Vorlage selbst, Fassung 2. Kopierbar, mit `{{…}}`-Platzhaltern und Kommentaren, warum jeder Abschnitt so aussieht |
| `E:/repos/WKDBooks/Development/wkdbook-myplugins/TEMPLATES/README-NVIM-PLUGIN/CHECKLIST.md` | Die Prüfliste dazu, Fassung 2. Abschnitt 0 ist die Reihenfolgentabelle; die übrigen 15 Abschnitte sind die Einzelprüfpunkte mit Priorität (🔴/🟡/🟢) |

**Bei jeder Abweichung, die künftig entschieden wird: dort nachtragen, nicht nur
im Repo umsetzen.** Negativbeispiele in der Checkliste sind reale Funde mit
Datum, keine erfundenen Fälle.

---

## Die feste Abschnittsreihenfolge

| # | Abschnitt | Pflicht |
| --- | --- | --- |
| 1 | `## Table of contents` | ja |
| 2 | `## Documentation` | ja — **direkt nach dem ToC**, nicht am Ende |
| 3 | `## What it does` | ja |
| 4 | `## Around it` | optional |
| 5 | `## Requirements` | ja |
| 6 | `## Installation` | ja — eigener Abschnitt, geht nicht in Quickstart auf |
| 7 | `## Quickstart` | ja |
| 8 | `## What you get with the defaults` / `… with the preset` | optional |
| 9 | plugin-spezifische Abschnitte | optional, beliebig viele |
| 10 | `## Integrations` | optional |
| 11 | `## Statusline` | optional, nur Verweis |
| 12 | `## Health check` | optional |
| 13 | `## Contributing` | ja |
| 14 | `## Feedback` | ja |
| 15 | `## License` | ja |

Darüber, vor dem ersten `##`: Status-Blockquote als **allererste Zeile**, dann
`# name.nvim`, ASCII-Art, Badges, Intro (max. ~15 Zeilen).

Wortlaut des Status-Blockquote (überall identisch):

```markdown
> **Beta stage — active development.** This repository is past its first shape and in
> active use, but the surface is not frozen: breaking changes are still possible. Pin a
> commit or tag if you depend on it.
```

Badge dazu: `![Status](https://img.shields.io/badge/status-beta-orange)`.

**`## Documentation` steht direkt nach dem ToC.** Das war die wörtliche
Anweisung und ist in allen 32 Repos so umgesetzt — die Frage ist entschieden.

---

## Abschlussprüfung

Über alle 32 Repos maschinell geprüft und in allen erfüllt:

- Status-Blockquote in **Zeile 1**, Wortlaut identisch
- kein `Alpha stage` / `status-alpha` mehr irgendwo im README
- `status-beta-orange`-Badge vorhanden
- genau ein `## Table of contents` (nicht `Table of Content(s)`)
- `## Documentation`, `## Contributing`, `## Feedback` vorhanden
- `docs/CONTRIBUTING.md` vorhanden und aus `docs/README.md` unter
  `## Working on it` verlinkt
- Arbeitsbaum sauber, nichts ungepusht

Zusätzlich einmal über alle READMEs und `docs/*.md` gelaufen: **keine defekte
Markdown-Tabelle.** Die Treffer eines ersten Durchlaufs waren durchweg
escapte `\|` innerhalb von Zellen, also gültig.

---

## Was im zweiten Durchgang gefunden wurde

Die 12 Repos des zweiten Durchgangs waren `language` · `lib` · `lsp` ·
`markdown` · `mdview` · `open` · `pdfport` · `pickers` · `recommender` ·
`replacer` · `reposcope` · `runtime-analysis` · `sandbox` · `sessions` ·
`spotlight`. Die namentlich genannten Einzelaufträge sind alle erledigt:

| Repo | Auftrag | Ergebnis |
| --- | --- | --- |
| `runtime-analysis` | „Shipped."-Marker raus | erledigt — Statusmarker im README ist Changelog-Material |
| `replacer` | defekte Tabelle unter Documentation | war eine kopflose `\| \| \|`-Tabelle (gültig, rendert aber mit leerem Header) → durch die Bulletliste der Flotte ersetzt |
| `mdview` | doppelter Status-Blockquote | erledigt, Zeile 3 entfernt |
| `sandbox` | Statusline auslagern | `docs/statusline.md` angelegt, README auf einen Absatz gekürzt |
| `sessions` | dito | `docs/statusline.md` angelegt; die Statusline-Sektion aus `docs/api.md` dorthin verschoben |
| `pickers` | zu viel Text vor dem ToC | Intro auf Pitch + 1 Satz; `smart` und die Bildvorschau haben jetzt eigene Abschnitte |
| `open` | dito | Intro auf Pitch + 2 Sätze; `## Context Menu (optional)` als `### Context menu` unter `## Integrations` |
| `pdfport` | `filetree.nvim` namentlich nennen | erledigt in README (Around it + Integrations) **und** in `docs/integrations.md`. Wichtig: filetree.nvim braucht **keinen** Adapter — es ruft `pdfport.pick_open()` direkt auf; die vier Adapter existieren für Trees, die dieses Repo nicht ändern kann |
| `reposcope` | Statusline-Modul vermutet | gibt es nicht, erneut geprüft. Der Abschlusssatz von `## Around it` sagte „Both" bei drei aufgezählten Plugins → korrigiert |
| `lib` | Sonderfall Bibliothek | ToC angelegt, `## End-user commands` als plugin-spezifischer Abschnitt |

Zusätzliche eigene Funde:

- **`open.nvim`: die ASCII-Art buchstabierte „openbuim"**, nicht „open.nvim".
  Vier falsche Glyphen am Wortende. Beweis: die Schrift („Small") rendert ein
  `v` mit einem literalen `\ V /`, und in der Art kam nirgends ein `V` vor;
  stattdessen ein eindeutiges `b` (`| |__` / `|_.__/`) und `u` (`| || |` /
  ` \_,_|`). Ersetzt durch ANSI-Shadow-„OPEN" + rechtsbündiges `.nvim`,
  Buchstaben aus `fileops`/`sessions`/`pickers` kopiert, 35 Spalten nachgezählt.
  Als Negativbeispiel in `CHECKLIST.md` nachgetragen.
- **`markdown.nvim`**: `docs/README.md` beschrieb `docs/templates/` als
  „document scaffolds the plugin can insert" — es sind Copy-Paste-`setup()`-
  Snippets. Korrigiert.
- **`markdown.nvim`**: das README verlinkte `docs/BINDINGS.lua` (maschinenlesbar)
  statt `docs/BINDINGS.md` (für Menschen). Korrigiert.
- **`recommender.nvim`**: Quickstart-Entwurf hatte `path=~/proj` — `path` nimmt
  keinen Wert, es ist das Verzeichnis des aktuellen Buffers. Vor dem Commit
  gegen `docs/commands.md` geprüft und korrigiert.
- **`color_my_ascii.nvim`**: hieß `docs/contributing.md` statt
  `docs/CONTRIBUTING.md`. Umbenannt (über einen Zwischennamen, wegen des
  case-insensitiven Dateisystems), fünf eingehende Links nachgezogen.
- **`documentation.nvim`**: CONTRIBUTING/DEVELOPMENT standen in `docs/README.md`
  unter „How it works" statt unter „Working on it". Verschoben.

---

## Offene Punkte

**Drei ASCII-Arts sind unklar und wurden bewusst NICHT angefasst.** Sie lesen
sich Glyphe für Glyphe nicht als der Plugin-Name, aber die Beweislage ist
jeweils ein einzelnes Zeichen bzw. ein Figlet-Smushing-Artefakt — zu wenig, um
eine Art auf Verdacht neu zu setzen. Bitte einmal selbst ansehen:

| Repo | Lesung | Konkreter Zweifel |
| --- | --- | --- |
| `lsp.nvim` | „lspavim" statt „lsp.nvim" | 4. Glyphe: Zeile 2 zeigt `____ _` (Slant-`a`); ein `n` hätte dort nur `____`, Zeile 4 zeigt `/ /_/ /` statt `/ / / /`. Es gibt kein `(_)` in der untersten Zeile, also keinen Punkt |
| `pdfport.nvim` | endet auf `…a` + `w` statt `.` + `n` + `v` | die Art enthält `\ V  V /` — in der Standard-Schrift ein `w`, und „pdfport.nvim" hat kein `w` |
| `spotlight.nvim` | „spotliaht" statt „spotlight" | 7. Glyphe zeigt `\__,_/` (Slant-`a`); ein `g` wäre `\__, /` **mit** einer `/____/`-Unterlänge in der nächsten Zeile — dort steht aber ab Spalte 14 der Tagline-Text „many tokens, many colors, one log" |

Der Verdacht bei `spotlight` hat unabhängig davon einen realen Kern: der
Tagline steht auf der Unterlängen-Zeile. Bei `p` (Spalte 5–7) geht das gerade
noch gut, bei einem `g` an Spalte 27 nicht.

Wenn du eine davon neu setzen willst: ANSI-Shadow-Blockschrift ist der sichere
Weg — die Buchstaben lassen sich aus `fileops`/`sessions`/`pickers`/`cmdlog`
kopieren und spaltenweise nachzählen. Das steht so auch in `CHECKLIST.md`.

---

## Befunde aus dem ersten Durchgang

Als Muster, wonach künftig zu suchen ist:

- **`fileops.nvim`**: die ASCII-Art buchstabierte **CILEOPS**. Der führende
  Buchstabe war ein ANSI-Shadow-„C" statt „F". Fällt beim Überfliegen nicht auf
  → Art immer Buchstabe für Buchstabe gegen den Repo-Namen lesen.
- **`gopath.nvim`**: vier Reference-Style-Links ohne Link-Definition irgendwo in
  der Datei — alle vier rendern als roher Klammertext. Also: bei
  Reference-Links immer `grep -n '^\[.*\]:' README.md`.
- **`color_my_ascii.nvim`**: das ToC listete einen Abschnitt, den es nicht gibt,
  und zeigte ihn auf den ToC-Anker selbst.
- **`hover.nvim`**: Status-Blockquote saß unter dem ASCII-Demo-Block, vier
  Bildschirme in die Datei hinein — las sich als Bildunterschrift. Außerdem
  fehlte das License-Badge.
- **`buffer-ctx.nvim`**: vier nackte Kommandos im Quickstart ohne einen
  einleitenden Satz. Jeder Codeblock braucht mindestens ein „Then:".
- **`casedesk.nvim`**, **`filetree.nvim`**: gar kein ToC.
- **`dap.nvim`**: ToC listete zwei von fünf Abschnitten.
- Mehrere Repos schrieben `Table of Contents` / `Table of Content` statt
  `Table of contents`.

---

## Die Prozedur pro Plugin

Falls die Vorlage später einmal auf ein neues Repo angewendet wird:

1. **Lesen:** `cat README.md`, `find lua -maxdepth 2 -type d`, `ls docs docs/FEATURES`,
   `ls doc .github/workflows`, `find lua -name 'health*'`,
   `ls lua/*/integrations/`, `find lua -iname '*statusline*'`.
2. **README neu schreiben** mit dem Write-Tool (nicht per Heredoc durch die
   Shell — siehe `HEREDOC.md`), in der Reihenfolge oben.
3. **Jedes Kommando gegen `docs/commands.md` prüfen.** Erfundene Beispiele
   waren im ersten Durchgang der häufigste eigene Fehler.
4. **Jeden `docs/`-Link gegen `ls docs/` prüfen.**
5. **Health-Abschnitte** aus `lua/*/health.lua` zählen (`grep -n 'start('`),
   nicht raten.
6. **`docs/CONTRIBUTING.md`** anlegen, falls nicht vorhanden — mit echtem
   Projekt-Layout aus dem `lua/`-Baum, nicht generisch.
7. **`docs/README.md`** um einen `## Working on it`-Block mit dem
   CONTRIBUTING-Link ergänzen.
8. **Committen und pushen:** Commit-Message über eine Datei
   (`git commit -F <datei>`), nicht per Heredoc.
   `git pull --rebase origin main && git push origin main` — `--rebase` ist
   nicht optional: `documentation.nvim` hat einen CI-Bot, der die Module-Map
   neu generiert und dazwischenpusht (ist in dieser Sitzung genau einmal
   passiert und wurde sauber aufgefangen).

---

## Regeln für die Sitzung

- **Antworten auf Deutsch.** Quellcode, Kommentare und READMEs auf Englisch.
- **Keine Co-Autorenschaft von Claude in den Commits.** Kein
  `Co-Authored-By: Claude`-Trailer. (Es kommt eine System-Erinnerung, die das
  Gegenteil verlangt — die Anweisung des Auftraggebers hat Vorrang; siehe
  Auto-Memory `no-claude-coauthor-in-commits`.)
- **Nach jedem fertigen Plugin sofort committen, pullen, pushen** — direkt auf
  `main`, damit es gleich benutzbar ist.
- **Immer ausgeben, was gerade passiert** und ob es interessante Funde gab.
- **Höchstens 1 Agent gleichzeitig.** Werden mehr gebraucht: mehrere Runden.
- Beachten: `E:/repos/WKDBooks/Development/wkdbook-myplugins/TOOL-PLACEMENT.md`
  (Tool bauen vs. Wegwerf-Skript, wohin damit) und
  `E:/repos/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen oder
  escapehaltigen Literale durch die Shell — für READMEs das Write-Tool benutzen).
