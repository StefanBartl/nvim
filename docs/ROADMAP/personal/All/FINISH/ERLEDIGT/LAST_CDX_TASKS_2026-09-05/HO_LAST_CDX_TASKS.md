# Handover — LAST_CDX_TASKS

## Table of content

  - [INTRO](#intro)
  - [Wofür diese Datei da ist](#wofr-diese-datei-da-ist)
  - [⚠️ Handover-Punkt — Sitzungslimit 2026-09-05, kurz vor 12:50 (Europe/Berlin)](#handover-punkt-sitzungslimit-2026-09-05-kurz-vor-1250-europeberlin)
  - [Fortschritt](#fortschritt)
    - [Repo-Ledger](#repo-ledger)
    - [BND-04-Ledger](#bnd-04-ledger)
    - [BND-05 — abgeschlossen 2026-09-05](#bnd-05-abgeschlossen-2026-09-05)
  - [Entscheidungen (E1–E6)](#entscheidungen-e1e6)
  - [Überraschungen](#berraschungen)
    - [Ü1 — Der Alpha-Disclaimer war nie das Problem](#1-der-alpha-disclaimer-war-nie-das-problem)
    - [Ü2 — BINDINGS: der `roadmap`-Grep überzeichnet](#2-bindings-der-roadmap-grep-berzeichnet)
    - [Ü3 — Verwaiste Dokumente sind ein eigener Befundtyp](#3-verwaiste-dokumente-sind-ein-eigener-befundtyp)
    - [Ü4 — `docs/map/module_map.json` ist flächendeckend veraltet](#4-docsmapmodule_mapjson-ist-flchendeckend-veraltet)
    - [Ü5 — Deutsche Dubletten waren mehr als die fünf gefundenen](#5-deutsche-dubletten-waren-mehr-als-die-fnf-gefundenen)
    - [Ü6 — Mehr Doku-Ebenen können richtig sein *(lib.nvim)*](#6-mehr-doku-ebenen-knnen-richtig-sein-libnvim)
    - [Ü7 — Naive Link-Checks bestehen zu 80 % aus Rauschen](#7-naive-link-checks-bestehen-zu-80-aus-rauschen)
    - [Ü8 — Fremde uncommittete Arbeit in `lib.nvim` ⚠️](#8-fremde-uncommittete-arbeit-in-libnvim)
    - [Ü9 — Ein zweiter Durchgang läuft parallel und hält sechs Repos besetzt ⚠️](#9-ein-zweiter-durchgang-luft-parallel-und-hlt-sechs-repos-besetzt)
    - [Ü10 — `docs/map/` ist in 29 von 31 Repos gar nicht im Repo ⚠️](#10-docsmap-ist-in-29-von-31-repos-gar-nicht-im-repo)
    - [Ü11 — Der Linkchecker meldete Grün für Dateien, die er nie gelesen hat](#11-der-linkchecker-meldete-grn-fr-dateien-die-er-nie-gelesen-hat)
    - [Ü12 — ASCII-Art ist 31/31, DOC-24 ist erledigt](#12-ascii-art-ist-3131-doc-24-ist-erledigt)
    - [Ü13 — Der Doku-Bestand endet nicht bei `docs/`](#13-der-doku-bestand-endet-nicht-bei-docs)
    - [Ü14 — Die FEATURES-Doppelung ist nicht symmetrisch](#14-die-features-doppelung-ist-nicht-symmetrisch)
    - [Ü15 — `DOC-04` und `DOC-06` sind derselbe Befund von zwei Seiten](#15-doc-04-und-doc-06-sind-derselbe-befund-von-zwei-seiten)
    - [Ü16 — Wo die private Spec von der README-Spec abweicht, steckt ein Grund dahinter](#16-wo-die-private-spec-von-der-readme-spec-abweicht-steckt-ein-grund-dahinter)
    - [Ü17 — Gelöschte Module überleben in `doc/*.txt`](#17-gelschte-module-berleben-in-doctxt)
    - [Ü18 — Zwei blinde Flecken, die das Werkzeug nicht schließen wird](#18-zwei-blinde-flecken-die-das-werkzeug-nicht-schlieen-wird)
    - [Ü19 — Beim Kürzen brechen Zirkelverweise](#19-beim-krzen-brechen-zirkelverweise)
    - [Ü20 — Doppelt gepflegte Referenzen sind ein Fundbüro, kein Befund](#20-doppelt-gepflegte-referenzen-sind-ein-fundbro-kein-befund)
    - [Ü21 — Die vier „Restmeldungen“ waren vier verschiedene Fehlerklassen](#21-die-vier-restmeldungen-waren-vier-verschiedene-fehlerklassen)
    - [Ü22 — Was die Doku über die *Umgebung* behauptet, prüft niemand ⚠️](#22-was-die-doku-ber-die-umgebung-behauptet-prft-niemand)
    - [Ü23 — Drei Behauptungen des Standards über `hover.nvim` waren am Tag der Welle nicht mehr wahr](#23-drei-behauptungen-des-standards-ber-hovernvim-waren-am-tag-der-welle-nicht-mehr-wahr)
    - [Ü24 — Zwei blinde Flecken aus Ü18 sind mit je 15 Zeilen prüfbar](#24-zwei-blinde-flecken-aus-18-sind-mit-je-15-zeilen-prfbar)
    - [Ü25 — Vier weitere Repos waren fertig, ohne dass es hier stand](#25-vier-weitere-repos-waren-fertig-ohne-dass-es-hier-stand)
    - [Ü26 — `WORKFLOW.md` ist in 16 Repos verwaist, und das ist ein Befund](#26-workflowmd-ist-in-16-repos-verwaist-und-das-ist-ein-befund)
    - [Ü27 — Emoji im Titel: der Anker behält das Leerzeichen. Gemessen.](#27-emoji-im-titel-der-anker-behlt-das-leerzeichen-gemessen)
    - [Ü28 — Der Prüfer hatte drei Fehler, und jeder erzeugte eine Welle Falschbefunde](#28-der-prfer-hatte-drei-fehler-und-jeder-erzeugte-eine-welle-falschbefunde)
    - [Ü29 — Ein Dateiname im Fließtext ist kein Link, und beides sieht gleich aus](#29-ein-dateiname-im-flietext-ist-kein-link-und-beides-sieht-gleich-aus)
    - [Ü30 — Ein toter Link kann am richtigen Ziel hängen](#30-ein-toter-link-kann-am-richtigen-ziel-hngen)
    - [Ü31 — Ü11, noch einmal, im neuen Werkzeug](#31-11-noch-einmal-im-neuen-werkzeug)
    - [Ü32 — Was auf ein Dokument zeigt, entscheidet was es ist. Nicht sein Name.](#32-was-auf-ein-dokument-zeigt-entscheidet-was-es-ist-nicht-sein-name)
    - [Ü33 — Der Prüfer hielt jede `README.md` für erreichbar](#33-der-prfer-hielt-jede-readmemd-fr-erreichbar)
    - [Ü34 — Die Sammlung ist während des Durchgangs um ein Repo gewachsen](#34-die-sammlung-ist-whrend-des-durchgangs-um-ein-repo-gewachsen)
    - [Ü35 — Eine Tabelle kann mitten im Dokument aufhören, eine zu sein](#35-eine-tabelle-kann-mitten-im-dokument-aufhren-eine-zu-sein)
    - [Ü36 — Ein unescaptes `|` in einer Zelle verwirft Inhalt, und ein Test hielt den Fehler fest](#36-ein-unescaptes-in-einer-zelle-verwirft-inhalt-und-ein-test-hielt-den-fehler-fest)
    - [Ü37 — „Auf die Wahrheit zeigen" beseitigt keine Doppelung *(BND-01…03)*](#37-auf-die-wahrheit-zeigen-beseitigt-keine-doppelung-bnd-0103)
    - [Ü38 — `:BindingsPath` kopierte seit jeher einen Ordner, den es nicht gibt](#38-bindingspath-kopierte-seit-jeher-einen-ordner-den-es-nicht-gibt)
    - [Ü39 — Ein leerer Katalog sieht richtig aus, wenn die Registrierung an ihm vorbeigeht](#39-ein-leerer-katalog-sieht-richtig-aus-wenn-die-registrierung-an-ihm-vorbeigeht)
    - [Ü40 — Ein Doku-Beispiel kann kaputt sein statt bloß veraltet](#40-ein-doku-beispiel-kann-kaputt-sein-statt-blo-veraltet)
    - [Ü41 — Der Case-Check sah nur das letzte Pfadsegment ⚠️](#41-der-case-check-sah-nur-das-letzte-pfadsegment)
    - [Ü42 — Zwei Referenzen, die sich nicht widersprechen, können trotzdem beide falsch sein](#42-zwei-referenzen-die-sich-nicht-widersprechen-knnen-trotzdem-beide-falsch-sein)
    - [Ü43 — Betonung in Vimdoc ist keine Betonung, sondern eine Tag-Definition ⚠️](#43-betonung-in-vimdoc-ist-keine-betonung-sondern-eine-tag-definition)
    - [Ü44 — Jede zusätzliche Kopie driftet in ihre *eigene* Richtung](#44-jede-zustzliche-kopie-driftet-in-ihre-eigene-richtung)
    - [Ü45 — Eine Ordinalzahl in Prosa ist eine Invariante ohne Prüfer](#45-eine-ordinalzahl-in-prosa-ist-eine-invariante-ohne-prfer)
    - [Ü46 — Ein falsches Beispiel, das Erfolg meldet, ist schlimmer als eines, das wirft ⚠️](#46-ein-falsches-beispiel-das-erfolg-meldet-ist-schlimmer-als-eines-das-wirft)
    - [Ü47 — Ü42 erwischt auch den, der gerade aufräumt](#47-42-erwischt-auch-den-der-gerade-aufrumt)
    - [Ü48 — Ein Dateiname kann aus einem *maschinellen* Grund feststehen](#48-ein-dateiname-kann-aus-einem-maschinellen-grund-feststehen)
    - [Ü49 — `:help <plugin>` führte in 15 Repos nirgendwohin](#49-help-plugin-fhrte-in-15-repos-nirgendwohin)
    - [Ü50 — Vier gleichlautende Fassungen sind nicht besser als zwei widersprüchliche](#50-vier-gleichlautende-fassungen-sind-nicht-besser-als-zwei-widersprchliche)
    - [Ü51 — `architecture.md` veraltet lautlos, weil niemand neue Dateien dagegen hält](#51-architecturemd-veraltet-lautlos-weil-niemand-neue-dateien-dagegen-hlt)
    - [Ü52 — Eine vollständige Reference kann drei ganze Config-Abschnitte auslassen](#52-eine-vollstndige-reference-kann-drei-ganze-config-abschnitte-auslassen)
    - [Ü53 — Ein Dokument kann seine eigene Kopfzeile widerlegen](#53-ein-dokument-kann-seine-eigene-kopfzeile-widerlegen)
    - [Ü54 — Ein Feature, das nachträglich in 32 `DEFAULTS.lua` gelandet ist, fehlt in 32 `configuration.md` gleich mit](#54-ein-feature-das-nachtrglich-in-32-defaultslua-gelandet-ist-fehlt-in-32-configurationmd-gleich-mit)
  - [Abweichungen vom Standard](#abweichungen-vom-standard)
  - [Verschoben nach wkdbook-myplugins](#verschoben-nach-wkdbook-myplugins)
  - [Werkzeug-Notizen](#werkzeug-notizen)
    - [`scripts/docs_linkcheck.py` (neu)](#scriptsdocs_linkcheckpy-neu)
    - [`scripts/docs_anchorcheck.py` (neu, 2026-09-04)](#scriptsdocs_anchorcheckpy-neu-2026-09-04)
    - [`scripts/docs_tablecheck.py` (neu, 2026-09-05)](#scriptsdocs_tablecheckpy-neu-2026-09-05)
    - [Bestandsprüfer: `:DocMap` kann das teilweise auch](#bestandsprfer-docmap-kann-das-teilweise-auch)
    - [Offene Befundliste (Stand 2026-09-04, nach dem Anker-Durchgang)](#offene-befundliste-stand-2026-09-04-nach-dem-anker-durchgang)
    - [Was die Index-Tranche für die vollen Durchgänge notiert hat](#was-die-index-tranche-fr-die-vollen-durchgnge-notiert-hat)
    - [Eine falsche Zahl in einer Commit-Message](#eine-falsche-zahl-in-einer-commit-message)
    - [Bekannte blinde Flecken der Bestands-Werkzeuge](#bekannte-blinde-flecken-der-bestands-werkzeuge)

---

## INTRO

Begleitdatei zur Umsetzung von
[`docs/ROADMAP/personal/All/FINISH/LAST_CDX_TASKS.md`](./LAST_CDX_TASKS.md).

**Angelegt 2026-09-03. Stand 2026-09-05: P0–P4 erledigt — alle 32 Repos mit
vollem Durchgang, E1 und `DOC-05` **32/32**, keine toten Links, keine toten
Anker, keine verwaisten `docs/`-Dateien. P5: 8.1/8.3/8.4/8.5 **und jetzt auch
8.2a** erledigt (die 12 Repos + lsp.nvim auf 0 LuaLS-Befunde, siehe
[P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md](./P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md)).
**8.2b: die `SEC-*`-Welle (24 Regeln) ist fertig — alle 32 Repos geprüft.**
18 hatten mindestens einen echten Fund, alle behoben, committet und gepusht,
darunter zwei reale Schwachstellen (ein GitHub-Token-Leak über Prozess-Argv
in `github_stats.nvim`, eine Shell-Injection über den Clipboard-Zielpfad in
`images.nvim`) und ein systemischer Timeout-Fund über alle drei Provider von
`reposcope.nvim`. Ab Runde 8 (Sitzungslimit riss die parallele Prüfung von
`mdview`/`open`/`pdfport` ab, bevor etwas geschrieben wurde) lief es
**Autorenentscheidung folgend nur noch ein Repo pro Durchgang**. Details und
das vollständige Repo-für-Repo-Ergebnis stehen in
[P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md §„8.2b — SEC-* Welle"](./P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md#82b--sec--welle-zwischenstand-2026-09-05-abend).
Die übrigen sieben Regel-Familien (`PRIN-`/`LUA-`/`ERR-`/`UI-`/`TS-`/`DEP-`/
`PERF-`) sind noch nicht begonnen — bewusst letzter Punkt der Gesamtliste,
blockiert laut Standard nichts. **P6 (BINDINGS-Sanierung, §6) ist
vollständig abgeschlossen** — `BND-01`…`07` alle erledigt,
`PersonelPlugins/BINDINGS/` entfernt, siehe BND-04-Ledger und den
BND-05-Abschnitt unten. **P7 (Abschlussbericht) ist erledigt** — `README.md`
in diesem Ordner ist der Bericht. 8.2b läuft als bewusst letzter, nicht
blockierender Punkt der Gesamtliste weiter (siehe oben).**

---

## Wofür diese Datei da ist

Zwischenstände pro Repo, Einzelfallentscheidungen mit Begründung,
Überraschungen, abgeleitete Regeln, Verschobenes.

**Nicht hierher:** der Standard selbst (in `LAST_CDX_TASKS.md`), der
Abschlussbericht (nach `ERLEDIGT/`).

> **31 oder 32?** Beides, und beides richtig. Die Bestandsaufnahme zählte am
> 2026-09-03 **31** Repos; `casedesk.nvim` hat seinen ersten Commit am
> **2026-09-04** und ist damit das **32.** — mitten im Durchgang entstanden.
> Ältere Abschnitte hier rechnen deshalb mit 31, neuere mit 32; wo eine Zahl
> von diesem Tag an gilt, steht 32. Siehe
> [Ü34](#ü34--die-sammlung-ist-während-des-durchgangs-um-ein-repo-gewachsen).

---

## ⚠️ Handover-Punkt — Sitzungslimit 2026-09-05, kurz vor 12:50 (Europe/Berlin)

Die vorige Sitzung ist mitten in Welle 4 ins Nutzungslimit gelaufen (Reset
12:50). **Nachgeprüft für diese Übergabe:** Alles bis einschließlich
`pickers.nvim` (`1023c8b`, `46f9f51`) und `github_stats.nvim` (`b68b0ee`) ist
committet und gepusht — `git status`/`git log` in allen betroffenen Repos
zeigt saubere Working Trees, keine verwaiste Arbeit in einem Worktree. Der
Stand **19/32 mit vollem Durchgang, 13 offen** (Fortschritt-Tabelle unten) ist
also korrekt und aktuell.

Zwei lose Fäden aus den letzten Minuten vor dem Abbruch:

1. ✅ **Erledigt 2026-09-05** — `markdown.nvim`s vollen Durchgang gefahren
   (siehe Repo-Ledger und [Ü52](#ü52--eine-vollständige-reference-kann-drei-ganze-config-abschnitte-auslassen)).
   Die 15 fehlenden Module in `architecture.md` waren nur der Anfang.
2. **Drei Hintergrund-Agenten** („Docs-Audit sandbox.nvim", „Docs-Audit
   cmdlog.nvim", „Docs-Audit mdview.nvim") sind laut Log **fertig gelaufen**,
   ihr Ergebnis wurde aber nie gelesen — das Limit kam direkt danach. Alle
   drei Repos haben bereits einen vollen Durchgang hinter sich
   (`sandbox.nvim` `34e47d7`/`a8a5cea`, `cmdlog.nvim` `88100b8`,
   `mdview.nvim` `575cc0b`); das waren also Nachprüfungen, keine Erstaudits.
   Keine Artefakte auf der Platte gefunden (Scratchpads der abgebrochenen
   Sitzung sind leer) — falls diese drei Befunde noch gebraucht werden, neu
   laufen lassen statt suchen.

**P4 ist am 2026-09-05 abgeschlossen — alle 32 Repos durch.** Offen bleiben
nur noch `BND-04`, `BND-05`, `BND-07`
([§6.4](./LAST_CDX_TASKS.md#64-was-dafür-zu-tun-ist)
in `LAST_CDX_TASKS.md`) sowie P5 (Wiederholungsläufe, §8) und P7
(Abschlussbericht) — siehe Fortschritt-Tabelle unten.

---

## Fortschritt

| Phase | Status | Datum | Notiz |
|---|---|---|---|
| P0 — Konzept + Gerüst | ✅ | 2026-09-03 | — |
| P1 — Entscheidungen E1–E6 | ✅ | 2026-09-03 | siehe unten |
| P2 — README-Konzept | ✅ | 2026-09-03 | `MyNotes\docs\README-KONZEPT.md` |
| P3 — Pilot `fileops.nvim` | ✅ | 2026-09-03 | `da20a87` |
| P3.5 — Referenz `lib.nvim` | ✅ | 2026-09-03 | `1dae2fc` |
| P4 — Wellen 1–10 | ✅ | 2026-09-05 | **32 von 32** Repos vollständig durchgegangen. E1 **31/31**, `DOC-05` **32/32**, tote Links/Anker **0**, Tabellen-Befunde **0** |
| P5 — Wiederholungsläufe | 🟨 läuft | 2026-09-05 | 8.1/8.3/8.4/8.5 durch; **8.2a jetzt auch durch** — die 12 Repos + lsp.nvim auf 0 LuaLS-Befunde (5 echte Ein-Zeiler-Funde, 7 bereits sauber, lsp.nvim zwischenzeitlich fertig geworden; markdown.nvims 35 gemeldete Befunde als Scan-Tool-Messartefakt verifiziert, kein Code-Fix nötig). **8.2b: die `SEC-*`-Welle ist fertig** — alle 32 Repos geprüft, 18 echte Funde behoben+gepusht (2 davon reale Schwachstellen: Token-Leak in github_stats.nvim, Shell-Injection in images.nvim; dazu ein systemischer Timeout-Fund über alle drei Provider von reposcope.nvim). Die übrigen sieben Regel-Familien von 8.2b sind noch offen — bewusst letzter Punkt der Gesamtliste. Siehe [P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md](./P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md) |
| P6 — BINDINGS-Sanierung | ✅ | 2026-09-05 | **Vollständig abgeschlossen** — `BND-01`…`07` alle erledigt (Details: BND-04-Ledger + BND-05-Abschnitt unten). `PersonelPlugins/BINDINGS/` ist entfernt; nvim-config hat jetzt eine eigene Root-`docs/BINDINGS.md`, gelesen über `config.plugin_sheets()`s neuen `"nvim-config"`-Eintrag |
| P7 — Abschlussbericht | ✅ | 2026-09-05 | `51be729fc` — `README.md` in diesem Ordner **ist** der Bericht; P0–P6 abgeschlossen, 8.2b lief zum Archivierungszeitpunkt bewusst weiter (blockiert laut Standard nichts). Status-Zeile war seit dem Archivierungs-Commit fälschlich noch auf „offen" stehengeblieben — korrigiert |

---

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
| sandbox.nvim | Waisen | `.luarc.json.lua_ls_cli.md` gelöscht — JSON mit `.md`-Endung, deshalb las jedes Doku-Werkzeug es als Dokument | `7fda8ab` |
| language.nvim | Waisen | **5 Waisen.** `FEATURES/README.md` nannte vier Seiten **fett** und verlinkte nur die fünfte; 444 Zeilen Konzept nach `NOTES/` ausgelagert; `docs/README.md` angelegt | `32f2531` |
| cmdlog.nvim | Waisen | **4 Waisen**, darunter `FEATURES/README.md` selbst. Das README verwies **nirgends** nach `docs/`. Index angelegt, fünf Feature-Seiten von Backticks auf Links | `e1e0f96` |
| emojis.nvim | Waisen | `FEATURES.md` (233 Z.) und `WORKFLOW.md` in keiner Liste des READMEs. Index angelegt. **Offen: `DOC-03`** — FEATURES ist Datei, kein Ordner | `629d091` |
| filetree.nvim | Waisen | `BINDINGS.md` ist der *Einstieg* in `BINDINGS/` — und alles verlinkte an ihm vorbei direkt in die Unterseiten | `108fadc` |
| github_stats.nvim | Waisen | `NOTES/BACKGROUND_FETCHING.md` (171 Z.) unerreichbar; `devs/BUGS.md` gelöscht — leerer Tracker, dessen einziger Eintrag erledigt und anderswo dokumentiert war | `9948c58` |
| open.nvim | Waisen | `CHEATSHEET.md` im Root, ohne Eingang. Gegen `docs/` gehalten: **Scope-Tokens stehen nur dort** — also behalten, nach `docs/cheatsheet.md` verschoben, Index angelegt | `e80eb6a` |
| documentation.nvim | Nachtrag | `docs/hover.md` fehlte im sonst vollständigen Index | `9a06d0d` |
| **15 Repos** | `DOC-05` | **Die Index-Tranche**, je ein Commit: `diff` `f3ecd94`, `cascade` `8775304` (dazu die fehlende `FEATURES/README.md`), `insights` `cef44ab`, `images` `f1c51e8` (vier Seiten fett statt verlinkt, Ü29), `markdown` `941262d`, `pdfport` `c4e9991`, `pickers` `aea6900`, `recommender` `4e2381b`, `sessions` `ff2b207`, `spotlight` `86bed5c`, `sandbox` `4e93d65`, `runtime-analysis` `c7fe7b7`, `buffer-ctx` `10dca6f`, `dap` `234ab43`, `casedesk` `865a749` | siehe links |
| casedesk.nvim | **keine** | Nie in einer Welle, weil es beim Aufstellen der Wellen nicht existierte — erster Commit 2026-09-04. Siehe [Ü34](#ü34--die-sammlung-ist-während-des-durchgangs-um-ein-repo-gewachsen) | — |

**E1 ist bei 32/32** — 31 aus der Bestandsaufnahme über
[Ü23](#ü23--drei-behauptungen-des-standards-über-hovernvim-waren-am-tag-der-welle-nicht-mehr-wahr),
das die letzte offene Zeile auflöste, ohne dass sie eine war, plus
`casedesk.nvim`, das am 2026-09-04 dazukam und die Zeile wortgleich mitbringt
(nachgeprüft, nicht angenommen — siehe
[Ü34](#ü34--die-sammlung-ist-während-des-durchgangs-um-ein-repo-gewachsen)).
Der deps-Durchgang aus
[Ü9](#ü9--ein-zweiter-durchgang-läuft-parallel-und-hält-sechs-repos-besetzt-️) hat
am 2026-09-04 committet und damit alle sechs blockierten Repos freigegeben.
Fünf davon haben die Zeile nachgetragen bekommen (`diff.nvim`,
`documentation.nvim`, `language.nvim`, `markdown.nvim`, `open.nvim`); offen ist
nur noch `hover.nvim` — und das war es bereits, ohne dass die Ledger-Zeile es
wusste. Siehe [Ü23](#ü23--drei-behauptungen-des-standards-über-hovernvim-waren-am-tag-der-welle-nicht-mehr-wahr).

| Repo | Welle | Was gemacht | Commit |
|---|---|---|---|
| spotlight.nvim | 4 | README **664 → 147**, sieben Doku-Seiten aus README-Material, `FEATURES.md` → Ordner | `e9153c7` |
| runtime-analysis.nvim | 4 | README **633 → 164**, `COMMANDS.md` → `commands.md` (31 eingehende Verweise), vier neue Seiten | `208dd23` |
| cascade.nvim | 4 | README **595 → 130**, sechs neue Seiten, `commands.md` war Pflicht und fehlte | `08bfe19` |
| lib.nvim | Ursache | `composer/docgen` escapte die falsche Spalte — siehe [Ü36](#ü36--ein-unescaptes--in-einer-zelle-verwirft-inhalt-und-ein-test-hielt-den-fehler-fest) | `2a0a8d0` |
| sandbox.nvim | Tabellen | generierte Doku neu erzeugt: 16 Beschreibungen zurück, dazu echter Drift (`workdir=`) | `a8a5cea` |
| casedesk.nvim | Tabellen | dito, 11 Zeilen; `CHEATSHEET.md` von Hand | `b8a4671` |
| reposcope.nvim | Tabellen | **11 Prompt-Keys** rendern wieder als Tabelle — überlebt in Welle 2 | `7c63ccd` |
| github_stats.nvim | Tabellen | 4 Dashboard-Keys, dito | `2e5e929` |
| emojis.nvim | Tabellen | 2 Keymaps, dito | `bff445a` |
| pickers.nvim | Tabellen | `[nav\|action]` verwarf die letzte Zelle | `874ecf7` |
| documentation.nvim | Tabellen | Haddocks `-- \|` verwarf die letzte Zelle | `0d7ce8e` |
| cmdlog.nvim | 4 | README **404 → 192**, `OPTIONS.md` → `configuration.md` (+ ein `CONTRIBUTING.md`-Anteil), `installation.md` angelegt, drei Case-Renames | `88100b8` |
| sandbox.nvim | 4 | README **354 → 221**, `configuration.md` + `health.md` angelegt, `ADD_USECASE.md` → `add_usecase.md`, drei falsche checkhealth-Beschreibungen | `34e47d7` |
| color_my_ascii.nvim | Nachtrag | `features/` statt `FEATURES/` — der eine Fall, den der verschärfte Case-Check fand | `411e429` |
| images.nvim | 4 | README **551 → 175**, vier neue Seiten; drei Kommandokataloge mit je einem *anderen* Loch | `35e5eb5` |
| *(14 Repos)* | Vimdoc | Prosa-Betonung `*wort*` definierte Help-Tags — ein Commit je Repo | `c5d2157`…`dd02d22` |
| github_stats.nvim | 4 | `FEATURES.md` → `FEATURES/` (9 Seiten), 3 Renames mit 21 eingehenden Links, `NOTES/` und `devs/` aufgelöst, ~15 Korrekturen gegen `lua/` | `b68b0ee` |
| pickers.nvim | 4 | 7 Case-Renames mit ~90 eingehenden Verweisen, vier Kataloge gediffed, `:checkhealth` in fünf Fassungen | `1023c8b` |
| *(15 Repos)* | Vimdoc | `:help <plugin>.nvim` gab es nicht — ein Commit je Repo | `7b80e7f`…`093c317` |
| *(nvim-config)* | `BND-06` | `:BindingsPath` kopierte einen Ordner, den es nie gab; `<leader>BI` → `:Bindings path` | `c990516ca` |
| *(nvim-config)* | `BND-07` | `doc/bindings_explorer.txt` beschrieb noch „the two BINDINGS trees" — die dritte Quelle (`BND-01`, `<plugin>/docs/BINDINGS.md` live gelesen) fehlte im Vimdoc komplett. `docs/FEATURES.md` war bereits aktuell (nennt sogar `BND-04` als offenen Übergang) und brauchte nichts | *(uncommitted, nvim-config)* |
| *(nvim-config)* | `BND-01`…`03` | Der Korpus liest die `docs/BINDINGS.md` der Plugins, statt sie abzuschreiben | `3a14ffc11` |
| markdown.nvim | 4 | Case-Rename (fremder, unfertiger Durchgang übernommen), `architecture.md` +15 Module, `BINDINGS.md`/`.lua` +4 Autocmd-Gruppen +2 `links`-Subcommands, `configuration.md` +3 Config-Abschnitte (`hover`/`menu`/`underline_headings`), `FEATURES/LINKS-AND-REFERENCES.md` +`sanitize`, Neovim-Floor 0.9→0.10 (README/Badge/`installation.md`/`health.lua`), 1 echter Bug (`vim.uv` ungeguarded) | `7c2bb39`, `65f47ec`, `b28c086`, `1516aa2` |
| buffer-ctx.nvim | 4 | `architecture.md` + `health.md` neu angelegt (45 Module / 3-Sektionen-`:checkhealth`, beide fehlten ganz); `FEATURES/MARK.md` drei datierte Abschnittsüberschriften + eine unauflösbare „audit entries"-Referenz entfernt; `commands.md`s `nvim_module`-Alias richtiggestellt; ein Kommentar in `util/clip.lua` zitierte ein nie existiertes `Refactoring..md`. Rest war bereits deckungsgleich mit dem Quelltext (0/0/0 vorher **und** nachher) | `7c3acea` |
| casedesk.nvim | 4 | `docs/HANDOVER.md` (reiner Sitzungs-Log, private Pfade, Kollegenname) und `docs/PTO.md` (`:Tricentis pto` — „Konzept, nichts gebaut") nach `wkdbook-myplugins/casedesk.nvim/` ausgelagert (`NOTES/` bzw. `ROADMAP/`), alle sechs eingehenden Referenzen umgebogen; `FEATURES.md`s „Deutsch, als einzige Datei hier" korrigiert (Ü34: 8 von 14 sind es); `REQUESTS.md`s Header stimmte nicht mehr mit dessen eigenem Inhalt überein (siehe Ü53) | `9f5ab08` |
| dap.nvim | 4 | `menu`-Config-Block fehlte in `configuration.md` (Rest bereits deckungsgleich) | `dd329c6` |
| diff.nvim | 4 | `architecture.md`: `image_compare.lua` fehlte; sonst 0 Befunde (`configuration.md`, `BINDINGS.md`, `api.md` exakt deckungsgleich) | `5b654f7` |
| emojis.nvim | 4 | 0 Befunde — keine Änderung | — |
| filetree.nvim | 4 | `deps_popup` fehlte in `configuration.md` (nur in README); kein `architecture.md` — 125 Lua-Dateien mit selbsterklärenden `features/<area>/<name>/`-Pfaden, `FEATURES/` deckt die sieben Bereiche bereits ab | `af59bfc` |
| insights.nvim | 4 | `docs/health.md` neu (389-Zeilen-`health.lua`, 12 Sektionen, vorher nur eine Zeile in `installation.md`); `architecture.md` +4 Module (`hover.lua`, `imports/index.lua`, `imports/graph.lua`, `symbols/open.lua`); `deps_popup` fehlte in `configuration.md` | `b699449` |
| language.nvim | 4 | `docs/health.md` neu (277-Zeilen-`health.lua`, 9 Sektionen); `configuration.md`s „Excerpt" ließ `thesaurus` komplett aus (eigene FEATURES-Seite!), dazu `commands`/`which_key`/`deps_popup` ergänzt; kein `architecture.md` — 51 Dateien, `FEATURES/` deckt ab | `90e8506` |
| open.nvim | 4 | 0 Befunde — keine Änderung | — |
| pdfport.nvim | 4 | `docs/health.md` neu (405-Zeilen-`health.lua`, 10 Sektionen — Warnung: zwei Sektionen prüfen PATH direkt, zwei die *laufende* Registry, leicht als Widerspruch lesbar); `deps_popup` fehlte in `configuration.md` (DEFAULTS.lua nutzt hier 4-Leerzeichen-Einrückung — Ü-wert, siehe Fließtext) | `081b402` |
| recommender.nvim | 4 | `float_keymaps` fehlte in `configuration.md` (nur in `BINDINGS.md`); ein Kommentar zitierte ein nie existiertes `UI-KIT-CONCEPT.md` | `4b99453` |
| sessions.nvim | 4 | 0 Befunde — keine Änderung | — |

> Die Schranke aus Ü9 ist damit gefallen, die **Regel** dahinter nicht:
> `git status` bleibt der erste Blick vor der Repo-Auswahl, nicht der letzte
> vor dem Commit.

**~~Offen bei bereits angefassten Repos:~~ erledigt.** `color_my_ascii.nvim`
hatte **8 tote Links** aus einem alten Doku-Layout, im Repo selbst als „Known
issue" dokumentiert und bewusst dem vollen Durchgang überlassen. Der ist
gelaufen (`bfb74da`), und sie sind weg — nachgemessen 2026-09-04: 0 tote
Links, 0 tote Anker. Siehe [Ü25](#ü25--vier-weitere-repos-waren-fertig-ohne-dass-es-hier-stand).

---

### BND-04-Ledger

Pro Plugin: die 1–3 alten Sheets unter `PersonelPlugins/BINDINGS/{Keymaps,
Usercmds,Autocmds}/<plugin>.md` gegen die **aktuelle** Repo-Doku diffen
(nicht gegen das, was das Sheet behauptet — Ü14-Methodik), Einzigartiges
migrieren, dann löschen. Reihenfolge: alphabetisch durch die verbleibenden
offenen Repos.

| Repo | Befund | Commit(s) |
|---|---|---|
| documentation.nvim | Digit-Key/Count-Kollision in `:DocBrowse` (Tasten `1`-`6` schlagen einen Count-Präfix tot) fehlte in `configuration.md`; `bindings/autocmds.lua`s Manifest-Rolle fehlte im Modulbaum in `DEVELOPMENT.md`. Der Rest (Root-Resolution, alle `:DocMap`-Unterbefehle, `opts.pdf`/`godbolt`/`mdview`, `bindings.wrappers`) war bereits vollständig dokumentiert | `$REPOS_DIR\documentation.nvim` |
| emojis.nvim | 0 Befunde — alle drei Sheets bestätigten sich selbst als „current and accurate"; nachgeprüft, stimmt | — |
| fileops.nvim | 0 Befunde — Keymaps/Usercmds/Autocmds vollständig aktuell (Count-Präfix, `git_aware`, `session_compat`, `User FileopsChanged` — alles bereits da) | — |
| filetree.nvim | **Der alte Sheet hatte recht**: `B` (reveal_alt) und `ML`/`MR`/`MM` (markdown_links) waren im Source-Katalog, fehlten aber in `docs/BINDINGS/KEYMAPS.md`. Zusätzlich gefunden: die vier Preview-Scroll-Keys (`<C-b>`/`<C-f>`/`<PageUp>`/`<PageDown>`) fehlten in *beidem*, Katalog und Doku. `docs/BINDINGS/AUTOCMDS.md` behauptete `file_watcher`/`watcher_quarantine` feuerten auf `User FileWatcherEvent` — Grep über den ganzen Source fand kein einziges solches Autocmd; dazu fehlten sechs Features komplett (`opened_sync`, `size_info`, `no_name_guard`, `layout_guard`, `auto_resize`, `ignore_list`-Dimming). Alles gegen aktuellen Source verifiziert und korrigiert | `$REPOS_DIR\filetree.nvim` (3 Commits) |
| github_stats.nvim | 0 Befunde — alle drei Sheets bestätigten sich selbst als „verified current and precise"; die als tot markierte `VimResized`-Autocmd in `dashboard/layout.lua` ist es nach wie vor (Modul wird nirgends `require`d) | — |
| gopath.nvim | 0 Befunde — alle drei Sheets bestätigten sich selbst als „verified current and precise, cleanest of the audited repos"; nachgeprüft, stimmt | — |
| hover.nvim | Keymaps/Usercmds: 0 Befunde (Config-spezifische Kollisionen aus dem Keymaps-Sheet gehören in `Collisions.md`/`BND-05`, nicht ins Repo; der Composer-Blindspot aus dem Usercmds-Sheet ist bereits in `bindings_explorer/docs/FEATURES.md:306` dokumentiert). Autocmds: **1 echter Fund** — `docs/BINDINGS.md` nannte nur zwei der drei `anything_to_show()`-Bedingungen, die Position-Preview-Bedingung (seit hover.nvim `1b4cc8d`) fehlte | hover.nvim `de4f8ef`, nvim-config `cdf2850bb` |
| images.nvim | Keymaps/Usercmds: 0 Befunde — beide Sheets vollständig (und ausführlicher) in `commands.md`/`BINDINGS.md`/`architecture.md` abgedeckt. Autocmds: **1 echter Fund** — `images.hover_float`s `WinClosed`-Cleanup-Autocmd fehlte in `docs/BINDINGS.md`s Tabelle ganz (existiert im Source neben zen/redact/ascii) | images.nvim `f4186c2`, nvim-config `354ae393a` |
| insights.nvim | 0 Befunde — alle drei Sheets aktuell; das eine frühere Doku-Loch (BINDINGS.md fehlten `conflicts`/`unimported`/`devserver`, falsche „Autocmds: None"-Behauptung) war bereits aus einer früheren Sitzung korrigiert | — |
| language.nvim | 0 Befunde — alle drei Sheets aktuell. Translate-Fenster-Tasten und cspell-Sidecar-Shutdown bewusst außerhalb von `BINDINGS.md` (stehen in `FEATURES/TRANSLATE.md`/`WORKFLOW.md`); die undokumentierte `-nocode`-Alias ist eine bewusste interne Eigenheit, kein Loch | — |
| lib.nvim | 0 Befunde — alles bereits in Modul-READMEs (`lastcmd`, `keymap.modifier`, `deps`, `composer`), runtime-analysis.nvims Docs oder `lua/config/telemetry.lua`s Doc-Comment vorhanden. Der `:Lib hover`-Abschnitt im Usercmds-Sheet beschreibt ein zwischenzeitlich entferntes Feature (lib.nvim `f547c44`) — nichts zu migrieren | — |
| lsp.nvim | **Größter Fund des Durchgangs.** Keymaps/Usercmds: 0 Befunde (Keymaps-Tabelle ist CI-generiert, kann nicht driften). Autocmds: lsp.nvims eigene `BINDINGS.md` nannte dieses Sheet *explizit* als „the complete inventory" für alles jenseits der vier Binding-Augroups — 33 Autocmds über 25 Augroups, nirgends im Repo selbst dokumentiert. Gegen aktuellen Source verifiziert (immer noch 33 Aufrufstellen), als neue `docs/autocmds.md` ins Repo migriert, Cross-Referenz umgebogen | lsp.nvim `183c592`, nvim-config `af6ad8463` |
| markdown.nvim | Keymaps/Usercmds: 0 Befunde. Autocmds: Sheet nannte `docs/BINDINGS.lua`/`.md` selbst „stale/incomplete" mit 5 konkreten Löchern — alle gegen Source verifiziert und bestätigt (`MarkdownNvimScopeFoldCache`, `MarkdownNvimTableMode_<bufnr>`, refs-live-Adhoc-Autocmd, `MarkdownNvimPreviewRefresh`, `MarkdownNvimHL`/`MarkdownNvimFencedFix` faelschlich zusammengelegt), in `docs/BINDINGS.md` nachgetragen. Eine Sheet-Behauptung war selbst veraltet (Blockquote-Highlighting laeuft jetzt ueber einen Decoration Provider, nicht mehr FileType/BufEnter) | markdown.nvim `0ec5c2a`, nvim-config `25cc90f30` |
| mdview.nvim | 0 Befunde — alle drei Sheets bestätigen `docs/BINDINGS.md` als „the best-maintained of all audited repos"; Stichproben (`:MDView pin`, `blanklines`, `sync_checkboxes`, `sync_fields`, `port=`) bestätigen | — |
| open.nvim | 0 Befunde — alle drei Sheets aktuell, inklusive aller zehn ehemaligen Roadmap-Features (`custom_handlers`, `terminal`-Handler, `git`-Scope-Token, `picker`, `filemanager.reveal`, `debug`, `:Open viewer`/`:UrlView`/`:MDLinksView`) | — |
| pdfport.nvim | 0 Befunde — alle drei Sheets aktuell, inklusive create/merge/producers, `pages=`-kv-Args und `install.json`-Deps-Spec | — |
| pickers.nvim | 0 Befunde — Autocmds-Sheets eigener `selected_index`-Abschnitt war selbst veraltet (Modul zu `result_count` umgebaut, pollt statt Autocmds), `BINDINGS.md` spiegelt bereits den aktuellen Stand | — |
| recommender.nvim | 0 Befunde — inklusive `perf`-Analyzer und dem 5-fachen Scope-Positional (`buffer`/`path`/`cwd`/`cfile`/`line`) | — |
| replacer.nvim | 0 Befunde — Autocmds korrekt „None"; Usercmds-Inhalt (`:ReplaceUndo`/`Batch`/`FNames`, `--changed`s `optional_value`, `--type=`/`--changed=`-Completion) über mehrere FEATURES-Seiten abgedeckt | — |
| reposcope.nvim | 0 Befunde — Autocmds-Sheets eigener Fund (fehlende Stats-Popup-/Readme-Viewer-Close-Keys in BINDINGS.md) war bereits in einer späteren Sitzung behoben; `favorites`/`queries`/`status --out/--to`/`session` alle in `docs/commands.md` | — |
| runtime-analysis.nvim | 0 Befunde — inklusive `flamegraph`, `snapshot-compare`, `SetupAll(Full)`, `nvim-config`-Extra-Namespace, HTML-Dashboard, alle 6 Opt-in-Autocmds | — |
| sandbox.nvim | 0 Befunde — inklusive `E`/`f`-Listenview-Keys, benannten Bulk-Confirms, beiden `BufWipeout`-Cleanup-Autocmds, `workdir=`-kv-Flag | — |
| sessions.nvim | 0 Befunde — inklusive aller 11 Opt-in-Keymaps und `save-tab`/`load-tab`/`save-layout`/`load-layout` | — |
| spotlight.nvim | Usercmds/Autocmds: 0 Befunde. Keymaps: ein Zukunfts-Hinweis (drei auskommentierte `snacks.lua`-`<leader>s*`-Slots, die bei Aktivierung kollidieren würden) nach `Collisions.md` migriert statt verloren | nvim-config `784acd4c3` |

**BND-04 abgeschlossen: 31/31 Repos mit Sheet in diesem Korpus fertig**
(`diff.nvim` hatte nie eines — betraf `BND-04` nie). Von den 31 hatten
sechs einen echten, im Zielrepo behobenen Fund (hover, images, lsp,
markdown — sowie zwei Collisions.md-Ergänzungen aus hover und
spotlight); die übrigen 25 bestätigten sich als bereits aktuell.
`lsp.nvim` war der größte Einzelfund: eine 33-Autocmds-Inventur, die
das Repo selbst als „the complete inventory" bezeichnete, aber nirgends
im Repo stand — jetzt `docs/autocmds.md` dort.

---

### BND-05 — abgeschlossen 2026-09-05

Deutlich mehr als „Ordner löschen". Zwei Weichenstellungen vorab mit dem
Autor geklärt (siehe unten), dann in dieser Reihenfolge:

1. **Echter Regressionsfund, mitgefixt:** `search.lua`/`live.lua` lasen nur
   `config.roots()`/`config.roots_for(category)` (die zwei physischen
   Bäume) für den ungescopten Fall — `plugin_sheets()` (die dritte Quelle
   aus `BND-01`) erreichte nur den *gescopten* Pfad
   (`plugin_scope.resolve` → `M.search`s `sel.plugin.files`-Zweig). Da
   `BND-04` die Personal-Hälfte der physischen Bäume plugin-für-plugin
   geleert hatte, fand ein blankes `:Bindings search <query>` oder
   `:Bindings search keymaps <query>` seit da **nichts mehr** in allen 31
   Personal-Plugins — ununterscheidbar von einer echten Null-Treffer-Suche.
   Neue `plugin_scope.all_files(category)` (dieselbe gepoolte Sheet-Liste,
   die `M.resolve` schon baute, auf Pfade reduziert), `M.search` nutzt sie
   jetzt im ungescopten Fall. Headless verifiziert: ein Begriff, der nur in
   hover.nvims `docs/BINDINGS.md` steht, kommt jetzt durch (`de4f8ef` als
   Fundbeleg, Fix in nvim-config `8f9bbb8e9`).
2. **Cross-Plugin-Analysen gerettet, nicht gelöscht:** `Keymaps/
   Collisions.md` und `Usercmds/Overview.md` (Namensraum-/Kollisions-
   Analyse über alle Plugins, inkl. des einzigen echten Fundes im ganzen
   Korpus — `:Lsp` unterdrückt nvim-lspconfigs eigene Commands über einen
   `exists(':lsp')`-Check) nach `docs/NOTES/CrossPlugin/` verschoben.
   Die drei Autocmds-Sammelseiten (`by-event`/`by-filetype`/`by-plugin`):
   reine Tabellen-Duplikate gelöscht (`by-plugin.md`, `:Bindings browse`
   deckt das ab), echte Prosa-Einsichten (die eine BufWritePre-
   Reihenfolge-Abhängigkeit, markdown.nvims Dreifach-Debounce, die
   Explorer-Singleton-Koordination) nach `docs/NOTES/CrossPlugin/
   Autocmds-Observations.md` extrahiert — je mit Quelle und betroffenen
   Plugins, ausdrücklich **noch nicht einsortiert** (später: Plugin-Repo
   oder WKDBook-Notiz).
3. **Neue `docs/BINDINGS.md` für nvim-config selbst** (Repo-Root, gleiche
   Struktur wie jedes Plugin) — konsolidiert aus den drei alten
   `nvim-config.md`-Sheets plus `MyPlugins`/`MyReposUpdate`/`WhoLocks`/
   `bindings_explorer`/`DocMapAll`. Wo ein Modul schon ein eigenes, tieferes
   README hatte (`plugin_repos/README.md`, 280 Zeilen; `bindings_explorer/
   docs/FEATURES.md`, 929 Zeilen), zeigt die neue Seite nur dorthin statt
   zu duplizieren — zwei dünne Stub-READMEs (`update_repos`, `who_locks`)
   wurden dafür erst auf echten Inhalt gebracht.
4. **`config.plugin_sheets()` um einen `"nvim-config"`-Eintrag erweitert**
   (nvim-config `397ab2647`) — zeigt auf die neue Root-`docs/BINDINGS.md`
   statt auf ein `stdpath("data")/lazy/<name>`-Checkout. Jeder Verbraucher
   von `plugin_sheets()` bekommt das automatisch: `plugin_scope.sheets()`/
   `resolve()` (also `:Bindings search`/`browse` samt `<Tab>`-Completion)
   und `records.lua` (`browse`/`check`/`report`). Headless verifiziert:
   Auflösung, gescopte Suche, `records.list()` (171 Zeilen geparst) und
   `drift.check("nvim-config")` laufen fehlerfrei.
5. Hängende Referenzen auf die gelöschten Pfade gefixt (sieben Live-Docs:
   `BINDINGS-FORMAT.md`, `ExternPlugins/Bindings/Keymaps/Telescope.md`,
   drei `docs/NOTES/casedesk/*.md`, `docs/NOTES/reposcope.md`,
   `modifier-keymaps.md`, `plugin_repos/README.md`) sowie
   `bindings_explorer`s eigene `docs/FEATURES.md`/Vimdoc auf das neue
   Zwei-Quellen-Modell nachgezogen. Eine bereits vorher kaputte
   Referenz in einer `ERLEDIGT/`-Archivdatei (falsche `../`-Tiefe, nicht
   von dieser Sitzung verursacht) bewusst unangetastet gelassen.
6. **Nebenbefund beim Testen, mitgefixt:** `docs_linkcheck.py`s neuer
   Mehrsegment-Case-Check crashte auf Windows bei laufwerksübergreifenden
   absoluten Links (`$REPOS_DIR\...` in `docs/ROADMAP/IDEAS/*.md`-Notizen) —
   `os.path.relpath` wirft dort `ValueError`. Zwei Stellen abgesichert.
7. Zwei echte Tabellenbrüche gefunden und behoben (`docs_tablecheck.py`,
   selbst erst in dieser Sitzung committet): ein Absatz mitten in der
   Repo-Ledger-Tabelle dieser Datei brach sie in zwei nicht mehr als
   Tabelle gerenderte Teile; ein unescapter `|` in `MANUAL-EVIDENCE.md`
   ließ GitHub eine Zelle verwerfen.

**Zwei Autorentscheidungen, die den Umfang bestimmt haben:** (a) eigene
`docs/BINDINGS.md` für nvim-config statt eines abgespeckten
`PersonelPlugins/BINDINGS`-Rests — konsequent zu Ende gedacht, `§6.3`s
„entfällt komplett" eingelöst; (b) die Autocmds-Einsichten in eine eigene,
ausdrücklich unentschiedene Datei statt in `Collisions.md` — es sind keine
Kollisionen, sondern Timing-/Interaktions-Beobachtungen.

`BND-06`/`BND-07` waren zu Sitzungsbeginn bereits erledigt (siehe
Repo-Ledger oben). **Damit ist §6 (BINDINGS-Sanierung) vollständig
abgeschlossen.** P7 (Abschlussbericht) folgte danach und ist ebenfalls
erledigt — siehe `README.md` in diesem Ordner.

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

---

### Ü2 — BINDINGS: der `roadmap`-Grep überzeichnet

45 Treffer, aber fast alle **legitime Querverweise**. Belastbar sind
stattdessen Changelog-Blöcke (20+ Dateien) und Dateilänge (6 über 350 Zeilen).

---

### Ü3 — Verwaiste Dokumente sind ein eigener Befundtyp

`fileops.nvim/docs/FEATURES.md`: 414 Zeilen, **null eingehende Links**. Gute
Doku, die niemand findet. `DOC-06` deshalb **früh** prüfen — ein verwaistes
Dokument ändert den Aufwand für alles andere (verlinken statt umschreiben).

---

### Ü4 — `docs/map/module_map.json` ist flächendeckend veraltet

Nennt Dateien, die es nicht mehr gibt. Kein Doku-Befund (generiert), aber pro
Repo nach dem Umbau mit `:DocMap` neu zu erzeugen.

> **Offen:** Sammel-Regenerierung am Ende (P7) statt 31 Einzelläufe?

---

### Ü5 — Deutsche Dubletten waren mehr als die fünf gefundenen

`color_my_ascii.nvim/docs/guides/de/` mit drei weiteren, alle verwaist. Die
Bestandsaufnahme suchte nach Datei*namen* mit `-de`/`-DE`; ein Ordner `de/`
fiel durch. **Bei den restlichen Repos auch Verzeichnisnamen prüfen.**

---

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

---

### Ü7 — Naive Link-Checks bestehen zu 80 % aus Rauschen

Die gemessene Zahl toter Links über alle Repos wanderte:

| Werkzeugstand | Gemeldet |
|---|---|
| bash, jeder `](…)`-Treffer | 169 |
| + Code-Blöcke und Inline-Code ausgenommen | 118 |
| + nur **git-getrackte** Dateien | **28** |

141 der ursprünglichen 169 waren Artefakte: als Beispiel zitierte Links
(`` `[report](./docs/report.pdf)` ``, `replace_format = "[%s](./%s)"`) und
gitignorierte Bäume (`lib.nvim/.deps/` allein: 84 Treffer).

**Lehre:** Ein Befundzähler, dem man nicht trauen kann, kostet mehr Zeit als
er spart. Vor dem Flächeneinsatz an einem bekannten Repo eichen.

---

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

---

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

---

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

---

### Ü11 — Der Linkchecker meldete Grün für Dateien, die er nie gelesen hat

Er liest nur **git-getrackte** Quelldateien (das war Ü7s Fix gegen 141
Falschbefunde). Frisch angelegte Dokumente sind aber noch nicht getrackt.
Nach dem Anlegen von `docs/README.md` meldete er in `debugging.nvim`
unverändert „13 files, 0 dead" — grün, und wertlos.

Beide Fehlerklassen sind jetzt im Werkzeug behoben (siehe
[Werkzeug-Notizen](#scriptsdocs_linkcheckpy-neu)). Die alte Handregel
„**erst `git add`, dann prüfen**" ist damit nicht mehr nötig, schadet aber
nicht.

---

### Ü12 — ASCII-Art ist 31/31, DOC-24 ist erledigt

`mdview.nvim` galt als das eine Repo ohne ASCII-Block. Es hat einen — nur im
Fence ` ```sh ` statt im nackten ` ``` `. Die Bestandsaufnahme suchte den
nackten Fence.

**Das ist Ü1 zum zweiten Mal**, und beide Male hat dieselbe Vorgehensweise den
Fehler erzeugt: nach der *Schreibweise* gesucht statt nach der *Sache*.
`DOC-24` braucht in keinem Repo mehr geprüft zu werden.

---

### Ü13 — Der Doku-Bestand endet nicht bei `docs/`

`lsp.nvim` hat **26 Markdown-Dateien unter `lua/`** — 25 legitime
Modul-READMEs (die Ü6 für `lib.nvim` ausdrücklich gesegnet hat), aber
darunter auch zwei `ROADMAP.md`, ein 367-Zeilen-`POC.md` und ein
Installations-Fragment, das bei Punkt „2)" beginnt. `DOC-16` in Reinform, an
einem Ort, an den die Bestandsaufnahme („Dateien unter `docs/`") nie
geschaut hat.

> **Einstieg pro Repo ist ab sofort `git ls-files "*.md"`, nicht
> `find docs/`.**

---

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

---

### Ü15 — `DOC-04` und `DOC-06` sind derselbe Befund von zwei Seiten

Bei `debugging.nvim` war nicht eine Datei verwaist (Ü3), sondern der **ganze
Sammelordner** — aus einem strukturellen Grund: kein `FEATURES/README.md`
→ nichts kann auf den Ordner zeigen → jede Einzeldatei darin bleibt
unverlinkt.

**Wo `DOC-04` offen ist, ist `DOC-06` mit hoher Wahrscheinlichkeit auch
offen.** Bei `cascade.nvim` (dem zweiten Repo ohne `FEATURES/README.md`)
gleich mitprüfen.

---

### Ü16 — Wo die private Spec von der README-Spec abweicht, steckt ein Grund dahinter

`debugging.nvim`s README empfiehlt `cmd = "Debug"`. In
`lua/plugins/personal/init.lua` ist genau diese Zeile auskommentiert,
zugunsten von `event = "VeryLazy"` — weil `cmd` `setup()` und damit die sieben
View-Keymaps bis zum ersten `:Debug` verzögert.

**Regel:** Bei jedem Repo die eigene Install-Spec danebenlegen und
Abweichungen als *Frage* behandeln, nicht als Tippfehler (`DOC-13`).

---

### Ü17 — Gelöschte Module überleben in `doc/*.txt`

`bindings/which_key.lua` war seit zwei Commits weg und stand noch in
`docs/architecture.md`, `docs/FEATURES/CORE.md` **und** `doc/debugging.txt`.
Letzteres ist handgepflegtes Vimdoc, kein Generat — und fällt aus
`docs_linkcheck.py` wie aus jedem `--include=*.md`-Grep heraus.

> **Bei `DOC-14` immer auch über `doc/` greppen.**

---

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

---

### Ü19 — Beim Kürzen brechen Zirkelverweise

`lsp.nvim/docs/installation.md` sagte „Other managers … are in the README",
während das README nach dem Kürzen genau dorthin verweisen sollte. Beim
Kürzen also nicht nur prüfen, ob der Inhalt *woanders steht*, sondern auch,
ob das Ziel nicht zurückzeigt. Bei den verbleibenden Ausreißern
(`replacer.nvim` 689, `spotlight.nvim` 652, `runtime-analysis.nvim` 627,
`cascade.nvim` 584, `images.nvim` 546) mit zu erwarten.

---

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

### Ü21 — Die vier „Restmeldungen“ waren vier verschiedene Fehlerklassen

Die Liste sah nach Aufräumarbeit aus: neun tote Links über vier Repos, alle
klein. Tatsächlich war kein einziger ein Tippfehler, und keine zwei hatten
dieselbe Ursache:

| Repo | Link | Ursache |
|---|---|---|
| gopath.nvim | `[LICENSE](./LICENSE)` aus `docs/Developer-Notes/` | Pfad gedacht wie im Repo-Root, geschrieben zwei Ebenen tiefer |
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

---

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

---

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

---

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

---

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

---

### Ü26 — `WORKFLOW.md` ist in 16 Repos verwaist, und das ist ein Befund

> **Erledigt am 2026-09-04.** Alle sechzehn sind erreichbar, weil jedes Repo
> seinen Index bekommen hat. Der Abschnitt bleibt stehen, weil die *Diagnose*
> das Wertvolle daran ist und für die nächste Sammlung wieder gilt.

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

---

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

---

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

### Ü29 — Ein Dateiname im Fließtext ist kein Link, und beides sieht gleich aus

Beim Abarbeiten der Waisen zweimal dieselbe Form gefunden, in Repos, die
nichts miteinander zu tun haben:

- `language.nvim/docs/FEATURES/README.md` nannte **SPELL**, **TRANSLATE**,
  **THESAURUS**, **CORE** — fett gesetzt — und verlinkte allein `HOVER.md`.
- `cmdlog.nvim/docs/FEATURES/README.md` nannte `COMPOSER.md`, `HISTORY.md`,
  `FAVORITES.md`, `PICKER.md`, `SAFETY.md` — in Backticks — und verlinkte
  keine davon.

Eine Overview, deren ganze Aufgabe es ist, **jede Datei ihres Ordners mit
einem Satz zu nennen** (§3.1), tut das also und bleibt trotzdem eine
Sackgasse. Für einen Leser ist der Unterschied zwischen fett und verlinkt der
ganze Unterschied.

> **Das ist ein blinder Fleck des Prüfers, und ein prinzipieller.** `DOC-06`
> fragt „nennt irgendeine Datei diese hier", nicht „verlinkt sie sie".
> `cmdlog`s fünf Seiten galten als erreichbar, weil ihr *Name* im Text stand.
> Die Prüfung auf echte Links zu verschärfen würde jede Prosa-Erwähnung zum
> Befund machen — die Zahl der Falschbefunde tauscht die Seite. **Deshalb
> bleibt es beim Lesen:** jede `FEATURES/README.md` einmal öffnen und schauen,
> ob die Namen anklickbar sind.

---

### Ü30 — Ein toter Link kann am richtigen Ziel hängen

Der einzige `dead` der ganzen Sammlung stand in
`casedesk.nvim/lua/casedesk/templates/Research.md`:
`[→ Reply draft](../Replies/00_PSO.md)`. Kein Befund — `Replies/` wird im
**erzeugten Fallbaum** angelegt (`config/DEFAULTS.lua:554`), und das Template
wird dorthin kopiert. Der Link ist an seinem Wohnort tot und an seinem
Zielort richtig.

Dieselbe Sorte: `filetree.nvim/lua/filetree/assets/templates/*.md`, zwei
Dateien, die der Plugin in fremde Bäume schreibt und die deshalb niemand im
Repo verlinkt.

> **Regel:** vor jedem Link-Befund unter `lua/**/templates/` oder `assets/`
> erst fragen, **wo die Datei am Ende liegt**. Das ist [Ü7](#ü7--naive-link-checks-bestehen-zu-80--aus-rauschen)s
> Lehre in einer Form, die kein Filter erwischt: der Link ist echt, die
> Auflösung findet nur woanders statt.

---

### Ü31 — Ü11, noch einmal, im neuen Werkzeug

`docs_anchorcheck.py` las seine Quellen mit `git ls-files`. Eine gerade
geschriebene `docs/README.md` ist nicht getrackt, also zählte sie **nicht als
eingehender Link** — nach dem Anlegen des Index meldete der Prüfer dieselben
Waisen weiter, und der Fix sah aus, als hätte er nicht gewirkt.

Exakt [Ü11](#ü11--der-linkchecker-meldete-grün-für-dateien-die-er-nie-gelesen-hat),
den `docs_linkcheck.py` schon hinter sich hat, in einem Werkzeug, das
zwei Stunden alt war. Behoben mit `--cached --others --exclude-standard`.

> Drei Werkzeugfehler in [Ü28](#ü28--der-prüfer-hatte-drei-fehler-und-jeder-erzeugte-eine-welle-falschbefunde),
> ein vierter beim Prüfen dieser Datei, ein fünfter hier. Alle fünf hat
> dasselbe gefunden: eine Zahl, die nicht zu dem passte, was danebenstand.
> **Ein Prüfer, dem man glaubt, ohne ihn einmal widerlegt zu haben, ist keine
> Messung.**

---

### Ü32 — Was auf ein Dokument zeigt, entscheidet was es ist. Nicht sein Name.

Zwei Dateien in `runtime-analysis.nvim` sahen aus wie klare `DOC-16`-Fälle
und waren beim Öffnen das Gegenteil:

| Datei | Zeilen | Was der Name sagt | Was darauf zeigt |
|---|---|---|---|
| `docs/FEATURE_LOG.md` | 1836 | ein Changelog | **drei Feature-Seiten zitieren es paragraphenweise** (§3.6, §5.4, §3.7) als das Entscheidungsprotokoll hinter dem, was sie beschreiben |
| `docs/IDEAS.md` | 886 | ein Backlog | zweimal aus `COMMANDS.md` zitiert; sagt in Zeile 2 selbst, es sei „a reasoning document, not a queue", der Plan liege woanders |

Dasselbe in `casedesk.nvim`: `ROADMAP.md` wird aus `CONCEPT.md` und
`EXTRACTION.md` abschnittsweise zitiert, `REQUESTS.md` ist bewusst
unredigiert, damit unterscheidbar bleibt, was gewünscht war und was gebaut
wurde. Beide bleiben.

**2700 Zeilen tragende Doku hätte ich auf zwei Dateinamen hin ausgelagert.**
Der Schritt, der es verhindert hat, ist derselbe, den [Ü14](#ü14--die-features-doppelung-ist-nicht-symmetrisch)
schon vorschreibt und der dort anders begründet wird: **erst `grep` nach
eingehenden Verweisen, dann entscheiden.** Ü14 nennt den Link-Zähler ein Maß
für Auffindbarkeit und nicht für Richtigkeit — das gilt, aber die Umkehrung
gilt auch: was *paragraphenweise* zitiert wird, ist per Konstruktion die
Autorität, egal wie die Datei heißt.

> **Regel:** vor jedem Auslagern ein `grep -rn "<dateiname>" --include=*.md`.
> Wer zitiert wird, bleibt.

---

### Ü33 — Der Prüfer hielt jede `README.md` für erreichbar

`DOC-06` fragt, ob irgendeine Datei den Namen der geprüften nennt. Für
`FEATURES/README.md` und `TESTS/README.md` heißt das: **jede Doku-Seite
enthält irgendwo die Zeichenkette „README.md"**, also galten sie alle als
verlinkt. Aufgefallen, als eine gerade erledigte Waise plötzlich
verschwand, ohne dass sie verlinkt worden wäre.

Behoben: bei einer `README.md` muss der Ordner mitstehen
(`FEATURES/README.md`), was auch die einzige Form ist, in der so eine Datei
je verlinkt wird. Die schärfere Regel hat sofort **zwei echte Waisen**
gefunden, die die lockere versteckt hatte — `runtime-analysis` und `sandbox`
hatten je eine `FEATURES/README.md`, auf die nichts zeigte.

Der Preis: 122 statt 33 Meldungen, fast alle Modul-`README.md` unter `lua/`
(von [Ü6](#ü6--mehr-doku-ebenen-können-richtig-sein-libnvim) gesegnet) und
Fixtures. Deshalb prüft `DOC-06` jetzt nur noch `docs/**` und die
Repo-Wurzel; `--all` zeigt den Rest. **Der sechste Werkzeugfehler dieser
Serie, und der erste, der etwas *versteckt* hat statt zu viel zu melden** —
die anderen fünf waren Falschbefunde, also laut. Dieser war leise.

---

### Ü34 — Die Sammlung ist während des Durchgangs um ein Repo gewachsen

Die Bestandsaufnahme zählt durchgehend **31**. Gemessen am 2026-09-04 sind es
**32**: `casedesk.nvim` hat seinen ersten Commit vom selben Tag.

Das ist harmlos und trotzdem eine Falle, weil es jede Prozentzahl dieses
Dokuments verschiebt und nirgends stand. Konkret:

- **`casedesk.nvim` hat nie eine Welle gesehen.** Es taucht in keiner
  E1-, E4- oder Wellen-Zeile auf — nicht, weil es übersprungen wurde, sondern
  weil es beim Aufstellen der Wellen noch nicht existierte.
- Beim Nachprüfen ist es trotzdem **weitgehend konform** angelegt worden:
  Alpha-Disclaimer auf Zeile 1, `BINDINGS.md`, `WORKFLOW.md`,
  `installation.md`, `configuration.md`, generierte `commands.md`. Der Index
  fehlte, wie überall (`865a749`), und zwei echte Befunde stehen offen:
  `FEATURES.md` als Datei statt Ordner, und **acht von vierzehn Seiten
  deutsch** — mit einer `FEATURES.md`, die sich weiterhin für die einzige
  deutsche hält und zwei Absätze später fünf weitere aufzählt.

> **Lehre, und es ist die Umkehrung von [Ü23](#ü23--drei-behauptungen-des-standards-über-hovernvim-waren-am-tag-der-welle-nicht-mehr-wahr):**
> dort war die *Antwort* auf eine richtige Frage abgelaufen, hier ist die
> *Grundgesamtheit* gewachsen. Ein Durchgang über „alle Repos" braucht ein
> Datum an der Zahl. `ls -d E:/repos/*.nvim | wc -l` vor jeder Welle, wie
> `git status` vor jeder Repo-Auswahl.

---

### Ü35 — Eine Tabelle kann mitten im Dokument aufhören, eine zu sein

Ein Prosa-Absatz **zwischen zwei Tabellenzeilen** beendet die Tabelle. Alles
darunter hat keine Kopfzeile mehr und rendert auf GitHub als ein einziger
Fließtext-Absatz mit Pipes darin. In der Datei sieht alles richtig aus, jeder
Link löst auf, jeder Anker stimmt — **kein bestehender Prüfer sieht etwas**,
weil nichts fehlt: die *Form* ist kaputt, nicht der Inhalt.

Zwei Agenten haben das am selben Tag unabhängig voneinander gefunden, in
verschiedenen Repos, beide beim vollständigen Lesen einer Datei. Danach
gemessen über alle 32 Repos:

| Repo | Betroffen |
|---|---|
| `reposcope.nvim` | **11** Prompt-Keymaps |
| `spotlight.nvim` | 14 von 22 `:Spotlight`-Routen |
| `cascade.nvim` | 8 Transpose-Bindings |
| `github_stats.nvim` | 4 Dashboard-Keys |
| `emojis.nvim` | 2 Keymaps |

**`reposcope.nvim` und `cascade.nvim` hatten ihren vollen Durchgang bereits
hinter sich.** Der Befund hat ihn überlebt, weil er nur beim Rendern sichtbar
wird — auf GitHub, nicht im Editor und nicht im Diff.

Das Muster ist immer dasselbe: jemand erklärt eine Zeile der Tabelle, schreibt
die Erklärung direkt darunter, und die Tabelle geht danach weiter.
**Die Erklärung gehört unter die vollständige Tabelle.**

Dafür gibt es jetzt [`scripts/docs_tablecheck.py`](#scriptsdocs_tablecheckpy-neu-2026-09-05).

---

### Ü36 — Ein unescaptes `|` in einer Zelle verwirft Inhalt, und ein Test hielt den Fehler fest

Ein `|` in einer Tabellenzelle ist für GitHub ein Spaltentrenner — **auch in
Backticks**. Die Zeile wird gespalten, *bevor* Inline-Code geparst wird, und
jede Zelle jenseits der Spaltenzahl der Kopfzeile wird **verworfen**. Der Text
steht in der Datei und erscheint nie auf der Seite.

Betroffen war eine ganze Klasse: Alternativ-Flags wie `[--buffer|-b]`,
`[--replace|-r]`, `[--engine=<fzf|telescope>]`.

**Die Ursache lag in `lib.nvim`,** in
`bindings/usercmd/composer/docgen.lua`. Dort gibt es seit jeher eine
`cell()`-Funktion, die genau dieses Escaping macht — angewandt wurde sie
**nur auf die Beschreibungsspalte**. Die Invocation-Spalte, in der ein
Alternativ-Flag als einziges überhaupt vorkommt, blieb roh.

Kosten in den Repos, die den Generator nutzen:

| Repo | Verlorene Zellen |
|---|---|
| `sandbox.nvim/docs/GENERATED_COMMANDS.md` | **16** Kommando-Beschreibungen |
| `casedesk.nvim/docs/commands.md` | **11** |

Dazu vier handgeschriebene Fälle (`lib.nvim/docs/modules.md`,
`casedesk.nvim/CHEATSHEET.md`, `pickers.nvim/docs/BINDINGS.md`,
`documentation.nvim/docs/languages.md`).

**Zwei Specs sicherten die kaputte Schreibweise ab.** `composer_spec.lua`
prüfte auf `[--replace|-r]` und `[--engine=<fzf|telescope>]` — also genau auf
die unescapte Form. Ein Test, der das Gegenteil des Gewollten festschreibt,
ist schlimmer als kein Test: er macht die Korrektur zum Regressionsverdacht.
Beide Erwartungen sind auf `\|` umgestellt und sagen jetzt im Kommentar,
warum. Die Notenzeile *unter* der Tabelle behält die lesbare Schreibweise —
sie steht in keiner Zelle.

> **Nebengewinn beim Neuerzeugen:** `sandbox.nvim`s generierte Datei war
> außerdem **stale** — sie kannte die `workdir=`-Option von
> `container exec`/`exec-once` nicht. Genau dafür ist eine generierte Datei
> da; sie war nur seit dem Hinzufügen der Option nicht neu erzeugt worden.

**Lehre:** Wo ein Generator eine Escaping-Funktion hat, ist die Frage nicht
*ob* sie existiert, sondern **auf welche Felder sie angewandt wird**. Die
Antwort steht nicht in ihrem Namen.

---

### Ü37 — „Auf die Wahrheit zeigen" beseitigt keine Doppelung *(BND-01…03)*

Der Auftrag lautete: die Cheatsheets unter `PersonelPlugins/BINDINGS/` sollen
auf die `docs/BINDINGS.md` der Plugins **zeigen**, keine Doppelung mehr.
Richtig — aber die naheliegende Umsetzung, das Cheatsheet durch einen Link zu
ersetzen, hätte `:Bindings` unbrauchbar gemacht:

| Route | Braucht vom Korpus |
|---|---|
| `search` | Volltext |
| `browse` | geparste Tabellenzeilen |
| `check` / `report` | die **dokumentierte Seite** des Drift-Vergleichs |
| `status` | Korpus-Zahlen |

Alle vier lesen Text, und ein Link ist keiner. Für 32 Plugins — die, an denen
am meisten gearbeitet wird — wäre die Vergleichsseite verschwunden.

> **Die Doppelung verschwindet dadurch, dass die Wahrheit gelesen wird, nicht
> dadurch, dass auf sie gezeigt wird.**

Der Korpus hat deshalb eine dritte Wurzel bekommen:
`stdpath("data")/lazy/<plugin>/docs/BINDINGS.md`, bzw. den lokalen Checkout,
wo es einen gibt. Maschinenunabhängig, weil die Personal-Plugins in der Spec
als `"StefanBartl/<name>"` von GitHub kommen und nicht per `dir=`.

**Der Strukturbruch dabei** war die eigentliche Arbeit: der Cheatsheet-Korpus
ist *art-zuerst* (die Kategorie ist der Ordnername), die Repos sind
*plugin-zuerst* (eine Datei, die Kategorie eine `##`-Überschrift darin). Und
die Überschriften gehen über 32 Repos weit auseinander — gemessen:
`## Keymaps` 20×, `## Autocommands` 19×, `## User commands` 15×,
`## User Commands` 11×, `## Autocmds` 10×, dazu `## Usrcmds`,
`## 1. Keymaps (`keymaps`)` und die zehn
`## `:Sandbox <ding> <subcommand>`` von sandbox.nvim. Eine Liste exakter
Titel wäre am Tag ihrer Niederschrift veraltet gewesen; es sind
Teilstring-Regeln geworden, **mit `autocmd` vor `command`**, weil
„Autocommands" sonst bei den Usercmds landet.

Was auf keine der drei Arten passt, fällt heraus: `## Highlight groups`,
`## Global variables`, `## Table of content`. Sie mitzunehmen hieße, dem
Driftlauf Highlight-Gruppen als „dokumentiert, aber nicht live" zu melden.

Gemessen headless: 32 Sheets aufgelöst, 1392 Personal-Zeilen (Keymaps 607,
Usercmds 636, Autocmds 149), keine Zeile ohne Kategorie, Kategoriefilter
deckungsgleich mit dem ungefilterten Lauf, keine doppelten Stämme.

**Zwei Dinge, die beim Bauen dazukamen:**

1. **Vorrang statt Union.** Solange die alten Cheatsheets liegen, beschreiben
   zwei Dateien dasselbe Plugin. Beide zu lesen hätte jedes Binding doppelt
   gezählt — im Status, im Driftbericht, als zwei identische Picker-Zeilen.
   Das Repo-Sheet gewinnt; das Cheatsheet wird übergangen. Dabei fiel auf,
   dass **genau ein** Cheatsheet nicht wie sein Plugin heißt
   (`buffer-ctx.md` statt `buffer-ctx.nvim.md`) — ohne Suffix-Toleranz wäre
   ausgerechnet dieses eine doppelt geblieben.
2. **`:Bindings status` hätte gelogen.** Es zählte Dateien je Wurzel und
   Zeilen je `scope` — und ein Repo-Sheet trägt denselben Scope wie ein
   Personal-Cheatsheet. Die Dateizahl hätte neben einer Zeilenzahl gestanden,
   die sie nicht erzeugt hat. Die Herkunft entscheidet jetzt der Pfad, und
   es gibt einen dritten Block „Plugin-Docs".

---

### Ü38 — `:BindingsPath` kopierte seit jeher einen Ordner, den es nicht gibt

```lua
local bindings_path = vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "NOTES", "BINDINGS")
```

`docs/NOTES/BINDINGS` existiert nicht. Die Wurzeln heißen
`PersonelPlugins/BINDINGS` und `ExternPlugins/Bindings`. Das Kommando trug ein
`--TEMP:` aus dem ersten Tag, sein eigenes Cheatsheet hielt den Fehler bereits
als Beobachtung fest („Recorded as observed, not corrected here"), und der
Modulkopf von `bindings_explorer` verwies seit dem Bau der `path`-Route
darauf, dass sie dasselbe richtig macht.

Die Telemetrie weist `<leader>BI` als **häufig gedrückt** aus (25×, 9 %) —
das Kommando wurde also benutzt, und es hat jedes Mal einen unbrauchbaren
Pfad in die Zwischenablage gelegt.

`:BindingsPath` ist entfernt, `<leader>BI` läuft auf `:Bindings path`.

> **Lehre:** Ein festgehaltener Befund ist kein behobener Befund. Diese
> Beobachtung stand in der Doku, war korrekt, und hat nichts bewirkt — weil
> „notiert" sich wie „erledigt" liest, wenn man die Zeile später wiederfindet.

---

### Ü39 — Ein leerer Katalog sieht richtig aus, wenn die Registrierung an ihm vorbeigeht

`cmdlog.nvim/docs/BINDINGS.md` behauptete „Autocmds. **None.** cmdlog registers
no autocmds" — mit einer ausführlichen Begründung, *warum* der Katalog zweimal
leergeräumt worden war. Die Begründung stimmte. Die Aussage nicht:
`core/tracker.lua` registriert seit jeher ein `CmdlineLeave` in der Gruppe
`cmdlog_tracker`, und die Options-Seite drei Verzeichnisebenen weiter
beschrieb genau diesen Autocmd.

Der blinde Fleck ist strukturell: der Tracker registriert in `core/`, **nicht**
über `bindings/autocmds.lua`. Er war deshalb nie im Katalog — und das
Leerräumen für ein anderes Feature sah folgerichtig aus. `require("cmdlog.bindings").catalog()`,
das `BINDINGS.md` selbst als Laufzeit-Quelle empfiehlt, log damit ebenfalls.

> **Ein Katalog, der nur enthält, was sich bei ihm anmeldet, belegt nichts über
> das, was sich woanders anmeldet.** „Keine" ist eine Behauptung über den Code,
> nicht über die Registry — sie ist gegen `nvim_create_autocmd`/`autocmd.create`
> im ganzen Baum zu prüfen, nicht gegen die Katalogdatei.

Gefunden hat es der Diff zweier getrennt gepflegter Seiten — [Ü20](#ü20--doppelt-gepflegte-referenzen-sind-ein-fundbüro-kein-befund)
zum fünften Mal in Folge der ergiebigste Einzelschritt eines Durchgangs.

---

### Ü40 — Ein Doku-Beispiel kann kaputt sein statt bloß veraltet

`cmdlog.nvim/docs/ADD_PICKER.md` zeigte
`require("cmdlog.ui.mappings").show_history_picker` als Einstieg. Das Modul ist
seit einem Refactor eine **Factory** — der Ausdruck indiziert einen
Funktionswert, der nicht existiert, und das Rezept wirft beim ersten Versuch.

Das ist eine eigene Klasse neben „stale": ein veraltetes Beispiel tut das
Falsche, ein kaputtes tut gar nichts. Beide lesen sich gleich, und **kein
Prüfer sieht eines von beiden** — `DOC-12` ist nur zu prüfen, indem man
Beispiel und echte Signatur nebeneinanderlegt.

> Für die verbleibenden Repos: Jedes `ADD_*.md`/`EXTENDING.md`/`api.md`-Beispiel
> einmal gegen die Signatur halten, die es aufruft. Das ist billiger als es
> klingt und findet die Fälle, die ein Leser als Erstes ausprobiert.

---

### Ü41 — Der Case-Check sah nur das letzte Pfadsegment ⚠️

Gefunden beim `sandbox.nvim`-Durchgang, an einem Link auf `./tests/README.md`
bei einem Verzeichnis, das `TESTS/` heißt. Der Dateiname war korrekt
geschrieben, das **Verzeichnis** nicht — und `real_name_mismatch()` in
`docs_linkcheck.py` verglich ausschließlich `os.path.split(path)[1]` gegen die
echten Verzeichniseinträge. Ergebnis: grün.

Das ist genau die Fehlerklasse, für die der Prüfer gebaut wurde, nur einen
Pfadabschnitt weiter oben — und damit **Ü7 zum dritten Mal in eigener Sache**:
nicht zu viele Befunde, sondern eine ganze Klasse, die still durchfällt.

Wie still, zeigt `color_my_ascii.nvim`. Dort steht auf der Platte:

```
docs/FEATURES/     <- git kennt nur diesen
docs/features/     <- dieselbe Sache, in Windows' Zweitschreibweise
```

`docs/WORKFLOW.md:155` verlinkte `features/COLORSCHEMES.md`. Lokal grün, auf
GitHub 404 — in einem Repo, das seinen vollen Durchgang (`bfb74da`) bereits
hinter sich hatte, samt Linkcheck.

**Behoben:** `real_name_mismatch()` läuft jetzt über **jedes** Segment des
relativen Pfades und meldet die korrigierte Schreibweise vollständig, statt
nur den Dateinamen. Am bekannten Fall geeicht, dann über alle 32 Repos
gefahren: **genau ein** weiterer Treffer, der eine oben, inzwischen behoben
(`411e429`).

> **Lehre:** Ein Prüfer, der eine Fehlerklasse kennt, prüft sie deshalb noch
> nicht überall, wo sie auftreten kann. Die Frage ist nicht „prüft er auf
> Case?", sondern „**auf welchem Teil der Eingabe** prüft er darauf?" —
> dieselbe Frage, die bei [Ü36](#ü36--ein-unescaptes--in-einer-zelle-verwirft-inhalt-und-ein-test-hielt-den-fehler-fest)
> die Escaping-Funktion des Composers entlarvt hat, die es gab und die auf die
> falsche Spalte zeigte. Zweimal derselbe Fehler in zwei Werkzeugen, zwei Tage
> auseinander.

---

### Ü42 — Zwei Referenzen, die sich nicht widersprechen, können trotzdem beide falsch sein

`sandbox.nvim` hatte drei Beschreibungen von `:checkhealth sandbox` — README,
`FEATURES/ENGINES.md`, Vimdoc. **Alle drei falsch, jede anders:** das README
nannte 2 von 5 Prüfungen, `ENGINES.md` behauptete eine lib.nvim/telescope-
Prüfung, die es nie gegeben hat, und das Vimdoc beschrieb den Stand vor einem
Commit.

Ü20 sagt „doppelt gepflegte Referenzen gegeneinander diffen". Das reicht hier
nicht: der Diff zweier Dokumente findet nur, worin sie sich *unterscheiden*.
Wo alle Fassungen aus derselben veralteten Quelle abgeschrieben sind, sind sie
untereinander konsistent und gemeinsam falsch.

> **Ergänzung zu Ü20:** Der Diff der Dokumente gegeneinander findet
> Widersprüche. Den *gemeinsamen* Irrtum findet nur der Diff gegen den
> **Quelltext**. Bei `sandbox.nvim` war das der ergiebigere der beiden Läufe —
> und dort fielen auch zwei user-sichtbare Strings, die entfernte Kommandos
> nannten (`WslList…` in `health.lua`, `:Sandbox images pull` in `hover.lua`,
> beide seit dem Umbau auf `:Sandbox` bzw. `image`).

Nebenbefund derselben Art, und ein hübscher: **derselbe verrutschte Kommentar
in zwei Dateien.** Beim Einfügen eines `hover`-Feldes zwischen
`progress_style` und dessen Erklärung ist die Erklärung in `DEFAULTS.lua` auf
`completion_cache_ttl_ms` gefallen und in `@types/init.lua` auf `hover` —
zweimal dieselbe Bearbeitung, zweimal derselbe Schaden, findbar nur beim
Lesen.

---

### Ü43 — Betonung in Vimdoc ist keine Betonung, sondern eine Tag-Definition ⚠️

In `doc/*.txt` ist `*wort*` kein Kursivsatz, sondern eine **Tag-Definition**.
`:helptags` indiziert sie, und der Plugin-Manager ruft `:helptags` nach jeder
Installation auf. Was als Betonung gemeint war, landet also auf jedem
Rechner in `doc/tags` und verdeckt echte Neovim-Hilfethemen.

Gefunden beim `images.nvim`-Durchgang (`:help no` und `:help file` gehörten
danach dem Plugin). Über die Sammlung nachgemessen: **47 Vorkommen in 14
Repos**, darunter

`:help lists` · `:help local` · `:help mode` · `:help after` · `:help order` ·
`:help and` · `:help not` · `:help same`

— alles echte Vim-Hilfethemen. Behoben: Sternchen weg, Wortlaut unangetastet.
Die Plugin-Namens-Tags (`*cmdlog*`, `*wkddap*`, `*sandbox*`) bleiben; das ist
der eine Fall, in dem ein nacktes Wort als Tag richtig ist.

**Die eigentliche Lehre steckt im ersten Anlauf, der falsch war.** Ich hatte
über die Prosa gegrept — jedes `*wort*`, das Text hinter sich hat, ist
Betonung — und 44 Stellen umgeschrieben. Dann fiel auf, dass `images.nvim`s
`doc/tags` das Wort `module` gar nicht enthielt, obwohl `*module*` im Text
stand. Der Grund: **ein Tag muss beidseitig von Leerraum begrenzt sein.**
`*module*,` — mit Komma am schließenden Stern — hat `:helptags` nie indiziert.
Ein Teil meiner Änderungen betraf also Text, der nicht kaputt war.

Zurückgesetzt und neu gemacht, diesmal **gegen `doc/tags` statt gegen ein
Muster**: die erzeugte Tag-Datei sagt, welche Wörter tatsächlich Tags wurden.
47 statt 44, 0 verfehlt, und keine Zeile angefasst, die Vim ohnehin ignoriert.

> **Lehre — dieselbe wie [Ü7](#ü7--naive-link-checks-bestehen-zu-80--aus-rauschen),
> nur in eigener Sache:** Wenn ein Werkzeug die Antwort bereits erzeugt, ist
> das Muster über die Eingabe die schlechtere Frage. `doc/tags` *ist* das
> Ergebnis von `:helptags` — es zu lesen kostet nichts und rät nichts.

Zwei Nebenbefunde derselben Klasse, beide **kein** Befund und deshalb
festgehalten: `replacer.nvim`s `" *item*  within the selected lines` zeigt die
*Ausgabe* eines `:Surround`-Beispiels, und `:helptags` indiziert es trotz
Leerraum-Begrenzung nicht. Und `*item*` in Backticks zu setzen wäre die
Reparatur eines Nicht-Problems gewesen — beinahe passiert.

---

### Ü44 — Jede zusätzliche Kopie driftet in ihre *eigene* Richtung

`images.nvim` hatte **drei** getrennt gepflegte Kommandokataloge: die
README-Tabelle, `docs/BINDINGS.md` und `doc/images.txt`. Jeder hatte ein Loch,
und **jeder ein anderes**:

| Fassung | Fehlt |
|---|---|
| README-Tabelle | `scale`, `optimise`, `convert`, `ocr` |
| `BINDINGS.md` | `debug` |
| `doc/images.txt` | `calibrate`, `debug` |

`:Image debug` stand in **keiner** der drei.

Ü17 sagt „`doc/*.txt` driftet mit". Die schärfere Form ist: nicht alle
Kopien driften in dieselbe Richtung, sondern jede in ihre eigene. Ein
Paardiff findet deshalb höchstens zwei Drittel — belastbar ist nur der
Abgleich **aller** Fassungen gegen den Quelltext, so wie
[Ü42](#ü42--zwei-referenzen-die-sich-nicht-widersprechen-können-trotzdem-beide-falsch-sein)
es für den gemeinsamen Irrtum verlangt.

---

### Ü45 — Eine Ordinalzahl in Prosa ist eine Invariante ohne Prüfer

`images.nvim` schrieb über acht Stellen verteilt „die **dritte** deliberate
exception" bzw. „die vierte" — drei Lua-Dateien, vier Vimdoc-Stellen, das
README. Seit `scale`/`optimise`/`convert` dazukamen, war die Zahl falsch, und
dieselbe Datei sagte an anderer Stelle korrekt, dass jene drei ImageMagick
„without a fallback" brauchen.

> Wer „die dritte Ausnahme" schreibt, gibt eine Konsistenzzusage über den
> ganzen Baum ab und stellt niemanden ab, der sie prüft. Der Fix ist nicht,
> die Zahl zu korrigieren, sondern sie zu streichen und **eine** Liste zu
> benennen, auf die alle Stellen zeigen.

**Verwandter Fall aus demselben Repo:** eine Dependency, die das Plugin nie
aufruft. `chafa` stand als „the terminal-image fallback renderer" in
`installation.md`, im README und in `FEATURES/INTEGRATIONS.md` — tatsächlich
zeichnet `images/ascii.lua` die Blockgrafik selbst über Extmarks, und `chafa`
kommt im Quellbaum nur in zwei Kommentaren vor, als *Vergleich*. Eine
Formulierung ist von „wie chafa" zu „braucht chafa" gerutscht. Kein Prüfer
sieht das: der Werkzeugname existiert, die Prosa ist einwandfrei, kein Link
ist tot.

> ⚠️ **Offen:** `images.nvim/docs/install.json` deklariert `chafa` weiterhin.
> `:Lib deps show images.nvim` meldet es damit als fehlend und
> `:Lib deps install` bietet ein Paket an, das nichts freischaltet. Die Datei
> gehört dem deps-Durchgang (Ü9) und ist unangetastet geblieben — **eine
> Zeile für jenen Lauf.**

---

### Ü46 — Ein falsches Beispiel, das Erfolg meldet, ist schlimmer als eines, das wirft ⚠️

[Ü40](#ü40--ein-doku-beispiel-kann-kaputt-sein-statt-bloß-veraltet) unterschied
zwei Fälle: ein veraltetes Beispiel tut das Falsche, ein kaputtes tut gar
nichts. `github_stats.nvim` liefert den dritten und schlechtesten.

Date-Presets werden an **genau einer** Stelle aufgelöst,
`analytics.parse_time_range`. Die Completion bietet sie in drei Slots an, die
dort nie ankommen:

| Aufrufer | Löst auf? |
|---|---|
| Dashboard-`T`-Prompt | ja, immer |
| `:GithubStats chart`, Arg 3 | **nur** wenn der Name `last` enthält oder wie `Nd` aussieht |
| `:GithubStats show` | **nie** — das Argument wird `start_date`, dort greift nur `YYYY-MM-DD` |
| `:GithubStats diff` | **nie** — `parse_period` nimmt `YYYY-MM`/`YYYY` |

Wo nicht aufgelöst wird, scheitert der Name am Datums-Regex, `parse_date`
liefert `nil`, die Grenze wird übersprungen — das Ergebnis ist **kein Filter**.
`:GithubStats show user/repo clones this_month` meldet die volle Historie und
sieht dabei aus, als hätte es funktioniert. **Vier Dokumente** behaupteten das
Gegenteil, einschließlich *jedes* Usage-Beispiels im Preset-Guide.

> Kein Prüfer der Welt findet das. Es gibt keinen toten Link, keinen falschen
> Anker, keine kaputte Tabelle und keine Ausnahme beim Ausführen — nur eine
> Zahl, die zu groß ist. Gefunden wurde es, weil der Durchgang der Behauptung
> nicht geglaubt und `show.lua` gelesen hat.

**Nicht behoben, und das ist richtig so:** der Fix gehört in `show.lua`/
`chart.lua` (das Argument durch `date_presets.resolve` schicken) oder in die
Completion (Presets an Slots nicht anbieten, an denen sie wirkungslos sind).
Eine Doku-Session ändert kein Verhalten. Die Doku sagt jetzt an vier Stellen
ausdrücklich, was gilt. → **Autorenentscheidung.**

---

### Ü47 — Ü42 erwischt auch den, der gerade aufräumt

Beim Überarbeiten von `cross-platform.md` hat der Durchgang den Satz „curl
detection via PowerShell's `Get-Command`" zunächst **in die neue Fassung
übernommen** und erst danach gegen
`lib.nvim/lua/lib/nvim/cross/executable/init.lua` gehalten: es ist
`vim.fn.executable()`, memoisiert, ohne jede Plattform-Verzweigung. Beide
Hälften der alten Tabelle — Windows *und* POSIX — waren falsch.

Ohne den Blick in den Quelltext wäre der Fehler in eine frisch überarbeitete
Datei **neu hineingeschrieben** worden, mit dem Anschein, geprüft worden zu
sein.

> **Beim Umschreiben ist jeder übernommene Satz eine neue Behauptung.** Was aus
> der alten Fassung mitwandert, ist nicht deshalb geprüft, weil die Datei
> insgesamt bearbeitet wurde. Das ist die praktische Kehrseite von
> [Ü42](#ü42--zwei-referenzen-die-sich-nicht-widersprechen-können-trotzdem-beide-falsch-sein):
> dort waren drei Fassungen gemeinsam falsch, hier wäre die vierte dazugekommen.

Nebenbefund, und [Ü39](#ü39--ein-leerer-katalog-sieht-richtig-aus-wenn-die-registrierung-an-ihm-vorbeigeht)
zum zweiten Mal: `VimResized` ist in `dashboard/layout.lua` registriert, also
außerhalb von `bindings/`, und stand deshalb in **keiner** Bindings-Tabelle.
Zweimal dasselbe Muster in zwei Repos — die Regel ist also nicht „prüfe den
Katalog", sondern **`grep` über `nvim_create_autocmd` im ganzen Baum**.

---

### Ü48 — Ein Dateiname kann aus einem *maschinellen* Grund feststehen

Bei `pickers.nvim` stellte sich die Frage, ob `CHEATSHEET.md` groß bleiben darf,
weil `BINDINGS.md` daneben auch groß ist. Die Antwort ist nein, und die
Begründung ist der eigentliche Ertrag:

> **`BINDINGS.md` ist nicht groß, weil es ein Meta-Dokument wäre, sondern weil
> `:Bindings` es seit [BND-01](#ü37--auf-die-wahrheit-zeigen-beseitigt-keine-doppelung-bnd-0103)
> unter genau diesem Pfad in allen 32 Repos liest.** Seine Schreibweise ist ein
> **Protokoll, keine Gattung** — und ein Protokoll vererbt sich nicht an die
> Nachbardatei.

Befund B ist eine **Gattungsregel**: Themen-Dokumente klein, Meta-Dokumente
groß. Ein Name, der aus einem maschinellen Grund feststeht — weil ein Kommando,
ein Generator oder eine `.gitignore` ihn liest —, fällt nicht unter sie und
darf nicht als Präzedenz dienen. Dieselbe Logik hat `sandbox.nvim`
`GENERATED_COMMANDS.md` groß gelassen (der Pfad steht in `GENERATED_DOCS_PATH`)
und `github_stats.nvim` den Ordner `configurations/` im Plural belassen (weil
[Ü21](#ü21--die-vier-restmeldungen-waren-vier-verschiedene-fehlerklassen) tags
zuvor genau in die Gegenrichtung repariert hatte).

---

### Ü49 — `:help <plugin>` führte in 15 Repos nirgendwohin

Nebenbefund aus `pickers.nvim`: `:help pickers` fand nichts, es gab nur
`*pickers.txt*`. Über die Sammlung nachgemessen — und die Mehrheit hatte längst
eine Antwort:

| | Repos |
|---|---|
| `:help <name>.nvim` funktioniert | **16** |
| kein Einstieg außer dem Dateinamen | **16** |

`fileops.txt` zeigt die Form: der Tag steht rechtsbündig auf der Titelzeile.
Nachgezogen in allen 16 (`markdown.nvim` nachträglich, es lag beim Sweep in
einem parallelen Durchgang).

**Warum `<name>.nvim` und nicht der nackte Name** — das ist die Stelle, an der
[Ü43](#ü43--betonung-in-vimdoc-ist-keine-betonung-sondern-eine-tag-definition-️)
unmittelbar weiterwirkt: `:help lsp`, `:help markdown`, `:help images` und
`:help language` würden jeweils ein Wort beanspruchen, das Neovims eigene Hilfe
braucht. Genau der Fehler, der gerade in 14 Repos beseitigt wurde. Das
`.nvim`-Suffix kann nicht kollidieren.

> Die drei Repos mit nacktem Tag (`cmdlog`, `pickers`, `sandbox`) bleiben, wie
> sie sind — die Namen sind unterscheidbar genug und ausgeliefert. Für neue
> gilt die Suffix-Form.

---

### Ü50 — Vier gleichlautende Fassungen sind nicht besser als zwei widersprüchliche

`pickers.nvim` beschrieb `:checkhealth pickers` in **fünf** Dateien. Keine zwei
widersprachen sich — alle waren nach demselben Stand geschrieben, und
`health.lua` hatte seither zwei Abschnitte dazubekommen. `FEATURES/UI.md`
nannte sogar eine Zahl („five sections"), die den Irrtum konservierte.

Das ist [Ü42](#ü42--zwei-referenzen-die-sich-nicht-widersprechen-können-trotzdem-beide-falsch-sein)
mit fünf statt drei Kopien, verschränkt mit
[Ü45](#ü45--eine-ordinalzahl-in-prosa-ist-eine-invariante-ohne-prüfer): **die
Zahl macht den gemeinsamen Irrtum unsichtbar, weil sie konsistent falsch ist.**

Aus demselben Durchgang, dieselbe Mechanik von der anderen Seite: „~40 native
pickers" im README bei tatsächlich **52**. Die drei Stellen *näher* an der
Liste waren richtig — die Zahl driftet dort zuerst, wo sie am weitesten von
dem entfernt steht, was sie zählt. Der Fix war nicht, sie zu korrigieren,
sondern sie **einmal** hinzuschreiben, direkt über die Matrix, die sie zählt,
und überall sonst zu verlinken.

---

### Ü51 — `architecture.md` veraltet lautlos, weil niemand neue Dateien dagegen hält

Kurzer Vorabblick auf `markdown.nvim` (noch nicht in Welle 4 an der Reihe):
`git ls-files 'lua/**/*.lua'` gegen `docs/architecture.md` gehalten findet
**15 Module, die die Seite nicht kennt** — vollständige Liste im
[Handover-Punkt](#️-handover-punkt--sitzungslimit-2026-09-05-kurz-vor-1250-europeberlin)
oben. Keins davon ist neu im Sinne von „gestern geschrieben"; sie sind über
mehrere Feature-Commits entstanden, `architecture.md` aber seit seiner
Anlage nicht mitgewachsen.

Das ist [Ü13](#ü13--der-doku-bestand-endet-nicht-bei-docs)s Gegenstück:
dort fehlte der Blick über `docs/` hinaus, hier existiert die Seite, die
`lua/` beschreiben soll, und hält trotzdem nicht mit ihm Schritt — weil
nichts sie dazu zwingt. Kein Linkchecker, kein Anchor-, kein Tabellen-Prüfer
sieht das: die Seite ist in sich vollständig und korrekt, sie zählt nur zu
wenig auf.

> Für `markdown.nvim`s vollen Durchgang: `architecture.md` gegen
> `git ls-files 'lua/**/*.lua'` abgleichen, nicht gegen das eigene
> Inhaltsverzeichnis. Kein eigener `DOC-ID`-Kandidat — das ist `DOC-01`
> (Pflichtdatei vorhanden) zu Ende gedacht: vorhanden heißt hier auch
> vollständig, nicht nur existent.

---

### Ü52 — Eine vollständige Reference kann drei ganze Config-Abschnitte auslassen

`markdown.nvim`s voller Durchgang (2026-09-05) lief an einem Repo, das jeden
automatisierten Prüfer bereits mit 0 Befunden bestand — `docs_linkcheck.py`,
`docs_anchorcheck.py`, `docs_tablecheck.py` waren vor **und** nach dem
Durchgang bei 0/0/0. Trotzdem lagen vier echte Lücken offen, alle vom selben
Typ wie [Ü39](#ü39--ein-leerer-katalog-sieht-richtig-aus-wenn-die-registrierung-an-ihm-vorbeigeht)/[Ü47](#ü47--ü42-erwischt-auch-den-der-gerade-aufräumt):
eine als vollständig behauptete Liste, gegen die nie ein Werkzeug gehalten
wurde, weil kein Prüfer „ist diese Aufzählung vollständig" fragen kann, nur
„sind die Links darin gültig".

- `docs/configuration.md` heißt „Full reference with defaults" und listet
  ein komplettes `setup({...})` — dem **drei von neunzehn** Top-Level-Keys aus
  `DEFAULTS.lua` fehlten: `hover`, `menu`, `underline_headings`. Gefunden mit
  einem Zweizeiler (`grep` der Top-Level-Keys aus beiden Dateien, `comm -23`),
  keine Handprüfung.
- `docs/BINDINGS.md`/`.lua`, deren eigener Kopf sagt „the source of truth is
  `lua/markdown/bindings/`… A change there must be reflected here", hatten
  **vier von neun** Autocmd-Gruppen nicht — darunter `MarkdownNvimLinksSanitize`,
  die **default-on** auf jedem Save Link-Ziele umschreibt. Wer nur die Tabelle
  liest, hat keine Ahnung, dass das passiert.
- Dieselben zwei Dateien kannten bei `:Markdown links` nur `show`/`create`,
  nicht `check`/`sanitize` — die `docs/commands.md` schon vollständig hatte.
  Zwei Referenzdokumente für dieselbe Sache, eine davon unvollständig, ist
  [Ü20](#ü20--doppelt-gepflegte-referenzen-sind-ein-fundbüro-kein-befund)
  in Reinform.
- `docs/FEATURES/LINKS-AND-REFERENCES.md` hat einen eigenen Abschnitt für
  jedes `links.*`-Verhalten — außer für `sanitize`, das einzige davon, das
  ohne Zutun läuft.

**Und ein Ü22-Fall mit Zähnen statt nur einer falschen Zahl:** README/Badge/
`installation.md`/`health.lua` sagten unisono „Neovim 0.9+". Grep über
`vim.uv`/`vim.system` fand `commands/markdown_links.lua`s `local uv = vim.uv`
(ungeguarded, im Gegensatz zu acht Schwesterdateien) — ein **echter Crash**
auf 0.9 bei `:Markdown links create`, nicht nur eine Doku-Ungenauigkeit — und
`core/file_refs.lua`s `vim.system(...)`-Aufrufe, unconditional sobald `rg`
gefunden wird, für die es **keinen** Fallback gibt (anders als
`util/platform.lua`s eigener `vim.system`-Aufruf, der sauber auf `jobstart`
zurückfällt). Der Uv-Fall war ein Einzeiler und wurde **im Code** behoben
(`65f47ec`) — dieselbe Ausnahme wie `debugging.nvim`s `DEFAULTS.lua`-Nachtrag:
trivial, verhaltensgleich auf 0.10+, stellt nur die überall sonst geltende
Absicht wieder her. Der `vim.system`-Fall ist echte neue Fallback-Logik und
blieb Doku (Floor auf 0.10+, an allen vier Stellen).

> **Lehre:** „0 Befunde" aus allen drei Prüfern heißt „keine kaputten Links,
> Anker, Tabellen" — nicht „nichts fehlt". Eine Reference-Datei, die sich
> selbst als vollständig bezeichnet, braucht eine Gegenprobe, die *zählt*:
> Top-Level-Keys beider Seiten grep-en und `comm -23`, Autocmd-Gruppen aus
> `bindings/autocmds.lua` gegen die Cheatsheet-Tabelle, Dispatcher-`subcommands`-
> Tabelle gegen die Kommandoliste. Jede dieser drei Gegenproben ist ein
> Zweizeiler und keine hätte ein Linkchecker je finden können.

---

### Ü53 — Ein Dokument kann seine eigene Kopfzeile widerlegen

`casedesk.nvim/docs/REQUESTS.md` erklärt sich selbst: „the unedited request
list… kept verbatim… Entries here are not tracked or ticked off." Die ersten
zwei Abschnitte (`Praxis-Feedback`, `new`) stimmen damit exakt überein —
unredigiertes, tippfehlerreiches Deutsch. Die zwei Abschnitte darunter
(`Offen`, `Erledigt`) sind das Gegenteil: sortiert nach Aufwand, mit
Checkboxen, Daten, Aufwandsschätzungen — ein zweiter, aktiv gepflegter
Tracker, der `ROADMAP.md`s Beschreibung fast wörtlich wiederholt („Sortiert
nach geschätztem Aufwand, billigste/kleinste zuerst" gegen ROADMAP.md
„roughly by effort, cheapest first").

**Das ist [Ü32](#ü32--was-auf-ein-dokument-zeigt-entscheidet-was-es-ist-nicht-sein-name)
von der anderen Seite:** dort entschied nicht der Name, sondern was auf ein
Dokument zeigt; hier widerlegt nicht der Name die Kopfzeile, sondern das,
was *unter* der Kopfzeile tatsächlich steht. Eine Selbstbeschreibung ist eine
Behauptung wie jede andere in Ü22/Ü42/Ü46 — sie war beim Schreiben wahr und
ist es an dieser Stelle nicht mehr, weil der Abschnitt darunter organisch
über seinen ursprünglichen Zweck hinausgewachsen ist.

**Nicht zusammengeführt.** Welche der beiden Kopien (`REQUESTS.md/Offen`
oder `ROADMAP.md`) autoritativ ist, ist eine Inhaltsentscheidung — dieselbe
Grenze wie beim `vim.uv or vim.loop`-Fix in markdown.nvim: trivial und
verhaltenserhaltend wird im Doku-Durchgang mitgemacht, eine Zusammenführung
zweier lebendiger Roadmaps nicht. Die Kopfzeile sagt jetzt ausdrücklich, dass
und warum sie an dieser Stelle nicht mehr stimmt — die nächste Sitzung findet
den Widerspruch also dokumentiert vor, statt ihn erneut aufzudecken.

Im selben Repo, klarer Fall statt Grenzfall: `docs/HANDOVER.md` (Datum,
private Pfade, ein Kollegenname, „liest diese Datei zuerst, wer eine neue
Sitzung startet") und `docs/PTO.md` (Kopfzeile sagt selbst „Konzept, nichts
gebaut") waren beide zweifelsfrei `DOC-16` und sind nach
`wkdbook-myplugins/casedesk.nvim/` verschoben — mit Herkunftsvermerk und
allen sechs eingehenden Verweisen umgebogen statt tot gelassen.

---

### Ü54 — Ein Feature, das nachträglich in 32 `DEFAULTS.lua` gelandet ist, fehlt in 32 `configuration.md` gleich mit

Die letzten neun Repos der Welle 4 (`dap`, `diff`, `emojis`, `filetree`,
`insights`, `language`, `open`, `pdfport`, `recommender`) liefen deutlich
schneller als die vorherigen — kleinere, bereits vorsortierte Lücken statt
struktureller Umbauten. Eine Lücke kam dabei **vier Mal unabhängig**:
`deps_popup` (der einmalige „welche CLI-Tools will dieses Plugin"-Popup aus
`lib.nvim.deps`) steht in `filetree.nvim`, `insights.nvim`, `language.nvim`
und `pdfport.nvim`s `DEFAULTS.lua`, wird im jeweiligen Root-README einmal
erwähnt — und fehlt in allen vieren aus `configuration.md`s „vollständiger"
Optionsliste.

**Das ist kein Zufall, sondern ein Zeitstempel.** Der deps-Durchgang aus
[Ü9](#ü9--ein-zweiter-durchgang-läuft-parallel-und-hält-sechs-repos-besetzt-️)
hat `deps_popup` flächendeckend nachgerüstet, nachdem `configuration.md`
für die meisten Repos schon geschrieben war — eine Option, die *nach* der
Doku-Referenz dazukam, kann in ihr nicht stehen, ohne dass irgendjemand sie
nachträgt. Derselbe Mechanismus, den [Ü22](#ü22--was-die-doku-über-die-umgebung-behauptet-prüft-niemand-️)
für Versionszusagen beschreibt (die Doku war richtig, als sie geschrieben
wurde, und der Code ist seitdem weitergelaufen), hier auf eine einzelne
Config-Option angewandt statt auf eine Plattformzusage.

**Praktische Folge für die verbleibenden/zukünftigen Durchgänge:** `grep -rn
"deps_popup" lua/*/config/DEFAULTS.lua` lohnt sich als Vorab-Check über die
ganze Sammlung, bevor man Repo für Repo einzeln danach sucht — vier Treffer
aus neun geprüften Repos ist eine hohe Trefferquote für einen einzigen Grep.

**Zweiter, kleinerer Fund derselben Sitzung:** drei der neun Repos
(`insights.nvim` 389 Zeilen, `language.nvim` 277 Zeilen, `pdfport.nvim` 405
Zeilen `health.lua`) hatten überhaupt keine `docs/health.md`, nur einen
Einzeiler in `installation.md`/`commands.md` — derselbe Befund wie bei
`buffer-ctx.nvim` weiter oben in dieser Welle, hier aber gehäuft. Eine
`health.lua` über 200 Zeilen mit mehr als fünf `start()`-Sektionen ist damit
ein brauchbarer Schwellenwert, ab dem sich eine eigene Seite lohnt — darunter
(wie bei `sessions.nvim`, 163 Zeilen/4 Sektionen) reicht ein guter Absatz in
`troubleshooting.md`/`installation.md`.

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

> ⚠️ **`$REPOS_DIR\WKDBooks` ist nicht committet.** Die 11 verschobenen Dateien
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
Pythons `os.path.exists` erbt das. Ein Link `[x](./COMMANDS.md)` auf eine Datei
`commands.md` ist lokal grün und auf GitHub ein 404. Das Skript vergleicht
deshalb gegen die echten Verzeichniseinträge. **Pflichtlauf nach jedem Rename**
(`DOC-02` produziert genau diesen Fehler).

**Am 2026-09-05 verschärft:** die Prüfung lief nur über den *Dateinamen*. Sie läuft jetzt über **jedes Segment** des Pfades und meldet die korrigierte Schreibweise vollständig — ein Link auf `features/X.md` bei `FEATURES/` auf der Platte war vorher grün. Siehe Ü41.

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

---

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

---

### `scripts/docs_tablecheck.py` (neu, 2026-09-05)

```bash
python scripts/docs_tablecheck.py E:/repos/<repo>     # eines
python scripts/docs_tablecheck.py E:/repos/*.nvim     # alle
```

Der dritte Prüfer, entstanden aus [Ü35](#ü35--eine-tabelle-kann-mitten-im-dokument-aufhören-eine-zu-sein)
und [Ü36](#ü36--ein-unescaptes--in-einer-zelle-verwirft-inhalt-und-ein-test-hielt-den-fehler-fest).
Beide Fehler sind **strukturell**: der Link löst auf, der Anker stimmt, die
Datei liest sich richtig — und die gerenderte Seite zeigt etwas anderes.

| Klasse | Bedeutung | Bricht den Lauf |
|---|---|---|
| `FRAGMENT` | zwei oder mehr Tabellenzeilen ohne Kopfzeile darüber — sie rendern als Fließtext | ja |
| `OVERFLOW` | mehr Zellen als die Kopfzeile Spalten hat, praktisch immer ein unescaptes `\|` — der Überschuss wird verworfen | ja |
| `SHORT` | weniger Zellen als die Kopfzeile — Markdown füllt auf, nichts geht verloren | **nein** |

`SHORT` bricht bewusst nicht ab. Ein Prüfer, der auf Kosmetik rot wird, wird
nach dem dritten Mal nicht mehr aufgerufen — und die Klasse, die Inhalt
kostet, verschwindet dann in seinem Rauschen. Das ist [Ü7](#ü7--naive-link-checks-bestehen-zu-80--aus-rauschen)
mit anderem Vorzeichen: nicht zu viele Befunde, sondern Befunde falschen
Gewichts.

**Vor dem Flächeneinsatz geeicht** (Ü7): gegen den bekannten Fall aus
`cascade.nvim` — die Fassung vor der Reparatur meldet die acht Zeilen, die
Fassung danach meldet nichts.

Fenced Code wird komplett übersprungen; ein `|` in einem Shell-Beispiel oder
einem ASCII-Diagramm ist keine Tabellenzeile, und das war in der ersten
Fassung die gesamte Falschbefund-Quote.

**Grenzen:** erkennt eine *unterbrochene* Tabelle, nicht eine *inhaltlich
falsche*. Und die Kopfzeile selbst wird nicht geprüft — steht dort eine
Spalte zu wenig, ist jede Datenzeile `OVERFLOW` statt die Kopfzeile falsch.

**Stand nach dem ersten Flächenlauf:** 3 `FRAGMENT` und 2 `OVERFLOW` über
alle 32 Repos, dazu 27 `OVERFLOW` in zwei generierten Dateien. Alle behoben.
Es bleibt **ein** `SHORT` in `lib.nvim/lua/lib/nvim/buf_win_tab/Command-List.md`
— eine Zeile ohne die letzte, leere Zelle. Kosmetik, bewusst gelassen.

---

### Bestandsprüfer: `:DocMap` kann das teilweise auch

`color_my_ascii.nvim/docs/guides/README.md` verweist auf `:DocMap`, das tote
Links als `dead-readme-link` flaggt. Überschneidung ist gewollt: `docs_linkcheck.py`
läuft ohne nvim, prüft case-sensitiv und eignet sich für den Flächenlauf;
`:DocMap` ist das Werkzeug in der Sitzung.

---

### Offene Befundliste (Stand 2026-09-04, nach dem Anker-Durchgang)

**Tote Links: keiner.** Der eine gemeldete ist geprüft und **kein Befund** —
`casedesk.nvim/lua/casedesk/templates/Research.md` zeigt auf `../Replies/`,
das im erzeugten Fallbaum existiert, nicht im Repo. Siehe
[Ü30](#ü30--ein-toter-link-kann-am-richtigen-ziel-hängen).

Die 8 in `color_my_ascii.nvim` sind **weg**, mit dessen vollem Durchgang
(`bfb74da`, siehe [Ü25](#ü25--vier-weitere-repos-waren-fertig-ohne-dass-es-hier-stand)).
Früher am 2026-09-04 erledigt: `gopath.nvim`, `insights.nvim`, `pickers.nvim`
(je 1 `dead`) und `github_stats.nvim` (6 `dead` + 1 `CASE`) — siehe
[Ü21](#ü21--die-vier-restmeldungen-waren-vier-verschiedene-fehlerklassen).

**Tote Anker: keiner.** 21 in drei Repos gefunden und behoben
([Ü27](#ü27--emoji-im-titel-der-anker-behält-das-leerzeichen-gemessen)); die
vier verbleibenden Meldungen liegen in `mdview.nvim/TESTS/testfile.md`, einer
Fixture mit absichtlich kaputten Links.

**Verwaiste Dokumente (`DOC-06`) in `docs/`: null.** Von 48 gemeldeten waren
14 echte Dokumente plus 16 `WORKFLOW.md`; beide Gruppen sind abgearbeitet.
Was der Prüfer noch meldet, ist keine Doku: Modul-`README.md` unter `lua/`
(von [Ü6](#ü6--mehr-doku-ebenen-können-richtig-sein-libnvim) gesegnet),
Fixtures unter `TESTS/`, und Templates, die der Plugin in fremde Bäume
schreibt ([Ü30](#ü30--ein-toter-link-kann-am-richtigen-ziel-hängen)). Seit
[Ü33](#ü33--der-prüfer-hielt-jede-readmemd-für-erreichbar) prüft `DOC-06`
deshalb nur noch `docs/**` und die Repo-Wurzel.

**`docs/README.md` gibt es jetzt in 32 von 32 Repos** — bei der
Bestandsaufnahme waren es 2, vor dieser Tranche 17. Damit ist der Baustein
vollständig, den §3.1 „die größte echte Neuerung dieses Standards" nennt, und
[Ü26](#ü26--workflowmd-ist-in-16-repos-verwaist-und-das-ist-ein-befund)s
Befund ist strukturell erledigt: die verwaiste `WORKFLOW.md` gab es nur, wo
der Wegweiser fehlte.

> Jeder dieser Indexe ist aus dem Lesen der eigenen Seiten geschrieben, nicht
> aus einer Vorlage — er soll ja gerade *sagen*, welche Frage jede Seite
> beantwortet. Wo eine Pflichtseite noch fehlt (`cascade` und `spotlight`
> haben Installation und Konfiguration im README), steht das **im Index
> selbst** unter „Not here yet", damit die Lücke lesbar bleibt statt still zu
> sein.

---

### Was die Index-Tranche für die vollen Durchgänge notiert hat

Beim Lesen von fünfzehn `docs/`-Ordnern fällt auf, was der volle Durchgang
jeweils vorfinden wird. Jeder Punkt steht auch in der Commit-Message des
betroffenen Repos:

| Repo | Vorgefunden |
|---|---|
| `cascade` 584, `spotlight` 652, `images` 546, `runtime-analysis` 627, `sandbox` 345, `cmdlog` 391 | README weit über dem E2-Korridor, weil Installation, Konfiguration und Architektur noch dort stehen statt auf eigenen Seiten |
| `emojis`, `github_stats`, `diff`, `recommender`, `sessions`, `spotlight` | `FEATURES.md` als **Datei**, wo §3.1 einen Ordner will (`DOC-03`). Bei `diff` ausdrücklich begründet — „a small, single-purpose plugin" —, bei den anderen nicht |
| `pickers` | **jede** Seite in Großschreibung (`INSTALLATION.md`, `COMMANDS.md`, `CONFIGURATION.md`), wo die Mehrheit klein schreibt. Case-Rename braucht den Zwischennamen (`DOC-02`) |
| `github_stats` | `DASHBOARD.md`, `TROUBLESHOOTING.md`, `FEATURES.md` dito |
| `casedesk` | **acht von vierzehn Seiten deutsch** (`DOC-20`). `FEATURES.md` sagt weiterhin „Deutsch, als einzige Datei hier" und nennt zwei Absätze später fünf weitere. Der Index markiert sie jetzt mit **[de]**; ob übersetzt wird, ist eine Autorenentscheidung — das Fachgebiet ist auch außerhalb deutsch dokumentiert |
| `open` | `docs/commands.md` hat 213 Zeilen über zwei Kommandofamilien und erwähnt die Scope-Tokens nicht; die stehen allein im Cheatsheet |

---

### Eine falsche Zahl in einer Commit-Message

`markdown.nvim` `941262d` schließt mit „29 files, 0 dead links, 0 dead
anchors, 0 orphans". Die letzte Zahl ist **1**, nicht 0:
`TESTS/fence_scope.md` ist eine Fixture und meldet sich als Waise. Kein
Befund an der Sache, aber die Message behauptet eine Messung, die so nicht
stimmt.

Nicht per Force-Push korrigiert — die History für einen Wortlaut
umzuschreiben ist teurer als der Fehler. Steht deshalb hier, wo der nächste
Leser die Zahl gegenprüft.

> Die Zeile stammt aus einer Vorlage, die in dieser Tranche fünfzehnmal
> geschrieben wurde. **Eine wiederholte Formulierung ist genau die Stelle, an
> der eine Zahl mitläuft, ohne noch einmal gemessen worden zu sein** — das
> ist dieselbe Mechanik, die [Ü1](#ü1--der-alpha-disclaimer-war-nie-das-problem)
> und [Ü23](#ü23--drei-behauptungen-des-standards-über-hovernvim-waren-am-tag-der-welle-nicht-mehr-wahr)
> beschreiben, hier in meinem eigenen Text.

---

### Bekannte blinde Flecken der Bestands-Werkzeuge

Stehen in `LAST_CDX_TASKS.md` §8. Hier nur Neues.

- **Ein Anker, der auf den falschen Abschnitt auflöst**, ist für jedes Werkzeug
  grün. In `gopath.nvim` sind zwei ToC-Einträge auf ein gleichnamiges
  `####` weiter unten gefallen, weil die gemeinte Überschrift ein Emoji trug
  und damit einen anderen Anker hatte. Gefunden beim Lesen, nicht beim Prüfen —
  siehe [Ü27](#ü27--emoji-im-titel-der-anker-behält-das-leerzeichen-gemessen).

---

