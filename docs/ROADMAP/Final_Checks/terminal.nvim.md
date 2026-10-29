# terminal.nvim — Live-Check-Plan (Stand 2026-10-15)

Alles, was gebaut und mit Specs (586, Windows lokal; CI ubuntu/windows/macos, Neovim 0.11.0 auf ubuntu) und `TESTS/live/*` geprüft ist, aber nie von Hand im Alltag lief. Task: `terminal.nvim/live-check` (Plan `terminal-build`, Phase `abnahme`); Definition of done steht im Plan `$REPOS_DIR/tasks-vault/terminal.nvim/ROADMAP/plans/terminal-build.md`. Was hier steht, kann keine Sitzung ohne deine Maschine, dein WezTerm und dein tmux.

Konvention: `- [ ]` offen, `- [x]` verifiziert. Unter jedem Punkt eine Zeile `Notiz:` für Beobachtungen. Ist etwas auffällig, **nicht hier sammeln**, sondern als Task anlegen (`kind: bug`, `refs: terminal.nvim/live-check`), die Zeile hier mit der Task-Id schließen.

## Table of content

  - [0 — Vorbereitung](#0--vorbereitung)
  - [A — Native: die alten Gewohnheiten](#a--native-die-alten-gewohnheiten)
  - [B — Befehle und Senden](#b--befehle-und-senden)
  - [C — Picker, Statusline-Segment, Events](#c--picker-statusline-segment-events)
  - [D — Sessions](#d--sessions)
  - [E — WezTerm (Windows)](#e--wezterm-windows)
  - [F — Zwei Neovim-Instanzen](#f--zwei-neovim-instanzen)
  - [G — tmux (WSL/Linux)](#g--tmux-wsllinux)
  - [H — Pin und Adopt](#h--pin-und-adopt)
  - [I — Fehlerfälle](#i--fehlerfälle)
  - [J — Last und Gefühl](#j--last-und-gefühl)
  - [K — Familien-Integrationen](#k--familien-integrationen)
  - [K2 — Cheatsheet](#k2--cheatsheet)
  - [L — Skripte (`TESTS/live/*`)](#l--skripte-testslive)
  - [M — Abschluss](#m--abschluss)
  - [Neue Live-Checks (Stand 2026-10-29)](#neue-live-checks-stand-2026-10-29)

---

## 0 — Vorbereitung

- [ ] `terminal.nvim`, `lib.nvim`, `sessions.nvim`, `ui.nvim`, `testing.nvim`, `sandbox.nvim` pullen (mindestens `terminal.nvim@de5b2ca`, `ui.nvim@cf54a71`, `sessions.nvim@bd0c82a`, `testing.nvim@1f2ddb0`, `sandbox.nvim@589820a`), Neovim neu starten.
  Notiz:
- [ ] `:checkhealth terminal` ohne Fehler; die Zeilen zu Backend, Multiplexer und `allow-passthrough` stimmen mit der Umgebung überein.
  Notiz:
- [ ] `:Terminal` ohne Argumente schaltet um (kein Menü). `:Terminal list` mit nichts offen meldet "no terminals in this project".
  Notiz:

---

## A — Native: die alten Gewohnheiten

Die Tasten aus dem früheren `terminal.lua` müssen sich anfühlen wie vorher.

- [ ] `<A-h>` öffnet das Float-Terminal im Projekt-Root (Terminal-Modus), erneut `<A-h>` blendet es aus; die Shell läuft weiter (`sleep 30` vorher starten, wieder einblenden).
  Notiz:
- [ ] `3<A-h>` öffnet Terminal "3", `<A-h>` danach wieder das Standard-Terminal; jedes Projekt hat seine eigene Menge (Projekt wechseln, Namen prüfen mit `:Terminal list`).
  Notiz:
- [ ] `<Esc>` und `<C-c>` verlassen den Terminal-Modus (`normal_mode`). `<C-c>` unterbricht dabei also keinen laufenden Befehl der Shell: so wie in der alten Config? (sonst Task, Taste per `keymaps.normal_mode` ändern).
  Notiz:
- [ ] `<C-h>` / `<C-j>` / `<C-k>` im Terminal wechseln das Fenster; `<C-l>` löscht weiterhin den Bildschirm der Shell (`window_right` ist aus).
  Notiz:
- [ ] Optional, falls `keymaps.clear` aktiviert ist: tippt `cls` bei cmd.exe/PowerShell, sonst `clear` (die Shell entscheidet, nicht das OS; Git Bash/WSL unter Windows bekommen `clear`).
  Notiz:
- [ ] Layouts: `:Terminal open build --layout=vsplit`, `split`, `tab`, `float` sehen richtig aus (Rahmen, Titel = Name, Größe), Fensteroptionen (keine Zeilennummern) stimmen.
  Notiz:
- [ ] Kitty-Padding nur in Kitty (falls genutzt): beim Start schmal, beim Beenden zurückgesetzt.
  Notiz:

---

## B — Befehle und Senden

- [ ] `:Terminal run npm test` (oder ein harmloser Befehl) tippt die Zeile ins "run"-Terminal und drückt Enter.
  Notiz:
- [ ] `:Terminal run --direct make test`: der Befehl ist der Job; nach dem Ende bleibt das Fenster (`close = never`), der Exit-Code ist sichtbar.
  Notiz:
- [ ] `:Terminal send line` tippt **ohne** Enter, `--exec` mit Enter. Mehrere Zeilen brauchen `--exec`.
  Notiz:
- [ ] `:'<,'>Terminal send selection` zeichenweise (`v`), zeilenweise (`V`) und blockweise (`<C-v>` mit `$`) sendet genau die Auswahl.
  Notiz:
- [ ] `:Terminal send file` sendet den Buffer.
  Notiz:
- [ ] `<Tab>`-Completion der Terminal-Namen nach `:Terminal open ` / `send line `.
  Notiz:
- [ ] `:Terminal hide` / `close` / `close build`: ausgeblendet läuft der Job weiter, geschlossen ist er weg und der Name frei.
  Notiz:

---

## C — Picker, Statusline-Segment, Events

Neu seit 2026-10-15.

- [ ] Zwei, drei Terminals offen. `:Terminal list` öffnet den Picker (Kit-Fenster), die Vorschau rechts zeigt die letzten Zeilen des Terminals unter dem Cursor und folgt dem Cursor.
  Notiz:
- [ ] Wörter im Prompt filtern die Liste; `<CR>` öffnet das gewählte Terminal.
  Notiz:
- [ ] `<C-x>` schließt das gewählte Terminal und die Liste aktualisiert sich ohne Neuöffnen.
  Notiz:
- [ ] `<C-s>`: Prompt "Send to …", eine Zeile eingeben, Enter; die Zeile läuft im Terminal.
  Notiz:
- [ ] Ein Terminal mit beendetem Job erscheint gedämpft mit "exited N".
  Notiz:
- [ ] Fallback: mit `lib.nvim` ohne Kit (oder `engine = "select"`) fragt `vim.ui.select` erst nach dem Terminal, dann nach der Aktion (open / send a line / close).
  Notiz:
- [ ] Statusline-Segment: `terminal_count` in die `order`-Liste von `ui.statusline` aufnehmen. Im Terminal steht `name (n)` bzw. nur `name`, woanders `n terminals`, ohne Terminals nichts. Kein Flackern beim Ein-/Ausblenden.
  Notiz:
- [ ] Events: `:autocmd User TerminalCommandPost` / `TerminalExitPost` mit einem Wegwerf-Listener (`:lua vim.api.nvim_create_autocmd("User", { pattern = {"TerminalCommandPost","TerminalExitPost"}, callback = function(ev) print(vim.inspect(ev.data)) end })`) belegen; `:Terminal run ls` und `:Terminal run --direct ...` lösen sie wie in `docs/BINDINGS.md` beschrieben aus; getippter Text ohne Enter nicht.
  Notiz:

---

## D — Sessions

Mit `sessions.nvim` (`fe35ca8`) und `terminal.nvim` (`b56a7c8`).

- [ ] Zwei Terminals offen (eins mit `run --direct`), `:Session save work`; neben `work.vim` liegt `.work.terminals.json`.
  Notiz:
- [ ] Neovim neu starten, `:Session load work`: die Terminals kommen versteckt zurück (`toggle` zeigt sie); bei `sessions.commands = "ask"` fragt die Auswahl einmal nach den Befehlen.
  Notiz:
- [ ] Zweites `:Session load work` dupliziert nichts.
  Notiz:
- [ ] `:Session rename work work2`: `.work2.terminals.json` ist da, `.work.terminals.json` weg; `:Session load work2` bringt die Terminals zurück.
  Notiz:
- [ ] `:Session delete work2` entfernt das Sidecar mit.
  Notiz:

---

## E — WezTerm (Windows)

Neovim in einem WezTerm-Tab, `Configs/terminals/wezterm` aktiv.

- [ ] Tab-Titel zeigt Datei (und Modus), Right-Status zeigt Modus, Branch, Diagnostik; Wechsel von Buffer/Modus/Branch aktualisiert innerhalb eines Augenblicks.
  Notiz:
- [ ] Neovim normal beenden (`:qa`): Anzeige verschwindet sofort.
  Notiz:
- [ ] Neovim abwürgen (`taskkill /f /im nvim.exe`): im Windows-Pane verschwindet die Anzeige (Prozessname ist nicht mehr Neovim). **Hinter `wsl.exe`/tmux/ssh bleibt sie stehen, bewusst nur dokumentiert** (`docs/nvim-status.md`, "Stale variables and cost").
  Notiz:
- [ ] Navigation: zweites WezTerm-Pane rechts (`wezterm cli split-pane --right`), in Neovim `<C-l>` (oder `nav_right`) am rechten Rand: Fokus wechselt ins andere Pane; innerhalb von Neovim wandert der Fokus zuerst durch die Fenster. Floats geben nie ab.
  Notiz:
- [ ] `backend = "wezterm"`: `:Terminal open build` öffnet ein WezTerm-Pane, `send`/`run` tippen hinein, `hide`/`close` verhalten sich wie dokumentiert (`docs/backends.md`).
  Notiz:
- [ ] Fokus unter Windows nach `<A-h>` aus WezTerm heraus (Alt-Tab und zurück): keine verlorene Tastatur.
  Notiz:

---

## F — Zwei Neovim-Instanzen

- [ ] Zwei WezTerm-Panes, in jedem ein Neovim (unterschiedliche Dateien/Branches): Tab-Titel und Right-Status gehören zum jeweils **fokussierten** Pane; ein Wechsel zeigt sofort den anderen.
  Notiz:
- [ ] Navigation zwischen den beiden Panes mit den Tasten funktioniert in beide Richtungen.
  Notiz:
- [ ] Ein Neovim als `:terminal`-Kind des anderen (`git commit` ohne `-m` öffnet `$EDITOR`): der innere exportiert nicht über den äußeren drüber (nested), im tmux-Pane des äußeren aber schon (`TESTS/live/nested.lua`).
  Notiz:

---

## G — tmux (WSL/Linux)

`allow-passthrough on` gesetzt, `Configs/terminals/tmux/tmux.conf` geladen (`@terminal_status_segment`).

- [ ] `status-right` zeigt Modus, Branch, Diagnostik und verschwindet, wenn im Pane kein Neovim läuft.
  Notiz:
- [ ] Mit Theme-Plugin (catppuccin-tmux): das Segment steht nach TPM-Start trotzdem vorn.
  Notiz:
- [ ] Navigation: `<C-h/j/k>` am Neovim-Rand springt ins Nachbar-Pane, am äußeren Rand des tmux-Fensters passiert **nichts** (kein Umbruch zur Gegenseite).
  Notiz:
- [ ] `backend = "tmux"`: `:Terminal open build` teilt das tmux-Fenster, `send` tippt wörtlich (auch `foo;` und `-l C-c Enter`), `close` räumt das Pane weg.
  Notiz:
- [ ] Status in einem **äußeren** WezTerm sichtbar (tmux in WezTerm, nur mit `allow-passthrough on`); ohne die Option erscheint er nicht, und `:checkhealth terminal` sagt es.
  Notiz:
- [ ] Verschachtelung: Neovim im tmux-Pane, darin `:terminal` + Neovim: nur der äußere exportiert.
  Notiz:

---

## H — Pin und Adopt

- [ ] `:Terminal pin build --backend=tmux` (oder `wezterm`): das native Terminal verschwindet, ein Pane startet, derselbe Name; ohne Multiplexer meldet es das, **bevor** das native Terminal beendet wird.
  Notiz:
- [ ] Neovim beenden, neu starten: das Pane lebt weiter; `:Terminal adopt build` zeigt den Bildschirm in einem schreibgeschützten Buffer, der sich aktualisiert.
  Notiz:
- [ ] Hängt `adopt` oder `pin` irgendwo (Multiplexer antwortet langsam)? Der Editor bleibt bedienbar (Timeouts `multiplexer.timeout_ms`, `adopt.refresh_ms`).
  Notiz:
- [ ] `terminal.teardown()` (z. B. vor `:qa`): schließt native Terminals und Adopt-Ansichten sauber, keine Meldungen.
  Notiz:

---

## I — Fehlerfälle

Jeder Fall meldet **einmal** und stört nicht.

- [ ] `backend = "wezterm"` ohne `wezterm` im PATH (oder `$WEZTERM_PANE` leer).
  Notiz:
- [ ] `backend = "tmux"` ohne tmux / außerhalb von tmux.
  Notiz:
- [ ] tmux-Server stirbt, während ein Pane-Terminal offen ist: nächstes `open` ersetzt es, kein Hänger.
  Notiz:
- [ ] Status-Export mit unbekannter Verschachtelung (äußerer Neovim antwortet nicht): Export bleibt an und warnt einmal (`0ab0268`).
  Notiz:
- [ ] Ein Verzeichnis mit `#` im Namen (`C#`) als Projekt-Root unter tmux: das Pane öffnet im richtigen Verzeichnis.
  Notiz:

---

## J — Last und Gefühl

- [ ] Viel Ausgabe im Terminal (`yes | head -n 200000`, `cat` einer großen Datei) und gleichzeitig tippen/scrollen im Editor: keine spürbare Verzögerung.
  Notiz:
- [ ] Schnelles Ein-/Ausblenden (`<A-h>` mehrfach hintereinander), auch mit mehreren Fenstern: kein Flackern, **kein Absturz** (unter Windows war das früher `0xC0000005`).
  Notiz:
- [ ] Halten von `<C-h>` am Rand mit Multiplexer: kein Prozess pro Wiederholung (ein Hand-off gleichzeitig).
  Notiz:
- [ ] `:Terminal list` mit vielen Terminals (10+): Picker öffnet ohne Verzögerung, Vorschau ruckelt nicht.
  Notiz:
- [ ] Start von Neovim fühlt sich unverändert schnell an (Messung: ohne messbaren Beitrag, `Messungen/startup-*.md`).
  Notiz:

---

## K — Familien-Integrationen

- [ ] `:Testing terminal` (testing.nvim): wiederholt den letzten `:Testing run` in einem Terminal `testing` mit der Ausgabe des Reporters; ohne früheren Lauf läuft das Projekt; ohne `terminal.nvim` meldet es das.
  Notiz:
- [ ] `sandbox.nvim` mit `exec_target = "terminal"`: `:Sandbox container exec <id>` öffnet ein Terminal `sandbox:<id>`, ausblendbar mit `<A-h>`/`:Terminal toggle sandbox:<id>`; mit Default `"split"` unverändert.
  Notiz:
- [ ] `dap.nvim` mit `terminal = { enable = true }` (`dap.nvim@92e0540`): eine Debug-Sitzung mit Programmstart im Terminal (z. B. Python/Node-Launch) öffnet ein Terminal `dap:<Konfigurationsname>` als Split, die Programmausgabe steht dort, nach dem Ende bleibt es mit Exit-Code offen; ein neuer Lauf derselben Konfiguration ersetzt es; `:Terminal list` zeigt es; ohne `enable` unverändert nvim-dap-Puffer.
  Notiz:
- [ ] `require("terminal").run({ "lazygit" }, { direct = true, ... })` aus einem anderen Plugin (gitsuite-Fallback): TUI läuft, Fenster schließt/bleibt nach `close`-Einstellung.
  Notiz:

---

## K2 — Cheatsheet

`terminal.nvim@bdaf625`, Doku `docs/cheatsheet.md`. Headless und mit Specs geprüft, nie als Bild gesehen.

- [ ] `:Terminal cheat` aus einem offenen Terminal: das Float sitzt am rechten Rand, das Terminal links bleibt lesbar (bei dem 80-%-Float-Terminal überdeckt es dessen rechten Rand: stört das?), Titel `bash · 1/9 About`, Markdown sieht gut aus (Tabellen, Backticks ausgeblendet).
  Notiz:
- [ ] `]]` / `[[` / `<Tab>` / `<S-Tab>` blättern, nach dem letzten kommt der erste.
  Notiz:
- [ ] `/` fragt nach einem Suchwort, springt in den passenden Abschnitt (auch ein anderer als der aktuelle), markiert den Treffer; `n` / `N` wandern über alle Treffer.
  Notiz:
- [ ] `g?` zeigt die `common`-Seite, nochmal `g?` zurück; `s` wählt eine andere Shell (`powershell`).
  Notiz:
- [ ] Windows: in einem PowerShell-Terminal (Shell `pwsh`) erscheint die PowerShell-Seite von selbst; in Git Bash oder WSL die bash-Seite; in einem tmux-/WezTerm-Pane `common`. Stimmen die Inhalte (Befehle ausprobieren: `Where-Object`, `Select-String`, `2>&1`, `<(cmd)`)?
  Notiz:
- [ ] `<CR>` auf einer Tabellenzeile tippt den Befehl (ohne Enter) ins Terminal und schließt das Float, du landest im Terminal-Modus; auf einer Kopfzeile oder Taste (`<C-r>`) passiert nichts außer einer Meldung.
  Notiz:
- [ ] `q` / `<Esc>` schließen; aus dem Terminal-Modus geöffnet kommst du im Terminal-Modus zurück.
  Notiz:
- [ ] Taste: `keymaps = { cheatsheet = "<A-?>" }` öffnet es im Terminal- und im Normal-Modus.
  Notiz:
- [ ] Eigene Sheets: `cheatsheet.dir` mit einer `bash.md` ersetzt die eingebaute Seite; eine leere Datei fällt auf die eingebaute zurück; `cheatsheet.shells = { fish = "..." }` fügt eine Shell hinzu und `:Terminal cheat <Tab>` kennt sie.
  Notiz:
- [ ] Inhalt: fehlt dir ein Bereich oder ein Befehl, den du ständig brauchst? (Wunschliste hier eintragen, daraus wird eine Task.)
  Notiz:

---

## L — Skripte (`TESTS/live/*`)

Kommentar im Kopf der Dateien nennt jeweils den Aufruf; jedes Skript endet in `RESULT ok` oder `RESULT failed` in `$SMOKE_OUT`.

- [ ] `smoke.lua` (echtes Neovim-Fenster): `SMOKE_OUT=… nvim -u NONE -i NONE -c "luafile TESTS/live/smoke.lua"` → `RESULT ok`.
  Notiz:
- [ ] `wezterm.lua` und `navigate.lua` und `pin.lua` (in einem WezTerm-Pane) → je `RESULT ok`.
  Notiz:
- [ ] `tmux.lua` (WSL: `TMUX_LIVE_WSL=<distro> nvim --headless -u NONE -l TESTS/live/tmux.lua`) und `nested.lua` (Linux/WSL) → `RESULT ok`.
  Notiz:

---

## M — Abschluss

- [ ] Jeder Befund ist ein Task (`kind: bug`, `refs: terminal.nvim/live-check`).
- [ ] Wenn alles passt: Punkte hier streichen, Task `live-check` erledigen (`tasks.lua done terminal.nvim/live-check`), Plan `terminal-build` auf `done` setzen und nach `Backlog/FEATURES/` verschieben (Regel R6).
- [ ] Danach Tag setzen (Task `release-docs`, Vorschlag `v0.1.0`) und `README` von "Beta" lösen oder bewusst lassen.

---

## Neue Live-Checks (Stand 2026-10-29)

Task `terminal.nvim/live-check` ist unverändert offen (Plan `terminal-build`, Phase `abnahme`, `effort: M`); die Abschnitte 0 bis M oben tragen die Akzeptanz der Task vollständig (alte Gewohnheiten, WezTerm, zwei Instanzen, tmux, Pin/adopt, Fehlerfälle, Last). Seit dem Stand vom 2026-10-15 sind zwei terminal.nvim-Funktionen dazugekommen, die in A bis M nicht vorkommen und in derselben Sitzung mitgeprüft werden sollten; ihre Schritte stehen in `nvim-config-live-checks-2026-10-29.md` (gleicher Ordner):

- [ ] Ask-Bridge `$NVIM_ASK` (Task `terminal.nvim/nvim-ask-bridge`): Large-files-Dialog aus lazygit und aus einem terminal.nvim-Terminal, `:checkhealth terminal` zeigt „Ask bridge: terminals get $NVIM_ASK …“ — dort Abschnitt 2.
  Notiz:
- [ ] Build-Terminal `build:<repo>` über `B` in `:MyPlugins machine` (Float, `direct`, `cwd` = Repo; `:Terminal list` zeigt es) — dort Abschnitt 4.
  Notiz:

Danach (zusätzlich zu M): beide Verweise hier abhaken, sobald die Abschnitte dort durch sind.
