# Offene Live-Checks (Stand 2026-10-30)

Erzeugt am 2026-10-30. Hier stehen nur Prüfungen, die du selbst machen musst: echte Konten und Schlüssel, ein echtes Fenster, ein anderer Rechner oder Alltagsnutzung über längere Zeit. Hinter jedem Punkt steht die Task-ID in Backticks. Ist ein Punkt schon in einer anderen Final_Checks-Datei beschrieben, steht hier nur eine Zeile mit Link dorthin.

## ALL (übergreifend)

- [ ] display-lang: Live-Abnahme über mdview, language.nvim und ai.nvim (`ALL/display-lang-live-check`): siehe [Checks-Blocker_0610.md](Checks-Blocker_0610.md)
- [ ] Claude-Account-Testsession (ai.nvim, ai-desktop, rules, docmap) (`ALL/claude-account-live-test-session`): siehe [Checks-Blocker_0610.md](Checks-Blocker_0610.md), Ablauf in [ai/claude-account-live-testing-schlachtplan.md](ai/claude-account-live-testing-schlachtplan.md) Abschnitt 7
- [ ] Handarbeit nach dem Umzug (Install-Probe, Profil, Autorennamen, Signieren) (`ALL/handarbeit-nach-umzug-schritt-fuer-schritt`): siehe [tasks-apps-live-checks-2026-10-29.md](tasks-apps-live-checks-2026-10-29.md)
- [ ] Plugin-Roadmaps-Testplan von Hand durchlaufen (`ALL/plugin-roadmaps-testplan-run`): siehe [PLUGIN_ROADMAPS_TESTPLAN.md](PLUGIN_ROADMAPS_TESTPLAN.md)
- [ ] Runner-Autostart beim echten Anmelden erproben (`ALL/runner-autostart-beim-anmelden-erproben`): siehe [tasks-apps-live-checks-2026-10-29.md](tasks-apps-live-checks-2026-10-29.md)
- [ ] UX-Backlog-Live-Checkliste (T1, T3, T4, T5, T9, Fokus) (`ALL/ux-backlog-live-checklist-run`): siehe [Running-Tasks_Checklist.md](Running-Tasks_Checklist.md)

## ai.nvim

- [ ] **Completion: Thinking-Tokens gegen max_tokens 512 live messen** (`ai.nvim/completion-thinking-tokens-gegen-max-tokens-512-live-messen`)
    - Completion mit einem 5.x-/Fable-Modell auslösen.
    - Im Log `stop_reason` und `usage` ansehen: werden Antworten wegen `max_tokens=512` abgeschnitten oder verworfen?
    - Werte notieren; danach den Cap pro Modell festlegen.
    - Warum du: Messung mit echtem API-Schlüssel und echten Kosten; der Agent fasst keine Schlüssel an.
- [ ] Copilot: Fehlerereignis mitten im Lauf aufzeichnen (`ai.nvim/copilot-fehlerereignis-mitten-im-lauf-aufzeichnen`): siehe [Checks-Blocker_0610.md](Checks-Blocker_0610.md)
- [ ] openai: file-Part gegen die echte API prüfen (`ai.nvim/openai-documents-live-check`): siehe [ai/openai-documents-live-check-2026-10-29.md](ai/openai-documents-live-check-2026-10-29.md)

## appkit

- [ ] Hub-Start über wscript auf der Workstation (Falcon) (`appkit/start-ueber-wscript-von-edr-beendet`): siehe [nvim-config-live-checks-2026-10-29.md](nvim-config-live-checks-2026-10-29.md) (nur auf der Workstation)

## casedesk.nvim

Alle Punkte stehen in [casedesk-live-checks-2026-10-29.md](casedesk-live-checks-2026-10-29.md):

- [ ] :Cases doctor gegen den echten Workspace (`casedesk.nvim/doctor-stale-unconfirmed-live-run`)
- [ ] Live-Test-Checkliste für casedesk durcharbeiten (`casedesk.nvim/live-tests-run`)
- [ ] :Case clipboard und Case-Spotlights im echten Neovim (`casedesk.nvim/clipboard-spotlight-live-check`)
- [ ] Case-Pin bei Meldungen im echten Neovim (`casedesk.nvim/pin-message-windows-live-check`)
- [ ] hover.nvim auf Case-Links ausprobieren (`casedesk.nvim/try-hover-on-case-links`)
- [ ] Schwesterplugins am Case-Alltag ausprobieren (`casedesk.nvim/try-sibling-plugins-no-wiring`)

