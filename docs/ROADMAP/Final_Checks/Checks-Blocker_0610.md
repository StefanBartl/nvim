# Final Checks 6. Nov: spotlight.nvim, mdview.nvim, ai.nvim, lib.nvim (Stand 2026-10-06)

Checks fuer dich aus der Umsetzung von `ROADMAP/Casedesk/NEW.md`, die **nicht
direkt casedesk.nvim** betreffen. Die casedesk-Checks und **alle Blocker** stehen
in `../Casedesk/Checks-und-Blocker-2026-10-06.md`.

## A. mdview.nvim (Releases v0.4.0 bis v0.4.3, `install.version = v0.4.3`)

Checkliste im Repo: `TESTS/CHECK.md`.

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

### Relay / Watcher

- [ ] `:MDView standalone <datei>`: Datei in einem Editor speichern, der
      "truncate, dann write" macht; die Vorschau zeigt nie kurz eine leere
      Datei. Aenderungen kommen nach etwa 500 ms (zwei Polls) an.
- [ ] Neues Release v0.4.3 wird beim ersten `:MDView start` heruntergeladen
      (Binary + Client-Bundle, Windows `.exe`), danach keine
      "relay too old"-Warnung mehr bei Spotlights.
- [ ] Mehrere Tabs gleichzeitig: Join waehrend laufender Aenderungen zeigt nie
      einen aelteren Stand nach einem frischen (atomarer Seed).

### Bekannte offene Kleinigkeiten

- Reihenfolge zweier sehr schnell aufeinanderfolgender Broadcasts an dieselbe
  Verbindung ist nicht garantiert (parallele HTTP-Handler).
- 13 weitere `src/`-Dateien waren nicht Prettier-clean; inzwischen formatiert
  (`7b791c8`), CI prueft Prettier nicht.
- Windows-CI: `breadcrumbs_spec` kann einmalig in ein Timeout laufen
  (Runner-Flake; `gh run rerun <id> --failed`).

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

### Command-Key-Quelle (`8b17769`, `eb714c3`, `82a58c7`)

- [ ] Key per Befehl (argv-Liste, kein Shell-String): Key kommt an, taucht nie
      in Logs/Health/Prompts im Klartext auf; Timeout wirkt
      (`timeout_ms` begrenzt auf 1..3600000).
- [ ] Windows: ein `.cmd`/`.bat` als Command wird mit Hinweis auf
      `pwsh -File` abgelehnt (`fetch` und `health`).
- [ ] Key-Datei-Rechte (group/others) werden im Health gemeldet.

### Sonstiges

- [ ] `capabilities.web = false` auf allen eingebauten Providern, keine
      Websuche aktiv (siehe Blocker `capabilities-web` in der Casedesk-Datei).
- [ ] `doc/ai.txt` und `docs/configuration.md` entsprechen `DEFAULTS`
      (Vimdoc-/Docs-Specs sind gruen).

## D. lib.nvim

- [ ] Usercmd-Composer: variadisches letztes Argument vervollstaendigt ueber
      die deklarierten Slots hinaus und zeigt `...` im Usage (`f0d76b9`);
      bestehende Befehle in anderen Plugins verhalten sich unveraendert.

## E. Housekeeping

- [ ] Worktree + Branch `claude/casedesk-roadmap-d5a22b` (komplett in `main`)
      aufraeumen, wenn nicht mehr gebraucht.
- [ ] Im nvim-Config-Repo liegen fremde, nicht von dieser Arbeit stammende
      Aenderungen (`docs/ROADMAP/00_ROADMAP.md`, `docs/TESTING/en_test.md`);
      im WKDBooks-Repo `language.nvim/Backlog/README.md`. Nicht mitcommittet.

## F. KI-Kette casedesk.nvim + ai.nvim (Review und Fixes vom 5./6.10., Stand 2026-10-06)

Alles unten ist offline gegen Fake-CLIs und synthetische Daten geprüft; hier steht, was
nur **live** mit echtem Account, echtem Binary oder echten Daten geht. Sicherheitsregel für
alle Läufe: zuerst mit synthetischen Daten (`:Case ai test`), keine Kundendaten, solange
`ki-datenfreigabe-klaeren` (Antwort der IT) offen ist.

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

### F2. Allow-List und Provider-Wahl auf der Workstation

- [ ] `CASEDESK_AI_ALLOWED=copilot,claude` setzen (setup-claude-code.ps1 oder User-Env):
      Statusline zeigt `AI:claude`; `:Case ai` zeigt Allow-List und Quelle.
- [ ] `:Case ai provider gemini` (außerhalb): Rückfrage, Antwort Nein ist vorbelegt; bei Ja
      nur für die Sitzung, Statusline `AI:gemini!`, jeder Send einzeln bestätigt.
- [ ] `:Ai provider auto` auf der eingeschränkten Maschine fragt **nicht** nach.
- [ ] Tippfehler im Config-Schlüssel (`policy = { alowed = {...} }`): Warnung beim Start,
      `:checkhealth ai` meldet es, es ist **nichts** erlaubt (fail-closed).
- [ ] Provider-Id in anderer Schreibweise (`--provider=Claude`, `Copilot`) wird erkannt.

### F3. Key-Profile (`:Ai key`)

- [ ] `keys = { claude = { active = "privat", profiles = { privat = {env=...}, firma = {file=...} } } }`
      mit deinem privaten Key und (in ein paar Wochen) dem Firmenzugang.
- [ ] `:Ai key firma` / `:Ai key reset` / `:Ai key` (zeigt nie den Key); Profil ohne Key:
      Anfrage schlägt mit Profilnamen fehl und weicht **nie** auf den Standard-Key aus.
- [ ] Key-Datei mit BOM / als UTF-16 (PowerShell 5.1 `Out-File`) wird gelesen.
- [ ] Ein privater Key auf der Firmen-Workstation mit Kundendaten kann gegen die
      Firmenrichtlinie verstoßen: nur `:Case ai test` mit synthetischen Daten.

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

### F5. Bekannte Grenzen (kein Test nötig, nur wissen)

- Prosa ohne Komma/Semikolon/Doppelpunkt zwischen Programmpfad und relativem Slash-Pfad
  lässt das Konto stehen; NT-Pfade `\Device\Mup\<host>\...` maskieren Host/Konto nicht.
- Zugangsdaten aus Federation-Profilen der CLI werden nicht erkannt (nur dokumentiert).
- Der Erfolgspfad der echten CLI (F1) und der Copilot-Fehlerpfad mitten im Lauf sind
  ungeprüft.

### F6. Stand-Hinweis

Die Handover-Texte von casedesk (`FEATURES.md`, Konzept-Banner) nennen `copilot-provider`,
`secret-sources` (Kommando-Quelle) und `capabilities-web` noch als offen; laut `ai.nvim`-Log
sind sie inzwischen gebaut (`6b84085`, `8b17769`, `6eb0852`) und stehen oben unter C. Die
Task-Dateien dazu bei Gelegenheit abhaken.
