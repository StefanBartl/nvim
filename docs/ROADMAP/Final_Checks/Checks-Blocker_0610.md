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

---

## Intro

Checks fuer dich aus der Umsetzung von `ROADMAP/Casedesk/NEW.md`, die **nicht
direkt casedesk.nvim** betreffen. Die casedesk-Checks und **alle Blocker** stehen
in `../Casedesk/Checks-und-Blocker-2026-10-06.md`.

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
