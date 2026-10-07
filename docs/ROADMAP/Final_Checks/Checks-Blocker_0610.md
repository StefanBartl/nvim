# Final Checks 6. Nov: spotlight.nvim, mdview.nvim, ai.nvim, lib.nvim (Stand 2026-10-06)

## Table of content

  - [Intro](#intro)
  - [A. mdview.nvim (Releases v0.4.0 bis v0.4.3, `install.version = v0.4.3`)](#a-mdviewnvim-releases-v040-bis-v043-installversion-v043)
    - [Spotlight-Spiegelung im Browser](#spotlight-spiegelung-im-browser)
    - [Relay / Watcher](#relay-watcher)
    - [Bekannte offene Kleinigkeiten](#bekannte-offene-kleinigkeiten)
  - [B. spotlight.nvim](#b-spotlightnvim)
  - [C. ai.nvim](#c-ainvim)
    - [Copilot-Provider (neu, `6b84085`)](#copilot-provider-neu-6b84085)
    - [Command-Key-Quelle (`8b17769`, `eb714c3`, `82a58c7`)](#command-key-quelle-8b17769-eb714c3-82a58c7)
    - [Sonstiges](#sonstiges)
  - [D. lib.nvim](#d-libnvim)
  - [E. Housekeeping](#e-housekeeping)
  - [F. KI-Kette casedesk.nvim + ai.nvim (Review und Fixes vom 5./6.10., Stand 2026-10-06)](#f-ki-kette-casedesknvim-ainvim-review-und-fixes-vom-5610-stand-2026-10-06)
    - [F1. BLOCKER: `claude-cli` mit echtem Account (Task `ai.nvim/review-restpunkte`)](#f1-blocker-claude-cli-mit-echtem-account-task-ainvimreview-restpunkte)
    - [F2. Allow-List und Provider-Wahl auf der Workstation](#f2-allow-list-und-provider-wahl-auf-der-workstation)
    - [F3. Key-Profile (`:Ai key`)](#f3-key-profile-ai-key)
    - [F4. casedesk: Senden und Log-Analyse (nur mit freigegebenem Provider)](#f4-casedesk-senden-und-log-analyse-nur-mit-freigegebenem-provider)
    - [F5. Bekannte Grenzen (kein Test nötig, nur wissen)](#f5-bekannte-grenzen-kein-test-ntig-nur-wissen)
  - [G. display-lang: deutscher Buffer, Vorschau in anderer Sprache (mdview + language + ai, Stand 2026-10-06)](#g-display-lang-deutscher-buffer-vorschau-in-anderer-sprache-mdview-language-ai-stand-2026-10-06)
    - [G1. BLOCKER: ohne dich geht es nicht weiter](#g1-blocker-ohne-dich-geht-es-nicht-weiter)
    - [G2. mdview.nvim: `core/mirror` (alle Vorschau-Lesewege)](#g2-mdviewnvim-coremirror-alle-vorschau-lesewege)
    - [G3. ai.nvim: Bulk-Profil `req.bulk`](#g3-ainvim-bulk-profil-reqbulk)
    - [G4. language.nvim: Chunking großer Eingaben](#g4-languagenvim-chunking-groer-eingaben)
    - [G5. `display_lang` selbst (gebaut, live noch nicht geprüft)](#g5-display_lang-selbst-gebaut-live-noch-nicht-geprft)
    - [G6. Bekannte Grenzen (kein Test nötig, nur wissen)](#g6-bekannte-grenzen-kein-test-ntig-nur-wissen)
    - [G7. Nachtrag: neue Befehle, Optionen, APIs und offene Tasks, die du live prüfen oder entscheiden musst](#g7-nachtrag-neue-befehle-optionen-apis-und-offene-tasks-die-du-live-prfen-oder-entscheiden-musst)
  - [H. pickers.nvim: `filegrep` (Dateien nach Pfad und Inhalt, Stand 2026-10-06)](#h-pickersnvim-filegrep-dateien-nach-pfad-und-inhalt-stand-2026-10-06)
    - [H1. Blocker / offene Entscheidungen](#h1-blocker-offene-entscheidungen)
    - [H2. Neue Bindings und Commands](#h2-neue-bindings-und-commands)
    - [H3. Checkliste](#h3-checkliste)
    - [H4. Bekannte Grenzen (kein Test nötig, nur wissen)](#h4-bekannte-grenzen-kein-test-ntig-nur-wissen)
  - [I. hover.nvim: Pins, Auth-Token, Review-Fixes (Stand 2026-10-06)](#i-hovernvim-pins-auth-token-review-fixes-stand-2026-10-06)
    - [I1. Blocker / offene Entscheidungen](#i1-blocker-offene-entscheidungen)
    - [I2. Neue Optionen, Commands, Bindings](#i2-neue-optionen-commands-bindings)
    - [I3. Live-Checkliste Pins](#i3-live-checkliste-pins)
    - [I4. Live-Checkliste Auth (Confluence-Token)](#i4-live-checkliste-auth-confluence-token)
    - [I5. Regression (Änderungen an bestehendem Verhalten)](#i5-regression-nderungen-an-bestehendem-verhalten)
    - [I6. Bekannte Grenzen (kein Test nötig, nur wissen)](#i6-bekannte-grenzen-kein-test-ntig-nur-wissen)
  - [K. casedesk.nvim + ui.nvim: Clipboard, Wordings, Import, Formular-Kit (Stand 2026-10-07)](#k-casedesknvim-uinvim-clipboard-wordings-import-formular-kit-stand-2026-10-07)
    - [K1. Blocker / offene Entscheidungen](#k1-blocker-offene-entscheidungen)
    - [K2. `:Case clipboard`: neue Felder und Wordings](#k2-case-clipboard-neue-felder-und-wordings)
    - [K3. `:Cases clipboard` (ohne Case)](#k3-cases-clipboard-ohne-case)
    - [K4. `:Case import` (früher `:Case copy`)](#k4-case-import-früher-case-copy)
    - [K5. ui.nvim: `kit.form` mit Zurück-Navigation](#k5-uinvim-kitform-mit-zurück-navigation-opt-in-back--true)
    - [K6. ui.nvim: `kit.sheet` (alle Felder in einem Fenster)](#k6-uinvim-kitsheet-alle-felder-in-einem-fenster)
    - [K7. Regression (ui.nvim-Änderungen am Bestandscode)](#k7-regression-uinvim-änderungen-am-bestandscode)
    - [K8. `:Case new [nr] [--form|--steps]`, `config.new_mode`](#k8-case-new-nr---form--steps-confignew_mode)
    - [K9. Wording-Ordner, Log-Snippets, `startCdxChat`](#k9-wording-ordner-log-snippets-startcdxchat)
    - [K10. `:Case insert snow-number|snow-url|sap-number|sap-incident|sap-url`](#k10-case-insert-snow-numbersnow-urlsap-numbersap-incidentsap-url)
    - [K11. `Links.md` in jedem Case](#k11-linksmd-in-jedem-case)
    - [K12. Erstantwort-Checkliste](#k12-erstantwort-checkliste)
    - [K13. Noch nicht gebaut](#k13-noch-nicht-gebaut)
  - [L. terminal.nvim: Terminals, WezTerm/tmux, Status, Navigation (Stand 2026-10-07)](#l-terminalnvim-terminals-weztermtmux-status-navigation-stand-2026-10-07)
    - [L1. Blocker / offene Entscheidungen](#l1-blocker-offene-entscheidungen)
    - [L2. Native Terminals (`<A-h>` und `:Terminal`)](#l2-native-terminals-a-h-und-terminal)
    - [L3. Text und Befehle senden (`send`, `run`)](#l3-text-und-befehle-senden-send-run)
    - [L4. `run --direct` für andere Plugins (lazygit-Fallback)](#l4-run---direct-für-andere-plugins-lazygit-fallback)
    - [L5. Status nach WezTerm (Tab-Titel, Right-Status)](#l5-status-nach-wezterm-tab-titel-right-status)
    - [L6. Navigation über Pane-Grenzen](#l6-navigation-über-pane-grenzen)
    - [L7. `backend = "wezterm"` (Terminals als WezTerm-Panes)](#l7-backend--wezterm-terminals-als-wezterm-panes)
    - [L8. Pin und Adopt](#l8-pin-und-adopt)
    - [L9. tmux (nur wenn Neovim in WSL/tmux läuft; sonst übersprungen)](#l9-tmux-nur-wenn-neovim-in-wsltmux-läuft-sonst-übersprungen)
    - [L10. Live-Skripte (echte Terminals statt Fakes)](#l10-live-skripte-echte-terminals-statt-fakes)
    - [L11. Regression (Änderungen an Bestehendem)](#l11-regression-änderungen-an-bestehendem)
    - [L12. Bekannte Grenzen (kein Test nötig, nur wissen)](#l12-bekannte-grenzen-kein-test-nötig-nur-wissen)
  - [L. casedesk.nvim: Checks aus `NEW.md` — Clipboard, Spotlights, Übersetzer-Policy, KI-Kette (Stand 2026-10-06)](#l-casedesknvim-checks-aus-newmd--clipboard-spotlights-übersetzer-policy-ki-kette-stand-2026-10-06)
    - [L1. Checks für dich (casedesk.nvim)](#l1-checks-für-dich-casedesknvim)
      - [`:Case clipboard`](#case-clipboard)
      - [Spotlights pro Case (`:Case spotlight`)](#spotlights-pro-case-case-spotlight)
      - [Uebersetzer-Policy (`:Case translate`)](#uebersetzer-policy-case-translate)
      - [KI-Kette / Copilot (casedesk-seitig)](#ki-kette--copilot-casedesk-seitig)
    - [L2. Entscheidungen, die schon gefallen sind (zur Kontrolle)](#l2-entscheidungen-die-schon-gefallen-sind-zur-kontrolle)
    - [L3. Bekannte Restpunkte (klein, ohne Handlungsdruck)](#l3-bekannte-restpunkte-klein-ohne-handlungsdruck)
  - [M. casedesk.nvim: Live-Test-Checkliste — alles, was das Plugin kann (Stand 2026-10-02)](#m-casedesknvim-live-test-checkliste--alles-was-das-plugin-kann-stand-2026-10-02)
    - [Vorbereitung](#vorbereitung)
    - [Teil A — neu am 2026-10-02](#teil-a--neu-am-2026-10-02)
      - [A1 · `:Case anonymize`: Telefonnummern und Arbeitszeiten (`50c828d`)](#a1--case-anonymize-telefonnummern-und-arbeitszeiten-50c828d)
      - [A2 · Synonyme für `:Case similar` / `:Cases solutions` (`e466407`)](#a2--synonyme-für-case-similar--cases-solutions-e466407)
      - [A3 · Tosca-Schreibweise bei `:Case ki import` (`df33234`)](#a3--tosca-schreibweise-bei-case-ki-import-df33234)
      - [A4 · Unausgefüllte Templates: `docs-thin` (`4ceb659`)](#a4--unausgefüllte-templates-docs-thin-4ceb659)
      - [A5 · Engine-Steckbrief im Faktenblock (`86d418b`)](#a5--engine-steckbrief-im-faktenblock-86d418b)
      - [A6 · `:Case spotlight` (`165ce12`) — braucht `spotlight.nvim`](#a6--case-spotlight-165ce12--braucht-spotlightnvim)
      - [A7 · Browser-Suche über `lib.nvim.deps` (`432e601`, hover `d17d610`, pdfport `a10c464`)](#a7--browser-suche-über-libnvimdeps-432e601-hover-d17d610-pdfport-a10c464)
      - [A8 · `:Case imp` — Notizen zu Case, Firma, Kontakt (`159d545`, `ba528a7`)](#a8--case-imp--notizen-zu-case-firma-kontakt-159d545-ba528a7)
      - [A9 · `:Case preflight` und Hinweise (`1717d44`)](#a9--case-preflight-und-hinweise-1717d44)
      - [A10 · `:Case image getText` (`7717d0c`) — braucht `images.nvim` + `tesseract`](#a10--case-image-gettext-7717d0c--braucht-imagesnvim--tesseract)
      - [A11 · `:Case translate` — Fix und `stream` (`9f104ba`) — braucht `language.nvim`, Internet](#a11--case-translate--fix-und-stream-9f104ba--braucht-languagenvim-internet)
      - [A12 · `:Case jql suggest` (`10ababe`)](#a12--case-jql-suggest-10ababe)
      - [A13 · Ablage und Doku](#a13--ablage-und-doku)
      - [A14 · `:Cases wordings <kind>`](#a14--cases-wordings-kind)
      - [A15 · `:Case pdf` (`26af2c7`) — braucht `pdftotext` (poppler)](#a15--case-pdf-26af2c7--braucht-pdftotext-poppler)
      - [A16 · Stufe 3 im Überblick (`83cdb3a`, `47dd570`, `8c97c06`, `a131d69`, `b3af13f`, `61607ae`, `07fd742`)](#a16--stufe-3-im-überblick-83cdb3a-47dd570-8c97c06-a131d69-b3af13f-61607ae-07fd742)
    - [Teil B — aus der Vorsitzung (2026-09-30) noch ungetestet](#teil-b--aus-der-vorsitzung-2026-09-30-noch-ungetestet)
    - [Teil C — Smoke-Inventar aller Routen](#teil-c--smoke-inventar-aller-routen)
      - [`:Case` — ein Case](#case--ein-case)
      - [`:Cases` — der Querschnitt](#cases--der-querschnitt)
      - [`:Tricentis` — über den Case-Baum hinaus](#tricentis--über-den-case-baum-hinaus)
    - [Teil D — Keymaps, Autocmds, Health](#teil-d--keymaps-autocmds-health)
    - [Nach dem Durchlauf](#nach-dem-durchlauf)
  - [N. Blocker aller Tasks (Stand 2026-10-07)](#n-blocker-aller-tasks-stand-2026-10-07)
    - [N1. Externe Blocker (kein Task kann sie lösen)](#n1-externe-blocker-kein-task-kann-sie-lösen)
    - [N2. Was auf dich wartet (Entscheidung, Live-Abnahme, Handarbeit)](#n2-was-auf-dich-wartet-entscheidung-live-abnahme-handarbeit)
    - [N3. Wurzel-Blocker: ein Task hält viele andere auf](#n3-wurzel-blocker-ein-task-hält-viele-andere-auf)
    - [N4. Blockaden, die sich selbst erledigt haben oder nicht auflösbar sind](#n4-blockaden-die-sich-selbst-erledigt-haben-oder-nicht-auflösbar-sind)
  - [O. ui.nvim: `ui.slots` (Kern ohne Leiste) — Live-Checks und Blocker (Stand 2026-10-07, Abend)](#o-uinvim-uislots-kern-ohne-leiste--live-checks-und-blocker-stand-2026-10-07-abend)
    - [O1. Blocker](#o1-blocker)
    - [O2. Neue Befehle, Optionen und APIs](#o2-neue-befehle-optionen-und-apis)
    - [O3. Live-Checkliste (ohne Leiste: alles per Befehl und Taste)](#o3-live-checkliste-ohne-leiste-alles-per-befehl-und-taste)
    - [O4. Regression (Änderungen an bestehendem Verhalten)](#o4-regression-änderungen-an-bestehendem-verhalten)
    - [O5. Bekannte Grenzen (kein Test nötig, nur wissen)](#o5-bekannte-grenzen-kein-test-nötig-nur-wissen)
  - [P. docmap-desktop + documentation.nvim: Projektleiste, Suche, Statistik, Auto-Hide, Findings-Regeln — Live-Checks und Blocker (Stand 2026-10-07, Abend)](#p-docmap-desktop--documentationnvim-projektleiste-suche-statistik-auto-hide-findings-regeln--live-checks-und-blocker-stand-2026-10-07-abend)
    - [P1. Blocker und offene Entscheidungen](#p1-blocker-und-offene-entscheidungen)
    - [P2. Neue Bedienelemente und Befehle](#p2-neue-bedienelemente-und-befehle)
    - [P3. Live-Checkliste](#p3-live-checkliste)
    - [P4. Regression (Änderungen an bestehendem Verhalten)](#p4-regression-änderungen-an-bestehendem-verhalten)
    - [P5. Bekannte Grenzen (kein Test nötig, nur wissen)](#p5-bekannte-grenzen-kein-test-nötig-nur-wissen)

---

## Intro

Checks fuer dich aus der Umsetzung von `NEW.md` (die Inbox-Notiz liegt seit dem 7.10. im
wkdbook-Backlog: `casedesk.nvim/Backlog/FEATURES/2026-10-06_inbox-new-clipboard-spotlight-mdview-mirror.md`), die **nicht
direkt casedesk.nvim** betreffen. Die casedesk-Checks stehen in den Abschnitten **K** (neu am 7.10.), **L** (`NEW.md`) und **M**
(komplette Live-Test-Checkliste), **alle Blocker** in **N**, die neuen `ui.slots` (Checks und Blocker, Stand 7.10. abends) in **O**.

---

## A. mdview.nvim (Releases v0.4.0 bis v0.4.3, `install.version = v0.4.3`)

Checkliste im Repo: `TESTS/CHECK.md`.

---

### Spotlight-Spiegelung im Browser

- [ ] Token in Neovim markieren: Treffer erscheinen im Browser innerhalb ~1 s in
      derselben Farbe (Latenz im Dauerbetrieb, bisher nur einmal skriptgesteuert
      geprueft).
- [ ] Entfernen, `clear` und `:Spotlight sets switch` aktualisieren die Ansicht.
- [ ] Colorscheme-Wechsel im laufenden Editor aktualisiert die Farben (auch mit
      `palette.reapply_on_colorscheme = false`).
- [ ] Case-sensitive, Teilstrings ohne Wortgrenzen (Visual-Auswahl) wie in
      Neovim; Treffer in `<code>`/`<pre>`.
- [ ] Zeilenmodus (`line_mode`) hebt Zeile/Block hervor; bei Browsern ohne CSS
      Custom Highlight API greift der `<mark>`-Fallback.
- [ ] Nach jedem Re-Render (Pufferaenderung) sind die Markierungen wieder da;
      neu geoeffneter/neu geladener Tab bekommt sofort den aktuellen Stand.
- [ ] `browser.spotlight_sync = false` bzw. `:MDView spotlight off`: nichts
      wird mehr gesendet (Datenschutz: geteilter Bildschirm/offener Tab).
- [ ] Ohne spotlight.nvim: kein Fehler, nichts passiert.
- [ ] Trefferlimit pro Spotlight bei einem grossen Dokument (Performance).

---

### Relay / Watcher

- [ ] `:MDView standalone <datei>`: Datei in einem Editor speichern, der
      "truncate, dann write" macht; die Vorschau zeigt nie kurz eine leere
      Datei. Aenderungen kommen nach etwa 500 ms (zwei Polls) an.
- [ ] Neues Release v0.4.3 wird beim ersten `:MDView start` heruntergeladen
      (Binary + Client-Bundle, Windows `.exe`), danach keine
      "relay too old"-Warnung mehr bei Spotlights.
- [ ] Mehrere Tabs gleichzeitig: Join waehrend laufender Aenderungen zeigt nie
      einen aelteren Stand nach einem frischen (atomarer Seed).

---

### Bekannte offene Kleinigkeiten

- Reihenfolge zweier sehr schnell aufeinanderfolgender Broadcasts an dieselbe
  Verbindung ist nicht garantiert (parallele HTTP-Handler).
- 13 weitere `src/`-Dateien waren nicht Prettier-clean; inzwischen formatiert
  (`7b791c8`), CI prueft Prettier nicht.
- Windows-CI: `breadcrumbs_spec` kann einmalig in ein Timeout laufen
  (Runner-Flake; `gh run rerun <id> --failed`).

---

## B. spotlight.nvim

- [ ] `:Spotlight`-Verhalten unveraendert im Alltag (Toggle, Sets, Persist).
- [ ] `require("spotlight").spotlights()` / `.colors()` und das
      `User SpotlightChanged`-Event: genau ein gebuendeltes Event pro
      Massenoperation, keines bei "nichts geaendert" (`refresh()`).
- [ ] Wort-Token behaelt seine Art auch mit `match.word_boundaries = false`
      und nach Persist-Roundtrip; alte Snapshots laden weiter.
- [ ] `export()` / `import(items)` / `origin_path(origin)` laut `docs/api.md`.
- [ ] Bei `palette.reapply_on_colorscheme = false` feuert bei ColorScheme kein
      Event (bewusst; mdview hoert selbst auf ColorScheme).
- [ ] Mit nvim 0.9: Link-only-Highlight-Gruppen loesen in `colors()` keine
      Farben auf (Fallback auf Palettenfarben).

---

## C. ai.nvim

### Copilot-Provider (neu, `6b84085`)

- [ ] `:Ai info` und `:checkhealth ai`: Copilot-Block (Installation, Login,
      Credit/Token-Fehlerklassen), Capabilities-Zeile je Provider.
- [ ] Echter Lauf mit harmlosem Prompt ("say ok"): Antwort kommt, Prompt ging
      per stdin (nicht argv), keine Tools, Wegwerf-`COPILOT_HOME` wird nach dem
      Lauf geloescht, dein `~/.copilot` bleibt unberuehrt. Kostet einen
      Premium-Request.
- [ ] `GITHUB_TOKEN` (klassisches `ghp_`) steht in der Umgebung: Provider
      funktioniert trotzdem (Token wird gestrippt); fuer die CLI direkt in der
      Shell die Variable entfernen.
- [ ] Opt-in: ohne Aktivierung kein Copilot-Aufruf.

---

### Command-Key-Quelle (`8b17769`, `eb714c3`, `82a58c7`)

- [ ] Key per Befehl (argv-Liste, kein Shell-String): Key kommt an, taucht nie
      in Logs/Health/Prompts im Klartext auf; Timeout wirkt
      (`timeout_ms` begrenzt auf 1..3600000).
- [ ] Windows: ein `.cmd`/`.bat` als Command wird mit Hinweis auf
      `pwsh -File` abgelehnt (`fetch` und `health`).
- [ ] Key-Datei-Rechte (group/others) werden im Health gemeldet.

---

### Sonstiges

- [ ] `capabilities.web = false` auf allen eingebauten Providern, keine
      Websuche aktiv (siehe Blocker `capabilities-web` in der Casedesk-Datei).
- [ ] `doc/ai.txt` und `docs/configuration.md` entsprechen `DEFAULTS`
      (Vimdoc-/Docs-Specs sind gruen).

---

## D. lib.nvim

- [ ] Usercmd-Composer: variadisches letztes Argument vervollstaendigt ueber
      die deklarierten Slots hinaus und zeigt `...` im Usage (`f0d76b9`);
      bestehende Befehle in anderen Plugins verhalten sich unveraendert.

---

## E. Housekeeping

- [ ] Worktree + Branch `claude/casedesk-roadmap-d5a22b` (komplett in `main`)
      aufraeumen, wenn nicht mehr gebraucht.
- [ ] Worktree + Branch `claude/hover-preview-config-c75234` (hover.nvim, komplett in `main`
      gepusht) aufräumen, wenn nicht mehr gebraucht.
- [ ] Im nvim-Config-Repo liegen fremde, nicht von dieser Arbeit stammende
      Aenderungen (`docs/ROADMAP/00_ROADMAP.md`, `docs/TESTING/en_test.md`);
      im WKDBooks-Repo `language.nvim/Backlog/README.md`. Nicht mitcommittet.

---

## F. KI-Kette casedesk.nvim + ai.nvim (Review und Fixes vom 5./6.10., Stand 2026-10-06)

Alles unten ist offline gegen Fake-CLIs und synthetische Daten geprüft; hier steht, was
nur **live** mit echtem Account, echtem Binary oder echten Daten geht. Sicherheitsregel für
alle Läufe: zuerst mit synthetischen Daten (`:Case ai test`), keine Kundendaten, solange
`ki-datenfreigabe-klaeren` (Antwort der IT) offen ist.

---

### F1. `claude-cli` mit echtem Account (Task `ai.nvim/review-restpunkte`)

Live geprüft am 2026-10-07 mit dem Max-Account (CLI 2.1.292): Antwort und Streaming,
`@pfad` (Datei wird nicht gelesen), `/cost` (geht zum Modell), ungültiger
`ANTHROPIC_API_KEY` in der Umgebung (wird ignoriert), `ANTHROPIC_BASE_URL`-Warnung und
Health-Eintrag. Was bleibt, braucht die Neovim-Oberfläche:

- [ ] Abbruch (Antwortfenster schließen) beendet den Prozess; in casedesk steht "cancelled",
      kein Netzwerkfehler.
- [ ] `:checkhealth ai`: Hinweis bei `apiKeyHelper` bzw. Zugangsdaten im `env`-Block deiner
      CLI-Einstellungen (nur wenn du so etwas konfiguriert hast; hier kam keiner, also
      nichts konfiguriert; zeigt nie den Wert).

---

### F2. Allow-List und Provider-Wahl auf der Workstation

- [ ] `CASEDESK_AI_ALLOWED=copilot,claude` setzen (setup-claude-code.ps1 oder User-Env):
      Statusline zeigt `AI:claude`; `:Case ai` zeigt Allow-List und Quelle.
- [ ] `:Case ai provider gemini` (außerhalb): Rückfrage, Antwort Nein ist vorbelegt; bei Ja
      nur für die Sitzung, Statusline `AI:gemini!`, jeder Send einzeln bestätigt.
- [ ] `:Ai provider auto` auf der eingeschränkten Maschine fragt **nicht** nach.
- [ ] Tippfehler im Config-Schlüssel (`policy = { alowed = {...} }`): Warnung beim Start,
      `:checkhealth ai` meldet es, es ist **nichts** erlaubt (fail-closed).
- [ ] Provider-Id in anderer Schreibweise (`--provider=Claude`, `Copilot`) wird erkannt.

---

### F3. Key-Profile (`:Ai key`)

- [ ] `keys = { claude = { active = "privat", profiles = { privat = {env=...}, firma = {file=...} } } }`
      mit deinem privaten Key und (in ein paar Wochen) dem Firmenzugang.
- [ ] `:Ai key firma` / `:Ai key reset` / `:Ai key` (zeigt nie den Key); Profil ohne Key:
      Anfrage schlägt mit Profilnamen fehl und weicht **nie** auf den Standard-Key aus.
- [ ] Key-Datei mit BOM / als UTF-16 (PowerShell 5.1 `Out-File`) wird gelesen.
- [ ] Ein privater Key auf der Firmen-Workstation mit Kundendaten kann gegen die
      Firmenrichtlinie verstoßen: nur `:Case ai test` mit synthetischen Daten.

---

### F4. casedesk: Senden und Log-Analyse (nur mit freigegebenem Provider)

- [ ] `:Case ai test` pro Provider: kurze synthetische Frage, Antwort, Audit-Zeile in
      `:Case ai log` (nur Metadaten, nie Inhalt).
- [ ] `:Case ki --send --preview`: anonymisierter Prompt wird gespeichert und geöffnet,
      nichts gesendet; Firma, Kontakt, Anhangsnamen, URLs/Hosts, UNC, IP/IPv6/MAC,
      Profilordner (auch mit Leerzeichen) sind maskiert; Bestätigungszeile nennt die Zähler.
- [ ] `:Case ki --send`: Antwortfenster öffnet ohne Fokus-Diebstahl, streamt; "Antwort
      ablegen?" erscheint; abgeschnittene/leere Antwort wird als unvollständig gewarnt.
- [ ] Schließen des Antwortfensters mitten im Stream: eine Audit-Zeile `cancelled`;
      Neovim beenden während eines Sends: Zeile `interrupted`.
- [ ] `:Case ki` (Copy-Weg) mit `--provider=<außerhalb der Allow-List>`: Prompt ist
      anonymisiert, Warnung sagt "WAS anonymized"; mit erlaubtem Provider unverändert.
- [ ] `:Case ki logs` mit echten Tosca-/DEX-Logs (Auswahl mehrerer Dateien, `--preview`
      zuerst): Passwörter, Tokens, Bearer-Header, Connection-Strings, Profilpfade, Hosts,
      deutsche Labels (Passwort/Kennwort), UTF-16-Logs; Labels sind `Log 1`, `Log 2`;
      Auswahl über 50 MB wird vor dem Lesen abgelehnt. Das ist der wichtigste Live-Check,
      weil die Regeln bisher nur gegen synthetische Logs geprüft sind.
- [ ] Doku-Link-Versionen, Zitate und `{facts}` im KI-Prompt wie bisher (`templates/KiPrompt.md`).

---

### F5. Bekannte Grenzen (kein Test nötig, nur wissen)

- Prosa ohne Komma/Semikolon/Doppelpunkt zwischen Programmpfad und relativem Slash-Pfad
  lässt das Konto stehen; NT-Pfade `\Device\Mup\<host>\...` maskieren Host/Konto nicht.
- Zugangsdaten aus Federation-Profilen der CLI werden nicht erkannt (nur dokumentiert).
- Der Erfolgspfad der echten CLI (F1) und der Copilot-Fehlerpfad mitten im Lauf sind
  ungeprüft.

---

## G. display-lang: deutscher Buffer, Vorschau in anderer Sprache (mdview + language + ai, Stand 2026-10-06)

Vorhaben: eine deutsche Datei bleibt im Buffer deutsch, mdview zeigt im Browser die
übersetzte Fassung (ohne KI über DeepL/Google, mit KI über ai.nvim). Plan und Handover:
`ROADMAP/handovers/display-lang_PLAN.md` (Original im Vault:
`wkdbook-myplugins/ALL/ROADMAP/plans/display-lang.md`); Tasks: `list --tag=display-lang`.

**Stand 2026-10-07: `display_lang` ist gebaut** (mdview `3623ba9`, Fixes `acba668`, `cf1d70c`,
`f939466`; language.nvim `translate_markdown` ab `152aade`, Provider `ai` `15dd862`, Fixes bis
`1f82e60`). Hier stehen (G1) die Blocker, die nur du lösen kannst, (G2 bis G4) die Bausteine, und
(G5) die Checks für `display_lang` selbst. Alle drei Bausteine sind per Spec und ultracode-Review geprüft, aber
noch nie in einer echten Sitzung mit echten Schlüsseln und Providern gelaufen. Ein Audit-Lauf
über alle Code-Commits (Bugs, Security, Performance) hat weitere Fixes angestoßen; die
Commit-Stände stehen in den Überschriften und werden hier nachgetragen.

---

### G1. BLOCKER: ohne dich geht es nicht weiter

- [ ] **DeepL-Schlüssel setzen** (`$DEEPL_API_KEY`, Free-Konto reicht). Der Spike konnte keine
      DeepL-Latenz messen (nur Google keyless und ein Fake). Danach messen: Kaltstart eines
      deutschen README (Spike: Google 8 bis 18 s bei 4 parallelen Anfragen, seriell 48 s für 105
      Einheiten) und eine Ein-Absatz-Änderung (Spike: 0,25 bis 0,8 s). Notiz:
      `wkdbook-myplugins/mdview.nvim/Backlog/FEATURES/2026-10-06_display-lang-spike.md`.
- [ ] **Echter KI-Provider für `ai.nvim`** bereitstellen (Claude-Key oder Ollama lokal) und die
      Policy der Workstation klären (`config.policy.allowed`): ohne das lässt sich G3 nicht live
      prüfen, und `language.nvim/translate-ai-provider` kann nicht abgenommen werden.
- [ ] **Entscheidung Google keyless:** der inoffizielle Endpunkt blieb im Spike bei rund 600
      Anfragen ohne HTTP 429, hat aber am 2026-09-03 durchgehend mit 429 geantwortet und lieferte
      am 2026-10-07 nach den Spike- und Testläufen eine **Captcha-Seite** ("Sorry..."); die
      Vorschau blieb dabei korrekt im Original ("61 paragraph(s) could not be translated").
      (`language.nvim/translate-engine-failover`). Als Standard-Engine für `display_lang`
      akzeptabel, oder nur als Fallback hinter DeepL?
- [ ] **Datenschutz-Regel festlegen:** welche Dokumente dürfen an eine Cloud-Engine (DeepL,
      Google, Claude)? Kundendaten nie; Ollama gilt als lokal. Die Regel gehört in die
      Dokumentation von `display_lang`, bevor es gebaut ist.
- [ ] Windows-Besonderheit merken: Platzhalter `⟦n⟧` wurden auf dem curl-Weg zerstört (25 %
      der Einheiten), `{n}` nicht. Beim Bau von `markdown-translate-api` live gegen den echten
      curl-Weg prüfen, nicht nur gegen einen Fake.

---

### G2. mdview.nvim: `core/mirror` (alle Vorschau-Lesewege, `30e4377`; Fixes `f184f10`, `e7b24c2`, `6255d6d`, `e1316f8`, `217f268`)

Alle Stellen, die den Buffer-Text in die Vorschau geben, laufen jetzt über
`lua/mdview/core/mirror.lua`. Das Verhalten soll **unverändert** sein; geprüft wurde nur per Spec.

- [ ] `:MDView start` auf einer Markdown-Datei: Browser zeigt den Inhalt, Tippen aktualisiert
      live (Latenz wie vorher).
- [ ] `browser_behavior = "reuse"` mit zwei Markdown-Dateien: Puffer wechseln, der Tab folgt, der
      Inhalt stimmt; nie der Inhalt des vorherigen Dokuments.
- [ ] Modi `new_tab` und `manual`: wie bisher.
- [ ] Datei, deren Puffer nicht geladen ist (`:MDView start <pfad>` bzw. Wechsel auf einen
      versteckten Puffer): zeigt die Datei von der Platte, nie ein leeres Dokument
      (Fix `e7b24c2`).
- [ ] In-Editor-Vorschau `:MDView preview-tab`: Inhalt stimmt, live synchron.
- [ ] `experimental.line_diff = true`: Zeilen mitten im Dokument einfügen, löschen, Undo/Redo,
      große Blockänderung; die Vorschau bleibt konsistent. Die Diff-Harness-Gegenprobe
      (`docs/diff-harness.md`) wurde beim Umbau **nicht** gefahren.
- [ ] Checkbox im Browser umschalten und Text-Field-Sync: schreibt weiter in den echten Buffer
      (der Rückweg `inbound_poll` liest bewusst nicht über `mirror`).
- [ ] Breadcrumbs (`core/breadcrumbs.lua`, liest nur bis zur Cursorzeile) unverändert.
- [ ] Großes Dokument (rund 5 000 Zeilen): kein spürbarer Mehraufwand beim Tippen
      (der Session-Snapshot-Hash wird jetzt erst beim ersten Lesen berechnet, `6255d6d`).
- [ ] `:MDView start a.md` mit einem **anderen** geladenen Buffer `sub/a.md` (und `a.md` nur auf
      der Platte): zeigt den Inhalt von `./a.md`, nicht den des fremden Buffers
      (`lines_for_path` vergleicht den Pfad jetzt exakt statt als Datei-Muster, `e1316f8`).
      Dateinamen mit `[ ] { } ~ * ? % #` und Leerzeichen gehen ebenfalls. Bekannte Grenze: derselbe
      Buffer unter anderem Basisnamen (Symlink, 8.3-Name) wird beim ersten Push nicht erkannt, dann
      steht der Plattenstand da, bis zum nächsten Edit.
- [ ] Datei mit ungespeicherten Änderungen in einem geladenen Buffer: `:MDView start` zeigt die
      ungespeicherten Änderungen, nicht die Platte.

---

### G3. ai.nvim: Bulk-Profil `req.bulk` (`e91c376`, `336122b`; Audit-Fixes `7785236`, `2b895c7`)

Leitplanken für unbeaufsichtigte Massenanfragen (`docs/bulk.md`). Alles mit Fake-Provider
geprüft, **nichts** gegen einen echten Provider.

- [ ] `require("ai").ask({ prompt = ..., provider = "<name>", bulk = { label = "t", max_chars =
      4000, concurrency = 2 } }, cb)` mit einem echten Provider: Antwort kommt, `res.bulk`
      nennt Provider, Modell, `temperature = 0`, `deterministic`.
- [ ] Provider **außerhalb** der Allow-List: Anfrage scheitert mit klarer Meldung; erst
      `require("ai.policy").grant_bulk("<id>")` erlaubt ihn (einmal je Sitzung);
      `allow_unlisted` an der Anfrage und die Bestätigung bei `:Ai provider` zählen hier
      **nicht**.
- [ ] `max_chars` überschritten: `bulk_limit`, es wird nichts gesendet. `max_total_chars`
      kumulativ je Label; `config.bulk.max_session_chars` über alle Läufe; `0` ist eine Grenze
      wie jede andere und lehnt alles ab; ein Tippfehler im Wert (`"500000"`) lehnt ebenfalls
      ab statt durchzulassen.
- [ ] Abbruch mitten in einer langen Antwort: `handle:kill()` und
      `require("ai.bulk").cancel("<label>")`: der Callback läuft genau einmal mit
      `kind = "cancelled"`. Bekannt: ein schon gesendeter HTTP-Request läuft weiter, nur die
      Antwort wird verworfen (kein Prozess-Handle der nicht-streamenden Provider).
- [ ] `require("ai.bulk").reset("<label>")` während Anfragen laufen, danach `kill()`:
      `usage()` zeigt nie negative Werte (Fix `336122b`).
- [ ] OpenAI-Modell, das nur Temperatur 1 akzeptiert (o-Serie): Fehler mit Hinweis auf
      `bulk.temperature = false`; mit `false` läuft die Anfrage. (Der Hinweis hat keine eigene
      Spec.)
- [ ] `loomai` und `claude-cli`: nehmen keine Temperatur, `res.bulk.deterministic = false`.
- [ ] Ollama lokal mit `temperature = 0`: gleiche Eingabe zweimal ergibt gleiche Ausgabe.
- [ ] Hängender Provider: der Watchdog (`timeout_ms` plus 5 s) beendet die Anfrage mit
      `kind = "timeout"`.
- [ ] Prompt mit NUL-Byte oder falschem Feldtyp (`system = 5`): Fehler kommt als
      `cb(false, invalid_request)`, **keine** Exception aus `ai.ask` (`7785236`). Eine Datei mit
      NUL-Bytes (UTF-16 ohne BOM) als Chunk-Quelle durchlaufen lassen.
- [ ] Provider mit **Command-Key-Quelle** (`:Ai key`-Profil, Befehl statt Datei): `kill()`,
      `cancel(label)` oder Watchdog **während** der Key-Befehl noch läuft: danach geht kein
      Request mit dem Dokumenttext mehr raus. Schlägt der Key-Befehl fehl, läuft er einmal, nicht
      einmal je Job (kein Passwort-Prompt-Sturm, keine Konto-Sperre). Bekannt offen: kurzer
      Negativ-Cache außerhalb der Bulk-Queue (Task `ai.nvim/ai-keys-fehlgeschlagene-command-key-quelle-kurz-negativ-cach`).
- [ ] Lange Queue (mehrere hundert Chunks) mit einem Provider, der sofort fehlschlägt (falscher
      Key): alle Callbacks kommen an, kein Stack-Overflow, das Label ist danach wieder frei
      (`usage(label)` zeigt `active = 0`).
- [ ] `config.bulk.max_session_chars = 0`, ein String (`"500000"`), eine negative Zahl und ein
      Tippfehler-Key unter `bulk`: jeder lehnt Bulk ab (fail-closed), warnt beim Start, steht in
      `:checkhealth ai` und `:Ai info`.
- [ ] `bulk.temperature = false` mit gesetztem `req.temperature`: es wird keine Temperatur
      gesendet, `res.bulk.temperature` meldet das Gesendete.

---

### G4. language.nvim: Chunking großer Eingaben (`a2e0a73`; Audit-Fixes `dd67f2e`, `3198fac`, Tests `e397d0f`, `8304e4b`)

(Die Markdown-API und der Provider `ai` stehen in G5.)

Große Eingaben werden zeilentreu in Blöcke zerlegt (`translate/chunk.lua`), der DeepL-Schlüssel
und der Body gehen über stdin. Geprüft nur mit Fake-Runner und einem lokalen HTTP-Server.

- [ ] `:Translate DE buffer` auf einer Datei **über 32 700 Zeichen** (Google keyless): kein
      `ENAMETOOLONG`, Ergebnis vollständig, Zeilenzahl gleich.
- [ ] Dasselbe mit **DeepL** (Schlüssel gesetzt): Umlaute, Anführungszeichen, Backslashes und
      Tabs kommen unverändert an. **SEC-10 live prüfen:** während des Laufs darf der Schlüssel
      in keiner Prozessliste stehen:
      `Get-CimInstance Win32_Process -Filter "Name like 'curl%'" | Select CommandLine`.
- [ ] translate-shell (`trans`) und eine `custom`-Engine mit großer Eingabe.
- [ ] Datei mit **sehr langen Einzelzeilen** (ein Absatz in einer Zeile, über 5 000 Zeichen)
      und mit Leerzeilen zwischen Absätzen: Zeilen und Leerzeilen bleiben erhalten
      (Task `language.nvim/google-long-line-limit`, Fix `dd67f2e`). Das ist der Fall, der später
      `display_lang` trifft, weil Markdown-Absätze oft in einer Zeile stehen.
- [ ] Fehlerfall mitten im Lauf (Netz trennen oder ungültiger Schlüssel): **eine** klare
      Meldung mit Blocknummer und Zeilenbereich, die Fortschrittsanzeige hängt nicht, der
      Callback läuft nur einmal.
- [ ] Abbruch mitten im Lauf (`:Translate!`-Fenster schließen): weitere Blöcke werden nicht mehr
      gesendet.
- [ ] `translate.max_chars` kleiner setzen: mehr Blöcke; größer setzen: wirkt nicht (nur senken).
      Zeitgrenze: `timeout_ms` gilt **je Block**, die Gesamtdauer kann N-mal so lang sein.
- [ ] `:Translate DE cwd` bzw. `path=<ordner>` mit einer großen und einer unlesbaren Datei: nur
      diese eine Datei scheitert, Fortschritt und die übrigen Dateien laufen weiter.
- [ ] Regression: Hover-Übersetzung, `:TranslateReplace --nocode`, `:Translate!` wie vorher.
- [ ] Windows: Befehle über `.cmd`-Shims (translate-shell) mit Text, der `&`, `%` oder `^`
      enthält, werden abgelehnt statt von `cmd.exe` interpretiert (`3198fac`). Offen als Task:
      `translate-shell-text-via-stdin` (Text per stdin statt argv, `trans` war nicht installiert).
- [ ] Google-Anfrage geht jetzt als POST-Body über stdin (`curl --data-urlencode q@-`): eine
      6 000-Zeichen-Zeile, eine 30 000-Zeichen-Zeile zwischen zwei anderen und eine
      600-Zeichen-Zeile Japanisch (ohne Leerzeichen) kommen vollständig und als **eine** Zeile
      zurück; nur ein einzelnes Token ohne jede Grenze über dem Budget scheitert mit klarer
      Meldung.
- [ ] Datei mit Leerzeilen, Einrückung und Listen und `translate.max_chars = 60`: Zeilenzahl und
      Einrückung bleiben erhalten (live gegen gtx: vorher 10 Zeilen rein, 6 raus).
- [ ] DeepL mit einer Datei über rund 2 500 Zeilen: wird mit klarer Meldung abgelehnt
      (`max_blocks = 50`), nicht stumm abgeschnitten. `translate.custom.max_bytes` hebt das
      Budget einer `custom`-Engine an, die den Text nicht ins argv legt.
- [ ] Bekannt offen (Task `translate-blocks-rate-limit-and-deadline`): Pause zwischen Blöcken
      für den keylosen Google-Endpunkt, Gesamtfrist statt `timeout_ms` je Block; auf einer sehr
      großen Datei einmal beobachten, ob gtx mit 429 antwortet.

---

### G5. `display_lang` selbst (gebaut, live noch nicht geprüft)

Alles ist per Spec, Oracle (echter comrak-Renderer), Fuzz und mehrere unabhängige Reviews geprüft,
aber **live nur mit einer Fake-Engine** (`custom` mit Node-Wörterbuch) gesehen: weder DeepL noch
`ai` noch der Browser-DOM. Die Akzeptanzliste der Live-Abnahme steht in
`ALL/display-lang-live-check` (Plan `ALL/display-lang`); Kurzfassung und Ergänzungen:

- [ ] **Einschalten:** `require("mdview").setup({ browser = { display_lang = "en" } })` oder
      `:MDView lang en`. Der Hinweis beim ersten Mal nennt die Engine, die den Text wirklich
      bekommt (Fallback-Kette beachten). Ohne die Option geht nie Text an einen Dritten.
- [ ] Badge im Browser ("Translating to en via ...", "Translated to en", "Original, translation
      failed"): sichtbar und lesbar; **Tab neu öffnen** nach dem letzten Status: das Badge kommt
      erst beim nächsten fertigen Push (bekannte Lücke). Ältere Clients ignorieren die Nachricht.
- [ ] `:MDView lang` ohne Argument zeigt Sprache, Trigger, Engine und Fortschritt; `refresh`
      übersetzt neu (nötig bei `display_lang_trigger = "manual"`); `off` stellt das Original
      sofort wieder her, **auch wenn der Fokus in einem Scratch-/Lua-Buffer liegt** und bei
      mehreren Dokumenten (`new_tab`: kann zusätzliche Engine-Anfragen auslösen).
- [ ] Trigger `idle` (800 ms), `save`, `manual`; schnelle Edits: die Übersetzung bleibt um die
      Editstelle stehen, geänderte Zeilen zeigen das Original bis zur Pause. Edits an Fences,
      `$`, Kommentaren, Überschriften und Front Matter laufen über einen vollen Parse
      (Anker-Links!). Bekannt: bei mehrzeiligen Absätzen kurz gemischtsprachig.
- [ ] **Großes Dokument** (5 000 und 20 000 Zeilen): Tippen bleibt flüssig; Wechsel/Speichern
      blockiert ca. 0,3 s bei 20k Zeilen (Cache-Parse); 40 000+ Zeilen frieren die Aufbereitung
      bis ca. 1 bis 2 s ein (Task `markdown-translate-hauptthread-rechnet-...`).
- [ ] Rückwege: Text-Field-Sync ist in der Übersetzung aus (einmalige Meldung); Checkbox im
      Browser schreibt nur den Marker in die echte Zeile; Scroll-Sync, Klick-Navigation und
      Cursor-Marker treffen die richtige Zeile.
- [ ] `:checkhealth mdview` (Abschnitt "display language": language.nvim gefunden bzw. zu alt,
      Engine verfügbar, Schlüssel gesetzt) und `:checkhealth language` (Provider `ai`, Modell,
      Allow-List, Bulk-Freigaben).
- [ ] Engine `ai` ist konfiguriert, aber nicht nutzbar (ai.nvim fehlt, `ai.bulk` fehlt, Provider
      nicht freigegeben): die Vorschau bleibt Original, es gibt **keinen** stillen Rückfall auf
      Google/DeepL.
- [ ] Anker-Links im README: `[siehe](#einrichtung)` springt nach der Übersetzung zur richtigen
      Überschrift (Spike: 16 von 18 brachen ohne Slug-Mapping). Zwei Überschriften mit gleichem
      Slug nach der Übersetzung: mdview kennt kein `-1` (Task `anker-kollisionen`).
- [ ] Echte Übersetzung eines deutschen README mit DeepL **und** mit `ai` (Claude, Ollama):
      Zeilenzahl gleich, Code byteidentisch, Tabellen und Listen intakt; Ablehnungen durch die
      Link-/URL-Validierung treten praktisch nie auf (gemessen 0 auf 351 000 Einheiten mit
      einer Fake-Engine): bei echter KI beobachten, ob Einheiten unübersetzt bleiben
      (`info.skipped`/`failed` im Log).

- [ ] `language.nvim/markdown-translate-api`: deutsches README (Tabelle, Fences, Inline-Code,
      Anker-Links, Front-Matter) mit **echtem DeepL**: Zeilenzahl gleich, Code byteidentisch,
      Platzhalter vollständig, Anker-Links springen zur richtigen Überschrift (Spike: 16 von 18
      Anker brechen ohne Slug-Mapping).
- [ ] `mdview.nvim/display-lang`: `:MDView lang en` zeigt die englische Fassung; Scroll-Sync,
      Cursor-Marker, Click-to-navigate und Checkbox treffen die richtige Zeile; Änderung eines
      Absatzes erscheint nach der Pause übersetzt, der Rest kommt aus dem Cache (im Log kein
      neuer Provider-Aufruf); `:MDView lang off` stellt das Original sofort wieder her.
- [ ] Fehlerpfade: ohne Netz, ohne Schlüssel, Provider außerhalb der Policy, Abbruch mitten im
      Lauf: die Vorschau bleibt im Original und meldet es einmal.
- [ ] Puffer- und Tab-Wechsel im "reuse"-Modus zeigt nie die Übersetzung des vorherigen Dokuments.
- [ ] `language.nvim/translate-ai-provider`: Claude und Ollama mit derselben Fixture,
      Struktur unverändert, Rückfall bei absichtlich kaputter Antwort; Cache-Schlüssel enthält
      das Modell (Modellwechsel liefert keine alten Texte).
- [ ] Standalone-Modus weist `display_lang` mit klarer Meldung zurück.

---

### G6. Bekannte Grenzen (kein Test nötig, nur wissen)

- Standalone-Modus (`mdview-server --watch`), mehrere Tabs mit verschiedenen Sprachen und das
  Zurückschreiben aus der Vorschau in die Übersetzung sind **nicht** vorgesehen.
- Spaltengenaue Spiegelungen (Selection-Mirror, Spotlight-Token) im übersetzten Text gibt es nur
  zeilengenau; die deutschen Token stehen im englischen Text nicht.
- `kill()` bei `req.bulk` verwirft nur die Antwort eines schon gesendeten Requests.
- DeepL-Latenz und KI-Qualität sind bis zur Erledigung von G1 ungemessen.
- `:MDView preview-tab` (in-Editor-Vorschau) und ein gepinnter Preview werden **nicht** übersetzt;
  `:MDView standalone` verweigert den Start, solange `display_lang` oder `transform` gesetzt ist
  (Warnen und Weitermachen wäre eine kleine Änderung in `usrcmds/standalone.lua`).
- Ein neu geöffneter HTML-Block (`<div>`) kann beim Tippen kurz fremde Zeilen als Rohtext zeigen.
- Inhaltspushes pro Raum sind nicht serialisiert (curl-Reihenfolge, Task angelegt); ein Patch kurz
  vor dem Endstand könnte theoretisch vertauscht ankommen, im Live-Lauf nie beobachtet.
- Der Bulk-Label des `ai`-Providers ist ein 5-Sekunden-Fenster (zwei Dokumente kurz hintereinander
  teilen `max_total_chars`); der Session-Cap von `ai.nvim` ist davon nicht betroffen.
- Ein Modellwechsel mitten im Request kann einen Cache-Eintrag unter dem neuen Modell ablegen.
- Der Guard in `mirror_guard_spec` erkennt nicht jeden Leseweg (zum Beispiel `pcall(io.open, ...)`);
  Task `mdview.nvim/mirror-guard-denylist-hardening`.

---

---

## H. pickers.nvim: `filegrep` (Dateien nach Pfad und Inhalt, Stand 2026-10-06)

Neue Action `filegrep`: ein Files-Picker, dessen Prompt zusätzlich `grep=<pattern>`
versteht. `akronyms grep=NWBC` listet Dateien, deren **Pfad** `akronyms` enthält und
deren **Inhalt** `NWBC` enthält. Mehrere `grep=` verknüpfen per UND, `grep="a b"` erlaubt
Leerzeichen, ohne brauchbares `grep=` (unter 2 Zeichen wird ignoriert) ist es ein normaler
Files-Picker. Soll eine Zeit lang als neuer Haupt-Picker getestet werden.

Commits (pickers.nvim, `main`): `daf2b47` (Feature), `b2d09c3` (Review-Fixes),
`4eff444` (`:FileGrep`), `351269f` (Collections, Cheatsheet). nvim-Config: `c42bbedb`,
`0fe7a7d7`. Doku: `docs/commands.md#the-filegrep-action`. Geprüft nur headless
(1032 Checks, echte `fd`/`rg`-Läufe gegen ein Repo), **noch nie in einem echten Picker-Fenster**.

---

### H1. Blocker / offene Entscheidungen

Kein harter Blocker. Entscheidungen, die du beim Testen treffen musst:

- [ ] **Pfad-Matching: Substring oder Fuzzy?** Aktuell: Substring zuerst, schwacher
      Subsequence-Fallback (`pickers.smart.score.match`). Die Frage war offen, ich bin vom
      Default ausgegangen. Wenn es stört: kleine Änderung in `filegrep.score_path`.
- [ ] **`<leader><leader>` auf filegrep legen?** Dort liegt aktuell `cwd_grep`
      (`navigate.lua`, `mappings`). Erst nach der Testphase umlegen.
- [ ] **Performance auf großen Repos.** Stand nach den Review-Runden: warme Abfrage
      0,2 bis 0,5 ms (Cache, einmal kleingeschriebene Pfade, nur die besten `limit`
      Zeilen werden sortiert). Offen bleibt ein **1-Zeichen-Pfadwort** bei ~100 000 Dateien
      (ca. 100 ms pro Taste, fast alle Pfade matchen per Subsequence). Wenn es zäh ist:
      Prefix-Reuse (nur die Treffer des vorigen Wortes neu bewerten) oder asynchroner `rg`.
- [x] **Prompt-Titel** zeigt jetzt das Scope-Label (`CWD grep=> `) und das Tab-Suffix wie
      bei `files` (erledigt in der Review-Runde, `actions/filegrep.lua`).

---

### H2. Neue Bindings und Commands

| Eintrag | Wirkung | Wo |
|---|---|---|
| `<leader>mp` | `:Pickers cwd filegrep` | `navigate.lua`, `keymaps.cwd_filegrep` |
| `<leader>mC` | `:Pickers config filegrep` | `navigate.lua`, `mappings.config_filegrep` |
| `<leader>mF` | `:Pickers folder filegrep` (Ordner wählen) | `navigate.lua`, `mappings.folder_filegrep` |
| `:FileGrep [query]` | cwd, Query belegt den Prompt vor | pickers.nvim |
| `:FileGrepConfig [query]` | nvim-Config, Query vorbelegt | pickers.nvim |
| `:Pickers <scope> filegrep` | jeder Scope und jede Collection, mit Tab-Completion | pickers.nvim |
| `:{Name}FileGrep [query]`, `keys.filegrep` | pro Collection (z. B. `:NotesFileGrep`) | pickers.nvim, `keys.filegrep` ist **nirgends gesetzt** |
| `mappings.<scope>_filegrep` | deklarativ, beliebiger Scope | pickers.nvim |

Hinweis: `<leader>mc` ist in den neo-tree-Keymaps als `noop` belegt, deshalb `<leader>mC`.
`<leader>mp` ist Präfix-frei gehalten (kein `<leader>mpc`), damit nichts auf Timeout wartet.

---

### H3. Checkliste

Nach Neustart von nvim:

- [ ] `<leader>mp`: Picker öffnet mit Prompt `Files grep=> `; leerer Prompt zeigt die Dateien
      des CWD.
- [ ] `akronyms` (nur Pfad): Liste wird auf Pfade mit `akronyms` eingegrenzt, wie `<leader>ff`.
- [ ] `akronyms grep=NWBC`: nur Dateien mit `akronyms` im Pfad **und** `NWBC` im Inhalt;
      Zeilen zeigen `pfad:zeile: text`; `<CR>` öffnet an der Fundstelle.
- [ ] `grep=NWBC grep=TODO`: nur Dateien mit **beiden** Mustern.
- [ ] `grep="foo bar" cfg`: Leerzeichen im Muster, Pfadwort `cfg` zusätzlich.
- [ ] `grep=N` (1 Zeichen) löst keinen `rg`-Lauf aus (Liste bleibt die Pfadliste), ab 2 Zeichen
      greift der Filter.
- [ ] Ungültiger Regex beim Tippen (`grep=(`): keine Fehlerflut, Liste bleibt bedienbar.
- [ ] Eine Datei, in der das Muster mehrfach in einer Zeile steht, erscheint **einmal**
      (Fix `b2d09c3`).
- [ ] Pfadteil nach gesetztem `grep=` ändern: Liste aktualisiert sich sofort (Cache, kein
      neuer `rg`-Lauf, ca. 5 s gültig).
- [ ] Neue Datei anlegen, die das Muster enthält, und innerhalb von 5 s erneut suchen: Cache
      kann sie noch nicht kennen (erwartet), danach erscheint sie.
- [ ] Alle drei Engines prüfen (`engine` pro Mapping pinnbar): **snacks** (deine Standard-
      Engine), **telescope**, **fzf-lua** (braucht fzf >= 0.45, Lua-Funktions-Live-Modus).
- [ ] Tab-Wechsel (`tabs`) mit Ziel `cwd filegrep` in einer Gruppe: Query wandert mit.
- [ ] `<leader>mC` und `<leader>mF` öffnen im jeweiligen Scope.
- [ ] `:FileGrep akronyms grep=NWBC` startet mit vorbelegtem Prompt.
- [ ] `:FileGrepConfig`, `:Pickers cwd filegrep`, `:Pickers cwd <Tab>` bietet `filegrep` an.
- [ ] `:PickersRepeat` nach einem filegrep-Lauf öffnet ihn erneut (Scope und Action).
- [ ] Which-Key zeigt die Einträge mit ihrer Beschreibung; `<leader>mp` kollidiert nicht mit
      anderen `<leader>m`-Belegungen (`:verbose map <leader>m`).
- [ ] Großes Repo (z. B. `E:\repos` als CWD): Antwortzeit pro Tastendruck erträglich?
      Notieren, ab wann es zäh wird (siehe H1, Performance).
- [ ] Regression: `<leader>ff`, `<leader><leader>` (cwd_grep), `cwd_smart` (`<leader>CW`)
      verhalten sich wie vorher.

---

### H4. Bekannte Grenzen (kein Test nötig, nur wissen)

- Ohne `grep=` rankt filegrep mit dem einfachen `smart`-Scorer, **nicht** mit dem nativen
  Fuzzy-Matcher der Engine, und zeigt höchstens `smart.limit` (2000) Zeilen.
- Ein Treffer pro Datei (erste Fundstelle); weitere Treffer derselben Datei werden nicht
  aufgelistet. Dafür ist die `grep`-Action zuständig.
- Das `grep=`-Muster ist ein ripgrep-Regex mit smart-case; `additional_args` und
  `find.exclude` der Quelle gelten auch hier.
- `rg` und `fd` laufen synchron auf dem Hauptthread (Timeout `smart.timeout`, 3000 ms; das
  Timeout begrenzt einen Stall nur so weit, wie das OS das Beenden zustellt). Ein per
  Timeout beendeter Lauf zeigt seine Teiltreffer plus eine Warnung (höchstens alle 10 s) und
  wird einige Sekunden gemerkt, damit der nächste Tastendruck nicht erneut blockiert; nur ein
  nicht startbarer Prozess wird sofort wiederholt.
- Weitere `grep=`-Muster durchsuchen nur die Treffer des ersten (in bis zu 8 Befehlszeilen,
  sonst ein Baum-Scan). Bricht ein Muster ab (Timeout, Regex-Fehler), werden die späteren
  nicht mehr angewendet; die Warnung sagt es.
- Ist `rg` ein `.cmd`/`.bat`-Shim, wird ein Muster mit `& | < > ^ % !` oder `"` abgelehnt
  (cmd.exe würde es interpretieren); `rg.exe` verwenden. Gilt auch für die smart-Action.
- Ein nach der Installation von fd/rg gestarteter Picker findet das Tool binnen 30 s
  (nicht erst nach Neustart).
- Mehrere Wurzeln (`roots`) werden nacheinander durchsucht; auf fzf-lua erscheinen Pfade aus
  Nebenwurzeln absolut (Windows-Laufwerksdoppelpunkt vs. `datei:zeile`-Format).
- Keine neuen Engine-Adapter: filegrep nutzt die `smart`-Live-Picker mit `opts.core`.

---

## I. hover.nvim: Pins, Auth-Token, Review-Fixes (Stand 2026-10-06)

Zwei neue Optionen für Links, die im Hover ein SSO-Login statt Inhalt zeigen (Confluence,
Jira und andere Tricentis-Seiten): `links.pins` (Link als eigene PDF/PNG zeigen) und
`links.auth` (Token für Fetch und PDF-Download). Persönliche Anleitung mit allen Hosts:
`docs/NOTES/Hover_Login-Seiten_Confluence_Tricentis.md`. Repo-Doku:
`hover.nvim/docs/WORKFLOW-LOGIN-PAGES.md`, `docs/FEATURES/PINS.md`, `AUTH.md`.

Commits (hover.nvim, `main`): `de23de6` (Pins), `12d9843` (Auth), `49d809d` (Workflow-Doku),
`311803e` (Fixes Review Runde 1), `d78ce52` (Fixes Review Runde 2). nvim-Config: `2c6badc4`
(Notiz). Geprüft: 706 Specs grün, stylua/luacheck sauber, jeder Fix einzeln per Mutation
gegen seinen Spec geprüft. **`d78ce52` wurde nicht mehr von einem Agenten reviewt** (auf
deinen Wunsch keine Runde 3). **Noch nie gegen dein echtes Confluence gelaufen.**

---

### I1. Blocker / offene Entscheidungen

- [ ] **BLOCKER Auth: deine Atlassian-Mail eintragen.** In der Notiz steht
      `DEINE-ATLASSIAN-MAIL`; ich kenne die Mail deines Atlassian-Kontos nicht (nicht
      zwingend `stefan.bartl.work@gmail.com`). Ohne sie gibt es kein Basic-Auth.
- [ ] **BLOCKER Auth: Token als Umgebungsvariable.** `setx CONFLUENCE_TOKEN "<token>"`,
      danach **Terminal und Neovim neu starten** (laufende Sitzung behält ihre alte
      Umgebung). Den Token nie in Config, Repo oder Chat. Token läuft irgendwann ab
      (`HTTP 401` im Float), dann neu erzeugen.
- [ ] **BLOCKER Auth: Export-URL testen, bevor etwas konfiguriert wird.** Ungeprüft, ob euer
      Confluence den PDF-Export mit Token liefert:
      `curl.exe -sS -o NUL -w "%{http_code} %{content_type}\n" -u "MAIL:$env:CONFLUENCE_TOKEN" "https://tricentis.atlassian.net/wiki/spaces/flyingpdf/pdfpageexport.action?pageId=ID"`.
      `200 application/pdf` heißt: Auth funktioniert für Exporte. Sonst bleiben nur Pins.
- [ ] **Config eintragen.** Ich habe `navigate.lua` (Spec `StefanBartl/hover.nvim`, ab
      Zeile ~234) **nicht** geändert. Fertiger `links`-Block steht in der Notiz.
- [ ] **Neovim neu starten**, damit der neue Plugin-Code geladen wird (Plugin liegt lokal in
      `E:/repos/hover.nvim`, `package.loaded` hält den alten Stand).
- [ ] **Entscheidung: persistentes Browser-Profil (`:Hover login`)?** Nicht gebaut. Wäre der
      Weg, um eine eingeloggte Seite als Bild im Hover zu rendern (Kosten: Sitzung läuft ab,
      privater Seiteninhalt im Cache). Erst entscheiden, wenn Pins zu mühsam werden.
- [ ] **Entscheidung: Export-URL automatisch ableiten?** Aus einer normalen Confluence-
      Seiten-URL die PDF-Export-URL bauen, damit nichts umgeschrieben werden muss. Erst sinnvoll,
      wenn der `curl.exe`-Test oben `200 application/pdf` liefert.
- [ ] **Sicherheitsvorfall prüfen:** ein Review-Agent hat mit `taskkill /F /IM nvim.exe` **alle**
      Neovim-Prozesse beendet. Falls du offene Sitzungen mit ungespeicherten Änderungen hattest,
      Buffer/Swapfiles prüfen. Gegenmaßnahme steht im Memory (`review-agents-never-kill-processes`).
- [ ] Optional: Review Runde 3 für `d78ce52` (Auth-Pfadnormalisierung, bare_url-Cap).

---

### I2. Neue Optionen, Commands, Bindings

**Keine neuen Keybindings, keine neuen User-Commands.** Alles läuft über Config.

| Eintrag | Wirkung | Wo |
|---|---|---|
| `links.pins = { { match = "host/pfad/*", show = "~/x.pdf" } }` | Link wird als diese Datei gezeigt (PDF blättern/zoomen, Bild croppen) | `setup()` von hover.nvim |
| `links.auth = { { match = "tricentis.atlassian.net", user = "MAIL", token_env = "CONFLUENCE_TOKEN" } }` | Basic-Auth (mit `user`) bzw. Bearer (ohne) für Fetch und PDF-Download | `setup()` von hover.nvim |
| `:Hover why` | nennt jetzt `pinned: ...`, und bei gelöschtem Pin den Typ, nach dem das Gate fragt | bestehend, neu |
| `<CR>` im Hover-Float | öffnet bei einem Pin die **echte URL** (nicht die Datei) | bestehend, neu |
| `:checkhealth hover` | meldet Pins (Anzahl, fehlende Dateien) und Auth-Regeln (Variable gesetzt ja/nein, nie der Wert) | bestehend, neu |
| `require("hover.pins").matches(url, glob)` | Glob vorab testen (strikt; Pins nutzen intern `ignore_port`) | Lua |

Voraussetzung für Auth: `links.web = true`, `links.fetch = true`, `links.pdf = { enabled = true }`
(sonst tut `auth` nichts, Health sagt es). Pins brauchen keinen Schalter und gehen auch mit
`links.web = false`.

---

### I3. Live-Checkliste Pins

- [ ] Eine Confluence-Seite eingeloggt als PDF drucken (`Strg+P`), **außerhalb jedes Repos**
      ablegen (z. B. `C:\Users\bartl\hover-pins\`), Pin eintragen, Neovim neu starten.
- [ ] Link-URL im Markdown/Text hovern: PDF erscheint (erste Seite), `<C-Down>`/`<C-Up>`
      blättern, `>` zoomt, `F` Vollbild.
- [ ] Pin mit `links.web = false`: funktioniert trotzdem (nichts geht ins Netz).
- [ ] Pin als PNG (DevTools-Screenshot): Bild wird gezeigt, `>` croppt.
- [ ] Glob-Varianten: nur Host (`tricentis.atlassian.net`), mit Pfad (`.../pages/ID*`), Liste
      von Globs, erster Treffer gewinnt (spezifisch vor allgemein).
- [ ] Link mit Port (z. B. `:8090`): Pin trifft, wenn der Glob keinen Port nennt.
- [ ] Datei umbenennen/löschen: Float sagt `pinned file not found (links.pins: ...)` (bei
      PDF/Bild auch beim automatischen Hovern), nicht die Login-Seite;
      `:checkhealth hover` listet den Pin.
- [ ] `<CR>` im Pin-Float öffnet die **echte URL** im Browser (mit `$` oder `?` in der URL).
- [ ] `:Hover why` auf dem Link: zeigt `pinned: ...`.
- [ ] Ungepinnte URL mit `links.web = false` und konfigurierten Pins: verhält sich wie vorher
      (keine Flicker, Positions-Previews antworten weiter).
- [ ] `links.enabled = false` mit Pin: kein automatisches Hovern; `:Hover show` geht.
- [ ] Pin auf `.md`/`.docx`: öffnet nur mit `:Hover show` (nur `pdf`/`image` automatisch).
- [ ] Zweites `setup()` mit kürzerer Pin-Liste: alte Pins sind weg (Liste ersetzt, nicht gemischt).
- [ ] UNC-Pfad als `show` (`\\\\server\\share\\x.pdf`) und `#` im Dateinamen funktionieren.

---

### I4. Live-Checkliste Auth (Confluence-Token)

Erst nach den Blockern aus I1. **Nur mit synthetischen/öffentlichen Seiten, keine Kundendaten.**

- [ ] `:checkhealth hover`: `links.auth: 1 rule(s)`, **keine** Warnung `$CONFLUENCE_TOKEN is not
      set`, Token-Wert taucht nirgends auf.
- [ ] Link auf einen Confluence-PDF-Export (oder Anhang-PDF) hovern: erste Seite erscheint,
      Blättern/Zoom gehen. `HTTP 401` im Float heißt: Mail/Token/Rechte falsch.
- [ ] **Token nicht in der Prozessliste** während des Downloads:
      `Get-CimInstance Win32_Process -Filter "Name like 'curl%'" | Select CommandLine`
      (darf weder Token noch `Authorization` zeigen).
- [ ] Normale Confluence-**Seiten**-URL hovern: erwartbar weiter Login/JS-Shell (Auth macht
      Seiten nicht lesbar, nur Dokumente). Für Seiten Pin verwenden.
- [ ] Rule mit `*.atlassian.net` in der Config: wird **abgelehnt** (Health warnt, nichts wird
      gesendet), nicht stillschweigend akzeptiert.
- [ ] Token-Variable absichtlich leer/unset: es wird nichts gesendet, Health meldet `is not
      set`.
- [ ] Token mit Zeilenumbruch (aus Datei gelesen) wird getrimmt; mit Steuerzeichen mittendrin
      zählt er als nicht gesetzt.
- [ ] Link mit `[` `]` oder `{` `}` in der URL: genau ein Request (`--globoff`).
- [ ] Zweite Regel mit **eigener** Variable für einen anderen Host; Allow der Reihenfolge
      (erste passende Regel entscheidet, auch bei leerer Variable).
- [ ] Heruntergeladene Auth-PDFs liegen in `stdpath("cache")/hover.nvim/webpdf` (bis zu
      `cache_days`, Standard 7; `0` = nie aufräumen!). Bei Bedarf `cache_days = 1` setzen oder
      Ordner löschen. Unter Windows keine 0700-Rechte (gelten nur auf Linux/macOS/CI).
- [ ] Nach Token-Ablauf oder Widerruf: `HTTP 401`, kein Absturz.

---

### I5. Regression (Änderungen an bestehendem Verhalten)

Im Rahmen der Review-Fixes wurde Bestehendes angefasst; bitte im Alltag beobachten:

- [ ] **Bare-URL-Erkennung** (`bare_url.under_cursor`) scannt nur noch das Token unter dem
      Cursor (Whitespace/Quotes/`<>`/`|`/Backtick begrenzen). URLs bis 8192 Bytes werden
      gefunden, längere nicht (vorher jede Länge, aber mit Sekunden-Hängern). Bei Web an: URLs
      in Logs, Markdown, Kommentaren, Zeilen mit Umlauten normal hovern.
- [ ] **`classify`** wurde refaktoriert (`classify.file`, `classify.kind_for_ext`): lokale
      Links (Dateien, Ordner, Bilder, PDF, Office, Video, Anker `#`, fehlende Datei) wie vorher.
- [ ] **Fetch/PDF-Requests** haben jetzt immer `--globoff` (Klammern in URLs werden nicht mehr
      von curl expandiert). Wirkt auch für Nutzer ohne Auth.
- [ ] `:Hover why` Meldungen und der Float-Titel für gelöschte Ziele unverändert (`broken link`).
- [ ] `:Hover links web on/fetch/pdf/shot` Schalter und `:Hover dashboard` zeigen keine neuen
      Einträge für `pins`/`auth` als Schalter (sind Listen, keine Switches).
- [ ] Nach Neustart: keine Fehler in `:messages`/`:checkhealth hover`, sonst Config-Block
      prüfen (`links.pins`/`links.auth` müssen **Listen von Tabellen** sein).

---

### I6. Bekannte Grenzen (kein Test nötig, nur wissen)

- Auth macht Confluence-/Jira-**Seiten** nicht lesbar (JavaScript-App, auch mit Token); nur
  Links, die direkt ein Dokument liefern. `links.shot` (Browser-Render) bekommt bewusst nie
  einen Token und zeigt weiter das Login.
- Ein **Pin aktualisiert sich nicht**; ändert sich die Seite, Datei neu erzeugen.
- Auth-Regeln: Port gehört zum Host (`wiki.acme.com` deckt nicht `:8090` ab; Pins ignorieren
  einen nicht genannten Port). Pfad-Scope wird gegen den von curl gesendeten (aufgelösten)
  Pfad geprüft. Eine Weiterleitung auf demselben Host, die im Scope **beginnt**, kann den
  Token außerhalb des Pfad-Scopes mitnehmen (dokumentiert, nicht abgestellt).
- Nur URLs mit Host (`scheme://host`) können gepinnt werden (`mailto:`/`tel:` nicht).
- Cookie-Übernahme aus dem Browser, Login im Hover und OAuth-Tokens (SharePoint/M365) sind nicht
  vorgesehen; dafür Pins oder `<CR>`.
- Andere Tricentis-Hosts (Support-Hub, Kunden-Tenants `*.my.tricentis.com`, Horizon, SharePoint,
  ServiceNow) haben keinen statischen Token: Pins. Tabelle in der Notiz.
- Der Rechte-Spec für das 0700-Cache-Verzeichnis ist unter Windows `pending` (greift in CI).

### G7. Nachtrag: neue Befehle, Optionen, APIs und offene Tasks, die du live prüfen oder entscheiden musst

Alles, was dieser Chat neu hinzugefügt hat und das eine Tastatur-, Config- oder Live-Prüfung
braucht (Bindings und Usercommands gibt es genau einen neuen; der Rest sind Optionen und APIs).

**Neue Usercommands und Bindings**

- [ ] `:MDView lang <code>|off|refresh` (mdview.nvim): Tab-Completion der Sprachcodes, Aufruf ohne
      Argument zeigt den Zustand. Es gibt **kein** neues Keymap und keinen neuen Autocmd-Eintrag
      für den Nutzer; `docs/BINDINGS.md` der Config hat keine MDView-Subcommand-Liste und blieb
      unverändert. Kontrollieren, ob du ein Keymap dafür willst (zum Beispiel Umschalten
      `en`/`off`); dann wäre das eine neue Task.

**Neue Optionen (setup)**

- [ ] mdview `browser`: `display_lang` (Standard aus), `display_lang_trigger` (`idle`|`save`|`manual`),
      `display_lang_debounce_ms` (800), `display_lang_source`, `display_lang_engine`, `transform`
      (async-Hook `function(lines, ctx, cb)`, `ctx.final` unterscheidet Patch und Endstand). Eine
      ungültige Angabe (`display_lang = 5`, `trigger = "x"`) muss beim Setup gewarnt werden.
- [ ] language.nvim: `translate.markdown = { concurrency, max_chars, disk_cache, cache_max_kb,
      cache_dir, keep }`, `translate.max_chars` (senkt das Provider-Limit, hebt es nie),
      `translate.custom.max_bytes`, `translate.ai = { provider, model, glossary, style, max_chars,
      concurrency, max_total_chars }`. Der Plattencache liegt in
      `stdpath("cache")/language.nvim/translate_markdown.json`: nach einem Lauf vorhanden, beim
      Löschen der Datei kein Fehler, `translate_markdown_clear_cache({ disk = true })` leert ihn.
- [ ] ai.nvim: `config.bulk.max_session_chars` (fail-closed), `req.bulk`, `req.temperature`
      (claude, openai, gemini, ollama), `ai.bulk.cancel|usage|reset`, `ai.policy().bulk_granted`,
      `policy.grant_bulk(id)`; `:Ai info` zeigt Bulk-Freigaben und Provider-Capabilities.

**Neue Funktionen für andere Plugins (nur Entwickler)**

- [ ] `require("language").translate_markdown(lines, opts, cb)` und `translate_markdown_clear_cache`:
      aus einer Lua-Konsole mit einem kleinen deutschen Dokument aufrufen (`:lua`, mit
      `opts = { target = "EN", engine = "deepl" }`): `cb(true, lines, info)`, gleiche Zeilenzahl,
      `info.cached` beim zweiten Aufruf = `info.units`.
- [ ] Entwicklerwerkzeug `language.nvim/scripts/markdown_oracle.{lua,mjs}`: nach jeder Änderung am
      Segmenter über einige hundert echte Dateien laufen lassen (braucht den Checkout
      `mdview.nvim`); steht in `TESTS/README.md`.

**Offene Tasks, bei denen du etwas live tun oder entscheiden musst**

- [ ] `language.nvim/translate-markdown-deepl-mit-echtem-schluessel-messen-platzh`: DeepL-Key setzen und
      messen (Platzhalter `{n}`, Batch-Latenz, ob `tag_handling` nötig ist). Ergebnis in die Task.
- [ ] `language.nvim/nicht-ascii-text-im-argv-unter-windows-curl-bekommt-ansi-sta` (Bug): unter Windows
      mit einer `custom`- oder `shell`-Engine, die den Text im argv bekommt, Umlaute übersetzen
      (`ü` kam als `%FC` an). Prüfen, ob dich das betrifft; Google und DeepL senden per stdin und
      sind nicht betroffen.
- [ ] `language.nvim/translate-shell-text-via-stdin`: braucht ein installiertes `trans`
      (translate-shell), sonst nicht prüfbar. Entscheiden, ob die `shell`-Engine Text per stdin
      senden soll.
- [ ] `language.nvim/translate-blocks-rate-limit-and-deadline` und `translate-engine-failover`
      (Entscheidung): Google keyless liefert inzwischen ein Captcha. Soll ein gescheiterter Aufruf
      in der Fallback-Kette weiterlaufen, und braucht es eine Pause zwischen Blöcken und eine
      Gesamtfrist statt `timeout_ms` je Block?
- [ ] `ai.nvim/ai-keys-fehlgeschlagene-command-key-quelle-kurz-negativ-cach` (Entscheidung): kurzer
      Negativ-Cache für eine fehlschlagende Command-Key-Quelle außerhalb der Bulk-Queue; Schicht
      und Dauer wählen.
- [ ] `mdview.nvim/ws-client-inhaltspushes-pro-raum-serialisieren-curl-reihenfo`: beobachten, ob beim
      schnellen Tippen mit `display_lang` je ein Patch nach dem Endstand ankommt (bisher nie).
- [ ] `language.nvim/markdown-translate-hauptthread-rechnet-grosse-dokumente-am-s`: ein sehr großes
      Dokument (40 000 Zeilen, eine Tabelle mit 20 000 Zeilen) übersetzen und das Einfrieren
      (ca. 1 bis 2 s) bewerten.
- [ ] `language.nvim/markdown-translate-anker-kollisionen-nach-der-uebersetzung-m` und
      `markdown-segmenter-restliche-abweichungen-vom-previewer-fuss`: nur beobachten (Anker mit
      gleichem Slug nach der Übersetzung; Fußnoten-Fortsetzungen, `$$` in Listenpunkten).
- [ ] `mdview.nvim/mirror-guard-denylist-hardening` und `language.nvim/chunk-spec-surviving-mutants`:
      reine Testhärtung, kein Live-Test nötig.
- [ ] `ALL/display-lang-live-check` (Plan `ALL/display-lang`, Phase `abnahme`): die eigentliche
      Abnahme; ihre Punkte stehen in G5. Danach Plan auf `done` und nach `ALL/Backlog/FEATURES/`
      verschieben.

**Zusätzlich nach den letzten Fixes (`1f82e60`)**

- [ ] Zeile mit sehr vielen Adressen (`foo@bar.com ` mal 20 000) oder vielen `<!--` in einem
      Dokument übersetzen: kein Einfrieren von Neovim (vorher 54 s bzw. 10 s, jetzt unter 1 s).
- [ ] Antwort einer echten KI, die `www.`-Adressen oder E-Mails neu einfügt, wird abgelehnt (die
      Einheit bleibt Deutsch); in `info.failed`/Log nachsehen.

---

## J. Neue Befehle und Specs aus dem Chat „:MyPlugins jumpTo“ (Stand 2026-10-07)

Alles hier ist gebaut, getestet (headless) und von einem `ultracode`-Review geprüft. Live am echten
Neovim noch nicht ausprobiert.

### J1. Blocker / offene Entscheidungen

- [ ] **Plugin-Stand:** `:Format cite` liegt in `buffer-ctx.nvim` (Commit `ea696ee`). Auf jeder
      Maschine erst `:Lazy sync` (oder `git pull` im Checkout), sonst gibt es den Unterbefehl nicht.
- [ ] **Wordings (WKDBook-Tricentis):** Die vier neuen Texte unter
      `Workflow/Templates/Wordings/` (`AttachmentUpload`, `WebsiteNeeded`, `HAR`,
      `VerifyContractStatus`) tauchen unter `:Cases wordings` erst auf, wenn casedesk.nvim
      `wording_dirs` kann (läuft in einem anderen Chat) und auf `Wordings` zeigt. Bis dahin nur als
      Dateien prüfen.

### J2. `:MyPlugins jumpTo <name>`

- [ ] `:MyPlugins jumpTo sessions.nvim`: öffnet `specs/navigate.lua` und setzt den Cursor auf die
      Zeile `"stefanbartl/sessions.nvim"`, Zeile mittig.
- [ ] Mit `<Tab>` vervollständigen: `:MyPlugins jumpTo ` zeigt alle Plugins mit Spec (41), ohne
      spürbare Verzögerung; `:MyPlugins jumpTo ai<Tab>` ergänzt `ai.nvim`.
- [ ] Die zwei, die zuerst nicht gingen: `jumpTo ai.nvim` und `jumpTo dap.nvim` landen auf der Zeile
      hinter `return {` (ai.lua:42, inspect.lua:51).
- [ ] Namen in anderer Schreibweise: `jumpTo SESSIONS.nvim` findet dieselbe Stelle.
- [ ] Unbekannter Name: `jumpTo gibtsnicht.nvim` gibt die Warnung „No install spec …“, keinen Fehler.
- [ ] Ein deaktiviertes Plugin (Modus `disabled` in `core/source.lua`) lässt sich anspringen und wird
      vervollständigt.
- [ ] Ungespeicherte Änderungen in einer Spec-Datei, dann `jumpTo` auf ein **anderes Plugin derselben
      Datei**: der Cursor springt, die Änderung bleibt, kein E37.
- [ ] Ungespeicherte Änderungen, die Zeilen **über** dem Ziel einfügen (z. B. 5 Zeilen am Dateianfang),
      dann `jumpTo` auf ein anderes Plugin derselben Datei: der Cursor landet auf der verschobenen
      Zeile des Plugins, nicht auf der alten Plattenposition.
- [ ] Ungespeicherte Änderungen, Sprung in eine **andere** Datei: mit gesetztem `hidden` öffnet sie
      sich normal; mit `:set nohidden` kommt eine Fehlermeldung als Notify, kein Lua-Stacktrace.
- [ ] Aus einem Dateibaum-Fenster (`winfixbuf`) aufrufen: Meldung statt Fehler. Bekannt: aus einem
      Float-Fenster würde die Datei im Float landen (nicht behandelt).

### J3. `:Clipboard remove citeX`

- [ ] `:Clipboard remove citeX` meldet „copied remove citeX“; in die Kommandozeile einfügen
      (`:` tippen, dann einfügen ergibt `::%s/\[cite: \d\+\]//g`): entfernt alle `[cite: N]` im Buffer.
- [ ] Das führende `:` stört (z. B. beim Einfügen mitten in einer Zeile)? Dann entscheiden, ob der
      Text ohne `:` kopiert werden soll.
- [ ] `<Tab>` nach `:Clipboard ` zeigt `remove` (neben `path`, `reports`, `handovers`); danach `citeX`.
- [ ] Die alten Befehle gehen weiter: `:Clipboard reports`, `:Clipboard path handovers`.
- [ ] Ohne Treffer meldet der kopierte Befehl E486 (normales Vim-Verhalten, kein Fehler im Befehl).
      Mit gesetztem `gdefault` würde nur das erste Vorkommen pro Zeile entfernt (bekannt).
- [ ] Eigenes Snippet in der Config: `require("bindings.usrcmds.clipboard").enable({ snippets = {
      ["say hi"] = { text = "hi", desc = "…" } } })` ergibt `:Clipboard say hi`. Ungültige Einträge
      (leerer Schlüssel, Schlüssel gleich einem Ziel wie `reports`) werden mit Warnung übersprungen
      statt das Laden von `bindings.usrcmds` abzubrechen.

### J4. `:Format cite` (buffer-ctx.nvim)

- [ ] Buffer mit `A [cite: 3] b [cite: 12].` füllen, `:Format cite`: beide Marker weg, Meldung
      „Removed 2 [cite: N] marker(s)“. Leerzeichen drumherum bleiben (`A  b .`).
- [ ] Listenform `[cite: 1, 2]` und `[cite:1]` verschwinden ebenfalls; `[cite: x]`, `[other: 4]`
      und `[CITE: 3]` bleiben stehen.
- [ ] Mit Bereich: `:3,5Format cite` und visuell `:'<,'>Format cite` wirken nur dort.
- [ ] Mit `:Mark` markierte Zeilen behalten ihr Zeichen (Extmarks), auch Zeilen ohne Marker.
      `u` macht alles in einem Schritt rückgängig.
- [ ] `<Tab>` nach `:Format ` bietet `cite` an.
- [ ] Nicht-änderbarer Buffer (`:set nomodifiable`): Fehlermeldung als Notify.

### J5. Installations-Specs (reiner Kommentar, Verhalten unverändert)

- [ ] `specs/project.lua` (tasks.nvim): Neovim startet ohne Meldung, `:Tasks` lädt wie vorher.
      Stichprobe: den Block `keys = { dashboard = { done = "X" } }` einkommentieren, `:Tasks list`
      öffnen, `X` beendet statt `D`; danach wieder auskommentieren.
- [ ] `specs/inspect.lua` (testing.nvim): `:Testing` lädt wie vorher; der Hinweis auf `.testing.lua`
      steht im Kommentar.
- [ ] Checklisten `LUA_NVIM.md` (`LUA-97`) und `NEW_PROJECT.md` (`NEW-58`) lesen: passt der Wortlaut
      („Installations-Spec mit allen Keys, auskommentiert, kommentiert“)?

### J6. sessions.nvim: Chip verschieben (nur nachschlagen)

- [ ] In `specs/navigate.lua` (sessions.nvim, Block `chip`) stehen die Positions-Keys: `anchor`
      (Zeile ~1942), `shape` (~1945), `dock` (~1948), `row_offset` (~1956), `col_offset` (~1964).
      Ausprobieren: `col_offset = 5` einkommentieren und eine Session laden; der Chip rückt nach
      rechts und wechselt auf `rounded_chip`. Gab es früher ein interaktives Mapping zum Verschieben,
      meldest du dich, dann suche ich es im Git-Verlauf.

### J7. WKDBook-Tricentis: neue Wording-Texte (nur lesen)

- [ ] `Workflow/Templates/Wordings/AttachmentUpload.md`, `WebsiteNeeded.md`, `HAR.md`,
      `VerifyContractStatus.md` gegenlesen: Stimmen Wortlaut und Schritte? `HAR.md` enthält einen neuen
      Hinweis, dass HAR-Dateien Cookies/Tokens/Passwörter enthalten können.
- [ ] `Templates/AttachmentsUploading/tsu.md`, `Templates/WebsiteNeeded.md` und
      `Templates/VerifyContractStatus.md` sind gelöscht; die Verweise in `Workflow_CDX.md`,
      `Workflow_DecisionTree.md` und `ConsultingEnablement_Requests.md` führen ins Leere? (Stichprobe;
      der Hintergrund „Hybrides Modell“ und die Ticket-Notiz stehen jetzt am Ende von
      `ConsultingEnablement_Requests.md`.)

### J8. Bekannte Grenzen (kein Test nötig, nur wissen)

- `:Format cite` und der kopierte `:%s`-Befehl entfernen nur den Marker, nicht die Leerzeichen davor;
  es entstehen doppelte Leerzeichen.
- `jumpTo` sucht nur nach dem Plugin-Namen (`sessions.nvim`), nicht nach `Owner/Name`; die erste
  Deklaration in Dateinamen-Reihenfolge gewinnt.
- `M.TARGETS` in `bindings.usrcmds.clipboard` prüft Schlüssel mit Leerzeichen oder Kollisionen nicht
  (nur die Snippets werden geprüft).

## K. casedesk.nvim + ui.nvim: Clipboard, Wordings, Import, Formular-Kit (Stand 2026-10-07)

Alles aus dem Chat "Clipboard-Commands" vom 7.10. Vor dem Testen
**casedesk.nvim und ui.nvim auf `main` pullen** (beide gepusht). Work-Repo für die Beispiele:
`E:/repos/WKDBook-Tricentis`. Die Fälle unten sind echte Fälle daraus:

| Fall | taugt für |
|---|---|
| `1135620` (Closed), `1195796`, `1213172`, `1226959`, `1229954` | hat SNOW- **und** Resolve-Link, Kontakt (`name`) gesetzt |
| `1149596`, `1179538`, `1201484` | nur SNOW-Link, kein Resolve-Link |
| `1007631` | keine Links, **kein** Kontakt (`name`) |

Commits, `casedesk.nvim` (`main`): `8f7645d`, `fa935ac`, `c101c3b`, `b721bf9` (K2 bis K4), `2f49cd1`,
`4b8d5ee`, `34a00bf`, `0fc3ad3` (K8), `f9f23e2` (K9), `e6754ec` (K10), `20bf95f` (K11), `2d8c468`
(K12). `ui.nvim` (`main`): `4dae2b4`, `a6c10fa`, `c476e0a` (K5/K7), `287eca6`, `05d4808`, `a774543`,
`40d3565`, `bc8da10` (K6), `23be8fd` (`on_back`). Work-Repo: `8e37bfc`, `43d717c`.

---

### K1. Blocker / offene Entscheidungen

- [ ] **Review-Haken:** nur der Workflow-Review (`wf_afab2922-fd1`) hat die Clipboard-, Import-,
      Zurück-Navigations-, Sheet- und `:Case new`-Commits geprüft (mehrere Fehler gefunden und
      behoben). **`f9f23e2`, `e6754ec`, `20bf95f`, `2d8c468` (K9 bis K12) sind nicht ultracode-reviewt.**
- [ ] **Entscheidung `link`:** Das alte Feld `link` bleibt unverändert (`config.snow_url_format`
      plus ID, ohne gesetzte Option eine Meldung). Der echte gespeicherte SNOW-Link ist das neue
      `snowurl`. Soll `:Case insert link` künftig auch `snowurl` bevorzugen?
- [ ] **Bekannt, nicht getestet gegen Echtbetrieb:** Resolve-Link aus Casenummer ableiten ist
      noch nicht gebaut (Präfix `0020751294` oder `0020751295`, Regel unbekannt). Task bleibt
      offen.

---

### K2. `:Case clipboard`: neue Felder und Wordings

- [ ] `:Case clipboard snowurl 1135620`: Clipboard enthält den SNOW-Link
      (`.../x_ttng2_sapresolve_case/<32 Hex>`), Meldung nennt `1135620: copied snowurl`.
- [ ] `:Case clipboard resolveurl 1135620`: Clipboard enthält den
      `resolve.sap.com/site#resolve-Display...Incident/0020751295_1135620_2026`-Link.
- [ ] `:Case clipboard snowurl,resolveurl 1135620 --sep=blank`: beide Links, durch eine
      Leerzeile getrennt. Aliase `snowlink` und `resolvelink` gehen auch.
- [ ] `:Case clipboard resolveurl 1149596` (nur SNOW-Link): Warnung mit Grund, **Clipboard
      bleibt unverändert** (vorher etwas anderes hineinkopieren und kontrollieren).
- [ ] `:Case clipboard snowurl 1007631` (keine Links): Warnung, nichts kopiert.
- [ ] `:Case clipboard link 1135620`: ohne `config.snow_url_format` die bekannte Meldung
      (`link` ist nicht `snowurl`).
- [ ] `:Case clipboard firstResponse 1135620`: Clipboard-Text beginnt mit dem Kontaktnamen
      aus `.case.json`, **kein** `<<customer>>` mehr.
- [ ] `:Case clipboard firstResponse 1007631` (ohne Kontakt): Platzhalter `<<customer>>`
      bleibt stehen, **Warnung** sagt, dass er nicht gefüllt werden konnte.
- [ ] Schreibweise egal: `:Case clipboard FIRSTRESPONSE 1135620` und `firstresponse` gehen;
      Reihenfolge egal (`1135620 firstResponse`).
- [ ] `:Case clipboard firstResponse --edit 1135620`: kopiert **und** öffnet die Datei
      `FirstResponses/FirstResponse.md`; ohne `--edit` wird nichts geöffnet.
- [ ] `:Case clipboard number,title --labels` in einem Case-Buffer: `Case: ...`, `Title: ...`.
- [ ] `:Case clipboard` ohne Argument: Multi-Select mit dem Wert je Feld; `snowurl`,
      `resolveurl`, `firstResponse`, `firstResponseDelay`, `germanSpeaker` sind dabei, ein
      fehlender Wert steht als `—`. `<Tab>` markiert mehrere, `<CR>` kopiert.
- [ ] Completion: `:Case clipboard <Tab>` listet Felder **und** Wordings, `snowurl` ist dabei.
- [ ] Fehler: `:Case clipboard titel` meldet "unknown field" mit der Liste der bekannten.

---

### K3. `:Cases clipboard` (ohne Case)

- [ ] `:Cases clipboard firstResponse`: Text unverändert, `<<customer>>` bleibt Platzhalter.
- [ ] `:Cases clipboard firstResponse germanSpeaker --sep=blank`: beide Texte, getrennt.
- [ ] `:Cases clipboard title`: abgelehnt mit "needs a case — use :Case clipboard",
      Clipboard bleibt unverändert.
- [ ] `:Cases clipboard 1135620`: ebenfalls abgelehnt (eine Casenummer braucht `:Case`).
- [ ] `:Cases clipboard` ohne Argument: Picker, der **nur** Wordings zeigt, keine Case-Felder.
- [ ] `:Cases clipboard <Tab>`: nur Wordings (kein `number`, `title`, ...).
- [ ] `:Cases clipboard firstResponse --edit`: kopiert und öffnet die Datei.
- [ ] `:Cases wordings firstResponse`: verhält sich wie vorher (Datei öffnen **und** kopieren,
      Text unverändert).
- [ ] Wording, dessen Datei fehlt (Pfad in `config.wordings` bewusst falsch setzen): Warnung mit
      Grund, nichts kopiert, kein Lua-Fehler.

---

### K4. `:Case import` (früher `:Case copy`)

- [ ] `:Case import C:\Pfad\datei.txt` im Case-Buffer: fragt den Zielordner (`Replies`,
      `Research`, `assets`, Case-Root), kopiert, öffnet die Datei. Bytegleich prüfen:
      `fc /b Quelle Ziel`.
- [ ] `:Case import` ohne Pfad: fragt "Source file" mit Dateicompletion.
- [ ] Zieldatei existiert schon: Meldung "already exists — not overwritten", nichts überschrieben,
      die vorhandene Datei wird geöffnet.
- [ ] `:Case copy C:\Pfad\datei.txt`: ein Hinweis auf `:Case import`, dann derselbe Ablauf.
- [ ] Falls du ein Binding oder eine eigene Config auf `:Case copy` hast: umstellen.

---

### K5. ui.nvim: `kit.form` mit Zurück-Navigation (Opt-in `back = true`)

Testen ohne casedesk, direkt im Command-Line-Modus:

```vim
:lua require("ui.kit").form({ back = true, fields = { { name = "a", label = "Eins" }, { name = "b", label = "Zwei" }, { name = "c", label = "Drei", required = true } }, on_submit = function(v) vim.print(v) end, on_cancel = function() print("cancel") end })
```

- [ ] Titel zeigt `Eins (1/3)`, `Zwei (2/3)` usw.; im ersten Feld **kein** `[← Back]`-Button.
- [ ] In Feld 2 `<BS>` auf **leerem** Feld: zurück zu Feld 1, dessen Antwort steht wieder
      im Feld (Cursor am Ende). Mit Text im Feld ist `<BS>` ein normales Löschen.
- [ ] `<BS>` gedrückt halten auf einem leeren Feld: wandert **nicht** durch alle Felder zurück
      (der Hold wird ignoriert), nach kurzer Pause geht es einen Schritt zurück.
- [ ] `<S-Tab>` und `<C-p>` gehen zurück; mit offenem Completion-Popup gehören sie dem Popup.
- [ ] Vorwärts und zurück verliert keine Eingabe; halb getippter Text bleibt erhalten.
- [ ] `<Down>` oder `<Tab>` im Feld setzt den Fokus auf die Buttonleiste (startet bei `Next`);
      dort `h`/`l` und Pfeile bewegen, `<CR>` drückt, `<Up>`/`k`/`i`/`a` kehrt ins Feld zurück.
- [ ] Mausklick auf `[← Back]`, `[Skip]`, `[Next ↵]` (nach `:set mouse=a`): fokussiert **und**
      drückt in einer Aktion. Beim letzten Feld heißt der Button `[Done ↵]`.
- [ ] `<Esc>` überspringt ein optionales Feld (Wert wieder `default`) und bricht bei dem
      `required`-Feld (`Drei`) ab (`cancel` wird gedruckt); `[Skip]` fehlt auf `Drei`.
- [ ] Einfügen mit Zeilenumbruch (mehrzeilig kopierter Text): bleibt **eine** Zeile, die Buttons
      bleiben sichtbar. Sehr langer Text, der seitwärts scrollt: Buttonleiste bleibt im Bild.
- [ ] Regression ohne `back = true`: gleiche Form ohne die Option verhält sich wie früher (keine
      Buttons, kein `(1/3)`, `<BS>` auf leerem Feld tut nichts). Prüfen mit den bestehenden
      casedesk-Dialogen: `:Case imp`, `:Case tag`, `:Tricentis pto`, die Case-Infocard-Edits.

---

### K6. ui.nvim: `kit.sheet` (alle Felder in einem Fenster)

```vim
:lua require("ui.kit").sheet({ title = "Test", fields = { { name = "number", label = "Case number", required = true, live = true, validate = function(v) if v:match("^%d+$") then return true end return false, "nur Ziffern" end }, { name = "area", label = "Area", kind = "select", choices = { "SAP", "CS" } }, { name = "title", label = "Title" }, { name = "token", label = "Token", secret = true } }, submit_label = "Anlegen", cancel_label = "Abbruch", on_submit = function(v) vim.print(v) end, on_cancel = function() print("cancel") end })
```

- [ ] Ein Fenster zeigt alle vier Zeilen mit Label links; die Labels lassen sich nicht
      bearbeiten und der Cursor landet nie auf einem Label.
- [ ] `<Tab>`/`<S-Tab>` wechseln Feld und danach die beiden Buttons, umlaufend; `<Down>`/`<Up>`
      ohne Umlauf.
- [ ] `12x` in `number` tippen: rote Meldung "nur Ziffern" unter dem Feld (`live`), Fenster
      wächst; beim Korrigieren verschwindet sie sofort und das Fenster schrumpft.
- [ ] `<CR>` im letzten Feld drückt `[Anlegen]`; mit ungültigem Feld wird nicht abgeschickt
      und der Fokus springt auf das erste ungültige.
- [ ] `number` leer lassen und abschicken: "required".
- [ ] Select-Feld `area`: `h`/`l` und Pfeile wechseln `SAP`/`CS`; `<CR>` oder `<Space>` öffnet
      die Auswahl, eine Wahl springt zum nächsten Feld.
- [ ] `token`: Eingabe erscheint als `*`, `on_submit` bekommt den echten Wert.
- [ ] `<Esc>` aus jeder Position bricht ab (`cancel`), keine Fenster bleiben zurück
      (`:lua print(#vim.api.nvim_list_wins())` vorher/nachher gleich).
- [ ] Mausklick auf ein Feld setzt Fokus und Cursor; Klick auf `[Anlegen]`/`[Abbruch]` drückt.
- [ ] Einfügen mit Zeilenumbruch in ein Feld: wird mit Leerzeichen zu einer Zeile verbunden.
- [ ] Hell und dunkel: `KitError`-Meldung, `*`-Markierung des Pflichtfelds und der fokussierte
      Label sind in beiden Themes lesbar.
- [ ] Sehr schmales Fenster (`:set columns=50`): lange Werte brechen unter die Wertspalte um.

---

### K7. Regression (ui.nvim-Änderungen am Bestandscode)

- [ ] `kit.input`: normale Eingabe (z. B. `:Case new` bis zur Nummer, ohne Buttons) verhält sich
      wie früher; `<BS>` auf leerem Feld bleibt ohne `on_back` wirkungslos.
- [ ] Picker (`c476e0a` hat den Item-Modus nach ui.nvim geholt): `:Tricentis links`,
      `:Cases livegrep`, `:Case insert` öffnen ohne Fehler, Filtern, Vorschau, Auswahl wie bisher.
- [ ] `kit.confirm` (z. B. beim Löschen eines Cases oder `:Case reopen`) sieht gleich aus, Buttons
      per `h`/`l` und Klick bedienbar (die Buttonlogik liegt jetzt in `ui.kit.buttons`).

---

### K8. `:Case new [nr] [--form|--steps]`, `config.new_mode`

Commits `casedesk.nvim`: `2f49cd1`, `4b8d5ee`, `34a00bf`, `0fc3ad3`; `ui.nvim`: `40d3565`, `bc8da10`.
Beide Wege enden im selben Dry-Run, derselben Bestätigung und demselben Anlegen.

- [ ] `:Case new --steps` (und ohne Flag, solange `new_mode = "steps"`): Nummer, dann Area (nur
      bei mehreren Areas), dann Titel, Company, Name, SNOW-Link, Resolve-Link als Formular.
      Titel zeigt `Title (1/5)` usw.
- [ ] Im Formular `<BS>` auf **leerem** Feld und `<S-Tab>` gehen zurück, die alte Antwort steht
      wieder im Feld. Vom ersten Feld aus geht es zurück zur Area, von dort zur Nummer.
- [ ] Beim Zurückgehen eine Nummer eingeben, die es schon gibt: Hinweis, **die bis dahin
      getippten Antworten bleiben** (fragt nur erneut), der Ablauf endet nicht.
- [ ] `:Case new --form`: ein Fenster mit Nummer, Area (Auswahlzeile, fehlt bei nur einer Area),
      Titel, Company, Name, SNOW-Link, Resolve-Link und `[ Create ] [ Cancel ]`.
- [ ] Im Form-Modus: ungültige Nummer (`12`, `abc`) zeigt die rote Meldung **beim Tippen** unter
      dem Feld; eine Nummer, die in der gewählten Area schon existiert, ebenfalls.
- [ ] `:Case new 977130 --form`: die Nummer steht schon im Feld und ist geprüft; existiert sie
      in der Standard-Area schon, startet das Fenster auf der Nummer mit Meldung.
- [ ] `:Case new --form --steps` meldet einen Fehler, `new_mode = "bogus"` fällt auf `steps`
      zurück, `:checkhealth casedesk` nennt es.
- [ ] Beide Wege ergeben denselben Case (Ordner, `.case.json`, Dry-Run-Liste). Danach enthält
      `Research/00_Research.md` den Checklisten-Block (K12) und der Case eine `Links.md` (K11).
- [ ] Esc-Verhalten: im Steps-Formular **überspringt** `<Esc>` ein Feld
      (bestehendes `kit.form`-Verhalten), im `--form`-Fenster bricht `<Esc>` alles ab.
- [ ] Ohne `ui.kit.sheet` (ältere ui.nvim): `--form` fällt mit Hinweis auf die Schritte zurück.

---

### K9. Wording-Ordner, Log-Snippets, `startCdxChat`

Commit `casedesk.nvim` `f9f23e2`; Work-Repo `8e37bfc` (Log-Snippets, `Logs.md`) und `43d717c`
(Fragen der Checkliste, Hinweis in `Workflow.md`). **Die deutschen `_DE`-Texte habe ich
geschrieben, bitte gegenlesen.** Der typische Windows-Pfad hinter `%TRICENTIS_ALLUSERS_APPDATA%`
steht bewusst nicht in den Texten.

- [ ] `:Cases clipboard TCSupportInfo`: genau `The 'TCSupportInfo' package can be generated in
      Tosca Commander via: *Project -> About Tosca -> Support Info*`.
- [ ] `:Cases clipboard tcsupportinfo` (kleingeschrieben) geht auch; `<Tab>` nach `:Cases clipboard `
      zeigt `TCSupportInfo`, `CommanderLog`, `TBoxLog`, `BrowserExtensionLog`, `DexServerLog`,
      `DexAgentLog`, `ToscaServerLog`, `HAR`, `GpResult` und deren `_DE`-Varianten sowie die
      Fragen (`ProductComponent`, `Subset`, ...).
- [ ] `:Cases clipboard TCSupportInfo CommanderLog --sep=blank`: beide Texte, durch eine
      Leerzeile getrennt.
- [ ] `:Cases clipboard CommanderLog_DE`: der deutsche Text.
- [ ] **Neue Datei ohne Neustart:** eine Datei `Workflow/Templates/Wordings/Logs/Test.md` anlegen,
      dann sofort `:Cases clipboard Test` und `:Cases wordings Test` (beides ohne Neustart gültig);
      Datei wieder löschen.
- [ ] `:Cases clipboard startCdxChat`: der Prompt aus `Workflow/CDX/StartChat.md` **bis
      einschließlich** `### Activity Stream:`, nichts danach (kein Platzhalter, keine Templates).
- [ ] Die Zeile `### Activity Stream:` in einer Kopie der Datei umbenennen und `startCdxChat`
      auf die Kopie zeigen lassen: Warnung, **nichts** wird kopiert (nicht die ganze Datei).
- [ ] `:Cases clipboard` ohne Argument: Picker nur über die Wordings (jetzt mehr als vorher).
- [ ] `:Case clipboard TCSupportInfo 1135620`: Snippet ohne Case-Bezug, Kopie identisch.

---

### K10. `:Case insert snow-number|snow-url|sap-number|sap-incident|sap-url`

Commit `casedesk.nvim` `e6754ec`. Cursor in einen Buffer setzen, dann:

- [ ] `:Case insert sap-url 1135620`: fügt den Resolve-Link ein **und** kopiert ihn.
- [ ] `:Case insert snow-url 1135620`: der SNOW-GUID-Link. `snow-number` ist dasselbe wie `snow`.
- [ ] `:Case insert sap-number 1135620`: `1135620/2026`. `:Case insert sap-incident 1135620`:
      `0020751295_1135620_2026`.
- [ ] `:Case insert sap-url 1149596` (nur SNOW-Link): Meldung mit Grund (`no SAP Resolve link …`),
      **nichts** eingefügt.
- [ ] `:Case insert` ohne Argument: der Picker zeigt die fünf Zeilen mit ihren Werten (`—` wenn
      keiner da ist); `<Tab>` nach `:Case insert ` kennt die neuen Namen.
- [ ] Mit Visual-Auswahl (`:'<,'>Case insert sap-number`) ersetzt die Auswahl.
- [ ] `:Case insert sap-number` in einem **CS**-Case: Meldung "area CS has no SAP incidents".
- [ ] `:Case insert snow` und `:Case insert link` verhalten sich wie vorher.
- [ ] `:Case clipboard sap-number,sap-incident,sap-url 1135620 --sep=blank`: dieselben Werte
      (gleiche Felder, `sapnumber`, `sapincident`, `resolveurl`).

---

### K11. `Links.md` in jedem Case

Commit `casedesk.nvim` `20bf95f`. Struktur: `## Tickets`, `## Docs & references`,
`## SWARM / internal tickets`, eine Zeile `- [Label](URL) — Zweck` je Link.

- [ ] Neuen Case anlegen mit SNOW- und Resolve-Link: `Links.md` liegt im Case-Ordner, öffnet sich
      **nicht**, beide Links stehen unter *Tickets* mit Zweck (`ServiceNow case record`,
      `SAP Resolve incident`). Ohne die Links ist die Gruppe leer.
- [ ] Älterer Case: `:Case links open 1135620` legt die Datei an (mit seinen Links in *Tickets*)
      und öffnet sie; ebenso `:Case sync` (listet `Links.md` als fehlend).
- [ ] `:Case links add https://docs.tricentis.com/... was der Kunde zuerst einrichten muss`:
      Zeile unter *Docs & references*; zweiter Link kommt **dahinter**, nicht darüber.
- [ ] Atlassian-Jira-Link (`.../browse/SWAT-1`) landet unter *SWARM / internal tickets*,
      `--section=swarm|docs|tickets` überschreibt, `--label=Text` setzt den Linktext.
- [ ] Einen Link im Browser kopieren, dann `:Case links add` (nur Zweck als Text, z. B.
      `:Case links add das SWAT-Ticket`): nimmt die URL aus der Zwischenablage, sagt es.
- [ ] `:Case links add <url>` ohne Zweck: fragt "What is this link for?"; leere Antwort fügt
      **nichts** hinzu.
- [ ] Denselben Link nochmal: Meldung `already listed`, keine zweite Zeile.
- [ ] Ein Resolve-/SNOW-Link, den du von Hand in `Links.md` einträgst, wird von
      `:Case clipboard snowurl` / `resolveurl` / `:Case insert sap-url` gefunden, wenn
      `.case.json` keinen hat; hat `.case.json` einen, gewinnt der.
- [ ] `:Case links 1135620` (ohne `add`/`open`) ist weiter die Doku-Versionsprüfung.
- [ ] `:Case doctor` und `:checkhealth casedesk` bei einem älteren Case ansehen: taucht `Links.md`
      dort als fehlend auf? (Nicht geprüft, ob diese Prüfungen das Blueprint auswerten.)

---

### K12. Erstantwort-Checkliste

Commit `casedesk.nvim` `2d8c468`; Fragen im Work-Repo `43d717c`. Die Checkliste steht in
`Research/00_Research.md` zwischen `<!-- casedesk:checklist begin … -->` und `… end -->`.

- [ ] Neuer Case: `Research/00_Research.md` enthält oben (unter dem `# …`) den Block mit den
      Abschnitten *Vor der Antwort*, *Beim Kunden erfragen — Stufe 1*, *Senden und danach*; bei
      DEX/XScan/Cloud im Titel zusätzlich *Je nach Fall* und die passenden Logs.
- [ ] Titel mit `XScan unmapped controls Fiori`: AppType, ControlsAffected, HTML-Seite, TBox-Log,
      Browser-Extension-Log erscheinen; Titel mit `DEX unattended`: DEX-Preflight, DEX-Agent-Log,
      gpresult (Stufe 2).
- [ ] `:Case checklist 1213172` in einem **echten** Case: Block wird eingefügt/aktualisiert, die
      Datei öffnet am Block. Bei Cases mit Bild unter `assets/` steht `[x] … — gefunden: <Datei>`.
      **Vorsicht: das schreibt in `Research/00_Research.md` des echten Cases** (nur den Block).
- [ ] Ein Häkchen von Hand setzen (`[x]`), eins auf `[-]`, dann `:Case checklist`: beide bleiben.
      Eine Support-Info-Datei in `assets/` legen: nächster Lauf hakt `Support Info` ab.
- [ ] Text **außerhalb** des Blocks (Notes, eigene Zeilen) bleibt unverändert; ungespeicherte
      Änderungen im Buffer: Meldung "save it first".
- [ ] Die Erstreaktions-Zeile nennt die fällige Zeit (`Erstreaktion fällig 2026-… (P2, in …)`),
      sobald der Case Priorität und Activity Stream hat (`:Case activity`).
- [ ] `:Case clipboard ask`: höchstens 4 nummerierte englische Fragen der aktuellen Stufe, mehrzeilige
      Texte (Browser-Extension-Log) eingerückt; Hinweis "stage 1 has N open questions, 4 asked at
      a time". Sind alle Punkte abgehakt: "nothing left to ask".
- [ ] `:Case checklist draft` in einem Case, dessen `Replies/00_PSO.md` noch das Gerüst
      (`Dear {name},`) ist: Entwurf mit Anrede (Kontaktname oder `<<customer>>`), nummerierten
      Fragen und Schluss. Hat die Datei schon Text: Entwurf nur in der Zwischenablage.
- [ ] `config.checklist = { lang = "de" }`: Fragen kommen aus den `_DE`-Dateien.
- [ ] `config.checklist = { skip = { "timer" } }` entfernt den Punkt, `extra = { { id =
      "licence", block = "ask", text = "Lizenzdatei", snippet = "TCSupportInfo", keywords = {
      "license" }, files = { "%.lic$" } } }` fügt einen eigenen hinzu.
- [ ] Fragen prüfen: sind die Formulierungen der `Wordings/Ask/*.md` so, wie du sie schicken
      willst? (Stufe-1-Auswahl und Reihenfolge ist meine Ableitung aus `Workflow.md`,
      `Workflow_DecisionTree.md`, `Policies_CDX.md`, `1_Answer.md`.)

---

### K13. Noch nicht gebaut

1. Resolve-Link aus Casenummer ableiten (wartet auf die Präfix-Regel `…294`/`…295`; Task `RM-47`
   im wkdbook).
2. Datenpflege: Case `0498885` (falsche Nummer, Firmenname als Link), Müll in `links[]` (`RM-48`,
   `RM-49`).

---

## L. casedesk.nvim: Checks aus `NEW.md` — Clipboard, Spotlights, Übersetzer-Policy, KI-Kette (Stand 2026-10-06)

Ergebnis der Umsetzung von `NEW.md` (`:Case clipboard`, Spotlights pro Case, spotlight.nvim <-> mdview.nvim; die
Notiz ist erledigt und liegt im wkdbook-Backlog) und der anschließenden Aufräum-Runden. Alles hier ist **von dir zu prüfen**; was **durch Externes blockiert** ist,
steht gesammelt in **N** (Blocker). Die Spotlight-/mdview-/ai-Checks, die nicht direkt casedesk betreffen, stehen in
den Abschnitten **A**, **B**, **C** und **F** dieser Datei. Task: `casedesk.nvim/clipboard-spotlight-live-check`
(wkdbook-myplugins). Fehler als eigene bug-Tasks anlegen.

---

### L1. Checks für dich (casedesk.nvim)

Task: `casedesk.nvim/clipboard-spotlight-live-check` (wkdbook-myplugins). Fehler
als eigene bug-Tasks anlegen.

#### `:Case clipboard`

_Neue Felder (`snowurl`, `resolveurl`, Wordings, `ask`, ...) und `:Cases clipboard`: siehe K2, K3 und K9._

- [ ] `:Case clipboard` ohne Argument: Mehrfachauswahl-Picker (`kit.select`,
      `multi`) in der echten TUI; Felder abhaken, Werte stimmen, Zwischenablage
      enthaelt das Erwartete (bisher nur mit gestubbtem `kit.select` geprueft).
- [ ] `:Case clipboard number,title --labels` gegen einen echten Case.
- [ ] `:Case clipboard number title --sep=pipe` bzw. `--sep=\n` (Escapes
      `\n`, `\t`, `\\` werden dekodiert) gegen einen echten Case.
- [ ] Explizite Case-Angabe (`AREA/Nummer`, `.`, volle SNOW-ID) an beliebiger
      Position; zwei verschiedene Cases ergeben einen Fehler.
- [ ] Feld ohne Wert (z. B. `title` ohne Titel, `link` ohne `snow_url_format`):
      Warnung mit Grund, Rest wird kopiert, Zwischenablage nie leer.
- [ ] Tab-Completion: Feldnamen, Felder nach dem Komma, Case-Nummern, und auch
      ab dem dritten Token (variadisch, lib.nvim `f0d76b9`).

#### Spotlights pro Case (`:Case spotlight`)

- [ ] Markierungen in Case A setzen, nach Case B wechseln (leer), dort
      markieren, zurueck nach A: `:Case spotlight list` und `show` stimmen,
      A hat wieder seine eigenen Markierungen, nichts vermischt sich.
- [ ] Neustart von Neovim in einem Case: Markierungen kommen zurueck, kein
      Hinweis-Dauerlaerm (Session-Restore von spotlight.nvim).
- [ ] Origin-Filter: in einer Datei **ausserhalb** des gebundenen Cases
      markieren; Markierung bleibt live, wird aber nicht in `.spotlight.json`
      geschrieben; einmalige Info erscheint; `:Case spotlight save` speichert
      alles.
- [ ] Case-Wechsel (BufEnter) mit zurueckgehaltenen Markierungen: Bindung wird
      geloest, Markierungen bleiben, eine Info nennt den Weg
      (`:Case spotlight load` fragt vor dem Ersetzen, `save` weist zu).
- [ ] Unlesbare `.spotlight.json` in einem betretenen Case: Warnung, Bindung am
      alten Case wird geloest (kein stilles Schreiben in den falschen Case).
- [ ] Portable Origins: gespeicherte absolute Pfade unter `$REPOS_DIR` stehen
      als `$REPOS_DIR/...` in der Datei; auf einer zweiten Maschine mit anderem
      `$REPOS_DIR` kommen die Markierungen richtig zurueck.
- [ ] `:checkhealth casedesk`: zeigt `follow`, `origin_filter`,
      `warn_unignored`; Gitignore-Warnung fuer `.spotlight.json`,
      `.spotlight.json.tmp`, `.spotlight.json.corrupt`; mit
      `spotlight.warn_unignored = false` verschwindet sie.
- [ ] Datenschutz-Stichprobe: `.spotlight.json` taucht weder im Export-Bundle
      noch in Anonymisierung oder KI-Prompts auf.

#### Uebersetzer-Policy (`:Case translate`)

- [ ] Mit leerer `translate_allowed_engines` wird Kundentext von jeder Engine
      abgelehnt; mit einem Eintrag (`CASEDESK_TRANSLATE_ALLOWED`) nur diese
      Engine erlaubt.

#### KI-Kette / Copilot (casedesk-seitig)

- [ ] `:Case ki --send` mit dem Copilot-Provider (nur harmlose Testdaten!):
      Anonymisierung greift, Antwort wird abgelegt. Jeder Lauf kostet einen
      Premium-Request.
- [ ] `docs/KI.md` liest sich stimmig zum Ist-Stand.

---

### L2. Entscheidungen, die schon gefallen sind (zur Kontrolle)

- Anonymisierung bleibt Pflicht, auch fuer Copilot/Claude.
- Interne Policy-Texte nur mit `--inline`, nie automatisch.
- Externe Uebersetzer fuer Kundentext nur per Allow-List.
- `spotlight.follow = true` bleibt Default.
- Kein Feld `spotlight` in `:Case clipboard`, kein Statusline-Segment.
- `.spotlight.json` wird **nicht** in die `.gitignore` des Case-Repos
  (WKDBook-Tricentis) eingetragen, damit die Markierungen per Git zwischen
  Geraeten mitreisen; Option `spotlight.warn_unignored = false` schaltet die
  Health-Warnung ab.
- Absolute Origins unter `$REPOS_DIR` werden als `$REPOS_DIR/...` gespeichert.

---

### L3. Bekannte Restpunkte (klein, ohne Handlungsdruck)

- Optionale Spec: `REPOS_DIR` als Symlink (Verhalten sicher, Pfad wird nur nicht
  kompaktiert).
- Aendert sich die Projekt-Root von spotlight.nvim mitten in der Session
  (`:cd`), werden relative Origins neuer Live-Items gegen die neue Root
  aufgeloest (bekannte Items sind geschuetzt).
- `GITHUB_TOKEN` enthaelt ein klassisches `ghp_`-Token: der Copilot-Provider
  reicht es bewusst nicht weiter; fuer die Copilot-CLI direkt in der Shell die
  Variable entfernen.

---

## M. casedesk.nvim: Live-Test-Checkliste — alles, was das Plugin kann (Stand 2026-10-02)

Alles, was `casedesk.nvim` kann, zum Durchtesten im echten Neovim mit dem echten
Case-Bestand — **ausführlich für alles, was in der Sitzung vom 2026-10-02 neu
gebaut wurde** (Teil A), danach die noch ungetesteten Punkte der Vorsitzung
(Teil B), dann ein Smoke-Inventar über **jede** Route (Teil C) und über
Keymaps, Autocmds und Health (Teil D). Automatisiert lief damals alles grün (846
Specs, `stylua`/`luacheck`/`gen_docs`; heute über 1870) — diese Liste ist für das, was Tests nicht
zeigen: echtes Verhalten an echten Daten, UX, Timing, Dinge, die nur beim Tippen
auffallen.

**Status:** ❌ ungetestet · 🟡 teilweise · ✅ wie erwartet · 🔴 Fehler (Notiz
ausfüllen!). Ein gefundener Fehler gehört zusätzlich als `RM-nn` in
`WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/ROADMAP/ROADMAP.md` oder
als GitHub-Issue — nicht nur hierher.

### Vorbereitung

**Stand holen und neu starten.** (Pfade: auf dieser Maschine liegen die Repos unter `E:/repos`.) Das Plugin kommt aus dem lokalen Checkout
(`C:/repos/casedesk.nvim`, `lazy = false`), aber `hover.nvim` und `pdfport.nvim`
haben heute ebenfalls Änderungen bekommen — alle drei pullen, dann **Neovim neu
starten** (kein `:Lazy reload`: `casedesk` registriert Routen und Autocmds beim
Start).

```bash
git -C C:/repos/casedesk.nvim pull
git -C C:/repos/hover.nvim pull
git -C C:/repos/pdfport.nvim pull
```

```vim
:checkhealth casedesk
```

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| V1 | Neovim startet | Keine Fehlermeldung beim Start, `:Case <Tab>` vervollständigt | ❌ | |
| V2 | `:checkhealth casedesk` | Alles grün bzw. klar benannte Warnung (welches Binary fehlt), **kein Abbruch** — der Browser-Check läuft jetzt über `lib.nvim.deps` | ❌ | |
| V3 | `:Case <Tab>` | Neue Verben tauchen auf: `imp`, `preflight`, `spotlight`, `jql`, `image`, `translate` | ❌ | |

**Testdaten, die es im Bestand gibt:**

| Fall | Wofür |
| --- | --- |
| `977392` (Solved, Siemens Energy) | hat `Research/01_ActivityStream.md` — Stream-Befehle (`spotlight`, `jql suggest`, `translate stream`, `anonymize`); die Firma hat zwei weitere Cases (`1229161`, `1244211`) — Firmen-Verlauf |
| `1195796` | hat `Research/NN_ActivityStream.md` — zweiter Stream-Fall |
| `1226959` | DEX-Fall, Titel "…Team Agent" — Preflight-Hinweis, Ähnlichkeits-Cluster mit `948965` und `1004926` |
| `1201484` | `assets/fourth/failed_login_errorlog.png` — der NDJSON-Log-Screenshot |
| Wegwerf-Case | für alles, was schreibt: `:Case new 999001`, am Ende `:Case delete 999001` (Nummer eintippen). **Nie** eine Testnotiz zu einem echten Kunden stehen lassen — `Cases/Important.jsonl` ist echter Bestand |

---

### Teil A — neu am 2026-10-02

#### A1 · `:Case anonymize`: Telefonnummern und Arbeitszeiten (`50c828d`)

Zwischenablage mit diesem Text füllen, in einem Wegwerf-Case `:Case activity`,
dann `:Case anonymize`:

```text
Please call me. Contact number: 0176 1234567
Alternatively +49 30 12345678 or 0049 30 12345678.
Available 10:00 A.m-19:00 P.M [IST] and 9am - 5pm CET.
Case 1201484, ticket SAP0000123456, tel 2026-09-30, phone: 12345.
Log at 2026-09-24 12:01:51 - 12:05:00, meeting at 3:52 PM.
```

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | Viewer-Kopfzeile | Zählt `N Telefonnummer(n) · N Arbeitszeit(en)` mit; Erwartung hier: 3 Telefonnummern, 2 Arbeitszeiten | ❌ | |
| 2 | Text darunter | `Contact number: [Telefon]`, `[Telefon]` für `+49…` und `0049…`, `[Arbeitszeit]` für beide Zeitbereiche samt `[IST]`/`CET` | ❌ | |
| 3 | `1201484`, `SAP0000123456` | **Bleiben stehen** (nackte Ziffernfolge ist keine Nummer) | ❌ | |
| 4 | `tel 2026-09-30`, `phone: 12345` | **Bleiben stehen** (Datum bzw. zu kurz) | ❌ | |
| 5 | Zeitstempel `12:01:51 - 12:05:00` und `3:52 PM` | **Bleiben stehen** (Log-Zeitstempel, einzelne Uhrzeit) | ❌ | |
| 6 | Warntext im Viewer | Nennt Telefonnummern "mit Label oder +/00-Präfix" und dass Nummern ohne Label **nicht** erkannt werden | ❌ | |
| 7 | Regression: Namen, E-Mails, S-User, Account/Contact | Weiterhin geschwärzt wie vorher | ❌ | |

#### A2 · Synonyme für `:Case similar` / `:Cases solutions` (`e466407`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case similar 948965` | `1226959` und `1004926` stehen auf Platz 1 und 2 (Scores um 0,27–0,30); Trefferwörter enthalten `distributed` | ❌ | |
| 2 | `:Case similar 1004926` | `1226959` Platz 1, `948965` Platz 2 (ohne Synonyme wäre es Platz 3) | ❌ | |
| 3 | `:Cases solutions dex agent` und `:Cases solutions team agent` | **Dieselben** Treffer in derselben Reihenfolge | ❌ | |
| 4 | Optional: `synonyms = {}` in der Plugin-Spec, neu starten, Test 1 wiederholen | Scores etwas niedriger, Reihenfolge ähnlich; danach wieder zurücknehmen | ❌ | |
| 5 | Kein Tempo-Einbruch bei `:Case similar` | Antwortet so schnell wie vorher (rund 47 Cases) | ❌ | |

#### A3 · Tosca-Schreibweise bei `:Case ki import` (`df33234`)

Zum Einfügen aus der Zwischenablage:

```markdown
## 1. Activity Stream Analysis
The execution list contains the failing test case and a test step value.
Siehe https://docs.tricentis.com/x/test-case.htm und `execution list`.

## 3. Solution
Re-create the Execution-List. Several test cases are affected.
```

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case ki import` im Wegwerf-Case | `Research/NN_KiAnalysis.md`: `` `ExecutionList` ``, `` `TestCase` ``, `` `TestStepValue` `` in Backticks | ❌ | |
| 2 | Die URL | **Unverändert** (`test-case.htm`) | ❌ | |
| 3 | `` `execution list` `` in Backticks | Bleibt wie geschrieben | ❌ | |
| 4 | "Several test cases" (Plural) | Bleibt unverändert | ❌ | |
| 5 | `:Case clean` auf derselben Datei | Fasst die Schreibweise **nicht** an (nur Paste-Artefakte) | ❌ | |

#### A4 · Unausgefüllte Templates: `docs-thin` (`4ceb659`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | Wegwerf-Case frisch anlegen, `:Case solved` (oder `:Case close`), `:Cases doctor` | `docs-thin` meldet `Summary.md` **trotz** 400 Zeichen Gerüst; Meldung sagt "of own text" | ❌ | |
| 2 | Echten Closed-/Solved-Case mit ordentlicher Doku | **Kein** `docs-thin` | ❌ | |
| 3 | Dieselbe `Summary.md` des Wegwerf-Cases um 3–4 Sätze ergänzen, `:Cases doctor` | Fund verschwindet | ❌ | |
| 4 | Anzahl `docs-thin`-Funde im echten Bestand | Plausibel (mehr als vorher ist möglich: Gerüst zählt nicht mehr); keine offensichtlich falschen Funde bei gut dokumentierten Cases | ❌ | |

#### A5 · Engine-Steckbrief im Faktenblock (`86d418b`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | Wegwerf-Case `:Case new 999001` mit Titel `Appium session fails on Android 14`, Stream in die Zwischenablage, `:Case ki`, Prompt irgendwo einfügen | Im Block "Ermittelte Fakten" eine Zeile `Engine-Steckbrief: EngineLab/Engines/Mobile/00_Engine.md` | ❌ | |
| 2 | Titel mit `Fiori` und `Excel` | Zwei Steckbriefe, alphabetisch (`Excel`, `SAP`), nie mehr als zwei | ❌ | |
| 3 | Titel ohne Stichwort (z. B. `Grid stays red`) | **Keine** Steckbrief-Zeile | ❌ | |
| 4 | Titel mit `Therapist` oder `index` | Keine Zeile (nur ganze Wörter) | ❌ | |
| 5 | Die genannte Datei | Existiert tatsächlich unter `C:/repos/WKDBook-Tricentis/EngineLab/Engines/…` | ❌ | |

#### A6 · `:Case spotlight` (`165ce12`) — braucht `spotlight.nvim`

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case spotlight 977392` | Stream öffnet sich, Fehlercodes/KBA-Nummern/Versionen/Anhangsnamen sind farbig markiert, jede in eigener Farbe | ❌ | |
| 2 | Mehr als 8 Tokens im Stream | Warnung nennt die nicht untergebrachten (Anhänge zuletzt) samt Hinweis `:Spotlight clear` | ❌ | |
| 3 | Vorher eigenen Spotlight setzen (`:Spotlight add foo`), dann `:Case spotlight` | Eigener Spotlight bleibt **bestehen**, wird nicht gelöscht | ❌ | |
| 4 | `:Case spotlight` ein zweites Mal | Keine Doppelmarkierung, Meldung zu "bereits markiert" | ❌ | |
| 5 | Case ohne Stream | Warnung "no Activity Stream found", nichts passiert | ❌ | |
| 6 | Stream ohne Token | Meldung "nothing to spotlight", Datei öffnet sich trotzdem | ❌ | |
| 7 | `spotlight.nvim` deaktivieren | Warnung "spotlight.nvim not installed", kein Fehler | ❌ | |

#### A7 · Browser-Suche über `lib.nvim.deps` (`432e601`, hover `d17d610`, pdfport `a10c464`)

Reines Refactoring — es darf sich **nichts** ändern. Prüfen, dass die drei
Plugins ihren Browser noch finden.

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:checkhealth casedesk` | Zeile `chrome found (<Pfad>) — :Cases export printing to PDF` | ❌ | |
| 2 | `:Cases export 977392` | PDF entsteht wie vorher | ❌ | |
| 3 | `:checkhealth hover` | Browser für Seiten-Screenshots gefunden (Hinweis "found off PATH" ist ok) | ❌ | |
| 4 | Mauszeiger/Cursor auf einen `https://docs.tricentis.com/…`-Link, `hover` auslösen | Screenshot-Vorschau erscheint wie vorher | ❌ | |
| 5 | `:checkhealth pdfport` | `chromium producer: ready (… browser: <Pfad>)` | ❌ | |
| 6 | Browser temporär umbenennen oder PATH/`paths` verbiegen (nur wenn leicht machbar) | Klare Meldung "no Chromium browser found", **kein Absturz** von `:checkhealth casedesk` | ❌ | |

#### A8 · `:Case imp` — Notizen zu Case, Firma, Kontakt (`159d545`, `ba528a7`)

**Wichtig:** Das schreibt nach `C:/repos/WKDBook-Tricentis/Cases/Important.jsonl`.
Zum Testen **neutrale** Texte verwenden und am Ende alles mit `:Case imp done`
wieder entfernen (Test 17). Eine echte Notiz zu einem echten Kunden ist
gewollt — nur Testnotizen dürfen nicht übrig bleiben.

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case imp 977392` ohne Notizen | Info "no notes on file — `:Case imp add` writes one" | ❌ | |
| 2 | `:Case imp add 977392` | Erst Auswahl "Note for": **Case 977392**, **Company: Siemens Energy …**, **Contact: …** (Firma/Kontakt nur, wenn das Sidecar sie kennt) | ❌ | |
| 3 | Company wählen → Level wählen (`Hinweis`/`Eskalation`) → Formular | Formular fragt Text und "Valid until (YYYY-MM-DD)" | ❌ | |
| 4 | Eskalation `TEST: Manager urgiert First Response`, kein Datum, speichern | Meldung "saved: [ESKALATION · Firma: …] …" | ❌ | |
| 5 | `Cases/Important.jsonl` im Editor öffnen | **Eine** JSON-Zeile pro Notiz, lesbar | ❌ | |
| 6 | `:Case imp 977392` | Viewer zeigt die Notiz | ❌ | |
| 7 | `:Case info 977392` | Notiz steht **in der Karte** (unter den Feldern) | ❌ | |
| 8 | `:Case open 977392` | Hinweis erscheint **als Warnung** (wegen Eskalation), bevor die Datei aufgeht | ❌ | |
| 9 | `:Case imp 1229161` (andere Case, **dieselbe Firma**) | Dieselbe Notiz erscheint — Match über das Sidecar-Feld `company` | ❌ | |
| 10 | `:Case imp 1195796` (andere Firma) | Keine Notiz | ❌ | |
| 11 | Firmen-Match mit anderer Schreibweise (im Sidecar `company` kurz groß/klein ändern, danach zurück) | Match bleibt (Groß-/Kleinschreibung egal), aber **kein** Match bei ähnlichem anderem Namen | ❌ | |
| 12 | Notiz mit "Valid until" in der Vergangenheit (z. B. `2020-01-01`) | Erscheint nicht in `:Case imp`/Info/Open; `:Cases imp` zeigt sie als `abgelaufen 2020-01-01` | ❌ | |
| 13 | Ungültiges Datum `morgen` | Fehler "valid_until must be YYYY-MM-DD", nichts gespeichert | ❌ | |
| 14 | Leerer Text | Fehler, nichts gespeichert | ❌ | |
| 15 | `:Case new 999001` mit derselben Firma wie die Testnotiz (Company-Feld beim Anlegen) | Direkt nach dem Anlegen **eine** Meldung: "<Firma> hatte schon N Case(s): …" **und** die Notiz — nicht zwei getrennte Meldungen; Warnstufe wegen Eskalation | ❌ | |
| 16 | `:Case new` für eine Firma ohne frühere Cases/Notizen | **Keine** Meldung | ❌ | |
| 17 | `:Case imp done 977392` → Notiz wählen → bestätigen; auch Abgelaufene (Test 12) entfernen | "note retired"; `Important.jsonl` ist wieder leer bzw. ohne Testzeilen; `:Cases imp` meldet "no notes on file" | ❌ | |
| 18 | `:Case imp done`, Rückfrage mit **Nein** | Notiz bleibt | ❌ | |
| 19 | `:Cases imp` mit mehreren Notizen | Alle gelistet, Abgelaufene markiert | ❌ | |
| 20 | Eine Zeile in `Important.jsonl` von Hand kaputt machen (`{kaputt`) | `:Case info`/`:Case open` laufen **weiter** (Hinweis "teilweise unlesbar"); `:Case imp add` verweigert das Schreiben mit klarer Meldung; danach Zeile reparieren | ❌ | |
| 21 | `<Tab>` nach `:Case imp <Tab>` | `add` und `done` erscheinen neben den Case-Nummern | ❌ | |
| 21a | Eine Notiz mit Zeilenumbruch im Text (beim Eintippen `<C-v><CR>`/Einfügen mehrerer Zeilen, oder in `Important.jsonl` ein `\n` in `text` schreiben) | In `:Case info` und `:Case imp` **eine** Zeile, kein Fehler | ❌ | |
| 21b | In `Important.jsonl` eine Zeile **ohne** `id` von Hand anlegen, dann `:Case imp done` darauf | Nur diese eine Notiz verschwindet, andere id-lose Zeilen bleiben | ❌ | |
| 21c | `Important.jsonl.tmp` im Ordner `Cases/` nach dem Speichern | Existiert nicht (wird umbenannt) | ❌ | |
| 22 | Git: `Important.jsonl` im Status von `WKDBook-Tricentis` | Tauchen als Änderung auf; nach `done` wieder sauber (nicht committen, solange Testzeilen drin sind) | ❌ | |

#### A9 · `:Case preflight` und Hinweise (`1717d44`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case preflight <Tab>` | Schlägt `dex` vor | ❌ | |
| 2 | `:Case preflight dex 1226959` | Legt `Research/DEX_Preflight.md` an und öffnet sie: **Abschnitt 1 ist GPO/Anmeldung**, dann Gruppen, Logs, Tosca-Konfiguration; Checkboxen, Links klickbar | ❌ | |
| 3 | Erneut ausführen | Öffnet die vorhandene Datei, **überschreibt nichts** (vorher ein Häkchen setzen und prüfen) | ❌ | |
| 4 | `:Case new 999001` mit Titel `Unattended run stops after reboot` | Hinweis: `DEX (Stichwort „unattended“): … — :Case preflight dex` | ❌ | |
| 5 | `:Case activity` mit einem Stream, der "DEX agent"/"Distributed Execution" enthält | Derselbe Hinweis nach dem Einfügen (solange `DEX_Preflight.md` fehlt) | ❌ | |
| 6 | Nach `:Case preflight dex` im selben Case `:Case activity` erneut | **Kein** Hinweis mehr | ❌ | |
| 7 | `:Case new` mit Titel `How does the Execution List folder structure work?` | Scope-Frage "Consulting/Enablement statt Defekt?" samt zwei Wiki-Links | ❌ | |
| 8 | Titel `How to fix the error on startup` und `Unmapped Control after Fiori update` | **Kein** Scope-Hinweis | ❌ | |
| 9 | Titel ohne Stichwort (`Grid stays red`) | Gar kein Hinweis | ❌ | |
| 10 | `:Case preflight nope` | Warnung "unknown preflight topic", nichts angelegt | ❌ | |
| 11 | Gefühl: Nerven die Hinweise? | Nicht bei normalen Cases; nur wenn sie passen | ❌ | |

#### A10 · `:Case image getText` (`7717d0c`) — braucht `images.nvim` + `tesseract`

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case image getText 1201484` | Picker mit den Bildern aus `assets/` (mit Marker, ob ein Sidecar existiert) | ❌ | |
| 2 | `failed_login_errorlog.png` wählen, **ohne** Preset | Viewer: Kopfzeile `preset default`, Text zerrissen (≈51 Zeilen), **keine** JSON-Zeile | ❌ | |
| 3 | `:Case image getText 1201484 --preset=log` | `preset log`, ≈27 Zeilen, Zeile `JSON-Validierung: N/M Zeile(n) valide` (erwartet 1/24) | ❌ | |
| 4 | `y` im Viewer | Text in der Zwischenablage ("copied") | ❌ | |
| 5 | Vor `w` den Ordner prüfen | **Kein** `*.ocr.md` entstanden, nur durch Ansehen | ❌ | |
| 6 | `w` im Viewer | `failed_login_errorlog.png.ocr.md` entsteht; öffnen: H1, Bildlink, Warnhinweis, JSON-Zeile, Text | ❌ | |
| 7 | `:Cases grep` auf ein Wort aus dem OCR-Text | Findet jetzt die Sidecar-Datei | ❌ | |
| 8 | Case mit **einem** Bild | Wird ohne Auswahl direkt gelesen | ❌ | |
| 9 | Case ohne Bilder | Warnung "no images in assets/" | ❌ | |
| 10 | `<Tab>` nach `--preset=` | `default`, `log` | ❌ | |
| 11 | `tesseract` nicht erreichbar (nur wenn leicht machbar) | Klare Meldung mit Installationshinweis, kein Absturz | ❌ | |
| 12 | Dasselbe Bild danach mit `:Case ocr 1201484` | Sidecar ist "current", wird übersprungen | ❌ | |
| 13 | Viewer-Text und geschriebenes Sidecar | **Kein** `^M` am Zeilenende (Windows-CRs werden entfernt) | ❌ | |

#### A11 · `:Case translate` — Fix und `stream` (`9f104ba`) — braucht `language.nvim`, Internet

Der Fix ist wichtig: **vorher hat `:'<,'>Case translate` immer den ganzen Puffer
übersetzt.**

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | Puffer mit mehreren Absätzen, **einen** visuell markieren, `:'<,'>Case translate EN` | Popup übersetzt **nur die Auswahl** | ❌ | |
| 2 | Dasselbe ohne Auswahl | Der ganze Puffer | ❌ | |
| 3 | Auswahl über zwei, drei Zeilen (V-Modus) | Genau diese Zeilen | ❌ | |
| 4 | `:Case translate` ohne `[lang]` | Übersetzt nach `DE` | ❌ | |
| 5 | `:Case translate stream 977392` | Öffnet den Stream, Popup mit deutscher Übersetzung, Buffer unverändert | ❌ | |
| 6 | `:Case translate stream 977392 --to=FR` | Französisch | ❌ | |
| 7 | `:Case translate stream` im Case-Buffer ohne Nummer | Nimmt den Case des aktuellen Buffers | ❌ | |
| 8 | Case ohne Stream | Warnung "no Activity Stream found" | ❌ | |
| 9 | Ohne Internet | Klarer Fehler von `language.nvim`, kein Hänger | ❌ | |
| 10 | `<Tab>` nach `:Case translate <Tab>` | `stream` taucht auf | ❌ | |
| 11 | `language.nvim` deaktiviert | Warnung "language.nvim not installed" für beide Formen | ❌ | |

#### A12 · `:Case jql suggest` (`10ababe`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case jql suggest 977392` | `Research/JQL.md` öffnet sich mit dem Block "Aus den Fakten": eine Suche je Fehlercode/KBA, ggf. "Fehlercode in Version …", ggf. "SAP Component …, letzte 180 Tage" | ❌ | |
| 2 | Jede Suche als `jql`-Fence, in Jira einfügen | Gültige Syntax, liefert Treffer oder sinnvoll "keine" | ❌ | |
| 3 | Gerüst darüber (Platzhalter-Erklärung, eigener Text) | **Unverändert** | ❌ | |
| 4 | Erneut ausführen | **Ein** Block (ersetzt, nicht verdoppelt); Datum aktualisiert | ❌ | |
| 5 | Text unterhalb des Blocks von Hand ergänzen, erneut ausführen | Dein Text bleibt | ❌ | |
| 6 | Die Suchen enthalten **nie** den Case-Titel; kein `project =` | ✔ | ❌ | |
| 7 | Case ohne Stream | Warnung "`:Case activity` first" | ❌ | |
| 8 | Stream ohne Fehlercode/KBA/Component | Info "nothing to search for", nichts geschrieben | ❌ | |
| 9 | Plain `:Case jql 977392` | Öffnet weiterhin nur die Datei | ❌ | |
| 10 | In `JQL.md` die Zeile `<!-- casedesk:jql:end -->` löschen, eigenen Text darunter schreiben, `:Case jql suggest` zweimal | Genau **ein** Start-Marker bleibt; der eigene Text steht nach dem zweiten Lauf noch da | ❌ | |

#### A13 · Ablage und Doku

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `docs/ROADMAP/Casedesk/` in der nvim-Config | Nur `IMPLEMENTIERUNGSPLAN.md` und `Tasks.md` | ❌ | |
| 2 | `IMPLEMENTIERUNGSPLAN.md` dort öffnen | Auf dieser Maschine nur eine Textzeile mit dem Zielpfad (`E:/…`) — **echten Symlink anlegen** (erhöhte PowerShell, Befehl in §6 des Plans); danach zeigt die Datei den Plan | ❌ | |
| 3 | Plan lesen: `WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/IMPLEMENTIERUNGSPLAN.md` | Stand, Stufen, was offen ist, stimmt mit dem überein, was du erlebst | ❌ | |
| 4 | `ROADMAP/ROADMAP.md` lesen | Nur Offenes, keine erledigten Punkte | ❌ | |
| 5 | `:help casedesk` / `CHEATSHEET.md` | Neue Befehle (`imp`, `preflight`, `jql suggest`, `image getText`, `spotlight`, `translate stream`) stehen im Cheatsheet; `doc/casedesk.txt` ist **noch nicht** nachgezogen (Lücke, ggf. eigener Punkt) | ❌ | |

#### A14 · `:Cases wordings <kind>`

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Cases wordings firstResponse` | `Workflow/Templates/FirstResponses/FirstResponse.md` öffnet sich; Meldung "copied FirstResponse.md" | ❌ | |
| 2 | Direkt danach in ein anderes Fenster / Browser einfügen | Der Text ist da, unverändert, `<<customer>>` steht noch | ❌ | |
| 3 | `:Cases wordings firstResponseDelay` | `FirstResponse_Delay.md` öffnet sich, Text in der Zwischenablage | ❌ | |
| 4 | `:Cases wordings germanSpeaker` | `Workflow/Templates/GermanSpeaker.md` öffnet sich, Text ("I noticed that your account is located in the DACH region …") in der Zwischenablage | ❌ | |
| 5 | `<Tab>` nach `:Cases wordings <Tab>` | Schlägt `firstResponse`, `firstResponseDelay`, `germanSpeaker` vor | ❌ | |
| 6 | `:Cases wordings nope` | Fehler/Usage, nichts kopiert | ❌ | |
| 7 | Die alten Namen `:Cases firstResponse` / `:Cases firstResponseDelay` | Gibt es nicht mehr (Usage statt Aktion) | ❌ | |
| 8 | Aus einem beliebigen Buffer (kein Case) aufrufen | Funktioniert, keine Case-Auswahl nötig | ❌ | |
| 9 | Datei kurz umbenennen, Befehl aufrufen | Warnung "wording not readable", nichts kopiert; danach zurückbenennen | ❌ | |

#### A15 · `:Case pdf` (`26af2c7`) — braucht `pdftotext` (poppler)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:checkhealth casedesk` | `pdftotext` unter den optionalen Werkzeugen, "ready" mit Pfad | ❌ | |
| 2 | In einem Case mit PDF in `assets/`: `:Case pdf` | "reading N PDF(s)…", dann "N PDF(s) read, 0 already current"; neben jedem PDF liegt `<name>.pdf.text.md` | ❌ | |
| 3 | `:Case pdf` gleich nochmal | "all N PDF(s) already read", nichts neu geschrieben | ❌ | |
| 4 | `:Case pdf --force` | Liest alle erneut | ❌ | |
| 5 | Ein Wort, das nur im PDF steht, mit `:Cases grep <wort>` suchen | Treffer in der `.pdf.text.md` | ❌ | |
| 6 | Case ohne PDF | Warnung "no PDFs in assets/" | ❌ | |
| 7 | Gescanntes PDF (ohne Textebene) | Meldung "without a text layer (scanned? needs OCR)", keine leere Sidecar-Datei | ❌ | |
| 8 | `:Case similar` vor und nach `:Case pdf` | Ranking unverändert — PDF-Sidecars fließen absichtlich nicht ein | ❌ | |

#### A16 · Stufe 3 im Überblick (`83cdb3a`, `47dd570`, `8c97c06`, `a131d69`, `b3af13f`, `61607ae`, `07fd742`)

Ausführliche Zeilen stehen noch aus; erst die Rauchprobe:

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case promote` an einem Case mit bestätigter Lösung | Dedup-Prüfung, Kundennamen ersetzt, Datei in `Cases/Solutions/` | ❌ | |
| 2 | `:Case tag` / `:Cases tag <Tag>` | Tag nur aus dem geschlossenen Vokabular; Zeile in der Infocard; `:Case similar` hat eine Tag-Achse | ❌ | |
| 3 | `:Case fingerprint` | Cases mit demselben Fehlerstring; dritte Achse in `:Case similar` | ❌ | |
| 4 | `:Tricentis pto` / `pto back` | Checkliste, Mails mit Rückkehrdatum, offene Cases mit Frist im Zeitraum | ❌ | |
| 5 | `:Case history` und `:Case info` | Git-Verlauf des Case-Ordners; die Git-Zeile in der Karte erscheint nach dem Öffnen (asynchron) | ❌ | |
| 6 | `:Cases solutions` mit unbestätigter Lösung | Unbestätigte ranken unten und sind markiert | ❌ | |
| 7 | Case mit `:Case imp`-Notiz im Pin-Chip | Chip trägt die Markierung | ❌ | |

---

### Teil B — aus der Vorsitzung (2026-09-30) noch ungetestet

Die ausführlichen Zeilen mit Erwartungen stehen in
`WKDBooks/Development/wkdbook-myplugins/ALL/manual-test-checklists/casedesk-neu-2026-09-30.md`
(dort 51 Zeilen offen) — hier nur die Blöcke und was bei jedem **zuerst**
zu prüfen ist. Status bitte in **dieser** Datei führen und in der anderen
nachziehen, wenn du magst.

| # | Block (Commit) | Zuerst prüfen | Status | Notizen |
| --- | --- | --- | --- | --- |
| B1 | SNOW-Aliase `:Cases account`/`contact`, `find account=` (`7222d0c`) | `:Cases account <Firma>` liefert dasselbe wie `:Cases company <Firma>` | ❌ | |
| B2 | `:Case open` → `Summary.md` (`a929e1c`, `c67f99f`) | Öffnet `Summary.md` direkt, **danach** Reveal im Filetree; Case ohne Summary öffnet neueste Datei | ❌ | |
| B3 | `:Case attachments find`/`insert` (`0e5fae0`) | `find` zeigt Anhänge **aller** Cases; `insert` öffnet den nativen Dateidialog und verschiebt nach `assets/` | ❌ | |
| B4 | Filetree-Reveal (`e6f5163`) | Kein Fehler "reveal nicht vorhanden", Baum zeigt die Datei | ❌ | |
| B5 | `:Case clean` und Auto-Cleanup in `:Case ki import` (`978fd82`) | `utm_source=gemini` und `$\rightarrow$` verschwinden; `clean cwd` fragt vor dem Schreiben | ❌ | |
| B6 | `:Case swat` und `:Case sync` (`042e8a1`) | `SWAT/Technicals.md` bei neuem Case; bei altem Warnung, nach `:Case sync` vorhanden | ❌ | |
| B7 | **`:Cases doctor` gegen den echten Bestand** (`204ccd0`, `ccfcef7`) | Funde `stale-unconfirmed`; **`:Cases normalize` verschiebt echte Ordner `Open` → `Closed`** — erst mit Wegwerf-Case, dann Trockenlauf-Viewer genau lesen. Das ist der offene Handgriff `RM-05` c | ❌ | |
| B8 | `docs-thin` (`f116ab8`) | Siehe A4 oben | ❌ | |
| B9 | `:Case ocr --preset=log` und JSON-Zeile im Sidecar (`eb61531`, `5998c00`) | `--preset=log` liefert Zeilenstruktur; Sidecar enthält die JSON-Validierungszeile | ❌ | |
| B10 | `:Case insert asset` setzt den Cursor in den Link (`dd58bc1`) | Nach dem Einfügen steht der Cursor im Linktext | ❌ | |
| B11 | `:Case translate` Grundfunktion (`f7cffee`) | Siehe A11 | ❌ | |

---

### Teil C — Smoke-Inventar aller Routen

Eine Zeile je Route aus `docs/commands.md`: einmal ausführen, prüfen, dass sie
tut, was die Beschreibung sagt, und **nichts wirft**. Detail-Erwartungen für die
älteren Befehle: `ALL/manual-test-checklists/casedesk.md` (81 Zeilen, alle noch
❌). Mit ★ markiert: neu oder geändert am 2026-10-02 (Details in Teil A).

Wegwerf-Case benutzen für alles, was schreibt, verschiebt oder löscht.

#### `:Case` — ein Case

_Seit dem 2026-10-07 neu oder geändert, Details in K: `:Case new --form|--steps` (K8), `:Case insert` mit `snow-url`/`sap-*` (K10), `:Case links add|open` und `Links.md` (K11), `:Case checklist`, `:Case clipboard ask` (K12), `:Case import` (K4), `:Cases clipboard` (K3, K9)._

| # | Route | Smoke | Status | Notizen |
| --- | --- | --- | --- | --- |
| C1 | `:Case` | Infocard des aktuellen Buffers, sonst Auswahl | ❌ | |
| C2 | `:Case new [nr]` ★ | Fragt fehlende Felder, Vorschau, Bestätigung, legt an; danach ggf. Firmen-/Notiz-/Preflight-Hinweis (A8, A9) | ❌ | |
| C3 | `:Case info [nr]` ★ | Karte mit Feldern; Notizen erscheinen (A8); `e`/`s`/`o` | ❌ | |
| C4 | `:Case open [nr]` ★ | Öffnet `Summary.md`, Reveal; Notiz-Hinweis (A8) | ❌ | |
| C5 | `:Case summary` / `notes` / `research` / `reply` / `task` / `swat` / `jql` | Öffnet jeweils die Datei; fehlend → Hinweis auf `:Case sync` | ❌ | |
| C6 | `:Case sync [nr]` | Legt fehlende Blueprint-Dateien an, überschreibt nichts | ❌ | |
| C7 | `:Case activity [nr]` ★ | Zwischenablage als `Research/NN_ActivityStream.md`; Priorität/Komponente/Versionen werden erkannt; Preflight-Hinweis (A9) | ❌ | |
| C8 | `:Case add <name> [suffix]` | Neue Markdown-Datei, `reply [suffix]` nummeriert | ❌ | |
| C9 | `:Case import [src]` (früher `:Case copy`, bleibt als Alias mit Hinweis) | Kopiert Datei in den Case, Zielordner wählbar; Details K4 | ❌ | |
| C10 | `:Case attachments [nr]` | Liste der Anhänge, Öffnen | ❌ | |
| C11 | `:Case attachments find` / `insert` | Siehe B3 | ❌ | |
| C12 | `:Case files [nr]` / `:Case grep [nr]` | Picker bzw. Live-Grep im Case-Ordner (pickers.nvim) | ❌ | |
| C13 | `:Case insert [field] [nr]` | Fügt Token am Cursor ein und kopiert; `asset` setzt Cursor in den Link (B10) | ❌ | |
| C14 | `:Case template [name]` | Fügt Reply-Block aus `Workflow/Templates` ein | ❌ | |
| C15 | `:Case reply check` | Gate: Emojis, Überschriften, tote Links; `c`/`s` im Viewer | ❌ | |
| C16 | `:Case links [nr]` | Doku-Links mit falscher Tosca-Version | ❌ | |
| C17 | `:Case versions [component] [nr] [--all] [--raw]` | Versions-Digest aus ToscaSupportInfo | ❌ | |
| C18 | `:Case snow [nr]` | Öffnet bzw. kopiert die SNOW-Ticket-ID | ❌ | |
| C19 | `:Case sla [nr] [--doc]` | Drei Uhren mit Restzeit; `--doc` öffnet die Vereinbarung | ❌ | |
| C20 | `:Case timeline [nr]` | Arbeitssitzungen; Pull-Stempel als "nicht messbar" | ❌ | |
| C21 | `:Case similar [nr] [n]` ★ | Ähnliche Cases mit Trefferwörtern; Synonyme (A2) | ❌ | |
| C22 | `:Case diff stream\|solution <andere> [nr]` | diff.nvim vergleicht (A: Stream oder Lösung) | ❌ | |
| C23 | `:Case solution [nr] [--edit]` | Lösungs-Viewer, `e`/`y`; ohne Lösung Angebot zum Anlegen | ❌ | |
| C24 | `:Case ki [nr]` ★ | Prompt in die Zwischenablage, Faktenblock inkl. Engine-Steckbrief (A5) | ❌ | |
| C25 | `:Case ki import [nr]` ★ | Teilt die Antwort in Analyse/Reply/Notiz; Schreibweise (A3), Paste-Cleanup (B5) | ❌ | |
| C26 | `:Case anonymize [nr]` ★ | Siehe A1 | ❌ | |
| C27 | `:Case clean [cfile\|cwd\|path=…]` | Siehe B5 | ❌ | |
| C28 | `:Case ocr [nr] [--force] [--lang] [--preset]` | Sidecars für alle Bilder (nur bei neuem/geändertem Bild) | ❌ | |
| C29 | `:Case image getText [nr] [--preset] [--lang]` ★ | Siehe A10 | ❌ | |
| C30 | `:Case spotlight [nr]` ★ | Siehe A6 | ❌ | |
| C31 | `:Case jql suggest [nr]` ★ | Siehe A12 | ❌ | |
| C32 | `:Case translate [lang]` ★ / `translate stream` ★ | Siehe A11 | ❌ | |
| C33 | `:Case preflight <topic> [nr]` ★ | Siehe A9 | ❌ | |
| C34 | `:Case imp` / `imp add` / `imp done` ★ | Siehe A8 | ❌ | |
| C35 | `:Case route [nr]` | Fragt Abteilung (`config.routing_targets`), schreibt `routed_to` | ❌ | |
| C36 | Zustandswechsel `:Case solved` / `t2` / `assigned` / `unassigned` / `reassign` / `otheragent` | Verschiebt in den Zustandsordner; bei CS-Case kein `t2` | ❌ | |
| C37 | `:Case close [nr]` | Zielauswahl; bei Solved/Closed Angebot zur Lösung und ggf. Abteilung | ❌ | |
| C38 | `:Case reopen [nr]` | Zurück nach `Open` | ❌ | |
| C39 | `:Case delete [nr]` | Verlangt die Case-Nummer als Bestätigung; löscht wirklich (nur Wegwerf-Case!) | ❌ | |

#### `:Cases` — der Querschnitt

| # | Route | Smoke | Status | Notizen |
| --- | --- | --- | --- | --- |
| C40 | `:Cases` / `:Cases list` | Alle Cases nach Zustand; `m` markiert, `c` schließt Markierte | ❌ | |
| C41 | `:Cases recent [n]` / `stale [days]` | Zuletzt benutzt bzw. lange unberührt | ❌ | |
| C42 | `:Cases stats` | Zähler nach Bereich/Zustand/Firma/Jahr | ❌ | |
| C43 | `:Cases area [SAP\|CS]` | Cases eines Bereichs, ohne Argument mit Zählern | ❌ | |
| C44 | `:Cases company\|name\|account\|contact\|title\|notes\|priority\|tosca_version\|outcome\|routed_to <pattern> [--exact] [--re]` | Filtert; Aliase (B1) | ❌ | |
| C45 | `:Cases find key=value …` | AND-Verknüpfung | ❌ | |
| C46 | `:Cases history [company]` | Alle Cases einer Firma nach Zustand | ❌ | |
| C47 | `:Cases grep <pattern> [--re]` / `livegrep` / `files` | Volltext über alle Cases; OCR-Sidecars werden gefunden | ❌ | |
| C48 | `:Cases insert [pattern]` | Token eines **anderen** Cases einfügen | ❌ | |
| C49 | `:Cases sla` / `sla report [--year]` | Dashboard bzw. Bericht | ❌ | |
| C50 | `:Cases solutions [pattern]` ★ | Suche über alle Lösungen; Synonyme (A2) | ❌ | |
| C51 | `:Cases terminology` | Alle Begriffe aller `Terminologie.md` | ❌ | |
| C52 | `:Cases doctor` ★ / `normalize` | Funde (u. a. `docs-thin` mit eigenem Text, `stale-unconfirmed`); `normalize` mit Trockenlauf (B7) | ❌ | |
| C53 | `:Cases links check [nr]` | Prüft docs.tricentis.com-Links auf tote Seiten | ❌ | |
| C54 | `:Cases export [nr]` ★ | PDF aus Summary/Notes/Research/Replies (A7) | ❌ | |
| C55 | `:Cases close` | Mehrere Cases schließen (Markierungen oder Multi-Select) | ❌ | |
| C56 | `:Cases pickers` | Menü: Anhänge, Links, Cases ohne Sidecar, Terminologie, Befehle, Lösungen | ❌ | |
| C57 | `:Cases imp` ★ | Alle Notizen (A8) | ❌ | |
| C57a | `:Cases wordings <kind>` ★ | Siehe A14 | ❌ | |

#### `:Tricentis` — über den Case-Baum hinaus

| # | Route | Smoke | Status | Notizen |
| --- | --- | --- | --- | --- |
| C58 | `:Tricentis` / `links [scope]` | Links aus dem ganzen Arbeits-Repo | ❌ | |
| C59 | `:Tricentis commands [topic]` | Picker, Auswahl landet in der Zwischenablage; `enginelab` ist ein Topic | ❌ | |
| C60 | `:Tricentis cheatsheet [topic]` | Gruppierter Scratch-Puffer aller Befehle | ❌ | |

---

### Teil D — Keymaps, Autocmds, Health

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| D1 | Globale Keymaps | **Keine** — `:verbose map <leader>` zeigt nichts von casedesk | ❌ | |
| D2 | `:Cases list` Viewer | `m` (n/x) markiert, `c` schließt Markierte, `q`/`Esc` schließt | ❌ | |
| D3 | `:Case info` Viewer | `e` Formular, `s` Summary, `o` Ordner | ❌ | |
| D4 | `:Case reply check` Viewer | `c` (nur bei Emojis) entfernt sie, `s` Spellcheck | ❌ | |
| D5 | `:Case solution` Viewer | `e` bearbeiten, `y` kopiert den Abschnitt `## Lösung` | ❌ | |
| D6 | **neu:** `:Case image getText` Viewer ★ | `y` kopiert Text, `w` schreibt Sidecar, `q` schließt (A10) | ❌ | |
| D7 | **neu:** `:Case imp` / `:Cases imp` Viewer ★ | Schließt mit `q`/`Esc`, bei Fokusverlust | ❌ | |
| D8 | Autocmd `FocusGained` (`CasedeskSlaNotify`) | Zurück zu Neovim mit überfälligem P1/P2-Case offen → Warnung | ❌ | |
| D9 | Autocmd `BufEnter`/`BufWinEnter`/`WinEnter` (`CasedeskPin`) | Zwischen zwei Case-Buffern wechseln → Pin-Chip zeigt den neuen Case sofort | ❌ | |
| D10 | `:Case imp` im **Pin-Chip** | Noch **nicht** gebaut (Folgepunkt) — nichts erwarten | ❌ | |
| D11 | `:checkhealth casedesk` | Siehe V2 | ❌ | |
| D12 | `:Lib deps show casedesk.nvim` | Zeigt die deklarierten Werkzeuge (pandoc, Chromium, tesseract, curl, ripgrep) mit Status | ❌ | |
| D13 | Statusline | SLA-Badge und Case-Label arbeiten weiter | ❌ | |

---

### Nach dem Durchlauf

- [ ] Gefundene Fehler als `RM-nn` in die Roadmap oder als GitHub-Issue
      (`StefanBartl/casedesk.nvim`) — nicht nur hier.
- [ ] Alle **Testnotizen** aus `Cases/Important.jsonl` entfernt, alle
      Wegwerf-Cases (`999001`) gelöscht, `git status` in `WKDBook-Tricentis` sauber.
- [ ] Diese Datei committen (`docs(casedesk): live-test results …`), damit der
      Stand über Sitzungen hinweg erhalten bleibt.
- [ ] Wenn ein Block ✅ ist: Zeile in `ALL/manual-test-checklists/casedesk-neu-2026-09-30.md`
      bzw. `casedesk.md` mit abhaken, damit die beiden Listen nicht auseinanderlaufen.

---

## N. Blocker aller Tasks (Stand 2026-10-07)

Drei Arten von Blockern, getrennt: was von **außen** kommt (N1), was **auf dich** wartet (N2) und was **Tasks gegenseitig**
aufhält (N3, N4). N2 bis N4 sind aus dem Task-Vault `wkdbook-myplugins` erzeugt (`ROADMAP/tasks/*.md`, Feld `status`,
`blocked_by`, `actor`); neu erzeugen mit `nvim --headless -u NONE -l scripts/tasks.lua list --actor=me` bzw. `list --waiting`.

### N1. Externe Blocker (kein Task kann sie lösen)

| Blocker | Betrifft | Wartet auf | Task / Ort |
|---|---|---|---|
| IT-Antwort zur Datenfreigabe | `ki-datenfreigabe-klaeren` | schriftliche IT-Antwort je Datenklasse (kunde, anhang, intern) und je Provider; Google Translate/DeepL für Kundentext. Bis dahin strenge Variante (Owner-Entscheidung 2026-10-06: Anonymisierung Pflicht, Policy-Texte nur mit `--inline`, Übersetzer nur per Allow-List). Task bleibt `decision`. | casedesk.nvim/ROADMAP/tasks |
| Claude: Live-Lauf | ai.nvim `review-restpunkte` | Account mit API-Guthaben (der eingeloggte meldet "Credit balance is too low"). Ungeprüft: reale stream-json-Ereignisform, Wirkung der Deny-Regel gegen `@pfad`, `CLAUDE_CODE_DISABLE_ATTACHMENTS`, Label `User message:` gegen lokale Slash-Befehle. | ai.nvim/ROADMAP/tasks/review-restpunkte |
| Claude: Websuche | ai.nvim `capabilities-web` | Guthaben + Aktivierung im Konto + Datenschutzentscheidung (Websuche schickt Anfragetext an Dritte). Kein Provider setzt `web = true`, bevor der Such-Parameter an der echten API geprüft ist. Task kann auch verworfen werden. | ai.nvim/ROADMAP/tasks/capabilities-web |
| Copilot: Fehlerform | ai.nvim `copilot-fehlerereignis-mitten-im-lauf-aufzeichnen` | ein Konto, das gerade scheitert (Guthaben alle, Rate-Limit, kein Login), um die Fehlerereignisse aufzuzeichnen. Bis dahin als "unverifiziert" markiert; der Provider fällt auf Exit-Code/stderr zurück und liefert nie eine halbe Antwort. | ai.nvim/ROADMAP/tasks |
| Copilot "auto" | Datenschutzfrage | Entscheidung, ob `model` fest gepinnt wird (`auto` routet über Modelle mehrerer Anbieter). | ai.nvim `copilot`-Provider |
| SAP-Resolve-Link aus der Case-Nummer | `casedesk.nvim/resolve-link-from-case-number` (RM-47) | die Regel für den 10-stelligen Präfix `0020751294` / `0020751295` (nicht aus Firma, GUID oder Jahr ableitbar): Messreihe über die nächsten Cases (Kunde, Produkt, SAP-Komponente) führen. Erst dann baut sich der Generator. | wkdbook-myplugins/casedesk.nvim/ROADMAP/tasks |
| Case-Daten im Arbeits-Repo | `casedesk.nvim/case-0498885-wrong-number-and-link` (RM-49) | Reparatur durch dich: `.case.json` von `Cases/CS/Open/0498885` trägt die Nummer `049885` und einen Firmennamen als Link. Die Daten wurden bewusst nicht angefasst. | WKDBook-Tricentis |
| CI-Reihenfolge ui.nvim/lib.nvim | ui.nvim-CI (`kit_drift_spec`) | ui.nvims CI liest den Branch `ci-verified` von lib.nvim; bis lib.nvims CI nach den Kit-Spiegel-Commits (zuletzt `d9c6cdb`) vorgerückt ist, kann der Drift-Check dort rot sein (lokal grün). | lib.nvim CI |

---

### N2. Was auf dich wartet (Entscheidung, Live-Abnahme, Handarbeit)

38 offene Tasks mit `actor=me` (dazu zählen Status `decision` und das Tag `needs-user`). Quelle: `nvim --headless -u NONE -l scripts/tasks.lua list --actor=me` im nvim-Config-Ordner.

| Task | Status | Prio | Was |
| --- | --- | --- | --- |
| `casedesk.nvim/ki-datenfreigabe-klaeren` | decision | 1 | KI-Datenfreigabe klären: Kundendaten, interne Policies, Google Translate |
| `docmap-desktop/live-test-installed-app` | open | 2 | Walk through the installed v0.6.0 app once (A1) |
| `docmap-desktop/live-test-traffic-surface` | open | 2 | Look at the GitHub traffic surface against a genuine fetch (A3) |
| `terminal.nvim/live-check` | open | 2 | terminal.nvim: Live-Abnahme in WezTerm (Windows) und tmux (WSL) |
| `testing.nvim/ui-concept-test-explorer` | decision | 2 | UI-Konzept: Test-Explorer als moderne Baum-Ansicht (Stil Neo-tree, eventuell auf ui.nvim) |
| `ai.nvim/release-demo-assets` | open | 3 | Release-Medien: Demo-GIF, Logo und Social-Preview (REL-09, REL-33) |
| `ALL/claude-account-live-test-session` | open | 3 | Claude-Account-Testsession - ai.nvim, loomAI, rules.nvim, documentation.nvim, docmap-desktop |
| `ALL/plugin-roadmaps-testplan-run` | open | 3 | Plugin-Roadmaps-Testplan von Hand durchlaufen (hover, lsp, mdview, images, documentation, ...) |
| `ALL/release-showcase-umbrella` | parked | 3 | Release und Schaufenster je Repo - Git-Release, Demo, Logo, Social-Preview, Root-README-Highlights |
| `ALL/ux-backlog-live-checklist-run` | open | 3 | UX-Backlog-Live-Checkliste (T1, T3, T4, T5, T9, Fokus) in der echten Sitzung durchlaufen |
| `buffer-ctx.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `cascade.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `cmdlog.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `dap.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `debugging.nvim/views-dead-refresh-sweep` | decision | 3 | Remove the dead tag-refresh machinery in views |
| `diff.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `docmap-desktop/live-test-engine-panel-and-call-edge-popup` | open | 3 | Look at the collapsed Engine panel and the call-graph edge popup in the app |
| `docmap-desktop/live-test-neovim-side-checks` | open | 3 | Check the traffic browse mode and the rules loader in Neovim against real data |
| `docmap-desktop/macos-menu-bar-variant` | open | 3 | A documented macOS variant of the menu bar, and a first look at the app on a Mac |
| `emojis.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `fileops.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `hover.nvim/demo-gif` | open | 3 | Demo-GIF fuer das README (REL-09), aufnehmbar mit ui.screenkey |
| `images.nvim/image-suite-decision` | decision | 3 | Entscheidung: dünnes Image-Suite-Meta-Plugin ja oder nein |
| `images.nvim/sixel-backend-evaluation` | decision | 3 | Sixel-Backend prüfen |
| `nvim-config/bindings-checklist-run` | blocked | 3 | Bindings-Laufzeit-Checkliste von Hand durchlaufen ("mappings durchchecken") |
| `nvim-config/context-open-review` | open | 3 | `context_open` (`M-o`) ausprobieren und prüfen, ob er erweitert werden soll |
| `nvim-config/live-check-structure-jump-and-bindings-check` | open | 3 | Live-Prüfung des Struktur-Sprungs `[u`/`]u` und der Source-Achse von `:Bindings check` |
| `nvim-config/neotest-live-checks-own-session` | open | 3 | neotest in der eigenen Sitzung ansehen (Kontextmenü-Klick K8, Statuszeichen) |
| `nvim-config/ohana-startup-remeasure` | open | 3 | OHANA (Neovim 0.11.4) mit UI neu messen |
| `nvim-config/upstream-appexeclink-executable-report` | open | 3 | Neovim-Issue - `executable()` ist für App Execution Aliases falsch, `vim.system()` startet sie |
| `nvim-config/upstream-neotest-reports` | open | 3 | neotest-Befunde upstream melden (Windows-Plenary-Hänger, unauthentifizierter Listener) |
| `recommender.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `reposcope.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `runtime-analysis.nvim/mdview-theme-parity` | decision | 3 | mdview-Theme: wer bestimmt, wie der Browser-Bericht aussieht |
| `sandbox.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `sessions.nvim/manual-checklist-run` | blocked | 3 | Manuelle Testcheckliste von Hand durchlaufen |
| `ui.nvim/release-demo-assets` | open | 3 | Release media: README demo GIF, screenshots, social preview |
| `ui.nvim/slots-live-check` | open | 3 | ui.slots: Live-Abnahme in der echten Konfiguration |

---

### N3. Wurzel-Blocker: ein Task hält viele andere auf

71 Tasks stehen auf `blocked`. Hier nach dem Task gruppiert, der am Ende der Kette steht (`blocked_by` bis zu einem Task, der selbst nicht blockiert ist). Wer diese Tasks anstößt oder entscheidet, löst die Ketten darunter. Ein Task ohne Status `blocked` in der Spalte "Status" ist der eigentliche Engpass.

| Engpass | Status | Hält auf | Davon (Auszug) |
| --- | --- | --- | --- |
| `testing.nvim/m1-runner` — M1 Runner, der nicht lügt: CLI, Exit-Codes, Discovery, Reporter | doing | 18 | `docmap-desktop/testing-nvim-integration`, `documentation.nvim/testing-nvim-integration`, `testing.nvim/explorer-on-filetree-engine`, `testing.nvim/fleet-plenary-removal-rollout` +14 |
| `testing.nvim/ui-concept-test-explorer` — UI-Konzept: Test-Explorer als moderne Baum-Ansicht (Stil Neo-tree, eve | decision | 9 | `testing.nvim/explorer-on-filetree-engine`, `testing.nvim/ui-explorer-actions`, `testing.nvim/ui-explorer-docs-tests`, `testing.nvim/ui-explorer-filters` +5 |
| `rules.nvim/agent-plan-validate` — Agent-Plan und Validierung (engine/agent/plan.lua, validate.lua) | open | 7 | `docmap-desktop/checklist-items-as-agent-input`, `docmap-desktop/rules-agent-job-runner-and-loomai-client`, `docmap-desktop/rules-api-plan-and-validate`, `docmap-desktop/rules-run-chat` +3 |
| `documentation.nvim/i18n-catalog-infrastructure` — Interface languages: catalog infrastructure and the English source cat | open | 7 | `documentation.nvim/i18n-cjk`, `documentation.nvim/i18n-contribution-path`, `documentation.nvim/i18n-editor-and-cli-messages`, `documentation.nvim/i18n-generated-page` +3 |
| `testing.nvim/m5-fast-affected-cache` — M5 Schnell: Cache, --affected, Worker-Pool, Shard, Watch | open | 7 | `testing.nvim/m6-snapshots-and-tier1`, `testing.nvim/m7-quality`, `testing.nvim/m8-multilang-and-tier25-3`, `testing.nvim/m9-cutting-edge` +3 |
| `testing.nvim/m3-ui-and-debug` — M3 UI und Debug ohne eigene UI: neotest-Adapter, --debug, :Testing-Com | open | 6 | `testing.nvim/ui-explorer-actions`, `testing.nvim/ui-explorer-docs-tests`, `testing.nvim/ui-explorer-filters`, `testing.nvim/ui-explorer-live-run` +2 |
| `testing.nvim/lib-harness-bootstrap` — lib.nvim behält TESTS/harness.lua als Bootstrap-Kern | open | 4 | `testing.nvim/fleet-plenary-removal-rollout`, `testing.nvim/m1-fleet-parity`, `testing.nvim/release-gate-first-alpha`, `testing.nvim/run-all-tests-sh-json-loop` |
| `testing.nvim/conformance-suite-k1-k15` — Konformitäts-Suite K1 bis K15 (Regeln, die laufen) | open | 4 | `testing.nvim/m4-conformance-and-coverage`, `testing.nvim/m6-snapshots-and-tier1`, `testing.nvim/pilot-pickers-nvim`, `testing.nvim/pilot-sessions-nvim` |
| `testing.nvim/binding-coverage-engine` — Binding-Coverage aus der Registry und :Testing surface | open | 4 | `testing.nvim/m4-conformance-and-coverage`, `testing.nvim/m6-snapshots-and-tier1`, `testing.nvim/pilot-pickers-nvim`, `testing.nvim/pilot-sessions-nvim` |
| `docmap-desktop/rules-api-catalog-and-run` — --api=rules in the standalone engine: catalog and run, and the bundle  | open | 2 | `docmap-desktop/rules-tab-list-and-mechanical-run`, `docmap-desktop/rules-trust-store-for-predicates` |
| `filetree.nvim/provider-contract` — Provider contract: register a tree once, get engine window and Neo-tre | open | 2 | `filetree.nvim/neotree-custom-source-bridge`, `testing.nvim/explorer-on-filetree-engine` |
| `ai.nvim/agent-presets` — Benannte Agenten-Presets (Provider, Modell, System-Prompt) | open | 1 | `ai.nvim/repo-instructions-and-hooks` |
| `buffer-ctx.nvim/manual-checklist-update` — Manuelle Testcheckliste auf den heutigen Funktionsumfang bringen | open | 1 | `buffer-ctx.nvim/manual-checklist-run` |
| `cascade.nvim/manual-checklist-update` — Manuelle Testcheckliste auf den heutigen Funktionsumfang bringen | open | 1 | `cascade.nvim/manual-checklist-run` |
| `casedesk.nvim/doc-link-library` — Belegte Doku-Referenzen: kuratierte Link-Bibliothek je Thema | open | 1 | `casedesk.nvim/doc-citation-finder` |
| `casedesk.nvim/doctor-stale-unconfirmed-live-run` — :Cases doctor gegen den echten Workspace laufen lassen | open | 1 | `casedesk.nvim/open-cases-recheck` |
| `casedesk.nvim/translate-activity-pipeline` — :Case activity: optional anonymisieren und übersetzen | open | 1 | `casedesk.nvim/translate-ki-import-german-note` |
| `cmdlog.nvim/manual-checklist-update` — Manuelle Testcheckliste von zwei entfernten Funktionen befreien und na | open | 1 | `cmdlog.nvim/manual-checklist-run` |
| `dap.nvim/manual-checklist-update` — Manuelle Testcheckliste auf den heutigen Funktionsumfang bringen | open | 1 | `dap.nvim/manual-checklist-run` |
| `lib.nvim/messages-status` — messages.status(): attach and renderer state | open | 1 | `debugging.nvim/health-recent-popup-requirements` |
| `diff.nvim/manual-checklist-update` — Manuelle Testcheckliste auf den heutigen Funktionsumfang bringen | open | 1 | `diff.nvim/manual-checklist-run` |
| `docmap-desktop/live-test-installed-app` — Walk through the installed v0.6.0 app once (A1) | open | 1 | `docmap-desktop/release-v0-6-1-decision` |
| `docmap-desktop/live-test-traffic-surface` — Look at the GitHub traffic surface against a genuine fetch (A3) | open | 1 | `docmap-desktop/release-v0-6-1-decision` |
| `emojis.nvim/manual-checklist-update` — Manuelle Testcheckliste auf den heutigen Funktionsumfang bringen | open | 1 | `emojis.nvim/manual-checklist-run` |
| `fileops.nvim/manual-checklist-update` — Manuelle Testcheckliste auf das Bestätigen statt Verweigern und die ne | open | 1 | `fileops.nvim/manual-checklist-run` |
| `lsp.nvim/deprecated-help-hover` — deprecated_help: offer a hover instead of opening a help split | open | 1 | `lsp.nvim/deprecated-help-word-under-cursor` |
| `lib.nvim/clipboard-utf8-scrubber` — Clipboard-UTF-8-Scrubber als lib.nvim-Modul | open | 1 | `my.nvim/clipboard-scrubber-spec` |
| `nvim-config/bindings-checklist-update` — Bindings-Laufzeit-Checkliste neu erzeugen und den Ausgabeordner repari | open | 1 | `nvim-config/bindings-checklist-run` |
| `ai.nvim/openai-documents-live-check` — openai: file-Part gegen die echte API prüfen und documents = true setz | open | 1 | `pdfport.nvim/openai-extraction-backend` |
| `recommender.nvim/manual-checklist-update` — Manuelle Testcheckliste auf den heutigen Funktionsumfang bringen | open | 1 | `recommender.nvim/manual-checklist-run` |
| `pickers.nvim/generic-items-source` — Generic items source for the engines (rows, preview callback, actions, | open | 1 | `replacer.nvim/pickers-nvim-list-migration` |
| `reposcope.nvim/manual-checklist-update` — Manuelle Testcheckliste auf den heutigen Funktionsumfang bringen | open | 1 | `reposcope.nvim/manual-checklist-run` |
| `documentation.nvim/runtime-tab-grouping` — Group the runtime tools under one Runtime tab | open | 1 | `runtime-analysis.nvim/persistent-data-panel` |
| `sandbox.nvim/manual-checklist-update` — Manuelle Testcheckliste auf den heutigen Funktionsumfang bringen | open | 1 | `sandbox.nvim/manual-checklist-run` |
| `sessions.nvim/manual-checklist-update` — Manuelle Testcheckliste auf den heutigen Funktionsumfang bringen | open | 1 | `sessions.nvim/manual-checklist-run` |
| `testing.nvim/conformance-fleet-triage` — conformance triage of the fleet: fix, waive with a reason, or accept e | open · cdx | 1 | `testing.nvim/conformance-gate-per-repo` |
| `testing.nvim/tier25-3-prerequisites` — Tier 2.5/3 Voraussetzungen: WSL2, msedgedriver, Container-Engine | open | 1 | `testing.nvim/m8-multilang-and-tier25-3` |
| `testing.nvim/vhs-osc1337-assumption-check` — VHS-Annahme prüfen: kein OSC 1337 in xterm.js/ttyd | open | 1 | `testing.nvim/m8-multilang-and-tier25-3` |
| `rules.nvim/work-list-json-contract` — Stabile Arbeitsliste als JSON (Befunde plus manuelle Regeln mit Regelt | open | 1 | `wkdbook-tasks.nvim/import-from-rules-and-bootstrap` |

---

### N4. Blockaden, die sich selbst erledigt haben oder nicht auflösbar sind

Status `blocked`, aber der Blocker ist erledigt, fehlt oder es gibt keinen Task als Blocker (Freitext). Diese Tasks gehören auf `open` gestellt oder ihre Blockade gehört benannt.

| Task | Problem |
| --- | --- |
| `ALL/replace-plenary-test-harness` | blockiert durch `ALL/spec-nvim-m0-falsification`, das erledigt ist bzw. fehlt |
| `color_my_ascii.nvim/fence-highlighter-registry` | blockiert durch `color_my_ascii.nvim/fence-user-event`, das erledigt ist bzw. fehlt |
| `ai.nvim/release-v1-tag` | `status: blocked` ohne `blocked_by`: Freitext/extern, siehe Task-Datei |

## L. terminal.nvim: Terminals, WezTerm/tmux, Status, Navigation (Stand 2026-10-07)

Neues Plugin `StefanBartl/terminal.nvim` (öffentlich, `E:\repos\terminal.nvim`), Plan `terminal-build` im Wkdbook (`wkdbook-myplugins/terminal.nvim/ROADMAP/`, Handover `docs/ROADMAP/handovers/terminal.nvim.md`). Es hat `bindings/mappings/terminal.lua` und `bindings/autocmds/terminals/` der Config **ersetzt** (Snacks-Terminal-Toggle entfällt). Vor dem Testen **`terminal.nvim`, `Configs` und die nvim-Config auf `main` pullen**, Neovim **0.11+** (die `termopen()`-Rückfallebene ist raus), Config neu starten. Die Gegenstücke liegen in `Configs/terminals/wezterm` (Status, Tasten) und `Configs/terminals/tmux/tmux.conf`; WezTerm-Config neu laden (`<C-S-r>` bzw. WezTerm neu starten), tmux mit `tmux source ~/.config/tmux/tmux.conf`.

Commits, `terminal.nvim` (`main`): `696570c`, `8096526`, `4c592c4` (Grundstock, im ersten Review geprüft), `7c16ef6` (18 Review-Fixes), `f219097` (`<C-l>`, `run --direct`-Optionen), `6c3698d` (Status-Export), `773cfb7` (WezTerm-Pane-Backend), `a46d133` (Navigation), `164685c` (Health, Property-Specs), `f30b4a3` (tmux), `15f5790` (Konformitäts-Suite), `d418a34` (Pin/Adopt), `9551aca` (Branch-Cache), `17104ac` (Kitty als argv), `ea5c908` (Neovim 0.11). `Configs` (`main`): `e84ba47`, `6e069c7` (WezTerm), `223ddc2`, `d4a25ac` (tmux). nvim-Config: `f9e63552` (Ersatz von `terminal.lua`) und die Spec-/Doku-Commits dazu.

---

### L1. Blocker / offene Entscheidungen

- [ ] **Review-Haken:** nur `696570c`, `8096526`, `4c592c4` und der Ersatz in der Config (`f9e63552`) wurden vom Workflow-Review geprüft (18 Befunde, alle in `7c16ef6` behoben). **Alles danach ist nicht ultracode-reviewt:** `7c16ef6`, `f219097`, `6c3698d`, `773cfb7`, `a46d133`, `164685c`, `f30b4a3`, `15f5790`, `d418a34`, `9551aca`, `17104ac`, `ea5c908` sowie `Configs` `e84ba47`, `6e069c7`, `223ddc2`, `d4a25ac`. Ein zweiter Review über `7c16ef6..HEAD` steht aus (Task `terminal.nvim/rules-nvim-sweep` gehört dazu).
- [ ] **Entscheidung Normal-Modus-Tasten:** `nav_left/down/up/right` (Fensterwechsel mit Zähler und Hand-off an WezTerm/tmux) sind **standardmäßig aus**, weil die Config `<C-h/j/k/l>` im Normal-Modus selbst belegt. Willst du sie auf `<C-h/j/k/l>` legen (dann dort in der Config entfernen), damit die Navigation auch aus normalen Fenstern in WezTerm-/tmux-Nachbar-Panes führt?
- [ ] **Entscheidung Shell-Panes (WezTerm):** `NAVIGATION.shell_panes = "send"` (Default: `<C-j>`/`<C-k>`/`<C-h>` behalten in der Shell ihre Bedeutung) oder `"navigate"` (wie `vim-tmux-navigator`: bewegt auch aus Shell-Panes zwischen WezTerm-Panes, kostet diese Shell-Tasten). `Configs/terminals/wezterm/config/keybindings.lua`.
- [ ] **Task `wezterm-navigation-keys`:** offen bis zum Handtest (L6); Tastendrücke lassen sich nicht automatisieren.
- [ ] **Task `perf-pass`:** offen, weil die A/B-Messung des Starts **mit UI** fehlt (`scripts/startup-probe/bench.lua` der Config, einmal mit und einmal ohne das Plugin; headless: `setup()` 7–10 ms, Status-Update 15 µs, `Messungen/perf-2026-10-07.md`).
- [ ] **Task `rules-nvim-sweep`:** die automatisierten Regeln (NEW, DEP, ERR, LUA, REL, SEC, UI, 39 mit Check) bestehen alle (`DEP-02` behoben, Neovim 0.11); die **393 manuellen** Regeln (432 gesamt) sind nicht abgearbeitet. Entscheidung: nur kritische Familien (SEC, ERR, PRIN) pro Sitzung durchgehen, oder alles?
- [ ] **Task `repo-scaffold`:** offen: `documentation.nvim` als Dev-Dependency und `scripts/gen_map.lua` (NEW-19/20), LuaLS-Nullmessung für das neue Repo, Abhaken der NEW-Gates.
- [ ] **Task `lib-osc-detect-extraction`:** offen (nicht blockiert, ein Repo-übergreifender Umbau): OSC-1337-Erkennung/Writer aus `images.nvim`/`media.nvim` nach `lib.nvim.terminal` heben; `terminal.nvim` hat heute einen eigenen kleinen `core/osc.lua`.
- [ ] **Tasks `integrate-sessions`, `integrate-pickers-ui`, `integrate-run-hooks`:** offen, je Plugin eine Bestandsaufnahme nötig (`sessions`: Terminal-Definitionen pro Branch speichern; `pickers`/`ui`: Picker mit Vorschau, Menü, Statusline-Segment; `testing`/`tasks`/`dap`/`cmdlog`/`sandbox`: `terminal.run`-Ziel). Keine Blocker, aber Reihenfolge ist deine Sache.
- [ ] **Task `release-docs`:** wartet auf Review, Regel-Sweep und die Live-Abnahme (`live-check`); Release/Tag erst nach deinem Ja.
- [ ] **Task `wezterm-config-counterpart`:** offen ist nur die Last-Messung von `update-right-status` in WezTerm (JSON-Parse eines unter 1 KiB großen Werts je Update).
- [ ] **Task im Bereich `gitsuite.nvim`** (`eigene-git-engine-fallback-tui-float-ueber-terminal-nvim-sta`): `terminal.run(argv, { direct = true, ... })` kann den Float/`jobstart` des lazygit-Fallbacks ersetzen; wartet auf den Engine-Umbau (GS-30ff).
- [ ] **Neovim in WSL fehlt:** `backend = "tmux"` im Alltag setzt Neovim **innerhalb** von tmux voraus (unter Windows also Neovim in WSL). In deinem WSL (`archlinux`) ist **tmux 3.7c** installiert (mit `pacman -Syu`), aber kein Neovim. Der echte tmux-Weg ist bisher nur über `TESTS/live/tmux.lua` (Windows-Neovim steuert tmux in WSL) geprüft.

---

### L2. Native Terminals (`<A-h>` und `:Terminal`)

Du hast `<A-h>`, `<A-l>`, `<Esc>` und `<C-h/j/k/l>` schon geprüft; hier das, was neu dazugekommen ist.

- [ ] `<C-l>` im Terminal leert die Shell (`clear`/`cls`), `<A-l>` im Terminal tut nichts mehr; `<A-l>` im Normal-Modus öffnet weiter filetree.
- [ ] `3<A-h>` öffnet das Terminal "3" (eigener Job, eigener Titel), `<A-h>` ohne Zahl "main"; zweimal `<A-h>`: ausblenden, der Job läuft weiter (Prompt, Verlauf noch da), wieder `<A-h>` blendet ihn ein.
- [ ] `:Terminal open build --layout=vsplit` / `split` / `tab` / `float`: jedes Layout öffnet im Projekt-Root (Git-Wurzel des Buffers), Größe aus `float`/`split`; `:Terminal list` zeigt die Terminals des Projekts, Auswahl öffnet es.
- [ ] Ein anderes Projekt (anderer Git-Root) hat **eigene** Terminals: `:Terminal list` im ersten Projekt zeigt die des zweiten nicht.
- [ ] `exit` in der Shell: Fenster und Buffer verschwinden (`on_exit = "close"`); mit `on_exit = "keep"` bleibt der Text stehen und `<A-h>` startet neu.
- [ ] `:Terminal close` beendet die Shell; danach `<A-h>` startet eine frische.
- [ ] Kitty (nur wenn du Kitty nutzt): Padding enger beim Start, wieder weit beim Beenden.
- [ ] `:checkhealth terminal`: alles grün oder mit einer verständlichen Handlungsanweisung (WezTerm-Version, `wezterm cli list`, Hand-off, RPC-Adresse, Shell).

---

### L3. Text und Befehle senden (`send`, `run`)

- [ ] `:Terminal send line` tippt die aktuelle Zeile ins Terminal "run" **ohne** Enter; `--exec` führt aus.
- [ ] `:'<,'>Terminal send selection` mit **einer** Zeile tippt sie; mit **mehreren** Zeilen ohne `--exec` kommt die Meldung "N lines would be executed one by one" und nichts wird gesendet; mit `--exec` laufen alle Zeilen. (Vorher scheiterte der Befehl mit E481.)
- [ ] `:Terminal send file --exec` führt den ganzen Buffer aus (nur mit einem harmlosen Testbuffer).
- [ ] `:Terminal run echo hallo` tippt und führt aus; `:Terminal run -- git log --oneline` behält `--oneline`; `:Terminal run --direct --name=job cmd /c exit 3` startet den Job direkt (Fenster bleibt, Exit-Code 3 sichtbar).
- [ ] Quoting in **deiner** Shell (pwsh): `:lua require("terminal").run({ "echo", "a b", "it's", "x;y" })` zeigt die Wörter unverändert (keine Ausführung von `;y`); ein Wort mit typografischem Apostroph (`’`) bleibt ein Wort.
- [ ] `:lua require("terminal").run({ "echo", "a\nb" })` wird abgelehnt (Zeilenumbruch).

---

### L4. `run --direct` für andere Plugins (lazygit-Fallback)

- [ ] `:lua require("terminal").run({ "lazygit" }, { direct = true, name = "lazygit", title = "lazygit", float = { width = 0.9, height = 0.9 }, close = "always", cwd = vim.fn.getcwd() })`: Float mit Titel "lazygit", beim Beenden von lazygit verschwindet das Fenster.
- [ ] `close = "success"`: bei Exit-Code ≠ 0 bleibt das Fenster lesbar stehen.
- [ ] `on_open = function(h) vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = h.bufnr }) end`: `q` im Normal-Modus schließt das Fenster.

---

### L5. Status nach WezTerm (Tab-Titel, Right-Status)

WezTerm-Config neu laden. In einem WezTerm-Tab nvim starten.

- [ ] Der Tab-Titel zeigt den **Dateinamen** (`+` bei ungespeicherten Änderungen, `E2 W1` bei Diagnostics); Dateiwechsel ändert den Titel binnen ~100 ms.
- [ ] Der Right-Status zeigt Modus-Chip (`NORMAL`/`INSERT`/`VISUAL`/`TERMINAL`), Branch (git), Diagnostics; `qa` (Makro-Aufnahme) zeigt `REC @a`.
- [ ] nvim beenden: Titel/Right-Status fallen auf das alte Verhalten zurück; nvim **hart beenden** (Prozess killen): nach kurzer Zeit zeigt der Tab keinen alten nvim-Status mehr.
- [ ] Zwei Tabs mit nvim: jeder Tab zeigt **seinen** Dateinamen; der Right-Status zeigt den des **fokussierten** Panes.
- [ ] Datei mit komischem Namen (z. B. `evil<ESC>[31mx.txt` per `:file`): im Titel erscheint `?`, keine Farbänderung/Titelmanipulation im Terminal.
- [ ] Während du tippst/scrollst: keine Ruckler im Tab-Titel (Updates werden entprellt und nur bei Änderung gesendet).

---

### L6. Navigation über Pane-Grenzen

Zwei WezTerm-Panes nebeneinander: links nvim, rechts eine Shell. Zweite Variante: zwei nvim-Panes.

- [ ] Im Terminal-Modus (z. B. `<A-h>`-Terminal, `split`-Layout): `<C-h>`/`<C-j>`/`<C-k>` wechseln erst zwischen Neovim-Fenstern; am Neovim-Rand springt der Fokus in das **Nachbar-Pane von WezTerm**.
- [ ] Ein **Float**-Terminal (`<A-h>`): `<C-h>` geht nicht ins Nachbar-Pane (Floats haben keine Nachbarn).
- [ ] `<C-l>` im Terminal bleibt das Clear der Shell, es wechselt **nicht** das Pane.
- [ ] Von der Shell-Pane (rechts) nach links: `<C-h>` tut in der Shell, was die Shell damit tut (Standard `send`); wechselst du auf `shell_panes = "navigate"`, springt es nach links in das nvim-Pane.
- [ ] Zwei nvim-Panes nebeneinander: aus dem linken über den Rand ins rechte und zurück, ohne Hänger und ohne dass die Taste im falschen Programm landet.
- [ ] (Optional, Entscheidung L1) `keymaps = { nav_left = "<C-h>" }`: aus einem normalen Fenster am Rand ins Nachbar-Pane; `3<C-h>` springt drei Fenster.
- [ ] `terminal.navigate("l")` per `:lua`: gibt `moved`, `edge` oder `float` zurück.

---

### L7. `backend = "wezterm"` (Terminals als WezTerm-Panes)

In der Spec `backend = "wezterm"` setzen (nur zum Testen), nvim in WezTerm neu starten.

- [ ] `<A-h>` öffnet ein **WezTerm-Pane** rechts (kein Float); `3<A-h>` ein zweites; `:Terminal open x --layout=tab` einen neuen WezTerm-Tab.
- [ ] `:Terminal run echo hallo` schreibt im Pane; `<A-h>` beim fokussierten Pane gibt den Fokus an Neovim zurück; Pane mit der Maus schließen, dann `<A-h>`: es entsteht ein **neues** Pane.
- [ ] Ohne WezTerm (anderes Terminal) mit `backend = "wezterm"`: eine Meldung mit dem Grund, danach native Terminals.
- [ ] Danach wieder `backend = "auto"` setzen.

---

### L8. Pin und Adopt

- [ ] Native Terminal öffnen (`<A-h>`), `:Terminal pin` in WezTerm: das native Fenster verschwindet, das gleiche Terminal läuft als **WezTerm-Pane** im gleichen Verzeichnis; Verlauf und Ausgabe des alten sind weg (ehrlich so dokumentiert).
- [ ] nvim beenden: das Pane lebt weiter. Neues nvim: `:Terminal adopt` zeigt den Bildschirm des Panes **schreibgeschützt** in einem Buffer (`terminal://wezterm/<pane>/<name>`), er aktualisiert sich etwa einmal pro Sekunde, solange er sichtbar ist, und meldet, wenn das Pane weg ist. (Hinweis: `adopt` findet ein Terminal über die Registry der laufenden Sitzung, also nur eines, das **diese** nvim-Sitzung gepinnt hat.)
- [ ] `:Terminal pin` ohne WezTerm/tmux: Meldung "no multiplexer backend is available"; `pin` für ein schon gepinntes Terminal: "already lives in ...".

---

### L9. tmux (nur wenn Neovim in WSL/tmux läuft; sonst übersprungen)

- [ ] Neovim in WSL installieren (`pacman -S neovim`), `tmux`, dann in tmux `nvim`: der Status erscheint rechts in der tmux-Statuszeile (`@terminal_mode`, Branch, Diagnostics), die Konfig dafür steht in `tmux.conf` (`allow-passthrough on` auch für WezTerm außen).
- [ ] `backend = "tmux"`: `<A-h>` öffnet ein tmux-Pane, `:Terminal run` tippt hinein, `:Terminal pin --backend=tmux` startet neu als tmux-Pane.
- [ ] `<C-h>` am Neovim-Rand springt ins Nachbar-**tmux**-Pane (`tmux select-pane`).
- [ ] `tmux source ~/.config/tmux/tmux.conf` lädt **ohne Fehler** (vorher stand `export TERM=...` darin und tmux verwarf die ganze Datei; jetzt bleiben nur Meldungen zu nicht installierten TPM-Plugins).
- [ ] Die Live-Skripte laufen lokal: `TMUX_LIVE_WSL=archlinux nvim --headless -u NONE -l TESTS/live/tmux.lua` (Ergebnis in `terminal-tmux.txt`, letzte Zeile `RESULT ok`); das gleiche läuft in der CI als Job `tmux-live`.

---

### L10. Live-Skripte (echte Terminals statt Fakes)

Im Repo `terminal.nvim`; jedes schreibt eine Zeile je Prüfung und endet mit `RESULT ok`/`RESULT failed`. Alle liefen am 2026-10-07 grün.

- [ ] `TESTS/live/smoke.lua` (echtes Neovim-UI: native Terminals): `SMOKE_OUT=… nvim -u NONE -i NONE -c "luafile TESTS/live/smoke.lua"` (11 Prüfungen).
- [ ] `TESTS/live/wezterm.lua` (in einem WezTerm-Pane): Pane öffnen, `send-text`, Text zurücklesen, schließen (9).
- [ ] `TESTS/live/navigate.lua` (WezTerm): Hand-off nach rechts (6).
- [ ] `TESTS/live/pin.lua` (WezTerm): Pin und Adopt (9).
- [ ] `TESTS/live/tmux.lua` (headless, tmux in WSL): Backend und Status-Optionen (17).

---

### L11. Regression (Änderungen an Bestehendem)

- [ ] **`<A-h>` kommt jetzt von `terminal.nvim`** (nicht mehr Snacks): das Terminal verhält sich wie vorher (Float, `rounded`, ein `<Esc>` genügt), gewinnt aber Namen/Zähler.
- [ ] **`<C-l>` im Terminal** führt nicht mehr zum Fensterwechsel nach rechts, sondern ist das Clear der Shell; `<A-l>` im Terminal-Modus ist frei.
- [ ] Alte Terminal-Fensteroptionen (keine Zeilennummern, `signcolumn=no` …) gelten weiter, jetzt über `window_options`.
- [ ] Die WezTerm-`tabtitle.lua` löschte den Right-Status jede Sekunde (Ticker); er setzt jetzt den aktuellen Text neu: ein bestehender Right-Status (falls du einen hattest) bleibt stehen.
- [ ] **Die tmux-Konfiguration** wird jetzt überhaupt geladen (vorher verwarf tmux sie wegen `export TERM=…`): alle ihre Einstellungen (Mouse, vi-Keys, Plugins, Tasten) greifen erstmals, falls du sie je erwartet hast. Prüfen, ob dir etwas dadurch auffällt.

---

### L12. Bekannte Grenzen (kein Test nötig, nur wissen)

- Multiplexer-Backends (`wezterm`, `tmux`) haben **keine Floats** (`float` wird zum rechten Split), setzen **kein `env`** und melden das **Ende** des Befehls nicht (`on_exit` wird nie aufgerufen, `close = …` wirkt nicht).
- `pin` ist **kein Transfer**: der Prozess startet im Multiplexer neu, Ausgabe und Verlauf des alten Terminals sind weg.
- `send` tippt nur; mehrzeiliger Text braucht `--exec`. Quoting kann nicht verhindern, dass ein Programm ein Wort mit `-` als Option liest (dafür `--`). cmd.exe kann Wörter mit `%` nicht sicher quoten: sie werden abgelehnt.
- Neovim 0.12 stürzt **headless unter Windows** mit `0xC0000005` ab, wenn ein Terminal kurz nach einem Resize oder dem Ende eines anderen Terminal-Jobs geschlossen wird; die Specs setzen Pausen (`jobs.settle`). Im echten UI nie gesehen, aber möglich (`NOTES/nvim-windows-terminal-findings.md`).
- tmux-Passthrough: der WezTerm-Status aus einem Neovim **in** tmux kommt nur mit `set -g allow-passthrough on` an (in `tmux.conf` gesetzt; `:checkhealth terminal` prüft es).
- Die tmux-Seite ist gegen **echtes** tmux nur über die Live-Skripte und die CI geprüft, nicht im Alltag (kein Neovim in deinem WSL).

---


---

## O. ui.nvim: `ui.slots` (Kern ohne Leiste) — Live-Checks und Blocker (Stand 2026-10-07, Abend)

Nummerierte **Slots** als konfigurierbare Aktionen (Datei, URL, Clipboard-Text, Ex-Befehl, Lua-Funktion, Mark). Gebaut ist der
**Kern**: Lua-API, `:UI slots`, Tasten, sechs Kinds. **Noch nicht da:** Leiste, Panel, Editor, Vorschau (Tasks stehen unten). Vor dem Testen
**ui.nvim auf `main` pullen** (neuester Stand dieses Abschnitts: `dd89502`; CI grün auf Linux, macOS, Windows).

Quellen: Design `wkdbook-myplugins/ui.nvim/ROADMAP/slots-design.md`, Plan `ui.nvim/ROADMAP/plans/ui-slots.md`, Handover
`$NVIM_CONFIG_DIR/docs/ROADMAP/handovers/ui.slots_HANDOVER.md`.

Commits, `ui.nvim` (`main`): `f48e987` (config, store, resolve), `c73abae` (Kinds file, yank, url), `b8f67e3` (API, `:UI slots`, Tasten, Autocmds),
`eb3b765`, `313d37a` (Review-Fixes), `2218327` (Kinds cmd, lua, mark), `4367842` (cmd fail closed), `dd89502` (Test-Fix macOS). Alle bis auf `dd89502`
(nur Testcode, CI grün) sind ultracode-reviewt (zwei Runden bei den Kinds und der API, eine bei den Aktions-Kinds).

### O1. Blocker

**Zahlen gegen N geprüft (7.10., abends):** 38 Tasks mit `actor=me`, 71 mit Status `blocked`, 80 wartend — **unverändert gegenüber N2/N3**,
N1 bis N4 gelten weiter. Aus diesem Chat kommt nur eine Zeile in N2 dazu, `ui.nvim/slots-live-check` (steht dort schon). Neu erzeugen:
`nvim --headless -u NONE -l scripts/tasks.lua list --actor=me` und `list --waiting` im Ordner von `tasks.nvim`, mit `TASKS_VAULT` auf den Vault.

**Kette des Plans `ui.nvim/ui-slots`** (7 von 12 Tasks offen; erledigt: `slots-entscheidungen`, `slots-store-resolve`, `slots-kinds-basic`,
`slots-commands-api`, `slots-action-kinds`). Nichts davon wartet auf dich, außer dem letzten Glied:

| Task | Status | Wartet auf | Was |
|---|---|---|---|
| `ui.nvim/slots-chips-bar` | startbar (L) | — | die sichtbare Leiste mit Akkordeon-Scroll |
| `hover.nvim/preview-target-api` | startbar (S) | — | prüfen, ob hover.nvim einen öffentlichen Einstieg für URL-Vorschauen hat; sonst dort ergänzen |
| `ui.nvim/slots-panel-editor` | blocked | `slots-chips-bar` | fokussierbares Panel, Editor, Kontextmenü (weiche Kante zu `kit-sidebar-surface`) |
| `ui.nvim/slots-preview-file` | blocked | `slots-panel-editor` | Vorschau-Renderer und Dateivorschau |
| `ui.nvim/slots-preview-url` | blocked | `slots-preview-file`, `hover.nvim/preview-target-api` | URL-Vorschau über hover.nvim |
| `ui.nvim/slots-docs-health` | blocked | `slots-panel-editor`, `slots-preview-url` | Health-Check, Moduldoku, `scope.md`, Mausspecs |
| `ui.nvim/slots-live-check` | blocked, **actor=me** | `slots-docs-health` | **deine** Live-Abnahme (Optik, Alltag, Maus) — erst wenn alles andere steht |

**Weitere Stolpersteine, die in dieser Sitzung aufgefallen sind (keine Tasks, nur wissen):**

| Stolperstein | Wirkung | Stand |
|---|---|---|
| Der Vault-weite `tasks ci` ist rot | `mux.nvim` fehlte im Index (inzwischen: `index --check` meldet 0 veraltet); `md_lint` läuft nur mit `--trust-vault-lint`; ein fremder Task-Befund bleibt | nicht von den Slots; Lauf mit `--trust-vault-lint` und dem eigenen Befund ansehen |
| Der nvim-config-Checkout hat uncommittete Änderungen anderer Sitzungen (`Notes.md`, `00_ROADMAP.md`, `Casedesk/…`, `IDEAS/…`) | Beim Committen nur die eigenen Dateien hinzufügen, nie `git add -A` | läuft weiter, gehört nicht zu den Slots |
| ui.nvim-CI war auf macOS rot (`313d37a`, `4367842`) | Tests verglichen den Temp-Pfad roh, macOS meldet `/private/var` statt `/var` | **behoben** in `dd89502`, CI grün |
| `kit_drift_spec` | Der rote Lauf `bc8da10` vor den Slots (Kit-Kopie in lib.nvim) | seither grün; die Drift-Prüfung gilt auch für die Leiste, solange sie nichts im Kit ändert |
| Windows: `vim.ui.open` startet `cmd.exe /c start` | `&`, `|`, `^`, `%` in einer URL sind cmd-Syntax (Query abgeschnitten, Befehlsausführung möglich) | im url-Kind umgangen (`rundll32`), **echter Browserstart noch ungeprüft** — siehe O3.4 |

---

### O2. Neue Befehle, Optionen und APIs

| Was | Wie |
|---|---|
| `:UI slots` / `:UI slots list` | listet die Slots (`Nr  Icon Label  (kind, fixed, missing)`) |
| `:UI slots <n>` | führt Slot n aus |
| `:UI slots add [n]` | aktuelle Datei in den nächsten freien (oder den freien Slot n); dieselbe Datei kein zweites Mal |
| `:UI slots yank <n>` | kopiert, wofür der Slot steht (Pfad, Adresse, Text, Befehlszeile) |
| `:UI slots clear <n>\|all` | leert einen Slot / alle, die nicht fest sind |
| `:UI slots move <a> <b>` | Slot a nach b; tauscht, wenn b belegt ist |
| `:UI slots kinds` | `cmd, file, lua, mark, url, yank` |
| `:UI slots toggle\|open\|close\|edit` | **melden "not built yet"** (Leiste und Editor fehlen) |
| `ui.setup({ slots = true })` | schaltet die Slots ein (Standardwerte bzw. frühere `slots.setup()`) |
| `ui.setup({ slots = { enabled = true, … } })` | konfiguriert und schaltet ein; ohne `enabled = true` nur konfiguriert |
| `require("ui.slots")` | `setup`, `enable`, `disable`, `apply`, `add`, `yank`, `clear`, `clear_all`, `move`, `list`, `get`, `register_kind`, `last_applied` |
| Tasten, nur über `keys = { … }` | `apply = "<leader>%d"` (Slots 1 bis 9), `count = "<leader>S"` (`12<leader>S`), `add = "<leader>sa"`; ohne `keys` **keine einzige Taste** |
| Daten | `stdpath("data")/ui/slots/project-<hash>.json` bzw. `global.json`; Option `data_dir` ändert den Ort |
| Platzhalter | `{file}` `{dir}` `{root}` `{cwd}` `{line}` `{col}` `{word}` `{sel}` `{clip}` `{count}`; `{{` und `}}` sind wörtliche Klammern |

Kinds und ihre Felder: `file { path, target?, line?, col? }`, `yank { text, register? }`, `url { url }` (nur http, https, file, mailto),
`cmd { cmd, args?, bang?, raw_values? }` (nur aus Lua/`setup`), `lua { fn }` (nur aus Lua/`setup`), `mark { index }` (braucht sessions.nvim).

---

### O3. Live-Checkliste (ohne Leiste: alles per Befehl und Taste)

**Vorbereitung:** ui.nvim pullen, Neovim neu starten. Zum Ausprobieren reicht `:UI slots` (schaltet für die Sitzung ein). Für die Tasten
zusätzlich in einer Testkonfiguration oder per `:lua`:
`require("ui.slots").setup({ keys = { apply = "<leader>%d", count = "<leader>S", add = "<leader>sa" } })`.

**O3.1 Grundfluss**

- [ ] `:UI slots` in einem frischen Projekt: Meldung "no slots yet; :UI slots add …".
- [ ] In einer Datei `:UI slots add`: "slot 1: <Dateiname>". Nochmal: "already in slot 1", **kein** zweiter Slot.
- [ ] In einer anderen Datei `:UI slots add 5`: landet in Slot 5. `:UI slots add 5` nochmal: "slot 5 is taken; clear it first".
- [ ] `:UI slots`: Liste, aufsteigend, Lücken (2 bis 4) stehen **nicht** drin.
- [ ] `:UI slots 1` aus einem anderen Buffer: öffnet die Datei. Cursor in der Datei bewegen, Buffer wechseln, `:UI slots 1`: Cursor steht wieder dort.
- [ ] Neovim in einer Slot-Datei **beenden** (`:wqa`), neu starten, `:UI slots 1`: Cursor an der letzten Stelle (nicht an der vorletzten).
- [ ] Eine Slot-Datei löschen/umbenennen: `:UI slots` zeigt `missing`, `:UI slots <n>` meldet "file does not exist" und **legt nichts an**.
- [ ] `:UI slots move 1 7`, `:UI slots move 5 7` (tauscht), `:UI slots clear 7`, `:UI slots clear all`.
- [ ] Ungültig: `:UI slots 0`, `:UI slots 0x10`, `:UI slots 99999999999`, `:UI slots clear x`, `:UI slots frobnicate`: jeweils Meldung, nie ein Fehler/Stacktrace.
- [ ] Keine Obergrenze: `:lua for i=1,30 do require("ui.slots").add({kind="yank",text="t"..i}) end`, danach `:UI slots 12` und `:UI slots 30` gehen.

**O3.2 Kopieren (`yank`)**

- [ ] `:UI slots yank 1` (Datei-Slot), dann `"+p`: der Pfad. Dasselbe für einen url- und einen yank-Slot.
- [ ] Yank-Slot mit Platzhaltern: `:lua require("ui.slots").add({kind="yank", text="{word} @ {file}:{line}"})`, Cursor auf ein Wort, `:UI slots <n>`, einfügen: Wort, Pfad, Zeile.
- [ ] Meldung "copied N characters to …" nennt nur Register, die es wirklich gibt (ohne Clipboard-Provider **kein** `+`/`*` in der Liste).
- [ ] Ein Slot mit `{nope}`: Warnung "unknown placeholder {nope}".
- [ ] Datei mit Klammern im Namen (`report {line}.md`): `:UI slots add`, dann in einem anderen Buffer `:UI slots <n>`: öffnet **genau diese** Datei.

**O3.3 Tasten** (mit der `keys`-Zeile aus der Vorbereitung)

- [ ] `<leader>1` bis `<leader>9` führen Slot 1 bis 9 aus; `<leader>sa` fügt die aktuelle Datei hinzu.
- [ ] `12<leader>S` führt Slot 12 aus; `<leader>S` ohne Zahl: Hinweis "give the slot number as a count".
- [ ] Ohne `keys`: `:nmap <leader>1` zeigt **keine** Slot-Belegung (nichts wird ungefragt gemappt).
- [ ] `:lua require("ui.slots").disable()`: die Belegungen sind weg, `:autocmd ui_slots` zeigt nichts; `enable()` bringt sie zurück, nicht doppelt.
- [ ] Leader ändern (`:let mapleader=","`), dann `disable()`: `maparg("\\1","n")` ist leer (nichts bleibt hängen).

**O3.4 URL (wichtig auf Windows)**

- [ ] `:lua require("ui.slots").add({kind="url", url="https://neovim.io/doc/?a=1&b=2"})`, `:UI slots <n>`: der Browser öffnet die **vollständige** Adresse (`&b=2` kommt an). **Das ist der Praxistest für `rundll32`**, den ich nicht ausführen konnte.
- [ ] Adresse mit Umlaut (`https://example.org/café`): öffnet korrekt.
- [ ] `:lua print(pcall(require("ui.slots").add, {kind="url", url="javascript:alert(1)"}))` bzw. `add` meldet "scheme 'javascript' is not opened"; ebenso `ssh://…`, eine Adresse ohne Schema.
- [ ] `{ kind="url", url="{clip}" }` mit einer https-Adresse im Clipboard öffnet sie; mit `javascript:…` im Clipboard Meldung statt Start.
- [ ] `?q={word}` mit einem Wort wie `a&b`: im Browser steht `a%26b`.

**O3.5 `cmd`, `lua`, `mark`** (nur per Lua; die Dateien dürfen sie nie enthalten)

- [ ] `cmd`: `:lua require("ui.slots").add({kind="cmd", cmd="echo", args="'hi' '{word}'"})` — Ausführen zeigt die Ausgabe. Unbekannter Befehl: "no such command".
- [ ] `cmd` verweigert Gefährliches: Wort mit `|` im Cursor, Slot `args="{word}"` → "refused, the value of {word} has a | or a backtick"; ebenso Backtick, und `{clip}` mit führendem `+`/`!`. Mit `raw_values = true` geht es durch (nur für Befehle mit `<q-args>`).
- [ ] `lua`: `add({kind="lua", fn=function(ctx) vim.notify("n="..ctx.n.." word="..ctx.word) end})`. Ein `error(...)` in der Funktion: Meldung, Neovim läuft weiter. Ein String als `fn`: abgelehnt.
- [ ] `mark` (nur mit sessions.nvim): `add({kind="mark", index=1})`, Ausführen öffnet Mark 1. Index über das Ende: "no mark at …". Ohne sessions.nvim: "sessions.nvim is not installed".
- [ ] Lua-/cmd-Slots überleben einen Projektwechsel (`:cd` in ein anderes Projekt und zurück) in derselben Sitzung.

**O3.6 Speicherung und Projekte**

- [ ] Slots anlegen, Neovim beenden, neu starten: sie sind da. `:cd` in ein anderes Projekt: **andere** Liste (leer), `:cd` zurück: die ersten wieder da.
- [ ] `:cd` innerhalb desselben Projekts (Unterordner): die Liste bleibt, es wird nicht neu geladen.
- [ ] Die JSON-Datei ansehen (`stdpath("data")/ui/slots/`): enthält **keinen** cmd-/lua-Slot, auch wenn welche aktiv sind.
- [ ] Die JSON-Datei von Hand um einen Eintrag `{"n":9,"kind":"cmd","cmd":"echo","args":"x"}` ergänzen, Neovim neu starten: der Eintrag wird **nicht** geladen, einmal gemeldet ("may not hold"), nichts läuft.
- [ ] Eine fremde Datei an den Datenpfad legen (kein `ui.slots`-Format): Meldung "not a ui.slots data file", die Datei bleibt **unverändert**, Slots arbeiten weiter im Speicher.

**O3.7 Vervollständigung**

- [ ] `:UI slots <Tab>`: Unterbefehle **und** die vorhandenen Slot-Nummern, auch in einer frischen Sitzung (vor dem ersten Slot-Befehl).
- [ ] `:UI slots clear <Tab>` bietet `all` und die Nummern; `:UI slots move <Tab>` die Nummern; `:UI slots clear all <Tab>` nichts.
- [ ] `:UI help` zeigt die `:UI slots …`-Zeilen.

**O3.8 Feste Slots aus der Config**

- [ ] `require("ui").setup({ slots = { enabled = true, slots = { [3] = { kind="file", path="~/notes.md" }, [5] = { kind="cmd", cmd="Lazy" } } } })`: `:UI slots` zeigt 3 und 5 als `fixed`; `:UI slots clear 3` und `move 3 1` werden verweigert; `add` überspringt 3 und 5.
- [ ] Ein ungültiger Wert in der Config (`layout = "tower"`, `persits = true`): Meldung beim Start mit dem Namen, Standardwert wird verwendet, Neovim startet normal.

---

### O4. Regression (Änderungen an bestehendem Verhalten)

- [ ] `:UI` ohne Argument und `:UI help`: wie vorher, plus der `slots`-Block.
- [ ] `:UI <Tab>` listet `slots` neben den anderen Unterbefehlen; `:UI zen <Tab>`, `:UI notify <Tab>` unverändert.
- [ ] `ui.setup({ all = true })` schaltet die Slots **nicht** ein (explizit-only, wie `notify`).
- [ ] `require("ui.slots")` allein erzeugt weder Befehl noch Taste noch Autocmd (`:autocmd ui_slots` leer).
- [ ] Die vorhandenen Tabline-/Statusline-/Kit-Funktionen verhalten sich unverändert (ui.nvim ändert dort nichts).

---

### O5. Bekannte Grenzen (kein Test nötig, nur wissen)

- **Keine Leiste, kein Panel, kein Editor, keine Vorschau.** `toggle`/`open`/`close`/`edit` melden "not built yet". Kommt mit `slots-chips-bar`, `slots-panel-editor`, `slots-preview-*`.
- **Kein Health-Check:** `:checkhealth ui` kennt die Slots noch nicht (`slots-docs-health`); ein unbekannter Platzhalter fällt erst beim Anlegen oder Ausführen auf.
- **`cmd` verweigert statt zu quoten:** Werte mit `|`, Backtick oder führendem `+`/`!` werden abgelehnt; Befehle, die ihre Argumente selbst zerlegen (`:set`, `:args`), entscheiden selbst über Leerzeichen. Wer mehr braucht, nimmt einen `lua`-Slot.
- **`mark`** öffnet im aktuellen Fenster (der `target`-Wert gilt nur für `file`); `target = "pick"` (Fensterwahl) ist nicht gebaut.
- **Pfade mit `{`/`}`** werden beim `:UI slots add` automatisch doppelt geschrieben (`{{`); wer solche Pfade von Hand in die Config schreibt, muss es selbst tun.
- **Zwei Sitzungen im selben Projekt** schreiben dieselbe Datei; die zuletzt schreibende gewinnt (kein Merge).
- **Projekt = Git-Wurzel:** Die Belegung gilt pro Projektwurzel; ohne `.git` zählt der Arbeitsordner selbst als Projekt.

---

## P. docmap-desktop + documentation.nvim: Projektleiste, Suche, Statistik, Auto-Hide, Findings-Regeln — Live-Checks und Blocker (Stand 2026-10-07, Abend)

Alles aus dem Chat „gh traffic window“. **docmap-desktop**: Traffic-Dialog entschlackt, Chip „Karte veraltet“, Auto-Hide-Seitenleiste mit Pin,
lesbare Engine-/Neovim-Panels, neue **Projektleiste** (Karte / Dateien / Statistik) mit **Suche** und **Projektstatistik**. **documentation.nvim**:
`missing-readme` fragt nur noch Top-Level- und große Module, `<plugin>.health` ist kein „unreferenced-module“ mehr. Getestet ist alles nur
**headless und im Browser-Preview mit Stub-Daten** (`tools/preview/preview.py`, `node --test` 185 grün, `cargo test` 155 grün); **nie im echten
Tauri-Fenster (WebView2)**.

Commits, `docmap-desktop` (`main`, gepusht): `08e21d9` (Traffic-Dialog), `a2f3de8` (Chip „Karte veraltet“, Änderungsdialog, keine doppelten Zähler,
Sortierung nur in der Übersicht), `6d45c0f` (Auto-Hide, Engine-/Neovim-Panels), `6bc7d3b` (Backend `stats.rs`/`search.rs`), `c97bc9f` (Projektleiste,
Suche, Statistik), `642dfc1` (CSS). `documentation.nvim`: `d2be49f` (`main`, Push erst nach einem GitHub-500 durchgegangen). **Keiner dieser Commits ist
ultracode-reviewt.**

### P1. Blocker und offene Entscheidungen

| Blocker | Wirkung | Stand |
|---|---|---|
| ~~`documentation.nvim`: Push von `d2be49f` wurde von GitHub abgelehnt~~ | war ein 500er von GitHub (dreimal); `d2be49f` ist **inzwischen auf `origin/main`** (die andere Sitzung hat darauf aufgebaut) | **erledigt** (7.10., abends, per `git branch -r --contains` geprüft) |
| **`documentation.nvim`: eine zweite Sitzung ändert parallel dasselbe Arbeitsverzeichnis** (`bindings/usrcmds/init.lua`, `editor/registry.lua`, `standalone/vim_shim.lua`, `@types/init.lua`, `TESTS/check_policy_spec.lua`, `TESTS/shim_behavior_spec.lua`, `TESTS/setup_lazy_spec.lua`) | Die Gesamtsuite war in drei Läufen nie grün, jedes Mal mit anderen Fehlschlägen (`guard fs: modified …`); einzeln laufen sie grün | **offen**: erst committen, was die andere Sitzung fertig hat, dann `bash scripts/test.sh` einmal sauber; ich habe nur meine vier Dateien committet |
| **Kein installierter Build mit den neuen Funktionen** | Installiert ist `v0.6.0`; alles hier liegt nur auf `main`. Ein Release `v0.6.1` ist nicht geschnitten (Task `docmap-desktop/release-v0-6-1-decision`) | zum Testen: im Repo `docmap-desktop` `cd src-tauri && cargo run` (Debug-Build, lädt `src/` direkt) |
| **Kein Test im echten Fenster möglich** (Dateidialog mit Startordner, Auswahllisten in der Auto-Hide-Seitenleiste, Hover über dem eingebetteten iframe, Editor-Start aus der Suche) | Das sind genau die Stellen, an denen WebView2 anders sein kann als der Browser-Preview | P3 unten ist deine Liste dafür |
| **Task-Blocker aus N nicht neu geprüft** | Zahlen in N1 bis N4 (Stand 7.10.) gelten unverändert; aus diesem Chat kommt **kein neuer Task** dazu | `tasks list --actor=me` neu laufen lassen, falls du aktuelle Zahlen willst |

**Entscheidungen, die du beim Testen treffen musst:**

- [ ] **`missing-readme`: Schwellen so lassen?** Top-Level = höchstens eine Ebene unter dem Source-Root, groß = ab 10 Quelldateien. Fest im Code
      (`core/check.lua`, `TOP_LEVEL_DEPTH`, `BIG_MODULE_FILES`), **keine Option**. Wenn dir eine Option (`opts.readme`) lieber ist: Änderung in
      `config`, `@types`, `docmap.schema.json`.
- [ ] **Auto-Hide-Seitenleiste: Standard.** Aktuell **angeheftet** (wie bisher). Soll Auto-Hide der Standard werden?
- [ ] **Suche ohne Regex.** Plain, Groß/Klein egal (Schalter „Match case“). Reicht das, oder soll ein Regex-Schalter kommen (Gefahr: ein Muster kann lange laufen)?
- [ ] **Sprung aus der „Ansicht“-Suche:** Treffer mit Knoten gehen in der Karte auf **Index → Tree** mit diesem Modul (die Seite hat keinen Direktlink auf
      eine Funktion); Features gehen auf den Features-Tab; Doku-Seiten öffnen die Datei. Passt das, oder soll es der Hierarchy-Tab sein?
- [ ] **`Strg+K` funktioniert nicht, solange der Fokus im eingebetteten Kartenfenster ist** (Tastenereignisse verlassen den iframe nicht). Ein Klick in die
      Leiste oder die Seitenleiste reicht; ein Menüeintrag mit Kürzel wäre der Ausweg (Tauri-Menü), nicht gebaut.
- [ ] Dein Punkt **„2.“** in der letzten Nachricht ist leer angekommen — bitte nachliefern.

---

### P2. Neue Bedienelemente und Befehle

| Was | Wie | Wo |
|---|---|---|
| Projektleiste | über der Karte, nur bei gewähltem Projekt: **Karte / Dateien / Statistik** links, Suchfeld in der Mitte | `index.html`, `main.js` |
| Suche | `Strg+K` fokussiert das Feld (nicht aus dem Kartenfenster); **Enter** sucht sofort, **↓** in die Trefferliste, **↑/↓** wandern, **Esc** schließt | `main.js` (Abschnitt „Search“) |
| Scope „Ordner“ | Pfadfeld + **Wählen …** (Dialog startet im Projekt), Modus **Text** (grep) oder **Dateinamen** (find), **Groß-/Kleinschreibung** | Backend `project_search` |
| Scope „Ansicht“ | durchsucht, was die Karte zeigt (`module_map.json`: Namen, Pfade, Summaries, Signaturen, Parameter, Doku, Features) | Backend `view_search` |
| Statistik | Dateien/Zeilen je Sprache; Code, Kommentare, Doku, Daten/Config, Leer; längste Quelldateien; **Neu zählen** | Backend `project_stats` |
| **View → Statistics** | Menü, ohne Kürzel (Haken wie „Files on disk“) | `menu.rs` |
| **View → Auto-hide sidebar** | Menü, ohne Kürzel; dasselbe wie die Pin-Taste in der Seitenleisten-Ecke | `menu.rs`, `main.js` |
| **Pin** in der Seitenleiste | angeheftet ↔ klappt zu einem 14-px-Rand zusammen und öffnet beim Hovern/Fokus | `main.js` |
| `Strg+B` (View → Sidebar) | blendet die Seitenleiste jetzt **wirklich** aus (vorher wirkungslos, CSS überstimmte `hidden`) | `style.css` |
| Chip **„Karte veraltet“** | ersetzt die Zeile „Quellen sind neuer …“; Klick öffnet die Liste der geänderten Dateien, dort **Neue Karte erzeugen** | Backend `map_changes` |
| Traffic-Details | nur noch Top-10-Seiten und der Zeitraum; Charts und Referrer sind weg | `index.html`, `main.js` |
| `documentation.nvim` `--check` | `missing-readme` nur Top-Level/groß; `unreferenced-module` ohne `<plugin>.health` | `core/check.lua` |

---

### P3. Live-Checkliste

Vor dem Testen: im Repo `docmap-desktop` `git pull`, dann `cd src-tauri && cargo run`. Für die Findings: `documentation.nvim` auf dem Stand mit `d2be49f`.

**P3.1 Traffic-Dialog**

- [ ] Projekt mit Traffic-Daten wählen, **Traffic-Details …**: keine Charts, kein Referrer-Block; **Top 10 auf GitHub** mit Zählern.
- [ ] Die Zeile unter dem Titel lautet „Aufgezeichnet vom … bis …“ (kein Wort „Digest“); Englisch: „Recorded from … to …“.
- [ ] Eine Seite, die eine Datei im Projekt ist: Klick öffnet sie im Editor; eine gelöschte Seite ist nicht klickbar.

**P3.2 Chip „Karte veraltet“**

- [ ] Ein Projekt, dessen Quellen neuer als die Karte sind: statt der langen Zeile steht **Karte veraltet** (Pille). Hover zeigt: „Die Karte ist veraltet — bitte eine neue erzeugen. Ein Klick zeigt, was sich geändert hat.“
- [ ] Klick: Dialog „Seit der Karte geändert“ mit Dateien, neueste zuerst, „vor … danach“, bei vielen Dateien „… und N weitere“. Klick auf eine Zeile öffnet die Datei.
- [ ] **Neue Karte erzeugen** im Dialog startet die Generierung; danach verschwindet der Chip.
- [ ] Ein Projekt mit aktueller Karte: kein Chip.

**P3.3 Seitenleiste**

- [ ] Die Zeile „3 Module · 4 Namespaces · 36 Dateien · …“ unter dem Projekt ist **weg** (nur bei „noch keine Karte“ steht dort ein Satz).
- [ ] Sortier-Auswahl: nur bei „Alle Projekte“ sichtbar, bei einem gewählten Projekt nicht.
- [ ] **Pin** klicken: die Seitenleiste klappt auf einen Rand zusammen, die Karte nimmt die ganze Breite.
- [ ] Mit der Maus an den linken Rand: sie öffnet als Overlay über der Karte; Maus weg: sie schließt nach ca. 0,3 s.
- [ ] **Projekt-Auswahlliste im Auto-Hide-Modus öffnen und ein Projekt wählen (echtes Fenster!)**: die Seitenleiste darf sich beim Aufklappen der Liste **nicht** schließen und klappt nach der Wahl wieder zu.
- [ ] Mit **Tab** in die zugeklappte Seitenleiste: sie öffnet sich.
- [ ] **View → Auto-hide sidebar** setzt den Haken passend zur Pin-Taste (beide Richtungen).
- [ ] **Strg+B** blendet die Seitenleiste ganz aus und wieder ein (Karte nutzt die Breite).
- [ ] Zustand (angeheftet/Auto-Hide) bleibt nach einem Neustart.

**P3.4 Engine- und Neovim-Panel**

- [ ] Aufklappen: Beschriftungen **Programm / Grammatiken / Liest** (Neovim: **Programm / Konfiguration**), Pfad mit gedimmtem Ordner und hervorgehobenem Dateinamen, Tags „mitgeliefert“/„im PATH“/„Standardort“.
- [ ] **Liest**: ein Chip pro Sprache; Sprachen ohne geladene Grammatik gestrichelt (Tooltip „Keine Grammatik geladen“).
- [ ] Der Text hat links Abstand (kein Anliegen an den Rand mehr), lange Pfade brechen um.
- [ ] **Settings → Engine** und **Neovim** zeigen dieselben Zeilen.
- [ ] Ohne Engine/ohne nvim: rote Zeile „Nicht gefunden …“, das Panel klappt von selbst auf.

**P3.5 Projektleiste**

- [ ] Bei gewähltem Projekt: Leiste mit **Karte / Dateien / Statistik**, Suchfeld mittig. Bei „Alle Projekte“: keine Leiste.
- [ ] **Dateien** zeigt den Dateibaum (wie View → Files on disk), **Karte** kommt ohne Neuladen zurück.
- [ ] Projektwechsel bei offener Statistik oder offenem Dateibaum: die Ansicht zeigt das neue Projekt.

**P3.6 Suche**

- [ ] Ins Feld klicken: Panel mit **Bereich**-Zeile (Pfad = Projektwurzel, **Wählen …**, Auswahl Ordner/Ansicht).
- [ ] **Text**: z. B. ein Funktionsname: Treffer mit `pfad:zeile` und hervorgehobenem Treffer; Klick öffnet den **Editor an der Zeile**.
- [ ] **Dateinamen**: `lua init` findet `…/init.lua`; der kürzeste Namenstreffer steht oben.
- [ ] **Wählen …**: der Dialog startet **im Projekt**, nicht bei `C:`. Einen Unterordner wählen: Suche läuft nur darin, Pfade bleiben projektrelativ.
- [ ] Einen Ordner **außerhalb** des Projekts eintippen: Meldung „außerhalb des Projekts“, nichts wird durchsucht. `..` im Pfad: Meldung.
- [ ] **Groß-/Kleinschreibung** an: „Needle“ findet „needle“ nicht mehr.
- [ ] **Ansicht**: ein Modulname findet das Modul, ein Parametertext findet die Funktion; Klick springt in der Karte auf **Index → Tree** mit dem Modul markiert (Panel schließt). **Datei öffnen** öffnet die Quelle.
- [ ] Ansicht-Suche in einem Projekt **ohne Karte**: Hinweis „noch keine Karte“.
- [ ] Tippen löst nach kurzer Pause die Suche aus; **Enter** sofort; **↓** springt in die Liste, **Esc** zurück ins Feld/schließt.
- [ ] Großes Projekt (z. B. ein Monorepo): Suche bricht bei 300 Treffern/wenigen Sekunden ab und **sagt es**; `node_modules`/`target`/`docs/map` tauchen nicht auf.
- [ ] Außerhalb des Panels klicken schließt es; **Strg+K** (Fokus nicht im Kartenfenster) fokussiert das Feld.
- [ ] Zuletzt gewählte Einstellungen (Ordner/Ansicht, Text/Dateinamen, Match case) bleiben nach Neustart.

**P3.7 Statistik**

- [ ] **Statistik** öffnen: Kacheln (Dateien, Zeilen, Code, Kommentare mit %-Anteil, Doku, Daten/Config, Leer), Balken mit Legende, Tabelle je Sprache, längste Quelldateien.
- [ ] Zahlen gegen ein bekanntes Projekt prüfen (z. B. `cloc`/`tokei`): Größenordnung stimmt; Kommentarzeilen = nur-Kommentar-Zeilen, Code mit Zeilenende-Kommentar zählt als Code.
- [ ] **Neu zählen** nach dem Anlegen einer Datei: Zahl ändert sich.
- [ ] Ein Klick auf eine „längste Datei“ öffnet sie im Editor.
- [ ] Großes Projekt: Fenster bleibt bedienbar, es steht „Zähle …“; bei Abbruch der Hinweis „Zahlen sind Untergrenzen“.
- [ ] Projekt ohne Karte: Statistik funktioniert trotzdem.

**P3.8 documentation.nvim: Findings** (nach dem Push von `d2be49f` bzw. lokal)

- [ ] Karte für `sessions.nvim` neu erzeugen, Reiter **Findings**: `missing-readme` nur noch für `lua/sessions` (nicht für `config`, `marks`, `bindings/*`).
- [ ] `unreferenced-module` meldet `sessions.health` **nicht** mehr; ein echtes unbenutztes Modul wird weiter gemeldet.
- [ ] Ein Plugin mit einem Unterordner ab 10 Quelldateien ohne README: **wird** gemeldet.
- [ ] `checks = { ["missing-readme"] = false }` schaltet die Regel weiter ganz ab.

---

### P4. Regression (Änderungen an bestehendem Verhalten)

- [ ] **Strg+B** hatte vorher keine sichtbare Wirkung; jetzt blendet es die Seitenleiste aus.
- [ ] Der Dateibaum (**Strg+Shift+F**) liegt jetzt **unter** der Projektleiste (nicht mehr bei y=0); Breadcrumb und Liste scrollen wie vorher.
- [ ] Der Kontext-Hinweis über dem Kartenfenster (Telemetry/Types) sitzt unter der Leiste.
- [ ] Die Zähler im Kartenkopf (`3 modules · 4 namespaces …`) stehen weiter in der Karte selbst; nur die Sidebar-Kopie ist weg.
- [ ] Sortierung in **Settings → Behaviour** funktioniert weiter (auch wenn die Sidebar-Auswahl ausgeblendet ist).
- [ ] Menü: **View** hat zwei neue Haken (Statistics, Auto-hide sidebar); alle anderen Einträge und Kürzel unverändert.
- [ ] Generieren, Projekt hinzufügen, Workspaces, Traffic-Sortierung: wie vorher.

---

### P5. Bekannte Grenzen (kein Test nötig, nur wissen)

- **Kopfzeile der Karte** (Projektname, „10 modules“ …) gehört zum erzeugten Dokument und lässt sich von der App nicht ändern; die Suche sitzt deshalb in einer App-Leiste **darüber**. Gewünscht in der Kartenzeile selbst: Arbeit in `documentation.nvim`.
- **Keine Regex-Suche.** Teilstring, ohne Beachtung der Groß/Klein; bei Dateinamen müssen **alle** Wörter im Pfad vorkommen.
- **Suche überspringt** `node_modules`, `target`, `dist` und ein Dutzend weitere Ordner (dieselbe Liste wie der Dateibaum), Nested-Checkouts, das Kartenverzeichnis, Symlinks, Binärdateien und Dateien über 1,5 MB. Pro Datei höchstens 12 Treffer, insgesamt 300.
- **Statistik zählt nicht** Dateien über 2 MB, Binärdateien und unbekannte Endungen (nur als „weitere Dateien“); ein Python-Docstring ist Code, ein Kommentarzeichen in einem String kann täuschen (wie bei `cloc`).
- **Statistik und Suche sind live von der Platte**, nicht aus der Karte: sie sehen auch Dateien, die in der Karte fehlen.
- **„Karte veraltet“ vergleicht Änderungszeiten:** eine ohne Änderung gespeicherte Datei zählt mit, die Liste nennt höchstens 100 Dateien (mit der Gesamtzahl).
- **Ansicht-Suche** findet nur, was in `module_map.json` steht; Funktionsrümpfe (`snippet`) sind absichtlich ausgenommen.
- **`documentation.nvim`-Schwellen** für `missing-readme` sind fest (siehe P1), keine Option.
- **Preview-Stub:** `tools/preview/preview.html` entsteht beim Start von `preview.py` aus `src/index.html`; nach Markup-Änderungen den Server neu starten, sonst sieht man die alte Seite (Skripte und CSS lädt der Browser sonst aus dem Cache).