## Manuelle Plugin-Testchecklisten

Alle Punkte stehen in [Checks-Blocker_0610.md](Checks-Blocker_0610.md) (Checklisten unter `ALL/manual-test-checklists/`):

- [ ] buffer-ctx (`buffer-ctx.nvim/manual-checklist-run`)
- [ ] cascade (`cascade.nvim/manual-checklist-run`)
- [ ] cmdlog (`cmdlog.nvim/manual-checklist-run`)
- [ ] dap (`dap.nvim/manual-checklist-run`)
- [ ] diff (`diff.nvim/manual-checklist-run`)
- [ ] emojis (`emojis.nvim/manual-checklist-run`)
- [ ] fileops (`fileops.nvim/manual-checklist-run`)
- [ ] recommender (`recommender.nvim/manual-checklist-run`)
- [ ] reposcope (`reposcope.nvim/manual-checklist-run`)
- [ ] sandbox (`sandbox.nvim/manual-checklist-run`)
- [ ] sessions (`sessions.nvim/manual-checklist-run`)

## docmap.nvim

- [ ] docmap-Binary: OneDrive-Platzhalter (Files on demand) (`docmap.nvim/engine-links-binary-check#onedrive`): siehe [docmap-live-checks-2026-10-29.md](docmap-live-checks-2026-10-29.md) Abschnitt 2
- [ ] Keyword-Karte: Tab-Navigation im echten Fenster (`docmap.nvim/keyword-card-tab-navigation-live-check`): siehe [docmap-live-checks-2026-10-29.md](docmap-live-checks-2026-10-29.md)

## docmap-desktop

Alle Punkte stehen in [docmap-desktop-live-tests-2026-10-02.md](docmap-desktop-live-tests-2026-10-02.md):

- [ ] Installierte docmap-desktop-App einmal durchgehen (A1) (`docmap-desktop/live-test-installed-app`)
- [ ] GitHub-Traffic-Oberfläche gegen echten Fetch (A3) (`docmap-desktop/live-test-traffic-surface`)
- [ ] Traffic-Browse und Rules-Loader in Neovim gegen echte Daten (`docmap-desktop/live-test-neovim-side-checks`)
- [ ] Engine-Panel und Call-Graph-Popup in der App ansehen (`docmap-desktop/live-test-engine-panel-and-call-edge-popup`)
- [ ] docmap-desktop auf einem Mac ansehen (Menüleiste) (`docmap-desktop/macos-menu-bar-variant`)

## filetree.nvim

- [ ] Modified-Icon-Blinken nach Redraw-Coalescing (`filetree.nvim/collapse-blink-live-check`): siehe [filetree-live-checks-2026-10-29.md](filetree-live-checks-2026-10-29.md)
- [ ] Verschwinden die W:/E:-Badges im Baum noch? (`filetree.nvim/diag-badges-vanish-live-check`): siehe [filetree-live-checks-2026-10-29.md](filetree-live-checks-2026-10-29.md)
- [ ] handle_guard gegen Windows-EPERM beobachten (`filetree.nvim/handle-guard-eperm-observation`): siehe [filetree-live-checks-2026-10-29.md](filetree-live-checks-2026-10-29.md)
- [ ] Gebündelter Papierkorb auf echtem Linux und macOS (`filetree.nvim/test-trash-batch-linux-macos`): siehe [filetree-trash-batch-performance-2026-09-26.md](filetree-trash-batch-performance-2026-09-26.md)

## github_stats.nvim

- [ ] Traffic-Digest-Kette einmal gegen echten Fetch (`github_stats.nvim/traffic-digest-e2e-check`): siehe [github_stats-live-checks-2026-10-29.md](github_stats-live-checks-2026-10-29.md)

## gitsuite.nvim

