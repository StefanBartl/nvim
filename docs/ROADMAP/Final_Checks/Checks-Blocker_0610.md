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
    - [G5. Später, wenn `display_lang` gebaut ist](#g5-spter-wenn-display_lang-gebaut-ist)
    - [G6. Bekannte Grenzen (kein Test nötig, nur wissen)](#g6-bekannte-grenzen-kein-test-ntig-nur-wissen)

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

### F1. BLOCKER: `claude-cli` mit echtem Account (Task `ai.nvim/review-restpunkte`)

Der hier eingeloggte Account liefert `Credit balance is too low`; der Erfolgspfad ist nur
gegen eine Fake-CLI geprüft. Voraussetzung: `claude auth login` mit dem Max-Account (oder
einem Account mit Guthaben), dann `:Ai provider claude-cli`.

- [ ] `:Ai ask` mit "say ok": Antwort kommt, Streaming (`:Ai stream`) füllt das Panel; die
      stream-json-Form passt (Annahme aus der Doku, nie live gesehen).
- [ ] `@pfad`-Erwähnung im Prompt (z. B. `@C:\Windows\win.ini`): die CLI liest die Datei
      **nicht** (Deny-Regel plus `CLAUDE_CODE_DISABLE_ATTACHMENTS`); Prompt-Anfang mit
      `/cost` wird nicht lokal beantwortet (Label `User message:`).
- [ ] `ANTHROPIC_API_KEY` in der Umgebung gesetzt: es wird trotzdem der eingeloggte Account
      benutzt (Variable wird aus dem Kindprozess entfernt).
- [ ] `ANTHROPIC_BASE_URL` gesetzt (Claude Desktop setzt sie evtl. selbst): `:checkhealth ai`
      und `:Ai info` nennen nur den Host, Warnung nur wenn `claude` verfügbar oder
      `claude-cli` aktiv; Anfrage geht weiter an dieses Gateway.
- [ ] Abbruch (Antwortfenster schließen) beendet den Prozess; in casedesk steht "cancelled",
      kein Netzwerkfehler.
- [ ] `:checkhealth ai`: Hinweis bei `apiKeyHelper` bzw. Zugangsdaten im `env`-Block deiner
      CLI-Einstellungen (nur wenn du so etwas konfiguriert hast; zeigt nie den Wert).

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

**Das Feature selbst (`display_lang`) ist noch nicht gebaut.** Hier stehen (G1) die Blocker, die
nur du lösen kannst, (G2 bis G4) die schon gelandeten Bausteine, die live zu prüfen sind, und
(G5) die Checks für später. Alle drei Bausteine sind per Spec und ultracode-Review geprüft, aber
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
      Anfragen ohne HTTP 429, hat aber am 2026-09-03 durchgehend mit 429 geantwortet
      (`language.nvim/translate-engine-failover`). Als Standard-Engine für `display_lang`
      akzeptabel, oder nur als Fallback hinter DeepL?
- [ ] **Datenschutz-Regel festlegen:** welche Dokumente dürfen an eine Cloud-Engine (DeepL,
      Google, Claude)? Kundendaten nie; Ollama gilt als lokal. Die Regel gehört in die
      Dokumentation von `display_lang`, bevor es gebaut ist.
- [ ] Windows-Besonderheit merken: Platzhalter `⟦n⟧` wurden auf dem curl-Weg zerstört (25 %
      der Einheiten), `{n}` nicht. Beim Bau von `markdown-translate-api` live gegen den echten
      curl-Weg prüfen, nicht nur gegen einen Fake.

---

### G2. mdview.nvim: `core/mirror` (alle Vorschau-Lesewege, Commit `30e4377` und Folgefixes)

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

---

### G3. ai.nvim: Bulk-Profil `req.bulk` (Commits `e91c376`, `336122b` und Folgefixes)

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

---

### G4. language.nvim: Chunking großer Eingaben (Commit `a2e0a73` und Folgefixes `dd67f2e`, `3198fac`)

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
      enthält, werden abgelehnt statt von `cmd.exe` interpretiert (`3198fac`).

---

### G5. Später, wenn `display_lang` gebaut ist

Noch nicht prüfbar, weil die Tasks offen sind. Die Akzeptanzliste der Live-Abnahme steht in
`ALL/display-lang-live-check`; Kurzfassung:

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

---