- [ ] gitsuite manuelle Checkliste (GS-30) erster Lauf (`gitsuite.nvim/live-test-checklist`): siehe [gitsuite-live-checks-2026-10-22.md](gitsuite-live-checks-2026-10-22.md)
- [ ] Report-Tab von :Git plugins (Farben, echte Klone, Tasten) (`gitsuite.nvim/plugins-report-ui-live-check`): siehe [gitsuite-live-checks-2026-10-22.md](gitsuite-live-checks-2026-10-22.md) Abschnitt 4
- [ ] :Lazy sync-Hook (Toast) (`gitsuite.nvim/plugins-lazy-sync-hook-live-check`): siehe [gitsuite-live-checks-2026-10-22.md](gitsuite-live-checks-2026-10-22.md)
- [ ] Dashboard: fertige Repos während gf bedienen (Rest) (`gitsuite.nvim/dashboard-act-during-bulk-fetch-live-check`): siehe [gitsuite-live-checks-2026-10-22.md](gitsuite-live-checks-2026-10-22.md)
- [ ] **Dashboard während eines Batches schließen und neu öffnen** (`gitsuite.nvim/dashboard-wiederoeffnen-live-test`)
    - `:Git dashboard` öffnen, `gf` drücken, das Popup vor dem Ende schließen und gleich wieder öffnen.
    - Prüfen: Die Zeilen zeigen weiter den Fortschritt und lösen sich am Ende auf.
    - Ein zweites `gf` während des Laufs meldet „A bulk fetch is already running“.
    - Warum du: Handtest im echten Neovim mit echten Repos und echtem Netz.

## gopath.nvim

- [ ] VeryLazy-Welle ohne load_from_disk mit UI messen (`gopath.nvim/lazy-profile-cache-measure`): siehe [gopath-lazy-profile-live-check-2026-10-29.md](gopath-lazy-profile-live-check-2026-10-29.md)

## hover.nvim

- [ ] :Hover copy / Y mit echter Zwischenablage (`hover.nvim/copy-live-check`): siehe [hover.nvim-live-checks-2026-10-29.md](hover.nvim-live-checks-2026-10-29.md)
- [ ] Kommt `<M-n>` im Terminal an? (`hover.nvim/position-next-key-live-test`): siehe [PLUGIN_ROADMAPS_TESTPLAN.md](PLUGIN_ROADMAPS_TESTPLAN.md)
- [ ] **hover.nvim und fileops on_hold einen Tag gleichzeitig** (`hover.nvim/fileops-on-hold-collision-trial`)
    - fileops `on_hold.enable=true` und hover mit Trigger `CursorHold` einen Arbeitstag lang zusammen nutzen.
    - Notieren, ob sich Floats überlappen, gegenseitig verdrängen oder flackern; eine Zeile in `MANUAL-EVIDENCE.md`.
    - Bei einer Kollision entscheiden, wer Vorrang hat.
    - Warum du: ein Arbeitstag echter Alltagsnutzung mit Beobachtung der Floats.
- [ ] **VLC-Pfad der Systemplayer-Stufe** (`hover.nvim/vlc-system-player-live-test`)
    - `video.use_mpv=false`, `system_player_align`, `prefer_classic` und `search_installs` auf `true` setzen.
    - Hover auf eine MP4, `<CR>`: VLC startet aus dem Installationspfad und ist ausgerichtet.
    - Gegenprobe mit `search_installs=false`; Ergebnis als Zeile in `MANUAL-EVIDENCE.md`.
    - Warum du: Das VLC-Fenster startet sichtbar, die Ausrichtung ist eine Sichtprüfung.

## images.nvim

- [ ] Bilder in tmux live in WezTerm prüfen (`images.nvim/bilder-in-tmux-live-in-wezterm-pruefen-allow-passthrough-on`): siehe [images-tmux-wezterm-live-checks-2026-10-29.md](images-tmux-wezterm-live-checks-2026-10-29.md)

## language.nvim

- [ ] Shell-Engine: stdin-Pfad mit echtem trans (`language.nvim/shell-engine-stdin-pfad-mit-echtem-trans-unter-windows-verif`): siehe [language-live-checks-2026-10-29.md](language-live-checks-2026-10-29.md)
- [ ] translate_markdown: DeepL mit echtem Schlüssel messen (`language.nvim/translate-markdown-deepl-mit-echtem-schluessel-messen-platzh`): siehe [language-live-checks-2026-10-29.md](language-live-checks-2026-10-29.md)

## lsp.nvim

- [ ] lspsaga-Ersatz im echten Terminal (A1-A11) (`lsp.nvim/live-check-lspsaga-replacements`): siehe [lsp.nvim-live-checks-2026-10-29.md](lsp.nvim-live-checks-2026-10-29.md)
- [ ] gx auf einem env-Link in echter 0.12-Sitzung (`lsp.nvim/gx-on-an-env-link-in-a-real-neovim-0-12-session-hand-check`): siehe [lsp.nvim-live-checks-2026-10-29.md](lsp.nvim-live-checks-2026-10-29.md)

## markdown.nvim

- [ ] markdown.nvim Live-Tests im echten Editor (`markdown.nvim/live-tests-im-echten-editor-snacks-fzf-lua-folds-insert-modu`): siehe [markdown.nvim-live-checks-2026-10-29.md](markdown.nvim-live-checks-2026-10-29.md)
- [ ] Tabellen-Kürzung und Zellen-Popup im echten Fenster (`markdown.nvim/tabellen-kuerzung-und-zellen-popup-im-echten-fenster-pruefen`): siehe [markdown.nvim-live-checks-2026-10-29.md](markdown.nvim-live-checks-2026-10-29.md)

## mdview.nvim

- [ ] **mdview: Cursorzeilen-Band im Browser sichten** (`mdview.nvim/mdview-nvim-cursorzeilen-band-im-browser-sichten`)
    - `cursor_marker='line'` setzen; das Band geht über die volle Breite und folgt `j`/`k`.
    - Umgebrochene Zeile, Codeblock und Leerzeile prüfen; `w`, `$` und `0` verschieben das Band nicht.
    - Alle fünf Themes ansehen (Farbe und Deckkraft).
    - Warum du: Farbe, Deckkraft und Verhalten im echten Browser kann nur ein Mensch beurteilen.
- [ ] Scroll-Lag (reverse/proportional) beurteilen (`mdview.nvim/scroll-lag-feel-judgement`): siehe [mdview.nvim-live-checks-2026-10-29.md](mdview.nvim-live-checks-2026-10-29.md)
- [ ] Shared relay mit zwei nvim-Instanzen und echtem Browser (`mdview.nvim/shared-relay-live-pruefen-zwei-nvim-instanzen-echter-browser`): siehe [mdview.nvim-live-checks-2026-10-29.md](mdview.nvim-live-checks-2026-10-29.md)
- [ ] Spotlight-Spiegel in echtem Neovim und Browser beurteilen (`mdview.nvim/spotlight-mirror-live-check`): siehe [mdview.nvim-live-checks-2026-10-29.md](mdview.nvim-live-checks-2026-10-29.md)

## nvim-config

- [ ] Bindings-Laufzeit-Checkliste von Hand (`nvim-config/bindings-checklist-run`): siehe [BINDINGS-RUNTIME-CHECKLIST.md](BINDINGS-RUNTIME-CHECKLIST.md)
- [ ] context_open (M-o) ausprobieren (`nvim-config/context-open-review`): siehe [nvim-config-live-checks-2026-10-29.md](nvim-config-live-checks-2026-10-29.md)
- [ ] noice-Skip-Regeln und Start ohne Standalone-nui (`nvim-config/live-check-noice-skip-regeln-und-start-ohne-standalone-nui`): siehe [nvim-config-live-checks-2026-10-29.md](nvim-config-live-checks-2026-10-29.md)
- [ ] [u/]u Struktur-Sprung und :Bindings check (`nvim-config/live-check-structure-jump-and-bindings-check`): siehe [nvim-config-live-checks-2026-10-29.md](nvim-config-live-checks-2026-10-29.md)
- [ ] B in :MyPlugins machine (Float-Terminal) (`nvim-config/machine-build-key-live-check`): siehe [nvim-config-live-checks-2026-10-29.md](nvim-config-live-checks-2026-10-29.md)
- [ ] :MyNative install und uninstall live (`nvim-config/mynative-install-und-uninstall-einmal-live-durchspielen`): siehe [nvim-config-live-checks-2026-10-29.md](nvim-config-live-checks-2026-10-29.md)
- [ ] neotest in der eigenen Sitzung (K8, Statuszeichen) (`nvim-config/neotest-live-checks-own-session`): siehe [Checks-Blocker_0610.md](Checks-Blocker_0610.md)
- [ ] OHANA mit UI neu messen (`nvim-config/ohana-startup-remeasure`): siehe [nvim-config-live-checks-2026-10-29.md](nvim-config-live-checks-2026-10-29.md)
- [ ] **neo-tree Handle-Leak: Patch nach einem Tag nachmessen** (`nvim-config/neo-tree-utils-job-handle-leak-upstream-issue-melden-und-pat`)
    - Nach einem Tag normaler Nutzung die offenen process-Handles mit `:lua vim.uv.walk(...)` zählen (soll einstellig sein, vorher 984).
    - Wert in der Task notieren.
    - Das Upstream-Issue bei neo-tree selbst posten.
    - Warum du: Messung in deiner echten, einen Tag laufenden Sitzung; das Upstream-Issue postest nur du.

## terminal.nvim

- [ ] terminal.nvim Live-Abnahme in WezTerm und tmux (`terminal.nvim/live-check`): siehe [terminal.nvim.md](terminal.nvim.md)

## ui.nvim

> **Stand 2026-10-31:** Die drei Checks unten sind jetzt Testblätter (`ui.nvim/TESTS/sheets/`).
> Der automatische Teil läuft mit der Suite; was nur du beurteilen kannst, steht in der
> Abnahme-Inbox von [testblaetter-report.md](testblaetter-report.md) (erzeugt mit
> `testing sheets report`). Dort abarbeiten, die Punkte hier sind nur noch der Verweis.

- [ ] ui.slots: Live-Abnahme in der echten Konfiguration (`ui.nvim/slots-live-check`): siehe [ui.nvim.md](ui.nvim.md), Abschnitt „Sichtprüfung ui.slots“
- [ ] :UI option-Float in echter Sitzung (`ui.nvim/try-the-ui-option-float-in-a-real-session`): siehe [ui.nvim.md](ui.nvim.md), Abschnitt „Option-Float von :UI“
- [ ] **Hotkey-Markierung der Dialog-Buttons im echten Terminal** (`ui.nvim/sichtpruefung-hotkey-markierung-der-dialog-buttons-im-echten`)
    - Einen `kit.confirm`-Dialog mit vielen Buttons öffnen.
    - Prüfen: `KitHotkey`-Unterstreichung ist sichtbar; hochgestellte Ziffern (auch ⁴ bis ⁹) sehen in deiner Schrift sauber aus.
    - Befund in der Task notieren.
    - Warum du: Unterstreichung und hochgestellte Ziffern in der eigenen Schrift lassen sich nur ansehen.

## testing.nvim

- [ ] **:Testing ci / ci repos im echten Editor, Statusline in lualine** (`testing.nvim/ci-editor-live-test-von-testing-ci-ci-repos-im-echten-editor`)
    - `:Testing ci` in testing.nvim: Live-Buffer, Fortschritt, Verdikt, Quickfix ansehen.
    - `:Testing ci repos` mit `roots=$REPOS_DIR` laufen lassen.
    - `statusline()` in lualine einbinden und ansehen; Auffälligkeiten als Tasks anlegen.
    - Warum du: Split, Fokus und Statusline lassen sich nur in einer echten UI beurteilen.

## tasks-desktop und tasks.nvim

- [ ] Kacheln der Übersicht und Filter im echten Tauri-Fenster (`tasks-desktop/hand-pruefung-kacheln-der-uebersicht-und-filter-im-echten-ta`): siehe [tasks-apps-live-checks-2026-10-29.md](tasks-apps-live-checks-2026-10-29.md)
- [ ] .exe auf sauberem Benutzerkonto (`tasks-desktop/tasks-desktop-exe-auf-sauberem-benutzerkonto-von-hand-durchs`): siehe [tasks-apps-live-checks-2026-10-29.md](tasks-apps-live-checks-2026-10-29.md)
- [ ] tasks-desktop: Mac-Test und dmg (Gatekeeper, Entfernen) (`tasks-desktop/tasks-desktop-mac-test-und-dmg-auf-einem-echten-mac-gatekeep`): siehe [tasks-apps-live-checks-2026-10-29.md](tasks-apps-live-checks-2026-10-29.md)
- [ ] Ordner des Vaults zeigen (explorer, open, xdg-open) (`tasks-desktop/tasks-desktop-ordner-des-vaults-zeigen-explorer-open-xdg-ope`): siehe [tasks-apps-live-checks-2026-10-29.md](tasks-apps-live-checks-2026-10-29.md)
- [ ] P6a: Ordner-Task in anderen Bereich verschieben, auf macOS (`tasks.nvim/tasks-app-p6a-ordner-task-in-einen-anderen-bereich-verschieb`): siehe [tasks-apps-live-checks-2026-10-29.md](tasks-apps-live-checks-2026-10-29.md)
- [ ] **tasks-desktop Standalone: Handlauf unter Linux und auf sauberem Windows-Konto** (`tasks-desktop/tasks-desktop-standalone-handlauf-unter-linux-xdg-open-und-a`)
    - Zuerst die Akzeptanzpunkte der Task konkretisieren (der Task-Text ist noch leer).
    - Standalone-Variante unter Linux starten und die xdg-open-Pfade prüfen.
    - Auf einem sauberen Windows-Konto durchspielen; Befunde als bug-Tasks.
    - Warum du: Braucht einen Linux-Desktop bzw. ein sauberes Zweitkonto.
- [ ] **tasks-App P6a: Meilenstein-Abnahme Inhalte** (`tasks-desktop/tasks-app-p6a-meilenstein-abnahme-inhalte-bestandsaufnahme-u`)
    - Erst nach der Entblockung (die Task steht zurzeit auf blocked).
    - Bestandsaufnahme: Spalte „Inhalte“ ohne „fehlt“; `tasks-hub usage --days=14` im eigenen Terminal.
    - Die zwei zugehörigen Tasks über die App schließen.
    - Warum du: Echter Gebrauch der App und deine eigenen Nutzungsdaten.

## takt

- [ ] **takt Gate 0: vier Wochen Alltagsnutzung** (`takt/gate-0-protokoll-vier-wochen-alltagsnutzung`)
    - takt als Standard-Player setzen und vier Wochen nutzen, mindestens 15 Protokolleinträge.
    - Störungen als bug-Tasks anlegen.
    - Die Gate-Antwort in `docs/reviews/phase-0.md` schreiben.
    - Warum du: Vier Wochen Eigennutzung mit Protokoll und ehrlicher Gate-Antwort; die Vorgänger-Tasks sind noch offen.

## Rest aus Agenten-Läufen

- [ ] **Runner dauerhaft laufen lassen? (Akzeptanzpunkt 2)** (`testing.nvim/casedesk-nvim-und-my-nvim-runner-starten-und-ci-der-review-f`)
    - Vorschlag des Agenten (steht als Notiz in der Task): praktisch schon entschieden. Die Runner laufen dauerhaft per Autostart im Benutzerkontext, nicht als Dienst; ein NETWORK-SERVICE-PATH-Problem gibt es daher nicht.
    - Wenn du zustimmst: Haken bei Punkt 2 setzen und `done` für die Task ausführen.
    - Warum du: Die Entscheidung über den Dauerbetrieb ist deine.
- [ ] **docmap Binary-Check: OneDrive-Rest und Eltern-Task** (`docmap.nvim/engine-links-binary-check#docs-map-junction`)
    - Der Teilpunkt „docs/map als Junction“ ist belegt und abgehakt. `done` lief nicht durch, weil die Tasks-CLI keine IDs mit `#` annimmt („invalid slug“); die Eltern-Task `docmap.nvim/engine-links-binary-check` bleibt deshalb offen.
    - Für dich bleiben nur die OneDrive-Punkte: ein Ordner mit „Files on demand“-Platzhaltern wird weiter gelesen, ein Platzhalter mit ` [` im Namen, und die Platzhalter-Hälfte von „Listing-Typ file/directory ist nie ein Link“ (siehe [docmap-live-checks-2026-10-29.md](docmap-live-checks-2026-10-29.md) Abschnitt 2).
    - Warum du: Braucht einen laufenden, angemeldeten OneDrive-Client mit aktivierten On-Demand-Dateien.

## Vom Agenten heute erledigt

- [x] `nvim-config/runner-einmal-neu-starten-damit-sie-ohne-nvim-dir-laufen`: bestanden
- [x] `ALL/private-repos-ci-runner-stevespc`: bestanden
- [ ] `testing.nvim/casedesk-nvim-und-my-nvim-runner-starten-und-ci-der-review-f`: teilweise (Akzeptanzpunkt 2 wartet auf deine Entscheidung, siehe oben)
- [x] `docmap.nvim/engine-links-binary-check#docs-map-junction`: bestanden (Eltern-Task bleibt wegen der `#`-ID offen, siehe oben)
